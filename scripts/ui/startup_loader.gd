extends Node
## Keep the initial scene resource out of this script's preload graph.
signal finished(runtime: Node)
signal fade_started
const RUNTIME_PATH: String = "res://scenes/Main.tscn"
const SCREEN = preload("res://scripts/ui/startup_screen.gd")

var screen: Control
var runtime: Node
var _native: Object
var _loading: bool = false
var _installing: bool = false
var _overlay: CanvasLayer
var _loads = preload("res://scripts/core/threaded_resource_queue.gd").new()
var _packed: PackedScene
var _legal_popup: CanvasLayer
var _transition: CanvasLayer
var _ui_audio: AudioStreamPlayer
var _legal_close_pending: int = 0
var _database: Object = Database
var _database_loading: bool = false
var _database_ready: bool = false
var _keep_fallback: bool = false
var _splash_dismissed: bool = false
var _preparation_started: bool = false

func _ready() -> void:
	# Keep the first-run shell stable even after consent changes the saved state.
	_keep_fallback = GameState.accepted_legal_documents_version == 0
	_overlay = CanvasLayer.new()
	_overlay.layer = 1001
	add_child(_overlay)
	screen = SCREEN.new()
	screen.initial_logo_language = "en" if _keep_fallback else GameState.interface_language
	_overlay.add_child(screen)
	screen.retry_requested.connect(_retry)
	if Engine.has_singleton("AndroidRuntime"):
		var activity: Object = Engine.get_singleton("AndroidRuntime").getActivity()
		if activity != null and activity.has_java_method("finishHomeStartup") and activity.has_java_method("isHomeStartupSplashDismissed"):
			_native = activity
	set_process(true)
	_begin.call_deferred()

func _begin() -> void:
	# Wait for the loading screen and its progress bar to be drawn before releasing the native splash.
	await RenderingServer.frame_post_draw
	if !is_inside_tree():
		return
	if _native != null:
		_native.finishHomeStartup()
	screen.set_progress(0.05)
	_request()
	_start_database()
	if _native != null:
		while !_native.isHomeStartupSplashDismissed():
			await get_tree().process_frame
			if !is_inside_tree():
				return
	GameState.ensure_initial_player_profile()
	_splash_dismissed = true
	if _database_ready:
		_prepare_after_splash.call_deferred()
	_try_install()

func _start_database() -> void:
	_database_loading = true
	_database.load_languages(GameState.interface_language, GameState.word_language)
	set_process(true)

func _retry() -> void:
	if !_database_ready and !_database_loading:
		_start_database()
	if _packed == null:
		_request()

func _prepare_after_splash() -> void:
	if !is_inside_tree() or is_queued_for_deletion() or !_database_ready or !_splash_dismissed or _preparation_started:
		return
	_preparation_started = true
	if !GameState.has_accepted_legal_documents():
		_ui_audio = load("res://scripts/ui/ui_audio_feedback.gd").new()
		add_child(_ui_audio)
		_legal_popup = load("res://scripts/ui/legal_consent_popup.gd").show(self, _accept_legal_documents,
			1002, null, false, _ui_audio.play_popup_open, _ui_audio.play_click)
	# Submit the optional legal modal before spending a frame on debug diagnostics.
	await RenderingServer.frame_post_draw
	if is_instance_valid(_legal_popup) and !_legal_popup.stage.open_bounce_complete:
		_legal_popup.stage.open_bounce_finished.connect(_request_debug_summary, CONNECT_ONE_SHOT)
	else:
		_request_debug_summary()

func _request_debug_summary() -> void:
	if is_inside_tree() and !is_queued_for_deletion():
		Database.request_debug_database_summary()

func _request() -> void:
	if _loading:
		return
	var error: Error = _loads.request(RUNTIME_PATH, "PackedScene", _on_resource_ready)
	if error != OK:
		screen.show_load_error()
		return
	_loading = true
	set_process(true)

