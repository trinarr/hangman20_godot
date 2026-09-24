class_name ButtonTextStyle
extends RefCounted

const UI_PALETTE: GDScript = preload("res://scripts/ui/ui_palette.gd")
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
	target.begin_bulk_theme_override()
	target.add_theme_color_override("font_outline_color", outline_color)
	target.add_theme_constant_override("outline_size", maxi(outline_size, 0))
	target.add_theme_color_override("font_shadow_color", resolved_shadow_color)
	target.add_theme_constant_override("shadow_offset_x", shadow_offset)
	target.add_theme_constant_override("shadow_offset_y", shadow_offset)
	target.add_theme_constant_override("shadow_outline_size", 0)
	target.end_bulk_theme_override()

static func apply_display(target: Control) -> void:
	# Reuse the exact navy treatment already present in the project: the outline
	# matches the comment-popup title and the extrusion uses the navigation shadow.
	apply_display_tinted(
		target,
		UI_PALETTE.UI_BLUE.darkened(0.40),
		UI_PALETTE.NAV_TEXT_SHADOW
	)

static func apply_display_tinted(
	target: Control,
	outline_color: Color,
	shadow_color: Color
) -> void:
	if target == null or !is_instance_valid(target):
		return
	# Keep the exact button/display geometry; only the two authored colors differ.
	# Native Label/Button effects stay disabled so they cannot double the shader
	# outline or extrusion.
	target.begin_bulk_theme_override()
	target.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
	target.add_theme_constant_override("outline_size", 0)
	target.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	target.add_theme_constant_override("shadow_offset_x", 0)
	target.add_theme_constant_override("shadow_offset_y", 0)
	target.add_theme_constant_override("shadow_outline_size", 0)
	target.end_bulk_theme_override()
	DISPLAY_TEXT_EFFECT_SCRIPT.attach(target, outline_color, shadow_color)

static func apply_regular_display(target: Control) -> void:
	if target == null or !is_instance_valid(target):
		return
	# Regular text keeps the same outline/extrusion language as display text,
	# but the shadow sits 30% closer to the glyph than headings/buttons.
	target.begin_bulk_theme_override()
	target.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
	target.add_theme_constant_override("outline_size", 0)
	target.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	target.add_theme_constant_override("shadow_offset_x", 0)
	target.add_theme_constant_override("shadow_offset_y", 0)
	target.add_theme_constant_override("shadow_outline_size", 0)
	target.end_bulk_theme_override()

	var outline_color: Color = UI_PALETTE.UI_BLUE.darkened(0.40)
	DISPLAY_TEXT_EFFECT_SCRIPT.attach(
		target,
		outline_color,
		UI_PALETTE.NAV_TEXT_SHADOW,
		REGULAR_DISPLAY_SHADOW_OFFSET_SCALE,
		REGULAR_DISPLAY_OUTLINE_SCALE,
		REGULAR_DISPLAY_SHADOW_SPREAD_SCALE
	)
