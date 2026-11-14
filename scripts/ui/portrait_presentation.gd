extends Node
## UI construction and cancellable animations shared by portrait presentations.
## Receives a rendering parent; never reads game state or performs navigation.

signal click_requested
var content: Control
var _animations: Array[Tween] = []
var _stopped: bool = false
var generation: int = 0

func _tween(owner: Node) -> Tween:
	var animation := owner.create_tween()
	_animations.append(animation)
	return animation

func stop() -> void:
	_stopped = true
	generation += 1
	for animation: Tween in _animations:
		if animation != null and animation.is_valid():
			animation.kill()
	_animations.clear()

func _exit_tree() -> void:
	stop()

func _connect_action(button: Object, action: Callable) -> void:
	if !action.is_valid():
		return
	button.connect(&"pressed", _dispatch_action.bind(action))

func _dispatch_action(action: Callable) -> void:
	if _stopped or !is_inside_tree() or !action.is_valid():
		return
	click_requested.emit()
	# Feedback listeners may navigate synchronously.
	if !_stopped and is_inside_tree() and action.is_valid():
		action.call()

func get_viewport_rect() -> Rect2:
	return get_viewport().get_visible_rect()

const FLASH_STAGE_CONTROL_SCRIPT: GDScript = preload("res://scripts/ui/flash_stage_control.gd")

const STAGE_LONG_BUTTON_SCRIPT: GDScript = preload("res://scripts/ui/stage_long_button.gd")

const LONG_BUTTON_COLOR_BLUE: int = 2

const ROUND_BUTTON_COLOR_BLUE: int = 2

const STAGE_ROUND_BUTTON_SCRIPT: GDScript = preload("res://scripts/ui/stage_round_button.gd")

const UI_FONTS: GDScript = preload("res://scripts/ui/ui_fonts.gd")

func _stage_holder(rect: Rect2, mouse_filter: int = Control.MOUSE_FILTER_PASS) -> Control:
	var holder: Control = FLASH_STAGE_CONTROL_SCRIPT.new() as Control
	holder.mouse_filter = mouse_filter
	holder.set("stage_rect", rect)
	content.add_child(holder)
	return holder

func _stage_label(rect: Rect2, text: String, font_size: int = 20, color: Color = Color.WHITE, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER, font: Font = null) -> Label:
	var holder: Control = _stage_holder(rect, Control.MOUSE_FILTER_IGNORE)
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.clip_text = true
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.begin_bulk_theme_override()
	if font != null:
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.end_bulk_theme_override()
	# Inherit the final theme and bounds before shaping non-empty text.
	holder.add_child(label)
	label.text = text
	return label

func _stage_main_button(rect: Rect2, callable: Callable, text: String, font_size: int = 20, disabled: bool = false, disabled_overlay_alpha: float = 0.32, use_normal_texture_when_disabled: bool = false, selected: bool = false, attention_bounce: bool = false, color_preset: int = LONG_BUTTON_COLOR_BLUE) -> Control:
	var button: FlashStageTextureButton = STAGE_LONG_BUTTON_SCRIPT.new() as FlashStageTextureButton
	button.call("configure", text, UI_FONTS.display_button_font_size(font_size), disabled, disabled_overlay_alpha, use_normal_texture_when_disabled, selected)
	button.call("set_color_preset", color_preset)
	button.set("attention_bounce_enabled", attention_bounce)
	_connect_action(button, callable)
	button.stage_rect = rect
	content.add_child(button)
	return button

func _stage_round_icon_button(rect: Rect2, callable: Callable, icon: Texture2D, icon_size: Vector2, disabled: bool = false, selected: bool = false, icon_offset: Vector2 = Vector2.ZERO, disabled_overlay_alpha: float = 0.32, color_preset: int = ROUND_BUTTON_COLOR_BLUE) -> Control:
	var button: FlashStageTextureButton = STAGE_ROUND_BUTTON_SCRIPT.new() as FlashStageTextureButton
	button.call("configure_texture", icon, icon_size, disabled, selected, icon_offset, disabled_overlay_alpha)
	button.call("set_color_preset", color_preset)
	_connect_action(button, callable)
	button.stage_rect = rect
	content.add_child(button)
	return button

const UI_PALETTE: GDScript = preload("res://scripts/ui/ui_palette.gd")

const FLASH_STAGE_BUTTON_SCRIPT: GDScript = preload("res://scripts/ui/flash_stage_button.gd")

const BUTTON_TEXT_STYLE_SCRIPT: GDScript = preload("res://scripts/ui/button_text_style.gd")

var UI_BUTTON_FONT: Font = UI_FONTS.button_font()

func _stage_button(rect: Rect2, callable: Callable, text: String = "", font_size: int = 20) -> Button:
	var button: Button = FLASH_STAGE_BUTTON_SCRIPT.new() as Button
	button.text = text.to_upper()
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.focus_mode = Control.FOCUS_NONE
	button.flat = true
	button.add_theme_font_override("font", UI_BUTTON_FONT)
	_apply_transparent_button_style(button, text != "", UI_FONTS.display_button_font_size(font_size))
	_connect_action(button, callable)
	button.set("stage_rect", rect)
	content.add_child(button)
	return button

func _apply_transparent_button_style(button: Button, show_text: bool = true, font_size: int = 20) -> void:
	var empty_style := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty_style)
	button.add_theme_stylebox_override("hover", empty_style)
	button.add_theme_stylebox_override("pressed", empty_style)
	button.add_theme_stylebox_override("focus", empty_style)
	button.add_theme_stylebox_override("disabled", empty_style)
	var font_color: Color = UI_PALETTE.TEXT_DARK if show_text else Color(1.0, 1.0, 1.0, 0.0)
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", font_color)
	button.add_theme_color_override("font_pressed_color", font_color)
	button.add_theme_color_override("font_disabled_color", Color(font_color.r, font_color.g, font_color.b, 0.45))
	if show_text:
		BUTTON_TEXT_STYLE_SCRIPT.apply_display(button)
	else:
		BUTTON_TEXT_STYLE_SCRIPT.apply(button, Color.TRANSPARENT, Color.TRANSPARENT, 0)
	button.add_theme_font_size_override("font_size", font_size)

const REWARD_BOUNCE_CONFIG = preload("res://scripts/core/game_design_config.gd")
var PORTRAIT_FINAL_REWARD_PACK_BOUNCE_SCALE: float = REWARD_BOUNCE_CONFIG.get_float(
	"timings.animations.final_reward.pack_bounce_scale"
)

var PORTRAIT_FINAL_REWARD_PACK_BOUNCE_GROW_DURATION: float = REWARD_BOUNCE_CONFIG.get_float(
	"timings.animations.final_reward.pack_bounce_grow_seconds"
)

var PORTRAIT_FINAL_REWARD_PACK_BOUNCE_SETTLE_DURATION: float = REWARD_BOUNCE_CONFIG.get_float(
	"timings.animations.final_reward.pack_bounce_settle_seconds"
)

func _create_final_reward_pack_bounce(
	pack: Control,
	peak_callback: Callable = Callable()
) -> Tween:
	if pack == null or !is_instance_valid(pack) or !pack.is_inside_tree():
		return null
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
	bounce_tween.tween_callback(func() -> void:
		if is_instance_valid(pack) and pack.is_inside_tree():
			pack.pivot_offset = Vector2.ZERO
			pack.position = rest_position
	)
	return bounce_tween
