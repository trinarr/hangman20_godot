class_name StageRoundButton
extends "res://scripts/ui/flash_stage_texture_button.gd"

const BUTTON_TEXT_STYLE_SCRIPT: GDScript = preload("res://scripts/ui/button_text_style.gd")
const UI_PALETTE: GDScript = preload("res://scripts/ui/ui_palette.gd")
const GAME_DESIGN: GDScript = preload("res://scripts/core/game_design_config.gd")

const NORMAL_TEXTURE: Texture2D = preload("res://flash_assets/user_round_button_36.png")
const PRESSED_TEXTURE: Texture2D = preload("res://flash_assets/user_round_button_38.png")
const ICON_VISUAL_SCALE: float = 0.82
var _attention_bounce_scale_value: float = GAME_DESIGN.get_float_range(
	"timings.animations.button_attention.round.scale", 1.1, 1.0, 1.5
)
var _attention_bounce_grow_duration: float = GAME_DESIGN.get_float(
	"timings.animations.button_attention.round.grow_seconds", 0.72
)
var _attention_bounce_settle_duration: float = GAME_DESIGN.get_float(
	"timings.animations.button_attention.round.settle_seconds", 0.82
)
var _attention_bounce_count: int = GAME_DESIGN.get_int_range(
	"timings.animations.button_attention.bounce_count", 2, 1, 8
)
var _attention_bounce_speed_multiplier: float = GAME_DESIGN.get_float_range(
	"timings.animations.button_attention.speed_multiplier", 1.5, 0.1, 10.0
)
var _attention_shine_duration: float = GAME_DESIGN.get_float(
	"timings.animations.button_attention.shine_seconds", 0.55
)
var _attention_cycle_pause_duration: float = GAME_DESIGN.get_float(
	"timings.animations.button_attention.pause_seconds", 0.1
)
var _attention_shine_width: float = GAME_DESIGN.get_float_range(
	"timings.animations.button_attention.shine_width", 0.16, 0.01, 1.0
)
var _attention_shine_strength: float = GAME_DESIGN.get_float_range(
	"timings.animations.button_attention.shine_strength", 0.42, 0.0, 1.0
)

enum ColorPreset {
	ORANGE,
	GREEN,
	BLUE,
	CUSTOM,
}

# The round-button PNGs are neutral grayscale masks. Modulation restores the
# authored orange visual language while allowing the same component to be
# recolored without producing additional textures. Pressed orange matches the
# long button; selected remains a separate blue state.
const ORANGE_NORMAL_TINT := UI_PALETTE.BUTTON_ORANGE
const ORANGE_PRESSED_TINT := UI_PALETTE.BUTTON_ORANGE_PRESSED
const ORANGE_SELECTED_TINT := UI_PALETTE.BUTTON_SELECTED_ACCENT
const DISABLED_TINT := UI_PALETTE.DISABLED
const DISABLED_OPACITY: float = UI_PALETTE.DISABLED_OPACITY
const GREEN_NORMAL_TINT := UI_PALETTE.SUCCESS
const GREEN_PRESSED_TINT := UI_PALETTE.SUCCESS_PRESSED
const GREEN_SELECTED_TINT := UI_PALETTE.SUCCESS_SELECTED
const BLUE_NORMAL_TINT := UI_PALETTE.BUTTON_BLUE
const BLUE_PRESSED_TINT := UI_PALETTE.BUTTON_BLUE_PRESSED
const BLUE_SELECTED_TINT := UI_PALETTE.BUTTON_BLUE_SELECTED
const BLUE_ICON_OUTLINE_COLOR := UI_PALETTE.BUTTON_BLUE_OUTLINE
const DEFAULT_ICON_OUTLINE_COLOR := UI_PALETTE.UI_BLUE

var attention_bounce_enabled: bool = false:
	set(value):
		if attention_bounce_enabled == value:
			return
		attention_bounce_enabled = value
		if attention_bounce_enabled:
			_start_attention_bounce()
		else:
			_stop_attention_bounce(true)

var icon_text: String = "":
	set(value):
		icon_text = value.to_upper()
		_sync_visuals()

var icon_texture: Texture2D = null:
	set(value):
		icon_texture = value
		_sync_visuals()

var icon_font_size: int = 26:
	set(value):
		icon_font_size = value
		_sync_visuals()

var icon_stage_size: Vector2 = Vector2(24.0, 24.0):
	set(value):
		icon_stage_size = value
		_sync_icon_layout()

var icon_stage_offset: Vector2 = Vector2.ZERO:
	set(value):
		icon_stage_offset = value
		_sync_icon_layout()

var icon_color: Color = Color.WHITE:
	set(value):
		icon_color = value
		_sync_visuals()

var icon_outline_color: Color = DEFAULT_ICON_OUTLINE_COLOR:
	set(value):
		icon_outline_color = value
		_sync_visuals()

var icon_outline_size: int = 3:
	set(value):
		icon_outline_size = value
		_sync_visuals()

