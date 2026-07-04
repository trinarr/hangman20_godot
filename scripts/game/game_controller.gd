extends Node

signal letter_pressed(letter: String)
signal game_won
signal game_lost


@onready var input_enabled: bool = true


# -----------------------------
# START GAME
# -----------------------------

func start_game(theme_id: int) -> void:

	WordManager.start_new_word(theme_id)
	input_enabled = true


# -----------------------------
# INPUT ENTRY POINT
# -----------------------------

func on_letter_input(letter: String) -> void:

	if !input_enabled:
		return

	var result := GameSession.guess(letter)

	emit_signal("letter_pressed", letter)

	_update_state(result)


# -----------------------------
# GAME STATE CHECK
# -----------------------------

func _update_state(last_correct: bool) -> void:

	if GameSession.is_won():
		input_enabled = false
		print("WIN")
		return

	if GameSession.is_lost():
		input_enabled = false
		print("LOSE")
		return
