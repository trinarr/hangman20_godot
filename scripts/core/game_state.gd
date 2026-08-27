extends Node

signal soft_currency_changed(balance: int)
signal hearts_changed(hearts: int, recovery_seconds: int)

const SAVE_PATH := "user://save_hangman.json"
const SAVE_TMP_PATH := "user://save_hangman.tmp"
const SAVE_BACKUP_PATH := "user://save_hangman.bak"
const SAVE_FORMAT_VERSION: int = 2
const SINGLE_PLAYER_LEVEL_HISTORY_LIMIT: int = 64
const SINGLE_PLAYER_MAX_SAVED_LEVEL_SLOTS: int = 16
const HINT_OPEN_LETTER: String = "open_letter"
const HINT_REMOVE_WRONG: String = "remove_wrong"
const HINT_COMMENT: String = "comment"
const HINT_QUIZ_FIFTY_FIFTY: String = "quiz_fifty_fifty"
const HINT_QUIZ_REPLACE_QUESTION: String = "quiz_replace_question"
const DEFAULT_HINT_COUNT: int = 3
const DEFAULT_SOFT_CURRENCY: int = 100
const MAX_HEARTS: int = 5
const HEART_RECOVERY_SECONDS: int = 5 * 60
const WORD_REWARD_COINS: int = 10
const COIN_REFILL_AD_MAX_VIEWS: int = 5
const COIN_REFILL_AD_COOLDOWN_SECONDS: int = 5 * 60 * 60
const SINGLE_PLAYER_DIFFICULTY_DEFAULT: float = 0.18
const SINGLE_PLAYER_DIFFICULTY_MIN: float = 0.08
const SINGLE_PLAYER_DIFFICULTY_MAX: float = 0.92
const SINGLE_PLAYER_SUCCESS_DIFFICULTY_STEP: float = 0.02
const SINGLE_PLAYER_FAILURE_DIFFICULTY_STEP: float = 0.04
const SINGLE_PLAYER_LEVEL_BASE_BONUS_COINS: int = 10
const SINGLE_PLAYER_LEVEL_WORD_BONUS_COINS: int = 5
const SINGLE_LEVEL_THEME_REROLL_AVAILABLE: int = 0
const SINGLE_LEVEL_THEME_REROLL_COIN_USED: int = 1
const SINGLE_LEVEL_THEME_REROLL_AD_USED: int = 2
const HINT_COSTS: Dictionary = {
	HINT_OPEN_LETTER: 20,
	HINT_REMOVE_WRONG: 15,
	HINT_COMMENT: 10,
	HINT_QUIZ_FIFTY_FIFTY: 20,
	HINT_QUIZ_REPLACE_QUESTION: 20,
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
var hearts: int = MAX_HEARTS
var heart_recovery_at: int = 0
var coin_refill_ad_views_remaining: int = COIN_REFILL_AD_MAX_VIEWS
var coin_refill_ad_cooldown_until: int = 0
var _heart_tick_timer: Timer = null
var _last_emitted_hearts: int = -1
var _last_emitted_heart_seconds: int = -1

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
var active_single_player_session: Dictionary = {}
var pending_single_player_reward: Dictionary = {}
var hint_counts: Dictionary = {
	HINT_OPEN_LETTER: DEFAULT_HINT_COUNT,
	HINT_REMOVE_WRONG: DEFAULT_HINT_COUNT,
	HINT_COMMENT: DEFAULT_HINT_COUNT,
	HINT_QUIZ_FIFTY_FIFTY: DEFAULT_HINT_COUNT,
	HINT_QUIZ_REPLACE_QUESTION: DEFAULT_HINT_COUNT,
}
var current_mode: int = GameMode.CLASSIC
var _save_write_in_progress: bool = false
var _save_blocked_by_future_version: bool = false

func _ready() -> void:
	load_game()
	_heart_tick_timer = Timer.new()
	_heart_tick_timer.name = "HeartRecoveryTick"
	_heart_tick_timer.wait_time = 1.0
	_heart_tick_timer.one_shot = false
	_heart_tick_timer.timeout.connect(_on_heart_tick)
	add_child(_heart_tick_timer)
	_heart_tick_timer.start()
	_emit_heart_status_if_changed(true)

func _on_heart_tick() -> void:
	_apply_elapsed_heart_recovery(true)
	_emit_heart_status_if_changed()

func load_game() -> void:
	_set_interface_language_from_locale()
	word_language = interface_language
	var parsed: Dictionary = _read_save_dictionary(SAVE_PATH)
	var loaded_from_backup: bool = false
	if parsed.is_empty() and FileAccess.file_exists(SAVE_PATH):
		parsed = _read_save_dictionary(SAVE_BACKUP_PATH)
		loaded_from_backup = !parsed.is_empty()
	elif parsed.is_empty():
		parsed = _read_save_dictionary(SAVE_BACKUP_PATH)
		loaded_from_backup = !parsed.is_empty()
	if parsed.is_empty():
		return

	var stored_version: int = int(parsed.get("save_version", 0))
	if stored_version > SAVE_FORMAT_VERSION:
		# Never overwrite a save produced by a newer build after an app downgrade.
		_save_blocked_by_future_version = true
		push_error("Save format is newer than this build: %d" % stored_version)
		return

	word_language = _normalize_language(str(parsed.get("word_language", word_language)))
	var migrated: bool = stored_version < SAVE_FORMAT_VERSION
	if migrated:
		parsed = _migrate_save_payload(parsed, stored_version)

	# Every section is normalized independently. One malformed optional field must
	# never discard an otherwise valid profile or restore economy defaults.
	player_name = str(parsed.get("player_name", "")).strip_edges().left(35)
	soft_currency = clampi(int(parsed.get("soft_currency", DEFAULT_SOFT_CURRENCY)), 0, 2_000_000_000)
	settings = _normalize_settings(parsed.get("settings", settings))
	records = _normalize_records(parsed.get("records", records))
	progress = (
		Dictionary(parsed.get("progress", {})).duplicate(true)
		if parsed.get("progress", {}) is Dictionary
		else {}
	)
	single_player = (
		Dictionary(parsed.get("single_player", {})).duplicate(true)
		if parsed.get("single_player", {}) is Dictionary
		else {}
	)
	active_single_player_session = _normalize_active_single_player_session(
		parsed.get("active_single_player_session", {})
	)
	pending_single_player_reward = _normalize_pending_single_player_reward(
		parsed.get("pending_single_player_reward", {})
	)
	_load_hint_counts_from_save(parsed)
	_load_hearts_from_save(parsed)
	_load_coin_refill_ad_state_from_save(parsed)
	_normalize_single_player_buckets()

	if migrated or loaded_from_backup:
		save_game()

func _read_save_dictionary(path: String) -> Dictionary:
	if !FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if !(parsed is Dictionary):
		return {}
	return Dictionary(parsed).duplicate(true)

func _migrate_save_payload(source: Dictionary, source_version: int) -> Dictionary:
	var migrated: Dictionary = source.duplicate(true)
	if source_version <= 1:
		_migrate_v1_content_keys(migrated)
	migrated["save_version"] = SAVE_FORMAT_VERSION
	return migrated

func _migrate_v1_content_keys(payload: Dictionary) -> void:
	var previous_language: String = Database.current_language
	var progress_root: Variant = payload.get("progress", {})
	if progress_root is Dictionary:
		var migrated_progress: Dictionary = {}
		for language_variant: Variant in (progress_root as Dictionary).keys():
			var language: String = _normalize_language(str(language_variant))
			Database.load_word_language(language)
			migrated_progress[language] = _migrate_v1_theme_progress(
				(progress_root as Dictionary).get(language_variant, {})
			)
		payload["progress"] = migrated_progress

	var single_root: Variant = payload.get("single_player", {})
	if single_root is Dictionary:
		var migrated_single: Dictionary = {}
		for language_variant: Variant in (single_root as Dictionary).keys():
			var language: String = _normalize_language(str(language_variant))
			Database.load_word_language(language)
			var bucket_variant: Variant = (single_root as Dictionary).get(language_variant, {})
			if !(bucket_variant is Dictionary):
				continue
			var bucket: Dictionary = Dictionary(bucket_variant).duplicate(true)
			bucket["word_stats"] = _migrate_v1_theme_progress(bucket.get("word_stats", {}))
			bucket["selected_themes"] = _migrate_v1_selected_themes(bucket.get("selected_themes", {}))
			bucket["question_stats"] = _migrate_v1_theme_dictionary(bucket.get("question_stats", {}))
			migrated_single[language] = bucket
		payload["single_player"] = migrated_single
	Database.load_word_language(_normalize_language(previous_language))

func _migrate_v1_theme_progress(source: Variant) -> Dictionary:
	var result: Dictionary = {}
	if !(source is Dictionary):
		return result
	for old_key_variant: Variant in (source as Dictionary).keys():
		var old_key: String = str(old_key_variant)
		if !old_key.is_valid_int():
			continue
		var theme_index: int = int(old_key)
		var theme_id: int = Database.get_theme_id(theme_index)
		if theme_id <= 0:
			continue
		var item_variant: Variant = (source as Dictionary).get(old_key_variant, {})
		result[str(theme_id)] = _migrate_v1_word_progress_item(item_variant, theme_index)
	return result

func _migrate_v1_word_progress_item(source: Variant, theme_index: int) -> Dictionary:
	var result := {"played": {}, "guessed": {}}
	if !(source is Dictionary):
		return result
	var word_keys: Array[String] = Database.get_word_progress_keys(theme_index)
	for field_name: String in ["played", "guessed"]:
		var flags_variant: Variant = (source as Dictionary).get(field_name, {})
		var migrated_flags: Dictionary = {}
		if flags_variant is Array:
			var flags: Array = flags_variant
			for word_index: int in range(mini(flags.size(), word_keys.size())):
				if bool(flags[word_index]) and !word_keys[word_index].is_empty():
					migrated_flags[word_keys[word_index]] = true
		elif flags_variant is Dictionary:
			for word_key_variant: Variant in (flags_variant as Dictionary).keys():
				if bool((flags_variant as Dictionary).get(word_key_variant, false)):
					migrated_flags[str(word_key_variant)] = true
		result[field_name] = migrated_flags
	return result

func _migrate_v1_theme_dictionary(source: Variant) -> Dictionary:
	var result: Dictionary = {}
	if !(source is Dictionary):
		return result
	for old_key_variant: Variant in (source as Dictionary).keys():
		var old_key: String = str(old_key_variant)
		if !old_key.is_valid_int():
			continue
		var theme_id: int = Database.get_theme_id(int(old_key))
		if theme_id > 0:
			result[str(theme_id)] = (source as Dictionary).get(old_key_variant)
	return result

func _migrate_v1_selected_themes(source: Variant) -> Dictionary:
	var result: Dictionary = {}
	if !(source is Dictionary):
		return result
	for level_key_variant: Variant in (source as Dictionary).keys():
		var theme_id: int = Database.get_theme_id(
			int((source as Dictionary).get(level_key_variant, -1))
		)
		if theme_id > 0:
			result[str(level_key_variant)] = theme_id
	return result

func _normalize_settings(source: Variant) -> Array:
	var result: Array = [1, 1, 2, 2, 2, 1]
	if source is Array:
		for index: int in range(mini((source as Array).size(), result.size())):
			var value: int = int((source as Array)[index])
			result[index] = value if value == 1 or value == 2 else result[index]
	return result

func _normalize_records(source: Variant) -> Array:
	var result: Array = [[0, 0, 0, 0], [0, 0]]
	if !(source is Array):
		return result
	for group_index: int in range(result.size()):
		if group_index >= (source as Array).size() or !((source as Array)[group_index] is Array):
			continue
		var source_group: Array = (source as Array)[group_index]
		var target_group: Array = result[group_index]
		for value_index: int in range(mini(source_group.size(), target_group.size())):
			target_group[value_index] = maxi(int(source_group[value_index]), 0)
		result[group_index] = target_group
	return result

func _load_hint_counts_from_save(parsed: Dictionary) -> void:
	var stored_counts = parsed.get("hint_counts")
	if !(stored_counts is Dictionary):
		# The save already exists, so missing inventory data must not be treated as
		# a new player bonus. A genuinely new player still keeps DEFAULT_HINT_COUNT
		# because load_game() returns earlier when no save file exists.
		for hint_key in HINT_COSTS.keys():
			hint_counts[hint_key] = 0
		return

	for hint_key in HINT_COSTS.keys():
		hint_counts[hint_key] = maxi(int(stored_counts.get(hint_key, 0)), 0)

func _load_hearts_from_save(parsed: Dictionary) -> void:
	# Existing saves predate the global-heart system and start full. Once the
	# fields exist, both the inventory and the absolute recovery deadline are
	# restored so regeneration continues while the app is closed.
	hearts = clampi(int(parsed.get("hearts", MAX_HEARTS)), 0, MAX_HEARTS)
	heart_recovery_at = maxi(int(parsed.get("heart_recovery_at", 0)), 0)
	_apply_elapsed_heart_recovery(false)

func _load_coin_refill_ad_state_from_save(parsed: Dictionary) -> void:
	coin_refill_ad_views_remaining = clampi(
		int(parsed.get("coin_refill_ad_views_remaining", COIN_REFILL_AD_MAX_VIEWS)),
		0,
		COIN_REFILL_AD_MAX_VIEWS
	)
	coin_refill_ad_cooldown_until = maxi(
		int(parsed.get("coin_refill_ad_cooldown_until", 0)),
		0
	)
	_refresh_coin_refill_ad_cooldown(false)

func _set_interface_language_from_locale() -> void:
	# The interface follows the device on every launch: Russian only for a
	# Russian locale, English for Ukrainian and every other locale.
	var locale: String = OS.get_locale().to_lower()
	interface_language = "ru" if locale.begins_with("ru") else "en"

func _normalize_language(lang: String) -> String:
	return "ru" if lang.to_lower().begins_with("ru") else "en"

func save_game() -> bool:
	if _save_blocked_by_future_version or _save_write_in_progress:
		return false
	_save_write_in_progress = true
	_compact_single_player_history()
	var payload: Dictionary = {
		"save_version": SAVE_FORMAT_VERSION,
		"word_language": word_language,
		"player_name": player_name,
		"settings": settings,
		"records": records,
		"progress": progress,
		"single_player": single_player,
		"active_single_player_session": active_single_player_session,
		"pending_single_player_reward": pending_single_player_reward,
		"hint_counts": hint_counts,
		"soft_currency": soft_currency,
		"hearts": hearts,
		"heart_recovery_at": heart_recovery_at,
		"coin_refill_ad_views_remaining": coin_refill_ad_views_remaining,
		"coin_refill_ad_cooldown_until": coin_refill_ad_cooldown_until,
	}
	var file := FileAccess.open(SAVE_TMP_PATH, FileAccess.WRITE)
	if file == null:
		_save_write_in_progress = false
		push_error("Can not write temporary save: " + SAVE_TMP_PATH)
		return false
	file.store_string(JSON.stringify(payload))
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	if write_error != OK or _read_save_dictionary(SAVE_TMP_PATH).is_empty():
		_save_write_in_progress = false
		push_error("Temporary save validation failed")
		return false

	var save_absolute: String = ProjectSettings.globalize_path(SAVE_PATH)
	var temp_absolute: String = ProjectSettings.globalize_path(SAVE_TMP_PATH)
	var backup_absolute: String = ProjectSettings.globalize_path(SAVE_BACKUP_PATH)
	if !_read_save_dictionary(SAVE_PATH).is_empty():
		var backup_error: Error = DirAccess.copy_absolute(save_absolute, backup_absolute)
		if backup_error != OK:
			_save_write_in_progress = false
			push_error("Can not create save backup")
			return false

	var replace_error: Error = DirAccess.rename_absolute(temp_absolute, save_absolute)
	if replace_error != OK and FileAccess.file_exists(SAVE_PATH):
		# Some platforms do not replace an existing destination during rename. The
		# validated backup is already durable, so remove only the old primary and retry.
		var remove_error: Error = DirAccess.remove_absolute(save_absolute)
		if remove_error == OK:
			replace_error = DirAccess.rename_absolute(temp_absolute, save_absolute)
	if replace_error != OK:
		if !FileAccess.file_exists(SAVE_PATH) and FileAccess.file_exists(SAVE_BACKUP_PATH):
			DirAccess.copy_absolute(backup_absolute, save_absolute)
		_save_write_in_progress = false
		push_error("Can not replace primary save")
		return false

	_save_write_in_progress = false
	return true

func _normalize_active_single_player_session(source: Variant) -> Dictionary:
	if !(source is Dictionary):
		return {}
	var session: Dictionary = Dictionary(source).duplicate(true)
	var kind: String = str(session.get("kind", ""))
	var level_index: int = int(session.get("level_index", -1))
	var word_slot: int = int(session.get("word_slot", -1))
	if !["word", "quiz", "next"].has(kind) or level_index < 0 or word_slot < 0:
		return {}
	session["kind"] = kind
	session["language"] = _normalize_language(str(session.get("language", word_language)))
	session["level_index"] = level_index
	session["word_slot"] = word_slot
	session["theme_id"] = maxi(int(session.get("theme_id", 0)), 0)
	if !(session.get("data", {}) is Dictionary):
		session["data"] = {}
	return session

func _normalize_pending_single_player_reward(source: Variant) -> Dictionary:
	if !(source is Dictionary):
		return {}
	var pending: Dictionary = Dictionary(source).duplicate(true)
	var level_index: int = int(pending.get("level_index", -1))
	var word_count: int = int(pending.get("word_count", 0))
	var word_slot: int = int(pending.get("word_slot", word_count - 1))
	var amount: int = clampi(int(pending.get("amount", 0)), 0, 1_000_000_000)
	if level_index < 0 or word_count <= 0 or word_slot < 0 or amount <= 0:
		return {}
	return {
		"claim_id": str(pending.get("claim_id", "%s:%d" % [word_language, level_index])),
		"language": _normalize_language(str(pending.get("language", word_language))),
		"level_index": level_index,
		"word_count": word_count,
		"word_slot": clampi(word_slot, 0, word_count - 1),
		"theme_id": maxi(int(pending.get("theme_id", 0)), 0),
		"amount": amount,
	}

func set_active_single_player_session(session: Dictionary, persist: bool = true) -> bool:
	var normalized: Dictionary = _normalize_active_single_player_session(session)
	if normalized.is_empty():
		return false
	active_single_player_session = normalized
	if persist:
		save_game()
	return true

func clear_active_single_player_session(persist: bool = true) -> void:
	if active_single_player_session.is_empty():
		return
	active_single_player_session = {}
	if persist:
		save_game()

func get_active_single_player_session() -> Dictionary:
	return active_single_player_session.duplicate(true)

func get_pending_single_player_reward() -> Dictionary:
	return pending_single_player_reward.duplicate(true)

func has_resumable_single_player_level() -> bool:
	return !pending_single_player_reward.is_empty() or !active_single_player_session.is_empty()

func get_resumable_single_player_level_index() -> int:
	if !pending_single_player_reward.is_empty():
		return int(pending_single_player_reward.get("level_index", -1))
	return int(active_single_player_session.get("level_index", -1))

func _create_pending_single_player_reward(
	lang: String,
	level_index: int,
	word_slot: int,
	word_count: int,
	theme_id: int,
	amount: int
) -> void:
	if level_index < 0 or word_count <= 0 or amount <= 0:
		return
	pending_single_player_reward = {
		"claim_id": "%s:%d:%d" % [_normalize_language(lang), level_index, word_slot],
		"language": _normalize_language(lang),
		"level_index": level_index,
		"word_slot": clampi(word_slot, 0, word_count - 1),
		"word_count": word_count,
		"theme_id": maxi(theme_id, 0),
		"amount": amount,
	}
	active_single_player_session = {}

func claim_pending_single_player_reward(multiplier: int = 1) -> int:
	if pending_single_player_reward.is_empty():
		return 0
	var credited_amount: int = maxi(
		int(pending_single_player_reward.get("amount", 0)) * clampi(multiplier, 1, 2),
		0
	)
	if credited_amount <= 0:
		return 0
	pending_single_player_reward = {}
	soft_currency = clampi(soft_currency + credited_amount, 0, 2_000_000_000)
	soft_currency_changed.emit(soft_currency)
	save_game()
	return credited_amount

func _normalize_single_player_buckets() -> void:
	if !(single_player is Dictionary):
		single_player = {}
		return
	for language_variant: Variant in single_player.keys():
		var language: String = _normalize_language(str(language_variant))
		var source_bucket: Variant = single_player.get(language_variant, {})
		if language_variant != language:
			single_player.erase(language_variant)
		if source_bucket is Dictionary:
			single_player[language] = Dictionary(source_bucket).duplicate(true)
		else:
			single_player[language] = {}
		_single_player_bucket(language)

func _compact_single_player_history() -> void:
	for language_variant: Variant in single_player.keys():
		if !(single_player.get(language_variant) is Dictionary):
			continue
		var bucket: Dictionary = single_player[language_variant]
		var unlocked_level: int = maxi(int(bucket.get("unlocked_level", 0)), 0)
		var oldest_kept_level: int = maxi(unlocked_level - SINGLE_PLAYER_LEVEL_HISTORY_LIMIT, 0)
		for field_name: String in [
			"levels",
			"selected_themes",
			"level_seeds",
			"theme_reroll_states",
			"level_question_slots",
			"level_question_ids",
		]:
			var values_variant: Variant = bucket.get(field_name, {})
			if !(values_variant is Dictionary):
				continue
			var values: Dictionary = values_variant
			for level_key_variant: Variant in values.keys():
				var level_key: String = str(level_key_variant)
				if (
					!level_key.is_valid_int()
					or int(level_key) < oldest_kept_level
					or int(level_key) > unlocked_level + 1
				):
					values.erase(level_key_variant)
				elif field_name == "levels" and values[level_key_variant] is Array:
					var statuses: Array = values[level_key_variant]
					if statuses.size() > SINGLE_PLAYER_MAX_SAVED_LEVEL_SLOTS:
						statuses.resize(SINGLE_PLAYER_MAX_SAVED_LEVEL_SLOTS)
			bucket[field_name] = values
		single_player[language_variant] = bucket

func get_hint_count(hint_key: String) -> int:
	return maxi(int(hint_counts.get(hint_key, 0)), 0)

func get_coin_refill_ad_views_remaining() -> int:
	_refresh_coin_refill_ad_cooldown(true)
	return clampi(coin_refill_ad_views_remaining, 0, COIN_REFILL_AD_MAX_VIEWS)

func get_coin_refill_ad_cooldown_seconds() -> int:
	_refresh_coin_refill_ad_cooldown(true)
	if coin_refill_ad_views_remaining > 0 or coin_refill_ad_cooldown_until <= 0:
		return 0
	return maxi(coin_refill_ad_cooldown_until - _coin_refill_ad_now(), 0)

func can_watch_coin_refill_ad() -> bool:
	_refresh_coin_refill_ad_cooldown(true)
	return coin_refill_ad_views_remaining > 0

func consume_coin_refill_ad_view(persist: bool = true) -> int:
	_refresh_coin_refill_ad_cooldown(false)
	if coin_refill_ad_views_remaining <= 0:
		return 0
	coin_refill_ad_views_remaining -= 1
	if coin_refill_ad_views_remaining <= 0:
		coin_refill_ad_views_remaining = 0
		coin_refill_ad_cooldown_until = (
			_coin_refill_ad_now() + COIN_REFILL_AD_COOLDOWN_SECONDS
		)
	if persist:
		save_game()
	return coin_refill_ad_views_remaining

func _coin_refill_ad_now() -> int:
	return int(floor(Time.get_unix_time_from_system()))

func _refresh_coin_refill_ad_cooldown(persist: bool) -> bool:
	coin_refill_ad_views_remaining = clampi(
		coin_refill_ad_views_remaining,
		0,
		COIN_REFILL_AD_MAX_VIEWS
	)
	if coin_refill_ad_views_remaining > 0:
		if coin_refill_ad_cooldown_until != 0:
			coin_refill_ad_cooldown_until = 0
			if persist:
				save_game()
			return true
		return false
	if coin_refill_ad_cooldown_until <= 0:
		coin_refill_ad_cooldown_until = _coin_refill_ad_now() + COIN_REFILL_AD_COOLDOWN_SECONDS
		if persist:
			save_game()
		return true
	if _coin_refill_ad_now() < coin_refill_ad_cooldown_until:
		return false
	coin_refill_ad_views_remaining = COIN_REFILL_AD_MAX_VIEWS
	coin_refill_ad_cooldown_until = 0
	if persist:
		save_game()
	return true

func get_soft_currency() -> int:
	soft_currency = maxi(soft_currency, 0)
	return soft_currency

func get_hearts() -> int:
	_apply_elapsed_heart_recovery(true)
	return clampi(hearts, 0, MAX_HEARTS)

func get_heart_recovery_seconds() -> int:
	_apply_elapsed_heart_recovery(true)
	if hearts >= MAX_HEARTS or heart_recovery_at <= 0:
		return 0
	return mini(maxi(heart_recovery_at - _heart_now(), 0), HEART_RECOVERY_SECONDS)

func lose_heart(persist: bool = true) -> bool:
	_apply_elapsed_heart_recovery(false)
	if hearts <= 0:
		_emit_heart_status_if_changed(true)
		return false
	var was_full: bool = hearts >= MAX_HEARTS
	hearts = maxi(hearts - 1, 0)
	if was_full or heart_recovery_at <= 0:
		heart_recovery_at = _heart_now() + HEART_RECOVERY_SECONDS
	if persist:
		save_game()
	_emit_heart_status_if_changed(true)
	return true

func refill_hearts(persist: bool = true) -> int:
	# A paid refill always restores the global inventory to exactly five lives.
	# Reset the recovery deadline as well: a full inventory must not keep a stale
	# countdown that could grant an extra life after the next one is spent.
	hearts = MAX_HEARTS
	heart_recovery_at = 0
	if persist:
		save_game()
	_emit_heart_status_if_changed(true)
	return hearts

func add_hearts(amount: int = 1, persist: bool = true) -> int:
	# Rewarded lives add to the current inventory instead of filling it outright.
	# Preserve an active recovery countdown unless the inventory becomes full.
	_apply_elapsed_heart_recovery(false)
	if amount <= 0 or hearts >= MAX_HEARTS:
		_emit_heart_status_if_changed(true)
		return clampi(hearts, 0, MAX_HEARTS)
	hearts = mini(hearts + amount, MAX_HEARTS)
	if hearts >= MAX_HEARTS:
		heart_recovery_at = 0
	elif heart_recovery_at <= 0:
		heart_recovery_at = _heart_now() + HEART_RECOVERY_SECONDS
	if persist:
		save_game()
	_emit_heart_status_if_changed(true)
	return hearts

func _heart_now() -> int:
	return int(floor(Time.get_unix_time_from_system()))

func _apply_elapsed_heart_recovery(persist: bool) -> bool:
	var now: int = _heart_now()
	var changed: bool = false
	hearts = clampi(hearts, 0, MAX_HEARTS)
	if hearts >= MAX_HEARTS:
		if heart_recovery_at != 0:
			heart_recovery_at = 0
			changed = true
	elif heart_recovery_at <= 0:
		heart_recovery_at = now + HEART_RECOVERY_SECONDS
		changed = true
	elif now >= heart_recovery_at:
		var restored_count: int = 1 + int((now - heart_recovery_at) / HEART_RECOVERY_SECONDS)
		hearts = mini(hearts + restored_count, MAX_HEARTS)
		if hearts >= MAX_HEARTS:
			heart_recovery_at = 0
		else:
			heart_recovery_at += restored_count * HEART_RECOVERY_SECONDS
		changed = true
	if changed and persist:
		save_game()
	return changed

func _emit_heart_status_if_changed(force: bool = false) -> void:
	var recovery_seconds: int = 0
	if hearts < MAX_HEARTS and heart_recovery_at > 0:
		recovery_seconds = mini(maxi(heart_recovery_at - _heart_now(), 0), HEART_RECOVERY_SECONDS)
	if (
		force
		or hearts != _last_emitted_hearts
		or recovery_seconds != _last_emitted_heart_seconds
	):
		_last_emitted_hearts = hearts
		_last_emitted_heart_seconds = recovery_seconds
		hearts_changed.emit(hearts, recovery_seconds)

func add_soft_currency(amount: int, persist: bool = true) -> int:
	if amount <= 0:
		return get_soft_currency()
	soft_currency = maxi(soft_currency + amount, 0)
	soft_currency_changed.emit(soft_currency)
	if persist:
		save_game()
	return soft_currency

func spend_soft_currency(amount: int, persist: bool = true) -> bool:
	if amount <= 0 or get_soft_currency() < amount:
		return false
	soft_currency -= amount
	soft_currency_changed.emit(soft_currency)
	if persist:
		save_game()
	return true

func get_hint_cost(hint_key: String) -> int:
	return maxi(int(HINT_COSTS.get(hint_key, 0)), 0)

func can_pay_for_hint(hint_key: String) -> bool:
	if get_hint_count(hint_key) > 0:
		return true
	var cost: int = get_hint_cost(hint_key)
	return cost > 0 and get_soft_currency() >= cost

func pay_for_hint(hint_key: String, persist: bool = true) -> int:
	var free_count: int = get_hint_count(hint_key)
	if free_count > 0:
		hint_counts[hint_key] = free_count - 1
		if persist:
			save_game()
		return HintPayment.FREE_HINT

	var cost: int = get_hint_cost(hint_key)
	if cost <= 0 or !spend_soft_currency(cost, persist):
		return HintPayment.FAILED
	return HintPayment.SOFT_CURRENCY

func reset_current_game() -> void:
	current_mode = GameMode.CLASSIC

func set_word_language(lang: String) -> void:
	word_language = _normalize_language(lang)
	save_game()

func _theme_progress_key(theme_index: int) -> String:
	var theme_id: int = Database.get_theme_id(theme_index)
	return str(theme_id) if theme_id > 0 else ""

func _word_progress_key(theme_index: int, word_index: int, word_text: String = "") -> String:
	var database_key: String = Database.get_word_progress_key(theme_index, word_index)
	if !database_key.is_empty():
		return database_key
	return Database.word_progress_key_from_text(word_text)

func _normalize_word_flag_dictionary(source: Variant) -> Dictionary:
	var result: Dictionary = {}
	if source is Dictionary:
		for key_variant: Variant in (source as Dictionary).keys():
			if bool((source as Dictionary).get(key_variant, false)):
				var key: String = str(key_variant).strip_edges()
				if !key.is_empty():
					result[key] = true
	return result

func _prune_word_flag_dictionary(source: Variant, theme_index: int) -> Dictionary:
	var normalized := _normalize_word_flag_dictionary(source)
	var allowed_keys: Dictionary = {}
	for key: String in Database.get_word_progress_keys(theme_index):
		if !key.is_empty():
			allowed_keys[key] = true
	for key_variant: Variant in normalized.keys():
		if !allowed_keys.has(str(key_variant)):
			normalized.erase(key_variant)
	return normalized

func ensure_theme_progress(lang: String, theme_index: int, _word_count: int) -> Dictionary:
	var lang_key := _normalize_language(lang)
	if !progress.has(lang_key) or !(progress[lang_key] is Dictionary):
		progress[lang_key] = {}
	var theme_key := _theme_progress_key(theme_index)
	if theme_key.is_empty():
		return {"played": {}, "guessed": {}}
	if !progress[lang_key].has(theme_key) or !(progress[lang_key][theme_key] is Dictionary):
		progress[lang_key][theme_key] = {"played": {}, "guessed": {}}
	var item: Dictionary = progress[lang_key][theme_key]
	item["played"] = _prune_word_flag_dictionary(item.get("played", {}), theme_index)
	item["guessed"] = _prune_word_flag_dictionary(item.get("guessed", {}), theme_index)
	progress[lang_key][theme_key] = item
	return item

func reset_theme_played_flags(lang: String, theme_index: int, persist: bool = true) -> void:
	var item := ensure_theme_progress(lang, theme_index, 0)
	item["played"] = {}
	if persist:
		save_game()

func mark_played(lang: String, theme_index: int, word_index: int, word_count: int, word_text: String = "", persist: bool = true) -> void:
	if theme_index < 0 or word_index < 0:
		return
	var key := _word_progress_key(theme_index, word_index, word_text)
	if key.is_empty():
		return
	var item := ensure_theme_progress(lang, theme_index, word_count)
	(item["played"] as Dictionary)[key] = true
	if persist:
		save_game()

func mark_guessed(lang: String, theme_index: int, word_index: int, word_count: int, word_text: String = "", persist: bool = true) -> void:
	if theme_index < 0 or word_index < 0:
		return
	var key := _word_progress_key(theme_index, word_index, word_text)
	if key.is_empty():
		return
	var item := ensure_theme_progress(lang, theme_index, word_count)
	(item["guessed"] as Dictionary)[key] = true
	if persist:
		save_game()

func clear_theme(lang: String, theme_index: int, word_count: int) -> void:
	var item := ensure_theme_progress(lang, theme_index, word_count)
	item["played"] = {}
	item["guessed"] = {}
	save_game()

func _new_single_player_bucket() -> Dictionary:
	return {
		"unlocked_level": 0,
		"adaptive_difficulty": SINGLE_PLAYER_DIFFICULTY_DEFAULT,
		"completed_attempts": 0,
		"failed_attempts": 0,
		"forfeited_attempts": 0,
		"levels": {},
		"selected_themes": {},
		"level_seeds": {},
		"theme_reroll_states": {},
		"word_stats": {},
		"level_question_slots": {},
		"level_question_ids": {},
		"question_stats": {},
	}

func _single_player_bucket(lang: String) -> Dictionary:
	var lang_key := _normalize_language(lang)
	if !single_player.has(lang_key) or !(single_player[lang_key] is Dictionary):
		single_player[lang_key] = _new_single_player_bucket()
	var bucket: Dictionary = single_player[lang_key]
	for dictionary_key in [
		"levels",
		"selected_themes",
		"level_seeds",
		"theme_reroll_states",
		"word_stats",
		"level_question_slots",
		"level_question_ids",
		"question_stats",
	]:
		if !bucket.has(dictionary_key) or !(bucket[dictionary_key] is Dictionary):
			bucket[dictionary_key] = {}
	if !bucket.has("unlocked_level"):
		bucket["unlocked_level"] = 0
	bucket["adaptive_difficulty"] = clampf(
		float(bucket.get("adaptive_difficulty", SINGLE_PLAYER_DIFFICULTY_DEFAULT)),
		SINGLE_PLAYER_DIFFICULTY_MIN,
		SINGLE_PLAYER_DIFFICULTY_MAX
	)
	for counter_key in ["completed_attempts", "failed_attempts", "forfeited_attempts"]:
		bucket[counter_key] = maxi(int(bucket.get(counter_key, 0)), 0)
	single_player[lang_key] = bucket
	return bucket

func _single_player_progress_bucket(lang: String, _difficulty: int = -1) -> Dictionary:
	return _single_player_bucket(lang)

func ensure_single_player_theme_progress(lang: String, theme_index: int, _word_count: int) -> Dictionary:
	var lang_key := _normalize_language(lang)
	var bucket := _single_player_bucket(lang_key)
	var word_stats: Dictionary = bucket["word_stats"]
	var theme_key := _theme_progress_key(theme_index)
	if theme_key.is_empty():
		return {"played": {}, "guessed": {}}
	if !word_stats.has(theme_key) or !(word_stats[theme_key] is Dictionary):
		word_stats[theme_key] = {"played": {}, "guessed": {}}
	var item: Dictionary = word_stats[theme_key]
	item["played"] = _prune_word_flag_dictionary(item.get("played", {}), theme_index)
	item["guessed"] = _prune_word_flag_dictionary(item.get("guessed", {}), theme_index)
	word_stats[theme_key] = item
	bucket["word_stats"] = word_stats
	single_player[lang_key] = bucket
	return item

func mark_single_player_word_shown(lang: String, theme_index: int, word_index: int, word_count: int, word_text: String = "", persist: bool = true) -> void:
	if theme_index < 0 or word_index < 0:
		return
	var key := _word_progress_key(theme_index, word_index, word_text)
	if key.is_empty():
		return
	var item := ensure_single_player_theme_progress(lang, theme_index, word_count)
	(item["played"] as Dictionary)[key] = true
	if persist:
		save_game()

func mark_single_player_word_guessed(lang: String, theme_index: int, word_index: int, word_count: int, word_text: String = "", persist: bool = true) -> void:
	if theme_index < 0 or word_index < 0:
		return
	var key := _word_progress_key(theme_index, word_index, word_text)
	if key.is_empty():
		return
	var item := ensure_single_player_theme_progress(lang, theme_index, word_count)
	(item["guessed"] as Dictionary)[key] = true
	if persist:
		save_game()

func get_single_level_question_slot(lang: String, level_index: int) -> int:
	if level_index < 0:
		return -1
	var bucket := _single_player_bucket(lang)
	var slots: Dictionary = bucket["level_question_slots"]
	return int(slots.get(str(level_index), -1))

func set_single_level_question_slot(lang: String, level_index: int, question_slot: int, persist: bool = true) -> void:
	if level_index < 0 or question_slot < 0:
		return
	var lang_key := _normalize_language(lang)
	var bucket := _single_player_bucket(lang_key)
	var slots: Dictionary = bucket["level_question_slots"]
	slots[str(level_index)] = question_slot
	bucket["level_question_slots"] = slots
	single_player[lang_key] = bucket
	if persist:
		save_game()

func get_single_level_question_id(lang: String, level_index: int) -> int:
	if level_index < 0:
		return -1
	var bucket := _single_player_bucket(lang)
	var question_ids: Dictionary = bucket["level_question_ids"]
	return int(question_ids.get(str(level_index), -1))

func set_single_level_question_id(lang: String, level_index: int, question_id: int, persist: bool = true) -> void:
	if level_index < 0 or question_id < 0:
		return
	var lang_key := _normalize_language(lang)
	var bucket := _single_player_bucket(lang_key)
	var question_ids: Dictionary = bucket["level_question_ids"]
	question_ids[str(level_index)] = question_id
	bucket["level_question_ids"] = question_ids
	single_player[lang_key] = bucket
	if persist:
		save_game()

func _single_player_question_theme_stats(lang: String, theme_index: int) -> Dictionary:
	var lang_key := _normalize_language(lang)
	var bucket := _single_player_bucket(lang_key)
	var question_stats: Dictionary = bucket["question_stats"]
	var theme_key := _theme_progress_key(theme_index)
	if !question_stats.has(theme_key) or !(question_stats[theme_key] is Dictionary):
		question_stats[theme_key] = {"seen": {}}
	var theme_stats: Dictionary = question_stats[theme_key]
	if !theme_stats.has("seen") or !(theme_stats["seen"] is Dictionary):
		theme_stats["seen"] = {}
	question_stats[theme_key] = theme_stats
	bucket["question_stats"] = question_stats
	single_player[lang_key] = bucket
	return theme_stats

func has_single_player_question_been_seen(lang: String, theme_index: int, question_id: int) -> bool:
	if theme_index < 0 or question_id < 0:
		return false
	var theme_stats := _single_player_question_theme_stats(lang, theme_index)
	var seen: Dictionary = theme_stats["seen"]
	return bool(seen.get(str(question_id), false))

func mark_single_player_question_seen(lang: String, theme_index: int, question_id: int, persist: bool = true) -> void:
	if theme_index < 0 or question_id < 0:
		return
	var lang_key := _normalize_language(lang)
	var theme_key := _theme_progress_key(theme_index)
	var theme_stats: Dictionary = _single_player_question_theme_stats(lang_key, theme_index)
	var seen: Dictionary = theme_stats["seen"]
	if bool(seen.get(str(question_id), false)):
		return
	seen[str(question_id)] = true
	theme_stats["seen"] = seen
	var bucket := _single_player_bucket(lang_key)
	var question_stats: Dictionary = bucket["question_stats"]
	question_stats[theme_key] = theme_stats
	bucket["question_stats"] = question_stats
	single_player[lang_key] = bucket
	if persist:
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

func has_single_level_seed(lang: String, level_index: int, _difficulty: int = -1) -> bool:
	if level_index < 0:
		return false
	var lang_key := _normalize_language(lang)
	var bucket := _single_player_bucket(lang_key)
	var level_seeds: Dictionary = bucket["level_seeds"]
	return maxi(int(level_seeds.get(str(level_index), 0)), 0) > 0

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
	return Database.get_theme_index_by_id(int(selected_themes.get(str(level_index), -1)))

func get_single_level_theme_reroll_state(lang: String, level_index: int) -> int:
	if level_index < 0:
		return SINGLE_LEVEL_THEME_REROLL_AVAILABLE
	var bucket := _single_player_bucket(lang)
	var reroll_states: Dictionary = bucket["theme_reroll_states"]
	return clampi(
		int(reroll_states.get(str(level_index), SINGLE_LEVEL_THEME_REROLL_AVAILABLE)),
		SINGLE_LEVEL_THEME_REROLL_AVAILABLE,
		SINGLE_LEVEL_THEME_REROLL_AD_USED
	)

func set_single_level_theme_reroll_state(lang: String, level_index: int, state: int, persist: bool = true) -> void:
	if level_index < 0:
		return
	var lang_key := _normalize_language(lang)
	var bucket := _single_player_bucket(lang_key)
	var reroll_states: Dictionary = bucket["theme_reroll_states"]
	var level_key := str(level_index)
	var resolved_state := clampi(
		state,
		SINGLE_LEVEL_THEME_REROLL_AVAILABLE,
		SINGLE_LEVEL_THEME_REROLL_AD_USED
	)
	if resolved_state == SINGLE_LEVEL_THEME_REROLL_AVAILABLE:
		reroll_states.erase(level_key)
	else:
		reroll_states[level_key] = resolved_state
	bucket["theme_reroll_states"] = reroll_states
	single_player[lang_key] = bucket
	if persist:
		save_game()

func select_single_level_theme(lang: String, level_index: int, theme_index: int, word_count: int, _difficulty: int = -1) -> void:
	if level_index < 0 or theme_index < 0:
		return
	var lang_key := _normalize_language(lang)
	var bucket := _single_player_bucket(lang_key)
	var level_key := str(level_index)
	var selected_themes: Dictionary = bucket["selected_themes"]
	if Database.get_theme_index_by_id(int(selected_themes.get(level_key, -1))) >= 0:
		return
	selected_themes[level_key] = Database.get_theme_id(theme_index)
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
	return is_single_level_perfect(lang, level_index, word_count, difficulty)

func is_single_level_perfect(lang: String, level_index: int, word_count: int, difficulty: int = -1) -> bool:
	if word_count <= 0:
		return false
	return get_single_level_guessed_count(lang, level_index, word_count, difficulty) >= word_count

func is_single_level_failed(lang: String, level_index: int, word_count: int, difficulty: int = -1) -> bool:
	var statuses := ensure_single_level_progress(lang, level_index, word_count, difficulty)
	for status in statuses:
		if _single_level_status(status) == 2:
			return true
	return false

func get_single_player_unlocked_level(lang: String, difficulty: int = -1) -> int:
	var progress_bucket := _single_player_progress_bucket(lang, difficulty)
	return maxi(int(progress_bucket.get("unlocked_level", 0)), 0)

func ensure_single_player_next_level_unlocked(lang: String, completed_level_index: int) -> void:
	if completed_level_index < 0:
		return
	var lang_key := _normalize_language(lang)
	var bucket := _single_player_bucket(lang_key)
	if completed_level_index < int(bucket.get("unlocked_level", 0)):
		return
	bucket["unlocked_level"] = completed_level_index + 1
	single_player[lang_key] = bucket
	save_game()

func get_single_player_adaptive_difficulty(lang: String) -> float:
	var bucket := _single_player_bucket(lang)
	return clampf(
		float(bucket.get("adaptive_difficulty", SINGLE_PLAYER_DIFFICULTY_DEFAULT)),
		SINGLE_PLAYER_DIFFICULTY_MIN,
		SINGLE_PLAYER_DIFFICULTY_MAX
	)

func _single_player_level_completion_bonus(word_count: int) -> int:
	return SINGLE_PLAYER_LEVEL_BASE_BONUS_COINS + maxi(word_count, 0) * SINGLE_PLAYER_LEVEL_WORD_BONUS_COINS

func mark_single_level_word_played(
	lang: String,
	level_index: int,
	word_slot: int,
	word_count: int,
	is_win: bool,
	failure_affects_difficulty: bool = true,
	difficulty: int = -1,
	award_completion_bonus: bool = true,
	persist: bool = true
) -> Dictionary:
	var statuses := ensure_single_level_progress(lang, level_index, word_count, difficulty)
	var was_unplayed: bool = word_slot >= 0 and word_slot < statuses.size() and _single_level_status(statuses[word_slot]) == 0
	if word_slot >= 0 and word_slot < statuses.size():
		statuses[word_slot] = 1 if is_win else 2
	var completed: bool = is_single_level_completed(lang, level_index, word_count, difficulty)
	var perfect: bool = is_single_level_perfect(lang, level_index, word_count, difficulty)
	var failed: bool = is_single_level_failed(lang, level_index, word_count, difficulty)
	var unlocked_next: bool = false
	var completion_bonus: int = 0
	var lang_key := _normalize_language(lang)
	var bucket := _single_player_bucket(lang_key)
	var unlocked_level: int = int(bucket.get("unlocked_level", 0))
	var difficulty_before: float = get_single_player_adaptive_difficulty(lang_key)
	var difficulty_after: float = difficulty_before
	if was_unplayed and is_win and completed:
		difficulty_after = clampf(
			difficulty_before + SINGLE_PLAYER_SUCCESS_DIFFICULTY_STEP,
			SINGLE_PLAYER_DIFFICULTY_MIN,
			SINGLE_PLAYER_DIFFICULTY_MAX
		)
		bucket["adaptive_difficulty"] = difficulty_after
		bucket["completed_attempts"] = int(bucket.get("completed_attempts", 0)) + 1
		completion_bonus = _single_player_level_completion_bonus(word_count)
		if award_completion_bonus:
			add_soft_currency(completion_bonus, false)
	elif was_unplayed and !is_win:
		if failure_affects_difficulty:
			difficulty_after = clampf(
				difficulty_before - SINGLE_PLAYER_FAILURE_DIFFICULTY_STEP,
				SINGLE_PLAYER_DIFFICULTY_MIN,
				SINGLE_PLAYER_DIFFICULTY_MAX
			)
			bucket["adaptive_difficulty"] = difficulty_after
			bucket["failed_attempts"] = int(bucket.get("failed_attempts", 0)) + 1
		else:
			bucket["forfeited_attempts"] = int(bucket.get("forfeited_attempts", 0)) + 1
	if completed and level_index >= unlocked_level:
		bucket["unlocked_level"] = level_index + 1
		unlocked_next = true
	single_player[lang_key] = bucket
	if was_unplayed and is_win and completed and !award_completion_bonus:
		var selected_theme_id: int = int(
			(bucket["selected_themes"] as Dictionary).get(str(level_index), 0)
		)
		_create_pending_single_player_reward(
			lang_key,
			level_index,
			word_slot,
			word_count,
			selected_theme_id,
			WORD_REWARD_COINS + completion_bonus
		)
	if persist:
		save_game()
	return {
		"completed": completed,
		"perfect": perfect,
		"failed": failed,
		"chain_ended": completed or failed,
		"played_count": get_single_level_played_count(lang, level_index, word_count, difficulty),
		"guessed_count": get_single_level_guessed_count(lang, level_index, word_count, difficulty),
		"unlocked_next": unlocked_next,
		"unlocked_level": get_single_player_unlocked_level(lang, difficulty),
		"completion_bonus": completion_bonus,
		"difficulty_before": difficulty_before,
		"difficulty_after": difficulty_after,
	}

func record_single_player_forfeit(lang: String, persist: bool = true) -> void:
	var lang_key := _normalize_language(lang)
	var bucket := _single_player_bucket(lang_key)
	bucket["forfeited_attempts"] = int(bucket.get("forfeited_attempts", 0)) + 1
	single_player[lang_key] = bucket
	if persist:
		save_game()

func reset_single_level_attempt(
	lang: String,
	level_index: int,
	reroll_seed: bool = true,
	clear_theme_reroll_state: bool = true,
	persist: bool = true
) -> void:
	if level_index < 0:
		return
	var lang_key := _normalize_language(lang)
	var bucket := _single_player_bucket(lang_key)
	var level_key := str(level_index)
	var levels: Dictionary = bucket["levels"]
	var selected_themes: Dictionary = bucket["selected_themes"]
	var level_seeds: Dictionary = bucket["level_seeds"]
	var theme_reroll_states: Dictionary = bucket["theme_reroll_states"]
	var level_question_slots: Dictionary = bucket["level_question_slots"]
	var level_question_ids: Dictionary = bucket["level_question_ids"]
	levels.erase(level_key)
	selected_themes.erase(level_key)
	level_question_slots.erase(level_key)
	level_question_ids.erase(level_key)
	if reroll_seed:
		level_seeds.erase(level_key)
	if clear_theme_reroll_state:
		theme_reroll_states.erase(level_key)
	bucket["levels"] = levels
	bucket["selected_themes"] = selected_themes
	bucket["level_seeds"] = level_seeds
	bucket["theme_reroll_states"] = theme_reroll_states
	bucket["level_question_slots"] = level_question_slots
	bucket["level_question_ids"] = level_question_ids
	single_player[lang_key] = bucket
	if (
		_normalize_language(str(active_single_player_session.get("language", lang_key))) == lang_key
		and int(active_single_player_session.get("level_index", -1)) == level_index
	):
		active_single_player_session = {}
	if persist:
		save_game()
