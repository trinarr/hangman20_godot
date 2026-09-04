class_name StageLongButton
extends "res://scripts/ui/flash_stage_texture_button.gd"

const BUTTON_TEXT_STYLE_SCRIPT: GDScript = preload("res://scripts/ui/button_text_style.gd")
const UI_PALETTE: GDScript = preload("res://scripts/ui/ui_palette.gd")
const UI_FONTS: GDScript = preload("res://scripts/ui/ui_fonts.gd")
const GAME_DESIGN: GDScript = preload("res://scripts/core/game_design_config.gd")
const ICON_EXTRUSION_SHADER: Shader = preload("res://shaders/hint_icon_extrusion_shadow.gdshader")

const ICON_SHADOW_DEPTH_RATIO: float = 0.055
const ICON_SHADOW_DEPTH_MIN: float = 1.5
const ICON_SHADOW_DEPTH_MAX: float = 5.0
const ICON_SHADOW_OFFSET_X_RATIO: float = 0.012
const ICON_SHADOW_OFFSET_X_MAX: float = 1.5
const ICON_SHADOW_LAYER_T := [0.25, 0.55, 0.80, 1.0]

const NORMAL_LEFT_TEXTURE: Texture2D = preload("res://flash_assets/user_main_button_21_left.png")
const NORMAL_CENTER_TEXTURE: Texture2D = preload("res://flash_assets/user_main_button_21_center.png")
const NORMAL_RIGHT_TEXTURE: Texture2D = preload("res://flash_assets/user_main_button_21_right.png")
const PRESSED_LEFT_TEXTURE: Texture2D = preload("res://flash_assets/user_main_button_23_left.png")
const PRESSED_CENTER_TEXTURE: Texture2D = preload("res://flash_assets/user_main_button_23_center.png")
const PRESSED_RIGHT_TEXTURE: Texture2D = preload("res://flash_assets/user_main_button_23_right.png")

