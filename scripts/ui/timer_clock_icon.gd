extends Control
## One large hand advances between quarter turns with an inertial stop and pause.
const DESIGN = preload("res://scripts/core/game_design_config.gd")
const DIAL = preload("res://assets/tournament/timer_clock_dial.png")
const HAND = preload("res://assets/tournament/timer_clock_hand.png")
var hand_angle: float = 0.0
var quarter_turn_seconds: float = DESIGN.get_float("timings.animations.timer_clock.quarter_turn_seconds")
var pause_seconds: float = DESIGN.get_float("timings.animations.timer_clock.pause_seconds")
var overshoot_degrees: float = DESIGN.get_float("timings.animations.timer_clock.overshoot_degrees")
var settle_fraction: float = DESIGN.get_float("timings.animations.timer_clock.settle_fraction")
var _elapsed: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	_elapsed = fposmod(_elapsed + delta, 4.0 * (quarter_turn_seconds + pause_seconds))
	hand_angle = _angle_at_time(_elapsed)
	queue_redraw()

func _angle_at_time(elapsed: float) -> float:
	var step_seconds := quarter_turn_seconds + pause_seconds
	var cycle_time := fposmod(elapsed, step_seconds * 4.0)
	var quadrant := floori(cycle_time / step_seconds)
	var step_time := cycle_time - float(quadrant) * step_seconds
	var start := float(quadrant) * PI * 0.5
	var target := start + PI * 0.5
	if step_time >= quarter_turn_seconds:
		return target
	var approach_seconds := quarter_turn_seconds * (1.0 - settle_fraction)
	var overshoot := target + deg_to_rad(overshoot_degrees)
	if step_time < approach_seconds:
		return lerpf(start, overshoot, smoothstep(0.0, approach_seconds, step_time))
	return lerpf(overshoot, target, smoothstep(approach_seconds, quarter_turn_seconds, step_time))

func _draw() -> void:
	draw_texture_rect(DIAL, Rect2(Vector2.ZERO, size), false)
	var center := size * 0.5
	draw_set_transform(center, hand_angle)
	draw_texture_rect(HAND, Rect2(-center, size), false)
	draw_set_transform(Vector2.ZERO)
