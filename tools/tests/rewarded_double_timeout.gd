extends "res://tools/tests/rewarded_stage_fixture.gd"
## Advertising lifecycle in one representative language and viewport.

func start() -> String:
	ui._on_final_reward_double_pressed()
	check(ads._rewarded_pending_show and ui._portrait_final_reward_waiting_for_ad, "Unloaded x2 waits for the native SDK")
	check(ui._portrait_final_reward_double_button.get("button_disabled"), "Waiting x2 is disabled")
	return ui._portrait_reward_ad_request_id

func check_stage_multiplier_totals() -> void:
	for cursor: float in [0.1, 0.3, 0.5]:
		var initial_balance: int = GameState.get_soft_currency()
		await fixture()
		ui.run_collection_animation = true
		check(GameState.get_soft_currency() == initial_balance + 25, "Stage base is saved exactly once before the ad")
		var component: Node = ui._portrait_stage_reward
		component.multiplier_meter.set_cursor(cursor)
		var total: int = roundi(25 * component.selected_multiplier())
		var request_id: String = start()
		check(int(GameState.rewarded_double_requests[request_id].amount) == total - 25, "Receipt contains only the bonus beyond the saved base")
		ads._on_rewarded_video_ad_loaded()
		await frames()
		ads._on_rewarded_for_request(request_id, "coins", 25)
		ads._on_rewarded_for_request(request_id, "coins", 25)
		ads._on_rewarded_closed_for_request(request_id)
		ads._on_rewarded_closed_for_request(request_id)
		await get_tree().create_timer(ui._single_player_reward_collection_duration() + 0.5).timeout
		check(ui.collection_amounts == [total] and component.deferred_coin_amount == 0, "Saved base is consumed once by the real collection animation")
		check(GameState.get_soft_currency() == initial_balance + total, "Final balance includes exactly the multiplied reward, without an extra base")
		for label: Node in get_tree().get_nodes_in_group(&"soft_currency_balance_label"):
			check(label.text == ui._soft_currency_balance_text(initial_balance + total), "Animated HUD finishes at the actual multiplied balance")
		ads._on_rewarded_for_request(request_id, "coins", 25)
		ui._play_early_stage_coin_reward_claim(component.prize)
		check(GameState.get_soft_currency() == initial_balance + total, "Late reward and repeated base claim do not add coins")
		GameState.load_game()
		check(GameState.get_soft_currency() == initial_balance + total, "Reload keeps the exact multiplied total")
		check(int(GameState.claim_active_single_player_stage_reward(true).get("amount", 0)) == 0, "Reload cannot pay the saved base again")

