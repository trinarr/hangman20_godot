extends Panel
## One shader draws the track, inset fill and progress front in logical UI units.

const INSET_UNITS := Vector2(1.5, 1.5)
const BOTTOM_INSET_UNITS: float = 3.5
const CAPTION_GAP_UNITS: float = 4.0

var _bar: ProgressBar
var _fill: ColorRect
var _ratio: float = 0.0

func configure(bar: ProgressBar, fill: ColorRect) -> void:
	_bar = bar
	_fill = fill
	_fill.material.set_shader_parameter("inset", INSET_UNITS)
	_fill.material.set_shader_parameter("bottom_inset", BOTTOM_INSET_UNITS)
	resized.connect(_sync_geometry)
	_sync_geometry()

func set_value_ratio(value: float) -> void:
	_ratio = clampf(value, 0.0, 1.0)
	_sync_geometry()
	_update_fill()

func _sync_geometry() -> void:
	_fill.position = Vector2.ZERO
	_fill.size = size
	_fill.material.set_shader_parameter("fill_size", _fill.size)
	_bar.position = position + INSET_UNITS
	_bar.size = (size - Vector2(INSET_UNITS.x * 2.0, INSET_UNITS.y + BOTTOM_INSET_UNITS)).max(Vector2.ZERO)
	_update_fill()

func _update_fill() -> void:
	_fill.material.set_shader_parameter("progress", _ratio)
