extends Node
## Quiz-style cascade on row visuals, leaving Container layout and scroll intact.
const CONFIG = preload("res://scripts/core/game_design_config.gd")
var _tween: Tween
var _items: Array[Dictionary] = []

static func slide(tween: Tween, item: Control, rest_x: float, seconds: float, delay: float) -> void:
	tween.tween_property(item, "position:x", rest_x, seconds).set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func is_playing() -> bool:
	return _tween != null and _tween.is_running()

func play(rows: VBoxContainer, scroll: ScrollContainer) -> void:
	stop()
	var speed := CONFIG.get_float_range("timings.animations.leaderboard.entrance_speed_multiplier", 0.1, 10.0)
	var seconds := CONFIG.get_float("timings.animations.quiz.entrance_content_seconds") / speed
	var stagger := CONFIG.get_float("timings.animations.quiz.entrance_answer_stagger_seconds") / speed
	var distance := maxf(480.0, scroll.size.x)
	var row_y := 0.0
	var order := 0
	_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	for row: Control in rows.get_children():
		var height := row.custom_minimum_size.y
		var on_screen := row_y + height > scroll.scroll_vertical and row_y < scroll.scroll_vertical + scroll.size.y
		row_y += height
		if !on_screen or !row.has_node("CardFace"):
			continue
		for visual: Control in row.get_children():
			_items.append({"control": visual, "x": visual.position.x, "size": visual.size})
			var rest_x := visual.position.x
			visual.position.x += distance
			slide(_tween, visual, rest_x, seconds, float(order) * stagger)
		order += 1
	if _items.is_empty():
		stop()
	else:
		_tween.finished.connect(stop)

func stop() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	for item: Dictionary in _items:
		if is_instance_valid(item.control):
			item.control.position.x = item.x
			# Moving Control offsets can round its size while it is far offscreen.
			item.control.size = item.size
	_items.clear()

func _exit_tree() -> void:
	stop()
