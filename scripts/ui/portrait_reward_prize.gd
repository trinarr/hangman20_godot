extends "res://scripts/ui/portrait_presentation.gd"
## Shared coin-prize visuals. Economy, advertisements and navigation stay outside.

var UI_REGULAR_FONT: Font = UI_FONTS.regular_font()

const SOFT_CURRENCY_COIN_TEXTURE: Texture2D = preload("res://flash_assets/soft_currency_coin.png")

const PORTRAIT_GAME_DESIGN: GDScript = preload("res://scripts/core/game_design_config.gd")

const PORTRAIT_UI_PALETTE: GDScript = preload("res://scripts/ui/ui_palette.gd")

const PORTRAIT_REWARD_SPARKLES: GDScript = preload("res://scripts/ui/portrait_reward_sparkles.gd")

const PORTRAIT_ICON_EXTRUSION: GDScript = preload("res://scripts/ui/portrait_icon_extrusion.gd")

const UI_MATERIALS: GDScript = preload("res://scripts/ui/ui_materials.gd")

const PORTRAIT_STAGE_LAYOUT: GDScript = preload("res://scripts/ui/portrait_stage_layout.gd")

const COIN_PACK_04_TEXTURE: Texture2D = preload("res://flash_assets/coin_pack_04.png")

const WATCH_AD_ICON_TEXTURE: Texture2D = preload("res://flash_assets/watch_ad_icon.png")

const FINAL_REWARD_ROTATING_GLOW_TEXTURE: Texture2D = preload(
	"res://flash_assets/final_reward_rotating_glow.png"
)

const PORTRAIT_STAGE_SIZE := Vector2(480.0, 800.0)

const PORTRAIT_LONG_BUTTON_SIZE := Vector2(300.0, 64.0)

const PORTRAIT_FOOTER_LONG_BUTTON_WIDTH_SCALE: float = 0.85

const PORTRAIT_FOOTER_CONTROL_SCALE: float = 1.10

const PORTRAIT_PRIMARY_BOTTOM_BUTTON_WIDTH_SCALE: float = 1.15

const PORTRAIT_PRIMARY_BOTTOM_BUTTON_WIDTH: float = (
	PORTRAIT_LONG_BUTTON_SIZE.x
	* PORTRAIT_FOOTER_LONG_BUTTON_WIDTH_SCALE
	* PORTRAIT_FOOTER_CONTROL_SCALE
	* PORTRAIT_PRIMARY_BOTTOM_BUTTON_WIDTH_SCALE
)

const PORTRAIT_FINAL_REWARD_AMOUNT_SIZE := Vector2(300.0, 58.0)

var PORTRAIT_FINAL_REWARD_PACK_BOUNCE_SCALE: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.final_reward.pack_bounce_scale"
)

var PORTRAIT_FINAL_REWARD_PACK_BOUNCE_GROW_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.final_reward.pack_bounce_grow_seconds"
)

var PORTRAIT_FINAL_REWARD_PACK_BOUNCE_SETTLE_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.final_reward.pack_bounce_settle_seconds"
)

var PORTRAIT_FINAL_REWARD_GLOW_ROTATION_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.final_reward.glow_rotation_seconds"
)

var PORTRAIT_FINAL_REWARD_ACTION_REVEAL_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.final_reward.action_reveal_seconds"
)

var PORTRAIT_FINAL_REWARD_COLLECT_DELAY: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.final_reward.collect_delay_seconds"
)

const PORTRAIT_FINAL_REWARD_DOUBLE_BUTTON_BONUS_COIN_SIZE := Vector2(28.0, 28.0)

const PORTRAIT_FINAL_REWARD_DOUBLE_BUTTON_PLAY_GAP: float = -8.0

const PORTRAIT_DARK_BLUE := PORTRAIT_UI_PALETTE.UI_BLUE_DARK

const PORTRAIT_AD_BADGE_PURPLE := PORTRAIT_UI_PALETTE.AD_PURPLE

const PORTRAIT_FINAL_REWARD_SPARKLE_FADE_IN_DURATION: float = 0.23

const PORTRAIT_FINAL_REWARD_SPARKLE_FADE_OUT_DURATION: float = 0.44

const PORTRAIT_FINAL_REWARD_SPARKLE_LOOP_DELAY: float = 1.43

