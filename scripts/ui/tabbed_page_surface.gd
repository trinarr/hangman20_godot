extends SubViewportContainer

# The complete page is rendered into one texture. Unlike CanvasGroup this
# includes every Z layer, text shader and scroll clip in the same opacity fade.
var page_viewport: SubViewport

func _ready() -> void:
	stretch = true
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
	size = get_viewport().get_visible_rect().size

func _exit_tree() -> void:
	if get_viewport().size_changed.is_connected(_sync_size):
		get_viewport().size_changed.disconnect(_sync_size)
