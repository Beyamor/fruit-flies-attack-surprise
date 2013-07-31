window.onload = ->
	GAME_WIDTH = 600
	GAME_HEIGHT = 600

	createSprite = (file, x, y) ->
		new jaws.Sprite {
			image: "assets/img/#{file}.png"
			x: x
			y: y
		}

	class Entity
		constructor: (sprite, x, y) ->
			@sprite = createSprite sprite, x, y
			@vel = {x: 0, y: 0}
			@acc = {x: 0, y: 0}
			@mass = 10
			@maxForce = 10
			@maxSpeed = 5

		applyForces: (forces...) ->
			resultingForce = {x: 0, y: 0}
			magnitudeSum = 0
			for force in forces
				magnitude = Math.sqrt(force.x*force.x + force.y*force.y)
				continue unless magnitude > 0

				if magnitudeSum + magnitude < @maxForce
					magnitudeSum += magnitude
					resultingForce.x += force.x
					resultingForce.y += force.y
				else
					scale = Math.max(0, (@maxForce - magnitudeSum) / magnitude)
					resultingForce.x += force.x * scale
					resultingForce.y += force.y * scale
					break

			@acc.x += resultingForce.x / @mass
			@acc.y += resultingForce.y / @mass

		update: ->
			@vel.x += @acc.x
			@vel.y += @acc.y

			speed = Math.sqrt(@vel.x*@vel.x + @vel.y*@vel.y)
			if speed > @maxSpeed
				@vel.x *= @maxSpeed / speed
				@vel.y *= @maxSpeed / speed

			@sprite.x += @vel.x
			@sprite.y += @vel.y

		speed: ->
			Math.sqrt @vel.x*@vel.x + @vel.y*@vel.y

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
