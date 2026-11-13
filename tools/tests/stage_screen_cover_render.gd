extends Node
## Real source/destination frames: retain the reward chain until the backdrop covers it.
class TestUI extends "res://scripts/main_portrait.gd":
	var quiz_stage := false
	func _ready() -> void:
		_build_root()
		_clear()
	func _portrait_ads_enabled() -> bool:
		return false
	func _single_player_stage_is_quiz(_level: int, _slot: int) -> bool:
		return quiz_stage

var main: TestUI
var checks := 0
var failures: Array[String] = []
var tag := ""

func check(ok: bool, message: String) -> void:
	checks += 1
	if !ok:
		failures.append(tag + ": " + message)
		push_error(tag + ": " + message)

func _ready() -> void:
	run.call_deferred()

func _process(_delta: float) -> void:
	if OS.get_environment("HANGMAN_TEST_HIDE_WINDOW") == "1":
		RenderingServer.force_draw(false)

func frame() -> Image:
	for index in range(3):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()

func save_frame(image: Image, phase: String) -> void:
	var directory := OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
	if !directory.is_empty():
		image.save_png(directory.path_join("cover_%s_%s.png" % [tag, phase]))

func mix_error(actual: Image, source: Image, destination: Image, amount: float) -> float:
	var maximum := 0.0
	# Exclude the independent top HUD; the full body includes hero, chain, clips
	# and the moving prize. Freeze all other tweens for a deterministic comparison.
	for y in range(int(actual.get_height() * 0.25), actual.get_height() - 20, 7):
		for x in range(20, actual.get_width() - 20, 7):
			var expected := source.get_pixel(x, y).lerp(destination.get_pixel(x, y), amount)
			var value := actual.get_pixel(x, y)
			maximum = maxf(maximum, maxf(absf(value.r - expected.r), maxf(absf(value.g - expected.g), absf(value.b - expected.b))))
	return maximum

func chain_fixture(completed: bool, large_stage: bool = false) -> void:
	main.quiz_stage = large_stage
	GameState.current_mode = GameState.GameMode.SINGLE_PLAYER
	var language: String = Database.current_language
	GameState.reset_single_level_attempt(language, 4, true, true, false)
	GameState._single_player_bucket(language)["unlocked_level"] = 4
	GameState.select_single_level_theme(language, 4, 0, 3)
	var statuses: Array = GameState.ensure_single_level_progress(language, 4, 3)
	statuses[0] = 1
	statuses[1] = 1
	statuses[2] = 1 if completed else 0
	GameState.pending_single_player_reward = GameState._normalize_pending_single_player_reward({
		"language": language, "level_index": 4, "word_count": 3, "amount": 35, "stars_amount": 10}) if completed else {}
	var result: Dictionary = {"single_player_level_index": 4, "single_player_word_slot": 2 if completed else 1,
		"single_player_total_count": 3, "single_player_level_completed": completed, "single_player_resume_chain_checkpoint": true}
	GameState.set_active_single_player_session({"kind": "next", "language": language, "level_index": 4,
		"word_slot": result.single_player_word_slot, "theme_id": Database.get_theme_id(0),
		"data": {"result": result, "reward_currency": GameState.STAGE_REWARD_COINS if large_stage else GameState.STAGE_REWARD_STARS,
		"reward_amount": 25 if large_stage else 5, "reward_claimed": !large_stage, "reward_double_resolved": !large_stage}}, true)
	main.last_result_data = result
	main.last_result_is_win = true
	main.single_player_active_level_index = 4
	main.single_player_active_word_slot = int(result.single_player_word_slot)
	main._portrait_single_reward_resume_without_intro = !large_stage
	main._show_single_player_reward_chain_screen()

func await_cover() -> Node:
	var deadline := Time.get_ticks_msec() + 5000
	while Time.get_ticks_msec() < deadline:
		var cover: Node = main.ui.find_child("ScreenCoverTransition", true, false)
		if is_instance_valid(cover) and cover._animation != null:
			return cover
		await get_tree().process_frame
	return null

