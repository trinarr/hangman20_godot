extends CanvasLayer
## Own the launch splash until the initial screen can draw.
signal prepared

var preparing: bool = true
var entrance_pending: bool = true
var _logo: Control
var _cover: ColorRect
var _native: Object
var _screen: Control
var _screen_ready: Callable

func _ready() -> void:
	layer = 1000
	set_process(false)
	_cover = ColorRect.new()
	# Also cover exports without the optional native gate with Home's base color.
	_cover.color = preload("res://scripts/ui/ui_palette.gd").UI_BLUE
	_cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cover.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_cover)
	if Engine.has_singleton("AndroidRuntime"):
		var runtime: Object = Engine.get_singleton("AndroidRuntime")
		var activity: Object = runtime.getActivity()
		if activity != null and activity.has_java_method("finishHomeStartup") and activity.has_java_method("isHomeStartupSplashDismissed"):
			_native = activity

func prepare_home(logo: Control, fonts: Node, home: Control, after_entrance: Callable) -> void:
	_logo = logo
	_screen = home
	logo.set("defer_entrance", true)
	logo.entrance_finished.connect(fonts.start, CONNECT_ONE_SHOT)
	logo.entrance_finished.connect(func(): entrance_pending = false, CONNECT_ONE_SHOT)
	logo.entrance_finished.connect(after_entrance, CONNECT_ONE_SHOT)
	home.tree_exiting.connect(_cancel, CONNECT_ONE_SHOT)
	_release.call_deferred()

func prepare_screen(screen: Control, ready_check: Callable) -> void:
	_screen = screen
	_screen_ready = ready_check
	screen.tree_exiting.connect(_cancel, CONNECT_ONE_SHOT)
	_release.call_deferred()

func _release() -> void:
	while preparing and is_instance_valid(_screen) and _screen_ready.is_valid() and !_screen_ready.call():
		await get_tree().process_frame
	if !preparing or !is_instance_valid(_screen):
		return
	# Submit the real screen, including mandatory consent, before native release.
	_cover.hide()
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	if !preparing or !is_instance_valid(_screen):
		return
	if _native != null:
		_native.finishHomeStartup()
		while preparing and !_native.isHomeStartupSplashDismissed():
			await get_tree().process_frame
	if !preparing or !is_instance_valid(_screen):
		return
	preparing = false
	set_process(false)
	if is_instance_valid(_logo):
		_logo.call("_start_entrance")
	else:
		entrance_pending = false
	prepared.emit()
	_cover.queue_free()

func _cancel() -> void:
	preparing = false
	entrance_pending = false
	set_process(false)
	if _native != null:
		_native.finishHomeStartup()
	if is_instance_valid(_cover):
		_cover.queue_free()

func _exit_tree() -> void:
	_cancel()
