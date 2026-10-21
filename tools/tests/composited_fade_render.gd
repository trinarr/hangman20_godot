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
	await check_dynamic_ownership(stage)
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
	await check_reward_marker(main, stage, background_only)
	await check_unlock_progress(main, stage, background_only)
	await check_stage_reward(main)
	await check_level_summary_sequence(main)
	await check_sparkles(main)
	await check_icon_materials(stage, background_only)
	main.queue_free()
	await get_tree().process_frame
	print("COMPOSITED_FADE_RENDER checks=%d failures=%d" % [checks, failures])
	get_tree().quit(1 if failures else 0)

func check_stage_reward(main: Node) -> void:
	main._clear()
	for language: String in ["ru", "en"]:
		Database.load_languages(language, language)
		TranslationServer.set_locale(language)
		for ads: bool in [false, true]:
			var parent := Control.new()
			parent.size = get_viewport().get_visible_rect().size
			parent.theme = main.ui.theme
			# FlashStage controls already map stage coordinates to viewport pixels.
			add_child(parent)
			var component := preload("res://scripts/ui/portrait_stage_reward.gd").new()
			parent.add_child(component)
			component.build(parent, 15, Rect2(180, 380, 120, 120), ads)
			var chain := Control.new()
			parent.add_child(chain)
			var source := Control.new()
			chain.add_child(source)
			# Reproduce the real screen: its parent collects initially hidden visuals.
			FADE.set_opacity(parent, 0.0)
			FADE.set_opacity(parent, 1.0)
			component.begin_transition(chain, null, source, null, component.prize,
				null, null, component.prize_glow, component.prize_amount,
				component.action, component.collect, component.collect_hit)
			await get_tree().create_timer(3.0).timeout
			component.stop()
			component.action.call("_stop_single_attention_shine")
			component.action.set("button_disabled", false)
			if ads:
				var enabled := await frame()
				for repeat in range(3):
					component.action.set("button_disabled", true)
					check((await frame()).get_data() != enabled.get_data(), "Reward button visibly dims when disabled in " + language)
					component.action.set("button_disabled", false)
					check((await frame()).get_data() == enabled.get_data(), "Reward button restores icons and shadows after re-enabling in " + language)
			var visuals: Array[Control] = [component.prize, component.prize_glow,
				FADE.wrap(component.prize_amount), component.action]
			if ads:
				visuals.append(component.collect)
			for visual: Control in visuals:
				visual.hide()
			var empty := await frame()
			for visual: Control in visuals:
				visual.show()
				var opaque := await frame()
				var label := "Stage reward %s ads=%s %s" % [language, ads, visual.name]
				check(opaque.get_data() != empty.get_data(), label + " becomes visible after intro")
				var controller: Object = visual if visual.get_script() == FADE else FADE.branch(visual)
				var opacity: float = controller.get("opacity")
				controller.set("opacity", opacity * 0.5)
				var intermediate := await frame()
				check(intermediate.get_data() != empty.get_data() and intermediate.get_data() != opaque.get_data(), label + " has an intermediate visible state")
				controller.set("opacity", 0.0)
				check((await frame()).get_data() == empty.get_data(), label + " hides every pixel")
				controller.set("opacity", opacity)
				check((await frame()).get_data() == opaque.get_data(), label + " restores its visible state")
				visual.hide()
			parent.queue_free()
			await get_tree().process_frame

