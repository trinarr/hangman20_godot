extends Node
const CLIENT = preload("res://tools/tests/leaderboard_client_mock.gd")
const TRANSPORT = preload("res://tools/tests/leaderboard_transport_mock.gd")
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if !value:
		failures += 1
		push_error(message)

func _ready() -> void:
	run.call_deferred()

func reply(count: int, seed: bool = false, own_stars: int = 10, language: String = "ru", owner: String = "local-owner") -> Dictionary:
	var body := {"ok":true,"protocol_version":2,"owner_id":owner,"language":language,"total_players":count,"me":null,"top":[]}
	for i: int in range(count):
		var own := i == count - 1
		var row := {"player_id":"me" if own else "real:%d" % i,"nickname":"Player %d" % i,"stars":own_stars if own else 200-i,"rank":i+1,"is_me":own,"is_filler":false}
		body.top.append(row)
		if own:
			body.me = row.duplicate(true)
			body.me["top_percent"] = null
	if seed:
		body["fillers"] = []
		if count < 100:
			for i: int in range(100):
				var pool := "cis" if i < (60 if language == "ru" else 20) else "us_europe"
				body.fillers.append({"player_id":"filler:%s:%03d" % [pool,i],"nickname":"Filler %d" % i,"stars":100-int(floor(70.0*i/99.0)),"rank":i+1,"is_me":false,"is_filler":true})
	return {"status":200,"body":body}

func settle(client: Node) -> void:
	for i: int in range(100):
		await get_tree().process_frame
		if !client._busy:
			return
	check(false, "Worker finishes bounded requests")

func fillers(client: Node) -> Array:
	return client.cached_snapshot().top.filter(func(row): return row.is_filler)

func load_reply(client: Node, transport: Node, response: Dictionary) -> void:
	transport.replies = [response]
	client.refresh(true)
	await settle(client)

func run() -> void:
	var transport := TRANSPORT.new()
	add_child(transport)
	transport._access_token = "test-access"
	var client := CLIENT.new()
	client.transport = transport
	add_child(client)
	var dev_path: String = client.environment_save_path()
	transport.dev = false
	check(dev_path != client.environment_save_path(), "Dev and production cannot share a roster file")
	transport.dev = true
	await load_reply(client, transport, reply(0, true))
	check(transport.calls.back().payload.p_seed_fillers, "First read requests initial roster")
	check(fillers(client).size() == 100 and client.cached_snapshot().me == null, "Empty real board starts with 100 positive fillers")
	var initial: Dictionary = {}
	for row: Dictionary in fillers(client):
		initial[row.player_id] = row.stars
		check(row.character_id in [1, 2] and row.frame_id >= 1 and row.frame_id <= 5, "Legacy fillers receive stable valid appearance without reseeding")
	await load_reply(client, transport, reply(1))
	check(!transport.calls.back().payload.p_seed_fillers, "Later reads request only real leaders")
	check(fillers(client).size() == 99, "A low-scoring real participant displaces one filler")
	check(client.cached_snapshot().top[0].is_filler and client.cached_snapshot().me.rank == 100, "Fillers can outrank the player and own card uses displayed rank")
	await load_reply(client, transport, reply(1, false, 90))
	for row: Dictionary in fillers(client):
		check(initial[row.player_id] == row.stars, "Real score updates never change retained filler stars")
	var own: Dictionary = client.cached_snapshot().top.filter(func(row): return row.is_me)[0]
	check(client.cached_snapshot().me.rank == own.rank and own.stars == 90, "Own position matches the merged list after score growth")
	await load_reply(client, transport, reply(40))
	check(fillers(client).size() == 60 and client.cached_snapshot().top.size() == 100, "Every real player is admitted; only best 60 fillers remain")
	var saved_fillers: Array = fillers(client)
	var saved_path: String = client.save_file
	client.queue_free()
	await get_tree().process_frame
	client = CLIENT.new()
	client.transport = transport
	client.save_file = saved_path
	add_child(client)
	check(fillers(client) == saved_fillers, "Restart restores the exact active roster and fixed stars")
	await load_reply(client, transport, reply(40))
	check(!transport.calls.back().payload.p_seed_fillers and fillers(client) == saved_fillers, "Restart downloads real leaders without requesting another seed")
	await load_reply(client, transport, {"status":503,"body":{}})
	check(fillers(client) == saved_fillers, "Network failure keeps the persisted roster")
	await load_reply(client, transport, reply(99))
	check(fillers(client).size() == 1 and fillers(client)[0].stars == 100, "At 99 real players only the strongest filler remains")
	await load_reply(client, transport, reply(100))
	check(fillers(client).is_empty() and client.cached_snapshot().top.size() == 100, "100 real players completely replace fillers")
	await load_reply(client, transport, reply(99))
	check(fillers(client).is_empty(), "Displaced fillers never return")
	client.language = "en"
	await load_reply(client, transport, reply(0, true, 10, "en"))
	check(transport.calls.back().payload.p_seed_fillers and fillers(client).size() == 100, "New locale gets its own persisted initial roster")
	check(fillers(client).filter(func(row): return row.player_id.begins_with("filler:cis:")).size() == 20, "English roster preserves the 20/80 mix")
	client.language = "ru"
	check(fillers(client).is_empty(), "Switching back restores the retired Russian roster")
	var calls: int = transport.calls.size()
	transport.replies = [reply(0, false, 10, "ru", "new-owner"), reply(0, true, 10, "ru", "new-owner")]
	client.refresh(true)
	await settle(client)
	check(transport.calls.size() == calls+2 and transport.calls.back().payload.p_seed_fillers, "Identity changed inside RPC triggers bootstrap for the new owner")
	check(fillers(client).size() == 100, "New identity does not inherit an exhausted previous roster")
	var broken := reply(0, true)
	broken.body.fillers[1].player_id = broken.body.fillers[0].player_id
	check(!client._valid_snapshot(broken.body, true), "Duplicate initial filler IDs are rejected")
	broken = reply(0, true)
	broken.body.fillers.pop_back()
	check(!client._valid_snapshot(broken.body, true), "Partial initial seed is rejected")
	# First contact with an already populated leaderboard never installs fillers.
	var fresh := CLIENT.new()
	fresh.transport = transport
	add_child(fresh)
	await load_reply(fresh, transport, reply(100, true))
	check(fillers(fresh).is_empty() and fresh.cached_snapshot().top.size() == 100, "First read with 100 real participants skips fake players")
	fresh.queue_free()
	client.queue_free()
	transport.queue_free()
	await get_tree().process_frame
	print("LEADERBOARD_LOCAL_FILLERS checks=%d failures=%d" % [checks, failures])
	get_tree().quit(1 if failures else 0)
