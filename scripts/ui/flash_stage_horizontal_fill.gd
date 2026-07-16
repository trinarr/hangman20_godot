class_name FlashStageHorizontalFill
extends Control

const STAGE_SIZE: Vector2 = Vector2(480.0, 800.0)
const PORTRAIT_LAYOUT: GDScript = preload("res://scripts/ui/portrait_stage_layout.gd")

var stage_y: float = 0.0:
	set(value):
		stage_y = value
		_sync_to_stage()

var stage_height: float = 0.0:
	set(value):
		stage_height = value
		_sync_to_stage()

var fill_color: Color = Color.WHITE:
	set(value):
		fill_color = value
		queue_redraw()

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
	draw_rect(Rect2(Vector2.ZERO, size), fill_color)

func _sync_to_stage() -> void:
	if !is_inside_tree():
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var fit_scale: float = PORTRAIT_LAYOUT.fit_scale(viewport_size)
	var mapped_y: float = PORTRAIT_LAYOUT.map_y(stage_y, viewport_size, self)
	position = Vector2(0.0, mapped_y * fit_scale)
	var fill_height: float = stage_height * fit_scale
	if stage_y <= 0.0 and stage_height >= STAGE_SIZE.y:
		fill_height = viewport_size.y
	elif stage_y + stage_height >= STAGE_SIZE.y:
		fill_height = maxf(0.0, viewport_size.y - position.y)
	size = Vector2(viewport_size.x, fill_height)
	custom_minimum_size = size
	queue_redraw()
