extends Node
const MOCK = preload("res://tools/tests/leaderboard_transport_mock.gd")
const CLIENT = preload("res://tools/tests/leaderboard_client_mock.gd")
var checks := 0
var failures := 0
var last_read: Dictionary = {}

func check(value: bool, message: String) -> void:
	checks += 1
	if !value:
		failures += 1
		push_error(message)

func _ready() -> void:
	run.call_deferred()

func service() -> Node:
	var node: Node = MOCK.new()
	add_child(node)
	node._access_token = "old-access"
	node._state.refresh_token = "old-refresh"
	return node

func settle(node: Node) -> void:
	for frame: int in range(300):
		await get_tree().process_frame
		if !node._busy and !node._auth_busy and node.active_calls == 0:
			await get_tree().process_frame
			if !node._busy and node.active_calls == 0:
				return
	check(false, "API worker settles")

func entries(count: int) -> Array:
	var result: Array = []
	for index: int in range(count):
		result.append({"p_key":"en:%d:%s" % [index + 1, "ab".repeat(32)], "p_answer":0})
	return result

func snapshot() -> Dictionary:
	return {"status":200,"body":{"ok":true,"counts":[1,0,0,0],"already_answered":true}}

func read_board(node: Node) -> void:
	last_read = await node.leaderboard_rpc({})

func batch(items: Array, failed_key: String = "") -> Dictionary:
	var results: Array = []
	for entry: Dictionary in items:
		var item := entry.duplicate(true)
		if entry.p_key == failed_key:
			item.merge({"ok":false,"code":"22023"})
		else:
			item.merge(snapshot().body)
		results.append(item)
	return {"status":200,"body":{"ok":true,"results":results}}

func tokens() -> Dictionary:
	return {"status":200,"body":{"access_token":"new-access","refresh_token":"new-refresh","expires_in":3600}}

