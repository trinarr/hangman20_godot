extends Node
const MOCK = preload("res://tools/tests/quiz_statistics_mock.gd")
var checks := 0
var failures := 0
func check(condition: bool, message: String) -> void:
	checks += 1
	if !condition:
		failures += 1
		push_error(message)
func _ready() -> void:
	call_deferred("run")
func settle(service: Node) -> void:
	for frame: int in range(200):
		await get_tree().process_frame
		if !service._busy:
			await get_tree().process_frame
			if !service._busy:
				return
	check(false, "Session worker did not settle")
func session() -> Node:
	var service: Node = MOCK.new()
	add_child(service)
	service._access_token = "old-access"
	service._state.refresh_token = "old-refresh"
	return service
func tokens() -> Dictionary:
	return {"status":200,"body":{"access_token":"new-access","refresh_token":"new-refresh","expires_in":3600}}
func snapshot() -> Dictionary:
	return {"status":200,"body":{"ok":true,"counts":[1,2,3,4],"already_answered":false}}
func revoked(code: String = "refresh_token_not_found") -> Dictionary:
	return {"status":400,"body":{"error_code":code}}
func run() -> void:
	Database.load_languages("ru", "ru")
	var q: Dictionary = Database.get_quiz_questions_by_theme_index(0)[0]
	var other: Dictionary = Database.get_quiz_questions_by_theme_index(0)[1]
	var key: String = QuizStatistics.describe_question(q,0).key
	var service := session()
	service._cache[key] = [1,2,3,4]
	service._answered[key] = false
	service.replies = [{"status":401,"body":{}},tokens(),{"status":200,"body":{"ok":true}}]
	service.record_answer(q,0,0,true)
	await settle(service)
	check(service.calls.size() == 3, "401 immediately refreshes and retries without a timer")
	check(service.calls[1].path.contains("refresh_token"), "Retry refreshes existing identity")
	check(service.calls[0].payload == service.calls[2].payload, "Retry sends the exact same vote")
	check(service._state.pending.is_empty() and service._state.refresh_token == "new-refresh", "Acknowledged retry clears queue and saves rotated token")
	check(service._identity_generation == 0, "JWT refresh does not replace account")
	service.queue_free()
	service = session()
	service.replies = [{"status":401,"body":{}},tokens(),snapshot()]
	service.prefetch_question(q,0)
	await settle(service)
	check(service.calls.size() == 3 and service._cache[key] == [1,2,3,4], "Prefetch also retries immediately after 401")
	service.queue_free()
	service = session()
	service.replies = [{"status":401,"body":{}},tokens(),{"status":401,"body":{}}]
	service.record_answer(q,0,0,true)
	await settle(service)
	check(service.calls.size() == 3 and service._state.pending.size() == 1, "Second 401 stops the immediate retry loop and retains vote")
	check(service._access_token.is_empty(), "Second 401 invalidates access token")
	service.queue_free()
	service = session()
	service._access_token_refresh_at_ms = maxi(1, Time.get_ticks_msec() - 1)
	service.replies = [tokens(),snapshot()]
	service.prefetch_question(q,0)
	await settle(service)
	check(service.calls.size() == 2 and service.calls[0].path.contains("refresh_token"), "Known JWT expiry refreshes before RPC")
	check(service._access_token_refresh_at_ms > Time.get_ticks_msec(), "New token has a future refresh deadline")
	service.queue_free()
	# Definitive revocation at startup discards old votes before anonymous signup.
	for code: String in ["refresh_token_not_found","refresh_token_already_used","session_not_found","session_expired","user_not_found","invalid_grant"]:
		service = session()
		service._access_token = ""
		service._state.pending = [{"p_key":"old-question","p_answer":0}]
		service._cache["old-question"] = [10,20,30,40]
		service._answered["old-question"] = true
		service.replies = [revoked(code),tokens(),snapshot()]
		service.prefetch_question(q,0)
		await settle(service)
		check(service.calls.size() == 3 and service.calls[1].path == "/auth/v1/signup", "Revoked session creates a replacement anonymous account: " + code)
		check(service._identity_generation == 1 and service._state.pending.is_empty(), "Old votes discarded on identity reset: " + code)
		check(!service._cache.has("old-question") and !service._answered.has("old-question"), "Old cached counts and attempt flags discarded: " + code)
		check(service.calls[2].payload.p_answer == -1 and service._state.refresh_token == "new-refresh", "Only read request continues under new identity: " + code)
		service.queue_free()
	# Revocation discovered after sending a vote must not replay it on the new account.
	service = session()
	service.replies = [{"status":401,"body":{}},revoked(),tokens()]
	service.record_answer(q,0,0,true)
	await settle(service)
	check(service.calls.size() == 3 and service.calls.back().path == "/auth/v1/signup", "Old in-flight vote is not retried on replacement identity")
	check(service._state.pending.is_empty() and service._cache.is_empty(), "In-flight identity reset leaves no old pending state")
	service.queue_free()
	service = session()
	service.replies = [{"status":401,"body":{}},revoked(),tokens(),snapshot()]
	service.prefetch_question(q,0)
	await settle(service)
	check(service.calls.size() == 4 and service._cache[key] == [1,2,3,4], "Read-only prefetch may retry after anonymous replacement")
	service.queue_free()
	# Network failures, rate limits and bans must not rotate identities or delete votes.
	for response: Dictionary in [{},{"status":429,"body":{}},{"status":500,"body":{}},{"status":400,"body":{}},{"status":403,"body":{"error_code":"user_banned"}}]:
		service = session()
		service._access_token = ""
		service._state.pending = [{"p_key":"old-question","p_answer":0}]
		service.replies = [response]
		service._flush()
		await settle(service)
		check(service.calls.size() == 1 and service._identity_generation == 0, "Temporary or unclassified error must not create account")
		check(service._state.pending.size() == 1 and service._state.refresh_token == "old-refresh", "Non-revocation preserves queue and refresh token")
		service.queue_free()
	# Failed replacement signup retries later without replaying the discarded queue.
	service = session()
	service._access_token = ""
	service._state.pending = [{"p_key":"old-question","p_answer":0}]
	service.replies = [revoked(),{}]
	service.prefetch_question(q,0)
	await settle(service)
	check(service.calls.size() == 2 and service._state.pending.is_empty() and service._state.refresh_token.is_empty(), "Signup failure does not resurrect old votes or tokens")
	service.replies = [tokens(),snapshot()]
	service._flush()
	await settle(service)
	check(service.calls.size() == 4 and service.calls[2].path == "/auth/v1/signup" and service._cache.has(key), "Replacement signup can recover on later attempt")
	service.queue_free()
	# A genuinely new answer arriving during replacement signup must survive.
	service = session()
	service.replies = [{"status":401,"body":{}},revoked(),tokens(),{"status":200,"body":{"ok":true,"counts":[1,0,0,0],"already_answered":true}}]
	service.record_answer(q,0,0,true)
	for frame: int in range(50):
		if service._identity_generation == 1:
			break
		await get_tree().process_frame
	check(service._identity_generation == 1, "Replacement begins before injecting a new answer")
	service.record_answer(other,0,0,true)
	await settle(service)
	check(service._state.pending.is_empty() and service.calls.size() == 4, "New answer submitted during signup is processed under replacement account")
	check(service.calls[0].payload.p_key != service.calls[3].payload.p_key, "Only new question is sent after identity reset")
	service.queue_free()
	print("QUIZ_SESSIONS checks=%d failures=%d" % [checks,failures])
	get_tree().quit(0 if failures == 0 else 1)
