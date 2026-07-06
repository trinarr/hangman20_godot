extends Node

var data: Dictionary = {}
var translations: Array = []
var current_language: String = "ru"

const WORD_FILES := {
	"ru": "res://data/words_ru.json",
	"en": "res://data/words_en.json"
}

const CONFIG_FILES := {
	"ru": "res://data/config_ru.json",
	"en": "res://data/config_en.json"
}

func _ready() -> void:
	load_language(current_language)

func load_language(lang: String) -> void:
	current_language = _normalize_language(lang)
	_load_words()
	_load_translations()

func _normalize_language(lang: String) -> String:
	var normalized := lang.to_lower()
	if normalized.begins_with("ru"):
		return "ru"
	return "en"

func _load_json(path: String) -> Variant:
	if !FileAccess.file_exists(path):
		push_error("File not found: " + path)
		return null

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Can not open file: " + path)
		return null

	var text := file.get_as_text()
	file.close()

	# Several converted files have UTF-8 BOM. JSON.parse_string does not accept it.
	if text.length() > 0 and text.unicode_at(0) == 0xFEFF:
		text = text.substr(1)

	var result = JSON.parse_string(text)
	if result == null:
		push_error("JSON parse error: " + path)
	return result

func _load_words() -> void:
	var result = _load_json(WORD_FILES[current_language])
	if result is Dictionary:
		data = result
	else:
		data = {}

func _load_translations() -> void:
	translations.clear()
	var result = _load_json(CONFIG_FILES[current_language])
	if result is Dictionary and result.has("words") and result["words"] is Array:
		translations = result["words"]

func tr_text(index: int, fallback: String = "") -> String:
	if index >= 0 and index < translations.size():
		return str(translations[index])
	return fallback

func get_alphabet() -> PackedStringArray:
	var result := PackedStringArray()
	var alphabet := str(data.get("alphabet", "ABCDEFGHIJKLMNOPQRSTUVWXYZ"))
	for i in range(alphabet.length()):
		result.append(alphabet.substr(i, 1))
	return result

func get_theme_count() -> int:
	return get_themes().size()

func get_themes() -> Array:
	var result: Array = []

	# Russian file shape: { "words": { "THEME": [ ... ] } }
	if data.has("words") and data["words"] is Dictionary:
		for theme_name in data["words"].keys():
			result.append(str(theme_name))
		return result

	# English file shape: { "themes": [ { "type": "SPORT", "words": [...] } ] }
	if data.has("themes") and data["themes"] is Array:
		for item in data["themes"]:
			if item is Dictionary:
				result.append(str(item.get("type", "Theme " + str(result.size() + 1))))
		return result

	# Legacy/old shape support: { "themes": { "THEME": { "words": [...] } } }
	if data.has("themes") and data["themes"] is Dictionary:
		for theme_name in data["themes"].keys():
			result.append(str(theme_name))

	return result

func get_theme_name(theme_index: int) -> String:
	var themes := get_themes()
	if theme_index >= 0 and theme_index < themes.size():
		return str(themes[theme_index])
	return tr_text(46, "No category")

func get_words_by_index(theme_index: int, difficulty_filter: int = 0) -> Array:
	var theme_name := get_theme_name(theme_index)
	var words: Array = []

	if data.has("words") and data["words"] is Dictionary:
		words = Array(data["words"].get(theme_name, []))
	elif data.has("themes") and data["themes"] is Array:
		var themes: Array = data["themes"]
		if theme_index >= 0 and theme_index < themes.size() and themes[theme_index] is Dictionary:
			words = Array(themes[theme_index].get("words", []))
	elif data.has("themes") and data["themes"] is Dictionary:
		var theme_data = data["themes"].get(theme_name, {})
		if theme_data is Dictionary:
			words = Array(theme_data.get("words", []))

	var filtered: Array = []
	for i in range(words.size()):
		var word := str(words[i]).strip_edges().to_upper()
		if word == "" or word == "_":
			continue
		if difficulty_filter != 0:
			var diff := get_word_difficulty(theme_index, i)
			# AS3 Settings[2]: 0 = all, 1 = hard only, 2 = easy only.
			if difficulty_filter == 1 and diff != 1:
				continue
			if difficulty_filter == 2 and diff != 0:
				continue
		filtered.append({"text": word, "index": i, "difficulty": get_word_difficulty(theme_index, i)})
	return filtered

func get_word_difficulty(theme_index: int, word_index: int) -> int:
	var theme_name := get_theme_name(theme_index)
	var difficulty_data = data.get("difficulty", {})
	if difficulty_data is Dictionary:
		var diff_str := str(difficulty_data.get(theme_name, ""))
		if word_index >= 0 and word_index < diff_str.length():
			return int(diff_str.substr(word_index, 1))
	elif difficulty_data is Array and theme_index >= 0 and theme_index < difficulty_data.size():
		var diff_text := str(difficulty_data[theme_index])
		if word_index >= 0 and word_index < diff_text.length():
			return int(diff_text.substr(word_index, 1))
	return 0

func get_number_of_all_words(theme_index: int = -1, difficulty_is_enabled: bool = false) -> int:
	var count := 0
	var filter := GameState.settings[2] if difficulty_is_enabled and has_node("/root/GameState") else 0
	if theme_index < 0:
		for i in range(get_theme_count()):
			count += get_words_by_index(i, filter).size()
	else:
		count = get_words_by_index(theme_index, filter).size()
	return count

# Compatibility helpers for the first partial Godot conversion.
func get_words(theme: String) -> Array:
	var themes := get_themes()
	var idx := themes.find(theme)
	if idx == -1 and theme.is_valid_int():
		idx = int(theme)
	var result: Array = []
	for item in get_words_by_index(idx, 0):
		result.append(item["text"])
	return result

func get_difficulty(theme: String) -> String:
	var themes := get_themes()
	var idx := themes.find(theme)
	if idx == -1 and theme.is_valid_int():
		idx = int(theme)
	var name := get_theme_name(idx)
	var diff = data.get("difficulty", {})
	if diff is Dictionary:
		return str(diff.get(name, ""))
	return ""
