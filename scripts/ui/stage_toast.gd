class_name StageToast
extends Panel

const TOAST_HEIGHT: float = 40.0
const TOAST_PARENT_GAP: float = 8.0
const TOAST_HORIZONTAL_PADDING: float = 10.0
const TOAST_ICON_TEXT_GAP: float = 5.0
const TOAST_ICON_FONT_SIZE: int = 26
const TOAST_TEXT_FONT_SIZE: int = 18
const TOAST_ENTER_OFFSET: float = 8.0
const TOAST_ENTER_DURATION: float = 0.16
const TOAST_HOLD_DURATION: float = 1.65
const TOAST_EXIT_DURATION: float = 0.22
const TOAST_BACKGROUND := Color(0.2314, 0.2627, 0.5176, 0.96)
const TOAST_SUCCESS := Color(0.24, 0.82, 0.43, 1.0)
const TOAST_FAILURE := Color(0.96, 0.28, 0.30, 1.0)

var _available_width: float = 0.0
var _status_icon: Label = null
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
	_status_icon.text = "✓" if is_success else "×"
	_status_icon.add_theme_color_override(
		"font_color",
		TOAST_SUCCESS if is_success else TOAST_FAILURE
	)
	_message_label.text = message
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
	_status_icon = Label.new()
	_status_icon.name = "StatusIcon"
	_status_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status_icon.add_theme_font_size_override("font_size", TOAST_ICON_FONT_SIZE)
	add_child(_status_icon)

	_message_label = Label.new()
	_message_label.name = "Message"
	_message_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_message_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_message_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_message_label.clip_text = true
	_message_label.add_theme_font_size_override("font_size", TOAST_TEXT_FONT_SIZE)
	_message_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(_message_label)

func _layout_message() -> void:
	if _status_icon == null or !is_instance_valid(_status_icon):
		return
	var icon_font: Font = _status_icon.get_theme_font("font")
	var message_font: Font = _message_label.get_theme_font("font")
	var icon_width: float = ceilf(icon_font.get_string_size(
		_status_icon.text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		TOAST_ICON_FONT_SIZE
	).x)
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
	_status_icon.position = Vector2(TOAST_HORIZONTAL_PADDING, 0.0)
	_status_icon.size = Vector2(icon_width, TOAST_HEIGHT)
	_message_label.position = Vector2(
		TOAST_HORIZONTAL_PADDING + icon_width + TOAST_ICON_TEXT_GAP,
		0.0
	)
	_message_label.size = Vector2(message_width, TOAST_HEIGHT)

func _finish_message() -> void:
	_toast_tween = null
	visible = false
