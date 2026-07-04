extends Node

@onready var controller := $"../GameController"


func start_game(theme_id: int):

	GameSession.mistakes = 0

	controller.start_game(theme_id)


func restart_round():

	var theme := GameSession.theme_id

	if theme == -1:
		theme = 0

	controller.start_game(theme)
