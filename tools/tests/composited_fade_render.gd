extends Node
## GPU regression: layered MSDF text must fade as one image, without darkening.
const FADE = preload("res://scripts/ui/composited_fade.gd")
const FONTS = preload("res://scripts/ui/ui_fonts.gd")
const STYLE = preload("res://scripts/ui/button_text_style.gd")
const PALETTE = preload("res://scripts/ui/ui_palette.gd")
var failures := 0
var checks := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if !ok:
		failures += 1
		push_error(message)

func _ready() -> void:
	run.call_deferred()

func frame() -> Image:
	for index in range(4):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()

func pixel_error(actual: Image, first: Image, second: Image, alpha: float) -> float:
	var maximum_error := 0.0
	for y in range(actual.get_height()):
		for x in range(actual.get_width()):
			var expected := first.get_pixel(x, y).lerp(second.get_pixel(x, y), alpha)
			var value := actual.get_pixel(x, y)
			maximum_error = maxf(maximum_error, maxf(absf(value.r - expected.r), maxf(absf(value.g - expected.g), absf(value.b - expected.b))))
	return maximum_error

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Composited fade regression requires a real renderer")
		get_tree().quit(1)
		return
	var background := ColorRect.new()
	background.size = get_viewport().get_visible_rect().size
	background.color = PALETTE.UI_BLUE
	add_child(background)
	var stage := Control.new()
	stage.scale = Vector2.ONE * (get_viewport().get_visible_rect().size.x / 480.0)
	add_child(stage)
	var fade := FADE.new()
	fade.position = Vector2(20, 40)
	fade.size = Vector2(440, 300)
	stage.add_child(fade)
	for index in range(4):
		var label := Label.new()
		label.position = Vector2(0, index * 65)
		label.size = Vector2(440, 60)
		label.text = ["МОЛНИЕНОСНО!", "+5", "LIGHTNING FAST!", "-1"][index]
		label.add_theme_font_override("font", FONTS.button_font() if index % 2 == 0 else FONTS.display_font())
		label.add_theme_font_size_override("font_size", 34)
		label.add_theme_color_override("font_color", PALETTE.SUCCESS_SOFT if index % 2 == 0 else Color.WHITE)
		fade.add_visual(label)
		STYLE.apply_display(label)
	var opaque := await frame()
	fade.opacity = 0.0
	var empty := await frame()
	var background_only := Image.create(empty.get_width(), empty.get_height(), false, empty.get_format())
	background_only.fill(background.color)
	check(pixel_error(empty, background_only, background_only, 0.0) < 0.025, "Zero opacity removes every text layer, including raised outline and shadows")
	check(pixel_error(opaque, background_only, background_only, 0.0) > 0.1, "Opaque reference contains visible text")
	# Reproduce the old per-layer fade with the same glyphs and materials.
	var ungrouped := Control.new()
	ungrouped.position = fade.position
	stage.add_child(ungrouped)
	for visual in fade._group.get_children():
		visual.reparent(ungrouped, false)
	check(pixel_error(await frame(), empty, opaque, 1.0) < 0.025, "Grouping preserves the fully opaque appearance")
	ungrouped.modulate.a = 0.5
	check(pixel_error(await frame(), empty, opaque, 0.5) > 0.025, "Regression reproduces darkening with separate layer opacity")
	for visual in ungrouped.get_children():
		visual.reparent(fade._group, false)
	ungrouped.queue_free()
	for alpha: float in [0.25, 0.5, 0.75]:
		fade.opacity = alpha
		var faded := await frame()
		var maximum_error := pixel_error(faded, empty, opaque, alpha)
		check(maximum_error < 0.025, "Composite alpha %.2f preserves text color: maximum pixel error %.4f" % [alpha, maximum_error])
	fade.opacity = 1.0
	check((await frame()).get_data() == opaque.get_data(), "Repeated fade restores the original appearance")
	var fade_tween := fade.create_tween()
	fade_tween.tween_property(fade, "opacity", 0.0, 1.0)
	fade_tween.pause()
	for step in range(1, 6):
		fade_tween.custom_step(0.2)
		var expected_alpha := maxf(0.0, 1.0 - step * 0.2)
		var animated := await frame()
		check(is_equal_approx(fade.opacity, expected_alpha), "Tween advances opacity at step %d" % step)
		check(pixel_error(animated, background_only, opaque, expected_alpha) < 0.025, "Tween fades visible pixels instead of waiting for removal at step %d" % step)
	fade_tween.kill()
	fade.hide()
	await check_wrapped_label(stage, background_only)
	await check_branch(stage, background_only)
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	GameState.guided_onboarding_completed = true
	GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
	add_child(main)
	for language: String in ["ru", "en"]:
		Database.load_languages(language, language)
		TranslationServer.set_locale(language)
		main._start_quiz_theme(0)
		await get_tree().create_timer(2.0).timeout
		main._play_quiz_correct_question_feedback(main.PORTRAIT_QUIZ_SPEED_LIGHTNING, 0, 0)
		var feedback: Node = main.content.find_child("QuizCorrectFeedback", true, false)
		check(is_instance_valid(feedback) and feedback.has_node("QuizCorrectFeedbackFade/CompositedVisuals"), "Correct feedback uses group opacity in " + language)
		check(feedback.has_node("QuizFastAnswerReward/CompositedVisuals"), "Reward text and star share group opacity in " + language)
		await get_tree().process_frame
		check(same_z_band(feedback.get_node("QuizCorrectFeedbackFade/CompositedVisuals")), "Correct feedback retains all glyph layers inside the group in " + language)
		check(same_z_band(feedback.get_node("QuizFastAnswerReward/CompositedVisuals")), "Late-created star and text layers stay inside the group in " + language)
		await get_tree().create_timer(3.0).timeout
		check(main.content.find_child("QuizCorrectFeedback", true, false) == null, "Correct feedback completes and releases its group in " + language)
		main._play_quiz_wrong_question_feedback()
		await get_tree().create_timer(0.1).timeout
		check(main.content.find_child("QuizWrongFeedbackVisual", true, false).has_node("CompositedVisuals"), "Heart loss uses group opacity in " + language)
		check(same_z_band(main.content.find_child("QuizWrongFeedbackVisual", true, false).get_node("CompositedVisuals")), "Heart face and extrusion stay inside the group in " + language)
		main.show_menu()
		await get_tree().create_timer(0.5).timeout
	await check_unlock_progress(main, stage)
	main.queue_free()
	await get_tree().process_frame
	print("COMPOSITED_FADE_RENDER checks=%d failures=%d" % [checks, failures])
	get_tree().quit(1 if failures else 0)

