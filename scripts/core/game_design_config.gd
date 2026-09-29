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

static func _difficulty_streak_ranges(path: String, current_difficulty: float) -> Array:
	var ranges: Array = get_array(path)
	if ranges.is_empty():
		_fatal_config_error("Expected non-empty difficulty streak table: %s" % path)
	# Preserve the original flat table format for configs without difficulty bands.
	if ranges[0] is Dictionary and !ranges[0].has("below_difficulty"):
		return ranges
	var difficulty: float = clampf(current_difficulty, 0.0, 1.0)
	for value: Variant in ranges:
		if !(value is Dictionary):
			_fatal_config_error("Expected dictionary difficulty streak band: %s" % path)
		var band: Dictionary = value
		var below_difficulty: float = _require_numeric_field(band, "below_difficulty", path)
		if !band.has("streaks"):
			_fatal_config_error("Missing streaks field in game-design config: %s" % path)
		if difficulty < below_difficulty:
			var streaks: Variant = band["streaks"]
			if !(streaks is Array):
				_fatal_config_error("Expected streak array in game-design config: %s" % path)
			var result: Array = streaks
			return result
	_fatal_config_error("No difficulty streak band covers difficulty %.3f: %s" % [difficulty, path])
	# Unreachable: _fatal_config_error() terminates the process via OS.crash().
	# Required only so the GDScript parser sees a return on every code path.
	return []

static func difficulty_win_increase(current_difficulty: float, win_streak: int) -> float:
	var resolved_difficulty: float = clampf(current_difficulty, 0.0, 1.0)
	var increase: float = 0.0
	var increase_found: bool = false
	for band_variant: Variant in get_array("difficulty.win_steps"):
		if !(band_variant is Dictionary):
			_fatal_config_error("Expected dictionary entry in difficulty.win_steps")
		var band: Dictionary = band_variant
		var below_difficulty: float = _require_numeric_field(band, "below_difficulty", "difficulty.win_steps")
		if resolved_difficulty < below_difficulty:
			increase = _require_numeric_field(band, "increase", "difficulty.win_steps")
			increase_found = true
			break
	if !increase_found:
		_fatal_config_error("No difficulty.win_steps entry covers difficulty %.3f" % resolved_difficulty)

	var resolved_streak: int = maxi(win_streak, 1)
	for range_variant: Variant in _difficulty_streak_ranges("difficulty.win_streak_multipliers", resolved_difficulty):
		if !(range_variant is Dictionary):
			_fatal_config_error("Expected dictionary entry in difficulty.win_streak_multipliers")
		var streak_range: Dictionary = range_variant
		var from_wins: int = _require_integer_field(streak_range, "from_wins", "difficulty.win_streak_multipliers")
		var to_wins: int = _require_integer_field(streak_range, "to_wins", "difficulty.win_streak_multipliers")
		if resolved_streak < from_wins or (to_wins > 0 and resolved_streak > to_wins):
			continue
		return increase * _require_numeric_field(streak_range, "multiplier", "difficulty.win_streak_multipliers")
	_fatal_config_error("No win-streak multiplier covers streak %d" % resolved_streak)
	# Unreachable after OS.crash(); parser-only return, not a runtime fallback.
	return 0.0

static func difficulty_loss_decrease(loss_streak: int, current_difficulty: float) -> float:
	var resolved_streak: int = maxi(loss_streak, 1)
	for range_variant: Variant in _difficulty_streak_ranges("difficulty.loss_steps", current_difficulty):
		if !(range_variant is Dictionary):
			_fatal_config_error("Expected dictionary entry in difficulty.loss_steps")
		var loss_range: Dictionary = range_variant
		var from_losses: int = _require_integer_field(loss_range, "from_losses", "difficulty.loss_steps")
		var to_losses: int = _require_integer_field(loss_range, "to_losses", "difficulty.loss_steps")
		if resolved_streak < from_losses or (to_losses > 0 and resolved_streak > to_losses):
			continue
		return _require_numeric_field(loss_range, "decrease", "difficulty.loss_steps")
	_fatal_config_error("No loss-step entry covers streak %d" % resolved_streak)
	# Unreachable after OS.crash(); parser-only return, not a runtime fallback.
	return 0.0

