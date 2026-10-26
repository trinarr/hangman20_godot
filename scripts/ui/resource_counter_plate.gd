extends Control
## Static, native-coordinate counterpart of the stage HUD counter.
const STYLE = preload("res://scripts/ui/resource_counter_style.gd")
const PALETTE = preload("res://scripts/ui/ui_palette.gd")
const FONTS = preload("res://scripts/ui/ui_fonts.gd")
const TEXT = preload("res://scripts/ui/button_text_style.gd")
const EXTRUSION = preload("res://scripts/ui/portrait_icon_extrusion.gd")
var icon_texture: Texture2D
var value := ""

static var _glyph_ink: Dictionary = {}

static func text_ink_bounds(text: String, font: Font, font_size: int) -> Rect2:
	var line := TextLine.new()
	line.add_string(text, font, font_size)
	var server := TextServerManager.get_primary_interface()
	var bounds := Rect2()
	var pen_x := 0.0
	var has_ink := false
	for glyph: Dictionary in server.shaped_text_get_glyphs(line.get_rid()):
		var font_rid: RID = glyph["font_rid"]
		var glyph_size := Vector2i(int(glyph["font_size"]), 0)
		var key := [font_rid, glyph_size.x, int(glyph["index"])]
		if !_glyph_ink.has(key):
			var ink := Rect2()
			if font_rid.is_valid() and glyph_size.x > 0:
				var glyph_index := int(glyph["index"])
				var offset := server.font_get_glyph_offset(font_rid, glyph_size, glyph_index)
				var extent := server.font_get_glyph_size(font_rid, glyph_size, glyph_index)
				var uv := server.font_get_glyph_uv_rect(font_rid, glyph_size, glyph_index)
				ink = Rect2(offset, extent)
				if uv.has_area():
					var atlas := server.font_get_texture_image(font_rid, glyph_size, server.font_get_glyph_texture_idx(font_rid, glyph_size, glyph_index))
					if atlas != null:
						var used := atlas.get_region(Rect2i(uv)).get_used_rect()
						var pixel_scale := extent / uv.size
						ink = Rect2(offset + Vector2(used.position) * pixel_scale, Vector2(used.size) * pixel_scale)
			# Only score digits, separators and the small supported font sizes are
			# cached. Never retain atlas images or perform GPU readback per row.
			_glyph_ink[key] = ink
		for repetition: int in int(glyph["repeat"]):
			var glyph_rect: Rect2 = _glyph_ink[key]
			if glyph_rect.has_area():
				glyph_rect.position += Vector2(pen_x, 0.0) + Vector2(glyph["offset"])
				bounds = bounds.merge(glyph_rect) if has_ink else glyph_rect
				has_ink = true
			pen_x += float(glyph["advance"])
	return bounds

static func width_for_value(text: String, height: float) -> float:
	var factor := height / 48.0
	var icon_right := 2.0 * factor + STYLE.ICON_SIZE * 0.28 + STYLE.ICON_SIZE
	var text_left := maxf(43.0 * factor, icon_right + 3.0)
	var font_size := roundi(24.0 * factor * STYLE.FONT_SCALE)
	var text_width := FONTS.regular_font().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	return ceilf(text_left + text_width + 4.0 + (STYLE.TRAILING_INSET + 2.0) * factor)

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
	style.bg_color = PALETTE.UI_BLUE_DARK
	style.set_corner_radius_all(roundi(plate_rect.size.y * 0.5))
	plate.add_theme_stylebox_override("panel", style)
	add_child(plate)
	var base_icon_position := Vector2(2.0 * factor + STYLE.ICON_SIZE * 0.28, (size.y - STYLE.ICON_SIZE) * 0.5)
	var icon_position := base_icon_position + STYLE.STAR_ICON_OFFSET + Vector2(-4, 0)
	var icon_size := Vector2.ONE * STYLE.ICON_SIZE
	var shadows := EXTRUSION._create_portrait_icon_extrusion_layers(self, icon_texture, "ScoreStarShadow", 0, STYLE.ICON_SHADOW_ALPHA)
	EXTRUSION._layout_portrait_icon_extrusion_layers(shadows, icon_position, icon_size)
	var icon := TextureRect.new()
	icon.name = "LeaderboardStarIcon"
	icon.z_index = 1
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = icon_texture
	icon.position = icon_position
	icon.size = icon_size
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon)
	var label := Label.new()
	label.name = "ScoreValue"
	var text_area := STYLE.value_rect(Rect2(Vector2.ZERO, size))
	var text_center := text_area.get_center().x
	# Use the HUD's authored text center; shrink symmetrically around it so
	# even long values cannot reach the overlapping star.
	var safe_left := maxf(text_area.position.x, icon.get_rect().end.x + 2.0)
	var half_width := maxf(1.0, minf(text_center - safe_left, text_area.end.x - text_center))
	label.position = Vector2(text_center - half_width, text_area.position.y)
	label.size = Vector2(half_width * 2.0, text_area.size.y)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.clip_text = true
	label.clip_contents = true
	label.add_theme_font_override("font", FONTS.regular_font())
	label.add_theme_color_override("font_color", Color.WHITE)
	TEXT.apply_regular_display(label)
	var font := FONTS.regular_font()
	var font_size := roundi(24.0 * factor * STYLE.FONT_SCALE)
	var effect := label.get_node("DisplayTextShaderEffect")
	# Center the visible glyph ink, including its outline and extrusion,
	# in the same text zone as the Home HUD.
	var ink := Rect2()
	var padding := Vector2.ZERO
	while true:
		label.add_theme_font_size_override("font_size", font_size)
		ink = text_ink_bounds(value, font, font_size)
		padding = effect.get_horizontal_ink_padding()
		if ink.size.x + padding.x + padding.y <= label.size.x or font_size <= 1:
			break
		font_size -= 1
	var advance := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var native_center_offset := (label.size.x - advance) * 0.5
	label.position.x += native_center_offset - floorf(native_center_offset) + advance * 0.5 - ink.get_center().x - (padding.y - padding.x) * 0.5
	label.text = value
	add_child(label)
