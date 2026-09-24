extends SceneTree
# Headless integration checks: real Home/Continue routing, isolated user://.
var main: Node
var state: Node
var session: Node
var database: Node
var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func _process(_delta: float) -> bool:
	# The dummy renderer never submits GPU frames. Advance only that fence;
	# navigation, saves, reward claims and scene construction run normally.
	RenderingServer.frame_post_draw.emit()
	return false

func check(value: bool, message: String) -> void:
	checks += 1
	if !value:
		failures.append(message)

func settle() -> void:
	await create_timer(5.0).timeout

func begin_level(level: int) -> void:
	main.show_menu()
	state.reset_single_level_attempt(database.current_language, level)
	main._invalidate_single_player_level_cache()
	main._show_single_player_level_popup(level)
	await settle()
	var theme: int = int(main._single_player_level_theme_options(level)[0])
	main._select_single_player_popup_theme(level, theme)
	main._start_single_player_popup_level(level)
	await settle()

func resume() -> void:
	main.show_menu()
	state.load_game()
	await settle()
	main._open_single_player_from_home(Callable(main, "_resume_saved_single_player_level"))
	await settle()

func run() -> void:
	state = root.get_node("GameState")
	session = root.get_node("GameSession")
	database = root.get_node("Database")
	state.guided_onboarding_completed = true
	state.accepted_legal_documents_version = state.LEGAL_DOCUMENTS_VERSION
	database.load_languages("ru", "ru")
	Engine.time_scale = 8.0
	root.size = Vector2i(480, 1068)
	main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await settle()
	await begin_level(0)
	check(session.is_active and main.game_screen_visible, "Word level opened")
	var text: String = session.word_data.text
	var wrongs: Array[String] = []
	for letter: String in ["А", "Б", "В", "Г", "Д", "Е", "Ж", "З", "И", "Й", "К", "Л", "М", "Н", "О", "П", "Р", "С", "Т", "У", "Ф", "Х", "Ц", "Ч", "Ш", "Щ", "Ъ", "Ы", "Ь", "Э", "Ю", "Я"]:
		if !text.contains(letter):
			wrongs.append(letter)
	session.guess(wrongs[0])
	var saved: Dictionary = session.to_save_data()
	var coins: int = state.get_soft_currency()
	var hearts: int = state.get_hearts()
	await resume()
	check(session.to_save_data() == saved, "Continue preserves word, guesses, attempts and hints")
	check(state.get_soft_currency() == coins and state.get_hearts() == hearts, "Resume does not charge currency or hearts")
	for index: int in range(1, 6):
		session.guess(wrongs[index], true)
	check(session.has_deferred_loss(), "Last-chance fixture created")
	saved = session.to_save_data()
	await resume()
	check(session.has_deferred_loss() and session.to_save_data() == saved, "Deferred last attempt survives reload")
	check(state.get_hearts() == hearts, "Pending last chance does not charge a heart")
	# Resolve loss and interrupt before result presentation can finish.
	session.resolve_deferred_loss()
	var lost_hearts: int = state.get_hearts()
	check(lost_hearts == hearts - 1, "Loss charges exactly one heart")
	await resume()
	check(state.get_hearts() == lost_hearts, "Reloaded loss does not charge another heart")
	check(state.is_single_level_completed(database.current_language, 0, 1), "Completed one-stage defeat remains recorded")
	check(!main.last_result_is_win, "Continue does not turn the recorded defeat into a win")
	await begin_level(1)
	check(main._quiz_screen_active, "Level 2 starts quiz")
	main._on_quiz_fifty_fifty_pressed()
	var hidden_indices: Array = main._quiz_fifty_fifty_hidden_indices.duplicate()
	check(hidden_indices.size() == 2, "50/50 hides two wrong answers")
	var quiz: Dictionary = state.get_active_single_player_session()
	await resume()
	check(main._quiz_screen_active, "Continue resumes quiz")
	check(main._quiz_current_question == quiz.data.question, "Quiz question and answer order survive reload")
	check(main._quiz_fifty_fifty_used and main._quiz_fifty_fifty_hidden_indices.map(func(value: Variant) -> int: return int(value)) == hidden_indices, "Used quiz hint stays used")
	check(main._quiz_question_ready_at_msec > 0, "Restored quiz timer starts after entrance")
	main._on_quiz_answer_selected(main._quiz_correct_answer_index())
	var stars_after_answer: int = state.get_stars()
	check(state.get_active_single_player_session().kind == "next", "Quiz result persists before animation")
	await resume()
	check(state.get_stars() == stars_after_answer, "Continue does not repeat quiz speed stars")
	main.queue_free()
	await process_frame
	print("RESUME_FLOW " + JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