func _process(_delta: float) -> void:
	if OS.get_environment("HANGMAN_TEST_HIDE_WINDOW") == "1":
		RenderingServer.force_draw(false)
	if _database_loading:
		var status: Error = _database.get_word_language_load_status()
		if status == OK:
			_database_loading = false
			_database_ready = true
			if !_keep_fallback:
				screen.apply_database_language()
			if _loading or _packed != null:
				screen.clear_load_error()
			_prepare_after_splash.call_deferred()
			_try_install()
		elif status != ERR_BUSY:
			_database_loading = false
			screen.show_load_error()
	if !_loading or _installing or _packed != null:
		return
	var progress: Array = []
	_loads.loader.load_threaded_get_status(RUNTIME_PATH, progress)
	if !progress.is_empty():
		screen.set_progress(0.05 + float(progress[0]) * 0.80)

func _on_resource_ready(_path: String, resource: Resource) -> void:
	if !is_inside_tree():
		return
	_packed = resource as PackedScene
	if _packed == null:
		_loading = false
		screen.show_load_error()
		return
	screen.set_progress(0.85)
	_try_install()

func _accept_legal_documents() -> void:
	if GameState.has_accepted_legal_documents():
		return
	if !GameState.accept_legal_documents():
		screen._show_portrait_status_toast(tr("CONSENT_SAVE_ERROR"))
		return
	screen.hide_status_toast()
	if is_instance_valid(_legal_popup):
		var fades: Array[CanvasLayer] = load("res://scripts/ui/portrait_popup.gd").remove_group(self, &"legal_consent_popup", 0.14)
		_legal_close_pending = fades.size()
		for fade: CanvasLayer in fades:
			fade.tree_exited.connect(_on_legal_dimmer_closed, CONNECT_DEFERRED | CONNECT_ONE_SHOT)
		_legal_popup = null
	ConsentRegion.refresh()
	_try_install()

func _on_legal_dimmer_closed() -> void:
	if !is_inside_tree() or is_queued_for_deletion():
		return
	_legal_close_pending = maxi(0, _legal_close_pending - 1)
	_try_install()

func _try_install() -> void:
	if _packed == null or !_database_ready or !_splash_dismissed or _installing or _legal_close_pending > 0 or !GameState.has_accepted_legal_documents():
		return
	_installing = true
	_install.call_deferred()

func _install() -> void:
	# Show completion of resource loading before main-thread UI construction.
	screen.set_progress(0.85)
	await RenderingServer.frame_post_draw
	if !is_inside_tree():
		return
	runtime = _packed.instantiate()
	_packed = null
	var preparation: Node = runtime.get_node("StartupPreparation")
	preparation.prepared.connect(_on_prepared, CONNECT_ONE_SHOT)
	add_child(runtime)
	screen.set_progress(0.95)

func _on_prepared() -> void:
	if !is_inside_tree():
		return
	screen.set_progress(1.0)
	# Label shaping is deferred; include a process frame before the final draw.
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	if !is_inside_tree():
		return
	# Reuse the page transition: fade the complete rendered frame as one image.
	# Load the transition only now, keeping its dependencies off the splash path.
	var frame: Image = get_viewport().get_texture().get_image()
	_transition = load("res://scripts/ui/tabbed_page_transition.gd").new()
	_transition.name = "LoadingScreenFade"
	add_child(_transition)
	_transition.finished.connect(_finish_loading, CONNECT_ONE_SHOT)
	_transition.start(screen, _hide_loading_layers, false, ImageTexture.create_from_image(frame))
	_transition.layer = 1004
	fade_started.emit()

func _hide_loading_layers() -> void:
	_overlay.hide()
	# CanvasLayer children (the status toaster) own independent visibility.
	for child: Node in screen.find_children("*", "CanvasLayer", true, false):
		(child as CanvasLayer).hide()

func _finish_loading() -> void:
	if !is_inside_tree() or is_queued_for_deletion():
		return
	_overlay.queue_free()
	if is_instance_valid(_ui_audio):
		_ui_audio.queue_free()
		_ui_audio = null
	_loading = false
	set_process(false)
	finished.emit(runtime)

func _exit_tree() -> void:
	_loading = false
	set_process(false)
	if _native != null:
		_native.finishHomeStartup()
