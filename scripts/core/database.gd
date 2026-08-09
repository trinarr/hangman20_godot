extends Node

var data: Dictionary = {}
var hints: Array = []
# `current_language` is kept as the word-database language because progress is
# keyed by it throughout the original game logic.
var current_language: String = "ru"
var interface_language: String = "ru"

# Normalized word lists are immutable after loading. Cache them per category and
# difficulty so screen rebuilds do not repeatedly normalize the whole database.
var _themes_cache: Array = []
var _themes_cache_ready: bool = false
var _words_by_index_cache: Dictionary = {}
var _alphabet_cache := PackedStringArray()

const DIFFICULTY_SPLIT: float = 0.5

const WORD_FILES := {
	"ru": "res://data/words_ru.json",
	"en": "res://data/words_en.json"
}

const TRANSLATION_KEYS := [
	"GAME_TITLE",
	"MENU_CLASSIC",
	"MENU_TWO_PLAYER",
	"COMMON_CONTINUE",
	"SETTINGS_TITLE",
	"COMMON_EXIT",
	"NEW_GAME",
	"CHARACTER_SELECT_TITLE",
	"RESTART",
	"MUSIC_LABEL",
	"UNUSED_12",
	"ABOUT_TITLE",
	"WORD_DATABASE_LABEL",
	"GIVE_UP",
	"START",
	"RECORDS_TITLE",
	"RECORD_EASY_STREAK",
	"RECORD_HARD_STREAK",
	"AUTHOR_NIKITA",
	"VERSION_LABEL",
	"AUTHOR_LABEL",
	"CONTACTS_LABEL",
	"ABOUT_WORD",
	"SHOW_EDGE_LETTERS",
	"SHOW_HINTS",
	"CLEAR_THEME_CONFIRM",
	"YES",
	"NO",
	"THEME_SELECT_TITLE",
	"ALL_WORDS_GUESSED",
	"GUESSED",
	"OF",
	"HINTS_LABEL",
	"RESULT_VICTORY",
	"RESULT_DEFEAT",
	"RESULT_END",
	"UNAVAILABLE",
	"INPUT_WORD",
	"VICTORIES",
	"DEFEATS",
	"NO_CATEGORY",
	"COMMENT",
	"CATEGORY_LABEL",
	"WIN_MESSAGE",
	"LOSE_MESSAGE",
	"CHANGE_CATEGORY",
	"EDGE_LETTERS",
	"EASY_WORDS",
	"HARD_WORDS",
	"ALL_WORDS",
	"TRIES_LEFT",
	"WORDS_TOTAL",
	"DIFFICULTY_GENERAL",
	"DIFFICULTY_HARD",
	"DIFFICULTY_EASY",
	"DIFFICULTY_SELECT_TITLE",
	"NEW_RECORD",
	"CATEGORY_COMPLETED",
	"PLAY",
	"SPACE",
	"CHECK_WORD",
	"VIBRATION",
	"REMOVE_ADS",
	"AUTHOR_BRUNO",
	"ERROR_GENERIC",
	"SOUND_MUSIC",
	"NO_COMMENT",
	"CHARACTER_LUCKY",
	"CHARACTER_EL_TIGRE",
	"WELCOME_BACK",
	"NO_UNFINISHED_GAMES",
	"LANGUAGE_RU_SHORT",
	"LANGUAGE_EN_SHORT",
	"ON",
	"OFF",
	"MAX_35_CHARACTERS",
	"RANDOM_WORD",
	"START_GAME",
	"OK",
]

const HINT_FILES := {
	"ru": "res://data/hints_ru.json",
	"en": "res://data/hints_en.json"
}

func load_languages(interface_lang: String, word_lang: String) -> void:
	interface_language = _normalize_language(interface_lang)
	current_language = _normalize_language(word_lang)
	TranslationServer.set_locale(interface_language)
	_load_words()
	_load_hints()

func load_word_language(word_lang: String) -> void:
	current_language = _normalize_language(word_lang)
	_load_words()
	_load_hints()

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
	_invalidate_word_runtime_cache()
	var result = _load_json(WORD_FILES[current_language])
	if result is Dictionary:
		data = result
	else:
		data = {}

func _invalidate_word_runtime_cache() -> void:
	_themes_cache.clear()
	_themes_cache_ready = false
	_words_by_index_cache.clear()
	_alphabet_cache.clear()

func _load_hints() -> void:
	hints.clear()
	var result = _load_json(HINT_FILES[current_language])
	if result is Dictionary and result.has("themes") and result["themes"] is Array:
		hints = result["themes"]

func tr_text(index: int, fallback: String = "") -> String:
	if index < 0 or index >= TRANSLATION_KEYS.size():
		return fallback
	var key := StringName(TRANSLATION_KEYS[index])
	var translated: String = str(TranslationServer.translate(key))
	if translated == "" or translated == str(key):
		return fallback
	return translated

