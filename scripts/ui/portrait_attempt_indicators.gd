extends Control

const PALETTE = preload("res://scripts/ui/ui_palette.gd")

const RADIUS: float = 7.5
const SPACING: float = 23.0
const CROSS_HALF_EXTENT := Vector2(3.0, 3.0)
const ROW_HEIGHT: float = 18.0

var total: int = 0
var remaining: int = 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func set_attempts(new_total: int, new_remaining: int) -> void:
	if total == new_total and remaining == new_remaining:
		return
	total = new_total
	remaining = new_remaining
	queue_redraw()

func _draw() -> void:
	var center := Vector2((size.x - SPACING * (total - 1)) * 0.5, size.y * 0.5)
	for index: int in range(total):
		draw_arc(center, RADIUS, 0.0, TAU, 32, PALETTE.UI_BLUE_LIGHT_BORDER, 1.6, true)
		if index < total - remaining:
			var opposite := Vector2(CROSS_HALF_EXTENT.x, -CROSS_HALF_EXTENT.y)
			draw_line(center - CROSS_HALF_EXTENT, center + CROSS_HALF_EXTENT, PALETTE.ERROR_SOFT, 2.2, true)
			draw_line(center - opposite, center + opposite, PALETTE.ERROR_SOFT, 2.2, true)
		center.x += SPACING
