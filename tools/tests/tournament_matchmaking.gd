extends Node
const MATCH = preload("res://scripts/services/tournament_matchmaking.gd")
const MODEL = preload("res://scripts/core/tournament_model.gd")
const DESIGN = preload("res://scripts/core/game_design_config.gd")
const ENVIRONMENT = preload("res://tools/tests/quiz_environment_mock.gd")
var checks := 0
var failures := 0

class Transport extends "res://tools/tests/leaderboard_transport_mock.gd":
	var configured := true
	func leaderboard_is_configured() -> bool:
		return configured

class Cache extends Node:
	var profiles: Array = []
	func get_player_id() -> String:
		return "999"
	func tournament_profiles() -> Array:
		return profiles.duplicate(true)

class DelayedService extends Node:
	var requests := 0
	var selection: Dictionary = {}
	func request_tournament_profiles() -> Dictionary:
		requests += 1
		for frame in range(10):
			await get_tree().process_frame
		return selection

class DelayedPage extends "res://scripts/ui/portrait_tournament.gd":
	var service: Node
	func _matchmaking_service() -> Node:
		return service

func check(value: bool, message: String) -> void:
	checks += 1
	if !value:
		failures += 1
		push_error(message)

func settle() -> void:
	for frame in range(20):
		await get_tree().process_frame

func profiles(count: int) -> Array:
	var result: Array = []
	for index in range(count):
		result.append({"player_id":str(index + 1), "nickname":"Real%d" % index,
			"character_id":2, "frame_id":5, "is_me":false, "is_filler":false})
	return result

func reply(count: int) -> Dictionary:
	return {"status":200, "body":{"ok":true, "protocol_version":1, "profiles":profiles(count)}}

func real_count(pool: Array) -> int:
	var count := 0
	for entry: Dictionary in pool:
		if entry.is_real:
			count += 1
	return count

func pool(selection: Dictionary) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 123
	return MODEL.ROSTER.build_pool("ru", DESIGN.get_value("tournament"), selection.profiles, rng, selection.from_cache)