func run() -> void:
	GameState.guided_onboarding_completed = true
	GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
	var node := service()
	node._state.pending = entries(45)
	node.route_replies[node._batch_rpc_path()] = [batch(node._state.pending.slice(0,20)),batch(node._state.pending.slice(20,40)),batch(node._state.pending.slice(40,45))]
	node._flush()
	await settle(node)
	check(node.calls.size() == 3 and node._state.pending.is_empty(), "45 queued votes use three bounded HTTP batches")
	check(node.calls[0].payload.p_answers.size() == 20 and node.calls[2].payload.p_answers.size() == 5, "Batch size never exceeds protocol limit")
	node.queue_free()
	node = service()
	node._state.pending = entries(2)
	var failed: String = node._state.pending[0].p_key
	node.replies = [batch(node._state.pending, failed)]
	node._flush()
	await settle(node)
	check(node._state.pending.size() == 1 and node._state.pending[0].p_key == failed, "Unknown catalog revision remains queued while valid batch items are acknowledged")
	check(node._cache.size() == 1, "Only valid batch item supplies statistics")
	node.queue_free()
	var malformed := batch(entries(2))
	malformed.body.results[1].p_key = "wrong-echo"
	for response: Dictionary in [{"status":503}, {"status":200,"body":{"ok":true,"results":[]}}, malformed]:
		node = service()
		node._state.pending = entries(2)
		node.replies = [response]
		node._flush()
		await settle(node)
		check(node._state.pending.size() == 2 and node._cache.is_empty(), "Failure or malformed batch cannot clear queue or partially publish statistics")
		node.queue_free()
	node = service()
	node._state.pending = entries(2)
	node.replies = [{"status":404,"body":{"code":"PGRST202"}},snapshot(),snapshot()]
	node._flush()
	await settle(node)
	check(node.calls.size() == 3 and node._state.pending.is_empty() and !node._batch_supported, "Server without batch RPC falls back to published single-answer API")
	node.queue_free()
	# A queued read becomes a real vote while the batch is in flight.
	node = service()
	node._state.pending = entries(2)
	node._state.pending[0].p_answer = -1
	node.replies = [batch(node._state.pending),snapshot()]
	node._flush()
	node._state.pending[0].p_answer = 1
	node._flush()
	await settle(node)
	check(node.calls.size() == 2 and node.calls[1].payload.p_answer == 1 and node._state.pending.is_empty(), "Batch read acknowledgement does not discard a newly queued vote")
	node.queue_free()
	# Simultaneous and delayed old 401s share one refresh.
	for delay: int in [1, 6]:
		node = service()
		node.route_replies = {node._rpc_path(): [{"status":401},snapshot()], node._leaderboard_rpc_path(): [{"status":401},{"status":200,"body":{"ok":true}}], "/auth/v1/token?grant_type=refresh_token": [tokens()]}
		node.delay_frames["/auth/v1/token?grant_type=refresh_token"] = 3
		node.delay_frames[node._leaderboard_rpc_path()] = delay
		node._state.pending = entries(1)
		node._flush()
		node.leaderboard_rpc({})
		await settle(node)
		var refreshes := 0
		for call: Dictionary in node.calls:
			if call.path.contains("refresh_token"):
				refreshes += 1
		check(refreshes == 1 and node._access_token == "new-access", "Parallel stale 401s cause one refresh and preserve the rotated JWT")
		check(node.max_active_calls >= 2 and node._state.pending.is_empty(), "Leaderboard and quiz HTTP overlap while acknowledgements stay independent")
		node.queue_free()
	# Identity replacement while an old vote is still returning 200.
	node = service()
	node._state.pending = entries(1)
	node.route_replies = {node._rpc_path(): [snapshot()], node._leaderboard_rpc_path(): [{"status":401},{"status":200,"body":{"ok":true}}], "/auth/v1/token?grant_type=refresh_token": [{"status":400,"body":{"error_code":"refresh_token_not_found"}}], "/auth/v1/signup": [tokens()]}
	node.delay_frames[node._rpc_path()] = 12
	node._flush()
	node.leaderboard_rpc({})
	for frame: int in range(60):
		if node._identity_generation == 1:
			break
		await get_tree().process_frame
	check(node._identity_generation == 1, "Other API lane can replace a revoked identity while a vote is in flight")
	# Retain a new-identity vote when its own subsequent request fails.
	node._state.pending = entries(1)
	node._state.pending[0].p_answer = 3
	node.route_replies[node._rpc_path()].append({"status":503})
	await settle(node)
	check(node._cache.is_empty() and node._state.pending.size() == 1 and node._state.pending[0].p_answer == 3, "Old identity's late success cannot acknowledge or cache a new identity's vote")
	node.queue_free()
	# Even two consecutive identity changes must not leak a stale read at the retry limit.
	node = service()
	node.route_replies[node._leaderboard_rpc_path()] = [{"status":200,"body":{"owner_id":"old"}}, {"status":200,"body":{"owner_id":"also-old"}}]
	node.delay_frames[node._leaderboard_rpc_path()] = 4
	read_board(node)
	node._reset_revoked_identity()
	node._access_token = "replacement-1"
	for frame: int in range(30):
		if node.calls.size() == 2:
			break
		await get_tree().process_frame
	node._reset_revoked_identity()
	node._access_token = "replacement-2"
	await settle(node)
	check(last_read.get("identity_reset") == true and !last_read.has("body"), "Retry limit never returns another identity's stale read")
	node.queue_free()
	# Public-profile acknowledgements survive restart and are scoped to an identity.
	node = service()
	var client: Node = CLIENT.new()
	client.transport = node
	add_child(client)
	client._owner_id = "saved-owner"
	client._synced_profile = client.profile.duplicate(true)
	client._save_store()
	var restored: Node = CLIENT.new()
	restored.transport = node
	restored.save_file = client.save_file
	add_child(restored)
	restored._ensure_store_loaded()
	restored.sync_profile()
	check(!restored._profile_pending and restored._synced_profile == restored.profile, "Restart restores profile acknowledgement without another upload")
	restored._on_identity_changed()
	check(restored._profile_pending and restored._synced_profile.is_empty(), "Replacement identity always queues its own initial profile")
	client.queue_free()
	restored.queue_free()
	node.queue_free()
	await get_tree().process_frame
	print("API_EFFICIENCY checks=%d failures=%d" % [checks, failures])
	get_tree().quit(1 if failures else 0)
