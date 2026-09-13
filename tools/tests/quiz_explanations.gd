extends Node

# Run with an isolated XDG_DATA_HOME: these integration tests change saved progress.
var failures: Array[String] = []
var checks: int = 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if !ok:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	check(Database._quiz_explanations_by_language.is_empty(), "Explanations loaded at startup")
	Database.get_quiz_questions_by_theme_index(0)
	check(Database._quiz_explanations_by_language.is_empty(), "Question selection loaded explanations")
	check(Database.get_quiz_answer_explanation(-1).is_empty(), "Invalid ID returned text")
	check(Database._quiz_explanations_by_language.is_empty(), "Invalid ID caused I/O")
	GameState.single_player = {}
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	main._start_quiz_theme(0)
	await get_tree().create_timer(1.8).timeout
	check(Database._quiz_explanations_by_language.is_empty(), "Showing a question loaded explanations")
	var label: Label = main._quiz_question_label
	var initial_text: String = label.text
	main._show_quiz_continue_button(false)
	check(label.text == initial_text and !main._quiz_continue_button.visible, "Unanswered question exposed its explanation")
	for language: String in ["ru", "en"]:
		# Content language must be independent of interface language.
		Database.load_languages("en" if language == "ru" else "ru", language)
		var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
			"res://data/quiz_explanations_%s.json" % language))
		var ids: Dictionary = {}
		var max_height: float = 0.0
		for theme_index: int in range(10):
			for question: Dictionary in Database.get_quiz_questions_by_theme_index(theme_index):
				var id: int = int(question.id)
				var text: String = Database.get_quiz_answer_explanation(id)
				ids[str(id)] = true
				check(!text.is_empty() and text == source.explanations[str(id)], "Missing/wrong language: %s/%d" % [language, id])
				check(text != question.question and text != question.answers[int(question.correct_index)], "Explanation only repeats question/answer: %s/%d" % [language, id])
				label.text = text
				max_height = maxf(max_height, label.get_minimum_size().y)
				check(label.get_minimum_size().y <= main.PORTRAIT_QUIZ_QUESTION_RECT.size.y,
					"Explanation overflows the question area: %s/%d" % [language, id])
		check(ids.size() == 1100 and source.explanations.size() == ids.size(), "Incomplete coverage or orphan IDs: " + language)
		check(Database._quiz_explanations_by_language[language].is_read_only(), "Mutable explanation cache")
		check(Database.get_quiz_answer_explanation(999999).is_empty(), "Unknown ID returned text")
		print("Layout ", language, ": ", ids.size(), " explanations; max height ", max_height)
	check(Database._quiz_explanations_by_language.size() == 2, "Wrong language cache size")
	for language: String in ["ru", "en"]:
		Database.load_languages(language, language)
		for tier: int in [main.PORTRAIT_QUIZ_SPEED_LIGHTNING, main.PORTRAIT_QUIZ_SPEED_FAST, main.PORTRAIT_QUIZ_SPEED_NONE]:
			await exercise_answer(main, true, tier, false)
		await exercise_answer(main, false, main.PORTRAIT_QUIZ_SPEED_NONE, false)
		await exercise_answer(main, true, main.PORTRAIT_QUIZ_SPEED_LIGHTNING, true)
		await exercise_answer(main, false, main.PORTRAIT_QUIZ_SPEED_NONE, true)
	# Missing optional content preserves the question and allows progression.
	main._start_quiz_theme(0)
	await get_tree().create_timer(1.8).timeout
	initial_text = main._quiz_question_label.text
	main._quiz_current_question["id"] = 999999
	main._quiz_answer_locked = true
	main._show_quiz_continue_button(false)
	check(main._quiz_question_label.text == initial_text and main._quiz_continue_button.visible, "Missing text blocked Continue or erased question")
	main._quiz_screen_active = false
	main._quiz_continue_button.visible = false
	main._show_quiz_continue_button(false)
	check(!main._quiz_continue_button.visible, "Stale callback changed a closed quiz")
	main.queue_free()
	await get_tree().process_frame
	print("Quiz explanations: ", checks, " checks, ", failures.size(), " failures")
	get_tree().quit(0 if failures.is_empty() else 1)

func exercise_answer(main: Node, correct: bool, tier: int, campaign: bool) -> void:
	if campaign:
		GameState.single_player = {}
		GameState._single_player_bucket(Database.current_language)["unlocked_level"] = 2
		GameState.select_single_level_theme(Database.current_language, 2, 0, main._single_player_level_word_target(2))
		main._invalidate_single_player_level_cache()
		var level: Dictionary = main._single_player_level_data(2)
		main._start_single_player_question(2, int(level.question_slot))
	else:
		main._start_quiz_theme(0)
	await get_tree().create_timer(1.8).timeout
	var question: Dictionary = main._quiz_current_question.duplicate(true)
	var explanation: String = Database.get_quiz_answer_explanation(int(question.id))
	var old_balance: int = GameState.get_stars()
	check(main._quiz_question_label.text == question.question, "New question already shows an explanation")
	if tier == main.PORTRAIT_QUIZ_SPEED_LIGHTNING:
		main._mark_quiz_question_ready()
	elif tier == main.PORTRAIT_QUIZ_SPEED_FAST:
		main._quiz_question_ready_at_msec = Time.get_ticks_msec() - main.PORTRAIT_QUIZ_LIGHTNING_ANSWER_WINDOW_MSEC - 1
	else:
		main._quiz_question_ready_at_msec = 0
	var answer: int = int(question.correct_index)
	main._on_quiz_answer_selected(answer if correct else (answer + 1) % 4)
	check(main._quiz_question_label.text != explanation and !main._quiz_continue_button.visible, "Explanation appeared before feedback/reward collection")
	var deadline: int = Time.get_ticks_msec() + 10000
	while !main._quiz_continue_button.visible and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	check(main._quiz_continue_button.visible, "Result did not reach Continue")
	check(main._quiz_question_label.text == explanation and main._quiz_question_label.visible, "Result did not show explanation")
	check(main._quiz_current_question == question, "Explanation changed saved question data")
	var expected: int = old_balance + (main._quiz_speed_reward_amount(tier) if correct else 0)
	check(GameState.get_stars() == expected, "Explanation changed star award")
	for balance_label: Node in get_tree().get_nodes_in_group("stars_balance_label"):
		if balance_label is Label and balance_label.is_visible_in_tree():
			check(balance_label.text == str(expected), "Explanation appeared before final HUD balance")
	main._restore_quiz_answer_result_state()
	check(main._quiz_question_label.text == explanation and GameState.get_stars() == expected, "Restoring result lost explanation or awarded twice")
	# Let Continue's existing fade finish before replacing its control.
	await get_tree().create_timer(0.4).timeout
	if !campaign:
		main._on_quiz_continue_pressed()
		check(!main._quiz_answer_locked and main._quiz_question_label.text == main._quiz_current_question.question,
			"Next question retained result text")
	print("Answer flow ", Database.current_language, " correct=", correct, " tier=", tier, " campaign=", campaign)
