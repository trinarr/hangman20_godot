extends Node


const GAME_DESIGN: GDScript = preload("res://scripts/core/game_design_config.gd")
const CROSTIC_PUZZLE: GDScript = preload("res://scripts/core/crostic_puzzle.gd")

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

var round_id: String = ""
var word_index: int = -1
var theme_id: int = -1
var word_data: WordData = null
var letters: PackedStringArray = []
var revealed: Array = []
var cipher_codes := PackedInt32Array()
var cipher_letters := PackedStringArray()
var selected_position: int = -1
var _cipher_wrong_letters: Dictionary = {}
var cipher_clues: Array[Dictionary] = []
var _cipher_clue_revealed: Array = []
var cipher_quote: String = ""
var correct_letters: PackedStringArray = []
var wrong_letters: PackedStringArray = []
var removed_wrong_letters: PackedStringArray = []
var mistakes: int = 0
var is_active: bool = false
var loss_deferred: bool = false
var mode: int = GameState.GameMode.SINGLE_PLAYER
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

func start_round(
	word: WordData,
	game_mode: int = GameState.GameMode.SINGLE_PLAYER,
	use_cipher: bool = false,
	use_crostic: bool = false,
	quote: Dictionary = {}
) -> void:
	round_id = "%d:%d" % [Time.get_ticks_usec(), randi()]
	word_data = word
	if word_data.id.is_empty() and word.theme_index >= 0:
		var reference: Dictionary = Database.resolve_saved_word(Database.get_theme_id(word.theme_index), word.text)
		word_data.id = str(reference.get("id", ""))
	word_index = word.index
	theme_id = word.theme_index
	mode = game_mode
	cipher_quote = str(quote.get("text", "")) if use_cipher and use_crostic else ""
	var answer: String = get_full_word()
	letters = _split_letters(answer)
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
	word_hint_text = _resolve_word_hint() if cipher_quote.is_empty() else str(quote.get("hint", ""))
	is_active = !answer.is_empty()
	for i in range(letters.size()):
		revealed.append(_is_separator(letters[i]))
	var clues: Array[Dictionary] = []
	if use_cipher and use_crostic:
		clues = CROSTIC_PUZZLE.pick_clues(answer, word, 1 if cipher_quote.is_empty() else 2, round_id.hash())
	_setup_cipher(use_cipher, clues)
	# Leave one-letter answers available for an actual guess.
	var next_position: int = _next_hidden_position(selected_position)
	if next_position > selected_position and next_position < letters.size():
		revealed[selected_position] = true
		selected_position = _next_hidden_position(selected_position)
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

func _split_letters(text: String) -> PackedStringArray:
	var result := PackedStringArray()
	for i in range(text.length()):
		result.append(text.substr(i, 1))
	return result

