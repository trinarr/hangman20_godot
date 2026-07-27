extends Node

const SAVE_PATH := "user://save_hangman.json"

var interface_language: String = "ru"
var word_language: String = "ru"
var player_name: String = ""

# AS3 Settings:
# 0 - show first/last letters in two-player mode: 1 off, 2 on
# 1 - hints in two-player mode: 1 off, 2 on
# 2 - word pool: 0 all/general, 1 hard words, 2 easy words
# 3 - sound/music: 1 off, 2 on
# 4 - vibration: 1 off, 2 on
# 5 - hero: 1 Lucky, 2 El Tigre
var settings: Array = [2, 2, 0, 2, 2, 1]

# Records:
# 0 classic: current easy, current hard, record easy, record hard
# 1 two-player: wins, defeats
var records: Array = [[0, 0, 0, 0], [0, 0]]

var progress: Dictionary = {}
var single_player: Dictionary = {}
var current_mode: int = 0 # 0 classic, 1 two-player, 2 level mode

func _ready() -> void:
	load_game()

func load_game() -> void:
	_set_interface_language_from_locale()
	word_language = interface_language
	if !FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if !(parsed is Dictionary):
		return

	# Older saves stored a single language for both UI and words. Preserve that
	# value only as the selected word database; UI language is always device-led.
	var legacy_language: String = str(parsed.get("language", interface_language))
	word_language = _normalize_language(str(parsed.get("word_language", legacy_language)))
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
	var loaded_single_player = parsed.get("single_player", single_player)
	if loaded_single_player is Dictionary:
		single_player = loaded_single_player
	_normalize_arrays()

func _set_interface_language_from_locale() -> void:
	# The interface follows the device on every launch: Russian only for a
	# Russian locale, English for Ukrainian and every other locale.
	var locale: String = OS.get_locale().to_lower()
	interface_language = "ru" if locale.begins_with("ru") else "en"

func _normalize_language(lang: String) -> String:
	return "ru" if lang.to_lower().begins_with("ru") else "en"

func save_game() -> void:
	_normalize_arrays()
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Can not write save: " + SAVE_PATH)
		return
	file.store_string(JSON.stringify({
		"word_language": word_language,
		"player_name": player_name,
		"settings": settings,
		"records": records,
		"progress": progress,
		"single_player": single_player
	}, "\t"))
	file.close()

func _normalize_arrays() -> void:
	while settings.size() < 6:
		settings.append(1)
	while records.size() < 2:
		records.append([])
	if records.size() > 2:
		records.resize(2)
	while Array(records[0]).size() < 4:
		records[0].append(0)
	while Array(records[1]).size() < 2:
		records[1].append(0)
	_normalize_single_player()

func reset_current_game() -> void:
	current_mode = 0
	save_game()

func set_word_language(lang: String) -> void:
	word_language = _normalize_language(lang)
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

func _normalize_single_player() -> void:
	if !(single_player is Dictionary):
		single_player = {}
	for lang_key in single_player.keys():
		if !(single_player[lang_key] is Dictionary):
			single_player[lang_key] = {}
		var bucket: Dictionary = single_player[lang_key]
		if !bucket.has("unlocked_level"):
			bucket["unlocked_level"] = 0
		bucket["unlocked_level"] = maxi(int(bucket["unlocked_level"]), 0)
		if !bucket.has("levels") or !(bucket["levels"] is Dictionary):
			bucket["levels"] = {}
		var levels: Dictionary = bucket["levels"]
		for level_key in levels.keys():
			if !(levels[level_key] is Array):
				levels[level_key] = []
				continue
			var statuses: Array = levels[level_key]
			for status_index in range(statuses.size()):
				statuses[status_index] = _normalize_single_level_status(statuses[status_index])
			levels[level_key] = statuses
		bucket["levels"] = levels
		if !bucket.has("word_stats") or !(bucket["word_stats"] is Dictionary):
			bucket["word_stats"] = {}
		var word_stats: Dictionary = bucket["word_stats"]
		for theme_key in word_stats.keys():
			if !(word_stats[theme_key] is Dictionary):
				word_stats[theme_key] = {"played": [], "guessed": []}
			var item: Dictionary = word_stats[theme_key]
			if !item.has("played") or !(item["played"] is Array):
				item["played"] = []
			if !item.has("guessed") or !(item["guessed"] is Array):
				item["guessed"] = []
			word_stats[theme_key] = item
		bucket["word_stats"] = word_stats
		single_player[lang_key] = bucket

func _single_player_bucket(lang: String) -> Dictionary:
	var lang_key := _normalize_language(lang)
	if !single_player.has(lang_key) or !(single_player[lang_key] is Dictionary):
		single_player[lang_key] = {
			"unlocked_level": 0,
			"levels": {}
		}
	var bucket: Dictionary = single_player[lang_key]
	if !bucket.has("unlocked_level"):
		bucket["unlocked_level"] = 0
	bucket["unlocked_level"] = maxi(int(bucket["unlocked_level"]), 0)
	if !bucket.has("levels") or !(bucket["levels"] is Dictionary):
		bucket["levels"] = {}
	if !bucket.has("word_stats") or !(bucket["word_stats"] is Dictionary):
		bucket["word_stats"] = {}
	single_player[lang_key] = bucket
	return bucket


