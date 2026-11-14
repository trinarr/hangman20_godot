extends "res://scripts/services/quiz_statistics.gd"

var replies: Array = []
var calls: Array = []
var route_replies: Dictionary = {}
var delay_frames: Dictionary = {}
var active_calls := 0
var max_active_calls := 0
var retry_clock_ms := -1
var use_real_lifecycle := false

func _collection_enabled() -> bool:
	return super._collection_enabled() if use_real_lifecycle else true

func _network_allowed() -> bool:
	# HTTP is always mocked; keep the runner's network ban on real autoloads.
	return GameState.can_use_online_services() if use_real_lifecycle else super._network_allowed()

func is_configured() -> bool:
	return super.is_configured() if use_real_lifecycle else true

func _ready() -> void:
	if use_real_lifecycle:
		super._ready()
	else:
		_state = {"pending": [], "refresh_token": ""}

func _save() -> void:
	if use_real_lifecycle:
		super._save()

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

func _retry_now_ms() -> int:
	return retry_clock_ms if retry_clock_ms >= 0 else super._retry_now_ms()

func advance_retry() -> void:
	var now := _retry_now_ms()
	var remaining := maxi(retry_delay_ms("quiz"), retry_delay_ms("leaderboard"))
	retry_clock_ms = now + remaining + 1
