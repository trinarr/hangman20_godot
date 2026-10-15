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
	# Production settings must never enable the real transport in debug/test runs.
	ProjectSettings.set_setting("quiz_statistics/enabled", true)
	check(!QuizStatistics.is_configured(), "Production backend blocked even when enabled in debug/test settings")
	var children_before: int = QuizStatistics.get_child_count()
	var blocked: Dictionary = await QuizStatistics._post("/auth/v1/signup", {})
	check(blocked.is_empty() and QuizStatistics.get_child_count() == children_before,
		"Direct HTTP call blocked before creating a network request")
	ProjectSettings.set_setting("quiz_statistics/enabled", false)
	ProjectSettings.set_setting("quiz_statistics/minimum_answers", 30)
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
	service.replies = [{"status": 200, "body": {"access_token": "new-access", "refresh_token": "new-refresh"}}, {"status": 200, "body": {"ok": true, "already_answered": true, "counts": [10,20,30,40]}}]
	service._flush()
	await settle(service)
	check(service._state.pending.is_empty(), "Successful retry removes pending vote")
	check(service._state.refresh_token == "new-refresh", "Refresh token rotates")
	check(service._cache.size() == 1, "Result cached after successful request")
	service.replies = [{}]
	service.record_answer(question, 0, 0, false)
	await settle(service)
	check(service._state.pending[0].p_answer == -2, "Hinted answer marks seen without a vote")
	service.replies = [{"status": 400, "body": {}}, {"status": 200, "body": {"ok": true, "already_answered": true, "counts": [1,2,3,4]}}]
	var other: Dictionary = PICK.shuffled(Database.get_quiz_questions_by_theme_index(0)[1])
	service.record_answer(other, 0, 0, true)
	await settle(service)
	check(service._state.pending.size() == 1 and service._state.pending[0].p_answer == -2, "Unknown catalog revision does not block other votes")
	service._access_token = ""
	var before_calls: int = service.calls.size()
	service.replies = [{"status": 400, "body": {}}]
	service._flush()
	await settle(service)
	check(service.calls.size() == before_calls + 1 and service.calls.back().path.contains("refresh_token"), "Unclassified auth error must not replace identity")
	service.queue_free()
	# Prefetch is read-only; a ready snapshot makes submission acknowledgement-only.
	var prefetched: Node = MOCK.new()
	add_child(prefetched)
	prefetched._access_token = "test-access"
	var key: String = prefetched.describe_question(question, 0).key
	prefetched.replies = [{"status": 200, "body": {"ok": true, "counts": [10,20,30,40], "already_answered": false}}]
	prefetched.prefetch_question(question, 0)
	await settle(prefetched)
	check(prefetched.calls[0].payload.p_answer == -1 and prefetched.calls[0].payload.p_include_counts, "Prefetch reads counters and first-attempt flag in one request")
	check(prefetched._state.pending.is_empty() and !prefetched._answered[key], "Prefetch does not consume an attempt or add a vote")
	var before: Array = prefetched._cache[key].duplicate()
	prefetched.replies = [{"status": 200, "body": {"ok": true}}]
	prefetched.record_answer(question, 0, 1, true)
	check(prefetched._cache[key][first] == before[first] + 1, "Cached first vote displayed immediately")
	await settle(prefetched)
	check(!prefetched.calls.back().payload.p_include_counts, "Cached submission requests only acknowledgement")
	check(prefetched._state.pending.is_empty(), "Acknowledgement removes pending vote without counters")
	prefetched.replies = [{"status": 200, "body": {"ok": true}}]
	prefetched.record_answer(question, 0, 2, true)
	await settle(prefetched)
	check(prefetched._cache[key][first] == before[first] + 1, "Repeat attempt never increments cached counts")
	# Player answers while a prefetch request is in flight: add the queued first answer once.
	prefetched.replies = [{"status": 200, "body": {"ok": true, "counts": [0,0,0,0], "already_answered": false}}, {"status": 200, "body": {"ok": true}}]
	prefetched.prefetch_question(other, 0)
	prefetched.record_answer(other, 0, 0, true)
	await settle(prefetched)
	var other_key: String = prefetched.describe_question(other, 0).key
	var other_index: int = prefetched.describe_question(other, 0).mapping[0]
	check(prefetched._cache[other_key][other_index] == 1 and prefetched._state.pending.is_empty(), "Answer during prefetch counted once and acknowledged")
	# Reloaded snapshots must not duplicate a vote already committed remotely.
	check(prefetched._accept_snapshot(other_key, {"counts": [2,3,4,5], "already_answered": true}), "Accept authoritative answered snapshot")
	prefetched.replies = [{"status": 200, "body": {"ok": true}}]
	prefetched.record_answer(other, 0, 1, true)
	await settle(prefetched)
	check(prefetched._cache[other_key] == [2,3,4,5], "Server answered flag prevents local repeat vote")
	# Offline hinted first attempts stay excluded even after later attempts without a hint.
	prefetched._cache[other_key] = [2,3,4,5]
	prefetched._answered[other_key] = false
	prefetched.replies = [{}]
	prefetched.record_answer(other, 0, 1, false)
	await settle(prefetched)
	check(prefetched._cache[other_key] == [2,3,4,5] and prefetched._state.pending[0].p_answer == -2, "Hinted attempt leaves cached counts unchanged")
	prefetched.replies = [{"status": 200, "body": {"ok": true}}]
	prefetched.record_answer(other, 0, 1, true)
	await settle(prefetched)
	check(prefetched._cache[other_key] == [2,3,4,5] and prefetched._state.pending.is_empty(), "Retry retains hinted first attempt and clears on acknowledgement")
	prefetched.queue_free()
	# Disabled backend must not touch the network or prevent normal quiz feedback.
	check(!QuizStatistics.is_configured(), "Backend disabled until configured")
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	main._start_quiz_theme(0)
	await get_tree().create_timer(2.0).timeout
	# 50/50 keeps the correct answer even when it is the least popular.
	var hint_identity: Dictionary = QuizStatistics.describe_question(main._quiz_current_question, 0)
	var hint_correct: int = main._quiz_correct_answer_index()
	var hint_wrong: Array = []
	for index: int in range(4):
		if index != hint_correct:
			hint_wrong.append(index)
	var hint_counts: Array = [0,0,0,0]
	for index: int in range(3):
		hint_counts[int(hint_identity.mapping[hint_wrong[index]])] = [5,10,100][index]
	QuizStatistics._cache[hint_identity.key] = hint_counts
	var ranked: Array = main._quiz_fifty_fifty_wrong_indices(hint_correct)
	check(ranked.slice(0, 2) == hint_wrong.slice(0, 2), "50/50 removes two least popular wrong answers after mapping shuffled buttons")
	check(!ranked.has(hint_correct) and ranked[2] == hint_wrong[2], "50/50 preserves correct and most popular wrong answer")
	var copied: Array = QuizStatistics.cached_answer_counts(main._quiz_current_question, 0)
	copied[hint_correct] = 999
	check(QuizStatistics._cache[hint_identity.key] == hint_counts, "50/50 does not mutate cached counters")
	ProjectSettings.set_setting("quiz_statistics/minimum_answers", 115)
	seed(1234)
	var random_order: Array = hint_wrong.duplicate()
	random_order.shuffle()
	seed(1234)
	check(main._quiz_fifty_fifty_wrong_indices(hint_correct) == random_order, "Equal-to-minimum sample uses original random selection")
	ProjectSettings.set_setting("quiz_statistics/minimum_answers", 116)
	seed(1234)
	check(main._quiz_fifty_fifty_wrong_indices(hint_correct) == random_order, "Below-minimum sample uses original random selection")
	QuizStatistics._cache.erase(hint_identity.key)
	seed(1234)
	check(main._quiz_fifty_fifty_wrong_indices(hint_correct) == random_order, "Missing prefetch does not delay 50/50 and uses random selection")
	ProjectSettings.set_setting("quiz_statistics/minimum_answers", 30)
	main._on_quiz_answer_selected(main._quiz_correct_answer_index())
	check(main._quiz_answer_locked, "Quiz completes with backend disabled")
	var identity: Dictionary = QuizStatistics.describe_question(main._quiz_current_question, 0)
	main._on_quiz_statistics_ready("stale-question", [10,20,30,40])
	check(!main._quiz_answer_buttons[0].has_node("QuizStatisticsFill"), "Late response for another question ignored")
	main._on_quiz_statistics_ready(identity.key, [1,0,0,0])
	check(!main._quiz_answer_buttons[0].has_node("QuizStatisticsFill"), "Small sample hidden")
	main._on_quiz_statistics_ready(identity.key, [10,20,30,40])
	await get_tree().create_timer(0.9).timeout
	for index: int in range(4):
		var button: Button = main._quiz_answer_buttons[index]
		var fill: ColorRect = button.get_node("QuizStatisticsFill")
		var material: ShaderMaterial = fill.material
		check(is_equal_approx(float(material.get_shader_parameter("fraction")), [0.1,0.2,0.3,0.4][int(identity.mapping[index])]), "Fill width follows shuffled answer identity")
		check(!button.has_node("QuizStatisticsPercent") and !button.has_node("QuizStatisticsBar"), "No percentages or thin bars")
		var style: StyleBoxFlat = button.get_theme_stylebox("normal")
		var expected: Color = style.bg_color.darkened(0.12)
		check(material.get_shader_parameter("fill_color") == expected, "Distribution uses darkened button background")
	await get_tree().create_timer(2.5).timeout
	for button: Button in main._quiz_answer_buttons:
		main._prepare_quiz_answer_for_replacement(button, "Next answer", 0.0)
		check(!button.has_node("QuizStatisticsFill"), "Reused button clears old distribution")
		check(!button.resized.is_connected(main._update_quiz_statistics_fill.bind(button)), "Reused button disconnects fill resize handler")
	main._on_quiz_statistics_ready(identity.key, [100,0,0,0])
	await get_tree().create_timer(0.9).timeout
	for index: int in range(4):
		var button: Button = main._quiz_answer_buttons[index]
		var material: ShaderMaterial = button.get_node("QuizStatisticsFill").material
		var expected: float = 0.92 if int(identity.mapping[index]) == 0 else 0.08
		check(is_equal_approx(float(material.get_shader_parameter("fraction")), expected), "Single populated answer capped; zero answers remain visible")
	var recolored: Button = main._quiz_answer_buttons[0]
	main._set_quiz_answer_fill(recolored, main.PORTRAIT_QUIZ_ANSWER_WRONG_COLOR)
	check(recolored.get_node("QuizStatisticsFill").material.get_shader_parameter("fill_color") == Color("#F45B77").darkened(0.12), "Late result feedback updates fill color")
	main.queue_free()
	await get_tree().process_frame
	print("QUIZ_STATISTICS checks=%d failures=%d" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
