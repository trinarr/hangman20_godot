class_name WordData

extends RefCounted

var text: String
var difficulty: int

func _init(word: String = "", diff: int = 0):
	text = word
	difficulty = diff
