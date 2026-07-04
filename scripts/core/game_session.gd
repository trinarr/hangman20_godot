extends Node

# -----------------------------
# CURRENT WORD STATE
# -----------------------------

var word_index: int = -1
var theme_id: int = -1

var letters: PackedStringArray = []   # аналог ErrArr[0]
var opened_letters: PackedStringArray = []

# -----------------------------
# GAME STATE
# -----------------------------

var mistakes: int = 0
var max_mistakes: int = 6

var is_active: bool = false


# -----------------------------
# START ROUND
# -----------------------------

func start_round(word: WordData, index: int, theme: int) -> void:
	word_index = index
	theme_id = theme

	letters = word.text.split("")
	opened_letters.clear()

	mistakes = 0
	is_active = true


# -----------------------------
# INPUT HANDLING
# -----------------------------

func guess(letter: String) -> bool:

	letter = letter.to_upper()

	if opened_letters.has(letter):
		return false

	opened_letters.append(letter)

	if letters.has(letter):

		if is_word_completed():
			is_active = false

		return true

	mistakes += 1

	if mistakes >= max_mistakes:
		is_active = false

	return false


# -----------------------------
# STATE CHECKS
# -----------------------------

func is_word_completed() -> bool:

	for c in letters:

		if c == " " or c == "-":
			continue

		if !opened_letters.has(c):
			return false

	return true


func is_lost() -> bool:
	return mistakes >= max_mistakes


func is_won() -> bool:
	return is_word_completed()
