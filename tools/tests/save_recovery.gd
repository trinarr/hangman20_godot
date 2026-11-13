extends SceneTree
# Run only with an isolated user:// directory (tools/run_reward_tests.py).
var failures: Array[String] = []
var checks: int = 0
class SuffixSyncMock extends Node:
	var calls := 0
	var pending := false
	func sync_profile_and_wait() -> bool:
		calls += 1
		if calls == 1:
			get_node("/root/GameState").apply_server_player_id("17")
			pending = true
		else:
			pending = false
		return true
	func has_pending_profile_sync() -> bool:
		return pending

var state: Node

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if !value:
		failures.append(message)

func write_json(path: String, payload: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(payload))
	file.close()

func reset() -> void:
	state._save_blocked_by_future_version = false
	state.word_language = "ru"
	state.single_player = {}
	state.single_player_resume_states = {}
	state.active_single_player_session = {}
	state.pending_single_player_reward = {}
	state.rewarded_double_requests = {}
	state.soft_currency = 100
	state.stars = 10
	state.guided_onboarding_completed = true
	for path: String in [state.SAVE_PATH, state.SAVE_TMP_PATH, state.SAVE_BACKUP_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func cross_language_receipt(context: String) -> void:
	reset()
	if context == "final":
		state.pending_single_player_reward = state._normalize_pending_single_player_reward({
			"language":"ru", "level_index":4, "word_slot":2, "word_count":3,
			"amount":35, "claimed":true, "double_resolved":false,
		})
	else:
		state.set_active_single_player_session({
			"kind":"next", "language":"ru", "level_index":4, "word_slot":1,
			"theme_id":1, "data": {"reward_currency":"coins", "reward_amount":15,
				"reward_claimed":true, "reward_double_resolved":false},
		}, false)
	var request: String = state.begin_rewarded_double_request(context)
	check(!request.is_empty(), context + ": request created")
	state.set_word_language("en")
	var prior_states: Dictionary = state.single_player_resume_states.duplicate(true)
	state._save_blocked_by_future_version = true
	check(state.claim_rewarded_double_request(request).is_empty(), context + ": failed write returns no award")
	check(state.get_soft_currency() == 100, context + ": failed write restores balance")
	check(state.single_player_resume_states == prior_states, context + ": failed write restores inactive flags")
	check(state.rewarded_double_requests.has(request), context + ": failed write keeps receipt retryable")
	state._save_blocked_by_future_version = false
	var reward: Dictionary = state.claim_rewarded_double_request(request)
	check(int(reward.get("amount", 0)) > 0, context + ": late receipt paid")
	check(!bool(reward.get("is_current", true)), context + ": inactive UI stays inactive")
	check(state.get_active_single_player_session().is_empty(), context + ": English campaign unchanged")
	var credited: int = state.get_soft_currency()
	state.load_game()
	state.set_word_language("ru")
	check(bool(state._rewarded_double_target(context).get("granted", false)), context + ": inactive offer paid durably")
	check(state.begin_rewarded_double_request(context).is_empty(), context + ": no second x2 after returning")
	check(state.claim_rewarded_double_request(request).is_empty(), context + ": duplicate callback ignored")
	check(state.get_soft_currency() == credited, context + ": duplicate leaves balance unchanged")

func run() -> void:
	state = root.get_node("GameState")
	var arguments := OS.get_cmdline_user_args()
	if arguments.has("--restart-prepare"):
		prepare_restart()
		finish()
		return
	if arguments.has("--restart-verify"):
		verify_restart()
		finish()
		return
	if arguments.has("--restart-confirm"):
		check(state.get_soft_currency() == 160, "Second process restart preserves paid balance")
		check(bool(state._rewarded_double_target("final").get("granted", false)), "Second restart preserves paid offer")
		check(state.rewarded_double_requests.is_empty(), "Second restart preserves receipt compaction")
		check(state.begin_rewarded_double_request("final").is_empty(), "Second restart cannot create duplicate x2")
		finish()
		return
	cross_language_receipt("final")
	cross_language_receipt("stage_coin")
	reset()
	var current_payload: Dictionary = {"save_version": state.SAVE_FORMAT_VERSION, "soft_currency": 321}
	var migrated_profile: Dictionary = state._migrate_save_payload({"save_version":3, "player_name":"OldPlayer", "settings":[1,1,1,1,1,2], "stars":73})
	check(migrated_profile.save_version == state.SAVE_FORMAT_VERSION and migrated_profile.player_frame_id == 4 and migrated_profile.settings[5] == 2 and migrated_profile.stars == 73, "Profile migration preserves character and progress and defaults to the orange frame")
	var model = preload("res://scripts/core/tournament_model.gd")
	var old_tournament: Dictionary = model.create(1800000000, "ru", state.GAME_DESIGN.get_value("tournament"), 123)
	old_tournament.version = 1
	for opponent: Dictionary in old_tournament.opponents:
		for field: String in ["profile_id", "character_id", "frame_id", "is_real"]:
			opponent.erase(field)
	var old_schedule := JSON.stringify(old_tournament.opponents)
	var migrated_tournament: Dictionary = state._migrate_save_payload({"save_version":5, "tournament":old_tournament, "stars":73})
	check(migrated_tournament.save_version == state.SAVE_FORMAT_VERSION and migrated_tournament.tournament.version == 2 and migrated_tournament.stars == 73, "Save migration preserves progress and upgrades tournament profiles")
	check(migrated_tournament.tournament.opponents[0].events == old_tournament.opponents[0].events and JSON.stringify(old_tournament.opponents) == old_schedule, "Save migration preserves the frozen tournament and source payload")
	for custom: bool in [false, true]:
		var migrated_name: Dictionary = state._migrate_save_payload({"save_version":6, "player_name_is_custom":custom, "soft_currency":123})
		check(migrated_name.save_version == state.SAVE_FORMAT_VERSION and migrated_name.player_name_free_change_used == custom and migrated_name.soft_currency == 123, "Migration records whether an existing player already chose a manual nickname")
	var legacy_rewards: Dictionary = {"save_version":7, "soft_currency":123, "single_player":{"ru":{"levels":{"1":[1, 0]}}}}
	var migrated_rewards: Dictionary = state._migrate_save_payload(legacy_rewards)
	check(migrated_rewards.save_version == state.SAVE_FORMAT_VERSION and migrated_rewards.soft_currency == 123 and migrated_rewards.single_player.ru.stage_coin_rewards.is_empty(), "Stage-credit migration preserves balance and initializes an empty history")
	check(migrated_rewards.single_player.ru.levels == legacy_rewards.single_player.ru.levels and !legacy_rewards.single_player.ru.has("stage_coin_rewards"), "Stage-credit migration preserves progress and leaves the legacy source unchanged")
	state.player_name = "Original"
	state.player_name_free_change_used = false
	state.soft_currency = 0
	check(state.save_game(), "Free nickname fixture is durable")
	check(state.update_player_profile("Original", 2, 3, false) and !state.player_name_free_change_used, "Appearance-only changes do not consume the free nickname change")
	state._save_blocked_by_future_version = true
	check(!state.update_player_profile("First name", 1, 1) and !state.player_name_free_change_used and state.player_name == "Original", "Failed free rename restores the free entitlement and nickname")
	state._save_blocked_by_future_version = false
	var free_profile: Dictionary = state.capture_player_profile_state()
	check(state.update_player_profile("First name", 1, 1) and state.player_name_free_change_used and state.soft_currency == 0, "First actual nickname change is free with zero coins")
	state.restore_player_profile_state(free_profile, 0)
	state.load_game()
	check(state.player_name == "Original" and !state.player_name_free_change_used and state.player_name_is_custom == bool(free_profile.custom), "Rejected free rename restores durable identity and free entitlement")
	check(state.update_player_profile("First name", 1, 1), "Free rename can be retried after rollback")
	var rename_cost: int = state.GAME_DESIGN.get_int("economy.profile_name_change_cost")
	check(state.get_player_name_change_cost("Second name") == rename_cost and state.get_player_name_change_cost("First name") == 0, "Only a different nickname has the configured repeat price")
	var before_paid: Dictionary = state.get_player_profile()
	check(!state.update_player_profile("Second name", 2, 4) and state.get_player_profile() == before_paid and state.soft_currency == 0, "Insufficient coins preserve nickname and appearance")
	state.add_soft_currency(rename_cost)
	state._save_write_in_progress = true
	check(!state.update_player_profile("Second name", 2, 4) and state.get_player_profile() == before_paid and state.soft_currency == rename_cost and state.player_name_free_change_used, "Failed paid write rolls back both profile and coins")
	state._save_write_in_progress = false
	check(state.update_player_profile("Second name", 2, 4, false) and state.soft_currency == 0, "Paid rename debits exactly the price even if the caller clears nickname_changed")
	check(state.update_player_profile("Second name", 2, 4) and state.soft_currency == 0, "Repeated identical save cannot charge twice")
	state.player_name_free_change_used = false
	state.load_game()
	check(state.player_name == "Second name" and state.player_name_free_change_used and state.soft_currency == 0, "Paid nickname and free entitlement survive reload together with the balance")
	state.soft_currency = rename_cost * 3
	check(state.update_player_profile("NewPlayer", 2, 3), "Profile commits through durable save")
	state.player_name = ""
	state.player_frame_id = 4
	state.settings[5] = 1
	state.load_game()
	check(state.player_name == "NewPlayer" and state.player_frame_id == 3 and state.settings[5] == 2, "Profile survives a save reload")
	var original_profile: Dictionary = state.get_player_profile()
	state._save_blocked_by_future_version = true
	check(!state.update_player_profile("OtherPlayer", 1, 1) and state.get_player_profile() == original_profile, "Failed profile write rolls back all three fields")
	state._save_blocked_by_future_version = false
	check(!state.update_player_profile("A", 1, 1) and !state.update_player_profile("Player", 3, 1) and !state.update_player_profile("Player", 1, 0), "Profile rejects invalid name and appearance IDs")
	var v8: Dictionary = state._migrate_save_payload({"save_version": 8, "player_name": "BeforeCrash", "soft_currency": 125})
	check(v8.save_version == 9 and v8.pending_profile_update.is_empty() and v8.soft_currency == 125, "Migration 8 to 9 adds an empty profile transaction without changing balance")
	var transaction_profile: Dictionary = state.capture_player_profile_state()
	var transaction_balance: int = state.soft_currency
	var transaction_id: String = state.begin_player_profile_update("Pending name", 1, 1)
	check(!transaction_id.is_empty() and !state._read_save_dictionary(state.SAVE_PATH).get("pending_profile_update", {}).is_empty(), "Profile mutation and rollback checkpoint are durable in one save")
	check(!state.update_player_profile("External", 2, 2), "An external profile update cannot overwrite an in-flight transaction")
	state.cancel_player_profile_update(transaction_id)
	check(state.get_player_profile().nickname == transaction_profile.nickname and state.soft_currency == transaction_balance, "Cancellation restores identity and refunds exactly once")
	var newer_id: String = state.begin_player_profile_update("Newer name", 2, 2)
	check(!state.complete_player_profile_update(transaction_id, true) and state.player_name == "Newer name", "Late acknowledgement cannot commit or cancel a newer operation")
	state.cancel_player_profile_update(transaction_id)
	state.cancel_player_profile_update(newer_id)
	check(state.soft_currency == transaction_balance, "Old cancellation cannot refund the newer transaction twice")
	state.player_name_free_change_used = false
	state.player_name_is_custom = false
	check(state.save_game(), "Free crash fixture is durable")
	var original_free_name: String = state.player_name
	check(!state.begin_player_profile_update("Free pending", 1, 1).is_empty(), "Free change also records its pending operation")
	state.load_game()
	check(state.player_name == original_free_name and !state.player_name_free_change_used and !state.player_name_is_custom and state._pending_profile_update.is_empty(), "Reload restores free entitlement and identity before network startup")
	state.load_game()
	check(state.player_name == original_free_name and state.soft_currency == transaction_balance, "A second recovery cannot refund again")
	state.player_name_free_change_used = true
	check(state.save_game(), "Confirmed paid-rename fixture is durable")
	var confirmed_id: String = state.begin_player_profile_update("Confirmed", 2, 5)
	check(!confirmed_id.is_empty() and state.complete_player_profile_update(confirmed_id, true), "Server acknowledgement durably clears the rollback checkpoint")
	var confirmed_balance: int = state.soft_currency
	state.load_game()
	check(state.player_name == "Confirmed" and state.soft_currency == confirmed_balance and state._pending_profile_update.is_empty(), "Confirmed profile survives reload without a refund")
	var rejected_id: String = state.begin_player_profile_update("Rejected", 1, 1)
	check(!rejected_id.is_empty(), "Commit-write failure fixture starts a paid transaction")
	state._save_blocked_by_future_version = true
	check(!state.complete_player_profile_update(rejected_id, true) and state.player_name == "Confirmed" and state.soft_currency == confirmed_balance, "A failed acknowledgement write rolls back profile and payment")
	state._save_blocked_by_future_version = false
	state.load_game()
	check(state.player_name == "Confirmed" and state.soft_currency == confirmed_balance, "Recovery of a failed commit write cannot double the refund")
	state.player_name = "AutoBase"
	state.player_name_base = "AutoBase"
	state.player_name_server_id = ""
	state.player_name_is_custom = false
	state.guided_onboarding_completed = true
	state.accepted_legal_documents_version = state.LEGAL_DOCUMENTS_VERSION
	check(state.save_game(), "Automatic-suffix transaction fixture is durable")
	var sync := SuffixSyncMock.new()
	var owner := Node.new()
	root.add_child(sync)
	root.add_child(owner)
	var suffix_saved: bool = await state.save_player_profile_and_wait("AutoBase", 1, 1, false, sync, owner)
	check(suffix_saved and sync.calls == 2 and state.player_name == "AutoBase17", "A server-added suffix must itself be acknowledged before commit")
	state.load_game()
	check(state.player_name == "AutoBase17" and state._pending_profile_update.is_empty(), "Acknowledged automatic suffix survives reload")
	sync.queue_free()
	owner.queue_free()
	var malformed_checkpoint: Dictionary = {"pending_profile_update": {"version": 1, "id": "bad", "previous": state.capture_player_profile_state(), "refund": -1}, "soft_currency": 123, "player_name": "KeepMe", "progress": {"keep": true}}
	check(state._recover_pending_profile_update(malformed_checkpoint) and malformed_checkpoint.soft_currency == 123 and malformed_checkpoint.player_name == "KeepMe" and malformed_checkpoint.progress.keep, "Malformed checkpoint cannot invent a refund or discard unrelated state")
	reset()
	var current_migrated: Dictionary = state._migrate_save_payload(current_payload)
	check(
		int(current_migrated.get("save_version", -1)) == state.SAVE_FORMAT_VERSION
		and int(current_migrated.get("soft_currency", -1)) == 321,
		"Current save format passes migration pipeline unchanged"
	)
	check(
		state._migrate_save_payload({"save_version": state.SAVE_MIGRATION_BASE_VERSION - 1}).is_empty(),
		"Pre-release save formats below the migration baseline stay rejected"
	)
	check(state.save_game(), "Initial save")
	state.soft_currency = 125
	state.player_name_free_change_used = true
	check(state.save_game(), "Newer save")
	DirAccess.rename_absolute(ProjectSettings.globalize_path(state.SAVE_PATH), ProjectSettings.globalize_path(state.SAVE_TMP_PATH))
	state.soft_currency = 0
	state.load_game()
	check(state.get_soft_currency() == 125, "Complete temp takes priority over older backup when primary is absent")
	check(!state._read_save_dictionary(state.SAVE_PATH).is_empty(), "Recovered temp committed as primary")
	reset()
	state.soft_currency = 175
	check(state.save_game(), "Backup fixture")
	DirAccess.copy_absolute(ProjectSettings.globalize_path(state.SAVE_PATH), ProjectSettings.globalize_path(state.SAVE_BACKUP_PATH))
	write_json(state.SAVE_PATH, {"save_version":0})
	state.soft_currency = 0
	state.load_game()
	check(state.get_soft_currency() == 175, "Incompatible primary falls back to valid backup")
	check(int(state._read_save_dictionary(state.SAVE_BACKUP_PATH).get("soft_currency", -1)) == 175, "Repair does not copy incompatible primary over backup")
	write_json(state.SAVE_TMP_PATH, {"save_version":state.SAVE_FORMAT_VERSION, "soft_currency":999})
	state.load_game()
	check(state.get_soft_currency() == 175, "Valid primary wins over leftover temp")
	write_json(state.SAVE_PATH, {"save_version":state.SAVE_FORMAT_VERSION + 1, "soft_currency":999})
	state.load_game()
	check(!state.save_game(), "Future save remains write-protected")
	check(int(state._read_save_dictionary(state.SAVE_PATH).get("soft_currency", 0)) == 999, "Future save intact")
	state._save_blocked_by_future_version = false
	finish()

func prepare_restart() -> void:
	reset()
	state.pending_single_player_reward = state._normalize_pending_single_player_reward({
		"language":"ru", "level_index":4, "word_slot":2, "word_count":3,
		"amount":35, "claimed":true, "double_resolved":false,
	})
	var request: String = state.begin_rewarded_double_request("final")
	check(!request.is_empty(), "Restart fixture creates durable receipt")
	state.set_word_language("en")
	state.soft_currency = 125
	state.player_name_free_change_used = true
	state.player_name = "BeforeCrash"
	state.player_name_is_custom = true
	state.settings[5] = 1
	state.player_frame_id = 4
	check(state.save_game(), "Restart fixture saves latest balance")
	write_json("user://restart_test.json", {"request":request})
	check(!state.begin_player_profile_update("Unconfirmed", 2, 2).is_empty(), "Crash fixture persists unconfirmed profile and its paid rollback checkpoint")
	# Simulate interruption after primary removal: no further GameState writes.
	check(DirAccess.rename_absolute(
		ProjectSettings.globalize_path(state.SAVE_PATH),
		ProjectSettings.globalize_path(state.SAVE_TMP_PATH)
	) == OK, "Restart fixture leaves complete temporary save")

func verify_restart() -> void:
	# Do not call load_game: these values must come from autoload in a new process.
	check(state.get_soft_currency() == 125, "Fresh process recovers newest temporary save and refunds the unconfirmed rename")
	check(state.player_name == "BeforeCrash" and state.settings[5] == 1 and state.player_frame_id == 4 and state._pending_profile_update.is_empty(), "A fresh engine process restores the original profile before autoload services")
	check(state.word_language == "en", "Fresh process restores selected language")
	check(state.player_name_free_change_used and state.get_player_name_change_cost("Restart rename") == state.GAME_DESIGN.get_int("economy.profile_name_change_cost"), "Fresh process cannot reuse the free nickname change")
	var request: String = str(state._read_save_dictionary("user://restart_test.json").get("request", ""))
	check(!request.is_empty() and state.rewarded_double_requests.has(request), "Fresh process restores unresolved receipt")
	var reward: Dictionary = state.claim_rewarded_double_request(request)
	check(int(reward.get("amount", 0)) == 35, "Late callback after restart pays captured amount")
	check(!bool(reward.get("is_current", true)), "Late callback after restart keeps inactive UI inactive")
	state.set_word_language("ru")
	check(bool(state._rewarded_double_target("final").get("granted", false)), "Inactive offer is resolved after restart")
	check(state.claim_rewarded_double_request(request).is_empty(), "Duplicate callback after restart is ignored")
	check(state.get_soft_currency() == 160, "Restart and duplicate callback preserve exact balance")

func finish() -> void:
	print("SAVE_RECOVERY " + JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
