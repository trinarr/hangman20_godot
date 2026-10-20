extends "res://scripts/services/quiz_statistics.gd"

var replies: Array = []
var calls: Array = []
var route_replies: Dictionary = {}
var delay_frames: Dictionary = {}
var active_calls := 0
var max_active_calls := 0

func is_configured() -> bool:
	return true

func _ready() -> void:
	_state = {"pending": [], "refresh_token": ""}

func _save() -> void:
	pass

func _post(path: String, payload: Dictionary, authorized: bool = false) -> Dictionary:
	calls.append({"path": path, "payload": payload.duplicate(true), "authorized": authorized, "token": _access_token})
	var queue: Array = route_replies.get(path, replies)
	var response: Dictionary = queue.pop_front() if !queue.is_empty() else {}
	active_calls += 1
	max_active_calls = maxi(max_active_calls, active_calls)
	for frame: int in range(int(delay_frames.get(path, 1))):
		await get_tree().process_frame
	active_calls -= 1
	return response
