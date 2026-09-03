class_name DisplayTextEffect
extends Control

const DISPLAY_TEXT_SHADER: Shader = preload("res://shaders/display_text_outline_shadow.gdshader")

# The outline scales with the display font instead of using one fixed value.
# 28 px button text resolves to ~8 px, matching the current authored treatment.
const OUTLINE_SIZE_RATIO: float = 0.285
const OUTLINE_SIZE_MIN: float = 3.0
const OUTLINE_SIZE_MAX: float = 14.0

# Build a compact lower extrusion from several connected text silhouettes.
const SHADOW_DEPTH_RATIO: float = 0.145
const SHADOW_DEPTH_MIN: float = 2.0
const SHADOW_DEPTH_MAX: float = 8.0
const SHADOW_SPREAD_FROM_OUTLINE: float = 0.82
const SHADOW_LAYER_COUNT: int = 6
const EFFECT_MARGIN_EXTRA: float = 4.0
const EFFECT_NODE_NAME: StringName = &"DisplayTextShaderEffect"

var _target: Control = null
var _main_label: Label = null
var _shadow_labels: Array[Label] = []
var _shadow_material: ShaderMaterial = null
var _outline_color: Color = Color.WHITE
var _shadow_color: Color = Color.BLACK
var _effect_margin: float = 0.0
var _outline_size: int = 0
var _shadow_spread: int = 0
var _shadow_depth: float = 0.0

static func attach(target: Control, outline_color: Color, shadow_color: Color) -> void:
	if target == null or !is_instance_valid(target):
		return
	var existing: Node = target.get_node_or_null(NodePath(String(EFFECT_NODE_NAME)))
	var effect: DisplayTextEffect = existing as DisplayTextEffect
	if effect == null:
		effect = DisplayTextEffect.new()
		effect.name = EFFECT_NODE_NAME
		target.add_child(effect)
	effect.configure(target, outline_color, shadow_color)

func configure(target: Control, outline_color: Color, shadow_color: Color) -> void:
	_target = target
	_outline_color = outline_color
	_shadow_color = shadow_color
	if !_target.resized.is_connected(_sync_all):
		_target.resized.connect(_sync_all)
	_ensure_nodes()
	_sync_all()
	if is_inside_tree():
		call_deferred("_sync_all")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	show_behind_parent = false
	z_index = 1
	set_process(true)
	_ensure_nodes()
	_sync_all()

func _process(_delta: float) -> void:
	if _target == null or !is_instance_valid(_target):
		queue_free()
		return
	if _main_label == null or !is_instance_valid(_main_label):
		_sync_all()
		return

	var expected_text: String = _target_text()
	var expected_font_size: int = _target.get_theme_font_size("font_size")
	var expected_font: Font = _target.get_theme_font("font")
	var expected_color: Color = _target_font_color()
	if (
		_main_label.text != expected_text
		or _main_label.get_theme_font_size("font_size") != expected_font_size
		or _main_label.get_theme_font("font") != expected_font
		or _main_label.get_theme_color("font_color") != expected_color
	):
		_sync_all()

func _ensure_nodes() -> void:
	if _shadow_material == null:
		_shadow_material = ShaderMaterial.new()
		_shadow_material.shader = DISPLAY_TEXT_SHADER

	while _shadow_labels.size() < SHADOW_LAYER_COUNT:
		var shadow_label := Label.new()
		shadow_label.name = "Extrusion%02d" % (_shadow_labels.size() + 1)
		shadow_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shadow_label.z_index = 0
		shadow_label.material = _shadow_material
		shadow_label.add_theme_color_override("font_color", Color.WHITE)
		shadow_label.add_theme_color_override("font_outline_color", Color.WHITE)
		shadow_label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
		shadow_label.add_theme_constant_override("shadow_offset_x", 0)
		shadow_label.add_theme_constant_override("shadow_offset_y", 0)
		shadow_label.add_theme_constant_override("shadow_outline_size", 0)
		add_child(shadow_label)
		_shadow_labels.append(shadow_label)

	if _main_label == null or !is_instance_valid(_main_label):
		_main_label = Label.new()
		_main_label.name = "DisplayTextFront"
		_main_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_main_label.z_index = 1
		_main_label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
		_main_label.add_theme_constant_override("shadow_offset_x", 0)
		_main_label.add_theme_constant_override("shadow_offset_y", 0)
		_main_label.add_theme_constant_override("shadow_outline_size", 0)
		add_child(_main_label)