var _attention_bounce_scale_value: float = GAME_DESIGN.get_float_range(
	"timings.animations.button_attention.long.scale", 1.07, 1.0, 1.5
)
var _attention_bounce_grow_duration: float = GAME_DESIGN.get_float(
	"timings.animations.button_attention.long.grow_seconds", 0.8
)
var _attention_bounce_settle_duration: float = GAME_DESIGN.get_float(
	"timings.animations.button_attention.long.settle_seconds", 0.85
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

# The PNGs are neutral grayscale masks. These tints restore the original
# orange/blue visual language while allowing other palettes to reuse the same
# button slices without recoloring the source assets.
const ORANGE_NORMAL_TINT := UI_PALETTE.BUTTON_ORANGE
const ORANGE_PRESSED_TINT := UI_PALETTE.BUTTON_ORANGE_PRESSED
const ORANGE_SELECTED_TINT := UI_PALETTE.BUTTON_SELECTED_ACCENT
# Match the bright green used for a correctly guessed letter.
const GREEN_NORMAL_TINT := UI_PALETTE.SUCCESS
const GREEN_PRESSED_TINT := UI_PALETTE.SUCCESS_PRESSED
const GREEN_SELECTED_TINT := UI_PALETTE.SUCCESS_SELECTED
const BLUE_NORMAL_TINT := UI_PALETTE.BUTTON_BLUE
const BLUE_PRESSED_TINT := UI_PALETTE.BUTTON_BLUE_PRESSED
const BLUE_SELECTED_TINT := UI_PALETTE.BUTTON_BLUE_SELECTED
const BLUE_OUTLINE_COLOR := UI_PALETTE.BUTTON_BLUE_OUTLINE
const DEFAULT_OUTLINE_COLOR := UI_PALETTE.UI_BLUE_DARK
const DISABLED_TINT := UI_PALETTE.DISABLED
const DISABLED_OPACITY: float = UI_PALETTE.DISABLED_OPACITY

var attention_bounce_enabled: bool = false:
	set(value):
		if attention_bounce_enabled == value:
			return
		attention_bounce_enabled = value
		if attention_bounce_enabled:
			_start_attention_bounce()
		else:
			_stop_attention_bounce(true)

var button_text: String = "":
	set(value):
		button_text = value.to_upper()
		_sync_label()

var button_font_size: int = 20:
	set(value):
		button_font_size = value
		_sync_label()

var button_disabled: bool = false:
	set(value):
		button_disabled = value
		disabled = value
		if button_disabled:
			_stop_single_attention_shine()
			_stop_attention_bounce(true)
		elif attention_bounce_enabled:
			_start_attention_bounce()
		_sync_label()
		_sync_icon()
		_sync_trailing_icon()

var selected: bool = false:
	set(value):
		selected = value
		queue_redraw()

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

var text_color: Color = Color.WHITE:
	set(value):
		text_color = value
		_sync_label()

var disabled_text_color: Color = Color.WHITE:
	set(value):
		disabled_text_color = value
		_sync_label()

var outline_color: Color = DEFAULT_OUTLINE_COLOR:
	set(value):
		outline_color = value
		_sync_label()

var outline_size: int = 3:
	set(value):
		outline_size = value
		_sync_label()

var icon_texture: Texture2D = null:
	set(value):
		icon_texture = value
		_sync_icon()

var icon_stage_size: Vector2 = Vector2(29.0, 24.0):
	set(value):
		icon_stage_size = value
		_sync_content_layout()

var icon_gap_stage: float = 8.0:
	set(value):
		icon_gap_stage = value
		_sync_content_layout()

var icon_before_text: bool = false:
	set(value):
		icon_before_text = value
		_sync_content_layout()

var trailing_icon_texture: Texture2D = null:
	set(value):
		trailing_icon_texture = value
		_sync_trailing_icon()

var trailing_icon_stage_size: Vector2 = Vector2(29.0, 24.0):
	set(value):
		trailing_icon_stage_size = value
		_sync_content_layout()

var trailing_icon_gap_stage: float = 8.0:
	set(value):
		trailing_icon_gap_stage = value
		_sync_content_layout()

var icon_shadow_enabled: bool = false:
	set(value):
		icon_shadow_enabled = value
		_sync_icon()

var trailing_icon_shadow_enabled: bool = false:
	set(value):
		trailing_icon_shadow_enabled = value
		_sync_trailing_icon()

var _button_text_font: Font = UI_FONTS.button_font()
var _label: Label = null
var _icon_shadow_layers: Array[TextureRect] = []
var _icon_shadow_material: ShaderMaterial = null
var _icon_rect: TextureRect = null
var _trailing_icon_shadow_layers: Array[TextureRect] = []
var _trailing_icon_shadow_material: ShaderMaterial = null
var _trailing_icon_rect: TextureRect = null
var _use_normal_parts_when_disabled: bool = false
var _attention_bounce_tween: Tween = null
var _single_attention_shine_tween: Tween = null

func _ready() -> void:
	press_scale_enabled = true
	_ensure_label()
	_ensure_icon_shadow_layers()
	_ensure_icon()
	_ensure_trailing_icon_shadow_layers()
	_ensure_trailing_icon()
	if !resized.is_connected(_sync_content_layout):
		resized.connect(_sync_content_layout)
	super._ready()
	_sync_label()
	_sync_icon()
	_sync_trailing_icon()
	_sync_content_layout()
	_start_attention_bounce()

func _exit_tree() -> void:
	_stop_single_attention_shine()
	_stop_attention_bounce(false)
	super._exit_tree()

func _set_press_scale(is_pressed: bool, animated: bool = true) -> void:
	# The attention loop and the press response animate the same visual scale.
	# Give the pressed state exclusive control while the finger is down, then
	# resume the loop only after the release scale has returned to rest.
	if is_pressed:
		_stop_single_attention_shine()
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
	_stop_single_attention_shine()
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

func play_single_attention_shine() -> void:
	if disabled or !is_inside_tree():
		return
	_stop_single_attention_shine()
	_configure_attention_shine(_attention_shine_width, _attention_shine_strength)
	_reset_attention_shine()
	_single_attention_shine_tween = create_tween()
	_single_attention_shine_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_single_attention_shine_tween.tween_method(
		_set_attention_shine_progress,
		ATTENTION_SHINE_START_PROGRESS,
		ATTENTION_SHINE_END_PROGRESS,
		_attention_shine_duration
	)
	_single_attention_shine_tween.finished.connect(
		_finish_single_attention_shine,
		CONNECT_ONE_SHOT
	)

func _finish_single_attention_shine() -> void:
	_single_attention_shine_tween = null
	_reset_attention_shine()

func _stop_single_attention_shine() -> void:
	if (
		_single_attention_shine_tween != null
		and _single_attention_shine_tween.is_valid()
	):
		_single_attention_shine_tween.kill()
	_single_attention_shine_tween = null
	_reset_attention_shine()

func _draw() -> void:
	var use_pressed_parts: bool = selected or _is_down
	var background_tint: Color = normal_tint
	if disabled:
		# Reuse the pressed relief so the disabled button has the same inverted
		# highlight/shadow direction, but keep it neutral gray and non-interactive.
		use_pressed_parts = true
		background_tint = Color(DISABLED_TINT.r, DISABLED_TINT.g, DISABLED_TINT.b, DISABLED_OPACITY)
	elif selected:
		background_tint = selected_tint
	elif _is_down:
		background_tint = pressed_tint
	var left_texture: Texture2D = PRESSED_LEFT_TEXTURE if use_pressed_parts else NORMAL_LEFT_TEXTURE
	var center_texture: Texture2D = PRESSED_CENTER_TEXTURE if use_pressed_parts else NORMAL_CENTER_TEXTURE
	var right_texture: Texture2D = PRESSED_RIGHT_TEXTURE if use_pressed_parts else NORMAL_RIGHT_TEXTURE
	var visual_size: Vector2 = size * visual_scale
	var visual_rect := Rect2((size - visual_size) * 0.5, visual_size)
	_draw_stretchable_background(left_texture, center_texture, right_texture, visual_rect, background_tint)

func _draw_stretchable_background(left_texture: Texture2D, center_texture: Texture2D, right_texture: Texture2D, rect: Rect2, tint: Color) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return

	var left_source_size: Vector2 = left_texture.get_size()
	var right_source_size: Vector2 = right_texture.get_size()
	var left_width: float = rect.size.y * left_source_size.x / left_source_size.y
	var right_width: float = rect.size.y * right_source_size.x / right_source_size.y
	var cap_width: float = left_width + right_width
	if cap_width > rect.size.x:
		var cap_fit: float = rect.size.x / cap_width
		left_width *= cap_fit
		right_width *= cap_fit

	var center_left: float = rect.position.x + left_width
	var center_right: float = rect.end.x - right_width
	if center_right > center_left:
		var center_rect := Rect2(
			Vector2(center_left, rect.position.y),
			Vector2(center_right - center_left, rect.size.y)
		)
		draw_texture_rect(center_texture, center_rect, false, tint)

	draw_texture_rect(left_texture, Rect2(rect.position, Vector2(left_width, rect.size.y)), false, tint)
	draw_texture_rect(
		right_texture,
		Rect2(Vector2(rect.end.x - right_width, rect.position.y), Vector2(right_width, rect.size.y)),
		false,
		tint
	)

func set_color_preset(preset: int) -> void:
	match preset:
		ColorPreset.GREEN:
			color_preset = ColorPreset.GREEN
			_apply_outline_style(DEFAULT_OUTLINE_COLOR, 3)
			_apply_color_palette(GREEN_NORMAL_TINT, GREEN_PRESSED_TINT, GREEN_SELECTED_TINT)
		ColorPreset.BLUE:
			color_preset = ColorPreset.BLUE
			_apply_outline_style(BLUE_OUTLINE_COLOR, 4)
			_apply_color_palette(BLUE_NORMAL_TINT, BLUE_PRESSED_TINT, BLUE_SELECTED_TINT)
		ColorPreset.CUSTOM:
			color_preset = ColorPreset.CUSTOM
		_:
			color_preset = ColorPreset.ORANGE
			_apply_outline_style(DEFAULT_OUTLINE_COLOR, 3)
			_apply_color_palette(ORANGE_NORMAL_TINT, ORANGE_PRESSED_TINT, ORANGE_SELECTED_TINT)

func _apply_outline_style(color: Color, size_value: int) -> void:
	outline_color = color
	outline_size = size_value

func set_color_palette(normal_color: Color, pressed_color: Color, selected_color: Color = ORANGE_SELECTED_TINT) -> void:
	color_preset = ColorPreset.CUSTOM
	_apply_color_palette(normal_color, pressed_color, selected_color)

func _apply_color_palette(normal_color: Color, pressed_color: Color, selected_color: Color) -> void:
	normal_tint = normal_color
	pressed_tint = pressed_color
	selected_tint = selected_color

func configure(text_value: String, font_size_value: int = 20, disabled_value: bool = false, disabled_overlay_alpha_value: float = 0.32, use_normal_texture_when_disabled: bool = false, selected_value: bool = false) -> void:
	icon_texture = null
	trailing_icon_texture = null
	button_text = text_value
	button_font_size = font_size_value
	disabled_overlay_alpha = disabled_overlay_alpha_value
	_use_normal_parts_when_disabled = use_normal_texture_when_disabled
	selected = selected_value
	button_disabled = disabled_value
	_ensure_label()
	_ensure_icon()
	_ensure_trailing_icon()
	_sync_label()
	_sync_icon()
	_sync_trailing_icon()
	_sync_content_layout()

func _ensure_label() -> void:
	if _label != null and is_instance_valid(_label):
		return
	_label = Label.new()
	_label.name = "Text"
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.clip_text = true
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.z_index = 2
	add_child(_label)

func _create_icon_shadow_layers(prefix: String, material: ShaderMaterial) -> Array[TextureRect]:
	var layers: Array[TextureRect] = []
	for index: int in range(ICON_SHADOW_LAYER_T.size()):
		var layer := TextureRect.new()
		layer.name = "%sExtrusion%02d" % [prefix, index + 1]
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		layer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		layer.z_index = 0
		layer.material = material
		add_child(layer)
		move_child(layer, 0)
		layers.append(layer)
	return layers

func _ensure_icon_shadow_layers() -> void:
	if !_icon_shadow_layers.is_empty():
		return
	_icon_shadow_material = ShaderMaterial.new()
	_icon_shadow_material.shader = ICON_EXTRUSION_SHADER
	_icon_shadow_material.set_shader_parameter("shadow_color", UI_PALETTE.NAV_TEXT_SHADOW)
	_icon_shadow_layers = _create_icon_shadow_layers("Icon", _icon_shadow_material)

func _ensure_trailing_icon_shadow_layers() -> void:
	if !_trailing_icon_shadow_layers.is_empty():
		return
	_trailing_icon_shadow_material = ShaderMaterial.new()
	_trailing_icon_shadow_material.shader = ICON_EXTRUSION_SHADER
	_trailing_icon_shadow_material.set_shader_parameter("shadow_color", UI_PALETTE.NAV_TEXT_SHADOW)
	_trailing_icon_shadow_layers = _create_icon_shadow_layers("TrailingIcon", _trailing_icon_shadow_material)

func _set_icon_shadow_layers_state(
	layers: Array[TextureRect],
	texture: Texture2D,
	visible: bool
) -> void:
	for layer: TextureRect in layers:
		if layer == null or !is_instance_valid(layer):
			continue
		layer.texture = texture
		layer.visible = visible and texture != null
		layer.modulate = Color(1.0, 1.0, 1.0, DISABLED_OPACITY if button_disabled else 1.0)

func _layout_icon_shadow_layers(
	layers: Array[TextureRect],
	base_position: Vector2,
	icon_size: Vector2
) -> void:
	var icon_extent: float = minf(icon_size.x, icon_size.y)
	var shadow_depth: float = clampf(
		icon_extent * ICON_SHADOW_DEPTH_RATIO,
		ICON_SHADOW_DEPTH_MIN,
		ICON_SHADOW_DEPTH_MAX
	)
	var shadow_offset_x: float = minf(
		icon_extent * ICON_SHADOW_OFFSET_X_RATIO,
		ICON_SHADOW_OFFSET_X_MAX
	)
	for index: int in range(layers.size()):
		var layer: TextureRect = layers[index]
		if layer == null or !is_instance_valid(layer):
			continue
		var layer_t: float = float(ICON_SHADOW_LAYER_T[index])
		layer.position = base_position + Vector2(
			shadow_offset_x * layer_t,
			shadow_depth * layer_t
		)
		layer.size = icon_size

func _ensure_icon() -> void:
	if _icon_rect != null and is_instance_valid(_icon_rect):
		return
	_icon_rect = TextureRect.new()
	_icon_rect.name = "Icon"
	_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon_rect.z_index = 1
	add_child(_icon_rect)

func _ensure_trailing_icon() -> void:
	if _trailing_icon_rect != null and is_instance_valid(_trailing_icon_rect):
		return
	_trailing_icon_rect = TextureRect.new()
	_trailing_icon_rect.name = "TrailingIcon"
	_trailing_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_trailing_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_trailing_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_trailing_icon_rect.z_index = 1
	add_child(_trailing_icon_rect)

func _sync_label() -> void:
	if _label == null or !is_instance_valid(_label):
		return
	_label.text = button_text
	_label.add_theme_font_override("font", _button_text_font)
	_label.add_theme_font_size_override("font_size", button_font_size)
	var label_color: Color = disabled_text_color if button_disabled else text_color
	if button_disabled:
		label_color = Color(label_color.r, label_color.g, label_color.b, label_color.a * DISABLED_OPACITY)
	_label.add_theme_color_override("font_color", label_color)
	BUTTON_TEXT_STYLE_SCRIPT.apply_display(_label)
	_sync_content_layout()

func _sync_icon() -> void:
	if _icon_rect == null or !is_instance_valid(_icon_rect):
		return
	_icon_rect.texture = icon_texture
	_icon_rect.visible = icon_texture != null
	_icon_rect.modulate = Color(1.0, 1.0, 1.0, DISABLED_OPACITY if button_disabled else 1.0)
	_set_icon_shadow_layers_state(
		_icon_shadow_layers,
		icon_texture,
		icon_shadow_enabled and icon_texture != null
	)
	if _icon_rect != null and is_instance_valid(_icon_rect):
		_icon_rect.z_index = 1
	if _label != null and is_instance_valid(_label):
		_label.z_index = 2
	_sync_content_layout()

func _sync_trailing_icon() -> void:
	if _trailing_icon_rect == null or !is_instance_valid(_trailing_icon_rect):
		return
	_trailing_icon_rect.texture = trailing_icon_texture
	_trailing_icon_rect.visible = trailing_icon_texture != null
	_trailing_icon_rect.modulate = Color(
		1.0,
		1.0,
		1.0,
		DISABLED_OPACITY if button_disabled else 1.0
	)
	_trailing_icon_rect.z_index = 1
	_set_icon_shadow_layers_state(
		_trailing_icon_shadow_layers,
		trailing_icon_texture,
		trailing_icon_shadow_enabled and trailing_icon_texture != null
	)
	_sync_content_layout()

func _sync_content_layout() -> void:
	if _label == null or !is_instance_valid(_label):
		return
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var has_icon: bool = _icon_rect != null and is_instance_valid(_icon_rect) and icon_texture != null
	var has_trailing_icon: bool = (
		_trailing_icon_rect != null
		and is_instance_valid(_trailing_icon_rect)
		and trailing_icon_texture != null
	)
	if (!has_icon and !has_trailing_icon) or stage_rect.size.x <= 0.0 or stage_rect.size.y <= 0.0:
		_label.position = Vector2.ZERO
		_label.size = size
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if _icon_rect != null and is_instance_valid(_icon_rect):
			_icon_rect.visible = false
		for layer: TextureRect in _icon_shadow_layers:
			if layer != null and is_instance_valid(layer):
				layer.visible = false
		for layer: TextureRect in _trailing_icon_shadow_layers:
			if layer != null and is_instance_valid(layer):
				layer.visible = false
		if _trailing_icon_rect != null and is_instance_valid(_trailing_icon_rect):
			_trailing_icon_rect.visible = false
		_sync_visual_child_scales()
		return

	var scale_to_view := Vector2(size.x / stage_rect.size.x, size.y / stage_rect.size.y)
	var actual_icon_size: Vector2 = icon_stage_size * scale_to_view
	var actual_trailing_icon_size: Vector2 = trailing_icon_stage_size * scale_to_view
	var actual_gap: float = icon_gap_stage * scale_to_view.x
	var actual_trailing_gap: float = trailing_icon_gap_stage * scale_to_view.x
	if _icon_rect != null and is_instance_valid(_icon_rect):
		_icon_rect.visible = has_icon
	_set_icon_shadow_layers_state(
		_icon_shadow_layers,
		icon_texture,
		icon_shadow_enabled and has_icon
	)
	_set_icon_shadow_layers_state(
		_trailing_icon_shadow_layers,
		trailing_icon_texture,
		trailing_icon_shadow_enabled and has_trailing_icon
	)
	if _trailing_icon_rect != null and is_instance_valid(_trailing_icon_rect):
		_trailing_icon_rect.visible = has_trailing_icon

	if button_text.is_empty():
		_label.position = Vector2.ZERO
		_label.size = size
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var icon_group_width: float = 0.0
		if has_icon:
			icon_group_width += actual_icon_size.x
		if has_icon and has_trailing_icon:
			icon_group_width += actual_trailing_gap
		if has_trailing_icon:
			icon_group_width += actual_trailing_icon_size.x
		var icon_cursor_x: float = maxf((size.x - icon_group_width) * 0.5, 0.0)
		if has_icon:
			_icon_rect.position = Vector2(icon_cursor_x, (size.y - actual_icon_size.y) * 0.5)
			_icon_rect.size = actual_icon_size
			_layout_icon_shadow_layers(_icon_shadow_layers, _icon_rect.position, actual_icon_size)
			icon_cursor_x += actual_icon_size.x + (actual_trailing_gap if has_trailing_icon else 0.0)
		if has_trailing_icon:
			_trailing_icon_rect.position = Vector2(
				icon_cursor_x,
				(size.y - actual_trailing_icon_size.y) * 0.5
			)
			_trailing_icon_rect.size = actual_trailing_icon_size
			_layout_icon_shadow_layers(
				_trailing_icon_shadow_layers,
				_trailing_icon_rect.position,
				actual_trailing_icon_size
			)
		_sync_visual_child_scales()
		return

	var font: Font = _label.get_theme_font("font")
	var text_width: float = font.get_string_size(
		button_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		button_font_size
	).x
	var group_width: float = text_width
	if has_icon:
		group_width += actual_icon_size.x + actual_gap
	if has_trailing_icon:
		group_width += actual_trailing_gap + actual_trailing_icon_size.x
	var cursor_x: float = maxf((size.x - group_width) * 0.5, 0.0)

	if has_icon and icon_before_text:
		_icon_rect.position = Vector2(cursor_x, (size.y - actual_icon_size.y) * 0.5)
		_icon_rect.size = actual_icon_size
		_layout_icon_shadow_layers(_icon_shadow_layers, _icon_rect.position, actual_icon_size)
		cursor_x += actual_icon_size.x + actual_gap

	_label.position = Vector2(cursor_x, 0.0)
	_label.size = Vector2(text_width + 2.0, size.y)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	cursor_x += text_width

	if has_icon and !icon_before_text:
		cursor_x += actual_gap
		_icon_rect.position = Vector2(cursor_x, (size.y - actual_icon_size.y) * 0.5)
		_icon_rect.size = actual_icon_size
		_layout_icon_shadow_layers(_icon_shadow_layers, _icon_rect.position, actual_icon_size)
		cursor_x += actual_icon_size.x

	if has_trailing_icon:
		cursor_x += actual_trailing_gap
		_trailing_icon_rect.position = Vector2(
			cursor_x,
			(size.y - actual_trailing_icon_size.y) * 0.5
		)
		_trailing_icon_rect.size = actual_trailing_icon_size
		_layout_icon_shadow_layers(
			_trailing_icon_shadow_layers,
			_trailing_icon_rect.position,
			actual_trailing_icon_size
		)
	_sync_visual_child_scales()
