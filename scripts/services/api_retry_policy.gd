extends RefCounted
## Session-local monotonic deadlines; RNG is independent from gameplay randomness.
const DESIGN = preload("res://scripts/core/game_design_config.gd")
var failures := 0
var next_at_ms := 0
var _random := RandomNumberGenerator.new()

func _init() -> void:
	_random.randomize()

static func base_seconds() -> float:
	return DESIGN.get_float("timings.network_retry.base_seconds")

func remaining_ms(now_ms: int) -> int:
	return maxi(0, next_at_ms - now_ms)

func failed(now_ms: int) -> int:
	failures = mini(failures + 1, 32)
	var ceiling := DESIGN.get_float("timings.network_retry.maximum_seconds")
	var spread := DESIGN.get_float("timings.network_retry.jitter_ratio")
	var delay := minf(ceiling, base_seconds() * pow(2.0, failures - 1))
	delay = minf(ceiling, delay * _random.randf_range(1.0 - spread, 1.0 + spread))
	next_at_ms = now_ms + maxi(1, roundi(delay * 1000.0))
	return next_at_ms - now_ms

func succeeded() -> void:
	failures = 0
	next_at_ms = 0
