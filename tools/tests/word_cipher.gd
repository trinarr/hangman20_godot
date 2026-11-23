extends Node

var checks: int = 0
var failures: int = 0

class TestUI extends "res://scripts/main_portrait.gd":
	var fixture_word: WordData = null

	func _single_player_level_words(level_index: int) -> Array:
		if fixture_word == null:
			return super._single_player_level_words(level_index)
		return [{
			"text": fixture_word.text, "difficulty": fixture_word.difficulty,
			"theme_index": fixture_word.theme_index, "word_index": fixture_word.index,
		}]

func _ready() -> void:
	run.call_deferred()

func _process(_delta: float) -> void:
	if DisplayServer.get_name() == "headless":
		RenderingServer.frame_post_draw.emit()
	elif OS.get_environment("HANGMAN_TEST_HIDE_WINDOW") == "1":
		RenderingServer.force_draw(false)

func check(condition: bool, message: String) -> void:
	checks += 1
	if !condition:
		failures += 1
		push_error(message)

func fixture(answer: String) -> WordData:
	for theme: int in range(Database.get_theme_count()):
		for word: Dictionary in Database.get_words_by_index(theme, 0):
			if str(word.text) == answer:
				return WordData.new(answer, float(word.difficulty), theme, int(word.index), str(word.id))
	return null

func click(control: Control) -> void:
	var point: Vector2 = control.get_global_rect().get_center()
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		get_viewport().push_input(event, true)
		await get_tree().process_frame

func swipe_up(point: Vector2) -> void:
	var previous_emulation: bool = Input.emulate_touch_from_mouse
	Input.emulate_touch_from_mouse = true
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = point
	get_viewport().push_input(touch, true)
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = true
	mouse.position = point
	get_viewport().push_input(mouse, true)
	for step: int in range(1, 5):
		var drag := InputEventScreenDrag.new()
		drag.position = point - Vector2(0.0, step * 24.0)
		drag.relative = Vector2(0.0, -24.0)
		get_viewport().push_input(drag, true)
		var motion := InputEventMouseMotion.new()
		motion.position = drag.position
		motion.relative = drag.relative
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		get_viewport().push_input(motion, true)
		await get_tree().process_frame
	touch.pressed = false
	touch.position = point - Vector2(0.0, 96.0)
	get_viewport().push_input(touch, true)
	mouse.pressed = false
	mouse.position = touch.position
	get_viewport().push_input(mouse, true)
	await get_tree().create_timer(0.5).timeout
	Input.emulate_touch_from_mouse = previous_emulation

func key(main: Node, letter: String) -> Control:
	for entry: Dictionary in main._portrait_game_keyboard_buttons:
		if entry.letter == letter:
			return entry.button
	return null

