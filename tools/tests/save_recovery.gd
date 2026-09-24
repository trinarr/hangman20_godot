extends SceneTree
# Run only with an isolated user:// directory (tools/run_reward_tests.py).
var failures: Array[String] = []
var checks: int = 0
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
	check(state.save_game(), "Initial save")
	state.soft_currency = 125
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
	check(state.save_game(), "Restart fixture saves latest balance")
	write_json("user://restart_test.json", {"request":request})
	# Simulate interruption after primary removal: no further GameState writes.
	check(DirAccess.rename_absolute(
		ProjectSettings.globalize_path(state.SAVE_PATH),
		ProjectSettings.globalize_path(state.SAVE_TMP_PATH)
	) == OK, "Restart fixture leaves complete temporary save")

func verify_restart() -> void:
	# Do not call load_game: these values must come from autoload in a new process.
	check(state.get_soft_currency() == 125, "Fresh process recovers newest temporary save")
	check(state.word_language == "en", "Fresh process restores selected language")
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
