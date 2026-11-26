extends Node

func normalize_word(text: String) -> String:
	var result := text.strip_edges().to_upper()
	result = result.replace("-", "—")
	result = result.replace("Ё", "Е")
	return result
