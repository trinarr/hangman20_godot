extends Node

const SAVE_PATH := "user://save_hangman.json"
const HINT_OPEN_LETTER: String = "open_letter"
const HINT_REMOVE_WRONG: String = "remove_wrong"
const HINT_COMMENT: String = "comment"
const DEFAULT_HINT_COUNT: int = 100

enum GameMode {
	CLASSIC,
	TWO_PLAYER,
	SINGLE_PLAYER,
}

var interface_language: String = "ru"
var word_language: String = "ru"
var player_name: String = ""

# AS3 Settings:
# 0 - reserved legacy two-player edge-letter setting
# 1 - reserved legacy two-player hint setting
# 2 - Classic word pool: 1 hard mode, 2 normal mode (easy words)
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
var hint_counts: Dictionary = {
	HINT_OPEN_LETTER: DEFAULT_HINT_COUNT,
	HINT_REMOVE_WRONG: DEFAULT_HINT_COUNT,
	HINT_COMMENT: DEFAULT_HINT_COUNT,
}
var current_mode: int = GameMode.CLASSIC

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
	var loaded_hint_counts = parsed.get("hint_counts", hint_counts)
	if loaded_hint_counts is Dictionary:
		hint_counts = loaded_hint_counts
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
		"single_player": single_player,
		"hint_counts": hint_counts
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
	# The old three-way selector used 0 for the general pool. The current UI
	# exposes only normal (easy words) and hard modes, so migrate legacy/general
	# saves to the normal mode.
	settings[2] = 1 if int(settings[2]) == 1 else 2
	_normalize_hint_counts()
	_normalize_single_player()

func _normalize_hint_counts() -> void:
	for hint_key in [HINT_OPEN_LETTER, HINT_REMOVE_WRONG, HINT_COMMENT]:
		hint_counts[hint_key] = maxi(int(hint_counts.get(hint_key, DEFAULT_HINT_COUNT)), 0)

func get_hint_count(hint_key: String) -> int:
	_normalize_hint_counts()
	return maxi(int(hint_counts.get(hint_key, 0)), 0)

func consume_hint(hint_key: String) -> bool:
	_normalize_hint_counts()
	var current_count: int = maxi(int(hint_counts.get(hint_key, 0)), 0)
	if current_count <= 0:
		return false
	hint_counts[hint_key] = current_count - 1
	save_game()
	return true

func reset_current_game() -> void:
	current_mode = GameMode.CLASSIC

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

func _normalize_single_player_difficulty(_value: int = -1) -> int:
	# The single-player campaign has one shared progression track. The difficulty
	# selector remains available only in Classic mode.
	return 0

func _normalize_single_player_progress_bucket(value: Variant) -> Dictionary:
	var progress_bucket: Dictionary = {}
	if value is Dictionary:
		progress_bucket = value
	if !progress_bucket.has("unlocked_level"):
		progress_bucket["unlocked_level"] = 0
	progress_bucket["unlocked_level"] = maxi(int(progress_bucket["unlocked_level"]), 0)
	if !progress_bucket.has("levels") or !(progress_bucket["levels"] is Dictionary):
		progress_bucket["levels"] = {}
	if !progress_bucket.has("selected_themes") or !(progress_bucket["selected_themes"] is Dictionary):
		progress_bucket["selected_themes"] = {}
	if !progress_bucket.has("level_seeds") or !(progress_bucket["level_seeds"] is Dictionary):
		progress_bucket["level_seeds"] = {}
	# `level_generations` belonged to a regeneration UI that was never shipped.
	# Drop the stale field while normalizing old saves.
	progress_bucket.erase("level_generations")
	var selected_themes: Dictionary = progress_bucket["selected_themes"]
	for level_key in selected_themes.keys():
		selected_themes[level_key] = int(selected_themes[level_key])
	progress_bucket["selected_themes"] = selected_themes
	var level_seeds: Dictionary = progress_bucket["level_seeds"]
	for seed_level_key in level_seeds.keys():
		level_seeds[seed_level_key] = maxi(int(level_seeds[seed_level_key]), 1)
	progress_bucket["level_seeds"] = level_seeds
	var levels: Dictionary = progress_bucket["levels"]
	for level_key in levels.keys():
		if !(levels[level_key] is Array):
			levels[level_key] = []
			continue
		var statuses: Array = levels[level_key]
		for status_index in range(statuses.size()):
			statuses[status_index] = _normalize_single_level_status(statuses[status_index])
		levels[level_key] = statuses
	progress_bucket["levels"] = levels
	return progress_bucket

