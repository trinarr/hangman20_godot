extends "res://tools/tests/rewards.gd"
## Exercise the real reward actions without requesting the native ad SDK.
class TestUI extends "res://scripts/main_portrait.gd":
	var ads_enabled := false
	func _ready() -> void:
		_build_root()
		_clear()
	func _portrait_ads_enabled() -> bool:
		return ads_enabled
	func _portrait_ads_service() -> Node:
		return null
	func _should_auto_resume_guided_single_player() -> bool:
		return false

func run() -> void:
	GameState.guided_onboarding_completed = true
	GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
	main = TestUI.new()
	add_child(main)
	Engine.time_scale = 8.0
	var unlock_level: int = GameState.GAME_DESIGN.get_int("tournament.unlock_completed_levels")
	for language: String in ["ru", "en"]:
		Database.load_languages(language, "ru")
		for ads_enabled: bool in [false, true]:
			main.ads_enabled = ads_enabled
			get_window().min_size = Vector2i(690, 1536) if ads_enabled else Vector2i(960, 1600)
			get_window().size = get_window().min_size
			for level_number: int in [unlock_level - 1, unlock_level, unlock_level + 1]:
				for won: bool in [false, true]:
					var count: int = main._single_player_level_word_target(level_number - 1)
					var prior_wins: Array = []
					prior_wins.resize(count - 1)
					prior_wins.fill(true)
					GameState.tournament_state = {}
					await setup_level(level_number - 1, prior_wins)
					GameState.hearts = GameState.MAX_HEARTS if won else 0
					record_stage(won)
					await present_summary()
					var coins := GameState.get_soft_currency()
					var stars := GameState.get_stars()
					var action: Control
					if ads_enabled:
						action = main.find_child("FinalRewardCollectButton", true, false)
					else:
						action = main._portrait_final_reward_continue_button
					check(is_instance_valid(action) and !action.disabled, "Reward exit action is available after the payout")
					if !is_instance_valid(action):
						continue
					action.pressed.emit()
					var generation: int = main.result_transition_generation
					main._claim_single_player_final_reward()
					check(main.result_transition_generation == generation, "Repeated reward exit cannot rebuild the destination")
					await get_tree().process_frame
					if level_number == unlock_level:
						check(is_instance_valid(main._home_logo_reveal), "Tournament unlock exits to Home for both outcomes and reward button styles")
						check(get_tree().get_nodes_in_group("single_player_theme_popup").is_empty(), "Unlock exit never opens the next-theme popup")
						check(get_tree().get_nodes_in_group(main.TOURNAMENT_START_POPUP.GROUP).size() == 1, "Unlock exit automatically presents exactly one tournament introduction")
						var directory := OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
						if !directory.is_empty() and DisplayServer.get_name() != "headless":
							await get_tree().create_timer(0.8).timeout
							await RenderingServer.frame_post_draw
							check(get_viewport().get_texture().get_image().save_png(directory.path_join("level_exit_%s_ads%d_win%d.png" % [language, int(ads_enabled), int(won)])) == OK, "Capture the automatic introduction on Home")
					else:
						check(!get_tree().get_nodes_in_group("single_player_theme_popup").is_empty(), "Other levels keep the direct next-theme destination")
					check(GameState.get_soft_currency() == coins and GameState.get_stars() == stars, "Reward exit cannot repeat the paid coins or stars")
					check(GameState.get_pending_single_player_reward().is_empty(), "Reward exit clears the completion offer")
					GameState.load_game()
					check(GameState.get_soft_currency() == coins and GameState.get_stars() == stars and GameState.get_pending_single_player_reward().is_empty(), "Reload preserves payment and the resolved offer")
	await test_exit_edges(unlock_level)
	await test_single_stage_unlock()
	main.queue_free()
	await get_tree().process_frame
	print("LEVEL_REWARD_NAVIGATION checks=%d failures=%d" % [checks, failures.size()])
	get_tree().quit(1 if !failures.is_empty() else 0)

func prepare_unlock_reward(unlock_level: int) -> void:
	var count: int = main._single_player_level_word_target(unlock_level - 1)
	var prior_wins: Array = []
	prior_wins.resize(count - 1)
	prior_wins.fill(true)
	GameState.tournament_state = {}
	await setup_level(unlock_level - 1, prior_wins)
	GameState.hearts = GameState.MAX_HEARTS
	record_stage(true)
	await present_summary()

