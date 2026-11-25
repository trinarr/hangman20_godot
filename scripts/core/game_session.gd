extends Node


const GAME_DESIGN: GDScript = preload("res://scripts/core/game_design_config.gd")
const WORD_CROSSWORD = preload("res://scripts/core/word_crossword.gd")
const CROSSWORD_STARTERS = preload("res://scripts/core/crossword_starters.gd")

signal changed
signal round_started
signal round_won
signal round_lost
signal round_finished(id: String, game_mode: int, won: bool, outcome: String)
signal hint_letters_selected(letters: PackedStringArray, is_correct: bool)
signal hint_activated(hint_type: String, source: String)

var WRONG_LETTER_VIBRATION_MS: int = GAME_DESIGN.get_int(
	"gameplay.vibration.wrong_letter_ms"
)
var MAX_MISTAKES: int = GAME_DESIGN.get_int_range("gameplay.max_mistakes", 1, 64)
var CROSSWORD_MAX_MISTAKES: int = GAME_DESIGN.get_int_range("gameplay.crossword_max_mistakes", 1, 64)

var round_id: String = ""
var word_index: int = -1
var theme_id: int = -1
var word_data: WordData = null
var crossword: RefCounted
var letters: PackedStringArray = []
var revealed: Array = []
var correct_letters: PackedStringArray = []
var wrong_letters: PackedStringArray = []
var misplaced_letters: PackedStringArray = []
var removed_wrong_letters: PackedStringArray = []
var mistakes: int = 0
var attempt_limit: int = MAX_MISTAKES
var is_active: bool = false
var loss_deferred: bool = false
var mode: int = GameState.GameMode.SINGLE_PLAYER
var open_hint_used: bool = false
var remove_wrong_hint_used: bool = false
var open_hint_ad_reuse_available: bool = false
var remove_wrong_hint_ad_reuse_available: bool = false
var comment_hint_unlocked: bool = false
var word_hint_text: String = ""
var crossword_starter_cells := PackedInt32Array()
var crossword_starter_letters := PackedStringArray()

func get_remaining_attempts() -> int:
	if loss_deferred:
		return 0
	return maxi(attempt_limit - mistakes, 0)

func start_round(
	word: WordData, game_mode: int = GameState.GameMode.SINGLE_PLAYER, word_count: int = 1,
	opening_words: Array = []
) -> void:
	round_id = "%d:%d" % [Time.get_ticks_usec(), randi()]
	word_data = word
	if word_data.id.is_empty() and word.theme_index >= 0:
		var reference: Dictionary = Database.resolve_saved_word(Database.get_theme_id(word.theme_index), word.text)
		word_data.id = str(reference.get("id", ""))
	word_index = word.index
	theme_id = word.theme_index
	mode = game_mode
	attempt_limit = CROSSWORD_MAX_MISTAKES if mode == GameState.GameMode.SINGLE_PLAYER else MAX_MISTAKES
	var use_starters: bool = mode == GameState.GameMode.SINGLE_PLAYER
	var candidates: Array = Database.get_words_by_index(theme_id, 0) if theme_id >= 0 and (word_count > 1 or use_starters) else []
	var puzzle_candidates: Array = candidates
	var use_opening: bool = (
		use_starters and !opening_words.is_empty()
		and opening_words.size() == word_count and opening_words[0] == word.text
	)
	if use_opening:
		puzzle_candidates = candidates.filter(func(candidate: Dictionary) -> bool: return opening_words.has(candidate.text))
		use_opening = puzzle_candidates.size() == word_count
		if !use_opening:
			puzzle_candidates = candidates
	crossword = WORD_CROSSWORD.build(word.text, word.difficulty, puzzle_candidates, word_count)
	letters = crossword.letters
	revealed.clear()
	correct_letters.clear()
	wrong_letters.clear()
	misplaced_letters.clear()
	removed_wrong_letters.clear()
	mistakes = 0
	loss_deferred = false
	open_hint_used = false
	remove_wrong_hint_used = false
	open_hint_ad_reuse_available = false
	remove_wrong_hint_ad_reuse_available = false
	comment_hint_unlocked = false
	word_hint_text = _resolve_word_hint()
	is_active = word.text.length() > 0
	for i in range(letters.size()):
		revealed.append(_is_separator(letters[i]))
	var starter_cells: Array = []
	if use_opening:
		starter_cells = Array(CROSSWORD_STARTERS.transfer_cells(crossword))
	elif use_starters:
		starter_cells = Array(CROSSWORD_STARTERS.choose(crossword, candidates, Database.current_language))
	_set_crossword_starters(starter_cells)
	for index: int in crossword_starter_cells:
		revealed[index] = true
	emit_signal("changed")
	round_started.emit()

