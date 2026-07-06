class_name WordData
extends RefCounted

var text: String = ""
var difficulty: int = 0
var theme_index: int = -1
var index: int = -1
var custom_comment: String = ""

func _init(word: String = "", diff: int = 0, p_theme_index: int = -1, p_index: int = -1, comment: String = "") -> void:
	text = word.to_upper()
	difficulty = diff
	theme_index = p_theme_index
	index = p_index
	custom_comment = comment
