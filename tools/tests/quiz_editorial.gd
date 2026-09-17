extends Node

const QUIZ: GDScript = preload("res://scripts/core/quiz_selection.gd")
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
	var rng := RandomNumberGenerator.new()
	rng.seed = 100
	var questions: Array = [
		{"id": 1, "difficulty": 0.3}, {"id": 2, "difficulty": 0.34},
		{"id": 3, "difficulty": 0.9}, {"id": 4, "difficulty": 0.38}
	]
	var history: Dictionary = {"seen": {"1": true, "2": true, "4": true}, "recent": [1, 2]}
	check(QUIZ.pick(questions, .3, .08, history, rng).id == 4, "Distant unseen fact displaced a suitable repeat")
	history.recent = [1, 2, 4]
	check(QUIZ.pick(questions, .3, .08, history, rng).id == 1, "Small exhausted pool did not release its oldest recent fact")
	history.seen.erase("2")
	check(QUIZ.pick(questions, .3, .08, history, rng).id == 2, "Unseen suitable fact must be preferred")
	check(QUIZ.pick(questions, .6, .01, {}, rng).id == 4, "Empty window must use nearest grade")
	check(QUIZ.pick([questions[0]], .3, .08, {}, rng, 1).is_empty(), "Replacement cannot return its excluded question")
	check(QUIZ.pick([], .3, .08, {}, rng).is_empty(), "Empty theme should be safe")

	GameState.single_player = {}
	Database.load_languages("ru", "ru")
	var cached: Dictionary = Database.get_quiz_questions_by_theme_index(0)[0]
	var original: Dictionary = cached.duplicate(true)
	var positions: Dictionary = {}
	seed(124)
	for iteration: int in range(100):
		var presented: Dictionary = QUIZ.shuffled(cached)
		positions[presented.correct_index] = true
		check(presented.answers[int(presented.correct_index)] == original.answers[int(original.correct_index)], "Shuffle lost the correct answer")
		var restored: Dictionary = QUIZ.restore_question(presented, cached)
		check(restored == presented, "Resume reshuffled a valid question")
	check(positions.size() == 4 and cached == original, "Shuffle biased positions or mutated the cache")
	var updated: Dictionary = cached.duplicate(true)
	updated.difficulty = .4
	var shuffled: Dictionary = QUIZ.shuffled(cached)
	check(QUIZ.restore_question(shuffled, updated).answers == shuffled.answers, "Grade-only edit changed answer order")
	updated.question += " updated"
	check(QUIZ.restore_question(shuffled, updated).is_empty(), "Old wording survived an editorial change")
	check(QUIZ.restore_question(shuffled, {}).is_empty(), "Retired fact survived restore")
	var wrong_key: Dictionary = shuffled.duplicate(true)
	wrong_key.correct_index = (int(wrong_key.correct_index) + 1) % 4
	check(QUIZ.restore_question(wrong_key, cached).is_empty(), "Changed answer key was ignored")

	# Old saves retain seen status; repeats update the bounded presentation history.
	for id: int in range(1, 12):
		GameState.mark_single_player_question_seen("ru", 0, id, false)
	GameState.mark_single_player_question_seen("ru", 0, 6, false)
	var stats: Dictionary = GameState.get_single_player_question_history("ru", 0)
	check(stats.seen.size() == 11 and stats.recent.size() == 8 and stats.recent.back() == 6, "Seen/recent history lost entries or ignored a repeat")
	GameState.save_game()
	GameState.single_player = {}
	GameState.load_game()
	check(GameState.get_single_player_question_history("ru", 0) == stats, "Question history did not survive save/load")

	GameState.single_player = {}
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	var balance: int = GameState.get_soft_currency()
	for language: String in ["ru", "en"]:
		GameState._single_player_bucket(language)["unlocked_level"] = 2
		Database.load_languages(language, language)
		main._invalidate_single_player_level_cache()
		var canonical: Dictionary = Database.get_quiz_question_by_id(0, 1)
		var presented: Dictionary = QUIZ.shuffled(canonical)
		var hidden: Array = []
		for index: int in range(4):
			if index != int(presented.correct_index) and hidden.size() < 2:
				hidden.append(index)
		var snapshot: Dictionary = {"question": presented, "target_difficulty": .3,
			"fifty_fifty_used": true, "hidden_indices": hidden, "replace_question_used": true}
		check(main._restore_quiz_session_data(snapshot, 0, 2) == snapshot, "Valid saved 50/50 changed on resume: " + language)
		var stale: Dictionary = snapshot.duplicate(true)
		stale.question.question = "Old text"
		var refreshed: Dictionary = main._restore_quiz_session_data(stale, 0, 2)
		check(refreshed.question.question == canonical.question and refreshed.question.id == 1, "Edited fact did not retain ID and update text")
		check(refreshed.hidden_indices.size() == 2 and !refreshed.hidden_indices.has(int(refreshed.question.correct_index)), "Editorial refresh broke paid 50/50")
		check(refreshed.replace_question_used, "Editorial refresh reset paid replacement flag")
		GameState.set_single_level_question_id(language, 2, 13, false)
		GameState.mark_single_player_question_seen(language, 0, 13, false)
		stale.question.id = 13
		var migrated: Dictionary = main._restore_quiz_session_data(stale, 0, 2)
		check(!migrated.is_empty() and migrated.question.id != 13, "Retired saved ID failed to receive an available question")
		check(GameState.get_single_level_question_id(language, 2) == int(migrated.question.id), "Replacement of retired ID was not committed")
		check(Database.get_quiz_question_by_id(0, 13).is_empty() and !Database.get_quiz_question_by_id(0, 801).is_empty(), "Retired/new IDs are wrong")
		check(migrated.hidden_indices.size() == 2 and !migrated.hidden_indices.has(int(migrated.question.correct_index)), "Retired question lost its paid 50/50")
		# Every actual presentation path must use the shuffled copy.
		main._start_quiz_theme(0)
		var current: Dictionary = main._quiz_current_question
		var source: Dictionary = Database.get_quiz_question_by_id(0, int(current.id))
		check(current.answers[int(current.correct_index)] == source.answers[int(source.correct_index)], "Standalone quiz answer mapping is broken")
		main._on_quiz_continue_pressed()
		check(int(main._quiz_current_question.id) != int(current.id), "Standalone next repeated the current fact")
		# Closing the app during the replacement tween must not persist old 50/50
		# indices beside a different question's shuffled answers.
		main._quiz_single_player_embedded = true
		main.single_player_active_level_index = 2
		main.single_player_active_word_slot = 1
		main._quiz_fifty_fifty_used = true
		main._quiz_fifty_fifty_hidden_indices = [0, 1]
		GameState.hint_counts[GameState.HINT_QUIZ_REPLACE_QUESTION] = 1
		main._on_quiz_replace_question_pressed()
		var transition: Dictionary = GameState.get_active_single_player_session().get("data", {})
		check(!transition.is_empty() and !transition.fifty_fifty_used and transition.hidden_indices.is_empty(), "Replacement saved old 50/50 indices during animation")
		await get_tree().create_timer(1.7).timeout
	check(GameState.get_soft_currency() == balance, "Restoring edited content charged the player")
	main.queue_free()
	await get_tree().process_frame
	print("Quiz editorial checks: %d; failures: %d" % [checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
