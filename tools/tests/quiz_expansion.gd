extends Node

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
	# Use an isolated XDG_DATA_HOME: campaign fixtures deliberately write saves.
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	for language: String in ["ru", "en"]:
		GameState.single_player = {}
		Database.load_languages(language, language)
		for theme_index: int in range(Database.get_theme_count()):
			var questions: Array = Database.get_quiz_questions_by_theme_index(theme_index)
			check(questions.size() == 110, "Expected 110 questions per theme: %s/%d" % [language, theme_index])
			var added: int = 0
			for question: Dictionary in questions:
				if int(question.id) < 829 or int(question.id) > 1128:
					continue
				added += 1
				check_copy_fits(question.question, main.UI_QUESTION_COMMENT_FONT,
					main._quiz_question_font_size(question.question), main.PORTRAIT_QUIZ_QUESTION_RECT.size,
					"%s/%d question" % [language, question.id])
				for answer: String in question.answers:
					check_copy_fits(answer, main.UI_REGULAR_FONT,
						main._quiz_answer_font_size(answer), main.PORTRAIT_QUIZ_ANSWER_BUTTON_SIZE - Vector2(36, 16),
						"%s/%d answer: %s" % [language, question.id, answer])
			check(added == 30, "Expected 30 additions per theme: %s/%d" % [language, theme_index])

		# Distinct synthetic bands reveal a hidden .68 cap even when the real
		# catalog lacks hard questions. Restore the cache before any UI action.
		var theme_id: int = Database.get_theme_id(0)
		var original_pool: Array = Database._quiz_questions_by_theme_cache[theme_id]
		var fixture: Array = [{"id": 20001, "difficulty": .68}, {"id": 20002, "difficulty": .84}]
		Database._quiz_questions_by_theme_cache[theme_id] = fixture
		check(main._single_player_pick_level_question(42, 123, 0, .84, false).id == 20002,
			"Campaign picker capped the target: " + language)
		main._quiz_selected_theme_index = 0
		main._quiz_single_player_embedded = true
		main._quiz_single_player_target_difficulty = .84
		main._quiz_current_question = {"id": 20003, "difficulty": .84}
		check(main._quiz_replacement_question().id == 20002, "Replacement capped the target: " + language)
		Database._quiz_questions_by_theme_cache[theme_id] = original_pool

		GameState._single_player_bucket(language)["adaptive_difficulty"] = .82
		GameState._single_player_bucket(language)["unlocked_level"] = 2
		GameState.select_single_level_theme(language, 2, 0, main._single_player_level_word_target(2))
		main._invalidate_single_player_level_cache()
		var level: Dictionary = main._single_player_level_data(2)
		check(level.question_slot >= 0 and !level.question.is_empty(), "Missing campaign quiz fixture")
		check(level.question_target_difficulty > .68, "Stage target was capped: " + language)
		check(is_equal_approx(level.question_target_difficulty, level.words[level.question_slot].target_difficulty),
			"Quiz and hangman stage targets differ: " + language)
		check(is_equal_approx(main._single_player_level_question_target_difficulty(2), level.question_target_difficulty),
			"Target accessor capped the stage: " + language)
		var snapshot: Dictionary = {"question": level.question, "target_difficulty": .84,
			"fifty_fifty_used": false, "hidden_indices": [], "replace_question_used": false}
		var restored: Dictionary = main._restore_quiz_session_data(snapshot, 0, 2)
		check(is_equal_approx(restored.target_difficulty, .84), "Save restore capped the target: " + language)
		GameState.set_active_single_player_session({"language": language, "level_index": 2,
			"word_slot": level.question_slot, "kind": "quiz", "theme_id": theme_id, "data": snapshot})
		GameState.load_game()
		main._quiz_single_player_target_difficulty = .2
		main._resume_saved_single_player_level()
		check(is_equal_approx(main._quiz_single_player_target_difficulty, .84),
			"Resumed quiz screen capped the target: " + language)
		check(is_equal_approx(GameState.get_active_single_player_session().data.target_difficulty, .84),
			"Resume persisted a capped target: " + language)
		await get_tree().create_timer(1.7).timeout
	main.queue_free()
	await get_tree().process_frame
	print("Quiz expansion checks: %d; failures: %d" % [checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

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
