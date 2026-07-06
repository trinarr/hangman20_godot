extends Node

var current_theme: int = -1
var current_word: WordData = null
var last_error: String = ""

func set_theme(theme_index: int) -> void:
	current_theme = theme_index

func start_new_word(theme_id: int) -> WordData:
	# Compatibility with the previous partially converted scripts.
	return select_new_word(theme_id, "CL")

func select_new_word(theme_index: int, mode: String = "CL") -> WordData:
	last_error = ""
	if Database.get_theme_count() == 0:
		last_error = "No themes in dictionary"
		current_word = WordData.new("")
		return current_word

	var selected_theme := theme_index
	if mode == "TA" or selected_theme < 0:
		selected_theme = randi() % Database.get_theme_count()

	var words := Database.get_words_by_index(selected_theme, GameState.settings[2])
	if words.is_empty():
		# Fallback to all words if current difficulty has no words in a category.
		words = Database.get_words_by_index(selected_theme, 0)
	if words.is_empty():
		last_error = "No words in theme: " + Database.get_theme_name(selected_theme)
		current_word = WordData.new("")
		return current_word

	var progress := GameState.ensure_theme_progress(Database.current_language, selected_theme, _real_word_count(selected_theme))
	var available: Array = []
	for item in words:
		var index := int(item["index"])
		var already_guessed := bool(progress["guessed"][index]) if index < progress["guessed"].size() else false
		var already_played := bool(progress["played"][index]) if index < progress["played"].size() else false
		# Classic mode prefers not guessed and not recently played. Time attack may repeat guessed words.
		if mode == "TA" or (!already_guessed and !already_played):
			available.append(item)

	if available.is_empty():
		# AS3 resets WasCL/WasTA when all eligible words were played.
		for item in words:
			var index := int(item["index"])
			if index >= 0 and index < progress["played"].size():
				progress["played"][index] = false
			var already_guessed := bool(progress["guessed"][index]) if index < progress["guessed"].size() else false
			if mode == "TA" or !already_guessed:
				available.append(item)

	if available.is_empty():
		# All words in this difficulty are guessed. Let the player still replay the category.
		available = words

	var picked: Dictionary = available[randi() % available.size()]
	current_theme = selected_theme
	current_word = WordData.new(str(picked["text"]), int(picked["difficulty"]), selected_theme, int(picked["index"]))
	GameState.current_theme = selected_theme
	GameState.current_word_index = current_word.index
	GameState.mark_played(Database.current_language, selected_theme, current_word.index, _real_word_count(selected_theme))
	return current_word

func set_custom_word(text: String, comment: String = "") -> WordData:
	var normalized := normalize_word(text)
	current_theme = -1
	current_word = WordData.new(normalized, 0, -1, -1, comment)
	GameState.current_theme = -1
	GameState.current_word_index = -1
	GameState.save_game()
	return current_word

func normalize_word(text: String) -> String:
	var result := text.strip_edges().to_upper()
	result = result.replace("-", "—")
	result = result.replace("Ё", "Е")
	return result

func get_random_word() -> String:
	var word := select_new_word(current_theme, "CL")
	return word.text

func get_current_word() -> WordData:
	return current_word

func get_masked_word() -> String:
	if has_node("/root/GameSession"):
		return GameSession.get_masked_word()
	return ""

func has_words_left(theme_index: int = -1) -> bool:
	var index := current_theme if theme_index < 0 else theme_index
	return Database.get_words_by_index(index, GameState.settings[2]).size() > 0

func get_progress(theme_index: int = -1) -> Dictionary:
	var index := current_theme if theme_index < 0 else theme_index
	var count := _real_word_count(index)
	return {
		"played": GameState.count_played(Database.current_language, index, count),
		"guessed": GameState.count_guessed(Database.current_language, index, count),
		"total": Database.get_words_by_index(index, GameState.settings[2]).size()
	}

func clear_the_theme(theme_index: int) -> void:
	GameState.clear_theme(Database.current_language, theme_index, _real_word_count(theme_index))

func _real_word_count(theme_index: int) -> int:
	return Database.get_words_by_index(theme_index, 0).size()
