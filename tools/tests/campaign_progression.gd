extends Node

const DESIGN = preload("res://scripts/core/game_design_config.gd")
const PALETTE = preload("res://scripts/ui/ui_palette.gd")
class TestUI extends "res://scripts/main_portrait.gd":
	func _ready() -> void:
		_build_root()
		_clear()
		GameSession.changed.connect(_persist_active_single_player_word_session)
		GameSession.changed.connect(_refresh_game_screen)
		GameSession.round_won.connect(_on_round_won)
		GameSession.round_lost.connect(_on_round_lost)
	func _portrait_ads_enabled() -> bool:
		return false

var checks: int = 0
var failures: Array[String] = []

func _ready() -> void:
	run.call_deferred()

func _process(_delta: float) -> void:
	if OS.get_environment("HANGMAN_TEST_HIDE_WINDOW") == "1":
		RenderingServer.force_draw(false)

func check(ok: bool, message: String) -> void:
	checks += 1
	if !ok:
		failures.append(message)

func ready_when(predicate: Callable, message: String) -> bool:
	var deadline: int = Time.get_ticks_msec() + 7000
	while !predicate.call() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	var ready: bool = predicate.call()
	check(ready, message)
	return ready

func run() -> void:
	Engine.time_scale = 6.0
	for level: int in range(1, 31):
		check(DESIGN.is_bonus_level(level) == (level % 10 == 0), "Every tenth level is hard")
		check(DESIGN.level_stage_count(level) == (3 if level % 10 == 5 else 1), "Only levels ending in five have three questions")
	for language: String in ["ru", "en"]:
		GameState.interface_language = language
		GameState.word_language = language
		Database.load_languages(language, language)
		check_word_queues()
		check_no_repeated_crossword_words(language)
		for dimensions: Vector2i in [Vector2i(960, 1600), Vector2i(690, 1536)]:
			get_window().min_size = dimensions
			get_window().size = dimensions
			for level_index: int in [0, 1, 2, 4, 5, 9]:
				GameState.single_player = {}
				GameState.single_player_resume_states = {}
				GameState.clear_active_single_player_session(false)
				GameState.clear_pending_single_player_reward(false)
				GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
				GameState.ad_personalization_choice = GameState.AdPersonalizationChoice.DENIED
				GameState._single_player_bucket(language)["unlocked_level"] = level_index
				GameState.hearts = GameState.MAX_HEARTS
				GameSession.discard_current_round()
				var main := TestUI.new()
				add_child(main)
				var options: Array = main._single_player_level_theme_options(level_index)
				check(!options.is_empty(), "The level offers a theme")
				if options.is_empty():
					main.queue_free()
					await get_tree().process_frame
					continue
				main._confirm_single_player_theme_selection(level_index, int(options[0]))
				if level_index == 4:
					await play_quizzes(main, language, dimensions.x)
				else:
					if (level_index == 5 and dimensions.x == 960) or (level_index == 9 and dimensions.x == 690):
						await check_failed_crossword_retry(main, language, level_index)
					await play_crossword(main)
				check(main.content.find_child("SinglePlayerRewardChain", true, false) == null, "No separate stage chain between gameplay and prize")
				if level_index not in [4, 9]:
					check(main.content.find_child("StageCoinLargeReward", true, false) != null, "A normal crossword goes directly to the coin prize")
				else:
					var prize: Node = main.content.find_child("LevelCompletionRewardPrize", true, false)
					check(prize != null and prize.has_node("ChestClosedVisual" if level_index == 9 else "CoinPackVisual"), "Continue opens the correct level prize")
					check(int(GameState.get_pending_single_player_reward().get("stars_amount", -1)) == 0, "The level prize has no extra stars")
					if level_index == 9 and language == "ru" and dimensions.x == 960:
						var before: int = GameState.get_soft_currency()
						var pending: Dictionary = GameState.get_pending_single_player_reward()
						main._clear()
						GameState.load_game()
						GameState.interface_language = language
						main._resume_saved_single_player_level()
						check(GameState.get_pending_single_player_reward().get("claim_id") == pending.get("claim_id") and GameState.get_soft_currency() == before, "An unclaimed chest survives a restart without paying early")
						if await ready_when(func(): return is_instance_valid(main._portrait_final_reward_continue_button) and !main._portrait_final_reward_continue_button.get("button_disabled"), "Restored chest reaches Continue"):
							main._portrait_final_reward_continue_button.pressed.emit()
							check(GameState.get_soft_currency() == before + int(pending.amount), "The chest pays its coin amount once")
							check(GameState.claim_pending_single_player_reward() == 0, "Claiming the chest again adds no coins")
				main.queue_free()
				await get_tree().process_frame
	print("CAMPAIGN_PROGRESSION ", JSON.stringify({"checks": checks, "failures": failures}))
	get_tree().quit(int(!failures.is_empty()))

