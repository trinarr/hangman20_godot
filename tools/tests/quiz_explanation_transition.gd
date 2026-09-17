extends Node

# Isolated XDG_DATA_HOME is required: real result flows write game progress.
# Short in-memory texts isolate animation timing from editorial content.
var failures: Array[String] = []
var checks: int = 0
var expect_old_flash: bool = false

func check(ok: bool, message: String) -> void:
	checks += 1
	if !ok:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	expect_old_flash = OS.get_cmdline_user_args().has("--expect-old-flash")
	for language: String in ["ru", "en"]:
		Database.load_languages(language, language)
		var texts: Dictionary = {}
		for theme: int in range(10):
			for question: Dictionary in Database.get_quiz_questions_by_theme_index(theme):
				texts[str(int(question.id))] = ("Пояснение к ответу " if language == "ru" else "Answer explanation ") + str(question.id)
		texts.make_read_only()
		Database._quiz_explanations_by_language[language] = texts
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	for language: String in (["ru"] if expect_old_flash else ["ru", "en"]):
		Database.load_languages(language, language)
		main._start_quiz_theme(0)
		await get_tree().create_timer(1.8).timeout
		var label: Label = main._quiz_question_label
		# All edited questions must fit at the current question font size.
		for id: int in [39,92,97,127,137,327,364,366,391,395,418,427,478,558,567,608,676,707,786,792,793,798,809,830,832,842,846,857,882,901,904,914,927,935,938,940,942,945,968,1000,1007,1010,1020,1032,1038,1081,1085,1092,1094,1109,1122,1127,1128]:
			for theme: int in range(10):
				var q: Dictionary = Database.get_quiz_question_by_id(theme, id)
				if !q.is_empty():
					label.text = q.question
					check(label.get_minimum_size().y <= main.PORTRAIT_QUIZ_QUESTION_RECT.size.y, "Question overflows: %s/%d" % [language, id])
		var tiers: Array = [main.PORTRAIT_QUIZ_SPEED_LIGHTNING] if expect_old_flash else [main.PORTRAIT_QUIZ_SPEED_LIGHTNING, main.PORTRAIT_QUIZ_SPEED_FAST, main.PORTRAIT_QUIZ_SPEED_NONE]
		for tier: int in tiers:
			await exercise(main, true, tier, false)
		await exercise(main, false, main.PORTRAIT_QUIZ_SPEED_NONE, true)
		if !expect_old_flash:
			await exercise(main, true, main.PORTRAIT_QUIZ_SPEED_LIGHTNING, true)
			await exercise(main, false, main.PORTRAIT_QUIZ_SPEED_NONE, false)
	main.queue_free()
	await get_tree().process_frame
	print("Transition checks: ", checks, "; failures: ", failures.size())
	get_tree().quit(0 if failures.is_empty() else 1)

func exercise(main: Node, correct: bool, tier: int, campaign: bool) -> void:
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
	check(!explanation.is_empty(), "Test explanation missing")
	var balance: int = GameState.get_stars()
	check(main._quiz_question_label.text == question.question, "Explanation exposed before answering")
	if tier == main.PORTRAIT_QUIZ_SPEED_LIGHTNING:
		main._mark_quiz_question_ready()
	elif tier == main.PORTRAIT_QUIZ_SPEED_FAST:
		main._quiz_question_ready_at_msec = Time.get_ticks_msec() - main.PORTRAIT_QUIZ_LIGHTNING_ANSWER_WINDOW_MSEC - 1
	else:
		main._quiz_question_ready_at_msec = 0
	var index: int = int(question.correct_index)
	main._on_quiz_answer_selected(index if correct else (index + 1) % 4)
	var old_flash: bool = false
	var explanation_during_fade: bool = false
	var early_explanation: bool = false
	var deadline: int = Time.get_ticks_msec() + 10000
	while !main._quiz_continue_button.visible and Time.get_ticks_msec() < deadline:
		var label: Label = main._quiz_question_label
		if label.visible and label.modulate.a > 0.001:
			if correct or campaign:
				old_flash = old_flash or label.text != explanation
			early_explanation = early_explanation or label.text == explanation
			if label.modulate.a < 0.999 and label.text == explanation:
				explanation_during_fade = true
		await get_tree().process_frame
	check(main._quiz_continue_button.visible, "Continue never appeared")
	if expect_old_flash:
		check(old_flash, "Regression reproduction failed to detect old question")
	elif correct or campaign:
		check(!old_flash, "Original question flashed after feedback")
		check(explanation_during_fade, "Fade-in did not start with explanation")
		if correct and tier != main.PORTRAIT_QUIZ_SPEED_NONE:
			check(early_explanation, "Explanation waited for star collection")
	check(main._quiz_question_label.text == explanation, "Wrong result text")
	check(main._quiz_current_question == question, "Saved question was mutated")
	var expected: int = balance + (main._quiz_speed_reward_amount(tier) if correct else 0)
	check(GameState.get_stars() == expected, "Star reward changed")
	for node: Node in get_tree().get_nodes_in_group("stars_balance_label"):
		if node is Label and node.is_visible_in_tree():
			check(node.text == str(expected), "Continue appeared before final star balance")
	main._restore_quiz_answer_result_state()
	check(main._quiz_question_label.text == explanation and GameState.get_stars() == expected, "Restore lost text or awarded twice")
	await get_tree().create_timer(0.4).timeout
	if !campaign:
		main._on_quiz_continue_pressed()
		check(!main._quiz_answer_locked and main._quiz_question_label.text == main._quiz_current_question.question, "Next question retained result text")
	print(Database.current_language, " correct=", correct, " tier=", tier, " campaign=", campaign, " old_flash=", old_flash)
