extends Control
signal retry_requested
## The small, static visual shell drawn before the gameplay scene is requested.
const PALETTE = preload("res://scripts/ui/ui_palette.gd")
const FONTS = preload("res://scripts/ui/ui_fonts.gd")
const LAYOUT = preload("res://scripts/ui/portrait_stage_layout.gd")
const THEMES = preload("res://scripts/core/theme_asset_cache.gd")
const LOGO = preload("res://scripts/ui/startup_logo.gd")
const TRACK = preload("res://scripts/ui/theme_unlock_track.gd")
const TRACK_SHADER = preload("res://shaders/stage_reward_track.gdshader")
const VERSION = preload("res://scripts/ui/application_version.gd")
const TEXT_STYLE = preload("res://scripts/ui/button_text_style.gd")

var progress: float = 0.0
var initial_logo_language: String = "en"
var _icons: Array[Texture2D] = []
var _logo: Control
var _progress_group: Control
var _track: Panel
var _percentage: Label
var _version: Label
var _retry: Control
var _toast: Control
var _toast_anchor: Control
var _localized: bool = false

func _ready() -> void:
	name = "LoadingScreen"
	mouse_filter = Control.MOUSE_FILTER_STOP
	for theme_id: int in THEMES.MONO_ICON_PATHS:
		_icons.append(THEMES.get_icon(theme_id, true))
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(PALETTE.UI_BLUE_DARK, 0.0), Color(PALETTE.UI_BLUE_DARK, 0.7)])
	var gradient_texture := GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.fill_from = Vector2(0.5, 0.0)
	gradient_texture.fill_to = Vector2(0.5, 1.0)
	var overlay := TextureRect.new()
	overlay.name = "BackgroundGradient"
	overlay.texture = gradient_texture
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	_logo = LOGO.new()
	_logo.language = initial_logo_language
	add_child(_logo)
	_progress_group = Control.new()
	_progress_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_progress_group)
	_build_progress()
	get_viewport().size_changed.connect(_layout)
	_layout()

func _build_progress() -> void:
	var shadow := Panel.new()
	shadow.position = Vector2(0.0, 3.0)
	shadow.size = Vector2(316.0, 36.5)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shadow_style := StyleBoxFlat.new()
	shadow_style.bg_color = PALETTE.UI_BLUE_DARK.lightened(0.18)
	shadow_style.set_corner_radius_all(18)
	shadow.add_theme_stylebox_override("panel", shadow_style)
	_progress_group.add_child(shadow)
	_track = TRACK.new()
	_track.name = "LoadingTrack"
	_track.size = shadow.size
	_track.clip_contents = true
	_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var empty := StyleBoxEmpty.new()
	_track.add_theme_stylebox_override("panel", empty)
	_progress_group.add_child(_track)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("background", empty)
	bar.add_theme_stylebox_override("fill", empty)
	_progress_group.add_child(bar)
	var fill := ColorRect.new()
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill_material := ShaderMaterial.new()
	fill_material.shader = TRACK_SHADER
	fill_material.set_shader_parameter("segmented", false)
	fill_material.set_shader_parameter("track_color", PALETTE.UI_BLUE_DARK)
	fill_material.set_shader_parameter("base_color", PALETTE.BUTTON_BLUE)
	fill_material.set_shader_parameter("highlight_color", Color("#96A9FF"))
	fill.material = fill_material
	_track.add_child(fill)
	_track.configure(bar, fill)
	_percentage = _label(20)
	_percentage.name = "LoadingPercentage"
	_percentage.size = shadow.size
	_percentage.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_progress_group.add_child(_percentage)
	_version = Label.new()
	VERSION.style_label(_version)
	_version.name = "LoadingVersion"
	_version.position = Vector2(-42.0, 56.0)
	_version.size = Vector2(400.0, 30.0)
	_version.text = VERSION.text("Version:")
	_progress_group.add_child(_version)
	set_progress(progress)

func _label(font_size: int) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", FONTS.regular_font())
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color.WHITE)
	TEXT_STYLE.apply_regular_display(label)
	return label

func set_progress(value: float) -> void:
	progress = clampf(maxf(progress, value), 0.0, 1.0)
	if _track != null:
		_track.set_value_ratio(progress)
		_percentage.text = "%d%%" % int(progress * 100.0)

