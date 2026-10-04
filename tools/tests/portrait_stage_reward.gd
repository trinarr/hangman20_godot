extends Node

class TestUI:
	extends "res://scripts/main_portrait.gd"
	var ads_enabled: bool = false
	var claims: int = 0
	var claim_scale: float = 0.0
	var doubles: int = 0
	func _ready() -> void:
		_build_root()
		_clear()
	func _portrait_ads_enabled() -> bool:
		return ads_enabled
	func _portrait_ads_service() -> Node:
		return null
	func _single_player_stage_is_quiz(_level: int, _slot: int) -> bool:
		return true
	func _play_early_stage_coin_reward_claim(source: Control) -> void:
		claims += 1
		claim_scale = source.scale.x
		super._play_early_stage_coin_reward_claim(source)
	func _on_final_reward_double_pressed() -> void:
		doubles += 1

var main: TestUI
var checks: int = 0
var failures: Array[String] = []
var signatures: Dictionary = {}
var standalone_claims: int = 0
var standalone_doubles: int = 0
var standalone_continues: int = 0

func check(value: bool, label: String) -> void:
	checks += 1
	if !value:
		failures.append(label)

func snapshot(node: Node) -> Dictionary:
	var result: Dictionary = {"class": node.get_class()}
	if node is Control:
		result.merge({"position": str(node.position), "size": str(node.size),
			"scale": str(node.scale), "z": node.z_index, "visible": node.visible,
			"mouse": node.mouse_filter, "modulate": str(node.modulate)})
	if node is Label:
		result.merge({"text": node.text, "font_size": node.get_theme_font_size("font_size"), "font_color": str(node.get_theme_color("font_color"))})
	if node is TextureRect:
		result["texture"] = node.texture.resource_path if node.texture != null else ""
	if node is FlashStageControl or node is FlashStageTextureButton:
		result["rect"] = str(node.get("stage_rect"))
	if node is FlashStageTextureButton:
		result["disabled"] = node.disabled
		result["visual_scale"] = str(node.visual_scale)
	var children: Array = []
	for child: Node in node.get_children():
		children.append(snapshot(child))
	result["children"] = children
	return result

func signature() -> String:
	var pack: Control = main.content.find_child("StageCoinLargeReward", true, false)
	var label: Label = main.content.find_child("StageCoinLargeRewardAmount", true, false)
	var button: Control = main.content.find_child("StageCoinRewardDoubleButton" if main.ads_enabled else "StageCoinRewardContinueButton", true, false)
	button.set("attention_bounce_enabled", false)
	button.set("visual_scale", Vector2.ONE)
	var objects: Array = [snapshot(pack), snapshot(label.get_parent()), snapshot(button)]
	if main.ads_enabled:
		objects.append(snapshot(main.content.find_child("FinalRewardCollectText", true, false)))
	return JSON.stringify(objects).sha256_text()

func fixture(ads: bool, completed: bool = false, count: int = 2) -> void:
	GameState.current_mode = GameState.GameMode.SINGLE_PLAYER
	GameState.active_single_player_session = {"kind": "next", "data": {"reward_currency": GameState.STAGE_REWARD_COINS, "reward_amount": 25,
		"reward_claimed": false, "reward_double_resolved": false, "reward_double_claimed": false}}
	main.ads_enabled = ads
	main.last_result_is_win = true
	main.single_player_active_level_index = 4
	main.single_player_active_word_slot = 0
	main.last_result_data = {"single_player_level_index": 4, "single_player_word_slot": 0,
		"single_player_total_count": count, "single_player_level_completed": completed}
	main._show_single_player_reward_chain_screen()

func _standalone_claim(_source: Control) -> void:
	standalone_claims += 1

func _standalone_double() -> void:
	standalone_doubles += 1