func run() -> void:
	Engine.time_scale = 5.0
	GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
	GameState.guided_onboarding_completed = true
	get_window().min_size = Vector2i.ONE
	for language: String in ["ru", "en"]:
		GameState.interface_language = language
		GameState.word_language = language
		Database.load_languages(language, language)
		GameState.current_mode = GameState.GameMode.SINGLE_PLAYER
		var source: WordData = fixture("БАРАБАН" if language == "ru" else "LETTER")
		check(source != null, language + " catalog has the repeated-letter fixture")
		if source == null:
			continue
		for window_size: Vector2i in [Vector2i(960, 1600), Vector2i(690, 1536)]:
			get_window().size = window_size
			GameState.interface_language = language
			GameState.clear_active_single_player_session()
			GameState.reset_single_level_attempt(language, 0)
			var main: Node = load("res://scenes/Main.tscn").instantiate()
			main.set_script(TestUI)
			add_child(main)
			var startup: Node = main.get_node("StartupPreparation")
			var deadline: int = Time.get_ticks_msec() + 15000
			while (startup.preparing or startup.entrance_pending) and Time.get_ticks_msec() < deadline:
				await get_tree().process_frame
			main.fixture_word = source
			main._start_single_player_word(0, 0)
			await get_tree().create_timer(4.0).timeout
			await check_quote(main, source, language, window_size)
			GameSession.start_round(source, GameState.GameMode.SINGLE_PLAYER, true, true)
			main.show_game_screen()
			await get_tree().create_timer(4.0).timeout
			check(GameSession.is_cipher_round() and GameSession.get_full_word() == source.text, "Word-based cipher snapshots retain their catalog answer")
			if !GameSession.is_cipher_round():
				main.queue_free()
				await get_tree().process_frame
				continue
			var root: Control = main._portrait_game_word_slots_root
			var slots: Array = root.get_meta("word_slots_cache")["slots"]
			var hud_labels: Array = main._portrait_game_attempts_controls
			check(main.hero_static_symbol == null and hud_labels.size() == 4, "Cipher builds the compact HUD without a character")
			var attempts_title: Rect2 = hud_labels[0].get_parent().get("stage_rect")
			var attempts_value: Rect2 = hud_labels[1].get_parent().get("stage_rect")
			var theme_title: Rect2 = hud_labels[2].get_parent().get("stage_rect")
			var theme_value: Rect2 = hud_labels[3].get_parent().get("stage_rect")
			check(
				attempts_title.end.x < theme_title.position.x
				and is_equal_approx(attempts_title.position.y, theme_title.position.y)
				and is_equal_approx(attempts_value.position.y, theme_value.position.y),
				"The attempts and category blocks sit side by side"
			)
			check(
				is_equal_approx(attempts_title.get_center().x, attempts_value.get_center().x)
				and is_equal_approx(theme_title.get_center().x, theme_value.get_center().x)
				and attempts_title.end.y <= attempts_value.position.y
				and theme_title.end.y <= theme_value.position.y,
				"Each HUD value sits below its own title"
			)
			var short_paper: Rect2 = main._portrait_game_word_paper_backside.get("stage_rect")
			check(is_equal_approx(short_paper.size.y, main.PORTRAIT_GAME_WORD_PAPER_HEIGHT), "Single-row cipher uses the original paper height")
			var clue_root: Control = main._portrait_crostic_clue_rows[0].slots if !main._portrait_crostic_clue_rows.is_empty() else null
			check(is_instance_valid(clue_root), "New campaign rounds build a catalog clue")
			if !is_instance_valid(clue_root):
				main.queue_free()
				await get_tree().process_frame
				continue
			var clue_slots: Array = clue_root.get_meta("word_slots_cache")["slots"]
			var definition: Label = clue_root.get_parent().find_child("CrosticDefinition0", true, false)
			var definition_rect: Rect2 = definition.get_parent().get_global_rect()
			var keyboard_key: Control = main._portrait_game_keyboard_buttons[0].button
			check(
				!main._portrait_game_word_paper_mask.is_ancestor_of(clue_root)
				and main._portrait_game_word_paper_backside.get_global_rect().end.y < definition_rect.position.y
				and hud_labels[1].get_parent().get_global_rect().end.y < main._portrait_game_word_paper_backside.get_global_rect().position.y
				and definition_rect.end.y <= clue_slots[0].hit.get_global_rect().position.y + 1.0
				and clue_slots[0].hit.get_global_rect().end.y < keyboard_key.get_global_rect().position.y,
				"Clue sits on the grid between the paper and the keyboard without overlapping the HUD"
			)
			check(GameSession.revealed.count(true) == 1 and GameSession.selected_position == 1 and slots[1].selection.visible, "Exactly one starter and initial focus")
			check(Database.interface_language == language, "Gameplay uses the requested interface language")
			check(slots[0].label.get_theme_font_size("font_size") == 34, "Cipher uses the classic gameplay letter size")
			check(slots[1].number.get_theme_font_size("font_size") == 21, "Codes use the enlarged font")
			var line_rect: Rect2 = slots[1].underline.get("stage_rect")
			check(is_equal_approx(line_rect.size.y, 4.0), "Cipher underline has the classic stroke thickness")
			check(slots[0].label.get_visible_line_count() == 1 and slots[1].number.get_visible_line_count() == 1, "Starter and codes fit their glyph bounds")
			check(
				slots[0].number.visible == (GameSession.cipher_letters.count(GameSession.letters[0]) > 1),
				"Starter code is shown only when another occurrence is still hidden"
			)
			var starter: Control = slots[0].label.get_parent()
			var starter_code: Control = slots[0].number.get_parent()
			var underline: Control = slots[1].underline
			var closed_code: Control = slots[1].number.get_parent()
			check(
				starter_code.get_global_rect().position.y >= starter.get_global_rect().end.y
				and closed_code.get_global_rect().position.y >= underline.get_global_rect().end.y,
				"Codes are below the starter and the blank"
			)
			if DisplayServer.get_name() != "headless":
				var capture_dir := OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
				if !capture_dir.is_empty():
					await RenderingServer.frame_post_draw
					var capture: String = "word_cipher_%s_%dx%d.png" % [language, window_size.x, window_size.y]
					var image: Image = get_viewport().get_texture().get_image()
					check(image.get_size() == window_size and image.save_png(capture_dir.path_join(capture)) == OK, "Capture initial layout at target viewport size")
			await check_hints(main)
			var first: int = 1 if language == "ru" else 2
			var second: int = 3
			var repeated: String = GameSession.letters[first]
			var misplaced: String = GameSession.letters[2 if language == "ru" else 1]
			var absent: String = ""
			for letter: String in Database.get_alphabet():
				if !GameSession.cipher_letters.has(letter):
					absent = letter
					break
			var clue_index: int = GameSession.cipher_letters.find(repeated, slots.size())
			check(clue_index >= slots.size(), "Clue shares a repeated letter with the main word")
			if clue_index < slots.size():
				main.queue_free()
				await get_tree().process_frame
				continue
			var clue_slot: Dictionary = clue_slots[clue_index - slots.size()]
			check(GameSession.cipher_codes[first] == GameSession.cipher_codes[second], "Matching letters share a number")
			check(GameSession.cipher_codes[0] != GameSession.cipher_codes[first], "Different letters have different numbers")
			if language == "ru":
				await click(slots[0].hit)
				check(GameSession.selected_position == 4 and slots[0].selection.visible and slots[4].selection.visible, "An open starter selects the unfinished group")
			await click(slots[first].hit)
			check(slots[first].selection.visible and slots[second].selection.visible and !slots[0].selection.visible, "Selecting a cell highlights all and only matching numbers")
			var misplaced_key := key(main, misplaced) as StageLetterButton
			var misplaced_glyph: Label = misplaced_key._label
			var misplaced_marker: TextureRect = misplaced_key._marker
			check(misplaced_key.letter_state == StageLetterButton.LetterState.NORMAL, "Untried hidden letter starts neutral")
			await click(key(main, misplaced))
			check(main.hero_static_symbol == null and main.hero_animation_overlay == null, "A guess does not bring back the character")
			check(GameSession.mistakes == 1 and GameSession.selected_position == first and !slots[first].label.visible, "Misplaced letter costs an attempt and retains focus")
			var wrong_feedback: Tween = misplaced_key._cipher_feedback_tween
			main._press_letter(misplaced)
			check(
				GameSession.mistakes == 1 and key(main, misplaced).get("disabled")
				and misplaced_key._cipher_feedback_tween == wrong_feedback,
				"Repeating an excluded guess neither spends an attempt nor restarts feedback"
			)
			await get_tree().create_timer(1.35).timeout
			check(
				misplaced_key.letter_state == StageLetterButton.LetterState.PRESENT
				and misplaced_glyph.get_theme_color("font_color") == StageLetterButton.PRESENT_COLOR
				and !misplaced_marker.visible,
				"Misplaced letter settles orange without a stroke"
			)
			await click(key(main, absent))
			check(
				GameSession.mistakes == 2 and GameSession.selected_position == first
				and GameSession.wrong_letters.has(absent) and key(main, absent).get("disabled"),
				"Absent letter costs one attempt and is globally disabled"
			)
			await click(slots[second].hit)
			check(GameSession.selected_position == second and slots[second].selection.visible and slots[first].selection.visible, "Clicking another match keeps the whole group highlighted")
			check(key(main, misplaced).get("disabled"), "A rejected letter stays unavailable for the same number")
			main._press_letter(misplaced)
			check(GameSession.mistakes == 2, "Repeating the same code guess costs nothing")
			await click(slots[second + 1].hit)
			check(!key(main, misplaced).get("disabled") and misplaced_glyph.get_theme_color("font_color") == StageLetterButton.PRESENT_COLOR, "Misplaced letter remains orange and available for another number")
			check(key(main, absent).get("disabled"), "Absent letter stays disabled in another cell")
			main._press_letter(absent)
			check(GameSession.mistakes == 2, "Repeating a globally wrong letter costs nothing")
			main._portrait_crostic_clue_block.ensure_control_visible(clue_slot.hit)
			await get_tree().process_frame
			await click(clue_slot.hit)
			check(clue_slot.selection.visible and slots[first].selection.visible and slots[second].selection.visible,
				"Selecting a clue number highlights its main-word matches")
			check(!GameSession.can_guess(misplaced), "The same error is blocked across the two rows")
			await click(key(main, repeated))
			check(clue_slot.label.visible and slots[second].label.visible and slots[first].label.visible
				and GameSession.selected_position == GameSession.revealed.find(false),
				"One entry from the clue reveals the group and returns focus to the main word")
			await get_tree().create_timer(0.75).timeout
			var repeated_key := key(main, repeated) as StageLetterButton
			check(
				repeated_key._label.get_theme_color("font_color") == StageLetterButton.UI_PALETTE.DISABLED
				and !slots[first].number.visible and !slots[second].number.visible,
				"The solved group hides its codes and mutes the key"
			)
			var codes: PackedInt32Array = GameSession.cipher_codes.duplicate()
			GameState.load_game()
			var session: Dictionary = GameState.get_active_single_player_session()
			var saved: Dictionary = session.get("data", {})
			GameSession.discard_current_round()
			check(GameSession.restore_from_save_data(saved), "Cipher snapshot restores from JSON")
			check(
				GameSession.cipher_codes == codes and GameSession.revealed[first] and GameSession.revealed[second]
				and GameSession.is_cipher_position_revealed(clue_index) and definition.text == GameSession.cipher_clues[0]["hint"]
				and GameSession.selected_position == GameSession.revealed.find(false),
				"Continue keeps the solved group and focuses the first hidden cell"
			)
			check(GameSession.can_view_comment_hint() and get_tree().get_first_node_in_group(&"word_comment_popup") == null, "Continue preserves comment access without opening it")
			check(
				misplaced_key.letter_state == StageLetterButton.LetterState.PRESENT
				and key(main, repeated).get("letter_state") == StageLetterButton.LetterState.CIRCLED,
				"Continue reconstructs the orange and completed key states"
			)
			check(!GameSession.can_guess(absent) and GameSession.mistakes == 2, "Continue keeps the global exclusion and attempt count")
			var previous_snapshot: Dictionary = saved.duplicate(true)
			previous_snapshot["cipher_clue"] = previous_snapshot["cipher_clues"][0]
			previous_snapshot.erase("cipher_clues")
			previous_snapshot["wrong_letters"] = []
			previous_snapshot["revealed"][first] = false
			previous_snapshot["cipher_wrong_letters"][str(first)] = [absent]
			previous_snapshot["cipher_wrong_letters"][str(second)] = [misplaced, absent]
			check(GameSession.restore_from_save_data(previous_snapshot), "Snapshot with old per-cell errors still restores")
			GameSession.select_position(second + 1)
			check(
				GameSession.wrong_letters.count(absent) == 1 and !GameSession.can_guess(absent)
				and GameSession.can_guess(misplaced) and GameSession.mistakes == 2,
				"Restore promotes old absent letters without charging another attempt"
			)
			await click(slots[second].hit)
			check(GameSession.selected_position == first and !GameSession.can_guess(misplaced), "An old per-cell rejection applies to its whole code")
			await click(key(main, repeated))
			check(
				key(main, repeated).get("letter_state") == StageLetterButton.LetterState.CIRCLED
				and key(main, repeated).get("disabled"),
				"Completing the final occurrence resolves and locks the key"
			)
			for position: int in range(GameSession.letters.size()):
				if GameSession.letters[position] == repeated:
					check(!slots[position].number.visible, "Completing a repeat hides every matching code")
			var states_capture_dir := OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
			await get_tree().create_timer(1.25).timeout
			for resolved_letter: String in [absent, repeated]:
				var resolved_key := key(main, resolved_letter) as StageLetterButton
				check(
					!resolved_key._marker.visible and is_equal_approx(float(resolved_key._cipher_letter_fade.get("opacity")), 0.5)
					and resolved_key._label.get_theme_color("font_color") == StageLetterButton.UI_PALETTE.DISABLED,
					"Resolved keys settle gray with no marker and half opacity"
				)
			if window_size.x == 690 and !states_capture_dir.is_empty() and DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				var capture := states_capture_dir.path_join("word_cipher_states_%s.png" % language)
				check(get_viewport().get_texture().get_image().save_png(capture) == OK, "Capture orange and muted keys")
			var unique_position: int = 2 if language == "ru" else 5
			var unique: String = GameSession.letters[unique_position]
			await click(slots[unique_position].hit)
			await click(key(main, unique))
			check(
				key(main, unique).get("letter_state") == StageLetterButton.LetterState.CIRCLED
				and !slots[unique_position].number.visible,
				"Solving a single occurrence resolves its key and hides its code"
			)
			var next_letter: String = GameSession.cipher_letters[GameSession.selected_position]
			for _attempt in range(GameSession.get_remaining_attempts()):
				for letter: String in Database.get_alphabet():
					if GameSession.can_guess(letter) and !GameSession.matches_guess(letter):
						main._press_letter(letter)
						break
			var other_position: int = 6 if language == "ru" else 4
			check(GameSession.has_deferred_loss() and !GameSession.select_position(other_position), "Last chance blocks both guesses and selection")
			check(GameSession.grant_deferred_attempt() and GameSession.can_guess(next_letter), "Continuation re-enables input")
			if window_size.x == 690:
				await check_long_word(main, language)
			main.queue_free()
			await get_tree().process_frame
		GameSession.start_round(source, GameState.GameMode.SINGLE_PLAYER, true, true, GameSession.CROSTIC_PUZZLE.quote_for_stage(language, 0, 0))
		while GameSession.is_active and GameSession.selected_position in range(GameSession.letters.size()):
			GameSession.guess(GameSession.cipher_letters[GameSession.selected_position])
		var unfinished_clue: bool = false
		for position: int in range(GameSession.letters.size(), GameSession.cipher_letters.size()):
			unfinished_clue = unfinished_clue or !GameSession.is_cipher_position_revealed(position)
		check(GameSession.is_word_completed() and !GameSession.is_active and unfinished_clue,
			"The quote wins while a clue still has blanks")
	GameSession.start_round(WordData.new("A-A B'B’C", 0.0, -1, -1), GameState.GameMode.SINGLE_PLAYER, true)
	for position: int in [1, 3, 5, 7]:
		check(GameSession.cipher_codes[position] == 0 and GameSession.revealed[position] and !GameSession.select_position(position), "Separators are visible, unnumbered and inert")
	GameSession.start_round(WordData.new("A", 0.0, -1, -1), GameState.GameMode.SINGLE_PLAYER, true)
	check(GameSession.selected_position == 0 and !GameSession.revealed[0], "Single-letter word stays playable")
	check(GameSession.guess("A") and !GameSession.is_active and GameSession.is_word_completed(), "Last closed cell completes the word")
	GameSession.start_round(WordData.new("ABBB", 0.0, -1, -1), GameState.GameMode.SINGLE_PLAYER, true)
	check(GameSession.guess("B") and !GameSession.is_active and GameSession.is_word_completed(), "A group can complete every remaining cell in one move")
	print("WORD_CIPHER checks=%d failures=%d" % [checks, failures])
	get_tree().quit(1 if failures else 0)