func start_custom_round(text: String) -> void:
	var word := WordManager.set_custom_word(text)
	start_round(word, GameState.GameMode.TWO_PLAYER)

func _resolve_word_hint() -> String:
	if word_data == null:
		return ""
	if theme_id >= 0:
		var reference: Dictionary = Database.resolve_saved_word(Database.get_theme_id(theme_id), word_data.text, word_data.id)
		return str(reference.get("hint", ""))
	return ""

func to_save_data() -> Dictionary:
	if word_data == null or mode != GameState.GameMode.SINGLE_PLAYER:
		return {}
	return {
		"round_id": round_id,
		"word": word_data.text,
		"crossword": crossword.entries.duplicate(true),
		"crossword_starter_cells": Array(crossword_starter_cells),
		"word_id": word_data.id,
		"content_version": Database.WORD_CONTENT.CONTENT_VERSION,
		"difficulty": word_data.difficulty,
		"theme_id": Database.get_theme_id(theme_id),
		"word_index": word_index,
		"revealed": revealed.duplicate(),
		"correct_letters": Array(correct_letters),
		"wrong_letters": Array(wrong_letters),
		"misplaced_letters": Array(misplaced_letters),
		"removed_wrong_letters": Array(removed_wrong_letters),
		"attempt_limit": attempt_limit,
		"mistakes": clampi(mistakes, 0, attempt_limit),
		"loss_deferred": loss_deferred,
		"open_hint_used": open_hint_used,
		"remove_wrong_hint_used": remove_wrong_hint_used,
		"open_hint_ad_reuse_available": open_hint_ad_reuse_available,
		"remove_wrong_hint_ad_reuse_available": remove_wrong_hint_ad_reuse_available,
		"comment_hint_unlocked": comment_hint_unlocked,
		"word_hint_text": word_hint_text,
	}

func _packed_string_array_from_save(source: Variant) -> PackedStringArray:
	var result := PackedStringArray()
	if source is Array:
		for value: Variant in source:
			var letter: String = str(value)
			if letter.length() == 1 and !result.has(letter):
				result.append(letter)
	return result

func restore_from_save_data(source: Dictionary) -> bool:
	var profile_result: bool = _home_profile_restore_from_save_data(source)
	return profile_result

func get_saved_attempt_limit(source: Dictionary) -> int:
	return clampi(int(source.get("attempt_limit", MAX_MISTAKES)), 1, 64)

