extends Node

var data: Dictionary = {}
var hints: Dictionary = {}
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
# Parsed source files are immutable during a run. Keeping both language payloads
# avoids reparsing several hundred kilobytes of JSON whenever the player toggles
# the word database in Settings.
var _json_cache: Dictionary = {}
var _loaded_word_language: String = ""

const DIFFICULTY_SPLIT: float = 0.5

# Stable numeric IDs are shared by data, icons, and runtime lookup. Semantic
# keys are kept separately for resource paths, diagnostics, and localization.
const THEME_IDS: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
const THEME_KEYS := {
	1: "sport",
	2: "geography",
	3: "nature",
	4: "technics",
	5: "people",
	6: "food",
	7: "science",
	8: "history",
	9: "general",
	10: "film_music",
}
const THEME_TRANSLATION_KEYS := {
	1: &"THEME_SPORT",
	2: &"THEME_GEOGRAPHY",
	3: &"THEME_NATURE",
	4: &"THEME_TECHNICS",
	5: &"THEME_PEOPLE",
	6: &"THEME_FOOD",
	7: &"THEME_SCIENCE",
	8: &"THEME_HISTORY",
	9: &"THEME_GENERAL",
	10: &"THEME_FILM_MUSIC",
}

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
	"COMMON_FREE",
]

const HINT_FILES := {
	"ru": "res://data/hints_ru.json",
	"en": "res://data/hints_en.json"
}

# The quiz mode currently ships with a Russian question base. Theme IDs are the
# same stable 1..10 IDs used by words, icons and localization, so the mode can
# reuse the existing category presentation without a second mapping table.
const QUIZ_FILES := {
	"ru": "res://data/quiz_questions_ru.json"
}

var _quiz_questions_by_theme_cache: Dictionary = {}
var _quiz_data_loaded: bool = false

func load_languages(interface_lang: String, word_lang: String) -> void:
	interface_language = _normalize_language(interface_lang)
	current_language = _normalize_language(word_lang)
	TranslationServer.set_locale(interface_language)
	_ensure_word_language_loaded()

func load_word_language(word_lang: String) -> void:
	current_language = _normalize_language(word_lang)
	_ensure_word_language_loaded()

func _ensure_word_language_loaded() -> void:
	if _loaded_word_language == current_language:
		return
	_load_words()
	_load_hints()
	_loaded_word_language = current_language

func _normalize_language(lang: String) -> String:
	var normalized := lang.to_lower()
	if normalized.begins_with("ru"):
		return "ru"
	return "en"

func _load_json(path: String) -> Variant:
	if _json_cache.has(path):
		return _json_cache[path]
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
	else:
		_json_cache[path] = result
	return result

func _load_words() -> void:
	_invalidate_word_runtime_cache()
	var result = _load_json(WORD_FILES[current_language])
	if result is Dictionary:
		data = result
		_validate_theme_data()
	else:
		data = {}

func _invalidate_word_runtime_cache() -> void:
	_themes_cache.clear()
	_themes_cache_ready = false
	_words_by_index_cache.clear()
	_alphabet_cache.clear()

func _load_hints() -> void:
	# Do not clear the previous dictionary in place: it may be retained by
	# the parsed JSON cache for another language.
	hints = {}
	var result = _load_json(HINT_FILES[current_language])
	if result is Dictionary and result.has("hints") and result["hints"] is Dictionary:
		hints = result["hints"]
	_validate_hint_data()

func _validate_theme_data() -> void:
	var words_data: Variant = data.get("words", {})
	var difficulty_data: Variant = data.get("difficulty", {})
	if !(words_data is Dictionary) or !(difficulty_data is Dictionary):
		push_error("Theme data must contain ID-keyed 'words' and 'difficulty' objects")
		return
	for theme_id in THEME_IDS:
		var data_theme_id := str(theme_id)
		if !words_data.has(data_theme_id):
			push_error("Missing words for theme ID: " + data_theme_id)
			continue
		if !difficulty_data.has(data_theme_id):
			push_error("Missing difficulty for theme ID: " + data_theme_id)
			continue
		var theme_words: Variant = words_data[data_theme_id]
		var theme_difficulty: Variant = difficulty_data[data_theme_id]
		if !(theme_words is Array) or !(theme_difficulty is Array):
			push_error("Theme words and difficulty must be arrays for ID: " + data_theme_id)
			continue
		if theme_words.size() != theme_difficulty.size():
			push_error("Word/difficulty count mismatch for theme ID: " + data_theme_id)
	for raw_theme_id in words_data.keys():
		if !_is_valid_data_theme_id(raw_theme_id):
			push_error("Unknown theme ID in words: " + str(raw_theme_id))
	for raw_theme_id in difficulty_data.keys():
		if !_is_valid_data_theme_id(raw_theme_id):
			push_error("Unknown theme ID in difficulty: " + str(raw_theme_id))

func _validate_hint_data() -> void:
	var words_data: Variant = data.get("words", {})
	for theme_id in THEME_IDS:
		var data_theme_id := str(theme_id)
		if !hints.has(data_theme_id):
			push_error("Missing hints for theme ID: " + data_theme_id)
			continue
		var theme_hints: Variant = hints[data_theme_id]
		if !(theme_hints is Array):
			push_error("Hints must be an array for theme ID: " + data_theme_id)
			continue
		if words_data is Dictionary and words_data.has(data_theme_id):
			var theme_words: Variant = words_data[data_theme_id]
			if theme_words is Array and theme_words.size() != theme_hints.size():
				push_error("Word/hint count mismatch for theme ID: " + data_theme_id)
	for raw_theme_id in hints.keys():
		if !_is_valid_data_theme_id(raw_theme_id):
			push_error("Unknown theme ID in hints: " + str(raw_theme_id))