func run() -> void:
	Engine.time_scale = 8.0
	GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
	GameState.guided_onboarding_completed = true
	GameState.ad_personalization_choice = GameState.AdPersonalizationChoice.ACCEPTED
	get_window().min_size = Vector2i(960, 1600)
	get_window().size = Vector2i(960, 1600)
	Database.load_languages("ru", "ru")
	await check_stage_multiplier_totals()
	await fixture(4)
	check(!is_instance_valid(ui._portrait_stage_reward.multiplier_meter) and ui._portrait_stage_reward.selected_multiplier() == 2.0, "Fourth level keeps fixed doubling")
	var early_request: String = start()
	check(int(GameState.rewarded_double_requests[early_request].get("amount", 0)) == 25, "Early doubling records exactly one base amount as bonus")
	var early_balance: int = GameState.get_soft_currency()
	ads._on_rewarded_video_ad_loaded()
	await frames()
	ads._on_rewarded_for_request(early_request, "coins", 25)
	check(GameState.get_soft_currency() == early_balance + 25, "Early x2 keeps its original one-base bonus")
	for label: Node in get_tree().get_nodes_in_group(&"soft_currency_balance_label"):
		check(label.text == ui._soft_currency_balance_text(early_balance + 25), "Early x2 keeps the original immediate HUD update before ad close")
	ads._on_rewarded_closed_for_request(early_request)
	await frames()
	check(ui.collection_amounts == [25] and ui._portrait_stage_reward.deferred_coin_amount == 0, "Early x2 animates only its bonus after the already presented base")
	await fixture()
	var meter: Control = ui._portrait_stage_reward.multiplier_meter
	var request := start()
	meter.running = true
	meter._process(0.3)
	check(is_equal_approx(meter.cursor, 0.3), "Multiplier freezes while advertisement is pending")
	meter.running = false
	var guard: Node = ui._portrait_reward_load_guard
	check(guard.expires_at_msec - Time.get_ticks_msec() > 11000, "Production timeout is twelve monotonic seconds")
	guard.expires_at_msec = Time.get_ticks_msec() - 1
	await frames()
	check(!ads._rewarded_pending_show and !ui._portrait_final_reward_waiting_for_ad and !GameState._fullscreen_ad_active, "Silence timeout clears pending show and UI lock")
	check(!ui._portrait_final_reward_double_button.get("button_disabled") and ui.toasts == 1, "Timeout restores x2 and displays one standard toast")
	check(!GameState.rewarded_double_requests.has(request), "Timeout cancels the unearned persistent receipt")
	var before := GameState.get_soft_currency()
	ads._on_rewarded_video_ad_loaded()
	ads._on_rewarded_for_request(request, "coins", 25)
	await frames()
	check(native.shows == 0 and GameState.get_soft_currency() == before, "Late load and reward cannot revive or pay a cancelled request")
	ui._decline_single_player_stage_coin_reward_double()
	check(ui.declines == 1, "No Thanks works after timeout")
	await fixture()
	request = start()
	var collect: Control = ui._portrait_stage_reward.collect
	check(collect != null and !bool(collect.get("button_disabled")), "No Thanks stays clickable while x2 is loading")
	collect.pressed.emit()
	check(ui.declines == 1 and !ui._portrait_final_reward_waiting_for_ad and !ads._rewarded_pending_show and ui.toasts == 0, "No Thanks immediately cancels loading and continues silently")
	check(!GameState.rewarded_double_requests.has(request), "Immediate decline cancels the unearned receipt")
	before = GameState.get_soft_currency()
	ads._on_rewarded_video_ad_loaded()
	ads._on_rewarded_for_request(request, "coins", 25)
	await frames()
	check(native.shows == 0 and GameState.get_soft_currency() == before, "Late load after immediate decline cannot show or grant a bonus")

	await fixture()
	request = start()
	ui._portrait_reward_load_guard.expires_at_msec = Time.get_ticks_msec() - 1
	ads._on_rewarded_video_ad_loaded()
	await frames()
	check(native.shows == 0 and !ui._portrait_final_reward_waiting_for_ad, "Validator rejects load arriving at the expired deadline before polling")
	ui._portrait_stage_reward.multiplier_meter.set_cursor(0.5)
	ui._on_final_reward_double_pressed()
	request = ui._portrait_reward_ad_request_id
	check(int(GameState.rewarded_double_requests[request].amount) == 50, "Real button captures x3 as a 50-coin bonus for a paid 25-coin stage")
	ui._portrait_stage_reward.multiplier_meter.set_cursor(0.1)
	check(native.shows == 1 and ads._rewarded_show_open, "Explicit retry starts the cached late ad")
	ui._portrait_reward_load_guard.expires_at_msec = Time.get_ticks_msec() - 1
	await frames()
	check(ads._rewarded_show_open and ui._portrait_final_reward_waiting_for_ad and ui.toasts == 1, "Expiry never cancels an already open ad")
	before = GameState.get_soft_currency()
	ads._on_rewarded_for_request(request, "coins", 25)
	ads._on_rewarded_for_request(request, "coins", 25)
	ads._on_rewarded_closed_for_request(request)
	check(GameState.get_soft_currency() == before + 50 and !ui._portrait_final_reward_waiting_for_ad, "Normal show grants captured x3 once despite subsequent cursor changes and releases UI")
	await frames()
	check(ui.collection_amounts == [75], "Closing a successful x3 ad animates base plus bonus exactly once")
	await fixture()
	request = start()
	ui._clear()
	check(!ads._rewarded_pending_show and !ui._portrait_final_reward_waiting_for_ad and ui.toasts == 0, "Navigation silently cancels pending x2 immediately")
	ads._on_rewarded_video_ad_loaded()
	await frames()
	check(native.shows == 0 and !GameState.rewarded_double_requests.has(request), "Late callback after navigation never starts an ad")
	await fixture()
	GameState.pending_single_player_reward = {"amount": 50, "claimed": true, "double_resolved": false, "double_claimed": false, "language": Database.current_language, "level_index": 4}
	ui._portrait_reward_double_context = &"final"
	request = start()
	ui._portrait_reward_load_guard.expires_at_msec = Time.get_ticks_msec() - 1
	await frames()
	check(!ui._portrait_final_reward_waiting_for_ad and !GameState.rewarded_double_requests.has(request), "Whole-level prize uses the same timeout and receipt cancellation")
	var next_request := start()
	ui._on_final_reward_ad_failed_to_show(request, "Old callback")
	check(ui._portrait_reward_ad_request_id == next_request and ui._portrait_final_reward_waiting_for_ad and ads.is_rewarded_request_pending(next_request), "Old cancellation cannot unlock or cancel a newer attempt")
	for next_theme: bool in [false, true]:
		await fixture()
		GameState.pending_single_player_reward = {"amount": 50, "claimed": true, "double_resolved": false, "double_claimed": false, "language": Database.current_language, "level_index": 4}
		ui._portrait_reward_double_context = &"final"
		ui._portrait_final_reward_claim_in_progress = true
		request = start()
		if next_theme:
			ui._claim_single_player_final_reward_and_open_next_theme(5)
		else:
			ui._claim_single_player_final_reward()
		check(ui.final_exits == 1 and ui.next_level == (5 if next_theme else -1), "Main-prize decline follows the requested exit immediately")
		check(!ads._rewarded_pending_show and !ui._portrait_final_reward_waiting_for_ad and ui.toasts == 0 and !GameState.rewarded_double_requests.has(request), "Both main-prize decline paths silently cancel pending advertising")
		ads._on_rewarded_video_ad_loaded()
		await frames()
		check(native.shows == 0, "Main-prize exit prevents a late automatic ad")
	await fixture()
	request = start()
	ui.queue_free()
	await frames()
	check(!ads._rewarded_pending_show and !GameState.rewarded_double_requests.has(request), "Owner teardown cancels its pending load")
	ads.queue_free()
	await frames()
	print("REWARDED_DOUBLE_TIMEOUT ", JSON.stringify({"checks": checks, "failures": failures}))
	get_tree().quit(0 if failures.is_empty() else 1)