func play_quizzes(main: TestUI, language: String, width: int) -> void:
	check(GameState.get_single_level_question_slots(language, 4) == [0, 1, 2], "The quiz level saves three quiz slots")
	check(GameState.get_single_level_word_assignments(language, 4).is_empty(), "Quiz-only levels do not select crosswords")
	var ids: Dictionary = {}
	for slot: int in range(3):
		if !await ready_when(func(): return main._quiz_question_ready_at_msec > 0, "Question becomes interactive"):
			return
		check(main.single_player_active_word_slot == slot, "Questions follow each other in order")
		ids[main._quiz_current_question.id] = true
		var index: int = main._quiz_correct_answer_index()
		var wrong_answer: bool = slot == 1 or (slot == 2 and width == 690)
		main._on_quiz_answer_selected((index + 1) % main._quiz_answer_buttons.size() if wrong_answer else index)
		var progress: Node = main.content.find_child("QuizLevelProgress", true, false)
		var expected: Color = PALETTE.ERROR_SOFT if wrong_answer else PALETTE.SUCCESS_BORDER
		check(progress != null and progress._segments.size() == 3 and progress._segments[slot].get_theme_stylebox("panel").bg_color == expected, "The progress strip marks an answer with the correct color")
		check(GameState.get_active_single_player_stage_reward().is_empty(), "No per-question prize is created")
		if !await ready_when(func(): return is_instance_valid(main._quiz_continue_button) and main._quiz_continue_button.visible, "Quiz result exposes Continue"):
			return
		if slot == 1:
			await RenderingServer.frame_post_draw
			var directory: String = OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
			if !directory.is_empty():
				get_viewport().get_texture().get_image().save_png(directory.path_join("quiz_%s_%d.png" % [language, width]))
		var reload_answer: bool = width == 960 and ((slot == 0 and language == "ru") or (slot == 2 and language == "en"))
		if reload_answer:
			main._clear()
			GameState.load_game()
			GameState.interface_language = language
			main._resume_saved_single_player_level()
		else:
			main._on_quiz_continue_pressed()
		if slot < 2:
			check(main._quiz_screen_active and main.content.find_child("SinglePlayerRewardChain", true, false) == null, "Continue opens the next question directly")
		else:
			check(main.content.find_child("LevelCompletionRewardPrize", true, false) != null and !main.game_screen_visible, "The final quiz answer opens the prize directly")
			check(main.content.get_node_or_null("PortraitBlueBackground") != null and !main.content.get_children().any(func(child: Node) -> bool: return child.get_script() == main.PORTRAIT_PAPER_BACKGROUND_SCRIPT), "The quiz prize has a blue backdrop in its first frame")
	check(ids.size() == 3, "All three quiz questions are distinct")

func check_word_queues() -> void:
	var main := TestUI.new()
	for theme: int in range(Database.get_theme_count()):
		var source: Array = Database.get_words_by_index(theme, 0)
		var queue: Array = main._campaign_word_queue(theme, {})
		check(queue.size() == source.size(), "The theme queue contains the whole catalog")
		var wave: Array = DESIGN.get_array("difficulty.word_wave_order")
		if queue.size() <= wave.size():
			continue
		var ranked: Array = source.duplicate()
		ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.id < b.id if a.difficulty == b.difficulty else a.difficulty < b.difficulty)
		for index: int in range(wave.size()):
			check(queue[index] == ranked[wave[index]], "The queue follows a fixed wave of difficulty")
		var used: Dictionary = {main._campaign_word_key(queue[0].text): true}
		var remainder: Array = main._campaign_word_queue(theme, used)
		check(remainder[0] == queue[1], "Consuming the first answer does not re-sort the wave")
	main.free()

