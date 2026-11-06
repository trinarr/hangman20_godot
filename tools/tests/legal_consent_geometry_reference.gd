extends "res://scripts/main_portrait.gd"
## Pre-loader legal popup layout, through the original runtime layout helpers.
var reference_popup: CanvasLayer
var reference_text: RichTextLabel
var reference_button: Control
var open_sound_calls: int = 0
var click_sound_calls: int = 0

func _play_popup_open_sound() -> void:
	open_sound_calls += 1
	super._play_popup_open_sound()

func _play_ui_click_sound() -> void:
	click_sound_calls += 1
	super._play_ui_click_sound()

func _ready() -> void:
	_build_root()
	_clear()

func build_reference() -> void:
	var rect := _portrait_popup_with_bottom_space(Rect2(28.0, 225.0, 424.0, 280.0))
	_portrait_popup_resume_without_intro = true
	var previous_content := _portrait_popup_begin("ReferenceLegal", "legal_geometry_reference",
		2001, Callable(), rect.position.y, rect.end.y, false, Callable(), false)
	reference_popup = content.get_parent().get_parent() as CanvasLayer
	_portrait_popup_shell(rect, tr("LEGAL_WELCOME_TITLE"), Callable(), 27,
		PORTRAIT_BLUE, PORTRAIT_DARK_BLUE, PORTRAIT_ORANGE, "", false)
	var holder := _stage_holder(Rect2(54.0, 294.0, 372.0, 116.0), Control.MOUSE_FILTER_PASS)
	reference_text = RichTextLabel.new()
	reference_text.name = "LegalConsentText"
	reference_text.bbcode_enabled = true
	reference_text.scroll_active = false
	reference_text.focus_mode = Control.FOCUS_NONE
	reference_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reference_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	reference_text.add_theme_font_override("normal_font", UI_REGULAR_FONT)
	reference_text.add_theme_font_override("bold_font", UI_REGULAR_FONT)
	reference_text.add_theme_font_size_override("normal_font_size", 22)
	reference_text.add_theme_font_size_override("bold_font_size", 22)
	reference_text.add_theme_color_override("default_color", Color.WHITE)
	var link_color: String = PORTRAIT_UI_PALETTE.SUCCESS_SOFT.to_html(false)
	reference_text.text = tr("LEGAL_CONSENT_TEXT") % [link_color, link_color]
	# Reuse the unchanged text effect; the runtime helpers remain the layout reference.
	preload("res://scripts/ui/rich_text_style.gd").apply_regular_display(holder, reference_text)
	holder.add_child(reference_text)
	reference_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	reference_button = _stage_portrait_popup_main_button(
		Rect2(90.0, _portrait_popup_bottom_button_y(rect.end.y, 56.0), 300.0, 56.0),
		Callable(), tr("LEGAL_ACCEPT"), 22, false, 0.0, false, false, false,
		LONG_BUTTON_COLOR_ORANGE)
	reference_button.set("drop_shadow_enabled", true)
	content = previous_content
