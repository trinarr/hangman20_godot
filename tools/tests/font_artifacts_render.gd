extends Node
## Real GPU regression: MSDF glyphs must not paint blocks outside raster outlines.
const FONTS = preload("res://scripts/ui/ui_fonts.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if !ok:
		failures += 1
		push_error(message)
func _ready() -> void:
	run.call_deferred()
func frame() -> Image:
	for _i in range(4):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()
func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Font artifact regression requires a real display")
		get_tree().quit(1)
		return
	var background := ColorRect.new()
	background.size = get_viewport().get_visible_rect().size
	background.color = Color.BLACK
	add_child(background)
	var labels: Array[Label] = []
	var references: Array[Font] = []
	var characters := "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
	var row := 0
	for font: FontVariation in [FONTS.button_font(), FONTS.display_font(), FONTS.regular_font()]:
		var bitmap := font.duplicate() as FontVariation
		var source := font.base_font.duplicate() as FontFile
		source.multichannel_signed_distance_field = false
		source.oversampling = 3.0
		source.hinting = TextServer.HINTING_NONE
		bitmap.base_font = source
		var column := 0
		for character in characters:
			var label := Label.new()
			label.position = Vector2(12 + column * 46, 8 + row * 76)
			label.size = Vector2(44, 64)
			label.text = character
			label.add_theme_font_override("font", font)
			label.add_theme_font_size_override("font_size", 32)
			label.add_theme_color_override("font_color", Color.WHITE)
			add_child(label)
			labels.append(label)
			references.append(bitmap)
			column += 1
			if column == 20:
				column = 0
				row += 1
		row += 1
	var msdf := await frame()
	for index in range(labels.size()):
		labels[index].add_theme_font_override("font", references[index])
	var bitmap_image := await frame()
	var outside := 0
	for y in range(3, msdf.get_height()-3):
		for x in range(3, msdf.get_width()-3):
			if msdf.get_pixel(x,y).r < 0.8 or bitmap_image.get_pixel(x,y).r > 0.05:
				continue
			var near_outline := false
			for dy in range(-3,4):
				for dx in range(-3,4):
					if bitmap_image.get_pixel(x+dx,y+dy).r > 0.05:
						near_outline = true
						break
				if near_outline:
					break
			if !near_outline:
				outside += 1
	check(outside <= 64, "MSDF has no spurious blocks beyond reference glyph outlines: %d pixels" % outside)
	check(FONTS.button_font().spacing_glyph == 0, "Button captions retain native glyph spacing")
	print("FONT_ARTIFACTS_RENDER glyphs=",labels.size()," unexpected_pixels=",outside," failures=",failures)
	get_tree().quit(1 if failures else 0)
