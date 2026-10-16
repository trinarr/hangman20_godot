extends RefCounted
## Shared geometry and connected tab/body treatment for Profile and Leaderboard.
const PALETTE = preload("res://scripts/ui/ui_palette.gd")
const FONTS = preload("res://scripts/ui/ui_fonts.gd")
const TEXT_STYLE = preload("res://scripts/ui/button_text_style.gd")
const TAB_Y := 88.0
const TAB_HEIGHT := 65.0
const CONTENT_Y := TAB_Y + TAB_HEIGHT
const BAND_HEIGHT := CONTENT_Y - 80.0

static func configure(button: Button, title: String, selected: bool, unavailable: bool = false) -> void:
	button.text = ""
	button.set_meta("tab_title", title)
	button.focus_mode = Control.FOCUS_NONE
	button.disabled = unavailable
	var caption := Label.new()
	caption.name = "TabCaption"
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	caption.text = title
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.add_theme_font_override("font", FONTS.display_font())
	caption.add_theme_font_size_override("font_size", 27)
	caption.add_theme_color_override("font_color", Color.WHITE)
	caption.modulate.a = 0.38 if unavailable else 1.0
	TEXT_STYLE.apply_display(caption)
	button.add_child(caption)
	select(button, selected)

static func select(button: Button, selected: bool) -> void:
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = PALETTE.UI_BLUE if selected and !button.disabled else Color.TRANSPARENT
		style.corner_radius_top_left = 16
		style.corner_radius_top_right = 16
		# Square bottom corners join the identically colored content backdrop.
		style.corner_radius_bottom_left = 0
		style.corner_radius_bottom_right = 0
		button.add_theme_stylebox_override(state, style)
