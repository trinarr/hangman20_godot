extends Node

# Run with an isolated XDG_DATA_HOME: these tests save and reload progress.
# The native ad SDK is not involved; callbacks use real GameState request receipts.
var main: Node
var checks: int = 0
var failures: Array[String] = []
var cancelled_callback_count: int = 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if !condition:
		failures.append(message)
		push_error(message)

func _process(_delta: float) -> void:
	# Home transitions await a GPU fence that the dummy renderer never emits.
	if DisplayServer.get_name() == "headless":
		RenderingServer.frame_post_draw.emit()

func _ready() -> void:
	call_deferred("run")

func settle() -> void:
	await get_tree().create_timer(8.0).timeout
	await get_tree().process_frame

func setup_level(level: int, prior_wins: Array) -> int:
	main.show_menu()
	await get_tree().process_frame
	# This fixture opens a reward directly, without the asynchronous Home route.
	main._clear()
	GameSession.discard_current_round()
	GameState.single_player = {}
	GameState.single_player_resume_states = {}
	GameState.clear_active_single_player_session(false)
	GameState.clear_pending_single_player_reward(false)
	GameState.rewarded_double_requests = {}
	GameState.soft_currency = 100
	GameState.stars = 100
	GameState.current_mode = GameState.GameMode.SINGLE_PLAYER
	GameState._single_player_bucket("ru")["unlocked_level"] = level
	main._portrait_reward_double_context = &""
	main._portrait_final_reward_waiting_for_ad = false
	main._portrait_final_reward_earned_ad_reward = false
	main._portrait_final_reward_claim_in_progress = false
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
	GameState.rewarded_double_requests = {}
	GameState.load_game()
	main._invalidate_single_player_level_cache()

func begin_ad(context: String) -> String:
	var request_id: String = GameState.begin_rewarded_double_request(context)
	check(!request_id.is_empty(), "Ad receipt missing for " + context)
	main._portrait_reward_ad_request_id = request_id
	main._portrait_reward_double_context = StringName(context)
	main._portrait_final_reward_waiting_for_ad = true
	main._portrait_final_reward_earned_ad_reward = false
	return request_id

func audit_text(node: Node) -> void:
	if node.name == &"DisplayTextShaderEffect":
		var label: Control = node.get_parent()
		for layer: Node in node.get_children():
			if layer is Label:
				check(layer.size.is_equal_approx(label.size.max(layer.get_combined_minimum_size())), "Reward text layer layout drift: %s" % label.name)
	for child: Node in node.get_children():
		audit_text(child)

func on_cancelled_collection_finished() -> void:
	cancelled_callback_count += 1