const PORTRAIT_FINAL_REWARD_SPARKLE_BASE_SCALE: float = 0.82

const PORTRAIT_FINAL_REWARD_SPARKLE_PEAK_SCALE: float = 1.00

func _stage_final_reward_glow(rect: Rect2, tint_color: Color = Color.WHITE) -> TextureRect:
	# The source glow texture is authored in grayscale, like the long-button
	# textures. White is therefore the neutral/default appearance, while modulate
	# can tint the same asset to any UI color without extra shaders.
	var holder := _stage_holder(rect, Control.MOUSE_FILTER_IGNORE)
	holder.name = "FinalRewardGlowHolder"
	holder.z_index = 10
	var glow := TextureRect.new()
	glow.name = "FinalRewardGlow"
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.texture = FINAL_REWARD_ROTATING_GLOW_TEXTURE
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glow.pivot_offset = rect.size * 0.5
	glow.modulate = Color(tint_color.r, tint_color.g, tint_color.b, 0.0)
	glow.set_meta(&"glow_tint_color", tint_color)
	holder.add_child(glow)
	return glow

func _start_final_reward_glow_rotation(
	glow: Control,
	duration: float = PORTRAIT_FINAL_REWARD_GLOW_ROTATION_DURATION
) -> void:
	if glow == null or !is_instance_valid(glow) or !glow.is_inside_tree():
		return
	glow.pivot_offset = glow.size * 0.5
	var rotation_tween := _tween(glow)
	rotation_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	rotation_tween.set_loops()
	rotation_tween.tween_property(
		glow,
		"rotation",
		TAU,
		duration
	).from(0.0)

func _play_final_reward_pack_bounce(
	pack: Control,
	peak_callback: Callable = Callable()
) -> void:
	if pack == null or !is_instance_valid(pack) or !pack.is_inside_tree():
		return
	# FlashStageTexture stores the viewport fit in Control.scale. Preserve that
	# base transform and compensate for the new center pivot before the bounce.
	var rest_position: Vector2 = pack.position
	var rest_scale: Vector2 = pack.scale
	pack.pivot_offset = pack.size * 0.5
	pack.position = rest_position + (rest_scale - Vector2.ONE) * pack.pivot_offset
	var bounce_tween := _tween(pack)
	bounce_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var grow := bounce_tween.tween_property(
		pack,
		"scale",
		rest_scale * PORTRAIT_FINAL_REWARD_PACK_BOUNCE_SCALE,
		PORTRAIT_FINAL_REWARD_PACK_BOUNCE_GROW_DURATION
	)
	grow.set_trans(Tween.TRANS_QUAD)
	grow.set_ease(Tween.EASE_OUT)
	if peak_callback.is_valid():
		# This callback runs after the grow phase has reached its exact target
		# scale and before the settling phase starts shrinking the prize again.
		bounce_tween.tween_callback(peak_callback)
	var settle := bounce_tween.tween_property(
		pack,
		"scale",
		rest_scale,
		PORTRAIT_FINAL_REWARD_PACK_BOUNCE_SETTLE_DURATION
	)
	settle.set_trans(Tween.TRANS_BOUNCE)
	settle.set_ease(Tween.EASE_OUT)
	await bounce_tween.finished
	if pack == null or !is_instance_valid(pack) or !pack.is_inside_tree():
		return
	pack.pivot_offset = Vector2.ZERO
	pack.position = rest_position

func _set_final_reward_collect_pressed(visual: Control, is_pressed: bool) -> void:
	if visual == null or !is_instance_valid(visual) or !visual.is_inside_tree():
		return
	var previous_tween := _optional_node_meta(visual, &"final_reward_press_tween") as Tween
	if previous_tween != null and previous_tween.is_valid():
		previous_tween.kill()
	var target_scale := Vector2.ONE * (0.93 if is_pressed else 1.0)
	var target_modulate: Color = PORTRAIT_UI_PALETTE.PRESS_HIGHLIGHT if is_pressed else Color.WHITE
	var press_tween := _tween(visual)
	press_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	press_tween.set_parallel(true)
	press_tween.tween_property(visual, "scale", target_scale, 0.07)
	press_tween.tween_property(visual, "modulate", target_modulate, 0.07)
	visual.set_meta(&"final_reward_press_tween", press_tween)

