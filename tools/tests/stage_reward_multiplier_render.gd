extends "res://tools/tests/rewarded_stage_fixture.gd"
## GPU layout matrix; no native advertisement requests are started.

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


func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Stage reward multiplier rendering requires a GPU")
		get_tree().quit(1)
		return
	Engine.time_scale = 8.0
	GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
	GameState.guided_onboarding_completed = true
	GameState.ad_personalization_choice = GameState.AdPersonalizationChoice.ACCEPTED
	for dimensions: Vector2i in [Vector2i(960, 1600), Vector2i(690, 1536), Vector2i(1080, 1920)]:
		get_window().min_size = dimensions
		get_window().size = dimensions
		for language: String in ["ru", "en"]:
			Database.load_languages(language, language)
			await fixture(4)
			check(!is_instance_valid(ui._portrait_stage_reward.multiplier_meter), "Early reward has no multiplier meter")
			await capture("stage_double_%dx%d_%s" % [dimensions.x, dimensions.y, language])
			await fixture()
			var meter: Control = ui._portrait_stage_reward.multiplier_meter
			for position: float in [0.1, 0.3, 0.5, 0.7, 0.9]:
				meter.set_cursor(position)
				await capture("stage_multiplier_%dx%d_%s_%d" % [dimensions.x, dimensions.y, language, roundi(position * 10)])
			check(native.shows == 0 and !ads._rewarded_pending_show and !ui._portrait_final_reward_waiting_for_ad, "Layout matrix never requests an advertisement")
	ui.queue_free()
	ads.queue_free()
	await frames()
	print("STAGE_REWARD_MULTIPLIER_RENDER ", JSON.stringify({"checks": checks, "failures": failures}))
	get_tree().quit(0 if failures.is_empty() else 1)
