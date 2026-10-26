extends Node
class NativeAds extends RefCounted:
	var shows: int = 0
	func loadRewardedVideo(_id: String) -> void: pass
	func showRewardedVideoForRequest(_id: String) -> void: shows += 1
	func hideBanner() -> void: pass
	func removeBanner() -> void: pass
class Ads extends "res://addons/GodotAndroidYandexAds/yandex_ads.gd":
	func _enter_tree() -> void: pass
class UI extends "res://scripts/main_portrait.gd":
	var ads: Node
	var toasts: int = 0
	var declines: int = 0
	var final_exits: int = 0
	var next_level: int = -1
	func _ready() -> void:
		_build_root()
		_clear()
	func _portrait_ads_service() -> Node: return ads
	func _portrait_ads_enabled() -> bool: return true
	func _stage_portrait_ad_banner(_source: String = "unspecified") -> void: pass
	func _should_auto_resume_guided_single_player() -> bool: return false
	func _single_player_stage_is_quiz(_level: int, _slot: int) -> bool: return true
	func _show_portrait_ad_not_ready_toast() -> void:
		toasts += 1
		super._show_portrait_ad_not_ready_toast()
	func _finish_single_player_stage_coin_reward_offer() -> void:
		declines += 1
	func _finish_single_player_final_reward_claim(next_theme_level_index: int = -1, _force_home: bool = false) -> void:
		final_exits += 1
		next_level = next_theme_level_index

var checks: int = 0
var failures: Array[String] = []
var ui: UI
var ads: Ads
var native: NativeAds
func check(ok: bool, message: String) -> void:
	checks += 1
	if !ok:
		failures.append(message)
		push_error(message)
func _ready() -> void: run.call_deferred()
func _process(_delta: float) -> void:
	if DisplayServer.get_name() == "headless":
		RenderingServer.frame_post_draw.emit()
	elif OS.get_environment("HANGMAN_TEST_HIDE_WINDOW") == "1":
		RenderingServer.force_draw(false)
func frames() -> void:
	for _i in range(4):
		await get_tree().process_frame
func capture(tag: String) -> void:
	var directory := OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
	if !directory.is_empty() and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(directory.path_join(tag + ".png"))
func fixture() -> void:
	if is_instance_valid(ui):
		ui.queue_free()
		await frames()
	if is_instance_valid(ads):
		ads.queue_free()
		await frames()
	GameState.set_fullscreen_ad_active(false)
	GameState.rewarded_double_requests.clear()
	GameState.pending_single_player_reward = {}
	GameState.current_mode = GameState.GameMode.SINGLE_PLAYER
	GameState.active_single_player_session = {"kind": "next", "data": {"reward_currency": GameState.STAGE_REWARD_COINS, "reward_amount": 25, "reward_claimed": false, "reward_double_resolved": false, "reward_double_claimed": false}}
	ads = Ads.new()
	native = NativeAds.new()
	ads._native = native
	ads._sdk_ready = true
	add_child(ads)
	ui = UI.new()
	ui.ads = ads
	add_child(ui)
	ui.last_result_is_win = true
	ui.single_player_active_level_index = 4
	ui.single_player_active_word_slot = 0
	ui.last_result_data = {"single_player_level_index": 4, "single_player_word_slot": 0, "single_player_total_count": 2, "single_player_level_completed": false}
	ui._show_single_player_reward_chain_screen()
	await get_tree().create_timer(6.0).timeout
	check(is_instance_valid(ui._portrait_final_reward_double_button) and !ui._portrait_final_reward_double_button.get("button_disabled"), "Fixture reveals the real stage x2 button")
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
	for size: Vector2i in [Vector2i(960, 1600), Vector2i(690, 1536)]:
		get_window().min_size = size
		get_window().size = size
		for language: String in ["ru", "en"]:
			Database.load_languages(language, language)
			await fixture()
			var request := start()
			var guard: Node = ui._portrait_reward_load_guard
			check(guard.expires_at_msec - Time.get_ticks_msec() > 11000, "Production timeout is twelve monotonic seconds")
			await capture("x2_waiting_%dx%d_%s" % [size.x, size.y, language])
			guard.expires_at_msec = Time.get_ticks_msec() - 1
			await frames()
			check(!ads._rewarded_pending_show and !ui._portrait_final_reward_waiting_for_ad and !GameState._fullscreen_ad_active, "Silence timeout clears pending show and UI lock")
			check(!ui._portrait_final_reward_double_button.get("button_disabled") and ui.toasts == 1, "Timeout restores x2 and displays one standard toast")
			check(!GameState.rewarded_double_requests.has(request), "Timeout cancels the unearned persistent receipt")
			await capture("x2_timeout_%dx%d_%s" % [size.x, size.y, language])
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
	var request := start()
	ui._portrait_reward_load_guard.expires_at_msec = Time.get_ticks_msec() - 1
	ads._on_rewarded_video_ad_loaded()
	await frames()
	check(native.shows == 0 and !ui._portrait_final_reward_waiting_for_ad, "Validator rejects load arriving at the expired deadline before polling")
	ui._on_final_reward_double_pressed()
	request = ui._portrait_reward_ad_request_id
	check(native.shows == 1 and ads._rewarded_show_open, "Explicit retry starts the cached late ad")
	ui._portrait_reward_load_guard.expires_at_msec = Time.get_ticks_msec() - 1
	await frames()
	check(ads._rewarded_show_open and ui._portrait_final_reward_waiting_for_ad and ui.toasts == 1, "Expiry never cancels an already open ad")
	var before := GameState.get_soft_currency()
	ads._on_rewarded_for_request(request, "coins", 25)
	ads._on_rewarded_for_request(request, "coins", 25)
	ads._on_rewarded_closed_for_request(request)
	check(GameState.get_soft_currency() == before + 25 and !ui._portrait_final_reward_waiting_for_ad, "Normal show grants the bonus once and releases UI")
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
