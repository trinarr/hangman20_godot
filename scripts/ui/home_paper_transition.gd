extends CanvasLayer

const TRANSITION_SHADER: Shader = preload("res://shaders/home_paper_transition.gdshader")
const PORTRAIT_LAYOUT: GDScript = preload("res://scripts/ui/portrait_stage_layout.gd")
const FADE_OUT_SECONDS: float = 0.20
const OPEN_SECONDS: float = 0.65 / 1.40 / 1.15
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
var _logo: Control
var _buttons: Array[Control] = []
var _action: Callable
var _normalized_logo_rect := Rect2()
var _source_size := Vector2.ONE
var _navigated: bool = false

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
	_material.set_shader_parameter("home_texture", _home_viewport.get_texture())
	_cover = ColorRect.new()
	_cover.name = "HomePaperTransitionCover"
	_cover.color = Color.WHITE
	_cover.material = _material
	_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_cover)

	# Separate foreground from the blue texture: it fades in place while the
	# upper/lower pieces move. The logo draws ink only, leaving the gap transparent.
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
	_navigate()

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
	_material.set_shader_parameter("canvas_size", viewport_size)
	_material.set_shader_parameter("logo_rect", Vector4(rect.position.x, rect.position.y, rect.size.x, rect.size.y))

func _fade_home(opacity: float) -> void:
	if is_instance_valid(_logo):
		_logo.call("set_foreground_opacity", opacity)
	for button: Control in _buttons:
		if is_instance_valid(button):
			button.modulate.a = opacity

func _set_progress(progress: float) -> void:
	_material.set_shader_parameter("progress", progress)

func _set_header_content_opacity(opacity: float) -> void:
	_material.set_shader_parameter("header_content_opacity", opacity)

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
	_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	# Start every track together, with no wait for the logo or gathering phase.
	_tween.set_parallel(true)
	_tween.tween_method(_fade_home, 1.0, 0.0, FADE_OUT_SECONDS)
	_tween.tween_method(_set_progress, 0.0, 1.0, OPEN_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_method(_set_header_content_opacity, 1.0, 0.0, HEADER_FADE_OUT_SECONDS)
	_tween.chain().tween_callback(queue_free)

func _exit_tree() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if get_viewport().size_changed.is_connected(_sync_layout):
		get_viewport().size_changed.disconnect(_sync_layout)