func check_sparkles(main: Node) -> void:
	main._clear()
	for chest: bool in [false, true]:
		var pack: Control = main._stage_reward_chest_transition(Rect2(150, 220, 180, 180)) if chest else main._stage_main_reward_coin_pack_transition(Rect2(150, 220, 180, 180))
		FADE.set_opacity(pack, 1.0)
		# Isolate the real glints from the prize art for pixel comparisons.
		for child: Node in pack.get_children():
			if child is CanvasItem:
				child.hide()
		main._play_reward_coin_sparkles(pack)
		var layer: Control = pack.get_meta("reward_coin_sparkle_layer")
		for sparkle: Node2D in layer.get_children():
			var animation: Tween = sparkle.get_meta("reward_sparkle_tween")
			animation.pause()
		var empty := await frame()
		for sparkle: Node2D in layer.get_children():
			var animation: Tween = sparkle.get_meta("reward_sparkle_tween")
			var fade: Control = sparkle.get_node("SparkleFade")
			var delay: float = float(sparkle.get_meta("reward_sparkle_delay")) * 1.3
			var rise: float = main.PORTRAIT_FINAL_REWARD_SPARKLE_FADE_IN_DURATION
			var fall: float = main.PORTRAIT_FINAL_REWARD_SPARKLE_FADE_OUT_DURATION
			var idle: float = main.PORTRAIT_FINAL_REWARD_SPARKLE_LOOP_DELAY
			for repeat in range(2):
				animation.custom_step(delay + rise + 0.00001)
				var shown := await frame()
				check(float(fade.get("opacity")) > 0.9 and shown.get_data() != empty.get_data(), "Every prize glint becomes visible on cycle %d chest=%s" % [repeat, chest])
				FADE.set_opacity(pack, 0.0)
				check((await frame()).get_data() == empty.get_data(), "Parent fade hides all glint pixels")
				FADE.set_opacity(pack, 1.0)
				check((await frame()).get_data() == shown.get_data(), "Parent fade restores glint pixels")
				animation.custom_step(fall + idle)
				check((await frame()).get_data() == empty.get_data(), "Glint fades completely between cycles")
			animation.kill()
		main._stop_reward_coin_sparkles(pack)
		check((await frame()).get_data() == empty.get_data(), "Stopping prize sparkles removes every glint")
		main._play_reward_coin_sparkles(pack)
		main._clear()
		await get_tree().process_frame
		check(!is_instance_valid(pack), "Leaving during restarted glints frees their owner")

func check_icon_materials(stage: Control, background_only: Image) -> void:
	for path: String in ["res://shaders/hint_icon_grayscale.gdshader", "res://scripts/ui/rounded_rect_texture_mask.gdshader", "res://shaders/letter_marker_reveal.gdshader"]:
		var holder := Control.new()
		holder.position = Vector2(20, 40)
		stage.add_child(holder)
		var icon := TextureRect.new()
		icon.size = Vector2(160, 160)
		icon.texture = preload("res://flash_assets/soft_currency_coin.png")
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		var material := ShaderMaterial.new()
		material.shader = load(path)
		if path.contains("mask"):
			material.set_shader_parameter("source_size", icon.size)
			material.set_shader_parameter("mask_rect", Vector4(20, 20, 120, 120))
			material.set_shader_parameter("corner_radius", 24.0)
			material.set_shader_parameter("opacity", 0.6)
		icon.material = material
		holder.add_child(icon)
		for mode in range(2 if path.contains("marker") else 1):
			if path.contains("marker"):
				material.set_shader_parameter("progress", 0.45)
				material.set_shader_parameter("reveal_mode", mode)
			var opaque := await frame()
			check(opaque.get_data() != background_only.get_data(), "Material retains visible authored effect: " + path)
			for alpha: float in [0.0, 0.5, 1.0]:
				holder.modulate.a = alpha
				check(pixel_error(await frame(), background_only, opaque, alpha) < 0.025, "Material respects inherited alpha %.2f: %s" % [alpha, path])
			var controller := FADE.branch(icon)
			for alpha: float in [0.0, 0.5, 1.0]:
				controller.set("opacity", alpha)
				check(pixel_error(await frame(), background_only, opaque, alpha) < 0.025, "Material respects branch alpha %.2f: %s" % [alpha, path])
		holder.queue_free()
		await frame()

func frozen_visual_pair(visual: Control) -> Array:
	# Pause both ordinary processing and tweens explicitly set to PAUSE_PROCESS.
	var animations: Array[Tween] = get_tree().get_processed_tweens()
	for animation: Tween in animations:
		animation.set_speed_scale(0.0)
	get_tree().paused = true
	visual.hide()
	var empty := await frame()
	visual.show()
	var shown := await frame()
	get_tree().paused = false
	for animation: Tween in animations:
		if animation.is_valid():
			animation.set_speed_scale(1.0)
	return [empty, shown]