func _home_profile_restore_from_save_data(source: Dictionary) -> bool:
	var text: String = WordManager.normalize_word(str(source.get("word", "")))
	var restored_theme_index: int = Database.get_theme_index_by_id(
		int(source.get("theme_id", -1))
	)
	var reference: Dictionary = Database.resolve_saved_word(int(source.get("theme_id", -1)), text, str(source.get("word_id", "")))
	var restored_word_index: int = int(reference.get("index", -1))
	if text.is_empty() or restored_theme_index < 0 or reference.is_empty():
		return false
	var restored_board: RefCounted
	if source.has("crossword"):
		restored_board = WORD_CROSSWORD.restore(text, source["crossword"])
		if restored_board == null:
			return false
	else:
		restored_board = WORD_CROSSWORD.build(text, 0.0, [], 1)
	var restored_letters: PackedStringArray = restored_board.letters
	var restored_revealed_variant: Variant = source.get("revealed", [])
	if !(restored_revealed_variant is Array):
		return false
	var restored_revealed: Array = Array(restored_revealed_variant)
	if restored_revealed.size() != restored_letters.size():
		return false
	for index: int in range(restored_revealed.size()):
		restored_revealed[index] = bool(restored_revealed[index]) or _is_separator(restored_letters[index])

	word_data = WordData.new(
		text,
		clampf(float(source.get("difficulty", 0.0)), 0.0, 1.0),
		restored_theme_index,
		restored_word_index,
		str(reference["id"])
	)
	word_index = restored_word_index
	theme_id = restored_theme_index
	mode = GameState.GameMode.SINGLE_PLAYER
	crossword = restored_board
	letters = restored_letters
	revealed = restored_revealed.duplicate()
	_set_crossword_starters(source.get("crossword_starter_cells", []))
	# Older rounds displayed some starter codes above the grid. Move those clues
	# onto their saved cells while leaving the last move to the player.
	var hidden_cells: int = revealed.count(false)
	for index: int in crossword_starter_cells:
		if !revealed[index] and hidden_cells > 1:
			revealed[index] = true
			hidden_cells -= 1
	correct_letters = _packed_string_array_from_save(source.get("correct_letters", []))
	wrong_letters = _packed_string_array_from_save(source.get("wrong_letters", []))
	misplaced_letters = _packed_string_array_from_save(source.get("misplaced_letters", []))
	removed_wrong_letters = _packed_string_array_from_save(source.get("removed_wrong_letters", []))
	attempt_limit = get_saved_attempt_limit(source)
	mistakes = clampi(int(source.get("mistakes", 0)), 0, attempt_limit - 1)
	loss_deferred = bool(source.get("loss_deferred", false))
	open_hint_used = bool(source.get("open_hint_used", false))
	remove_wrong_hint_used = bool(source.get("remove_wrong_hint_used", false))
	open_hint_ad_reuse_available = bool(source.get("open_hint_ad_reuse_available", false))
	remove_wrong_hint_ad_reuse_available = bool(source.get("remove_wrong_hint_ad_reuse_available", false))
	comment_hint_unlocked = bool(source.get("comment_hint_unlocked", false))
	word_hint_text = str(source.get("word_hint_text", reference.get("hint", "")))
	round_id = str(source.get("round_id", "%d:%d" % [Time.get_ticks_usec(), randi()]))
	is_active = true
	emit_signal("changed")
	return true

func _is_separator(letter: String) -> bool:
	return WORD_CROSSWORD.is_separator(letter)

func _set_crossword_starters(indices: Variant) -> void:
	crossword_starter_cells.clear()
	crossword_starter_letters.clear()
	if !(indices is Array):
		return
	for raw_index: Variant in indices:
		if !(raw_index is int or raw_index is float) or raw_index < 0 or raw_index >= letters.size() or int(raw_index) != raw_index:
			continue
		var index: int = int(raw_index)
		var letter: String = letters[index]
		if !_is_separator(letter) and !crossword_starter_letters.has(letter):
			crossword_starter_cells.append(index)
			crossword_starter_letters.append(letter)

func guess(letter: String, defer_loss: bool = false) -> bool:
	letter = WordManager.normalize_word(letter)
	if !can_guess_letter(letter):
		return false
	if _reveal_letter(letter):
		_publish_correct_guess()
		return true
	return _record_wrong_guess(letter, defer_loss)

func can_guess_cell(index: int) -> bool:
	return is_active and !loss_deferred and index >= 0 and index < revealed.size() and !revealed[index]

func can_guess_letter(letter: String, cell_index: int = -1) -> bool:
	if !is_active or loss_deferred or letter.length() != 1 or wrong_letters.has(letter) or removed_wrong_letters.has(letter):
		return false
	if cell_index == -1:
		return !correct_letters.has(letter)
	return can_guess_cell(cell_index) and (
		(!correct_letters.has(letter) and !crossword_starter_letters.has(letter))
		or get_hidden_letter_counts().has(letter)
	)

func guess_cell(index: int, letter: String, defer_loss: bool = false) -> bool:
	letter = WordManager.normalize_word(letter)
	if index < 0 or !can_guess_letter(letter, index):
		return false
	if letters[index] != letter:
		return _record_wrong_guess(letter, defer_loss)
	revealed[index] = true
	if !correct_letters.has(letter):
		correct_letters.append(letter)
	_publish_correct_guess()
	return true

