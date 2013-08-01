window.onload = ->
	GAME_WIDTH = 800
	GAME_HEIGHT = 600

	random = {
		coinFlip: -> Math.random() < 0.5
		inRange: (min, max) -> min + Math.random() * (max - min)
	}

	v = {
		create: (x, y) ->
			{x: x, y: y}

		add: (v1, v2) ->
			v.create v1.x + v2.x, v1.y + v2.y

		subtract: (v1, v2) ->
			v.create v1.x - v2.x, v1.y - v2.y

		scale: (v1, scale) ->
			v.create v1.x * scale, v1.y * scale

		zero: ->
			v.create 0, 0
			{x: 0, y: 0}

		length: ({x: x, y: y}) ->
			Math.sqrt(x*x + y*y)

		normal: (v1) ->
			length = v.length v1
			if length > 0
				v.create(v1.x/length, v1.y/length)
			else
				v.zero()

		toString: ({x: x, y: y}) ->
			"(#{x}, #{y})"
	}

	class Entity extends jaws.Sprite
		constructor: (image, x, y) ->
			super {
				image: "assets/img/#{image}.png"
				x: x
				y: y
				anchor: "center"
			}
			@vel = v.zero()
			@acc = v.zero()
			@mass = 10
			@maxForce = 10
			@maxSpeed = 5
			@radius = @width / 2

		applyForces: (forces...) ->
			resultingForce = v.zero()
			magnitudeSum = 0
			for force in forces
				magnitude = v.length force
				continue unless magnitude > 0

				if magnitudeSum + magnitude < @maxForce
					magnitudeSum += magnitude
					resultingForce = v.add resultingForce, force
				else
					scale = Math.max(0, (@maxForce - magnitudeSum) / magnitude)
					resultingForce = v.add resultingForce, v.scale(force, scale)
					break

			@acc = v.scale resultingForce, (1/@mass)

		update: ->
			@vel = v.add @vel, @acc

			speed = v.length @vel
			if speed > @maxSpeed
				@vel = v.scale @vel, (@maxSpeed / speed)

			@x += @vel.x
			@y += @vel.y

			@angle = Math.atan2(@vel.y, @vel.x) * 180 / Math.PI

	class Fly extends Entity
		constructor: ({fruit: @fruit, flies: @flies, shots: @shots}, x, y) ->
			super("fruit-fly", x, y)

		update: ->
			# flies love fruit
			fruitForce = {x: 0, y: 0}
			difference = v.subtract @fruit, this
			distance = v.length difference
			if distance > 0
				desiredSpeed = distance * 0.5
				desiredVel = v.scale(v.normal(difference), desiredSpeed)

				fruitForce = v.subtract desiredVel, @vel

			# flies hate flies?
			hateDistance = 200
			flyForce = v.zero()
			@flies.forEach (fly, _, __) =>
				return if fly is this

				difference = v.subtract this, fly
				distance = v.length difference
				return if distance > hateDistance

				magnitude = ((hateDistance - distance) / hateDistance) * @maxForce * 0.4
				flyForce = v.add(flyForce, v.scale(v.normal(difference), magnitude))

			# flies suuuper hate bullets
			hateDistance = 300
			shotForce = v.zero()
			@shots.forEach (shot, _, __) =>
				difference = v.subtract this, shot
				distance = v.length difference
				return if distance > hateDistance

				magnitude = ((hateDistance - distance) / hateDistance) * @maxForce * 0.9
				shotForce = v.add(shotForce, v.scale(v.normal(difference), magnitude))

			# yo, stay inside the room
			roomForce = v.zero()
			if @y + @radius > GAME_HEIGHT
				roomForce.y = -((@y + @radius) - GAME_HEIGHT)


			@applyForces roomForce, shotForce, flyForce, fruitForce

			super()

	class Fruit extends Entity
		constructor: (@entities, @state, x, y) ->
			super("fruit", x, y)

		update: ->
			if jaws.collideOneWithMany(this, @entities.flies).length isnt 0
				@state.end()

	class FlySpawner
		constructor: (@entities) ->
			@ticks = 0
			@maxTicks = 1500

		update: ->
			@ticks += jaws.game_loop.tick_duration
			if @ticks >= @maxTicks
				@ticks = 0

				# from the side
				if random.coinFlip()
					x = if random.coinFlip() then -100 else GAME_WIDTH + 100
					y = random.inRange(0, GAME_HEIGHT / 2)

				# from the top
				else
					y = -100
					x = random.inRange(0, GAME_WIDTH)

				@entities.flies.push new Fly @entities, x, y

	class Shot extends Entity
		constructor: (@entities, @state, x, y, direction) ->
			super "shot", x, y
			direction *= Math.PI / 180
			@vel = v.scale(v.create(Math.cos(direction), Math.sin(direction)), 10)

		update: ->
			super()

			flies = jaws.collideOneWithMany this, @entities.flies
			for fly in flies
				@entities.flies.remove fly
				@state.flyKilled()
			@entities.shots.remove this if flies.length isnt 0

	class Gun extends Entity
		constructor: (@entities, @state, x, y) ->
			super "gun", x, y
			@maxTick = 1000
			@tick = @maxTick

		update: ->
			dx = jaws.mouse_x - @x
			dy = jaws.mouse_y - @y
			@angle = Math.atan2(dy, dx) * 180 / Math.PI

			@tick += jaws.game_loop.tick_duration
			if jaws.pressed("left_mouse_button") and @tick >= @maxTick
				@tick = 0
				@entities.shots.push new Shot @entities, @state, @x, @y, @angle

	playState = {
		setup: ->
			@entities = {
				flies: new jaws.SpriteList
				shots: new jaws.SpriteList
				guns: new jaws.SpriteList
			}

			@entities.fruit = new Fruit @entities, this, GAME_WIDTH/2, GAME_HEIGHT - 50
			@entities.spawner = new FlySpawner @entities
			@entities.guns.push new Gun(@entities, this, GAME_WIDTH/2 - 100, GAME_HEIGHT - 25)
			@entities.guns.push new Gun(@entities, this, GAME_WIDTH/2 + 100, GAME_HEIGHT - 25)

			@numberOfFliesKilled = 0

		update: ->
			@entities.spawner.update()
			@entities.guns.update()
			@entities.shots.update()
			@entities.flies.update()
			@entities.fruit.update()

		draw: ->
			jaws.clear()
			@entities.shots.draw()
			@entities.guns.draw()
			@entities.flies.draw()
			@entities.fruit.draw()

		flyKilled: ->
			++@numberOfFliesKilled

		end: ->
			fliesKilled = @numberOfFliesKilled
			jaws.switchGameState {
				update: ->
					jaws.switchGameState mainMenuState if jaws.pressedWithoutRepeat "left_mouse_button"

				draw: ->
					jaws.clear()
					jaws.context.fillStyle = "black"
					jaws.context.font = "bold 32px Courier"
					jaws.context.fillText("you killed #{fliesKilled} flies!", 100, 250)
					jaws.context.fillText("good job commander", 100, 300)
					jaws.context.fillText("but the battle's not over yet!", 100, 350)
					jaws.context.font = "bold 12px Courier"
					jaws.context.fillText("(click to play again)", 100, 400)
			}
	}

	mainMenuState = {
		update: ->
			jaws.switchGameState playState if jaws.pressedWithoutRepeat "left_mouse_button"

		draw: ->
			jaws.clear()
			jaws.context.fillStyle = "black"
			jaws.context.font = "bold 32px Courier"
			jaws.context.fillText("fruit flies!", 100, 250)
			jaws.context.fillText("attack! surprise!", 100, 300)
			jaws.context.font = "bold 12px Courier"
			jaws.context.fillText("(click to play)", 100, 400)
	}

	# whatever.
	jaws.clear = ->
		jaws.context.fillStyle = "white"
		jaws.context.beginPath()
		jaws.context.rect 0, 0, GAME_WIDTH, GAME_HEIGHT
		jaws.context.fill()

	jaws.assets.add "assets/img/fruit-fly.png"
	jaws.assets.add "assets/img/fruit.png"
	jaws.assets.add "assets/img/shot.png"
	jaws.assets.add "assets/img/gun.png"
	jaws.init {width: GAME_WIDTH, height: GAME_HEIGHT}
	jaws.start mainMenuState
