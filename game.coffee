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

		update: ->
			# pass

		draw: ->
			@sprite.draw()

	class Fly extends Entity
		constructor: (x, y) ->
			super("fruit-fly", x, y)

	class Fruit extends Entity
		constructor: (x, y) ->
			super("fruit", x, y)

	playState = {
		setup: =>
			@fruit = new Fruit GAME_WIDTH/2, GAME_HEIGHT/2
			@flies = (new Fly(x, y) for [x, y] in [[30, 20], [100, 50], [200, 30]])

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
