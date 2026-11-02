extends Control
## Decorative timing meter. The offer owns payout and advertisement handling.

const CONFIG = preload("res://scripts/core/game_design_config.gd")
const PALETTE = preload("res://scripts/ui/ui_palette.gd")
const FONTS = preload("res://scripts/ui/ui_fonts.gd")
const TEXT_STYLE = preload("res://scripts/ui/button_text_style.gd")
const FILL = preload("res://shaders/theme_unlock_fill.gdshader")
const ICON_OUTLINE = preload("res://scripts/ui/colored_icon_outline.gd")
const BAR_HEIGHT: float = 36.5 * 1.4
const TRACK_INSET_PIXELS := Vector2(6.0, 6.0)
const TRACK_BOTTOM_INSET_PIXELS: float = 9.0
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
var _border_scale := Vector2.ZERO

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
	track.bg_color = PALETTE.UI_BLUE_DARK
	track.set_corner_radius_all(26)
	frame.add_theme_stylebox_override("panel", track)
	add_child(frame)
	var fill := ColorRect.new()
	fill.position = TRACK_INSET_PIXELS
	fill.size = frame.size - Vector2(TRACK_INSET_PIXELS.x * 2.0, TRACK_INSET_PIXELS.y + TRACK_BOTTOM_INSET_PIXELS)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fill = fill
	var material_instance := ShaderMaterial.new()
	material_instance.shader = FILL
	material_instance.set_shader_parameter("fill_size", fill.size)
	material_instance.set_shader_parameter("segmented", true)
	material_instance.set_shader_parameter("base_color", PALETTE.ERROR)
	material_instance.set_shader_parameter("highlight_color", PALETTE.ERROR.lightened(0.25))
	material_instance.set_shader_parameter("middle_color", PALETTE.BUTTON_ORANGE)
	material_instance.set_shader_parameter("center_color", PALETTE.SUCCESS)
	fill.material = material_instance
	frame.add_child(fill)
	for index in range(5):
		var label := Label.new()
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.position = Vector2(TRACK_INSET_PIXELS.x + fill.size.x * float(index) / 5.0, 24)
		label.size = Vector2(fill.size.x / 5.0, BAR_HEIGHT)
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
	_sync_border_scale()
	set_cursor(CURSOR_MIN)

func _sync_border_scale() -> void:
	if !is_instance_valid(_frame):
		return
	var transform: Transform2D = get_global_transform_with_canvas()
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	# Window/SubViewport size is the actual render target; ViewportTexture's
	# reported size can itself include content stretching.
	var target_size: Vector2 = Vector2(get_viewport().get("size"))
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0 or target_size.x <= 0.0 or target_size.y <= 0.0:
		return
	var pixel_ratio: Vector2 = target_size / viewport_size
	var render_scale := Vector2(maxf((transform.x * pixel_ratio).length(), 0.001), maxf((transform.y * pixel_ratio).length(), 0.001))
	if render_scale.is_equal_approx(_border_scale):
		return
	_border_scale = render_scale
	# Draw the track in render-target pixels so all edge thicknesses stay fixed.
	_frame.scale = Vector2.ONE / render_scale
	_frame.size = Vector2(size.x, BAR_HEIGHT) * render_scale
	var track: StyleBoxFlat = _frame.get_theme_stylebox("panel")
	track.set_corner_radius_all(ceili(_frame.size.y * 0.5))
	_fill.position = TRACK_INSET_PIXELS
	_fill.size = _frame.size - Vector2(TRACK_INSET_PIXELS.x * 2.0, TRACK_INSET_PIXELS.y + TRACK_BOTTOM_INSET_PIXELS)
	_fill.material.set_shader_parameter("fill_size", _fill.size)
	var inset: float = TRACK_INSET_PIXELS.x / render_scale.x
	var content_width: float = size.x - inset * 2.0
	for index in range(_labels.size()):
		_labels[index].position.x = inset + content_width * float(index) / 5.0
		_labels[index].size.x = content_width / 5.0
		_labels[index].pivot_offset = _labels[index].size * 0.5
	_update_pointer_position()

func _update_pointer_position() -> void:
	if is_instance_valid(_pointer):
		var inset: float = TRACK_INSET_PIXELS.x / maxf(_border_scale.x, 0.001)
		_pointer.position = Vector2(inset + cursor * (size.x - inset * 2.0), 24.0 + BAR_HEIGHT) - POINTER_SIZE * 0.5

func selected_multiplier() -> float:
	return float(_multipliers[mini(int(cursor * 5.0), 4)])

func _process(delta: float) -> void:
	_sync_border_scale()
	if !running or !is_instance_valid(action) or bool(action.get("button_disabled")):
		return
	_elapsed += delta
	# Shorten the leg duration with the travel distance to retain pointer speed.
	var duration: float = CONFIG.get_float("timings.animations.stage_reward_multiplier.traverse_seconds") * (CURSOR_MAX - CURSOR_MIN)
	var pause: float = CONFIG.get_float("timings.animations.stage_reward_multiplier.endpoint_pause_seconds")
	var phase: float = fmod(_elapsed, 2.0 * (duration + pause))
	if phase < pause:
		set_cursor(CURSOR_MIN)
	elif phase < pause + duration:
		set_cursor(lerpf(CURSOR_MIN, CURSOR_MAX, (phase - pause) / duration))
	elif phase < 2.0 * pause + duration:
		set_cursor(CURSOR_MAX)
	else:
		set_cursor(lerpf(CURSOR_MAX, CURSOR_MIN, (phase - 2.0 * pause - duration) / duration))

func set_cursor(value: float) -> void:
	cursor = clampf(value, CURSOR_MIN, CURSOR_MAX)
	for index in range(_labels.size()):
		var distance: float = absf(cursor - (float(index) + 0.5) / 5.0)
		var proximity: float = clampf(1.0 - distance / 0.2, 0.0, 1.0)
		var peak: float = CONFIG.get_float("timings.animations.stage_reward_multiplier.label_peak_scale")
		_labels[index].scale = Vector2.ONE * lerpf(1.0, peak, smoothstep(0.0, 1.0, proximity))
	_update_pointer_position()
