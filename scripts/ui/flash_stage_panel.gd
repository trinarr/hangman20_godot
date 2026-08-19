class_name FlashStagePanel
extends Control

const PORTRAIT_LAYOUT: GDScript = preload("res://scripts/ui/portrait_stage_layout.gd")

var stage_rect: Rect2 = Rect2(0.0, 0.0, 0.0, 0.0):
	set(value):
		stage_rect = value
		_sync_to_stage()

var fill_color: Color = Color.WHITE:
	set(value):
		fill_color = value
		queue_redraw()

var gradient_top_color: Color = Color(0.0, 0.0, 0.0, 0.0):
	set(value):
		gradient_top_color = value
		queue_redraw()

var gradient_bottom_color: Color = Color(0.0, 0.0, 0.0, 0.0):
	set(value):
		gradient_bottom_color = value
		queue_redraw()

var use_vertical_gradient: bool = false:
	set(value):
		use_vertical_gradient = value
		queue_redraw()

var border_color: Color = Color(0.0, 0.0, 0.0, 0.0):
	set(value):
		border_color = value
		queue_redraw()

var border_width: float = 0.0:
	set(value):
		border_width = value
		queue_redraw()

var corner_radius: float = 0.0:
	set(value):
		corner_radius = value
		_sync_to_stage()

var _fit_scale: float = 1.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if !get_viewport().size_changed.is_connected(_sync_to_stage):
		get_viewport().size_changed.connect(_sync_to_stage)
	_sync_to_stage()

func _exit_tree() -> void:
	if get_viewport() != null and get_viewport().size_changed.is_connected(_sync_to_stage):
		get_viewport().size_changed.disconnect(_sync_to_stage)

func _draw() -> void:
	var target_rect := Rect2(Vector2.ZERO, size)
	var radius: float = maxf(corner_radius, 0.0)
	var scaled_border: float = maxf(border_width, 0.0)
	if use_vertical_gradient:
		# Draw the border first when requested, then paint the gradient as narrow
		# horizontal strips. This is deterministic on CanvasItem and avoids relying
		# on per-vertex polygon color interpolation.
		if scaled_border > 0.0:
			var border_style: StyleBoxFlat = StyleBoxFlat.new()
			border_style.bg_color = border_color
			var border_radius: int = int(round(radius))
			border_style.corner_radius_top_left = border_radius
			border_style.corner_radius_top_right = border_radius
			border_style.corner_radius_bottom_left = border_radius
			border_style.corner_radius_bottom_right = border_radius
			draw_style_box(border_style, target_rect)
			target_rect = target_rect.grow(-scaled_border)
			radius = maxf(radius - scaled_border, 0.0)
		if target_rect.size.x <= 0.0 or target_rect.size.y <= 0.0:
			return
		var strip_height: float = 2.0
		var strip_count: int = maxi(1, int(ceil(target_rect.size.y / strip_height)))
		for index: int in range(strip_count):
			var y0: float = target_rect.position.y + float(index) * strip_height
			var y1: float = minf(y0 + strip_height, target_rect.end.y)
			var center_y: float = (y0 + y1) * 0.5
			var normalized_y: float = clampf(
				(center_y - target_rect.position.y) / maxf(target_rect.size.y, 1.0),
				0.0,
				1.0
			)
			var inset: float = _rounded_rect_horizontal_inset(target_rect, radius, center_y)
			var strip_width: float = target_rect.size.x - inset * 2.0
			if strip_width <= 0.0:
				continue
			draw_rect(
				Rect2(target_rect.position.x + inset, y0, strip_width, y1 - y0),
				gradient_top_color.lerp(gradient_bottom_color, normalized_y)
			)
		return

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill_color
	var style_radius: int = int(round(radius))
	style.corner_radius_top_left = style_radius
	style.corner_radius_top_right = style_radius
	style.corner_radius_bottom_left = style_radius
	style.corner_radius_bottom_right = style_radius
	var solid_border: int = int(round(scaled_border))
	if solid_border > 0:
		style.border_color = border_color
		style.border_width_left = solid_border
		style.border_width_top = solid_border
		style.border_width_right = solid_border
		style.border_width_bottom = solid_border
	draw_style_box(style, Rect2(Vector2.ZERO, size))

func _rounded_rect_horizontal_inset(target_rect: Rect2, radius: float, y: float) -> float:
	if radius <= 0.0:
		return 0.0
	var clamped_radius: float = minf(radius, minf(target_rect.size.x, target_rect.size.y) * 0.5)
	var local_y: float = y - target_rect.position.y
	var distance_from_curve_center: float = 0.0
	if local_y < clamped_radius:
		distance_from_curve_center = clamped_radius - local_y
	elif local_y > target_rect.size.y - clamped_radius:
		distance_from_curve_center = local_y - (target_rect.size.y - clamped_radius)
	else:
		return 0.0
	var inside: float = maxf(clamped_radius * clamped_radius - distance_from_curve_center * distance_from_curve_center, 0.0)
	return clamped_radius - sqrt(inside)

func _sync_to_stage() -> void:
	if !is_inside_tree():
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	_fit_scale = PORTRAIT_LAYOUT.fit_scale(viewport_size)
	var mapped_position: Vector2 = PORTRAIT_LAYOUT.map_rect_position(stage_rect, viewport_size, self)
	position = Vector2(PORTRAIT_LAYOUT.horizontal_offset(viewport_size), 0.0) + mapped_position * _fit_scale
	scale = Vector2.ONE * _fit_scale
	size = stage_rect.size
	custom_minimum_size = size
	queue_redraw()
