extends CanvasLayer

const TRANSITION_SHADER: Shader = preload("res://shaders/home_paper_transition.gdshader")
const PAPER_BACKGROUND_SCRIPT: GDScript = preload("res://scripts/ui/portrait_paper_background.gd")
const PORTRAIT_LAYOUT: GDScript = preload("res://scripts/ui/portrait_stage_layout.gd")
const FADE_OUT_SECONDS: float = 0.20
const MOVEMENT_SPEED: float = 0.88
const GATHER_SECONDS: float = 0.10 / MOVEMENT_SPEED
const GATHER_DISTANCE: float = 18.0
const OPEN_SECONDS: float = (0.65 / 1.40 / 1.15) / MOVEMENT_SPEED
const HEADER_FADE_OUT_SECONDS: float = 0.18

# _clear() runs synchronously while building the destination. Retain the
# transition and its independent Home artwork throughout that rebuild.
var header_stage_height: float = 80.0
var committing: bool = false
var _cover: ColorRect
var _input_blocker: Control
var _foreground: Control
var _home_viewport: SubViewport
var _material: ShaderMaterial
var _tween: Tween
var _fade_tween: Tween
var _logo: Control
var _buttons: Array[Control] = []
var _action: Callable
var _normalized_logo_rect := Rect2()
var _source_size := Vector2.ONE
var _navigated: bool = false
var _prepared_frames: int = 0
static var _warmup_started: bool = false

static func warm_up(host: Node) -> void:
	if _warmup_started:
		return
	_warmup_started = true
	# preload() loads shader resources, but does not submit their first draw.
	# Render offscreen once while Home is displayed, before the first navigation.
	var viewport := SubViewport.new()
	viewport.name = "HomeTransitionShaderWarmup"
	viewport.disable_3d = true
	viewport.gui_disable_input = true
	viewport.size = Vector2i(64, 64)
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	host.add_child(viewport)
	var paper := ColorRect.new()
	paper.size = Vector2(64.0, 64.0)
	var paper_material := ShaderMaterial.new()
	paper_material.shader = PAPER_BACKGROUND_SCRIPT.PAPER_SHADER
	PAPER_BACKGROUND_SCRIPT.configure_material(paper_material, paper.size)
	paper.material = paper_material
	viewport.add_child(paper)
	var cover := ColorRect.new()
	cover.size = paper.size
	var cover_material := ShaderMaterial.new()
	cover_material.shader = TRANSITION_SHADER
	PAPER_BACKGROUND_SCRIPT.configure_material(cover_material, cover.size)
	cover_material.set_shader_parameter("home_texture", PAPER_BACKGROUND_SCRIPT.PAPER_TEXTURE)
	cover_material.set_shader_parameter("canvas_size", cover.size)
	cover_material.set_shader_parameter("header_bottom", 8.0)
	cover_material.set_shader_parameter("logo_rect", Vector4(16.0, 8.0, 32.0, 32.0))
	cover_material.set_shader_parameter("destination_ready", true)
	cover.material = cover_material
	viewport.add_child(cover)
	RenderingServer.frame_post_draw.connect(viewport.queue_free, CONNECT_ONE_SHOT)

func start(home_content: Control, logo: Control, buttons: Array[Control], action: Callable) -> void:
	layer = 1000
	_logo = logo
	_buttons = buttons
	_action = action
	_source_size = get_viewport().get_visible_rect().size
	_logo.call("prepare_departure")
	var anchor: Control = _logo.get("logo_anchor")
	var logo_rect: Rect2 = anchor.get_global_rect()
	_normalized_logo_rect = Rect2(logo_rect.position / _source_size, logo_rect.size / _source_size)

	# Keep Home's background/counters on the GPU, independently of the new UI.
	# Render once: no screen readback, and no sampling of the destination as blue.
	_home_viewport = SubViewport.new()
	_home_viewport.disable_3d = true
	_home_viewport.gui_disable_input = true
	_home_viewport.size = Vector2i(_source_size)
	_home_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(_home_viewport)
	var home_root := Control.new()
	home_root.theme = home_content.get_parent_control().theme
	_home_viewport.add_child(home_root)
	home_content.reparent(home_root, false)

	_material = ShaderMaterial.new()
	_material.shader = TRANSITION_SHADER
	_material.set_shader_parameter("gather_distance", GATHER_DISTANCE)
	_material.set_shader_parameter("home_texture", _home_viewport.get_texture())
	_cover = ColorRect.new()
	_cover.name = "HomePaperTransitionCover"
	_cover.color = Color.WHITE
	_cover.material = _material
	_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_cover)

	# Separate foreground from the blue texture so its fade can overlap motion.
	# The cover retains Home paper until the destination has been built.
	_foreground = Control.new()
	_foreground.theme = home_root.theme
	_foreground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_foreground)
	_logo.reparent(_foreground, false)
	for button: Control in _buttons:
		button.reparent(_foreground, false)
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# A transparent full-screen control also blocks pointer/touch input over
	# the already-built destination until the entire transition has finished.
	_input_blocker = Control.new()
	_input_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_input_blocker)
	_sync_layout()
	get_viewport().size_changed.connect(_sync_layout)
	_start_gather()

