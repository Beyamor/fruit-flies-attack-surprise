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
		constructor: (@fruit, @flies, x, y) ->
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

			@applyForces flyForce, fruitForce

			super()

	class Fruit extends Entity
		constructor: (x, y) ->
			super("fruit", x, y)

	class FlySpawner
		constructor: (@fruit, @flies) ->
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

				@flies.push new Fly @fruit, @flies, x, y

	class Shot extends Entity
		constructor: (x, y, direction) ->
			super "shot", x, y
			direction *= Math.PI / 180
			@vel = v.scale(v.create(Math.cos(direction), Math.sin(direction)), 10)

	class Gun extends Entity
		constructor: (@shots, x, y) ->
			super "gun", x, y
			@maxTick = 500
			@tick = @maxTick

		update: ->
			dx = jaws.mouse_x - @x
			dy = jaws.mouse_y - @y
			@angle = Math.atan2(dy, dx) * 180 / Math.PI

			@tick += jaws.game_loop.tick_duration
			if jaws.pressed("left_mouse_button") and @tick >= @maxTick
				@tick = 0
				@shots.push new Shot @x, @y, @angle

	playState = {
		setup: =>
			@fruit = new Fruit GAME_WIDTH/2, GAME_HEIGHT - 50
			@flies = new jaws.SpriteList
			@shots = new jaws.SpriteList
			@spawner = new FlySpawner @fruit, @flies
			@guns = new jaws.SpriteList
			@guns.push new Gun(@shots, GAME_WIDTH/2 - 100, GAME_HEIGHT - 25)
			@guns.push new Gun(@shots, GAME_WIDTH/2 + 100, GAME_HEIGHT - 25)

			jaws.preventDefaultKeys ["up", "down", "left", "right", "space"]

		update: =>
			@spawner.update()
			@guns.update()
			@shots.update()
			@flies.update()

		draw: =>
			jaws.clear()
			@shots.draw()
			@guns.draw()
			@flies.draw()
			@fruit.draw()
	}

	jaws.assets.add "assets/img/fruit-fly.png"
	jaws.assets.add "assets/img/fruit.png"
	jaws.assets.add "assets/img/shot.png"
	jaws.assets.add "assets/img/gun.png"
	jaws.init {width: GAME_WIDTH, height: GAME_HEIGHT}
	jaws.start playState