func to_save_data() -> Dictionary:
	if word_data == null or mode != GameState.GameMode.SINGLE_PLAYER:
		return {}
	var data: Dictionary = {
		"round_id": round_id,
		"word": word_data.text,
		"word_id": word_data.id,
		"content_version": Database.WORD_CONTENT.CONTENT_VERSION,
		"difficulty": word_data.difficulty,
		"theme_id": Database.get_theme_id(theme_id),
		"word_index": word_index,
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
	if is_cipher_round():
		data["cipher_wrong_letters"] = _cipher_wrong_letters.duplicate(true)
		if !cipher_quote.is_empty():
			data["cipher_quote"] = cipher_quote
		if !cipher_clues.is_empty():
			var saved_clues: Array[Dictionary] = []
			for clue: Dictionary in cipher_clues:
				var saved_clue: Dictionary = clue.duplicate()
				var offset: int = int(saved_clue["start"]) - letters.size()
				saved_clue.erase("start")
				saved_clue["revealed"] = _cipher_clue_revealed.slice(offset, offset + str(clue["word"]).length())
				saved_clues.append(saved_clue)
			data["cipher_clues"] = saved_clues
	return data

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

func _home_profile_restore_from_save_data(source: Dictionary) -> bool:
	var text: String = WordManager.normalize_word(str(source.get("word", "")))
	var restored_theme_index: int = Database.get_theme_index_by_id(
		int(source.get("theme_id", -1))
	)
	var reference: Dictionary = Database.resolve_saved_word(int(source.get("theme_id", -1)), text, str(source.get("word_id", "")))
	var restored_word_index: int = int(reference.get("index", -1))
	if text.is_empty() or restored_theme_index < 0 or reference.is_empty():
		return false
	var use_cipher: bool = source.has("cipher_wrong_letters")
	var restored_quote: String = str(source.get("cipher_quote", "")) if use_cipher else ""
	var restored_letters: PackedStringArray = _split_letters(text if restored_quote.is_empty() else restored_quote)
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
	cipher_quote = restored_quote
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
	word_hint_text = str(source.get("word_hint_text", reference.get("hint", "")))
	round_id = str(source.get("round_id", "%d:%d" % [Time.get_ticks_usec(), randi()]))
	var saved_clue: Variant = source.get("cipher_clue", {})
	var saved_clues: Variant = source.get("cipher_clues", [saved_clue])
	_setup_cipher(use_cipher, saved_clues if saved_clues is Array else [])
	var saved_errors: Variant = source.get("cipher_wrong_letters")
	if saved_errors is Dictionary:
		for i: int in range(cipher_codes.size()):
			if cipher_codes[i] == 0:
				continue
			var errors: PackedStringArray = _packed_string_array_from_save(saved_errors.get(str(i)))
			# Older cipher snapshots also stored absent letters by position.
			for letter: String in errors:
				_record_wrong_guess(letter, i)
	is_active = true
	emit_signal("changed")
	return true

func _is_separator(letter: String) -> bool:
	return CROSTIC_PUZZLE.SEPARATORS.contains(letter)

func is_cipher_position_revealed(position: int) -> bool:
	return bool(revealed[position]) if position < letters.size() else bool(_cipher_clue_revealed[position - letters.size()])

func _reveal_cipher_position(position: int) -> void:
	if position < letters.size():
		revealed[position] = true
	else:
		_cipher_clue_revealed[position - letters.size()] = true

func _setup_cipher(enabled: bool, clues: Array = []) -> void:
	cipher_codes.clear()
	cipher_letters.clear()
	_cipher_wrong_letters.clear()
	cipher_clues.clear()
	_cipher_clue_revealed.clear()
	selected_position = -1
	if !enabled:
		return
	cipher_letters = letters.duplicate()
	for clue_variant: Variant in clues.slice(0, 2):
		if !(clue_variant is Dictionary):
			continue
		var clue: Dictionary = clue_variant
		var clue_text: String = str(clue.get("word", ""))
		if clue_text.length() < 3 or clue_text.length() > CROSTIC_PUZZLE.CLUE_MAX_LENGTH or str(clue.get("hint", "")).is_empty():
			continue
		var snapshot: Dictionary = clue.duplicate()
		snapshot["start"] = cipher_letters.size()
		var clue_letters: PackedStringArray = _split_letters(clue_text)
		var saved_revealed: Variant = snapshot.get("revealed")
		snapshot.erase("revealed")
		for position: int in range(clue_letters.size()):
			var was_revealed: bool = saved_revealed is Array and position < saved_revealed.size() and bool(saved_revealed[position])
			_cipher_clue_revealed.append(was_revealed or _is_separator(clue_letters[position]))
		cipher_letters.append_array(clue_letters)
		cipher_clues.append(snapshot)
	var codes_by_letter: Dictionary = {}
	var pool := PackedInt32Array()
	for letter: String in cipher_letters:
		if !_is_separator(letter) and !codes_by_letter.has(letter):
			pool.append(pool.size() + 1)
			codes_by_letter[letter] = 0
	# Use the saved round ID so reopening a round keeps the same number key.
	var random := RandomNumberGenerator.new()
	random.seed = round_id.hash()
	for letter: String in codes_by_letter:
		var index: int = random.randi_range(0, pool.size() - 1)
		codes_by_letter[letter] = pool[index]
		pool.remove_at(index)
	for letter: String in cipher_letters:
		cipher_codes.append(int(codes_by_letter.get(letter, 0)))
	selected_position = _next_hidden_position(-1)

func is_cipher_round() -> bool:
	return !cipher_codes.is_empty()

func _next_hidden_position(after: int) -> int:
	for step: int in range(1, cipher_codes.size() + 1):
		var position: int = (after + step) % cipher_codes.size()
		if cipher_codes[position] != 0 and !is_cipher_position_revealed(position):
			return position
	return -1

func can_select_cipher_position(position: int) -> bool:
	return (
		is_active and !loss_deferred and position >= 0 and position < cipher_codes.size()
		and cipher_codes[position] != 0 and !is_cipher_letter_complete(cipher_letters[position])
	)

func select_position(position: int) -> bool:
	if !can_select_cipher_position(position):
		return false
	# An already revealed occurrence can still select its unfinished code.
	if is_cipher_position_revealed(position):
		var code: int = cipher_codes[position]
		for index: int in range(cipher_codes.size()):
			if cipher_codes[index] == code and !is_cipher_position_revealed(index):
				position = index
				break
	if position == selected_position:
		return false
	selected_position = position
	return true

func was_wrong_at_selection(letter: String) -> bool:
	if wrong_letters.has(letter):
		return true
	if is_cipher_round():
		if selected_position < 0:
			return false
		var code: int = cipher_codes[selected_position]
		for position: String in _cipher_wrong_letters:
			if cipher_codes[int(position)] == code and _cipher_wrong_letters[position].has(letter):
				return true
		return false
	return removed_wrong_letters.has(letter)

func _record_wrong_guess(letter: String, position: int) -> void:
	if position >= 0 and cipher_letters.has(letter):
		var errors: Array = _cipher_wrong_letters.get_or_add(str(position), [])
		errors.append(letter)
	elif !wrong_letters.has(letter):
		wrong_letters.append(letter)

func is_cipher_letter_known(letter: String) -> bool:
	for position: int in range(cipher_letters.size()):
		if cipher_letters[position] == letter and is_cipher_position_revealed(position):
			return true
	for errors: Array in _cipher_wrong_letters.values():
		if errors.has(letter):
			return true
	return false

func is_cipher_letter_complete(letter: String) -> bool:
	var found: bool = false
	for position: int in range(cipher_letters.size()):
		if cipher_letters[position] != letter:
			continue
		if !is_cipher_position_revealed(position):
			return false
		found = true
	return found

func can_guess(letter: String) -> bool:
	if !is_active or loss_deferred or letter.length() != 1 or _is_separator(letter):
		return false
	if is_cipher_round():
		return (
			selected_position >= 0 and !was_wrong_at_selection(letter)
			and !is_cipher_letter_complete(letter)
		)
	return !correct_letters.has(letter) and !was_wrong_at_selection(letter)

func matches_guess(letter: String) -> bool:
	if is_cipher_round():
		return selected_position >= 0 and cipher_letters[selected_position] == letter
	return letters.has(letter)

func guess(letter: String, defer_loss: bool = false) -> bool:
	letter = WordManager.normalize_word(letter)
	if !can_guess(letter):
		return false
	if matches_guess(letter):
		if is_cipher_round():
			var code: int = cipher_codes[selected_position]
			for position: int in range(cipher_codes.size()):
				if cipher_codes[position] == code:
					_reveal_cipher_position(position)
			selected_position = _next_hidden_position(selected_position if selected_position < letters.size() else -1)
		else:
			_reveal_letter(letter)
		if is_word_completed():
			is_active = false
			emit_signal("changed")
			emit_signal("round_won")
		else:
			emit_signal("changed")
		return true
	_record_wrong_guess(letter, selected_position)
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
		and (mode != GameState.GameMode.SINGLE_PLAYER
			or GameState.is_single_player_hint_unlocked(Database.current_language, GameState.HINT_OPEN_LETTER))
		and !open_hint_used
		and _has_hidden_letter()
		and _letter_hints_allowed()
	)

