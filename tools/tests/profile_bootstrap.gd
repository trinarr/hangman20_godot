extends Node
const CLIENT = preload("res://tools/tests/leaderboard_client_mock.gd")
const TRANSPORT = preload("res://tools/tests/leaderboard_transport_mock.gd")
const ENVIRONMENT = preload("res://tools/tests/quiz_environment_mock.gd")
const HELPERS = preload("res://tools/tests/leaderboard.gd")
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if !value:
		failures += 1
		push_error(message)

func _ready() -> void:
	run.call_deferred()

func reset_automatic_name(value: String) -> void:
	GameState.player_name = value
	GameState.player_name_base = value
	GameState.player_name_server_id = ""
	GameState.player_name_is_custom = false
	GameState.settings[5] = 1
	GameState.player_frame_id = 3
	check(GameState.save_game(), "Automatic nickname fixture saved")

func settle(client: Node, transport: Node) -> void:
	for frame in range(200):
		await get_tree().process_frame
		if !client._busy and !transport._busy:
			return
	check(false, "Profile synchronization finishes")

func run() -> void:
	var initial_name := GameState.player_name
	check(GameState.PLAYER_PROFILE.valid_name(initial_name) and GameState.player_name_base == initial_name and !GameState.player_name_is_custom, "First startup generates an automatic valid nickname")
	check(GameState.settings[5] == 1 and GameState.player_frame_id == 3, "New player starts with Lucky and blue frame")
	check(!GameState.ensure_initial_player_profile() and GameState.player_name == initial_name, "Repeated initialization never rerolls the nickname")
	GameState.load_game()
	check(GameState.player_name == initial_name and GameState.player_name_base == initial_name and !GameState.player_name_is_custom, "Generated nickname and ownership survive reload")
	var migrated := GameState._migrate_save_payload({"save_version":4,"player_name":"OldChoice","player_frame_id":5,"settings":[1,1,1,1,1,2]})
	check(migrated.save_version == GameState.SAVE_FORMAT_VERSION and migrated.player_name_is_custom and migrated.player_frame_id == 5 and migrated.settings[5] == 2, "Migration protects previously saved names and appearance")
	GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
	GameState.guided_onboarding_completed = false
	var environment: Node = ENVIRONMENT.new()
	var blocked_env := OS.get_environment("HANGMAN_SUPABASE_NETWORK_DISABLED")
	OS.set_environment("HANGMAN_SUPABASE_NETWORK_DISABLED", "")
	check(!environment.is_configured() and !environment.leaderboard_is_configured(), "Both real services remain disabled before tutorial")
	for path: String in ["/auth/v1/signup", "/auth/v1/token?grant_type=refresh_token", environment._rpc_path(), environment._leaderboard_rpc_path()]:
		check((await environment._post(path, {}, true)).is_empty() and environment.get_child_count() == 0, "Pre-tutorial transport creates no HTTPRequest: " + path)
	check(!(await environment._authenticate()) and environment.get_child_count() == 0, "Pre-tutorial authentication cannot start")
	OS.set_environment("HANGMAN_SUPABASE_NETWORK_DISABLED", blocked_env)
	environment.free()
	check(!GameState.apply_server_player_id("123"), "An early server ID cannot rename a player before tutorial")
	var transport: Node = TRANSPORT.new()
	add_child(transport)
	transport._access_token = "test-access"
	var client: Node = CLIENT.new()
	client.transport = transport
	client.use_game_profile = true
	client.tutorial_completed = false
	add_child(client)
	client.sync_profile()
	client.sync_stars(90)
	client.refresh(true)
	client._tick()
	client._flush()
	check(transport.calls.is_empty() and !client._started and client.cached_snapshot().is_empty() and client.get_player_id().is_empty(), "No results, reads or uploads before tutorial")
	GameState._save_write_in_progress = true
	check(!GameState.complete_single_player_guided_onboarding() and !GameState.guided_onboarding_completed, "Failed completion save keeps the online gate closed")
	GameState._save_write_in_progress = false
	check(GameState.complete_single_player_guided_onboarding() and GameState.can_use_online_services(), "Saved tutorial completion opens the online gate")
	var helpers: Node = HELPERS.new()
	transport.replies = [helpers.reply(90), helpers.reply(90)]
	client.tutorial_completed = true
	client._tick()
	await settle(client, transport)
	check(GameState.player_name == initial_name + "123" and GameState.player_name_server_id == "123", "First numeric server ID is appended to the original automatic name")
	check(transport.calls.size() == 2 and transport.calls[0].payload.p_nickname == initial_name and transport.calls[1].payload.p_nickname == initial_name + "123", "New automatic name is uploaded after receiving the ID")
	check(!GameState.apply_server_player_id("123") and GameState.player_name == initial_name + "123", "Repeated replies never duplicate the suffix")
	GameState.load_game()
	check(GameState.player_name == initial_name + "123" and !GameState.player_name_is_custom, "Automatic suffix survives restart")
	reset_automatic_name("МойКот")
	transport.replies = [helpers.reply(90), helpers.reply(90)]
	client.sync_profile()
	client._flush()
	check(GameState.update_player_profile("MyChoice", 2, 5), "Manual nickname is saved while request is in flight")
	await settle(client, transport)
	check(GameState.player_name == "MyChoice" and GameState.player_name_is_custom and transport.calls.back().payload.p_nickname == "MyChoice", "Late reply preserves a manually changed nickname")
	GameState.load_game()
	check(GameState.player_name_is_custom and !GameState.apply_server_player_id("456") and GameState.player_name == "MyChoice", "Manual ownership remains protected after restart")
	reset_automatic_name("МойЛис")
	check(GameState.update_player_profile("МойЛис", 2, 5, false), "Appearance-only changes save without claiming the nickname")
	check(GameState.apply_server_player_id("321") and GameState.player_name == "МойЛис321" and GameState.settings[5] == 2 and GameState.player_frame_id == 5, "Appearance changes do not prevent automatic suffixing")
	reset_automatic_name("МойЁж")
	GameState._save_write_in_progress = true
	check(!GameState.apply_server_player_id("77") and GameState.player_name == "МойЁж" and GameState.player_name_server_id.is_empty(), "Failed suffix save rolls back name and ID")
	GameState._save_write_in_progress = false
	check(GameState.apply_server_player_id("77") and GameState.player_name == "МойЁж77", "Suffix save can be retried")
	check(GameState.apply_server_player_id("88") and GameState.player_name == "МойЁж88", "A replacement account ID replaces the old automatic suffix")
	helpers.free()
	client.queue_free()
	transport.queue_free()
	await get_tree().process_frame
	print("PROFILE_BOOTSTRAP checks=%d failures=%d" % [checks, failures])
	get_tree().quit(1 if failures else 0)
