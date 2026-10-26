extends RefCounted
## Shared geometry and connected tab/body treatment for Profile and Leaderboard.
const PALETTE = preload("res://scripts/ui/ui_palette.gd")
const FONTS = preload("res://scripts/ui/ui_fonts.gd")
const TEXT_STYLE = preload("res://scripts/ui/button_text_style.gd")
const BACKGROUND = preload("res://scripts/ui/tab_header_background.gd")
const CONFIG = preload("res://scripts/core/game_design_config.gd")
const TAB_Y := 88.0
const TAB_HEIGHT := 65.0
const CONTENT_Y := TAB_Y + TAB_HEIGHT
const BAND_HEIGHT := CONTENT_Y - 80.0

static func configure(button: Button, title: String, selected: bool, unavailable: bool = false) -> void:
	button.text = ""
	button.set_meta("tab_title", title)
	button.set_meta("tab_unavailable", unavailable)
	button.focus_mode = Control.FOCUS_NONE
	button.disabled = unavailable
	var background := BACKGROUND.new()
	background.name = "TabGradient"
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.add_child(background)
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
	button.resized.connect(func(): button.pivot_offset = button.size * 0.5)
	button.tree_exiting.connect(_reset_press.bind(button))
	select(button, selected)

static func _reset_press(button: Button) -> void:
	var tween: Tween = button.get_meta("tab_release_tween") if button.has_meta("tab_release_tween") else null
	if tween != null and tween.is_valid():
		tween.kill()
	button.scale = Vector2.ONE

static func select(button: Button, selected: bool, animate: bool = false) -> void:
	_reset_press(button)
	var unavailable: bool = button.get_meta("tab_unavailable", false)
	button.disabled = unavailable or selected
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE if button.disabled else Control.MOUSE_FILTER_STOP
	var background := button.get_node_or_null("TabGradient")
	if background != null:
		background.visible = selected and !unavailable
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color.TRANSPARENT
		style.corner_radius_top_left = 16
		style.corner_radius_top_right = 16
		# Square bottom corners join the identically colored content backdrop.
		style.corner_radius_bottom_left = 0
		style.corner_radius_bottom_right = 0
		button.add_theme_stylebox_override(state, style)
	if selected and animate and !unavailable:
		button.pivot_offset = button.size * 0.5
		button.scale = Vector2.ONE * 0.94
		var tween := button.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(button, "scale", Vector2.ONE, CONFIG.get_float("timings.animations.counter_release_seconds")).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		button.set_meta("tab_release_tween", tween)
