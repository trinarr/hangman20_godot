extends Control
## Static, native-coordinate counterpart of the stage HUD counter.
const STYLE = preload("res://scripts/ui/resource_counter_style.gd")
const PALETTE = preload("res://scripts/ui/ui_palette.gd")
const FONTS = preload("res://scripts/ui/ui_fonts.gd")
const TEXT = preload("res://scripts/ui/button_text_style.gd")
const EXTRUSION = preload("res://scripts/ui/portrait_icon_extrusion.gd")
var icon_texture: Texture2D
var value := ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var factor := size.y / 48.0
	var plate_rect := STYLE.panel_rect(Rect2(Vector2.ZERO, size))
	var plate := Panel.new()
	plate.name = "CounterBackground"
	plate.position = plate_rect.position
	plate.size = plate_rect.size
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = PALETTE.with_alpha(PALETTE.UI_BLUE_DARK, PALETTE.RESOURCE_COUNTER_OPACITY)
	style.set_corner_radius_all(roundi(plate_rect.size.y * 0.5))
	plate.add_theme_stylebox_override("panel", style)
	add_child(plate)
	var base_icon_position := Vector2(2.0 * factor + STYLE.ICON_SIZE * 0.28, (size.y - STYLE.ICON_SIZE) * 0.5)
	var icon_position := base_icon_position + STYLE.STAR_ICON_OFFSET
	var icon_size := Vector2.ONE * STYLE.ICON_SIZE
	var shadows := EXTRUSION._create_portrait_icon_extrusion_layers(self, icon_texture, "ScoreStarShadow")
	EXTRUSION._layout_portrait_icon_extrusion_layers(shadows, icon_position, icon_size)
	var icon := TextureRect.new()
	icon.name = "LeaderboardStarIcon"
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = icon_texture
	icon.position = icon_position
	icon.size = icon_size
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon)
	var label := Label.new()
	label.name = "ScoreValue"
	label.position = Vector2(maxf(43.0 * factor, base_icon_position.x + icon_size.x + 3.0), plate_rect.position.y)
	label.size = Vector2(plate_rect.end.x - STYLE.TRAILING_INSET * factor - label.position.x, plate_rect.size.y)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.clip_text = true
	label.clip_contents = true
	label.add_theme_font_override("font", FONTS.regular_font())
	label.add_theme_color_override("font_color", Color.WHITE)
	TEXT.apply_regular_display(label)
	var font_size := roundi(24.0 * factor * STYLE.FONT_SCALE)
	while font_size > 8 and FONTS.regular_font().get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > label.size.x - 4.0:
		font_size -= 1
	label.add_theme_font_size_override("font_size", font_size)
	label.text = value
	add_child(label)
