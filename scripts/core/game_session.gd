extends Node

const GAME_DESIGN: GDScript = preload("res://scripts/core/game_design_config.gd")

signal changed
signal round_won
signal round_lost
signal hint_letters_selected(letters: PackedStringArray, is_correct: bool)

var WRONG_LETTER_VIBRATION_MS: int = GAME_DESIGN.get_int(
	"gameplay.vibration.wrong_letter_ms", 35
)
var MAX_MISTAKES: int = GAME_DESIGN.get_int_range("gameplay.max_mistakes", 6, 1, 64)

var word_index: int = -1
var theme_id: int = -1
var word_data: WordData = null
var letters: PackedStringArray = []
var revealed: Array = []
var correct_letters: PackedStringArray = []
var wrong_letters: PackedStringArray = []
var removed_wrong_letters: PackedStringArray = []
var mistakes: int = 0
var is_active: bool = false
var loss_deferred: bool = false
var mode: int = GameState.GameMode.CLASSIC
var open_hint_used: bool = false
var remove_wrong_hint_used: bool = false
var open_hint_ad_reuse_available: bool = false
var remove_wrong_hint_ad_reuse_available: bool = false
var comment_hint_unlocked: bool = false
var word_hint_text: String = ""

func get_remaining_attempts() -> int:
	if loss_deferred:
		return 0
	return maxi(MAX_MISTAKES - mistakes, 0)

func start_round(word: WordData, game_mode: int = GameState.GameMode.CLASSIC) -> void:
	word_data = word
	word_index = word.index
	theme_id = word.theme_index
	mode = game_mode
	letters = _split_letters(word.text)
	revealed.clear()
	correct_letters.clear()
	wrong_letters.clear()
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
	emit_signal("changed")

func start_new_round(theme_index: int) -> void:
	var word := WordManager.select_new_word(theme_index)
	start_round(word, GameState.GameMode.CLASSIC)

func start_custom_round(text: String, comment: String = "") -> void:
	var word := WordManager.set_custom_word(text, comment)
	start_round(word, GameState.GameMode.TWO_PLAYER)

func _resolve_word_hint() -> String:
	if word_data == null:
		return ""
	if word_data.custom_comment.strip_edges() != "":
		return word_data.custom_comment.strip_edges()
	if theme_id >= 0 and word_index >= 0:
		return Database.get_hint(theme_id, word_index)
	return ""

func _split_letters(text: String) -> PackedStringArray:
	var result := PackedStringArray()
	for i in range(text.length()):
		result.append(text.substr(i, 1))
	return result

func to_save_data() -> Dictionary:
	if word_data == null or mode != GameState.GameMode.SINGLE_PLAYER:
		return {}
	return {
		"word": word_data.text,
		"difficulty": word_data.difficulty,
		"theme_id": Database.get_theme_id(theme_id),
		"word_index": word_index,
		"custom_comment": word_data.custom_comment,
		"revealed": revealed.duplicate(),
		"correct_letters": Array(correct_letters),
		"wrong_letters": Array(wrong_letters),
		"removed_wrong_letters": Array(removed_wrong_letters),
		"mistakes": clampi(mistakes, 0, MAX_MISTAKES),
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
	var text: String = WordManager.normalize_word(str(source.get("word", "")))
	var restored_theme_index: int = Database.get_theme_index_by_id(
		int(source.get("theme_id", -1))
	)
	var restored_word_index: int = int(source.get("word_index", -1))
	if text.is_empty() or restored_theme_index < 0 or restored_word_index < 0:
		return false
	var restored_letters: PackedStringArray = _split_letters(text)
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
		str(source.get("custom_comment", ""))
	)
	word_index = restored_word_index
	theme_id = restored_theme_index
	mode = GameState.GameMode.SINGLE_PLAYER
	letters = restored_letters
	revealed = restored_revealed.duplicate()
	correct_letters = _packed_string_array_from_save(source.get("correct_letters", []))
	wrong_letters = _packed_string_array_from_save(source.get("wrong_letters", []))
	removed_wrong_letters = _packed_string_array_from_save(source.get("removed_wrong_letters", []))
	mistakes = clampi(int(source.get("mistakes", 0)), 0, MAX_MISTAKES - 1)
	loss_deferred = bool(source.get("loss_deferred", false))
	open_hint_used = bool(source.get("open_hint_used", false))
	remove_wrong_hint_used = bool(source.get("remove_wrong_hint_used", false))
	open_hint_ad_reuse_available = bool(source.get("open_hint_ad_reuse_available", false))
	remove_wrong_hint_ad_reuse_available = bool(source.get("remove_wrong_hint_ad_reuse_available", false))
	comment_hint_unlocked = bool(source.get("comment_hint_unlocked", false))
	word_hint_text = str(source.get("word_hint_text", _resolve_word_hint()))
	is_active = true
	emit_signal("changed")
	return true

