extends RefCounted

const MAX_WORDS: int = 12
const PREFERRED_CANDIDATES: int = 32

var entries: Array[Dictionary] = []
var cells: Dictionary = {}
var letters := PackedStringArray()
var bounds := Rect2i()
var _directions: Dictionary = {}

static func is_separator(letter: String) -> bool:
	return letter in [" ", "-", "—", "'"]

static func build(primary: String, target: float, candidates: Array, count: int) -> RefCounted:
	var board := new()
	board._place(primary, Vector2i.ZERO, Vector2i.RIGHT)
	if count <= 1:
		return board

	var pool: Array[Dictionary] = []
	var used: Dictionary = {primary: true}
	for candidate: Dictionary in candidates:
		var word: String = candidate["text"]
		if word.length() < 2 or word.contains(" ") or used.has(word):
			continue
		used[word] = true
		pool.append({"text": word, "distance": absf(float(candidate["difficulty"]) - target)})
	pool.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["distance"] == b["distance"]:
			return a["text"] < b["text"]
		return a["distance"] < b["distance"]
	)
	while board.entries.size() < count and !pool.is_empty():
		var placement: Dictionary = board._find_placement(pool)
		var index: int = placement.get("index", 0)
		board._place(
			pool[index]["text"],
			placement.get("start", Vector2i(board.bounds.position.x, board.bounds.end.y + 1)),
			placement.get("direction", Vector2i.RIGHT)
		)
		pool.remove_at(index)
	return board

static func restore(primary: String, entries_from_save: Variant) -> RefCounted:
	if !(entries_from_save is Array) or entries_from_save.is_empty() or entries_from_save.size() > MAX_WORDS:
		return null
	var board := new()
	var used: Dictionary = {}
	for entry: Variant in entries_from_save:
		if !(entry is Dictionary) or !(entry.get("text") is String) or !(entry.get("vertical") is bool):
			return null
		var word: String = entry["text"]
		if word.is_empty() or word.length() > 64 or used.has(word):
			return null
		if board.entries.is_empty() and word != primary:
			return null
		var x: Variant = entry.get("x")
		var y: Variant = entry.get("y")
		if !(x is int or x is float) or !(y is int or y is float):
			return null
		if absf(float(x)) > 128.0 or absf(float(y)) > 128.0 or x != int(x) or y != int(y):
			return null
		var start := Vector2i(int(x), int(y))
		var direction: Vector2i = Vector2i.DOWN if entry["vertical"] else Vector2i.RIGHT
		if board._crossings(word, start, direction) < 0:
			return null
		board._place(word, start, direction)
		used[word] = true
	return board

func _find_placement(pool: Array[Dictionary]) -> Dictionary:
	var best: Dictionary = {}
	var best_score: float = INF
	for index: int in range(pool.size()):
		if index >= PREFERRED_CANDIDATES and !best.is_empty():
			break
		var word: String = pool[index]["text"]
		for point: Vector2i in cells:
			var letter: String = letters[cells[point]]
			if is_separator(letter) or _directions[point] == 3:
				continue
			var direction: Vector2i = Vector2i.DOWN if _directions[point] == 1 else Vector2i.RIGHT
			for offset: int in range(word.length()):
				if word[offset] != letter:
					continue
				var start: Vector2i = point - direction * offset
				var crossings: int = _crossings(word, start, direction)
				if crossings <= 0:
					continue
				var size: Vector2i = bounds.merge(_word_rect(word, start, direction)).size
				var score: float = maxi(size.x, size.y) * 5 + size.x * size.y * 0.1 - crossings * 3 + index * 0.12
				if score < best_score:
					best_score = score
					best = {"index": index, "start": start, "direction": direction}
	return best

func _crossings(word: String, start: Vector2i, direction: Vector2i) -> int:
	if cells.has(start - direction) or cells.has(start + direction * word.length()):
		return -1
	var side := Vector2i(direction.y, direction.x)
	var direction_mask: int = 1 if direction == Vector2i.RIGHT else 2
	var count: int = 0
	for offset: int in range(word.length()):
		var point: Vector2i = start + direction * offset
		if cells.has(point):
			if letters[cells[point]] != word[offset] or is_separator(word[offset]) or (_directions[point] & direction_mask) != 0:
				return -1
			count += 1
		elif cells.has(point + side) or cells.has(point - side):
			return -1
	return count

func _place(word: String, start: Vector2i, direction: Vector2i) -> void:
	if word.is_empty():
		return
	var mask: int = 1 if direction == Vector2i.RIGHT else 2
	for offset: int in range(word.length()):
		var point: Vector2i = start + direction * offset
		if !cells.has(point):
			cells[point] = letters.size()
			letters.append(word[offset])
		_directions[point] = int(_directions.get(point, 0)) | mask
	var word_rect: Rect2i = _word_rect(word, start, direction)
	bounds = word_rect if entries.is_empty() else bounds.merge(word_rect)
	entries.append({"text": word, "x": start.x, "y": start.y, "vertical": direction == Vector2i.DOWN})

func _word_rect(word: String, start: Vector2i, direction: Vector2i) -> Rect2i:
	return Rect2i(start, Vector2i.ONE + direction * (word.length() - 1))