func same_z_band(root: Node) -> bool:
	for child: Node in root.get_children():
		if child is CanvasItem and (child.z_index != 0 or !child.z_as_relative):
			return false
		if !same_z_band(child):
			return false
	return true

func check_wrapped_label(stage: Control, background_only: Image) -> void:
	var holder := Control.new()
	holder.position = Vector2(20, 360)
	holder.size = Vector2(300, 80)
	stage.add_child(holder)
	var label := Label.new()
	holder.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.offset_left = 8
	label.offset_right = -8
	label.text = "НАГРАДА / REWARD x200"
	label.add_theme_font_override("font", FONTS.display_font())
	label.add_theme_font_size_override("font_size", 30)
	STYLE.apply_display(label)
	var original := await frame()
	var original_rect := label.get_global_rect()
	var wrapped := FADE.wrap(label)
	check(FADE.wrap(label) == wrapped, "Repeated wrapping reuses the same opacity owner")
	check(label.get_global_rect().is_equal_approx(original_rect), "Wrapping preserves stage position and anchor offsets")
	check(pixel_error(await frame(), original, original, 0.0) < 0.025, "Wrapping preserves opaque glyph appearance and layout")
	for alpha: float in [0.0, 0.25, 0.5, 0.75, 1.0]:
		wrapped.set("opacity", alpha)
		check(pixel_error(await frame(), background_only, original, alpha) < 0.025, "Wrapped label alpha %.2f fades all glyph layers" % alpha)
	holder.size.x += 40
	await frame()
	check(is_equal_approx(label.size.x, holder.size.x - 16) and is_equal_approx(label.position.x, 8), "Wrapped full-rect label follows parent resizing")
	label.position.y = 10
	label.scale = Vector2.ONE * 0.9
	check(is_equal_approx(label.position.y, 10) and label.scale.is_equal_approx(Vector2.ONE * 0.9), "Existing label position/scale animations remain available")
	holder.queue_free()
	await get_tree().process_frame

