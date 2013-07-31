window.onload = ->
	GAME_WIDTH = 600
	GAME_HEIGHT = 600

	class Fly
		constructor: (x, y) ->
			@sprite = new jaws.Sprite {
				image: "assets/img/fruit-fly.png"
				x: x
				y: y
			}

		update: ->
			# pass
		
		draw: ->
			@sprite.draw()

	playState = {
		setup: =>
			@flies = (new Fly(x, y) for [x, y] in [[30, 20], [100, 50], [200, 30]])

			jaws.preventDefaultKeys ["up", "down", "left", "right", "space"]

		update: =>
			fly.update() for fly in @flies

		draw: =>
			jaws.clear()
			fly.draw() for fly in @flies
	}

	jaws.assets.add "assets/img/fruit-fly.png"
	jaws.init {width: GAME_WIDTH, height: GAME_HEIGHT}
	jaws.start playState