func check_quote(main: Node, source: WordData, language: String, window_size: Vector2i) -> void:
	var quote: String = GameSession.CROSTIC_PUZZLE.quote_for_stage(language, 0, 0)["text"]
	check(GameSession.get_full_word() == quote and GameSession.word_data.text == source.text,
		"Campaign starts a quote with the original catalog identity")
	check(GameSession.cipher_clues.size() == 2 and main._portrait_crostic_clue_rows.size() == 2,
		"The quote starts with two independent clue answers")
	if GameSession.cipher_clues.size() != 2 or main._portrait_crostic_clue_rows.size() != 2:
		return
	var quote_slots: Array = main._portrait_game_word_slots_root.get_meta("word_slots_cache")["slots"]
	var comma: int = quote.find(",")
	check(comma >= 0 and GameSession.cipher_codes[comma] == 0 and quote_slots[comma].label.visible
		and !quote_slots[comma].has("hit"), "Quote punctuation is visible and unnumbered")
	var hint: Control = main._portrait_game_hint_button_for_key(GameState.HINT_COMMENT)
	var keyboard_first: Control = main._portrait_game_keyboard_buttons.front().button
	var keyboard_last: Control = main._portrait_game_keyboard_buttons.back().button
	check(hint.get_global_rect().end.y < keyboard_first.get_global_rect().position.y
		and float(keyboard_last.get("stage_rect").end.y) > main.PORTRAIT_FOOTER_Y,
		"Hint buttons are above the lowered keyboard")
	var clue_positions: Array[Dictionary] = main._portrait_crostic_clue_rows
	var scroll: ScrollContainer = main._portrait_crostic_clue_block
	var scroll_rect: Rect2 = scroll.get_global_rect()
	check(scroll.clip_contents and scroll_rect.position.y > main._portrait_game_word_paper_backside.get_global_rect().end.y
		and scroll_rect.end.y < hint.get_global_rect().position.y, "The scroll viewport is clipped between the paper and the hints")
	var selectable: Dictionary = {}
	var previous_row_bottom: float = scroll_rect.position.y - 1.0
	var swipe_cell: Control = null
	for index: int in range(clue_positions.size()):
		var clue: Dictionary = GameSession.cipher_clues[index]
		var catalog: Dictionary = Database.resolve_saved_word(Database.get_theme_id(source.theme_index), clue["word"], clue["word_id"])
		check(catalog.get("hint") == clue["hint"], "Clue uses the original catalog definition")
		var clue_row: Dictionary = clue_positions[index]
		var root: Control = clue_row["slots"]
		var definition: Label = root.get_parent().find_child("CrosticDefinition%d" % index, true, false)
		var slots: Array = root.get_meta("word_slots_cache")["slots"]
		var first_cell: Rect2 = slots[0].hit.get_global_rect()
		check(definition.get_global_rect().position.y > previous_row_bottom
			and definition.get_global_rect().end.y <= first_cell.position.y + 1.0,
			"Each full-width clue starts on its own line below the previous clue")
		previous_row_bottom = first_cell.end.y
		if index == 0:
			swipe_cell = slots[0].hit
		check(definition.get_line_count() == definition.get_visible_line_count(),
			"The full catalog definition is visible")
		for cell: int in range(slots.size()):
			var quote_position: int = GameSession.letters.find(slots[cell]["letter"])
			if index == 1 and quote_position >= 0 and !GameSession.revealed[quote_position] and slots[cell].has("hit"):
				selectable = {"slot": slots[cell], "quote_position": quote_position, "index": cell + int(clue_row["start"])}
				break
	check(!selectable.is_empty(), "The second clue links to a hidden quote letter")
	if selectable.is_empty():
		return
	if DisplayServer.get_name() != "headless":
		var capture_dir := OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
		if !capture_dir.is_empty():
			await RenderingServer.frame_post_draw
			var path: String = "crostic_quote_%s_%dx%d.png" % [language, window_size.x, window_size.y]
			check(get_viewport().get_texture().get_image().save_png(capture_dir.path_join(path)) == OK, "Capture the quote layout")
	var slot: Dictionary = selectable["slot"]
	var quote_position: int = selectable["quote_position"]
	var paper_position: Vector2 = main._portrait_game_word_paper_backside.get_global_rect().position
	var keyboard_position: Vector2 = keyboard_first.get_global_rect().position
	var scroll_bar: VScrollBar = scroll.get_v_scroll_bar()
	if window_size.x == 960:
		check(scroll_bar.visible and scroll_bar.max_value > scroll_bar.page,
			"Clues that overflow have a visible scrollbar")
		check(!scroll_rect.has_point(slot.hit.get_global_rect().get_center()), "The second answer starts outside the clip")
		var selected_before_drag: int = GameSession.selected_position
		await swipe_up(swipe_cell.get_global_rect().get_center())
		check(scroll.scroll_vertical > 0 and GameSession.selected_position == selected_before_drag,
			"Dragging a clue moves the viewport without selecting a letter")
	else:
		check(!scroll_bar.visible and scroll_rect.has_point(slot.hit.get_global_rect().get_center()),
			"Both clues fit without a scrollbar on the taller screen")
	scroll.ensure_control_visible(slot.hit)
	await get_tree().process_frame
	check(scroll_rect.has_point(slot.hit.get_global_rect().get_center())
		and main._portrait_game_word_paper_backside.get_global_rect().position == paper_position
		and keyboard_first.get_global_rect().position == keyboard_position, "Scrolling keeps the paper and keyboard fixed")
	var scroll_before_guess: int = scroll.scroll_vertical
	await click(slot.hit)
	check(quote_slots[quote_position].selection.visible, "Second clue selection highlights its quote cells")
	await click(key(main, slot.letter))
	check(slot.label.visible and quote_slots[quote_position].label.visible, "Second clue reveals the shared letter in the quote")
	check(scroll.scroll_vertical == scroll_before_guess, "A guess preserves the scroll position")
	var codes: PackedInt32Array = GameSession.cipher_codes.duplicate()
	GameState.load_game()
	var saved: Dictionary = GameState.get_active_single_player_session().get("data", {})
	check(GameSession.restore_from_save_data(saved)
		and GameSession.get_full_word() == quote and GameSession.cipher_codes == codes
		and GameSession.is_cipher_position_revealed(selectable["index"])
		and GameSession.cipher_clues.size() == 2, "Save and resume keep the quote, two clues and solved group")