func apply_database_language() -> void:
	_localized = true
	if _logo.language != Database.interface_language:
		_logo.set_language(Database.interface_language)
	_version.text = VERSION.text()
	if is_instance_valid(_retry):
		_retry.configure(tr("LEADERBOARD_RETRY"), 20)

func clear_load_error() -> void:
	if is_instance_valid(_retry):
		_retry.hide()
	hide_status_toast()

func show_load_error() -> void:
	if _retry == null:
		_retry = load("res://scripts/ui/stage_long_button.gd").new()
		_retry.position = Vector2(48.0, -76.0)
		_retry.size = Vector2(220.0, 58.0)
		_progress_group.add_child(_retry)
		_retry.configure(tr("LEADERBOARD_RETRY") if _localized else "Retry", 20)
		_retry.pressed.connect(func():
			_retry.hide()
			retry_requested.emit()
		)
	_retry.show()
	_show_portrait_status_toast(tr("STARTUP_LOAD_ERROR") if _localized else "Could not load the game. Please try again.")

func _show_portrait_status_toast(message: String) -> void:
	if _toast == null:
		_toast = load("res://scripts/ui/stage_toast.gd").new()
		_toast.grow_downward = true
		var toast_layer := CanvasLayer.new()
		toast_layer.layer = 1003
		add_child(toast_layer)
		_toast_anchor = Control.new()
		_toast_anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
		toast_layer.add_child(_toast_anchor)
		_toast_anchor.add_child(_toast)
	_layout_toast()
	_toast.set_available_width(480.0)
	_toast.show_message(message, false)

func _layout_toast() -> void:
	if !is_instance_valid(_toast_anchor):
		return
	var fit: float = LAYOUT.fit_scale(size)
	_toast_anchor.scale = Vector2.ONE * fit
	_toast_anchor.position = Vector2(LAYOUT.horizontal_offset(size), LAYOUT.safe_top_inset_pixels(size) + 40.0 * fit)
	_toast_anchor.size = Vector2(480.0, 0.0)

func hide_status_toast() -> void:
	if is_instance_valid(_toast):
		_toast.hide_message()

func _layout() -> void:
	size = get_viewport_rect().size
	var fit: float = LAYOUT.fit_scale(size)
	var adaptive: float = LAYOUT.adaptive_ui_scale(size)
	var logo_scale: float = fit * adaptive
	var bounds := Vector2(506.88, 304.128)
	var texture_size: Vector2 = _logo.logo_texture.get_size()
	var logo_size: Vector2 = texture_size * minf(bounds.x / texture_size.x, bounds.y / texture_size.y) * logo_scale
	var logo_position := Vector2(size.x * 0.5, 294.864 * fit) - logo_size * 0.5
	_logo.set_geometry(size, Rect2(logo_position, logo_size), logo_scale)
	_progress_group.scale = Vector2.ONE * fit * adaptive
	var group_height: float = 86.0 * fit * adaptive
	_progress_group.position = Vector2((size.x - 316.0 * fit * adaptive) * 0.5, size.y * 0.9 - group_height * 0.5)
	_layout_toast()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), PALETTE.REWARD_HEADER)
	# Home's pattern is laid out directly in viewport units, outside stage scaling.
	var spacing: float = 218.7 * 0.92
	var icon_size := pattern_icon_size()
	var columns: int = ceili(size.x / spacing) + 2
	var rows: int = ceili(size.y / spacing) + 2
	for row: int in range(rows):
		for col: int in range(columns):
			var texture: Texture2D = _icons[(row * columns + col) % _icons.size()]
			if texture == null:
				continue
			var at := Vector2((col - 1) * spacing + (spacing * 0.5 if row % 2 == 0 else 0.0), (row - 1) * spacing)
			var alpha: float = 0.13 * pow(clampf((1.0 - at.y / size.y) / 0.3, 0.0, 1.0), 1.7)
			draw_set_transform(at + icon_size * 0.5, deg_to_rad(-18.0))
			var fitted: Vector2 = texture.get_size() * minf(icon_size.x / texture.get_width(), icon_size.y / texture.get_height())
			draw_texture_rect(texture, Rect2(-fitted * 0.5, fitted), false, Color(1.0, 1.0, 1.0, alpha))
	draw_set_transform(Vector2.ZERO)

func pattern_icon_size() -> Vector2:
	return Vector2.ONE * 133.12 * 1.10

func _exit_tree() -> void:
	if get_viewport().size_changed.is_connected(_layout):
		get_viewport().size_changed.disconnect(_layout)
