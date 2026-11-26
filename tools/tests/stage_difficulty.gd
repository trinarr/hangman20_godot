extends Node

var failures: Array[String] = []
var checks: int = 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if !condition:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	# Run with an isolated Godot profile; the fixture deliberately writes saves.
	GameState.single_player = {}
	Database.load_languages("en", "en")
	GameState.progress = {}
	GameState.single_player = {}
	GameState.interface_language = "ru"
	GameState.word_language = "ru"
	Database.load_languages("ru", "ru")
	var target: float = GameState.GAME_DESIGN.campaign_quiz_difficulty(4)
	GameState.set_single_level_question_slots("ru", 4, [0, 1, 2])
	var first: Dictionary = GameState.mark_single_level_word_played("ru", 4, 0, 3, true, true, -1, true, false)
	check(!first.completed and first.completion_bonus == 0, "There is no completion reward after the first question")
	var second: Dictionary = GameState.mark_single_level_word_played("ru", 4, 1, 3, false, true, -1, true, false)
	check(!second.retry_crossword and !second.completed, "A wrong quiz answer leaves the next question available")
	var third: Dictionary = GameState.mark_single_level_word_played("ru", 4, 2, 3, true, true, -1, true, false)
	check(third.completed and !third.perfect and third.completion_bonus > 0, "A mixed quiz sequence completes and earns its prize")
	check(is_equal_approx(GameState.GAME_DESIGN.campaign_quiz_difficulty(4), target), "Results never affect the target for a given level")
	var coins: int = GameState.get_soft_currency()
	var repeated: Dictionary = GameState.mark_single_level_word_played("ru", 4, 2, 3, false, true, -1, true, false)
	check(repeated.completion_bonus == 0 and GameState.get_soft_currency() == coins, "Duplicate result cannot award more coins")
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	# The maximum is twenty letters, not twenty characters including spaces.
	main._clear()
	GameSession.start_round(WordData.new("БЕСПРОВОДНЫЕ НАУШНИКИ", .2, -1, -1))
	check(GameSession.letters.size() == 21 and GameSession.revealed[12], "Twenty-letter phrase was truncated or its space hidden")
	main.game_finished = false
	main.show_game_screen()
	GameSession.revealed.fill(true)
	main._refresh_game_screen()
	await get_tree().process_frame
	var visible_letters: int = 0
	for glyph: Label in main._portrait_crossword._glyphs:
		if glyph == null or !glyph.visible:
			continue
		visible_letters += 1
		var tile: Control = glyph.get_parent()
		var font: Font = glyph.get_theme_font("font")
		var text_width: float = font.get_string_size(glyph.text, HORIZONTAL_ALIGNMENT_LEFT, -1, glyph.get_theme_font_size("font_size")).x
		check(text_width <= tile.size.x + 2.0, "Long answer glyph overflows its cell: %s %.2f / %.2f" % [glyph.text, text_width, tile.size.x])
	check(visible_letters == 20, "Not all twenty letters are displayed")
	# Completion rules are tested independently of result-screen animations.
	GameSession.round_won.disconnect(main._on_round_won)
	GameSession.revealed.fill(false)
	GameSession.revealed[12] = true
	for letter: String in GameSession.letters:
		if !GameSession._is_separator(letter) and GameSession.is_active:
			GameSession.guess(letter)
	check(GameSession.is_word_completed(), "Twenty-letter phrase cannot be completed")
	GameSession.start_round(WordData.new("DIRECTOR'S CUT", .3, -1, -1))
	for letter: String in GameSession.letters:
		if !GameSession._is_separator(letter) and GameSession.is_active:
			GameSession.guess(letter)
	check(GameSession.is_word_completed(), "Possessive punctuation cannot be completed")
	GameSession.discard_current_round()
	main.show_menu()
	await get_tree().create_timer(2.0).timeout
	main.queue_free()
	await get_tree().process_frame
	print("STAGE_DIFFICULTY ", JSON.stringify({"checks": checks, "failures": failures}))
	get_tree().quit(0 if failures.is_empty() else 1)
