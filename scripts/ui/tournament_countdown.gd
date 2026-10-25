extends Control
## Shared tournament countdown pill for the introduction and standings tab.
const PALETTE = preload("res://scripts/ui/ui_palette.gd")
const FONTS = preload("res://scripts/ui/ui_fonts.gd")
const TEXT_STYLE = preload("res://scripts/ui/button_text_style.gd")
const CLOCK = preload("res://scripts/ui/timer_clock_icon.gd")
const PILL_SIZE := Vector2(144, 34) * 0.85
var digits: Label

func _ready() -> void:
	size = PILL_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var plate := Panel.new()
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = PALETTE.TEXT_DARK
	style.set_corner_radius_all(roundi(PILL_SIZE.y * 0.5))
	plate.add_theme_stylebox_override("panel", style)
	add_child(plate)
	var clock: Control = CLOCK.new()
	clock.name = "TournamentStartClockIcon"
	clock.position = Vector2.ONE * ((PILL_SIZE.y - 26.0) * 0.5)
	clock.size = Vector2(26, 26)
	add_child(clock)
	digits = Label.new()
	digits.name = "TournamentStartTimer"
	digits.position = Vector2(31, 0)
	digits.size = PILL_SIZE - Vector2(34, 0)
	digits.mouse_filter = Control.MOUSE_FILTER_IGNORE
	digits.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	digits.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	digits.add_theme_font_override("font", FONTS.regular_font())
	digits.add_theme_font_size_override("font_size", 20)
	digits.add_theme_color_override("font_color", Color.WHITE)
	add_child(digits)
	TEXT_STYLE.apply_regular_display(digits)

func set_remaining(seconds: int) -> void:
	var remaining := maxi(0, seconds)
	digits.text = "%02d:%02d:%02d" % [remaining / 3600, (remaining / 60) % 60, remaining % 60]
