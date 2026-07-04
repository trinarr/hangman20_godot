extends Node

var data := {}
var current_language := "ru"

func _ready() -> void:
	load_language("ru")


func load_language(lang: String) -> void:
	current_language = lang

	var path := ""
	match lang:
		"ru":
			path = "res://data/words_ru.json"
		"en":
			path = "res://data/words_en.json"

	if !FileAccess.file_exists(path):
		push_error("Dictionary not found: " + path)
		return

	var file := FileAccess.open(path, FileAccess.READ)
	var text := file.get_as_text()

	var result = JSON.parse_string(text)

	if result == null:
		push_error("JSON parse error: " + path)
		return

	data = result


func get_themes() -> Array:
	if !data.has("themes"):
		return []
	return data["themes"].keys()


func get_words(theme: String) -> Array:
	if !data.has("themes"):
		return []

	if !data["themes"].has(theme):
		return []

	return data["themes"][theme]["words"]


func get_difficulty(theme: String) -> String:
	if !data.has("themes"):
		return ""

	if !data["themes"].has(theme):
		return ""

	return data["themes"][theme]["difficulty"]
