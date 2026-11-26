extends Node

class TestUI:
	extends "res://scripts/main_portrait.gd"
	var continued: int = 0
	var sounds: int = 0
	var preview_banner: bool = false
	func _ready() -> void:
		_build_root()
		_clear()
	func _portrait_ads_enabled() -> bool:
		return preview_banner
	func _prepare_portrait_game_entrance() -> void:
		pass
	func _play_result_sound_once(_win: bool, _data: Dictionary = {}) -> void:
		sounds += 1
	func _result_continue_action() -> Callable:
		return _continued
	func _continued() -> void:
		continued += 1

var main: TestUI
var checks: int = 0
var failures: Array[String] = []
var independent_continues: int = 0

func check(value: bool, label: String) -> void:
	checks += 1
	if !value:
		failures.append(label)

func build(word: String, mistakes: int = 0) -> void:
	GameState.current_mode = GameState.GameMode.SINGLE_PLAYER
	GameSession.start_round(WordData.new(word, 0.2, -1, -1))
	GameSession.mistakes = mistakes
	main.show_game_screen()
	# Focus on the result choreography after a settled gameplay entrance.
	main._portrait_game_entrance_active = false
	main.last_result_data = {}
	GameSession.is_active = false

func _independent_continue() -> void:
	independent_continues += 1

func _ready() -> void:
	call_deferred("run")

func check_final_key_feedback() -> void:
	build("АБВА")
	var key: StageLetterButton = main._portrait_game_keyboard_buttons[0].button
	key.configure(key.letter_text, StageLetterButton.LetterState.WRONG, key.letter_font_size, true, true)
	key._start_feedback()
	var bounce: Tween = key._letter_bounce_tween
	bounce.pause()
	main._show_in_place_round_result(false, true)
	var animations: Array = main._portrait_round_result._animations.duplicate()
	bounce.custom_step(0.15)
	for animation: Tween in animations:
		animation.pause()
		animation.custom_step(0.15)
	check(key._key_visual.opacity < 1.0 and key._key_visual.opacity > StageLetterButton.USED_OPACITY and main.COMPOSITED_FADE.get_opacity(key) == 1.0, "only the used key's own fade runs during its return")
	bounce.custom_step(0.20)
	for animation: Tween in animations:
		if animation.is_valid():
			animation.custom_step(0.20)
	check(key._label.scale.is_equal_approx(Vector2.ONE) and is_equal_approx(key._key_visual.opacity, StageLetterButton.USED_OPACITY) and main.COMPOSITED_FADE.get_opacity(key) < 1.0, "result fade follows completed key feedback")
	main._clear()