var icon_modulate: Color = Color.WHITE:
	set(value):
		icon_modulate = value
		_sync_visuals()

var selected: bool = false:
	set(value):
		selected = value
		_sync_background()

var color_preset: int = ColorPreset.ORANGE

var normal_tint: Color = ORANGE_NORMAL_TINT:
	set(value):
		normal_tint = value
		queue_redraw()

var pressed_tint: Color = ORANGE_PRESSED_TINT:
	set(value):
		pressed_tint = value
		queue_redraw()

var selected_tint: Color = ORANGE_SELECTED_TINT:
	set(value):
		selected_tint = value
		queue_redraw()

var button_disabled: bool = false:
	set(value):
		button_disabled = value
		disabled = value
		if button_disabled:
			_stop_attention_bounce(true)
		elif attention_bounce_enabled:
			_start_attention_bounce()
		_sync_visuals()

var _icon_rect: TextureRect = null
var _icon_label: Label = null
var _attention_bounce_tween: Tween = null

func _ready() -> void:
	press_scale_enabled = true
	_ensure_visual_nodes()
	if !resized.is_connected(_sync_icon_layout):
		resized.connect(_sync_icon_layout)
	_sync_background()
	super._ready()
	_sync_visuals()
	_sync_icon_layout()
	_start_attention_bounce()

func _exit_tree() -> void:
	_stop_attention_bounce(false)
	super._exit_tree()

func _set_press_scale(is_pressed: bool, animated: bool = true) -> void:
	# Press feedback and the attention loop animate the same visual scale. Pause
	# the loop while the button is held and resume it after release.
	if is_pressed:
		_stop_attention_bounce(false)
	super._set_press_scale(is_pressed, animated)
	if is_pressed or !attention_bounce_enabled or disabled:
		return
	if animated and _press_scale_tween != null and _press_scale_tween.is_valid():
		_press_scale_tween.finished.connect(_start_attention_bounce, CONNECT_ONE_SHOT)
	else:
		_start_attention_bounce()

func _start_attention_bounce() -> void:
	if !attention_bounce_enabled or disabled or _is_down or !is_inside_tree():
		return
	_configure_attention_shine(_attention_shine_width, _attention_shine_strength)
	_stop_attention_bounce(false)
	visual_scale = Vector2.ONE
	_attention_bounce_tween = create_tween()
	_attention_bounce_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_attention_bounce_tween.set_loops()
	var bounce_scale: Vector2 = Vector2.ONE * _attention_bounce_scale_value
	var grow_duration: float = _attention_bounce_grow_duration / _attention_bounce_speed_multiplier
	var settle_duration: float = _attention_bounce_settle_duration / _attention_bounce_speed_multiplier
	_attention_bounce_tween.tween_callback(_reset_attention_shine)
	_attention_bounce_tween.tween_method(
		_set_attention_shine_progress,
		ATTENTION_SHINE_START_PROGRESS,
		ATTENTION_SHINE_END_PROGRESS,
		_attention_shine_duration
	)
	for _bounce_index: int in range(_attention_bounce_count):
		var grow_tweener: PropertyTweener = _attention_bounce_tween.tween_property(
			self,
			"visual_scale",
			bounce_scale,
			grow_duration
		)
		grow_tweener.set_trans(Tween.TRANS_QUAD)
		grow_tweener.set_ease(Tween.EASE_OUT)
		var settle_tweener: PropertyTweener = _attention_bounce_tween.tween_property(
			self,
			"visual_scale",
			Vector2.ONE,
			settle_duration
		)
		settle_tweener.set_trans(Tween.TRANS_BACK)
		settle_tweener.set_ease(Tween.EASE_OUT)
	_attention_bounce_tween.tween_interval(_attention_cycle_pause_duration)

func _stop_attention_bounce(reset_scale: bool) -> void:
	if _attention_bounce_tween != null and _attention_bounce_tween.is_valid():
		_attention_bounce_tween.kill()
	_attention_bounce_tween = null
	_reset_attention_shine()
	if reset_scale:
		visual_scale = Vector2.ONE

func _draw() -> void:
	var background_texture: Texture2D = NORMAL_TEXTURE
	var background_tint: Color = normal_tint
	if disabled:
		# Match the pressed button's inverted relief while keeping the disabled
		# state neutral gray and unavailable for pointer input.
		background_texture = PRESSED_TEXTURE
		background_tint = Color(DISABLED_TINT.r, DISABLED_TINT.g, DISABLED_TINT.b, DISABLED_OPACITY)
	elif selected:
		background_texture = PRESSED_TEXTURE
		background_tint = selected_tint
	elif _is_down:
		background_texture = PRESSED_TEXTURE
		background_tint = pressed_tint
	var visual_size: Vector2 = size * visual_scale
	var visual_rect := Rect2((size - visual_size) * 0.5, visual_size)
	draw_texture_rect(background_texture, visual_rect, false, background_tint)

