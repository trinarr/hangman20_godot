class_name PopupStageCenter
extends Control

const STAGE_SIZE: Vector2 = Vector2(800.0, 480.0)

var popup_top: float = 0.0:
	set(value):
		popup_top = value
		_sync_to_viewport()

var popup_bottom: float = 0.0:
	set(value):
		popup_bottom = value
		_sync_to_viewport()

func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	if !get_viewport().size_changed.is_connected(_sync_to_viewport):
		get_viewport().size_changed.connect(_sync_to_viewport)
	_sync_to_viewport()

func _exit_tree() -> void:
	if get_viewport() != null and get_viewport().size_changed.is_connected(_sync_to_viewport):
		get_viewport().size_changed.disconnect(_sync_to_viewport)

func _sync_to_viewport() -> void:
	if !is_inside_tree():
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var fit_scale: float = min(viewport_size.x / STAGE_SIZE.x, viewport_size.y / STAGE_SIZE.y)
	var centered_stage_shift: float = (STAGE_SIZE.y - popup_top - popup_bottom) * 0.5
	position = Vector2(0.0, centered_stage_shift * fit_scale)
	size = viewport_size
	custom_minimum_size = viewport_size
