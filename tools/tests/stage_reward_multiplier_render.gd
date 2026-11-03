extends "res://tools/tests/rewarded_stage_fixture.gd"
## GPU layout matrix; no native advertisement requests are started.

func check_track_fade() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(420, 160)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var background := ColorRect.new()
	background.color = preload("res://scripts/ui/ui_palette.gd").UI_BLUE
	background.size = Vector2(viewport.size)
	viewport.add_child(background)
	var meter := preload("res://scripts/ui/stage_reward_multiplier.gd").new()
	meter.position = Vector2(12, 10)
	meter.size = Vector2(396, 94.6)
	viewport.add_child(meter)
	meter.build(null)
	# Isolate the new shader. Text and pointer use separate fade surfaces and
	# overlap the plaque, so their combined half-opacity is not a flat image mix.
	for label: Label in meter._labels:
		label.hide()
	meter._pointer.hide()
	var fade: Node = preload("res://scripts/ui/composited_fade.gd").branch(meter)
	await frames()
	await RenderingServer.frame_post_draw
	var original: Image = viewport.get_texture().get_image()
	for opacity: float in [0.5, 0.0, 1.0]:
		fade.set("opacity", opacity)
		await frames()
		await RenderingServer.frame_post_draw
		var current: Image = viewport.get_texture().get_image()
		var error: float = 0.0
		for y in range(current.get_height()):
			for x in range(current.get_width()):
				var expected: Color = background.color.lerp(original.get_pixel(x, y), opacity)
				var actual: Color = current.get_pixel(x, y)
				error = maxf(error, maxf(absf(actual.r - expected.r), maxf(absf(actual.g - expected.g), absf(actual.b - expected.b))))
		check(error < 0.03, "Track and fill shader preserves incoming opacity %.1f (error %.3f)" % [opacity, error])
	viewport.queue_free()
	await frames()

func capture(tag: String) -> void:
	var directory := OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var screenshot: Image = get_viewport().get_texture().get_image()
	if !directory.is_empty():
		screenshot.save_png(directory.path_join(tag + ".png"))
	if tag.begins_with("stage_multiplier_") and tag.ends_with("_5"):
		check(ui._portrait_stage_reward.prize_amount.text == "x25", "Large prize retains base amount while pointer selects x3: " + tag)
		var frame: Control = ui._portrait_stage_reward.multiplier_meter.get_child(0)
		var rect: Rect2 = frame.get_global_rect()
		var ratio: Vector2 = Vector2(screenshot.get_size()) / get_viewport().get_visible_rect().size
		var transform: Transform2D = frame.get_global_transform_with_canvas()
		var render_scale := Vector2((transform.x * ratio).length(), (transform.y * ratio).length())
		# Compare both curved ends, including the phone resolution from the report.
		for fraction: float in [0.35, 0.5, 0.65]:
			var row: int = floori((rect.position.y + rect.size.y * fraction) * ratio.y)
			var rims: Array[int] = []
			for side in range(2):
				var outer: int = -1
				var inner: int = -1
				for offset in range(64):
					var x: int = floori(rect.position.x * ratio.x) + offset if side == 0 else ceili(rect.end.x * ratio.x) - 1 - offset
					var color: Color = screenshot.get_pixel(x, row)
					if outer < 0 and color.r < 0.28 and color.g < 0.33 and color.b > 0.4 and color.b < 0.6:
						outer = offset
					if color.r > 0.7 and color.g < 0.5 and color.b < 0.5:
						inner = offset
						break
				check(outer >= 0 and inner > outer, "Both rounded ends expose a measurable dark rim: " + tag)
				rims.append(inner - outer)
			check(absi(rims[0] - rims[1]) <= 1, "Multiplier rim is horizontally symmetric at %.2f (%d/%d): " % [fraction, rims[0], rims[1]] + tag)
		var sample: Vector2i = Vector2i((rect.position + Vector2(0.0, rect.size.y * 0.5)) * ratio)
		var first_fill_pixel: int = -1
		for offset in range(16):
			var color: Color = screenshot.get_pixel(sample.x + offset, sample.y)
			if color.r > 0.7 and color.g < 0.5 and color.b < 0.5:
				first_fill_pixel = offset
				break
		check(first_fill_pixel >= 0 and absf(float(first_fill_pixel) - 2.5 * render_scale.x) <= ceili(render_scale.x * 0.5) + 1, "Multiplier track side scales from 2.5 logical units (%d): " % first_fill_pixel + tag)
		var top: Vector2i = Vector2i((rect.position + Vector2(rect.size.x * 0.3, 0.0)) * ratio)
		var bottom: Vector2i = Vector2i((rect.position + Vector2(rect.size.x * 0.3, rect.size.y)) * ratio) - Vector2i(0, 1)
		for edge: int in range(2):
			var thickness: int = -1
			for offset in range(16):
				var point: Vector2i = top + Vector2i(0, offset) if edge == 0 else bottom - Vector2i(0, offset)
				var color: Color = screenshot.get_pixelv(point)
				if color.r > 0.7 and color.g > 0.4 and color.b < 0.65:
					thickness = offset
					break
			var expected: float = (2.5 if edge == 0 else 4.0) * render_scale.y
			check(thickness >= 0 and absf(float(thickness) - expected) <= ceili(render_scale.y * 0.5) + 1, "Track top/bottom scale from logical units (%d/%d): " % [edge, thickness] + tag)


