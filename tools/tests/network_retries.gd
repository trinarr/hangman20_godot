extends Node
const POLICY = preload("res://scripts/services/api_retry_policy.gd")
const MOCK = preload("res://tools/tests/leaderboard_transport_mock.gd")
const CLIENT = preload("res://tools/tests/leaderboard_client_mock.gd")
const BOARD_FIXTURE = preload("res://tools/tests/leaderboard.gd")
var checks := 0
var failures := 0

func _ready() -> void:
	run.call_deferred()

func check(value: bool, message: String) -> void:
	checks += 1
	if !value:
		failures += 1
		push_error(message)

func settle(transport: Node, client: Node = null) -> void:
	for frame: int in range(200):
		await get_tree().process_frame
		if !transport._busy and !transport._auth_busy and transport.active_calls == 0 and (client == null or !client._busy):
			await get_tree().process_frame
			if transport.active_calls == 0 and !transport._busy and (client == null or !client._busy):
				return
	check(false, "Retry workers settle without real sleeps")

func transport() -> Node:
	var node: Node = MOCK.new()
	add_child(node)
	node._access_token = "test-access"
	node._state.refresh_token = "test-refresh"
	node.retry_clock_ms = 1000
	return node

func client(node: Node, saved_file: String = "") -> Node:
	var result: Node = CLIENT.new()
	result.transport = node
	if !saved_file.is_empty():
		result.save_file = saved_file
	add_child(result)
	return result

func vote_reply() -> Dictionary:
	return {"status":200,"body":{"ok":true,"counts":[1,0,0,0],"already_answered":true}}

