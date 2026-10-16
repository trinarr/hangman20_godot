extends Node
## Optional Supabase transport. Gameplay never waits for authentication or network.
signal statistics_ready(question_key: String, counts: Array)

const SAVE_PATH := "user://quiz_statistics.json"
const DEV_SAVE_PATH := "user://quiz_statistics_dev.json"
const MAX_PENDING := 4000
var _state: Dictionary = {"pending": [], "refresh_token": ""}
var _access_token := ""
var _access_token_refresh_at_ms: int = 0
var _identity_generation: int = 0
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
	_debug_log("Environment=%s RPC=%s save=%s" % ["dev" if _uses_dev() else "production", _rpc_path(), _save_path()])
	if FileAccess.file_exists(_save_path()):
		var saved: Variant = JSON.parse_string(FileAccess.get_file_as_string(_save_path()))
		if saved is Dictionary and saved.get("pending") is Array:
			_state = saved
	_debug_log("Startup: configured=%s enabled=%s pending=%d saved_session=%s minimum_answers=%d" % [
		is_configured(), ProjectSettings.get_setting("quiz_statistics/dev_enabled" if _uses_dev() else "quiz_statistics/enabled", false),
		(_state["pending"] as Array).size(), !str(_state.get("refresh_token", "")).is_empty(),
		int(ProjectSettings.get_setting("quiz_statistics/minimum_answers", 30))])
	if !_network_allowed():
		_debug_log("Supabase network disabled for this execution")
		return
	_retry = Timer.new()
	_retry.wait_time = 30.0
	_retry.timeout.connect(_flush)
	add_child(_retry)
	_retry.start()
	_flush()

func _uses_dev() -> bool:
	return OS.is_debug_build() or OS.has_feature("editor")

func _save_path() -> String:
	# Never migrate a production session or pending votes into the dev environment.
	return DEV_SAVE_PATH if _uses_dev() else SAVE_PATH

func _rpc_path() -> String:
	return "/rest/v1/rpc/quiz_answer_dev" if _uses_dev() else "/rest/v1/rpc/quiz_answer"

func _network_allowed() -> bool:
	return OS.get_environment("HANGMAN_SUPABASE_NETWORK_DISABLED") != "1"

func _path_allowed(path: String) -> bool:
	# No caller can accidentally send a debug vote to the production RPC.
	return path == _rpc_path() or path in [
		"/auth/v1/signup", "/auth/v1/token?grant_type=refresh_token"]

func is_configured() -> bool:
	var enabled_setting := "quiz_statistics/dev_enabled" if _uses_dev() else "quiz_statistics/enabled"
	return _network_allowed() and bool(ProjectSettings.get_setting(enabled_setting, false)) \
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

func cached_answer_counts(question: Dictionary, theme_index: int) -> Array:
	var description := describe_question(question, theme_index)
	if description.is_empty() or !_cache.has(description["key"]):
		return []
	var canonical_counts: Array = _cache[description["key"]]
	var shown_counts: Array = []
	for source_index: int in description["mapping"]:
		shown_counts.append(canonical_counts[source_index])
	return shown_counts

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
	var file := FileAccess.open(_save_path() + ".tmp", FileAccess.WRITE)
	if file == null:
		_debug_log("Queue save failed: error=%d" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(_state))
	file.close()
	var error := DirAccess.rename_absolute(_save_path() + ".tmp", _save_path())
	if error != OK:
		_debug_log("Queue rename failed: error=%d" % error)

func _post(path: String, payload: Dictionary, authorized: bool = false) -> Dictionary:
	# Last line of defense, including direct calls outside the normal worker.
	# Tests replace this method with an in-memory mock.
	if !is_configured() or !_path_allowed(path):
		_debug_log("HTTP blocked: Supabase disabled for this execution")
		return {}
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

func _token_needs_refresh() -> bool:
	return _access_token.is_empty() or (
		_access_token_refresh_at_ms > 0 and Time.get_ticks_msec() >= _access_token_refresh_at_ms
	)

func _session_is_revoked(response: Dictionary) -> bool:
	if int(response.get("status", 0)) not in [400, 401, 403]:
		return false
	var body: Variant = response.get("body")
	if !(body is Dictionary):
		return false
	var code := str(body.get("error_code", body.get("code", body.get("error", ""))))
	return code in ["refresh_token_not_found", "refresh_token_already_used",
		"session_not_found", "session_expired", "user_not_found", "invalid_grant"]

