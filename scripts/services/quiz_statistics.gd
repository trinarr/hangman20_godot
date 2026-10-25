extends Node
## Optional Supabase transport. Gameplay never waits for authentication or network.
signal statistics_ready(question_key: String, counts: Array)
signal identity_changed()

const RETRY_POLICY = preload("res://scripts/services/api_retry_policy.gd")
const SAVE_PATH := "user://quiz_statistics.json"
const DEV_SAVE_PATH := "user://quiz_statistics_dev.json"
const MAX_PENDING := 4000
# Protocol bound shared with migration 017; one failed batch remains safely retryable.
const MAX_BATCH := 20
var _state: Dictionary = {"pending": [], "refresh_token": ""}
var _access_token := ""
var _access_token_refresh_at_ms: int = 0
var _identity_generation: int = 0
var _busy := false
var _flush_again := false
var _auth_busy := false
var _auth_last_success := false
var _batch_supported := true
var _cache: Dictionary = {}
var _answered: Dictionary = {}
var _prefetch: Array[String] = []
var _prefetch_in_flight := ""
var _retry: Timer
var _retry_states: Dictionary = {}

func _debug_log(message: String) -> void:
	if OS.is_debug_build():
		print("[QuizStatistics] " + message)

func _debug_question(key: String) -> String:
	# Language and ID are sufficient; omit the long revision hash from logs.
	var parts := key.split(":")
	return ":".join(parts.slice(0, 2))

func _ready() -> void:
	GameState.guided_onboarding_finished.connect(_start_online_worker)
	_debug_log("Environment=%s RPC=%s save=%s" % ["dev" if _uses_dev() else "production", _rpc_path(), _save_path()])
	if FileAccess.file_exists(_save_path()):
		var saved: Variant = JSON.parse_string(FileAccess.get_file_as_string(_save_path()))
		if saved is Dictionary and saved.get("pending") is Array:
			_state = saved
	_debug_log("Startup: configured=%s enabled=%s pending=%d saved_session=%s minimum_answers=%d" % [
		is_configured(), ProjectSettings.get_setting("quiz_statistics/dev_enabled" if _uses_dev() else "quiz_statistics/enabled", false),
		(_state["pending"] as Array).size(), !str(_state.get("refresh_token", "")).is_empty(),
		minimum_answers()])
	_start_online_worker()

func _start_online_worker() -> void:
	if OS.get_environment("HANGMAN_SUPABASE_NETWORK_DISABLED") == "1" or !GameState.is_single_player_guided_onboarding_completed():
		_debug_log("Supabase network disabled for this execution")
		return
	if !is_instance_valid(_retry):
		_retry = Timer.new()
		_retry.wait_time = RETRY_POLICY.base_seconds()
		_retry.timeout.connect(_flush)
		add_child(_retry)
		_retry.start()
	_flush()

func _uses_dev() -> bool:
	return OS.is_debug_build() or OS.has_feature("editor")

func minimum_answers() -> int:
	var setting := "quiz_statistics/dev_minimum_answers" if _uses_dev() else "quiz_statistics/minimum_answers"
	return maxi(1, int(ProjectSettings.get_setting(setting, 1 if _uses_dev() else 30)))

func _save_path() -> String:
	# Never migrate a production session or pending votes into the dev environment.
	return DEV_SAVE_PATH if _uses_dev() else SAVE_PATH

func _rpc_path() -> String:
	return "/rest/v1/rpc/quiz_answer_dev" if _uses_dev() else "/rest/v1/rpc/quiz_answer"

func _batch_rpc_path() -> String:
	return "/rest/v1/rpc/quiz_answers_dev" if _uses_dev() else "/rest/v1/rpc/quiz_answers"

func _leaderboard_rpc_path() -> String:
	return "/rest/v1/rpc/leaderboard_sync_dev" if _uses_dev() else "/rest/v1/rpc/leaderboard_sync"

func leaderboard_is_configured() -> bool:
	var setting := "leaderboard/dev_enabled" if _uses_dev() else "leaderboard/enabled"
	return _network_allowed() and bool(ProjectSettings.get_setting(setting, false)) \
		and _url().begins_with("https://") and !_public_key().is_empty()

func _network_allowed() -> bool:
	return OS.get_environment("HANGMAN_SUPABASE_NETWORK_DISABLED") != "1" and GameState.can_use_online_services()