func _stage_final_reward_collect_text(
	rect: Rect2,
	next_level_index: int = -1,
	custom_action: Callable = Callable()
) -> Dictionary:
	var holder := _stage_holder(rect, Control.MOUSE_FILTER_IGNORE)
	holder.name = "FinalRewardCollectText"
	holder.z_index = 120
	var visual := Control.new()
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.position = Vector2.ZERO
	visual.size = rect.size
	visual.pivot_offset = rect.size * 0.5
	holder.add_child(visual)
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.text = tr("NO_THANKS")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", UI_REGULAR_FONT)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color.WHITE)
	BUTTON_TEXT_STYLE_SCRIPT.apply_regular_display(label)
	visual.add_child(label)

	var collect_action: Callable = custom_action
	if !collect_action.is_valid():
		collect_action = Callable()
	var hit_button := _stage_button(
		rect,
		collect_action,
		""
	)
	hit_button.name = "FinalRewardCollectButton"
	hit_button.z_index = 121
	hit_button.disabled = true
	hit_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hit_button.button_down.connect(
		Callable(self, "_set_final_reward_collect_pressed").bind(visual, true)
	)
	hit_button.button_up.connect(
		Callable(self, "_set_final_reward_collect_pressed").bind(visual, false)
	)
	hit_button.mouse_exited.connect(
		Callable(self, "_set_final_reward_collect_pressed").bind(visual, false)
	)
	holder.modulate.a = 0.0
	return {
		"holder": holder,
		"visual": visual,
		"button": hit_button,
	}

func _reveal_final_reward_collect_action(
	collect_holder: Control,
	collect_button: Button
) -> void:
	if collect_holder == null or !is_instance_valid(collect_holder) or !collect_holder.is_inside_tree():
		return
	if collect_button == null or !is_instance_valid(collect_button) or !collect_button.is_inside_tree():
		return
	collect_button.disabled = false
	collect_button.mouse_filter = Control.MOUSE_FILTER_STOP
	var reveal_tween := _tween(collect_holder)
	reveal_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	reveal_tween.tween_property(
		collect_holder,
		"modulate:a",
		1.0,
		PORTRAIT_FINAL_REWARD_ACTION_REVEAL_DURATION
	)

func _reveal_final_reward_actions(
	double_button: Control,
	collect_holder: Control,
	collect_button: Button
) -> void:
	if double_button == null or !is_instance_valid(double_button) or !double_button.is_inside_tree():
		return
	double_button.set("button_disabled", false)
	double_button.set("visual_scale", Vector2.ONE * 0.94)
	var reveal_tween := _tween(double_button)
	reveal_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	reveal_tween.set_parallel(true)
	reveal_tween.tween_property(
		double_button,
		"modulate:a",
		1.0,
		PORTRAIT_FINAL_REWARD_ACTION_REVEAL_DURATION
	)
	var button_grow := reveal_tween.tween_property(
		double_button,
		"visual_scale",
		Vector2.ONE,
		PORTRAIT_FINAL_REWARD_ACTION_REVEAL_DURATION
	)
	button_grow.set_trans(Tween.TRANS_BACK)
	button_grow.set_ease(Tween.EASE_OUT)
	reveal_tween.finished.connect(
		Callable(self, "_finish_final_reward_action_reveal").bind(double_button),
		CONNECT_ONE_SHOT
	)
	if (
		collect_holder != null
		and is_instance_valid(collect_holder)
		and collect_holder.is_inside_tree()
		and collect_button != null
		and is_instance_valid(collect_button)
		and collect_button.is_inside_tree()
	):
		var collect_delay := _tween(collect_holder)
		collect_delay.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		collect_delay.tween_interval(
			PORTRAIT_FINAL_REWARD_ACTION_REVEAL_DURATION
			+ PORTRAIT_FINAL_REWARD_COLLECT_DELAY
		)
		collect_delay.tween_callback(
			Callable(self, "_reveal_final_reward_collect_action").bind(
				collect_holder,
				collect_button
			)
		)

func _finish_final_reward_action_reveal(button: Control) -> void:
	if button == null or !is_instance_valid(button) or !button.is_inside_tree():
		return
	if (
		bool(button.get_meta(&"single_shine_after_reveal", false))
		and button.has_method("play_single_attention_shine")
	):
		button.call("play_single_attention_shine")
	_enable_final_reward_continue_attention(button)

