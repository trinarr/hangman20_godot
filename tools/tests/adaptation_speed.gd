extends SceneTree
# Run with isolated XDG_DATA_HOME; this project autoloads the save service.
const CONFIG = preload("res://scripts/core/game_design_config.gd")
var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if !condition:
		failures.append(message)

func run() -> void:
	check(is_equal_approx(CONFIG.difficulty_win_increase(0.18, 1), 0.01), "Early win unchanged")
	check(is_equal_approx(CONFIG.difficulty_loss_decrease(1, 0.18), 0.012), "Early loss unchanged")
	check(is_equal_approx(CONFIG.difficulty_win_increase(0.30, 1), 0.006), "Boundary selects next victory band")
	check(is_equal_approx(CONFIG.difficulty_loss_decrease(2, 0.30), 0.015), "Boundary selects next defeat band")
	check(is_equal_approx(CONFIG.difficulty_win_increase(0.50, 1), 0.0036), "Medium victory band")
	check(is_equal_approx(CONFIG.difficulty_loss_decrease(3, 0.50), 0.018), "Medium defeat streak")
	check(is_equal_approx(CONFIG.difficulty_win_increase(0.70, 6), 0.0025), "High victory streak")
	check(is_equal_approx(CONFIG.difficulty_loss_decrease(3, 0.70), 0.015), "High defeat streak")
	var original: Dictionary = CONFIG._config.duplicate(true)
	# Designers may give win streaks their own boundaries, independent of win_steps.
	CONFIG._config["difficulty"]["win_streak_multipliers"] = [
		{"below_difficulty":0.5, "streaks":[{"from_wins":1,"to_wins":0,"multiplier":2.0}]},
		{"below_difficulty":1.01, "streaks":[{"from_wins":1,"to_wins":0,"multiplier":0.5}]},
	]
	check(is_equal_approx(CONFIG.difficulty_win_increase(0.49, 4), 0.012), "Custom medium streak multiplier")
	check(is_equal_approx(CONFIG.difficulty_win_increase(0.5, 4), 0.0018), "Custom streak boundary is exclusive")
	# Original configs remain usable without nested bands.
	CONFIG._config["difficulty"]["win_streak_multipliers"] = [{"from_wins":1,"to_wins":0,"multiplier":1.25}]
	CONFIG._config["difficulty"]["loss_steps"] = [{"from_losses":1,"to_losses":0,"decrease":0.02}]
	check(is_equal_approx(CONFIG.difficulty_win_increase(0.5, 12), 0.0045), "Flat victory streak compatibility")
	check(is_equal_approx(CONFIG.difficulty_loss_decrease(12, 0.8), 0.02), "Flat defeat compatibility")
	CONFIG._config = original
	var state: Node = root.get_node("GameState")
	for won: bool in [true, false]:
		state.single_player = {}
		state._single_player_bucket("ru")["adaptive_difficulty"] = 0.75
		var result: Dictionary = state.mark_single_level_word_played("ru", 0, 0, 3, won, true, -1, false, false)
		check(is_equal_approx(result.difficulty_after, 0.752 if won else 0.744), "Stage result integrates new rate: %s" % won)
		var repeated: Dictionary = state.mark_single_level_word_played("ru", 0, 0, 3, won, true, -1, false, false)
		check(is_zero_approx(repeated.difficulty_delta), "Duplicate stage does not adapt twice")
	print("ADAPTATION_SPEED " + JSON.stringify({"checks":checks, "failures":failures}))
	quit(0 if failures.is_empty() else 1)
