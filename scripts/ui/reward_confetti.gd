extends Node2D
## One short burst of paper strips, in portrait-stage units. No textures or timers.
## The reward screen owns this node, so leaving the screen also removes the effect.

const PIECE_COUNT: int = 112
const PIECE_SIZE_SCALE: float = 1.82
const FALL_LIFETIME_SCALE: float = 0.7225
const FADE_SECONDS: float = 0.8 * FALL_LIFETIME_SCALE
const BURST_SPEED_SCALE: float = 1.4
const BURST_DISTANCE_SCALE: float = 0.7
# A shorter flight at higher speed needs proportionally stronger braking.
# Time scale = 2, ascent acceleration scale = 2.8. Falling stays slow.
const BURST_TIME_SCALE: float = BURST_SPEED_SCALE / BURST_DISTANCE_SCALE
const BURST_ACCELERATION_SCALE: float = BURST_SPEED_SCALE * BURST_TIME_SCALE
const EMISSION_SECONDS: float = 0.14 / BURST_TIME_SCALE
const GRAVITY: float = 360.0
const PALETTE: Array[Color] = [
	Color("ffcf35"), Color("ff547d"), Color("40dfed"),
	Color("8f65ff"), Color("65e859"), Color("ff963d")
]

class PaperPiece:
	var position: Vector2 = Vector2.ZERO
	var velocity: Vector2 = Vector2.ZERO
	var age: float = 0.0
	var lifetime: float = 0.0
	var delay: float = 0.0
	var angle: float = 0.0
	var spin: float = 0.0
	var phase: float = 0.0
	var flutter_speed: float = 0.0
	var fall_speed: float = 0.0
	var length: float = 0.0
	var width: float = 0.0
	var curl: float = 0.0
	var color: Color = Color.WHITE
	var points: PackedVector2Array = PackedVector2Array()
	var colors: PackedColorArray = PackedColorArray()

var _pieces: Array[PaperPiece] = []
var _started: bool = false

func _ready() -> void:
	set_process(false)

func burst() -> void:
	if _started:
		return
	_started = true
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for index: int in range(PIECE_COUNT):
		var piece := PaperPiece.new()
		piece.position = Vector2(rng.randf_range(-23.0, 23.0), rng.randf_range(-5.0, 5.0)) * BURST_DISTANCE_SCALE
		# A wide upward fan, then air resistance and a slow terminal fall.
		var direction: float = rng.randf_range(-0.95, 0.95)
		piece.velocity = Vector2(sin(direction), -cos(direction)) * rng.randf_range(330.0, 540.0) * BURST_SPEED_SCALE
		piece.delay = rng.randf_range(0.0, EMISSION_SECONDS)
		# Shorten only the falling phase; preserve the upward flight timing.
		var ascent_seconds: float = -piece.velocity.y / (GRAVITY * BURST_ACCELERATION_SCALE)
		var original_lifetime: float = rng.randf_range(4.6, 6.2)
		piece.lifetime = ascent_seconds + (original_lifetime - ascent_seconds) * FALL_LIFETIME_SCALE
		piece.angle = rng.randf_range(-PI, PI)
		piece.spin = rng.randf_range(-4.0, 4.0)
		piece.phase = rng.randf_range(0.0, TAU)
		piece.flutter_speed = rng.randf_range(5.0, 10.0)
		piece.fall_speed = rng.randf_range(75.0, 125.0)
		piece.length = rng.randf_range(6.0, 11.0) * PIECE_SIZE_SCALE
		piece.width = rng.randf_range(2.5, 4.0) * PIECE_SIZE_SCALE
		piece.curl = rng.randf_range(1.2, 3.5) * PIECE_SIZE_SCALE if index % 3 == 0 else 0.0
		piece.color = PALETTE[index % PALETTE.size()]
		# Reuse polygon buffers instead of creating nodes or arrays every frame.
		var vertex_count: int = 10 if piece.curl > 0.0 else 4
		piece.points.resize(vertex_count)
		piece.colors.resize(vertex_count)
		_pieces.append(piece)
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	# Avoid a large physics jump on a slow frame or return from the background.
	var remaining: float = minf(delta, 0.1)
	while remaining > 0.0:
		var step: float = minf(remaining, 1.0 / 60.0)
		_advance(step)
		remaining -= step
	if _pieces.is_empty():
		set_process(false)
		queue_free()
	queue_redraw()

func _advance(delta: float) -> void:
	for index: int in range(_pieces.size() - 1, -1, -1):
		var piece: PaperPiece = _pieces[index]
		if piece.delay > 0.0:
			piece.delay -= delta
			continue
		piece.age += delta
		if piece.age >= piece.lifetime:
			_pieces.remove_at(index)
			continue
		var falling: bool = piece.velocity.y >= 0.0
		piece.velocity.x *= exp(-delta * BURST_TIME_SCALE * (1.8 if falling else 0.65))
		if falling:
			piece.velocity.y = minf(piece.velocity.y + GRAVITY * delta, piece.fall_speed)
		else:
			piece.velocity.y = minf(piece.velocity.y + GRAVITY * BURST_ACCELERATION_SCALE * delta, 0.0)
		var sway: float = sin(piece.age * piece.flutter_speed + piece.phase) * (25.0 if falling else 5.0)
		piece.position += (piece.velocity + Vector2(sway, 0.0)) * delta
		piece.angle += piece.spin * delta

func _draw() -> void:
	for piece: PaperPiece in _pieces:
		if piece.delay > 0.0:
			continue
		var phase: float = piece.age * piece.flutter_speed + piece.phase
		# Narrow silhouettes and changing light suggest paper flipping in 3D.
		var facing: float = cos(phase)
		var half_width: float = piece.width * 0.5 * maxf(0.14, absf(facing))
		var alpha: float = minf(piece.age / 0.045, 1.0) * clampf((piece.lifetime - piece.age) / FADE_SECONDS, 0.0, 1.0)
		var tint: Color = piece.color.darkened(0.24 * (1.0 - facing) * 0.5)
		tint.a = alpha
		var samples: int = 5 if piece.curl > 0.0 else 2
		for index: int in range(samples):
			var along: float = float(index) / float(samples - 1)
			var x: float = (along - 0.5) * piece.length
			var bend: float = sin(along * PI + phase * 0.45) * piece.curl
			piece.points[index] = Vector2(x, bend - half_width)
			piece.points[samples * 2 - 1 - index] = Vector2(x, bend + half_width)
			var shade: Color = tint.lightened(0.15 * along)
			shade.a = alpha
			piece.colors[index] = shade
			piece.colors[samples * 2 - 1 - index] = tint
		draw_set_transform(piece.position, piece.angle)
		draw_polygon(piece.points, piece.colors)
	draw_set_transform(Vector2.ZERO)
