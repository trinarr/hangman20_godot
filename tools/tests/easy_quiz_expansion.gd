extends SceneTree

const PICK = preload("res://scripts/core/quiz_selection.gd")
const FONTS = preload("res://scripts/ui/ui_fonts.gd")
const FIRST_ID: int = 1329
const LAST_ID: int = 1928
var checks: int = 0
var failures: int = 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if !ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func remember(history: Dictionary, id: int) -> void:
	var key := str(id)
	history.seen_count[key] = int(history.seen_count.get(key, 0)) + 1
	history.sequence += 1
	history.last_seen[key] = history.sequence
	history.recent.erase(key)
	history.recent.append(key)
	history.recent = history.recent.slice(maxi(0, history.recent.size() - 8))

func copy_fits(text: String, context: String) -> void:
	var label := Label.new()
	label.add_theme_font_override("font", FONTS.question_comment_font())
	label.add_theme_font_size_override("font_size", 25)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size = Vector2(400.0, 224.0)
	label.text = text
	root.add_child(label)
	check(label.get_minimum_size().y <= 224.0, "Portrait copy overflow: " + context)
	label.free()

func run() -> void:
	var database: Node = root.get_node("Database")
	var state: Node = root.get_node("GameState")
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261004
	# Assert the measurements still match the actual shipped UI, without
	# instantiating the full campaign or replacing its balance with fixtures.
	var ui_source: String = FileAccess.get_file_as_string("res://scripts/main_portrait.gd")
	check(ui_source.contains("PORTRAIT_QUIZ_QUESTION_RECT := Rect2(40.0, 138.0, 400.0, 224.0)"), "Question layout changed; update measurements")
	check(ui_source.contains("PORTRAIT_QUIZ_ANSWER_BUTTON_SIZE := Vector2(412.0, 68.0)"), "Answer layout changed; update measurements")
	for language: String in ["ru", "en"]:
		database.load_languages("en" if language == "ru" else "ru", language)
		var added_total: int = 0
		for theme: int in range(database.get_theme_count()):
			var pool: Array = database.get_quiz_questions_by_theme_index(theme)
			check(pool.size() >= 190, "Expanded theme did not load: %s/%d" % [language, theme])
			var old_history: Dictionary = {"seen_count": {}, "last_seen": {}, "recent": [], "sequence": 0}
			var added: Array = []
			var easy_count: int = 0
			for q: Dictionary in pool:
				var id: int = int(q.id)
				if id < FIRST_ID:
					old_history.seen_count[str(id)] = 1
				if id < FIRST_ID or id > LAST_ID:
					continue
				added.append(q)
				if float(q.difficulty) <= .16:
					easy_count += 1
				copy_fits(q.question, "%s/%d question" % [language, id])
				var explanation: String = database.get_quiz_answer_explanation(id)
				check(!explanation.is_empty(), "New explanation unavailable")
				copy_fits(explanation, "%s/%d explanation" % [language, id])
				for answer: String in q.answers:
					var width: float = FONTS.regular_font().get_string_size(answer, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20).x
					check(width <= 376.01, "Portrait answer overflow: %s/%d %.2fpx %s" % [language, id, width, answer])
			check(added.size() == 60 and easy_count == 40, "New quotas differ: %s/%d" % [language, theme])
			added_total += added.size()
			# Old save history marks only old IDs: all forty new easy facts
			# must remain playable before returning an already-seen old fact.
			for turn: int in range(40):
				var picked: Dictionary = PICK.pick(pool, .08, old_history, rng)
				check(!picked.is_empty(), "Missing low-floor candidate")
				if picked.is_empty():
					continue
				check(int(picked.id) >= FIRST_ID and int(picked.id) <= LAST_ID, "Repeated an old fact before new easy facts")
				check(!old_history.seen_count.has(str(picked.id)), "Repeated before exhausting new easy facts")
				check(float(picked.difficulty) <= .160001, "Low-floor picker exceeded cap")
				remember(old_history, int(picked.id))
		check(added_total == 600, "Wrong additions per language")
	# A released ID and a newly added ID can coexist in the unchanged save schema.
	state.single_player = {}
	state.mark_single_player_question_seen("ru", 0, 1, true)
	state.mark_single_player_question_seen("ru", 0, FIRST_ID, false)
	state.save_game()
	state.load_game()
	var restored: Dictionary = state.get_single_player_question_history("ru", 0)
	check(restored.seen_count.has("1") and restored.seen_count.has(str(FIRST_ID)), "Old/new IDs lost on save reload")
	check(state.get_single_player_question_history("en", 0).seen_count.is_empty(), "Language histories mixed")
	print("EASY_QUIZ_EXPANSION checks=", checks, " failures=", failures)
	quit(1 if failures else 0)
