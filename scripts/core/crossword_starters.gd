extends RefCounted

const BOARD = preload("res://scripts/core/word_crossword.gd")
const MAX_CODES: int = 2

static func choose(board: RefCounted, candidates: Array, max_known_fraction: float) -> PackedInt32Array:
	var first_cells: Dictionary = {}
	var counts: Dictionary = {}
	var cell_count: int = 0
	for index: int in range(board.letters.size()):
		var letter: String = board.letters[index]
		if BOARD.is_separator(letter):
			continue
		if !first_cells.has(letter):
			first_cells[letter] = index
		counts[letter] = int(counts.get(letter, 0)) + 1
		cell_count += 1
	if counts.size() < 2:
		return PackedInt32Array()

	var words: Array[Dictionary] = []
	for entry: Dictionary in board.entries:
		var word: String = entry.text
		var pattern: String = _pattern(word)
		var alternatives := PackedStringArray([word])
		for candidate: Dictionary in candidates:
			var text: String = candidate.text
			if text != word and text.length() == word.length() and _pattern(text) == pattern:
				alternatives.append(text)
		words.append({"text": word, "alternatives": alternatives})

	var first: String = ""
	var first_options: int = 0
	var best_rank: Vector3i = Vector3i(-1, 0, 0)
	for letter: String in first_cells:
		if float(counts[letter]) / cell_count > max_known_fraction:
			continue
		var options: int = _anchor_options(words, letter)
		# Minimize the candidates for a word the player can still work on, then
		# prefer useful repetition and wider coverage through the other words.
		var rank := Vector3i(-options, int(counts[letter] > 1), _word_coverage(words, letter))
		if first.is_empty() or _better_rank(rank, best_rank):
			first = letter
			first_options = options
			best_rank = rank
	if first.is_empty():
		return PackedInt32Array()

	var starters := PackedInt32Array([first_cells[first]])
	if first_options <= 1 or counts.size() < MAX_CODES + 2:
		return starters
	var second: String = ""
	var best_options: int = first_options
	for letter: String in first_cells:
		if letter == first or float(counts[first] + counts[letter]) / cell_count > max_known_fraction:
			continue
		var options: int = _anchor_options(words, first + letter)
		if options < best_options:
			second = letter
			best_options = options
	if !second.is_empty():
		starters.append(first_cells[second])
	return starters

static func _pattern(word: String) -> String:
	var codes: Dictionary = {}
	var result := PackedStringArray()
	for letter: String in word:
		if BOARD.is_separator(letter):
			result.append(letter)
		else:
			if !codes.has(letter):
				codes[letter] = str(codes.size())
			result.append(codes[letter])
	return ",".join(result)

static func _anchor_options(words: Array[Dictionary], known: String) -> int:
	var fewest: int = 2147483647
	for entry: Dictionary in words:
		var word: String = entry.text
		var known_positions := PackedInt32Array()
		var hidden: bool = false
		for index: int in range(word.length()):
			var letter: String = word[index]
			if known.contains(letter):
				known_positions.append(index)
			elif !BOARD.is_separator(letter):
				hidden = true
		if known_positions.is_empty() or !hidden:
			continue
		var options: int = 0
		for candidate: String in entry.alternatives:
			var compatible: bool = true
			for index: int in range(word.length()):
				if known_positions.has(index):
					if candidate[index] != word[index]:
						compatible = false
						break
				elif known.contains(candidate[index]):
					compatible = false
					break
			if compatible:
				options += 1
		fewest = mini(fewest, options)
	return fewest

static func _word_coverage(words: Array[Dictionary], letter: String) -> int:
	var count: int = 0
	for entry: Dictionary in words:
		if String(entry.text).contains(letter):
			count += 1
	return count

static func _better_rank(a: Vector3i, b: Vector3i) -> bool:
	return a.x > b.x or (a.x == b.x and (a.y > b.y or (a.y == b.y and a.z > b.z)))