func verify_prize_flight(prize: Control) -> void:
	var animations: Array[Tween] = get_tree().get_processed_tweens()
	for animation: Tween in animations:
		animation.pause()
	var previous_rect: Rect2 = prize.get("stage_rect")
	for animation: Tween in animations:
		if animation.is_valid():
			animation.custom_step(0.025)
	var early: float = main.COMPOSITED_FADE.get_opacity(prize)
	for animation: Tween in animations:
		if animation.is_valid():
			animation.custom_step(0.025)
	var late: float = main.COMPOSITED_FADE.get_opacity(prize)
	check(early > 0.0 and late > early and late < 1.0, "Flying prize progressively fades in")
	check(!previous_rect.is_equal_approx(prize.get("stage_rect")), "Prize moves while fading in")
	for shadow: TextureRect in prize.get_meta("main_reward_icon_shadow_layers"):
		check(is_zero_approx(main.COMPOSITED_FADE.get_opacity(shadow)), "Prize shadow stays hidden during flight")
	var visible_prize := await frame()
	save_frame(visible_prize, "prize_flight")
	main.COMPOSITED_FADE.set_opacity(prize, 0.0)
	var hidden_prize := await frame()
	check(visible_prize.get_data() != hidden_prize.get_data(), "Intermediate prize opacity draws visible GPU pixels")
	main.COMPOSITED_FADE.set_opacity(prize, late)
	for animation: Tween in animations:
		if animation.is_valid():
			animation.play()

