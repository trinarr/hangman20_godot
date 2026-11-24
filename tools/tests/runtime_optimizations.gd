extends Node

# Run through run_reward_tests.py --suite runtime_optimizations for save isolation.
var main: Node
var checks: int = 0
var failures: Array[String] = []
var balance_notifications: int = 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if !condition:
		failures.append(message)
		push_error(message)

func _process(_delta: float) -> void:
	# Home transitions await a GPU fence that the dummy renderer never emits.
	if DisplayServer.get_name() == "headless":
		RenderingServer.frame_post_draw.emit()
	elif OS.get_environment("HANGMAN_TEST_HIDE_WINDOW") == "1":
		RenderingServer.force_draw(false)

func _ready() -> void:
	call_deferred("run")

func click_control(control: Control) -> void:
	var point: Vector2 = control.get_global_rect().get_center()
	for down: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		get_viewport().push_input(event, true)
		await get_tree().process_frame

func crossword_key(letter: String) -> StageLetterButton:
	for entry: Dictionary in main._portrait_game_keyboard_buttons:
		if entry.letter == letter:
			return entry.button
	return null

func test_crossword() -> void:
	var design = GameSession.GAME_DESIGN
	for level: int in [2, 3, 4, 10, 11, 20, 21, 30]:
		check(design.level_crossword_word_count(level) == design.level_stage_count_with_bonus(level), "Initial crossword balance differs from the stage counts")
	for language: String in ["ru", "en"]:
		GameState.set_word_language(language)
		Database.load_languages(language, language)
		for size: Vector2i in [Vector2i(960, 1600), Vector2i(690, 1536)]:
			get_window().min_size = size
			get_window().size = size
			get_window().content_scale_size = size
			await get_tree().process_frame
			var level_index: int = 29 if size.x == 960 else 39
			var theme: int = Database.get_theme_index_by_id(9 if size.x == 960 else 2)
			main._clear()
			GameState._single_player_bucket(language)["unlocked_level"] = level_index
			GameState.select_single_level_theme(language, level_index, theme, design.level_stage_count_with_bonus(level_index + 1))
			main._invalidate_single_player_level_cache()
			main._start_single_player_word(level_index, 0)
			await get_tree().create_timer(1.6).timeout
			var root: Control = main._portrait_crossword
			var board: RefCounted = GameSession.crossword
			check(is_instance_valid(root) and main.hero_static_symbol == null, "Word level %d (%s, %s) must show the crossword without a character" % [level_index + 1, language, size])
			if !is_instance_valid(root) or board == null:
				return
			var pattern_clip := main.content.get_node_or_null("PortraitGameBackground/PortraitGameThemePattern") as Control
			var pattern_motion := main.content.get_node_or_null("PortraitGameBackground/PortraitGameThemePattern/PatternMotion") as Control
			check(is_instance_valid(pattern_clip) and is_instance_valid(pattern_motion), "Crossword uses the shared animated theme pattern")
			if !is_instance_valid(pattern_clip) or !is_instance_valid(pattern_motion):
				return
			var theme_icon: Texture2D = main._theme_icon_mono_texture(theme)
			check(theme_icon != null and pattern_motion.get_child_count() > 0 and pattern_motion.get_child(0).texture == theme_icon, "Crossword pattern shows the active theme icon")
			check(pattern_clip.mouse_filter == Control.MOUSE_FILTER_IGNORE and pattern_motion.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Crossword pattern does not intercept input")
			var pattern_tween: Tween = pattern_motion.get_meta("pattern_move_tween", null)
			check(pattern_tween != null and pattern_tween.is_running(), "Crossword theme pattern is moving")
			check(board.entries.size() == 7, "Bonus crossword must contain seven words")
			var occupied: Dictionary = {}
			for entry: Dictionary in board.entries:
				var start := Vector2i(entry.x, entry.y)
				var direction := Vector2i.DOWN if entry.vertical else Vector2i.RIGHT
				var crosses: bool = false
				var word: String = entry.text
				check(!word.contains(" "), "Crossword must contain only entries without spaces")
				for i: int in range(word.length()):
					var point: Vector2i = start + direction * i
					if occupied.has(point):
						crosses = true
						check(occupied[point] == word[i], "Crossing letters differ")
					occupied[point] = word[i]
				check(crosses or entry == board.entries[0], "A crossword word is detached")
			check(occupied.size() == root._tiles.size(), "Intersections share a single tile")
			var numbers: Dictionary = {}
			var glyphs: Array = root._glyphs.duplicate()
			var initial_revealed: Array = GameSession.revealed.duplicate()
			var starters: PackedStringArray = GameSession.crossword_starter_letters.duplicate()
			var level_title := main._portrait_top_bar_content.find_child("GameLevelTitle", true, false) as Label
			var expected_title: String = ("УРОВЕНЬ %d" if language == "ru" else "LEVEL %d") % (level_index + 1)
			check(is_instance_valid(level_title) and level_title.text == expected_title, "Word header shows the current localized level")
			if !is_instance_valid(level_title):
				return
			var level_rect: Rect2 = level_title.get_global_rect()
			check(!is_instance_valid(main._portrait_header_fill) and !is_instance_valid(main._portrait_currency_counter_visual) and !is_instance_valid(main._portrait_star_counter_visual), "Word header has no backdrop or resource counters")
			var labels: Array[Node] = main.content.find_children("*", "Label", true, false)
			check(labels.all(func(label: Label) -> bool: return label.text != tr("ATTEMPTS_LABEL")), "Word screen has no attempts block")
			var card := root.get_node("StageQuestionCard") as FlashStagePanel
			var title := card.find_child("StageQuestionThemeTitle", true, false) as Label
			var first_hint: Control = main._portrait_game_hint_buttons[0]
			var panel_rect: Rect2 = card.get_global_rect()
			var title_rect: Rect2 = title.get_global_rect()
			var fit: float = main.PORTRAIT_STAGE_LAYOUT.fit_scale(get_viewport().get_visible_rect().size)
			check(card.stage_rect.size.x == main.PORTRAIT_QUIZ_QUESTION_PANEL_RECT.size.x and card.stage_rect.size.y > main.PORTRAIT_QUIZ_QUESTION_PANEL_RECT.size.y, "Crossword card uses the quiz width and extends farther down")
			var quiz_title_offset: Vector2 = main.PORTRAIT_QUIZ_THEME_TITLE_RECT.position - main.PORTRAIT_QUIZ_QUESTION_PANEL_RECT.position
			var expected_title_position: Vector2 = panel_rect.position + quiz_title_offset * fit
			check(title.text == Database.get_theme_name(theme) and title_rect.position.distance_to(expected_title_position) < fit and title_rect.end.y > panel_rect.position.y, "Title keeps the quiz card offset across the top border: %s / %s" % [title_rect, expected_title_position])
			var nav_rect: Rect2 = main._portrait_game_back_button.get_global_rect()
			check(level_rect.end.y < title_rect.position.y and is_equal_approx(level_rect.get_center().x, panel_rect.get_center().x), "Level title is centered above the crossword and its theme")
			var attempts: Control = main._portrait_attempt_indicators
			var attempts_rect: Rect2 = attempts.get_global_rect()
			var header_center: Vector2 = level_rect.merge(attempts_rect).get_center()
			check(level_rect.end.y < attempts_rect.position.y and is_equal_approx(header_center.y, nav_rect.get_center().y) and level_rect.position.x > nav_rect.end.x, "Level title and attempts sit centered as a group beside navigation")
			check(attempts.total == 3 and attempts.remaining == 3 and is_equal_approx(attempts_rect.get_center().x, level_rect.get_center().x), "Three empty attempts are centered under the title at the start")
			check(card.stage_rect.position.y == main.PORTRAIT_QUIZ_QUESTION_PANEL_RECT.position.y, "Crossword reuses the quiz card top offset")
			check(is_equal_approx(first_hint.get_global_rect().position.y - panel_rect.end.y, main.PORTRAIT_CROSSWORD_CARD_HINT_GAP * fit), "Card bottom follows the hints on the adapted viewport")
			var text_effect := level_title.get_node_or_null(NodePath(String(DisplayTextEffect.EFFECT_NODE_NAME))) as DisplayTextEffect
			check(level_title.get_theme_font("font") == main.UI_REGULAR_FONT and is_instance_valid(text_effect), "Level title uses the reward subtitle font and text effect")
			check(level_title.get_theme_font_size("font_size") == 24, "Level title renders at the reward subtitle size")
			var letter_font: Font = main.UI_FONTS.gameplay_word_font()
			for i: int in range(glyphs.size()):
				var tile: Control = root._tiles[i]
				var tile_rect: Rect2 = tile.get_global_rect()
				check(panel_rect.encloses(tile_rect) and tile_rect.position.y > title_rect.end.y, "Tile stays inside the card and below its theme title")
				if glyphs[i] == null:
					continue
				var number_label := tile.find_child("Number", true, false) as Label
				check(number_label.get_theme_font("font") == main.UI_REGULAR_FONT and glyphs[i].get_theme_font("font") == letter_font, "Crossword cell uses Roboto Flex")
				var letter: String = board.letters[i]
				var number: String = number_label.text
				check(glyphs[i].visible == initial_revealed[i] and number == numbers.get(letter, number), "Equal letters share a number and only starter cells are initially visible")
				numbers[letter] = number
			var distinct_numbers: Dictionary = {}
			for number: String in numbers.values():
				distinct_numbers[number] = true
			check(numbers.size() == distinct_numbers.size(), "Different letters must have different numbers")
			var directory: String = OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
			if DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				var frame: Image = get_viewport().get_texture().get_image()
				var field: Rect2i = Rect2i(pattern_clip.get_global_rect())
				field.size.y = mini(field.size.y, int(title_rect.end.y) - field.position.y + 100)
				pattern_clip.hide()
				await RenderingServer.frame_post_draw
				var plain: Image = get_viewport().get_texture().get_image()
				pattern_clip.show()
				check(frame.get_region(field).get_data() != plain.get_region(field).get_data(), "Crossword theme pattern contributes visible pixels behind the playfield")
				if !directory.is_empty():
					frame.save_png(directory.path_join("crossword_%s_%d.png" % [language, size.x]))
			var lives: int = GameSession.get_remaining_attempts()
			var shared_letter: String = ""
			for letter: String in numbers:
				if !starters.has(letter) and board.letters.count(letter) >= 2:
					shared_letter = letter
					break
			check(!shared_letter.is_empty(), "The grid has a repeated unknown letter for keyboard tests")
			if shared_letter.is_empty():
				return
			var selected_index: int = board.letters.find(shared_letter)
			var matching_count: int = board.letters.count(shared_letter)
			var key := crossword_key(shared_letter)
			check(!starters.is_empty() and root.selected_cell >= 0 and board.letters[root.selected_cell] == starters[0], "Late campaign levels also focus the first starter")
			await click_control(root._tiles[selected_index])
			check(root.selected_cell == selected_index and root._tiles[selected_index].get_theme_stylebox("panel").bg_color == main.PORTRAIT_UI_PALETTE.BUTTON_ORANGE, "Click highlights one hidden cell in orange")
			for letter: String in Database.get_alphabet():
				if !GameSession.letters.has(letter):
					main._press_letter(letter)
					main._press_letter(letter)
					break
			check(GameSession.get_remaining_attempts() == lives - 1, "A repeated wrong key consumed more than one attempt")
			check(attempts.remaining == 2, "Only the first marker changes after a repeated wrong key")
			check(root.selected_cell == selected_index, "A wrong guess keeps the selected cell")
			main._press_letter(shared_letter)
			for i: int in range(glyphs.size()):
				if glyphs[i] == null:
					continue
				check(glyphs[i].visible == (initial_revealed[i] or i == selected_index), "A correct key reveals only the selected cell")
			check(!key.disabled and key._label.get_theme_color("font_color") == main.PORTRAIT_UI_PALETTE.SUCCESS_BORDER and !key._count_label.visible, "A correct key starts its bounce in green without a counter")
			check(root._glyphs == glyphs and main._portrait_word_letter_bounce_active_count == 1, "Guess reuses cell nodes and animates only the selection")
			main._refresh_portrait_game_runtime_state()
			check(main._portrait_word_letter_bounce_active_count == 1, "Refresh interrupted an active letter animation")
			await get_tree().create_timer(0.7).timeout
			check(main._portrait_word_letter_bounce_active_count == 0, "Letter animations did not complete")
			check(key._label.get_theme_color("font_color") == main.PORTRAIT_UI_PALETTE.MARKER_ORANGE_TEXT and key._count_label.visible and key._count_label.text == str(matching_count - 1), "A correct key turns orange with its exact remaining count after the bounce")
			if DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				var frame: Image = get_viewport().get_texture().get_image()
				var first_center: Vector2 = attempts_rect.get_center() - Vector2(main.PORTRAIT_ATTEMPT_INDICATORS.SPACING * fit, 0.0)
				var crossed: Color = frame.get_pixelv(Vector2i(first_center))
				var empty: Color = frame.get_pixelv(Vector2i(attempts_rect.get_center()))
				check(crossed.r > 0.8 and crossed.g < 0.5 and empty.r < 0.7, "A red cross is drawn only inside the spent circle")
				check(key.get_global_rect().encloses(key._count_label.get_global_rect()), "The active orange key displays its counter inside the key face")
				if !directory.is_empty():
					frame.save_png(directory.path_join("crossword_revealed_%s_%d.png" % [language, size.x]))
			var misplaced_letter: String = ""
			var target_index: int = -1
			for i: int in range(glyphs.size()):
				if !GameSession.can_guess_cell(i) or !GameSession.get_known_crossword_letter(i).is_empty():
					continue
				if misplaced_letter.is_empty():
					misplaced_letter = board.letters[i]
				elif board.letters[i] != misplaced_letter:
					target_index = i
					break
			check(target_index >= 0, "The grid has two unknown codes for a misplaced guess")
			if target_index < 0:
				return
			var misplaced_count: int = board.letters.count(misplaced_letter)
			var misplaced_key := crossword_key(misplaced_letter)
			root.select_cell(target_index)
			await click_control(misplaced_key)
			check(!GameSession.revealed[target_index] and root.selected_cell == target_index and attempts.remaining == 1, "A misplaced guess spends an attempt and retains the selection")
			check(!misplaced_key.disabled and misplaced_key._label.get_theme_color("font_color") == main.PORTRAIT_UI_PALETTE.MARKER_ORANGE_TEXT and misplaced_key._count_label.visible and misplaced_key._count_label.text == str(misplaced_count), "An untried letter in another cell is immediately marked orange with a counter")
			var snapshot: Dictionary = GameSession.to_save_data()
			var stored: Dictionary = GameState._read_save_dictionary(GameState.SAVE_PATH)
			check(stored.active_single_player_session.data.has("crossword"), "Board entries were not written to the player save")
			main._clear()
			check(GameSession.restore_from_save_data(stored.active_single_player_session.data), "Saved board failed to restore")
			main.show_game_screen()
			await get_tree().process_frame
			check(GameSession.to_save_data() == snapshot and main._portrait_crossword != root, "Reopened stage lost its layout, reveal state or attempt count")
			check(main._portrait_attempt_indicators.remaining == 1, "Reopened stage restores the used markers")
			check(!is_instance_valid(pattern_motion), "Reopening the stage removes the old background nodes")
			var reopened_title := main._portrait_top_bar_content.find_child("GameLevelTitle", true, false) as Label
			check(is_instance_valid(reopened_title) and reopened_title != level_title and reopened_title.text == expected_title, "Reopened stage rebuilds the same level title")
			await get_tree().create_timer(1.6).timeout
			var reopened: Control = main._portrait_crossword
			key = crossword_key(shared_letter)
			check(GameSession.revealed.count(true) == initial_revealed.count(true) + 1 and !key.disabled and key.remaining_count == matching_count - 1, "Resume restores starters, the guessed cell, and its counter")
			check(reopened.selected_cell == GameSession.revealed.find(false), "Resume selects the first hidden cell")
			misplaced_key = crossword_key(misplaced_letter)
			check(!misplaced_key.disabled and misplaced_key._count_label.visible and misplaced_key.remaining_count == misplaced_count and misplaced_key._label.get_theme_color("font_color") == main.PORTRAIT_UI_PALETTE.MARKER_ORANGE_TEXT, "Resume restores a letter discovered by a misplaced guess")
			for i: int in range(board.letters.size()):
				if board.letters[i] == shared_letter and !GameSession.revealed[i]:
					reopened.select_cell(i)
					main._press_letter(shared_letter)
			check(key.disabled and !key._count_label.visible, "The last matching cell disables its key and removes the counter")
			if language == "en" and size.x == 690:
				for i: int in range(board.entries[0].text.length()):
					if !GameSession.revealed[i]:
						reopened.select_cell(i)
						main._press_letter(board.letters[i])
				check(GameSession.is_active, "Solving only the original word finished the board")
				for _i: int in range(GameSession.revealed.count(false)):
					if reopened.selected_cell < 0:
						break
					main._press_letter(board.letters[reopened.selected_cell])
				check(!GameSession.is_active and main.game_finished, "Solving the complete grid did not finish its stage")
				check(reopened.selected_cell == -1, "A completed grid has no selected cell")
			main._clear()
			await get_tree().process_frame
			check(!is_instance_valid(root), "Leaving the screen retained the previous crossword")
			check(pattern_tween == null or !pattern_tween.is_valid(), "The engine releases the old background tween after freeing its owner")

	main.game_finished = false
	GameSession.start_round(WordData.new("GRID", 0.2, -1, -1), GameState.GameMode.TWO_PLAYER)
	main.show_game_screen()
	await get_tree().process_frame
	check(main._portrait_game_entrance_active, "Close test must interrupt a running grid entrance")
	var closing_grid: Control = main._portrait_crossword
	main._clear()
	check(!main._portrait_game_entrance_active, "Closing the grid did not cancel its entrance")
	await get_tree().create_timer(1.6).timeout
	check(!is_instance_valid(closing_grid) and !main._portrait_game_entrance_active, "An old grid entrance survived screen closure")

func test_crossword_selection() -> void:
	GameState.current_mode = GameState.GameMode.TWO_PLAYER
	main.game_finished = false
	GameSession.start_round(WordData.new("C-AT", 0.2, -1, -1), GameState.GameMode.TWO_PLAYER)
	var board: RefCounted = GameSession.WORD_CROSSWORD.restore("C-AT", [
		{"text": "C-AT", "x": 0, "y": 0, "vertical": false},
		{"text": "ABLE", "x": 2, "y": 0, "vertical": true},
		{"text": "ELK", "x": 1, "y": 2, "vertical": false},
	])
	check(board != null, "Selection fixture must form a valid crossword")
	if board == null:
		return
	GameSession.crossword = board
	GameSession.letters = board.letters
	while GameSession.revealed.size() < board.letters.size():
		GameSession.revealed.append(false)
	main.show_game_screen()
	await get_tree().create_timer(1.6).timeout
	var grid: Control = main._portrait_crossword
	check(is_instance_valid(grid) and grid._input_enabled, "The selection fixture accepts input after the entrance")
	var first: int = board.cells[Vector2i.ZERO]
	var shared_start: int = board.cells[Vector2i(2, 0)]
	var last: int = board.cells[Vector2i(3, 0)]
	check(grid.selected_cell == first, "The initial selection is the first cell of the first word")
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_C
	key.unicode = "C".unicode_at(0)
	get_viewport().push_input(key)
	check(GameSession.revealed[first] and grid.selected_cell == shared_start, "Keyboard input works without a click and advances past the separator")
	await click_control(grid._tiles[last])
	main._press_letter("T")
	check(grid.selected_cell == shared_start, "Guessing the last cell wraps to the first hidden cell of the same word")
	main._press_letter("A")
	check(grid.selected_cell == board.cells[Vector2i(2, 1)], "Finishing a word skips the revealed start of the next word")
	main._press_letter("B")
	check(grid.selected_cell == board.cells[Vector2i(2, 2)], "Selection advances to the next vertical cell")
	main._press_letter("L")
	check(grid.selected_cell == board.cells[Vector2i(2, 3)], "Guessing a crossing cell continues in the current word")
	main._press_letter("E")
	check(grid.selected_cell == board.cells[Vector2i(1, 2)], "Finishing the vertical word selects the first cell of the next word")
	main._clear()
	await get_tree().process_frame

func test_crossword_starters() -> void:
	GameState.current_mode = GameState.GameMode.SINGLE_PLAYER
	main.single_player_active_level_index = 0
	main.single_player_active_word_slot = -1
	for language: String in ["ru", "en"]:
		GameState.interface_language = language
		GameState.set_word_language(language)
		Database.load_languages(language, language)
		var theme: int = Database.get_theme_index_by_id(9)
		var word_text: String = "ВЛОГ" if language == "ru" else "SHELF"
		var word: WordData
		for entry: Dictionary in Database.get_words_by_index(theme):
			if entry.text == word_text:
				word = WordData.new(word_text, entry.difficulty, theme, entry.index, entry.id)
				break
		check(word != null, "The adaptive starter test uses an ambiguous catalog word")
		if word == null:
			return
		for size: Vector2i in [Vector2i(960, 1600), Vector2i(690, 1536)]:
			get_window().min_size = size
			get_window().size = size
			get_window().content_scale_size = size
			await get_tree().process_frame
			main.game_finished = false
			GameSession.start_round(word)
			var cells: PackedInt32Array = GameSession.crossword_starter_cells
			check(cells.size() == 2, "An ambiguous %s grid receives two starter codes by default" % language)
			if cells.is_empty():
				return
			check(GameSession.get_remaining_attempts() == GameSession.attempt_limit and GameSession.correct_letters.is_empty() and !GameSession.open_hint_used, "Starting codes are free")
			main.show_game_screen()
			await get_tree().create_timer(1.6).timeout
			var grid: Control = main._portrait_crossword
			var starter_label: Label = grid.get("_starter_label")
			check(starter_label != null and starter_label.get_global_rect().end.y < grid._grid.global_position.y and grid.selected_cell == cells[0], "Starter pairs fit above the grid and focus the first copy")
			if starter_label != null:
				check(starter_label.text.count("=") == 2, "Both given codes are visible")
			var first_letter: String = GameSession.letters[cells[0]]
			var target: int = grid.selected_cell
			main._press_letter("А" if language == "ru" else "Z")
			check(GameSession.mistakes == 0 and !GameSession.revealed[target] and grid.selected_cell == target, "A mismatch on a given code is free and keeps the selection")
			await click_control(crossword_key(first_letter))
			check(GameSession.revealed[target], "A given code is copied through the keyboard")
			var snapshot: Dictionary = GameSession.to_save_data()
			main._clear()
			check(GameSession.restore_from_save_data(snapshot) and GameSession.to_save_data() == snapshot, "Resume uses the saved starters")
			await get_tree().process_frame
	GameSession.start_round(WordData.new("COCOA", 0.2, -1, -1))
	check(GameSession.crossword_starter_letters == PackedStringArray(["C"]) and GameSession.revealed == [true, false, false, false, false], "An unambiguous grid receives one code and opens only its example")

func pattern(clip: Control, motion: Control, textures: Array, color: Color = Color.WHITE, speed: float = 1.0) -> void:
	main._layout_multi_theme_pattern(clip, motion, textures, color, 1.0, 1.0, speed, 0.05, 0.35)

func test_pattern_reuse() -> void:
	var clip := Control.new()
	add_child(clip)
	clip.size = Vector2(480, 800)
	var motion := Control.new()
	clip.add_child(motion)
	var texture := GradientTexture2D.new()
	var textures: Array = [texture]
	pattern(clip, motion, textures)
	var nodes: Array[Node] = motion.get_children()
	var tween: Tween = motion.get_meta("pattern_move_tween")
	await get_tree().create_timer(0.1).timeout
	var position_before: Vector2 = motion.position
	pattern(clip, motion, textures)
	check(motion.get_children() == nodes, "Identical pattern recreated nodes")
	check(motion.get_meta("pattern_move_tween") == tween and motion.position == position_before, "Identical pattern restarted movement")
	clip.size.y += 300.0
	pattern(clip, motion, textures)
	check(motion.get_child(0) == nodes[0] and motion.get_child_count() > nodes.size(), "Growing pattern failed to reuse prefix")
	check(motion.get_meta("pattern_move_tween") == tween and motion.position == position_before, "Resize reset movement")
	clip.size.y = 400.0
	pattern(clip, motion, textures, Color(0.2, 0.4, 0.6, 0.5))
	check(motion.get_child(0) == nodes[0] and motion.get_child_count() < nodes.size(), "Shrinking pattern failed to reuse prefix")
	check(is_equal_approx(motion.get_child(0).modulate.r, 0.2), "Pattern color cache stayed stale")
	var replacement := GradientTexture2D.new()
	textures[0] = replacement
	pattern(clip, motion, textures)
	check(motion.get_child(0).texture == replacement, "Texture change did not invalidate cache")
	pattern(clip, motion, textures, Color.WHITE, 2.0)
	check(motion.get_meta("pattern_move_tween") != tween and !tween.is_valid(), "Changed speed kept old movement")
	clip.free()

func receipt(target: String, granted: bool = false) -> Dictionary:
	return {"context":"final", "target":target, "amount":10, "granted":granted}

func on_balance_changed(_balance: int) -> void:
	balance_notifications += 1

func test_receipt_compaction() -> void:
	GameState.soft_currency_changed.connect(on_balance_changed)
	GameState.single_player_resume_states = {}
	GameState.active_single_player_session = {}
	GameState.pending_single_player_reward = {}
	GameState.soft_currency = 100
	var legacy: Dictionary = {}
	for i: int in range(1000):
		legacy["paid:%d" % i] = receipt("target:%d" % i, true)
	legacy["paid-retry"] = receipt("target:0")
	legacy["late"] = receipt("old-unresolved")
	legacy["late-retry"] = receipt("old-unresolved")
	legacy["other"] = receipt("other-unresolved")
	GameState._load_rewarded_double_requests(legacy)
	check(GameState.rewarded_double_requests.size() == 3, "Legacy paid targets or their retries survived compaction")
	check(GameState.claim_rewarded_double_request("paid-retry").is_empty(), "Compacted paid retry granted again")
	check(GameState.save_game(), "Could not persist compacted receipts")
	GameState.load_game()
	check(GameState.rewarded_double_requests.size() == 3, "Reload discarded unresolved receipts")
	var result: Dictionary = GameState.claim_rewarded_double_request("late")
	check(result.get("amount") == 10 and !result.get("is_current"), "Late migrated receipt lost original payout")
	check(GameState.rewarded_double_requests.size() == 1 and GameState.rewarded_double_requests.has("other"), "Completed target did not remove all retries")
	GameState.load_game()
	check(GameState.claim_rewarded_double_request("late-retry").is_empty(), "Reload allowed paid retry")
	check(GameState.get_soft_currency() == 110, "Paid retry changed balance")
	var notifications_before: int = balance_notifications
	GameState._save_blocked_by_future_version = true
	check(GameState.claim_rewarded_double_request("other").is_empty(), "Failed save reported successful payout")
	check(GameState.get_soft_currency() == 110 and GameState.rewarded_double_requests.has("other"), "Failed save lost balance or receipt")
	check(balance_notifications == notifications_before, "Failed save notified UI of uncommitted payout")
	GameState._save_blocked_by_future_version = false
	check(GameState.claim_rewarded_double_request("other").get("amount") == 10, "Receipt could not retry after save failure")
	check(GameState.rewarded_double_requests.is_empty(), "Completed history kept growing")
	# Current offers must retain their double-claimed flag after receipt removal.
	GameState.pending_single_player_reward = GameState._normalize_pending_single_player_reward({
		"language":"ru", "level_index":4, "word_count":3, "amount":35,
	})
	GameState.claim_pending_single_player_reward()
	var request_id: String = GameState.begin_rewarded_double_request("final")
	var retry_id: String = GameState.begin_rewarded_double_request("final")
	check(!request_id.is_empty() and !retry_id.is_empty(), "Current offer did not create receipts")
	GameState._save_blocked_by_future_version = true
	check(GameState.claim_rewarded_double_request(request_id).is_empty(), "Current offer committed failed save")
	check(!GameState.pending_single_player_reward.get("double_claimed", false), "Failed save left current offer claimed")
	GameState._save_blocked_by_future_version = false
	check(GameState.claim_rewarded_double_request(request_id).get("amount") == 35, "Current offer amount changed")
	GameState.load_game()
	check(GameState.begin_rewarded_double_request("final").is_empty(), "Compaction allowed a new show for paid offer")
	check(GameState.claim_rewarded_double_request(retry_id).is_empty(), "Current retry paid twice after restart")
	check(GameState.rewarded_double_requests.is_empty(), "Current completed target remained on disk")

func run() -> void:
	GameState.interface_language = "ru"
	GameState.word_language = "ru"
	GameState.guided_onboarding_completed = true
	GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
	Database.load_languages("ru", "ru")
	main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	# Intermediate animation assertions need the game's normal frame/time ratio.
	Engine.time_scale = 1.0
	await test_crossword()
	await test_crossword_selection()
	await test_crossword_starters()
	await test_pattern_reuse()
	test_receipt_compaction()
	# Let asynchronous scene/texture loads and deferred Home work finish.
	await get_tree().create_timer(8.0).timeout
	main.queue_free()
	await get_tree().process_frame
	print("RUNTIME_OPTIMIZATIONS ", JSON.stringify({"checks":checks, "failures":failures}))
	get_tree().quit(0 if failures.is_empty() else 1)
