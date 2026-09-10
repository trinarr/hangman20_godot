extends Node

# Run with an isolated XDG_DATA_HOME: these tests save and reload game progress.
var main: Node
var checks: int = 0
var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	checks += 1
	if !condition:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	call_deferred("run")

func settle() -> void:
	await get_tree().create_timer(6.0).timeout
	await get_tree().process_frame

func setup_level(level: int, prior_wins: Array) -> int:
	main.show_menu()
	await get_tree().process_frame
	GameSession.discard_current_round()
	GameState.single_player = {}
	GameState.clear_active_single_player_session(false)
	GameState.clear_pending_single_player_reward(false)
	GameState.soft_currency = 100
	GameState.stars = 100
	GameState.current_mode = GameState.GameMode.SINGLE_PLAYER
	GameState._single_player_bucket("ru")["unlocked_level"] = level
	main._invalidate_single_player_level_cache()
	var count: int = main._single_player_level_word_target(level)
	GameState.select_single_level_theme("ru", level, 0, count)
	main._invalidate_single_player_level_cache()
	for slot: int in range(prior_wins.size()):
		GameState.mark_single_level_word_played("ru", level, slot, count, prior_wins[slot], true, -1, false, false)
	main.single_player_active_level_index = level
	main.single_player_active_word_slot = prior_wins.size()
	main.game_finished = true
	return count

func record_stage(won: bool, deferred: bool = true) -> void:
	main.last_result_is_win = won
	main.last_result_data = main._single_player_mark_current_word_finished({"lines": []}, won, true, deferred, true)

func reload_save() -> void:
	GameState.single_player = {}
	GameState.active_single_player_session = {}
	GameState.pending_single_player_reward = {}
	GameState.load_game()
	main._invalidate_single_player_level_cache()

func audit_text(node: Node) -> void:
	if node.name == &"DisplayTextShaderEffect":
		var label: Control = node.get_parent()
		for layer: Node in node.get_children():
			if layer is Label:
				check(layer.size.is_equal_approx(label.size.max(layer.get_combined_minimum_size())), "Reward text layer layout drift: %s" % label.name)
	for child: Node in node.get_children():
		audit_text(child)

