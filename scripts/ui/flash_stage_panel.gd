class_name FlashStagePanel
extends Control

const STAGE_SIZE: Vector2 = Vector2(480.0, 800.0)
const PORTRAIT_LAYOUT: GDScript = preload("res://scripts/ui/portrait_stage_layout.gd")

var stage_rect: Rect2 = Rect2(0.0, 0.0, 0.0, 0.0):
	set(value):
		stage_rect = value
		_sync_to_stage()

var fill_color: Color = Color.WHITE:
	set(value):
		fill_color = value
		queue_redraw()

var border_color: Color = Color(0.0, 0.0, 0.0, 0.0):
	set(value):
		border_color = value
		queue_redraw()

var border_width: float = 0.0:
	set(value):
		border_width = value
		queue_redraw()

var corner_radius: float = 0.0:
	set(value):
		corner_radius = value
		_sync_to_stage()

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
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill_color
	var radius: int = int(round(corner_radius))
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	var scaled_border: int = int(round(border_width))
	if scaled_border > 0:
		style.border_color = border_color
		style.border_width_left = scaled_border
		style.border_width_top = scaled_border
		style.border_width_right = scaled_border
		style.border_width_bottom = scaled_border
	draw_style_box(style, Rect2(Vector2.ZERO, size))

func _sync_to_stage() -> void:
	if !is_inside_tree():
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	_fit_scale = PORTRAIT_LAYOUT.fit_scale(viewport_size)
	var mapped_position: Vector2 = PORTRAIT_LAYOUT.map_rect_position(stage_rect, viewport_size, self)
	position = Vector2(PORTRAIT_LAYOUT.horizontal_offset(viewport_size), 0.0) + mapped_position * _fit_scale
	scale = Vector2.ONE * _fit_scale
	size = stage_rect.size
	custom_minimum_size = size
	queue_redraw()
