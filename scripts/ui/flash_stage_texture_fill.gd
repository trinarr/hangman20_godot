class_name FlashStageTextureFill
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

var texture: Texture2D:
	set(value):
		texture = value
		queue_redraw()

var _fit_scale: float = 1.0

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
	if texture == null:
		return
	var tile_size: Vector2 = texture.get_size() * _fit_scale
	if tile_size.x <= 0.0 or tile_size.y <= 0.0:
		return
	var y: float = 0.0
	while y < size.y:
		var x: float = 0.0
		while x < size.x:
			draw_texture_rect(texture, Rect2(x, y, tile_size.x, tile_size.y), false)
			x += tile_size.x
		y += tile_size.y

func _sync_to_stage() -> void:
	if !is_inside_tree():
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	_fit_scale = min(viewport_size.x / STAGE_SIZE.x, viewport_size.y / STAGE_SIZE.y)
	var stage_offset: Vector2 = (viewport_size - STAGE_SIZE * _fit_scale) * 0.5
	position = Vector2(0.0, stage_offset.y + stage_y * _fit_scale)
	size = Vector2(viewport_size.x, stage_height * _fit_scale)
	custom_minimum_size = size
	queue_redraw()
