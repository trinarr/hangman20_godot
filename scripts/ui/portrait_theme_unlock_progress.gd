extends Node
## Presents a supplied unlock snapshot without changing durable theme progress.
const PORTRAIT_ICON_EXTRUSION = preload("res://scripts/ui/portrait_icon_extrusion.gd")

const BUTTON_TEXT_STYLE_SCRIPT: GDScript = preload("res://scripts/ui/button_text_style.gd")
const UI_FONTS: GDScript = preload("res://scripts/ui/ui_fonts.gd")
var UI_DISPLAY_FONT: Font = UI_FONTS.display_font()
var UI_REGULAR_FONT: Font = UI_FONTS.regular_font()
const RESOURCE_COUNTER_STYLE = preload("res://scripts/ui/resource_counter_style.gd")
const COMPOSITED_FADE = preload("res://scripts/ui/composited_fade.gd")
const PORTRAIT_GAME_DESIGN: GDScript = preload("res://scripts/core/game_design_config.gd")
const PORTRAIT_UI_PALETTE: GDScript = preload("res://scripts/ui/ui_palette.gd")
const BADGE_SHADOW_STYLE_SCRIPT: GDScript = preload("res://scripts/ui/badge_shadow_style.gd")
const UI_MATERIALS: GDScript = preload("res://scripts/ui/ui_materials.gd")
const FINAL_REWARD_ROTATING_GLOW_TEXTURE: Texture2D = preload(
	"res://flash_assets/final_reward_rotating_glow.png"
)
const THEME_UNLOCK_ICON_GRAYSCALE_SHADER: Shader = preload("res://shaders/theme_unlock_icon_grayscale.gdshader")
const THEME_UNLOCK_FILL_SHADER: Shader = preload("res://shaders/stage_reward_track.gdshader")
const THEME_UNLOCK_TRACK = preload("res://scripts/ui/theme_unlock_track.gd")
var PORTRAIT_FINAL_REWARD_GLOW_ROTATION_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.final_reward.glow_rotation_seconds"
)
const PORTRAIT_DARK_BLUE := PORTRAIT_UI_PALETTE.UI_BLUE_DARK
func _create_theme_unlock_progress(parent: Control, rect: Rect2, progress: Dictionary, theme_icon_texture: Texture2D) -> Control:
	if progress.is_empty():
		return null
	var holder := Control.new()
	holder.name = "ThemeUnlockProgress"
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.position = rect.position
	holder.size = rect.size
	parent.add_child(holder)
	# Keep this reward as a lightweight progress element without an extra card
	# surface. On the merged reward screen it occupies the dedicated top slot.
	var bar_width: float = (rect.size.x - 102.0) * 0.70 * 1.15
	var bar_x: float = (rect.size.x - bar_width) * 0.5
	var title := Label.new()
	title.name = "UnlockTitle"
	# Sit close to the bar and share its exact horizontal center.
	var title_height: float = 26.0
	title.position = Vector2(bar_x, 0.0)
	title.size = Vector2(bar_width, title_height)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var title_text: String = tr("NEXT_THEME_UNLOCK").to_lower()
	title.text = title_text.left(1).to_upper() + title_text.substr(1)
	title.add_theme_font_override("font", UI_REGULAR_FONT)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color.WHITE)
	BUTTON_TEXT_STYLE_SCRIPT.apply_regular_display(title)
	title.z_index = 2
	holder.add_child(title)
	# Draw the track and fill on one rectangle, with shader-local logical insets.
	var bar_frame := THEME_UNLOCK_TRACK.new()
	bar_frame.name = "UnlockBarFrame"
	# Rim in logical stage units: 1.5 on top/sides and 3.5 below.
	bar_frame.position = Vector2(bar_x, title_height + THEME_UNLOCK_TRACK.CAPTION_GAP_UNITS)
	bar_frame.size = Vector2(bar_width, 36.5)
	bar_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_frame.clip_contents = true
	# Reuse the rounded-badge shader extrusion for the complete progress plaque.
	# Keep it in a dedicated holder so the shadow can extend outside the clipped
	# bar frame while following exactly the same rounded geometry.
	var bar_shadow_holder := Control.new()
	bar_shadow_holder.name = "UnlockBarShadow"
	bar_shadow_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_shadow_holder.position = bar_frame.position
	bar_shadow_holder.size = bar_frame.size
	bar_shadow_holder.z_index = 1
	holder.add_child(bar_shadow_holder)
	var bar_shadow_layers := _create_portrait_rounded_panel_extrusion_layers(
		bar_shadow_holder,
		"UnlockBarShadow",
		0
	)
	_layout_portrait_rounded_panel_extrusion_layers(
		bar_shadow_layers,
		bar_frame.size,
		bar_frame.size.y * 0.5
	)
	# This plaque uses a lighter extrusion; do not change other badge shadows.
	if !bar_shadow_layers.is_empty():
		var shadow_material := bar_shadow_layers[0].material as ShaderMaterial
		var shadow_color: Color = PORTRAIT_DARK_BLUE.lightened(0.18)
		shadow_color.a = BADGE_SHADOW_STYLE_SCRIPT.SHADOW_ALPHA
		shadow_material.set_shader_parameter("shadow_color", shadow_color)
	var track := StyleBoxFlat.new()
	track.bg_color = Color.TRANSPARENT
	track.set_corner_radius_all(18)
	bar_frame.add_theme_stylebox_override("panel", track)
	bar_frame.z_index = 2
	holder.add_child(bar_frame)

	var bar := ProgressBar.new()
	bar.name = "UnlockBar"
	bar.position = bar_frame.position
	bar.size = bar_frame.size
	bar.min_value = 0.0
	bar.max_value = float(progress["total"])
	bar.value = float(progress["from"])
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var inner_track := StyleBoxFlat.new()
	inner_track.bg_color = Color.TRANSPARENT
	inner_track.set_corner_radius_all(15)
	var transparent_fill := StyleBoxFlat.new()
	transparent_fill.bg_color = Color.TRANSPARENT
	transparent_fill.set_corner_radius_all(15)
	bar.add_theme_stylebox_override("background", inner_track)
	bar.add_theme_stylebox_override("fill", transparent_fill)
	bar.z_index = 2
	holder.add_child(bar)
	# The shader clips the fixed-size pill at its progress front.
	var fill_panel := ColorRect.new()
	fill_panel.name = "UnlockBarFill"
	fill_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill_panel.position = Vector2.ZERO
	fill_panel.size = bar.size
	fill_panel.color = Color.WHITE
	var fill_material := ShaderMaterial.new()
	fill_material.shader = THEME_UNLOCK_FILL_SHADER
	fill_material.set_shader_parameter("fill_size", fill_panel.size)
	fill_material.set_shader_parameter("segmented", false)
	fill_material.set_shader_parameter("track_color", PORTRAIT_DARK_BLUE)
	fill_material.set_shader_parameter("base_color", PORTRAIT_UI_PALETTE.BUTTON_BLUE)
	fill_material.set_shader_parameter("highlight_color", Color("#96A9FF"))
	fill_panel.material = fill_material
	bar_frame.add_child(fill_panel)
	bar_frame.configure(bar, fill_panel)
	var count := Label.new()
	count.name = "UnlockCount"
	count.position = bar_frame.position
	count.size = bar_frame.size
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count.add_theme_font_override("font", UI_DISPLAY_FONT)
	count.add_theme_font_size_override("font_size", 20)
	count.add_theme_color_override("font_color", Color.WHITE)
	BUTTON_TEXT_STYLE_SCRIPT.apply_display(count)
	count.z_index = 3
	holder.add_child(count)
	var icon := Control.new()
	icon.name = "UnlockThemeIcon"
	# Keep the icon four stage units left of the endpoint and two above the bar center.
	icon.size = Vector2(52.8, 52.8)
	var bar_center_y: float = bar_frame.position.y + bar_frame.size.y * 0.5
	icon.position = Vector2(
		bar_frame.position.x + bar_frame.size.x - icon.size.x * 0.5 - 4.0,
		bar_center_y - icon.size.y * 0.5 - 2.0
	)
	icon.pivot_offset = icon.size * 0.5
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.z_index = 2
	holder.add_child(icon)
	# Match HUD resource icons: the combined shadow follows the icon bounce.
	var icon_shadow_layers := _create_portrait_icon_extrusion_layers(
		icon,
		theme_icon_texture,
		"UnlockThemeIcon",
		0,
		RESOURCE_COUNTER_STYLE.ICON_SHADOW_ALPHA
	)
	_layout_portrait_icon_holder_extrusion(icon, icon_shadow_layers)
	# Animate saturation on one artwork surface to avoid opacity dips from
	# crossfading two copies while the shadow remains stable underneath.
	var artwork := TextureRect.new()
	artwork.name = "Artwork"
	artwork.texture = theme_icon_texture
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	artwork.z_index = 1
	var icon_material := ShaderMaterial.new()
	icon_material.shader = THEME_UNLOCK_ICON_GRAYSCALE_SHADER
	icon_material.set_shader_parameter("colored_outline", true)
	icon_material.set_shader_parameter("outline_pixels", UI_MATERIALS.OUTLINE.THEME_PIXELS)
	icon_material.set_shader_parameter("outline_color", PORTRAIT_UI_PALETTE.TEXT_DARK)
	icon_material.set_shader_parameter("saturation", 0.0)
	icon_material.set_shader_parameter("shadow_tint", PORTRAIT_UI_PALETTE.BUTTON_BLUE_SELECTED)
	icon_material.set_shader_parameter("highlight_tint", PORTRAIT_UI_PALETTE.BUTTON_BLUE.lightened(0.10))
	artwork.material = icon_material
	icon.add_child(artwork)
	artwork.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Keep the count centered across the complete frame, including the icon end.
	holder.set_meta(&"unlock_progress", progress)
	_set_theme_unlock_bar_value(float(progress["from"]), holder)
	return holder