func _enable_final_reward_continue_attention(button: Control) -> void:
	if button == null or !is_instance_valid(button) or !button.is_inside_tree():
		return
	if !bool(button.get_meta(&"attention_after_reveal", false)):
		return
	button.set("attention_bounce_enabled", true)

func _stage_main_reward_coin_pack_transition(rect: Rect2) -> Control:
	# FlashStageTexture draws its image on the parent CanvasItem itself, so negative-z
	# child extrusion layers can be visually swallowed by the main draw. Mirror the
	# chest implementation instead: use a transparent stage holder, place the shadow
	# layers behind it, and draw the coin pack as a full-rect child above them.
	var holder := _stage_holder(rect, Control.MOUSE_FILTER_IGNORE)
	holder.name = "SingleStageLevelCoinReward"
	holder.z_index = 20
	_attach_main_reward_icon_shadow(
		holder,
		COIN_PACK_04_TEXTURE,
		"SingleStageLevelCoinRewardShadow"
	)
	var visual := TextureRect.new()
	visual.name = "CoinPackVisual"
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.texture = COIN_PACK_04_TEXTURE
	visual.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	visual.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	holder.add_child(visual)
	visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visual.z_index = 0
	return holder

func _attach_main_reward_icon_shadow(
	holder: Control,
	texture: Texture2D,
	prefix: String
) -> Array[TextureRect]:
	var layers: Array[TextureRect] = []
	if holder == null or !is_instance_valid(holder) or texture == null:
		return layers
	# Match the theme-unlock icon exactly: the regular ad-button shader extrusion,
	# half depth, tinted with the dark-blue progress-bar track color. Keep the
	# layers as children of the reward visual so flight/bounce scale affects both.
	layers = _create_portrait_icon_extrusion_layers(
		holder,
		texture,
		prefix,
		-1
	)
	var shadow_color := Color(
		PORTRAIT_DARK_BLUE.r,
		PORTRAIT_DARK_BLUE.g,
		PORTRAIT_DARK_BLUE.b,
		PORTRAIT_UI_PALETTE.NAV_TEXT_SHADOW.a
	)
	var shadow_material: ShaderMaterial = UI_MATERIALS.icon_shadow(shadow_color)
	for layer: TextureRect in layers:
		layer.material = shadow_material
	_layout_portrait_icon_holder_extrusion(holder, layers, 0.5)
	var resize_callback := Callable(self, "_layout_portrait_icon_holder_extrusion").bind(
		holder,
		layers,
		0.5
	)
	if !holder.resized.is_connected(resize_callback):
		holder.resized.connect(resize_callback)
	holder.set_meta(&"main_reward_icon_shadow_layers", layers)
	return layers

func _create_portrait_icon_extrusion_layers(
	parent: Control,
	texture: Texture2D,
	prefix: String,
	z_index: int = 0,
	shadow_alpha: float = 1.0
) -> Array[TextureRect]:
	return PORTRAIT_ICON_EXTRUSION._create_portrait_icon_extrusion_layers(parent, texture, prefix, z_index, shadow_alpha)

func _layout_portrait_icon_holder_extrusion(
	holder: Control,
	layers: Array[TextureRect],
	shadow_offset_scale: float = 1.0
) -> void:
	PORTRAIT_ICON_EXTRUSION._layout_portrait_icon_holder_extrusion(holder, layers, shadow_offset_scale)

func _optional_node_meta(node: Object, key: StringName) -> Variant:
	# A null get_meta default still reports a missing-key error in Godot.
	# Animation metadata is deliberately absent before the first interaction.
	return node.get_meta(key) if node.has_meta(key) else null

func _set_panel_fill_color(color: Color, panel: Panel) -> void:
	if panel == null or !is_instance_valid(panel):
		return
	var style := panel.get_theme_stylebox("panel") as StyleBoxFlat
	if style == null:
		return
	style.bg_color = color
	panel.add_theme_stylebox_override("panel", style)

