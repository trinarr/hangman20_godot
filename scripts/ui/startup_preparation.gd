extends CanvasLayer
## Own the first-launch splash until Home and shared local resources are ready.
signal prepared
const THEMES = preload("res://scripts/core/theme_asset_cache.gd")
const HERO = preload("res://scripts/ui/flash_stage_symbol.gd")

var preparing: bool = true
var entrance_pending: bool = true
var _fonts_ready: bool = false
var _releasing: bool = false
var _logo: Control
var _cover: ColorRect
var _native: Object

func _ready() -> void:
	layer = 1000
	set_process(false)
	_cover = ColorRect.new()
	_cover.color = Color.BLACK
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
	logo.set("defer_entrance", true)
	fonts.set("startup_mode", true)
	fonts.finished.connect(func(): _fonts_ready = true, CONNECT_ONE_SHOT)
	logo.entrance_finished.connect(func(): entrance_pending = false, CONNECT_ONE_SHOT)
	logo.entrance_finished.connect(after_entrance, CONNECT_ONE_SHOT)
	home.tree_exiting.connect(_cancel, CONNECT_ONE_SHOT)
	fonts.start.call_deferred()
	set_process(true)

func _process(_delta: float) -> void:
	if !preparing or _releasing or !_fonts_ready:
		return
	if THEMES.is_prewarm_pending() or HERO.is_prewarm_pending():
		return
	_releasing = true
	_release.call_deferred()

func _release() -> void:
	# Let layout, shader setup and the first real Home draw finish under the splash.
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	if !preparing or !is_instance_valid(_logo):
		return
	_cover.hide()
	if _native != null:
		_native.finishHomeStartup()
		while preparing and !_native.isHomeStartupSplashDismissed():
			await get_tree().process_frame
	if !preparing or !is_instance_valid(_logo):
		return
	preparing = false
	set_process(false)
	_logo.call("_start_entrance")
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
