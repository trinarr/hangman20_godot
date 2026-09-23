extends CanvasLayer

const TRANSITION_SHADER: Shader = preload("res://shaders/home_paper_transition.gdshader")
const PAPER_BACKGROUND_SCRIPT: GDScript = preload("res://scripts/ui/portrait_paper_background.gd")
const PORTRAIT_LAYOUT: GDScript = preload("res://scripts/ui/portrait_stage_layout.gd")
const FADE_OUT_SECONDS: float = 0.20
const GATHER_SECONDS: float = 0.10
const OPEN_SECONDS: float = 0.65 / 1.40 / 1.15
const HEADER_FADE_OUT_SECONDS: float = 0.12
const HEADER_FADE_IN_SECONDS: float = 0.18
const FADE_IN_SECONDS: float = 0.20

# _clear() may run synchronously inside the destination action. In that case
# retain this cover until the new screen has completed its deferred layout.
var header_stage_height: float = 80.0
var header_color: Color
var committing: bool = false
var _cover: ColorRect
var _material: ShaderMaterial
var _tween: Tween
var _logo: Control
var _buttons: Array[Control] = []
var _action: Callable
var _normalized_logo_rect := Rect2()
var _navigated: bool = false

func start(logo: Control, buttons: Array[Control], action: Callable) -> void:
	# Theme selection and resume offers use their own popup CanvasLayers.
	# Cover those as well until the destination fade has finished.
	layer = 1000
	_logo = logo
	_buttons = buttons
	_action = action
	_material = ShaderMaterial.new()
	_material.shader = TRANSITION_SHADER
	_material.set_shader_parameter("header_color", header_color)
	_cover = ColorRect.new()
	_cover.name = "HomePaperTransitionCover"
	_cover.color = Color.TRANSPARENT
	_cover.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_cover)
	_logo.call("prepare_departure")
	_sync_layout()
	get_viewport().size_changed.connect(_sync_layout)
	_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_method(_fade_home, 1.0, 0.0, FADE_OUT_SECONDS)
	_tween.tween_callback(_begin_open)
	# A small symmetric anticipation closes the gap before the blue pieces leave.
	_tween.tween_method(_set_gather, 0.0, 1.0, GATHER_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_method(_set_progress, 0.0, 1.0, OPEN_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_tween.parallel().tween_method(_set_gather, 1.0, 0.0, OPEN_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	# Finish hiding the old counters during the final part of the opening.
	# At the open edge, both new counters and content can appear immediately.
	_tween.parallel().tween_method(_set_header_content_opacity, 1.0, 0.0, HEADER_FADE_OUT_SECONDS).set_delay(OPEN_SECONDS - HEADER_FADE_OUT_SECONDS)
	_tween.chain().tween_callback(_navigate)

func _input(event: InputEvent) -> void:
	# Block keyboard/controller input too, including Escape during the handoff.
	if event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion:
		get_viewport().set_input_as_handled()

func _sync_layout() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	_cover.size = viewport_size
	if is_instance_valid(_logo) and is_instance_valid(_logo.get("logo_anchor")):
		var anchor: Control = _logo.get("logo_anchor")
		var rect: Rect2 = anchor.get_global_rect()
		_normalized_logo_rect = Rect2(rect.position / viewport_size, rect.size / viewport_size)
	var rect := Rect2(_normalized_logo_rect.position * viewport_size, _normalized_logo_rect.size * viewport_size)
	PAPER_BACKGROUND_SCRIPT.configure_material(_material, viewport_size)
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

func _begin_open() -> void:
	_sync_layout()
	_cover.color = Color.WHITE
	_cover.material = _material

func _set_progress(progress: float) -> void:
	_material.set_shader_parameter("progress", progress)

func _set_gather(amount: float) -> void:
	_material.set_shader_parameter("gather", amount)

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
	# Run after the destination's queued layout work, within the same idle cycle.
	# Do not add a timer or opaque process-frame holds after the tear has opened.
	call_deferred("_reveal_destination")

func _reveal_destination() -> void:
	if is_queued_for_deletion():
		return
	_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_property(_cover, "modulate:a", 0.0, FADE_IN_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_method(_set_header_content_opacity, 0.0, 1.0, HEADER_FADE_IN_SECONDS)
	_tween.chain().tween_callback(queue_free)

func _exit_tree() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if get_viewport().size_changed.is_connected(_sync_layout):
		get_viewport().size_changed.disconnect(_sync_layout)
