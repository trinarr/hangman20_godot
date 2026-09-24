extends ScrollContainer

# Existing stage widgets already scale themselves to the viewport. Keep this
# container in pixels and translate their stage canvas instead of scaling twice.
const LAYOUT: GDScript = preload("res://scripts/ui/portrait_stage_layout.gd")

# Settings is intentionally the only scroll surface that adds a visual elastic
# overscroll. ScrollContainer still owns the real scroll position and kinetic
# scrolling; this offset only stretches the stage canvas after the real scroll
# has reached either edge.
const OVERSCROLL_MAX_STAGE_PX: float = 52.0
const OVERSCROLL_RESISTANCE: float = 0.46
const OVERSCROLL_EDGE_DAMPING: float = 0.72
const OVERSCROLL_RETURN_SECONDS: float = 0.364
const DRAG_DEADZONE_STAGE_PX: float = 8.0

enum PointerKind {
	NONE,
	TOUCH,
	MOUSE,
}

var stage_rect: Rect2
var content_origin_y: float = 206.0
var content_height: float = 600.0
var stage_content := Control.new()
var _extent := Control.new()
var _fit_scale: float = 1.0
var _pointer_kind: int = PointerKind.NONE
var _touch_index: int = -1
var _drag_distance: float = 0.0
var _drag_started: bool = false
var _overscroll_offset_y: float = 0.0
var _overscroll_return_tween: Tween = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	follow_focus = true
	clip_contents = true
	_extent.name = "ScrollExtent"
	_extent.mouse_filter = Control.MOUSE_FILTER_PASS
	_extent.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_extent)
	stage_content.name = "SettingsStageContent"
	stage_content.mouse_filter = Control.MOUSE_FILTER_PASS
	_extent.add_child(stage_content)
	# Observe the same GUI stream ScrollContainer uses without replacing its
	# native handler. That preserves Godot's kinetic scrolling and wheel support.
	gui_input.connect(_on_scroll_gui_input)
	get_viewport().size_changed.connect(_sync_to_stage)
	_sync_to_stage()
	call_deferred("_prepare_touch_controls", stage_content)

func _exit_tree() -> void:
	_stop_overscroll_return()
	if get_viewport() != null and get_viewport().size_changed.is_connected(_sync_to_stage):
		get_viewport().size_changed.disconnect(_sync_to_stage)

func _prepare_touch_controls(node: Node) -> void:
	# Settings buttons must keep taps, but they must not own the whole pointer
	# sequence. Opt our custom buttons into bubbling so ScrollContainer can turn a
	# touch that started on a button into a drag. Native buttons/links already use
	# PASS here, which is the normal ScrollContainer-friendly setup.
	if node is FlashStageTextureButton:
		(node as FlashStageTextureButton).allow_parent_scroll_drag = true
	if node is Control and node.mouse_filter == Control.MOUSE_FILTER_STOP:
		node.mouse_filter = Control.MOUSE_FILTER_PASS
	for child: Node in node.get_children():
		_prepare_touch_controls(child)