func check_keyboard_layout(language: String, size: Vector2i) -> void:
	var is_russian: bool = language == "ru"
	main.preview_banner = true
	build("АБВА" if is_russian else "ABBA")
	GameSession.is_active = true
	GameSession.correct_letters.append("А" if is_russian else "A")
	GameSession.revealed[0] = true
	GameSession.wrong_letters.append("Й" if is_russian else "Q")
	main._refresh_portrait_game_keyboard()
	var background: Control = main.content.get_node("PortraitGameBackground")
	var background_rect: Rect2 = background.get_global_rect()
	check(background.has_node("PortraitGameBackgroundGradient") and !background.has_node("PortraitGameThemePattern"), "A theme-less fixture has the shared gradient without a theme icon")
	check(main.content.find_child("PortraitPaperBackground", true, false) == null and main.content.find_child("PortraitGameKeyboardPanel", true, false) == null, "keyboard stays on the blue gradient")
	var banner: Control = main.get_tree().get_first_node_in_group("ad_banner_slot")
	var banner_rect: Rect2 = banner.get_global_rect()
	var key_top: float = INF
	var key_bottom: float = -INF
	var expected_font_size: int = {960: 27, 690: 31, 1080: 28}[size.x]
	var keyboard_font := main.UI_FONTS.keyboard_font() as FontVariation
	var baked_font := keyboard_font.base_font as FontFile
	var weight_axis: int = TextServerManager.get_primary_interface().name_to_tag("wght")
	check(baked_font.multichannel_signed_distance_field and int(keyboard_font.variation_opentype[weight_axis]) == 600, "keyboard uses a baked MSDF profile at weight 600")
	var cyrillic_e: StageLetterButton
	var rows: Dictionary = {}
	for entry: Dictionary in main._portrait_game_keyboard_buttons:
		var button: StageLetterButton = entry.button
		var key_rect: Rect2 = button.get_global_rect()
		if button.letter_text == "Э":
			cyrillic_e = button
		key_top = minf(key_top, key_rect.position.y)
		key_bottom = maxf(key_bottom, key_rect.end.y)
		rows[key_rect.position.y] = rows.get(key_rect.position.y, "") + entry.letter
		check(background_rect.encloses(key_rect) and key_rect.end.y < banner_rect.position.y, "keyboard key stays on the playfield and above the ad")
		check(button._face.get_theme_stylebox("panel").corner_radius_top_left == 14, "key uses the leaderboard corner radius")
		check(button._label.get_theme_font("font") == keyboard_font, "letter uses the keyboard font profile")
		check(button._label.get_theme_font_size("font_size") == expected_font_size, "letter uses the expected adaptive font size")
		check(button.disabled == (button.letter_state != StageLetterButton.LetterState.NORMAL and button.remaining_count == 0), "a used key stays active only while its letter has hidden cells")
	check(rows.values() == (["ЙЦУКЕНГШЩЗХ", "ФЫВАПРОЛДЖЭ", "ЯЧСМИТЬЪБЮ"] if is_russian else ["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"]), "keyboard uses the expected rows with the complete game alphabet")
	check(is_equal_approx(background_rect.end.y, banner_rect.end.y), "shared background covers the screen through the ad slot")
	var stage_scale: float = main.PORTRAIT_STAGE_LAYOUT.fit_scale(main.get_viewport_rect().size)
	check(is_equal_approx(banner_rect.position.y - key_bottom, 22.0 * stage_scale), "bottom keyboard padding is 22 stage units")
	check(main._portrait_game_hint_buttons.size() == 3, "all three game hints are present")
	var hint_right: float = -INF
	for hint: Control in main._portrait_game_hint_buttons:
		var hint_rect: Rect2 = hint.get_global_rect()
		if hint_right != -INF:
			check(is_equal_approx(hint_rect.position.x - hint_right, 12.0 * stage_scale), "hint buttons sit twelve stage units apart")
		hint_right = hint_rect.end.x
		var expected_size: Vector2 = main.PORTRAIT_GAME_HINT_BUTTON_SIZE * 0.88 * stage_scale
		check(hint_rect.size.is_equal_approx(expected_size), "hint button and its input area are 20 percent smaller")
		check(is_equal_approx(key_top - hint_rect.end.y, 44.0 * stage_scale), "hint retains its gap to the first keyboard row")
		var icon: Control = hint.get_node("HintArtHolder")
		check(icon.get_global_rect().size.is_equal_approx(main.PORTRAIT_GAME_HINT_ART_SIZE * 0.88 * stage_scale), "hint icon scales with its button")
	var right_edge: float = background_rect.get_center().x + main.PORTRAIT_STAGE_SIZE.x * 0.5 * stage_scale
	check(is_equal_approx(right_edge - hint_right, 18.4 * stage_scale), "hint row uses the right screen margin")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var frame: Image = get_viewport().get_texture().get_image()
		var used_key: Control = main._portrait_game_keyboard_buttons[0].button
		var available_key: Control = main._portrait_game_keyboard_buttons[1].button
		var used_sample := Vector2i(used_key.get_global_rect().get_center().x, used_key.global_position.y + 7.0)
		var available_sample := Vector2i(available_key.get_global_rect().get_center().x, available_key.global_position.y + 7.0)
		var used_color: Color = frame.get_pixelv(used_sample)
		var white: Color = frame.get_pixelv(available_sample)
		var blue: Color = frame.get_pixel(2, used_sample.y)
		check(white.r > 0.95 and used_color.r < white.r - 0.1 and used_color.r > blue.r + 0.1, "used key blends between the white face and the gradient on GPU")
		var former_bar_edge: int = int(main.PORTRAIT_HEADER_HEIGHT * stage_scale)
		var upper: Color = frame.get_pixel(2, former_bar_edge - 4)
		var lower: Color = frame.get_pixel(2, former_bar_edge + 4)
		check(upper == Color.WHITE and lower == Color.WHITE, "White paper continues through the former header edge")
		var field_y: int = int(key_top - 11.0 * stage_scale)
		var field_color: Color = frame.get_pixel(2, field_y)
		check(lower.r > field_color.r + 0.04 and field_color.r >= blue.r and field_color.r - blue.r < 0.025, "playfield gradient continues smoothly behind the keyboard")
		check(frame.get_pixel(frame.get_width() - 3, used_sample.y) == blue, "keyboard background is a uniform gradient across the screen")
		await check_crossword_paper(frame, stage_scale, key_top)
		if is_instance_valid(cyrillic_e):
			var bounds: Rect2 = cyrillic_e.get_global_rect()
			var left_gap := Rect2i(Rect2(bounds.position + bounds.size * Vector2(0.08, 0.34), bounds.size * Vector2(0.13, 0.30)))
			var clear_left_gap: bool = true
			for y in range(left_gap.position.y, left_gap.end.y):
				for x in range(left_gap.position.x, left_gap.end.x):
					clear_left_gap = clear_left_gap and frame.get_pixel(x, y).r > 0.9
			check(clear_left_gap, "Cyrillic Э has no stray MSDF pixels to the left of its outline")
		var directory: String = OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
		if !directory.is_empty():
			frame.save_png(directory.path_join("game_keyboard_%s_%d.png" % [language, size.x]))
	main._clear()
	main.preview_banner = false