func can_use_remove_wrong_hint() -> bool:
	return (
		is_active
		and (mode != GameState.GameMode.SINGLE_PLAYER
			or GameState.is_single_player_hint_unlocked(Database.current_language, GameState.HINT_REMOVE_WRONG))
		and !remove_wrong_hint_used
		and _has_removable_wrong_letter()
		and _letter_hints_allowed()
	)

func can_use_open_letter_hint_ad() -> bool:
	return (
		is_active
		and (mode != GameState.GameMode.SINGLE_PLAYER
			or GameState.is_single_player_hint_unlocked(Database.current_language, GameState.HINT_OPEN_LETTER))
		and open_hint_used
		and open_hint_ad_reuse_available
		and _has_hidden_letter()
		and _letter_hints_allowed()
	)

func can_use_remove_wrong_hint_ad() -> bool:
	return (
		is_active
		and (mode != GameState.GameMode.SINGLE_PLAYER
			or GameState.is_single_player_hint_unlocked(Database.current_language, GameState.HINT_REMOVE_WRONG))
		and remove_wrong_hint_used
		and remove_wrong_hint_ad_reuse_available
		and _has_removable_wrong_letter()
		and _letter_hints_allowed()
	)

func has_word_hint() -> bool:
	return word_hint_text.strip_edges() != ""

func can_unlock_comment_hint() -> bool:
	return (
		is_active
		and !comment_hint_unlocked
		and has_word_hint()
		and theme_id >= 0
	)

func can_view_comment_hint() -> bool:
	return is_active and comment_hint_unlocked and has_word_hint() and theme_id >= 0

func _letter_hints_allowed() -> bool:
	# In-progress classic rounds keep their original hint entitlements.
	return theme_id >= 0 and !is_cipher_round()

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
	if !cipher_quote.is_empty():
		return cipher_quote
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
	cipher_quote = ""
	letters.clear()
	_setup_cipher(false)
	revealed.clear()
	correct_letters.clear()
	wrong_letters.clear()
	removed_wrong_letters.clear()
	mistakes = 0
	loss_deferred = false
	is_active = false
	mode = GameState.GameMode.SINGLE_PLAYER
	open_hint_used = false
	remove_wrong_hint_used = false
	open_hint_ad_reuse_available = false
	remove_wrong_hint_ad_reuse_available = false
	comment_hint_unlocked = false
	word_hint_text = ""
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
