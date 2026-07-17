class_name PopupStageCenter
extends Control

const STAGE_SIZE: Vector2 = Vector2(480.0, 800.0)
const PORTRAIT_LAYOUT: GDScript = preload("res://scripts/ui/portrait_stage_layout.gd")
const OPEN_START_FACTOR: float = 0.965
const OPEN_PEAK_FACTOR: float = 1.025
const OPEN_GROW_DURATION: float = 0.15
const OPEN_SETTLE_DURATION: float = 0.11
const MAX_ADAPTIVE_POPUP_SCALE: float = 1.08

var popup_top: float = 0.0:
	set(value):
		popup_top = value
		_sync_to_viewport()

var popup_bottom: float = 0.0:
	set(value):
		popup_bottom = value
		_sync_to_viewport()

var _open_tween: Tween = null
var _rest_scale: float = 1.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if !get_viewport().size_changed.is_connected(_sync_to_viewport):
		get_viewport().size_changed.connect(_sync_to_viewport)
	_sync_to_viewport()
	scale = Vector2.ONE * _rest_scale * OPEN_START_FACTOR
	call_deferred("_play_open_bounce")

func _exit_tree() -> void:
	if _open_tween != null and _open_tween.is_valid():
		_open_tween.kill()
	if get_viewport() != null and get_viewport().size_changed.is_connected(_sync_to_viewport):
		get_viewport().size_changed.disconnect(_sync_to_viewport)

func _play_open_bounce() -> void:
	if !is_inside_tree():
		return
	if _open_tween != null and _open_tween.is_valid():
		_open_tween.kill()

	scale = Vector2.ONE * _rest_scale * OPEN_START_FACTOR
	_open_tween = create_tween()
	_open_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var grow_tweener: PropertyTweener = _open_tween.tween_property(self, "scale", Vector2.ONE * _rest_scale * OPEN_PEAK_FACTOR, OPEN_GROW_DURATION)
	grow_tweener.set_trans(Tween.TRANS_CUBIC)
	grow_tweener.set_ease(Tween.EASE_OUT)
	var settle_tweener: PropertyTweener = _open_tween.tween_property(self, "scale", Vector2.ONE * _rest_scale, OPEN_SETTLE_DURATION)
	settle_tweener.set_trans(Tween.TRANS_QUAD)
	settle_tweener.set_ease(Tween.EASE_IN_OUT)

func _sync_to_viewport() -> void:
	if !is_inside_tree():
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var fit_scale: float = PORTRAIT_LAYOUT.fit_scale(viewport_size)
	var stage_height: float = PORTRAIT_LAYOUT.expanded_stage_height(viewport_size)
	var centered_stage_shift: float = (stage_height - popup_top - popup_bottom) * 0.5
	position = Vector2(0.0, centered_stage_shift * fit_scale)
	size = viewport_size
	custom_minimum_size = viewport_size
	_rest_scale = PORTRAIT_LAYOUT.adaptive_ui_scale(viewport_size, MAX_ADAPTIVE_POPUP_SCALE)

	# Scale around the visual center of the popup itself, not the top-left of the
	# viewport. This keeps both the adaptive size and bounce centered.
	var popup_center_stage := Vector2(STAGE_SIZE.x * 0.5, (popup_top + popup_bottom) * 0.5)
	pivot_offset = Vector2(PORTRAIT_LAYOUT.horizontal_offset(viewport_size), 0.0) + popup_center_stage * fit_scale
	if _open_tween == null or !_open_tween.is_valid():
		scale = Vector2.ONE * _rest_scale
