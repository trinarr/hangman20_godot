extends RefCounted
## Shared regular text outline and shadow layers for BBCode labels.
const PALETTE = preload("res://scripts/ui/ui_palette.gd")
const UI_MATERIALS = preload("res://scripts/ui/ui_materials.gd")

static func apply_regular_display(
	holder: Control,
	target: RichTextLabel
) -> void:
	if holder == null or target == null or !is_instance_valid(target):
		return

	# Match ButtonTextStyle.apply_regular_display(), which is used by the quiz
	# question. RichTextLabel needs real RichTextLabel shadow copies so its
	# BBCode links remain clickable on the untouched front layer.
	var font_size: float = float(maxi(target.get_theme_font_size("normal_font_size"), 1))
	var outline_local: float = clampf(font_size * 0.075, 2.0, 9.0)
	var outline_size: int = maxi(1, int(round(outline_local * 0.55)))
	var shadow_spread: int = maxi(1, int(round(outline_local * 0.92 * 0.55)))
	var shadow_depth: float = clampf(font_size * 0.055, 1.5, 5.0) * 0.70
	var shadow_offset_x: float = minf(font_size * 0.012, 1.5) * 0.70

	target.add_theme_color_override(
		"font_outline_color",
		PALETTE.UI_BLUE.darkened(0.40)
	)
	target.add_theme_constant_override("outline_size", outline_size)
	target.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	target.add_theme_constant_override("shadow_offset_x", 0)
	target.add_theme_constant_override("shadow_offset_y", 0)
	target.add_theme_constant_override("shadow_outline_size", 0)

	var shadow_material: ShaderMaterial = UI_MATERIALS.text_shadow(
		PALETTE.NAV_TEXT_SHADOW
	)
	var layer_depths: Array[float] = [0.25, 0.55, 0.80, 1.0]
	for layer_index: int in range(layer_depths.size()):
		var layer_t: float = layer_depths[layer_index]
		var shadow_text := RichTextLabel.new()
		shadow_text.name = "LegalConsentTextShadow%02d" % (layer_index + 1)
		shadow_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shadow_text.focus_mode = Control.FOCUS_NONE
		shadow_text.bbcode_enabled = true
		shadow_text.fit_content = false
		shadow_text.scroll_active = false
		shadow_text.selection_enabled = false
		shadow_text.autowrap_mode = target.autowrap_mode
		shadow_text.vertical_alignment = target.vertical_alignment
		shadow_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		shadow_text.offset_left = shadow_offset_x * layer_t
		shadow_text.offset_right = shadow_offset_x * layer_t
		shadow_text.offset_top = shadow_depth * layer_t
		shadow_text.offset_bottom = shadow_depth * layer_t
		shadow_text.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		shadow_text.add_theme_font_override("normal_font", target.get_theme_font("normal_font"))
		shadow_text.add_theme_font_override("bold_font", target.get_theme_font("bold_font"))
		shadow_text.add_theme_font_size_override(
			"normal_font_size",
			target.get_theme_font_size("normal_font_size")
		)
		shadow_text.add_theme_font_size_override(
			"bold_font_size",
			target.get_theme_font_size("bold_font_size")
		)
		shadow_text.add_theme_color_override("default_color", Color.WHITE)
		shadow_text.add_theme_color_override("font_outline_color", Color.WHITE)
		shadow_text.add_theme_constant_override("outline_size", shadow_spread)
		shadow_text.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
		shadow_text.add_theme_constant_override("shadow_offset_x", 0)
		shadow_text.add_theme_constant_override("shadow_offset_y", 0)
		shadow_text.add_theme_constant_override("shadow_outline_size", 0)
		shadow_text.material = shadow_material
		shadow_text.text = target.text
		holder.add_child(shadow_text)

