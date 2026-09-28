extends RefCounted
const GAME_DESIGN: GDScript = preload("res://scripts/core/game_design_config.gd")

## Pure quiz operations. Never mutate Database's read-only cached dictionaries.

static func pick(
	questions: Array, target: float, window: float, history: Dictionary,
	rng: RandomNumberGenerator, excluded_id: int = -1
) -> Dictionary:
	var pool: Array = []
	var easier: Array = []
	var safe_window: float = maxf(window, 0.0)
	var minimum_pool_size: int = GAME_DESIGN.get_int_range(
		"difficulty.quiz_min_pool_size", 12, 1, 1000
	)
	for question: Dictionary in questions:
		if int(question.get("id", -1)) == excluded_id:
			continue
		var difficulty: float = float(question.get("difficulty", 0.5))
		var distance: float = absf(difficulty - target)
		if distance <= safe_window + 0.000001:
			pool.append(question)
		elif difficulty < target:
			easier.append(question)
	# Extend only downwards: a sparse catalog must not force harder questions.
	# Include ties at the cutoff so database order does not starve equal grades.
	if pool.size() < minimum_pool_size and !easier.is_empty():
		easier.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return float(a.get("difficulty", 0.5)) > float(b.get("difficulty", 0.5))
		)
		var needed: int = mini(minimum_pool_size - pool.size(), easier.size())
		var cutoff: float = float(easier[needed - 1].get("difficulty", 0.5))
		for question: Dictionary in easier:
			if float(question.get("difficulty", 0.5)) < cutoff - 0.000001:
				break
			pool.append(question)
	if pool.is_empty():
		return {}
	# Apply before unseen preference, including legacy/incomplete seen history.
	var recent: Array = history.get("recent", [])
	if pool.size() > 1 and !recent.is_empty():
		var previous_id: int = int(recent.back())
		pool = pool.filter(func(question: Dictionary) -> bool:
			return int(question["id"]) != previous_id
		)
	var seen: Dictionary = history.get("seen", {})
	var unseen: Array = []
	for question: Dictionary in pool:
		if !bool(seen.get(str(int(question["id"])), false)):
			unseen.append(question)
	if !unseen.is_empty():
		pool = unseen
	else:
		# Evict the oldest recent presentation first if the local pool is small.
		# This prevents immediate repeats whenever another suitable card exists.
		for start: int in range(recent.size() + 1):
			var fresh: Array = []
			var excluded: Array = recent.slice(start)
			for question: Dictionary in pool:
				if !excluded.has(int(question["id"])):
					fresh.append(question)
			if !fresh.is_empty():
				pool = fresh
				break
	return (pool[rng.randi_range(0, pool.size() - 1)] as Dictionary).duplicate(true)

static func shuffled(question: Dictionary) -> Dictionary:
	var result: Dictionary = question.duplicate(true)
	var answers: Array = result.get("answers", [])
	var correct: int = int(result.get("correct_index", -1))
	if answers.size() != 4 or correct < 0 or correct >= 4:
		return {}
	var order: Array = [0, 1, 2, 3]
	order.shuffle()
	var reordered: Array = []
	for index: int in order:
		reordered.append(answers[index])
	result["answers"] = reordered
	result["correct_index"] = order.find(correct)
	return result

static func restore_question(snapshot: Dictionary, canonical: Dictionary) -> Dictionary:
	# A valid snapshot owns its presentation order (also used by saved 50/50).
	# Return empty when content changed so the caller can rebuild the stage.
	if canonical.is_empty() or str(snapshot.get("question", "")) != str(canonical.get("question", "")):
		return {}
	var answers_value: Variant = snapshot.get("answers", [])
	if !(answers_value is Array):
		return {}
	var answers: Array = answers_value
	var correct: int = int(snapshot.get("correct_index", -1))
	if answers.size() != 4 or correct < 0 or correct >= 4:
		return {}
	var expected: Array = canonical.get("answers", [])
	if answers[correct] != expected[int(canonical["correct_index"])]:
		return {}
	var sorted_saved: Array = answers.duplicate()
	var sorted_expected: Array = expected.duplicate()
	sorted_saved.sort()
	sorted_expected.sort()
	if sorted_saved != sorted_expected:
		return {}
	var restored: Dictionary = canonical.duplicate(true)
	restored["answers"] = answers.duplicate()
	restored["correct_index"] = correct
	return restored