func check_moving_center(meter: Control, tag: String) -> void:
	var previous_time_scale: float = Engine.time_scale
	Engine.time_scale = 1.0
	meter.set_cursor(0.1)
	await get_tree().create_timer(0.12).timeout
	meter._elapsed = 0.0
	meter.running = true
	var duration: float = GameDesignConfig.get_float("timings.animations.stage_reward_multiplier.traverse_seconds") * 0.8
	var pause: float = GameDesignConfig.get_float("timings.animations.stage_reward_multiplier.endpoint_pause_seconds")
	var previous_cursor: float = meter.cursor
	var previous_scale: float = meter._labels[2].scale.x
	var samples: Array = []
	var directions: Array[bool] = [false, false]
	var shrink_after_exit: Array[bool] = [false, false]
	while meter._elapsed < 2.0 * (duration + pause):
		await get_tree().process_frame
		var current_cursor: float = meter.cursor
		var current_scale: float = meter._labels[2].scale.x
		var direction: int = 0 if meter._elapsed < duration + 2.0 * pause else 1
		var inside: bool = current_cursor >= 0.4 and current_cursor < 0.6
		var was_inside: bool = previous_cursor >= 0.4 and previous_cursor < 0.6
		if inside and was_inside:
			directions[direction] = true
			check(current_scale + 0.00001 >= previous_scale, "Moving x3 never shrinks inside its sector: " + tag)
		if !inside and current_scale < previous_scale - 0.00001:
			shrink_after_exit[direction] = true
		if inside or was_inside:
			samples.append({"cursor": current_cursor, "scale": current_scale, "direction": direction})
		previous_cursor = current_cursor
		previous_scale = current_scale
	meter.running = false
	check(directions[0] and directions[1], "Continuous movement samples x3 in both directions: " + tag)
	check(shrink_after_exit[0] and shrink_after_exit[1], "Moving x3 shrinks after leaving the sector in both directions: " + tag)
	var directory: String = OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
	if !directory.is_empty():
		var output := FileAccess.open(directory.path_join(tag + ".json"), FileAccess.WRITE)
		output.store_string(JSON.stringify(samples))
	Engine.time_scale = previous_time_scale

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Stage reward multiplier rendering requires a GPU")
		get_tree().quit(1)
		return
	Engine.time_scale = 8.0
	GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
	GameState.guided_onboarding_completed = true
	GameState.ad_personalization_choice = GameState.AdPersonalizationChoice.ACCEPTED
	await check_track_fade()
	for dimensions: Vector2i in [Vector2i(960, 1600), Vector2i(690, 1536), Vector2i(1080, 1920), Vector2i(1200, 2670)]:
		get_window().min_size = dimensions
		get_window().size = dimensions
		for language: String in ["ru", "en"]:
			Database.load_languages(language, language)
			await fixture(4)
			check(!is_instance_valid(ui._portrait_stage_reward.multiplier_meter), "Early reward has no multiplier meter")
			await capture("stage_double_%dx%d_%s" % [dimensions.x, dimensions.y, language])
			await fixture()
			var meter: Control = ui._portrait_stage_reward.multiplier_meter
			var label_transition: float = GameDesignConfig.get_float("timings.animations.stage_reward_multiplier.label_transition_seconds")
			for position: float in [0.1, 0.3, 0.5, 0.7, 0.9]:
				meter.set_cursor(position)
				await get_tree().create_timer(label_transition + 0.02).timeout
				await capture("stage_multiplier_%dx%d_%s_%d" % [dimensions.x, dimensions.y, language, roundi(position * 10)])
			meter.set_cursor(0.399)
			meter._label_tween.pause()
			meter._label_tween.custom_step(label_transition)
			meter.set_cursor(0.4)
			meter._label_tween.pause()
			await capture("stage_zone_enter_%dx%d_%s" % [dimensions.x, dimensions.y, language])
			meter._label_tween.custom_step(label_transition * 0.5)
			check(meter._labels[2].scale.x > 1.0 and meter._labels[2].scale.x < 28.0 / 24.0, "GPU frame captures intermediate growth at sector boundary")
			await capture("stage_zone_mid_%dx%d_%s" % [dimensions.x, dimensions.y, language])
			meter._label_tween.custom_step(label_transition * 0.5)
			check(is_equal_approx(meter._labels[2].scale.x, 28.0 / 24.0), "GPU frame captures full scale at sector boundary")
			await capture("stage_zone_full_%dx%d_%s" % [dimensions.x, dimensions.y, language])
			await check_moving_center(meter, "stage_moving_center_%dx%d_%s" % [dimensions.x, dimensions.y, language])
			check(native.shows == 0 and !ads._rewarded_pending_show and !ui._portrait_final_reward_waiting_for_ad, "Layout matrix never requests an advertisement")
	ui.queue_free()
	ads.queue_free()
	await frames()
	print("STAGE_REWARD_MULTIPLIER_RENDER ", JSON.stringify({"checks": checks, "failures": failures}))
	get_tree().quit(0 if failures.is_empty() else 1)
