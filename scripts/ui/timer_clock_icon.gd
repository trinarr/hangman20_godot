extends Control
## Separate dial and independently rotating hands; owned by the popup.
const DIAL = preload("res://assets/tournament/timer_clock_dial.png")
const HAND = preload("res://assets/tournament/timer_clock_hand.png")
var minute_angle: float = 0.0
var hour_angle: float = -PI / 3.0
var minute_turn_seconds: float = 1.0
var hour_turn_seconds: float = 1.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	minute_angle = fposmod(minute_angle + TAU * delta / minute_turn_seconds, TAU)
	hour_angle = fposmod(hour_angle + TAU * delta / hour_turn_seconds, TAU)
	queue_redraw()

func _draw() -> void:
	draw_texture_rect(DIAL, Rect2(Vector2.ZERO, size), false)
	var center := size * 0.5
	draw_set_transform(center, hour_angle, Vector2.ONE * 0.72)
	draw_texture_rect(HAND, Rect2(-center, size), false)
	draw_set_transform(center, minute_angle)
	draw_texture_rect(HAND, Rect2(-center, size), false)
	draw_set_transform(Vector2.ZERO)