func _single_player_progress_score(progress_bucket: Dictionary) -> int:
	var score: int = maxi(int(progress_bucket.get("unlocked_level", 0)), 0) * 10000
	var selected_themes: Variant = progress_bucket.get("selected_themes", {})
	if selected_themes is Dictionary:
		score += selected_themes.size() * 100
	var levels: Variant = progress_bucket.get("levels", {})
	if levels is Dictionary:
		for statuses_value in levels.values():
			if !(statuses_value is Array):
				continue
			for status in statuses_value:
				if _normalize_single_level_status(status) != 0:
					score += 1
	return score

func _normalize_single_player() -> void:
	if !(single_player is Dictionary):
		single_player = {}
	for lang_key in single_player.keys():
		if !(single_player[lang_key] is Dictionary):
			single_player[lang_key] = {}
		var bucket: Dictionary = single_player[lang_key]

		# Older builds kept independent Normal and Hard campaigns. Keep whichever
		# track progressed furthest and migrate it into the new shared campaign.
		var campaign_source: Dictionary = {}
		var best_score: int = -1
		if bucket.has("levels") and bucket["levels"] is Dictionary:
			var legacy_bucket := _normalize_single_player_progress_bucket({
				"unlocked_level": maxi(int(bucket.get("unlocked_level", 0)), 0),
				"levels": bucket["levels"].duplicate(true),
				"selected_themes": {},
				"level_seeds": {},
			})
			campaign_source = legacy_bucket
			best_score = _single_player_progress_score(legacy_bucket)
		var difficulty_progress: Dictionary = {}
		if bucket.has("difficulty_progress") and bucket["difficulty_progress"] is Dictionary:
			difficulty_progress = bucket["difficulty_progress"]
		for difficulty_key in ["0", "2", "1"]:
			if !difficulty_progress.has(difficulty_key):
				continue
			var candidate := _normalize_single_player_progress_bucket(difficulty_progress[difficulty_key])
			var candidate_score: int = _single_player_progress_score(candidate)
			if candidate_score > best_score:
				campaign_source = candidate
				best_score = candidate_score
		bucket["difficulty_progress"] = {
			"0": _normalize_single_player_progress_bucket(campaign_source)
		}
		bucket.erase("unlocked_level")
		bucket.erase("levels")

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
			"difficulty_progress": {
				"0": {
					"unlocked_level": 0,
					"levels": {},
					"selected_themes": {},
					"level_seeds": {},
				}
			},
			"word_stats": {},
		}
	var bucket: Dictionary = single_player[lang_key]
	if !bucket.has("difficulty_progress") or !(bucket["difficulty_progress"] is Dictionary):
		bucket["difficulty_progress"] = {}
	var difficulty_progress: Dictionary = bucket["difficulty_progress"]
	difficulty_progress["0"] = _normalize_single_player_progress_bucket(
		difficulty_progress.get("0", {})
	)
	bucket["difficulty_progress"] = difficulty_progress
	if !bucket.has("word_stats") or !(bucket["word_stats"] is Dictionary):
		bucket["word_stats"] = {}
	single_player[lang_key] = bucket
	return bucket

