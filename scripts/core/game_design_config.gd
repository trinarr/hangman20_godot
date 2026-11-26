extends RefCounted
class_name GameDesignConfig

const CONFIG_PATH: String = "res://data/game_design_config.json"

static var _config: Dictionary = {}
static var _loaded: bool = false

static func reload() -> void:
	_loaded = false
	_config.clear()
	_ensure_loaded()

static func get_value(path: String) -> Variant:
	_ensure_loaded()
	var current: Variant = _config
	for key: String in path.split(".", false):
		if !(current is Dictionary):
			_fatal_config_error("Invalid game-design config path: %s" % path)
		var section: Dictionary = current
		if !section.has(key):
			_fatal_config_error("Missing game-design config key: %s" % path)
		current = section[key]
	return current

static func get_int(path: String) -> int:
	return _require_integer_value(get_value(path), path)

static func get_float(path: String) -> float:
	return _require_numeric_value(get_value(path), path)

static func get_int_range(path: String, minimum: int, maximum: int) -> int:
	if minimum > maximum:
		_fatal_config_error("Invalid integer validation range for %s: %d..%d" % [path, minimum, maximum])
	var value: int = get_int(path)
	if value < minimum or value > maximum:
		_fatal_config_error("Game-design value out of range at %s: %d (expected %d..%d)" % [path, value, minimum, maximum])
	return value

static func get_float_range(path: String, minimum: float, maximum: float) -> float:
	if minimum > maximum:
		_fatal_config_error("Invalid numeric validation range for %s: %.6f..%.6f" % [path, minimum, maximum])
	var value: float = get_float(path)
	if value < minimum or value > maximum:
		_fatal_config_error("Game-design value out of range at %s: %.6f (expected %.6f..%.6f)" % [path, value, minimum, maximum])
	return value

static func get_array(path: String) -> Array:
	var value: Variant = get_value(path)
	if !(value is Array):
		_fatal_config_error("Expected array game-design value: %s" % path)
	var result: Array = value
	return result.duplicate(true)

static func single_stage_reward(word_count: int) -> Dictionary:
	if word_count != get_int_range("economy.rewards.single_stage_level.stage_count", 1, 100):
		return {}
	var currency: String = str(get_value("economy.rewards.single_stage_level.currency"))
	if currency not in ["coins", "stars"]:
		_fatal_config_error("Invalid single-stage reward currency: %s" % currency)
	return {"currency": currency,
		"amount": get_int_range("economy.rewards.single_stage_level.amount", 1, get_int("economy.maximum_single_reward"))}

static func level_stage_count(level_number: int) -> int:
	return get_int_range("progression.quiz.questions_per_level", 1, 12) if is_quiz_level(level_number) else 1

static func campaign_quiz_difficulty(level_index: int) -> float:
	var ramp_length: int = get_int_range("difficulty.quiz_levels_to_maximum", 1, 100000)
	return lerpf(get_float("difficulty.default"), get_float("difficulty.maximum"), clampf(float(level_index) / ramp_length, 0.0, 1.0))

static func level_crossword_word_count(level_number: int) -> int:
	var count: int = _level_stage_range_value(level_number, "crossword_words")
	if is_bonus_level(level_number):
		count += get_int("progression.bonus_level.extra_crossword_words")
	return count

static func _level_stage_range_value(level_number: int, field: String) -> int:
	var resolved_level: int = maxi(level_number, 1)
	for range_variant: Variant in get_array("progression.level_stage_counts"):
		if !(range_variant is Dictionary):
			_fatal_config_error("Expected dictionary entry in progression.level_stage_counts")
		var stage_range: Dictionary = range_variant
		var from_level: int = _require_integer_field(stage_range, "from_level", "progression.level_stage_counts")
		var to_level: int = _require_integer_field(stage_range, "to_level", "progression.level_stage_counts")
		if resolved_level < from_level:
			continue
		if to_level > 0 and resolved_level > to_level:
			continue
		return _require_integer_field(stage_range, field, "progression.level_stage_counts")
	_fatal_config_error("No progression.level_stage_counts entry covers level %d" % resolved_level)
	# Unreachable after OS.crash(); parser-only return, not a runtime fallback.
	return 0

static func is_bonus_level(level_number: int) -> bool:
	var every_levels: int = get_int("progression.bonus_level.every_levels")
	return level_number > 0 and level_number % every_levels == 0

