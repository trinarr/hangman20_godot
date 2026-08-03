class_name PortraitThemeIconPattern
extends Control

const PORTRAIT_LAYOUT: GDScript = preload("res://scripts/ui/portrait_stage_layout.gd")

const ICON_STAGE_SIZE: float = 64.0
const COLUMN_STAGE_STEP: float = 126.0
const ROW_STAGE_STEP: float = 138.0
const DIAGONAL_STAGE_SPEED := Vector2(4.0, 4.0)
const REDRAW_INTERVAL: float = 1.0 / 24.0
# Theme art is mostly white with thin black contours. A blue tint plus a
# deliberate 20% alpha keeps both parts readable over the pale paper without
# competing with cards and buttons drawn above the pattern.
const ICON_TINT := Color(0.48, 0.62, 0.95, 0.20)

var theme_icons: Array[Texture2D] = []:
	set(value):
		theme_icons = value
		queue_redraw()

var _stage_offset := Vector2.ZERO
var _redraw_elapsed: float = 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	if !get_viewport().size_changed.is_connected(queue_redraw):
		get_viewport().size_changed.connect(queue_redraw)
	queue_redraw()

func _exit_tree() -> void:
	if get_viewport() != null and get_viewport().size_changed.is_connected(queue_redraw):
		get_viewport().size_changed.disconnect(queue_redraw)

func _process(delta: float) -> void:
	_stage_offset.x = fmod(_stage_offset.x + DIAGONAL_STAGE_SPEED.x * delta, COLUMN_STAGE_STEP)
	_stage_offset.y = fmod(_stage_offset.y + DIAGONAL_STAGE_SPEED.y * delta, ROW_STAGE_STEP)
	_redraw_elapsed += delta
	if _redraw_elapsed < REDRAW_INTERVAL:
		return
	_redraw_elapsed = 0.0
	queue_redraw()

func _draw() -> void:
	if theme_icons.is_empty():
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var fit_scale: float = PORTRAIT_LAYOUT.fit_scale(viewport_size)
	if fit_scale <= 0.0:
		return
	var logical_size: Vector2 = viewport_size / fit_scale
	var icon_size := Vector2.ONE * ICON_STAGE_SIZE
	var first_row: int = -2
	var last_row: int = ceili(logical_size.y / ROW_STAGE_STEP) + 1
	var first_column: int = -2
	var last_column: int = ceili(logical_size.x / COLUMN_STAGE_STEP) + 1
	for row_index in range(first_row, last_row + 1):
		var row_shift: float = COLUMN_STAGE_STEP * 0.5 if posmod(row_index, 2) == 1 else 0.0
		for column_index in range(first_column, last_column + 1):
			var logical_position := Vector2(
				float(column_index) * COLUMN_STAGE_STEP + row_shift + _stage_offset.x,
				float(row_index) * ROW_STAGE_STEP + _stage_offset.y
			)
			var icon_index: int = posmod(row_index * 3 + column_index, theme_icons.size())
			var icon: Texture2D = theme_icons[icon_index]
			if icon == null:
				continue
			draw_texture_rect(
				icon,
				Rect2(logical_position * fit_scale, icon_size * fit_scale),
				false,
				ICON_TINT
			)