func _single_player_progress_bucket(lang: String, difficulty: int = -1) -> Dictionary:
	var lang_key := _normalize_language(lang)
	var bucket := _single_player_bucket(lang_key)
	var difficulty_progress: Dictionary = bucket["difficulty_progress"]
	var difficulty_key := str(_normalize_single_player_difficulty(difficulty))
	var progress_bucket := _normalize_single_player_progress_bucket(
		difficulty_progress.get(difficulty_key, {})
	)
	difficulty_progress[difficulty_key] = progress_bucket
	bucket["difficulty_progress"] = difficulty_progress
	single_player[lang_key] = bucket
	return progress_bucket

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

func get_or_create_single_level_seed(lang: String, level_index: int, difficulty: int = -1) -> int:
	if level_index < 0:
		return 1
	var resolved_difficulty := _normalize_single_player_difficulty(difficulty)
	var lang_key := _normalize_language(lang)
	var root_bucket := _single_player_bucket(lang_key)
	var difficulty_progress: Dictionary = root_bucket["difficulty_progress"]
	var difficulty_key := str(resolved_difficulty)
	var progress_bucket := _normalize_single_player_progress_bucket(
		difficulty_progress.get(difficulty_key, {})
	)
	var level_key := str(level_index)
	var level_seeds: Dictionary = progress_bucket["level_seeds"]
	var seed: int = maxi(int(level_seeds.get(level_key, 0)), 0)
	if seed <= 0:
		seed = maxi(int(randi() & 0x7fffffff), 1)
		level_seeds[level_key] = seed
		progress_bucket["level_seeds"] = level_seeds
		difficulty_progress[difficulty_key] = progress_bucket
		root_bucket["difficulty_progress"] = difficulty_progress
		single_player[lang_key] = root_bucket
		save_game()
	return seed

func get_single_level_selected_theme(lang: String, level_index: int, difficulty: int = -1) -> int:
	if level_index < 0:
		return -1
	var progress_bucket := _single_player_progress_bucket(lang, difficulty)
	var selected_themes: Dictionary = progress_bucket["selected_themes"]
	return int(selected_themes.get(str(level_index), -1))

func select_single_level_theme(lang: String, level_index: int, theme_index: int, word_count: int, difficulty: int = -1) -> void:
	if level_index < 0 or theme_index < 0:
		return
	var resolved_difficulty := _normalize_single_player_difficulty(difficulty)
	var lang_key := _normalize_language(lang)
	var root_bucket := _single_player_bucket(lang_key)
	var difficulty_progress: Dictionary = root_bucket["difficulty_progress"]
	var difficulty_key := str(resolved_difficulty)
	var progress_bucket := _normalize_single_player_progress_bucket(
		difficulty_progress.get(difficulty_key, {})
	)
	var level_key := str(level_index)
	var selected_themes: Dictionary = progress_bucket["selected_themes"]
	if int(selected_themes.get(level_key, -1)) >= 0:
		return
	selected_themes[level_key] = theme_index
	progress_bucket["selected_themes"] = selected_themes
	var levels: Dictionary = progress_bucket["levels"]
	var statuses: Array = []
	_resize_single_level_status_array(statuses, word_count)
	levels[level_key] = statuses
	progress_bucket["levels"] = levels
	difficulty_progress[difficulty_key] = progress_bucket
	root_bucket["difficulty_progress"] = difficulty_progress
	single_player[lang_key] = root_bucket
	save_game()

func ensure_single_level_progress(lang: String, level_index: int, word_count: int, difficulty: int = -1) -> Array:
	var lang_key := _normalize_language(lang)
	var root_bucket := _single_player_bucket(lang_key)
	var difficulty_progress: Dictionary = root_bucket["difficulty_progress"]
	var difficulty_key := str(_normalize_single_player_difficulty(difficulty))
	var progress_bucket := _normalize_single_player_progress_bucket(
		difficulty_progress.get(difficulty_key, {})
	)
	var levels: Dictionary = progress_bucket["levels"]
	var level_key := str(level_index)
	if !levels.has(level_key) or !(levels[level_key] is Array):
		levels[level_key] = []
	var statuses: Array = levels[level_key]
	_resize_single_level_status_array(statuses, word_count)
	levels[level_key] = statuses
	progress_bucket["levels"] = levels
	difficulty_progress[difficulty_key] = progress_bucket
	root_bucket["difficulty_progress"] = difficulty_progress
	single_player[lang_key] = root_bucket
	return statuses

