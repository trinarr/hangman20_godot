extends Node
const TRANSPORT = preload("res://tools/tests/leaderboard_transport_mock.gd")
const CLIENT = preload("res://tools/tests/leaderboard_client_mock.gd")
const ENVIRONMENT = preload("res://tools/tests/quiz_environment_mock.gd")
var checks := 0
var failures := 0
var delivered: Array = []

func check(value: bool, message: String) -> void:
	checks += 1
	if !value:
		failures += 1
		push_error(message)

func _ready() -> void:
	run.call_deferred()

func row(stars: int = 80) -> Dictionary:
	return {"player_id":"123", "nickname":"Игрок 123", "character_id":2, "frame_id":3, "is_filler":false, "rank":1, "top_percent":null, "stars":stars}

func reply(stars: int = 80, top: bool = true, language: String = "ru") -> Dictionary:
	var body: Dictionary = {"ok":true,"protocol_version":2,"owner_id":"test-owner", "me":row(stars), "total_players":1, "language":language}
	if top:
		var entry := row(stars)
		entry["is_me"] = true
		body["top"] = [entry]
		body["fillers"] = []
		for index: int in range(100):
			body.fillers.append({"player_id":"filler:cis:%03d" % index,"nickname":"Ромашка%d" % index,"stars":30,"rank":index+1,"is_me":false,"is_filler":true})
	return {"status":200, "body":body}

func tokens() -> Dictionary:
	return {"status":200,"body":{"access_token":"test-access","refresh_token":"test-refresh","expires_in":3600}}

func settle(client: Node, transport: Node) -> void:
	for frame: int in range(200):
		await get_tree().process_frame
		if !client._busy and !transport._busy:
			await get_tree().process_frame
			if !client._busy and !transport._busy:
				return
	check(false, "Workers did not settle")

