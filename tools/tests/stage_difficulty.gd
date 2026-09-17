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
	# Run with a separate XDG_DATA_HOME; the fixture deliberately writes saves.
	GameState.single_player = {}
	Database.load_languages("en", "en")
	# Patch03 saves already have revision 3. New cross-theme aliases must still run.
	var old_en_stats: Dictionary = {
		"_word_catalog_version": 3,
		"9": {"played": {"FILM DIRECTOR": true}, "guessed": {"FILM DIRECTOR": true}},
		"4": {"played": {"WEB CAMERA": true}, "guessed": {"WEB CAMERA": true}},
		"1": {"played": {"RACQUET": true}, "guessed": {"CAPTAIN ARMBAND": true}},
	}
	GameState.progress = {"en": old_en_stats.duplicate(true)}
	GameState._single_player_bucket("en")["word_stats"] = old_en_stats.duplicate(true)
	var en_classic: Dictionary = GameState.ensure_theme_progress("en", 9, 0)
	check(bool(en_classic.guessed.get("DIRECTOR", false)), "English classic cross-theme alias lost revision-3 progress")
	var en_campaign: Dictionary = GameState.ensure_single_player_theme_progress("en", 8, 0)
	check(bool(en_campaign.played.get("WEBCAM", false)) and bool(en_campaign.guessed.get("WEBCAM", false)), "English campaign merge lost revision-3 progress")
	var en_sport: Dictionary = GameState.ensure_single_player_theme_progress("en", 0, 0)
	check(bool(en_sport.played.get("RACKET", false)) and bool(en_sport.guessed.get("CAPTAIN'S ARMBAND", false)), "English same-theme rename lost progress")
	var migrated_stats: Dictionary = GameState._single_player_bucket("en")["word_stats"].duplicate(true)
	GameState.ensure_single_player_theme_progress("en", 8, 0)
	check(GameState._single_player_bucket("en")["word_stats"] == migrated_stats, "English alias migration must be idempotent")
	GameState.single_player = {}
	GameState.interface_language = "ru"
	GameState.word_language = "ru"
	Database.load_languages("ru", "ru")
	GameState.progress = {"ru": {"10": {"guessed": {"ОПИСАНИЕ СЮЖЕТА": true}}}}
	var merged: Dictionary = GameState.ensure_theme_progress("ru", 6, 0)
	check(bool(merged.guessed.get("СИНОПСИС", false)), "Cross-theme merge lost guessed progress")
	check(Database.word_progress_key_from_text("НОВАЯ ВЕРСИЯ") == "РЕМЕЙК", "Renamed answer lost its progress alias")
	var first: Dictionary = GameState.mark_single_level_word_played("ru", 0, 0, 3, true, true, -1, true, false)
	check(is_equal_approx(first.difficulty_after, .19), "A mid-level win must raise difficulty")
	check(!first.completed and first.completion_bonus == 0, "No completion reward mid-level")
	var second: Dictionary = GameState.mark_single_level_word_played("ru", 0, 1, 3, false, true, -1, true, false)
	check(is_equal_approx(second.difficulty_after, .178), "A lost stage must lower difficulty")
	check(second.win_streak == 0 and second.loss_streak == 1, "Loss must reset winning streak")
	var third: Dictionary = GameState.mark_single_level_word_played("ru", 0, 2, 3, true, true, -1, true, false)
	check(third.completed and !third.perfect and third.difficulty_after > third.difficulty_before, "A win after a loss must still raise difficulty")
	check(third.completion_bonus > 0, "Mixed-result chain keeps its completion reward")
	var coins: int = GameState.get_soft_currency()
	var repeated: Dictionary = GameState.mark_single_level_word_played("ru", 0, 2, 3, false, true, -1, true, false)
	check(is_zero_approx(repeated.difficulty_delta) and repeated.completion_bonus == 0, "Duplicate result must be idempotent")
	check(GameState.get_single_level_word_status("ru", 0, 2, 3) == 1 and GameState.get_soft_currency() == coins, "Duplicate cannot rewrite result or award coins")
	GameState.single_player = {}
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	var level: int = 4
	var count: int = main._single_player_level_word_target(level)
	GameState._single_player_bucket("ru")["unlocked_level"] = level
	GameState.select_single_level_theme("ru", level, 0, count)
	main._invalidate_single_player_level_cache()
	var before: Dictionary = main._single_player_level_data(level).duplicate(true)
	check(GameState.get_single_level_word_assignments("ru", level).size() == 1, "Only the first offered stage is committed")
	GameState.mark_single_level_word_played("ru", level, 0, count, true, true, -1, true, false)
	var after: Dictionary = main._single_player_level_data(level).duplicate(true)
	check(after.words[0] == before.words[0], "Completed assignment changed on adaptation")
	check(after.words[1].target_difficulty > before.words[1].target_difficulty, "Next stage did not use updated target")
	check(GameState.get_single_level_word_assignments("ru", level).size() == 2, "Next assignment was not persisted")
	var ids: Dictionary = {}
	for word: Dictionary in after.words:
		ids[word.id] = true
	check(ids.size() == after.words.size(), "Repeated word inside a level")
	GameState.save_game()
	GameState.single_player = {}
	GameState.load_game()
	main._invalidate_single_player_level_cache()
	var restored: Dictionary = main._single_player_level_data(level)
	for slot: int in range(2):
		check(restored.words[slot].id == after.words[slot].id and restored.words[slot].text == after.words[slot].text and is_equal_approx(restored.words[slot].target_difficulty, after.words[slot].target_difficulty), "Saved assigned prefix changed on reload")
	var base: float = GameState.get_single_player_adaptive_difficulty("ru")
	var hard: Dictionary = main._single_player_level_data(9)
	var normal: Dictionary = main._single_player_level_data(10)
	check(hard.is_bonus_level and hard.target_difficulty > base, "Hard level requires temporary offset")
	check(is_equal_approx(normal.target_difficulty, base) and is_equal_approx(GameState.get_single_player_adaptive_difficulty("ru"), base), "Hard offset leaked into shared base or next level")
	# At the clamp, the stage still advances even though the numeric target is unchanged.
	GameState._single_player_bucket("ru")["adaptive_difficulty"] = GameState.SINGLE_PLAYER_DIFFICULTY_MAX
	main._invalidate_single_player_level_cache()
	main._single_player_level_data(level)
	GameState.mark_single_level_word_played("ru", level, 1, count, true, true, -1, true, false)
	main._single_player_level_data(level)
	check(GameState.get_single_level_word_assignments("ru", level).size() == mini(3, count), "Clamped difficulty kept an obsolete stage cache")
	# Quiz is selected provisionally until its actual stage begins.
	GameState.single_player = {}
	main._invalidate_single_player_level_cache()
	level = 2
	count = main._single_player_level_word_target(level)
	GameState._single_player_bucket("ru")["unlocked_level"] = level
	GameState.select_single_level_theme("ru", level, 0, count)
	main._invalidate_single_player_level_cache()
	before = main._single_player_level_data(level)
	check(before.question_slot == 1 and !before.question.is_empty(), "Quiz onboarding fixture changed")
	check(GameState.get_single_level_question_id("ru", level) == -1, "Future quiz was committed too early")
	GameState.mark_single_level_word_played("ru", level, 0, count, false, true, -1, true, false)
	after = main._single_player_level_data(level)
	check(GameState.get_single_level_question_id("ru", level) == int(after.question.id), "Current quiz was not committed")
	check(after.question_target_difficulty < before.question_target_difficulty, "Quiz did not use the same stage adaptation")
	GameState.reset_single_level_attempt("ru", level, true, true, false)
	check(GameState.get_single_level_word_assignments("ru", level).is_empty(), "Retry retained old assignments")
	# The maximum is twenty letters, not twenty characters including spaces.
	main.show_menu()
	GameSession.start_round(WordData.new("БЕСПРОВОДНЫЕ НАУШНИКИ", .2, -1, -1), GameState.GameMode.TWO_PLAYER)
	check(GameSession.letters.size() == 21 and GameSession.revealed[12], "Twenty-letter phrase was truncated or its space hidden")
	main.game_finished = false
	main.show_game_screen()
	GameSession.revealed.fill(true)
	main._refresh_game_screen()
	await get_tree().process_frame
	var holder: Control = main._portrait_game_word_slots_root
	var visible_letters: int = 0
	for slot: Node in holder.get_children():
		for child: Node in slot.get_children():
			if child is Label and child.text.length() == 1:
				visible_letters += 1
				var font: Font = child.get_theme_font("font")
				var text_width: float = font.get_string_size(child.text, HORIZONTAL_ALIGNMENT_LEFT, -1, child.get_theme_font_size("font_size")).x
				check(text_width <= slot.size.x + 2.0, "Long answer glyph overflows its slot: %s %.2f / %.2f" % [child.text, text_width, slot.size.x])
	check(visible_letters == 20, "Not all twenty letters are displayed")
	# Completion rules are tested independently of result-screen animations.
	GameSession.round_won.disconnect(main._on_round_won)
	GameSession.revealed.fill(false)
	GameSession.revealed[12] = true
	for letter: String in GameSession.letters:
		if !GameSession._is_separator(letter) and GameSession.is_active:
			GameSession.guess(letter)
	check(GameSession.is_word_completed(), "Twenty-letter phrase cannot be completed")
	GameSession.start_round(WordData.new("DIRECTOR'S CUT", .3, -1, -1), GameState.GameMode.TWO_PLAYER)
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