func check_no_repeated_crossword_words(language: String) -> void:
	GameState.single_player = {}
	GameState.single_player_resume_states = {}
	GameState.clear_active_single_player_session(false)
	GameState.clear_pending_single_player_reward(false)
	GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
	GameState._single_player_bucket(language)["unlocked_level"] = 11
	var main := TestUI.new()
	add_child(main)
	for level_index: int in [11, 12, 13]:
		var theme: int = 0 if level_index == 11 else 8
		GameState._single_player_bucket(language)["unlocked_level"] = level_index
		GameState.select_single_level_theme(language, level_index, theme, 1)
		var used: Dictionary = GameState.get_campaign_seen_words(language)
		main._start_single_player_word(level_index, 0)
		check(main.single_player_active_level_index == level_index, "The selected level starts a new grid")
		check(GameSession.crossword.entries.size() > 1, "The repetition check includes supplementary entries")
		for entry: Dictionary in GameSession.crossword.entries:
			check(!used.has(main._campaign_word_key(entry.text)), "A new grid never selects a shown word")
			check(GameState.get_campaign_seen_words(language).has(main._campaign_word_key(entry.text)), "Every displayed grid entry is recorded")
		GameState.load_game()
		for entry: Dictionary in GameSession.crossword.entries:
			check(GameState.get_campaign_seen_words(language).has(main._campaign_word_key(entry.text)), "Used grid entries survive save and reload")
		main._invalidate_single_player_level_cache()
	main.free()
	GameSession.discard_current_round()

func check_failed_crossword_retry(main: TestUI, language: String, level_index: int) -> void:
	if !await ready_when(func(): return GameSession.is_active and !main._portrait_game_entrance_active, "Crossword is ready for the loss scenario"):
		return
	var entries: Array = GameSession.crossword.entries.duplicate(true)
	var initial_cells: Array = GameSession.revealed.duplicate()
	var coins: int = GameState.get_soft_currency()
	var stars: int = GameState.get_stars()
	var tickets: int = GameState.get_hearts()
	main._portrait_game_back_button.pressed.emit()
	var exit_popup: Node = get_tree().get_first_node_in_group("exit_game_popup")
	if !check_exit_popup_actions(exit_popup, "Normal gameplay exit"):
		return
	exit_popup.find_child("ExitLevelContinueButton", true, false).pressed.emit()
	check(GameSession.is_active and GameState.get_hearts() == tickets, "Continuing from a normal exit keeps the round and ticket")
	for letter: String in Database.get_alphabet():
		if GameSession.letters.has(letter):
			continue
		main._press_letter(letter)
		if GameSession.has_deferred_loss():
			break
	if !await ready_when(func(): return get_tree().get_first_node_in_group("single_player_last_chance_popup") != null, "The last mistake opens the attempt offer"):
		return
	check(GameSession.revealed == initial_cells and !main._portrait_in_place_result_active, "The attempt offer keeps the solution hidden")
	var offer_cost: int = main._single_player_extra_attempt_cost()
	main._decline_single_player_extra_attempt()
	exit_popup = get_tree().get_first_node_in_group("exit_game_popup")
	check(is_instance_valid(exit_popup) and exit_popup.find_child("ExitLifeStatus", true, false) != null, "Declining opens the exit confirmation with its ticket warning")
	check(GameSession.revealed == initial_cells and GameSession.has_deferred_loss() and GameState.get_hearts() == tickets, "Declining leaves the answer hidden and keeps the ticket until confirmation")
	if !check_exit_popup_actions(exit_popup, "Exit after declining attempts"):
		return
	if language == "ru":
		var continue_button: Control = exit_popup.find_child("ExitLevelContinueButton", true, false)
		continue_button.pressed.emit()
	else:
		main._portrait_handle_modal_back_request()
	check(get_tree().get_first_node_in_group("single_player_last_chance_popup") != null and main._single_player_extra_attempt_cost() == offer_cost, "Cancelling exit restores the same attempt offer")
	main._decline_single_player_extra_attempt()
	exit_popup = get_tree().get_first_node_in_group("exit_game_popup")
	if !is_instance_valid(exit_popup):
		check(false, "Exit confirmation opens again")
		return
	var exit_button: Control = exit_popup.find_child("ExitLevelConfirmButton", true, false)
	exit_button.pressed.emit()
	check(is_instance_valid(main._home_logo_reveal) and !is_instance_valid(main._portrait_round_result), "Confirming exit opens Home without showing the answer")
	check_home_failed_level_title(main, language, level_index)
	check(GameState.get_hearts() == tickets - 1, "Confirming exit consumes exactly one ticket")
	check(!GameState.is_single_level_completed(language, level_index, 1) and GameState.get_single_player_unlocked_level(language) == level_index, "A failed crossword keeps the same level locked in")
	check(GameState.get_pending_single_player_reward().is_empty() and GameState.get_active_single_player_stage_reward().is_empty() and GameState.get_soft_currency() == coins and GameState.get_stars() == stars, "A failed crossword has no prize or currency payout")
	if level_index == 9:
		GameState.load_game()
		main.show_menu()
		check_home_failed_level_title(main, language, level_index)
	main._play_single_player_from_home()
	if !await ready_when(func(): return main.game_screen_visible and GameSession.is_active, "Home Continue opens the retry"):
		return
	check(main.single_player_active_level_index == level_index and GameSession.is_active and GameSession.crossword.entries == entries and GameSession.revealed == initial_cells and GameSession.mistakes == 0, "Retry restores the same grid at its initial state")
	check(main.content.find_child("LevelCompletionRewardPrize", true, false) == null, "Retry opens gameplay directly")

