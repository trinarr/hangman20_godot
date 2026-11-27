extends Node
## Keep the initial scene resource out of this script's preload graph.
signal finished(runtime: Node)
signal fade_started
const RUNTIME_PATH: String = "res://scenes/Main.tscn"
const SCREEN = preload("res://scripts/ui/startup_screen.gd")
const DRAW_TIMEOUT_MS: int = 750
const LOAD_TIMEOUT_MS: int = 15000

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
var _legal_fades: Array[CanvasLayer] = []
var _database: Object = Database
var _database_loading: bool = false
var _database_ready: bool = false
var _keep_fallback: bool = false
var _splash_dismissed: bool = false
var _preparation_started: bool = false
var _first_draw_pending: bool = true
var _final_draw_after: int = -1
var _paused_at: int = -1
var _phase: StringName
var _deadline: int
var _timed_out: bool = false

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
	_bind_native_activity()
	RenderingServer.frame_post_draw.connect(_on_frame_drawn)
	set_process(true)

func _bind_native_activity() -> void:
	if Engine.has_singleton("AndroidRuntime"):
		var activity: Object = Engine.get_singleton("AndroidRuntime").getActivity()
		if activity != null and activity.has_java_method("finishHomeStartup") and activity.has_java_method("isHomeStartupSplashDismissed"):
			_native = activity

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED and _paused_at < 0:
		_paused_at = Time.get_ticks_msec()
	elif what == NOTIFICATION_APPLICATION_RESUMED and _paused_at >= 0:
		_deadline += Time.get_ticks_msec() - _paused_at
		_paused_at = -1
		if is_node_ready() and !_first_draw_pending and !_splash_dismissed:
			_bind_native_activity()
			_release_native_splash()

func _on_frame_drawn() -> void:
	if _paused_at >= 0 or is_queued_for_deletion():
		return
	if _first_draw_pending:
		_start_loading()
	elif _final_draw_after >= 0 and Engine.get_process_frames() >= _final_draw_after:
		_start_fade()

func _start_loading() -> void:
	_first_draw_pending = false
	_begin()

func _begin() -> void:
	_release_native_splash()
	screen.set_progress(0.05)
	_request()
	_start_database()
	_poll_native_splash()

func _release_native_splash() -> void:
	if is_instance_valid(_native):
		_native.finishHomeStartup()

func _poll_native_splash() -> void:
	if _splash_dismissed or (is_instance_valid(_native) and !_native.isHomeStartupSplashDismissed()):
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
	if _paused_at >= 0 or is_queued_for_deletion():
		return
	if _timed_out and _phase == &"initial_screen" and _packed != null and is_instance_valid(runtime):
		# Keep the packed scene and let the new runtime resume the saved route.
		runtime.free()
		runtime = null
		_installing = false
	_phase = &""
	_timed_out = false
	screen.clear_load_error()
	if !_splash_dismissed:
		_bind_native_activity()
		_release_native_splash()
	if !_database_ready and !_database_loading:
		_start_database()
	if _packed == null:
		_request()
	_try_install()

func _prepare_after_splash() -> void:
	if !is_inside_tree() or is_queued_for_deletion() or !_database_ready or !_splash_dismissed or _preparation_started:
		return
	_preparation_started = true
	if !GameState.has_accepted_legal_documents():
		_ui_audio = load("res://scripts/ui/ui_audio_feedback.gd").new()
		add_child(_ui_audio)
		_legal_popup = load("res://scripts/ui/legal_consent_popup.gd").show(self, _accept_legal_documents,
			1002, null, false, _ui_audio.play_popup_open, _ui_audio.play_click)
	if is_instance_valid(_legal_popup) and !_legal_popup.stage.open_bounce_complete:
		_legal_popup.stage.open_bounce_finished.connect(_request_debug_summary, CONNECT_ONE_SHOT)

func _request_debug_summary() -> void:
	if is_inside_tree() and !is_queued_for_deletion():
		Database.request_debug_database_summary()

func _request() -> void:
	if _loading:
		return
	var error: Error = _loads.request(RUNTIME_PATH, "PackedScene", _on_resource_ready)
	if error != OK:
		_show_load_error(&"main_resource", error)
		return
	_loading = true
	set_process(true)

func _process(_delta: float) -> void:
	if _paused_at >= 0 or is_queued_for_deletion():
		return
	if OS.get_environment("HANGMAN_TEST_HIDE_WINDOW") == "1":
		RenderingServer.force_draw(false)
	if _first_draw_pending:
		_check_startup_deadline()
		return
	_poll_native_splash()
	if _database_loading:
		var status: Error = _database.get_word_language_load_status()
		if status == OK:
			_database_loading = false
			_database_ready = true
			if !_keep_fallback:
				screen.apply_database_language()
			_prepare_after_splash.call_deferred()
		elif status != ERR_BUSY:
			_database_loading = false
			_show_load_error(&"database", status)
	_try_install()
	_check_startup_deadline()
	if !_loading or _installing or _packed != null:
		return
	var progress: Array = []
	_loads.loader.load_threaded_get_status(RUNTIME_PATH, progress)
	if !progress.is_empty():
		screen.set_progress(0.05 + float(progress[0]) * 0.80)

