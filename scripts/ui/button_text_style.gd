class_name ButtonTextStyle
extends RefCounted

const UI_PALETTE: GDScript = preload("res://scripts/ui/ui_palette.gd")
const DISPLAY_TEXT_EFFECT_SCRIPT: GDScript = preload("res://scripts/ui/display_text_effect.gd")

const DEFAULT_OUTLINE_SIZE: int = 3
const DEFAULT_SHADOW_OFFSET: int = 2

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