func test_exit_edges(unlock_level: int) -> void:
	main.ads_enabled = true
	for rewarded_first: bool in [true, false]:
		await prepare_unlock_reward(unlock_level)
		var coins := GameState.get_soft_currency()
		var bonus := int(GameState.get_pending_single_player_reward().amount)
		var request_id := begin_ad("final")
		var generation: int = main.result_transition_generation
		if rewarded_first:
			main._on_final_reward_ad_rewarded(request_id, "coins", 1)
			check(main.result_transition_generation == generation, "Rewarded signal cannot leave the prize while the ad is still open")
		main._on_final_reward_ad_closed(request_id)
		if !rewarded_first:
			check(main.result_transition_generation == generation, "Ad close without a reward keeps the unresolved offer")
			main._on_final_reward_ad_rewarded(request_id, "coins", 1)
		await get_tree().process_frame
		check(is_instance_valid(main._home_logo_reveal) and get_tree().get_nodes_in_group(main.TOURNAMENT_START_POPUP.GROUP).size() == 1, "Both rewarded/closed orders return Home with one tournament intro")
		check(GameState.get_soft_currency() == coins + bonus, "Ad exit pays the configured bonus once")
		generation = main.result_transition_generation
		main._on_final_reward_ad_rewarded(request_id, "coins", 1)
		main._on_final_reward_ad_closed(request_id)
		check(main.result_transition_generation == generation and GameState.get_soft_currency() == coins + bonus, "Repeated ad callbacks cannot restart Home or pay twice")
	await prepare_unlock_reward(unlock_level)
	var request_id := begin_ad("final")
	main._claim_single_player_final_reward()
	check(main._portrait_final_reward_waiting_for_ad, "No Thanks cannot dismiss an outstanding ad")
	main._on_final_reward_ad_failed_to_show(request_id, "test")
	check(main._portrait_reward_double_context == &"final", "Failed ad leaves the reward available for No Thanks")
	main._claim_single_player_final_reward()
	await get_tree().process_frame
	check(get_tree().get_nodes_in_group(main.TOURNAMENT_START_POPUP.GROUP).size() == 1, "No Thanks still introduces the tournament after an ad failure")
	await prepare_unlock_reward(unlock_level)
	var coins := GameState.get_soft_currency()
	main._clear()
	GameState.load_game()
	main._resume_saved_single_player_level()
	await get_tree().process_frame
	check(is_instance_valid(main._home_logo_reveal) and get_tree().get_nodes_in_group(main.TOURNAMENT_START_POPUP.GROUP).size() == 1, "Interrupted presented reward resumes Home with the tournament intro")
	check(GameState.get_soft_currency() == coins and GameState.get_pending_single_player_reward().is_empty(), "Recovery cannot repeat the level payment")
	main.content.get_node("TournamentStartPrompt")._go()
	main.show_menu()
	await get_tree().process_frame
	check(get_tree().get_nodes_in_group(main.TOURNAMENT_START_POPUP.GROUP).is_empty(), "A later Home visit does not repeat the resolved introduction")
	await prepare_unlock_reward(unlock_level)
	main._claim_single_player_final_reward()
	main._show_leaderboard_screen(true)
	await get_tree().process_frame
	check(is_instance_valid(main._portrait_leaderboard) and get_tree().get_nodes_in_group(main.TOURNAMENT_START_POPUP.GROUP).is_empty(), "An obsolete deferred intro cannot appear over a newer page")
	await prepare_unlock_reward(unlock_level)
	main._claim_single_player_final_reward()
	var blocker := CanvasLayer.new()
	main.add_child(blocker)
	blocker.add_to_group(main.PORTRAIT_MODAL_POPUP_GROUP)
	await get_tree().process_frame
	check(get_tree().get_nodes_in_group(main.TOURNAMENT_START_POPUP.GROUP).is_empty(), "Automatic intro waits for the current Home modal")
	main.TOURNAMENT_START_POPUP.present_after_home_return.call_deferred(main, main.result_transition_generation)
	blocker.remove_from_group(main.PORTRAIT_MODAL_POPUP_GROUP)
	blocker.queue_free()
	for _frame in range(3):
		await get_tree().process_frame
	check(get_tree().get_nodes_in_group(main.TOURNAMENT_START_POPUP.GROUP).size() == 1, "Automatic intro appears after the blocking modal closes")
	main.content.get_node("TournamentStartPrompt")._go()
	for _frame in range(3):
		await get_tree().process_frame
	check(get_tree().get_nodes_in_group(main.TOURNAMENT_START_POPUP.GROUP).is_empty(), "Duplicate automatic requests cannot reopen a dismissed introduction")
	await prepare_unlock_reward(unlock_level)
	var now: int = GameState._tournament_now()
	var config: Dictionary = GameState.GAME_DESIGN.get_value("tournament")
	GameState.tournament_state = GameState.TOURNAMENT_MODEL.create(now - int(config.duration_seconds), "ru", config, 812)
	GameState.tournament_state.player_stars = 2000000000
	var identifier: String = GameState.tournament_state.id
	main._claim_single_player_final_reward()
	await settle()
	check(GameState.tournament_state.id == identifier and get_tree().get_nodes_in_group(main.TOURNAMENT_FINISH_POPUP.GROUP).size() == 1, "Unclaimed tournament prize takes precedence over the automatic intro")
	check(get_tree().get_nodes_in_group(main.TOURNAMENT_START_POPUP.GROUP).is_empty(), "Automatic intro cannot replace an unclaimed tournament prize")

func test_single_stage_unlock() -> void:
	var config: Dictionary = GameState.GAME_DESIGN.get_value("tournament")
	var original_level: int = int(config.unlock_completed_levels)
	config.unlock_completed_levels = 1
	main.ads_enabled = false
	GameState.tournament_state = {}
	await setup_level(0, [])
	record_stage(true)
	main._show_single_player_reward_chain_screen()
	await settle()
	main._continue_from_single_player_reward_chain()
	await get_tree().process_frame
	check(is_instance_valid(main._home_logo_reveal) and get_tree().get_nodes_in_group(main.TOURNAMENT_START_POPUP.GROUP).size() == 1, "A configured single-stage unlock also returns Home with an intro without a separate level prize")
	config.unlock_completed_levels = original_level
