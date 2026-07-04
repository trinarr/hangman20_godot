extends Node2D

enum ScreenState {
	MENU,
	GAME,
	SETTINGS,
	RESULTS,
	HELP
}

var current_state: ScreenState

@onready var menu: Control = $Screens/Menu
@onready var game: Node = $Screens/Game

func _ready() -> void:
	print("Game started")
	change_state(ScreenState.MENU)

func change_state(state: ScreenState) -> void:
	current_state = state

	menu.visible = false
	game.visible = false

	match state:
		ScreenState.MENU:
			menu.visible = true

		ScreenState.GAME:
			game.visible = true

			if game.has_method("start_game"):
				game.start_game()