static func level_stage_count(level_number: int) -> int:
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
		return _require_integer_field(stage_range, "count", "progression.level_stage_counts")
	_fatal_config_error("No progression.level_stage_counts entry covers level %d" % resolved_level)
	# Unreachable after OS.crash(); parser-only return, not a runtime fallback.
	return 0

static func is_bonus_level(level_number: int) -> bool:
	var every_levels: int = get_int("progression.bonus_level.every_levels")
	return level_number > 0 and level_number % every_levels == 0

static func level_stage_count_with_bonus(level_number: int) -> int:
	var count: int = level_stage_count(level_number)
	if is_bonus_level(level_number):
		count += get_int("progression.bonus_level.extra_stages")
	return count

static func is_quiz_onboarding_level(level_number: int) -> bool:
	var from_level: int = get_int("progression.quiz.onboarding_from_level")
	var to_level: int = get_int("progression.quiz.onboarding_to_level")
	return level_number >= from_level and level_number <= to_level

static func level_uses_quiz(level_number: int, stage_count: int) -> bool:
	if is_quiz_onboarding_level(level_number):
		return stage_count >= get_int("progression.quiz.onboarding_stage_count")
	return stage_count >= get_int("progression.quiz.regular_min_stage_count")

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

	var minimum: float = get_float_range("difficulty.minimum", 0.0, 1.0)
	var default_difficulty: float = get_float_range("difficulty.default", 0.0, 1.0)
	var maximum: float = get_float_range("difficulty.maximum", 0.0, 1.0)
	if minimum > default_difficulty or default_difficulty > maximum:
		_fatal_config_error("Difficulty bounds must satisfy minimum <= default <= maximum")
	if get_float("progression.theme_intro.catch_up_rate") <= 0.0 or get_float("progression.theme_intro.catch_up_rate") > 1.0:
		_fatal_config_error("progression.theme_intro.catch_up_rate must be in (0, 1]")
	var tolerance: float = get_float("progression.theme_intro.completion_tolerance")
	if tolerance <= 0.0 or tolerance >= maximum - minimum:
		_fatal_config_error("progression.theme_intro.completion_tolerance must be positive and below the difficulty span")
	if get_int("progression.bonus_level.every_levels") <= 0:
		_fatal_config_error("progression.bonus_level.every_levels must be greater than zero")
	if get_int("progression.quiz.onboarding_from_level") <= 0:
		_fatal_config_error("progression.quiz.onboarding_from_level must be greater than zero")
	if get_int("progression.quiz.onboarding_to_level") < get_int("progression.quiz.onboarding_from_level"):
		_fatal_config_error("progression.quiz.onboarding_to_level must not precede onboarding_from_level")
	if get_int("progression.quiz.onboarding_stage_count") <= 0 or get_int("progression.quiz.regular_min_stage_count") <= 0:
		_fatal_config_error("Quiz stage-count thresholds must be greater than zero")
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

	var hint_fade_seconds: float = get_float("timings.animations.round_end.hints_fade_seconds")
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
	_validate_win_steps(maximum)
	_validate_streak_table("difficulty.win_streak_multipliers", "from_wins", "to_wins", "multiplier", maximum)
	_validate_streak_table("difficulty.loss_steps", "from_losses", "to_losses", "decrease", maximum)

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
	for index: int in range(ranges.size()):
		var value: Variant = ranges[index]
		if !(value is Dictionary):
			_fatal_config_error("Expected dictionary at progression.level_stage_counts[%d]" % index)
		var item: Dictionary = value
		var context: String = "progression.level_stage_counts[%d]" % index
		var from_level: int = _require_integer_field(item, "from_level", context)
		var to_level: int = _require_integer_field(item, "to_level", context)
		var count: int = _require_integer_field(item, "count", context)
		if from_level != expected_start:
			_fatal_config_error("Stage-count ranges must be contiguous; %s starts at %d, expected %d" % [context, from_level, expected_start])
		if count <= 0:
			_fatal_config_error("Stage count must be greater than zero at %s" % context)
		if to_level == 0:
			if index != ranges.size() - 1:
				_fatal_config_error("Only the final stage-count range may be open-ended")
			return
		if to_level < from_level:
			_fatal_config_error("Stage-count range ends before it starts at %s" % context)
		expected_start = to_level + 1
	_fatal_config_error("Final progression.level_stage_counts range must be open-ended")

