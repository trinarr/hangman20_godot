extends Node
const PICK = preload("res://scripts/core/word_selection.gd")
var failures: int = 0
var checks: int = 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr(message)
func word(text: String, difficulty: float) -> Dictionary:
	return {"text": text, "difficulty": difficulty}
func choose(pool: Array, history: Dictionary = {}, intro: bool = false, target: float = 0.3) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = 123
	return PICK.pick_index(pool, target, history, intro, rng)
func history(keys: Array, counts: Array, seen: Array, recent: Array = []) -> Dictionary:
	var h := {"seen_count": {}, "last_seen": {}, "recent_words": []}
	for i: int in range(keys.size()):
		var key: String = Database.word_progress_key_from_text(keys[i])
		h.seen_count[key] = counts[i]
		h.last_seen[key] = seen[i]
	for key: String in recent:
		h.recent_words.append(Database.word_progress_key_from_text(key))
	return h
func _ready() -> void:
	var pool := [word("OLD", 0.3), word("NEW", 0.32)]
	check(choose(pool, history(["OLD"], [1], [1])) == 1, "Unseen beats exact repeat")
	check(choose([word("EASY", 0.2), word("HARD", 0.36)]) == 0, "Easier expansion precedes harder")
	check(choose([word("EASY", 0.1), word("NEAR", 0.22)]) == 1, "Expand in steps")
	check(choose([word("OLD", 0.3), word("NEW", 0.36)], history(["OLD"], [1], [1])) == 1, "Modest harder unseen accepted")
	check(choose([word("OLD", 0.3), word("NEW", 0.39)], history(["OLD"], [1], [1])) == 0, "Too-hard unseen rejected")
	check(choose([word("OLD", 0.08), word("NEW", 0.14)], history(["OLD"], [1], [1]), true, 0.08) == 0, "Intro has stricter cap")
	pool = [word("A", 0.3), word("B", 0.3)]
	check(choose(pool, history(["A", "B"], [3, 1], [1, 2])) == 1, "Repeat count first")
	check(choose(pool, history(["A", "B"], [1, 1], [5, 2])) == 1, "Oldest breaks count tie")
	check(choose(pool, history(["A", "B"], [1, 4], [5, 2], ["A"])) == 1, "Recent excluded before count ranking")
	check(choose(pool, history(["A", "B"], [1, 4], [5, 2], ["B", "A"])) == 1, "Exhausted cooldown lifts oldest first")
	check(choose([word("A", 0.8), word("B", 0.6)]) == 1, "No suitable content uses easiest fallback")
	check(choose([]) == -1, "Empty pool")
	GameState.single_player = {}
	var words: Array = Database.get_words_by_index(5, 0)
	var w: Dictionary = words[0]
	var key: String = Database.word_progress_key_from_text(w.text)
	var target_before: float = GameState.get_single_player_theme_target_difficulty("ru", 5, 0.6)
	GameState.mark_single_player_word_shown("ru", 5, int(w.index), words.size(), w.text, false)
	var stats: Dictionary = GameState.ensure_single_player_theme_progress("ru", 5, words.size())
	check(int(stats.seen_count[key]) == 1, "First real show counted once")
	check(is_equal_approx(target_before, GameState.get_single_player_theme_target_difficulty("ru", 5, 0.6)), "Showing word does not advance intro")
	GameState.mark_single_player_word_shown("ru", 5, int(w.index), words.size(), w.text, false)
	check(int(stats.seen_count[key]) == 2 and int(stats.last_seen[key]) == 2, "Actual repeat counted")
	GameState.save_game()
	GameState.load_game()
	stats = GameState.ensure_single_player_theme_progress("ru", 5, words.size())
	check(int(stats.seen_count[key]) == 2 and int(stats.last_seen[key]) == 2, "History persists across save reload")
	check(GameState.ensure_single_player_theme_progress("en", 5, 0).seen_count.is_empty(), "Languages isolated")
	var main_script: GDScript = load("res://scripts/main.gd")
	var main: Node = main_script.new()
	GameState.single_player = {}
	var before: Dictionary = GameState.ensure_single_player_theme_progress("ru", 5, 0).duplicate(true)
	var selected: Array = main._single_player_words_for_theme(0, 123, 5, 3, 0.6)
	var after: Dictionary = GameState.ensure_single_player_theme_progress("ru", 5, 0)
	check(before.seen_count == after.seen_count and before.seen_sequence == after.seen_sequence, "Chain preview does not count presentations")
	var keys: Dictionary = {}
	for row: Dictionary in selected:
		keys[Database.word_progress_key_from_text(row.text)] = true
		check(is_equal_approx(float(row.target_difficulty), 0.08), "Chain selector uses intro target")
	check(keys.size() == selected.size(), "Chain reservations prevent duplicates")
	var selected_again: Array = main._single_player_words_for_theme(0, 123, 5, 3, 0.6)
	check(selected[0].text == selected_again[0].text, "Saved current assignment preserved")
	main.free()
	print("WORD SELECTION: %d checks, %d failures" % [checks, failures])
	get_tree().quit(failures)
