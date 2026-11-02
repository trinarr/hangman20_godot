extends "res://tools/tests/rewarded_stage_fixture.gd"
## Advertising lifecycle in one representative language and viewport.

func start() -> String:
	ui._on_final_reward_double_pressed()
	check(ads._rewarded_pending_show and ui._portrait_final_reward_waiting_for_ad, "Unloaded x2 waits for the native SDK")
	check(ui._portrait_final_reward_double_button.get("button_disabled"), "Waiting x2 is disabled")
	return ui._portrait_reward_ad_request_id
func run() -> void:
	Engine.time_scale = 8.0
	GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
	GameState.guided_onboarding_completed = true
	GameState.ad_personalization_choice = GameState.AdPersonalizationChoice.ACCEPTED
	get_window().min_size = Vector2i(960, 1600)
	get_window().size = Vector2i(960, 1600)
	Database.load_languages("ru", "ru")
	await fixture(4)
	check(!is_instance_valid(ui._portrait_stage_reward.multiplier_meter) and ui._portrait_stage_reward.selected_multiplier() == 2.0, "Fourth level keeps fixed doubling")
	var early_request: String = start()
	check(int(GameState.rewarded_double_requests[early_request].get("amount", 0)) == 25, "Early doubling records exactly one base amount as bonus")
	ui._decline_single_player_stage_coin_reward_double()
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
	var collect := ui.find_child("FinalRewardCollectButton", true, false) as Button
	check(collect != null and !collect.disabled, "No Thanks stays clickable while x2 is loading")
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