func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion:
		get_viewport().set_input_as_handled()

func _sync_layout() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	_cover.size = viewport_size
	_input_blocker.size = viewport_size
	_foreground.scale = viewport_size / _source_size
	var rect := Rect2(_normalized_logo_rect.position * viewport_size, _normalized_logo_rect.size * viewport_size)
	_material.set_shader_parameter("header_bottom", (
		header_stage_height + PORTRAIT_LAYOUT.safe_top_stage(viewport_size)
	) * PORTRAIT_LAYOUT.fit_scale(viewport_size))
	PAPER_BACKGROUND_SCRIPT.configure_material(_material, viewport_size)
	_material.set_shader_parameter("canvas_size", viewport_size)
	_material.set_shader_parameter("logo_rect", Vector4(rect.position.x, rect.position.y, rect.size.x, rect.size.y))

func _fade_logo(opacity: float) -> void:
	if is_instance_valid(_logo):
		_logo.call("set_foreground_opacity", opacity)

func _fade_buttons(opacity: float) -> void:
	for button: Control in _buttons:
		if is_instance_valid(button):
			button.modulate.a = opacity

func _set_progress(progress: float) -> void:
	_material.set_shader_parameter("progress", progress)

func _set_gather(amount: float) -> void:
	_material.set_shader_parameter("gather", amount)
	if is_instance_valid(_logo):
		_logo.call("set_departure_inset", amount * GATHER_DISTANCE)

func _set_header_content_opacity(opacity: float) -> void:
	_material.set_shader_parameter("header_content_opacity", opacity)

func _start_gather() -> void:
	# Keep Home behind the pieces for the entire inward movement.
	_fade_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	# The logo must be completely gone exactly at maximum gather. Keep the
	# buttons on their existing fade timing so their departure remains unchanged.
	_fade_tween.tween_method(_fade_logo, 1.0, 0.0, GATHER_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_fade_tween.parallel().tween_method(_fade_buttons, 1.0, 0.0, FADE_OUT_SECONDS)
	_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_method(_set_gather, 0.0, 1.0, GATHER_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_callback(_at_gather_peak)

func _at_gather_peak() -> void:
	# Present maximum inward displacement before constructing the destination.
	RenderingServer.frame_post_draw.connect(_queue_navigation, CONNECT_ONE_SHOT)

func _queue_navigation() -> void:
	call_deferred("_navigate")

func _navigate() -> void:
	if _navigated:
		return
	_navigated = true
	committing = true
	if _action.is_valid():
		_action.call()
	committing = false
	_action = Callable()
	# The destination's deferred layout/entrance work is queued before opening.
	call_deferred("_reveal_destination")

func _reveal_destination() -> void:
	if is_queued_for_deletion():
		return
	# Keep the old cover/foreground still while the destination submits its first
	# frame (including deferred layout, glyph uploads and first-use pipelines).
	# Hold maximum gather until the destination is ready to reveal.
	_prepared_frames = 0
	RenderingServer.frame_post_draw.connect(_queue_motion)

func _queue_motion() -> void:
	_prepared_frames += 1
	# One further frame keeps the cold frame's large delta out of the first
	# opening update. The inward movement and fade have already finished.
	if _prepared_frames < 2:
		return
	RenderingServer.frame_post_draw.disconnect(_queue_motion)
	call_deferred("_start_opening")

func _start_opening() -> void:
	if is_queued_for_deletion():
		return
	_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	# Swap the paper for the real destination at maximum gather, then open.
	_material.set_shader_parameter("destination_ready", true)
	_tween.tween_method(_set_progress, 0.0, 1.0, OPEN_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_tween.parallel().tween_method(_set_gather, 1.0, 0.0, OPEN_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_tween.parallel().tween_method(_set_header_content_opacity, 1.0, 0.0, HEADER_FADE_OUT_SECONDS)
	_tween.chain().tween_callback(queue_free)

func _exit_tree() -> void:
	if RenderingServer.frame_post_draw.is_connected(_queue_navigation):
		RenderingServer.frame_post_draw.disconnect(_queue_navigation)
	if RenderingServer.frame_post_draw.is_connected(_queue_motion):
		RenderingServer.frame_post_draw.disconnect(_queue_motion)
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if get_viewport().size_changed.is_connected(_sync_layout):
		get_viewport().size_changed.disconnect(_sync_layout)