func _is_valid_data_theme_id(raw_theme_id: Variant) -> bool:
	var data_theme_id := str(raw_theme_id)
	if !data_theme_id.is_valid_int():
		return false
	var numeric_theme_id := int(data_theme_id)
	return data_theme_id == str(numeric_theme_id) and THEME_IDS.has(numeric_theme_id)

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
	_themes_cache = THEME_IDS.duplicate()
	_themes_cache_ready = true
	return _themes_cache

func get_theme_id(theme_index: int) -> int:
	if theme_index >= 0 and theme_index < THEME_IDS.size():
		return THEME_IDS[theme_index]
	return 0

func get_theme_index(theme_id: int) -> int:
	return THEME_IDS.find(theme_id)

func get_theme_key(theme_id: int) -> String:
	return str(THEME_KEYS.get(theme_id, ""))

func get_theme_key_by_index(theme_index: int) -> String:
	return get_theme_key(get_theme_id(theme_index))

func get_theme_name(theme_index: int) -> String:
	var theme_id: int = get_theme_id(theme_index)
	if theme_id <= 0:
		return tr_text(40, "No category")
	var translation_key: StringName = THEME_TRANSLATION_KEYS.get(theme_id, &"")
	if translation_key == &"":
		push_error("Missing translation key for theme ID: " + str(theme_id))
		return get_theme_key(theme_id).replace("_", " ").capitalize()
	var translated: String = str(TranslationServer.translate(translation_key))
	if translated.is_empty() or translated == str(translation_key):
		push_error("Missing localized name for theme ID: " + str(theme_id))
		return get_theme_key(theme_id).replace("_", " ").capitalize()
	return translated

func _ensure_quiz_data_loaded() -> void:
	if _quiz_data_loaded:
		return
	_quiz_data_loaded = true
	_quiz_questions_by_theme_cache.clear()

	var quiz_path: String = str(QUIZ_FILES.get("ru", ""))
	if quiz_path.is_empty():
		return
	var parsed: Variant = _load_json(quiz_path)
	if !(parsed is Dictionary):
		push_error("Quiz data must be a dictionary: " + quiz_path)
		return
	var questions_variant: Variant = parsed.get("questions", [])
	if !(questions_variant is Array):
		push_error("Quiz data must contain a 'questions' array: " + quiz_path)
		return

	for question_variant in questions_variant:
		if !(question_variant is Dictionary):
			continue
		var question: Dictionary = question_variant
		var theme_id: int = int(question.get("theme_id", 0))
		if !THEME_IDS.has(theme_id):
			continue
		var question_text: String = str(question.get("question", "")).strip_edges()
		var answers_variant: Variant = question.get("answers", [])
		if question_text.is_empty() or !(answers_variant is Array):
			continue
		var answers: Array = answers_variant
		if answers.size() != 4:
			continue
		var correct_index: int = int(question.get("correct_index", -1))
		if correct_index < 0 or correct_index >= answers.size():
			continue
		if !_quiz_questions_by_theme_cache.has(theme_id):
			_quiz_questions_by_theme_cache[theme_id] = []
		var theme_questions: Array = _quiz_questions_by_theme_cache[theme_id]
		theme_questions.append(question.duplicate(true))

func get_quiz_questions_by_theme_index(theme_index: int) -> Array:
	_ensure_quiz_data_loaded()
	var theme_id: int = get_theme_id(theme_index)
	if theme_id <= 0:
		return []
	var cached: Variant = _quiz_questions_by_theme_cache.get(theme_id, [])
	if !(cached is Array):
		return []
	return Array(cached).duplicate(true)

func get_quiz_question_count_by_theme_index(theme_index: int) -> int:
	_ensure_quiz_data_loaded()
	var theme_id: int = get_theme_id(theme_index)
	if theme_id <= 0:
		return 0
	var cached: Variant = _quiz_questions_by_theme_cache.get(theme_id, [])
	return Array(cached).size() if cached is Array else 0

func get_words_by_index(theme_index: int, difficulty_filter: int = 0) -> Array:
	var cache_key := "%d:%d" % [theme_index, difficulty_filter]
	var cached_words: Variant = _words_by_index_cache.get(cache_key)
	if cached_words is Array:
		return cached_words

	var theme_id: int = get_theme_id(theme_index)
	var data_theme_id := str(theme_id)
	var words: Array = []
	if theme_id > 0 and data.has("words") and data["words"] is Dictionary:
		words = Array(data["words"].get(data_theme_id, []))

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
	var theme_id: int = get_theme_id(theme_index)
	var difficulty_data = data.get("difficulty", {})
	var theme_difficulty: Variant = null
	if difficulty_data is Dictionary:
		theme_difficulty = difficulty_data.get(str(theme_id), [])

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
	var theme_id: int = get_theme_id(theme_index)
	var data_theme_id := str(theme_id)
	if theme_id <= 0 or !hints.has(data_theme_id) or !(hints[data_theme_id] is Array):
		return ""
	var theme_hints: Array = hints[data_theme_id]
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