static func opening_crossword_words(level_number: int, language: String, theme_id: int) -> Array:
	var by_language: Dictionary = get_value("progression.opening_crosswords")
	var by_level: Dictionary = by_language.get(language, {})
	var by_theme: Dictionary = by_level.get(str(level_number), {})
	return Array(by_theme.get(str(theme_id), [])).duplicate()

static func is_quiz_level(level_number: int) -> bool:
	var interval: int = get_int_range("progression.quiz.level_interval", 1, 1000)
	return level_number > 0 and level_number % interval == 0 and !is_bonus_level(level_number)

static func _ensure_loaded() -> void:
	if _loaded:
		return
	if !FileAccess.file_exists(CONFIG_PATH):
		_fatal_config_error("Game-design config not found: %s" % CONFIG_PATH)
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		_fatal_config_error("Could not open game-design config: %s" % CONFIG_PATH)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if !(parsed is Dictionary):
		_fatal_config_error("Invalid JSON object in game-design config: %s" % CONFIG_PATH)
	_config = parsed
	_loaded = true
	_validate_loaded_config()

static func _validate_loaded_config() -> void:
	_validate_nonnegative_numbers(_config, "")
	get_float_range("economy.rewards.completion_coin_curve_strength", 0.0, 1.0)
	get_int_range("economy.rewards.stage_ad_multipliers_from_level", 1, 1000)
	var stage_multipliers: Array = get_array("economy.rewards.stage_ad_multipliers")
	if stage_multipliers.size() != 3:
		_fatal_config_error("Stage ad meter requires three multipliers")
	var previous_multiplier: float = 1.0
	for value: Variant in stage_multipliers:
		var multiplier: float = _require_numeric_value(value, "economy.rewards.stage_ad_multipliers")
		if multiplier <= previous_multiplier or multiplier > 10.0:
			_fatal_config_error("Stage ad multipliers must increase above one and not exceed ten")
		previous_multiplier = multiplier
	get_float_range("timings.animations.stage_reward_multiplier.traverse_seconds", 0.1, 10.0)
	get_float_range("timings.animations.stage_reward_multiplier.label_peak_scale", 1.0, 1.5)
	get_float_range("timings.animations.stage_reward_multiplier.endpoint_pause_seconds", 0.0, 2.0)
	var tournament_pool_size := get_int_range("tournament.candidate_pool_size", 9, 100)
	get_int_range("tournament.cache_minimum_fillers", 0, tournament_pool_size)
	get_float_range("tournament.filler_cis_ratio.ru", 0.0, 1.0)
	get_float_range("tournament.filler_cis_ratio.en", 0.0, 1.0)
	var tournament_duration := get_int_range("tournament.duration_seconds", 60, 604800)
	var debug_tournament_duration := tournament_duration
	if OS.is_debug_build():
		debug_tournament_duration = get_int_range("tournament.debug_duration_seconds", 60, 604800)
	get_int_range("tournament.opponent_start_delay_seconds", 1, mini(tournament_duration, debug_tournament_duration) - 1)
	get_int_range("tournament.unlock_completed_levels", 0, 1000000)
	var prizes := get_array("tournament.rewards_coins")
	if prizes.size() != 3:
		_fatal_config_error("Tournament requires three prizes")
	for prize: Variant in prizes:
		if _require_integer_value(prize, "tournament prize") > 100000:
			_fatal_config_error("Tournament prize exceeds maximum")
	var opponents := get_array("tournament.opponent_star_ranges")
	if opponents.size() != 9:
		_fatal_config_error("Tournament requires nine opponent ranges")
	for bounds: Variant in opponents:
		if !(bounds is Array) or bounds.size() != 2:
			_fatal_config_error("Tournament opponent range must contain minimum and maximum")
		var minimum := _require_integer_value(bounds[0], "tournament opponent minimum")
		var maximum := _require_integer_value(bounds[1], "tournament opponent maximum")
		if minimum > maximum or maximum > 100000:
			_fatal_config_error("Invalid tournament opponent score range")

	var minimum: float = get_float_range("difficulty.minimum", 0.0, 1.0)
	var default_difficulty: float = get_float_range("difficulty.default", 0.0, 1.0)
	var maximum: float = get_float_range("difficulty.maximum", 0.0, 1.0)
	if minimum > default_difficulty or default_difficulty > maximum:
		_fatal_config_error("Difficulty bounds must satisfy minimum <= default <= maximum")
	var wave: Array = get_array("difficulty.word_wave_order")
	if wave.is_empty():
		_fatal_config_error("difficulty.word_wave_order must not be empty")
	var ranks: Dictionary = {}
	for value: Variant in wave:
		var rank: int = _require_integer_value(value, "difficulty.word_wave_order")
		if rank < 0 or rank >= wave.size() or ranks.has(rank):
			_fatal_config_error("difficulty.word_wave_order must contain each rank once")
		ranks[rank] = true
	get_int_range("difficulty.quiz_levels_to_maximum", 1, 100000)
	if get_int("progression.bonus_level.every_levels") <= 0:
		_fatal_config_error("progression.bonus_level.every_levels must be greater than zero")
	get_int_range("progression.quiz.level_interval", 1, 1000)
	get_int_range("progression.quiz.questions_per_level", 1, 12)
	if get_int("economy.maximum_balance") <= 0:
		_fatal_config_error("economy.maximum_balance must be greater than zero")
	if get_int("economy.maximum_single_reward") > get_int("economy.maximum_balance"):
		_fatal_config_error("economy.maximum_single_reward must not exceed economy.maximum_balance")
	if get_int("economy.extra_attempts.count_step_interval") <= 0:
		_fatal_config_error("economy.extra_attempts.count_step_interval must be greater than zero")
	for ad_path: String in [
		"economy.coin_refill_ad",
		"economy.heart_refill_ad",
		"economy.extra_attempt_ad",
	]:
		if get_int(ad_path + ".maximum_views") <= 0:
			_fatal_config_error(ad_path + ".maximum_views must be greater than zero")
		if get_int(ad_path + ".cooldown_seconds") <= 0:
			_fatal_config_error(ad_path + ".cooldown_seconds must be greater than zero")
	if get_int("gameplay.max_mistakes") <= 0:
		_fatal_config_error("gameplay.max_mistakes must be greater than zero")
	var crossword_max_mistakes: int = get_int_range("gameplay.crossword_max_mistakes", 1, 64)
	get_int_range("economy.extra_attempts.base_count", 1, crossword_max_mistakes)
	get_float_range("gameplay.crossword_starters.max_known_fraction", 0.5, 0.99)
	for key: String in ["anchor_cells_by_length", "extra_cells_by_word_count"]:
		var path: String = "gameplay.crossword_starters." + key
		var budgets: Array = get_array(path)
		if budgets.is_empty():
			_fatal_config_error("Starter cell budgets must not be empty: " + path)
		var minimum_budget: int = 1 if key == "anchor_cells_by_length" else 0
		for value: Variant in budgets:
			if _require_integer_value(value, path) < minimum_budget:
				_fatal_config_error("Invalid starter cell budget: " + path)

	var hint_fade_seconds: float = get_float("timings.animations.round_end.hints_fade_seconds")
	var fullscreen_recovery: Dictionary = get_value("advertising.fullscreen_show_recovery")
	for key: String in ["queue_timeout_seconds", "return_grace_seconds", "poll_interval_seconds"]:
		if _require_numeric_field(fullscreen_recovery, key, "advertising.fullscreen_show_recovery") < 0.001:
			_fatal_config_error("Fullscreen recovery timings must be at least one millisecond")
	var retry_base := get_float("timings.network_retry.base_seconds")
	var banner_recovery: Dictionary = get_value("advertising.banner_recovery")
	get_int_range("advertising.banner_recovery.maximum_recovery_attempts", 0, 10)
	for key: String in ["load_timeout_seconds", "sdk_refresh_grace_seconds", "refresh_after_background_seconds", "retry_base_seconds", "retry_maximum_seconds", "probe_cooldown_seconds"]:
		if _require_numeric_field(banner_recovery, key, "advertising.banner_recovery") <= 0.0:
			_fatal_config_error("Banner recovery timings must be positive")
	if get_float("advertising.banner_recovery.retry_base_seconds") > get_float("advertising.banner_recovery.retry_maximum_seconds"):
		_fatal_config_error("Banner recovery retry base must not exceed maximum")
	var interstitial_recovery: Dictionary = get_value("advertising.interstitial_recovery")
	get_int_range("advertising.interstitial_recovery.maximum_recovery_attempts", 0, 10)
	for key: String in ["load_timeout_seconds", "retry_base_seconds", "retry_maximum_seconds", "probe_cooldown_seconds"]:
		if _require_numeric_field(interstitial_recovery, key, "advertising.interstitial_recovery") <= 0.0:
			_fatal_config_error("Interstitial recovery timings must be positive")
	if get_float("advertising.interstitial_recovery.retry_base_seconds") > get_float("advertising.interstitial_recovery.retry_maximum_seconds"):
		_fatal_config_error("Interstitial recovery retry base must not exceed maximum")
	var retry_maximum := get_float("timings.network_retry.maximum_seconds")
	var retry_jitter := get_float("timings.network_retry.jitter_ratio")
	if retry_base <= 0.0 or retry_maximum < retry_base or retry_jitter < 0.0 or retry_jitter > 0.5:
		_fatal_config_error("Network retry timings must satisfy 0 < base <= maximum and 0 <= jitter <= 0.5")
	var hint_badge_fade_seconds: float = get_float(
		"timings.animations.round_end.hint_badges_fade_seconds"
	)
	if hint_fade_seconds <= 0.0:
		_fatal_config_error("timings.animations.round_end.hints_fade_seconds must be greater than zero")
	if hint_badge_fade_seconds <= 0.0 or hint_badge_fade_seconds >= hint_fade_seconds:
		_fatal_config_error(
			"timings.animations.round_end.hint_badges_fade_seconds must be greater than zero and shorter than hints_fade_seconds"
		)

	var lightning_ms: int = get_int("timings.quiz_lightning_answer_window_ms")
	var fast_ms: int = get_int("timings.quiz_fast_answer_window_ms")
	if lightning_ms <= 0.0 or lightning_ms >= fast_ms:
		_fatal_config_error("Quiz answer windows must be positive and ordered")
	var fast_stars: int = get_int("economy.rewards.quick_quiz_answer_stars")
	var lightning_stars: int = get_int("economy.rewards.lightning_quiz_answer_stars")
	if fast_stars > lightning_stars:
		_fatal_config_error("Quiz speed rewards must satisfy quick <= lightning")

	var initial_window: float = get_float("difficulty.content_selection.initial_window")
	var easier_step: float = get_float("difficulty.content_selection.easier_step")
	var intro_max_harder: float = get_float("difficulty.content_selection.intro_max_harder")
	var max_harder: float = get_float("difficulty.content_selection.max_harder")
	if initial_window <= 0.0 or initial_window > 1.0:
		_fatal_config_error("difficulty.content_selection.initial_window must be in (0, 1]")
	if easier_step <= 0.0 or easier_step > 1.0:
		_fatal_config_error("difficulty.content_selection.easier_step must be in (0, 1]")
	if intro_max_harder > max_harder or max_harder > 1.0:
		_fatal_config_error("Content-selection harder ceilings are inconsistent")
	get_int_range("difficulty.content_selection.recent_count", 0, 100)

	_validate_initial_theme_ids()
	_validate_theme_unlock_milestones()
	_validate_level_stage_counts()

