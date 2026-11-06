extends RefCounted
## One legal modal shared by startup and the runtime; Main is never a dependency.
const POPUP = preload("res://scripts/ui/portrait_popup.gd")
const FONTS = preload("res://scripts/ui/ui_fonts.gd")
const PALETTE = preload("res://scripts/ui/ui_palette.gd")
const HOLDER = preload("res://scripts/ui/flash_stage_control.gd")
const UI_MATERIALS = preload("res://scripts/ui/ui_materials.gd")
const BUTTON = preload("res://scripts/ui/stage_long_button.gd")

static func show(parent: Node, accept: Callable, layer_index: int = 1002,
	inherited_theme: Theme = null, resume_without_intro: bool = false,
	open_sound: Callable = Callable(), click_sound: Callable = Callable()) -> CanvasLayer:
	if !resume_without_intro and open_sound.is_valid():
		open_sound.call()
	var popup: CanvasLayer = POPUP.open(parent, "LegalConsentPopup", "legal_consent_popup",
		&"portrait_modal_popup", layer_index, Callable(), 225.0, 512.0, inherited_theme,
		FONTS.regular_font(), 0.874, 0.18 if !resume_without_intro else 0.0, resume_without_intro)
	var style := {
		"top_trim": 51.3, "corner_radius": 26.0, "title_scale": 1.2078,
		"heading_scale": 1.12, "display_font": FONTS.display_font(),
		"button_uniform_scale": 1.15, "long_button_min_source_width": 280.0,
		"long_button_width": 313.6, "button_length_scale": 0.85,
		"bottom_button_gap": 25.0,
	}
	POPUP.build_shell(popup.stage, style, Rect2(28.0, 225.0, 424.0, 287.0),
		TranslationServer.translate("LEGAL_WELCOME_TITLE"), Callable(), 27,
		PALETTE.UI_BLUE, PALETTE.UI_BLUE_DARK, PALETTE.ACCENT_ORANGE, "", false)
	var holder: Control = HOLDER.new()
	holder.stage_rect = Rect2(54.0, 294.0, 372.0, 116.0)
	popup.stage.add_child(holder)
	var text := RichTextLabel.new()
	text.name = "LegalConsentText"
	text.bbcode_enabled = true
	text.scroll_active = false
	text.focus_mode = Control.FOCUS_NONE
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.add_theme_font_override("normal_font", FONTS.regular_font())
	text.add_theme_font_override("bold_font", FONTS.regular_font())
	text.add_theme_font_size_override("normal_font_size", 22)
	text.add_theme_font_size_override("bold_font_size", 22)
	text.add_theme_color_override("default_color", Color.WHITE)
	var link_color: String = PALETTE.SUCCESS_SOFT.to_html(false)
	text.text = TranslationServer.translate("LEGAL_CONSENT_TEXT") % [link_color, link_color]
	_style_text(holder, text)
	text.meta_clicked.connect(open_document)
	holder.add_child(text)
	text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var button: Control = BUTTON.new()
	button.name = "LegalAcceptButton"
	# Preserve the original popup CTA's geometry and both font-size steps.
	var button_y: float = POPUP.bottom_button_y(style, 512.0, 56.0)
	button.stage_rect = POPUP.button_rect(style, Rect2(90.0, button_y, 300.0, 56.0))
	popup.stage.add_child(button)
	button.configure(TranslationServer.translate("LEGAL_ACCEPT"), FONTS.display_button_font_size(POPUP.button_font_size(style, 22)))
	button.set_color_preset(BUTTON.ColorPreset.ORANGE)
	button.drop_shadow_enabled = true
	button.attention_bounce_enabled = false
	if click_sound.is_valid():
		button.pressed.connect(click_sound)
	button.pressed.connect(accept)
	return popup

static func open_document(meta: Variant) -> void:
	var url: String = document_url(meta)
	if !url.is_empty():
		OS.shell_open(url)

static func document_url(meta: Variant) -> String:
	var document_type: String = str(meta)
	if document_type not in ["terms", "privacy"]:
		return ""
	var key: String = "legal/terms_of_service_url" if document_type == "terms" else "legal/privacy_policy_url"
	var localized_key: String = key + "_en" if Database.interface_language == "en" else key
	return str(ProjectSettings.get_setting(localized_key, ProjectSettings.get_setting(key, ""))).strip_edges()

static func _style_text(
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

