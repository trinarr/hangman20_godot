extends Node
const MODEL = preload("res://scripts/core/profile_statistics.gd")
var failures := 0
var checks := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if !ok:
		failures += 1
		push_error(message)
func _ready() -> void:
	var legacy := {"ru": {"unlocked_level": 8, "levels": {"7": [1, 1, 2]}, "level_question_slots": {"7": [1]}, "word_stats": {"1": {"guessed": {"a": true, "b": true}}}}, "en": {"unlocked_level": 2}}
	var migrated := MODEL.migrate(legacy, 150, GameState.GAME_DESIGN)
	check(migrated.levels_completed == 10 and migrated.quizzes_solved == 1 and migrated.words_solved == 2 and migrated.stars_earned == 150, "Legacy language histories merge without double-counting word flags")
	check(MODEL.normalize({"stars_earned": -9, "words_solved": "broken"}).stars_earned == 0, "Malformed statistics normalize safely")
	GameState.single_player = {}
	GameState.profile_statistics = MODEL.normalize({})
	GameState.stars = 0
	GameState.set_single_level_question_slots("ru", 0, [1])
	GameState.mark_single_level_word_played("ru", 0, 0, 2, true, true, -1, false, false, -1, 3)
	GameState.mark_single_level_word_played("ru", 0, 0, 2, true, true, -1, false, false, -1, 3)
	check(GameState.get_profile_statistics().words_solved == 1 and GameState.get_profile_statistics().stars_earned == 3, "Duplicate result cannot increment statistics")
	GameState.mark_single_level_word_played("ru", 0, 1, 2, true, true, -1, false, false, -1, 4)
	var totals := GameState.get_profile_statistics()
	check(totals.levels_completed == 1 and totals.quizzes_solved == 1 and totals.words_solved == 1, "Only completed chains count as levels; quizzes and words remain separate")
	var expected_stars := 7 + GameState._single_player_level_completion_stars(0, 2)
	check(totals.stars_earned == expected_stars, "Stars include stage and completion rewards exactly once")
	GameState.add_stars(10, false)
	GameState.spend_stars(5, false)
	check(GameState.get_profile_statistics() == totals, "Wallet changes and reward claims never count earned gameplay stars again")
	GameState.add_gameplay_stars(6, false)
	check(GameState.get_profile_statistics().stars_earned == totals.stars_earned + 6, "Quiz speed and remaining-attempt gameplay bonuses count as earned stars")
	var hard_index := 0
	while !GameState.GAME_DESIGN.is_bonus_level(hard_index + 1):
		hard_index += 1
	GameState.mark_single_level_word_played("en", hard_index, 0, 1, false, true, -1, false, false)
	check(GameState.get_profile_statistics().hard_levels_completed == 1 and GameState.get_profile_statistics().words_solved == 1, "Hard chain completion counts once and wrong answers do not count as solved")
	var saved := GameState.get_profile_statistics()
	check(GameState.save_game(), "Profile statistics save succeeds")
	GameState.profile_statistics = {}
	GameState.load_game()
	check(GameState.get_profile_statistics() == saved, "All totals survive save/load and progress compaction")
	print("PROFILE_STATISTICS checks=%d failures=%d" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