func run() -> void:
	GameState.guided_onboarding_completed = true
	GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
	var environment: Node = ENVIRONMENT.new()
	check(environment._leaderboard_rpc_path() == "/rest/v1/rpc/leaderboard_sync_dev", "Debug uses dev leaderboard RPC")
	check(!environment._path_allowed("/rest/v1/rpc/leaderboard_sync"), "Debug rejects production leaderboard RPC")
	check(environment._path_allowed(environment._leaderboard_rpc_path()), "Own leaderboard RPC allowed")
	environment.dev = false
	check(environment._leaderboard_rpc_path() == "/rest/v1/rpc/leaderboard_sync", "Release uses production leaderboard RPC")
	check(!environment._path_allowed("/rest/v1/rpc/leaderboard_sync_dev"), "Release rejects dev leaderboard RPC")
	environment.dev = true
	var disabled_env := OS.get_environment("HANGMAN_SUPABASE_NETWORK_DISABLED")
	OS.set_environment("HANGMAN_SUPABASE_NETWORK_DISABLED", "")
	ProjectSettings.set_setting("quiz_statistics/dev_enabled", false)
	check(environment.leaderboard_is_configured(), "Leaderboard works independently of disabled quiz statistics")
	var blocked: Dictionary = await environment._post("/rest/v1/rpc/leaderboard_sync", {"p_stars":9}, true)
	check(blocked.is_empty() and environment.get_child_count() == 0, "Real debug transport blocks direct production leaderboard RPC before HTTPRequest")
	ProjectSettings.set_setting("leaderboard/dev_enabled", false)
	ProjectSettings.set_setting("quiz_statistics/dev_enabled", true)
	blocked = await environment._post("/rest/v1/rpc/leaderboard_sync_dev", {"p_stars":9}, true)
	check(blocked.is_empty() and environment.get_child_count() == 0, "Quiz enablement cannot bypass disabled leaderboard")
	ProjectSettings.set_setting("leaderboard/dev_enabled", true)
	OS.set_environment("HANGMAN_SUPABASE_NETWORK_DISABLED", disabled_env)
	environment.free()
	check(!QuizStatistics.leaderboard_is_configured(), "Real leaderboard network disabled in tests")
	var before: int = QuizStatistics.get_child_count()
	check((await QuizStatistics.leaderboard_rpc({"p_stars":9})).is_empty(), "Test network guard blocks real leaderboard")
	check(QuizStatistics.get_child_count() == before, "Blocked leaderboard creates no HTTPRequest")
	var transport: Node = TRANSPORT.new()
	add_child(transport)
	transport._access_token = "test-access"
	var client: Node = CLIENT.new()
	client.transport = transport
	add_child(client)
	client.leaderboard_ready.connect(func(snapshot: Dictionary, cached: bool): delivered.append({"snapshot":snapshot,"cached":cached}))
	client.sync_stars(0)
	check(client._pending_stars == -1 and transport.calls.is_empty(), "Zero-star player is not queued or registered")
	client.sync_stars(40)
	client.sync_stars(80)
	transport.replies = [reply()]
	client.refresh()
	await settle(client,transport)
	check(transport.calls.size() == 1 and transport.calls[0].payload.p_stars == 80, "Only latest best offline score submitted")
	check(transport.calls[0].path == "/rest/v1/rpc/leaderboard_sync_dev", "Debug worker sends only dev RPC")
	check(transport.calls[0].payload.p_language == "ru", "Client sends nickname-pool language")
	check(client._pending_stars == -1 and client.cached_snapshot().me.stars == 80, "Successful score clears pending snapshot")
	check(client.get_player_id() == "123", "Nickname generation receives the own numeric server ID")
	check(transport.calls[0].payload.has("p_nickname"), "First identity uploads its profile")
	check(delivered.size() == 1 and !delivered.back().cached, "Top signal reports server response")
	var copied: Dictionary = client.cached_snapshot()
	copied.top[0].stars = 999
	check(client.cached_snapshot().top[0].stars == 80, "Caller cannot mutate cached top")
	client.refresh()
	check(transport.calls.size() == 1 and delivered.back().cached, "Repeated refresh uses one-minute cache")
	transport.replies = [reply(80)]
	client.refresh(true)
	await settle(client,transport)
	check(transport.calls.size() == 2 and !transport.calls.back().payload.has("p_stars"), "Forced refresh reads without submitting a score")
	check(!transport.calls.back().payload.has("p_nickname"), "Read-only refresh omits unchanged profile fields")
	client._cache_at_ms = Time.get_ticks_msec() - client.CACHE_MS
	transport.replies = [reply(80)]
	client.refresh()
	await settle(client,transport)
	check(transport.calls.size() == 3, "Expired cache loads again")
	# An update arriving in-flight must be sent after the older acknowledgement.
	transport.replies = [reply(100,false),reply(120,false)]
	client.sync_stars(100)
	client._flush()
	client.sync_stars(120)
	await settle(client,transport)
	check(transport.calls[-2].payload.p_stars == 100 and transport.calls[-1].payload.p_stars == 120, "Score changed in-flight is not dropped")
	check(!transport.calls.back().payload.p_include_top and client._cache_at_ms == -1, "Ordinary score sync avoids downloading top and invalidates cache")
	transport.replies = [{"status":503,"body":{}}]
	client.sync_stars(140)
	client._flush()
	await settle(client,transport)
	check(client._pending_stars == 140, "Network failure retains pending stars")
	transport.replies = [reply(140,false)]
	transport.advance_retry()
	client._flush()
	await settle(client,transport)
	check(client._pending_stars == -1 and client.cached_snapshot().me.stars == 140, "Retry acknowledges saved score")
	# Bounded cache and protocol validation.
	var invalid: Dictionary = reply().body
	invalid.top = []
	for index: int in range(101):
		invalid.top.append({"player_id":str(index),"rank":index+1,"stars":1,"is_me":false})
	check(!client._valid_snapshot(invalid,true), "More than 100 rows rejected")
	invalid = reply().body
	invalid.top[0].rank = 2
	check(!client._valid_snapshot(invalid,true), "Invalid top order rejected")
	invalid = reply().body
	invalid.top[0].stars = -1
	check(!client._valid_snapshot(invalid,true), "Negative score rejected")
	check(client._valid_snapshot({"ok":true,"protocol_version":2,"owner_id":"test-owner","me":null,"top":[],"total_players":0,"language":"ru"},true), "Read-only nonparticipant accepted")
	var percentile: Dictionary = {"ok":true,"protocol_version":2,"owner_id":"test-owner","me":{"player_id":"123","nickname":"Игрок 123","is_filler":false,"stars":140,"rank":null,"top_percent":6},"top":[],"total_players":10000,"language":"ru"}
	check(client._valid_snapshot(percentile,true), "Own position outside top-100 accepts a percentile instead of exact rank")
	percentile.me.top_percent = 0
	check(!client._valid_snapshot(percentile,true), "Top zero percent rejected")
	percentile.me.top_percent = 101
	check(!client._valid_snapshot(percentile,true), "Top above one hundred percent rejected")
	percentile.me.top_percent = 6.5
	check(!client._valid_snapshot(percentile,true), "Fractional percentile rejected")
	percentile.me.top_percent = 6
	percentile.me.rank = 101
	check(!client._valid_snapshot(percentile,true), "Exact own rank outside top-100 rejected")
	percentile.me.rank = 1
	check(!client._valid_snapshot(percentile,true), "Own row cannot contain both exact rank and percentile")
	percentile.me.rank = null
	transport.replies = [{"status":200,"body":percentile}]
	client.refresh(true)
	await settle(client,transport)
	check(client.cached_snapshot().me.rank == null and client.cached_snapshot().me.top_percent == 6 and client.cached_snapshot().total_players == 10000, "Cached own position keeps only Top N percent outside top-100")
	# Real-only server lists cannot contain fillers; seeding is separate.
	var invalid_seed: Dictionary = reply().body
	check(client._valid_snapshot(invalid_seed, true), "Separate initial roster is accepted")
	invalid_seed.fillers[0].stars = 101
	check(!client._valid_snapshot(invalid_seed, true), "Initial filler scores above 100 are rejected")
	invalid_seed = reply().body
	invalid_seed.top[0] = invalid_seed.fillers[0]
	check(!client._valid_snapshot(invalid_seed, true), "Fillers cannot masquerade as current real leaders")
	var language_calls: int = transport.calls.size()
	client.language = "en"
	transport.replies = [reply(140,true,"en")]
	client.refresh()
	await settle(client,transport)
	check(transport.calls.size() == language_calls+1 and transport.calls.back().payload.p_language == "en" and client.cached_snapshot().language == "en", "Language change bypasses old pool cache")
	language_calls = transport.calls.size()
	var delivered_before: int = delivered.size()
	transport.replies = [reply(140,true,"en"),reply(140,true,"ru")]
	client.refresh(true)
	client.language = "ru"
	await settle(client,transport)
	check(transport.calls.size() == language_calls+2 and transport.calls.back().payload.p_language == "ru", "Language changed in-flight triggers a read for the correct pool")
	check(delivered.size() == delivered_before+1 and delivered.back().snapshot.language == "ru", "Stale-language snapshot is not emitted to consumers")
	var previous_calls: int = transport.calls.size()
	client.legal = false
	client.sync_stars(900)
	client.refresh(true)
	check(transport.calls.size() == previous_calls and client._pending_stars == -1, "No registration or upload before legal acceptance")
	client.legal = true
	# Authentication is shared, but quiz HTTP and leaderboard HTTP may overlap.
	Database.load_languages("ru", "ru")
	var question: Dictionary = Database.get_quiz_questions_by_theme_index(0)[0]
	transport._access_token = ""
	transport._state.refresh_token = ""
	var quiz_reply: Dictionary = {"status":200,"body":{"ok":true,"counts":[1,2,3,4],"already_answered":true}}
	transport.route_replies = {
		"/auth/v1/signup": [tokens()], transport._leaderboard_rpc_path(): [reply(140)], transport._rpc_path(): [quiz_reply]}
	transport.delay_frames[transport._rpc_path()] = 5
	previous_calls = transport.calls.size()
	transport.record_answer(question,0,0,true)
	client.refresh(true)
	await settle(client,transport)
	check(transport.calls.size() == previous_calls + 3, "Concurrent quiz and leaderboard share one authentication")
	check(transport.calls[previous_calls].path == "/auth/v1/signup" and transport.max_active_calls >= 2, "Independent API requests overlap after shared signup")
	# A batch of queued votes does not block a leaderboard read.
	var q2: Dictionary = Database.get_quiz_questions_by_theme_index(0)[1]
	var q3: Dictionary = Database.get_quiz_questions_by_theme_index(0)[2]
	transport._state.pending = [
		{"p_key":transport.describe_question(q2,0).key,"p_answer":0},
		{"p_key":transport.describe_question(q3,0).key,"p_answer":0}]
	var results: Array = []
	for entry: Dictionary in transport._state.pending:
		var item := entry.duplicate(true)
		item.merge(quiz_reply.body)
		results.append(item)
	transport.route_replies = {
		transport._batch_rpc_path(): [{"status":200,"body":{"ok":true,"results":results}}],
		transport._leaderboard_rpc_path(): [reply(140)]}
	transport.delay_frames[transport._batch_rpc_path()] = 5
	previous_calls = transport.calls.size()
	transport._flush()
	client.refresh(true)
	await settle(client,transport)
	check(transport.calls.size() == previous_calls+2 and transport.calls[previous_calls+1].path.ends_with("leaderboard_sync_dev"), "Leaderboard starts without waiting for the offline quiz batch")
	check(transport._state.pending.is_empty(), "Quiz batch is acknowledged independently")
	transport.route_replies.clear()
	transport.delay_frames.clear()
	# 401 recovery uses same shared immediate retry, including leaderboard RPC.
	transport._state.refresh_token = "old-refresh"
	transport.replies = [{"status":401,"body":{}},tokens(),reply(140)]
	previous_calls = transport.calls.size()
	client.refresh(true)
	await settle(client,transport)
	check(transport.calls.size() == previous_calls + 3 and transport.calls[previous_calls+1].path.contains("refresh_token"), "Leaderboard refreshes JWT and retries immediately")
	# Revoked identity clears old cached ranking; current score can register a new participant.
	transport._access_token = ""
	transport.replies = [{"status":400,"body":{"error_code":"refresh_token_not_found"}},tokens(),reply(90),reply(90)]
	previous_calls = transport.calls.size()
	client.refresh(true)
	await settle(client,transport)
	check(transport._identity_generation == 1 and transport.calls[previous_calls+1].path == "/auth/v1/signup", "Revoked session creates one replacement account")
	check(client.cached_snapshot().me.stars == 90 and client._pending_stars == -1, "Current stars synchronize under replacement identity")
	# Restart uses the ordinary persisted game score rather than a growing event queue.
	client._started = false
	client.current_stars = 160
	transport.replies = [reply(160)]
	client._tick()
	await settle(client,transport)
	check(client._started and transport.calls.back().payload.p_stars == 160, "Startup synchronizes persisted star total")
	check(!transport.calls.back().payload.has("p_nickname"), "Startup does not resend an already acknowledged unchanged profile")
	# An unranked profile must synchronize without registering a zero score.
	client._snapshot.clear()
	check(client.get_player_id() == "123", "Own ID can be restored from the saved account roster")
	client.current_stars = 0
	client.profile = {"nickname":"FirstProfile", "character_id":2, "frame_id":3}
	transport.replies = [{"status":503,"body":{}}]
	client.sync_profile()
	client._flush()
	await settle(client,transport)
	check(client._profile_pending, "Profile failure keeps the offline request pending")
	transport.replies = [reply(160,false), reply(160,false)]
	transport.advance_retry()
	client._flush()
	client.profile = {"nickname":"NewerProfile", "character_id":1, "frame_id":5}
	client.sync_profile()
	await settle(client,transport)
	check(transport.calls[-2].payload.p_nickname == "FirstProfile" and transport.calls[-1].payload.p_nickname == "NewerProfile" and !client._profile_pending, "Profile changed in flight is uploaded after the older acknowledgement")
	check(!transport.calls.back().payload.has("p_stars"), "Zero-star profile update sends no ranking score")
	var appearance_row := row()
	appearance_row["character_id"] = 2
	appearance_row["frame_id"] = 5
	check(client._valid_row(appearance_row, true), "Valid public appearance IDs accepted")
	appearance_row.frame_id = 6
	check(!client._valid_row(appearance_row, true), "Invalid public appearance ID rejected")
	# Tournament candidates use public real rows from cache, excluding every own row.
	var saved_boards: Dictionary = client._boards.duplicate(true)
	var saved_language: String = client.language
	client.language = "ru"
	var own_entry := row()
	own_entry.is_me = true
	var first_real := row(70)
	first_real.merge({"player_id":"201", "nickname":"PublicOne", "is_me":false, "rank":2}, true)
	var second_real := row(60)
	second_real.merge({"player_id":"202", "nickname":"PublicTwo", "is_me":false, "rank":3}, true)
	client._boards = {"ru":{"initialized":true, "me":row(), "real_top":[own_entry, first_real, second_real], "fillers":[], "total_players":3}}
	var older := first_real.duplicate(true)
	older.nickname = "OldName"
	var third_real := row(50)
	third_real.merge({"player_id":"203", "nickname":"PublicThree", "is_me":false, "rank":3}, true)
	var own_other := own_entry.duplicate(true)
	own_other.is_me = false
	client._boards.en = {"initialized":true, "me":row(), "real_top":[own_other, older, third_real], "fillers":[], "total_players":3}
	var candidates: Array = client.tournament_profiles()
	check(candidates.size() == 3 and candidates[0].nickname == "PublicOne" and candidates[2].player_id == "203", "Tournament combines cached locales, prefers current locale, deduplicates and excludes own identity")
	check(candidates[0].character_id == 2 and candidates[0].frame_id == 3 and !candidates[0].has("stars"), "Tournament candidates copy public appearance without leaderboard scores")
	candidates[0].nickname = "ExternalMutation"
	check(client.tournament_profiles()[0].nickname == "PublicOne", "Candidate snapshots do not mutate leaderboard cache")
	client._save_store()
	var reloaded: Node = CLIENT.new()
	reloaded.transport = transport
	reloaded.save_file = client.save_file
	add_child(reloaded)
	check(reloaded.tournament_profiles().size() == 3, "Offline restart restores real tournament candidates from persisted leaderboard cache")
	reloaded.legal = false
	check(reloaded.tournament_profiles().is_empty(), "Candidate cache respects legal access gate")
	reloaded.legal = true
	reloaded.tutorial_completed = false
	check(reloaded.tournament_profiles().is_empty(), "Candidate cache respects onboarding access gate")
	reloaded.queue_free()
	client._boards = saved_boards
	client.language = saved_language
	client._owner_id = ""
	check(client.get_player_id().is_empty(), "A cached row without a known account cannot supply a nickname ID")
	client._owner_id = "test-owner"
	client._snapshot = {"me":{"player_id":"filler:cis:001", "is_filler":true}}
	check(client.get_player_id().is_empty(), "Filler IDs are never used for generated player names")
	client._snapshot = {"me":{"player_id":"00000000-0000-0000-0000-000000000001", "is_filler":false}}
	check(client.get_player_id().is_empty(), "Auth UUID is not a numeric player ID")
	client._on_identity_changed()
	check(client.get_player_id().is_empty(), "Replacing identity discards the previous numeric ID")
	client.queue_free()
	transport.queue_free()
	await get_tree().process_frame
	print("LEADERBOARD checks=%d failures=%d" % [checks,failures])
	get_tree().quit(1 if failures else 0)
