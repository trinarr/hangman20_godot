class_name StageWordInput
extends "res://scripts/ui/flash_stage_control.gd"

signal input_submitted(value: String)

const STAGE_TOAST_SCRIPT: GDScript = preload("res://scripts/ui/stage_toast.gd")
const UI_PALETTE: GDScript = preload("res://scripts/ui/ui_palette.gd")
const UI_FONTS: GDScript = preload("res://scripts/ui/ui_fonts.gd")
const BUTTON_TEXT_STYLE_SCRIPT: GDScript = preload("res://scripts/ui/button_text_style.gd")
const WORD_SLOT_LAYOUT_SCRIPT: GDScript = preload("res://scripts/ui/word_slot_layout.gd")

const STAGE_SIZE := Vector2(480.0, 800.0)
const MIN_FONT_SIZE: int = 24
const INPUT_TEXT_SIDE_PADDING: float = 2.0
# Keep glyph proportions readable; do not bypass this axis floor with scale.x.
const INPUT_MIN_WIDTH: float = 30.0
const INPUT_TEXT_EFFECT_PADDING: float = 12.0
const MARKER_BASE_ALPHA: float = 0.35
const MARKER_DETAIL_ALPHA: float = 0.70
const KEYBOARD_SAFE_MARGIN_STAGE: float = 24.0
# Match the exact gameplay reveal bounce used when a correct guessed letter
# appears on the word strip.
const WORD_BOUNCE_START_SCALE := Vector2(0.58, 0.58)
const WORD_BOUNCE_PEAK_SCALE := Vector2(1.24, 1.24)
const WORD_BOUNCE_GROW_DURATION: float = 0.18
const WORD_BOUNCE_SETTLE_DURATION: float = 0.24
const VIRTUAL_KEYBOARD_POLL_INTERVAL: float = 0.05

var max_input_length: int = 20
var input_font_size: int = 34
var avoid_virtual_keyboard: bool = false:
	set(value):
		avoid_virtual_keyboard = value
		set_process(avoid_virtual_keyboard and _has_input_focus)
var text_color: Color = Color.WHITE:
	set(value):
		text_color = value
		_apply_display_text_style()
var marker_color: Color = UI_PALETTE.MARKER_INFO:
	set(value):
		marker_color = value
		_apply_marker_tint()
		_apply_display_text_style()

var _line_edit: LineEdit = null
var _visual_text: String = ""
var _display_content_width: float = -1.0
var _visual_root: Control = null
var _display_label: Label = null
var _marker_node: Node2D = null
var _has_input_focus: bool = false
var _validation_toast: Control = null
var _word_bounce_tweens: Array[Tween] = []
var _virtual_keyboard_poll_elapsed: float = VIRTUAL_KEYBOARD_POLL_INTERVAL

func configure(initial_text: String, maximum_length: int = 20, font_size: int = 34) -> void:
	max_input_length = maxi(maximum_length, 1)
	input_font_size = maxi(font_size, MIN_FONT_SIZE)
	_ensure_nodes()
	_line_edit.max_length = max_input_length
	_line_edit.text = initial_text
	_visual_text = initial_text.substr(0, max_input_length)
	_move_caret_to_end()
	_rebuild_visuals()

func get_line_edit() -> LineEdit:
	_ensure_nodes()
	return _line_edit


func set_marker_node(marker: Node2D) -> void:
	_marker_node = marker
	_apply_marker_tint()

func set_display_content_width(width: float) -> void:
	# The transparent native LineEdit deliberately remains full-width for IME/focus.
	# Only the rendered word is constrained to the supplied display area.
	_display_content_width = maxf(width, 1.0)
	_rebuild_visuals()

func set_marker_tint(color: Color) -> void:
	marker_color = color

func set_display_text(value: String) -> void:
	# Keep the visible, normalized word separate from the native LineEdit buffer.
	# Android IMEs can keep an active composition range inside LineEdit; rewriting
	# its text/caret from text_changed can invalidate that composition and leave
	# the keyboard visible while subsequent key presses stop reaching the field.
	_visual_text = value.substr(0, max_input_length)
	_rebuild_visuals()

func play_word_bounce() -> void:
	_play_letter_bounce_from_slot(0)

func play_new_letter_bounce(first_slot_index: int) -> void:
	_play_letter_bounce_from_slot(maxi(first_slot_index, 0))

