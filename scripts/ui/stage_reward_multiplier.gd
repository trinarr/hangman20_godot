extends Control

signal selection_changed
## Decorative timing meter. The offer owns payout and advertisement handling.

const CONFIG = preload("res://scripts/core/game_design_config.gd")
const PALETTE = preload("res://scripts/ui/ui_palette.gd")
const FONTS = preload("res://scripts/ui/ui_fonts.gd")
const TEXT_STYLE = preload("res://scripts/ui/button_text_style.gd")
const FILL = preload("res://shaders/stage_reward_track.gdshader")
const ICON_OUTLINE = preload("res://scripts/ui/colored_icon_outline.gd")
const BAR_HEIGHT: float = 36.5 * 1.4
const TRACK_INSET_UNITS := Vector2(2.5, 2.5)
const TRACK_BOTTOM_INSET_UNITS: float = 4.0
const CURSOR_MIN: float = 0.1
const CURSOR_MAX: float = 0.9
const POINTER_SIZE := Vector2(24.0, 24.0)
static var _pointer_texture: Texture2D

var action: Control
var cursor: float = CURSOR_MIN
var running: bool = false
var _elapsed: float = 0.0
var _labels: Array[Label] = []
var _multipliers: Array = []
var _pointer: TextureRect
var _frame: Panel
var _fill: ColorRect
var _active_zone: int = -1
var _label_tween: Tween

