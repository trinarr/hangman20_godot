class_name SinglePlayerLevelMap
extends Control

signal level_selected(level_index: int)

const PORTRAIT_LAYOUT: GDScript = preload("res://scripts/ui/portrait_stage_layout.gd")
const STAGE_ROUND_BUTTON_SCRIPT: GDScript = preload("res://scripts/ui/stage_round_button.gd")

const STAGE_WIDTH: float = 480.0
const FOOTER_STAGE_Y: float = 688.0
# Level nodes are 25% larger than the standard 64 px round control. The
# increased vertical step keeps the route airy and leaves room for the bounce.
const LEVEL_BUTTON_SIZE: float = 80.0
const LEVEL_STEP: float = 136.0
const ROUTE_TOP_PADDING: float = 76.0
const ROUTE_BOTTOM_PADDING: float = 84.0
const ROUTE_COLOR := Color(0.20, 0.39, 0.76, 0.88)
const ROUTE_SECONDARY_COLOR := Color(0.31, 0.50, 0.88, 0.38)
const LOCKED_BUTTON_TINT := Color(0.64, 0.66, 0.71, 1.0)

var level_count: int = 10
var current_level_index: int = 0
var unlocked_states: Array = []
var completed_states: Array = []
var perfect_states: Array = []

var _scroll: ScrollContainer = null
var _route_root: Control = null
var _level_centers: Array[Vector2] = []

func configure(
	count: int,
	current_index: int,
	unlocked: Array,
	completed: Array,
	perfect: Array = []
) -> void:
	level_count = maxi(count, 0)
	current_level_index = clampi(current_index, 0, maxi(level_count - 1, 0))
	unlocked_states = unlocked.duplicate()
	completed_states = completed.duplicate()
	perfect_states = perfect.duplicate()
	if is_inside_tree():
		_rebuild_route()

func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	clip_contents = true
	_build_scroll()
	_rebuild_route()
	if !get_viewport().size_changed.is_connected(_sync_layout):
		get_viewport().size_changed.connect(_sync_layout)
	_sync_layout()
	call_deferred("_apply_initial_scroll")

func _exit_tree() -> void:
	if get_viewport() != null and get_viewport().size_changed.is_connected(_sync_layout):
		get_viewport().size_changed.disconnect(_sync_layout)

func _build_scroll() -> void:
	_scroll = ScrollContainer.new()
	_scroll.name = "LevelMapScroll"
	_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.follow_focus = true
	add_child(_scroll)

	_route_root = Control.new()
	_route_root.name = "LevelRoute"
	_route_root.mouse_filter = Control.MOUSE_FILTER_PASS
	_scroll.add_child(_route_root)

func _sync_layout() -> void:
	if !is_inside_tree():
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var fit_scale: float = PORTRAIT_LAYOUT.fit_scale(viewport_size)
	var safe_top: float = PORTRAIT_LAYOUT.safe_top_stage(viewport_size)
	var extra_height: float = PORTRAIT_LAYOUT.extra_stage_height(viewport_size)
	position = Vector2(
		PORTRAIT_LAYOUT.horizontal_offset(viewport_size),
		safe_top * fit_scale
	)
	scale = Vector2.ONE * fit_scale
	size = Vector2(
		STAGE_WIDTH,
		maxf(1.0, FOOTER_STAGE_Y + extra_height - safe_top)
	)
	custom_minimum_size = size
	if _scroll != null:
		_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _rebuild_route() -> void:
	if _route_root == null:
		return
	for child: Node in _route_root.get_children():
		_route_root.remove_child(child)
		child.queue_free()
	_level_centers.clear()
	_level_centers.resize(level_count)

	var content_height: float = (
		ROUTE_TOP_PADDING
		+ ROUTE_BOTTOM_PADDING
		+ LEVEL_BUTTON_SIZE
		+ float(maxi(level_count - 1, 0)) * LEVEL_STEP
	)
	_route_root.custom_minimum_size = Vector2(STAGE_WIDTH, content_height)
	_route_root.size = Vector2(STAGE_WIDTH, content_height)

	var route_centers: PackedVector2Array = PackedVector2Array()
	for visual_index in range(level_count):
		var level_index: int = level_count - 1 - visual_index
		var center := Vector2(
			STAGE_WIDTH * 0.5,
			ROUTE_TOP_PADDING + LEVEL_BUTTON_SIZE * 0.5 + float(visual_index) * LEVEL_STEP
		)
		_level_centers[level_index] = center
		route_centers.append(center)

	_stage_hand_drawn_route(route_centers)

	for level_index in range(level_count):
		_stage_level_button(level_index, _level_centers[level_index])

	call_deferred("_apply_initial_scroll")

