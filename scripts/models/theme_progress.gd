class_name ThemeProgress

extends RefCounted

var played_words: PackedByteArray
var guessed_words: PackedByteArray


func initialize(word_count: int):

	played_words.resize(word_count)
	guessed_words.resize(word_count)