func get_hidden_letter_counts() -> Dictionary:
	var counts: Dictionary = {}
	for index: int in range(letters.size()):
		if !revealed[index]:
			var letter: String = letters[index]
			counts[letter] = int(counts.get(letter, 0)) + 1
	return counts

func _publish_correct_guess() -> void:
	if is_word_completed():
		is_active = false
		changed.emit()
		round_won.emit()
	else:
		changed.emit()

func _record_wrong_guess(letter: String, defer_loss: bool) -> bool:
	# A wrong placement does not eliminate a letter that belongs to another cell.
	if !letters.has(letter):
		wrong_letters.append(letter)
	elif !misplaced_letters.has(letter):
		misplaced_letters.append(letter)
	var reaches_loss_limit: bool = mistakes + 1 >= attempt_limit
	if defer_loss and reaches_loss_limit:
		loss_deferred = true
	else:
		mistakes += 1
	if int(GameState.settings[4]) == 2:
		# A short pulse gives subtle feedback without interrupting gameplay.
		Input.vibrate_handheld(WRONG_LETTER_VIBRATION_MS)
	if mistakes >= attempt_limit:
		is_active = false
		emit_signal("changed")
		emit_signal("round_lost")
	else:
		emit_signal("changed")
	return false

func has_deferred_loss() -> bool:
	return loss_deferred

func grant_deferred_attempt(attempt_count: int = 1) -> bool:
	if !loss_deferred or !is_active:
		return false
	var granted_attempts: int = clampi(attempt_count, 1, attempt_limit)
	loss_deferred = false
	# The deferred final mistake was never committed. Clearing the deferred flag
	# already restores one attempt; roll back additional mistakes so the refill
	# leaves the requested number of real guesses on the gameplay counter.
	mistakes = maxi(mistakes - (granted_attempts - 1), 0)
	emit_signal("changed")
	return true

func resolve_deferred_loss() -> bool:
	if !loss_deferred:
		return false
	loss_deferred = false
	mistakes = attempt_limit
	is_active = false
	emit_signal("changed")
	emit_signal("round_lost")
	return true

func _reveal_letter(letter: String) -> bool:
	var found := false
	for i in range(letters.size()):
		if letters[i] == letter:
			revealed[i] = true
			found = true
	if found and !correct_letters.has(letter):
		correct_letters.append(letter)
	return found

func can_use_open_letter_hint() -> bool:
	return (
		is_active
		and (mode != GameState.GameMode.SINGLE_PLAYER
			or GameState.is_single_player_hint_unlocked(Database.current_language, GameState.HINT_OPEN_LETTER))
		and !open_hint_used
		and _has_hidden_letter()
		and _hints_allowed()
	)

func can_use_remove_wrong_hint() -> bool:
	return (
		is_active
		and (mode != GameState.GameMode.SINGLE_PLAYER
			or GameState.is_single_player_hint_unlocked(Database.current_language, GameState.HINT_REMOVE_WRONG))
		and !remove_wrong_hint_used
		and _has_removable_wrong_letter()
		and _hints_allowed()
	)

func can_use_open_letter_hint_ad() -> bool:
	return (
		is_active
		and (mode != GameState.GameMode.SINGLE_PLAYER
			or GameState.is_single_player_hint_unlocked(Database.current_language, GameState.HINT_OPEN_LETTER))
		and open_hint_used
		and open_hint_ad_reuse_available
		and _has_hidden_letter()
		and _hints_allowed()
	)

func can_use_remove_wrong_hint_ad() -> bool:
	return (
		is_active
		and (mode != GameState.GameMode.SINGLE_PLAYER
			or GameState.is_single_player_hint_unlocked(Database.current_language, GameState.HINT_REMOVE_WRONG))
		and remove_wrong_hint_used
		and remove_wrong_hint_ad_reuse_available
		and _has_removable_wrong_letter()
		and _hints_allowed()
	)

func has_word_hint() -> bool:
	return word_hint_text.strip_edges() != ""

func can_unlock_comment_hint() -> bool:
	return (
		is_active
		and !comment_hint_unlocked
		and has_word_hint()
		and _hints_allowed()
	)

