class_name StageToast
extends Panel

const UI_PALETTE: GDScript = preload("res://scripts/ui/ui_palette.gd")
const UI_FONTS: GDScript = preload("res://scripts/ui/ui_fonts.gd")
const UI_MATERIALS: GDScript = preload("res://scripts/ui/ui_materials.gd")
const BUTTON_TEXT_STYLE_SCRIPT: GDScript = preload("res://scripts/ui/button_text_style.gd")
const DISPLAY_TEXT_EFFECT_SCRIPT: GDScript = preload("res://scripts/ui/display_text_effect.gd")

const TOAST_HEIGHT: float = 44.2
const TOAST_PARENT_GAP: float = 8.84
const TOAST_HORIZONTAL_PADDING: float = 11.05
const TOAST_ICON_TEXT_GAP: float = 5.525
const TOAST_TEXT_FONT_SIZE: int = 20
const TOAST_ICON_SIZE: float = 26.52
const TOAST_ICON_STROKE_WIDTH: float = 4.9725
const TOAST_ICON_SHADOW_LAYER_T := [0.25, 0.55, 0.80, 1.0]
const TOAST_ENTER_OFFSET: float = 8.84
const TOAST_ENTER_DURATION: float = 0.16
const TOAST_HOLD_DURATION: float = 1.65
const TOAST_EXIT_DURATION: float = 0.22
const TOAST_BACKGROUND := UI_PALETTE.TOAST_BACKGROUND
const STATUS_ICON_SCRIPT: GDScript = preload("res://scripts/ui/stage_status_icon.gd")

var _available_width: float = 0.0
var _status_icon: Control = null
var _status_icon_shadow_layers: Array[Control] = []
var _message_label: Label = null
var _toast_tween: Tween = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	z_index = 20
	var background := StyleBoxFlat.new()
	background.bg_color = TOAST_BACKGROUND
	add_theme_stylebox_override("panel", background)
	_ensure_content()

func set_available_width(value: float) -> void:
	_available_width = maxf(value, 0.0)
	_ensure_content()
	_layout_message()