static func _validate_initial_theme_ids() -> void:
	var seen: Dictionary = {}
	var values: Array = get_array("progression.theme_unlocks.initial_theme_ids")
	if values.is_empty():
		_fatal_config_error("progression.theme_unlocks.initial_theme_ids must not be empty")
	for index: int in range(values.size()):
		var theme_id: int = _require_integer_value(values[index], "progression.theme_unlocks.initial_theme_ids[%d]" % index)
		if theme_id <= 0:
			_fatal_config_error("Theme IDs must be greater than zero")
		if seen.has(theme_id):
			_fatal_config_error("Duplicate initial theme ID: %d" % theme_id)
		seen[theme_id] = true

static func _validate_theme_unlock_milestones() -> void:
	var seen: Dictionary = {}
	for value: Variant in get_array("progression.theme_unlocks.initial_theme_ids"):
		seen[_require_integer_value(value, "progression.theme_unlocks.initial_theme_ids")] = true
	var previous_level: int = 0
	var milestones: Array = get_array("progression.theme_unlocks.milestones")
	for index: int in range(milestones.size()):
		var value: Variant = milestones[index]
		if !(value is Dictionary):
			_fatal_config_error("Expected dictionary at progression.theme_unlocks.milestones[%d]" % index)
		var milestone: Dictionary = value
		var context: String = "progression.theme_unlocks.milestones[%d]" % index
		var after_level: int = _require_integer_field(milestone, "after_level", context)
		var theme_id: int = _require_integer_field(milestone, "theme_id", context)
		if after_level <= previous_level:
			_fatal_config_error("Theme-unlock milestones must be strictly ordered by after_level")
		if theme_id <= 0:
			_fatal_config_error("Theme IDs must be greater than zero")
		if seen.has(theme_id):
			_fatal_config_error("Duplicate theme ID in unlock progression: %d" % theme_id)
		previous_level = after_level
		seen[theme_id] = true