func run() -> void:
	GameState.guided_onboarding_completed = true
	GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
	var policy := POLICY.new()
	var now := 1000
	var previous := 0
	for index: int in range(10):
		var delay: int = policy.failed(now)
		check(delay > 0 and delay <= 900000, "Delay is positive and capped")
		if index < 5:
			check(delay > previous, "Consecutive failures increase delay despite jitter")
		check(policy.remaining_ms(now + delay - 1) == 1 and policy.remaining_ms(now + delay) == 0, "Deadline is monotonic and expires exactly")
		previous = delay
		now += delay
	policy.succeeded()
	check(policy.failures == 0 and policy.remaining_ms(now) == 0, "Success clears accumulated failures")
	check(policy.failed(now) >= 24000 and policy.remaining_ms(now) <= 36000, "First failure after success returns to base interval")
	# Quiz failures cannot be bypassed by a new flush, and do not block leaderboard HTTP.
	var node := transport()
	node._state.pending = [{"p_key":"en:1:%s" % "ab".repeat(32),"p_answer":0}]
	node.replies = [{"status":429}]
	node._flush()
	await settle(node)
	var delay1: int = node.retry_delay_ms("quiz")
	check(delay1 >= 24000 and delay1 <= 36000 and node._state.pending.size() == 1, "429 retains vote and starts a bounded first delay")
	for attempt: int in range(5):
		node._flush()
	await settle(node)
	check(node.calls.size() == 1 and node._retry_state("quiz").failures == 1, "Deferred retries make no HTTP calls and do not inflate failure count")
	node.replies = [{"status":200,"body":{"ok":true}}]
	await node.leaderboard_rpc({})
	check(node.calls.size() == 2 and node.retry_delay_ms("quiz") == delay1, "Quiz cooldown does not block another API lane")
	node.replies = [{"status":503}]
	await node.leaderboard_rpc({}, true)
	var manual_calls: int = node.calls.size()
	var still_deferred: Dictionary = await node.leaderboard_rpc({})
	check(still_deferred.get("retry_deferred") == true and node.calls.size() == manual_calls, "Background reads retain leaderboard cooldown after a manual failure")
	node.replies = [{"status":200,"body":{"ok":true}}]
	var manual_reply: Dictionary = await node.leaderboard_rpc({}, true)
	check(int(manual_reply.status) == 200 and node.calls.size() == manual_calls + 1, "Manual read bypasses an active leaderboard cooldown")
	check(node.retry_delay_ms("quiz") == delay1 and node._state.pending.size() == 1, "Manual read does not clear the quiz cooldown or its queued vote")
	node.advance_retry()
	node.replies = [{"status":503}]
	node._flush()
	await settle(node)
	check(node.retry_delay_ms("quiz") >= 48000 and node._retry_state("quiz").failures == 2, "5xx increases retry interval without counting the same error twice")
	node.advance_retry()
	node.replies = [vote_reply()]
	node._flush()
	await settle(node)
	check(node._state.pending.is_empty() and node.retry_delay_ms("quiz") == 0 and node._retry_state("quiz").failures == 0, "Acknowledged vote resets its retry lane")
	node.queue_free()
	# Authentication cooldown is shared by both API lanes, with one failure per auth attempt.
	node = transport()
	node._access_token = ""
	node._state.pending = [{"p_key":"en:1:%s" % "ab".repeat(32),"p_answer":0}]
	node.replies = [{"status":503}]
	node._flush()
	node.leaderboard_rpc({})
	await settle(node)
	check(node.calls.size() == 1 and node._retry_state("auth").failures == 1, "Parallel callers share one failed authentication and one cooldown")
	node._flush()
	var deferred: Dictionary = await node.leaderboard_rpc({})
	check(deferred.get("retry_deferred") == true and node.calls.size() == 1, "Both API lanes respect an auth cooldown")
	var auth_calls: int = node.calls.size()
	node.replies = [{"status":200,"body":{"access_token":"new","refresh_token":"new-refresh","expires_in":3600}}, {"status":200,"body":{"ok":true}}]
	var auth_manual: Dictionary = await node.leaderboard_rpc({}, true)
	check(int(auth_manual.status) == 200 and node.calls.size() == auth_calls + 2, "Manual action bypasses auth cooldown and then performs its RPC")
	check(node._state.pending.size() == 1, "Manual authentication does not lose the queued quiz vote")
	node.replies = [vote_reply()]
	node._flush()
	await settle(node)
	check(node._state.pending.is_empty() and node._retry_state("auth").failures == 0, "Authentication recovers without losing the queue")
	node.queue_free()
	var joined_auth := transport()
	joined_auth._access_token = ""
	joined_auth.replies = [{"status":503}, {"status":200,"body":{"access_token":"joined","refresh_token":"joined-refresh","expires_in":3600}}, {"status":200,"body":{"ok":true}}]
	joined_auth._authenticate()
	var joined_reply: Dictionary = await joined_auth.leaderboard_rpc({}, true)
	check(int(joined_reply.status) == 200 and joined_auth.calls.size() == 3, "Manual request waiting on a failed background authentication receives its own immediate auth attempt")
	check(joined_auth.max_active_calls == 1, "Manual authentication remains serialized with the older attempt")
	joined_auth.queue_free()
	# Confirmed stars persist independently of snapshots downloaded by the UI.
	node = transport()
	var fixtures: Node = BOARD_FIXTURE.new()
	var board := client(node)
	board.current_stars = 100
	node.replies = [fixtures.reply(100, false)]
	board.sync_stars(100)
	board._flush()
	await settle(node, board)
	check(board._confirmed_stars == 100 and board._pending_stars == -1, "Server acknowledgement records the confirmed star total")
	var restored := client(node, board.save_file)
	restored.current_stars = 100
	node.replies = [fixtures.reply(100)]
	restored._tick()
	await settle(node, restored)
	check(restored._confirmed_stars == 100 and !node.calls.back().payload.has("p_stars"), "Restart refreshes ranking without resubmitting confirmed stars")
	var before: int = node.calls.size()
	restored.sync_stars(100)
	restored.sync_stars(90)
	restored._flush()
	await settle(node, restored)
	check(node.calls.size() == before, "Equal or lower totals cause no upload")
	node.replies = [{"status":503}]
	restored.sync_stars(200)
	restored._flush()
	await settle(node, restored)
	check(restored._confirmed_stars == 100 and restored._pending_stars == 200, "Failed submission does not advance confirmation")
	before = node.calls.size()
	restored.sync_stars(220)
	restored.refresh(true)
	await settle(node, restored)
	check(node.calls.size() == before and restored._pending_stars == 220, "New best result and forced refresh retain work without bypassing cooldown")
	node.advance_retry()
	node.replies = [fixtures.reply(220),fixtures.reply(230, false)]
	restored._flush()
	restored.current_stars = 230
	restored.sync_stars(230)
	await settle(node, restored)
	check(restored._confirmed_stars == 230 and restored._pending_stars == -1, "Older acknowledgement does not drop a higher result queued in flight")
	check(node._retry_state("leaderboard").failures == 0, "Valid leaderboard response resets its retry lane")
	# An apparently successful response below the submitted score is not an acknowledgement.
	node.replies = [fixtures.reply(230, false)]
	restored.sync_stars(240)
	restored._flush()
	await settle(node, restored)
	check(restored._confirmed_stars == 230 and restored._pending_stars == 240, "Lower server score cannot falsely acknowledge a submission")
	var restarted := client(node, restored.save_file)
	restarted._ensure_store_loaded()
	check(restarted._confirmed_stars == 230, "Only the successful confirmation survives restart")
	restarted.current_stars = 240
	restarted._on_identity_changed()
	check(restarted._confirmed_stars == -1 and restarted._pending_stars == 240, "Replacement account always submits its own score")
	# Legacy or malformed caches never suppress an unconfirmed score.
	var legacy := client(node)
	var file := FileAccess.open(legacy.save_file, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version":1,"owner_id":"legacy-owner","boards":{},"confirmed_stars":"240"}))
	file.close()
	legacy.sync_stars(240)
	check(legacy._confirmed_stars == -1 and legacy._pending_stars == 240, "Malformed acknowledgement is ignored without losing the current result")
	var manual_transport := transport()
	var manual_board := client(manual_transport)
	manual_board.current_stars = 90
	var queued_errors: Array = []
	manual_board.sync_failed.connect(func(): queued_errors.append(true))
	manual_transport.delay_frames["/rest/v1/rpc/leaderboard_sync_dev"] = 4
	manual_transport.replies = [{"status":503}, fixtures.reply(90, false)]
	manual_board.sync_stars(90)
	manual_board._flush()
	manual_board.profile = {"nickname":"ManualProfile", "character_id":2, "frame_id":5}
	var outcomes: Array = []
	collect_profile_result(manual_board, outcomes)
	await settle(manual_transport, manual_board)
	await get_tree().process_frame
	check(outcomes == [true] and manual_transport.calls.size() == 2 and queued_errors.is_empty(), "Manual profile queued behind a failed background request runs immediately without advancing the retry clock")
	check(manual_transport.max_active_calls == 1 and manual_board._synced_profile == manual_board.profile, "Manual profile shares the worker and acknowledges its own target without parallel duplicate RPCs")
	check(!manual_board._user_request_pending, "Completed manual action leaves no cooldown bypass for later background work")
	manual_board.queue_free()
	manual_transport.queue_free()
	for item: Node in [board, restored, restarted, legacy, node, fixtures]:
		item.queue_free()
	await get_tree().process_frame
	print("NETWORK_RETRIES checks=%d failures=%d" % [checks, failures])
	get_tree().quit(1 if failures else 0)

func collect_profile_result(board: Node, outcomes: Array) -> void:
	outcomes.append(await board.sync_profile_and_wait())
