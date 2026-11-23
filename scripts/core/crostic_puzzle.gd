extends RefCounted

const CLUE_MAX_LENGTH: int = 12
const SEPARATORS: String = " -—'’.,!?;:…"
const QUOTES := {
	"ru": [
		{"text": "ДЕЛУ ВРЕМЯ, ПОТЕХЕ ЧАС", "hint": "Пословица о том, когда стоит работать, а когда отдыхать."},
		{"text": "ВЕК ЖИВИ, ВЕК УЧИСЬ", "hint": "Пословица о том, что образование продолжается всю жизнь."},
		{"text": "УТРО ВЕЧЕРА МУДРЕНЕЕ", "hint": "Пословица советует отложить трудное решение до следующего дня."},
		{"text": "СЛОВО НЕ ВОРОБЕЙ", "hint": "Так напоминают, что сказанного уже не вернуть."},
		{"text": "НЕТ ХУДА БЕЗ ДОБРА", "hint": "Так говорят, когда у неприятности находятся хорошие последствия."},
		{"text": "ВСЕ ХОРОШО В МЕРУ", "hint": "Пословица предостерегает от излишеств даже в приятных делах."},
		{"text": "СМЕЛОСТЬ ГОРОДА БЕРЕТ", "hint": "Пословица о том, чего помогает добиться решительность."},
	],
	"en": [
		{"text": "EASY COME, EASY GO", "hint": "A saying about losing something as readily as you gained it."},
		{"text": "LOOK BEFORE YOU LEAP", "hint": "A saying about thinking through the consequences before acting."},
		{"text": "LESS IS MORE", "hint": "A saying about the value of simplicity."},
		{"text": "TIME IS MONEY", "hint": "A saying that treats each passing minute as something valuable."},
		{"text": "NO NEWS IS GOOD NEWS", "hint": "Silence can be reassuring when a problem would have been reported."},
		{"text": "KNOWLEDGE IS POWER", "hint": "A saying about the advantage that comes from understanding things."},
		{"text": "BETTER LATE THAN NEVER", "hint": "A saying about the value of getting something done even after a delay."},
	],
}

static func quote_for_stage(language: String, level_index: int, word_slot: int) -> Dictionary:
	var quotes: Array = QUOTES.get(language, [])
	if quotes.is_empty():
		return {}
	return quotes[posmod(level_index * 3 + word_slot, quotes.size())]

static func pick_clues(answer: String, anchor: WordData, amount: int, seed_value: int) -> Array[Dictionary]:
	var selected: Array[Dictionary] = []
	if anchor.theme_index < 0:
		return selected
	var remaining: Dictionary = {}
	for letter: String in answer:
		if !SEPARATORS.contains(letter):
			remaining[letter] = int(remaining.get(letter, 0)) + 1
	if remaining.size() < 2:
		return selected
	if int(remaining.get(answer[0], 0)) == 1:
		remaining.erase(answer[0])
	var shared_letters: Dictionary = remaining.duplicate()
	var candidates: Array[Dictionary] = []
	for word: Dictionary in Database.get_words_by_index(anchor.theme_index):
		var text: String = word["text"]
		if text.length() < 3 or text.length() > CLUE_MAX_LENGTH or text == answer:
			continue
		var hint: String = Database.get_hint(anchor.theme_index, int(word["index"]))
		if hint.is_empty():
			continue
		candidates.append({"word": text, "word_id": word["id"], "hint": hint})

	for slot: int in range(amount):
		var best_score: int = 0
		var choices: Array[Dictionary] = []
		for candidate: Dictionary in candidates:
			var overlap: Dictionary = {}
			for letter: String in str(candidate["word"]):
				if shared_letters.has(letter):
					overlap[letter] = int(remaining.get(letter, 0))
			if overlap.is_empty():
				continue
			var score: int = overlap.size()
			for occurrences: int in overlap.values():
				if occurrences > 0:
					score += answer.length() + occurrences
			if slot == 0 and amount > 1 and candidate["word"] == anchor.text and overlap.size() >= 2:
				score += answer.length() * 2
			if score > best_score:
				best_score = score
				choices.clear()
			if score == best_score:
				choices.append(candidate)
		if choices.is_empty():
			break
		var choice: Dictionary = choices[posmod(seed_value + slot, choices.size())]
		selected.append(choice)
		candidates.erase(choice)
		for letter: String in str(choice["word"]):
			remaining.erase(letter)
	return selected
