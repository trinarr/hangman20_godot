extends RefCounted

# Content v1 is the public 1.0 database. Retired records are compatibility data,
# never candidates for a new round. Save format 3 applies this transition once.
const CONTENT_VERSION: int = 2
const MANIFEST_PATH: String = "res://data/word_content_migration_v2.json"
const WORD_FILES := {"ru": "res://data/words_ru.json", "en": "res://data/words_en.json"}
const HINT_FILES := {"ru": "res://data/hints_ru.json", "en": "res://data/hints_en.json"}
static var _manifest: Dictionary = {}

static func manifest() -> Dictionary:
	if _manifest.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
		if parsed is Dictionary:
			_manifest = parsed
	return _manifest

static func normalize(text: String) -> String:
	return text.strip_edges().to_upper().replace("-", "—").replace("Ё", "Е")

static func retired_record(language: String, word_id: String, text: String = "") -> Dictionary:
	for merge: Dictionary in manifest().get("merges", []):
		if str(merge["language"]) != language:
			continue
		var retired: Dictionary = merge["retired"]
		if (!word_id.is_empty() and word_id == str(retired["id"])) or (
			word_id.is_empty() and !text.is_empty() and normalize(text) == normalize(str(retired["answer"]))
		):
			return retired
	return {}

static func canonical_word(language: String, theme_id: int, text: String) -> Dictionary:
	for merge: Dictionary in manifest().get("merges", []):
		var retired: Dictionary = merge["retired"]
		if str(merge["language"]) == language and int(retired["theme_id"]) == theme_id and normalize(text) == normalize(str(retired["answer"])):
			return {"theme_id": int(merge["canonical_theme_id"]), "text": normalize(str(merge["canonical_answer"])), "id": str(merge["canonical_id"])}
	return {}

static func _dictionary(parent: Dictionary, key: String) -> Dictionary:
	var value: Variant = parent.get(key, {})
	return value if value is Dictionary else {}

static func _merge_flags(source: Dictionary, target: Dictionary, old_key: String, new_key: String) -> void:
	for field: String in ["played", "guessed"]:
		var flags: Dictionary = _dictionary(source, field)
		if bool(flags.get(old_key, false)):
			var target_flags: Dictionary = _dictionary(target, field)
			target_flags[new_key] = true
			target[field] = target_flags
		flags.erase(old_key)
		if source.has(field):
			source[field] = flags

static func _merge_history(stats: Dictionary, merge: Dictionary, with_counts: bool) -> void:
	var retired: Dictionary = merge["retired"]
	var source_theme: String = str(int(retired["theme_id"]))
	var target_theme: String = str(int(merge["canonical_theme_id"]))
	var old_key: String = normalize(str(retired["answer"]))
	var new_key: String = normalize(str(merge["canonical_answer"]))
	var source: Dictionary = _dictionary(stats, source_theme)
	if source.is_empty():
		return
	var target: Dictionary = source if source_theme == target_theme else _dictionary(stats, target_theme)
	# Some release saves have flags but no counters. Treat a played flag as one
	# historical display, matching the content selection's count-based history.
	var source_played: bool = bool(_dictionary(source, "played").get(old_key, false))
	var target_played: bool = bool(_dictionary(target, "played").get(new_key, false))
	_merge_flags(source, target, old_key, new_key)
	if with_counts:
		var counts: Dictionary = _dictionary(source, "seen_count")
		var last: Dictionary = _dictionary(source, "last_seen")
		var old_count: int = maxi(int(counts.get(old_key, 0)), 1 if source_played else 0)
		var recent_value: Variant = source.get("recent_words", [])
		var source_recent: Array = recent_value if recent_value is Array else []
		var old_recent: bool = source_recent.has(old_key)
		if old_count > 0:
			var target_counts: Dictionary = _dictionary(target, "seen_count")
			target_counts[new_key] = maxi(int(target_counts.get(new_key, 0)), 1 if target_played else 0) + old_count
			target["seen_count"] = target_counts
			var target_last: Dictionary = _dictionary(target, "last_seen")
			if source_theme == target_theme:
				target_last[new_key] = maxi(int(target_last.get(new_key, 0)), int(last.get(old_key, 0)))
			else:
				# Local theme sequences cannot be compared. Conservatively append
				# the imported display to the destination's own sequence.
				var sequence: int = int(target.get("seen_sequence", 0))
				for value: Variant in target_last.values():
					sequence = maxi(sequence, int(value))
				sequence += 1
				target["seen_sequence"] = sequence
				target_last[new_key] = sequence
				target["last_seen"] = target_last
		counts.erase(old_key)
		last.erase(old_key)
		source["seen_count"] = counts
		source["last_seen"] = last
		if source_theme == target_theme:
			var mapped: Array = []
			for value: Variant in source_recent:
				var key: String = new_key if str(value) == old_key else str(value)
				mapped.erase(key)
				mapped.append(key)
			target["recent_words"] = mapped
		else:
			source_recent.erase(old_key)
			source["recent_words"] = source_recent
			if old_recent:
				var target_value: Variant = target.get("recent_words", [])
				var target_recent: Array = target_value if target_value is Array else []
				target_recent.erase(new_key)
				target_recent.append(new_key)
				target["recent_words"] = target_recent
	stats[source_theme] = source
	stats[target_theme] = target