func _is_separator(letter: String) -> bool:
	return letter == " " or letter == "-" or letter == "—"

func guess(letter: String, defer_loss: bool = false) -> bool:
	if !is_active or loss_deferred:
		return false
	letter = WordManager.normalize_word(letter)
	if letter.length() != 1:
		return false
	if correct_letters.has(letter) or wrong_letters.has(letter) or removed_wrong_letters.has(letter):
		return false
	var correct := _reveal_letter(letter)
	if correct:
		if is_word_completed():
			is_active = false
			emit_signal("changed")
			emit_signal("round_won")
		else:
			emit_signal("changed")
		return true
	wrong_letters.append(letter)
	var reaches_loss_limit: bool = mistakes + 1 >= MAX_MISTAKES
	if defer_loss and reaches_loss_limit:
		loss_deferred = true
	else:
		mistakes += 1
	if int(GameState.settings[4]) == 2:
		# A short pulse gives subtle feedback without interrupting gameplay.
		Input.vibrate_handheld(WRONG_LETTER_VIBRATION_MS)
	if mistakes >= MAX_MISTAKES:
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
	var granted_attempts: int = maxi(attempt_count, 1)
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
	mistakes = MAX_MISTAKES
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
		and !open_hint_used
		and _has_hidden_letter()
		and _hints_allowed()
	)

func can_use_remove_wrong_hint() -> bool:
	return (
		is_active
		and !remove_wrong_hint_used
		and _has_removable_wrong_letter()
		and _hints_allowed()
	)

func can_use_open_letter_hint_ad() -> bool:
	return (
		is_active
		and open_hint_used
		and open_hint_ad_reuse_available
		and _has_hidden_letter()
		and _hints_allowed()
	)

func can_use_remove_wrong_hint_ad() -> bool:
	return (
		is_active
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
	emit_signal("changed")
	return true

func unlock_comment_hint() -> bool:
	if comment_hint_unlocked:
		return can_view_comment_hint()
	if !can_unlock_comment_hint():
		return false
	if GameState.pay_for_hint(
		GameState.HINT_COMMENT,
		false
	) == GameState.HintPayment.FAILED:
		return false
	comment_hint_unlocked = true
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
	letters.clear()
	revealed.clear()
	correct_letters.clear()
	wrong_letters.clear()
	removed_wrong_letters.clear()
	mistakes = 0
	loss_deferred = false
	is_active = false
	mode = GameState.GameMode.CLASSIC
	open_hint_used = false
	remove_wrong_hint_used = false
	open_hint_ad_reuse_available = false
	remove_wrong_hint_ad_reuse_available = false
	comment_hint_unlocked = false
	word_hint_text = ""
	GameState.reset_current_game()

func finish_result(is_win: bool, award_win_coins: bool = true) -> Dictionary:
	var result := {
		"title": Database.tr_text(33 if is_win else 34, "VICTORY" if is_win else "DEFEAT"),
		"lines": []
	}
	if word_data == null:
		return result

	if is_win:
		if award_win_coins:
			GameState.add_soft_currency(GameState.WORD_REWARD_COINS, false)
		var reward_text: String = tr("COINS_EARNED")
		if reward_text == "COINS_EARNED":
			reward_text = "Coins: +%d"
		result["lines"].append(reward_text % GameState.WORD_REWARD_COINS)

	var diff: int = 1 if word_data.difficulty > Database.DIFFICULTY_SPLIT else 0

	# Only Classic category words update the Classic difficulty streak. Level
	# rounds keep their word statistics and progression in a separate bucket.
	if mode == GameState.GameMode.CLASSIC and theme_id >= 0:
		if is_win:
			GameState.records[0][diff] = int(GameState.records[0][diff]) + 1
			if int(GameState.records[0][diff]) > int(GameState.records[0][2 + diff]):
				GameState.records[0][2 + diff] = int(GameState.records[0][diff])
		else:
			GameState.records[0][diff] = 0

	if mode == GameState.GameMode.CLASSIC:
		if is_win and theme_id >= 0:
			GameState.mark_guessed(
				Database.current_language,
				theme_id,
				word_index,
				Database.get_words_by_index(theme_id, 0).size(),
				word_data.text,
				false
			)
			if _is_theme_completed(theme_id):
				result["lines"].append(Database.tr_text(57, "Category is completed!"))
	elif mode == GameState.GameMode.SINGLE_PLAYER:
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
	return result

func _is_theme_completed(theme_index: int) -> bool:
	return Database.get_number_of_all_words(theme_index, true) - Database.get_number_of_guessed_words(theme_index, true) == 0