func check_hints(main: Node) -> void:
	var hint_text: String = GameSession.get_word_hint().strip_edges()
	var matching_labels: Array[Node] = main.find_children("*", "Label", true, false).filter(
		func(label: Label) -> bool: return label.is_visible_in_tree() and label.text == hint_text
	)
	check(matching_labels.is_empty(), "Catalog comment is hidden before using its hint")
	var coins: int = GameState.get_soft_currency()
	var count: int = GameState.get_hint_count(GameState.HINT_COMMENT)
	for hint_key: String in [GameState.HINT_OPEN_LETTER, GameState.HINT_REMOVE_WRONG]:
		var button: Control = main._portrait_game_hint_button_for_key(hint_key)
		check(is_instance_valid(button) and button.is_visible_in_tree() and button.get("disabled"), hint_key + " is visible and locked")
		if is_instance_valid(button):
			await click(button)
	check(
		!GameSession.open_hint_used and !GameSession.remove_wrong_hint_used
		and !GameSession.can_use_open_letter_hint() and !GameSession.can_use_remove_wrong_hint()
		and !GameSession.can_use_open_letter_hint_ad() and !GameSession.can_use_remove_wrong_hint_ad()
		and GameState.get_soft_currency() == coins,
		"Locked buttons cannot apply hints or charge coins"
	)
	var comment: Control = main._portrait_game_hint_button_for_key(GameState.HINT_COMMENT)
	check(is_instance_valid(comment) and comment.is_visible_in_tree() and !comment.get("disabled"), "Comment uses the enabled third button")
	if !is_instance_valid(comment):
		return
	await click(comment)
	await get_tree().create_timer(3.0).timeout
	var popup: Node = get_tree().get_first_node_in_group(&"word_comment_popup")
	check(popup != null and GameSession.can_view_comment_hint(), "Comment hint opens the standard popup")
	if popup != null:
		var label := popup.find_child("WordCommentText", true, false) as Label
		check(label != null and label.is_visible_in_tree() and label.text == hint_text, "Popup contains the catalog comment")
		var capture_dir := OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
		if !capture_dir.is_empty() and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			var capture: String = "word_cipher_comment_%s_%d.png" % [Database.current_language, get_window().size.x]
			check(get_viewport().get_texture().get_image().save_png(capture_dir.path_join(capture)) == OK, "Capture comment popup")
	var remaining_coins: int = coins if count > 0 else coins - GameState.get_hint_cost(GameState.HINT_COMMENT)
	var remaining_count: int = maxi(0, count - 1)
	check(GameState.get_soft_currency() == remaining_coins and GameState.get_hint_count(GameState.HINT_COMMENT) == remaining_count, "First view pays the standard price")
	main._remove_word_comment_popup()
	await get_tree().create_timer(3.0).timeout
	comment = main._portrait_game_hint_button_for_key(GameState.HINT_COMMENT)
	if is_instance_valid(comment):
		await click(comment)
	check(get_tree().get_first_node_in_group(&"word_comment_popup") != null and GameState.get_soft_currency() == remaining_coins and GameState.get_hint_count(GameState.HINT_COMMENT) == remaining_count, "Reopening the comment is free")
	main._remove_word_comment_popup()
	await get_tree().create_timer(3.0).timeout