func check_branch(stage: Control, background_only: Image) -> void:
	var holder := Control.new()
	holder.position = Vector2(20, 40)
	holder.size = Vector2(440, 300)
	stage.add_child(holder)
	var label := Label.new()
	label.text = "НАГРАДА / REWARD"
	label.position.y = 90
	label.add_theme_font_override("font", FONTS.display_font())
	label.add_theme_font_size_override("font_size", 30)
	holder.add_child(label)
	STYLE.apply_display(label)
	var clip := Control.new()
	clip.size = Vector2(60, 40)
	clip.clip_contents = true
	holder.add_child(clip)
	var fill := ColorRect.new()
	fill.size = Vector2(150, 40)
	fill.color = Color.GREEN
	clip.add_child(fill)
	var original := await frame()
	var controller := FADE.branch(holder)
	check(holder.get_parent() == stage and clip.get_parent() == holder and clip.clip_contents, "Branch preserves layout/input roots and clipping")
	check(pixel_error(await frame(), original, original, 0.0) < 0.025, "Branch preserves opaque text and clipped fill")
	for alpha: float in [0.0, 0.25, 0.5, 0.75, 1.0]:
		controller.set("opacity", alpha)
		check(pixel_error(await frame(), background_only, original, alpha) < 0.025, "Branch alpha %.2f fades text and clipped fill" % alpha)
	FADE.set_opacity(label, 0.5)
	controller.set("opacity", 0.5)
	check(is_equal_approx(FADE.get_opacity(label), 0.5) and is_equal_approx(FADE.wrap(label)._group.self_modulate.a, 0.25), "Independent child and parent opacity multiply without overwriting each other")
	var nested := FADE.branch(clip)
	nested.set("opacity", 0.5)
	check(is_equal_approx(fill.self_modulate.a, 0.25), "Creating a nested controller during a fade preserves both alpha factors")
	nested.set("opacity", 1.0)
	controller.set("opacity", 1.0)
	FADE.set_opacity(label, 1.0)
	controller.set("opacity", 0.0)
	var late := Label.new()
	late.text = "ПОЗДНИЙ / LATE"
	late.position.y = 160
	holder.add_child(late)
	STYLE.apply_display(late)
	check(pixel_error(await frame(), background_only, background_only, 0.0) < 0.025, "Late-created text inherits a hidden branch after ready")
	controller.set("opacity", 1.0)
	check(FADE.wrap(late)._group.self_modulate.a == 1.0, "Reopening restores late-created text")
	holder.queue_free()
	await frame()
	var button := StageLongButton.new()
	button.use_stage_layout = false
	button.stage_rect = Rect2(20, 40, 400, 70)
	stage.add_child(button)
	button.configure("ПРОДОЛЖИТЬ / CONTINUE", 24)
	original = await frame()
	var parent := button.get_parent()
	var mouse_filter := button.mouse_filter
	controller = FADE.branch(button)
	check(button.get_parent() == parent and button.mouse_filter == mouse_filter, "Action button retains input and layout ownership")
	check(pixel_error(await frame(), original, original, 0.0) < 0.025, "Action button preserves its opaque appearance")
	controller.set("opacity", 0.0)
	check(pixel_error(await frame(), background_only, background_only, 0.0) < 0.025, "Action button fully hides its shader background and every glyph layer")
	controller.set("opacity", 1.0)
	button.visual_scale = Vector2.ONE * 0.94
	button.configure("ПРОДОЛЖИТЬ / CONTINUE", 24)
	await frame()
	check(same_z_band(FADE.wrap(button._label)._group), "Button reconfiguration retains grouped glyph Z")
	check(is_equal_approx(button._label.get_global_transform().get_scale().x, stage.scale.x * 0.94), "Button press scales wrapped text exactly once")
	button.visual_scale = Vector2.ONE
	check(pixel_error(await frame(), original, original, 0.0) < 0.025, "Action button restores appearance after press and repeated opening")
	button.queue_free()
	await frame()
	var answer := Button.new()
	answer.position = Vector2(20, 40)
	answer.size = Vector2(400, 70)
	answer.text = "50/50 ОТВЕТ / ANSWER"
	answer.add_theme_font_override("font", FONTS.button_font())
	stage.add_child(answer)
	original = await frame()
	controller = FADE.branch(answer)
	for alpha: float in [0.0, 0.5, 1.0]:
		controller.set("opacity", alpha)
		check(pixel_error(await frame(), background_only, original, alpha) < 0.025, "Native answer button alpha %.2f preserves text and panel" % alpha)
	FADE.wrap(answer).queue_free()
	await frame()

func check_unlock_progress(main: Node, stage: Control) -> void:
	main._clear()
	var progress: Control = main._create_theme_unlock_progress(stage, Rect2(20, 100, 440, 100), {"total":10, "from":2, "to":5, "theme_id":Database.THEME_IDS[0]})
	var mask: Control = progress.find_child("UnlockBarFillMask", true, false)
	var mask_parent := mask.get_parent()
	var controller := FADE.branch(progress)
	main._set_theme_unlock_bar_value(5.0, progress)
	await frame()
	check(mask.clip_contents and mask.get_parent() == mask_parent, "Unlock progress retains its clipping hierarchy")
	check(progress.find_child("UnlockCount", true, false).text.contains("5"), "Unlock progress still updates wrapped count text")
	controller.set("opacity", 0.0)
	await frame()
	check(FADE.wrap(progress.find_child("UnlockCount", true, false))._group.self_modulate.a == 0.0, "Unlock count hides with its progress branch")
	controller.set("opacity", 1.0)
	progress.queue_free()
	await frame()
