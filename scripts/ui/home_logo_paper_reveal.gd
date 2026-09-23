extends ColorRect

signal buttons_appearance_changed(opacity: float, visual_scale: float)
signal buttons_bounce_finished

const REVEAL_SHADER: Shader = preload("res://shaders/home_logo_paper_reveal.gdshader")
const PAPER_BACKGROUND_SCRIPT: GDScript = preload("res://scripts/ui/portrait_paper_background.gd")
const PEEL_SPEED_MULTIPLIER: float = 1.30
const BADGE_BOUNCE_SPEED: float = 1.20
const BACKSIDE_TEXTURE: Texture2D = preload("res://flash_assets/word_paper_backside.png")

# The existing adaptive logo holder remains the source of position and scale.
# This separate, unscaled layer reaches the physical left and right screen edges.
var logo_anchor: Control
var logo_texture: Texture2D
var title_texture: Texture2D
var title_chroma_key: bool = false
var start_delay: float = 0.12
var reveal_duration: float = 0.71
var badge_grow_duration: float = 0.18
var badge_settle_duration: float = 0.22
var shine_duration: float = 0.75
var _reveal_material: ShaderMaterial
var _entrance_tween: Tween
var _buttons_opacity: float = 0.0
var _buttons_tween: Tween
var _buttons_started: bool = false
var _departing: bool = false

func _ready() -> void:
	name = "HomeLogoPaperReveal"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	color = Color.WHITE
	_reveal_material = ShaderMaterial.new()
	_reveal_material.shader = REVEAL_SHADER
	_reveal_material.set_shader_parameter("logo_texture", logo_texture)
	_reveal_material.set_shader_parameter("title_texture", title_texture if title_texture != null else logo_texture)
	_reveal_material.set_shader_parameter("title_chroma_key", title_chroma_key)
	_reveal_material.set_shader_parameter("backside_texture", BACKSIDE_TEXTURE)
	# Initialize before the first draw: only the normal blue background is visible.
	_reveal_material.set_shader_parameter("reveal_progress", 0.0)
	_reveal_material.set_shader_parameter("badge_alpha", 0.0)
	_reveal_material.set_shader_parameter("badge_scale", 0.65)
	material = _reveal_material
	get_viewport().size_changed.connect(_queue_layout)
	call_deferred("_start_entrance")

func _exit_tree() -> void:
	if _buttons_tween != null and _buttons_tween.is_valid():
		_buttons_tween.kill()
	if _entrance_tween != null and _entrance_tween.is_valid():
		_entrance_tween.kill()
	if get_viewport().size_changed.is_connected(_queue_layout):
		get_viewport().size_changed.disconnect(_queue_layout)

func _queue_layout() -> void:
	# Let the stage holder and its adaptive parent finish their resize first.
	call_deferred("_sync_layout")

func _sync_layout() -> void:
	if !is_inside_tree() or !is_instance_valid(logo_anchor):
		return
	# RuntimeUI is hosted by a Node2D, so its Control descendants have no
	# automatic full-viewport size. Size this layer explicitly, like stage fills.
	position = Vector2.ZERO
	size = get_viewport_rect().size
	var logo_rect: Rect2 = logo_anchor.get_global_rect()
	logo_rect.position -= get_global_rect().position
	PAPER_BACKGROUND_SCRIPT.configure_material(_reveal_material, size)
	_reveal_material.set_shader_parameter("canvas_size", size)
	_reveal_material.set_shader_parameter("logo_rect", Vector4(
		logo_rect.position.x, logo_rect.position.y, logo_rect.size.x, logo_rect.size.y
	))

func _start_entrance() -> void:
	if !is_inside_tree() or _departing:
		return
	_sync_layout()
	_entrance_tween = create_tween()
	_entrance_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_entrance_tween.tween_interval(maxf(0.0, start_delay))
	# Same fixed-content / moving-fold geometry and easing as the gameplay paper.
	var peel: MethodTweener = _entrance_tween.tween_method(
		_set_reveal_progress, 0.0, 1.0, maxf(0.01, reveal_duration / PEEL_SPEED_MULTIPLIER)
	)
	peel.set_trans(Tween.TRANS_QUAD)
	peel.set_ease(Tween.EASE_IN_OUT)
	# The separate badge is revealed only once the entire blue strip has left.
	var badge_grow: MethodTweener = _entrance_tween.tween_method(
		_set_badge_appearance, 0.0, 1.0, maxf(0.01, badge_grow_duration / BADGE_BOUNCE_SPEED)
	)
	badge_grow.set_trans(Tween.TRANS_QUAD)
	badge_grow.set_ease(Tween.EASE_OUT)
	var badge_settle: MethodTweener = _entrance_tween.tween_method(
		_set_badge_scale, 1.14, 1.0, maxf(0.01, badge_settle_duration / BADGE_BOUNCE_SPEED)
	)
	badge_settle.set_trans(Tween.TRANS_BACK)
	badge_settle.set_ease(Tween.EASE_OUT)
	# Highlight immediately at the badge edge, without traversing empty atlas space.
	var shine: MethodTweener = _entrance_tween.tween_method(
		_set_shine_progress, 0.22, 1.55, maxf(0.01, shine_duration)
	)
	shine.set_trans(Tween.TRANS_SINE)
	shine.set_ease(Tween.EASE_IN_OUT)

func _set_reveal_progress(value: float) -> void:
	_reveal_material.set_shader_parameter("reveal_progress", value)
	if value >= 0.5 and !_buttons_started:
		_start_buttons_entrance()

func _set_shine_progress(value: float) -> void:
	_reveal_material.set_shader_parameter("shine_progress", value)

func _set_badge_appearance(value: float) -> void:
	_reveal_material.set_shader_parameter("badge_alpha", value)
	_set_badge_scale(lerpf(0.65, 1.14, value))

func _set_badge_scale(value: float) -> void:
	_reveal_material.set_shader_parameter("badge_scale", value)

func _start_buttons_entrance() -> void:
	_buttons_started = true
	_buttons_tween = create_tween()
	_buttons_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var grow := _buttons_tween.tween_method(
		_set_buttons_appearance, 0.0, 1.0, maxf(0.01, badge_grow_duration / BADGE_BOUNCE_SPEED)
	)
	grow.set_trans(Tween.TRANS_QUAD)
	grow.set_ease(Tween.EASE_OUT)
	var settle := _buttons_tween.tween_method(
		_set_buttons_scale, 1.14, 1.0, maxf(0.01, badge_settle_duration / BADGE_BOUNCE_SPEED)
	)
	settle.set_trans(Tween.TRANS_BACK)
	settle.set_ease(Tween.EASE_OUT)
	_buttons_tween.tween_callback(buttons_bounce_finished.emit)

func _set_buttons_appearance(value: float) -> void:
	_buttons_opacity = value
	_set_buttons_scale(lerpf(0.65, 1.14, value))

func _set_buttons_scale(value: float) -> void:
	buttons_appearance_changed.emit(_buttons_opacity, value)

func prepare_departure() -> void:
	_departing = true
	if _entrance_tween != null and _entrance_tween.is_valid():
		_entrance_tween.kill()
	if _buttons_tween != null and _buttons_tween.is_valid():
		_buttons_tween.kill()
	_reveal_material.set_shader_parameter("reveal_progress", 1.0)
	# During departure the moving blue pieces reveal the destination directly.
	# Keep only the fading lettering/badge above that opening, without Home paper.
	_reveal_material.set_shader_parameter("foreground_only", true)
	_sync_layout()

func set_foreground_opacity(value: float) -> void:
	_reveal_material.set_shader_parameter("foreground_opacity", value)
