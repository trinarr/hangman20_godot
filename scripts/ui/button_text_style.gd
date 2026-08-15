class_name ButtonTextStyle
extends RefCounted

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