func ensure_single_player_theme_progress(lang: String, theme_index: int, word_count: int) -> Dictionary:
	var lang_key := _normalize_language(lang)
	var bucket := _single_player_bucket(lang_key)
	var word_stats: Dictionary = bucket["word_stats"]
	var theme_key := str(theme_index)
	if !word_stats.has(theme_key) or !(word_stats[theme_key] is Dictionary):
		word_stats[theme_key] = {"played": [], "guessed": []}
	var item: Dictionary = word_stats[theme_key]
	if !item.has("played") or !(item["played"] is Array):
		item["played"] = []
	if !item.has("guessed") or !(item["guessed"] is Array):
		item["guessed"] = []
	_resize_bool_array(item["played"], word_count)
	_resize_bool_array(item["guessed"], word_count)
	word_stats[theme_key] = item
	bucket["word_stats"] = word_stats
	single_player[lang_key] = bucket
	return item

func mark_single_player_word_shown(lang: String, theme_index: int, word_index: int, word_count: int) -> void:
	if theme_index < 0 or word_index < 0:
		return
	var item := ensure_single_player_theme_progress(lang, theme_index, word_count)
	if word_index >= item["played"].size():
		return
	item["played"][word_index] = true
	save_game()

func mark_single_player_word_guessed(lang: String, theme_index: int, word_index: int, word_count: int) -> void:
	if theme_index < 0 or word_index < 0:
		return
	var item := ensure_single_player_theme_progress(lang, theme_index, word_count)
	if word_index >= item["guessed"].size():
		return
	item["guessed"][word_index] = true
	save_game()

func _normalize_single_level_status(value: Variant) -> int:
	if value is bool:
		return 1 if bool(value) else 0
	return clampi(int(value), 0, 2)

func _resize_single_level_status_array(statuses: Array, size: int) -> void:
	while statuses.size() < size:
		statuses.append(0)
	if statuses.size() > size:
		statuses.resize(size)
	for status_index in range(statuses.size()):
		statuses[status_index] = _normalize_single_level_status(statuses[status_index])

func ensure_single_level_progress(lang: String, level_index: int, word_count: int) -> Array:
	var bucket := _single_player_bucket(lang)
	var levels: Dictionary = bucket["levels"]
	var level_key := str(level_index)
	if !levels.has(level_key) or !(levels[level_key] is Array):
		levels[level_key] = []
	var statuses: Array = levels[level_key]
	_resize_single_level_status_array(statuses, word_count)
	levels[level_key] = statuses
	bucket["levels"] = levels
	single_player[_normalize_language(lang)] = bucket
	return statuses

func get_single_level_word_status(lang: String, level_index: int, word_slot: int, word_count: int) -> int:
	if level_index < 0 or word_slot < 0:
		return 0
	var statuses := ensure_single_level_progress(lang, level_index, word_count)
	if word_slot >= statuses.size():
		return 0
	return _normalize_single_level_status(statuses[word_slot])

func is_single_level_word_played(lang: String, level_index: int, word_slot: int, word_count: int) -> bool:
	return get_single_level_word_status(lang, level_index, word_slot, word_count) != 0

func get_single_level_played_count(lang: String, level_index: int, word_count: int) -> int:
	var statuses := ensure_single_level_progress(lang, level_index, word_count)
	var count := 0
	for status in statuses:
		if _normalize_single_level_status(status) != 0:
			count += 1
	return count

func is_single_level_completed(lang: String, level_index: int, word_count: int) -> bool:
	if word_count <= 0:
		return false
	return get_single_level_played_count(lang, level_index, word_count) >= word_count

func get_single_level_snapshot(lang: String, level_index: int, word_count: int) -> Dictionary:
	var statuses := ensure_single_level_progress(lang, level_index, word_count)
	var played_count: int = 0
	for status in statuses:
		if _normalize_single_level_status(status) != 0:
			played_count += 1
	return {
		"statuses": statuses.duplicate(),
		"played_count": played_count,
		"completed": word_count > 0 and played_count >= word_count,
	}

func get_single_player_unlocked_level(lang: String) -> int:
	var bucket := _single_player_bucket(lang)
	return maxi(int(bucket.get("unlocked_level", 0)), 0)

func is_single_level_unlocked(lang: String, level_index: int) -> bool:
	return level_index <= get_single_player_unlocked_level(lang)

func mark_single_level_word_played(lang: String, level_index: int, word_slot: int, word_count: int, total_level_count: int, is_win: bool) -> Dictionary:
	var statuses := ensure_single_level_progress(lang, level_index, word_count)
	if word_slot >= 0 and word_slot < statuses.size():
		statuses[word_slot] = 1 if is_win else 2
	var completed: bool = is_single_level_completed(lang, level_index, word_count)
	var unlocked_next: bool = false
	var bucket := _single_player_bucket(lang)
	var unlocked_level: int = int(bucket.get("unlocked_level", 0))
	if completed and level_index >= unlocked_level and level_index + 1 < total_level_count:
		bucket["unlocked_level"] = level_index + 1
		single_player[_normalize_language(lang)] = bucket
		unlocked_next = true
	save_game()
	return {
		"completed": completed,
		"played_count": get_single_level_played_count(lang, level_index, word_count),
		"unlocked_next": unlocked_next,
		"unlocked_level": get_single_player_unlocked_level(lang),
	}

func get_single_player_display_level(lang: String, total_level_count: int) -> int:
	if total_level_count <= 0:
		return 0
	return mini(get_single_player_unlocked_level(lang) + 1, total_level_count)