func _standalone_continue() -> void:
	standalone_continues += 1

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	GameState.ad_personalization_choice = GameState.AdPersonalizationChoice.ACCEPTED
	main = TestUI.new()
	add_child(main)
	for ads: bool in [false, true]:
		var before: int = GameState.get_soft_currency()
		var claims_before: int = main.claims
		fixture(ads)
		check(bool(GameState.get_active_single_player_stage_reward().get("presentation_started", false)), "stage presentation marker is saved before intro")
		check(GameState.get_soft_currency() == before and main.claims == claims_before, "building screen does not grant reward")
		var button: Control = main.content.find_child("StageCoinRewardDoubleButton" if ads else "StageCoinRewardContinueButton", true, false)
		check(button != null and bool(button.get("button_disabled")), "action blocked during intro")
		await get_tree().create_timer(5.0).timeout
		check(main.claims == claims_before + 1 and GameState.get_soft_currency() == before + 25, "one base reward granted during presentation")
		check(main.claim_scale > 1.0 and bool(GameState.get_active_single_player_stage_reward().get("claimed", false)), "peak callback grants and persists reward")
		check(!bool(button.get("button_disabled")) and is_equal_approx(button.modulate.a, 1.0), "action enabled after intro")
		var pack: Control = main.content.find_child("StageCoinLargeReward", true, false)
		check(pack.get_meta("main_reward_icon_shadow_layers", []).size() == 4, "large coin pack keeps extrusion shadow")
		signatures["ads" if ads else "continue"] = signature()
		if ads:
			button.emit_signal("pressed")
			check(main.doubles == 1, "double action reaches ad controller")
			var collect: Button = main.content.find_child("FinalRewardCollectButton", true, false)
			check(collect != null and !collect.disabled and collect.mouse_filter == Control.MOUSE_FILTER_STOP, "no thanks appears after delay")
			collect.emit_signal("pressed")
		else:
			button.emit_signal("pressed")
		check(GameState.get_soft_currency() == before + 25, "continue never credits base twice")
		check(bool(GameState.get_active_single_player_stage_reward().get("double_resolved", false)), "decline persists choice")
		await get_tree().process_frame
		check(main.content.find_child("StageCoinLargeReward", true, false) == null, "resolved offer returns to ordinary chain")
	# Interruption before peak keeps durable presentation intent, then restore settles it once.
	var before: int = GameState.get_soft_currency()
	var claims_before: int = main.claims
	fixture(false)
	main._clear()
	await get_tree().create_timer(1.0).timeout
	check(GameState.get_soft_currency() == before and main.claims == claims_before, "closing before peak cancels presentation callback")
	var settled: Dictionary = GameState.settle_presented_active_single_player_stage_reward(false)
	check(int(settled.get("amount", 0)) == 25 and GameState.get_soft_currency() == before + 25, "restore settles saved presentation exactly once")
	GameState.settle_presented_active_single_player_stage_reward(false)
	check(GameState.get_soft_currency() == before + 25, "repeat restore does not duplicate reward")
	# Single-stage completion and normal last-stage completion share the same offer.
	fixture(false, true, 1)
	check(main.content.find_child("StageCoinLargeReward", true, false) != null, "one-stage level uses large stage reward")
	main._clear()
	# Level rewards use the shared prize visuals too: keep their claim sequence intact.
	GameState.active_single_player_session = {}
	GameState.pending_single_player_reward = GameState._normalize_pending_single_player_reward({
		"language": Database.current_language, "level_index": 4, "word_count": 3,
		"amount": 35, "stars_amount": 10})
	var coins_before_summary: int = GameState.get_soft_currency()
	var stars_before_summary: int = GameState.get_stars()
	main.last_result_is_win = true
	main.last_result_data = {"single_player_level_index": 4, "single_player_word_slot": 2,
		"single_player_total_count": 3, "single_player_level_completed": true, "single_player_level_summary_view": true}
	main.ads_enabled = false
	main._portrait_single_reward_resume_without_intro = true
	main._show_single_player_reward_chain_screen()
	await get_tree().create_timer(7.0).timeout
	check(GameState.get_soft_currency() == coins_before_summary + 35 and GameState.get_stars() == stars_before_summary + 10, "shared visuals preserve level coin/star grants")
	check(bool(GameState.pending_single_player_reward.get("claimed", false)) and bool(GameState.pending_single_player_reward.get("stars_claimed", false)), "level claim flags stay durable")
	check(main.content.find_child("SinglePlayerRewardHeroViewport", true, false) == null, "level summary still omits hero viewport")
	main._clear()
	# Standalone presentation has no dependency on the gameplay adapter.
	var parent := Control.new()
	parent.theme = main.ui.theme
	add_child(parent)
	var component := preload("res://scripts/ui/portrait_stage_reward.gd").new()
	parent.add_child(component)
	component.claim_peak.connect(_standalone_claim)
	component.double_requested.connect(_standalone_double)
	component.continue_requested.connect(_standalone_continue)
	var source_rect := Rect2(180, 380, 120, 120)
	component.build(parent, 25, source_rect, true)
	var child_count: int = parent.get_child_count()
	component.build(parent, 25, source_rect, true)
	check(parent.get_child_count() == child_count, "duplicate build is ignored")
	var chain := Control.new()
	parent.add_child(chain)
	var source := Control.new()
	chain.add_child(source)
	var count_label := Label.new()
	chain.add_child(count_label)
	main.queue_free()
	await get_tree().process_frame
	var balances: Vector2i = Vector2i(GameState.get_soft_currency(), GameState.get_stars())
	component.begin_transition(chain, null, source,
		count_label, component.prize, null, null, component.prize_glow,
		component.prize_amount, component.action, component.collect, component.collect_hit)
	component.begin_transition(chain, null, source,
		count_label, component.prize, null, null, component.prize_glow,
		component.prize_amount, component.action, component.collect, component.collect_hit)
	await get_tree().create_timer(3.0).timeout
	check(standalone_claims == 1, "standalone transition emits one peak intent after adapter deletion")
	check(!bool(component.action.get("button_disabled")) and !component.collect_hit.disabled, "standalone actions become available")
	component._on_claim_peak(component.prize)
	check(standalone_claims == 1, "repeat peak does not repeat claim intent")
	component.action.emit_signal("pressed")
	component.collect_hit.emit_signal("pressed")
	check(standalone_doubles == 1 and standalone_continues == 1, "standalone actions emit intents")
	check(Vector2i(GameState.get_soft_currency(), GameState.get_stars()) == balances, "standalone component never changes balances")
	component.stop()
	component.action.emit_signal("pressed")
	component.collect_hit.emit_signal("pressed")
	check(standalone_doubles == 1 and standalone_continues == 1, "stopped presentation ignores actions")
	check(component._animations.is_empty(), "stop cancels all stage animations")
	parent.queue_free()
	print("PORTRAIT_STAGE_REWARD " + JSON.stringify({"checks": checks, "failures": failures, "signatures": signatures}))
	await get_tree().process_frame
	get_tree().quit(0 if failures.is_empty() else 1)
