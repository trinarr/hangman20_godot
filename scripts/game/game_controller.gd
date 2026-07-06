extends Node

signal letter_pressed(letter: String)
signal game_won
signal game_lost

var input_enabled: bool = true

func start_game(theme_id: int) -> void:
	var word := WordManager.start_new_word(theme_id)
	GameSession.start_round(word, word.index, word.theme_index, 0)
	input_enabled = true

func on_letter_input(letter: String) -> void:
	if !input_enabled:
		return
	var result := GameSession.guess(letter)
	emit_signal("letter_pressed", letter)
	_update_state(result)

func _update_state(_last_correct: bool) -> void:
	if GameSession.is_won():
		input_enabled = false
		emit_signal("game_won")
		print("WIN")
		return
	if GameSession.is_lost():
		input_enabled = false
		emit_signal("game_lost")
		print("LOSE")
