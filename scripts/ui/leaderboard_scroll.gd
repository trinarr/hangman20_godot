extends "res://scripts/ui/settings_scroll.gd"
## Native-layout adapter for Settings' edge resistance and elastic return.
## ScrollContainer owns the VBox geometry; this script adds only a visual offset.
signal visual_offset_changed

func _ready() -> void:
	# Settings' wrapper nodes belong to its stage layout, not this native list.
	_extent.free()
	_extent = null
	stage_content.free()
	stage_content = null
	mouse_filter = Control.MOUSE_FILTER_STOP
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	clip_contents = true
	gui_input.connect(_on_scroll_gui_input)
	resized.connect(_sync_to_stage)
	get_v_scroll_bar().value_changed.connect(func(_value: float): _sync_stage_content_position.call_deferred())
	_sync_to_stage()

func set_list(list: Control) -> void:
	stage_content = list
	add_child(list)

func reset_scroll_effect() -> void:
	_stop_overscroll_return()
	_pointer_kind = PointerKind.NONE
	_touch_index = -1
	_drag_distance = 0
	_drag_started = false
	_set_overscroll_offset(0)

func _sync_to_stage() -> void:
	# GUI deltas already use logical units in the leaderboard's scaled subtree.
	_fit_scale = 1.0
	scroll_deadzone = int(DRAG_DEADZONE_STAGE_PX)
	_sync_stage_content_position.call_deferred()

func _sync_stage_content_position() -> void:
	if is_instance_valid(stage_content):
		stage_content.position.y = -float(scroll_vertical) + _overscroll_offset_y
	visual_offset_changed.emit()
