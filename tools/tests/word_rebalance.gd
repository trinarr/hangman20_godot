extends SceneTree

const CONTENT: GDScript = preload("res://scripts/core/word_content_migration.gd")
const REVISION: String = "editorial_rebalance_20261004"
var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1
	if !value:
		failures.append(label)

func run() -> void:
	var database: Node = root.get_node("Database")
	var session: Node = root.get_node("GameSession")
	var state: Node = root.get_node("GameState")
	var archive: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONTENT.RETIREMENTS_PATH))
	for language: String in ["ru", "en"]:
		database.load_word_language(language)
		var active: Dictionary = {}
		for theme_index: int in range(10):
			for word: Dictionary in database.get_words_by_index(theme_index, 0):
				active[str(word["id"])] = word
		var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/word_catalog_" + language + ".json"))
		var new_entries: Array = catalog["entries"].filter(func(entry: Dictionary) -> bool: return entry.get("editorial_revision", "") == REVISION)
		check(new_entries.size() >= 750, language + " minimum replacement quota")
		for entry: Dictionary in new_entries:
			var word: Dictionary = active.get(str(entry["id"]), {})
			check(!word.is_empty() and word.get("text", "") == database.normalize_loaded_word(str(entry["answer"])), str(entry["id"]) + " replacement selectable")
			check(CONTENT.retired_record(language, str(entry["id"])).is_empty(), str(entry["id"]) + " fresh identity")
			check(float(word.get("difficulty", 1.0)) < .25, str(entry["id"]) + " easy calibration")
		var records: Array = archive["languages"][language]["retired"]
		for item: Dictionary in records:
			var entry: Dictionary = item["entry"]
			var id: String = str(entry["id"])
			var text: String = database.normalize_loaded_word(str(entry["answer"]))
			var theme: int = int(entry["theme_id"])
			var label: String = id + " "
			check(!active.has(id), label + " excluded from new selection")
			var reference: Dictionary = database.resolve_saved_word(theme, text, id)
			check(reference.get("retired", false) and int(reference.get("index", 0)) == -1 and str(reference.get("id", "")) == id, label + " archived ID resolution")
			check(str(reference.get("hint", "")) == str(entry["hint"]), label + " old clue resolution")
			check(database.resolve_saved_word(theme, text) == reference, label + " legacy text resolution")
			check(database.resolve_saved_word(theme, text, "mismatched-id").is_empty(), label + " mismatched ID rejected")
			check(database.resolve_saved_word(theme % 10 + 1, text, id).is_empty(), label + " mismatched theme rejected")
			var revealed: Array = []
			for index: int in range(text.length()):
				revealed.append(index == 0 or text[index] in [" ", "—", "'"])
			var wrong: String = ""
			var removed: String = ""
			var alphabet: String = str(catalog["alphabet"])
			for letter: String in alphabet:
				if !text.contains(letter):
					if wrong.is_empty():
						wrong = letter
					else:
						removed = letter
						break
			var saved: Dictionary = {"word": text, "word_id": id, "theme_id": theme, "word_index": int(item["word_index"]), "difficulty": float(item["difficulty"]), "revealed": revealed, "round_id": "retired-round-" + id, "mistakes": 1, "wrong_letters": [wrong], "correct_letters": [text[0]], "removed_wrong_letters": [removed], "open_hint_used": true, "remove_wrong_hint_used": true, "open_hint_ad_reuse_available": true, "remove_wrong_hint_ad_reuse_available": true, "comment_hint_unlocked": true, "word_hint_text": str(entry["hint"])}
			check(session.restore_from_save_data(saved), label + " existing v3 round resumes")
			check(session.word_data.id == id and session.word_data.text == text and session.word_index == -1, label + " no stale index substitution")
			check(session.revealed == revealed and session.mistakes == 1 and session.round_id == saved["round_id"], label + " round progress preserved")
			check(session.open_hint_used and session.remove_wrong_hint_used and session.comment_hint_unlocked and session.open_hint_ad_reuse_available and session.remove_wrong_hint_ad_reuse_available, label + " purchased hint state preserved")
			check(session.wrong_letters == PackedStringArray([wrong]) and session.removed_wrong_letters == PackedStringArray([removed]) and session.correct_letters == PackedStringArray([text[0]]), label + " letter state preserved")
			check(session.word_hint_text == entry["hint"] and is_equal_approx(session.word_data.difficulty, float(item["difficulty"])), label + " old hint and difficulty preserved")
			var serialized: Dictionary = session.to_save_data()
			check(session.restore_from_save_data(serialized) and session.to_save_data() == serialized, label + " repeat serialization stable")
			var without_id: Dictionary = saved.duplicate(true)
			without_id.erase("word_id")
			without_id.erase("word_hint_text")
			check(session.restore_from_save_data(without_id) and session.word_data.id == id and session.word_hint_text == entry["hint"], label + " missing ID and clue recovered")
			check(CONTENT.canonical_word(language, theme, text).is_empty(), label + " unrelated history never merged")
		# Version 3 needs no destructive rewrite. Old history, level assignments,
		# rewards and paid attempts retain their own identities across this update.
		var first: Dictionary = records[0]["entry"]
		var new_word: Dictionary = new_entries[0]
		var old_key: String = CONTENT.normalize(str(first["answer"]))
		var history: Dictionary = {str(first["theme_id"]): {"played": {old_key: true}, "guessed": {old_key: true}, "seen_count": {old_key: 3}, "last_seen": {old_key: 9}, "recent_words": [old_key]}}
		var payload: Dictionary = {"save_version": 3, "word_language": language, "soft_currency": 777, "stars": 888, "hearts": 4, "single_player": {language: {"word_stats": history, "level_word_assignments": {"7": [{"id": first["id"], "text": first["answer"], "word_index": records[0]["word_index"]}]}}}, "pending_single_player_reward": {"amount": 99, "reward_id": "untouched"}, "rewarded_action_requests": {"receipt": {"round_id": "untouched-round"}}}
		var migrated: Dictionary = state._migrate_save_payload(payload)
		check(migrated == payload, language + " v3 history, balances, assignments and rewards untouched")
		check(!JSON.stringify(migrated["single_player"]).contains(str(new_word["id"])), language + " new word receives no old history")
		# An older save with a stable ID also resolves the archive during v2 -> v3.
		var legacy: Dictionary = {"save_version": 2, "word_language": language, "active_single_player_session": {"kind": "word", "language": language, "data": {"word": first["answer"], "word_id": first["id"], "word_index": records[0]["word_index"], "theme_id": first["theme_id"], "round_id": "legacy-round"}}}
		var converted: Dictionary = state._migrate_save_payload(legacy)
		var data: Dictionary = converted["active_single_player_session"]["data"]
		check(data["word_id"] == first["id"] and int(data["word_index"]) == -1 and data["word_hint_text"] == first["hint"] and data["round_id"] == "legacy-round", language + " v2 archive reference migrates")
	print("WORD_REBALANCE " + JSON.stringify({"checks": checks, "failures": failures}))
	quit(0 if failures.is_empty() else 1)
