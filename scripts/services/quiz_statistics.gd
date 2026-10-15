extends Node
## Optional Supabase transport. Gameplay never waits for authentication or network.
signal statistics_ready(question_key: String, counts: Array)

const SAVE_PATH := "user://quiz_statistics.json"
const MAX_PENDING := 4000
var _state: Dictionary = {"pending": [], "refresh_token": ""}
var _access_token := ""
var _busy := false
var _cache: Dictionary = {}
var _retry: Timer

func _ready() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var saved: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
		if saved is Dictionary and saved.get("pending") is Array:
			_state = saved
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

func record_answer(question: Dictionary, theme_index: int, answer_index: int, eligible: bool) -> void:
	if !is_configured():
		return
	var description := describe_question(question, theme_index)
	if description.is_empty():
		return
	var key: String = description["key"]
	var selected := -1
	if answer_index >= 0 and answer_index < 4:
		selected = int(description["mapping"][answer_index]) if eligible else -2
	var pending: Array = _state["pending"]
	# Keep the earliest offline answer; retries and repeat plays never replace it.
	for entry: Dictionary in pending:
		if entry.get("p_key") == key:
			if int(entry.get("p_answer", -1)) == -1 and selected != -1:
				entry["p_answer"] = selected
				_save()
			if _cache.has(key):
				statistics_ready.emit(key, _cache[key])
			_flush()
			return
	if pending.size() >= MAX_PENDING:
		return
	pending.append({"p_key": key, "p_answer": selected})
	_save()
	if _cache.has(key):
		statistics_ready.emit(key, _cache[key])
	_flush()

func _save() -> void:
	# Write then rename so termination during a write preserves the previous queue.
	var file := FileAccess.open(SAVE_PATH + ".tmp", FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(_state))
	file.close()
	DirAccess.rename_absolute(SAVE_PATH + ".tmp", SAVE_PATH)

func _post(path: String, payload: Dictionary, authorized: bool = false) -> Dictionary:
	var request := HTTPRequest.new()
	request.timeout = 10.0
	add_child(request)
	var headers := PackedStringArray(["Content-Type: application/json", "apikey: " + _public_key()])
	if authorized:
		headers.append("Authorization: Bearer " + _access_token)
	var error := request.request(_url() + path, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if error != OK:
		request.queue_free()
		return {}
	var response: Array = await request.request_completed
	request.queue_free()
	if int(response[0]) != HTTPRequest.RESULT_SUCCESS:
		return {}
	var body: Variant = JSON.parse_string((response[3] as PackedByteArray).get_string_from_utf8())
	return {"status": int(response[1]), "body": body}

func _authenticate() -> bool:
	var refresh: String = str(_state.get("refresh_token", ""))
	var response: Dictionary
	if !refresh.is_empty():
		response = await _post("/auth/v1/token?grant_type=refresh_token", {"refresh_token": refresh})
		# Do not create a new identity after a transient network failure.
		if response.is_empty() or int(response.get("status", 0)) >= 500:
			return false
		if int(response.get("status", 0)) not in [400, 401, 403] and int(response.get("status", 0)) != 200:
			return false
		# A lost/invalid identity requires explicit recovery, never silent replacement.
		if int(response.get("status", 0)) != 200:
			return false
	else:
		response = await _post("/auth/v1/signup", {})
	var body: Variant = response.get("body")
	if int(response.get("status", 0)) != 200 or !(body is Dictionary):
		return false
	_access_token = str(body.get("access_token", ""))
	_state["refresh_token"] = str(body.get("refresh_token", ""))
	_save()
	return !_access_token.is_empty()

func _flush() -> void:
	if _busy or !is_configured() or (_state["pending"] as Array).is_empty():
		return
	_busy = true
	if _access_token.is_empty() and !(await _authenticate()):
		_busy = false
		return
	var pending: Array = _state["pending"]
	for _attempt: int in range(pending.size()):
		if pending.is_empty() or !is_configured():
			break
		var entry: Dictionary = pending[0].duplicate(true)
		var response := await _post("/rest/v1/rpc/quiz_answer", entry, true)
		var status: int = int(response.get("status", 0))
		if status == 401:
			_access_token = ""
			break
		var body: Variant = response.get("body")
		if status == 200 and body is Dictionary and body.get("counts") is Array:
			var counts: Array = body["counts"]
			if counts.size() != 4:
				break
			var key: String = str(entry["p_key"])
			_cache[key] = counts
			statistics_ready.emit(key, counts)
		elif status not in [400, 404, 422]:
			break
		# Keep undeployed catalog versions without blocking all other answers.
		else:
			pending.append(pending.pop_front())
			_save()
			continue
		if int(pending[0]["p_answer"]) == int(entry["p_answer"]):
			pending.pop_front()
		_save()
	_busy = false
