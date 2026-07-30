extends Node

signal soft_currency_changed(balance: int)

const SAVE_PATH := "user://save_hangman.json"
const SAVE_FORMAT_VERSION: int = 1
const HINT_OPEN_LETTER: String = "open_letter"
const HINT_REMOVE_WRONG: String = "remove_wrong"
const HINT_COMMENT: String = "comment"
const DEFAULT_HINT_COUNT: int = 3
const DEFAULT_SOFT_CURRENCY: int = 0
const WORD_REWARD_COINS: int = 10
const HINT_COSTS: Dictionary = {
	HINT_OPEN_LETTER: 20,
	HINT_REMOVE_WRONG: 15,
	HINT_COMMENT: 10,
}

enum GameMode {
	CLASSIC,
	TWO_PLAYER,
	SINGLE_PLAYER,
}

enum HintPayment {
	FAILED,
	FREE_HINT,
	SOFT_CURRENCY,
}

var interface_language: String = "ru"
var word_language: String = "ru"
var player_name: String = ""
var soft_currency: int = DEFAULT_SOFT_CURRENCY

# Settings:
# 0 - reserved
# 1 - reserved
# 2 - Classic word pool: 1 hard mode, 2 normal mode (easy words)
# 3 - sound/music: 1 off, 2 on
# 4 - vibration: 1 off, 2 on
# 5 - hero: 1 Lucky, 2 El Tigre
var settings: Array = [1, 1, 2, 2, 2, 1]

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
	if int(parsed.get("save_version", -1)) != SAVE_FORMAT_VERSION:
		return
	if (
		!(parsed.get("settings") is Array)
		or !(parsed.get("records") is Array)
		or !(parsed.get("progress") is Dictionary)
		or !(parsed.get("single_player") is Dictionary)
		or !(parsed.get("hint_counts") is Dictionary)
	):
		return

	word_language = _normalize_language(str(parsed.get("word_language", word_language)))
	player_name = str(parsed.get("player_name", "")).strip_edges()
	soft_currency = maxi(int(parsed.get("soft_currency", DEFAULT_SOFT_CURRENCY)), 0)
	settings = Array(parsed["settings"]).duplicate(true)
	records = Array(parsed["records"]).duplicate(true)
	progress = Dictionary(parsed["progress"]).duplicate(true)
	single_player = Dictionary(parsed["single_player"]).duplicate(true)
	hint_counts = Dictionary(parsed["hint_counts"]).duplicate(true)

func _set_interface_language_from_locale() -> void:
	# The interface follows the device on every launch: Russian only for a
	# Russian locale, English for Ukrainian and every other locale.
	var locale: String = OS.get_locale().to_lower()
	interface_language = "ru" if locale.begins_with("ru") else "en"

func _normalize_language(lang: String) -> String:
	return "ru" if lang.to_lower().begins_with("ru") else "en"

func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Can not write save: " + SAVE_PATH)
		return
	file.store_string(JSON.stringify({
		"save_version": SAVE_FORMAT_VERSION,
		"word_language": word_language,
		"player_name": player_name,
		"settings": settings,
		"records": records,
		"progress": progress,
		"single_player": single_player,
		"hint_counts": hint_counts,
		"soft_currency": soft_currency
	}, "\t"))
	file.close()

func get_hint_count(hint_key: String) -> int:
	return maxi(int(hint_counts.get(hint_key, 0)), 0)

func get_soft_currency() -> int:
	soft_currency = maxi(soft_currency, 0)
	return soft_currency

func add_soft_currency(amount: int, persist: bool = true) -> int:
	if amount <= 0:
		return get_soft_currency()
	soft_currency = maxi(soft_currency + amount, 0)
	soft_currency_changed.emit(soft_currency)
	if persist:
		save_game()
	return soft_currency

func get_hint_cost(hint_key: String) -> int:
	return maxi(int(HINT_COSTS.get(hint_key, 0)), 0)

func can_pay_for_hint(hint_key: String) -> bool:
	if get_hint_count(hint_key) > 0:
		return true
	var cost: int = get_hint_cost(hint_key)
	return cost > 0 and get_soft_currency() >= cost

func pay_for_hint(hint_key: String) -> int:
	var free_count: int = get_hint_count(hint_key)
	if free_count > 0:
		hint_counts[hint_key] = free_count - 1
		save_game()
		return HintPayment.FREE_HINT

	var cost: int = get_hint_cost(hint_key)
	if cost <= 0 or get_soft_currency() < cost:
		return HintPayment.FAILED
	soft_currency -= cost
	soft_currency_changed.emit(soft_currency)
	save_game()
	return HintPayment.SOFT_CURRENCY

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

func _new_single_player_bucket() -> Dictionary:
	return {
		"unlocked_level": 0,
		"levels": {},
		"selected_themes": {},
		"level_seeds": {},
		"word_stats": {},
	}

func _single_player_bucket(lang: String) -> Dictionary:
	var lang_key := _normalize_language(lang)
	if !single_player.has(lang_key) or !(single_player[lang_key] is Dictionary):
		single_player[lang_key] = _new_single_player_bucket()
	var bucket: Dictionary = single_player[lang_key]
	for dictionary_key in ["levels", "selected_themes", "level_seeds", "word_stats"]:
		if !bucket.has(dictionary_key) or !(bucket[dictionary_key] is Dictionary):
			bucket[dictionary_key] = {}
	if !bucket.has("unlocked_level"):
		bucket["unlocked_level"] = 0
	single_player[lang_key] = bucket
	return bucket

