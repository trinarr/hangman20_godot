extends SceneTree
# Use an isolated XDG_DATA_HOME: this test deliberately writes and reloads saves.
const CONFIG = preload("res://scripts/core/game_design_config.gd")
var checks: int = 0
var failures: Array[String] = []
var state: Node
var database: Node

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if !condition:
		failures.append(message)

func fresh(global_difficulty: float) -> void:
	state.single_player = {}
	state.active_single_player_session = {}
	state.pending_single_player_reward = {}
	state.single_player_resume_states = {}
	state._single_player_bucket("ru")["adaptive_difficulty"] = global_difficulty

func target(theme: int = 5, language: String = "ru") -> float:
	return state.get_single_player_theme_target_difficulty(language, theme, state.get_single_player_adaptive_difficulty(language))

func finish(slot: int, won: bool = true, theme: int = 5) -> void:
	state.mark_single_level_word_played("ru", 0, slot, 30, won, true, -1, false, false, theme)

func run() -> void:
	preload("res://tools/tests/mechanics_fixture.gd").apply(root.get_node("GameState"))
	state = root.get_node("GameState")
	database = root.get_node("Database")
	database.load_languages("ru", "ru")
	state.word_language = "ru"
	state.interface_language = "ru"
	fresh(0.8)
	for theme: int in [0, 8, 1]:
		check(is_equal_approx(target(theme), 0.8), "Starter theme immediately uses global difficulty: %s" % theme)
		var key: String = str(database.get_theme_id(theme))
		state._single_player_bucket("ru")["theme_intro"][key] = {"difficulty": 0.08, "completed": false}
		check(is_equal_approx(target(theme), 0.8), "Starter intro from previous build is bypassed: %s" % theme)
		check(bool(state._single_player_bucket("ru")["theme_intro"][key]["completed"]), "Starter intro is permanently retired")
	check(is_equal_approx(state.get_single_player_theme_target_difficulty("ru", 0, 0.74), 0.74), "Starter preserves normal chain spread")
	fresh(0.8)
	check(is_equal_approx(target(), 0.08), "New theme starts at minimum")
	finish(0)
	var first: float = target()
	check(is_equal_approx(first, 0.08 + (0.802 - 0.08) * 0.25), "Win closes a fraction of the updated global gap")
	finish(0)
	check(is_equal_approx(target(), first), "Duplicate result cannot advance intro")
	finish(1, false)
	check(is_equal_approx(target(), first), "Defeat does not advance intro")
	state.mark_single_level_word_played("ru", 0, 3, 30, false, false, -1, false, false, 5)
	check(is_equal_approx(target(), first), "Forfeit does not advance intro")
	finish(2, true, -1)
	check(is_equal_approx(target(), first), "Result without a theme does not advance intro")
	check(is_equal_approx(target(2), 0.08), "Themes have independent intro state")
	state._single_player_bucket("en")["adaptive_difficulty"] = 0.8
	check(is_equal_approx(target(5, "en"), 0.08), "Languages have independent intro state")
	fresh(0.4)
	target()
	finish(0)
	check(target() - 0.08 < first - 0.08, "Larger gap gives larger catch-up step")
	fresh(0.86)
	target()
	var wins: int = 0
	while target() < 0.86 and wins < 30:
		finish(wins)
		wins += 1
	check(wins == 11, "At fixed cap intro completes after eleven wins with fixed fixture")
	state._single_player_bucket("ru")["adaptive_difficulty"] = 0.3
	check(is_equal_approx(target(), 0.3), "Completed theme follows lowered global difficulty")
	state._single_player_bucket("ru")["adaptive_difficulty"] = 0.86
	check(is_equal_approx(target(), 0.86), "Completed intro never restarts")
	state.save_game()
	state.single_player = {}
	state.load_game()
	check(is_equal_approx(target(), 0.86), "Completed flag survives restart")
	fresh(0.8)
	target()
	finish(0)
	state._single_player_bucket("ru")["adaptive_difficulty"] = 0.1
	check(is_equal_approx(target(), 0.1), "Global falling below intro completes it without a harder target")
	state._single_player_bucket("ru")["adaptive_difficulty"] = 0.8
	check(is_equal_approx(target(), 0.8), "Completion caused by falling global is permanent")
	fresh(0.8)
	var history: Dictionary = state.ensure_single_player_theme_progress("ru", 5, 0)
	history["played"][database.get_word_progress_key(5, 0)] = true
	check(is_equal_approx(target(), 0.8), "Legacy played theme skips intro")
	check(is_equal_approx(target(2), 0.08), "Legacy untouched theme still starts intro")
	fresh(0.8)
	state._single_player_question_theme_stats("ru", 5)["seen"]["1"] = true
	check(is_equal_approx(target(), 0.8), "Legacy quiz history skips intro")
	fresh(0.8)
	state.mark_single_player_question_seen("ru", 5, 1, false)
	check(is_equal_approx(target(), 0.08), "First quiz presentation initializes intro before history")

	fresh(0.8)
	state.mark_single_player_word_shown("ru", 5, 0, 0, "", false)
	state.mark_single_player_word_guessed("ru", 5, 0, 0, "", false)
	check(is_equal_approx(target(), 0.08), "First display initializes before played/guessed history")
	finish(0)
	var saved_target: float = target()
	check(state.save_game(), "Intro save succeeds")
	state.single_player = {}
	state.load_game()
	check(is_equal_approx(target(), saved_target), "Intro progress survives save/load")
	finish(0)
	check(is_equal_approx(target(), saved_target), "Replayed saved result cannot advance again")
	state.reset_single_level_attempt("ru", 0, true, true, false)
	check(is_equal_approx(target(), saved_target), "Chain reset does not reset theme intro")
	fresh(0.8)
	var intro: Dictionary = state._single_player_theme_intro("ru", 5)
	intro["difficulty"] = 0.759
	check(is_equal_approx(target(), 0.759), "Outside tolerance remains in intro")
	intro["difficulty"] = 0.761
	check(is_equal_approx(target(), 0.8), "Inside tolerance switches to global")
	var original: Dictionary = CONFIG._config.duplicate(true)
	CONFIG._config["progression"]["theme_intro"]["catch_up_rate"] = 1.0
	fresh(0.8)
	target()
	finish(0)
	check(is_equal_approx(target(), state.get_single_player_adaptive_difficulty("ru")), "Configured catch-up rate is used")
	CONFIG._config = original
	# Exercise the actual selector and result pipeline, including cached levels.
	var main: Node = load("res://scripts/main.gd").new()
	fresh(0.86)
	var level: int = 2
	var count: int = main._single_player_level_word_target(level)
	state._single_player_bucket("ru")["unlocked_level"] = level
	state._single_player_bucket("ru")["theme_unlock_completed_levels"] = 3
	state.select_single_level_theme("ru", level, 5, count)
	main._invalidate_single_player_level_cache()
	var before: Dictionary = main._single_player_level_data(level).duplicate(true)
	check(is_equal_approx(before.words[0].target_difficulty, 0.08), "Actual first word uses minimum intro difficulty")
	check(before.question_slot == 1 and !before.question.is_empty(), "Quiz fixture available")
	check(is_equal_approx(before.question_target_difficulty, 0.08), "Quiz uses shared theme intro target")
	main.single_player_active_level_index = level
	main.single_player_active_word_slot = 0
	main._single_player_mark_current_word_finished({}, true, true, false, false)
	var after: Dictionary = main._single_player_level_data(level).duplicate(true)
	check(after.words[0] == before.words[0], "Committed assignment survives intro advance")
	check(is_equal_approx(after.words[2].target_difficulty, 0.275), "Next word target updates even at global cap")
	check(is_equal_approx(after.question_target_difficulty, 0.275), "Word win updates the following quiz target")
	var after_word: float = target()
	main.single_player_active_word_slot = 1
	main._single_player_mark_current_word_finished({}, true, true, false, false)
	check(is_equal_approx(target(), after_word + (0.86 - after_word) * 0.25), "Actual quiz win advances shared intro")
	var after_quiz: float = target()
	main._single_player_mark_current_word_finished({}, true, true, false, false)
	check(is_equal_approx(target(), after_quiz), "Duplicate quiz result does not advance intro twice")
	after = main._single_player_level_data(level).duplicate(true)
	check(is_equal_approx(after.words[2].target_difficulty, after_quiz), "Quiz win updates the following word target")
	check(state.save_game(), "Save with committed next word succeeds")
	state.single_player = {}
	state.load_game()
	main._invalidate_single_player_level_cache()
	var resumed: Dictionary = main._single_player_level_data(level)
	check(resumed.words[2].id == after.words[2].id
		and resumed.words[2].text == after.words[2].text
		and int(resumed.words[2].theme_index) == int(after.words[2].theme_index)
		and is_equal_approx(resumed.words[2].target_difficulty, after.words[2].target_difficulty),
		"Continue keeps the exact assigned word and target")
	main.free()
	print("THEME_INTRO " + JSON.stringify({"checks": checks, "failures": failures}))
	quit(0 if failures.is_empty() else 1)
