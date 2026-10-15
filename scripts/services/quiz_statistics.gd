extends Node
## Optional Supabase transport. Gameplay never waits for authentication or network.
signal statistics_ready(question_key: String, counts: Array)

const SAVE_PATH := "user://quiz_statistics.json"
const MAX_PENDING := 4000
var _state: Dictionary = {"pending": [], "refresh_token": ""}
var _access_token := ""
var _busy := false
var _cache: Dictionary = {}
var _answered: Dictionary = {}
var _prefetch: Array[String] = []
var _prefetch_in_flight := ""
var _retry: Timer

func _debug_log(message: String) -> void:
	if OS.is_debug_build():
		print("[QuizStatistics] " + message)

func _debug_question(key: String) -> String:
	# Language and ID are sufficient; omit the long revision hash from logs.
	var parts := key.split(":")
	return ":".join(parts.slice(0, 2))

func _ready() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var saved: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
		if saved is Dictionary and saved.get("pending") is Array:
			_state = saved
	_debug_log("Startup: configured=%s enabled=%s pending=%d saved_session=%s minimum_answers=%d" % [
		is_configured(), ProjectSettings.get_setting("quiz_statistics/enabled", false),
		(_state["pending"] as Array).size(), !str(_state.get("refresh_token", "")).is_empty(),
		int(ProjectSettings.get_setting("quiz_statistics/minimum_answers", 30))])
	_retry = Timer.new()
	_retry.wait_time = 30.0
	_retry.timeout.connect(_flush)
	add_child(_retry)
	_retry.start()
	_flush()

func is_configured() -> bool:
	return bool(ProjectSettings.get_setting("quiz_statistics/enabled", false)) \
		and _url().begins_with("https://") and !_public_key().is_empty()

func _url() -> String:
	return str(ProjectSettings.get_setting("quiz_statistics/supabase_url", "")).trim_suffix("/")

func _public_key() -> String:
	return str(ProjectSettings.get_setting("quiz_statistics/publishable_key", ""))

func describe_question(question: Dictionary, theme_index: int) -> Dictionary:
	var canonical: Dictionary = Database.get_quiz_question_by_id(theme_index, int(question.get("id", -1)))
	if canonical.is_empty() or question.get("question") != canonical.get("question"):
		return {}
	var source: Array = canonical.get("answers", [])
	var shown: Array = question.get("answers", [])
	if source.size() != 4 or shown.size() != 4:
		return {}
	var mapping: Array = []
	for answer: Variant in shown:
		var index: int = source.find(answer)
		if index < 0 or mapping.has(index):
			return {}
		mapping.append(index)
	var revision: String = (str(canonical["question"]) + "\n" + "\n".join(source) + "\n" + str(int(canonical["correct_index"]))).sha256_text()
	return {"key": "%s:%d:%s" % [Database.current_language, int(canonical["id"]), revision], "mapping": mapping}

func prefetch_question(question: Dictionary, theme_index: int) -> void:
	if !is_configured():
		return
	var description := describe_question(question, theme_index)
	if description.is_empty():
		return
	var key: String = description["key"]
	if key == _prefetch_in_flight:
		return
	_prefetch.clear()
	_prefetch.append(key)
	_debug_log("Prefetch queued: question=%s" % _debug_question(key))
	_flush()

func _emit_cached(key: String, selected: int) -> void:
	if !_cache.has(key):
		return
	if selected != -1 and !_answered.get(key, false):
		var counts: Array = (_cache[key] as Array).duplicate()
		if selected >= 0:
			counts[selected] = int(counts[selected]) + 1
		_cache[key] = counts
		_answered[key] = true
		_debug_log("Local first attempt applied: question=%s answer=%d" % [_debug_question(key), selected])
	statistics_ready.emit(key, _cache[key])

func _accept_snapshot(key: String, body: Dictionary) -> bool:
	var counts: Variant = body.get("counts")
	if !(counts is Array) or counts.size() != 4 or !(body.get("already_answered") is bool):
		return false
	for value: Variant in counts:
		if !(value is int or value is float) or float(value) < 0.0:
			return false
	_cache[key] = counts.duplicate()
	_answered[key] = body["already_answered"]
	# An answer may have been queued while the read request was in flight.
	for entry: Dictionary in _state["pending"]:
		if entry.get("p_key") == key:
			_emit_cached(key, int(entry.get("p_answer", -1)))
			return true
	statistics_ready.emit(key, _cache[key])
	return true