func check_crossword_paper(frame: Image, stage_scale: float, key_top: float) -> void:
	var grid: Control = main._portrait_crossword
	var paper := grid.find_child("CrosswordPaper", true, false) as ColorRect
	check(is_instance_valid(paper), "crossword has a dedicated paper sheet")
	if paper == null:
		return
	var rect: Rect2 = paper.get_global_rect()
	check(grid._grid.scale.x > 1.0, "Short crosswords use the larger cell scale")
	check(is_equal_approx((key_top - rect.end.y) / stage_scale, 22.0), "Paper ends 22 stage units above the first key row")
	for hint: Control in main._portrait_game_hint_buttons:
		check(is_equal_approx((rect.end.y - hint.get_global_rect().end.y) / stage_scale, 22.0), "Paper ends 22 stage units below each hint")
	var middle := Vector2i(3, int(rect.get_center().y))
	var body: Color = frame.get_pixelv(middle)
	check(body == Color.WHITE and frame.get_pixel(3, 0) == Color.WHITE, "White paper covers the playfield and reaches the top")
	check(frame.get_pixel(frame.get_width() - 4, middle.y).r > 0.90, "paper reaches the opposite screen edge")
	var plain: bool = true
	var clear_row: int = int(main.PORTRAIT_QUIZ_THEME_TITLE_RECT.end.y * stage_scale)
	for x: int in range(8, frame.get_width() - 8):
		plain = plain and frame.get_pixel(x, clear_row) == Color.WHITE
	check(plain, "the paper face has no graph ruling")
	var bottom_rows: Dictionary = {}
	for x: int in range(8, frame.get_width() - 8, 7):
		for band: int in range(ceili(10.0 * stage_scale)):
			var y: int = ceili(rect.end.y) - band
			if frame.get_pixel(x, y).r > 0.67:
				bottom_rows[y] = true
				break
	check(bottom_rows.size() > 1, "The bottom paper edge has an irregular tear contour")
	main.COMPOSITED_FADE.set_opacity(grid, 0.5)
	await RenderingServer.frame_post_draw
	var half: Color = get_viewport().get_texture().get_image().get_pixelv(middle)
	main.COMPOSITED_FADE.set_opacity(grid, 0.0)
	await RenderingServer.frame_post_draw
	var background: Color = get_viewport().get_texture().get_image().get_pixelv(middle)
	check(background.r < 0.7 and half.r > background.r + 0.08 and half.r < body.r - 0.08, "paper fades into the live blue gradient")
	main.COMPOSITED_FADE.set_opacity(grid, 1.0)
	await RenderingServer.frame_post_draw
	check(get_viewport().get_texture().get_image().get_pixelv(middle) == body, "paper restores its texture after the fade")