static func _validate_level_stage_counts() -> void:
	var ranges: Array = get_array("progression.level_stage_counts")
	if ranges.is_empty():
		_fatal_config_error("progression.level_stage_counts must not be empty")
	var expected_start: int = 1
	var extra_words: int = get_int_range("progression.bonus_level.extra_crossword_words", 0, 11)
	for index: int in range(ranges.size()):
		var value: Variant = ranges[index]
		if !(value is Dictionary):
			_fatal_config_error("Expected dictionary at progression.level_stage_counts[%d]" % index)
		var item: Dictionary = value
		var context: String = "progression.level_stage_counts[%d]" % index
		var from_level: int = _require_integer_field(item, "from_level", context)
		var to_level: int = _require_integer_field(item, "to_level", context)
		var crossword_words: int = _require_integer_field(item, "crossword_words", context)
		if from_level != expected_start:
			_fatal_config_error("Stage-count ranges must be contiguous; %s starts at %d, expected %d" % [context, from_level, expected_start])
		if crossword_words <= 0 or crossword_words + extra_words > 12:
			_fatal_config_error("Crossword word count including bonus must be between 1 and 12 at %s" % context)
		if to_level == 0:
			if index != ranges.size() - 1:
				_fatal_config_error("Only the final stage-count range may be open-ended")
			return
		if to_level < from_level:
			_fatal_config_error("Stage-count range ends before it starts at %s" % context)
		expected_start = to_level + 1
	_fatal_config_error("Final progression.level_stage_counts range must be open-ended")

