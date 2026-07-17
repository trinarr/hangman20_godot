class_name PortraitAdaptiveGroup
extends Control

const PORTRAIT_LAYOUT: GDScript = preload("res://scripts/ui/portrait_stage_layout.gd")

var pivot_stage_position: Vector2 = Vector2(240.0, 400.0):
	set(value):
		pivot_stage_position = value
		_sync_to_viewport()

var max_adaptive_scale: float = 1.15:
	set(value):
		max_adaptive_scale = maxf(1.0, value)
		_sync_to_viewport()

var extra_y_shift_factor: float = 0.0:
	set(value):
		extra_y_shift_factor = value
		_sync_to_viewport()

func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	var fit_scale: float = PORTRAIT_LAYOUT.fit_scale(viewport_size)
	var extra_height: float = PORTRAIT_LAYOUT.extra_stage_height(viewport_size)
	position = Vector2(0.0, extra_height * fit_scale * extra_y_shift_factor)
	size = viewport_size
	custom_minimum_size = viewport_size
	pivot_offset = Vector2(
		PORTRAIT_LAYOUT.horizontal_offset(viewport_size) + pivot_stage_position.x * fit_scale,
		PORTRAIT_LAYOUT.map_y(pivot_stage_position.y, viewport_size) * fit_scale
	)
	var adaptive_scale: float = PORTRAIT_LAYOUT.adaptive_ui_scale(viewport_size, max_adaptive_scale)
	scale = Vector2.ONE * adaptive_scale