func _play_letter_bounce_from_slot(first_slot_index: int) -> void:
	if _visual_root == null or !is_instance_valid(_visual_root) or !is_inside_tree():
		return
	for bounce_tween: Tween in _word_bounce_tweens:
		if bounce_tween != null and bounce_tween.is_valid():
			bounce_tween.kill()
	_word_bounce_tweens.clear()

	# Use the same scale envelope as a newly revealed gameplay letter. Only glyph
	# Labels participate; the orange answer slots are separate ColorRects and stay
	# completely fixed.
	for child: Node in _visual_root.get_children():
		var label := child as Label
		if label == null or label.text.is_empty() or label.text in ["-", "—", "−"]:
			continue
		var slot_index: int = int(label.get_meta(&"word_slot_index", -1))
		if slot_index < first_slot_index:
			continue
		var rest_scale: Vector2 = label.get_meta(&"input_rest_scale", Vector2.ONE)
		var peak_x: float = float(label.get_meta(&"input_bounce_peak_x", WORD_BOUNCE_PEAK_SCALE.x))
		label.pivot_offset = label.size * 0.5
		label.scale = rest_scale * WORD_BOUNCE_START_SCALE
		var bounce_tween := label.create_tween()
		bounce_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		var grow_tweener: PropertyTweener = bounce_tween.tween_property(
			label,
			"scale",
			rest_scale * Vector2(peak_x, WORD_BOUNCE_PEAK_SCALE.y),
			WORD_BOUNCE_GROW_DURATION
		)
		grow_tweener.set_trans(Tween.TRANS_QUAD)
		grow_tweener.set_ease(Tween.EASE_OUT)
		var settle_tweener: PropertyTweener = bounce_tween.tween_property(
			label,
			"scale",
			rest_scale,
			WORD_BOUNCE_SETTLE_DURATION
		)
		settle_tweener.set_trans(Tween.TRANS_BACK)
		settle_tweener.set_ease(Tween.EASE_OUT)
		_word_bounce_tweens.append(bounce_tween)
		bounce_tween.finished.connect(
			_prune_finished_word_bounce_tweens,
			CONNECT_ONE_SHOT
		)

func _prune_finished_word_bounce_tweens() -> void:
	var active_tweens: Array[Tween] = []
	for bounce_tween: Tween in _word_bounce_tweens:
		if bounce_tween != null and bounce_tween.is_valid() and bounce_tween.is_running():
			active_tweens.append(bounce_tween)
	_word_bounce_tweens = active_tweens

func show_validation_toast(message_key: StringName, is_success: bool) -> void:
	_ensure_nodes()
	_validation_toast.call("show_translation", message_key, is_success)

func hide_validation_toast() -> void:
	if _validation_toast != null and is_instance_valid(_validation_toast):
		_validation_toast.call("hide_message")

func _ready() -> void:
	_ensure_nodes()
	if !resized.is_connected(_rebuild_visuals):
		resized.connect(_rebuild_visuals)
	super._ready()
	set_process(avoid_virtual_keyboard and _has_input_focus)
	_rebuild_visuals()

func _exit_tree() -> void:
	for bounce_tween: Tween in _word_bounce_tweens:
		if bounce_tween != null and bounce_tween.is_valid():
			bounce_tween.kill()
	_word_bounce_tweens.clear()
	super._exit_tree()

func _process(delta: float) -> void:
	_virtual_keyboard_poll_elapsed += maxf(delta, 0.0)
	if _virtual_keyboard_poll_elapsed < VIRTUAL_KEYBOARD_POLL_INTERVAL:
		return
	_virtual_keyboard_poll_elapsed = fposmod(
		_virtual_keyboard_poll_elapsed,
		VIRTUAL_KEYBOARD_POLL_INTERVAL
	)
	_sync_to_stage()

func _sync_to_stage() -> void:
	super._sync_to_stage()
	_apply_virtual_keyboard_avoidance()

func _apply_virtual_keyboard_avoidance() -> void:
	if !avoid_virtual_keyboard or !_has_input_focus or !is_inside_tree():
		return
	var keyboard_height: float = float(DisplayServer.virtual_keyboard_get_height())
	if keyboard_height <= 0.0:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var window_size: Vector2i = DisplayServer.window_get_size()
	if viewport_size.y <= 0.0 or window_size.y <= 0:
		return

	# DisplayServer reports the IME in physical window pixels, while Controls
	# use root-viewport pixels. Keep the underline row above the moving keyboard
	# edge without changing its authored centered position when the IME is hidden.
	var keyboard_height_viewport: float = keyboard_height * viewport_size.y / float(window_size.y)
	var keyboard_top: float = viewport_size.y - keyboard_height_viewport
	var global_transform: Transform2D = get_global_transform()
	var global_bottom: float = maxf(
		(global_transform * Vector2(0.0, size.y)).y,
		(global_transform * Vector2(size.x, size.y)).y
	)
	var stage_to_viewport_scale: float = viewport_size.x / STAGE_SIZE.x
	var overlap: float = global_bottom + KEYBOARD_SAFE_MARGIN_STAGE * stage_to_viewport_scale - keyboard_top
	if overlap <= 0.0:
		return

	var parent_scale_y: float = 1.0
	if get_parent() is CanvasItem:
		parent_scale_y = maxf((get_parent() as CanvasItem).get_global_transform().y.length(), 0.001)
	position.y -= overlap / parent_scale_y

