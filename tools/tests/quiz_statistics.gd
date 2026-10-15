extends Node

const PICK = preload("res://scripts/core/quiz_selection.gd")
const MOCK = preload("res://tools/tests/quiz_statistics_mock.gd")
var checks := 0
var failures := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if !condition:
		failures += 1
		push_error(message)

func _process(_delta: float) -> void:
	if DisplayServer.get_name() == "headless":
		RenderingServer.frame_post_draw.emit()

func _ready() -> void:
	call_deferred("run")

func settle(service: Node) -> void:
	for frame: int in range(100):
		if !service._busy:
			return
		await get_tree().process_frame
	check(false, "Mock request failed to settle")

func run() -> void:
	var catalog: String = FileAccess.get_file_as_string("res://supabase/migrations/002_quiz_catalog.sql")
	for language: String in ["ru", "en"]:
		Database.load_languages(language, language)
		for theme: int in range(Database.get_theme_count()):
			for canonical: Dictionary in Database.get_quiz_questions_by_theme_index(theme):
				var shuffled: Dictionary = PICK.shuffled(canonical)
				var description: Dictionary = QuizStatistics.describe_question(shuffled, theme)
				check(!description.is_empty() and catalog.contains(description.get("key", "MISSING")), "Client/server content revision mismatch")
				for index: int in range(4):
					check(shuffled.answers[index] == canonical.answers[int(description.mapping[index])], "Wrong shuffled answer mapping")
				check(QuizStatistics.describe_question(PICK.restore_question(shuffled, canonical), theme) == description, "Restored order must retain identity")
	Database.load_languages("ru", "ru")
	var question: Dictionary = PICK.shuffled(Database.get_quiz_questions_by_theme_index(0)[0])
	var service: Node = MOCK.new()
	add_child(service)
	service.replies = [{"status": 200, "body": {"access_token": "test-access", "refresh_token": "test-refresh"}}, {}]
	service.record_answer(question, 0, 1, true)
	service.record_answer(question, 0, 2, true)
	await settle(service)
	check(service._state.pending.size() == 1, "Offline queue retains first vote")
	var first: int = int(service.describe_question(question, 0).mapping[1])
	check(service._state.pending[0].p_answer == first, "Second answer must not replace first")
	var persistence: Node = load("res://scripts/services/quiz_statistics.gd").new()
	persistence._state = service._state.duplicate(true)
	persistence._save()
	persistence.free()
	var reloaded: Node = load("res://scripts/services/quiz_statistics.gd").new()
	add_child(reloaded)
	check(reloaded._state.pending.size() == 1 and reloaded._state.pending[0].p_answer == first, "Offline queue survives process restart")
	reloaded.queue_free()
	check(service.calls[0].path == "/auth/v1/signup", "New installation uses anonymous signup")
	service.replies = [{"status": 401, "body": {}}]
	service._flush()
	await settle(service)
	check(service._access_token.is_empty() and service._state.pending.size() == 1, "Expired token keeps pending vote")
	service.replies = [{"status": 200, "body": {"access_token": "new-access", "refresh_token": "new-refresh"}}, {"status": 200, "body": {"counts": [10,20,30,40]}}]
	service._flush()
	await settle(service)
	check(service._state.pending.is_empty(), "Successful retry removes pending vote")
	check(service._state.refresh_token == "new-refresh", "Refresh token rotates")
	check(service._cache.size() == 1, "Result cached after successful request")
	service.replies = [{}]
	service.record_answer(question, 0, 0, false)
	await settle(service)
	check(service._state.pending[0].p_answer == -2, "Hinted answer marks seen without a vote")
	service.replies = [{"status": 400, "body": {}}, {"status": 200, "body": {"counts": [1,2,3,4]}}]
	var other: Dictionary = PICK.shuffled(Database.get_quiz_questions_by_theme_index(0)[1])
	service.record_answer(other, 0, 0, true)
	await settle(service)
	check(service._state.pending.size() == 1 and service._state.pending[0].p_answer == -2, "Unknown catalog revision does not block other votes")
	service._access_token = ""
	var before_calls: int = service.calls.size()
	service.replies = [{"status": 400, "body": {}}]
	service._flush()
	await settle(service)
	check(service.calls.size() == before_calls + 1 and service.calls.back().path.contains("refresh_token"), "Invalid session must not silently create another player")
	service.queue_free()
	# Disabled backend must not touch the network or prevent normal quiz feedback.
	check(!QuizStatistics.is_configured(), "Backend disabled until configured")
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	main._start_quiz_theme(0)
	await get_tree().create_timer(2.0).timeout
	main._on_quiz_answer_selected(main._quiz_correct_answer_index())
	check(main._quiz_answer_locked, "Quiz completes with backend disabled")
	var identity: Dictionary = QuizStatistics.describe_question(main._quiz_current_question, 0)
	main._on_quiz_statistics_ready("stale-question", [10,20,30,40])
	check(!main._quiz_answer_buttons[0].has_node("QuizStatisticsPercent"), "Late response for another question ignored")
	main._on_quiz_statistics_ready(identity.key, [1,0,0,0])
	check(!main._quiz_answer_buttons[0].has_node("QuizStatisticsPercent"), "Small sample hidden")
	main._on_quiz_statistics_ready(identity.key, [10,20,30,40])
	for index: int in range(4):
		var button: Button = main._quiz_answer_buttons[index]
		var percent: Label = button.get_node("QuizStatisticsPercent")
		check(percent.text == "%d%%" % ([10,20,30,40][int(identity.mapping[index])]), "UI percentage follows answer identity")
	await get_tree().create_timer(2.5).timeout
	var reused: Button = main._quiz_answer_buttons[0]
	main._prepare_quiz_answer_for_replacement(reused, "Next answer", 0.0)
	check(!reused.has_node("QuizStatisticsPercent") and !reused.has_node("QuizStatisticsBar"), "Reused button clears old distribution")
	check(main._quiz_answer_label(reused).offset_right == -main.PORTRAIT_QUIZ_ANSWER_HORIZONTAL_PADDING, "Reused button restores text width")
	main.queue_free()
	await get_tree().process_frame
	print("QUIZ_STATISTICS checks=%d failures=%d" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
