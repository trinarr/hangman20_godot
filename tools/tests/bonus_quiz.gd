extends Node
var checks: int = 0
var failures: int = 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func _process(_delta: float) -> void:
	if DisplayServer.get_name() == "headless":
		RenderingServer.frame_post_draw.emit()
func _ready() -> void:
	call_deferred("run")
func run() -> void:
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	GameState.single_player = {}
	GameState.active_single_player_session = {}
	GameState.pending_single_player_reward = {}
	GameState.single_player_resume_states = {}
	GameState.word_language = "ru"
	GameState.interface_language = "ru"
	Database.load_languages("ru", "ru")
	for level: int in [9, 19, 29]:
		GameState._single_player_bucket("ru")["unlocked_level"] = level
		var count: int = main._single_player_level_word_target(level)
		var combinations: Dictionary = {}
		for seed_value: int in range(60):
			GameState._single_player_bucket("ru")["level_question_slots"].erase(str(level))
			var slots: Array = main._single_player_level_question_slots(level, seed_value, count)
			check(slots.size() == 2, "Bonus must contain two quizzes")
			check(int(slots[0]) > 0 and int(slots[1]) < count - 1, "No endpoint quiz")
			check(int(slots[1]) - int(slots[0]) > 1, "No adjacent quizzes")
			check(main._single_player_level_question_slots(level, seed_value + 1, count) == slots, "Saved positions never reroll")
			combinations[str(slots)] = true
		check(combinations.size() == (3 if count == 6 else 6), "All legal pairs reachable")
	# Regular levels retain their current rules.
	for level: int in [0, 1, 2, 3, 4, 7, 18]:
		GameState._single_player_bucket("ru")["unlocked_level"] = level
		var count: int = main._single_player_level_word_target(level)
		var slots: Array = main._single_player_level_question_slots(level, 123, count)
		check(slots.size() == (0 if level == 0 else 1), "Regular quiz count unchanged")
		if level in [1, 2, 3]:
			check(slots[0] == (0 if level == 1 else 1), "Onboarding position unchanged")
	for level: int in [9, 19]:
		GameState.single_player = {}
		GameState.active_single_player_session = {}
		GameState.pending_single_player_reward = {}
		GameState._single_player_bucket("ru")["unlocked_level"] = level
		var count: int = main._single_player_level_word_target(level)
		GameState.select_single_level_theme("ru", level, 0, count)
		main._invalidate_single_player_level_cache()
		var data: Dictionary = main._single_player_level_data(level)
		var slots: Array = data.question_slots.duplicate()
		check(data.questions.size() == 2, "Both quizzes have content")
		check(data.questions[str(slots[0])].id != data.questions[str(slots[1])].id, "Questions differ")
		for slot: int in slots:
			check(GameState.get_single_level_question_id("ru", level, slot) == -1, "Preview not committed")
		var previous: int = -1
		for quiz_slot: int in slots:
			for slot: int in range(previous + 1, quiz_slot):
				GameState.mark_single_level_word_played("ru", level, slot, count, true, true, -1, false, false)
			main._invalidate_single_player_level_cache()
			main._start_single_player_question(level, quiz_slot)
			var id: int = int(main._quiz_current_question.id)
			check(GameState.get_single_level_question_id("ru", level, quiz_slot) == id, "Own stage ID committed")
			check(main._single_player_stage_reward_currency(level, quiz_slot, count) == GameState.STAGE_REWARD_COINS, "Both quizzes pay quiz rewards")
			var seen: Dictionary = GameState.get_single_player_question_history("ru", 0).duplicate(true)
			GameState.save_game()
			GameState.load_game()
			main._invalidate_single_player_level_cache()
			main._resume_saved_single_player_level()
			check(int(main._quiz_current_question.id) == id, "Resume restores correct quiz")
			check(main.single_player_active_word_slot == quiz_slot, "Resume restores correct stage")
			var restored_history: Dictionary = GameState.get_single_player_question_history("ru", 0)
			check(int(restored_history.seen_sequence) == int(seen.seen_sequence) and int(restored_history.seen_count[str(id)]) == int(seen.seen_count[str(id)]) and restored_history.recent == seen.recent, "Resume does not count another presentation")
			check(GameState.get_single_level_question_slots("ru", level) == slots, "Positions survive reload")
			var other_slot: int = int(slots[1]) if quiz_slot == int(slots[0]) else int(slots[0])
			var other_id: int = GameState.get_single_level_question_id("ru", level, other_slot)
			var replacement: Dictionary = main._quiz_replacement_question()
			check(not replacement.is_empty() and int(replacement.id) != id and int(replacement.id) != other_id, "Replacement excludes current and other assigned quiz")
			GameState.set_single_level_question_id("ru", level, int(replacement.id), false, quiz_slot)
			check(GameState.get_single_level_question_id("ru", level, other_slot) == other_id, "Replacement leaves other assignment intact")
			GameState.mark_single_level_word_played("ru", level, quiz_slot, count, true, true, -1, false, false)
			previous = quiz_slot
		GameState.reset_single_level_attempt("ru", level, true, true, false)
		check(GameState.get_single_level_question_slots("ru", level).is_empty(), "Retry clears quiz positions")
		check(GameState.get_single_level_question_id("ru", level, int(slots[0])) == -1 and GameState.get_single_level_question_id("ru", level, int(slots[1])) == -1, "Retry clears both question IDs")
	main.queue_free()
	await get_tree().process_frame
	print("BONUS_QUIZ checks=", checks, " failures=", failures)
	get_tree().quit(1 if failures else 0)
