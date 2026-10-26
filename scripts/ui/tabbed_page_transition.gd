extends CanvasLayer

signal finished

const OPEN_SECONDS: float = 0.24
const CLOSE_SECONDS: float = 0.24
const PAGE_SURFACE_SCRIPT: GDScript = preload("res://scripts/ui/tabbed_page_surface.gd")

# Uses the same retention/cancellation contract as the Home transitions.
var committing: bool = false
var opening: bool = false
var _page_surface: SubViewportContainer
var _blocker: Control
var _tween: Tween
var _outgoing_page: Control
var _handoff_complete: bool = false
var _snapshot: TextureRect
var _destination: Control
var _destination_parent: Control

func start(page: Control, action: Callable, open_page: bool = false, page_texture: Texture2D = null) -> void:
	layer = 1000
	opening = open_page
	_outgoing_page = page
	if !opening:
		# A rendered frame includes every Z layer, text shader and scroll clip.
		# CanvasGroup cannot flatten this screen's mixed-Z children reliably.
		_snapshot = TextureRect.new()
		_snapshot.name = "ClosingPageSnapshot"
		_snapshot.texture = page_texture
		_snapshot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_snapshot.stretch_mode = TextureRect.STRETCH_SCALE
		_snapshot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_snapshot)
	else:
		page.process_mode = Node.PROCESS_MODE_DISABLED
	_blocker = Control.new()
	_blocker.name = "TabbedTransitionInputBlocker"
	_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	_blocker.z_index = RenderingServer.CANVAS_ITEM_Z_MAX
	add_child(_blocker)
	_sync_layout()
	get_viewport().size_changed.connect(_sync_layout)
	# On opening, _clear preserves Home and prepares an empty destination surface
	# before any live controls are added. The final handoff uses an explicit
	# transfer scope so _exit_tree does not dispose the live destination.
	committing = true
	action.call()
	committing = false
	_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if opening:
		_tween.tween_property(_page_surface, "modulate:a", 1.0, OPEN_SECONDS).from(0.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		# Only this one full-screen image loses alpha; the new Home stays opaque.
		_tween.tween_property(_snapshot, "modulate:a", 0.0, CLOSE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_callback(_finish)

func preserved_home() -> Control:
	return _outgoing_page if opening and committing else null

func prepare_destination(destination: Control) -> void:
	_page_surface = PAGE_SURFACE_SCRIPT.new()
	_page_surface.name = "OpeningTabbedPage"
	_page_surface.modulate.a = 0.0
	_page_surface.z_index = RenderingServer.CANVAS_ITEM_Z_MAX
	_destination = destination
	var ui_root := destination.get_parent_control()
	_destination_parent = ui_root
	ui_root.add_child(_page_surface)
	destination.theme = ui_root.theme
	destination.reparent(_page_surface.get("page_viewport"), false)

func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion:
		get_viewport().set_input_as_handled()

func _sync_layout() -> void:
	_blocker.size = get_viewport().get_visible_rect().size
	if is_instance_valid(_snapshot):
		_snapshot.size = _blocker.size

func _finish() -> void:
	if opening:
		_outgoing_page.hide()
		_outgoing_page.queue_free()
		preload("res://scripts/ui/tabbed_page_transfer.gd").finish(_destination, _destination_parent)
		_page_surface.hide()
		_page_surface.queue_free()
		_handoff_complete = true
	finished.emit()
	queue_free()

func _exit_tree() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if opening and !_handoff_complete:
		if is_instance_valid(_outgoing_page):
			_outgoing_page.queue_free()
		if is_instance_valid(_page_surface):
			_page_surface.queue_free()
	if get_viewport().size_changed.is_connected(_sync_layout):
		get_viewport().size_changed.disconnect(_sync_layout)
