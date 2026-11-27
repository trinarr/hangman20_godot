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

func swipe_comment(grid: Control, offset: Vector2, touch: bool = false, canceled: bool = false) -> void:
	var start: Vector2 = grid._comment_swipe_area.get_global_rect().get_center()
	for down: bool in [true, false]:
		var event: InputEvent
		if touch:
			var screen_touch := InputEventScreenTouch.new()
			screen_touch.index = 0
			event = screen_touch
		else:
			var mouse_button := InputEventMouseButton.new()
			mouse_button.button_index = MOUSE_BUTTON_LEFT
			event = mouse_button
		event.position = start if down else start + offset
		event.pressed = down
		event.canceled = canceled and !down
		get_viewport().push_input(event, true)
		await get_tree().process_frame

func crossword_key(letter: String) -> StageLetterButton:
	for entry: Dictionary in main._portrait_game_keyboard_buttons:
		if entry.letter == letter:
			return entry.button
	return null

func test_crossword() -> void:
	var design = GameSession.GAME_DESIGN
	for level: int in [2, 3, 4, 5, 10, 11, 15, 20, 21, 25, 30]:
		check(design.level_stage_count(level) == (3 if level in [5, 15, 25] else 1), "A level is one crossword or three quiz questions")
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
			main._stage_home_pattern_background()
			await get_tree().process_frame
			var home_clip: Control = main.content.get_node("HomeBackgroundOverlay/HomeThemePattern")
			var home_motion: Control = home_clip.get_node("PatternMotion")
			var home_first: TextureRect = home_motion.get_child(0)
			var home_next: TextureRect = home_motion.get_child(1)
			var home_icon_size: Vector2 = home_first.size
			var home_icon_rotation: float = home_first.rotation
			var home_spacing: Vector2 = home_next.position - home_first.position
			var home_motion_signature: Vector2 = home_motion.get_meta("pattern_motion_signature")
			var home_origin: Vector2 = home_clip.get_global_rect().position + home_first.position
			main._clear()
			GameState._single_player_bucket(language)["unlocked_level"] = level_index
			GameState.select_single_level_theme(language, level_index, theme, design.level_stage_count(level_index + 1))
			main._invalidate_single_player_level_cache()
			main._start_single_player_word(level_index, 0)
			await get_tree().create_timer(1.6).timeout
			var root: Control = main._portrait_crossword
			var board: RefCounted = GameSession.crossword
			check(is_instance_valid(root) and main.hero_static_symbol == null, "Word level %d (%s, %s) must show the crossword without a character" % [level_index + 1, language, size])
			if !is_instance_valid(root) or board == null:
				return
			var paper_pattern := root.get_node_or_null("CrosswordPaperPattern") as Control
			var pattern_motion := root.get_node_or_null("CrosswordPaperPattern/PatternMotion") as Control
			check(!main.content.has_node("PortraitGameBackground/PortraitGameThemePattern"), "The blue crossword backdrop has no pattern")
			check(pattern_motion != null, "The white crossword paper has its own animated pattern")
			if pattern_motion == null:
				return
			var theme_icon: Texture2D = main._theme_icon_mono_texture(theme)
			check(theme_icon != null and pattern_motion.get_child_count() > 0 and pattern_motion.get_child(0).texture == theme_icon, "Crossword pattern shows the active theme icon")
			check(pattern_motion.mouse_filter == Control.MOUSE_FILTER_IGNORE and paper_pattern.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Crossword pattern does not intercept input")
			var pattern_tween: Tween = pattern_motion.get_meta("pattern_move_tween", null)
			check(pattern_tween != null and pattern_tween.is_running(), "Crossword theme pattern is moving")
			if pattern_motion.get_child_count() > 1:
				var first: TextureRect = pattern_motion.get_child(0)
				var next: TextureRect = pattern_motion.get_child(1)
				check(first.size.is_equal_approx(home_icon_size) and is_equal_approx(first.rotation, home_icon_rotation), "Paper icons match Home size and rotation")
				check((next.position - first.position).is_equal_approx(home_spacing) and (paper_pattern.get_global_rect().position + first.position).is_equal_approx(home_origin), "Paper pattern matches Home spacing and origin")
				check(pattern_motion.get_meta("pattern_motion_signature") == home_motion_signature, "Paper pattern matches Home motion")
				var tint: Color = first.material.get_shader_parameter("pattern_color")
				check(is_equal_approx(tint.a, 0.08), "Paper pattern uses eight percent opacity")
				var previous_position: Vector2 = pattern_motion.position
				await get_tree().process_frame
				await get_tree().process_frame
				check(!pattern_motion.position.is_equal_approx(previous_position), "The paper pattern moves between frames")
			check(board.entries.size() == 7, "Bonus crossword must contain seven words")
			var occupied: Dictionary = {}
			var longest_length: int = 0
			var longest_vertical_length: int = 0
			for entry: Dictionary in board.entries:
				var start := Vector2i(entry.x, entry.y)
				var direction := Vector2i.DOWN if entry.vertical else Vector2i.RIGHT
				var crosses: bool = false
				var word: String = entry.text
				check(!word.is_empty(), "Crossword entries contain an answer")
				var first_tile: Panel = root._tiles[board.cells[start]]
				var last_tile: Panel = root._tiles[board.cells[start + direction * (word.length() - 1)]]
				var delta: Vector2 = last_tile.position - first_tile.position
				var reads_down: bool = delta.x == 0.0 and delta.y > 0.0
				check(reads_down or (delta.y == 0.0 and delta.x > 0.0), "Crossword shows words in reading order")
				longest_length = maxi(longest_length, word.length())
				if reads_down:
					longest_vertical_length = maxi(longest_vertical_length, word.length())
				for i: int in range(word.length()):
					var point: Vector2i = start + direction * i
					if occupied.has(point):
						crosses = true
						check(occupied[point] == word[i], "Crossing letters differ")
					occupied[point] = word[i]
				check(crosses or entry == board.entries[0], "A crossword word is detached")
			check(longest_vertical_length == longest_length, "A longest word is displayed vertically")
			check(occupied.size() == root._tiles.size(), "Intersections share a single tile")
			var numbers: Dictionary = {}
			var glyphs: Array = root._glyphs.duplicate()
			var initial_revealed: Array = GameSession.revealed.duplicate()
			var starters: PackedStringArray = GameSession.crossword_starter_letters.duplicate()
			var starter_cells: PackedInt32Array = GameSession.crossword_starter_cells
			var anchor_length: int = board.entries[0].text.length()
			var anchor_starters: int = 0
			for index: int in starter_cells:
				anchor_starters += int(index < anchor_length)
			var known: int = 0
			var letters_in_grid: int = 0
			for letter: String in board.letters:
				letters_in_grid += int(!GameSession.WORD_CROSSWORD.is_separator(letter))
				known += int(starters.has(letter))
			var known_limit: int = floori(letters_in_grid * GameState.GAME_DESIGN.get_float("gameplay.crossword_starters.max_known_fraction"))
			var extra_starters: int = starter_cells.size() - anchor_starters
			check(anchor_starters >= 1 and anchor_starters <= 3 and extra_starters <= 2 and known <= known_limit, "Bonus starters respect the anchor, extra and known-letter budgets")
			if extra_starters < 2:
				var can_fit_extra: bool = false
				for index: int in range(anchor_length, board.letters.size()):
					var letter: String = board.letters[index]
					if !GameSession.WORD_CROSSWORD.is_separator(letter) and !starters.has(letter) and known + board.letters.count(letter) <= known_limit:
						can_fit_extra = true
				check(!can_fit_extra, "A bonus grid uses its extra clues when they fit the coverage cap")
			var level_title := main._portrait_top_bar_content.find_child("GameLevelTitle", true, false) as Label
			var expected_title: String = ("УРОВЕНЬ %d" if language == "ru" else "LEVEL %d") % (level_index + 1)
			check(is_instance_valid(level_title) and level_title.text == expected_title, "Word header shows the current localized level")
			if !is_instance_valid(level_title):
				return
			var level_rect: Rect2 = level_title.get_global_rect()
			check(!is_instance_valid(main._portrait_header_fill) and !is_instance_valid(main._portrait_currency_counter_visual) and !is_instance_valid(main._portrait_star_counter_visual), "Word header has no backdrop or resource counters")
			var labels: Array[Node] = main.content.find_children("*", "Label", true, false)
			check(labels.all(func(label: Label) -> bool: return label.text != tr("ATTEMPTS_LABEL")), "Word screen has no attempts block")
			var card := root.get_node("CrosswordField") as FlashStagePanel
			var paper: ColorRect = root.get_node("CrosswordPaper")
			var comment: Label = root._comment_label
			var panel_rect: Rect2 = card.get_global_rect()
			var paper_rect: Rect2 = paper.get_global_rect()
			var fit: float = main.PORTRAIT_STAGE_LAYOUT.fit_scale(get_viewport().get_visible_rect().size)
			var comment_rect: Rect2 = comment.get_global_rect()
			var keyboard_font: Font = main.UI_FONTS.keyboard_font()
			check(root.find_child("GameThemeCaption", true, false) == null and root.find_child("GameThemeName", true, false) == null, "The crossword does not have theme labels")
			check(comment.visible and comment.text == GameSession.get_crossword_comments()[root._selected_word], "Initial selection shows the matching catalog comment")
			check(comment.get_theme_font("font") == main.UI_QUESTION_COMMENT_FONT and comment.mouse_filter == Control.MOUSE_FILTER_IGNORE, "The comment uses the question font and passes input through")
			check(paper_rect.encloses(comment_rect) and is_equal_approx(comment_rect.get_center().x, paper_rect.get_center().x), "The comment is centered on the paper")
			check(is_equal_approx(comment_rect.position.y - panel_rect.end.y, root.COMMENT_GRID_GAP * fit), "The grid keeps clearance above the comment")
			check(comment.get_visible_line_count() == comment.get_line_count(), "The whole word comment fits")
			var swipe_area: Control = root._comment_swipe_area
			check(swipe_area.get_global_rect().is_equal_approx(comment_rect) and swipe_area.mouse_filter == Control.MOUSE_FILTER_STOP, "The full comment block handles swipes")
			check(is_equal_approx(comment_rect.size.x, (main.PORTRAIT_STAGE_SIZE.x - 48.0) * fit), "The comment uses the full text width")
			check(card.stage_rect.size.x == main.PORTRAIT_QUIZ_QUESTION_PANEL_RECT.size.x and card.stage_rect.size.y > main.PORTRAIT_QUIZ_QUESTION_PANEL_RECT.size.y, "Crossword card uses the quiz width and extends farther down")
			check(card.fill_color == Color.TRANSPARENT and root.find_child("StageQuestionCard", true, false) == null, "Crossword replaces the blue quiz card with paper")
			check(absf(paper.global_position.x) < 0.01 and is_equal_approx(paper.get_global_rect().size.x, get_viewport().get_visible_rect().size.x) and paper.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Paper spans the viewport without receiving input")
			var nav_rect: Rect2 = main._portrait_game_back_button.get_global_rect()
			check(level_rect.end.y < panel_rect.position.y and is_equal_approx(level_rect.get_center().x, panel_rect.get_center().x), "Level title is centered above the crossword")
			var attempts: Control = main._portrait_attempt_indicators
			var attempts_rect: Rect2 = attempts.get_global_rect()
			check(is_equal_approx(panel_rect.position.y - nav_rect.end.y, main.PORTRAIT_CROSSWORD_HEADER_GAP * fit) and attempts_rect.end.y < panel_rect.position.y, "Crossword uses the space directly below the header without overlapping the hearts")
			var grid_rect := Rect2(root._grid.global_position, root._board_size * root._grid.get_global_transform().get_scale())
			check(grid_rect.position.y >= panel_rect.position.y and grid_rect.end.y < comment_rect.position.y, "The playfield keeps the grid between the header and comment")
			var header_center: Vector2 = level_rect.merge(attempts_rect).get_center()
			check(is_equal_approx(attempts_rect.position.y - level_rect.end.y, 5.0 * fit), "Five stage units separate the level title and hearts")
			check(is_equal_approx(header_center.y, nav_rect.get_center().y) and level_rect.position.x > nav_rect.end.x, "Level title and attempts sit centered as a group beside navigation")
			check(attempts.total == 3 and attempts.remaining == 3 and is_equal_approx(attempts_rect.get_center().x, level_rect.get_center().x), "Three available attempts are centered under the title at the start")
			for heart: Control in attempts.get_child(0).get_children():
				check(heart.get_global_rect().size.is_equal_approx(Vector2.ONE * 25.0 * fit), "Each attempt heart is 25 by 25 stage units")
			check(level_title.get_theme_font("font") == keyboard_font and level_title.get_theme_color("font_color") == main.PORTRAIT_UI_PALETTE.UI_BLUE and main._portrait_top_bar_content.z_index > root.z_index, "Blue level title draws over the white sheet")
			check(level_title.get_theme_font_size("font_size") == 20, "Crossword level title uses size 20")
			var letter_font: Font = main.UI_FONTS.gameplay_word_font()
			var hidden_counts: Dictionary = GameSession.get_hidden_letter_counts()
			for i: int in range(glyphs.size()):
				var tile: Control = root._tiles[i]
				var tile_rect: Rect2 = tile.get_global_rect()
				check(tile_rect.size.x <= 50.0 * fit + 0.01 and tile_rect.size.y <= 50.0 * fit + 0.01, "Bonus crossword cells stay within 50 stage units")
				check(paper_rect.encloses(tile_rect) and tile_rect.position.y >= panel_rect.position.y and tile_rect.end.y < comment_rect.position.y, "Tiles stay on the paper above the comment")
				if glyphs[i] == null:
					continue
				var number_label := tile.find_child("Number", true, false) as Label
				check(number_label.get_theme_font("font") == main.UI_REGULAR_FONT and glyphs[i].get_theme_font("font") == letter_font, "Crossword cell uses Roboto Flex")
				var letter: String = board.letters[i]
				var number: String = number_label.text
				check(glyphs[i].visible == initial_revealed[i] and number == numbers.get(letter, number), "Equal letters share a number and only starter cells are initially visible")
				check(number_label.visible == hidden_counts.has(letter), "Initial numbers mark only letters with empty cells")
				numbers[letter] = number
			var distinct_numbers: Dictionary = {}
			for number: String in numbers.values():
				distinct_numbers[number] = true
			check(numbers.size() == distinct_numbers.size(), "Different letters must have different numbers")
			var directory: String = OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
			if DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				var frame: Image = get_viewport().get_texture().get_image()
				var comment_paper: Color = frame.get_pixel(3, int(comment_rect.get_center().y))
				check(comment_paper.r > 0.90 and comment_paper.b >= comment_paper.r, "White paper reaches the comment on GPU")
				var field: Rect2i = Rect2i(paper_rect)
				var header := Rect2i(0, 0, field.size.x, ceili(attempts_rect.end.y))
				var blue_top: int = ceili(paper_rect.end.y)
				var blue := Rect2i(0, blue_top, frame.get_width(), frame.get_height() - blue_top)
				field.position.y = ceili(panel_rect.position.y)
				field.size.y = int(comment_rect.position.y) - field.position.y
				paper_pattern.hide()
				await RenderingServer.frame_post_draw
				var plain: Image = get_viewport().get_texture().get_image()
				paper_pattern.show()
				check(frame.get_region(field).get_data() != plain.get_region(field).get_data(), "Blue theme pattern contributes visible pixels over the white paper")
				check(frame.get_region(header).get_data() != plain.get_region(header).get_data(), "Blue theme pattern continues behind the upper bar")
				check(frame.get_region(blue).get_data() == plain.get_region(blue).get_data(), "The paper pattern contributes no pixels below the torn edge")
				if !directory.is_empty():
					frame.save_png(directory.path_join("crossword_%s_%d.png" % [language, size.x]))
			check(starters.has(board.letters[root.selected_cell]) and !initial_revealed[root.selected_cell], "Late campaign levels focus a hidden copy of a given letter")
			var previous_word: int = root._selected_word
			var selected_other: bool = false
			var coins_before: int = GameState.get_soft_currency()
			var comment_hints_before: int = GameState.get_hint_count(GameState.HINT_COMMENT)
			for word_index: int in range(board.entries.size()):
				if word_index == previous_word:
					continue
				var reference: Dictionary = Database.resolve_saved_word(Database.get_theme_id(theme), board.entries[word_index].text)
				var expected_comment: String = str(reference.get("hint", "")).strip_edges()
				if expected_comment.is_empty() or expected_comment == comment.text:
					continue
				for cell: int in root._word_cells[word_index]:
					if !initial_revealed[cell] and !root._word_cells[previous_word].has(cell):
						await click_control(root._tiles[cell])
						selected_other = root._selected_word != previous_word and root._selected_word == word_index
						if selected_other:
							check(comment.visible and comment.text == expected_comment, "Clicking another word switches to its own comment")
							check(comment.get_visible_line_count() == comment.get_line_count(), "The changed comment fits the whole text")
							break
				if selected_other:
					break
			check(selected_other, "A click changes the active word in the multiword fixture")
			check(GameState.get_soft_currency() == coins_before and GameState.get_hint_count(GameState.HINT_COMMENT) == comment_hints_before, "Reading comments does not spend currency or a hint")
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
			await click_control(root._tiles[selected_index])
			check(root.selected_cell == selected_index and root._tiles[selected_index].get_theme_stylebox("panel").bg_color == main.PORTRAIT_UI_PALETTE.BUTTON_ORANGE, "Click highlights one hidden cell in orange")
			for i: int in range(glyphs.size()):
				if i != selected_index and board.letters[i] == shared_letter:
					check(root._tiles[i].get_theme_stylebox("panel").border_color == main.PORTRAIT_UI_PALETTE.UI_BLUE_LIGHT_BORDER, "Other hidden copies of the selected letter keep the standard border")
			for letter: String in Database.get_alphabet():
				if !GameSession.letters.has(letter):
					main._press_letter(letter)
					main._press_letter(letter)
					break
			check(GameSession.get_remaining_attempts() == lives - 1, "A repeated wrong key consumed more than one attempt")
			check(attempts.remaining == 2, "A repeated wrong key spends only one heart")
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
				var hearts := attempts.get_child(0)
				var available := hearts.get_child(0).get_node("AttemptHeart") as TextureRect
				var spent := hearts.get_child(-1).get_node("AttemptHeart") as TextureRect
				var red: Color = frame.get_pixelv(Vector2i(available.get_global_rect().get_center()))
				var gray: Color = frame.get_pixelv(Vector2i(spent.get_global_rect().get_center()))
				check(red.r > red.g + 0.25 and absf(gray.r - gray.g) < 0.02 and absf(gray.g - gray.b) < 0.02 and gray.r < 0.85, "Available hearts are red and the spent heart is gray")
				check(key.get_global_rect().encloses(key._count_label.get_global_rect()), "The active orange key displays its counter inside the key face")
				if !directory.is_empty():
					frame.save_png(directory.path_join("crossword_revealed_%s_%d.png" % [language, size.x]))
			var misplaced_letter: String = ""
			var target_index: int = -1
			for i: int in range(glyphs.size()):
				if !GameSession.can_guess_cell(i) or crossword_key(board.letters[i]).letter_state != StageLetterButton.LetterState.NORMAL:
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
			var tile_positions: Array = root._tiles.map(func(tile: Panel) -> Vector2: return tile.position)
			var stored: Dictionary = GameState._read_save_dictionary(GameState.SAVE_PATH)
			check(stored.active_single_player_session.data.has("crossword"), "Board entries were not written to the player save")
			main._clear()
			check(GameSession.restore_from_save_data(stored.active_single_player_session.data), "Saved board failed to restore")
			main.show_game_screen()
			await get_tree().process_frame
			check(GameSession.to_save_data() == snapshot and main._portrait_crossword != root, "Reopened stage lost its layout, reveal state or attempt count")
			check(main._portrait_attempt_indicators.remaining == 1, "Reopened stage restores the used markers")
			check(!is_instance_valid(pattern_motion) and !is_instance_valid(paper_pattern), "Reopening the stage removes both old pattern layers")
			var reopened_title := main._portrait_top_bar_content.find_child("GameLevelTitle", true, false) as Label
			check(is_instance_valid(reopened_title) and reopened_title != level_title and reopened_title.text == expected_title, "Reopened stage rebuilds the same level title")
			await get_tree().create_timer(1.6).timeout
			var reopened: Control = main._portrait_crossword
			check(reopened._tiles.map(func(tile: Panel) -> Vector2: return tile.position) == tile_positions, "Resume displays the same orientation")
			key = crossword_key(shared_letter)
			check(GameSession.revealed.count(true) == initial_revealed.count(true) + 1 and !key.disabled and key.remaining_count == matching_count - 1, "Resume restores starters, the guessed cell, and its counter")
			check(reopened._number_labels[selected_index].visible, "A restored open cell keeps its number until all matching cells are filled")
			check(reopened.selected_cell == GameSession.revealed.find(false), "Resume selects the first hidden cell")
			check(reopened._comment_label.text == GameSession.get_crossword_comments()[reopened._selected_word], "Resume restores the comment for the newly selected word")
			misplaced_key = crossword_key(misplaced_letter)
			check(!misplaced_key.disabled and misplaced_key._count_label.visible and misplaced_key.remaining_count == misplaced_count and misplaced_key._label.get_theme_color("font_color") == main.PORTRAIT_UI_PALETTE.MARKER_ORANGE_TEXT, "Resume restores a letter discovered by a misplaced guess")
			for i: int in range(board.letters.size()):
				if board.letters[i] == shared_letter and !GameSession.revealed[i]:
					reopened.select_cell(i)
					main._press_letter(shared_letter)
			check(key.disabled and !key._count_label.visible, "The last matching cell disables its key and removes the counter")
			for i: int in range(board.letters.size()):
				if board.letters[i] == shared_letter:
					check(!reopened._number_labels[i].visible, "Filling the last matching cell hides the number on every copy")
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
				check(main._portrait_crossword_victory_pending and reopened.has_pending_word_wave() and !is_instance_valid(main._portrait_round_result), "Victory waits for the last word wave without constructing a result screen")
				check(reopened.selected_cell == -1 and !reopened._comment_label.visible, "A completed grid clears the selection and comment")
			main._clear()
			await get_tree().process_frame
			check(!is_instance_valid(root), "Leaving the screen retained the previous crossword")
			check(!main._portrait_crossword_victory_pending, "Leaving the screen cancels the deferred victory animation")
			check(pattern_tween == null or !pattern_tween.is_valid(), "The engine releases the old background tween after freeing its owner")

	main.game_finished = false
	GameSession.start_round(WordData.new("GRID", 0.2, -1, -1))
	main.show_game_screen()
	await get_tree().process_frame
	check(main._portrait_game_entrance_active, "Close test must interrupt a running grid entrance")
	var closing_grid: Control = main._portrait_crossword
	main._clear()
	check(!main._portrait_game_entrance_active, "Closing the grid did not cancel its entrance")
	await get_tree().create_timer(1.6).timeout
	check(!is_instance_valid(closing_grid) and !main._portrait_game_entrance_active, "An old grid entrance survived screen closure")

func test_crossword_selection() -> void:
	main.game_finished = false
	GameSession.start_round(WordData.new("C AT", 0.2, -1, -1))
	var board: RefCounted = GameSession.WORD_CROSSWORD.restore("C AT", [
		{"text": "C AT", "x": 0, "y": 0, "vertical": false},
		{"text": "ABLE", "x": 2, "y": 0, "vertical": true},
		{"text": "ELK", "x": 1, "y": 2, "vertical": false},
	])
	check(board != null, "Selection fixture must form a valid crossword")
	if board == null:
		return
	GameSession.crossword = board
	GameSession.letters = board.letters
	GameSession._set_crossword_starters([])
	GameSession.revealed.clear()
	for letter: String in board.letters:
		GameSession.revealed.append(GameSession.WORD_CROSSWORD.is_separator(letter))
	main.show_game_screen()
	await get_tree().create_timer(1.6).timeout
	var grid: Control = main._portrait_crossword
	check(is_instance_valid(grid) and grid._input_enabled, "The selection fixture accepts input after the entrance")
	var first: int = board.cells[Vector2i.ZERO]
	var space: Panel = grid._tiles[board.cells[Vector2i(1, 0)]]
	var space_style := space.get_theme_stylebox("panel") as StyleBoxFlat
	check(space_style != null and space_style.bg_color == main.PORTRAIT_UI_PALETTE.CROSSWORD_SPACE_FILL, "A space has the filled gray cell style")
	check(space.get_child_count() == 0 and space.mouse_filter == Control.MOUSE_FILTER_IGNORE, "A space has no number, letter, or input")
	var shared_start: int = board.cells[Vector2i(2, 0)]
	var last: int = board.cells[Vector2i(3, 0)]
	check(grid._tiles[first].position.y == grid._tiles[last].position.y, "A tied longest word already runs vertically, so the board keeps its orientation")
	check(grid.selected_cell == first and !grid._comment_label.visible, "The initial cell with no catalog comment shows no text")
	grid._comments = PackedStringArray(["First word comment", "Second word comment", ""])
	grid._sync_comment()
	check(grid._comment_label.text == "First word comment", "The first selected word displays its comment")
	await swipe_comment(grid, Vector2(5, 0))
	await swipe_comment(grid, Vector2(15, 100), true)
	await swipe_comment(grid, Vector2(-100, 0), true, true)
	check(grid._selected_word == 0, "A tap, vertical drag or canceled gesture does not switch words")
	await swipe_comment(grid, Vector2(-100, 0), true)
	check(grid._selected_word == 1 and grid.selected_cell == shared_start and grid._comment_label.text == "Second word comment", "A left swipe selects the next word even at a crossing")
	await swipe_comment(grid, Vector2(100, 0))
	check(grid._selected_word == 0 and grid.selected_cell == first, "A right drag returns to the previous word")
	await swipe_comment(grid, Vector2(100, 0), true)
	check(grid._selected_word == 2 and !grid._comment_label.visible, "A right swipe wraps to a word without a comment")
	await swipe_comment(grid, Vector2(-100, 0))
	check(grid._selected_word == 0 and grid.selected_cell == first, "A left drag on the empty comment area wraps to the first word")
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_C
	key.unicode = "C".unicode_at(0)
	get_viewport().push_input(key)
	check(GameSession.revealed[first] and grid.selected_cell == shared_start, "Keyboard input works without a click and advances past the separator")
	await click_control(grid._tiles[last])
	main._press_letter("T")
	check(grid.selected_cell == shared_start, "Guessing the last cell wraps to the first hidden cell of the same word")
	await get_tree().create_timer(0.5).timeout
	main._press_letter("A")
	check(grid.selected_cell == board.cells[Vector2i(2, 1)], "Finishing a word skips the revealed start of the next word")
	check(grid._comment_label.text == "Second word comment", "Automatic selection advances to the next word comment")
	var wave: Tween = grid._word_wave
	check(wave != null and GameSession.is_active, "Completing one word starts its wave before the round ends")
	if wave == null:
		main._clear()
		return
	wave.pause()
	await swipe_comment(grid, Vector2(100, 0), true)
	check(grid._selected_word == 2, "Word navigation skips completed words")
	await swipe_comment(grid, Vector2(-100, 0), true)
	check(grid._selected_word == 1 and grid.selected_cell == board.cells[Vector2i(2, 1)], "Word navigation selects the first remaining cell")
	var step: float = grid._wave_step
	wave.custom_step(step * 0.5)
	check(grid._glyphs[first].scale.x > 1.0 and grid._glyphs[shared_start].scale == Vector2.ONE and grid._glyphs[last].scale == Vector2.ONE, "The wave begins with the first letter")
	wave.custom_step(step)
	check(grid._glyphs[shared_start].scale.x > 1.0 and grid._glyphs[last].scale == Vector2.ONE, "The wave advances past the separator to the next letter")
	wave.custom_step(step)
	check(grid._glyphs[last].scale.x > 1.0, "The last letter participates in the wave")
	main._refresh_portrait_game_runtime_state()
	check(grid._word_wave == wave and grid._word_wave_queue.is_empty(), "Refreshing a completed word does not replay its wave")
	main._press_letter("B")
	check(grid.selected_cell == board.cells[Vector2i(2, 2)], "Selection advances to the next vertical cell")
	main._press_letter("L")
	check(grid.selected_cell == board.cells[Vector2i(2, 3)], "Guessing a crossing cell continues in the current word")
	main._press_letter("E")
	check(grid.selected_cell == board.cells[Vector2i(1, 2)], "Finishing the vertical word selects the first cell of the next word")
	check(!grid._comment_label.visible and grid._comment_label.text.is_empty(), "A word without a comment clears the previous text")
	check(grid._word_wave_queue.size() == 1 and grid._word_wave == wave, "The next word queues its own wave when the words share a glyph")
	wave.custom_step(1.0)
	check(grid._glyphs[first].scale == Vector2.ONE and grid._glyphs[last].scale == Vector2.ONE, "The wave restores each letter to its resting size")
	await get_tree().create_timer(0.5).timeout
	var vertical_wave: Tween = grid._word_wave
	check(vertical_wave != null and vertical_wave != wave, "The queued vertical word starts after the previous feedback")
	main._clear()
	await get_tree().process_frame
	check(!is_instance_valid(grid) and (vertical_wave == null or !vertical_wave.is_valid()), "Leaving the screen cancels the remaining wave")
	main.show_game_screen()
	var restored: Control = main._portrait_crossword
	check(restored.primary_word_completed_in_grid() and !restored.has_pending_word_wave(), "Reopening a completed word does not replay its wave")
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
		var theme: int = Database.get_theme_index_by_id(1)
		var word_text: String = "ДРИБЛИНГ" if language == "ru" else "DRIBBLING"
		var word: WordData
		for entry: Dictionary in Database.get_words_by_index(theme):
			if entry.text == word_text:
				word = WordData.new(word_text, entry.difficulty, theme, entry.index, entry.id)
				break
		check(word != null, "The starter fragment test uses a real catalog word")
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
			var suffix_start: int = word_text.length() - 3
			check(cells == PackedInt32Array(range(suffix_start, word_text.length())), "The recognizable %s suffix opens three adjacent cells" % language)
			if cells.size() != 3:
				return
			check(GameSession.revealed.count(true) == 3 and GameSession.get_remaining_attempts() == GameSession.attempt_limit and GameSession.correct_letters.is_empty() and !GameSession.open_hint_used, "Only the free starter cells are open")
			main.show_game_screen()
			await get_tree().create_timer(1.6).timeout
			var grid: Control = main._portrait_crossword
			var word_span: Vector2 = grid._tiles[word_text.length() - 1].position - grid._tiles[0].position
			check(word_span.x == 0.0 and word_span.y > 0.0, "A one-word grid is displayed vertically in reading order")
			check(grid.find_child("CrosswordStarterCodes", true, false) == null, "The theme title has no separate starter pairs")
			for cell: int in cells:
				check(grid._glyphs[cell].visible, "The given letter is visible directly in its cell")
			var first_letter: String = GameSession.letters[cells[0]]
			var target: int = grid.selected_cell
			check(target == word_text.find(first_letter) and target != cells[0], "Initial selection focuses a hidden copy of the first given letter")
			check(grid._tiles[cells[0]].get_theme_stylebox("panel").border_color == main.PORTRAIT_UI_PALETTE.BUTTON_BLUE, "A visible copy of the selected letter keeps the standard revealed border")
			var repeated_key := crossword_key(first_letter)
			var given_key := crossword_key(GameSession.letters[cells[2]])
			check(repeated_key.remaining_count == 1 and !repeated_key.disabled and given_key.disabled, "Only the given letters with open positions can be entered")
			var wrong_key := crossword_key("А" if language == "ru" else "Z")
			await click_control(wrong_key)
			check(GameSession.mistakes == 1 and wrong_key.disabled and !GameSession.revealed[target] and grid.selected_cell == target, "A wrong letter on a given code spends an attempt and keeps the selection")
			var misplaced_key := crossword_key(word_text[0])
			await click_control(misplaced_key)
			check(GameSession.mistakes == 2 and !misplaced_key.disabled and misplaced_key.remaining_count > 0 and !GameSession.revealed[target], "A misplaced letter on a given code spends an attempt and stays available")
			await click_control(crossword_key(first_letter))
			check(GameSession.revealed[target], "A given code is copied through the keyboard")
			var snapshot: Dictionary = GameSession.to_save_data()
			main._clear()
			check(GameSession.restore_from_save_data(snapshot) and GameSession.to_save_data() == snapshot, "Resume uses the saved starters")
			await get_tree().process_frame
			if size.x == 960:
				var legacy: Dictionary = snapshot.duplicate(true)
				var legacy_cell: int = cells[2]
				legacy.crossword_starter_cells = [legacy_cell]
				legacy.revealed[legacy_cell] = false
				check(GameSession.restore_from_save_data(legacy) and GameSession.revealed == snapshot.revealed, "A legacy clue from the removed row is now visible on the board")
				legacy.revealed.fill(true)
				legacy.revealed[legacy_cell] = false
				check(GameSession.restore_from_save_data(legacy) and GameSession.can_guess_cell(legacy_cell), "Restoring a legacy clue leaves the final move playable")
	GameSession.start_round(WordData.new("QUART", 0.2, -1, -1))
	check(GameSession.revealed.count(true) == 2, "A word without a recognized fragment still opens two letters")
	GameSession.start_round(WordData.new("SHIP", 0.2, -1, -1))
	check(GameSession.revealed == [true, true, false, false], "A short word with a useful fragment keeps two cells for the player")
	GameSession.start_round(WordData.new("QUAD", 0.2, -1, -1))
	check(GameSession.revealed.count(true) == 1, "A short word without a fragment opens one letter")

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