func can_view_comment_hint() -> bool:
	return is_active and comment_hint_unlocked and has_word_hint() and _hints_allowed()

func _hints_allowed() -> bool:
	# Hints belong to database-backed rounds. Two-player custom words intentionally
	# have no hints.
	return theme_id >= 0

func _has_hidden_letter() -> bool:
	for i in range(letters.size()):
		if !bool(revealed[i]) and !_is_separator(letters[i]):
			return true
	return false

func _has_removable_wrong_letter() -> bool:
	var alphabet := Database.get_alphabet()
	for letter in alphabet:
		if !letters.has(letter) and !wrong_letters.has(letter) and !removed_wrong_letters.has(letter):
			return true
	return false

func use_open_letter_hint() -> bool:
	if !can_use_open_letter_hint():
		return false
	var candidates: Array = []
	for i in range(letters.size()):
		if !bool(revealed[i]) and !_is_separator(letters[i]):
			candidates.append(i)
	if candidates.is_empty():
		return false
	var payment: int = GameState.pay_for_hint(
		GameState.HINT_OPEN_LETTER,
		false
	)
	if payment == GameState.HintPayment.FAILED:
		return false
	open_hint_used = true
	# The first activation may come either from the player's free inventory or
	# from coins. In both cases, allow exactly one additional activation via a
	# rewarded ad for this round.
	open_hint_ad_reuse_available = true
	var index: int = candidates[randi() % candidates.size()]
	var selected_letter: String = letters[index]
	_reveal_letter(selected_letter)
	if mode != GameState.GameMode.SINGLE_PLAYER:
		GameState.save_game()
	emit_signal("hint_letters_selected", PackedStringArray([selected_letter]), true)
	hint_activated.emit(GameState.HINT_OPEN_LETTER, "inventory" if payment == GameState.HintPayment.FREE_HINT else "coins")
	if is_word_completed():
		is_active = false
		emit_signal("changed")
		emit_signal("round_won")
	else:
		emit_signal("changed")
	return true

func use_open_letter_hint_ad() -> bool:
	if !can_use_open_letter_hint_ad():
		return false
	var candidates: Array = []
	for i in range(letters.size()):
		if !bool(revealed[i]) and !_is_separator(letters[i]):
			candidates.append(i)
	if candidates.is_empty():
		return false
	open_hint_ad_reuse_available = false
	var index: int = candidates[randi() % candidates.size()]
	var selected_letter: String = letters[index]
	_reveal_letter(selected_letter)
	emit_signal("hint_letters_selected", PackedStringArray([selected_letter]), true)
	hint_activated.emit(GameState.HINT_OPEN_LETTER, "rewarded")
	if is_word_completed():
		is_active = false
		emit_signal("changed")
		emit_signal("round_won")
	else:
		emit_signal("changed")
	return true

func use_remove_wrong_hint() -> bool:
	if !can_use_remove_wrong_hint():
		return false
	var alphabet := Database.get_alphabet()
	var candidates: Array = []
	for letter in alphabet:
		if !letters.has(letter) and !wrong_letters.has(letter) and !removed_wrong_letters.has(letter):
			candidates.append(letter)
	if candidates.is_empty():
		return false
	var payment: int = GameState.pay_for_hint(
		GameState.HINT_REMOVE_WRONG,
		false
	)
	if payment == GameState.HintPayment.FAILED:
		return false
	remove_wrong_hint_used = true
	# Free-counter and coin activations both unlock one rewarded-ad reuse.
	remove_wrong_hint_ad_reuse_available = true
	# Remove exactly three unavailable keyboard letters in every language. They
	# are selected without replacement and never count as mistakes.
	var remove_count: int = 3
	var selected_letters := PackedStringArray()
	for _index in range(mini(remove_count, candidates.size())):
		var candidate_index: int = randi() % candidates.size()
		var selected_letter: String = str(candidates[candidate_index])
		removed_wrong_letters.append(selected_letter)
		selected_letters.append(selected_letter)
		candidates.remove_at(candidate_index)
	if mode != GameState.GameMode.SINGLE_PLAYER:
		GameState.save_game()
	emit_signal("hint_letters_selected", selected_letters, false)
	hint_activated.emit(GameState.HINT_REMOVE_WRONG, "inventory" if payment == GameState.HintPayment.FREE_HINT else "coins")
	emit_signal("changed")
	return true

