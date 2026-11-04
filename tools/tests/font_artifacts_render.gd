extends Node
## Real GPU regression: MSDF glyphs must not paint blocks outside raster outlines.
const FONTS = preload("res://scripts/ui/ui_fonts.gd")
var failures := 0
var checks := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if !ok:
		failures += 1
		push_error(message)
func _ready() -> void:
	run.call_deferred()
func _process(_delta: float) -> void:
	if OS.get_environment("HANGMAN_TEST_HIDE_WINDOW") == "1":
		RenderingServer.force_draw(false)
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
	var dimensions := OS.get_environment("HANGMAN_PROFILE_PREVIEW_SIZE").split("x")
	if dimensions.size() == 2:
		get_window().min_size = Vector2i(int(dimensions[0]), int(dimensions[1]))
		get_window().size = get_window().min_size
	var language := OS.get_environment("HANGMAN_PROFILE_PREVIEW_LANGUAGE")
	var characters: String = ("АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя" if language == "ru" else "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz") + "0123456789"
	var background := ColorRect.new()
	background.size = get_viewport().get_visible_rect().size
	background.color = Color.BLACK
	add_child(background)
	var profiles: Array[Font] = [FONTS.button_font(), FONTS.regular_font(), FONTS.heavy_display_font()]
	for width in range(int(FONTS.ROBOTO_FLEX_DISPLAY_MIN_WIDTH), int(FONTS.ROBOTO_FLEX_DISPLAY_WIDTH) + 1):
		profiles.append(FONTS.display_font_with_width(width))
	for index in range(profiles.size()):
		for font_size: int in [32, 48]:
			await check_profile(profiles[index], characters, font_size, 4 if font_size == 48 else 0, "%s_%d_%d" % [language, index, font_size])
	check(FONTS.button_font().spacing_glyph == 0, "Button captions retain native glyph spacing")
	print("FONT_ARTIFACTS_RENDER checks=", checks, " profiles=", profiles.size(), " failures=", failures)
	get_tree().quit(1 if failures else 0)

func check_profile(font: FontVariation, characters: String, font_size: int, outline: int, name: String) -> void:
	var labels: Array[Label] = []
	var bitmap := font.duplicate() as FontVariation
	var source := font.base_font.duplicate() as FontFile
	source.multichannel_signed_distance_field = false
	source.oversampling = 3.0
	source.hinting = TextServer.HINTING_NONE
	bitmap.base_font = source
	for index in range(characters.length()):
		var label := Label.new()
		label.position = Vector2(12 + (index % 14) * 64, 8 + (index / 14) * 96)
		label.size = Vector2(60, 88)
		label.text = characters[index]
		label.add_theme_font_override("font", font)
		label.add_theme_font_size_override("font_size", font_size)
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_color_override("font_outline_color", Color.WHITE)
		label.add_theme_constant_override("outline_size", outline)
		add_child(label)
		labels.append(label)
	var msdf := await frame()
	var directory := OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
	if !directory.is_empty():
		msdf.save_png(directory.path_join("font_" + name + ".png"))
	for label: Label in labels:
		label.add_theme_font_override("font", bitmap)
	var bitmap_image := await frame()
	var outside := 0
	var ink := 0
	var pixel_scale: float = float(msdf.get_width()) / get_viewport().get_visible_rect().size.x
	var bottom: int = mini(msdf.get_height() - 3, ceili((8 + ceili(float(characters.length()) / 14) * 96) * pixel_scale))
	for y in range(3, bottom):
		for x in range(3, msdf.get_width()-3):
			if msdf.get_pixel(x,y).r > 0.8:
				ink += 1
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
	check(ink > 0 and outside <= 64, "MSDF fill/outline matches raster reference %s: ink=%d unexpected=%d" % [name, ink, outside])
	for label: Label in labels:
		label.queue_free()
	await get_tree().process_frame
