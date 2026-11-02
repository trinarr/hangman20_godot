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
func fixture(level_number: int = 5) -> void:
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
	ui.single_player_active_level_index = level_number - 1
	ui.single_player_active_word_slot = 0
	ui.last_result_data = {"single_player_level_index": level_number - 1, "single_player_word_slot": 0, "single_player_total_count": 2, "single_player_level_completed": false}
	ui._show_single_player_reward_chain_screen()
	var initial_collect := ui.find_child("FinalRewardCollectButton", true, false) as Button
	check(initial_collect != null and initial_collect.disabled, "No Thanks remains unavailable during the original introduction delay")
	await get_tree().create_timer(6.0).timeout
	check(is_instance_valid(ui._portrait_final_reward_double_button) and !ui._portrait_final_reward_double_button.get("button_disabled"), "Fixture reveals the real stage x2 button")
	check(ui._portrait_final_reward_double_button.get("button_text") == tr("REWARD_GET" if level_number >= 5 else "REWARD_GET_X2").to_upper(), "Stage ad action uses the requested localized caption")
	var meter: Control = ui._portrait_stage_reward.multiplier_meter
	if is_instance_valid(meter):
		meter.running = false
		meter.set_cursor(0.3)

func run() -> void:
	pass