func configure_text(text_value: String, disabled_value: bool = false, selected_value: bool = false, font_size_value: int = 26, disabled_overlay_alpha_value: float = 0.32) -> void:
	icon_texture = null
	icon_text = text_value
	icon_font_size = font_size_value
	disabled_overlay_alpha = disabled_overlay_alpha_value
	selected = selected_value
	button_disabled = disabled_value
	_ensure_visual_nodes()
	_sync_visuals()

func configure_texture(texture_value: Texture2D, stage_size_value: Vector2, disabled_value: bool = false, selected_value: bool = false, stage_offset_value: Vector2 = Vector2.ZERO, disabled_overlay_alpha_value: float = 0.32) -> void:
	icon_text = ""
	icon_texture = texture_value
	icon_stage_size = stage_size_value
	icon_stage_offset = stage_offset_value
	disabled_overlay_alpha = disabled_overlay_alpha_value
	selected = selected_value
	button_disabled = disabled_value
	_ensure_visual_nodes()
	_sync_visuals()
	_sync_icon_layout()

func _ensure_visual_nodes() -> void:
	if _icon_rect == null or !is_instance_valid(_icon_rect):
		_icon_rect = TextureRect.new()
		_icon_rect.name = "Icon"
		_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		add_child(_icon_rect)
	if _icon_label == null or !is_instance_valid(_icon_label):
		_icon_label = Label.new()
		_icon_label.name = "Text"
		_icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_icon_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_icon_label.clip_text = true
		_icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_child(_icon_label)

func _sync_background() -> void:
	queue_redraw()

func set_color_preset(preset: int) -> void:
	match preset:
		ColorPreset.GREEN:
			color_preset = ColorPreset.GREEN
			_apply_icon_outline_style(DEFAULT_ICON_OUTLINE_COLOR, 3)
			_apply_color_palette(GREEN_NORMAL_TINT, GREEN_PRESSED_TINT, GREEN_SELECTED_TINT)
		ColorPreset.BLUE:
			color_preset = ColorPreset.BLUE
			_apply_icon_outline_style(BLUE_ICON_OUTLINE_COLOR, 4)
			_apply_color_palette(BLUE_NORMAL_TINT, BLUE_PRESSED_TINT, BLUE_SELECTED_TINT)
		ColorPreset.CUSTOM:
			color_preset = ColorPreset.CUSTOM
		_:
			color_preset = ColorPreset.ORANGE
			_apply_icon_outline_style(DEFAULT_ICON_OUTLINE_COLOR, 3)
			_apply_color_palette(ORANGE_NORMAL_TINT, ORANGE_PRESSED_TINT, ORANGE_SELECTED_TINT)

func _apply_icon_outline_style(color: Color, size_value: int) -> void:
	icon_outline_color = color
	icon_outline_size = size_value

func set_color_palette(normal_color: Color, pressed_color: Color, selected_color: Color = ORANGE_SELECTED_TINT) -> void:
	color_preset = ColorPreset.CUSTOM
	_apply_color_palette(normal_color, pressed_color, selected_color)

func _apply_color_palette(normal_color: Color, pressed_color: Color, selected_color: Color) -> void:
	normal_tint = normal_color
	pressed_tint = pressed_color
	selected_tint = selected_color

func _sync_visuals() -> void:
	if _icon_rect == null or _icon_label == null:
		return
	var has_texture: bool = icon_texture != null
	var visual_opacity: float = DISABLED_OPACITY if button_disabled else 1.0
	var current_icon_color := Color(icon_color.r, icon_color.g, icon_color.b, icon_color.a * visual_opacity)
	var current_effect_color := Color(
		icon_outline_color.r,
		icon_outline_color.g,
		icon_outline_color.b,
		icon_outline_color.a * visual_opacity * 0.55
	)
	_icon_rect.visible = has_texture
	_icon_rect.texture = icon_texture
	_icon_rect.modulate = Color(icon_modulate.r, icon_modulate.g, icon_modulate.b, icon_modulate.a * visual_opacity)
	_icon_label.visible = !has_texture and icon_text != ""
	_icon_label.text = icon_text
	_icon_label.add_theme_font_size_override("font_size", icon_font_size)
	_icon_label.add_theme_color_override("font_color", current_icon_color)
	BUTTON_TEXT_STYLE_SCRIPT.apply(
		_icon_label,
		current_effect_color,
		current_effect_color,
		3 if icon_outline_size > 0 else 0
	)

func _sync_icon_layout() -> void:
	if _icon_rect == null or !is_instance_valid(_icon_rect):
		return
	if stage_rect.size.x <= 0.0 or stage_rect.size.y <= 0.0:
		return
	var scale_to_view: Vector2 = Vector2(size.x / stage_rect.size.x, size.y / stage_rect.size.y)
	var actual_size: Vector2 = icon_stage_size * scale_to_view * ICON_VISUAL_SCALE
	var actual_offset: Vector2 = icon_stage_offset * scale_to_view
	_icon_rect.position = size * 0.5 + actual_offset - actual_size * 0.5
	_icon_rect.size = actual_size
	_sync_visual_child_scales()
