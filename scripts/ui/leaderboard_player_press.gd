extends "res://scripts/ui/flash_stage_texture_button.gd"
## Observe taps without taking GUI ownership, including over the pinned card.
## Godot's touch-to-mouse emulation supplies the same stream on Android.
const SCROLL = preload("res://scripts/ui/settings_scroll.gd")
var active := false
var scroll_surface: ScrollContainer
var _distance := 0.0

func _ready() -> void:
	use_stage_layout = false
	press_scale_enabled = true
	allow_parent_scroll_drag = true
	super._ready()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visibility_changed.connect(cancel_press)

func _input(event: InputEvent) -> void:
	if !active or !is_visible_in_tree() or get_parent().modulate.a <= 0.0:
		cancel_press()
		return
	if event is InputEventMouseMotion and _is_down:
		_distance += event.relative.length() / maxf(get_global_transform().get_scale().x, 0.001)
		if _distance >= SCROLL.DRAG_DEADZONE_STAGE_PX:
			cancel_press()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var local := make_input_local(event) as InputEventMouseButton
		var inside := Rect2(Vector2.ZERO, size).has_point(local.position)
		if is_instance_valid(scroll_surface):
			inside = inside and scroll_surface.get_global_rect().has_point(event.position)
		# A modal or another interactive control above the list owns this tap.
		var hovered := get_viewport().gui_get_hovered_control()
		if hovered != null and hovered != scroll_surface and !get_parent().is_ancestor_of(hovered):
			inside = false
		if event.pressed:
			_distance = 0.0
			if inside:
				super._gui_input(local)
		elif _is_down:
			if inside:
				super._gui_input(local)
			else:
				cancel_press()

func cancel_press() -> void:
	if _is_down:
		_is_down = false
		_set_press_scale(false)

func _sync_visual_child_scales() -> void:
	if !is_inside_tree():
		return
	for path in ["CardFace", "CardShadow"]:
		var visual := get_parent().get_node_or_null(path) as Control
		if visual != null:
			visual.pivot_offset = position + size * 0.5 - visual.position
			visual.scale = visual_scale