func check_long_word(main: Node, language: String) -> void:
	var source: WordData = fixture("БЕСПРОВОДНЫЕ НАУШНИКИ" if language == "ru" else "VOLCANIC ARCHIPELAGO")
	check(source != null, "Catalog has the long compound fixture")
	if source == null:
		return
	get_window().size = Vector2i(1080, 1920)
	GameSession.start_round(source, GameState.GameMode.SINGLE_PLAYER, true, true)
	main.show_game_screen()
	await get_tree().create_timer(4.0).timeout
	var slots: Array = main._portrait_game_word_slots_root.get_meta("word_slots_cache")["slots"]
	var last: Dictionary = slots.back()
	var first_rect: Rect2 = slots[0].hit.get_global_rect()
	var last_rect: Rect2 = last.hit.get_global_rect()
	check(last_rect.position.y >= first_rect.end.y and last_rect.size.x >= 40.0, "Long answer wraps to a second touchable row")
	var paper: Rect2 = main._portrait_game_word_paper_rect(main._portrait_game_word_rect)
	var reverse: Control = main._portrait_game_word_paper_backside
	var reverse_rect: Rect2 = reverse.get("stage_rect")
	var last_number_rect: Rect2 = last.number.get_parent().get("stage_rect")
	check(
		paper.size.y > main.PORTRAIT_GAME_WORD_PAPER_HEIGHT
		and is_equal_approx(paper.size.y, reverse_rect.size.y)
		and is_equal_approx(paper.position.y, reverse_rect.position.y)
		and last_number_rect.end.y < paper.end.y,
		"The enlarged two-row sheet contains the numbers and matches its reverse"
	)
	check(!main._portrait_crostic_clue_rows.is_empty() and main._portrait_crostic_clue_rows[0].rect.position.y > paper.end.y,
		"The clue stays below the enlarged sheet")
	main._set_portrait_word_paper_peel_progress(0.5)
	var half_peeled_rect: Rect2 = reverse.get("stage_rect")
	check(
		is_equal_approx(half_peeled_rect.position.y, paper.position.y)
		and is_equal_approx(half_peeled_rect.size.y, paper.size.y),
		"The enlarged reverse keeps its height during the peel"
	)
	main._set_portrait_word_paper_peel_progress(0.0)
	var space: int = source.text.find(" ")
	var separator: Dictionary = slots[space]
	check(!separator.has("number") and !separator.has("hit"), "Space has no number or hit area")
	var before_space: Control = slots[space - 1].hit
	var after_space: Control = slots[space + 1].hit
	check(before_space.get_global_rect().position.y == first_rect.position.y and after_space.get_global_rect().position.y == last_rect.position.y, "Wrap follows the word boundary when both words fit")
	await click(last.hit)
	check(GameSession.selected_position == slots.size() - 1 and last.selection.visible, "Last cell can be selected on the second row")
	await click(key(main, last.letter))
	check(
		last.label.visible and last.label.get_theme_font_size("font_size") == 34
		and last.label.get_visible_line_count() == 1 and !last.number.visible,
		"Second row shows the full-size letter and hides its completed code"
	)
	for slot: Dictionary in slots:
		if slot.letter == last.letter:
			check(slot.label.visible and !slot.number.visible, "Group reveal also updates matches on other rows")
	var capture_dir := OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
	if !capture_dir.is_empty() and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var image: Image = get_viewport().get_texture().get_image()
		check(image.get_size() == Vector2i(1080, 1920) and image.save_png(capture_dir.path_join("word_cipher_long_%s.png" % language)) == OK, "Capture long answer")
