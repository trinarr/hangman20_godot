extends SubViewportContainer

# The complete page is rendered into one texture. Unlike CanvasGroup this
# includes every Z layer, text shader and scroll clip in the same opacity fade.
var page_viewport: SubViewport

func _ready() -> void:
	stretch = true
	stretch_shrink = 1
	mouse_filter = Control.MOUSE_FILTER_PASS
	page_viewport = SubViewport.new()
	page_viewport.name = "TabbedPageViewport"
	page_viewport.disable_3d = true
	page_viewport.transparent_bg = true
	page_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(page_viewport)
	_sync_size()
	get_viewport().size_changed.connect(_sync_size)

func _sync_size() -> void:
	var parent_viewport := get_viewport()
	var logical_size := parent_viewport.get_visible_rect().size
	if logical_size.x <= 0.0 or logical_size.y <= 0.0:
		return
	# canvas_items stretch renders the root at the window's real pixel density.
	# A default SubViewport only follows logical Control dimensions, so on a
	# larger display its texture would be magnified after the text was rendered.
	var pixel_scale := parent_viewport.get_stretch_transform().get_scale().abs()
	var pixels := Vector2i((logical_size * pixel_scale).round())
	pixels = pixels.max(Vector2i(2, 2))
	# Keep native page coordinates/input mapping while making the texture match
	# its physical output size. The inverse container scale cancels root stretch.
	page_viewport.size_2d_override = Vector2i(logical_size.round())
	page_viewport.size_2d_override_stretch = true
	scale = logical_size / Vector2(pixels)
	size = Vector2(pixels)

func _exit_tree() -> void:
	if get_viewport().size_changed.is_connected(_sync_size):
		get_viewport().size_changed.disconnect(_sync_size)
