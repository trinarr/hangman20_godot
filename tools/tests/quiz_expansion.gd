extends Node

var failures: Array[String] = []
var checks: int = 0

const QUIZ_ANSWER_CONTENT_WIDTH: float = 376.0

func check(ok: bool, message: String) -> void:
	checks += 1
	if !ok:
		failures.append(message)
		push_error(message)

func _process(_delta: float) -> void:
	if DisplayServer.get_name() == "headless":
		RenderingServer.frame_post_draw.emit()

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	preload("res://tools/tests/mechanics_fixture.gd").apply(GameState)
	# Use an isolated XDG_DATA_HOME: campaign fixtures deliberately write saves.
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	var quiz_answer_content_width: float = (
		main.PORTRAIT_QUIZ_ANSWER_BUTTON_SIZE.x
		- main.PORTRAIT_QUIZ_ANSWER_HORIZONTAL_PADDING * 2.0
	)
	check(
		is_equal_approx(quiz_answer_content_width, QUIZ_ANSWER_CONTENT_WIDTH),
		"Quiz answer content width changed: %.2f px (expected %.0f px)" % [
			quiz_answer_content_width,
			QUIZ_ANSWER_CONTENT_WIDTH,
		]
	)
	for language: String in ["ru", "en"]:
		GameState.single_player = {}
		GameState.active_single_player_session = {}
		GameState.pending_single_player_reward = {}
		GameState.single_player_resume_states = {}
		GameState.word_language = language
		GameState.interface_language = language
		Database.load_languages(language, language)
		for theme_index: int in range(Database.get_theme_count()):
			var questions: Array = Database.get_quiz_questions_by_theme_index(theme_index)
			check(!questions.is_empty(), "Expected questions in theme: %s/%d" % [language, theme_index])
			for question: Dictionary in questions:
				check_copy_fits(question.question, main.UI_QUESTION_COMMENT_FONT,
					main._quiz_question_font_size(question.question), main.PORTRAIT_QUIZ_QUESTION_RECT.size,
					"%s/%d question" % [language, question.id])
				for answer: String in question.answers:
					check_answer_fits_one_line(
						answer,
						main.UI_REGULAR_FONT,
						main._quiz_answer_font_size(answer),
						quiz_answer_content_width,
						"%s/%d answer: %s" % [language, question.id, answer]
					)

		# Distinct synthetic bands reveal a hidden .68 cap even when the real
		# catalog lacks hard questions. Restore the cache before any UI action.
		var theme_id: int = Database.get_theme_id(0)
		var original_pool: Array = Database._quiz_questions_by_theme_cache[theme_id]
		var fixture: Array = [{"id": 20001, "difficulty": .68}]
		for question_id: int in range(20010, 20022):
			fixture.append({"id": question_id, "difficulty": .84})
		Database._quiz_questions_by_theme_cache[theme_id] = fixture
		check(main._single_player_pick_level_question(42, 123, 0, .84, false).difficulty == .84,
			"Campaign picker capped the target: " + language)
		main._quiz_selected_theme_index = 0
		main._quiz_single_player_embedded = true
		main._quiz_single_player_target_difficulty = .84
		main._quiz_current_question = {"id": 20003, "difficulty": .84}
		check(main._quiz_replacement_question().difficulty == .84, "Replacement capped the target: " + language)
		Database._quiz_questions_by_theme_cache[theme_id] = original_pool

		GameState._single_player_bucket(language)["adaptive_difficulty"] = .82
		GameState._single_player_bucket(language)["unlocked_level"] = 2
		GameState.select_single_level_theme(language, 2, 0, main._single_player_level_word_target(2))
		main._invalidate_single_player_level_cache()
		var level: Dictionary = main._single_player_level_data(2)
		check(level.question_slots[0] >= 0 and !level.questions[str(level.question_slots[0])].is_empty(), "Missing campaign quiz fixture")
		check(level.question_targets[str(level.question_slots[0])] > .68, "Stage target was capped: " + language)
		check(is_equal_approx(level.question_targets[str(level.question_slots[0])], level.words[level.question_slots[0]].target_difficulty),
			"Quiz and hangman stage targets differ: " + language)
		check(is_equal_approx(main._single_player_level_question_target_difficulty(2), level.question_targets[str(level.question_slots[0])]),
			"Target accessor capped the stage: " + language)
		var snapshot: Dictionary = {"question": level.questions[str(level.question_slots[0])], "target_difficulty": .84,
			"fifty_fifty_used": false, "hidden_indices": [], "replace_question_used": false}
		var restored: Dictionary = main._restore_quiz_session_data(snapshot, 0, 2)
		check(is_equal_approx(restored.target_difficulty, .84), "Save restore capped the target: " + language)
		for slot: int in range(int(level.question_slots[0])):
			GameState.mark_single_level_word_played(language, 2, slot,
				main._single_player_level_word_target(2), true, true, -1, false, false)
		GameState.set_active_single_player_session({"language": language, "level_index": 2,
			"word_slot": level.question_slots[0], "kind": "quiz", "theme_id": theme_id, "data": snapshot})
		GameState.load_game()
		main._quiz_single_player_target_difficulty = .2
		main._resume_saved_single_player_level()
		check(is_equal_approx(main._quiz_single_player_target_difficulty, .84),
			"Resumed quiz screen capped the target: " + language)
		check(is_equal_approx(Dictionary(GameState.get_active_single_player_session().get("data", {})).get("target_difficulty", -1.0), .84),
			"Resume persisted a capped target: " + language)
		await get_tree().create_timer(1.7).timeout
		await check_editorial_resume(main, language, int(level.question_slots[0]))
	main.queue_free()
	await get_tree().process_frame
	print("Quiz expansion checks: %d; failures: %d" % [checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func check_editorial_resume(main: Node, language: String, slot: int) -> void:
	var selection: GDScript = preload("res://scripts/core/quiz_selection.gd")
	var canonical: Dictionary = Database.get_quiz_question_by_id(0, int(main._quiz_current_question.id))
	var presented: Dictionary = selection.shuffled(canonical)
	var hidden: Array = []
	for index in range(4):
		if index != int(presented.correct_index) and hidden.size() < 2:
			hidden.append(index)
	var snapshot: Dictionary = {"question": presented, "target_difficulty": .84, "fifty_fifty_used": true, "hidden_indices": hidden, "replace_question_used": true}
	var before: int = GameState.get_soft_currency()
	check(main._restore_quiz_session_data(snapshot, 0, 2, slot) == snapshot, "Valid resume preserves paid 50/50 and replacement flags: " + language)
	var stale: Dictionary = snapshot.duplicate(true)
	stale.question.question = "Outdated test wording"
	var refreshed: Dictionary = main._restore_quiz_session_data(stale, 0, 2, slot)
	check(refreshed.question.question == canonical.question and refreshed.question.id == canonical.id, "Edited question keeps its ID and receives current wording: " + language)
	check(refreshed.hidden_indices.size() == 2 and !refreshed.hidden_indices.has(int(refreshed.question.correct_index)) and refreshed.replace_question_used, "Editorial refresh preserves paid hints with valid answer indices: " + language)
	# Exercise the real resume consumer: it owns the updated slot assignment/save.
	stale.question.id = 13
	GameState.set_single_level_question_id(language, 2, 13, false, slot)
	GameState.set_active_single_player_session({"language": language, "level_index": 2, "word_slot": slot, "kind": "quiz", "theme_id": Database.get_theme_id(0), "data": stale})
	GameState.load_game()
	main._invalidate_single_player_level_cache()
	main._resume_saved_single_player_level()
	await get_tree().create_timer(1.7).timeout
	var data: Dictionary = GameState.get_active_single_player_session().get("data", {})
	check(!data.is_empty() and int(data.question.id) != 13, "Retired saved question receives a playable replacement: " + language)
	check(GameState.get_single_level_question_id(language, 2, slot) == int(data.question.id), "Resume persists the replacement in its original slot: " + language)
	check(Database.get_quiz_question_by_id(0, 13).is_empty() and !Database.get_quiz_question_by_id(0, 801).is_empty(), "Retired and replacement IDs keep their published identities: " + language)
	check(data.hidden_indices.size() == 2 and !data.hidden_indices.has(int(data.question.correct_index)) and data.replace_question_used, "Retired-question resume preserves paid hint state: " + language)
	# A new replacement must be durable before its first animation await.
	GameState._single_player_bucket(language)["unlocked_level"] = 3
	main._quiz_replace_question_used = false
	main._quiz_fifty_fifty_used = true
	main._quiz_fifty_fifty_hidden_indices = data.hidden_indices.duplicate()
	GameState.hint_counts[GameState.HINT_QUIZ_REPLACE_QUESTION] = 1
	var previous_id: int = int(main._quiz_current_question.id)
	main._on_quiz_replace_question_pressed()
	var transition: Dictionary = GameState.get_active_single_player_session().get("data", {})
	check(!transition.is_empty() and int(transition.question.id) != previous_id and transition.replace_question_used and !transition.fifty_fifty_used and transition.hidden_indices.is_empty(), "Replacement immediately saves a consistent question without old 50/50 indices: " + language)
	GameState.load_game()
	# Preserve every serialized value while allowing JSON's numeric conversion.
	check(GameState.get_active_single_player_session().get("data", {}) == JSON.parse_string(JSON.stringify(transition)), "Replacement snapshot survives reload during its animation: " + language)
	main._clear()
	await get_tree().process_frame
	main._start_quiz_theme(0)
	await get_tree().create_timer(1.7).timeout
	var current: Dictionary = main._quiz_current_question
	var source: Dictionary = Database.get_quiz_question_by_id(0, int(current.id))
	check(current.answers[int(current.correct_index)] == source.answers[int(source.correct_index)], "Standalone presentation keeps the shuffled correct-answer mapping: " + language)
	check(GameState.get_soft_currency() == before, "Content refresh and stocked replacement do not charge coins: " + language)
	main._clear()

func check_copy_fits(copy: String, font: Font, font_size: int, available: Vector2, context: String) -> void:
	var label := Label.new()
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size = available
	label.text = copy
	add_child(label)
	# Same fonts, wrap mode and authored content rectangle as the portrait UI.
	check(label.get_minimum_size().y <= available.y, "Text overflows: " + context)
	label.free()

func check_answer_fits_one_line(
	copy: String,
	font: Font,
	font_size: int,
	available_width: float,
	context: String
) -> void:
	# Quiz answer labels never wrap in the real UI. Measure the exact font
	# variation and authored size instead of allowing the test label to wrap.
	var required_width: float = font.get_string_size(
		copy,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		font_size
	).x
	check(
		required_width <= available_width + 0.01,
		"Answer exceeds %.0f px (needs %.2f px): %s" % [
			available_width,
			required_width,
			context,
		]
	)