func get_single_level_word_status(lang: String, level_index: int, word_slot: int, word_count: int, difficulty: int = -1) -> int:
	if level_index < 0 or word_slot < 0:
		return 0
	var statuses := ensure_single_level_progress(lang, level_index, word_count, difficulty)
	if word_slot >= statuses.size():
		return 0
	return _normalize_single_level_status(statuses[word_slot])

func get_single_level_played_count(lang: String, level_index: int, word_count: int, difficulty: int = -1) -> int:
	var statuses := ensure_single_level_progress(lang, level_index, word_count, difficulty)
	var count := 0
	for status in statuses:
		if _normalize_single_level_status(status) != 0:
			count += 1
	return count

func get_single_level_guessed_count(lang: String, level_index: int, word_count: int, difficulty: int = -1) -> int:
	var statuses := ensure_single_level_progress(lang, level_index, word_count, difficulty)
	var count := 0
	for status in statuses:
		if _normalize_single_level_status(status) == 1:
			count += 1
	return count

func is_single_level_completed(lang: String, level_index: int, word_count: int, difficulty: int = -1) -> bool:
	if word_count <= 0:
		return false
	return get_single_level_played_count(lang, level_index, word_count, difficulty) >= word_count

func is_single_level_perfect(lang: String, level_index: int, word_count: int, difficulty: int = -1) -> bool:
	if word_count <= 0:
		return false
	return get_single_level_guessed_count(lang, level_index, word_count, difficulty) >= word_count

func get_single_player_unlocked_level(lang: String, difficulty: int = -1) -> int:
	var progress_bucket := _single_player_progress_bucket(lang, difficulty)
	return maxi(int(progress_bucket.get("unlocked_level", 0)), 0)

func mark_single_level_word_played(lang: String, level_index: int, word_slot: int, word_count: int, total_level_count: int, is_win: bool, difficulty: int = -1) -> Dictionary:
	var resolved_difficulty := _normalize_single_player_difficulty(difficulty)
	var statuses := ensure_single_level_progress(lang, level_index, word_count, resolved_difficulty)
	if word_slot >= 0 and word_slot < statuses.size():
		statuses[word_slot] = 1 if is_win else 2
	var completed: bool = is_single_level_completed(lang, level_index, word_count, resolved_difficulty)
	var perfect: bool = is_single_level_perfect(lang, level_index, word_count, resolved_difficulty)
	var unlocked_next: bool = false
	var lang_key := _normalize_language(lang)
	var root_bucket := _single_player_bucket(lang_key)
	var difficulty_progress: Dictionary = root_bucket["difficulty_progress"]
	var difficulty_key := str(resolved_difficulty)
	var progress_bucket := _normalize_single_player_progress_bucket(
		difficulty_progress.get(difficulty_key, {})
	)
	var unlocked_level: int = int(progress_bucket.get("unlocked_level", 0))
	if completed and level_index >= unlocked_level and level_index + 1 < total_level_count:
		progress_bucket["unlocked_level"] = level_index + 1
		difficulty_progress[difficulty_key] = progress_bucket
		root_bucket["difficulty_progress"] = difficulty_progress
		single_player[lang_key] = root_bucket
		unlocked_next = true
	save_game()
	return {
		"completed": completed,
		"perfect": perfect,
		"played_count": get_single_level_played_count(lang, level_index, word_count, resolved_difficulty),
		"guessed_count": get_single_level_guessed_count(lang, level_index, word_count, resolved_difficulty),
		"unlocked_next": unlocked_next,
		"unlocked_level": get_single_player_unlocked_level(lang, resolved_difficulty),
	}

func get_single_player_display_level(lang: String, total_level_count: int, difficulty: int = -1) -> int:
	if total_level_count <= 0:
		return 0
	return mini(get_single_player_unlocked_level(lang, difficulty) + 1, total_level_count)