func check_level_summary_sequence(main: Node) -> void:
	for language: String in ["ru", "en"]:
		Database.load_languages(language, language)
		TranslationServer.set_locale(language)
		GameState.current_mode = GameState.GameMode.SINGLE_PLAYER
		GameState.active_single_player_session = {}
		GameState.pending_single_player_reward = GameState._normalize_pending_single_player_reward({
			"language": language, "level_index": 4, "word_count": 3,
			"amount": 35, "stars_amount": 10})
		main.last_result_is_win = true
		main.single_player_active_level_index = 4
		main.single_player_active_word_slot = 2
		main.last_result_data = {"single_player_level_index": 4, "single_player_word_slot": 2,
			"single_player_total_count": 3, "single_player_level_completed": true, "single_player_level_summary_view": true}
		main._portrait_single_reward_resume_without_intro = false
		main._show_single_player_reward_chain_screen()
		var saw_flash := false
		var saw_plaque := false
		var deadline: int = Time.get_ticks_msec() + 8500
		while Time.get_ticks_msec() < deadline:
			await RenderingServer.frame_post_draw
			var chest: Control = main.content.find_child("LevelCompletionRewardPrize", true, false)
			var flash: Control = main._reward_chest_flash_overlay(chest)
			var plaque: Control = main.content.find_child("SinglePlayerLevelStarAward", true, false)
			if !saw_flash and flash.is_visible_in_tree() and flash.self_modulate.a * flash.modulate.a > 0.55 and chest.get_meta("reward_chest_closed_visual").visible:
				saw_flash = true
				var pair: Array = await frozen_visual_pair(flash)
				var bright_pixels := 0
				var rect: Rect2i = Rect2i(flash.get_global_rect()).intersection(Rect2i(Vector2i.ZERO, pair[1].get_size()))
				for y in range(rect.position.y, rect.end.y):
					for x in range(rect.position.x, rect.end.x):
						var before: Color = pair[0].get_pixel(x, y)
						var after: Color = pair[1].get_pixel(x, y)
						if after.r + after.g + after.b > before.r + before.g + before.b + 0.25:
							bright_pixels += 1
				check(bright_pixels > 100, "Closed chest whitens visibly before burst in " + language)
				var captures := OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
				if !captures.is_empty():
					pair[1].save_png(captures.path_join("level_summary_flash_" + language + ".png"))
			if !saw_plaque and plaque.is_visible_in_tree() and plaque.self_modulate.a * plaque.modulate.a > 0.8:
				saw_plaque = true
				var pair: Array = await frozen_visual_pair(plaque)
				check(pixel_error(pair[1], pair[0], pair[0], 0.0) > 0.1, "Earned-star plaque renders during actual payout in " + language)
				check(same_z_band(FADE.wrap(plaque.find_child("StarAwardLabel", true, false))._group), "Star caption retains grouped glyph layers in " + language)
				check(same_z_band(FADE.wrap(plaque.get_meta("level_star_value_label"))._group), "Changing star counter retains grouped glyph layers in " + language)
				var captures := OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
				if !captures.is_empty():
					pair[1].save_png(captures.path_join("level_summary_stars_" + language + ".png"))
		check(saw_flash, "Actual level summary reaches visible pressure flash in " + language)
		check(saw_plaque, "Actual level summary reaches visible earned-star plaque in " + language)
		var chest: Control = main.content.find_child("LevelCompletionRewardPrize", true, false)
		check(!main._reward_chest_flash_overlay(chest).visible, "White flash disappears after opening in " + language)
		for shadow: TextureRect in chest.get_meta("main_reward_icon_shadow_layers"):
			check(shadow.self_modulate.a > 0.99, "Chest shadow appears after white flash in " + language)
		main._clear()
		await get_tree().process_frame

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

func check_reward_marker(main: Node, stage: Control, background_only: Image) -> void:
	main._clear()
	var holder := Control.new()
	holder.position = Vector2(20, 100)
	stage.add_child(holder)
	var marker: Control = main._stage_single_player_reward_status_icon(holder, Rect2(0, 0, 100, 100), true, false)
	var controller := FADE.branch(holder)
	check(pixel_error(await frame(), background_only, background_only, 0.0) < 0.025, "Initially hidden reward marker stays hidden after ancestor collection")
	for repeat in range(2):
		main._animate_single_player_failed_reward_marker(marker)
		await get_tree().create_timer(1.0).timeout
		var revealed := await frame()
		check(pixel_error(revealed, background_only, background_only, 0.0) > 0.1, "Reward marker becomes visible after reveal %d" % repeat)
		controller.set("opacity", 0.5)
		check(pixel_error(await frame(), background_only, revealed, 0.5) < 0.025, "Revealed marker still follows parent opacity")
		controller.set("opacity", 0.0)
		check(pixel_error(await frame(), background_only, background_only, 0.0) < 0.025, "Closing the reward branch hides its revealed marker")
		controller.set("opacity", 1.0)
	holder.queue_free()
	await frame()

