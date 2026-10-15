extends "res://scripts/services/quiz_statistics.gd"

var replies: Array = []
var calls: Array = []

func is_configured() -> bool:
	return true

func _ready() -> void:
	_state = {"pending": [], "refresh_token": ""}

func _save() -> void:
	pass

func _post(path: String, payload: Dictionary, authorized: bool = false) -> Dictionary:
	calls.append({"path": path, "payload": payload.duplicate(true), "authorized": authorized})
	await get_tree().process_frame
	return replies.pop_front() if !replies.is_empty() else {}
