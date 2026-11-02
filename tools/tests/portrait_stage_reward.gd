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

func fixture(ads: bool, completed: bool = false, count: int = 2, level_number: int = 5) -> void:
	GameState.current_mode = GameState.GameMode.SINGLE_PLAYER
	GameState.active_single_player_session = {"kind": "next", "data": {"reward_currency": GameState.STAGE_REWARD_COINS, "reward_amount": 25,
		"reward_claimed": false, "reward_double_resolved": false, "reward_double_claimed": false}}
	main.ads_enabled = ads
	main.last_result_is_win = true
	main.single_player_active_level_index = level_number - 1
	main.single_player_active_word_slot = 0
	main.last_result_data = {"single_player_level_index": level_number - 1, "single_player_word_slot": 0,
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
	for level_number: int in [1, 4, 5, 6]:
		fixture(true, false, 2, level_number)
		var component: Node = main._portrait_stage_reward
		var use_meter: bool = level_number >= 5
		check(is_instance_valid(component.multiplier_meter) == use_meter, "Multiplier meter starts with level five: %d" % level_number)
		check(component.action.get("button_text") == tr("REWARD_GET" if use_meter else "REWARD_GET_X2").to_upper(), "Stage caption matches its reward approach: %d" % level_number)
		check((component.action.get("trailing_icon_texture") == null) == use_meter, "Old doubling keeps its currency icon: %d" % level_number)
		if !use_meter:
			check(component.selected_multiplier() == 2.0, "Early levels keep fixed doubling")
		main._clear()
		await get_tree().process_frame
	for ads: bool in [false, true]:
		var before: int = GameState.get_soft_currency()
		var claims_before: int = main.claims
		fixture(ads)
		var large_pack: Control = main.content.find_child("CoinPackVisual", true, false)
		check(large_pack != null and large_pack.material.get_shader_parameter("outline_pixels") == 8.0, "Large reward uses eight-pixel outline")
		var chain_icons: Array[Node] = main.content.find_children("RewardCoinIcon", "TextureRect", true, false)
		check(!chain_icons.is_empty(), "Chain fixture contains resource icons")
		for resource: TextureRect in chain_icons:
			check(resource.material.get_shader_parameter("outline_pixels") == 5.0, "Chain rewards use five-pixel outline")
		check(bool(GameState.get_active_single_player_stage_reward().get("presentation_started", false)), "stage presentation marker is saved before intro")
		check(GameState.get_soft_currency() == before and main.claims == claims_before, "building screen does not grant reward")
		var button: Control = main.content.find_child("StageCoinRewardDoubleButton" if ads else "StageCoinRewardContinueButton", true, false)
		check(button != null and bool(button.get("button_disabled")), "action blocked during intro")
		await get_tree().create_timer(5.0).timeout
		check(main.claims == claims_before + 1 and GameState.get_soft_currency() == before + 25, "one base reward granted during presentation")
		check(main.claim_scale > 1.0 and bool(GameState.get_active_single_player_stage_reward().get("claimed", false)), "peak callback grants and persists reward")
		check(!bool(button.get("button_disabled")) and is_equal_approx(button.modulate.a, 1.0), "action enabled after intro")
		var amount_label: Label = main.content.find_child("StageCoinLargeRewardAmount", true, false)
		var amount_fade: Control = main.COMPOSITED_FADE.wrap(amount_label)
		check(is_equal_approx(float(amount_fade.get("opacity")), 1.0) and is_equal_approx(amount_label.modulate.a, 1.0), "large reward amount finishes revealing through composite opacity")
		var pack: Control = main.content.find_child("StageCoinLargeReward", true, false)
		check(pack.self_modulate.a > 0.99 and pack.find_child("CoinPackVisual", true, false).self_modulate.a > 0.99, "large reward art restores visible alpha after parent intro")
		check(button.self_modulate.a > 0.99, "enabled action also restores visible alpha after parent intro")
		var glow: Control = main.content.find_child("FinalRewardGlow", true, false)
		check(glow.self_modulate.a > 0.1, "reward glow reveals after parent intro")
		if ads:
			var meter: Control = main._portrait_stage_reward.multiplier_meter
			check(meter != null and meter.running, "stage offer starts multiplier meter")
			var meter_rect: Rect2 = meter.get_parent().get("stage_rect")
			check(is_equal_approx(meter_rect.position.x, 42.0) and is_equal_approx(meter_rect.size.x, 396.0), "meter width is reduced ten percent and stays centered")
			check(is_equal_approx(meter.BAR_HEIGHT, 51.1), "meter height increases by forty percent")
			meter.running = false
			for index in range(5):
				meter.set_cursor((float(index) + 0.5) / 5.0)
				check(meter._labels[index].get_theme_font_size("font_size") == 24 and is_equal_approx(24.0 * meter._labels[index].scale.x, 28.0), "label grows from base size 24 to 28 at sector center")
				check(amount_label.text == "x25", "large prize keeps its base amount in every multiplier sector")
				check(amount_label.scale.is_equal_approx(Vector2.ONE) and amount_label.get_theme_font_size("font_size") == 48, "reward count retains its original unscaled size")
				check(button.get("button_text") == tr("REWARD_GET").to_upper() and button.get("trailing_icon_texture") == null, "claim button has no currency amount or currency icon")
				check(meter._labels[index].get_theme_font("font") == preload("res://scripts/ui/ui_fonts.gd").heavy_display_font(), "multiplier uses heavy heading font")
				check(meter._labels[index].get_theme_font("font").base_font.multichannel_signed_distance_field, "heavy heading uses baked MSDF for sharp scaling")
			meter.set_cursor(0.4)
			check(meter.selected_multiplier() == 3.0, "sector boundary selects next multiplier")
			meter.set_cursor(0.5)
			var peak_scale: float = meter._labels[2].scale.x
			meter.set_cursor(0.45)
			check(meter._labels[2].scale.x > 1.0 and meter._labels[2].scale.x < peak_scale, "label grows gradually approaching center")
			meter.running = true
			meter._elapsed = 0.0
			var traverse: float = GameDesignConfig.get_float("timings.animations.stage_reward_multiplier.traverse_seconds")
			check(is_equal_approx(traverse * 1.15, 0.9230769231), "meter travels fifteen percent faster than its previous speed")
			traverse *= 0.8
			meter._process(0.05)
			check(is_equal_approx(meter.cursor, 0.1), "arrow pauses at the first sector center")
			meter._process(0.05)
			check(is_equal_approx(meter.cursor, 0.1), "left endpoint pause lasts 0.1 seconds")
			meter._process(traverse * 0.25)
			check(is_equal_approx(meter.cursor, 0.3), "arrow moves between sector centers")
			meter._process(traverse * 0.75)
			check(is_equal_approx(meter.cursor, 0.9), "arrow turns at the last sector center")
			meter._process(0.05)
			check(is_equal_approx(meter.cursor, 0.9), "arrow pauses at the last sector center")
			meter._process(0.05)
			check(is_equal_approx(meter.cursor, 0.9), "right endpoint pause lasts 0.1 seconds")
			meter._process(traverse * 0.5)
			check(is_equal_approx(meter.cursor, 0.5), "arrow reverses smoothly after the endpoint")
			meter._process(traverse * 0.5 + 0.05)
			check(is_equal_approx(meter.cursor, 0.1), "left pause repeats after a complete cycle")
			var border: StyleBoxFlat = meter.get_child(0).get_theme_stylebox("panel")
			check(border.draw_center and border.bg_color == preload("res://scripts/ui/ui_palette.gd").UI_BLUE_DARK, "meter uses the theme-unlock dark track")
			check([border.border_width_left, border.border_width_top, border.border_width_right, border.border_width_bottom] == [0, 0, 0, 0], "track replaces the uniform outline")
			var fill: Control = meter.get_child(0).get_child(0)
			check(fill.position == Vector2(6, 6) and fill.size == meter.get_child(0).size - Vector2(12, 15), "track has six-pixel sides and a heavier nine-pixel lower edge")
			meter.scale = Vector2.ONE * 1.25
			meter._sync_border_scale()
			var frame_transform: Transform2D = meter.get_child(0).get_global_transform_with_canvas()
			var pixel_ratio: Vector2 = Vector2(get_viewport().get("size")) / get_viewport().get_visible_rect().size
			check(is_equal_approx((frame_transform.x * pixel_ratio).length(), 1.0) and is_equal_approx((frame_transform.y * pixel_ratio).length(), 1.0), "track compensates ancestor scaling and viewport stretching without integer rounding")
			meter.scale = Vector2.ONE
			meter._sync_border_scale()
			meter.set_cursor(0.0)
			check(is_equal_approx(meter.cursor, 0.1), "arrow cannot leave the first sector center")
			check(meter._pointer.texture != null and meter._pointer.material.get_shader_parameter("outline_pixels") == 5.0, "rounded pointer uses shared icon outline shader")
			check(is_equal_approx(meter._pointer.position.y + meter._pointer.size.y * 0.5, 24.0 + meter.BAR_HEIGHT), "plaque edge bisects pointer height")
			meter.running = false
			check(main.content.find_child("FinalRewardCollectText", true, false).self_modulate.a > 0.99, "delayed collect text restores visible alpha")
			var icon_layers: Array = [button.get("_icon_rect")]
			icon_layers.append_array(button.get("_icon_shadow_layers"))
			for repeat in range(3):
				for disabled: bool in [true, false]:
					button.set("button_disabled", disabled)
					for icon: TextureRect in icon_layers:
						check(is_equal_approx(icon.self_modulate.a, 0.85 if disabled else 1.0), "reward icons and shadows follow disabled state after intro")
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
	var saw_star_plaque := false
	var saw_pressure_flash := false
	var summary_deadline: int = Time.get_ticks_msec() + 7000
	while Time.get_ticks_msec() < summary_deadline:
		var plaque: Control = main.content.find_child("SinglePlayerLevelStarAward", true, false)
		var chest: Control = main.content.find_child("LevelCompletionRewardPrize", true, false)
		var flash: Control = main._reward_chest_flash_overlay(chest)
		saw_star_plaque = saw_star_plaque or (plaque.is_visible_in_tree() and plaque.self_modulate.a * plaque.modulate.a > 0.5)
		saw_pressure_flash = saw_pressure_flash or (flash.is_visible_in_tree() and flash.self_modulate.a * flash.modulate.a > 0.5 and chest.get_meta("reward_chest_closed_visual").visible)
		await get_tree().process_frame
	check(saw_star_plaque, "level summary shows earned-star plaque during payout")
	check(saw_pressure_flash, "closed chest visibly whitens before opening")
	for shadow: TextureRect in main.content.find_child("LevelCompletionRewardPrize", true, false).get_meta("main_reward_icon_shadow_layers"):
		check(shadow.self_modulate.a > 0.99, "chest extrusion appears after white flash finishes")
	check(GameState.get_soft_currency() == coins_before_summary + 35 and GameState.get_stars() == stars_before_summary + 10, "shared visuals preserve level coin/star grants")
	check(bool(GameState.pending_single_player_reward.get("claimed", false)) and bool(GameState.pending_single_player_reward.get("stars_claimed", false)), "level claim flags stay durable")
	check(main.content.find_child("SinglePlayerRewardHeroViewport", true, false) == null, "level summary still omits hero viewport")
	check(main.content.find_child("LevelCompletionRewardPrize", true, false).self_modulate.a > 0.99, "level summary prize restores visible alpha")
	check(main.content.find_child("FinalRewardContinueButton", true, false).self_modulate.a > 0.99, "level summary action restores visible alpha")
	check(main.content.find_child("FinalRewardGlow", true, false).self_modulate.a > 0.1, "level summary glow restores visible alpha")
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
	component.build(parent, 25, source_rect, true, 5)
	var child_count: int = parent.get_child_count()
	component.build(parent, 25, source_rect, true, 5)
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
	check(!component.multiplier_meter.running, "stop cancels the moving meter")
	component.action.emit_signal("pressed")
	component.collect_hit.emit_signal("pressed")
	check(standalone_doubles == 1 and standalone_continues == 1, "stopped presentation ignores actions")
	check(component._animations.is_empty(), "stop cancels all stage animations")
	parent.queue_free()
	print("PORTRAIT_STAGE_REWARD " + JSON.stringify({"checks": checks, "failures": failures, "signatures": signatures}))
	await get_tree().process_frame
	get_tree().quit(0 if failures.is_empty() else 1)