func show_message(message: String, is_success: bool) -> void:
	if message.is_empty():
		hide_message()
		return
	_ensure_content()
	_status_icon.call("configure", is_success, TOAST_ICON_STROKE_WIDTH)
	for shadow_icon: Control in _status_icon_shadow_layers:
		if shadow_icon != null and is_instance_valid(shadow_icon):
			shadow_icon.call("configure", is_success, TOAST_ICON_STROKE_WIDTH)
	_message_label.text = message.to_upper()
	_layout_message()
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()

	var rest_position: Vector2 = position
	visible = true
	modulate = Color(1.0, 1.0, 1.0, 0.0)
	position = rest_position + Vector2(0.0, TOAST_ENTER_OFFSET)
	_toast_tween = create_tween()
	_toast_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_toast_tween.tween_property(
		self,
		"position",
		rest_position,
		TOAST_ENTER_DURATION
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_toast_tween.parallel().tween_property(
		self,
		"modulate:a",
		1.0,
		TOAST_ENTER_DURATION
	)
	_toast_tween.tween_interval(TOAST_HOLD_DURATION)
	_toast_tween.tween_property(
		self,
		"modulate:a",
		0.0,
		TOAST_EXIT_DURATION
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_toast_tween.tween_callback(_finish_message)

func show_translation(message_key: StringName, is_success: bool) -> void:
	show_message(tr(message_key), is_success)

func hide_message() -> void:
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = null
	visible = false
	modulate = Color.WHITE

func _exit_tree() -> void:
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = null

func _ensure_content() -> void:
	if _status_icon != null and is_instance_valid(_status_icon):
		return
	var icon_shadow_material: ShaderMaterial = UI_MATERIALS.text_shadow(UI_PALETTE.NAV_TEXT_SHADOW)
	for layer_index: int in range(TOAST_ICON_SHADOW_LAYER_T.size()):
		var shadow_icon: Control = STATUS_ICON_SCRIPT.new() as Control
		shadow_icon.name = "StatusIconExtrusion%02d" % (layer_index + 1)
		shadow_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shadow_icon.material = icon_shadow_material
		shadow_icon.z_index = 0
		add_child(shadow_icon)
		_status_icon_shadow_layers.append(shadow_icon)

	_status_icon = STATUS_ICON_SCRIPT.new() as Control
	_status_icon.name = "StatusIcon"
	_status_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_icon.z_index = 1
	add_child(_status_icon)

	_message_label = Label.new()
	_message_label.name = "Message"
	_message_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_message_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_message_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_message_label.clip_text = true
	_message_label.add_theme_font_override("font", UI_FONTS.button_font())
	_message_label.add_theme_font_size_override("font_size", TOAST_TEXT_FONT_SIZE)
	_message_label.add_theme_color_override("font_color", Color.WHITE)
	_message_label.z_index = 2
	BUTTON_TEXT_STYLE_SCRIPT.apply_display(_message_label)
	add_child(_message_label)

func _layout_message() -> void:
	if _status_icon == null or !is_instance_valid(_status_icon):
		return
	var icon_width: float = TOAST_ICON_SIZE
	var message_font: Font = _message_label.get_theme_font("font")
	var measured_message_width: float = ceilf(message_font.get_string_size(
		_message_label.text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		TOAST_TEXT_FONT_SIZE
	).x)
	var maximum_message_width: float = maxf(
		_available_width
			- TOAST_HORIZONTAL_PADDING * 2.0
			- icon_width
			- TOAST_ICON_TEXT_GAP,
		1.0
	)
	var message_width: float = minf(measured_message_width, maximum_message_width)
	var toast_width: float = (
		TOAST_HORIZONTAL_PADDING * 2.0
		+ icon_width
		+ TOAST_ICON_TEXT_GAP
		+ message_width
	)
	size = Vector2(toast_width, TOAST_HEIGHT)
	position = Vector2(
		(_available_width - toast_width) * 0.5,
		-TOAST_HEIGHT - TOAST_PARENT_GAP
	)
	_status_icon.position = Vector2(
		TOAST_HORIZONTAL_PADDING,
		(TOAST_HEIGHT - icon_width) * 0.5
	)
	_status_icon.size = Vector2(icon_width, icon_width)
	var icon_shadow_depth: float = clampf(
		float(TOAST_TEXT_FONT_SIZE) * DISPLAY_TEXT_EFFECT_SCRIPT.SHADOW_DEPTH_RATIO,
		DISPLAY_TEXT_EFFECT_SCRIPT.SHADOW_DEPTH_MIN,
		DISPLAY_TEXT_EFFECT_SCRIPT.SHADOW_DEPTH_MAX
	)
	var icon_shadow_offset_x: float = minf(
		float(TOAST_TEXT_FONT_SIZE) * DISPLAY_TEXT_EFFECT_SCRIPT.SHADOW_OFFSET_X_RATIO,
		DISPLAY_TEXT_EFFECT_SCRIPT.SHADOW_OFFSET_X_MAX
	)
	for layer_index: int in range(_status_icon_shadow_layers.size()):
		var shadow_icon: Control = _status_icon_shadow_layers[layer_index]
		if shadow_icon == null or !is_instance_valid(shadow_icon):
			continue
		var layer_t: float = float(TOAST_ICON_SHADOW_LAYER_T[layer_index])
		shadow_icon.position = _status_icon.position + Vector2(
			icon_shadow_offset_x * layer_t,
			icon_shadow_depth * layer_t
		)
		shadow_icon.size = Vector2(icon_width, icon_width)
	_message_label.position = Vector2(
		TOAST_HORIZONTAL_PADDING + icon_width + TOAST_ICON_TEXT_GAP,
		0.0
	)
	_message_label.size = Vector2(message_width, TOAST_HEIGHT)

func _finish_message() -> void:
	_toast_tween = null
	visible = false