func _set_theme_unlock_bar_value(value: float, holder: Control) -> void:
	if !is_instance_valid(holder):
		return
	var bar := holder.get_node("UnlockBar") as ProgressBar
	bar.value = value
	var bar_frame := holder.get_node("UnlockBarFrame") as Control
	var ratio: float = 0.0
	if bar.max_value > 0.0:
		ratio = clampf(value / bar.max_value, 0.0, 1.0)
	bar_frame.set_value_ratio(ratio)
	var count := holder.find_child("UnlockCount", true, false) as Label
	count.text = "%d / %d" % [int(round(value)), int(bar.max_value)]

func _ensure_theme_unlock_glow(holder: Control) -> Control:
	if holder == null or !is_instance_valid(holder):
		return null
	var existing := holder.get_node_or_null("UnlockThemeGlow") as Control
	if existing != null and is_instance_valid(existing):
		return existing
	var icon := holder.get_node_or_null("UnlockThemeIcon") as Control
	if icon == null or !is_instance_valid(icon):
		return null
	var glow := TextureRect.new()
	glow.name = "UnlockThemeGlow"
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.texture = FINAL_REWARD_ROTATING_GLOW_TEXTURE
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glow.size = icon.size * 1.534
	glow.position = icon.position + icon.size * 0.5 - glow.size * 0.5
	glow.pivot_offset = glow.size * 0.5
	# Final-state layering: bar < glow < text < theme icon. This keeps the
	# rotating glow visibly on top of the progress bar while remaining directly
	# behind the theme artwork.
	glow.z_index = 3
	icon.z_index = 5
	holder.add_child(glow)
	COMPOSITED_FADE.set_opacity(glow, 0.0)
	return glow

