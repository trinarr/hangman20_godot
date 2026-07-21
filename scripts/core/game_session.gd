extends Node

signal changed
signal round_won
signal round_lost

const WRONG_LETTER_VIBRATION_MS: int = 35
const MAX_MISTAKES: int = 7

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
var mode: int = 0 # 0 classic, 1 time attack, 2 two-player
var open_hint_used: bool = false
var remove_wrong_hint_used: bool = false
var word_hint_text: String = ""

func start_round(word: WordData, index: int = -1, theme: int = -1, game_mode: int = 0) -> void:
	word_data = word
	word_index = index if index >= 0 else word.index
	theme_id = theme if theme >= -1 else word.theme_index
	mode = game_mode
	letters = _split_letters(word.text)
	revealed.clear()
	correct_letters.clear()
	wrong_letters.clear()
	removed_wrong_letters.clear()
	mistakes = 0
	open_hint_used = false
	remove_wrong_hint_used = false
	word_hint_text = _resolve_word_hint()
	is_active = word.text.length() > 0
	for i in range(letters.size()):
		revealed.append(_is_separator(letters[i]))
	GameState.save_game()
	emit_signal("changed")

func start_new_round(theme_index: int, game_mode: int = 0) -> void:
	var mode_string := "TA" if game_mode == 1 else "CL"
	var word := WordManager.select_new_word(theme_index, mode_string)
	start_round(word, word.index, word.theme_index, game_mode)

func start_custom_round(text: String, comment: String = "") -> void:
	var word := WordManager.set_custom_word(text, comment)
	start_round(word, -1, -1, 2)

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

func _is_separator(letter: String) -> bool:
	return letter == " " or letter == "-" or letter == "—"

func guess(letter: String) -> bool:
	if !is_active:
		return false
	letter = WordManager.normalize_word(letter)
	if letter.length() != 1:
		return false
	if correct_letters.has(letter) or wrong_letters.has(letter) or removed_wrong_letters.has(letter):
		return false
	var correct := _reveal_letter(letter)
	if correct:
		if mode == 1:
			GameState.correct_guess_streak += 1
			_add_time_attack_points(GameState.correct_guess_streak * 2 * _time_attack_difficulty_factor())
		if is_word_completed():
			is_active = false
			GameState.save_game()
			emit_signal("changed")
			emit_signal("round_won")
		else:
			GameState.save_game()
			emit_signal("changed")
		return true
	wrong_letters.append(letter)
	mistakes += 1
	if mode == 1:
		GameState.correct_guess_streak = 0
	if int(GameState.settings[4]) == 2:
		# A short pulse gives subtle feedback without interrupting gameplay.
		Input.vibrate_handheld(WRONG_LETTER_VIBRATION_MS)
	if mistakes >= MAX_MISTAKES:
		is_active = false
		GameState.save_game()
		emit_signal("changed")
		emit_signal("round_lost")
	else:
		GameState.save_game()
		emit_signal("changed")
	return false

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
	return is_active and !open_hint_used and _has_hidden_letter() and _hints_allowed()

func can_use_remove_wrong_hint() -> bool:
	return is_active and !remove_wrong_hint_used and _has_removable_wrong_letter() and _hints_allowed()

func _hints_allowed() -> bool:
	# Category rounds always allow both hint buttons; custom rounds follow their own setting.
	if theme_id >= 0:
		return true
	return int(GameState.settings[1]) == 2

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
	open_hint_used = true
	var index: int = candidates[randi() % candidates.size()]
	_reveal_letter(letters[index])
	if mode == 1:
		_add_time_attack_points(-25)
	if is_word_completed():
		is_active = false
		GameState.save_game()
		emit_signal("changed")
		emit_signal("round_won")
	else:
		GameState.save_game()
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
	remove_wrong_hint_used = true
	# The newer FLA removes three Russian or two English keyboard letters.
	# They are selected without replacement and never count as mistakes.
	var remove_count: int = 2 if Database.get_alphabet().size() == 26 else 3
	for _index in range(mini(remove_count, candidates.size())):
		var candidate_index: int = randi() % candidates.size()
		removed_wrong_letters.append(str(candidates[candidate_index]))
		candidates.remove_at(candidate_index)
	if mode == 1:
		_add_time_attack_points(-20)
	GameState.save_game()
	emit_signal("changed")
	return true