func _ensure_nodes() -> void:
	if _visual_root == null or !is_instance_valid(_visual_root):
		_visual_root = Control.new()
		_visual_root.name = "WordSlots"
		_visual_root.set_anchors_preset(Control.PRESET_FULL_RECT)
		_visual_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# The bounce peak is bounded separately using the fitted text width.
		_visual_root.clip_contents = false
		add_child(_visual_root)

	if _line_edit != null and is_instance_valid(_line_edit):
		_ensure_validation_toast()
		return
	_line_edit = LineEdit.new()
	_line_edit.name = "NativeKeyboardInput"
	_line_edit.set_anchors_preset(Control.PRESET_FULL_RECT)
	_line_edit.max_length = max_input_length
	_line_edit.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_line_edit.virtual_keyboard_enabled = true
	_line_edit.virtual_keyboard_show_on_focus = true
	_line_edit.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_DEFAULT
	_line_edit.mouse_default_cursor_shape = Control.CURSOR_IBEAM
	_line_edit.add_theme_font_override("font", UI_FONTS.gameplay_word_font())
	_line_edit.add_theme_font_size_override("font_size", input_font_size)
	_line_edit.add_theme_color_override("font_color", Color.TRANSPARENT)
	_line_edit.add_theme_color_override("font_selected_color", Color.TRANSPARENT)
	_line_edit.add_theme_color_override("font_uneditable_color", Color.TRANSPARENT)
	_line_edit.add_theme_color_override("caret_color", Color.TRANSPARENT)
	_line_edit.add_theme_color_override("selection_color", Color.TRANSPARENT)
	_line_edit.add_theme_color_override("font_placeholder_color", Color.TRANSPARENT)
	var empty_style := StyleBoxEmpty.new()
	_line_edit.add_theme_stylebox_override("normal", empty_style)
	_line_edit.add_theme_stylebox_override("focus", empty_style)
	_line_edit.add_theme_stylebox_override("read_only", empty_style)
	_line_edit.text_submitted.connect(_on_line_edit_text_submitted)
	_line_edit.focus_entered.connect(_on_focus_entered)
	_line_edit.focus_exited.connect(_on_focus_exited)
	_line_edit.gui_input.connect(_on_line_edit_gui_input)
	add_child(_line_edit)
	_ensure_validation_toast()

func _ensure_validation_toast() -> void:
	if _validation_toast != null and is_instance_valid(_validation_toast):
		return
	_validation_toast = STAGE_TOAST_SCRIPT.new() as Control
	_validation_toast.name = "ValidationToast"
	add_child(_validation_toast)
	_validation_toast.call("set_available_width", size.x)

func _on_line_edit_text_submitted(value: String) -> void:
	_line_edit.release_focus()
	DisplayServer.virtual_keyboard_hide()
	input_submitted.emit(value)

func _on_focus_entered() -> void:
	_has_input_focus = true
	_virtual_keyboard_poll_elapsed = VIRTUAL_KEYBOARD_POLL_INTERVAL
	set_process(avoid_virtual_keyboard)
	_move_caret_to_end()
	_rebuild_visuals()

func _on_focus_exited() -> void:
	_has_input_focus = false
	set_process(false)
	_rebuild_visuals()

func _on_line_edit_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		call_deferred("_move_caret_to_end")
	elif event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		call_deferred("_move_caret_to_end")

func _move_caret_to_end() -> void:
	if _line_edit == null or !is_instance_valid(_line_edit):
		return
	_line_edit.caret_column = _line_edit.text.length()
	_line_edit.deselect()

