extends RefCounted
## Lifetime single-player totals. Never infer fresh totals from pruned history.
const KEYS := ["stars_earned", "levels_completed", "hard_levels_completed", "quizzes_solved", "words_solved"]
const LIMIT := 2147483647

static func normalize(source: Variant) -> Dictionary:
	var result := {}
	for key: String in KEYS:
		var value: Variant = source.get(key, 0) if source is Dictionary else 0
		result[key] = clampi(int(value), 0, LIMIT) if value is int or value is float else 0
	return result

static func migrate(history: Dictionary, balance: int, design: GDScript) -> Dictionary:
	var result := normalize({"stars_earned": balance})
	for source: Variant in history.values():
		if !(source is Dictionary):
			continue
		var unlocked := clampi(int(source.get("unlocked_level", 0)), 0, 100000)
		result.levels_completed += unlocked
		for number in range(1, unlocked + 1):
			if design.is_bonus_level(number):
				result.hard_levels_completed += 1
		var words := 0
		var quizzes := 0
		var slots: Dictionary = source.get("level_question_slots", {}) if source.get("level_question_slots") is Dictionary else {}
		var levels: Dictionary = source.get("levels", {}) if source.get("levels") is Dictionary else {}
		for level: Variant in levels:
			if !(levels[level] is Array):
				continue
			var question_slots: Array = slots.get(str(level), []) if slots.get(str(level)) is Array else []
			for index in range(levels[level].size()):
				if int(levels[level][index]) == 1:
					if question_slots.has(index):
						quizzes += 1
					else:
						words += 1
		var unique_words := 0
		var word_history: Dictionary = source.get("word_stats", {}) if source.get("word_stats") is Dictionary else {}
		for item: Variant in word_history.values():
			if item is Dictionary and item.get("guessed") is Dictionary:
				for guessed: Variant in item.guessed.values():
					if bool(guessed):
						unique_words += 1
		result.words_solved += maxi(words, unique_words)
		result.quizzes_solved += quizzes
	return normalize(result)

static func record(totals: Dictionary, won: bool, quiz: bool, completed: bool, hard: bool, earned_stars: int) -> void:
	if won:
		_increment(totals, "quizzes_solved" if quiz else "words_solved", 1)
	if completed:
		_increment(totals, "levels_completed", 1)
		if hard:
			_increment(totals, "hard_levels_completed", 1)
	add_earned_stars(totals, earned_stars)

static func add_earned_stars(totals: Dictionary, amount: int) -> void:
	_increment(totals, "stars_earned", maxi(0, amount))

static func _increment(totals: Dictionary, key: String, amount: int) -> void:
	totals[key] = clampi(int(totals.get(key, 0)) + amount, 0, LIMIT)