func _sync_all() -> void:
	_sync_effect_metrics()
	_sync_from_target()

func _target_text() -> String:
	if _target is Label:
		return (_target as Label).text
	if _target is Button:
		return (_target as Button).text
	return ""

func _target_font_color() -> Color:
	if _target == null or !is_instance_valid(_target):
		return Color.WHITE
	if _target is Button:
		var button := _target as Button
		if button.disabled:
			return button.get_theme_color("font_disabled_color")
	return _target.get_theme_color("font_color")

func _copy_text_layout(source: Control, destination: Label) -> void:
	destination.add_theme_font_override("font", source.get_theme_font("font"))
	destination.add_theme_font_size_override("font_size", source.get_theme_font_size("font_size"))
	if source is Label:
		var label_source := source as Label
		destination.text = label_source.text
		destination.horizontal_alignment = label_source.horizontal_alignment
		destination.vertical_alignment = label_source.vertical_alignment
		destination.autowrap_mode = label_source.autowrap_mode
		destination.text_overrun_behavior = label_source.text_overrun_behavior
		destination.clip_text = label_source.clip_text
		destination.max_lines_visible = label_source.max_lines_visible
		destination.lines_skipped = label_source.lines_skipped
		destination.text_direction = label_source.text_direction
		destination.language = label_source.language
	elif source is Button:
		var button_source := source as Button
		destination.text = button_source.text
		destination.horizontal_alignment = button_source.alignment
		destination.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		destination.autowrap_mode = TextServer.AUTOWRAP_OFF
		destination.clip_text = button_source.clip_text
		destination.text_direction = button_source.text_direction
		destination.language = button_source.language
	else:
		destination.text = ""

func _sync_from_target() -> void:
	if _target == null or !is_instance_valid(_target):
		return
	_ensure_nodes()

	_shadow_material.set_shader_parameter("shadow_color", _shadow_color)
	var base_position := Vector2.ONE * _effect_margin
	for index: int in range(_shadow_labels.size()):
		var shadow_label: Label = _shadow_labels[index]
		_copy_text_layout(_target, shadow_label)
		var layer_t: float = float(index + 1) / float(maxi(SHADOW_LAYER_COUNT, 1))
		shadow_label.position = base_position + Vector2(0.0, _shadow_depth * layer_t)
		shadow_label.size = _target.size
		shadow_label.custom_minimum_size = Vector2.ZERO
		shadow_label.add_theme_constant_override("outline_size", _shadow_spread)

	_copy_text_layout(_target, _main_label)
	_main_label.position = base_position
	_main_label.size = _target.size
	_main_label.custom_minimum_size = Vector2.ZERO
	_main_label.add_theme_color_override("font_color", _target_font_color())
	_main_label.add_theme_color_override("font_outline_color", _outline_color)
	_main_label.add_theme_constant_override("outline_size", _outline_size)

func _sync_effect_metrics() -> void:
	if _target == null or !is_instance_valid(_target):
		return
	_ensure_nodes()
	var font_size: float = float(maxi(_target.get_theme_font_size("font_size"), 1))
	var outline_local: float = clampf(
		font_size * OUTLINE_SIZE_RATIO,
		OUTLINE_SIZE_MIN,
		OUTLINE_SIZE_MAX
	)
	_shadow_depth = clampf(
		font_size * SHADOW_DEPTH_RATIO,
		SHADOW_DEPTH_MIN,
		SHADOW_DEPTH_MAX
	)
	_outline_size = maxi(1, int(round(outline_local)))
	_shadow_spread = maxi(1, int(round(outline_local * SHADOW_SPREAD_FROM_OUTLINE)))
	_effect_margin = ceil(float(_outline_size) + _shadow_depth + EFFECT_MARGIN_EXTRA)

	position = -Vector2.ONE * _effect_margin
	size = Vector2(
		maxf(_target.size.x + _effect_margin * 2.0, 2.0),
		maxf(_target.size.y + _effect_margin * 2.0, 2.0)
	)
	custom_minimum_size = Vector2.ZERO
