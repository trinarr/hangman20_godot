extends RefCounted
const SELECTION = preload("res://scripts/core/content_selection.gd")

# Pure selection; the caller records actual presentation and owns saved stages.
static func pick(questions: Array, target: float, history: Dictionary,
		rng: RandomNumberGenerator, excluded_id: int = -1, intro_active: bool = false) -> Dictionary:
	var candidates: Array = []
	var keys: Array = []
	for question: Dictionary in questions:
		if int(question.get("id", -1)) != excluded_id:
			candidates.append(question)
			keys.append(str(int(question["id"])))
	var index: int = SELECTION.pick_index(candidates, target, history, intro_active, rng, keys)
	return {} if index < 0 else (candidates[index] as Dictionary).duplicate(true)

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
