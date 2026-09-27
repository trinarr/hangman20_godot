extends SceneTree
# Run with isolated XDG_DATA_HOME; this test writes campaign saves.
var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
	call_deferred("run")

func _process(_delta: float) -> bool:
	RenderingServer.frame_post_draw.emit()
	return false

func check(ok: bool, message: String) -> void:
	checks += 1
	if !ok:
		failures.append(message)

func run() -> void:
	var state: Node = root.get_node("GameState")
	var database: Node = root.get_node("Database")
	database.load_languages("ru", "ru")
	state.word_language = "ru"
	state.single_player = {}
	state.active_single_player_session = {}
	state.pending_single_player_reward = {}
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	database.load_languages("ru", "ru")
	state.word_language = "ru"
	state.interface_language = "ru"
	state.single_player = {}
	state._single_player_bucket("ru")["adaptive_difficulty"] = 0.8
	state._single_player_bucket("ru")["theme_unlock_completed_levels"] = 3
	state._single_player_bucket("ru")["unlocked_level"] = 2
	state.select_single_level_theme("ru", 2, 5, 3)
	main._invalidate_single_player_level_cache()
	main.single_player_active_level_index = 2
	main.single_player_active_word_slot = 0
	var first: Dictionary = main._single_player_mark_current_word_finished({}, true, true, true, false)
	check(first.has("difficulty_debug"), "Debug result has snapshot")
	check(is_equal_approx(first.difficulty_debug.global, 0.802), "Snapshot contains post-result global difficulty")
	check(is_equal_approx(first.difficulty_debug.delta, 0.002), "Snapshot contains actual win delta")
	check(first.difficulty_debug.intro_active and first.difficulty_debug.win_streak == 1, "Snapshot contains intro and streak")
	main.last_result_data = first
	var text: String = main._difficulty_debug_text(5)
	check(text.contains("+0.0020") and text.contains("Вводный режим: да"), "Toast formats increase and intro")
	state.save_game()
	state.load_game()
	var restored: Dictionary = state.get_active_single_player_session().data.result
	check(is_equal_approx(restored.difficulty_debug.delta, first.difficulty_debug.delta), "Snapshot survives restart")
	main.single_player_active_word_slot = 1
	var second: Dictionary = main._single_player_mark_current_word_finished({}, false, true, true, false)
	main.last_result_data = second
	text = main._difficulty_debug_text(5)
	check(text.contains("-0.0060") and text.contains("поражения × 1"), "Quiz defeat formats decrease and losing streak")
	main.single_player_active_word_slot = 2
	var last: Dictionary = main._single_player_mark_current_word_finished({}, true, true, true, false)
	main.last_result_data = last
	main.last_result_is_win = true
	main._home_logo_reveal = null
	main._portrait_single_reward_resume_without_intro = true
	main._show_single_player_reward_chain_screen()
	var button: Control = main._portrait_single_reward_continue_button
	check(is_instance_valid(button) and !bool(button.get("disabled")), "Debug final stage has enabled Continue")
	check(main.content.has_node("DifficultyDebugToast"), "Chain shows debug toast")
	main._auto_advance_final_stage_reward()
	await process_frame
	check(!bool(main.last_result_data.get("single_player_level_summary_view", false)), "Debug automatic advance is blocked")
	main._continue_from_single_player_reward_chain()
	check(bool(main.last_result_data.get("single_player_level_summary_view", false)), "Continue opens main level reward")
	main.last_result_data = {}
	check(main._difficulty_debug_text(0).contains("нет данных"), "Old saves do not invent a delta")
	main.queue_free()
	await process_frame
	print("DEBUG_CHAIN " + JSON.stringify({"checks": checks, "failures": failures}))
	quit(0 if failures.is_empty() else 1)