func collect(transport: Node, cache: Node, sink: Array) -> void:
	sink.append(await MATCH.fetch(transport, cache, "ru"))

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	GameState.guided_onboarding_completed = true
	GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
	var environment := ENVIRONMENT.new()
	check(environment._tournament_rpc_path().ends_with("tournament_profiles_dev") and !environment._path_allowed("/rest/v1/rpc/tournament_profiles"), "Debug tournament RPC cannot reach production")
	environment.dev = false
	check(environment._tournament_rpc_path().ends_with("tournament_profiles") and !environment._path_allowed("/rest/v1/rpc/tournament_profiles_dev"), "Production tournament RPC cannot reach dev")
	check((await environment.tournament_rpc({})).is_empty() and environment.get_child_count() == 0, "Network-disabled tournament path creates no HTTPRequest")
	environment.free()
	var transport := Transport.new()
	add_child(transport)
	transport._access_token = "access"
	transport._state.refresh_token = "refresh"
	transport.retry_clock_ms = 1000
	var cache := Cache.new()
	add_child(cache)
	cache.profiles = profiles(80)
	for count in [0, 12, 49, 50]:
		transport.replies = [reply(count)]
		var selection: Dictionary = await MATCH.fetch(transport, cache, "ru")
		check(!selection.from_cache and selection.profiles.size() == count, "Successful server sampling is used even when empty or incomplete")
		var candidates := pool(selection)
		check(candidates.size() == 50 and real_count(candidates) == count, "Server pool can contain fifty real profiles; only missing slots are synthetic")
		check(transport.calls.back().path == transport._tournament_rpc_path() and transport.calls.back().payload == {"p_language":"ru"}, "Each sampling uses a separate authenticated tournament RPC")
	var malformed: Array = [{}, {"status":503}, {"status":404}, {"status":429}, {"status":200,"body":{}}, reply(51)]
	var duplicate := reply(2)
	duplicate.body.profiles[1] = duplicate.body.profiles[0].duplicate(true)
	malformed.append(duplicate)
	var own := reply(1)
	own.body.profiles[0].player_id = "999"
	malformed.append(own)
	var invalid := reply(1)
	invalid.body.profiles[0].frame_id = 6
	malformed.append(invalid)
	var filler := reply(1)
	filler.body.profiles[0].is_filler = true
	malformed.append(filler)
	for failure: Dictionary in malformed:
		transport.advance_retry()
		transport.replies = [failure]
		var selection: Dictionary = await MATCH.fetch(transport, cache, "ru")
		var candidates := pool(selection)
		check(selection.from_cache and candidates.size() == 50 and real_count(candidates) == 25, "Transport, missing RPC and malformed responses fall back to at least twenty-five synthetic entries")
		check(transport.retry_delay_ms("tournament") > 0 and transport.retry_delay_ms("leaderboard") == 0 and transport.retry_delay_ms("quiz") == 0, "Tournament failures have an independent backoff lane")
	var calls := transport.calls.size()
	var deferred: Dictionary = await MATCH.fetch(transport, cache, "ru")
	check(deferred.from_cache and transport.calls.size() == calls, "Cooldown falls back immediately without another server request")
	transport.configured = false
	for count in [0, 12, 80]:
		cache.profiles = profiles(count)
		var selection: Dictionary = await MATCH.fetch(transport, cache, "en")
		check(selection.from_cache and real_count(pool(selection)) == mini(25, count), "Offline selection respects the filler floor for empty, small and large caches")
	check(transport.calls.size() == calls, "Offline fallback makes no HTTP calls")
	for language: String in ["ru", "en"]:
		var rng := RandomNumberGenerator.new()
		rng.seed = 123
		var fallback_pool := MODEL.ROSTER.build_pool(language, DESIGN.get_value("tournament"), profiles(80), rng, true)
		var cis := 0
		for entry: Dictionary in fallback_pool:
			if !entry.is_real and entry.nickname in MODEL.NAMES.CIS:
				cis += 1
		check(cis == (15 if language == "ru" else 5), "The twenty-five fallback fillers preserve the selected locale distribution")
	transport.configured = true
	transport.advance_retry()
	transport.replies = [{"status":401}, {"status":200,"body":{"access_token":"new","refresh_token":"new-refresh","expires_in":3600}}, reply(50)]
	var refreshed: Dictionary = await MATCH.fetch(transport, cache, "en")
	check(!refreshed.from_cache and transport.calls.size() == calls + 3 and transport._retry_state("tournament").failures == 0, "One 401 refreshes authentication immediately, repeats sampling and resets backoff")
	# A late old-account response cannot be used for the replacement account.
	cache.profiles = profiles(80)
	transport.delay_frames[transport._tournament_rpc_path()] = 5
	transport.replies = [reply(50)]
	var received: Array = []
	collect(transport, cache, received)
	await get_tree().process_frame
	transport._identity_generation += 1
	cache.profiles.clear()
	await settle()
	check(received.size() == 1 and received[0].from_cache and received[0].profiles.is_empty(), "Identity replacement discards stale server data and reads the current fallback cache")
	# Closing or repeatedly pressing Join while HTTP waits cannot start a hidden tournament.
	GameState.single_player = {}
	GameState._single_player_bucket("ru")["theme_unlock_completed_levels"] = 5
	GameState.tournament_state = {}
	var canceled_service := DelayedService.new()
	canceled_service.selection = {"profiles":profiles(50), "from_cache":false}
	add_child(canceled_service)
	var canceled := DelayedPage.new()
	canceled.service = canceled_service
	add_child(canceled)
	canceled._action()
	canceled._action()
	canceled.refresh()
	check(canceled_service.requests == 1 and canceled._joining and canceled._button.disabled, "Join is disabled across timer refreshes while one request is pending")
	canceled.dispose()
	canceled.queue_free()
	await settle()
	check(GameState.tournament_state.is_empty(), "Closing before the sampling response never starts a tournament")
	canceled_service.queue_free()
	var service := DelayedService.new()
	service.selection = {"profiles":profiles(50), "from_cache":false}
	add_child(service)
	var page := DelayedPage.new()
	page.service = service
	add_child(page)
	page._action()
	page._action()
	await settle()
	check(service.requests == 1 and !page._joining and GameState.tournament_state.opponents.size() == 9, "One successful request starts exactly one tournament")
	check(real_count(GameState.tournament_state.opponents) == 9, "Server profiles reach the durable tournament without the cache filler cap")
	page.dispose()
	page.queue_free()
	service.queue_free()
	cache.queue_free()
	transport.queue_free()
	await settle()
	print("TOURNAMENT_MATCHMAKING checks=%d failures=%d" % [checks, failures])
	get_tree().quit(1 if failures else 0)