static func _validate_win_steps(maximum: float) -> void:
	var steps: Array = get_array("difficulty.win_steps")
	if steps.is_empty():
		_fatal_config_error("difficulty.win_steps must not be empty")
	var previous_boundary: float = 0.0
	for index: int in range(steps.size()):
		var value: Variant = steps[index]
		if !(value is Dictionary):
			_fatal_config_error("Expected dictionary at difficulty.win_steps[%d]" % index)
		var item: Dictionary = value
		var context: String = "difficulty.win_steps[%d]" % index
		var boundary: float = _require_numeric_field(item, "below_difficulty", context)
		_require_numeric_field(item, "increase", context)
		if boundary <= previous_boundary:
			_fatal_config_error("difficulty.win_steps boundaries must be strictly increasing")
		previous_boundary = boundary
	if previous_boundary <= maximum:
		_fatal_config_error("difficulty.win_steps must cover maximum difficulty")

static func _validate_streak_table(path: String, start_key: String, end_key: String, value_key: String, maximum: float) -> void:
	var table: Array = get_array(path)
	if table.is_empty():
		_fatal_config_error("Streak table must not be empty: %s" % path)
	if !(table[0] is Dictionary):
		_fatal_config_error("Expected dictionary at %s[0]" % path)
	var first_band: Dictionary = table[0]
	var banded: bool = first_band.has("below_difficulty")
	if !banded:
		_validate_open_ended_streak_ranges(table, start_key, end_key, value_key, path)
		return
	var previous_boundary: float = 0.0
	for index: int in range(table.size()):
		var value: Variant = table[index]
		if !(value is Dictionary):
			_fatal_config_error("Expected dictionary at %s[%d]" % [path, index])
		var band: Dictionary = value
		var context: String = "%s[%d]" % [path, index]
		var boundary: float = _require_numeric_field(band, "below_difficulty", context)
		if boundary <= previous_boundary:
			_fatal_config_error("Difficulty bands must be strictly increasing: %s" % path)
		if !band.has("streaks") or !(band["streaks"] is Array):
			_fatal_config_error("Expected streak array at %s.streaks" % context)
		var streaks: Array = band["streaks"]
		_validate_open_ended_streak_ranges(streaks, start_key, end_key, value_key, context + ".streaks")
		previous_boundary = boundary
	if previous_boundary <= maximum:
		_fatal_config_error("Difficulty bands must cover maximum difficulty: %s" % path)

static func _validate_open_ended_streak_ranges(ranges: Array, start_key: String, end_key: String, value_key: String, context: String) -> void:
	if ranges.is_empty():
		_fatal_config_error("Streak ranges must not be empty: %s" % context)
	var expected_start: int = 1
	for index: int in range(ranges.size()):
		var value: Variant = ranges[index]
		if !(value is Dictionary):
			_fatal_config_error("Expected dictionary at %s[%d]" % [context, index])
		var item: Dictionary = value
		var item_context: String = "%s[%d]" % [context, index]
		var start: int = _require_integer_field(item, start_key, item_context)
		var finish: int = _require_integer_field(item, end_key, item_context)
		_require_numeric_field(item, value_key, item_context)
		if start != expected_start:
			_fatal_config_error("Streak ranges must be contiguous at %s" % item_context)
		if finish == 0:
			if index != ranges.size() - 1:
				_fatal_config_error("Only the final streak range may be open-ended: %s" % context)
			return
		if finish < start:
			_fatal_config_error("Streak range ends before it starts at %s" % item_context)
		expected_start = finish + 1
	_fatal_config_error("Final streak range must be open-ended: %s" % context)

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