func use_remove_wrong_hint_ad() -> bool:
	if !can_use_remove_wrong_hint_ad():
		return false
	var alphabet := Database.get_alphabet()
	var candidates: Array = []
	for letter in alphabet:
		if !letters.has(letter) and !wrong_letters.has(letter) and !removed_wrong_letters.has(letter):
			candidates.append(letter)
	if candidates.is_empty():
		return false
	remove_wrong_hint_ad_reuse_available = false
	var remove_count: int = 3
	var selected_letters := PackedStringArray()
	for _index in range(mini(remove_count, candidates.size())):
		var candidate_index: int = randi() % candidates.size()
		var selected_letter: String = str(candidates[candidate_index])
		removed_wrong_letters.append(selected_letter)
		selected_letters.append(selected_letter)
		candidates.remove_at(candidate_index)
	emit_signal("hint_letters_selected", selected_letters, false)
	hint_activated.emit(GameState.HINT_REMOVE_WRONG, "rewarded")
	emit_signal("changed")
	return true

func unlock_comment_hint() -> bool:
	if comment_hint_unlocked:
		return can_view_comment_hint()
	if !can_unlock_comment_hint():
		return false
	var payment: int = GameState.pay_for_hint(
		GameState.HINT_COMMENT,
		false
	)
	if payment == GameState.HintPayment.FAILED:
		return false
	comment_hint_unlocked = true
	hint_activated.emit(GameState.HINT_COMMENT, "inventory" if payment == GameState.HintPayment.FREE_HINT else "coins")
	if mode != GameState.GameMode.SINGLE_PLAYER:
		GameState.save_game()
	emit_signal("changed")
	return true

func get_full_word() -> String:
	return "" if word_data == null else word_data.text

func get_word_hint() -> String:
	return word_hint_text

func is_word_completed() -> bool:
	for i in range(letters.size()):
		if !_is_separator(letters[i]) and !bool(revealed[i]):
			return false
	return letters.size() > 0

func discard_current_round() -> void:
	word_index = -1
	theme_id = -1
	word_data = null
	crossword = null
	letters.clear()
	revealed.clear()
	correct_letters.clear()
	wrong_letters.clear()
	misplaced_letters.clear()
	removed_wrong_letters.clear()
	mistakes = 0
	attempt_limit = MAX_MISTAKES
	loss_deferred = false
	is_active = false
	mode = GameState.GameMode.SINGLE_PLAYER
	open_hint_used = false
	remove_wrong_hint_used = false
	open_hint_ad_reuse_available = false
	remove_wrong_hint_ad_reuse_available = false
	comment_hint_unlocked = false
	word_hint_text = ""
	_set_crossword_starters([])
	GameState.reset_current_game()

func report_round_finished(is_win: bool, outcome: String = "") -> void:
	if word_data != null:
		round_finished.emit(round_id, mode, is_win, outcome if !outcome.is_empty() else ("win" if is_win else "loss"))

func finish_result(is_win: bool, outcome: String = "") -> Dictionary:
	var result := {
		"title": Database.tr_text(33 if is_win else 34, "VICTORY" if is_win else "DEFEAT"),
		"lines": []
	}
	if word_data == null:
		return result

	if mode == GameState.GameMode.SINGLE_PLAYER:
		if is_win and theme_id >= 0:
			GameState.mark_single_player_word_guessed(
				Database.current_language,
				theme_id,
				word_index,
				Database.get_words_by_index(theme_id, 0).size(),
				word_data.text,
				false
			)
	elif mode == GameState.GameMode.TWO_PLAYER:
		if is_win:
			GameState.records[1][0] = int(GameState.records[1][0]) + 1
		else:
			GameState.records[1][1] = int(GameState.records[1][1]) + 1

	# Single-player level status, economy and a possible final pending reward are
	# committed together by Main after this method returns.
	if mode != GameState.GameMode.SINGLE_PLAYER:
		GameState.save_game()
	report_round_finished(is_win, outcome)
	return result
