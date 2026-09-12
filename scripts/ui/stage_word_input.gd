class_name StageWordInput
extends "res://scripts/ui/flash_stage_control.gd"

signal input_submitted(value: String)

const STAGE_TOAST_SCRIPT: GDScript = preload("res://scripts/ui/stage_toast.gd")
const UI_PALETTE: GDScript = preload("res://scripts/ui/ui_palette.gd")
const UI_FONTS: GDScript = preload("res://scripts/ui/ui_fonts.gd")
const WORD_SLOT_LAYOUT_SCRIPT: GDScript = preload("res://scripts/ui/word_slot_layout.gd")

const STAGE_SIZE := Vector2(480.0, 800.0)
const EMPTY_PREVIEW_SLOTS: int = 5
const MIN_FONT_SIZE: int = 18
const KEYBOARD_SAFE_MARGIN_STAGE: float = 24.0
# Match the exact gameplay reveal bounce used when a correct guessed letter
# appears on the word strip.
const WORD_BOUNCE_START_SCALE := Vector2(0.58, 0.58)
const WORD_BOUNCE_PEAK_SCALE := Vector2(1.24, 1.24)
const WORD_BOUNCE_GROW_DURATION: float = 0.18
const WORD_BOUNCE_SETTLE_DURATION: float = 0.24
const VIRTUAL_KEYBOARD_POLL_INTERVAL: float = 0.05

var max_input_length: int = 15
var input_font_size: int = 34
var avoid_virtual_keyboard: bool = false:
	set(value):
		avoid_virtual_keyboard = value
		set_process(avoid_virtual_keyboard and _has_input_focus)
var text_color: Color = UI_PALETTE.UI_BLUE:
	set(value):
		text_color = value
		_rebuild_visuals()
var underline_color: Color = UI_PALETTE.ACCENT_ORANGE:
	set(value):
		underline_color = value
		_rebuild_visuals()

var _line_edit: LineEdit = null
var _visual_root: Control = null
var _has_input_focus: bool = false
var _validation_toast: Control = null
var _word_bounce_tweens: Array[Tween] = []
var _virtual_keyboard_poll_elapsed: float = VIRTUAL_KEYBOARD_POLL_INTERVAL

func configure(initial_text: String, maximum_length: int = 15, font_size: int = 34) -> void:
	max_input_length = maxi(maximum_length, 1)
	input_font_size = maxi(font_size, MIN_FONT_SIZE)
	_ensure_nodes()
	_line_edit.max_length = max_input_length
	_line_edit.text = initial_text
	_move_caret_to_end()
	_rebuild_visuals()

func get_line_edit() -> LineEdit:
	_ensure_nodes()
	return _line_edit

func refresh_display() -> void:
	_move_caret_to_end()
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
		label.pivot_offset = label.size * 0.5
		label.scale = WORD_BOUNCE_START_SCALE
		var bounce_tween := label.create_tween()
		bounce_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		var grow_tweener: PropertyTweener = bounce_tween.tween_property(
			label,
			"scale",
			WORD_BOUNCE_PEAK_SCALE,
			WORD_BOUNCE_GROW_DURATION
		)
		grow_tweener.set_trans(Tween.TRANS_QUAD)
		grow_tweener.set_ease(Tween.EASE_OUT)
		var settle_tweener: PropertyTweener = bounce_tween.tween_property(
			label,
			"scale",
			Vector2.ONE,
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
		# The authored side margins leave room for the same reveal bounce as gameplay.
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
	_line_edit.text_changed.connect(_on_line_edit_text_changed)
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

func _on_line_edit_text_changed(_value: String) -> void:
	_move_caret_to_end()
	_rebuild_visuals()

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
	for child: Node in _visual_root.get_children():
		_visual_root.remove_child(child)
		child.queue_free()
	if size.x <= 0.0 or size.y <= 0.0:
		return

	var value: String = _line_edit.text if _line_edit != null and is_instance_valid(_line_edit) else ""
	var slots := PackedStringArray()
	if value.is_empty():
		for _slot_index: int in range(EMPTY_PREVIEW_SLOTS):
			slots.append("")
	else:
		for character_index: int in range(value.length()):
			slots.append(value.substr(character_index, 1))

	# Resolve the same font axes, center rhythm, separators and underline geometry
	# as gameplay. Input text is passed directly; GameSession is never modified.
	var resolved: Dictionary = WORD_SLOT_LAYOUT_SCRIPT.new(slots).resolve(size, input_font_size)
	var items: Array = resolved["items"]
	var word_font: Font = resolved["font"]
	var resolved_font_size: int = int(resolved["font_size"])
	var underline_width: float = float(resolved["underline_width"])
	var underline_height: float = float(resolved["underline_height"])
	var start_x: float = float(resolved["start_x"])
	var baseline_y: float = float(resolved["baseline_y"])
	for slot_index: int in range(slots.size()):
		var character: String = slots[slot_index]
		var item: Dictionary = items[slot_index]
		var slot_width: float = float(item["width"])
		var x: float = start_x + float(item["left"])
		var center_x: float = start_x + float(item["center"])
		var is_space: bool = character == " "
		var is_separator: bool = character == "—" or character == "-"
		var is_active_slot: bool = (
			(value.is_empty() and slot_index == 0)
			or (
				!value.is_empty()
				and slot_index == value.length()
				and value.length() < max_input_length
			)
		)
		if !is_space and !is_separator:
			var line := ColorRect.new()
			line.mouse_filter = Control.MOUSE_FILTER_IGNORE
			line.color = underline_color.lightened(0.16) if is_active_slot and _has_input_focus else underline_color
			line.position = Vector2(
				center_x - underline_width * 0.5,
				baseline_y
			)
			line.size = Vector2(underline_width, underline_height)
			_visual_root.add_child(line)
		if !character.is_empty() and !is_space:
			var label := Label.new()
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			label.position = Vector2(x, 0.0)
			label.size = Vector2(slot_width, size.y - 10.0)
			label.text = WORD_SLOT_LAYOUT_SCRIPT.display_text(character)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			label.autowrap_mode = TextServer.AUTOWRAP_OFF
			label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
			# Match gameplay: allow the reveal bounce to extend beyond the glyph box.
			label.clip_text = false
			label.add_theme_font_override("font", word_font)
			label.add_theme_font_size_override("font_size", resolved_font_size)
			label.add_theme_color_override("font_color", text_color)
			label.set_meta(&"word_slot_index", slot_index)
			_visual_root.add_child(label)