func build(button: Control) -> void:
	action = button
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var values: Array = CONFIG.get_array("economy.rewards.stage_ad_multipliers")
	_multipliers = [values[0], values[1], values[2], values[1], values[0]]
	# Theme-unlock progress treatment: a dark track with a heavier lower edge.
	var frame := Panel.new()
	frame.position = Vector2(0, 24)
	frame.size = Vector2(size.x, BAR_HEIGHT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame = frame
	var track := StyleBoxFlat.new()
	# The shader draws the track and its fill on one shared rectangle.
	track.bg_color = Color.TRANSPARENT
	track.set_corner_radius_all(26)
	frame.add_theme_stylebox_override("panel", track)
	add_child(frame)
	var fill := ColorRect.new()
	fill.position = Vector2.ZERO
	fill.size = frame.size
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fill = fill
	var material_instance := ShaderMaterial.new()
	material_instance.shader = FILL
	material_instance.set_shader_parameter("fill_size", fill.size)
	material_instance.set_shader_parameter("inset", TRACK_INSET_UNITS)
	material_instance.set_shader_parameter("bottom_inset", TRACK_BOTTOM_INSET_UNITS)
	material_instance.set_shader_parameter("track_color", PALETTE.UI_BLUE_DARK)
	material_instance.set_shader_parameter("base_color", PALETTE.ERROR)
	material_instance.set_shader_parameter("middle_color", PALETTE.BUTTON_ORANGE)
	material_instance.set_shader_parameter("center_color", PALETTE.SUCCESS)
	fill.material = material_instance
	frame.add_child(fill)
	var content_width: float = frame.size.x - TRACK_INSET_UNITS.x * 2.0
	for index in range(5):
		var label := Label.new()
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.position = Vector2(TRACK_INSET_UNITS.x + content_width * float(index) / 5.0, 24)
		label.size = Vector2(content_width / 5.0, BAR_HEIGHT)
		label.pivot_offset = label.size * 0.5
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_override("font", FONTS.heavy_display_font())
		label.add_theme_font_size_override("font_size", 24)
		label.text = "x%s" % str(_multipliers[index]).trim_suffix(".0")
		TEXT_STYLE.apply_display(label)
		add_child(label)
		_labels.append(label)
	# Draw above the plaque so its lower edge bisects the pointer's height.
	_pointer = TextureRect.new()
	_pointer.name = "Pointer"
	_pointer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pointer.size = POINTER_SIZE
	_pointer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_pointer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if _pointer_texture == null:
		# A code-native vector pointer, rasterized once with rounded corners.
		var svg: String = '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path fill="#ffffff" d="M10.2 3.8 Q12 .7 13.8 3.8 L22 19.2 Q23.4 21.75 20.5 21.75 H3.5 Q.6 21.75 2 19.2 Z"/></svg>'
		var image := Image.new()
		if image.load_svg_from_string(svg, 4.0) == OK:
			_pointer_texture = ImageTexture.create_from_image(image)
	_pointer.texture = _pointer_texture
	_pointer.material = ICON_OUTLINE.material(ICON_OUTLINE.CHAIN_PIXELS)
	add_child(_pointer)
	resized.connect(_sync_layout)
	_sync_layout()
	set_cursor(CURSOR_MIN)

func _sync_layout() -> void:
	if !is_instance_valid(_frame):
		return
	_frame.size = Vector2(size.x, BAR_HEIGHT)
	_fill.position = Vector2.ZERO
	_fill.size = _frame.size
	_fill.material.set_shader_parameter("fill_size", _fill.size)
	var content_width: float = _frame.size.x - TRACK_INSET_UNITS.x * 2.0
	for index in range(_labels.size()):
		_labels[index].position.x = TRACK_INSET_UNITS.x + content_width * float(index) / 5.0
		_labels[index].size.x = content_width / 5.0
		_labels[index].pivot_offset = _labels[index].size * 0.5
	_update_pointer_position()

func _update_pointer_position() -> void:
	if is_instance_valid(_pointer):
		var inset: float = TRACK_INSET_UNITS.x
		_pointer.position = Vector2(inset + cursor * (size.x - inset * 2.0), 24.0 + BAR_HEIGHT) - POINTER_SIZE * 0.5

func selected_multiplier() -> float:
	return float(_multipliers[mini(int(cursor * 5.0), 4)])

func _process(delta: float) -> void:
	if !running or !is_instance_valid(action) or bool(action.get("button_disabled")):
		return
	_elapsed += delta
	# A longer braking phase starts before the midpoint and eases into the edge.
	var duration: float = CONFIG.get_float("timings.animations.stage_reward_multiplier.traverse_seconds") * (CURSOR_MAX - CURSOR_MIN)
	var pause: float = CONFIG.get_float("timings.animations.stage_reward_multiplier.endpoint_pause_seconds")
	var phase: float = fmod(_elapsed, 2.0 * (duration + pause))
	if phase < pause:
		set_cursor(CURSOR_MIN)
	elif phase < pause + duration:
		set_cursor(lerpf(CURSOR_MIN, CURSOR_MAX, _travel_progress((phase - pause) / duration)))
	elif phase < 2.0 * pause + duration:
		set_cursor(CURSOR_MAX)
	else:
		set_cursor(lerpf(CURSOR_MAX, CURSOR_MIN, _travel_progress((phase - 2.0 * pause - duration) / duration)))

func _travel_progress(progress: float) -> float:
	var acceleration: float = CONFIG.get_float("timings.animations.stage_reward_multiplier.acceleration_fraction")
	if progress < acceleration:
		return progress * progress * progress / (acceleration * acceleration)
	var remaining: float = 1.0 - progress
	var braking: float = 1.0 - acceleration
	return 1.0 - remaining * remaining * remaining / (braking * braking)

func set_cursor(value: float) -> void:
	cursor = clampf(value, CURSOR_MIN, CURSOR_MAX)
	var zone: int = mini(int(cursor * 5.0), 4)
	if zone != _active_zone:
		_active_zone = zone
		selection_changed.emit()
		if _label_tween != null:
			_label_tween.kill()
		_label_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		var peak: float = CONFIG.get_float("timings.animations.stage_reward_multiplier.label_peak_scale")
		var duration: float = CONFIG.get_float("timings.animations.stage_reward_multiplier.label_transition_seconds")
		for index in range(_labels.size()):
			_label_tween.tween_property(_labels[index], "scale", Vector2.ONE * (peak if index == zone else 1.0), duration)
	_update_pointer_position()

func _exit_tree() -> void:
	if _label_tween != null:
		_label_tween.kill()
	_active_zone = -1
