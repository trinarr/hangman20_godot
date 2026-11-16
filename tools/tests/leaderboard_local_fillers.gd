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
	check(fillers(client).size() == 100, "A low-scoring real participant cannot displace a stronger filler")
	check(client.cached_snapshot().top[0].is_filler and client.cached_snapshot().me.rank == null and client.cached_snapshot().me.top_percent == 100, "Own player outside mixed top displays 100+")
	check(!client.cached_snapshot().top.any(func(row: Dictionary): return row.is_me), "Low-scoring own player is absent from the visible top")
	var acknowledgement := reply(1, false, 20)
	acknowledgement.body.erase("top")
	transport.replies = [acknowledgement]
	client.sync_stars(20)
	client._flush()
	await settle(client)
	check(client.cached_snapshot().me.rank == null and client.cached_snapshot().me.stars == 20, "Background acknowledgement keeps mixed outside-top position with fresh stars")
	acknowledgement = reply(1, false, 90)
	acknowledgement.body.erase("top")
	transport.replies = [acknowledgement]
	client.sync_stars(90)
	client._flush()
	await settle(client)
	check(client.cached_snapshot().me.rank == null and client.cached_snapshot().me.stars == 90, "Later acknowledgement cannot move an existing own row ahead of the cached standings")
	await load_reply(client, transport, reply(1, false, 90))
	for row: Dictionary in fillers(client):
		check(initial[row.player_id] == row.stars, "Real score updates never change retained filler stars")
	var own: Dictionary = client.cached_snapshot().top.filter(func(row): return row.is_me)[0]
	check(client.cached_snapshot().me.rank == own.rank and own.stars == 90, "Own position matches the merged list after score growth")
	await load_reply(client, transport, reply(40))
	check(fillers(client).size() == 61 and client.cached_snapshot().top.size() == 100 and client.cached_snapshot().me.rank == null, "Only real scores that beat fillers enter the mixed top")
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
	transport.advance_retry()
	await load_reply(client, transport, reply(99))
	check(fillers(client).size() == 2 and fillers(client)[0].stars == 100, "99 real participants can retain two stronger fillers")
	await load_reply(client, transport, reply(100))
	check(fillers(client).size() == 1 and client.cached_snapshot().me.rank == null, "Population 100 alone does not retire a stronger filler")
	await load_reply(client, transport, reply(100, false, 100))
	check(fillers(client).is_empty() and client.cached_snapshot().top.size() == 100 and client.cached_snapshot().me.rank == 100, "Real player wins a tied score and naturally retires the last filler")
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
	await inspect_legacy_cache(transport)
	await inspect_first_acknowledgement(transport)
	client.queue_free()
	transport.queue_free()
	await get_tree().process_frame
	print("LEADERBOARD_LOCAL_FILLERS checks=%d failures=%d" % [checks, failures])
	get_tree().quit(1 if failures else 0)

# An actual v1 file models the old client: 40 real rows and only 60 fillers.
func inspect_legacy_cache(transport: Node) -> void:
	var legacy := CLIENT.new()
	legacy.transport = transport
	var boards: Dictionary = {}
	for language: String in ["ru", "en"]:
		var body: Dictionary = reply(40, true, 10, language).body
		boards[language] = {"initialized":true, "real_top":body.top, "fillers":body.fillers.slice(0, 60), "me":body.me, "total_players":40}
	var file := FileAccess.open(legacy.save_file, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version":1,"owner_id":"local-owner","boards":boards,"confirmed_stars":90,"synced_profile":legacy.profile}))
	file.close()
	var path: String = legacy.save_file
	add_child(legacy)
	for language: String in ["ru", "en"]:
		legacy.language = language
		var cached: Dictionary = legacy.cached_snapshot()
		check(cached.top.size() == 100 and fillers(legacy).size() == 60 and cached.me.rank == 100, "Upgrade reads old shortened roster offline without restoring retired fillers: " + language)
		check(legacy._confirmed_stars == 90 and legacy._synced_profile == legacy.profile, "Upgrade preserves score and profile acknowledgements: " + language)
	for language: String in ["ru", "en"]:
		legacy.language = language
		# Add a second low-scoring real participant to the actual response.
		var response := reply(40, false, 10, language)
		response.body.top.append({"player_id":"new-low","nickname":"NewLow","stars":5,"rank":41,"is_me":false,"is_filler":false})
		response.body.total_players = 41
		await load_reply(legacy, transport, response)
		check(!transport.calls.back().payload.p_seed_fillers and fillers(legacy).size() == 60 and legacy.cached_snapshot().me.rank == 100, "New weak participant does not force old filler retirement after upgrade: " + language)
		check(!legacy.cached_snapshot().top.any(func(row: Dictionary): return row.player_id == "new-low"), "Weak newcomer remains outside mixed top: " + language)
	legacy.queue_free()
	await get_tree().process_frame
	var reloaded := CLIENT.new()
	reloaded.transport = transport
	reloaded.save_file = path
	add_child(reloaded)
	for language: String in ["ru", "en"]:
		reloaded.language = language
		check(fillers(reloaded).size() == 60 and reloaded.cached_snapshot().me.rank == 100, "Restart preserves upgraded cache in each language: " + language)
	reloaded.queue_free()
	await get_tree().process_frame

func inspect_first_acknowledgement(transport: Node) -> void:
	# 30 ties the weakest filler; 70 lies inside the table; 100 ties its leaders.
	var scores := [10, 30, 70, 100, 150]
	var ranks := [null, 100, 44, 1, 1]
	for language: String in ["ru", "en"]:
		for index in range(scores.size()):
			var client := CLIENT.new()
			client.transport = transport
			client.language = language
			add_child(client)
			await load_reply(client, transport, reply(0, true, 10, language))
			check(client.cached_snapshot().me == null, "First score regression starts without a cached own row")
			var acknowledgement := reply(1, false, scores[index], language)
			acknowledgement.body.erase("top")
			transport.replies = [acknowledgement]
			client.sync_stars(scores[index])
			client._flush()
			await settle(client)
			var cached: Dictionary = client.cached_snapshot()
			check(!transport.calls.back().payload.p_include_top and cached.me.rank == ranks[index] and cached.me.stars == scores[index], "First acknowledgement maps server place through cached fillers before standings: %s/%d" % [language, scores[index]])
			check(cached.me.top_percent == (100 if ranks[index] == null else null) and fillers(client).size() == 100, "First acknowledgement preserves roster and outside-top marker")
			check(client.cached_snapshot() == cached, "Repeated cache reads do not apply filler offsets twice")
			await load_reply(client, transport, reply(1, false, scores[index], language))
			check(client.cached_snapshot().me.rank == ranks[index], "Full standings agree with first acknowledgement at ties and top boundary")
			var path: String = client.save_file
			client.queue_free()
			await get_tree().process_frame
			var reloaded := CLIENT.new()
			reloaded.transport = transport
			reloaded.save_file = path
			reloaded.language = language
			add_child(reloaded)
			check(reloaded.cached_snapshot().me.rank == ranks[index] and reloaded.cached_snapshot().me.stars == scores[index], "Restart preserves mixed place after first standings")
			reloaded.queue_free()
			await get_tree().process_frame