func _single_player_progress_bucket(lang: String, _difficulty: int = -1) -> Dictionary:
	return _single_player_bucket(lang)

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

func _single_level_status(value: Variant) -> int:
	return clampi(int(value), 0, 2)

func _resize_single_level_status_array(statuses: Array, size: int) -> void:
	while statuses.size() < size:
		statuses.append(0)
	if statuses.size() > size:
		statuses.resize(size)
	for status_index in range(statuses.size()):
		statuses[status_index] = _single_level_status(statuses[status_index])

func get_or_create_single_level_seed(lang: String, level_index: int, _difficulty: int = -1) -> int:
	if level_index < 0:
		return 1
	var lang_key := _normalize_language(lang)
	var bucket := _single_player_bucket(lang_key)
	var level_key := str(level_index)
	var level_seeds: Dictionary = bucket["level_seeds"]
	var seed: int = maxi(int(level_seeds.get(level_key, 0)), 0)
	if seed <= 0:
		seed = maxi(int(randi() & 0x7fffffff), 1)
		level_seeds[level_key] = seed
		bucket["level_seeds"] = level_seeds
		single_player[lang_key] = bucket
		save_game()
	return seed

func get_single_level_selected_theme(lang: String, level_index: int, difficulty: int = -1) -> int:
	if level_index < 0:
		return -1
	var progress_bucket := _single_player_progress_bucket(lang, difficulty)
	var selected_themes: Dictionary = progress_bucket["selected_themes"]
	return int(selected_themes.get(str(level_index), -1))

func select_single_level_theme(lang: String, level_index: int, theme_index: int, word_count: int, _difficulty: int = -1) -> void:
	if level_index < 0 or theme_index < 0:
		return
	var lang_key := _normalize_language(lang)
	var bucket := _single_player_bucket(lang_key)
	var level_key := str(level_index)
	var selected_themes: Dictionary = bucket["selected_themes"]
	if int(selected_themes.get(level_key, -1)) >= 0:
		return
	selected_themes[level_key] = theme_index
	bucket["selected_themes"] = selected_themes
	var levels: Dictionary = bucket["levels"]
	var statuses: Array = []
	_resize_single_level_status_array(statuses, word_count)
	levels[level_key] = statuses
	bucket["levels"] = levels
	single_player[lang_key] = bucket
	save_game()

func ensure_single_level_progress(lang: String, level_index: int, word_count: int, _difficulty: int = -1) -> Array:
	var lang_key := _normalize_language(lang)
	var bucket := _single_player_bucket(lang_key)
	var levels: Dictionary = bucket["levels"]
	var level_key := str(level_index)
	if !levels.has(level_key) or !(levels[level_key] is Array):
		levels[level_key] = []
	var statuses: Array = levels[level_key]
	_resize_single_level_status_array(statuses, word_count)
	levels[level_key] = statuses
	bucket["levels"] = levels
	single_player[lang_key] = bucket
	return statuses

func get_single_level_word_status(lang: String, level_index: int, word_slot: int, word_count: int, difficulty: int = -1) -> int:
	if level_index < 0 or word_slot < 0:
		return 0
	var statuses := ensure_single_level_progress(lang, level_index, word_count, difficulty)
	if word_slot >= statuses.size():
		return 0
	return _single_level_status(statuses[word_slot])

func get_single_level_played_count(lang: String, level_index: int, word_count: int, difficulty: int = -1) -> int:
	var statuses := ensure_single_level_progress(lang, level_index, word_count, difficulty)
	var count := 0
	for status in statuses:
		if _single_level_status(status) != 0:
			count += 1
	return count

func get_single_level_guessed_count(lang: String, level_index: int, word_count: int, difficulty: int = -1) -> int:
	var statuses := ensure_single_level_progress(lang, level_index, word_count, difficulty)
	var count := 0
	for status in statuses:
		if _single_level_status(status) == 1:
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
	var statuses := ensure_single_level_progress(lang, level_index, word_count, difficulty)
	if word_slot >= 0 and word_slot < statuses.size():
		statuses[word_slot] = 1 if is_win else 2
	var completed: bool = is_single_level_completed(lang, level_index, word_count, difficulty)
	var perfect: bool = is_single_level_perfect(lang, level_index, word_count, difficulty)
	var unlocked_next: bool = false
	var lang_key := _normalize_language(lang)
	var bucket := _single_player_bucket(lang_key)
	var unlocked_level: int = int(bucket.get("unlocked_level", 0))
	if completed and level_index >= unlocked_level and level_index + 1 < total_level_count:
		bucket["unlocked_level"] = level_index + 1
		single_player[lang_key] = bucket
		unlocked_next = true
	save_game()
	return {
		"completed": completed,
		"perfect": perfect,
		"played_count": get_single_level_played_count(lang, level_index, word_count, difficulty),
		"guessed_count": get_single_level_guessed_count(lang, level_index, word_count, difficulty),
		"unlocked_next": unlocked_next,
		"unlocked_level": get_single_player_unlocked_level(lang, difficulty),
	}

func get_single_player_display_level(lang: String, total_level_count: int, difficulty: int = -1) -> int:
	if total_level_count <= 0:
		return 0
	return mini(get_single_player_unlocked_level(lang, difficulty) + 1, total_level_count)
