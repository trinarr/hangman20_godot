extends Node

@onready var db = get_node("/root/Database")

var current_theme: String
var available_words: Array = []
var used_words: Array = []


func set_theme(theme: String) -> void:
	current_theme = theme
	available_words = db.get_words(theme).duplicate()
	used_words.clear()


func get_random_word() -> String:
	if available_words.is_empty():
		return ""

	var index: int = randi() % available_words.size()
	var word: String = available_words[index]

	available_words.remove_at(index)
	used_words.append(word)

	return word


func reset() -> void:
	available_words = db.get_words(current_theme).duplicate()
	used_words.clear()


func has_words_left() -> bool:
	return !available_words.is_empty()


func get_progress() -> Dictionary:
	return {
		"used": used_words.size(),
		"total": used_words.size() + available_words.size()
	}