func record_answer(question: Dictionary, theme_index: int, answer_index: int, eligible: bool) -> void:
	if !is_configured():
		_debug_log("Skipped: statistics disabled or URL/public key missing")
		return
	var description := describe_question(question, theme_index)
	if description.is_empty():
		_debug_log("Skipped: question does not match the local catalog")
		return
	var key: String = description["key"]
	var selected := -1
	if answer_index >= 0 and answer_index < 4:
		selected = int(description["mapping"][answer_index]) if eligible else -2
	var pending: Array = _state["pending"]
	_debug_log("Answer: question=%s catalog_answer=%d eligible=%s (-2=hinted, -1=read only)" % [
		_debug_question(key), selected, eligible])
	# Keep the earliest offline answer; retries and repeat plays never replace it.
	for entry: Dictionary in pending:
		if entry.get("p_key") == key:
			_debug_log("Already queued: keeping first answer for %s" % _debug_question(key))
			if int(entry.get("p_answer", -1)) == -1 and selected != -1:
				entry["p_answer"] = selected
				_save()
			_emit_cached(key, int(entry.get("p_answer", -1)))
			_flush()
			return
	if pending.size() >= MAX_PENDING:
		_debug_log("Queue full: answer not queued")
		return
	pending.append({"p_key": key, "p_answer": selected})
	_debug_log("Queued: pending=%d" % pending.size())
	_save()
	_emit_cached(key, selected)
	_flush()

func _save() -> void:
	# Write then rename so termination during a write preserves the previous queue.
	var file := FileAccess.open(SAVE_PATH + ".tmp", FileAccess.WRITE)
	if file == null:
		_debug_log("Queue save failed: error=%d" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(_state))
	file.close()
	var error := DirAccess.rename_absolute(SAVE_PATH + ".tmp", SAVE_PATH)
	if error != OK:
		_debug_log("Queue rename failed: error=%d" % error)

