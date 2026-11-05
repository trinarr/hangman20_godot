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
	for width: int in FONTS.ROBOTO_FLEX_DISPLAY_WIDTHS:
		profiles.append(FONTS.display_font_with_width(width))
	for index in range(profiles.size()):
		for font_size: int in [32, 48]:
			await check_profile(profiles[index], characters, font_size, 4 if font_size == 48 else 0, "%s_%d_%d" % [language, index, font_size])
	check(FONTS.button_font().spacing_glyph == 0, "Button captions retain native glyph spacing")
	await check_input_profiles()
	print("FONT_ARTIFACTS_RENDER checks=", checks, " profiles=", profiles.size(), " failures=", failures)
	get_tree().quit(1 if failures else 0)

func check_input_profiles() -> void:
	var warnings_before: int = FONTS._msdf_warning_paths.size()
	var cases := [
		["АВАРИЙНОЕ ОСВЕЩЕНИЕ", 40, Vector2(464, 72), 20, 32],
		["WORD", 40, Vector2(464, 72), 20, 35],
		["W".repeat(20), 40, Vector2(464, 72), 20, 30],
		["Ш".repeat(18), 31, Vector2(344, 62.4), 18, 30],
		["Player 123", 31, Vector2(344, 62.4), 18, 35],
	]
	for index in range(cases.size()):
		var sample: Array = cases[index]
		var input := preload("res://scripts/ui/stage_word_input.gd").new()
		input.stage_rect = Rect2(Vector2(8, 200), sample[2])
		add_child(input)
		input.configure(sample[0], sample[3], sample[1])
		await frame()
		var label: Label = input._display_label
		var font: Font = label.get_theme_font("font")
		check(font == FONTS.display_font_with_width(sample[4]), "Input selects the intended sparse MSDF profile: case %d" % index)
		var measured := font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x
		check(measured <= input.size.x - 16.0, "Word or nickname fits its authored field: case %d" % index)
		input.play_word_bounce()
		var first: Tween = input._word_bounce_tweens[0]
		first.pause()
		check(label.scale.is_equal_approx(Vector2.ONE * 0.58), "Input bounce starts at its authored scale")
		first.custom_step(0.09)
		check(label.scale.x > 0.58 and label.scale.y < 1.24 and label.get_theme_font("font") == font, "Input bounce progresses without switching font")
		var image := await frame()
		var directory := OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
		if !directory.is_empty():
			image.save_png(directory.path_join("input_profile_%s_%d_%dx%d.png" % [OS.get_environment("HANGMAN_PROFILE_PREVIEW_LANGUAGE"), index, get_window().size.x, get_window().size.y]))
		input.play_word_bounce()
		check(!first.is_valid() and input._word_bounce_tweens.size() == 1, "Repeated input bounce cancels the old tween")
		var restarted: Tween = input._word_bounce_tweens[0]
		restarted.pause()
		restarted.custom_step(0.43)
		check(label.scale.is_equal_approx(Vector2.ONE) and label.get_theme_font("font") == font, "Input bounce completes at full scale with the same font")
		input.play_word_bounce()
		input.queue_free()
		await frame()
		check(!is_instance_valid(input), "Leaving the input during a bounce releases its owner")
	check(FONTS._msdf_warning_paths.size() == warnings_before, "Word and nickname fitting never requests a removed MSDF profile")

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
