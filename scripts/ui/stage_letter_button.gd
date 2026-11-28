class_name StageLetterButton
extends "res://scripts/ui/flash_stage_texture_button.gd"

signal feedback_started(is_correct: bool)

const UI_FONTS = preload("res://scripts/ui/ui_fonts.gd")
const UI_PALETTE = preload("res://scripts/ui/ui_palette.gd")
const CARD_STYLE = preload("res://scripts/ui/quiz_answer_card_style.gd")
const FADE = preload("res://scripts/ui/composited_fade.gd")

enum LetterState {
	NORMAL,
	WRONG,
	CORRECT,
	PARTIAL,
}

const USED_OPACITY: float = 0.48
const DEFAULT_FONT_SIZE: int = 27
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
var letter_font_size: int = DEFAULT_FONT_SIZE
var remaining_count: int = 0

var _key_visual: FADE
var _face: Panel
var _label: Label
var _count_label: Label
var _letter_bounce_tween: Tween
var _feedback_pending: bool = false
var _feedback_correct: bool = false

func _ready() -> void:
	press_scale_enabled = true
	pressed_scale = LETTER_PRESSED_SCALE
	disabled_overlay_alpha = 0.0
	_build_key_visual()
	resized.connect(_sync_layout)
	super._ready()
	_sync_visuals()
	_sync_layout()
	if _feedback_pending:
		_start_feedback.call_deferred()

func _exit_tree() -> void:
	_feedback_pending = false
	if _letter_bounce_tween != null and _letter_bounce_tween.is_valid():
		_letter_bounce_tween.kill()
	super._exit_tree()

func configure(
	letter_value: String,
	state_value: int = LetterState.NORMAL,
	font_size_value: int = DEFAULT_FONT_SIZE,
	disabled_value: bool = false,
	animate_feedback: bool = false,
	count_value: int = 0,
	misplaced_feedback: bool = false
) -> void:
	var next_letter: String = letter_value.to_upper()
	var keep_feedback: bool = (
		!animate_feedback and letter_text == next_letter and letter_state == state_value and remaining_count == count_value
		and (_feedback_pending or (_letter_bounce_tween != null and _letter_bounce_tween.is_valid()))
	)
	if !keep_feedback:
		if _letter_bounce_tween != null and _letter_bounce_tween.is_valid():
			_letter_bounce_tween.kill()
		_feedback_pending = animate_feedback and state_value != LetterState.NORMAL
		_feedback_correct = !misplaced_feedback and state_value in [LetterState.CORRECT, LetterState.PARTIAL]
		if is_instance_valid(_label):
			_label.scale = Vector2.ONE
	letter_text = next_letter
	letter_state = state_value
	letter_font_size = font_size_value
	remaining_count = count_value
	disabled = disabled_value
	if !is_inside_tree():
		return
	if !keep_feedback:
		_sync_visuals()
	if _feedback_pending:
		_start_feedback.call_deferred()

func _build_key_visual() -> void:
	_key_visual = FADE.new()
	_key_visual.name = "KeyVisual"
	add_child(_key_visual)

	var style := CARD_STYLE.face_style()
	style.set_corner_radius_all(PORTRAIT_LAYOUT.CROSSWORD_CELL_CORNER_RADIUS)
	_face = Panel.new()
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_face.add_theme_stylebox_override("panel", style)
	_key_visual.add_visual(_face)

	_label = Label.new()
	_label.name = "Text"
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_override("font", UI_FONTS.keyboard_font())
	_key_visual.add_visual(_label)

	_count_label = Label.new()
	_count_label.name = "RemainingCount"
	_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_count_label.add_theme_font_override("font", UI_FONTS.keyboard_font())
	_count_label.add_theme_color_override("font_color", UI_PALETTE.MARKER_ORANGE_TEXT)
	_key_visual.add_visual(_count_label)

func _sync_visuals() -> void:
	_label.text = letter_text
	_label.add_theme_font_size_override("font_size", letter_font_size)
	_count_label.add_theme_font_size_override("font_size", maxi(8, roundi(letter_font_size * 0.38)))
	_count_label.text = str(remaining_count) if remaining_count > 0 else ""
	_sync_key_mark(_feedback_pending)
	_key_visual.opacity = 1.0 if _feedback_pending else _rest_opacity()

func _sync_key_mark(show_feedback: bool = false) -> void:
	var glyph_color: Color = UI_PALETTE.DISABLED
	match letter_state:
		LetterState.NORMAL:
			glyph_color = UI_PALETTE.TEXT_DARK
		LetterState.PARTIAL:
			glyph_color = UI_PALETTE.MARKER_ORANGE_TEXT
	if show_feedback:
		if _feedback_correct:
			glyph_color = UI_PALETTE.SUCCESS_BORDER
		elif letter_state == LetterState.WRONG:
			glyph_color = UI_PALETTE.ERROR
	_label.add_theme_color_override("font_color", glyph_color)
	_count_label.visible = remaining_count > 0 and !(show_feedback and _feedback_correct)

func _rest_opacity() -> float:
	return 1.0 if letter_state in [LetterState.NORMAL, LetterState.PARTIAL] else USED_OPACITY

func _sync_layout() -> void:
	_key_visual.size = size
	_face.size = size
	_label.size = size
	_label.pivot_offset = size * 0.5
	_count_label.position = size * Vector2(0.10, 0.70)
	_count_label.size = size * Vector2(0.8, 0.27)
	_sync_visual_child_scales()

func feedback_bounce_time_left() -> float:
	var duration: float = (LETTER_MARK_BOUNCE_GROW_DURATION + LETTER_MARK_BOUNCE_SETTLE_DURATION) / _feedback_speed()
	if _feedback_pending:
		return duration
	if _letter_bounce_tween != null and _letter_bounce_tween.is_valid():
		return maxf(0.0, duration - _letter_bounce_tween.get_total_elapsed_time())
	return 0.0

func _feedback_speed() -> float:
	return 1.0 if _feedback_correct else WRONG_LETTER_FEEDBACK_SPEED

func _start_feedback() -> void:
	if !_feedback_pending or !is_inside_tree():
		return
	_feedback_pending = false
	var speed: float = _feedback_speed()
	var grow_duration: float = LETTER_MARK_BOUNCE_GROW_DURATION / speed
	var settle_duration: float = LETTER_MARK_BOUNCE_SETTLE_DURATION / speed
	_letter_bounce_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_letter_bounce_tween.tween_property(_label, "scale", LETTER_MARK_BOUNCE_SCALE, grow_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if !_feedback_correct:
		# Keep the wrong-answer sound at the peak of the bounce.
		_letter_bounce_tween.tween_callback(feedback_started.emit.bind(false))
	var rest_opacity: float = _rest_opacity()
	if rest_opacity < 1.0:
		_letter_bounce_tween.tween_callback(_sync_key_mark)
	_letter_bounce_tween.tween_property(_label, "scale", Vector2.ONE, settle_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if rest_opacity < 1.0:
		_letter_bounce_tween.parallel().tween_property(_key_visual, "opacity", rest_opacity, settle_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	elif _feedback_correct:
		_letter_bounce_tween.tween_callback(_sync_key_mark)
	if _feedback_correct:
		feedback_started.emit(true)
