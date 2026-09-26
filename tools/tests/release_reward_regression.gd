extends Node
# Run with a disposable user-data directory:
# XDG_DATA_HOME=/tmp/hangman-tests godot --headless --path . res://tools/tests/release_reward_regression.tscn

class TestUI:
	extends "res://scripts/main_portrait.gd"
	var test_ads: Node
	func _portrait_ads_service() -> Node:
		return test_ads
	func _portrait_ads_enabled() -> bool:
		return test_ads != null
	func _ready() -> void:
		pass
	func _remove_single_player_last_chance_popup() -> void:
		pass
	func _clear_hero_animation_overlay() -> void:
		pass
	func _show_portrait_ad_not_ready_toast() -> void:
		pass

class NativeAds:
	extends RefCounted
	var interstitial_shows: int = 0
	var rewarded_shows: int = 0
	func loadInterstitial(_id: String) -> void:
		pass
	func showInterstitial() -> void:
		interstitial_shows += 1
	func loadRewardedVideo(_id: String) -> void:
		pass
	func showRewardedVideoForRequest(_id: String) -> void:
		rewarded_shows += 1
	func removeBanner() -> void:
		pass

class TestAds:
	extends "res://addons/GodotAndroidYandexAds/yandex_ads.gd"
	func _enter_tree() -> void:
		pass
	func is_native_available() -> bool:
		return _native != null

class CountedState:
	extends "res://scripts/core/game_state.gd"
	var commits: int = 0
	func _home_profile_save_game() -> bool:
		commits += 1
		return true

var failures: int = 0
var checks: int = 0

func check(value: bool, label: String) -> void:
	checks += 1
	if !value:
		failures += 1
		push_error("FAIL: " + label)
	else:
		print("PASS: " + label)

