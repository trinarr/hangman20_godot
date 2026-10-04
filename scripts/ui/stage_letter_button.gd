class_name StageLetterButton
extends "res://scripts/ui/flash_stage_texture_button.gd"

signal marker_reveal_started(is_correct: bool)

const KEYBOARD_FONT: Font = preload("res://fonts/BalsamiqSans-Bold.ttf")

const UI_PALETTE: GDScript = preload("res://scripts/ui/ui_palette.gd")

enum LetterState {
	NORMAL,
	CROSSED,
	CIRCLED
}

const CORRECT_MARKER_TEXTURE: Texture2D = preload("res://img/_______435______2_0_SHAPE_0_BOUNDS_-1.96_-1.96_SIZE_211_211.png")
const WRONG_MARKER_TEXTURE: Texture2D = preload("res://img/_______430______1_0_SHAPE_0_BOUNDS_3.99_8.74_SIZE_186_177.png")
const MARKER_REVEAL_SHADER: Shader = preload("res://shaders/letter_marker_reveal.gdshader")
const MARKER_REVEAL_DURATION: float = 0.2
const WRONG_LETTER_FEEDBACK_SPEED: float = 1.5
const LETTER_PRESSED_SCALE := Vector2(0.90, 0.90)
const LETTER_MARK_BOUNCE_SCALE := Vector2(1.32, 1.32)
const LETTER_MARK_BOUNCE_GROW_DURATION: float = 0.18
const LETTER_MARK_BOUNCE_SETTLE_DURATION: float = 0.25

const NORMAL_COLOR := UI_PALETTE.UI_BLUE
const CROSSED_COLOR := UI_PALETTE.ERROR
const CIRCLED_COLOR := UI_PALETTE.SUCCESS

var letter_text: String = ""
var letter_state: int = LetterState.NORMAL
var letter_font_size: int = 29
var marker_stage_size: Vector2 = Vector2(44.0, 44.0)
var marker_stage_offset: Vector2 = Vector2(0.0, -1.0)
var label_stage_offset: Vector2 = Vector2(-5.0, -7.0)
var label_stage_padding: Vector2 = Vector2(10.0, 12.0)
var animate_marker: bool = false

var _label: Label = null
var _button_text_font: Font = KEYBOARD_FONT
var _marker: TextureRect = null
var _marker_tween: Tween = null
var _letter_bounce_tween: Tween = null
var _marker_animation_pending: bool = false
var _marker_feedback_active: bool = false
var _marker_reveal_has_started: bool = false
var _marker_animation_generation: int = 0

func _ready() -> void:
	press_scale_enabled = true
	pressed_scale = LETTER_PRESSED_SCALE
	disabled_overlay_alpha = 0.0
	_ensure_visual_nodes()
	if !resized.is_connected(_sync_layout):
		resized.connect(_sync_layout)
	super._ready()
	_sync_visuals()
	_sync_layout()
	if _marker_animation_pending:
		call_deferred("_start_marker_reveal")

func _exit_tree() -> void:
	if _marker_tween != null and _marker_tween.is_valid():
		_marker_tween.kill()
	if _letter_bounce_tween != null and _letter_bounce_tween.is_valid():
		_letter_bounce_tween.kill()
	super._exit_tree()

