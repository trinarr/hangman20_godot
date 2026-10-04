extends Node

func set_custom_word(text: String) -> WordData:
	var normalized := normalize_word(text)
	var custom_word := WordData.new(normalized, 0.0, -1, -1)
	return custom_word

func normalize_word(text: String) -> String:
	var result := text.strip_edges().to_upper()
	result = result.replace("-", "—")
	result = result.replace("Ё", "Е")
	return result
