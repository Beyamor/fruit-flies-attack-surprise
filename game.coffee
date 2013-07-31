window.onload = ->
	GAME_WIDTH = 600
	GAME_HEIGHT = 600

	createSprite = (file, x, y) ->
		new jaws.Sprite {
			image: "assets/img/#{file}.png"
			x: x
			y: y
		}

	v = {
		create: (x, y) ->
			{x: x, y: y}

		add: (v1, v2) ->
			v.create v1.x + v2.x, v1.y + v2.y

		substract: (v1, v2) ->
			v.create v1.x - v2.x, v1.y - v2.y

		scale: (v1, scale) ->
			v.create v1.x * scale, v1.y * scale

		zero: ->
			v.create 0, 0
			{x: 0, y: 0}

		length: ({x: x, y: y}) ->
			Math.sqrt x*x + y*y

		normal: (v1) ->
			length = v.length v1
			if length > 0
				v.create v1.x/length, v2.y/length
			else
				v.zero()
	}

	class Entity
		constructor: (sprite, x, y) ->
			@sprite = createSprite sprite, x, y
			@vel = v.zero()
			@acc = v.zero()
			@mass = 10
			@maxForce = 10
			@maxSpeed = 5

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

			@sprite.x += @vel.x
			@sprite.y += @vel.y

		draw: ->
			@sprite.draw()

	class Fly extends Entity
		constructor: (@fruit, x, y) ->
			super("fruit-fly", x, y)

		update: ->

			fruitForce = {x: 0, y: 0}
			dx = @fruit.sprite.x - @sprite.x
			dy = @fruit.sprite.y - @sprite.y
			distance = Math.sqrt(dx*dx + dy*dy)
			if distance > 0
				dx /= distance
				dy /= distance

				desiredSpeed = distance * 0.05
				desiredVelX = dx * desiredSpeed
				desiredVelY = dy * desiredSpeed

				fruitForce = {x: desiredVelX - @vel.x, y: desiredVelY - @vel.y}

			@applyForces fruitForce

			super()

	class Fruit extends Entity
		constructor: (x, y) ->
			super("fruit", x, y)

	playState = {
		setup: =>
			@fruit = new Fruit GAME_WIDTH/2, GAME_HEIGHT/2
			@flies = (new Fly(@fruit, x, y) for [x, y] in [[30, 20], [100, 50], [200, 30]])

			jaws.preventDefaultKeys ["up", "down", "left", "right", "space"]

		update: =>
			fly.update() for fly in @flies

		draw: =>
			jaws.clear()
			fly.draw() for fly in @flies
			@fruit.draw()
	}

	jaws.assets.add "assets/img/fruit-fly.png"
	jaws.assets.add "assets/img/fruit.png"
	jaws.init {width: GAME_WIDTH, height: GAME_HEIGHT}
	jaws.start playState