func _ready() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	var root: Node = get_tree().root
	var ui := TestUI.new()
	root.add_child(ui)
	GameSession.changed.connect(ui._persist_active_single_player_word_session)
	GameState.rewarded_action_requests.clear()
	GameState.current_mode = GameState.GameMode.SINGLE_PLAYER
	ui.single_player_active_level_index = 4
	ui.single_player_active_word_slot = 0
	GameSession.start_round(WordData.new("TEST", 0.3, 0, 0), GameState.GameMode.SINGLE_PLAYER)
	GameSession.mistakes = 5
	GameSession.loss_deferred = true
	ui._advance_single_player_extra_attempt_offer()
	ui._advance_single_player_extra_attempt_offer()
	ui._advance_single_player_extra_attempt_offer()
	var saved: Dictionary = GameState.get_active_single_player_session()["data"].duplicate(true)
	check(int(saved["attempt_offer_cost"]) == 60 and int(saved["attempt_offer_size"]) == 4, "save escalating offer 60 / 4")
	ui._reset_single_player_extra_attempt_offers()
	ui._restore_attempt_offer(saved)
	check(GameSession.restore_from_save_data(saved), "restore saved round")
	check(ui._single_player_extra_attempt_cost() == 60 and ui._single_player_extra_attempt_count() == 4, "restore offer before changed signal")
	check(ui._advance_single_player_extra_attempt_offer() == 70, "next offer continues at 70")
	check(GameSession.round_id == str(saved["round_id"]), "round identity survives restore")

	var context: Dictionary = ui._action_reward_context(&"extra_attempt", -1)
	var request_id: String = GameState.begin_rewarded_action_request("extra_attempt", context)
	ui._portrait_rewarded_request_id = request_id
	ui._portrait_rewarded_action = &"extra_attempt"
	ui._on_action_request_closed(request_id)
	check(GameState.rewarded_action_requests.has(request_id), "close retains unconfirmed receipt")
	var before_views: int = GameState.extra_attempt_ad_views_remaining
	ui._on_action_request_rewarded(request_id, "", 1)
	check(!GameSession.has_deferred_loss() and GameSession.get_remaining_attempts() == 5, "close-before-reward grants original attempt bundle")
	check(GameState.extra_attempt_ad_views_remaining == before_views - 1, "attempt quota consumed once")
	ui._on_action_request_rewarded(request_id, "", 1)
	check(GameState.extra_attempt_ad_views_remaining == before_views - 1, "duplicate callback ignored")

	GameSession.open_hint_used = true
	GameSession.open_hint_ad_reuse_available = true
	request_id = GameState.begin_rewarded_action_request("hint_open", ui._action_reward_context(&"hint_open", -1))
	var old_round: String = GameSession.round_id
	GameSession.start_round(WordData.new("WORD", 0.3, 0, 0), GameState.GameMode.SINGLE_PLAYER)
	var revealed_before: Array = GameSession.revealed.duplicate()
	var hints_before: int = GameState.get_hint_count(GameState.HINT_OPEN_LETTER)
	ui._on_action_request_rewarded(request_id, "", 1)
	check(GameSession.round_id != old_round and GameSession.revealed == revealed_before, "late hint does not alter another word")
	check(GameState.get_hint_count(GameState.HINT_OPEN_LETTER) == hints_before + 1, "late hint preserved in inventory")
	ui._on_action_request_rewarded(request_id, "", 1)
	check(GameState.get_hint_count(GameState.HINT_OPEN_LETTER) == hints_before + 1, "inventory grant is idempotent")

	var before_coins: int = GameState.get_soft_currency()
	var before_stars: int = GameState.get_stars()
	GameState.current_mode = GameState.GameMode.TWO_PLAYER
	GameSession.start_custom_round("TEST")
	var result: Dictionary = GameSession.finish_result(true, true)
	ui._grant_remaining_attempt_star_reward(result, true)
	check(GameState.get_soft_currency() == before_coins and GameState.get_stars() == before_stars, "two-player awards no currency even with award flag")
	check(Array(result["lines"]).is_empty(), "two-player result does not promise coins")

	GameState.coin_refill_ad_views_remaining = 5
	GameState.coin_refill_ad_cooldown_until = 0
	request_id = GameState.begin_rewarded_action_request("coin_refill", {})
	GameState.rewarded_action_requests[request_id]["earned"] = true
	GameState.save_game()
	GameState.rewarded_action_requests.clear()
	GameState.load_game()
	check(GameState.rewarded_action_requests.has(request_id), "earned receipt survives save/load")
	ui._retry_action_rewards()
	check(GameState.get_soft_currency() == before_coins + 50, "recovered receipt awards exactly 50")
	GameState.load_game()
	ui._on_action_request_rewarded(request_id, "", 1)
	check(GameState.get_soft_currency() == before_coins + 50, "consumed receipt stays consumed after reload")

	var counted := CountedState.new()
	counted.begin_save_batch()
	for i: int in range(16):
		counted.reset_single_level_attempt("en", 4, true, false)
		counted.get_or_create_single_level_seed("en", 4)
	check(counted.commits == 0, "no disk writes while exploring 16 variants")
	counted.end_save_batch()
	check(counted.commits == 1, "one final commit for theme search")
	counted.free()

	var ads := TestAds.new()
	var native := NativeAds.new()
	ads._native = native
	ads._sdk_ready = true
	ads.interstitial_id = "test-interstitial"
	ads.rewarded_id = "test-rewarded"
	root.add_child(ads)
	check(!ads.show_interstitial(), "unloaded interstitial does not block navigation")
	ads._on_interstitial_loaded()
	await get_tree().process_frame
	check(native.interstitial_shows == 0, "late interstitial load does not auto-show")
	check(ads.show_interstitial() and native.interstitial_shows == 1, "ready interstitial shows")
	check(ads.show_rewarded_video("cancelled"), "rewarded can wait for load")
	ads._on_rewarded_video_ad_loaded()
	check(ads.cancel_pending_rewarded_request("cancelled"), "pending rewarded cancelled")
	await get_tree().process_frame
	check(native.rewarded_shows == 0, "queued callback cannot revive cancelled show")
	check(!ads.show_rewarded_video("invalid", &"", func() -> bool: return false), "context validated immediately before native show")
	check(native.rewarded_shows == 0, "invalid context never reaches SDK")
	check(ads.show_rewarded_video("valid", &"", func() -> bool: return true), "valid rewarded starts")
	check(native.rewarded_shows == 1, "exactly one native rewarded show")
	ads._on_rewarded_closed_for_request("valid")
	ads._rewarded_loaded = true
	ads._rewarded_loaded_id = ads.rewarded_id
	ui.test_ads = ads
	GameState.current_mode = GameState.GameMode.SINGLE_PLAYER
	GameSession.start_round(WordData.new("TEST", 0.3, 0, 0), GameState.GameMode.SINGLE_PLAYER)
	GameSession.open_hint_used = true
	GameSession.open_hint_ad_reuse_available = true
	var origin := Control.new()
	ui.add_child(origin)
	ui._portrait_game_input_group = origin
	check(ui._show_portrait_rewarded_action(&"hint_open"), "UI creates tagged rewarded request")
	var first_request: String = ui._portrait_rewarded_request_id
	if ads.is_rewarded_request_pending(first_request):
		ads._on_rewarded_video_ad_loaded()
		await get_tree().process_frame
	ads._on_rewarded_closed_for_request(first_request)
	check(ui._portrait_rewarded_request_id.is_empty(), "tagged close releases UI")
	ads._on_rewarded_for_request(first_request, "", 1)
	check(!GameSession.open_hint_ad_reuse_available, "tagged late callback reaches original hint")
	var after_hint: Array = GameSession.revealed.duplicate()
	ads._on_rewarded_for_request(first_request, "", 1)
	check(GameSession.revealed == after_hint, "tagged duplicate cannot reveal another letter")

	GameSession.open_hint_ad_reuse_available = true
	check(ui._show_portrait_rewarded_action(&"hint_open"), "second UI request can load")
	var second_request: String = ui._portrait_rewarded_request_id
	ui._on_action_request_closed(first_request)
	check(ui._portrait_rewarded_request_id == second_request, "old close cannot clear newer request")
	ui._portrait_rewarded_request_started_msec -= 12001
	check(!ui._action_request_can_show(second_request), "12-second wait expires")
	ads._on_rewarded_video_ad_loaded()
	await get_tree().process_frame
	check(!ads._rewarded_pending_show and ui._portrait_rewarded_request_id.is_empty(), "expired load releases pending request and UI")
	check(!GameState.rewarded_action_requests.has(second_request), "cancelled load removes unearned receipt")

	before_coins = GameState.get_soft_currency()
	request_id = GameState.begin_rewarded_action_request("coin_refill", {})
	GameState._save_blocked_by_future_version = true
	ui._on_action_request_rewarded(request_id, "", 1)
	check(GameState.get_soft_currency() == before_coins and GameState.rewarded_action_requests.has(request_id), "save failure retains earned receipt without crediting")
	GameState._save_blocked_by_future_version = false
	ui._retry_action_rewards()
	check(GameState.get_soft_currency() == before_coins + 50 and !GameState.rewarded_action_requests.has(request_id), "retry credits retained receipt once")
	before_coins = GameState.get_soft_currency()
	request_id = GameState.begin_rewarded_action_request("coin_refill", {})
	GameState.coin_refill_ad_views_remaining = 0
	GameState.coin_refill_ad_cooldown_until = int(Time.get_unix_time_from_system()) + 3600
	var cooldown: int = GameState.coin_refill_ad_cooldown_until
	ui._on_action_request_rewarded(request_id, "", 1)
	check(GameState.get_soft_currency() == before_coins + 50, "earned reward honoured after quota runs out")
	check(GameState.coin_refill_ad_views_remaining == 0 and GameState.coin_refill_ad_cooldown_until == cooldown, "late grant neither makes quota negative nor extends cooldown")
	await get_tree().create_timer(2.1).timeout
	ads.free()
	ui.free()
	print("RESULT: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)