func _path_allowed(path: String) -> bool:
	# No caller can accidentally send a debug vote to the production RPC.
	return path == _rpc_path() or path == _batch_rpc_path() or path == _leaderboard_rpc_path() or path in [
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

func _valid_counts_snapshot(body: Dictionary) -> bool:
	var counts: Variant = body.get("counts")
	if !(counts is Array) or counts.size() != 4 or !(body.get("already_answered") is bool):
		return false
	for value: Variant in counts:
		if !(value is int or value is float) or float(value) < 0.0:
			return false
	return true

func _accept_snapshot(key: String, body: Dictionary) -> bool:
	if !_valid_counts_snapshot(body):
		return false
	var counts: Array = body["counts"]
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
	var configured := is_configured() or leaderboard_is_configured()
	if path == _rpc_path() or path == _batch_rpc_path():
		configured = is_configured()
	elif path == _leaderboard_rpc_path():
		configured = leaderboard_is_configured()
	if !configured or !_path_allowed(path):
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
	identity_changed.emit()

func _authenticate(user_requested: bool = false) -> bool:
	# Only token rotation is serialized. Independent API requests may overlap.
	if _auth_busy:
		while _auth_busy:
			await get_tree().process_frame
		if _auth_last_success and !_token_needs_refresh():
			return true
		if !user_requested:
			return false
		# A failed older auth attempt must not consume the user's own retry.
	if !user_requested and retry_delay_ms("auth") > 0:
		return false
	_auth_busy = true
	_auth_last_success = await _authenticate_session()
	if _auth_last_success:
		retry_success("auth")
	else:
		retry_failure("auth", {})
	_auth_busy = false
	return _auth_last_success

func _authenticate_session() -> bool:
	if !is_configured() and !leaderboard_is_configured():
		return false
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
	return await _authorized_rpc(_rpc_path(), payload, int(payload.get("p_answer", -1)) != -1)

func leaderboard_rpc(payload: Dictionary, user_requested: bool = false) -> Dictionary:
	if !leaderboard_is_configured():
		return {}
	# Share authentication, without waiting for the quiz worker's HTTP request.
	return await _authorized_rpc(_leaderboard_rpc_path(), payload, false, user_requested)

func _authorized_rpc(path: String, payload: Dictionary, identity_bound: bool, user_requested: bool = false) -> Dictionary:
	var lane := "leaderboard" if path == _leaderboard_rpc_path() else "quiz"
	var delay := retry_delay_ms(lane)
	if delay > 0 and !user_requested:
		return {"retry_deferred":true,"retry_after_ms":delay}
	var generation := _identity_generation
	var response: Dictionary = {}
	for attempt: int in range(2):
		if _token_needs_refresh() and !(await _authenticate(user_requested)):
			return {"identity_reset": generation != _identity_generation, "retry_scheduled":true}
		if generation != _identity_generation and identity_bound:
			return {"identity_reset": true}
		var request_generation := _identity_generation
		var sent_token := _access_token
		response = await _post(path, payload, true)
		# An old identity's late success must never acknowledge the new queue/cache.
		if request_generation != _identity_generation:
			if identity_bound:
				return {"identity_reset": true}
			response = {"identity_reset": true}
			continue
		if int(response.get("status", 0)) != 401:
			var status: int = int(response.get("status", 0))
			if status <= 0 or status in [408, 425, 429, 403] or status >= 500:
				retry_failure(lane, response)
			return response
		# A delayed 401 for an old JWT must not erase a concurrently refreshed token.
		if sent_token == _access_token:
			_access_token = ""
			_access_token_refresh_at_ms = 0
		if attempt == 0:
			_debug_log("RPC unauthorized: sharing token refresh and retrying once")
	if int(response.get("status", 0)) == 401:
		retry_failure(lane, response)
	return response

func _batch_reply_valid(body: Variant, entries: Array) -> bool:
	if !(body is Dictionary) or body.get("ok") != true or !(body.get("results") is Array) or body.results.size() != entries.size():
		return false
	for index: int in range(entries.size()):
		var item: Variant = body.results[index]
		var entry: Dictionary = entries[index]
		if !(item is Dictionary) or item.get("p_key") != entry.p_key or item.get("p_answer") != entry.p_answer or !(item.get("ok") is bool):
			return false
		if item.ok:
			if entry.p_include_counts and !_valid_counts_snapshot(item):
				return false
		elif item.get("code") != "22023":
			return false
	return true

func _acknowledge_entry(entry: Dictionary, body: Dictionary) -> bool:
	var key: String = entry.p_key
	if entry.p_include_counts and !_accept_snapshot(key, body):
		return false
	if int(entry.p_answer) != -1:
		_answered[key] = true
	# The queued entry may have changed from a read into a vote while HTTP ran.
	var pending: Array = _state["pending"]
	for index: int in range(pending.size()):
		if pending[index].get("p_key") == key and pending[index].get("p_answer") == entry.p_answer:
			pending.remove_at(index)
			break
	return true

func _flush() -> void:
	if _busy:
		_flush_again = true
		return
	if !is_configured() or ((_state["pending"] as Array).is_empty() and _prefetch.is_empty()):
		return
	if retry_delay_ms("quiz") > 0:
		_schedule_retry()
		return
	_busy = true
	_flush_again = false
	_debug_log("Flush: pending=%d" % (_state["pending"] as Array).size())
	if _token_needs_refresh() and !(await _authenticate()):
		_busy = false
		return
	# One quiz queue worker; leaderboard requests share only the auth lock.
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
			retry_success("quiz")
			_debug_log("Prefetch ready: question=%s already_answered=%s counts=%s" % [
				_debug_question(key), body["already_answered"], str(body["counts"])])
		else:
			prefetch_failed = true
			if _prefetch.is_empty():
				_prefetch.append(key)
			_debug_log("Prefetch failed: status=%d; retry later" % status)
			# Let pending writes proceed on catalog errors, but avoid duplicate network failures.
			if status not in [400, 404, 422]:
				retry_failure("quiz", response)
				_busy = false
				_schedule_retry()
				return
			break
	var remaining: int = (_state["pending"] as Array).size()
	while remaining > 0 and !(_state["pending"] as Array).is_empty() and is_configured():
		var pending: Array = _state["pending"]
		var count := mini(remaining, mini(pending.size(), MAX_BATCH if _batch_supported else 1))
		var entries: Array = []
		for index: int in range(count):
			var entry: Dictionary = pending[index].duplicate(true)
			entry["p_include_counts"] = !_cache.has(str(entry.p_key))
			entries.append(entry)
		var response: Dictionary
		if entries.size() > 1:
			response = await _authorized_rpc(_batch_rpc_path(), {"p_answers": entries}, true)
			var error_body: Variant = response.get("body")
			if int(response.get("status", 0)) == 404 or (error_body is Dictionary and error_body.get("code") == "PGRST202"):
				# Deployment compatibility: old servers retain the single-answer RPC.
				_batch_supported = false
				continue
		else:
			response = await _quiz_rpc(entries[0])
		if bool(response.get("identity_reset", false)):
			_busy = false
			if !_access_token.is_empty():
				_flush.call_deferred()
			return
		var status: int = int(response.get("status", 0))
		var body: Variant = response.get("body")
		if entries.size() > 1:
			if status != 200 or !_batch_reply_valid(body, entries):
				retry_failure("quiz", response)
				break
			retry_success("quiz")
			for index: int in range(entries.size()):
				var item: Dictionary = body.results[index]
				if item.ok:
					_acknowledge_entry(entries[index], item)
				else:
					_rotate_pending_entry(str(entries[index].p_key))
		elif status == 200 and body is Dictionary and body.get("ok") == true:
			if !_acknowledge_entry(entries[0], body):
				retry_failure("quiz", response)
				break
			retry_success("quiz")
		elif status in [400, 404, 422]:
			_rotate_pending_entry(str(entries[0].p_key))
		else:
			retry_failure("quiz", response)
			break
		remaining -= entries.size()
		_save()
	_busy = false
	_debug_log("Flush finished: pending=%d" % (_state["pending"] as Array).size())
	_schedule_retry()
	if _flush_again or (!prefetch_failed and !_prefetch.is_empty()):
		_flush.call_deferred()

func _rotate_pending_entry(key: String) -> void:
	var pending: Array = _state["pending"]
	for index: int in range(pending.size()):
		if pending[index].get("p_key") == key:
			pending.append(pending.pop_at(index))
			return

func _retry_now_ms() -> int:
	return Time.get_ticks_msec()

func _retry_state(lane: String) -> RefCounted:
	if !_retry_states.has(lane):
		_retry_states[lane] = RETRY_POLICY.new()
	return _retry_states[lane]

func retry_delay_ms(lane: String) -> int:
	var now := _retry_now_ms()
	return maxi(_retry_state("auth").remaining_ms(now), _retry_state(lane).remaining_ms(now))

func retry_failure(lane: String, response: Dictionary) -> void:
	if response.get("retry_deferred", false) or response.get("retry_scheduled", false) or response.get("identity_reset", false):
		return
	var delay: int = _retry_state(lane).failed(_retry_now_ms())
	response["retry_scheduled"] = true
	_debug_log("Retry lane=%s delay_ms=%d" % [lane, delay])
	if lane in ["auth", "quiz"]:
		_schedule_retry()

func retry_success(lane: String) -> void:
	_retry_state(lane).succeeded()
	if lane in ["auth", "quiz"]:
		_schedule_retry()

func _schedule_retry() -> void:
	if is_instance_valid(_retry):
		var delay := retry_delay_ms("quiz")
		_retry.start(float(delay) / 1000.0 if delay > 0 else RETRY_POLICY.base_seconds())
