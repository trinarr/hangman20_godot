extends RefCounted
class_name GameDesignConfig

const CONFIG_PATH: String = "res://data/game_design_config.json"

static var _config: Dictionary = {}
static var _loaded: bool = false

static func reload() -> void:
	_loaded = false
	_config.clear()
	_ensure_loaded()

static func get_value(path: String, fallback: Variant) -> Variant:
	_ensure_loaded()
	var current: Variant = _config
	for key: String in path.split(".", false):
		if !(current is Dictionary):
			return fallback
		var section: Dictionary = current
		if !section.has(key):
			return fallback
		current = section[key]
	return current

static func get_int(path: String, fallback: int) -> int:
	var value: Variant = get_value(path, fallback)
	if value is int or value is float:
		return maxi(int(value), 0)
	return fallback

static func get_float(path: String, fallback: float) -> float:
	var value: Variant = get_value(path, fallback)
	if value is int or value is float:
		return maxf(float(value), 0.0)
	return fallback

static func get_int_range(path: String, fallback: int, minimum: int, maximum: int) -> int:
	return clampi(get_int(path, fallback), minimum, maximum)

static func get_float_range(path: String, fallback: float, minimum: float, maximum: float) -> float:
	return clampf(get_float(path, fallback), minimum, maximum)

static func get_array(path: String, fallback: Array = []) -> Array:
	var value: Variant = get_value(path, fallback)
	return value.duplicate(true) if value is Array else fallback.duplicate(true)

static func difficulty_win_increase(current_difficulty: float, win_streak: int) -> float:
	var resolved_difficulty: float = clampf(current_difficulty, 0.0, 1.0)
	var increase: float = 0.01
	for band_variant: Variant in get_array("difficulty.win_steps"):
		if !(band_variant is Dictionary):
			continue
		var band: Dictionary = band_variant
		var below_difficulty: float = maxf(float(band.get("below_difficulty", 1.01)), 0.0)
		if resolved_difficulty < below_difficulty:
			increase = maxf(float(band.get("increase", increase)), 0.0)
			break

	var resolved_streak: int = maxi(win_streak, 1)
	var multiplier: float = 1.0
	for range_variant: Variant in get_array("difficulty.win_streak_multipliers"):
		if !(range_variant is Dictionary):
			continue
		var streak_range: Dictionary = range_variant
		var from_wins: int = maxi(int(streak_range.get("from_wins", 1)), 1)
		var to_wins: int = maxi(int(streak_range.get("to_wins", 0)), 0)
		if resolved_streak < from_wins or (to_wins > 0 and resolved_streak > to_wins):
			continue
		multiplier = maxf(float(streak_range.get("multiplier", 1.0)), 0.0)
		break
	return increase * multiplier

static func difficulty_loss_decrease(loss_streak: int) -> float:
	var resolved_streak: int = maxi(loss_streak, 1)
	var decrease: float = 0.012
	for range_variant: Variant in get_array("difficulty.loss_steps"):
		if !(range_variant is Dictionary):
			continue
		var loss_range: Dictionary = range_variant
		var from_losses: int = maxi(int(loss_range.get("from_losses", 1)), 1)
		var to_losses: int = maxi(int(loss_range.get("to_losses", 0)), 0)
		if resolved_streak < from_losses or (to_losses > 0 and resolved_streak > to_losses):
			continue
		decrease = maxf(float(loss_range.get("decrease", decrease)), 0.0)
		break
	return decrease

static func level_stage_count(level_number: int) -> int:
	var resolved_level: int = maxi(level_number, 1)
	for range_variant: Variant in get_array("progression.level_stage_counts"):
		if !(range_variant is Dictionary):
			continue
		var stage_range: Dictionary = range_variant
		var from_level: int = maxi(int(stage_range.get("from_level", 1)), 1)
		var to_level: int = maxi(int(stage_range.get("to_level", 0)), 0)
		if resolved_level < from_level:
			continue
		if to_level > 0 and resolved_level > to_level:
			continue
		return maxi(int(stage_range.get("count", 1)), 1)
	return 1

static func is_bonus_level(level_number: int) -> bool:
	var every_levels: int = get_int("progression.bonus_level.every_levels", 10)
	return level_number > 0 and every_levels > 0 and level_number % every_levels == 0

static func level_stage_count_with_bonus(level_number: int) -> int:
	var count: int = level_stage_count(level_number)
	if is_bonus_level(level_number):
		count += get_int("progression.bonus_level.extra_stages", 2)
	return maxi(count, 1)

static func is_quiz_onboarding_level(level_number: int) -> bool:
	var from_level: int = get_int("progression.quiz.onboarding_from_level", 2)
	var to_level: int = get_int("progression.quiz.onboarding_to_level", 4)
	return level_number >= from_level and level_number <= maxi(to_level, from_level)

static func level_uses_quiz(level_number: int, stage_count: int) -> bool:
	if is_quiz_onboarding_level(level_number):
		return stage_count >= get_int("progression.quiz.onboarding_stage_count", 2)
	return stage_count >= get_int("progression.quiz.regular_min_stage_count", 3)

static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	if !FileAccess.file_exists(CONFIG_PATH):
		push_error("Game-design config not found: %s" % CONFIG_PATH)
		return
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not open game-design config: %s" % CONFIG_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_config = parsed
	else:
		push_error("Invalid JSON object in game-design config: %s" % CONFIG_PATH)
