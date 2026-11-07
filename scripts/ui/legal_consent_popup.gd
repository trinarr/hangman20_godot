extends RefCounted
## One legal modal shared by startup and the runtime; Main is never a dependency.
const POPUP = preload("res://scripts/ui/portrait_popup.gd")
const FONTS = preload("res://scripts/ui/ui_fonts.gd")
const PALETTE = preload("res://scripts/ui/ui_palette.gd")
const HOLDER = preload("res://scripts/ui/flash_stage_control.gd")
const TEXT_STYLE = preload("res://scripts/ui/rich_text_style.gd")
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
	TEXT_STYLE.apply_regular_display(holder, text)
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