func check_unlock_progress(main: Node, stage: Control, background_only: Image) -> void:
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
	for language: String in ["ru", "en"]:
		TranslationServer.set_locale(language)
		progress = main._create_theme_unlock_progress(stage, Rect2(20, 100, 440, 100), {"total":10, "from":9, "to":10, "theme_id":Database.THEME_IDS[0], "unlocked":true})
		controller = FADE.branch(progress)
		await main._animate_theme_unlock_progress(progress)
		await frame()
		var count := progress.find_child("UnlockCount", true, false) as Label
		var count_fade := FADE.wrap(count)
		check(count.text == TranslationServer.translate("NEW_THEME_UNLOCKED"), "Completed progress shows the unlocked caption in " + language)
		check(count_fade.z_index == 4 and same_z_band(count_fade._group), "Unlocked caption keeps every glyph inside its composited Z band")
		var glow := progress.get_node("UnlockThemeGlow") as Control
		check(is_equal_approx(glow.self_modulate.a, 0.52), "Late-created unlock glow reaches its visible alpha")
		var lit := await frame()
		glow.hide()
		check(pixel_error(await frame(), lit, lit, 0.0) > 0.025, "Completed unlock glow contributes visible pixels")
		glow.show()
		controller.set("opacity", 0.0)
		check(pixel_error(await frame(), background_only, background_only, 0.0) < 0.025, "Completed caption and glow fully hide with their branch")
		controller.set("opacity", 1.0)
		check(is_equal_approx(glow.self_modulate.a, 0.52) and is_equal_approx(float(count_fade.get("opacity")), 1.0), "Reopening restores the unlocked caption and glow")
		progress.queue_free()
		await frame()

func check_dynamic_ownership(stage: Control) -> void:
	var holder := Control.new()
	stage.add_child(holder)
	var dimmed := Control.new()
	dimmed.modulate.a = 0.5
	holder.add_child(dimmed)
	var first := ColorRect.new()
	first.position = Vector2(20, 30)
	first.size = Vector2(60, 60)
	dimmed.add_child(first)
	var owner: Node = FADE.branch(holder)
	var late := ColorRect.new()
	late.position = Vector2(120, 30)
	late.size = first.size
	dimmed.add_child(late)
	var image := await frame()
	var scale_factor := stage.scale.x
	var point_a := Vector2i(Vector2(40, 50) * scale_factor)
	var point_b := Vector2i(Vector2(140, 50) * scale_factor)
	check(image.get_pixelv(point_a).is_equal_approx(image.get_pixelv(point_b)), "Late visual inherits dimmed intermediate ancestor on GPU")
	var reference := image.get_data()
	owner.refresh()
	owner.refresh()
	check((await frame()).get_data() == reference, "Repeated collection preserves original local alpha on GPU")
	owner.opacity = 0.0
	var hidden := await frame()
	var extra := ColorRect.new()
	extra.position = Vector2(220, 30)
	extra.size = first.size
	dimmed.add_child(extra)
	check((await frame()).get_data() == hidden.get_data(), "Late visual stays hidden under zero opacity")
	owner.opacity = 1.0
	image = await frame()
	check(image.get_pixelv(point_a).is_equal_approx(image.get_pixelv(Vector2i(Vector2(240, 50) * scale_factor))), "Late visual restores intermediate ancestor alpha")
	var outside := Control.new()
	stage.add_child(outside)
	late.reparent(outside, false)
	var moved := await frame()
	owner.opacity = 0.0
	image = await frame()
	check(image.get_pixelv(point_b).is_equal_approx(moved.get_pixelv(point_b)), "Old owner no longer fades reparented visual pixels")
	var destination: Node = FADE.branch(outside)
	destination.opacity = 0.5
	image = await frame()
	check(image.get_pixelv(point_b).is_equal_approx(moved.get_pixelv(point_a)), "New owner applies alpha without previous ancestor multiplier")
	var nested: Node = FADE.branch(late)
	nested.opacity = 0.5
	var nested_reference := await frame()
	late.reparent(dimmed, false)
	await frame()
	owner.opacity = 1.0
	check((await frame()).get_pixelv(point_b).is_equal_approx(nested_reference.get_pixelv(point_b)), "Nested controller transfers between equal-alpha parents without double fading")
	late.reparent(outside, false)
	await frame()
	owner.opacity = 0.0
	check((await frame()).get_pixelv(point_b).is_equal_approx(nested_reference.get_pixelv(point_b)), "Old branch cannot overwrite transferred nested controller")
	destination.opacity = 0.0
	check((await frame()).get_data() == hidden.get_data(), "Moved branch fully disappears at zero opacity")
	holder.free()
	outside.free()
	await frame()