func run() -> void:
	GameState.interface_language = "ru"
	GameState.word_language = "ru"
	GameState.guided_onboarding_completed = true
	GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
	Database.load_languages("ru", "ru")
	main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	Engine.time_scale = 8.0
	# The final stage advances automatically into the merged chest/stars screen.
	await setup_level(1, [false])
	record_stage(true)
	check(GameState.get_active_single_player_stage_reward().amount == 10, "Hangman payout changed")
	check(GameState.get_pending_single_player_reward().amount == 35, "Normal completion formula changed")
	check(GameState.get_pending_single_player_reward().stars_amount == 12, "Normal completion stars changed")
	GameState.claim_active_single_player_stage_reward()
	record_stage(true)
	check(GameState.claim_active_single_player_stage_reward().amount == 0, "Duplicate stage result reset its claim")
	reload_save()
	check(GameState.get_active_single_player_stage_reward().claimed, "Stage claim lost after reload")
	main._show_single_player_reward_chain_screen()
	await settle()
	check(main.last_result_data.get("single_player_level_summary_view", false), "Final stage did not auto-advance")
	check(GameState.get_soft_currency() == 145 and GameState.get_stars() == 112, "Merged summary did not credit coins and stars once")
	check(main.find_child("SinglePlayerRewardHeroViewport", true, false) == null, "Summary created a hidden hero viewport")
	check(main.find_child("SinglePlayerRewardChain", true, false) == null, "Summary created an unused chain")
	var chest: Node = main.find_child("FinalRewardChest", true, false)
	check(chest != null and chest.get_node("ChestOpenVisual").visible, "Chest did not open")
	check(chest != null and !chest.get_node("ChestFlashOverlay").visible, "Chest flash kept drawing")
	check(is_instance_valid(main._portrait_final_reward_continue_button) and main._portrait_final_reward_continue_button.is_visible_in_tree() and !main._portrait_final_reward_continue_button.get("disabled"), "Summary actions missing or disabled")
	audit_text(main)
	# The request id, not SDK amount, determines the bonus. Retries share one target.
	var request_id: String = begin_ad("final")
	var retry_id: String = GameState.begin_rewarded_double_request("final")
	main._on_final_reward_ad_rewarded(request_id, "ignored", 99999)
	main._on_final_reward_ad_rewarded(request_id, "coins", 1)
	main._on_final_reward_ad_rewarded(retry_id, "coins", 1)
	check(GameState.get_soft_currency() == 180, "Repeated/retried ad duplicated bonus")
	main._on_final_reward_ad_closed("unrelated")
	check(main._portrait_final_reward_waiting_for_ad, "Unrelated close dismissed current ad")
	main._on_final_reward_ad_closed(request_id)
	await settle()
	check(GameState.get_pending_single_player_reward().is_empty(), "Successful final x2 left a pending reward")
	check(main._portrait_reward_double_context == &"", "Final x2 did not leave the offer")
	reload_save()
	main._on_final_reward_ad_rewarded(request_id, "coins", 1)
	check(GameState.get_soft_currency() == 180 and GameState.get_stars() == 112, "Reload allowed another ad payout")
	# Fresh final-stage credit must finish before the automatic summary rebuild.
	await setup_level(1, [false])
	record_stage(true)
	main._show_single_player_reward_chain_screen()
	var stage_header: Control = main._portrait_top_bar_content
	await settle()
	check(GameState.get_soft_currency() == 145 and GameState.get_stars() == 112, "Automatic transition interrupted the fresh stage payout")
	check(main._portrait_top_bar_content == stage_header, "Summary replaced the shared result header")
	# Failed final stages still receive the base level bonus, including zero wins.
	for won_before: bool in [true, false]:
		await setup_level(1, [won_before])
		record_stage(false)
		var expected_coins: int = 35 if won_before else 25
		var expected_stars: int = 12 if won_before else 10
		check(GameState.get_active_single_player_stage_reward().is_empty(), "Failed stage has a payout")
		main._show_single_player_reward_chain_screen()
		await settle()
		check(GameState.get_soft_currency() == 100 + expected_coins, "Failed-final coins wrong")
		check(GameState.get_stars() == 100 + expected_stars, "Failed-final stars wrong")
		check(GameState.claim_pending_single_player_level_stars() == 0, "Summary stars repeated")
	# A presented summary settles remaining rewards on restart, without reviving x2.
	await setup_level(1, [true])
	record_stage(false)
	GameState.clear_active_single_player_session(false)
	GameState.mark_pending_single_player_reward_presented(true)
	reload_save()
	main._resume_saved_single_player_level()
	check(GameState.get_soft_currency() == 135 and GameState.get_stars() == 112, "Interrupted summary lost unpaid rewards")
	check(GameState.get_pending_single_player_reward().is_empty(), "Interrupted summary retained offer")
	reload_save()
	main._resume_saved_single_player_level()
	check(GameState.get_soft_currency() == 135 and GameState.get_stars() == 112, "Restart repeated settled rewards")
	# Hard-level formula and balance caps retain idempotent claims.
	var count: int = await setup_level(9, [true, false, true, false, false])
	check(count == 6, "Hard-level fixture changed")
	record_stage(true)
	check(GameState.get_pending_single_player_reward().amount == 110, "Hard completion coins wrong")
	check(GameState.get_pending_single_player_reward().stars_amount == 24, "Hard completion stars wrong")
	GameState.soft_currency = GameState.MAX_CURRENCY_BALANCE - 3
	GameState.stars = GameState.MAX_CURRENCY_BALANCE - 2
	check(GameState.claim_pending_single_player_reward() == 3, "Capped coin claim did not report actual credit")
	check(GameState.claim_pending_single_player_reward(2) == 0, "Capped x2 exceeded limit")
	check(GameState.claim_pending_single_player_level_stars() == 2, "Capped stars did not report actual credit")
	check(GameState.claim_pending_single_player_level_stars() == 0, "Capped stars repeated")
	# Embedded quiz and single-stage level offers have no level chest.
	for level: int in [1, 0]:
		await setup_level(level, [])
		record_stage(true, false)
		var stage_amount: int = 15 if level == 1 else 10
		main._show_single_player_reward_chain_screen()
		await settle()
		check(GameState.get_soft_currency() == 100 + stage_amount, "Stage offer base payout wrong")
		request_id = begin_ad("stage_coin")
		main._on_final_reward_ad_closed(request_id)
		main._on_final_reward_ad_rewarded(request_id, "coins", 1)
		main._on_final_reward_ad_rewarded(request_id, "coins", 1)
		await settle()
		check(GameState.get_soft_currency() == 100 + 2 * stage_amount, "Close-before-reward lost or duplicated payout")
		check(GameState.get_stars() == 100 and GameState.get_pending_single_player_reward().is_empty(), "Stage offer created a level bonus")
	# Relaunching after the large stage-coin reward has appeared skips that offer.
	# The base payout is settled exactly once and Continue resumes on the chain.
	await setup_level(1, [])
	record_stage(true, false)
	main._show_single_player_reward_chain_screen()
	check(
		GameState.get_active_single_player_stage_reward().get("presentation_started", false),
		"Large stage reward did not persist its presentation marker"
	)
	# Leave before the deferred pack bounce reaches the base-claim callback.
	main.show_menu()
	reload_save()
	main._resume_saved_single_player_level()
	await settle()
	var resumed_stage_reward: Dictionary = GameState.get_active_single_player_stage_reward()
	check(GameState.get_soft_currency() == 115, "Interrupted stage reward lost or duplicated base payout")
	check(
		bool(resumed_stage_reward.get("claimed", false))
		and bool(resumed_stage_reward.get("double_resolved", false))
		and !bool(resumed_stage_reward.get("double_claimed", false)),
		"Interrupted stage reward did not settle the skipped x2 offer"
	)
	check(main.find_child("StageCoinLargeReward", true, false) == null, "Interrupted stage reward reopened the large reward screen")
	check(main.find_child("SinglePlayerRewardChain", true, false) != null, "Interrupted stage reward did not resume on the chain")
	reload_save()
	main._resume_saved_single_player_level()
	check(GameState.get_soft_currency() == 115, "Repeated resume credited interrupted stage reward twice")
	# A late receipt pays the old target, even while a new offer exists.
	await setup_level(0, [])
	record_stage(true)
	GameState.claim_active_single_player_stage_reward()
	request_id = GameState.begin_rewarded_double_request("stage_coin")
	GameState.clear_active_single_player_session(false)
	main.single_player_active_level_index = 1
	main.single_player_active_word_slot = 0
	GameState.select_single_level_theme("ru", 1, 0, 2)
	main._invalidate_single_player_level_cache()
	record_stage(true, false)
	GameState.claim_active_single_player_stage_reward()
	main._portrait_reward_double_context = &"stage_coin"
	var balance_before: int = GameState.get_soft_currency()
	main._on_final_reward_ad_rewarded(request_id, "coins", 1)
	check(GameState.get_soft_currency() == balance_before + 10, "Late old-target receipt used new reward amount")
	check(!GameState.get_active_single_player_stage_reward().double_resolved, "Late old-target receipt resolved new offer")
	var cancelled_id: String = GameState.begin_rewarded_double_request("stage_coin")
	main._on_final_reward_ad_failed_to_show(cancelled_id, "test")
	main._on_final_reward_ad_rewarded(cancelled_id, "coins", 1)
	main._on_final_reward_ad_rewarded("unknown", "coins", 1)
	check(GameState.get_soft_currency() == balance_before + 10, "Cancelled or unknown ad paid out")
	# Leaving a still-pending stage offer must make its late receipt silent.
	await setup_level(0, [])
	record_stage(true)
	main._show_single_player_reward_chain_screen()
	await settle()
	request_id = begin_ad("stage_coin")
	main._on_final_reward_ad_closed(request_id)
	main.show_menu()
	var home_generation: int = main.result_transition_generation
	main._on_final_reward_ad_rewarded(request_id, "coins", 1)
	check(main.result_transition_generation == home_generation, "Late off-screen receipt navigated away from Home")
	check(GameState.get_soft_currency() == 120, "Late off-screen receipt lost payout")
	# Cancellation must stop root-owned effects, HUD rolls and stale navigation.
	await setup_level(1, [true])
	record_stage(false)
	main.show_menu()
	var source := Control.new()
	source.size = Vector2(32, 32)
	main.content.add_child(source)
	main._portrait_final_reward_claim_in_progress = false
	main._play_early_final_reward_coin_claim(source, Callable(self, "on_cancelled_collection_finished"))
	main.show_menu()
	await get_tree().process_frame
	check(main.find_child("SinglePlayerRewardResourceCanvas", true, false) == null, "Resource overlay survived screen clear")
	# A later balance update must not be overwritten by the cancelled count roll.
	GameState.add_soft_currency(7)
	for frame: int in range(15):
		await get_tree().process_frame
		for label: Node in get_tree().get_nodes_in_group("soft_currency_balance_label"):
			if label is Label:
				check(label.text == main._soft_currency_balance_text(GameState.get_soft_currency()), "Old coin roll overwrote the new HUD")
	await settle()
	check(cancelled_callback_count == 0, "Cancelled resource flight executed its completion callback")
	# The same flight helper is also used for quiz stars.
	source = Control.new()
	source.size = Vector2(32, 32)
	main.content.add_child(source)
	GameState.add_stars(2)
	main._play_quiz_fast_answer_star_collection(source, GameState.get_stars() - 2, GameState.get_stars())
	main.show_menu()
	GameState.add_stars(3)
	for frame: int in range(15):
		await get_tree().process_frame
		for label: Node in get_tree().get_nodes_in_group("stars_balance_label"):
			if label is Label:
				check(label.text == main._soft_currency_balance_text(GameState.get_stars()), "Old star roll overwrote the new HUD")
	# A reward header can outlive the body: clear must reset its held pose too.
	var counter: Control = main._portrait_currency_counter_visual
	var icon: Control = main._portrait_currency_coin_icon_visual
	var rest_scale: Vector2 = counter.scale
	var icon_scale: Vector2 = icon.scale
	main._set_portrait_resource_counter_collection_active("coins", true)
	await get_tree().create_timer(0.2).timeout
	main._bounce_portrait_resource_counter_icon("coins")
	main._clear(main.content)
	check(counter.is_inside_tree() and counter.scale.is_equal_approx(rest_scale), "Retained counter kept its collection scale")
	check(icon.scale.is_equal_approx(icon_scale) and !counter.get_meta("reward_counter_collection_active"), "Retained icon kept its impact state")
	main.show_menu()
	# Post-ad delivery queued for one Home must not rewind a newer screen.
	var generation: int = main.result_transition_generation
	main.call_deferred("_play_centered_rewarded_double_coin_animation", 1, 100, 180, generation)
	main.show_menu()
	await get_tree().process_frame
	check(main.find_child("SinglePlayerRewardResourceCanvas", true, false) == null, "Deferred ad delivery ran on a different screen")
	# Queue navigation in the same frame as leaving the final stage.
	await setup_level(1, [true])
	record_stage(false)
	main._auto_advance_final_stage_reward()
	main.show_menu()
	await settle()
	check(!main.last_result_data.get("single_player_level_summary_view", false), "Deferred old-stage navigation reopened summary")
	# Legacy amount and independent UI/word languages remain compatible.
	GameState.pending_single_player_reward = GameState._normalize_pending_single_player_reward({"language":"ru", "level_index":4, "word_count":3, "amount":35})
	GameState.soft_currency = 0
	check(GameState.claim_pending_single_player_reward() == 35, "Legacy completion amount changed")
	check(GameState.claim_pending_single_player_reward() == 0, "Legacy completion repeated")
	Database.load_languages("en", "ru")
	check(main._single_player_level_completed_label() == "LEVEL COMPLETED", "Summary title followed word language")
	for viewport_size: Vector2i in [Vector2i(690, 1536), Vector2i(960, 1600)]:
		get_tree().root.size = viewport_size
		await setup_level(1, [true])
		record_stage(false)
		main._show_single_player_reward_chain_screen()
		await settle()
		audit_text(main)
	main.show_menu()
	await settle()
	main.queue_free()
	await get_tree().process_frame
	print("REWARDS ", JSON.stringify({"checks":checks, "failures":failures}))
	get_tree().quit(0 if failures.is_empty() else 1)
