extends RefCounted

const BOARD = preload("res://scripts/core/word_crossword.gd")
const DESIGN = preload("res://scripts/core/game_design_config.gd")
const SUFFIXES := {
	"en": ["ER", "ING", "NG", "ION", "TION"],
	"ru": ["ЕР", "ИНГ", "НГ", "НИК", "СТ"],
}
const CLUSTERS := {
	"en": ["TH", "SH", "CH"],
	"ru": ["НГ", "СТ", "СК"],
}

static func transfer_cells(board: RefCounted) -> PackedInt32Array:
	var cells := PackedInt32Array()
	var seen: Dictionary = {}
	for index: int in range(board.letters.size()):
		var letter: String = board.letters[index]
		if !BOARD.is_separator(letter) and !seen.has(letter):
			seen[letter] = true
			cells.append(index)
	return cells

static func choose(board: RefCounted, candidates: Array, language: String) -> PackedInt32Array:
	if board.entries.is_empty():
		return PackedInt32Array()
	var counts: Dictionary = {}
	for letter: String in board.letters:
		if !BOARD.is_separator(letter):
			counts[letter] = int(counts.get(letter, 0)) + 1
	var cell_count: int = 0
	for count: int in counts.values():
		cell_count += count
	var known_limit: int = floori(cell_count * DESIGN.get_float("gameplay.crossword_starters.max_known_fraction"))

	# Placing the primary word first gives it consecutive cell indices.
	var word: String = board.entries[0].text
	var anchor_length: int = 0
	var anchor_groups: Array[PackedInt32Array] = []
	var fragments: Array[PackedInt32Array] = []
	for index: int in range(word.length()):
		if BOARD.is_separator(word[index]):
			continue
		anchor_length += 1
		anchor_groups.append(PackedInt32Array([index]))
		for piece: String in SUFFIXES.get(language, []):
			var end: int = index + piece.length()
			if word.substr(index, piece.length()) == piece and (end == word.length() or BOARD.is_separator(word[end])):
				fragments.append(PackedInt32Array(range(index, end)))
		for piece: String in CLUSTERS.get(language, []):
			if word.substr(index, piece.length()) == piece:
				fragments.append(PackedInt32Array(range(index, index + piece.length())))
	if anchor_length < 2:
		return PackedInt32Array()

	var anchor_budget: int = mini(_budget(DESIGN.get_array("gameplay.crossword_starters.anchor_cells_by_length"), anchor_length), maxi(1, anchor_length - 2))
	var alternatives := PackedStringArray([word])
	var pattern: String = _pattern(word)
	for candidate: Dictionary in candidates:
		var text: String = candidate.text
		if text != word and text.length() == word.length() and _pattern(text) == pattern:
			alternatives.append(text)

	var cell_word_counts := PackedInt32Array()
	cell_word_counts.resize(board.letters.size())
	for entry: Dictionary in board.entries:
		var direction: Vector2i = Vector2i.DOWN if entry.vertical else Vector2i.RIGHT
		var start := Vector2i(entry.x, entry.y)
		for offset: int in range(String(entry.text).length()):
			var index: int = board.cells[start + direction * offset]
			cell_word_counts[index] += 1

	var fragment_budget: int = maxi(anchor_budget, mini(2, anchor_length - 2))
	var starters: PackedInt32Array = _best_group(board, fragments, "", fragment_budget, known_limit, counts, cell_word_counts, word, alternatives)
	var known: String = _group_letters(board, starters)
	while starters.size() < anchor_budget:
		var next: PackedInt32Array = _best_group(board, anchor_groups, known, 1, known_limit, counts, cell_word_counts, word, alternatives)
		if next.is_empty():
			break
		starters.append_array(next)
		known += _group_letters(board, next)

	var extra_budget: int = _budget(DESIGN.get_array("gameplay.crossword_starters.extra_cells_by_word_count"), board.entries.size())
	var extra_groups: Array[PackedInt32Array] = []
	for index: int in range(word.length(), board.letters.size()):
		if !BOARD.is_separator(board.letters[index]):
			extra_groups.append(PackedInt32Array([index]))
	for _extra: int in range(extra_budget):
		var next: PackedInt32Array = _best_group(board, extra_groups, known, 1, known_limit, counts, cell_word_counts, "", PackedStringArray())
		if next.is_empty():
			break
		starters.append_array(next)
		known += _group_letters(board, next)
	return starters

static func _budget(budgets: Array, size: int) -> int:
	return int(budgets[mini(size, budgets.size()) - 1])

static func _group_letters(board: RefCounted, group: PackedInt32Array) -> String:
	var result: String = ""
	for index: int in group:
		result += board.letters[index]
	return result

static func _best_group(
	board: RefCounted, groups: Array[PackedInt32Array], known: String, budget: int, known_limit: int,
	counts: Dictionary, cell_word_counts: PackedInt32Array, word: String, alternatives: PackedStringArray
) -> PackedInt32Array:
	var best := PackedInt32Array()
	var best_rank := Vector4i()
	for group: PackedInt32Array in groups:
		if group.size() > budget:
			continue
		var next_known: String = known
		var crossings: int = 0
		for index: int in group:
			var letter: String = board.letters[index]
			if !next_known.contains(letter):
				next_known += letter
			crossings += cell_word_counts[index] - 1
		if next_known.length() != known.length() + group.size():
			continue
		var coverage: int = 0
		for letter: String in next_known:
			coverage += int(counts[letter])
		if coverage > known_limit:
			continue
		var options: int = _matching_options(alternatives, word, next_known)
		var rank := Vector4i(-options, group.size(), crossings, coverage)
		if best.is_empty() or rank > best_rank:
			best = group
			best_rank = rank
	return best

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

static func _matching_options(alternatives: PackedStringArray, word: String, known: String) -> int:
	var options: int = 0
	for candidate: String in alternatives:
		var compatible: bool = true
		for index: int in range(word.length()):
			var expected: String = word[index]
			var actual: String = candidate[index]
			if (known.contains(expected) and actual != expected) or (!known.contains(expected) and known.contains(actual)):
				compatible = false
				break
		if compatible:
			options += 1
	return options