func _rebuild_visuals() -> void:
	if _visual_root == null or !is_instance_valid(_visual_root):
		return
	if _validation_toast != null and is_instance_valid(_validation_toast):
		_validation_toast.call("set_available_width", size.x)
	for bounce_tween: Tween in _word_bounce_tweens:
		if bounce_tween != null and bounce_tween.is_valid():
			bounce_tween.kill()
	_word_bounce_tweens.clear()
	for child: Node in _visual_root.get_children():
		_visual_root.remove_child(child)
		child.queue_free()
	_display_label = null
	if size.x <= 0.0 or size.y <= 0.0:
		return

	# The two-player input now uses the same visual language as the screen title:
	# one centered display label over a hand-drawn marker. The native LineEdit
	# remains transparent above it so Android/iOS IME composition is untouched.
	var display_value: String = WORD_SLOT_LAYOUT_SCRIPT.display_text(_visual_text)
	if display_value.is_empty():
		return

	var content_width: float = size.x
	if _display_content_width > 0.0:
		content_width = minf(_display_content_width, size.x)
	var text_area_width: float = maxf(
		content_width - INPUT_TEXT_SIDE_PADDING * 2.0,
		1.0
	)
	# Fit against authored geometry, never Label.size: an unwrapped Label may
	# enlarge itself to its text minimum before its final font has been assigned.
	var fit: Dictionary = _resolved_display_font(
		display_value, maxf(text_area_width - INPUT_TEXT_EFFECT_PADDING, 1.0)
	)
	var label_width: float = text_area_width
	var label := Label.new()
	label.name = "InputText"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# A fixed, clipped layout box prevents native minimum-size growth. The full
	# text is already fitted with room for outline/shadow; clipping is only a guard.
	label.clip_text = true
	label.add_theme_font_override("font", fit["font"] as Font)
	label.add_theme_font_size_override("font_size", int(fit["font_size"]))
	label.position = Vector2((size.x - label_width) * 0.5, 0.0)
	label.size = Vector2(label_width, size.y)
	label.pivot_offset = label.size * 0.5
	label.scale = Vector2.ONE
	label.set_meta(&"input_rest_scale", label.scale)
	var occupied_width: float = float(fit["measured_width"]) + INPUT_TEXT_EFFECT_PADDING
	label.set_meta(&"input_bounce_peak_x", clampf(
		(content_width - 8.0) / maxf(occupied_width, 1.0),
		1.0, WORD_BOUNCE_PEAK_SCALE.x
	))
	label.text = display_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	label.add_theme_color_override("font_color", text_color)
	label.set_meta(&"word_slot_index", 0)
	_visual_root.add_child(label)
	_display_label = label
	_apply_display_text_style()

func _resolved_display_font(value: String, available_width: float) -> Dictionary:
	var resolved_size: int = maxi(input_font_size, MIN_FONT_SIZE)
	var resolved_width: float = UI_FONTS.ROBOTO_FLEX_DISPLAY_WIDTH
	var font: Font = UI_FONTS.display_font_with_width(resolved_width)
	var measured: float = font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, resolved_size).x
	# Like the result word, exhaust width adjustment before reducing font size.
	# Stop at wdth=30 and preserve the font's native proportions afterwards.
	while measured > available_width and resolved_width > INPUT_MIN_WIDTH:
		resolved_width = maxf(resolved_width - 1.0, INPUT_MIN_WIDTH)
		font = UI_FONTS.display_font_with_width(resolved_width)
		measured = font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, resolved_size).x
	# Extremely wide 20-letter words may need less than the old 24 px floor.
	# Reduce size uniformly rather than squeezing glyphs or overflowing the field.
	while measured > available_width and resolved_size > 1:
		resolved_size -= 1
		measured = font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, resolved_size).x
	return {
		"font": font,
		"font_size": resolved_size,
		"measured_width": measured,
	}

func _apply_display_text_style() -> void:
	if _display_label == null or !is_instance_valid(_display_label):
		return
	_display_label.add_theme_color_override("font_color", text_color)
	BUTTON_TEXT_STYLE_SCRIPT.apply_display_tinted(
		_display_label,
		marker_color.darkened(0.42),
		marker_color.darkened(0.62)
	)

func _apply_marker_tint() -> void:
	if _marker_node == null or !is_instance_valid(_marker_node):
		return
	var base_layer := _marker_node.get_node_or_null("BaseLayer") as CanvasGroup
	if base_layer != null and is_instance_valid(base_layer):
		base_layer.self_modulate = Color(
			marker_color.r,
			marker_color.g,
			marker_color.b,
			MARKER_BASE_ALPHA
		)
	var detail_layer := _marker_node.get_node_or_null("DetailLayer") as CanvasGroup
	if detail_layer != null and is_instance_valid(detail_layer):
		var darker_marker: Color = marker_color.darkened(0.10)
		detail_layer.self_modulate = Color(
			darker_marker.r,
			darker_marker.g,
			darker_marker.b,
			MARKER_DETAIL_ALPHA
		)
