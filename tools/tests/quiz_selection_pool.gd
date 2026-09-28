extends SceneTree

const PICK = preload("res://scripts/core/quiz_selection.gd")
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
	history.seen[str(id)] = true
	history.recent.erase(id)
	history.recent.append(id)
	history.recent = history.recent.slice(maxi(0, history.recent.size() - 8))

func run() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 123
	var questions: Array = []
	for id: int in range(20):
		questions.append({"id": id, "difficulty": 0.1 + id * 0.025})
	var original: Array = questions.duplicate(true)
	var history: Dictionary = {"seen": {}, "recent": []}
	for turn: int in range(12):
		var q: Dictionary = PICK.pick(questions, .86, .08, history, rng)
		check(int(q.id) >= 8, "Expansion must use the nearest twelve grades")
		check(!history.seen.has(str(q.id)), "Prefer unseen expanded candidates")
		remember(history, int(q.id))
	var saved_history: Dictionary = history.duplicate(true)
	var picked: Dictionary = PICK.pick(questions, .86, .08, history, rng)
	picked.difficulty = -1.0
	check(questions == original and history == saved_history, "Picker must not mutate database/history")
	for turn: int in range(100):
		var q: Dictionary = PICK.pick(questions, .86, .08, history, rng)
		check(int(q.id) != int(history.recent.back()), "No immediate repeats after exhausting unseen")
		remember(history, int(q.id))
	var sparse: Array = [{"id": 1, "difficulty": .1}, {"id": 2, "difficulty": .15}, {"id": 3, "difficulty": .8}]
	for turn: int in range(30):
		check(int(PICK.pick(sparse, .1, .08, {}, rng).id) != 3, "Sparse pool must not force difficult content")
	check(PICK.pick([sparse[2]], .1, .08, {}, rng).is_empty(), "No safe candidate returns empty")
	check(int(PICK.pick([sparse[0]], .1, .08, {"seen": {"1": true}, "recent": [1]}, rng).id) == 1,
		"Single safe question may repeat")
	check(PICK.pick([sparse[0]], .1, .08, {}, rng, 1).is_empty(), "Replacement exclusion is absolute")
	check(int(PICK.pick(sparse, .1, .08, {"seen": {}, "recent": [1.0]}, rng).id) == 2,
		"Recent protection precedes unseen, including JSON float IDs")
	var two: Array = sparse.slice(0, 2)
	check(int(PICK.pick(two, .1, .08, {"seen": {"1": true, "2": true}, "recent": [2, 1]}, rng).id) == 2,
		"Use least recent when all candidates are recent")
	var tied: Array = []
	for id: int in range(15):
		tied.append({"id": id, "difficulty": .4})
	history = {"seen": {}, "recent": []}
	for turn: int in range(15):
		var q: Dictionary = PICK.pick(tied, .86, .08, history, rng)
		check(!history.seen.has(str(q.id)), "Include all equal grades at expansion cutoff")
		remember(history, int(q.id))
	# Exercise the shipped catalog in both languages and every theme at the cap.
	var database: Node = root.get_node("Database")
	for language: String in ["ru", "en"]:
		database.load_languages(language, language)
		var total_unique: int = 0
		for theme: int in range(database.get_theme_count()):
			var pool: Array = database.get_quiz_questions_by_theme_index(theme)
			history = {"seen": {}, "recent": []}
			for turn: int in range(40):
				var q: Dictionary = PICK.pick(pool, .86, .08, history, rng)
				check(!q.is_empty(), "Catalog must have safe questions")
				if q.is_empty():
					continue
				if turn < 12:
					check(!history.seen.has(str(q.id)), "First twelve cap picks must be unique")
				if !history.recent.is_empty():
					check(int(q.id) != int(history.recent.back()), "Catalog immediate repeat")
				remember(history, int(q.id))
			check(history.seen.size() >= 12, "Cap pool must contain at least twelve questions")
			total_unique += history.seen.size()
			for target: float in [.08, .18, .3, .5, .7]:
				var q: Dictionary = PICK.pick(pool, target, .08, {}, rng)
				check(!q.is_empty() and float(q.get("difficulty", 2.0)) <= target + .080001,
					"Catalog picker must respect the upper difficulty limit")
		print("QUIZ_POOL ", language, " cap unique in 40/theme: ", total_unique)
	print("QUIZ_SELECTION_POOL checks=", checks, " failures=", failures)
	quit(1 if failures else 0)