func _animate_theme_unlock_progress(
	holder: Control,
	finished_callback: Callable = Callable()
) -> void:
	if holder == null or !is_instance_valid(holder) or !holder.is_inside_tree():
		if finished_callback.is_valid():
			finished_callback.call()
		return
	if bool(holder.get_meta(&"unlock_animation_started", false)):
		if finished_callback.is_valid():
			finished_callback.call()
		return
	holder.set_meta(&"unlock_animation_started", true)
	var progress: Dictionary = holder.get_meta(&"unlock_progress", {})
	var tween := _owned_tween(holder)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_method(Callable(self, "_set_theme_unlock_bar_value").bind(holder),
		float(progress["from"]), float(progress["to"]), 0.577
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	if !is_instance_valid(holder) or !holder.is_inside_tree():
		return
	if !bool(progress.get("unlocked", false)):
		if finished_callback.is_valid():
			finished_callback.call()
		return
	var bar := holder.get_node("UnlockBar") as ProgressBar
	_set_theme_unlock_bar_value(bar.max_value, holder)
	var title := holder.find_child("UnlockTitle", true, false) as Label
	title.hide()
	var count := holder.find_child("UnlockCount", true, false) as Label
	# Keep the requested font size and center on the complete plaque. The icon
	# does not reserve caption space or shift its horizontal center.
	count.clip_text = true
	count.text = tr("NEW_THEME_UNLOCKED")
	count.add_theme_font_size_override("font_size", 15)
	var bar_frame := holder.get_node("UnlockBarFrame") as Control
	count.position = bar_frame.position
	count.size = bar_frame.size
	COMPOSITED_FADE.wrap(count).z_index = 4
	count.show()
	var icon := holder.get_node("UnlockThemeIcon") as Control
	var fill := holder.find_child("UnlockBarFill", true, false) as Control
	var fill_material := fill.material as ShaderMaterial
	var recolor := _owned_tween(holder)
	recolor.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	recolor.set_parallel(true)
	recolor.tween_property(fill_material, "shader_parameter/base_color", PORTRAIT_UI_PALETTE.SUCCESS_SELECTED, 0.30).set_trans(Tween.TRANS_SINE)
	recolor.tween_property(fill_material, "shader_parameter/highlight_color", PORTRAIT_UI_PALETTE.SUCCESS_SOFT, 0.30).set_trans(Tween.TRANS_SINE)
	var bounce_up := _owned_tween(icon)
	bounce_up.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	bounce_up.tween_property(icon, "scale", Vector2.ONE * 1.234, 0.16).set_trans(Tween.TRANS_SINE)
	await bounce_up.finished
	if !is_instance_valid(holder) or !holder.is_inside_tree():
		return
	# Start revealing the rotating glow exactly at the bounce peak, while the
	# colored theme icon is still held at its maximum scale.
	var glow := _ensure_theme_unlock_glow(holder)
	if glow != null and is_instance_valid(glow):
		_start_final_reward_glow_rotation(glow, PORTRAIT_FINAL_REWARD_GLOW_ROTATION_DURATION)
		var glow_fade := _owned_tween(glow)
		glow_fade.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		glow_fade.tween_property(
			COMPOSITED_FADE.branch(glow),
			"opacity",
			0.52,
			0.35
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Restore the original colors while holding the peak briefly, then settle the
	# icon back to rest. The glow fade runs in parallel from the peak onward.
	var icon_material := (icon.get_node("Artwork") as TextureRect).material as ShaderMaterial
	var settle := _owned_tween(icon)
	settle.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	settle.tween_property(icon_material, "shader_parameter/saturation", 1.0, 0.12).set_trans(Tween.TRANS_SINE)
	settle.tween_property(icon, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await settle.finished
	if finished_callback.is_valid():
		finished_callback.call()

func _create_portrait_rounded_panel_extrusion_layers(
	parent: Control,
	prefix: String,
	z_index: int = -1
) -> Array[ColorRect]:
	return BADGE_SHADOW_STYLE_SCRIPT.create_layers(parent, prefix, z_index)

func _layout_portrait_rounded_panel_extrusion_layers(
	layers: Array[ColorRect],
	panel_size: Vector2,
	corner_radius: float
) -> void:
	BADGE_SHADOW_STYLE_SCRIPT.layout_layers(
		layers,
		panel_size,
		corner_radius
	)

func _create_portrait_icon_extrusion_layers(
	parent: Control,
	texture: Texture2D,
	prefix: String,
	z_index: int = 0,
	shadow_alpha: float = 1.0
) -> Array[TextureRect]:
	return PORTRAIT_ICON_EXTRUSION._create_portrait_icon_extrusion_layers(parent, texture, prefix, z_index, shadow_alpha)

func _layout_portrait_icon_holder_extrusion(
	holder: Control,
	layers: Array[TextureRect],
	shadow_offset_scale: float = 1.0
) -> void:
	PORTRAIT_ICON_EXTRUSION._layout_portrait_icon_holder_extrusion(holder, layers, shadow_offset_scale)

func _start_final_reward_glow_rotation(
	glow: Control,
	duration: float = PORTRAIT_FINAL_REWARD_GLOW_ROTATION_DURATION
) -> void:
	if glow == null or !is_instance_valid(glow) or !glow.is_inside_tree():
		return
	glow.pivot_offset = glow.size * 0.5
	var rotation_tween := _owned_tween(glow)
	rotation_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	rotation_tween.set_loops()
	rotation_tween.tween_property(
		glow,
		"rotation",
		TAU,
		duration
	).from(0.0)

var _owned_animations: Array[Tween] = []

func _owned_tween(owner: Node) -> Tween:
	_prune_owned_animations()
	var tween := owner.create_tween()
	_owned_animations.append(tween)
	set_process(true)
	tween.finished.connect(_on_owned_tween_finished.bind(tween.get_instance_id()), CONNECT_ONE_SHOT)
	return tween

func _exit_tree() -> void:
	for tween: Tween in _owned_animations:
		if tween != null and tween.is_valid():
			tween.kill()
	_owned_animations.clear()
	set_process(false)

func _on_owned_tween_finished(identifier: int) -> void:
	for index in range(_owned_animations.size() - 1, -1, -1):
		if _owned_animations[index].get_instance_id() == identifier:
			_owned_animations.remove_at(index)
			set_process(!_owned_animations.is_empty())
			return

func _cancel_owned_tween(tween: Tween) -> void:
	if tween != null:
		tween.kill()
		_owned_animations.erase(tween)
		set_process(!_owned_animations.is_empty())

func _ready() -> void:
	set_process(false)

func _process(_delta: float) -> void:
	_prune_owned_animations()

func _prune_owned_animations() -> void:
	# kill() and a bound owner's destruction do not emit finished.
	for index in range(_owned_animations.size() - 1, -1, -1):
		if !_owned_animations[index].is_valid():
			_owned_animations.remove_at(index)
	set_process(!_owned_animations.is_empty())
