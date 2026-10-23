extends Control
## Popup-owned, clipped coin confetti. No timers or callbacks outlive this node.
const COIN = preload("res://flash_assets/soft_currency_coin.png")
var particles: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rng.randomize()
	for index in range(18):
		var particle := {}
		_reset(particle)
		particle.y = _rng.randf_range(-20.0, size.y)
		particles.append(particle)

func _reset(particle: Dictionary) -> void:
	particle.x = _rng.randf_range(28.0, size.x - 28.0)
	particle.y = -24.0
	particle.speed = _rng.randf_range(27.0, 52.0)
	particle.diameter = _rng.randf_range(9.0, 17.0) * 1.15
	particle.angle = _rng.randf_range(-PI, PI)
	particle.spin = _rng.randf_range(1.5, 3.5)

func _process(delta: float) -> void:
	var step: float = minf(delta, 0.1)
	for particle: Dictionary in particles:
		particle.y += particle.speed * step
		particle.angle += particle.spin * step
		if particle.y > size.y + 24.0:
			_reset(particle)
	queue_redraw()

func _draw() -> void:
	for particle: Dictionary in particles:
		var diameter: float = particle.diameter
		draw_set_transform(Vector2(particle.x, particle.y), particle.angle * 0.3,
			Vector2(maxf(absf(cos(particle.angle)), 0.18), 1.0))
		draw_texture_rect(COIN, Rect2(Vector2.ONE * -diameter * 0.5, Vector2.ONE * diameter), false)
	draw_set_transform(Vector2.ZERO)
