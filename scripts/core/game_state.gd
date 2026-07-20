extends Node

const SAVE_PATH := "user://save_hangman.json"

var language: String = "ru"
var player_name: String = ""

# AS3 Settings:
# 0 - show first/last letters in two-player mode: 1 off, 2 on
# 1 - hints in two-player mode: 1 off, 2 on
# 2 - word pool: 0 all/general, 1 hard words, 2 easy words
# 3 - sound/music: 1 off, 2 on
# 4 - vibration: 1 off, 2 on
# 5 - hero: 1 Lucky, 2 El Tigre
var settings: Array = [2, 2, 0, 2, 2, 1]

# AS3 Records:
# 0 classic: current easy, current hard, record easy, record hard
# 1 two-player: wins, defeats
# 2 time attack: wins, best wins, best score
var records: Array = [[0, 0, 0, 0], [0, 0], [0, 0, 0]]

var progress: Dictionary = {}
var current_mode: int = 0 # 0 classic, 1 time attack, 2 two-player
var current_score: int = 0
var current_time_left: int = 180
# Hangman 3.2.3 keeps two additional values in ErrArr[1]:
# - the current word number in Time Attack (starts at 1);
# - the uninterrupted correct-letter streak used by the score multiplier.
var time_attack_round: int = 1
var correct_guess_streak: int = 0

func _ready() -> void:
	load_game()

func load_game() -> void:
	if !FileAccess.file_exists(SAVE_PATH):
		_set_default_language_from_locale()
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if !(parsed is Dictionary):
		return

	language = str(parsed.get("language", language))
	player_name = str(parsed.get("player_name", player_name)).strip_edges()
	var loaded_settings = parsed.get("settings", settings)
	if loaded_settings is Array:
		settings = loaded_settings
	var loaded_records = parsed.get("records", records)
	if loaded_records is Array:
		records = loaded_records
	var loaded_progress = parsed.get("progress", progress)
	if loaded_progress is Dictionary:
		progress = loaded_progress
	_normalize_arrays()

func _set_default_language_from_locale() -> void:
	# MainTimeline.as uses Russian for Russian and Ukrainian system locales and
	# English for every other locale on the first launch.
	var locale: String = OS.get_locale().to_lower()
	language = "ru" if locale.begins_with("ru") or locale.begins_with("uk") else "en"

func save_game() -> void:
	_normalize_arrays()
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Can not write save: " + SAVE_PATH)
		return
	file.store_string(JSON.stringify({
		"language": language,
		"player_name": player_name,
		"settings": settings,
		"records": records,
		"progress": progress
	}, "\t"))
	file.close()

func _normalize_arrays() -> void:
	while settings.size() < 6:
		settings.append(1)
	while records.size() < 3:
		records.append([])
	while Array(records[0]).size() < 4:
		records[0].append(0)
	while Array(records[1]).size() < 2:
		records[1].append(0)
	while Array(records[2]).size() < 3:
		records[2].append(0)
	time_attack_round = maxi(1, time_attack_round)
	correct_guess_streak = maxi(0, correct_guess_streak)

func reset_current_game() -> void:
	current_mode = 0
	current_score = 0
	current_time_left = 180
	time_attack_round = 1
	correct_guess_streak = 0
	save_game()

func set_language(lang: String) -> void:
	var normalized: String = lang.to_lower()
	language = "ru" if normalized.begins_with("ru") or normalized.begins_with("uk") else "en"
	save_game()

func ensure_theme_progress(lang: String, theme_index: int, word_count: int) -> Dictionary:
	var lang_key := lang.to_lower()
	if !progress.has(lang_key) or !(progress[lang_key] is Dictionary):
		progress[lang_key] = {}
	var theme_key := str(theme_index)
	if !progress[lang_key].has(theme_key) or !(progress[lang_key][theme_key] is Dictionary):
		progress[lang_key][theme_key] = {"played": [], "guessed": []}
	var item: Dictionary = progress[lang_key][theme_key]
	if !item.has("played") or !(item["played"] is Array):
		item["played"] = []
	if !item.has("guessed") or !(item["guessed"] is Array):
		item["guessed"] = []
	_resize_bool_array(item["played"], word_count)
	_resize_bool_array(item["guessed"], word_count)
	progress[lang_key][theme_key] = item
	return item

func _resize_bool_array(arr: Array, size: int) -> void:
	while arr.size() < size:
		arr.append(false)
	if arr.size() > size:
		arr.resize(size)

func mark_played(lang: String, theme_index: int, word_index: int, word_count: int) -> void:
	if theme_index < 0 or word_index < 0:
		return
	var item := ensure_theme_progress(lang, theme_index, word_count)
	item["played"][word_index] = true
	save_game()

func mark_guessed(lang: String, theme_index: int, word_index: int, word_count: int) -> void:
	if theme_index < 0 or word_index < 0:
		return
	var item := ensure_theme_progress(lang, theme_index, word_count)
	item["guessed"][word_index] = true
	save_game()

func clear_theme(lang: String, theme_index: int, word_count: int) -> void:
	var item := ensure_theme_progress(lang, theme_index, word_count)
	for i in range(item["played"].size()):
		item["played"][i] = false
		item["guessed"][i] = false
	save_game()