func _post(path: String, payload: Dictionary, authorized: bool = false) -> Dictionary:
	var started := Time.get_ticks_msec()
	_debug_log("HTTP POST %s" % path)
	var request := HTTPRequest.new()
	request.timeout = 10.0
	add_child(request)
	var headers := PackedStringArray(["Content-Type: application/json", "apikey: " + _public_key()])
	if authorized:
		headers.append("Authorization: Bearer " + _access_token)
	var error := request.request(_url() + path, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if error != OK:
		_debug_log("HTTP request could not start: error=%d" % error)
		request.queue_free()
		return {}
	var response: Array = await request.request_completed
	request.queue_free()
	if int(response[0]) != HTTPRequest.RESULT_SUCCESS:
		_debug_log("HTTP transport failed: result=%d elapsed_ms=%d; queue retained" % [
			int(response[0]), Time.get_ticks_msec() - started])
		return {}
	var body: Variant = JSON.parse_string((response[3] as PackedByteArray).get_string_from_utf8())
	_debug_log("HTTP response: status=%d elapsed_ms=%d" % [int(response[1]), Time.get_ticks_msec() - started])
	if int(response[1]) >= 400 and body is Dictionary:
		# Never log raw bodies: authentication responses can contain credentials.
		_debug_log("Server error code=%s" % str(body.get("error_code", body.get("code", "unspecified"))))
	return {"status": int(response[1]), "body": body}

func _authenticate() -> bool:
	var refresh: String = str(_state.get("refresh_token", ""))
	var response: Dictionary
	if !refresh.is_empty():
		_debug_log("Auth: refreshing saved session")
		response = await _post("/auth/v1/token?grant_type=refresh_token", {"refresh_token": refresh})
		# Do not create a new identity after a transient network failure.
		if response.is_empty() or int(response.get("status", 0)) >= 500:
			return false
		if int(response.get("status", 0)) not in [400, 401, 403] and int(response.get("status", 0)) != 200:
			return false
		# A lost/invalid identity requires explicit recovery, never silent replacement.
		if int(response.get("status", 0)) != 200:
			_debug_log("Auth refresh rejected: status=%d; keeping identity, no new account" % int(response.get("status", 0)))
			return false
	else:
		_debug_log("Auth: creating anonymous session")
		response = await _post("/auth/v1/signup", {})
	var body: Variant = response.get("body")
	if int(response.get("status", 0)) != 200 or !(body is Dictionary):
		_debug_log("Auth failed: status=%d; queue retained" % int(response.get("status", 0)))
		return false
	_access_token = str(body.get("access_token", ""))
	_state["refresh_token"] = str(body.get("refresh_token", ""))
	_save()
	_debug_log("Auth complete: access_token_present=%s" % [!_access_token.is_empty()])
	return !_access_token.is_empty()

func _flush() -> void:
	if _busy or !is_configured() or ((_state["pending"] as Array).is_empty() and _prefetch.is_empty()):
		return
	_busy = true
	_debug_log("Flush: pending=%d" % (_state["pending"] as Array).size())
	if _access_token.is_empty() and !(await _authenticate()):
		_busy = false
		return
	# Serialize reads, auth and writes so token refreshes cannot race each other.
	var prefetch_failed := false
	while !_prefetch.is_empty():
		var key: String = _prefetch.pop_front()
		_prefetch_in_flight = key
		var response := await _post("/rest/v1/rpc/quiz_answer", {
			"p_key": key, "p_answer": -1, "p_include_counts": true}, true)
		_prefetch_in_flight = ""
		var status := int(response.get("status", 0))
		var body: Variant = response.get("body")
		if status == 200 and body is Dictionary and _accept_snapshot(key, body):
			_debug_log("Prefetch ready: question=%s already_answered=%s counts=%s" % [
				_debug_question(key), body["already_answered"], str(body["counts"])])
		else:
			prefetch_failed = true
			if _prefetch.is_empty():
				_prefetch.append(key)
			if status == 401:
				_access_token = ""
			_debug_log("Prefetch failed: status=%d; retry later" % status)
			# Let pending writes proceed on catalog errors, but avoid duplicate network failures.
			if status not in [400, 404, 422]:
				_busy = false
				return
			break
	var pending: Array = _state["pending"]
	for _attempt: int in range(pending.size()):
		if pending.is_empty() or !is_configured():
			break
		var entry: Dictionary = pending[0].duplicate(true)
		_debug_log("RPC quiz_answer: question=%s answer=%d" % [_debug_question(str(entry["p_key"])), int(entry["p_answer"])])
		var key: String = str(entry["p_key"])
		var payload := entry.duplicate(true)
		payload["p_include_counts"] = !_cache.has(key)
		_debug_log("Submit: include_counts=%s" % payload["p_include_counts"])
		var response := await _post("/rest/v1/rpc/quiz_answer", payload, true)
		var status: int = int(response.get("status", 0))
		if status == 401:
			_debug_log("Session expired/rejected: refresh on next retry; queue retained")
			_access_token = ""
			break
		var body: Variant = response.get("body")
		if status == 200 and body is Dictionary and body.get("ok") == true:
			if bool(payload["p_include_counts"]):
				if !_accept_snapshot(key, body):
					_debug_log("Invalid statistics response; queue retained")
					break
			if int(entry["p_answer"]) != -1:
				_answered[key] = true
			_debug_log("Database acknowledged: question=%s counts_returned=%s" % [
				_debug_question(key), body.has("counts")])
		elif status not in [400, 404, 422]:
			_debug_log("RPC unsuccessful: status=%d; queue retained for retry" % status)
			break
		# Keep undeployed catalog versions without blocking all other answers.
		else:
			_debug_log("RPC rejected: status=%d question=%s; retained for catalog/configuration fix" % [status, _debug_question(str(entry["p_key"]))])
			pending.append(pending.pop_front())
			_save()
			continue
		if int(pending[0]["p_answer"]) == int(entry["p_answer"]):
			pending.pop_front()
		_save()
	_busy = false
	_debug_log("Flush finished: pending=%d" % pending.size())
	if !prefetch_failed and !_prefetch.is_empty():
		_flush.call_deferred()