func configure(
	letter_value: String,
	state_value: int = LetterState.NORMAL,
	font_size_value: int = 29,
	marker_size_value: Vector2 = Vector2(44.0, 44.0),
	disabled_value: bool = false,
	animate_marker_value: bool = false
) -> void:
	var keep_feedback: bool = (
		_marker_feedback_active
		and !animate_marker_value
		and letter_text == letter_value.to_upper()
		and letter_state == clampi(state_value, LetterState.NORMAL, LetterState.CIRCLED)
	)
	var feedback_scale: Vector2 = _label.scale if is_instance_valid(_label) else Vector2.ONE
	if !keep_feedback:
		_marker_animation_generation += 1
		_marker_reveal_has_started = false
		if _marker_tween != null and _marker_tween.is_valid():
			_marker_tween.kill()
		if _letter_bounce_tween != null and _letter_bounce_tween.is_valid():
			_letter_bounce_tween.kill()
		if is_instance_valid(_label):
			_label.scale = Vector2.ONE
	letter_text = letter_value.to_upper()
	letter_state = clampi(state_value, LetterState.NORMAL, LetterState.CIRCLED)
	letter_font_size = font_size_value
	marker_stage_size = marker_size_value
	if !keep_feedback:
		animate_marker = animate_marker_value and letter_state != LetterState.NORMAL
		_marker_animation_pending = animate_marker
		_marker_feedback_active = animate_marker
	disabled = disabled_value
	# Initial configuration is applied once in _ready(), with final geometry.
	if !is_inside_tree():
		return
	_ensure_visual_nodes()
	_sync_visuals()
	_sync_layout()
	if keep_feedback:
		_label.scale = feedback_scale
	if is_inside_tree() and _marker_animation_pending:
		call_deferred("_start_marker_reveal")

func _ensure_visual_nodes() -> void:
	if _marker == null or !is_instance_valid(_marker):
		_marker = TextureRect.new()
		_marker.name = "Marker"
		_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_marker.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_marker.stretch_mode = TextureRect.STRETCH_SCALE
		add_child(_marker)
	if _label == null or !is_instance_valid(_label):
		_label = Label.new()
		_label.name = "Text"
		_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_label.clip_text = false
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_child(_label)

func _sync_visuals() -> void:
	if _marker == null or _label == null:
		return
	_label.begin_bulk_theme_override()
	_label.add_theme_font_override("font", _button_text_font)
	_label.add_theme_font_size_override("font_size", letter_font_size)
	_label.add_theme_color_override("font_color", _letter_color())
	# Gameplay keyboard letters stay clean and flat: no outline or shadow.
	_label.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
	_label.add_theme_constant_override("outline_size", 0)
	_label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	_label.add_theme_constant_override("shadow_offset_x", 0)
	_label.add_theme_constant_override("shadow_offset_y", 0)
	_label.add_theme_constant_override("shadow_outline_size", 0)
	_label.end_bulk_theme_override()
	_label.text = letter_text

	# Wrong-letter strokes overlay the glyph, including during its bounce.
	_marker.z_index = 1 if letter_state == LetterState.CROSSED else 0
	var cross_waiting_for_growth: bool = (
		animate_marker and letter_state == LetterState.CROSSED
		and !_marker_reveal_has_started
	)
	_marker.visible = letter_state != LetterState.NORMAL and !cross_waiting_for_growth
	_marker.texture = _marker_texture()
	if !animate_marker:
		_marker.material = null

func _sync_layout() -> void:
	if _marker == null or _label == null:
		return
	if stage_rect.size.x <= 0.0 or stage_rect.size.y <= 0.0:
		return
	var scale_to_view := Vector2(size.x / stage_rect.size.x, size.y / stage_rect.size.y)
	var marker_size := marker_stage_size * scale_to_view
	var marker_offset := marker_stage_offset * scale_to_view
	_marker.position = size * 0.5 + marker_offset - marker_size * 0.5
	_marker.size = marker_size
	_label.position = label_stage_offset * scale_to_view
	_label.size = (stage_rect.size + label_stage_padding) * scale_to_view
	_sync_visual_child_scales()

func _letter_color() -> Color:
	match letter_state:
		LetterState.CROSSED:
			return CROSSED_COLOR
		LetterState.CIRCLED:
			return CIRCLED_COLOR
		_:
			return NORMAL_COLOR

func _marker_texture() -> Texture2D:
	match letter_state:
		LetterState.CROSSED:
			return WRONG_MARKER_TEXTURE
		LetterState.CIRCLED:
			return CORRECT_MARKER_TEXTURE
		_:
			return null