func get_alphabet() -> PackedStringArray:
	if !_alphabet_cache.is_empty():
		return _alphabet_cache
	var alphabet := str(data.get("alphabet", "ABCDEFGHIJKLMNOPQRSTUVWXYZ"))
	for i in range(alphabet.length()):
		_alphabet_cache.append(alphabet.substr(i, 1))
	return _alphabet_cache

func get_theme_count() -> int:
	return get_themes().size()

func get_themes() -> Array:
	if _themes_cache_ready:
		return _themes_cache

	var result: Array = []

	# Russian file shape: { "words": { "THEME": [ ... ] } }
	if data.has("words") and data["words"] is Dictionary:
		for theme_name in data["words"].keys():
			result.append(str(theme_name))
	# English file shape: { "themes": [ { "type": "SPORT", "words": [...] } ] }
	elif data.has("themes") and data["themes"] is Array:
		for item in data["themes"]:
			if item is Dictionary:
				result.append(str(item.get("type", "Theme " + str(result.size() + 1))))
	# Legacy/old shape support: { "themes": { "THEME": { "words": [...] } } }
	elif data.has("themes") and data["themes"] is Dictionary:
		for theme_name in data["themes"].keys():
			result.append(str(theme_name))

	_themes_cache = result
	_themes_cache_ready = true
	return _themes_cache

func get_theme_name(theme_index: int) -> String:
	var themes := get_themes()
	if theme_index >= 0 and theme_index < themes.size():
		return str(themes[theme_index])
	return tr_text(40, "No category")

func get_words_by_index(theme_index: int, difficulty_filter: int = 0) -> Array:
	var cache_key := "%d:%d" % [theme_index, difficulty_filter]
	var cached_words: Variant = _words_by_index_cache.get(cache_key)
	if cached_words is Array:
		return cached_words

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
		var word := normalize_loaded_word(str(words[i]))
		if word == "" or word == "_":
			continue
		var diff: float = get_word_difficulty(theme_index, i)
		if difficulty_filter != 0:
			# AS3 Settings[2]: 0 = all/general, 1 = hard only, 2 = easy only.
			# Scores up to and including 0.5 are easy; scores above 0.5 are hard.
			if difficulty_filter == 1 and diff <= DIFFICULTY_SPLIT:
				continue
			if difficulty_filter == 2 and diff > DIFFICULTY_SPLIT:
				continue
		filtered.append({"text": word, "index": i, "difficulty": diff})
	_words_by_index_cache[cache_key] = filtered
	return filtered

func normalize_loaded_word(word: String) -> String:
	var result := word.strip_edges().to_upper()
	result = result.replace("-", "—")
	result = result.replace("Ё", "Е")
	return result

func get_word_difficulty(theme_index: int, word_index: int) -> float:
	var theme_name := get_theme_name(theme_index)
	var difficulty_data = data.get("difficulty", {})
	var theme_difficulty: Variant = null
	if difficulty_data is Dictionary:
		theme_difficulty = difficulty_data.get(theme_name, [])
	elif difficulty_data is Array and theme_index >= 0 and theme_index < difficulty_data.size():
		theme_difficulty = difficulty_data[theme_index]

	if theme_difficulty == null:
		return 0.0
	if theme_difficulty is Array:
		var scores: Array = theme_difficulty
		if word_index >= 0 and word_index < scores.size():
			return clampf(float(scores[word_index]), 0.0, 1.0)
	else:
		# Backward compatibility for old databases containing strings of 0/1.
		var legacy_values := str(theme_difficulty)
		if word_index >= 0 and word_index < legacy_values.length():
			return clampf(float(legacy_values.substr(word_index, 1)), 0.0, 1.0)
	return 0.0

func get_hint(theme_index: int, word_index: int) -> String:
	if theme_index < 0 or word_index < 0:
		return ""
	if theme_index >= hints.size() or !(hints[theme_index] is Array):
		return ""
	var theme_hints: Array = hints[theme_index]
	if word_index >= 0 and word_index < theme_hints.size():
		return str(theme_hints[word_index]).strip_edges()
	return ""

func get_number_of_all_words(theme_index: int = -1, difficulty_is_enabled: bool = false) -> int:
	var count := 0
	var difficulty_filter: int = int(GameState.settings[2]) if difficulty_is_enabled and has_node("/root/GameState") else 0
	if theme_index < 0:
		for i in range(get_theme_count()):
			count += get_words_by_index(i, difficulty_filter).size()
	else:
		count = get_words_by_index(theme_index, difficulty_filter).size()
	return count

func get_number_of_guessed_words(theme_index: int = -1, difficulty_is_enabled: bool = false) -> int:
	var count := 0
	if theme_index < 0:
		for i in range(get_theme_count()):
			count += get_number_of_guessed_words(i, difficulty_is_enabled)
		return count
	var total := get_words_by_index(theme_index, 0).size()
	var progress := GameState.ensure_theme_progress(current_language, theme_index, total)
	var difficulty_filter: int = int(GameState.settings[2]) if difficulty_is_enabled else 0
	for item in get_words_by_index(theme_index, difficulty_filter):
		var index := int(item["index"])
		if index >= 0 and index < progress["guessed"].size() and bool(progress["guessed"][index]):
			count += 1
	return count