func _on_scroll_gui_input(event: InputEvent) -> void:
	# Touch is preferred when both a real touch event and an emulated mouse event
	# are produced for the same finger. This avoids applying edge stretch twice.
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if _pointer_kind == PointerKind.NONE or _pointer_kind == PointerKind.MOUSE:
				_begin_pointer_drag(PointerKind.TOUCH)
				_touch_index = touch.index
		elif _pointer_kind == PointerKind.TOUCH and touch.index == _touch_index:
			_end_pointer_drag()
		return

	if event is InputEventScreenDrag:
		var touch_drag := event as InputEventScreenDrag
		if _pointer_kind == PointerKind.TOUCH and touch_drag.index == _touch_index:
			_update_pointer_drag(touch_drag.relative.y)
		return

	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse_button.pressed:
			if _pointer_kind == PointerKind.NONE:
				_begin_pointer_drag(PointerKind.MOUSE)
		elif _pointer_kind == PointerKind.MOUSE:
			_end_pointer_drag()
		return

	if event is InputEventMouseMotion and _pointer_kind == PointerKind.MOUSE:
		var mouse_motion := event as InputEventMouseMotion
		if (mouse_motion.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			_update_pointer_drag(mouse_motion.relative.y)

func _begin_pointer_drag(kind: int) -> void:
	_stop_overscroll_return()
	_pointer_kind = kind
	_touch_index = -1
	_drag_distance = 0.0
	_drag_started = false

func _update_pointer_drag(delta_y: float) -> void:
	if is_zero_approx(delta_y):
		return
	_drag_distance += absf(delta_y)
	if !_drag_started:
		var drag_deadzone: float = DRAG_DEADZONE_STAGE_PX * _fit_scale
		if _drag_distance < drag_deadzone:
			return
		_drag_started = true
		# At an edge ScrollContainer may have no real pixels to consume, so make
		# sure a button that started this gesture still cancels its pressed/click
		# state as soon as the gesture becomes a scroll.
		stage_content.propagate_notification(Control.NOTIFICATION_SCROLL_BEGIN)

	var max_scroll: float = _max_scroll_vertical()
	var at_top: bool = float(scroll_vertical) <= 0.5
	var at_bottom: bool = float(scroll_vertical) >= max_scroll - 0.5
	var pulling_past_top: bool = at_top and delta_y > 0.0
	var pulling_past_bottom: bool = at_bottom and delta_y < 0.0
	var returning_from_top: bool = _overscroll_offset_y > 0.0 and delta_y < 0.0
	var returning_from_bottom: bool = _overscroll_offset_y < 0.0 and delta_y > 0.0

	if pulling_past_top or pulling_past_bottom or returning_from_top or returning_from_bottom:
		_apply_overscroll_drag(delta_y)
	elif !is_zero_approx(_overscroll_offset_y):
		_set_overscroll_offset(0.0)

func _end_pointer_drag() -> void:
	_pointer_kind = PointerKind.NONE
	_touch_index = -1
	_drag_distance = 0.0
	_drag_started = false
	_start_overscroll_return()

func _apply_overscroll_drag(delta_y: float) -> void:
	var max_offset: float = OVERSCROLL_MAX_STAGE_PX * _fit_scale
	if max_offset <= 0.0:
		return
	var normalized: float = clampf(absf(_overscroll_offset_y) / max_offset, 0.0, 1.0)
	var resistance: float = OVERSCROLL_RESISTANCE * (1.0 - normalized * OVERSCROLL_EDGE_DAMPING)
	var next_offset: float = _overscroll_offset_y + delta_y * maxf(resistance, 0.08)
	_set_overscroll_offset(clampf(next_offset, -max_offset, max_offset))

func _start_overscroll_return() -> void:
	_stop_overscroll_return()
	if is_zero_approx(_overscroll_offset_y) or !is_inside_tree():
		_set_overscroll_offset(0.0)
		return
	_overscroll_return_tween = create_tween()
	_overscroll_return_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var tweener: MethodTweener = _overscroll_return_tween.tween_method(
		Callable(self, "_set_overscroll_offset"),
		_overscroll_offset_y,
		0.0,
		OVERSCROLL_RETURN_SECONDS
	)
	tweener.set_trans(Tween.TRANS_QUINT)
	tweener.set_ease(Tween.EASE_OUT)
	_overscroll_return_tween.finished.connect(_clear_overscroll_return_tween, CONNECT_ONE_SHOT)

func _stop_overscroll_return() -> void:
	if _overscroll_return_tween != null and _overscroll_return_tween.is_valid():
		_overscroll_return_tween.kill()
	_overscroll_return_tween = null

func _clear_overscroll_return_tween() -> void:
	_overscroll_return_tween = null
	_set_overscroll_offset(0.0)

func _set_overscroll_offset(value: float) -> void:
	_overscroll_offset_y = value
	_sync_stage_content_position()

func _max_scroll_vertical() -> float:
	var scrollbar: VScrollBar = get_v_scroll_bar()
	if scrollbar == null:
		return 0.0
	return maxf(scrollbar.max_value - scrollbar.page, 0.0)

func _sync_stage_content_position() -> void:
	if stage_content == null:
		return
	stage_content.position = (
		-Vector2(
			LAYOUT.horizontal_offset(get_viewport_rect().size) + stage_rect.position.x * _fit_scale,
			content_origin_y * _fit_scale
		)
		+ Vector2(0.0, _overscroll_offset_y)
	)

func _sync_to_stage() -> void:
	var viewport_size := get_viewport_rect().size
	_fit_scale = LAYOUT.fit_scale(viewport_size)
	var offset: float = LAYOUT.horizontal_offset(viewport_size)
	position = Vector2(offset, 0.0) + stage_rect.position * _fit_scale
	size = stage_rect.size * _fit_scale
	scroll_deadzone = maxi(8, int(round(DRAG_DEADZONE_STAGE_PX * _fit_scale)))
	_extent.custom_minimum_size = Vector2(0.0, content_height * _fit_scale)
	_sync_stage_content_position()
	stage_content.size = Vector2(480.0, content_origin_y + content_height) * _fit_scale
