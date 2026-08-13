class_name StageStatusIcon
extends Control

const SUCCESS_COLOR := Color(0.24, 0.82, 0.43, 1.0)
const FAILURE_COLOR := Color(0.96, 0.28, 0.30, 1.0)

var is_success: bool = true:
	set(value):
		is_success = value
		queue_redraw()

var line_width: float = 6.0:
	set(value):
		line_width = maxf(value, 1.0)
		queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func configure(success: bool, width: float = 6.0) -> void:
	is_success = success
	line_width = width
	queue_redraw()

func _draw() -> void:
	var inset: float = maxf(line_width * 0.75, 2.0)
	var icon_side: float = minf(size.x, size.y) - inset * 2.0
	var draw_rect := Rect2(
		(size - Vector2(icon_side, icon_side)) * 0.5,
		Vector2(icon_side, icon_side)
	)
	if draw_rect.size.x <= 0.0 or draw_rect.size.y <= 0.0:
		return
	if is_success:
		_draw_check(draw_rect)
	else:
		_draw_cross(draw_rect)

func _draw_check(rect: Rect2) -> void:
	var points := PackedVector2Array([
		rect.position + Vector2(rect.size.x * 0.08, rect.size.y * 0.54),
		rect.position + Vector2(rect.size.x * 0.38, rect.size.y * 0.84),
		rect.position + Vector2(rect.size.x * 0.92, rect.size.y * 0.16),
	])
	draw_polyline(points, SUCCESS_COLOR, line_width, true)
	for point in points:
		draw_circle(point, line_width * 0.5, SUCCESS_COLOR)

func _draw_cross(rect: Rect2) -> void:
	var start_a := rect.position + Vector2(rect.size.x * 0.16, rect.size.y * 0.16)
	var end_a := rect.position + Vector2(rect.size.x * 0.84, rect.size.y * 0.84)
	var start_b := rect.position + Vector2(rect.size.x * 0.84, rect.size.y * 0.16)
	var end_b := rect.position + Vector2(rect.size.x * 0.16, rect.size.y * 0.84)
	draw_line(start_a, end_a, FAILURE_COLOR, line_width, true)
	draw_line(start_b, end_b, FAILURE_COLOR, line_width, true)
	for point in [start_a, end_a, start_b, end_b]:
		draw_circle(point, line_width * 0.5, FAILURE_COLOR)