func run() -> void:
	GameState.ad_personalization_choice = GameState.AdPersonalizationChoice.ACCEPTED
	main = TestUI.new()
	add_child(main)
	check_final_key_feedback()
	var balances: Vector2i = Vector2i(GameState.get_soft_currency(), GameState.get_stars())
	for win: bool in [true, false]:
		build("ГРИВИСТЫЙ ВОЛК")
		main._show_in_place_round_result(win, false)
		await get_tree().process_frame
		check(main._portrait_in_place_result_active and main._portrait_in_place_result_is_win == win, "result flags reflect outcome")
		check(main._portrait_crossword._glyphs.all(func(label: Label) -> bool: return label == null or label.visible), "static result reveals the entire crossword")
		check(main._portrait_crossword._number_labels.all(func(label: Label) -> bool: return label == null or !label.visible), "Showing the solution removes all numbers")
		check(main._portrait_inline_result_search_button.visible and !main._portrait_inline_result_search_button.get("disabled"), "static search ready")
		check(main._portrait_inline_result_continue_button.visible and !main._portrait_inline_result_continue_button.get("disabled"), "static continue ready")
		check(main._portrait_game_keyboard_buttons.all(func(entry: Dictionary) -> bool: return entry.button.disabled and !entry.button.visible), "Restored results hide and disable the keyboard")
		var sounds: int = main.sounds
		var button: Control = main._portrait_inline_result_continue_button
		main._show_in_place_round_result(win, false)
		check(main.sounds == sounds and main._portrait_inline_result_continue_button == button, "duplicate result does not rebuild or replay sound")
		button.emit_signal("pressed")
		check(main.continued == (1 if win else 2), "continue reaches adapter")
	build("ДЛИННОЕ СОСТАВНОЕ-СЛОВО")
	main._portrait_word_letter_bounce_active_count = 1
	main._show_in_place_round_result(true, true)
	check(main._portrait_round_end_waiting_for_letter_bounce and main._portrait_inline_result_search_button == null, "winning result waits for gameplay letter")
	main._finish_portrait_word_letter_bounce(main._portrait_word_letter_bounce_generation)
	check(!main._portrait_round_end_waiting_for_letter_bounce and main._portrait_inline_result_search_button != null, "last gameplay letter presents the result")
	await get_tree().create_timer(3.0).timeout
	check(main._portrait_inline_result_search_button.visible and main._portrait_inline_result_search_button.mouse_filter == Control.MOUSE_FILTER_STOP, "search enters after word wave")
	check(main._portrait_crossword.visible and main._portrait_inline_result_continue_button.visible, "animated result settles")
	var result_label: Label = main.content.find_child("ResultWordLabel", true, false)
	check(result_label.visible and result_label.text.contains("−"), "settled word uses display separator")
	check(main.content.find_child("ResultWordBounceLetters", true, false) == null, "temporary glyphs are removed")
	# A restored result must skip attempts collection and show actions immediately.
	for animated: bool in [false, true]:
		build("АБВА")
		GameSession.word_hint_text = "Описание слова"
		main.last_result_data = {"remaining_attempt_star_reward_amount": 3}
		main._show_in_place_round_result(true, animated)
		if animated:
			await get_tree().create_timer(2.0).timeout
		check(main._portrait_inline_result_continue_button.visible and !main._portrait_inline_result_continue_button.get("disabled"), "Reward metadata does not delay Continue")
		check(main.find_child("AttemptStarRewardSummary", true, false) == null, "Word result has no attempts reward HUD")
		check(Vector2i(GameState.get_soft_currency(), GameState.get_stars()) == balances, "Result presentation never credits balances")
	# Remove the screen before deferred word completion callbacks run.
	build("ОТМЕНА")
	main._show_in_place_round_result(false, true)
	main._clear()
	await get_tree().create_timer(1.5).timeout
	check(!main._portrait_in_place_result_active and main._portrait_inline_result_continue_button == null, "navigation cancels old result")
	for size: Vector2i in [Vector2i(960, 1600), Vector2i(690, 1536), Vector2i(1080, 1920)]:
		get_window().min_size = size
		get_window().size = size
		get_window().content_scale_size = size
		await get_tree().process_frame
		for language: String in ["ru", "en"]:
			Database.load_languages(language, language)
			await check_keyboard_layout(language, size)
			for win: bool in [false, true]:
				build("АБВА" if language == "ru" else "ABBA")
				GameState.current_mode = GameState.GameMode.SINGLE_PLAYER
				GameSession.word_hint_text = "Описание загаданного слова, которое появляется после завершения раунда." if language == "ru" else "A description of the hidden answer, shown after the round ends."
				main._show_in_place_round_result(win, true)
				var result: Node = main._portrait_round_result
				var first: Control = main._portrait_game_keyboard_buttons[0].button
				var last: Control = main._portrait_game_keyboard_buttons[5].button
				var fade: float = main.PORTRAIT_ROUND_END_KEY_FADE_DURATION
				# Step the real tweens at fixed times: GPU shader compilation must not
				# consume the entire short first-key fade before its first assertion.
				var transitions: Array = result._animations.duplicate()
				for animation: Tween in transitions:
					animation.pause()
					animation.custom_step(fade * 0.35)
				var early: float = main.COMPOSITED_FADE.get_opacity(first)
				check(early > 0.0 and early < 1.0, "result wave has intermediate opacity")
				if DisplayServer.get_name() != "headless":
					await RenderingServer.frame_post_draw
					var directory: String = OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
					if directory != "":
						get_viewport().get_texture().get_image().save_png(directory.path_join("%s_wave_%s_%d.png" % ["win" if win else "loss", language, size.x]))
				check(main.COMPOSITED_FADE.get_opacity(last) > early, "result wave travels left to right")
				check(is_zero_approx(main.COMPOSITED_FADE.get_opacity(result.comment_label)), "comment waits for keyboard")
				for animation: Tween in transitions:
					if animation.is_valid():
						animation.custom_step(fade * 0.25)
				check(main.COMPOSITED_FADE.get_opacity(first) < early, "result opacity continues moving")
				for animation: Tween in transitions:
					if animation.is_valid():
						if !animation.custom_step(main.PORTRAIT_ROUND_END_KEY_WAVE_DURATION + fade * 0.7):
							animation.kill()
				var middle: float = main.COMPOSITED_FADE.get_opacity(result.comment_label)
				check(middle > 0.0 and middle < 1.0, "comment has intermediate fade")
				for animation: Tween in transitions:
					if animation.is_valid():
						animation.custom_step(0.5)
				await get_tree().create_timer(0.5).timeout
				check(!first.visible and !last.visible, "result removes all keyboard visuals")
				if DisplayServer.get_name() != "headless":
					var keyboard_top: int = int(first.get_global_rect().position.y - 40.0)
					var viewport_size := Vector2i(get_viewport().get_visible_rect().size)
					var region := Rect2i(0, keyboard_top, viewport_size.x, viewport_size.y - keyboard_top)
					var action: Control = main._portrait_inline_result_continue_button
					var action_was_visible: bool = action.visible
					# The continuing attention bounce overlaps the old keyboard area.
					action.hide()
					await RenderingServer.frame_post_draw
					var hidden: Image = get_viewport().get_texture().get_image().get_region(region)
					for entry: Dictionary in main._portrait_game_keyboard_buttons:
						entry.button.show()
					await RenderingServer.frame_post_draw
					var transparent: Image = get_viewport().get_texture().get_image().get_region(region)
					check(hidden.get_data() == transparent.get_data(), "zero-opacity keyboard leaves no GPU pixels")
					for entry: Dictionary in main._portrait_game_keyboard_buttons:
						entry.button.hide()
					action.visible = action_was_visible
				check(is_equal_approx(main.COMPOSITED_FADE.get_opacity(result.comment_label), 1.0), "comment finishes opaque")
				check(result.comment_label.get_theme_font("font") == main.UI_QUESTION_COMMENT_FONT, "comment uses the Roboto Flex question and comment profile")
				check(result.comment_label.text == GameSession.get_word_hint(), "comment uses current word hint")
				check(result.comment_label.get_theme_font_size("font_size") == 28, "comment font size is 28")
				var comment_bounds: Rect2 = main.COMPOSITED_FADE.layout_parent(result.comment_label).get("stage_rect")
				check(is_equal_approx(comment_bounds.position.x, 50.0) and is_equal_approx(main.PORTRAIT_STAGE_SIZE.x - comment_bounds.end.x, 50.0), "comment has fifty-unit margins on both sides")
				var answer: Label = main.content.find_child("ResultWordLabel", true, false)
				var answer_bounds: Rect2 = main.COMPOSITED_FADE.layout_parent(answer).get("stage_rect")
				check(is_equal_approx(comment_bounds.position.y - answer_bounds.end.y, 50.0) and result.comment_label.vertical_alignment == VERTICAL_ALIGNMENT_TOP, "comment starts at fixed gap below word block")
				if DisplayServer.get_name() != "headless":
					await RenderingServer.frame_post_draw
					var directory: String = OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
					if directory != "":
						get_viewport().get_texture().get_image().save_png(directory.path_join("%s_comment_%s_%d.png" % ["win" if win else "loss", language, size.x]))
				main._clear()
				build("АБВА" if language == "ru" else "ABBA")
				GameState.current_mode = GameState.GameMode.SINGLE_PLAYER
				GameSession.word_hint_text = "Описание" if language == "ru" else "Description"
				main._show_in_place_round_result(win, false)
				check(main._portrait_game_keyboard_buttons.all(func(entry: Dictionary) -> bool: return !entry.button.visible), "restored single-player result skips the wave")
				check(is_equal_approx(main.COMPOSITED_FADE.get_opacity(main._portrait_round_result.comment_label), 1.0), "restored result immediately shows the comment")
				main._clear()
	build("ОТМЕНА")
	GameState.current_mode = GameState.GameMode.SINGLE_PLAYER
	GameSession.word_hint_text = "Комментарий"
	main._show_in_place_round_result(false, true)
	var departing_result: Node = main._portrait_round_result
	var departing_animations: Array = departing_result._animations.duplicate()
	main._clear()
	check(departing_animations.all(func(animation: Tween) -> bool: return !animation.is_valid() or !animation.is_running()), "leaving cancels loss wave and pending comment fade")
	await get_tree().create_timer(1.0).timeout
	check(!main._portrait_in_place_result_active and main._portrait_round_result == null, "loss callbacks cannot restore the departed screen")
	# The component also works without the gameplay adapter.
	var parent := Control.new()
	parent.theme = main.ui.theme
	add_child(parent)
	var component := preload("res://scripts/ui/portrait_round_result.gd").new()
	parent.add_child(component)
	var standalone_letters: Array[String] = ["А", "Б", "В", "А"]
	component.configure(parent, {"word_rect": Rect2(18, 450, 444, 60), "action_rect": Rect2(52, 650, 376, 72)}, standalone_letters)
	component.continue_requested.connect(_independent_continue)
	main.queue_free()
	await get_tree().process_frame
	component.begin(true, false, false, "ПРОДОЛЖИТЬ")
	check(component.result_search_button.visible and component.result_continue_button.visible, "standalone builds after adapter is gone")
	component.result_continue_button.emit_signal("pressed")
	check(independent_continues == 1, "standalone emits continue intent")
	component.stop()
	component.result_continue_button.emit_signal("pressed")
	check(independent_continues == 1, "stopped component ignores actions")
	check(component._animations.all(func(animation: Tween) -> bool: return !animation.is_valid() or !animation.is_running()), "stop cancels owned animations")
	parent.queue_free()
	print("PORTRAIT_ROUND_RESULT " + JSON.stringify({"checks": checks, "failures": failures}))
	await get_tree().process_frame
	get_tree().quit(0 if failures.is_empty() else 1)
