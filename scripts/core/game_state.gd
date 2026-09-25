extends Node

const BUILD_TRACE: GDScript = preload("res://scripts/ui/home_transition_trace.gd")

const GAME_DESIGN: GDScript = preload("res://scripts/core/game_design_config.gd")

signal ads_became_available
signal ad_personalization_choice_changed

signal soft_currency_changed(balance: int)
signal stars_changed(balance: int)
signal hearts_changed(hearts: int, recovery_seconds: int)

const SAVE_PATH := "user://save_hangman.json"
const SAVE_TMP_PATH := "user://save_hangman.tmp"
const SAVE_BACKUP_PATH := "user://save_hangman.bak"
const SAVE_FORMAT_VERSION: int = 2
# Content aliases change independently of the word difficulty model version.
const WORD_PROGRESS_ALIAS_REVISION: int = 4
const LEGAL_DOCUMENTS_VERSION: int = 1
const SINGLE_PLAYER_LEVEL_HISTORY_LIMIT: int = 64
const SINGLE_PLAYER_MAX_SAVED_LEVEL_SLOTS: int = 16
const HINT_OPEN_LETTER: String = "open_letter"
const HINT_REMOVE_WRONG: String = "remove_wrong"
const HINT_COMMENT: String = "comment"
const HINT_QUIZ_FIFTY_FIFTY: String = "quiz_fifty_fifty"
const HINT_QUIZ_REPLACE_QUESTION: String = "quiz_replace_question"
var DEFAULT_HINT_COUNT: int = GAME_DESIGN.get_int("economy.hints.starting_count", 3)
var DEFAULT_SOFT_CURRENCY: int = GAME_DESIGN.get_int("economy.starting_coins", 100)
var DEFAULT_STARS: int = GAME_DESIGN.get_int("economy.starting_stars", 0)
var MAX_CURRENCY_BALANCE: int = GAME_DESIGN.get_int_range(
	"economy.maximum_balance", 2_000_000_000, 1, 2_000_000_000
)
var MAX_SINGLE_REWARD: int = GAME_DESIGN.get_int_range(
	"economy.maximum_single_reward", 1_000_000_000, 1, MAX_CURRENCY_BALANCE
)
var MAX_HEARTS: int = GAME_DESIGN.get_int_range("economy.hearts.maximum", 5, 1, 1000)
var HEART_RECOVERY_SECONDS: int = GAME_DESIGN.get_int_range(
	"economy.hearts.recovery_seconds", 300, 1, 31536000
)
var HEART_STATE_POLL_SECONDS: float = GAME_DESIGN.get_float_range(
	"timings.heart_state_poll_seconds", 1.0, 0.05, 60.0
)
var WORD_REWARD_COINS: int = GAME_DESIGN.get_int("economy.rewards.word_coins", 10)
var QUIZ_STAGE_REWARD_COIN_MULTIPLIER: float = GAME_DESIGN.get_float_range(
	"economy.rewards.quiz_stage_coin_multiplier", 1.0, 0.0, 100.0
)
const STAGE_REWARD_COINS: String = "coins"
const STAGE_REWARD_STARS: String = "stars"
var COIN_REFILL_AD_MAX_VIEWS: int = GAME_DESIGN.get_int_range(
	"economy.coin_refill_ad.maximum_views", 5, 1, 1000
)
var COIN_REFILL_AD_COOLDOWN_SECONDS: int = GAME_DESIGN.get_int(
	"economy.coin_refill_ad.cooldown_seconds", 18000
)
var ADS_UNLOCK_LEVEL: int = GAME_DESIGN.get_int_range(
	"advertising.unlock_level", 3, 1, 1_000_000
)
var INTERSTITIAL_INTERVAL_SECONDS: float = GAME_DESIGN.get_float_range(
	"advertising.interstitial_interval_seconds", 300.0, 1.0, 86_400.0
)
var SINGLE_PLAYER_DIFFICULTY_DEFAULT: float = GAME_DESIGN.get_float_range(
	"difficulty.default", 0.18, 0.0, 1.0
)
var SINGLE_PLAYER_DIFFICULTY_MIN: float = GAME_DESIGN.get_float_range(
	"difficulty.minimum", 0.08, 0.0, 1.0
)
var SINGLE_PLAYER_DIFFICULTY_MAX: float = GAME_DESIGN.get_float_range(
	"difficulty.maximum", 0.86, 0.0, 1.0
)
var SINGLE_PLAYER_LEVEL_COMPLETION_BASE_COINS: int = GAME_DESIGN.get_int(
	"economy.rewards.level_completion_base_coins", 25
)
var SINGLE_PLAYER_LEVEL_COMPLETION_PER_WIN_COINS: int = GAME_DESIGN.get_int(
	"economy.rewards.level_completion_per_win_coins", 10
)
var SINGLE_PLAYER_CHALLENGE_LEVEL_COMPLETION_BASE_COINS: int = GAME_DESIGN.get_int(
	"economy.rewards.challenge_level_completion_base_coins", 50
)
var SINGLE_PLAYER_CHALLENGE_LEVEL_COMPLETION_PER_WIN_COINS: int = GAME_DESIGN.get_int(
	"economy.rewards.challenge_level_completion_per_win_coins", 20
)
var SINGLE_PLAYER_LEVEL_COMPLETION_BASE_STARS: int = GAME_DESIGN.get_int(
	"economy.rewards.level_completion_base_stars", 10
)
var SINGLE_PLAYER_LEVEL_COMPLETION_PER_WIN_STARS: int = GAME_DESIGN.get_int(
	"economy.rewards.level_completion_per_win_stars", 2
)
var SINGLE_PLAYER_CHALLENGE_LEVEL_COMPLETION_BASE_STARS: int = GAME_DESIGN.get_int(
	"economy.rewards.challenge_level_completion_base_stars", 15
)
var SINGLE_PLAYER_CHALLENGE_LEVEL_COMPLETION_PER_WIN_STARS: int = GAME_DESIGN.get_int(
	"economy.rewards.challenge_level_completion_per_win_stars", 3
)
const SINGLE_LEVEL_THEME_REROLL_AVAILABLE: int = 0
const SINGLE_LEVEL_THEME_REROLL_COIN_USED: int = 1
const SINGLE_LEVEL_THEME_REROLL_AD_USED: int = 2
var HINT_COSTS: Dictionary = {
	HINT_OPEN_LETTER: GAME_DESIGN.get_int("economy.hints.costs.open_letter", 20),
	HINT_REMOVE_WRONG: GAME_DESIGN.get_int("economy.hints.costs.remove_wrong", 15),
	HINT_COMMENT: GAME_DESIGN.get_int("economy.hints.costs.comment", 10),
	HINT_QUIZ_FIFTY_FIFTY: GAME_DESIGN.get_int("economy.hints.costs.quiz_fifty_fifty", 20),
	HINT_QUIZ_REPLACE_QUESTION: GAME_DESIGN.get_int("economy.hints.costs.quiz_replace_question", 20),
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

enum AdPersonalizationChoice {
	UNKNOWN,
	ACCEPTED,
	DENIED,
}

var interface_language: String = "ru"
var word_language: String = "ru"
var player_name: String = ""
var soft_currency: int = DEFAULT_SOFT_CURRENCY
var stars: int = DEFAULT_STARS
var hearts: int = MAX_HEARTS
var heart_recovery_at: int = 0
var coin_refill_ad_views_remaining: int = COIN_REFILL_AD_MAX_VIEWS
var coin_refill_ad_cooldown_until: int = 0
var heart_refill_ad_views_remaining: int = COIN_REFILL_AD_MAX_VIEWS
var heart_refill_ad_cooldown_until: int = 0
var extra_attempt_ad_views_remaining: int = COIN_REFILL_AD_MAX_VIEWS
var extra_attempt_ad_cooldown_until: int = 0
var ads_unlocked: bool = false
var guided_onboarding_completed: bool = false
var interstitial_active_elapsed_seconds: float = 0.0
var accepted_legal_documents_version: int = 0
var ad_personalization_choice: int = AdPersonalizationChoice.UNKNOWN
# Explicit choice is persistent; region permission is valid only for this lookup.
var ad_personalization_choice_at: int = 0
var ad_personalization_choice_source: String = ""
var ad_region_country: String = ""
var ad_region_rule: String = "unknown"
var ad_region_policy_version: String = ""
var ad_region_checked_at: int = 0
var _heart_tick_timer: Timer = null
var _last_emitted_hearts: int = -1
var _last_emitted_heart_seconds: int = -1
var _app_in_foreground: bool = true
var _fullscreen_ad_active: bool = false

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
# Resumable level UI/state is independent for each word-base language. The two
# legacy current-state fields below remain the working slot used by gameplay;
# `single_player_resume_states` preserves the inactive language while the player
# switches between RU and EN from Settings.
var single_player_resume_states: Dictionary = {}
var active_single_player_session: Dictionary = {}
var pending_single_player_reward: Dictionary = {}
var rewarded_double_requests: Dictionary = {}
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
	_normalize_game_design_values()
	load_game()
	_heart_tick_timer = Timer.new()
	_heart_tick_timer.name = "HeartRecoveryTick"
	_heart_tick_timer.wait_time = HEART_STATE_POLL_SECONDS
	_heart_tick_timer.one_shot = false
	_heart_tick_timer.timeout.connect(_on_heart_tick)
	add_child(_heart_tick_timer)
	_heart_tick_timer.start()
	_emit_heart_status_if_changed(true)
	_sync_interstitial_process_state()

func _process(delta: float) -> void:
	interstitial_active_elapsed_seconds = minf(
		interstitial_active_elapsed_seconds + maxf(delta, 0.0),
		INTERSTITIAL_INTERVAL_SECONDS
	)
	if interstitial_active_elapsed_seconds >= INTERSTITIAL_INTERVAL_SECONDS:
		set_process(false)

func _sync_interstitial_process_state() -> void:
	# The interstitial cooldown is the only state that needs an idle callback.
	# Stop dispatching `_process` while ads are locked, the application is paused,
	# a fullscreen ad is visible, or the cooldown has already completed.
	set_process(
		ads_unlocked
		and _app_in_foreground
		and !_fullscreen_ad_active
		and interstitial_active_elapsed_seconds < INTERSTITIAL_INTERVAL_SECONDS
	)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			_app_in_foreground = false
			_sync_interstitial_process_state()
			save_game()
		NOTIFICATION_APPLICATION_RESUMED:
			_app_in_foreground = true
			_sync_interstitial_process_state()

func activate_ads_for_level(level_index: int, persist: bool = true) -> bool:
	if ads_unlocked or level_index + 1 < ADS_UNLOCK_LEVEL:
		return ads_unlocked
	ads_unlocked = true
	interstitial_active_elapsed_seconds = 0.0
	_sync_interstitial_process_state()
	if persist:
		save_game()
	ads_became_available.emit()
	return true

func is_single_player_guided_onboarding_completed() -> bool:
	return guided_onboarding_completed

func complete_single_player_guided_onboarding(persist: bool = true) -> bool:
	# Onboarding is profile-wide: once completed in either language, starting
	# level 3 in the other campaign must not mutate that campaign's resume state.
	if guided_onboarding_completed:
		return false
	guided_onboarding_completed = true
	# Clear only the transient guided theme snapshot of the language that is
	# completing onboarding. The other language is an independent campaign and
	# may legitimately have its own unfinished theme-selection state.
	_clear_guided_theme_resume_state_for_language(word_language)
	if persist:
		save_game()
	return true

func are_ads_enabled() -> bool:
	return ads_unlocked

func is_interstitial_ready() -> bool:
	return (
		ads_unlocked
		and interstitial_active_elapsed_seconds >= INTERSTITIAL_INTERVAL_SECONDS
	)

func reset_interstitial_timer(persist: bool = true) -> void:
	if !ads_unlocked:
		return
	interstitial_active_elapsed_seconds = 0.0
	_sync_interstitial_process_state()
	if persist:
		save_game()

func set_fullscreen_ad_active(active: bool) -> void:
	_fullscreen_ad_active = active
	_sync_interstitial_process_state()

func _normalize_game_design_values() -> void:
	SINGLE_PLAYER_DIFFICULTY_MAX = maxf(
		SINGLE_PLAYER_DIFFICULTY_MAX,
		SINGLE_PLAYER_DIFFICULTY_MIN
	)
	SINGLE_PLAYER_DIFFICULTY_DEFAULT = clampf(
		SINGLE_PLAYER_DIFFICULTY_DEFAULT,
		SINGLE_PLAYER_DIFFICULTY_MIN,
		SINGLE_PLAYER_DIFFICULTY_MAX
	)
	soft_currency = clampi(soft_currency, 0, MAX_CURRENCY_BALANCE)
	stars = clampi(stars, 0, MAX_CURRENCY_BALANCE)
	hearts = clampi(hearts, 0, MAX_HEARTS)
	coin_refill_ad_views_remaining = clampi(
		coin_refill_ad_views_remaining,
		0,
		COIN_REFILL_AD_MAX_VIEWS
	)

func _on_heart_tick() -> void:
	_apply_elapsed_heart_recovery(true)
	_emit_heart_status_if_changed()

func load_game() -> void:
	_set_interface_language_from_locale()
	word_language = interface_language
	var parsed: Dictionary = _read_save_dictionary(SAVE_PATH)
	var loaded_from_recovery: bool = false
	var stored_version: int = int(parsed.get("save_version", -1))
	if stored_version > SAVE_FORMAT_VERSION:
		_save_blocked_by_future_version = true
		push_warning("Ignoring incompatible save format: %d" % stored_version)
		return
	if parsed.is_empty() or stored_version != SAVE_FORMAT_VERSION:
		# A crash between removal and rename can leave the newest complete save
		# in .tmp. Prefer it to the older backup, but never to a valid primary.
		for recovery_path: String in [SAVE_TMP_PATH, SAVE_BACKUP_PATH]:
			var recovered: Dictionary = _read_save_dictionary(recovery_path)
			if int(recovered.get("save_version", -1)) == SAVE_FORMAT_VERSION:
				parsed = recovered
				loaded_from_recovery = true
				break
		if !loaded_from_recovery:
			return

	word_language = _normalize_language(str(parsed.get("word_language", word_language)))
	accepted_legal_documents_version = maxi(
		int(parsed.get("accepted_legal_documents_version", 0)),
		0
	)
	ad_personalization_choice = clampi(
		int(parsed.get("ad_personalization_choice", AdPersonalizationChoice.UNKNOWN)),
		AdPersonalizationChoice.UNKNOWN,
		AdPersonalizationChoice.DENIED
	)

	ad_personalization_choice_at = maxi(int(parsed.get("ad_personalization_choice_at", 0)), 0)
	ad_personalization_choice_source = (
		str(parsed.get("ad_personalization_choice_source", "legacy_user"))
		if has_answered_ad_personalization_choice() else ""
	)
	# Never restore a previous IP lookup as permission on a new launch.

	# Every section is normalized independently. One malformed optional field must
	# never discard an otherwise valid profile or restore economy defaults.
	player_name = str(parsed.get("player_name", "")).strip_edges().left(35)
	soft_currency = clampi(int(parsed.get("soft_currency", DEFAULT_SOFT_CURRENCY)), 0, MAX_CURRENCY_BALANCE)
	stars = clampi(int(parsed.get("stars", DEFAULT_STARS)), 0, MAX_CURRENCY_BALANCE)
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
	var legacy_active_session: Dictionary = _normalize_active_single_player_session(
		parsed.get("active_single_player_session", {})
	)
	var legacy_pending_reward: Dictionary = _normalize_pending_single_player_reward(
		parsed.get("pending_single_player_reward", {})
	)
	single_player_resume_states = _normalize_single_player_resume_states(
		parsed.get("single_player_resume_states", {})
	)
	_merge_legacy_single_player_resume_state(legacy_active_session, legacy_pending_reward)
	_restore_single_player_resume_state(word_language)
	_load_rewarded_double_requests(parsed.get("rewarded_double_requests", {}))
	_load_hint_counts_from_save(parsed)
	_load_hearts_from_save(parsed)
	_load_coin_refill_ad_state_from_save(parsed)
	_load_heart_refill_ad_state_from_save(parsed)
	_load_extra_attempt_ad_state_from_save(parsed)
	ads_unlocked = bool(parsed.get("ads_unlocked", false))
	var guided_state_was_missing: bool = !parsed.has("guided_onboarding_completed")
	# Existing development saves already record the real start of level 3 by
	# unlocking ads. Reuse that durable fact to repair the old forced-popup state.
	guided_onboarding_completed = bool(parsed.get(
		"guided_onboarding_completed",
		ads_unlocked
	))
	interstitial_active_elapsed_seconds = clampf(
		float(parsed.get("interstitial_active_elapsed_seconds", 0.0)),
		0.0,
		INTERSTITIAL_INTERVAL_SECONDS
	)
	_normalize_single_player_buckets()

	if loaded_from_recovery or guided_state_was_missing:
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
	# JSON.parse_string already owns a fresh tree. The load normalizers copy the
	# sections they retain; validation of temporary/backup saves needs no copy.
	return parsed

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
		# A malformed save must not refill a spent inventory. A genuinely new player
		# keeps DEFAULT_HINT_COUNT because load_game() returns when no save exists.
		for hint_key in HINT_COSTS.keys():
			hint_counts[hint_key] = 0
		return

	for hint_key in HINT_COSTS.keys():
		hint_counts[hint_key] = maxi(int(stored_counts.get(hint_key, 0)), 0)

func _load_hearts_from_save(parsed: Dictionary) -> void:
	# Restore the absolute recovery deadline so regeneration continues while the
	# app is closed.
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

func _load_heart_refill_ad_state_from_save(parsed: Dictionary) -> void:
	heart_refill_ad_views_remaining = clampi(
		int(parsed.get("heart_refill_ad_views_remaining", COIN_REFILL_AD_MAX_VIEWS)),
		0,
		COIN_REFILL_AD_MAX_VIEWS
	)
	heart_refill_ad_cooldown_until = maxi(
		int(parsed.get("heart_refill_ad_cooldown_until", 0)),
		0
	)
	_refresh_heart_refill_ad_cooldown(false)

func _load_extra_attempt_ad_state_from_save(parsed: Dictionary) -> void:
	extra_attempt_ad_views_remaining = clampi(
		int(parsed.get("extra_attempt_ad_views_remaining", COIN_REFILL_AD_MAX_VIEWS)),
		0,
		COIN_REFILL_AD_MAX_VIEWS
	)
	extra_attempt_ad_cooldown_until = maxi(
		int(parsed.get("extra_attempt_ad_cooldown_until", 0)),
		0
	)
	_refresh_extra_attempt_ad_cooldown(false)

func _set_interface_language_from_locale() -> void:
	# The interface follows the device on every launch: Russian only for a
	# Russian locale, English for Ukrainian and every other locale.
	var locale: String = OS.get_locale().to_lower()
	interface_language = "ru" if locale.begins_with("ru") else "en"

func _normalize_language(lang: String) -> String:
	return "ru" if lang.to_lower().begins_with("ru") else "en"

func save_game() -> bool:
	var profile_started_usec: int = BUILD_TRACE.section_start()
	var profile_result: bool = _home_profile_save_game()
	BUILD_TRACE.section_end(&"save.total", profile_started_usec)
	return profile_result

func _home_profile_save_game() -> bool:
	if _save_blocked_by_future_version or _save_write_in_progress:
		return false
	_save_write_in_progress = true
	_compact_single_player_history()
	_store_current_single_player_resume_state()
	var payload: Dictionary = {
		"save_version": SAVE_FORMAT_VERSION,
		"word_language": word_language,
		"player_name": player_name,
		"settings": settings,
		"records": records,
		"progress": progress,
		"single_player": single_player,
		"single_player_resume_states": single_player_resume_states,
		"active_single_player_session": active_single_player_session,
		"pending_single_player_reward": pending_single_player_reward,
		"rewarded_double_requests": rewarded_double_requests,
		"hint_counts": hint_counts,
		"soft_currency": soft_currency,
		"stars": stars,
		"hearts": hearts,
		"heart_recovery_at": heart_recovery_at,
		"coin_refill_ad_views_remaining": coin_refill_ad_views_remaining,
		"coin_refill_ad_cooldown_until": coin_refill_ad_cooldown_until,
		"heart_refill_ad_views_remaining": heart_refill_ad_views_remaining,
		"heart_refill_ad_cooldown_until": heart_refill_ad_cooldown_until,
		"extra_attempt_ad_views_remaining": extra_attempt_ad_views_remaining,
		"extra_attempt_ad_cooldown_until": extra_attempt_ad_cooldown_until,
		"ads_unlocked": ads_unlocked,
		"guided_onboarding_completed": guided_onboarding_completed,
		"interstitial_active_elapsed_seconds": interstitial_active_elapsed_seconds,
		"accepted_legal_documents_version": accepted_legal_documents_version,
		"ad_personalization_choice": ad_personalization_choice,
		"ad_personalization_choice_at": ad_personalization_choice_at,
		"ad_personalization_choice_source": ad_personalization_choice_source,
		"ad_region_last_observation": {
			"country": ad_region_country,
			"rule": ad_region_rule,
			"policy_version": ad_region_policy_version,
			"checked_at": ad_region_checked_at,
		},
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
	if int(_read_save_dictionary(SAVE_PATH).get("save_version", -1)) == SAVE_FORMAT_VERSION:
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

func has_accepted_legal_documents() -> bool:
	return accepted_legal_documents_version >= LEGAL_DOCUMENTS_VERSION

func accept_legal_documents() -> bool:
	if has_accepted_legal_documents():
		return true
	var previous_version: int = accepted_legal_documents_version
	accepted_legal_documents_version = LEGAL_DOCUMENTS_VERSION
	if save_game():
		return true
	accepted_legal_documents_version = previous_version
	return false

func has_answered_ad_personalization_choice() -> bool:
	return ad_personalization_choice != AdPersonalizationChoice.UNKNOWN

func allows_ad_personalization() -> bool:
	if has_answered_ad_personalization_choice():
		return ad_personalization_choice == AdPersonalizationChoice.ACCEPTED
	return ad_region_rule == "automatic"

func has_ad_personalization_decision() -> bool:
	return has_answered_ad_personalization_choice() or ad_region_rule == "automatic"

func needs_ad_personalization_consent() -> bool:
	return !has_answered_ad_personalization_choice() and ad_region_rule == "required"

func get_ad_personalization_source() -> String:
	if has_answered_ad_personalization_choice():
		return ad_personalization_choice_source
	return "region" if ad_region_rule == "automatic" else "unknown"

func set_ad_region(country: String, rule: String, policy_version: String) -> void:
	ad_region_country = country
	ad_region_rule = rule if rule in ["required", "automatic"] else "unknown"
	ad_region_policy_version = policy_version
	ad_region_checked_at = int(Time.get_unix_time_from_system())
	# A failed diagnostic save must not restore an expired regional permission.
	save_game()

func set_ad_personalization_choice(accepted: bool, source: String = "user_popup") -> bool:
	var next_choice: int = (
		AdPersonalizationChoice.ACCEPTED if accepted else AdPersonalizationChoice.DENIED
	)
	if ad_personalization_choice == next_choice:
		return true
	var previous_choice: int = ad_personalization_choice
	var previous_at: int = ad_personalization_choice_at
	var previous_source: String = ad_personalization_choice_source
	ad_personalization_choice = next_choice
	ad_personalization_choice_at = int(Time.get_unix_time_from_system())
	ad_personalization_choice_source = source
	if save_game():
		ad_personalization_choice_changed.emit()
		return true
	ad_personalization_choice = previous_choice
	ad_personalization_choice_at = previous_at
	ad_personalization_choice_source = previous_source
	return false

func _normalize_active_single_player_session(source: Variant) -> Dictionary:
	if !(source is Dictionary):
		return {}
	var session: Dictionary = Dictionary(source).duplicate(true)
	var kind: String = str(session.get("kind", ""))
	var level_index: int = int(session.get("level_index", -1))
	var word_slot: int = int(session.get("word_slot", -1))
	if !["theme", "word", "quiz", "next"].has(kind) or level_index < 0 or word_slot < 0:
		return {}
	session["kind"] = kind
	session["language"] = _normalize_language(str(session.get("language", word_language)))
	session["level_index"] = level_index
	session["word_slot"] = word_slot
	session["theme_id"] = maxi(int(session.get("theme_id", 0)), 0)
	if !(session.get("data", {}) is Dictionary):
		session["data"] = {}
	return session

func _normalize_single_player_resume_states(source: Variant) -> Dictionary:
	var result: Dictionary = {}
	if !(source is Dictionary):
		return result
	for language: String in ["ru", "en"]:
		var state_variant: Variant = Dictionary(source).get(language, {})
		if !(state_variant is Dictionary):
			continue
		var state: Dictionary = state_variant
		var active: Dictionary = _normalize_active_single_player_session(
			state.get("active_session", {})
		)
		var pending: Dictionary = _normalize_pending_single_player_reward(
			state.get("pending_reward", {})
		)
		if !active.is_empty() and str(active.get("language", "")) != language:
			active = {}
		if !pending.is_empty() and str(pending.get("language", "")) != language:
			pending = {}
		if !active.is_empty() or !pending.is_empty():
			result[language] = {
				"active_session": active,
				"pending_reward": pending,
			}
	return result

func _merge_legacy_single_player_resume_state(
	legacy_active: Dictionary,
	legacy_pending: Dictionary
) -> void:
	# Save v2 originally had only one global resume slot. Preserve it during the
	# first launch with per-language slots, without replacing newer keyed state.
	for source: Dictionary in [legacy_active, legacy_pending]:
		if source.is_empty():
			continue
		var language: String = _normalize_language(str(source.get("language", word_language)))
		var state: Dictionary = Dictionary(single_player_resume_states.get(language, {})).duplicate(true)
		var field_name: String = (
			"active_session" if source == legacy_active else "pending_reward"
		)
		if !(state.get(field_name, {}) is Dictionary) or Dictionary(state.get(field_name, {})).is_empty():
			state[field_name] = source.duplicate(true)
		single_player_resume_states[language] = state

func _store_current_single_player_resume_state() -> void:
	var profile_started_usec: int = BUILD_TRACE.section_start()
	_home_profile_store_current_single_player_resume_state()
	BUILD_TRACE.section_end(&"save.snapshot", profile_started_usec)

func _home_profile_store_current_single_player_resume_state() -> void:
	var language: String = _normalize_language(word_language)
	if active_single_player_session.is_empty() and pending_single_player_reward.is_empty():
		single_player_resume_states.erase(language)
		return
	single_player_resume_states[language] = {
		"active_session": active_single_player_session.duplicate(true),
		"pending_reward": pending_single_player_reward.duplicate(true),
	}

func _restore_single_player_resume_state(lang: String) -> void:
	var language: String = _normalize_language(lang)
	var state_variant: Variant = single_player_resume_states.get(language, {})
	var state: Dictionary = state_variant if state_variant is Dictionary else {}
	active_single_player_session = _normalize_active_single_player_session(
		state.get("active_session", {})
	)
	pending_single_player_reward = _normalize_pending_single_player_reward(
		state.get("pending_reward", {})
	)
	if (
		!active_single_player_session.is_empty()
		and str(active_single_player_session.get("language", "")) != language
	):
		active_single_player_session = {}
	if (
		!pending_single_player_reward.is_empty()
		and str(pending_single_player_reward.get("language", "")) != language
	):
		pending_single_player_reward = {}

func _clear_guided_theme_resume_state_for_language(lang: String) -> bool:
	var language: String = _normalize_language(lang)
	var removed: bool = false
	# The working fields always belong to word_language. Never touch them while
	# cleaning the inactive campaign's keyed slot.
	if language == _normalize_language(word_language):
		if str(active_single_player_session.get("kind", "")) == "theme":
			active_single_player_session = {}
			removed = true
	var state_variant: Variant = single_player_resume_states.get(language, {})
	if !(state_variant is Dictionary):
		return removed
	var state: Dictionary = Dictionary(state_variant).duplicate(true)
	var active_variant: Variant = state.get("active_session", {})
	if !(active_variant is Dictionary):
		return removed
	if str(Dictionary(active_variant).get("kind", "")) != "theme":
		return removed
	state["active_session"] = {}
	var pending_variant: Variant = state.get("pending_reward", {})
	if !(pending_variant is Dictionary) or Dictionary(pending_variant).is_empty():
		single_player_resume_states.erase(language)
	else:
		single_player_resume_states[language] = state
	return true

func _normalize_pending_single_player_reward(source: Variant) -> Dictionary:
	if !(source is Dictionary):
		return {}
	var pending: Dictionary = Dictionary(source).duplicate(true)
	var level_index: int = int(pending.get("level_index", -1))
	var word_count: int = int(pending.get("word_count", 0))
	var word_slot: int = int(pending.get("word_slot", word_count - 1))
	var amount: int = clampi(int(pending.get("amount", 0)), 0, MAX_SINGLE_REWARD)
	if level_index < 0 or word_count <= 0 or word_slot < 0 or amount <= 0:
		return {}
	var language: String = _normalize_language(str(pending.get("language", word_language)))
	var stars_amount: int = clampi(int(pending.get("stars_amount", -1)), -1, MAX_SINGLE_REWARD)
	if stars_amount < 0:
		var guessed_count: int = get_single_level_guessed_count(language, level_index, word_count)
		stars_amount = (
			_single_player_level_completion_stars(level_index, guessed_count)
			if word_count > 1
			else 0
		)
	return {
		"claim_id": str(pending.get("claim_id", "%s:%d" % [language, level_index])),
		"ad_reward_id": str(pending.get("ad_reward_id", "")),
		"language": language,
		"level_index": level_index,
		"word_count": word_count,
		"word_slot": clampi(word_slot, 0, word_count - 1),
		"theme_id": maxi(int(pending.get("theme_id", 0)), 0),
		"amount": amount,
		"claimed": bool(pending.get("claimed", false)),
		"stars_amount": maxi(stars_amount, 0),
		"stars_claimed": bool(pending.get("stars_claimed", false)),
		"double_resolved": bool(pending.get("double_resolved", false)),
		"double_claimed": bool(pending.get("double_claimed", false)),
		"presentation_started": bool(pending.get("presentation_started", false)),
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

func get_active_single_player_stage_reward() -> Dictionary:
	if str(active_single_player_session.get("kind", "")) != "next":
		return {}
	var data_variant: Variant = active_single_player_session.get("data", {})
	if !(data_variant is Dictionary):
		return {}
	var data: Dictionary = data_variant
	var currency: String = str(data.get("reward_currency", ""))
	var amount: int = clampi(int(data.get("reward_amount", 0)), 0, MAX_SINGLE_REWARD)
	if ![STAGE_REWARD_COINS, STAGE_REWARD_STARS].has(currency) or amount <= 0:
		return {}
	var claimed: bool = bool(data.get("reward_claimed", false))
	return {
		"currency": currency,
		"amount": amount,
		"claimed": claimed,
		# Older saves predate the intermediate coin x2 offer. Treat an already
		# claimed legacy reward as resolved unless the new flag was persisted
		# explicitly. New coin-stage snapshots store false until the player chooses.
		"double_resolved": bool(data.get("reward_double_resolved", claimed)),
		"double_claimed": bool(data.get("reward_double_claimed", false)),
		"presentation_started": bool(data.get("reward_presentation_started", false)),
	}

func mark_active_single_player_stage_reward_presented(persist: bool = true) -> bool:
	var reward: Dictionary = get_active_single_player_stage_reward()
	if reward.is_empty():
		return false
	if bool(reward.get("presentation_started", false)):
		return true
	var session: Dictionary = active_single_player_session.duplicate(true)
	var data: Dictionary = Dictionary(session.get("data", {})).duplicate(true)
	data["reward_presentation_started"] = true
	session["data"] = data
	active_single_player_session = session
	if persist:
		save_game()
	return true

func settle_presented_active_single_player_stage_reward(persist: bool = true) -> Dictionary:
	var reward: Dictionary = get_active_single_player_stage_reward()
	if reward.is_empty() or !bool(reward.get("presentation_started", false)):
		return {}
	var session: Dictionary = active_single_player_session.duplicate(true)
	var data: Dictionary = Dictionary(session.get("data", {})).duplicate(true)
	var currency: String = str(reward.get("currency", ""))
	var credited_amount: int = 0
	if !bool(reward.get("claimed", false)):
		data["reward_claimed"] = true
		var requested_amount: int = int(reward.get("amount", 0))
		var previous_balance: int = (
			get_stars() if currency == STAGE_REWARD_STARS else get_soft_currency()
		)
		var final_balance: int = (
			add_stars(requested_amount, false)
			if currency == STAGE_REWARD_STARS
			else add_soft_currency(requested_amount, false)
		)
		credited_amount = maxi(final_balance - previous_balance, 0)
	# Reopening after the large reward was already presented must not resurrect
	# its optional x2 offer. Preserve a bonus that was already granted before the
	# interruption; otherwise treat the choice as skipped.
	if currency == STAGE_REWARD_COINS and !bool(reward.get("double_resolved", false)):
		data["reward_double_resolved"] = true
		data["reward_double_claimed"] = false
	session["data"] = data
	active_single_player_session = session
	if persist:
		save_game()
	return {
		"currency": currency,
		"amount": credited_amount,
		"double_resolved": bool(data.get("reward_double_resolved", true)),
		"double_claimed": bool(data.get("reward_double_claimed", false)),
	}

func claim_active_single_player_stage_reward(persist: bool = true) -> Dictionary:
	var reward: Dictionary = get_active_single_player_stage_reward()
	if reward.is_empty():
		return {}
	var currency: String = str(reward.get("currency", ""))
	if bool(reward.get("claimed", false)):
		return {
			"currency": currency,
			"amount": 0,
			"already_claimed": true,
		}
	var session: Dictionary = active_single_player_session.duplicate(true)
	var data: Dictionary = Dictionary(session.get("data", {})).duplicate(true)
	data["reward_claimed"] = true
	session["data"] = data
	active_single_player_session = session
	var requested_amount: int = int(reward.get("amount", 0))
	var previous_balance: int = (
		get_stars() if currency == STAGE_REWARD_STARS else get_soft_currency()
	)
	var final_balance: int = (
		add_stars(requested_amount, false)
		if currency == STAGE_REWARD_STARS
		else add_soft_currency(requested_amount, false)
	)
	if persist:
		save_game()
	return {
		"currency": currency,
		"amount": maxi(final_balance - previous_balance, 0),
		"already_claimed": false,
	}

func resolve_active_single_player_stage_reward_double(
	grant_bonus: bool,
	persist: bool = true
) -> Dictionary:
	var reward: Dictionary = get_active_single_player_stage_reward()
	if reward.is_empty():
		return {}
	var currency: String = str(reward.get("currency", ""))
	if currency != STAGE_REWARD_COINS:
		return {
			"currency": currency,
			"amount": 0,
			"resolved": true,
			"granted": false,
		}
	if bool(reward.get("double_resolved", false)):
		return {
			"currency": currency,
			"amount": 0,
			"resolved": true,
			"granted": bool(reward.get("double_claimed", false)),
		}
	# The x2 option is a bonus on top of a base reward that has already been
	# credited at the peak of the large-reward bounce. Never create the bonus if
	# the base claim did not complete.
	if !bool(reward.get("claimed", false)):
		return {
			"currency": currency,
			"amount": 0,
			"resolved": false,
			"granted": false,
		}
	var session: Dictionary = active_single_player_session.duplicate(true)
	var data: Dictionary = Dictionary(session.get("data", {})).duplicate(true)
	data["reward_double_resolved"] = true
	data["reward_double_claimed"] = grant_bonus
	session["data"] = data
	active_single_player_session = session
	var credited_amount: int = 0
	if grant_bonus:
		var previous_balance: int = get_soft_currency()
		var final_balance: int = add_soft_currency(int(reward.get("amount", 0)), false)
		credited_amount = maxi(final_balance - previous_balance, 0)
	if persist:
		save_game()
	return {
		"currency": currency,
		"amount": credited_amount,
		"resolved": true,
		"granted": grant_bonus,
	}

func get_pending_single_player_reward() -> Dictionary:
	return pending_single_player_reward.duplicate(true)

func clear_pending_single_player_reward(persist: bool = true) -> void:
	if pending_single_player_reward.is_empty():
		return
	pending_single_player_reward = {}
	if persist:
		save_game()

func mark_pending_single_player_reward_presented(persist: bool = true) -> bool:
	if pending_single_player_reward.is_empty():
		return false
	if bool(pending_single_player_reward.get("presentation_started", false)):
		return true
	pending_single_player_reward["presentation_started"] = true
	if persist:
		save_game()
	return true

func is_pending_single_player_reward_presented() -> bool:
	return (
		!pending_single_player_reward.is_empty()
		and bool(pending_single_player_reward.get("presentation_started", false))
	)

func settle_presented_pending_single_player_reward(persist: bool = true) -> Dictionary:
	if !is_pending_single_player_reward_presented():
		return {}
	var credited_coins: int = 0
	var credited_stars: int = 0
	if !bool(pending_single_player_reward.get("claimed", false)):
		pending_single_player_reward["claimed"] = true
		var previous_coins: int = get_soft_currency()
		credited_coins = (
			add_soft_currency(int(pending_single_player_reward.get("amount", 0)), false)
			- previous_coins
		)
	if !bool(pending_single_player_reward.get("stars_claimed", false)):
		pending_single_player_reward["stars_claimed"] = true
		var previous_stars: int = get_stars()
		credited_stars = (
			add_stars(int(pending_single_player_reward.get("stars_amount", 0)), false)
			- previous_stars
		)
	# Leaving the main-reward presentation means the optional x2 offer was skipped.
	# Mark it resolved before dropping the snapshot so a resumed/late UI cannot
	# resurrect the offer or create a Home Continue state for this completed level.
	pending_single_player_reward["double_resolved"] = true
	pending_single_player_reward["double_claimed"] = false
	var settled_level_index: int = int(pending_single_player_reward.get("level_index", -1))
	pending_single_player_reward = {}
	active_single_player_session = {}
	if persist:
		save_game()
	return {
		"level_index": settled_level_index,
		"coins": credited_coins,
		"stars": credited_stars,
	}

func has_resumable_single_player_level() -> bool:
	return !pending_single_player_reward.is_empty() or !active_single_player_session.is_empty()

func get_resumable_single_player_level_index() -> int:
	if !pending_single_player_reward.is_empty():
		return int(pending_single_player_reward.get("level_index", -1))
	return int(active_single_player_session.get("level_index", -1))

func get_resumable_single_player_level_index_for_language(lang: String) -> int:
	var language: String = _normalize_language(lang)
	if language == word_language:
		return get_resumable_single_player_level_index()
	var state_variant: Variant = single_player_resume_states.get(language, {})
	if !(state_variant is Dictionary):
		return -1
	var state: Dictionary = state_variant
	var pending_variant: Variant = state.get("pending_reward", {})
	if pending_variant is Dictionary and !Dictionary(pending_variant).is_empty():
		return int(Dictionary(pending_variant).get("level_index", -1))
	var active_variant: Variant = state.get("active_session", {})
	if active_variant is Dictionary and !Dictionary(active_variant).is_empty():
		return int(Dictionary(active_variant).get("level_index", -1))
	return -1

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
	var language: String = _normalize_language(lang)
	var guessed_count: int = get_single_level_guessed_count(language, level_index, word_count)
	var stars_amount: int = (
		_single_player_level_completion_stars(level_index, guessed_count)
		if word_count > 1
		else 0
	)
	pending_single_player_reward = {
		"claim_id": "%s:%d:%d" % [language, level_index, word_slot],
		"language": language,
		"level_index": level_index,
		"word_slot": clampi(word_slot, 0, word_count - 1),
		"word_count": word_count,
		"theme_id": maxi(theme_id, 0),
		"amount": amount,
		"stars_amount": stars_amount,
		"stars_claimed": stars_amount <= 0,
		"presentation_started": false,
	}
	active_single_player_session = {}

func claim_pending_single_player_reward(multiplier: int = 1) -> int:
	if pending_single_player_reward.is_empty():
		return 0
	var credited_amount: int = 0
	if !bool(pending_single_player_reward.get("claimed", false)):
		pending_single_player_reward["claimed"] = true
		var previous_balance: int = get_soft_currency()
		credited_amount = add_soft_currency(int(pending_single_player_reward["amount"]), false) - previous_balance
	if multiplier >= 2:
		credited_amount += resolve_pending_single_player_reward_double(true, false)
	# Keep the completion snapshot through the x2 offer. It also owns the durable
	# level-star claim used by the merged reward presentation.
	save_game()
	return credited_amount

func claim_pending_single_player_level_stars(persist: bool = true) -> int:
	if pending_single_player_reward.is_empty():
		return 0
	if bool(pending_single_player_reward.get("stars_claimed", false)):
		return 0
	pending_single_player_reward["stars_claimed"] = true
	var requested_amount: int = clampi(
		int(pending_single_player_reward.get("stars_amount", 0)),
		0,
		MAX_SINGLE_REWARD
	)
	var previous_balance: int = get_stars()
	var final_balance: int = add_stars(requested_amount, false)
	if persist:
		save_game()
	return maxi(final_balance - previous_balance, 0)

func resolve_pending_single_player_reward_double(grant_bonus: bool, persist: bool = true) -> int:
	if (
		pending_single_player_reward.is_empty()
		or !bool(pending_single_player_reward.get("claimed", false))
		or bool(pending_single_player_reward.get("double_resolved", false))
	):
		return 0
	pending_single_player_reward["double_resolved"] = true
	pending_single_player_reward["double_claimed"] = grant_bonus
	var credited_amount: int = 0
	if grant_bonus:
		var previous_balance: int = get_soft_currency()
		credited_amount = add_soft_currency(int(pending_single_player_reward["amount"]), false) - previous_balance
	if persist:
		save_game()
	return credited_amount

# Each native show carries a durable request id. The receipt captures the amount
# and target before showing, so a delayed callback cannot credit the next level.
func _rewarded_double_target(context: String) -> Dictionary:
	return _rewarded_double_target_from_snapshots(
		context, active_single_player_session, pending_single_player_reward
	)

func _rewarded_double_target_from_snapshots(
	context: String, active: Dictionary, pending: Dictionary
) -> Dictionary:
	var source: Dictionary = {}
	var amount: int = 0
	var claimed: bool = false
	var resolved: bool = true
	var granted: bool = false
	var reward_id: String = ""
	if context == "final":
		source = pending
		reward_id = str(source.get("ad_reward_id", ""))
		amount = int(source.get("amount", 0))
		claimed = bool(source.get("claimed", false))
		resolved = bool(source.get("double_resolved", false))
		granted = bool(source.get("double_claimed", false))
	elif context == "stage_coin":
		source = active
		reward_id = str(Dictionary(source.get("data", {})).get("reward_ad_id", ""))
		var data: Dictionary = Dictionary(source.get("data", {}))
		if str(source.get("kind", "")) != "next" or str(data.get("reward_currency", "")) != STAGE_REWARD_COINS:
			return {}
		amount = clampi(int(data.get("reward_amount", 0)), 0, MAX_SINGLE_REWARD)
		claimed = bool(data.get("reward_claimed", false))
		resolved = bool(data.get("reward_double_resolved", claimed))
		granted = bool(data.get("reward_double_claimed", false))
	if source.is_empty() or amount <= 0 or !claimed:
		return {}
	return {
		"target": "%s:%s:%d:%d:%s" % [context, str(source.get("language", word_language)),
			int(source.get("level_index", -1)), int(source.get("word_slot", -1)), reward_id],
		"context": context, "amount": amount, "resolved": resolved, "granted": granted,
	}

func begin_rewarded_double_request(context: String) -> String:
	var target: Dictionary = _rewarded_double_target(context)
	if target.is_empty() or bool(target.get("resolved", true)):
		return ""
	var request_id: String = "double:%s:%d:%d" % [str(Time.get_unix_time_from_system()), Time.get_ticks_usec(), randi()]
	# The same level/slot can be replayed. Give each actual payout its own id.
	if context == "final":
		if str(pending_single_player_reward.get("ad_reward_id", "")).is_empty():
			pending_single_player_reward["ad_reward_id"] = request_id
	else:
		var data: Dictionary = active_single_player_session["data"]
		if str(data.get("reward_ad_id", "")).is_empty():
			data["reward_ad_id"] = request_id
	target = _rewarded_double_target(context)
	rewarded_double_requests[request_id] = target
	if !save_game():
		rewarded_double_requests.erase(request_id)
		return ""
	return request_id

func cancel_rewarded_double_request(request_id: String) -> void:
	if rewarded_double_requests.has(request_id) and !bool(rewarded_double_requests[request_id].get("granted", false)):
		rewarded_double_requests.erase(request_id)
		save_game()

func claim_rewarded_double_request(request_id: String) -> Dictionary:
	var request: Dictionary = rewarded_double_requests.get(request_id, {})
	if request.is_empty() or bool(request.get("granted", false)):
		return {}
	var context: String = str(request.get("context", ""))
	var current: Dictionary = _rewarded_double_target(context)
	var is_current: bool = !current.is_empty() and current.get("target") == request.get("target")
	var already_granted: bool = is_current and bool(current.get("granted", false))
	# A late callback can belong to the other language's saved campaign.
	# Its offer flags must commit together with the shared coin balance.
	var inactive_state: Dictionary = {}
	if !is_current:
		for language: String in single_player_resume_states:
			if language == word_language:
				continue
			var candidate: Dictionary = single_player_resume_states[language]
			var target: Dictionary = _rewarded_double_target_from_snapshots(
				context, candidate.get("active_session", {}), candidate.get("pending_reward", {})
			)
			if !target.is_empty() and target.get("target") == request.get("target"):
				inactive_state = candidate
				already_granted = bool(target.get("granted", false))
				break
	# Keep only unresolved receipts. Unknown ids cannot create a payout, so
	# removing ALL retries of a paid target is its compact, idempotent state.
	var completed_requests: Dictionary = {}
	for other_id: Variant in rewarded_double_requests:
		var other: Dictionary = rewarded_double_requests[other_id]
		if other.get("target") == request.get("target"):
			already_granted = already_granted or bool(other.get("granted", false))
			completed_requests[other_id] = other
	for other_id: Variant in completed_requests:
		rewarded_double_requests.erase(other_id)
	var previous_pending: Dictionary = pending_single_player_reward.duplicate(true)
	var previous_resume_states: Dictionary = single_player_resume_states.duplicate(true)
	var previous_session: Dictionary = active_single_player_session.duplicate(true)
	if is_current:
		if context == "final":
			pending_single_player_reward["double_resolved"] = true
			pending_single_player_reward["double_claimed"] = true
		else:
			var data: Dictionary = active_single_player_session["data"]
			data["reward_double_resolved"] = true
			data["reward_double_claimed"] = true
	elif !inactive_state.is_empty():
		if context == "final":
			var pending: Dictionary = inactive_state["pending_reward"]
			pending["double_resolved"] = true
			pending["double_claimed"] = true
		else:
			var data: Dictionary = inactive_state["active_session"]["data"]
			data["reward_double_resolved"] = true
			data["reward_double_claimed"] = true
	var before: int = get_soft_currency()
	if !already_granted:
		soft_currency = clampi(before + int(request["amount"]), 0, MAX_CURRENCY_BALANCE)
	if !save_game():
		# Balance, offer flags and receipt removal must commit together. Keep the
		# receipt retryable if the durable write fails.
		soft_currency = before
		pending_single_player_reward = previous_pending
		active_single_player_session = previous_session
		single_player_resume_states = previous_resume_states
		rewarded_double_requests.merge(completed_requests)
		_store_current_single_player_resume_state()
		return {}
	# Notify UI only after the balance and receipt removal are durable.
	if !already_granted:
		soft_currency_changed.emit(soft_currency)
	return {"context": context, "is_current": is_current, "amount": get_soft_currency() - before}

func _load_rewarded_double_requests(source: Variant) -> void:
	rewarded_double_requests = {}
	if !(source is Dictionary):
		return
	for request_id: Variant in source:
		var item: Variant = source[request_id]
		if !(item is Dictionary):
			continue
		var context: String = str(item.get("context", ""))
		var target: String = str(item.get("target", ""))
		var amount: int = clampi(int(item.get("amount", 0)), 0, MAX_SINGLE_REWARD)
		if str(request_id).is_empty() or target.is_empty() or amount <= 0 or !["final", "stage_coin"].has(context):
			continue
		rewarded_double_requests[str(request_id)] = {
			"context": context, "target": target, "amount": amount,
			"granted": bool(item.get("granted", false)),
		}

	# Migrate older saves, including mixed granted/ungranted retries for one
	# target. Never discard an unrelated unresolved receipt, regardless of age.
	var completed_targets: Dictionary = {}
	for item: Dictionary in rewarded_double_requests.values():
		if bool(item.get("granted", false)):
			completed_targets[item["target"]] = true
	for request_id: Variant in rewarded_double_requests.keys():
		if completed_targets.has(rewarded_double_requests[request_id]["target"]):
			rewarded_double_requests.erase(request_id)

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
	var profile_started_usec: int = BUILD_TRACE.section_start()
	_home_profile_compact_single_player_history()
	BUILD_TRACE.section_end(&"save.compact", profile_started_usec)

func _home_profile_compact_single_player_history() -> void:
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
			"level_word_assignments",
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

func get_heart_refill_ad_views_remaining() -> int:
	_refresh_heart_refill_ad_cooldown(true)
	return clampi(heart_refill_ad_views_remaining, 0, COIN_REFILL_AD_MAX_VIEWS)

func get_heart_refill_ad_cooldown_seconds() -> int:
	_refresh_heart_refill_ad_cooldown(true)
	if heart_refill_ad_views_remaining > 0 or heart_refill_ad_cooldown_until <= 0:
		return 0
	return maxi(heart_refill_ad_cooldown_until - _coin_refill_ad_now(), 0)

func can_watch_heart_refill_ad() -> bool:
	_refresh_heart_refill_ad_cooldown(true)
	return heart_refill_ad_views_remaining > 0

func consume_heart_refill_ad_view(persist: bool = true) -> int:
	_refresh_heart_refill_ad_cooldown(false)
	if heart_refill_ad_views_remaining <= 0:
		return 0
	heart_refill_ad_views_remaining -= 1
	if heart_refill_ad_views_remaining <= 0:
		heart_refill_ad_views_remaining = 0
		heart_refill_ad_cooldown_until = (
			_coin_refill_ad_now() + COIN_REFILL_AD_COOLDOWN_SECONDS
		)
	if persist:
		save_game()
	return heart_refill_ad_views_remaining

func _refresh_heart_refill_ad_cooldown(persist: bool) -> bool:
	heart_refill_ad_views_remaining = clampi(
		heart_refill_ad_views_remaining,
		0,
		COIN_REFILL_AD_MAX_VIEWS
	)
	if heart_refill_ad_views_remaining > 0:
		if heart_refill_ad_cooldown_until != 0:
			heart_refill_ad_cooldown_until = 0
			if persist:
				save_game()
			return true
		return false
	if heart_refill_ad_cooldown_until <= 0:
		heart_refill_ad_cooldown_until = _coin_refill_ad_now() + COIN_REFILL_AD_COOLDOWN_SECONDS
		if persist:
			save_game()
		return true
	if _coin_refill_ad_now() < heart_refill_ad_cooldown_until:
		return false
	heart_refill_ad_views_remaining = COIN_REFILL_AD_MAX_VIEWS
	heart_refill_ad_cooldown_until = 0
	if persist:
		save_game()
	return true

func get_extra_attempt_ad_views_remaining() -> int:
	_refresh_extra_attempt_ad_cooldown(true)
	return clampi(extra_attempt_ad_views_remaining, 0, COIN_REFILL_AD_MAX_VIEWS)

func get_extra_attempt_ad_cooldown_seconds() -> int:
	_refresh_extra_attempt_ad_cooldown(true)
	if extra_attempt_ad_views_remaining > 0 or extra_attempt_ad_cooldown_until <= 0:
		return 0
	return maxi(extra_attempt_ad_cooldown_until - _coin_refill_ad_now(), 0)

func can_watch_extra_attempt_ad() -> bool:
	_refresh_extra_attempt_ad_cooldown(true)
	return extra_attempt_ad_views_remaining > 0

func consume_extra_attempt_ad_view(persist: bool = true) -> int:
	_refresh_extra_attempt_ad_cooldown(false)
	if extra_attempt_ad_views_remaining <= 0:
		return 0
	extra_attempt_ad_views_remaining -= 1
	if extra_attempt_ad_views_remaining <= 0:
		extra_attempt_ad_views_remaining = 0
		extra_attempt_ad_cooldown_until = (
			_coin_refill_ad_now() + COIN_REFILL_AD_COOLDOWN_SECONDS
		)
	if persist:
		save_game()
	return extra_attempt_ad_views_remaining

func _refresh_extra_attempt_ad_cooldown(persist: bool) -> bool:
	extra_attempt_ad_views_remaining = clampi(
		extra_attempt_ad_views_remaining,
		0,
		COIN_REFILL_AD_MAX_VIEWS
	)
	if extra_attempt_ad_views_remaining > 0:
		if extra_attempt_ad_cooldown_until != 0:
			extra_attempt_ad_cooldown_until = 0
			if persist:
				save_game()
			return true
		return false
	if extra_attempt_ad_cooldown_until <= 0:
		extra_attempt_ad_cooldown_until = _coin_refill_ad_now() + COIN_REFILL_AD_COOLDOWN_SECONDS
		if persist:
			save_game()
		return true
	if _coin_refill_ad_now() < extra_attempt_ad_cooldown_until:
		return false
	extra_attempt_ad_views_remaining = COIN_REFILL_AD_MAX_VIEWS
	extra_attempt_ad_cooldown_until = 0
	if persist:
		save_game()
	return true

func get_soft_currency() -> int:
	soft_currency = maxi(soft_currency, 0)
	return soft_currency

func get_stars() -> int:
	stars = clampi(stars, 0, MAX_CURRENCY_BALANCE)
	return stars

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
	soft_currency = clampi(soft_currency + amount, 0, MAX_CURRENCY_BALANCE)
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

func add_stars(amount: int, persist: bool = true) -> int:
	if amount <= 0:
		return get_stars()
	stars = clampi(stars + amount, 0, MAX_CURRENCY_BALANCE)
	stars_changed.emit(stars)
	if persist:
		save_game()
	return stars

func spend_stars(amount: int, persist: bool = true) -> bool:
	if amount <= 0 or get_stars() < amount:
		return false
	stars -= amount
	stars_changed.emit(stars)
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
	var normalized_language: String = _normalize_language(lang)
	if normalized_language == word_language:
		save_game()
		return
	# Keep the unfinished campaign of the language we are leaving, then expose
	# only the resume state that belongs to the newly selected word base.
	_store_current_single_player_resume_state()
	word_language = normalized_language
	_restore_single_player_resume_state(word_language)
	save_game()

func _theme_progress_key(theme_index: int) -> String:
	var theme_id: int = Database.get_theme_id(theme_index)
	return str(theme_id) if theme_id > 0 else ""

func _word_progress_key(theme_index: int, word_index: int, word_text: String = "") -> String:
	var database_key: String = Database.get_word_progress_key(theme_index, word_index)
	var text_key: String = Database.word_progress_key_from_text(word_text)
	if (
		!database_key.is_empty()
		and (
			text_key.is_empty()
			or database_key == text_key
			or database_key.begins_with(text_key + "::")
		)
	):
		return database_key
	# A resumable round may refer to an index from the previous database revision.
	# Prefer its saved word text when cleanup/removal shifted later array entries.
	return text_key

func _normalize_word_flag_dictionary(source: Variant) -> Dictionary:
	var result: Dictionary = {}
	if source is Dictionary:
		for key_variant: Variant in (source as Dictionary).keys():
			if bool((source as Dictionary).get(key_variant, false)):
				var key: String = Database.word_progress_key_from_text(str(key_variant).strip_edges())
				if !key.is_empty():
					result[key] = true
	return result

func _prune_word_flag_dictionary(source: Variant, theme_index: int) -> Dictionary:
	var normalized := _normalize_word_flag_dictionary(source)
	var allowed_keys: Dictionary = Database.get_word_progress_key_set(theme_index)
	for key_variant: Variant in normalized.keys():
		if !allowed_keys.has(str(key_variant)):
			normalized.erase(key_variant)
	return normalized

func _migrate_word_aliases_in_stats(stats: Dictionary) -> void:
	if int(stats.get("_word_catalog_version", 0)) >= WORD_PROGRESS_ALIAS_REVISION:
		return
	var aliases: Dictionary = Database.get_word_progress_alias_themes()
	for theme_key: Variant in stats.keys():
		if !(stats[theme_key] is Dictionary):
			continue
		var source: Dictionary = stats[theme_key]
		for field: String in ["played", "guessed"]:
			if !(source.get(field) is Dictionary):
				continue
			var flags: Dictionary = source[field]
			for old_key: Variant in flags.keys():
				var normalized: String = Database.normalize_loaded_word(str(old_key))
				if !aliases.has(normalized):
					continue
				if bool(flags[old_key]):
					var target_theme: String = str(int(aliases[normalized]))
					if !(stats.get(target_theme) is Dictionary):
						stats[target_theme] = {}
					var target: Dictionary = stats[target_theme]
					if !(target.get(field) is Dictionary):
						target[field] = {}
					target[field][Database.word_progress_key_from_text(normalized)] = true
				flags.erase(old_key)
	stats["_word_catalog_version"] = WORD_PROGRESS_ALIAS_REVISION

func ensure_theme_progress(lang: String, theme_index: int, _word_count: int) -> Dictionary:
	var lang_key := _normalize_language(lang)
	if !progress.has(lang_key) or !(progress[lang_key] is Dictionary):
		progress[lang_key] = {}
	_migrate_word_aliases_in_stats(progress[lang_key])
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
		"win_streak": 0,
		"loss_streak": 0,
		"levels": {},
		"selected_themes": {},
		"level_seeds": {},
		"theme_reroll_states": {},
		"word_stats": {},
		"level_question_slots": {},
		"level_question_ids": {},
		"level_word_assignments": {},
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
		"level_word_assignments",
		"question_stats",
	]:
		if !bucket.has(dictionary_key) or !(bucket[dictionary_key] is Dictionary):
			bucket[dictionary_key] = {}
	if !bucket.has("unlocked_level"):
		bucket["unlocked_level"] = 0
	# Legacy saves already encode completed level count as the next level index.
	bucket["theme_unlock_completed_levels"] = maxi(
		maxi(int(bucket.get("theme_unlock_completed_levels", 0)), 0),
		maxi(int(bucket.get("unlocked_level", 0)), 0)
	)
	bucket["adaptive_difficulty"] = clampf(
		float(bucket.get("adaptive_difficulty", SINGLE_PLAYER_DIFFICULTY_DEFAULT)),
		SINGLE_PLAYER_DIFFICULTY_MIN,
		SINGLE_PLAYER_DIFFICULTY_MAX
	)
	for counter_key in [
		"completed_attempts",
		"failed_attempts",
		"forfeited_attempts",
		"win_streak",
		"loss_streak",
	]:
		bucket[counter_key] = maxi(int(bucket.get(counter_key, 0)), 0)
	single_player[lang_key] = bucket
	return bucket

func _single_player_progress_bucket(lang: String, _difficulty: int = -1) -> Dictionary:
	return _single_player_bucket(lang)

func ensure_single_player_theme_progress(lang: String, theme_index: int, _word_count: int) -> Dictionary:
	var lang_key := _normalize_language(lang)
	var bucket := _single_player_bucket(lang_key)
	var word_stats: Dictionary = bucket["word_stats"]
	_migrate_word_aliases_in_stats(word_stats)
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

# Only the completed prefix and the currently offered stage are committed.
# Later stages are selected again using the latest shared adaptive difficulty.
func get_single_level_word_assignments(lang: String, level_index: int) -> Array:
	var bucket := _single_player_bucket(lang)
	var source: Variant = bucket["level_word_assignments"].get(str(level_index), [])
	return Array(source).duplicate(true) if source is Array else []

func set_single_level_word_assignments(lang: String, level_index: int, words: Array) -> void:
	var bucket := _single_player_bucket(lang)
	bucket["level_word_assignments"][str(level_index)] = words.duplicate(true)
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
	# JSON numbers reload as floats; normalize IDs before Array.has/erase.
	var recent_value: Variant = theme_stats.get("recent", [])
	var recent: Array = []
	if recent_value is Array:
		for value: Variant in recent_value:
			if value is int or value is float:
				var question_id: int = int(value)
				if question_id >= 0:
					recent.erase(question_id)
					recent.append(question_id)
	theme_stats["recent"] = recent.slice(maxi(0, recent.size() - 8))
	question_stats[theme_key] = theme_stats
	bucket["question_stats"] = question_stats
	single_player[lang_key] = bucket
	return theme_stats

func get_single_player_question_history(lang: String, theme_index: int) -> Dictionary:
	return _single_player_question_theme_stats(lang, theme_index).duplicate(true)

func mark_single_player_question_seen(lang: String, theme_index: int, question_id: int, persist: bool = true) -> void:
	if theme_index < 0 or question_id < 0:
		return
	var lang_key := _normalize_language(lang)
	var theme_key := _theme_progress_key(theme_index)
	var theme_stats: Dictionary = _single_player_question_theme_stats(lang_key, theme_index)
	var seen: Dictionary = theme_stats["seen"]
	seen[str(question_id)] = true
	theme_stats["seen"] = seen
	# Track the last eight actual presentations, including repeats. Old saves
	# have no recent list and retain their complete seen history unchanged.
	var recent_value: Variant = theme_stats.get("recent", [])
	var recent: Array = Array(recent_value).duplicate() if recent_value is Array else []
	recent.erase(question_id)
	recent.append(question_id)
	while recent.size() > 8:
		recent.pop_front()
	theme_stats["recent"] = recent
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
	if word_count <= 0:
		return false
	return get_single_level_played_count(lang, level_index, word_count, difficulty) >= word_count

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

# Unlocks follow completed campaign levels, not stars, wins or paid rerolls.
# Keep a high-water mark so resetting an attempt never removes a theme.
func get_theme_unlock_completed_levels(lang: String) -> int:
	return int(_single_player_bucket(lang).get("theme_unlock_completed_levels", 0))

func get_unlocked_theme_ids(lang: String) -> Array[int]:
	var result: Array[int] = []
	for value: Variant in GAME_DESIGN.get_array("progression.theme_unlocks.initial_theme_ids", [1, 9, 2]):
		var theme_id: int = int(value)
		if Database.THEME_IDS.has(theme_id) and !result.has(theme_id):
			result.append(theme_id)
	var completed: int = get_theme_unlock_completed_levels(lang)
	for entry: Dictionary in _theme_unlock_milestones():
		var theme_id: int = int(entry.get("theme_id", -1))
		if completed >= int(entry.get("after_level", 0)) and !result.has(theme_id):
			result.append(theme_id)
	return result

func _theme_unlock_milestones() -> Array:
	return GAME_DESIGN.get_array("progression.theme_unlocks.milestones", [
		{"after_level": 3, "theme_id": 6}, {"after_level": 6, "theme_id": 3},
		{"after_level": 10, "theme_id": 10}, {"after_level": 14, "theme_id": 5},
		{"after_level": 18, "theme_id": 8}, {"after_level": 25, "theme_id": 4},
		{"after_level": 30, "theme_id": 7},
	])

func get_theme_unlock_reward_progress(before: int, after: int) -> Dictionary:
	before = maxi(before, 0)
	after = maxi(after, before)
	var previous_goal: int = 0
	for entry: Dictionary in _theme_unlock_milestones():
		var goal: int = int(entry["after_level"])
		if after < goal or (before < goal and after == goal):
			var span: int = maxi(goal - previous_goal, 1)
			return {
				"theme_id": int(entry["theme_id"]), "goal_level": goal,
				"from": clampi(before - previous_goal, 0, span),
				"to": clampi(after - previous_goal, 0, span), "total": span,
				"unlocked": before < goal and after >= goal,
			}
		previous_goal = goal
	return {}

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

func relock_single_player_level_if_latest(
	lang: String,
	level_index: int,
	persist: bool = true
) -> bool:
	# Used only when the zero-heart popup is closed after the last failed stage.
	# Never relock if the following level has already acquired any durable state.
	if level_index < 0:
		return false
	var lang_key := _normalize_language(lang)
	var bucket := _single_player_bucket(lang_key)
	if int(bucket.get("unlocked_level", 0)) != level_index + 1:
		return false
	var next_level_key := str(level_index + 1)
	var levels: Dictionary = bucket["levels"]
	var selected_themes: Dictionary = bucket["selected_themes"]
	if levels.has(next_level_key) or selected_themes.has(next_level_key):
		return false
	bucket["unlocked_level"] = level_index
	single_player[lang_key] = bucket
	if persist:
		save_game()
	return true

func get_single_player_adaptive_difficulty(lang: String) -> float:
	var bucket := _single_player_bucket(lang)
	return clampf(
		float(bucket.get("adaptive_difficulty", SINGLE_PLAYER_DIFFICULTY_DEFAULT)),
		SINGLE_PLAYER_DIFFICULTY_MIN,
		SINGLE_PLAYER_DIFFICULTY_MAX
	)

func _single_player_level_completion_bonus(level_index: int, guessed_count: int) -> int:
	var wins: int = maxi(guessed_count, 0)
	if GAME_DESIGN.is_bonus_level(level_index + 1):
		return (
			SINGLE_PLAYER_CHALLENGE_LEVEL_COMPLETION_BASE_COINS
			+ wins * SINGLE_PLAYER_CHALLENGE_LEVEL_COMPLETION_PER_WIN_COINS
		)
	return (
		SINGLE_PLAYER_LEVEL_COMPLETION_BASE_COINS
		+ wins * SINGLE_PLAYER_LEVEL_COMPLETION_PER_WIN_COINS
	)

func _single_player_level_completion_stars(level_index: int, guessed_count: int) -> int:
	var wins: int = maxi(guessed_count, 0)
	if GAME_DESIGN.is_bonus_level(level_index + 1):
		return (
			SINGLE_PLAYER_CHALLENGE_LEVEL_COMPLETION_BASE_STARS
			+ wins * SINGLE_PLAYER_CHALLENGE_LEVEL_COMPLETION_PER_WIN_STARS
		)
	return (
		SINGLE_PLAYER_LEVEL_COMPLETION_BASE_STARS
		+ wins * SINGLE_PLAYER_LEVEL_COMPLETION_PER_WIN_STARS
	)

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
	if was_unplayed:
		statuses[word_slot] = 1 if is_win else 2
	var completed: bool = is_single_level_completed(lang, level_index, word_count, difficulty)
	var perfect: bool = is_single_level_perfect(lang, level_index, word_count, difficulty)
	var failed: bool = is_single_level_failed(lang, level_index, word_count, difficulty)
	var unlocked_next: bool = false
	var completion_bonus: int = 0
	var lang_key := _normalize_language(lang)
	var bucket := _single_player_bucket(lang_key)
	var unlocked_level: int = int(bucket.get("unlocked_level", 0))
	var theme_unlock_before: int = int(bucket.get("theme_unlock_completed_levels", 0))
	var difficulty_before: float = get_single_player_adaptive_difficulty(lang_key)
	var difficulty_after: float = difficulty_before
	var difficulty_delta: float = 0.0
	if was_unplayed and is_win:
		var win_streak: int = int(bucket.get("win_streak", 0)) + 1
		difficulty_delta = GAME_DESIGN.difficulty_win_increase(difficulty_before, win_streak)
		difficulty_after = clampf(
			difficulty_before + difficulty_delta,
			SINGLE_PLAYER_DIFFICULTY_MIN,
			SINGLE_PLAYER_DIFFICULTY_MAX
		)
		bucket["adaptive_difficulty"] = difficulty_after
		bucket["completed_attempts"] = int(bucket.get("completed_attempts", 0)) + 1
		bucket["win_streak"] = win_streak
		bucket["loss_streak"] = 0
	elif was_unplayed and !is_win:
		if failure_affects_difficulty:
			var loss_streak: int = int(bucket.get("loss_streak", 0)) + 1
			difficulty_delta = -GAME_DESIGN.difficulty_loss_decrease(loss_streak)
			difficulty_after = clampf(
				difficulty_before + difficulty_delta,
				SINGLE_PLAYER_DIFFICULTY_MIN,
				SINGLE_PLAYER_DIFFICULTY_MAX
			)
			bucket["adaptive_difficulty"] = difficulty_after
			bucket["failed_attempts"] = int(bucket.get("failed_attempts", 0)) + 1
			bucket["win_streak"] = 0
			bucket["loss_streak"] = loss_streak
		else:
			bucket["forfeited_attempts"] = int(bucket.get("forfeited_attempts", 0)) + 1
	if was_unplayed and completed and word_count > 1:
		var guessed_count: int = get_single_level_guessed_count(
			lang,
			level_index,
			word_count,
			difficulty
		)
		completion_bonus = _single_player_level_completion_bonus(level_index, guessed_count)
		if award_completion_bonus:
			add_soft_currency(completion_bonus, false)
	difficulty_delta = difficulty_after - difficulty_before
	if was_unplayed and completed and level_index >= unlocked_level:
		bucket["unlocked_level"] = level_index + 1
		unlocked_next = true
	if was_unplayed and completed:
		bucket["theme_unlock_completed_levels"] = maxi(theme_unlock_before, level_index + 1)
	single_player[lang_key] = bucket
	if was_unplayed and completed and !award_completion_bonus and completion_bonus > 0:
		var selected_theme_id: int = int(
			(bucket["selected_themes"] as Dictionary).get(str(level_index), 0)
		)
		_create_pending_single_player_reward(
			lang_key,
			level_index,
			word_slot,
			word_count,
			selected_theme_id,
			completion_bonus
		)
	if persist:
		save_game()
	return {
		"completed": completed,
		"theme_unlock_before": theme_unlock_before,
		"theme_unlock_after": int(bucket.get("theme_unlock_completed_levels", 0)),
		"perfect": perfect,
		"failed": failed,
		# A failed stage only withholds its reward; it no longer ends the chain.
		"chain_ended": completed,
		"played_count": get_single_level_played_count(lang, level_index, word_count, difficulty),
		"guessed_count": get_single_level_guessed_count(lang, level_index, word_count, difficulty),
		"unlocked_next": unlocked_next,
		"unlocked_level": get_single_player_unlocked_level(lang, difficulty),
		"completion_bonus": completion_bonus,
		"difficulty_before": difficulty_before,
		"difficulty_after": difficulty_after,
		"difficulty_delta": difficulty_delta,
		"win_streak": int(bucket.get("win_streak", 0)),
		"loss_streak": int(bucket.get("loss_streak", 0)),
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
	bucket["level_word_assignments"].erase(level_key)
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
