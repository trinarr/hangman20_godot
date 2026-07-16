class_name FlashStageTextureButton
extends Control

signal pressed

const STAGE_SIZE: Vector2 = Vector2(480.0, 800.0)
const PORTRAIT_LAYOUT: GDScript = preload("res://scripts/ui/portrait_stage_layout.gd")

var stage_rect: Rect2 = Rect2(0.0, 0.0, 0.0, 0.0):
	set(value):
		stage_rect = value
		_sync_to_stage()

var texture_normal: Texture2D:
	set(value):
		texture_normal = value
		queue_redraw()

var texture_pressed: Texture2D:
	set(value):
		texture_pressed = value
		queue_redraw()

var texture_disabled: Texture2D:
	set(value):
		texture_disabled = value
		queue_redraw()

var disabled_overlay_alpha: float = 0.32:
	set(value):
		disabled_overlay_alpha = value
		queue_redraw()

var disabled: bool = false:
	set(value):
		disabled = value
		mouse_filter = Control.MOUSE_FILTER_IGNORE if disabled else Control.MOUSE_FILTER_STOP
		mouse_default_cursor_shape = Control.CURSOR_ARROW if disabled else Control.CURSOR_POINTING_HAND
		if disabled:
			_is_down = false
			_set_press_scale(false, false)
		queue_redraw()

# Long and round button components enable this behavior. Other texture buttons
# keep their previous interaction and size.
var press_scale_enabled: bool = false
var pressed_scale: Vector2 = Vector2(0.9, 0.9)
var press_scale_duration: float = 0.055
var release_scale_duration: float = 0.085

var visual_scale: Vector2 = Vector2.ONE:
	set(value):
		visual_scale = value
		_sync_visual_child_scales()
		queue_redraw()

var _is_down: bool = false
var _press_scale_tween: Tween = null

func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE if disabled else Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_ARROW if disabled else Control.CURSOR_POINTING_HAND
	focus_mode = Control.FOCUS_NONE
	if !resized.is_connected(_sync_visual_child_scales):
		resized.connect(_sync_visual_child_scales)
	if !get_viewport().size_changed.is_connected(_sync_to_stage):
		get_viewport().size_changed.connect(_sync_to_stage)
	_sync_to_stage()

func _exit_tree() -> void:
	if _press_scale_tween != null and _press_scale_tween.is_valid():
		_press_scale_tween.kill()
	if get_viewport() != null and get_viewport().size_changed.is_connected(_sync_to_stage):
		get_viewport().size_changed.disconnect(_sync_to_stage)

func _draw() -> void:
	var texture := texture_normal
	if disabled and texture_disabled != null:
		texture = texture_disabled
	elif _is_down and texture_pressed != null:
		texture = texture_pressed
	var visual_size: Vector2 = size * visual_scale
	var visual_rect := Rect2((size - visual_size) * 0.5, visual_size)
	if texture != null:
		draw_texture_rect(texture, visual_rect, false)
	# Do not add a rectangular fallback overlay when a selected-state button
	# deliberately uses the same bitmap for normal and pressed states. The
	# bitmap itself already represents the blue selected state.
	if disabled and disabled_overlay_alpha > 0.0:
		draw_rect(visual_rect, Color(1.0, 1.0, 1.0, disabled_overlay_alpha), true)

func _gui_input(event: InputEvent) -> void:
	if disabled:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse_event.pressed:
			_is_down = true
			_set_press_scale(true)
			accept_event()
			queue_redraw()
		else:
			var was_down := _is_down
			_is_down = false
			_set_press_scale(false)
			accept_event()
			queue_redraw()
			if was_down and Rect2(Vector2.ZERO, size).has_point(mouse_event.position):
				pressed.emit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT and _is_down:
		_is_down = false
		_set_press_scale(false)
		queue_redraw()

func _set_press_scale(is_pressed: bool, animated: bool = true) -> void:
	if !press_scale_enabled:
		return
	var target_scale: Vector2 = pressed_scale if is_pressed else Vector2.ONE
	if _press_scale_tween != null and _press_scale_tween.is_valid():
		_press_scale_tween.kill()
	if !animated or !is_inside_tree():
		visual_scale = target_scale
		return
	var duration: float = press_scale_duration if is_pressed else release_scale_duration
	_press_scale_tween = create_tween()
	_press_scale_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var scale_tweener: PropertyTweener = _press_scale_tween.tween_property(self, "visual_scale", target_scale, duration)
	scale_tweener.set_trans(Tween.TRANS_QUAD)
	scale_tweener.set_ease(Tween.EASE_OUT)

func _sync_to_stage() -> void:
	if !is_inside_tree():
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var fit_scale: float = PORTRAIT_LAYOUT.fit_scale(viewport_size)
	var mapped_position: Vector2 = PORTRAIT_LAYOUT.map_rect_position(stage_rect, viewport_size, self)
	position = Vector2(PORTRAIT_LAYOUT.horizontal_offset(viewport_size), 0.0) + mapped_position * fit_scale
	size = stage_rect.size * fit_scale
	custom_minimum_size = size
	_sync_visual_child_scales()
	queue_redraw()

func _sync_visual_child_scales() -> void:
	if !press_scale_enabled:
		return
	var visual_center: Vector2 = size * 0.5
	for child: Node in get_children():
		if child is Control:
			var visual_child := child as Control
			# Use the button center as the common pivot so the background, text and
			# icon shrink as one unit while the clickable area stays unchanged.
			visual_child.pivot_offset = visual_center - visual_child.position
			visual_child.scale = visual_scale
