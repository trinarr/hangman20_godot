extends RefCounted
## Pure quiz operations. Never mutate Database's read-only cached dictionaries.

static func pick(
	questions: Array, target: float, window: float, history: Dictionary,
	rng: RandomNumberGenerator, excluded_id: int = -1
) -> Dictionary:
	var suitable: Array = []
	var nearest: Array = []
	var nearest_distance: float = INF
	for question: Dictionary in questions:
		if int(question.get("id", -1)) == excluded_id:
			continue
		var distance: float = absf(float(question.get("difficulty", 0.5)) - target)
		if distance <= window + 0.000001:
			suitable.append(question)
		if distance < nearest_distance - 0.000001:
			nearest_distance = distance
			nearest = [question]
		elif is_equal_approx(distance, nearest_distance):
			nearest.append(question)
	# Empty windows use only the closest available grade, not all unseen facts.
	var pool: Array = suitable if !suitable.is_empty() else nearest
	if pool.is_empty():
		return {}
	var seen: Dictionary = history.get("seen", {})
	var unseen: Array = []
	for question: Dictionary in pool:
		if !bool(seen.get(str(int(question["id"])), false)):
			unseen.append(question)
	if !unseen.is_empty():
		pool = unseen
	else:
		var recent: Array = history.get("recent", [])
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