func _stage_hand_drawn_route(centers: PackedVector2Array) -> void:
	if centers.size() < 2:
		return
	var wavy_points := PackedVector2Array()
	for segment_index in range(centers.size() - 1):
		var start: Vector2 = centers[segment_index]
		var finish: Vector2 = centers[segment_index + 1]
		var segment_steps: int = 6
		for point_index in range(segment_steps):
			if segment_index > 0 and point_index == 0:
				continue
			var t: float = float(point_index) / float(segment_steps)
			var point: Vector2 = start.lerp(finish, t)
			point.x += sin(float(segment_index * segment_steps + point_index) * 1.7) * 3.2
			wavy_points.append(point)
	wavy_points.append(centers[centers.size() - 1])

	var shadow_line := Line2D.new()
	shadow_line.name = "PenLineShadow"
	shadow_line.points = wavy_points
	shadow_line.width = 8.0
	shadow_line.default_color = ROUTE_SECONDARY_COLOR
	shadow_line.antialiased = true
	shadow_line.joint_mode = Line2D.LINE_JOINT_ROUND
	shadow_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	shadow_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	shadow_line.z_index = 0
	_route_root.add_child(shadow_line)

	var ink_line := Line2D.new()
	ink_line.name = "PenLine"
	ink_line.points = wavy_points
	ink_line.width = 4.5
	ink_line.default_color = ROUTE_COLOR
	ink_line.antialiased = true
	ink_line.joint_mode = Line2D.LINE_JOINT_ROUND
	ink_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	ink_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	ink_line.z_index = 1
	_route_root.add_child(ink_line)

func _stage_level_button(level_index: int, center: Vector2) -> void:
	var unlocked: bool = _state_at(unlocked_states, level_index)
	var completed: bool = _state_at(completed_states, level_index)
	var perfect: bool = _state_at(perfect_states, level_index)
	var is_current: bool = unlocked and !completed and level_index == current_level_index
	var button: Control = STAGE_ROUND_BUTTON_SCRIPT.new() as Control
	button.name = "Level%d" % (level_index + 1)
	button.set("use_stage_layout", false)
	button.call(
		"configure_text",
		str(level_index + 1),
		!unlocked,
		false,
		33,
		0.0
	)
	if completed:
		# Both perfect and imperfect completed levels are blue. Perfect levels stay
		# visible as achievements but deliberately ignore pointer input.
		button.call("set_color_preset", 2)
	elif !unlocked:
		button.call(
			"set_color_palette",
			LOCKED_BUTTON_TINT,
			LOCKED_BUTTON_TINT,
			LOCKED_BUTTON_TINT
		)
		button.set("icon_outline_color", Color(0.40, 0.42, 0.47, 1.0))
	button.set("attention_bounce_enabled", is_current)
	button.z_index = 3
	_route_root.add_child(button)
	button.set(
		"stage_rect",
		Rect2(
			center - Vector2.ONE * LEVEL_BUTTON_SIZE * 0.5,
			Vector2.ONE * LEVEL_BUTTON_SIZE
		)
	)
	if unlocked and !perfect:
		button.connect(&"pressed", Callable(self, "_on_level_pressed").bind(level_index))
	elif perfect:
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.focus_mode = Control.FOCUS_NONE

func _state_at(states: Array, index: int) -> bool:
	return index >= 0 and index < states.size() and bool(states[index])

func _on_level_pressed(level_index: int) -> void:
	level_selected.emit(level_index)

func _apply_initial_scroll() -> void:
	if _scroll == null or _level_centers.is_empty():
		return
	await get_tree().process_frame
	await get_tree().process_frame
	var resolved_index: int = clampi(current_level_index, 0, _level_centers.size() - 1)
	var target_center: Vector2 = _level_centers[resolved_index]
	var desired: float = target_center.y - size.y * 0.72
	var scroll_bar: VScrollBar = _scroll.get_v_scroll_bar()
	var max_scroll: float = maxf(0.0, scroll_bar.max_value - scroll_bar.page)
	_scroll.scroll_vertical = int(round(clampf(desired, 0.0, max_scroll)))
