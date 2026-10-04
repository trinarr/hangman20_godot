extends SceneTree
const CONTENT: GDScript = preload("res://scripts/core/word_content_migration.gd")
var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1
	if !value:
		failures.append(label)

func run() -> void:
	var state: Node = root.get_node("GameState")
	var database: Node = root.get_node("Database")
	var session: Node = root.get_node("GameSession")
	for merge: Dictionary in CONTENT.manifest()["merges"]:
		var language: String = str(merge["language"])
		database.load_word_language(language)
		var retired: Dictionary = merge["retired"]
		var source_theme: String = str(int(retired["theme_id"]))
		var target_theme: String = str(int(merge["canonical_theme_id"]))
		var old_key: String = CONTENT.normalize(str(retired["answer"]))
		var new_key: String = CONTENT.normalize(str(merge["canonical_answer"]))
		var label: String = str(merge["audit_number"]) + " "
		var stats: Dictionary = {
			source_theme: {"played": {old_key: true}, "guessed": {old_key: true}, "seen_count": {old_key: 2}, "last_seen": {old_key: 40}, "seen_sequence": 40, "recent_words": [old_key]},
		}
		if source_theme == target_theme:
			stats[source_theme]["seen_count"][new_key] = 3
			stats[source_theme]["last_seen"][new_key] = 5
			stats[source_theme]["recent_words"].append(new_key)
		else:
			stats[target_theme] = {"seen_count": {new_key: 3}, "last_seen": {new_key: 5}, "seen_sequence": 5, "recent_words": []}
		var ids: Array = CONTENT.manifest()["released_ids"][language][source_theme]
		var old_index: int = ids.find(str(retired["id"]))
		var revealed: Array = []
		for index: int in range(old_key.length()):
			revealed.append(index == 0 or old_key[index] in [" ", "—", "'"])
		var round_data: Dictionary = {"word": old_key, "word_index": old_index, "theme_id": int(source_theme), "revealed": revealed, "round_id": "migration-test-" + label, "mistakes": 4, "correct_letters": [old_key[0]], "wrong_letters": [], "removed_wrong_letters": ["Z"], "open_hint_used": true, "remove_wrong_hint_used": true, "comment_hint_unlocked": true, "word_hint_text": "Purchased old hint", "attempt_offer_cost": 70, "attempt_offer_size": 4, "difficulty": .5}
		var active: Dictionary = {"kind": "word", "language": language, "level_index": 4, "word_slot": 0, "theme_id": int(source_theme), "data": round_data}
		var pending: Dictionary = {"language": language, "level_index": 4, "amount": 99, "claimed": true, "double_resolved": false, "reward_id": "untouched-reward"}
		var payload: Dictionary = {"save_version": 2, "word_language": language, "soft_currency": 777, "stars": 888, "hearts": 4, "rewarded_action_requests": {"receipt": {"action": "extra_attempt", "context": {"round_id": round_data["round_id"]}}}, "progress": {language: {source_theme: {"played": {old_key: true}, "guessed": {old_key: true}}}}, "single_player": {language: {"word_stats": stats, "level_word_assignments": {"4": [{"id": str(retired["id"]), "theme_index": int(source_theme) - 1, "word_index": old_index, "text": old_key}]}}}, "active_single_player_session": active, "single_player_resume_states": {language: {"active_session": active.duplicate(true), "pending_reward": pending}}, "pending_single_player_reward": pending.duplicate(true)}
		var original: Dictionary = payload.duplicate(true)
		var migrated: Dictionary = state._migrate_save_payload(payload)
		check(payload == original, label + "input untouched")
		check(int(migrated.get("save_version", -1)) == 3, label + "version advanced")
		var history: Dictionary = migrated["single_player"][language]["word_stats"][target_theme]
		check(int(history["seen_count"][new_key]) == 5, label + "counts summed")
		check(bool(history["played"][new_key]) and bool(history["guessed"][new_key]), label + "flags merged")
		check(!migrated["single_player"][language]["word_stats"][source_theme]["seen_count"].has(old_key), label + "retired count removed")
		check(history["recent_words"].count(new_key) == 1, label + "recent canonical once")
		check(int(history["last_seen"][new_key]) == (40 if source_theme == target_theme else 6), label + "theme sequence semantics")
		check(bool(migrated["progress"][language][target_theme]["guessed"][new_key]), label + "archived flag merged")
		check(!history["seen_count"].has(CONTENT.normalize(str(merge["replacement_answer"]))), label + "replacement starts unseen")
		check(state._migrate_save_payload(migrated) == migrated, label + "second load idempotent")
		check(int(migrated["soft_currency"]) == 777 and int(migrated["stars"]) == 888 and int(migrated["hearts"]) == 4, label + "economy untouched")
		check(migrated["pending_single_player_reward"] == pending and migrated["rewarded_action_requests"] == original["rewarded_action_requests"], label + "rewards and receipts untouched")
		var saved_round: Dictionary = migrated["single_player_resume_states"][language]["active_session"]["data"]
		check(str(saved_round["word_id"]) == str(retired["id"]) and int(saved_round["word_index"]) == -1, label + "archive identity")
		check(saved_round["revealed"] == revealed and str(saved_round["word"]) == old_key and int(saved_round["attempt_offer_cost"]) == 70, label + "old round and attempts intact")
		check(session.restore_from_save_data(saved_round), label + "archived round restores")
		check(session.word_data.id == str(retired["id"]) and session.letters.size() == old_key.length() and session.revealed == revealed, label + "restored old positions")
		check(session.open_hint_used and session.remove_wrong_hint_used and session.comment_hint_unlocked and session.word_hint_text == "Purchased old hint", label + "paid hints intact")
		check(str(session.to_save_data()["word_id"]) == str(retired["id"]) and session.round_id == str(round_data["round_id"]), label + "identity survives next save")
		state.single_player = migrated["single_player"].duplicate(true)
		state.single_player[language]["word_stats"][target_theme]["guessed"][new_key] = false
		state.mark_single_player_word_guessed(language, int(source_theme) - 1, -1, 0, old_key, false)
		check(bool(state.single_player[language]["word_stats"][target_theme]["guessed"][new_key]), label + "archived result credits canonical")
		var active_words: Array = database.get_words_by_index(int(source_theme) - 1, 0)
		check(!active_words.any(func(word: Dictionary) -> bool: return str(word["id"]) == str(retired["id"])), label + "retired excluded from selection")
		# A normal surviving record also resolves by text if its old index shifted.
		var survivors: Array = active_words.filter(func(word: Dictionary) -> bool: return ids.has(str(word["id"])))
		var survivor: Dictionary = survivors[0]
		var reference: Dictionary = database.resolve_saved_word(int(source_theme), str(survivor["text"]), str(survivor["id"]))
		check(int(reference.get("index", -1)) == int(survivor["index"]), label + "survivor uses current index")
		var survivor_payload: Dictionary = {"save_version": 2, "word_language": language, "active_single_player_session": {"kind": "word", "language": language, "theme_id": int(source_theme), "data": {"word": survivor["text"], "theme_id": int(source_theme), "word_index": ids.find(str(survivor["id"])), "revealed": [true], "round_id": "survivor-round"}}}
		var survivor_migrated: Dictionary = state._migrate_save_payload(survivor_payload)
		var survivor_round: Dictionary = survivor_migrated["active_single_player_session"]["data"]
		check(str(survivor_round["word_id"]) == str(survivor["id"]) and int(survivor_round["word_index"]) == int(survivor["index"]), label + "v2 surviving snapshot reindexed")
		check(str(survivor_round["round_id"]) == "survivor-round" and survivor_round["revealed"] == [true], label + "v2 surviving snapshot state untouched")
		check(session.restore_from_save_data(session.to_save_data()), label + "archived round survives another serialization")
	# Actual disk recovery must use the same v2 migration as the normal load.
	for path: String in [state.SAVE_PATH, state.SAVE_TMP_PATH, state.SAVE_BACKUP_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var fixture: Dictionary = {"save_version": 2, "soft_currency": 321, "stars": 123, "guided_onboarding_completed": true}
	var file: FileAccess = FileAccess.open(state.SAVE_BACKUP_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(fixture))
	file.close()
	file = FileAccess.open(state.SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"save_version": 0}))
	file.close()
	state.load_game()
	check(state.soft_currency == 321 and state.stars == 123, "v2 backup recovered and balances preserved")
	check(int(state._read_save_dictionary(state.SAVE_PATH).get("save_version", -1)) == 3, "recovery commits migrated format")
	state.load_game()
	check(state.soft_currency == 321 and state.stars == 123, "disk reload does not rerun migration")
	print("WORD_CONTENT_MIGRATION " + JSON.stringify({"checks": checks, "failures": failures}))
	quit(0 if failures.is_empty() else 1)