static func _current_records(language: String) -> Dictionary:
	var words_value: Variant = JSON.parse_string(FileAccess.get_file_as_string(WORD_FILES[language]).trim_prefix("\ufeff"))
	var hints_value: Variant = JSON.parse_string(FileAccess.get_file_as_string(HINT_FILES[language]).trim_prefix("\ufeff"))
	if !(words_value is Dictionary) or !(hints_value is Dictionary):
		return {}
	var words: Dictionary = words_value
	var hints: Dictionary = hints_value
	var records: Dictionary = {}
	for theme: String in words.get("ids", {}):
		var ids: Array = words["ids"][theme]
		for index: int in range(ids.size()):
			records[str(ids[index])] = {"id": str(ids[index]), "index": index, "theme_id": int(theme), "text": normalize(str(words["words"][theme][index])), "hint": str(hints["hints"][theme][index])}
	for merge: Dictionary in manifest().get("merges", []):
		if str(merge["language"]) == language:
			var retired: Dictionary = merge["retired"]
			records[str(retired["id"])] = {"id": str(retired["id"]), "index": -1, "theme_id": int(retired["theme_id"]), "text": normalize(str(retired["answer"])), "hint": str(retired["hint"])}
	return records

static func _released_reference(language: String, theme_id: int, index: int, text: String, word_id: String, records: Dictionary) -> Dictionary:
	var resolved_id: String = word_id
	if resolved_id.is_empty():
		var themes: Dictionary = _dictionary(_dictionary(manifest(), "released_ids"), language)
		var ids: Array = themes.get(str(theme_id), [])
		if index >= 0 and index < ids.size():
			resolved_id = str(ids[index])
	var candidate: Dictionary = _dictionary(records, resolved_id)
	if !candidate.is_empty() and int(candidate["theme_id"]) == theme_id and normalize(str(candidate["text"])) == normalize(text):
		return candidate
	# Saved text takes precedence over a stale or mismatched array index.
	for value: Dictionary in records.values():
		if int(value["theme_id"]) == theme_id and normalize(str(value["text"])) == normalize(text):
			return value
	return {}

static func _migrate_assignments(bucket: Dictionary, language: String, records: Dictionary) -> void:
	var levels: Dictionary = _dictionary(bucket, "level_word_assignments")
	for assignments_value: Variant in levels.values():
		if !(assignments_value is Array):
			continue
		for value: Variant in assignments_value:
			if !(value is Dictionary):
				continue
			var assignment: Dictionary = value
			var theme_id: int = int(assignment.get("theme_index", -1)) + 1
			var reference: Dictionary = _released_reference(language, theme_id, int(assignment.get("word_index", -1)), str(assignment.get("text", "")), str(assignment.get("id", "")), records)
			if !reference.is_empty():
				assignment["id"] = reference["id"]
				assignment["word_index"] = reference["index"]
				assignment["content_version"] = CONTENT_VERSION

static func _migrate_session(value: Variant, default_language: String, records_by_language: Dictionary) -> void:
	if !(value is Dictionary):
		return
	var session: Dictionary = value
	if str(session.get("kind", "")) != "word":
		return
	var language: String = str(session.get("language", default_language))
	if !records_by_language.has(language):
		return
	var data: Dictionary = _dictionary(session, "data")
	var theme_id: int = int(data.get("theme_id", session.get("theme_id", -1)))
	var reference: Dictionary = _released_reference(language, theme_id, int(data.get("word_index", -1)), str(data.get("word", "")), str(data.get("word_id", "")), records_by_language[language])
	if reference.is_empty():
		return
	data["word_id"] = reference["id"]
	data["word_index"] = reference["index"]
	data["content_version"] = CONTENT_VERSION
	# Preserve the old word, revealed positions, purchased hints and round_id.
	# Only fill a missing hint; an existing snapshot owns its presentation.
	if !data.has("word_hint_text"):
		data["word_hint_text"] = reference["hint"]
	session["data"] = data

static func migrate_v2_to_v3(payload: Dictionary) -> bool:
	if manifest().is_empty():
		return false
	var records_by_language: Dictionary = {}
	var all_progress: Dictionary = _dictionary(payload, "progress")
	var single_player: Dictionary = _dictionary(payload, "single_player")
	for language: String in ["ru", "en"]:
		var records: Dictionary = _current_records(language)
		if records.is_empty():
			return false
		records_by_language[language] = records
		var progress: Dictionary = _dictionary(all_progress, language)
		var bucket: Dictionary = _dictionary(single_player, language)
		var stats: Dictionary = _dictionary(bucket, "word_stats")
		for merge: Dictionary in manifest().get("merges", []):
			if str(merge["language"]) == language:
				_merge_history(progress, merge, false)
				_merge_history(stats, merge, true)
		if !progress.is_empty():
			all_progress[language] = progress
		if !bucket.is_empty():
			bucket["word_stats"] = stats
			_migrate_assignments(bucket, language, records)
			single_player[language] = bucket
	payload["progress"] = all_progress
	payload["single_player"] = single_player
	var selected_language: String = str(payload.get("word_language", "ru"))
	_migrate_session(payload.get("active_single_player_session", {}), selected_language, records_by_language)
	var resume: Dictionary = _dictionary(payload, "single_player_resume_states")
	for language: String in ["ru", "en"]:
		_migrate_session(_dictionary(resume, language).get("active_session", {}), language, records_by_language)
	payload["word_content_version"] = CONTENT_VERSION
	payload["save_version"] = 3
	return true
