extends Node

func select_new_word(theme_index: int, mode: String = "CL") -> WordData:
	if Database.get_theme_count() == 0:
		return WordData.new("")

	var selected_theme := theme_index
	if mode == "TA" or selected_theme < 0:
		selected_theme = randi() % Database.get_theme_count()

	var words := Database.get_words_by_index(selected_theme, GameState.settings[2])
	if words.is_empty():
		# Fallback to all words if current difficulty has no words in a category.
		words = Database.get_words_by_index(selected_theme, 0)
	if words.is_empty():
		return WordData.new("")

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
	var selected_word := WordData.new(str(picked["text"]), int(picked["difficulty"]), selected_theme, int(picked["index"]))
	GameState.mark_played(Database.current_language, selected_theme, selected_word.index, _real_word_count(selected_theme))
	return selected_word

func set_custom_word(text: String, comment: String = "") -> WordData:
	var normalized := normalize_word(text)
	var custom_word := WordData.new(normalized, 0, -1, -1, comment)
	return custom_word

func normalize_word(text: String) -> String:
	var result := text.strip_edges().to_upper()
	result = result.replace("-", "—")
	result = result.replace("Ё", "Е")
	return result

func clear_the_theme(theme_index: int) -> void:
	GameState.clear_theme(Database.current_language, theme_index, _real_word_count(theme_index))

func _real_word_count(theme_index: int) -> int:
	return Database.get_words_by_index(theme_index, 0).size()