func check_home_failed_level_title(main: TestUI, language: String, level_index: int) -> void:
	var button: Control = main.content.find_child("HomeSinglePlayerButton", true, false)
	var labels: Array = button.find_children("*", "Label", false, false).filter(func(label: Label) -> bool: return !label.text.is_empty()) if is_instance_valid(button) else []
	var title: String = ("УРОВЕНЬ %d" if language == "ru" else "LEVEL %d") % (level_index + 1)
	check(labels.size() == 1 and labels[0].name == &"LevelTitle" and labels[0].text == title, "Home shows only the failed level number")

func check_exit_popup_actions(popup: Node, context: String) -> bool:
	var stage: Node = popup.find_child("CenteredPopupStage", true, false) if is_instance_valid(popup) else null
	if !is_instance_valid(stage):
		check(false, context + " opens the exit confirmation")
		return false
	check(!stage.get_children().any(func(node: Node) -> bool: return node is StageRoundButton), context + " has no circular close button")
	var has_actions: bool = is_instance_valid(stage.find_child("ExitLevelContinueButton", true, false)) and is_instance_valid(stage.find_child("ExitLevelConfirmButton", true, false))
	check(has_actions, context + " offers Continue and Exit")
	return has_actions

func play_crossword(main: TestUI) -> void:
	if !await ready_when(func(): return GameSession.is_active and !main._portrait_game_entrance_active, "Crossword becomes interactive"):
		return
	var grid: Control = main._portrait_crossword
	var expected: Array = DESIGN.opening_crossword_words(
		main.single_player_active_level_index + 1, Database.current_language, Database.get_theme_id(GameSession.theme_id))
	var visible_codes: Dictionary = {}
	if !expected.is_empty():
		check(GameSession.crossword.entries.map(func(entry: Dictionary) -> String: return entry.text) == expected, "Tutorial uses its authored crossword")
		for index: int in range(grid._tiles.size()):
			var number: Label = grid._number_labels[index]
			if number != null and number.visible and grid._glyphs[index].visible:
				visible_codes[number.text] = grid._glyphs[index].text
	for move: int in range(GameSession.revealed.count(false)):
		var cell: int = grid.selected_cell
		if cell < 0:
			check(false, "Unsolved crossword has a selected cell")
			return
		var letter: String = GameSession.letters[cell]
		if !expected.is_empty():
			letter = visible_codes.get(grid._number_labels[cell].text, "")
			if letter.is_empty():
				check(false, "The tutorial supplies every letter needed to solve the crossword")
				return
		main._press_letter(letter)
	if GameSession.is_active:
		check(false, "All crossword guesses finish the level")
		return
	check(!grid._input_enabled and main._portrait_game_keyboard_buttons.all(func(entry: Dictionary) -> bool: return entry.button.disabled), "Solving the grid locks all answers")
	check(grid.has_pending_word_wave() and !grid._victory_shown, "The last word plays its wave before the victory bounce")
	if !await ready_when(func(): return is_instance_valid(grid) and grid._victory_bounce != null, "The victory bounce starts after all word waves"):
		return
	check(!is_instance_valid(main._portrait_round_result), "Victory skips the result, comment and search screen")
	var victory_bounce: Tween = grid._victory_bounce
	victory_bounce.pause()
	victory_bounce.custom_step(grid._bounce_grow * 0.5)
	for index: int in range(grid._glyphs.size()):
		if grid._glyphs[index] == null:
			continue
		check(grid._tiles[index].get_theme_stylebox("panel").bg_color == PALETTE.MARKER_SUCCESS and grid._glyphs[index].scale.x > 1.0, "All letters bounce together on green cells")
	check(main.game_screen_visible, "The reward waits for the victory bounce to finish")
	victory_bounce.custom_step(1.0)
	await ready_when(func(): return !main.game_screen_visible, "The game opens the reward without Continue")