func get_masked_word() -> String:
	if letters.is_empty():
		return ""
	var output := PackedStringArray()
	for i in range(letters.size()):
		output.append(letters[i] if bool(revealed[i]) else "_")
	return " ".join(output)

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
	is_active = false
	mode = 0
	open_hint_used = false
	remove_wrong_hint_used = false
	word_hint_text = ""
	GameState.reset_current_game()

func finish_result(is_win: bool) -> Dictionary:
	var result := {
		"title": Database.tr_text(37 if is_win else 38, "VICTORY" if is_win else "DEFEAT"),
		"lines": []
	}
	if word_data == null:
		return result

	var diff := clampi(int(word_data.difficulty), 0, 1)

	# ReztMovBlock.as updates the classic difficulty streak for every category
	# word, including words played during Time Attack. Only two-player words have
	# no category and therefore use their own win/loss counters.
	if theme_id >= 0:
		if is_win:
			GameState.records[0][diff] = int(GameState.records[0][diff]) + 1
			if int(GameState.records[0][diff]) > int(GameState.records[0][2 + diff]):
				GameState.records[0][2 + diff] = int(GameState.records[0][diff])
		else:
			GameState.records[0][diff] = 0

	if mode == 0:
		if is_win and theme_id >= 0:
			GameState.mark_guessed(Database.current_language, theme_id, word_index, Database.get_words_by_index(theme_id, 0).size())
			if _is_theme_completed(theme_id):
				result["lines"].append(Database.tr_text(65, "Category is completed!"))
	elif mode == 1:
		if is_win:
			# New FLA formula:
			# round * 3 * difficulty_factor + 105 - 15 * HeroMov.currentFrame.
			# HeroMov starts on frame 1, so currentFrame == mistakes + 1.
			var bonus: int = (
				GameState.time_attack_round * 3 * _time_attack_difficulty_factor()
				+ 105
				- 15 * (mistakes + 1)
			)
			_add_time_attack_points(bonus)
			result["lines"].append(Database.tr_key(&"POINTS_GAINED", "Points:") + " " + str(bonus))
			GameState.time_attack_round += 1
			GameState.records[2][0] = int(GameState.records[2][0]) + 1
			if int(GameState.records[2][0]) > int(GameState.records[2][1]):
				GameState.records[2][1] = int(GameState.records[2][0])
				result["lines"].append(Database.tr_text(45, "Victories per game") + ": " + str(GameState.records[2][0]))
		else:
			GameState.time_attack_round = 1
			_add_time_attack_points(-20)
			result["lines"].append(Database.tr_key(&"PENALTY", "Penalty:") + " 20")
	elif mode == 2:
		if is_win:
			GameState.records[1][0] = int(GameState.records[1][0]) + 1
		else:
			GameState.records[1][1] = int(GameState.records[1][1]) + 1

	GameState.save_game()
	return result

func finish_time_attack_timeout(timed_out: bool = true) -> Dictionary:
	var final_score: int = int(GameState.current_score)
	var result := {
		"title": Database.tr_text(39, "GAME OVER"),
		"lines": [],
		"time_attack_finished": true,
		"final_score": final_score
	}
	if timed_out:
		result["lines"].append(Database.tr_text(51, "Time's up!"))
	if final_score > int(GameState.records[2][2]):
		GameState.records[2][2] = final_score
		result["lines"].append(Database.tr_text(64, "New record!"))
	GameState.records[2][0] = 0
	GameState.time_attack_round = 1
	GameState.correct_guess_streak = 0
	is_active = false
	GameState.save_game()
	return result

func _time_attack_difficulty_factor() -> int:
	# Difficulty affects only the selected word pool and the Time Attack reward.
	# Original AS3 factors: hard x4, general x2, easy x1.
	match int(GameState.settings[2]):
		1:
			return 4 # hard
		2:
			return 1 # easy
		_:
			return 2 # general

func _add_time_attack_points(delta: int) -> void:
	if mode != 1:
		return
	const AS3_INT_MAX: int = 2147483647
	GameState.current_score = clampi(GameState.current_score + delta, 0, AS3_INT_MAX)

func _is_theme_completed(theme_index: int) -> bool:
	return Database.get_number_of_all_words(theme_index, true) - Database.get_number_of_guessed_words(theme_index, true) == 0