func _on_resource_ready(_path: String, resource: Resource) -> void:
	if !is_inside_tree() or is_queued_for_deletion():
		return
	_packed = resource as PackedScene
	if _packed == null:
		_loading = false
		_show_load_error(&"main_resource", ERR_CANT_OPEN)
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
		_legal_fades = load("res://scripts/ui/portrait_popup.gd").remove_group(self, &"legal_consent_popup", 0.14)
		_legal_close_pending = _legal_fades.size()
		for fade: CanvasLayer in _legal_fades:
			fade.tree_exited.connect(_on_legal_dimmer_closed, CONNECT_DEFERRED | CONNECT_ONE_SHOT)
		_legal_popup = null
	ConsentRegion.refresh()
	_try_install()

func _on_legal_dimmer_closed() -> void:
	if !is_inside_tree() or is_queued_for_deletion():
		return
	_legal_close_pending = maxi(0, _legal_close_pending - 1)
	if _legal_close_pending == 0:
		_legal_fades.clear()
	_try_install()

func _try_install() -> void:
	if _paused_at >= 0 or _packed == null or !_database_ready or !_splash_dismissed or _installing or _legal_close_pending > 0 or !GameState.has_accepted_legal_documents():
		return
	_installing = true
	_install.call_deferred()

func _install() -> void:
	if !is_inside_tree() or is_queued_for_deletion():
		return
	if _paused_at >= 0:
		_installing = false
		return
	var instance: Node = _packed.instantiate()
	var preparation: Node = instance.get_node_or_null("StartupPreparation") if instance != null else null
	# A PackedScene can still load when the exported runtime script cannot compile.
	if instance == null or instance.get_script() == null or !instance.get_script().can_instantiate() \
		or preparation == null or !preparation.has_signal(&"prepared"):
		if instance != null:
			instance.free()
		_packed = null
		_loading = false
		_installing = false
		_show_load_error(&"main_instance", ERR_CANT_CREATE)
		return
	runtime = instance
	preparation.splash_managed_by_loader = true
	preparation.prepared.connect(_on_prepared, CONNECT_ONE_SHOT)
	add_child(runtime)
	screen.set_progress(0.95)

func _on_prepared() -> void:
	if !is_inside_tree() or is_queued_for_deletion():
		return
	_packed = null
	screen.clear_load_error()
	screen.set_progress(1.0)
	# Label shaping is deferred; include a process frame before the final draw.
	_final_draw_after = Engine.get_process_frames() + 1

func _start_fade() -> void:
	_final_draw_after = -1
	var frame: Image = get_viewport().get_texture().get_image()
	if frame == null or frame.is_empty():
		_finish_loading()
		return
	# Reuse the page transition: fade the complete rendered frame as one image.
	# Load the transition only now, keeping its dependencies off the splash path.
	_transition = load("res://scripts/ui/tabbed_page_transition.gd").new()
	_transition.name = "LoadingScreenFade"
	add_child(_transition)
	_transition.finished.connect(_finish_loading, CONNECT_ONE_SHOT)
	_transition.start(screen, _hide_loading_layers, false, ImageTexture.create_from_image(frame))
	_transition.layer = 1004
	fade_started.emit()

func _startup_phase() -> StringName:
	if _first_draw_pending:
		return &"first_frame"
	if _final_draw_after >= 0:
		return &"final_frame"
	if is_instance_valid(_transition):
		return &""
	if !_splash_dismissed:
		return &"native_splash"
	if !_database_ready:
		return &"database" if _database_loading else &""
	if !GameState.has_accepted_legal_documents():
		return &"consent"
	if _legal_close_pending > 0:
		return &"consent_close"
	if _installing:
		return &"initial_screen"
	if _loading and _packed == null:
		return &"main_resource"
	return &""

func _check_startup_deadline() -> void:
	var phase: StringName = _startup_phase()
	var now: int = Time.get_ticks_msec()
	if phase != _phase:
		if _timed_out and (_loading or _packed != null) and (_database_loading or _database_ready):
			screen.clear_load_error()
		_phase = phase
		_timed_out = false
		var visual_wait: bool = phase in [&"first_frame", &"final_frame", &"consent_close"]
		_deadline = now + (DRAW_TIMEOUT_MS if visual_wait else LOAD_TIMEOUT_MS)
		if OS.is_debug_build() and !phase.is_empty():
			print("[Startup] phase=", phase)
	if _timed_out or phase.is_empty() or phase == &"consent" or now < _deadline:
		return
	_timed_out = true
	match phase:
		&"first_frame":
			_start_loading()
		&"final_frame":
			_finish_loading()
		&"consent_close":
			for fade: CanvasLayer in _legal_fades:
				if is_instance_valid(fade):
					fade.queue_free()
		_:
			_show_load_error(phase, ERR_TIMEOUT)
	if phase in [&"first_frame", &"final_frame", &"consent_close"]:
		push_warning("[Startup] skipped visual wait: %s" % phase)

func _show_load_error(phase: StringName, error: Error) -> void:
	push_warning("[Startup] phase=%s error=%s" % [phase, error_string(error)])
	screen.show_load_error()

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
	_final_draw_after = -1
	RenderingServer.frame_post_draw.disconnect(_on_frame_drawn)
	set_process(false)
	finished.emit(runtime)

func _exit_tree() -> void:
	_loading = false
	set_process(false)
	if RenderingServer.frame_post_draw.is_connected(_on_frame_drawn):
		RenderingServer.frame_post_draw.disconnect(_on_frame_drawn)
	if !_splash_dismissed:
		_release_native_splash()
