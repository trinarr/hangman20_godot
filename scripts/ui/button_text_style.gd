class_name ButtonTextStyle
extends RefCounted

const UI_PALETTE: GDScript = preload("res://scripts/ui/ui_palette.gd")
const UI_MATERIALS: GDScript = preload("res://scripts/ui/ui_materials.gd")
const DISPLAY_TEXT_EFFECT_SCRIPT: GDScript = preload("res://scripts/ui/display_text_effect.gd")

const DEFAULT_OUTLINE_SIZE: int = 3
const DEFAULT_SHADOW_OFFSET: int = 2
const REGULAR_DISPLAY_SHADOW_OFFSET_SCALE: float = 0.70
const REGULAR_DISPLAY_OUTLINE_SCALE: float = 0.55
const REGULAR_DISPLAY_SHADOW_SPREAD_SCALE: float = 0.55

static func apply(
	target: Control,
	outline_color: Color,
	shadow_color: Color = Color(-1.0, -1.0, -1.0, -1.0),
	outline_size: int = DEFAULT_OUTLINE_SIZE,
	shadow_offset: int = DEFAULT_SHADOW_OFFSET
) -> void:
	if target == null or !is_instance_valid(target):
		return
	var resolved_shadow_color: Color = outline_color
	if shadow_color.r >= 0.0:
		resolved_shadow_color = shadow_color
	target.add_theme_color_override("font_outline_color", outline_color)
	target.add_theme_constant_override("outline_size", maxi(outline_size, 0))
	target.add_theme_color_override("font_shadow_color", resolved_shadow_color)
	target.add_theme_constant_override("shadow_offset_x", shadow_offset)
	target.add_theme_constant_override("shadow_offset_y", shadow_offset)
	target.add_theme_constant_override("shadow_outline_size", 0)

static func apply_display(target: Control) -> void:
	if target == null or !is_instance_valid(target):
		return
	# The shader owns the display outline and shadow. Keep the native Label/Button
	# effects disabled so they do not double the generated silhouette.
	target.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
	target.add_theme_constant_override("outline_size", 0)
	target.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	target.add_theme_constant_override("shadow_offset_x", 0)
	target.add_theme_constant_override("shadow_offset_y", 0)
	target.add_theme_constant_override("shadow_outline_size", 0)

	# Reuse the exact navy treatment already present in the project: the outline
	# matches the comment-popup title and the extrusion uses the navigation shadow.
	var outline_color: Color = UI_PALETTE.UI_BLUE.darkened(0.40)
	DISPLAY_TEXT_EFFECT_SCRIPT.attach(target, outline_color, UI_PALETTE.NAV_TEXT_SHADOW)

static func apply_regular_display(target: Control) -> void:
	if target == null or !is_instance_valid(target):
		return
	# Regular text keeps the same outline/extrusion language as display text,
	# but the shadow sits 30% closer to the glyph than headings/buttons.
	target.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
	target.add_theme_constant_override("outline_size", 0)
	target.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	target.add_theme_constant_override("shadow_offset_x", 0)
	target.add_theme_constant_override("shadow_offset_y", 0)
	target.add_theme_constant_override("shadow_outline_size", 0)

	var outline_color: Color = UI_PALETTE.UI_BLUE.darkened(0.40)
	DISPLAY_TEXT_EFFECT_SCRIPT.attach(
		target,
		outline_color,
		UI_PALETTE.NAV_TEXT_SHADOW,
		REGULAR_DISPLAY_SHADOW_OFFSET_SCALE,
		REGULAR_DISPLAY_OUTLINE_SCALE,
		REGULAR_DISPLAY_SHADOW_SPREAD_SCALE
	)

