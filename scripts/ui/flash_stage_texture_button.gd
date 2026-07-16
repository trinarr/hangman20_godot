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
		queue_redraw()

var _is_down: bool = false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE if disabled else Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_ARROW if disabled else Control.CURSOR_POINTING_HAND
	focus_mode = Control.FOCUS_NONE
	if !get_viewport().size_changed.is_connected(_sync_to_stage):
		get_viewport().size_changed.connect(_sync_to_stage)
	_sync_to_stage()

func _exit_tree() -> void:
	if get_viewport() != null and get_viewport().size_changed.is_connected(_sync_to_stage):
		get_viewport().size_changed.disconnect(_sync_to_stage)

func _draw() -> void:
	var texture := texture_normal
	if disabled and texture_disabled != null:
		texture = texture_disabled
	elif _is_down and texture_pressed != null:
		texture = texture_pressed
	if texture != null:
		draw_texture_rect(texture, Rect2(Vector2.ZERO, size), false)
	# Do not add a rectangular fallback overlay when a selected-state button
	# deliberately uses the same bitmap for normal and pressed states. The
	# bitmap itself already represents the blue selected state.
	if disabled and disabled_overlay_alpha > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(1.0, 1.0, 1.0, disabled_overlay_alpha), true)

func _gui_input(event: InputEvent) -> void:
	if disabled:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse_event.pressed:
			_is_down = true
			accept_event()
			queue_redraw()
		else:
			var was_down := _is_down
			_is_down = false
			accept_event()
			queue_redraw()
			if was_down and Rect2(Vector2.ZERO, size).has_point(mouse_event.position):
				pressed.emit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT and _is_down:
		_is_down = false
		queue_redraw()

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
	queue_redraw()