func run() -> void:
	GameState.interface_language = "ru"
	GameState.word_language = "ru"
	Database.load_languages("ru", "ru")
	main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	Engine.time_scale = 12.0
	# An ordinary final Hangman stage and the level chest coexist independently.
	await setup_level(1, [false])
	record_stage(true)
	check(GameState.get_active_single_player_stage_reward().amount == 10, "Final Hangman must keep its own 10-coin payout")
	check(GameState.get_pending_single_player_reward().amount == 35, "Normal completion must award 25 + 10 per win")
	main._show_single_player_reward_chain_screen()
	await settle()
	check(GameState.get_soft_currency() == 110, "Stage screen must credit only the stage reward")
	record_stage(true)
	check(GameState.claim_active_single_player_stage_reward().amount == 0, "Duplicate result reset the stage claim")
	reload_save()
	check(GameState.get_active_single_player_stage_reward().claimed, "Stage claim lost after reload")
	check(GameState.get_pending_single_player_reward().amount == 35, "Pending chest lost while stage result exists")
	main._resume_saved_single_player_level()
	await settle()
	main._continue_from_single_player_reward_chain()
	await settle()
	check(GameState.get_soft_currency() == 145, "Chest must credit once at the animation peak")
	check(GameState.get_pending_single_player_reward().get("claimed", false), "Chest offer needs a durable claimed snapshot")
	check(main.find_child("SinglePlayerRewardHeroViewport", true, false) == null, "Hidden hero viewport created on summary")
	var chain: Node = main.find_child("SinglePlayerRewardChain", true, false)
	check(chain != null and chain.get_child_count() == 0, "Invisible chain tiles created on summary")
	var chest: Node = main.find_child("FinalRewardChest", true, false)
	check(chest != null and chest.get_node("ChestOpenVisual").visible, "Chest did not open")
	check(chest != null and !chest.get_node("ChestFlashOverlay").visible, "Flash kept drawing after animation")
	audit_text(main)
	# Restart between the chest peak and either x2/No Thanks retains the offer.
	reload_save()
	main._resume_saved_single_player_level()
	await settle()
	check(GameState.get_soft_currency() == 145, "Restart repeated the chest base reward")
	main._portrait_final_reward_waiting_for_ad = true
	main._on_final_reward_ad_rewarded("coins", 1)
	main._on_final_reward_ad_rewarded("coins", 1)
	check(GameState.get_soft_currency() == 180, "Repeated rewarded signal changed the x2 payout")
	reload_save()
	main._resume_saved_single_player_level()
	await settle()
	check(main.last_result_data.get("single_player_level_stars_view", false), "Resolved ad must resume directly on stars")
	check(GameState.get_stars() == 101, "Level stars count only successful stages")
	check(GameState.get_pending_single_player_reward().is_empty(), "Stars transition did not consume chest snapshot")
	main._show_completed_single_player_level_stars()
	await settle()
	check(GameState.get_stars() == 101, "Repeated stars navigation duplicated payout")
	reload_save()
	main._resume_saved_single_player_level()
	await settle()
	check(GameState.get_stars() == 101, "Restart duplicated level stars")
	main._finish_completed_single_player_stage_result(false)
	check(!GameState.has_resumable_single_player_level(), "Finished rewards left an obsolete resume point")
	# Final-stage defeat still earns a chest, including a run with zero wins.
	for won_before: bool in [true, false]:
		await setup_level(1, [won_before])
		record_stage(false)
		var expected: int = 35 if won_before else 25
		check(GameState.get_active_single_player_stage_reward().is_empty(), "Failed stage has a payout")
		check(GameState.get_pending_single_player_reward().amount == expected, "Failed-final completion formula is wrong")
		main._show_single_player_reward_chain_screen()
		await settle()
		main._continue_from_single_player_reward_chain()
		await settle()
		check(GameState.get_soft_currency() == 100 + expected, "Failed-final chest not credited")
		main._claim_single_player_final_reward()
		await settle()
		check(GameState.get_stars() == (101 if won_before else 100), "Failed-final stars are wrong")
		check(main._portrait_single_reward_continue_button != null, "Zero-star flow has no Continue")
	# Hard-level formula, without changing stage adaptation.
	var count: int = await setup_level(9, [true, false, true, false, false])
	check(count == 6, "Hard-level stage fixture changed")
	record_stage(true)
	check(GameState.get_pending_single_player_reward().amount == 110, "Hard completion must award 50 + 20 per win")
	# Quiz coins are 1.5x Hangman, and its ad affects only that stage.
	await setup_level(1, [])
	record_stage(true, false)
	check(GameState.get_active_single_player_stage_reward().amount == 15, "Quiz stage must pay 15 coins")
	main._show_single_player_reward_chain_screen()
	await settle()
	check(GameState.get_soft_currency() == 115, "Quiz base payout was not credited")
	main._portrait_final_reward_waiting_for_ad = true
	main._on_final_reward_ad_rewarded("coins", 1)
	main._on_final_reward_ad_rewarded("coins", 1)
	check(GameState.get_soft_currency() == 130, "Quiz x2 must credit exactly 15 extra")
	main._on_final_reward_ad_closed()
	await settle()
	check(main._portrait_reward_double_context == &"", "Quiz ad did not finish its offer")
	check(GameState.get_pending_single_player_reward().is_empty(), "Mid-level quiz created a chest")
	# A single stage has no chest or stars screen. Its star flag survives reload.
	await setup_level(0, [])
	record_stage(true)
	check(GameState.get_pending_single_player_reward().is_empty(), "One-stage level created a chest bonus")
	GameState.claim_active_single_player_stage_reward()
	check(GameState.claim_single_stage_level_stars() == 1, "Single-stage win missing its star")
	reload_save()
	check(GameState.claim_single_stage_level_stars() == 0, "Single-stage star repeated after reload")
	main._resume_saved_single_player_level()
	await settle()
	main._decline_single_player_stage_coin_reward_double()
	await settle()
	check(GameState.get_stars() == 101 and GameState.get_soft_currency() == 110, "Single-stage Continue duplicated payout")
	check(!main.last_result_data.get("single_player_level_stars_view", false), "Single-stage level displayed a separate stars screen")
	# Closing the ad before its earned signal must still grant once and advance.
	await setup_level(0, [])
	record_stage(true)
	main._show_single_player_reward_chain_screen()
	await settle()
	main._portrait_final_reward_waiting_for_ad = true
	main._on_final_reward_ad_closed()
	main._on_final_reward_ad_rewarded("coins", 1)
	await settle()
	check(GameState.get_soft_currency() == 120 and GameState.get_stars() == 101, "Close-before-reward lost or duplicated single-stage rewards")
	check(!main.last_result_data.get("single_player_level_summary_view", false), "Single-stage x2 opened a completion screen")
	# X on a completed stage retains both the result and the pending chest.
	await setup_level(4, [true, false])
	record_stage(false)
	main._leave_single_player_failure_reward_to_menu()
	check(GameState.has_resumable_single_player_level(), "Stage X discarded an unfinished level reward")
	check(!GameState.get_pending_single_player_reward().is_empty(), "Stage X dropped the chest")
	# Balance caps report the actual credit and still resolve the claim.
	await setup_level(1, [true])
	record_stage(true)
	GameState.soft_currency = GameState.MAX_CURRENCY_BALANCE - 3
	check(GameState.claim_pending_single_player_reward() == 3, "Capped claim returned the requested amount rather than actual credit")
	check(GameState.claim_pending_single_player_reward(2) == 0, "Capped x2 claim exceeded balance limit")
	check(GameState.get_pending_single_player_reward().double_resolved, "Capped bonus did not resolve")
	# Patch05 pending rewards preserve the promised amount on migration.
	var legacy: Dictionary = GameState._normalize_pending_single_player_reward({"language":"ru", "level_index":4, "word_count":3, "amount":35})
	GameState.pending_single_player_reward = legacy
	GameState.soft_currency = 0
	check(GameState.claim_pending_single_player_reward() == 35, "Legacy completion amount changed")
	check(GameState.claim_pending_single_player_reward() == 0, "Legacy completion repeated")
	# Interface text follows the interface language independently of the words.
	Database.load_languages("en", "ru")
	check(main._single_player_level_completed_label() == "LEVEL COMPLETED", "Summary title follows word language instead of interface language")
	# Both portrait aspect ratios retain text layer geometry on the new stars UI.
	for viewport_size: Vector2i in [Vector2i(690,1536), Vector2i(960,1600)]:
		get_tree().root.size = viewport_size
		await setup_level(1, [true])
		record_stage(false)
		main._show_completed_single_player_level_stars()
		await settle()
		audit_text(main)
	main.show_menu()
	await settle()
	main.queue_free()
	await get_tree().process_frame
	print("REWARDS ", JSON.stringify({"checks":checks, "failures":failures}))
	get_tree().quit(0 if failures.is_empty() else 1)
