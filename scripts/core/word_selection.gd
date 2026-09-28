extends RefCounted
const SELECTION = preload("res://scripts/core/content_selection.gd")

static func pick_index(candidates: Array, target: float, history: Dictionary, intro_active: bool, rng: RandomNumberGenerator) -> int:
	var keys: Array = []
	for candidate: Dictionary in candidates:
		keys.append(Database.word_progress_key_from_text(str(candidate.get("text", ""))))
	var selection_history: Dictionary = history.duplicate()
	selection_history["recent"] = history.get("recent_words", [])
	return SELECTION.pick_index(candidates, target, selection_history, intro_active, rng, keys, true)
