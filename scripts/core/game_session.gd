extends Node

signal changed
signal round_won
signal round_lost

var word_index: int = -1
var theme_id: int = -1
var word_data: WordData = null
var letters: PackedStringArray = []
var revealed: Array = []
var correct_letters: PackedStringArray = []
var wrong_letters: PackedStringArray = []
var removed_wrong_letters: PackedStringArray = []
var mistakes: int = 0
var max_mistakes: int = 7
var is_active: bool = false
var mode: int = 0 # 0 classic, 1 time attack, 2 two-player
var open_hint_used: bool = false
var remove_wrong_hint_used: bool = false
var word_hint_text: String = ""

func _ready() -> void:
	_restore_session_state()

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
	_open_initial_letters()
	_save_session_state()
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

func _open_initial_letters() -> void:
	if letters.is_empty():
		return
	var should_open := false
	if theme_id < 0:
		should_open = int(GameState.settings[0]) == 2
	else:
		# In the AS3 logic category words open first/last letters only in easy mode.
		should_open = int(GameState.settings[2]) == 2
	if !should_open:
		return
	var first := ""
	var last := ""
	for letter in letters:
		if !_is_separator(letter):
			first = letter
			break
	for i in range(letters.size() - 1, -1, -1):
		if !_is_separator(letters[i]):
			last = letters[i]
			break
	if first != "":
		_reveal_letter(first)
	if last != "" and last != first:
		_reveal_letter(last)

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
			_save_session_state()
			emit_signal("changed")
			emit_signal("round_won")
		else:
			_save_session_state()
			emit_signal("changed")
		return true
	wrong_letters.append(letter)
	mistakes += 1
	if mode == 1:
		GameState.correct_guess_streak = 0
	if int(GameState.settings[4]) == 2:
		Input.vibrate_handheld(150)
	if mistakes >= max_mistakes:
		is_active = false
		_save_session_state()
		emit_signal("changed")
		emit_signal("round_lost")
	else:
		_save_session_state()
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
	if theme_id >= 0 and int(GameState.settings[2]) == 1:
		return false
	return is_active and !open_hint_used and _has_hidden_letter() and _hints_allowed()

func can_use_remove_wrong_hint() -> bool:
	return is_active and !remove_wrong_hint_used and _has_removable_wrong_letter() and _hints_allowed()

func _hints_allowed() -> bool:
	# Category words always had the hint buttons, except the open-letter hint is disabled in hard mode.
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
		_save_session_state()
		emit_signal("changed")
		emit_signal("round_won")
	else:
		_save_session_state()
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
	_save_session_state()
	emit_signal("changed")
	return true

func give_up() -> void:
	if !is_active:
		return
	is_active = false
	_save_session_state()
	emit_signal("changed")
	emit_signal("round_lost")

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

func is_lost() -> bool:
	return mistakes >= max_mistakes

func is_won() -> bool:
	return is_word_completed()

func tries_left() -> int:
	return max(0, max_mistakes - mistakes)

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
				result["lines"].append(Database.tr_text(20 + diff, "Words in a row") + ": " + str(GameState.records[0][diff]))
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

func finish_time_attack_timeout() -> Dictionary:
	var result := {
		"title": Database.tr_text(39, "THE END"),
		"lines": [Database.tr_text(51, "Time's up!")]
	}
	if int(GameState.current_score) > int(GameState.records[2][2]):
		GameState.records[2][2] = int(GameState.current_score)
		result["lines"].append(Database.tr_text(64, "New record!"))
	GameState.records[2][0] = 0
	GameState.time_attack_round = 1
	GameState.correct_guess_streak = 0
	is_active = false
	GameState.session_state.clear()
	GameState.save_game()
	return result

func _save_session_state() -> void:
	if !is_active or word_data == null:
		GameState.session_state.clear()
		GameState.save_game()
		return
	GameState.session_state = {
		"word": word_data.text,
		"difficulty": word_data.difficulty,
		"theme_index": theme_id,
		"word_index": word_index,
		"custom_comment": word_data.custom_comment,
		"revealed": revealed.duplicate(),
		"correct_letters": Array(correct_letters),
		"wrong_letters": Array(wrong_letters),
		"removed_wrong_letters": Array(removed_wrong_letters),
		"mistakes": mistakes,
		"max_mistakes": max_mistakes,
		"mode": mode,
		"open_hint_used": open_hint_used,
		"remove_wrong_hint_used": remove_wrong_hint_used,
		"word_hint_text": word_hint_text,
	}
	GameState.save_game()

func _restore_session_state() -> void:
	var saved: Dictionary = GameState.session_state
	var saved_word: String = str(saved.get("word", "")).strip_edges()
	if saved_word == "":
		return
	word_index = int(saved.get("word_index", -1))
	theme_id = int(saved.get("theme_index", -1))
	mode = int(saved.get("mode", GameState.current_mode))
	word_data = WordData.new(
		saved_word,
		int(saved.get("difficulty", 0)),
		theme_id,
		word_index,
		str(saved.get("custom_comment", ""))
	)
	letters = _split_letters(word_data.text)
	revealed = Array(saved.get("revealed", []))
	while revealed.size() < letters.size():
		revealed.append(false)
	if revealed.size() > letters.size():
		revealed.resize(letters.size())
	correct_letters = PackedStringArray(saved.get("correct_letters", []))
	wrong_letters = PackedStringArray(saved.get("wrong_letters", []))
	removed_wrong_letters = PackedStringArray(saved.get("removed_wrong_letters", []))
	mistakes = int(saved.get("mistakes", 0))
	max_mistakes = int(saved.get("max_mistakes", 7))
	open_hint_used = bool(saved.get("open_hint_used", false))
	remove_wrong_hint_used = bool(saved.get("remove_wrong_hint_used", false))
	word_hint_text = str(saved.get("word_hint_text", ""))
	is_active = true
	GameState.current_mode = mode
	GameState.current_theme = theme_id
	GameState.current_word_index = word_index

func _time_attack_difficulty_factor() -> int:
	# Exact AS3 expression:
	# floor(((Settings[2] + 1) % 3) * 1.5) + 1
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
