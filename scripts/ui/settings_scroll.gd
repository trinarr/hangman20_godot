extends ScrollContainer

# Existing stage widgets already scale themselves to the viewport. Keep this
# container in pixels and translate their stage canvas instead of scaling twice.
const LAYOUT: GDScript = preload("res://scripts/ui/portrait_stage_layout.gd")

var stage_rect: Rect2
var content_origin_y: float = 206.0
var content_height: float = 600.0
var stage_content := Control.new()
var _extent := Control.new()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	follow_focus = true
	clip_contents = true
	_extent.name = "ScrollExtent"
	_extent.mouse_filter = Control.MOUSE_FILTER_PASS
	_extent.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_extent)
	stage_content.name = "SettingsStageContent"
	stage_content.mouse_filter = Control.MOUSE_FILTER_PASS
	_extent.add_child(stage_content)
	get_viewport().size_changed.connect(_sync_to_stage)
	_sync_to_stage()
	call_deferred("_prepare_touch_controls", stage_content)

func _exit_tree() -> void:
	if get_viewport() != null and get_viewport().size_changed.is_connected(_sync_to_stage):
		get_viewport().size_changed.disconnect(_sync_to_stage)

func _prepare_touch_controls(node: Node) -> void:
	# Let real touch/drag events bubble from the custom mouse-driven buttons to
	# ScrollContainer. Their mouse clicks still use their normal release action.
	if node is Control and node.mouse_filter == Control.MOUSE_FILTER_STOP:
		node.mouse_filter = Control.MOUSE_FILTER_PASS
	for child: Node in node.get_children():
		_prepare_touch_controls(child)

func _sync_to_stage() -> void:
	var viewport_size := get_viewport_rect().size
	var fit: float = LAYOUT.fit_scale(viewport_size)
	var offset: float = LAYOUT.horizontal_offset(viewport_size)
	position = Vector2(offset, 0.0) + stage_rect.position * fit
	size = stage_rect.size * fit
	scroll_deadzone = maxi(8, int(round(8.0 * fit)))
	_extent.custom_minimum_size = Vector2(0.0, content_height * fit)
	stage_content.position = -Vector2(offset + stage_rect.position.x * fit, content_origin_y * fit)
	stage_content.size = Vector2(480.0, content_origin_y + content_height) * fit
