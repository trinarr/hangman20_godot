class_name FlashStageHorizontalFill
extends Control

const STAGE_SIZE: Vector2 = Vector2(800.0, 480.0)

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
	var fit_scale: float = min(viewport_size.x / STAGE_SIZE.x, viewport_size.y / STAGE_SIZE.y)
	var stage_offset: Vector2 = (viewport_size - STAGE_SIZE * fit_scale) * 0.5
	position = Vector2(0.0, stage_offset.y + stage_y * fit_scale)
	size = Vector2(viewport_size.x, stage_height * fit_scale)
	custom_minimum_size = size
	queue_redraw()