func _portrait_final_reward_center_rect(size: Vector2) -> Rect2:
	var viewport_size: Vector2 = get_viewport_rect().size
	var logical_height: float = PORTRAIT_STAGE_LAYOUT.expanded_stage_height(viewport_size)
	var safe_top: float = PORTRAIT_STAGE_LAYOUT.safe_top_stage(viewport_size)
	var center_stage_y: float = logical_height * 0.5 - safe_top
	return Rect2(
		Vector2(
			(PORTRAIT_STAGE_SIZE.x - size.x) * 0.5,
			center_stage_y - size.y * 0.5
		),
		size
	)

func _portrait_final_reward_amount_rect(coin_rect: Rect2) -> Rect2:
	return Rect2(
		Vector2(
			(PORTRAIT_STAGE_SIZE.x - PORTRAIT_FINAL_REWARD_AMOUNT_SIZE.x) * 0.5,
			coin_rect.end.y - 26.0
		),
		PORTRAIT_FINAL_REWARD_AMOUNT_SIZE
	)

func _sync_final_reward_double_button_content(button: Control) -> void:
	if button == null or !is_instance_valid(button):
		return
	# Use StageLongButton's native text+icon layout. It measures the caption and
	# icon as one row and centers that complete row inside the authored button.
	button.set("button_text", tr("REWARD_GET_X2"))
	button.set("icon_texture", WATCH_AD_ICON_TEXTURE)
	button.set("icon_stage_size", PORTRAIT_FINAL_REWARD_DOUBLE_BUTTON_BONUS_COIN_SIZE * 2.0)
	button.set("icon_gap_stage", PORTRAIT_FINAL_REWARD_DOUBLE_BUTTON_PLAY_GAP)
	button.set("icon_before_text", true)
	button.set("icon_shadow_enabled", true)
	button.set("trailing_icon_texture", SOFT_CURRENCY_COIN_TEXTURE)
	button.set("trailing_icon_stage_size", PORTRAIT_FINAL_REWARD_DOUBLE_BUTTON_BONUS_COIN_SIZE)
	button.set("trailing_icon_gap_stage", 6.0)
	button.set("trailing_icon_shadow_enabled", true)
	var label := button.get_node_or_null("Text") as Label
	if label != null and is_instance_valid(label):
		label.visible = true
		label.add_theme_font_override("font", UI_BUTTON_FONT)
		label.add_theme_font_size_override("font_size", 24)
		label.clip_text = false
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
	var built_in_icon := button.get_node_or_null("Icon") as TextureRect
	if built_in_icon != null and is_instance_valid(built_in_icon):
		built_in_icon.visible = true

func _configure_final_reward_double_button(button: Control) -> void:
	if button == null or !is_instance_valid(button):
		return
	_sync_final_reward_double_button_content(button)
	button.set("drop_shadow_enabled", true)
	# Keep the standard stretchable long-button slices and only tint them to the
	# same purple used by rewarded-ad indicators.
	if button.has_method("set_color_palette"):
		button.call(
			"set_color_palette",
			PORTRAIT_AD_BADGE_PURPLE,
			PORTRAIT_UI_PALETTE.AD_PURPLE_PRESSED,
			PORTRAIT_UI_PALETTE.AD_PURPLE_SELECTED
		)

func _play_reward_coin_sparkles(reward_visual: Control) -> void:
	PORTRAIT_REWARD_SPARKLES._play_reward_coin_sparkles(reward_visual, PORTRAIT_FINAL_REWARD_SPARKLE_BASE_SCALE, PORTRAIT_FINAL_REWARD_SPARKLE_PEAK_SCALE, PORTRAIT_FINAL_REWARD_SPARKLE_FADE_IN_DURATION, PORTRAIT_FINAL_REWARD_SPARKLE_FADE_OUT_DURATION, PORTRAIT_FINAL_REWARD_SPARKLE_LOOP_DELAY)

func _single_player_reward_chain_count_text(amount: int) -> String:
	return "x%d" % maxi(amount, 0)

func _portrait_primary_bottom_button_rect(rect: Rect2) -> Rect2:
	var resized_rect: Rect2 = rect
	resized_rect.position.x = rect.get_center().x - PORTRAIT_PRIMARY_BOTTOM_BUTTON_WIDTH * 0.5
	resized_rect.size.x = PORTRAIT_PRIMARY_BOTTOM_BUTTON_WIDTH
	return resized_rect
