extends Node

@onready var controller := get_node_or_null("../GameController")

func start_game(theme_id: int) -> void:
	GameSession.mistakes = 0
	if controller != null:
		controller.start_game(theme_id)

func restart_round() -> void:
	var theme := GameSession.theme_id
	if theme == -1:
		theme = 0
	start_game(theme)