static func _validate_nonnegative_numbers(value: Variant, path: String) -> void:
	if value is Dictionary:
		var section: Dictionary = value
		for key: Variant in section.keys():
			var child_path: String = str(key) if path.is_empty() else "%s.%s" % [path, str(key)]
			_validate_nonnegative_numbers(section[key], child_path)
	elif value is Array:
		var values: Array = value
		for index: int in range(values.size()):
			_validate_nonnegative_numbers(values[index], "%s[%d]" % [path, index])
	elif value is int or value is float:
		_require_numeric_value(value, path)

static func _require_numeric_field(section: Dictionary, field: String, context: String) -> float:
	if !section.has(field):
		_fatal_config_error("Missing numeric field '%s' in game-design config: %s" % [field, context])
	return _require_numeric_value(section[field], "%s.%s" % [context, field])

static func _require_integer_field(section: Dictionary, field: String, context: String) -> int:
	if !section.has(field):
		_fatal_config_error("Missing integer field '%s' in game-design config: %s" % [field, context])
	return _require_integer_value(section[field], "%s.%s" % [context, field])

static func _require_numeric_value(value: Variant, context: String) -> float:
	if !(value is int or value is float):
		_fatal_config_error("Expected numeric game-design value: %s" % context)
	var numeric: float = float(value)
	if is_nan(numeric) or is_inf(numeric):
		_fatal_config_error("Non-finite game-design value: %s" % context)
	if numeric < 0.0:
		_fatal_config_error("Negative game-design value is not allowed at %s: %.6f" % [context, numeric])
	return numeric

static func _require_integer_value(value: Variant, context: String) -> int:
	var numeric: float = _require_numeric_value(value, context)
	if numeric != floor(numeric):
		_fatal_config_error("Expected integer game-design value at %s, got %.6f" % [context, numeric])
	return int(numeric)

static func _fatal_config_error(message: String) -> void:
	push_error(message)
	OS.crash(message)