static func apply_display_to_rich_text(
	holder: Control,
	target: RichTextLabel,
	shadow_name_prefix: String = "DisplayRichTextShadow",
	outline_color_override: Color = Color(-1.0, -1.0, -1.0, -1.0),
	shadow_color_override: Color = Color(-1.0, -1.0, -1.0, -1.0)
) -> void:
	if (
		holder == null
		or target == null
		or !is_instance_valid(holder)
		or !is_instance_valid(target)
	):
		return

	# RichTextLabel cannot use DisplayTextEffect directly because its per-character
	# custom effects (the result-word bounce) would be replaced by a plain Label.
	# Rebuild the same button/display treatment with RichTextLabel shadow layers,
	# while leaving the authored front RichTextLabel and its custom FX intact.
	var font_size: float = float(maxi(target.get_theme_font_size("normal_font_size"), 1))
	var outline_local: float = clampf(
		font_size * DISPLAY_TEXT_EFFECT_SCRIPT.OUTLINE_SIZE_RATIO,
		DISPLAY_TEXT_EFFECT_SCRIPT.OUTLINE_SIZE_MIN,
		DISPLAY_TEXT_EFFECT_SCRIPT.OUTLINE_SIZE_MAX
	)
	var outline_size: int = maxi(1, int(round(outline_local)))
	var shadow_spread: int = maxi(1, int(round(
		outline_local * DISPLAY_TEXT_EFFECT_SCRIPT.SHADOW_SPREAD_FROM_OUTLINE
	)))
	var shadow_depth: float = clampf(
		font_size * DISPLAY_TEXT_EFFECT_SCRIPT.SHADOW_DEPTH_RATIO,
		DISPLAY_TEXT_EFFECT_SCRIPT.SHADOW_DEPTH_MIN,
		DISPLAY_TEXT_EFFECT_SCRIPT.SHADOW_DEPTH_MAX
	)
	var shadow_offset_x: float = minf(
		font_size * DISPLAY_TEXT_EFFECT_SCRIPT.SHADOW_OFFSET_X_RATIO,
		DISPLAY_TEXT_EFFECT_SCRIPT.SHADOW_OFFSET_X_MAX
	)
	var outline_color: Color = UI_PALETTE.UI_BLUE.darkened(0.40)
	if outline_color_override.r >= 0.0:
		outline_color = outline_color_override
	var shadow_color: Color = UI_PALETTE.NAV_TEXT_SHADOW
	if shadow_color_override.r >= 0.0:
		shadow_color = shadow_color_override

	# Match apply_display(): the front glyph owns the outline; the native shadow is
	# disabled because the four shader-tinted silhouettes below provide the depth.
	target.add_theme_color_override("font_outline_color", outline_color)
	target.add_theme_constant_override("outline_size", outline_size)
	target.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	target.add_theme_constant_override("shadow_offset_x", 0)
	target.add_theme_constant_override("shadow_offset_y", 0)
	target.add_theme_constant_override("shadow_outline_size", 0)

	var shadow_material: ShaderMaterial = UI_MATERIALS.text_shadow(shadow_color)
	var parsed_text: String = target.get_parsed_text()
	var layer_depths: Array[float] = [0.25, 0.55, 0.80, 1.0]
	for layer_index: int in range(layer_depths.size()):
		var layer_t: float = layer_depths[layer_index]
		var shadow_text := RichTextLabel.new()
		shadow_text.name = "%s%02d" % [shadow_name_prefix, layer_index + 1]
		shadow_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shadow_text.focus_mode = Control.FOCUS_NONE
		shadow_text.fit_content = false
		shadow_text.scroll_active = false
		shadow_text.selection_enabled = false
		shadow_text.context_menu_enabled = false
		shadow_text.autowrap_mode = target.autowrap_mode
		shadow_text.horizontal_alignment = target.horizontal_alignment
		shadow_text.vertical_alignment = target.vertical_alignment
		shadow_text.clip_contents = false
		shadow_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		shadow_text.offset_left = shadow_offset_x * layer_t
		shadow_text.offset_right = shadow_offset_x * layer_t
		shadow_text.offset_top = shadow_depth * layer_t
		shadow_text.offset_bottom = shadow_depth * layer_t
		shadow_text.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		shadow_text.add_theme_font_override("normal_font", target.get_theme_font("normal_font"))
		shadow_text.add_theme_font_size_override(
			"normal_font_size",
			target.get_theme_font_size("normal_font_size")
		)
		shadow_text.add_theme_color_override("default_color", Color.WHITE)
		shadow_text.add_theme_color_override("font_outline_color", Color.WHITE)
		shadow_text.add_theme_constant_override("outline_size", shadow_spread)
		shadow_text.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
		shadow_text.add_theme_constant_override("shadow_offset_x", 0)
		shadow_text.add_theme_constant_override("shadow_offset_y", 0)
		shadow_text.add_theme_constant_override("shadow_outline_size", 0)
		shadow_text.material = shadow_material
		shadow_text.text = parsed_text
		shadow_text.z_index = target.z_index - 1
		holder.add_child(shadow_text)