func _reset_revoked_identity() -> void:
	_debug_log("Auth: revoked session; discarding old pending answers and cached attempt flags")
	_identity_generation += 1
	_access_token = ""
	_access_token_refresh_at_ms = 0
	_state = {"pending": [], "refresh_token": ""}
	_cache.clear()
	_answered.clear()
	# Read-only prefetch requests can safely continue under the new identity.
	_save()

func _authenticate() -> bool:
	var refresh: String = str(_state.get("refresh_token", ""))
	var response: Dictionary
	if !refresh.is_empty():
		_debug_log("Auth: refreshing saved session")
		response = await _post("/auth/v1/token?grant_type=refresh_token", {"refresh_token": refresh})
		if int(response.get("status", 0)) != 200:
			if !_session_is_revoked(response):
				_debug_log("Auth refresh failed: status=%d; keeping identity and queue" % int(response.get("status", 0)))
				return false
			_reset_revoked_identity()
			_debug_log("Auth: creating replacement anonymous session")
			response = await _post("/auth/v1/signup", {})
	else:
		_debug_log("Auth: creating anonymous session")
		response = await _post("/auth/v1/signup", {})
	var body: Variant = response.get("body")
	if int(response.get("status", 0)) != 200 or !(body is Dictionary):
		_debug_log("Auth failed: status=%d; retry later" % int(response.get("status", 0)))
		return false
	var access := str(body.get("access_token", ""))
	var next_refresh := str(body.get("refresh_token", ""))
	if access.is_empty() or next_refresh.is_empty():
		_debug_log("Auth failed: incomplete token pair")
		return false
	_access_token = access
	_state["refresh_token"] = next_refresh
	var lifetime_ms := maxi(0, int(body.get("expires_in", 0))) * 1000
	_access_token_refresh_at_ms = (
		Time.get_ticks_msec() + lifetime_ms - mini(30000, lifetime_ms / 10)
		if lifetime_ms > 0 else 0
	)
	_save()
	_debug_log("Auth complete: access_token_present=true")
	return true

func _quiz_rpc(payload: Dictionary) -> Dictionary:
	var generation := _identity_generation
	if _token_needs_refresh() and !(await _authenticate()):
		return {"identity_reset": generation != _identity_generation}
	# An old queued vote must never be replayed under a replacement account.
	if generation != _identity_generation and int(payload.get("p_answer", -1)) != -1:
		return {"identity_reset": true}
	var response := await _post(_rpc_path(), payload, true)
	if int(response.get("status", 0)) != 401:
		return response
	_debug_log("RPC unauthorized: refreshing session and retrying once immediately")
	_access_token = ""
	_access_token_refresh_at_ms = 0
	if !(await _authenticate()):
		return {"identity_reset": generation != _identity_generation}
	if generation != _identity_generation and int(payload.get("p_answer", -1)) != -1:
		return {"identity_reset": true}
	return await _post(_rpc_path(), payload, true)

func _flush() -> void:
	if _busy or !is_configured() or ((_state["pending"] as Array).is_empty() and _prefetch.is_empty()):
		return
	_busy = true
	_debug_log("Flush: pending=%d" % (_state["pending"] as Array).size())
	if _token_needs_refresh() and !(await _authenticate()):
		_busy = false
		return
	# Serialize reads, auth and writes so token refreshes cannot race each other.
	var prefetch_failed := false
	while !_prefetch.is_empty():
		var key: String = _prefetch.pop_front()
		_prefetch_in_flight = key
		var response := await _quiz_rpc({
			"p_key": key, "p_answer": -1, "p_include_counts": true})
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
		_debug_log("RPC %s: question=%s answer=%d" % [_rpc_path(), _debug_question(str(entry["p_key"])), int(entry["p_answer"])])
		var key: String = str(entry["p_key"])
		var payload := entry.duplicate(true)
		payload["p_include_counts"] = !_cache.has(key)
		_debug_log("Submit: include_counts=%s" % payload["p_include_counts"])
		var response := await _quiz_rpc(payload)
		if bool(response.get("identity_reset", false)):
			# The old array belongs to the discarded identity. Process only new work next.
			_busy = false
			if !_access_token.is_empty():
				_flush.call_deferred()
			return
		var status: int = int(response.get("status", 0))
		if status == 401:
			_debug_log("RPC still unauthorized after immediate retry; queue retained")
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
