extends Node
## Owns only the wait before a rewarded ad starts; an open native ad is untouched.
signal cancelled(request_id: String, message: String, report_error: bool)
const GAME_DESIGN = preload("res://scripts/core/game_design_config.gd")

var expires_at_msec: int = 0
var _request_id: String = ""
var _ads: WeakRef
var _origin: WeakRef
var _finished: bool = false

func watch(ads: Node, request_id: String, origin: Control) -> void:
	_ads = weakref(ads)
	_origin = weakref(origin)
	_request_id = request_id
	expires_at_msec = Time.get_ticks_msec() + int(GAME_DESIGN.get_float_range(
		"advertising.rewarded_load_timeout_seconds", 0.1, 120.0) * 1000.0)
	origin.tree_exiting.connect(_on_origin_exiting, CONNECT_ONE_SHOT)

func can_show() -> bool:
	var origin: Node = _origin.get_ref()
	return !_finished and Time.get_ticks_msec() < expires_at_msec and is_instance_valid(origin) and !origin.is_queued_for_deletion() and origin.is_inside_tree()

func _process(_delta: float) -> void:
	var ads: Node = _ads.get_ref()
	if !is_instance_valid(ads):
		cancel(true)
	elif !bool(ads.call("is_rewarded_request_pending", _request_id)):
		_finish()
	elif !can_show():
		cancel(true)

func cancel(report_error: bool = false) -> void:
	if _finished:
		return
	var ads: Node = _ads.get_ref()
	var cancelled_pending: bool = !is_instance_valid(ads) or bool(ads.call("cancel_pending_rewarded_request", _request_id))
	_finish()
	if cancelled_pending:
		cancelled.emit(_request_id, "Cancelled pending rewarded load", report_error)

func _finish() -> void:
	if _finished:
		return
	_finished = true
	set_process(false)
	var origin: Node = _origin.get_ref()
	if is_instance_valid(origin) and origin.tree_exiting.is_connected(_on_origin_exiting):
		origin.tree_exiting.disconnect(_on_origin_exiting)
	queue_free()

func _on_origin_exiting() -> void:
	cancel(false)

func _exit_tree() -> void:
	cancel(false)