func _start_marker_reveal() -> void:
	if !_marker_animation_pending:
		return
	_marker_animation_pending = false
	if !is_inside_tree() or _marker == null or letter_state == LetterState.NORMAL:
		return
	var generation: int = _marker_animation_generation
	if letter_state == LetterState.CROSSED:
		_marker.visible = false
		_play_letter_mark_bounce()
	else:
		_begin_marker_reveal(generation)
		_play_letter_mark_bounce()
	_letter_bounce_tween.finished.connect(
		_finish_marker_feedback.bind(generation), CONNECT_ONE_SHOT
	)

func _begin_marker_reveal(generation: int) -> void:
	if generation != _marker_animation_generation or !is_inside_tree() or !animate_marker:
		return
	if _marker == null or letter_state == LetterState.NORMAL:
		return
	if _marker_tween != null and _marker_tween.is_valid():
		_marker_tween.kill()
	var reveal_material := ShaderMaterial.new()
	reveal_material.shader = MARKER_REVEAL_SHADER
	reveal_material.set_shader_parameter("progress", 0.0)
	reveal_material.set_shader_parameter("reveal_mode", 0 if letter_state == LetterState.CIRCLED else 1)
	_marker.material = reveal_material
	_marker_reveal_has_started = true
	_marker.visible = true
	_marker_tween = create_tween()
	_marker_tween.set_trans(Tween.TRANS_LINEAR)
	_marker_tween.set_ease(Tween.EASE_IN_OUT)
	var feedback_speed: float = WRONG_LETTER_FEEDBACK_SPEED if letter_state == LetterState.CROSSED else 1.0
	_marker_tween.tween_method(_set_marker_reveal_progress.bind(reveal_material), 0.0, 1.0, MARKER_REVEAL_DURATION / feedback_speed)
	_marker_tween.finished.connect(_finish_marker_feedback.bind(generation), CONNECT_ONE_SHOT)
	marker_reveal_started.emit(letter_state == LetterState.CIRCLED)

func _finish_marker_feedback(generation: int) -> void:
	if generation != _marker_animation_generation:
		return
	if _letter_bounce_tween != null and _letter_bounce_tween.is_running():
		return
	if _marker_tween != null and _marker_tween.is_running():
		return
	_marker_feedback_active = false

func _play_letter_mark_bounce() -> void:
	if _label == null or !is_instance_valid(_label):
		return
	if _letter_bounce_tween != null and _letter_bounce_tween.is_valid():
		_letter_bounce_tween.kill()

	var feedback_speed: float = WRONG_LETTER_FEEDBACK_SPEED if letter_state == LetterState.CROSSED else 1.0
	# Keep the marked letter centered during its bounce.
	_label.pivot_offset = size * 0.5 - _label.position
	_label.scale = Vector2.ONE
	_letter_bounce_tween = create_tween()
	_letter_bounce_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var grow_tweener: PropertyTweener = _letter_bounce_tween.tween_property(
		_label,
		"scale",
		LETTER_MARK_BOUNCE_SCALE,
		LETTER_MARK_BOUNCE_GROW_DURATION / feedback_speed
	)
	grow_tweener.set_trans(Tween.TRANS_QUAD)
	grow_tweener.set_ease(Tween.EASE_OUT)
	if letter_state == LetterState.CROSSED:
		# Reveal and its sound start at the peak, as the glyph starts shrinking.
		_letter_bounce_tween.tween_callback(
			_begin_marker_reveal.bind(_marker_animation_generation)
		)
	var settle_tweener: PropertyTweener = _letter_bounce_tween.tween_property(
		_label,
		"scale",
		Vector2.ONE,
		LETTER_MARK_BOUNCE_SETTLE_DURATION / feedback_speed
	)
	settle_tweener.set_trans(Tween.TRANS_BACK)
	settle_tweener.set_ease(Tween.EASE_OUT)

func _set_marker_reveal_progress(value: float, reveal_material: ShaderMaterial) -> void:
	if is_instance_valid(reveal_material):
		reveal_material.set_shader_parameter("progress", value)