func verify_pixels(cover: Node) -> void:
	check(cover.has_source and (is_instance_valid(cover._snapshot) or cover.uses_live_source()), "Transition retains its real source")
	if tag.ends_with("_stage"):
		check(cover.uses_live_source() and cover._snapshot == null, "Stage reward keeps the live hierarchy without a screenshot")
		await verify_prize_flight(main.content.find_child("StageCoinLargeReward", true, false))
	check(is_instance_valid(cover._blocker) and cover._blocker.mouse_filter == Control.MOUSE_FILTER_STOP, "Cover blocks repeat input")
	var animations: Array[Tween] = get_tree().get_processed_tweens()
	for animation: Tween in animations:
		animation.pause()
	cover._animation.custom_step(0.05)
	var early: float = cover.coverage
	cover._animation.custom_step(0.05)
	var late: float = cover.coverage
	check(early > 0.0 and late > early and late < 1.0, "Real tween advances through two distinct intermediate coverage values")
	cover.coverage = 0.0
	var source := await frame()
	save_frame(source, "source")
	cover.coverage = 1.0
	var destination := await frame()
	save_frame(destination, "destination")
	check(mix_error(source, destination, destination, 0.0) > 0.1, "Source and destination body pixels are distinct")
	for amount: float in [0.25, 0.5, 0.75]:
		cover.coverage = amount
		var middle := await frame()
		var error := mix_error(middle, source, destination, amount)
		check(error <= 3.0 / 255.0, "Body is a uniform composite at %.2f (error %.4f)" % [amount, error])
		save_frame(middle, "middle_%d" % int(amount * 100))
	cover.coverage = 0.0
	var restored := await frame()
	check(mix_error(restored, source, source, 0.0) <= 2.0 / 255.0, "Opaque source restores without missing hero or chain pixels")
	# Hiding/showing a live source may rebuild its composited branches. Do this
	# independent zero-pixel check only after the uniform-mixing comparisons.
	cover.coverage = 1.0
	var live: Array[Control] = []
	if is_instance_valid(cover._snapshot):
		cover._snapshot.hide()
	else:
		for reference: WeakRef in cover._live_sources:
			var source_visual: Control = reference.get_ref()
			if is_instance_valid(source_visual):
				live.append(source_visual)
				source_visual.hide()
	var independent_destination := await frame()
	check(mix_error(destination, independent_destination, independent_destination, 0.0) <= 2.0 / 255.0, "Full coverage leaves no outgoing snapshot pixels")
	if is_instance_valid(cover._snapshot):
		cover._snapshot.show()
	for source_visual: Control in live:
		source_visual.show()
	for animation: Tween in animations:
		if animation.is_valid():
			animation.play()

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Screen-cover pixel regression requires GPU")
		get_tree().quit(1)
		return
	if OS.get_environment("HANGMAN_TEST_HIDE_WINDOW") == "1":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)
	GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
	GameState.guided_onboarding_completed = true
	main = TestUI.new()
	add_child(main)
	for language: String in ["ru", "en"]:
		GameState.set_word_language(language)
		GameState.interface_language = language
		Database.load_languages(language, language)
		for dimensions: Vector2i in [Vector2i(960, 1600), Vector2i(690, 1536), Vector2i(1080, 1920)]:
			get_window().min_size = dimensions
			get_window().size = dimensions
			var resize_deadline := Time.get_ticks_msec() + 2000
			var resized_image := await frame()
			while resized_image.get_size() != dimensions and Time.get_ticks_msec() < resize_deadline:
				resized_image = await frame()
			check(resized_image.get_size() == dimensions, "GPU frame has requested pixel dimensions: %s / %s" % [resized_image.get_size(), dimensions])
			for target: String in ["summary", "stage", "quiz", "restored_quiz"]:
				tag = "%s_%dx%d_%s" % [language, dimensions.x, dimensions.y, target]
				chain_fixture(target == "summary", target == "stage")
				if target != "stage":
					await frame()
					await get_tree().create_timer(0.15).timeout
					await frame()
					var hero: Control = main.content.find_child("SinglePlayerRewardHeroTexture", true, false)
					check(is_instance_valid(hero) and hero.is_visible_in_tree(), "Source has a visible hero")
					if target == "summary":
						main._show_completed_single_player_level_summary()
					else:
						main._quiz_mode_active = true
						main._quiz_single_player_embedded = true
						main._quiz_selected_theme_index = 0
						main._quiz_current_question = main.QUIZ_SELECTION.shuffled(Database.get_quiz_questions_by_theme_index(0)[0])
						main._quiz_answer_locked = false
						main._quiz_selected_answer_index = -1
						main._quiz_fifty_fifty_used = target == "restored_quiz"
						main._quiz_replace_question_used = false
						main._quiz_question_replacing = false
						main._quiz_question_ready_at_msec = 0
						main._show_quiz_game_screen()
				var cover := await await_cover()
				check(is_instance_valid(cover), "Destination starts the shared cover")
				if !is_instance_valid(cover):
					continue
				if target.contains("quiz"):
					check(main._quiz_question_ready_at_msec == 0, "Speed timer waits for the visible question")
				var generation: int = main.result_transition_generation
				main._continue_from_single_player_reward_chain()
				check(main.result_transition_generation == generation, "Repeat Continue cannot replace a pending transition")
				await verify_pixels(cover)
				# The same tween is reused; a second request cannot restart the cover.
				check(cover.reveal(5.0) == cover._animation, "Repeated reveal reuses the running transition")
				await cover.finished
				check(cover.complete and is_equal_approx(cover.coverage, 1.0) and cover._snapshot == null and cover._blocker == null, "Full coverage releases snapshot and input blocker")
				if target == "summary":
					# The cover signal precedes the deferred flight continuation.
					await get_tree().process_frame
					await verify_prize_flight(main.content.find_child("LevelCompletionRewardPrize", true, false))
				await get_tree().create_timer(1.6).timeout
				if target in ["stage", "summary"]:
					var prize: Control = main.content.find_child("StageCoinLargeReward" if target == "stage" else "LevelCompletionRewardPrize", true, false)
					for shadow: TextureRect in prize.get_meta("main_reward_icon_shadow_layers"):
						check(is_equal_approx(main.COMPOSITED_FADE.get_opacity(shadow), 1.0), "Prize shadow appears after the landing animation")
				if target.contains("quiz"):
					check(main._quiz_question_ready_at_msec > 0, "Speed timer starts after the entrance")
				# Cancel another instance mid-fade, then allow its old deadline to pass.
				chain_fixture(false)
				await frame()
				main._quiz_mode_active = true
				main._quiz_selected_theme_index = 0
				main._quiz_current_question = main.QUIZ_SELECTION.shuffled(Database.get_quiz_questions_by_theme_index(0)[0])
				main._quiz_fifty_fifty_used = false
				main._show_quiz_game_screen()
				var cancelled := await await_cover()
				var snapshot: Control = cancelled._snapshot
				var blocker: Control = cancelled._blocker
				main._clear()
				var cleared_generation: int = main.result_transition_generation
				await get_tree().create_timer(0.6).timeout
				check(!is_instance_valid(cancelled) and !is_instance_valid(snapshot) and !is_instance_valid(blocker), "Leaving mid-cover releases all owned visuals")
				check(main.result_transition_generation == cleared_generation and !main._quiz_screen_active, "Cancelled transition cannot revive the destination")
	main.queue_free()
	await get_tree().process_frame
	print("STAGE_SCREEN_COVER_RENDER " + JSON.stringify({"checks": checks, "failures": failures}))
	get_tree().quit(1 if !failures.is_empty() else 0)
