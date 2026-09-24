extends CanvasLayer

const TRACE_SCRIPT: GDScript = preload("res://scripts/ui/home_transition_trace.gd")
var _trace = TRACE_SCRIPT.new()

signal finished

const LOGO_SCRIPT: GDScript = preload("res://scripts/ui/home_logo_paper_reveal.gd")
const FADE_OUT_SECONDS: float = 0.20
const BACKGROUND_BLEND_SECONDS: float = 0.34

# Shared navigation contract with HomePaperTransition: _clear() retains the
# transition while its action builds the destination, and cancels it otherwise.
var committing: bool = false
var _home: Control
var _logo: Control
var _buttons: Array[Control] = []
var _button_opacities: Array[float] = []
var _action: Callable
var _tween: Tween
var _blocker: Control
var _navigated: bool = false
var _old_pattern: Control
var _new_pattern: Control

func start(home_content: Control, logo: Control, buttons: Array[Control], action: Callable) -> void:
	_trace.begin("blue -> " + str(action.get_method()))
	layer = 1000
	_home = home_content
	_logo = logo
	_buttons = buttons
	_action = action
	for button: Control in _buttons:
		_button_opacities.append(button.modulate.a)
	var progress: float = _logo.call("prepare_reverse_departure")
	var close_seconds: float = maxf(FADE_OUT_SECONDS,
		float(_logo.get("reveal_duration")) / LOGO_SCRIPT.PEEL_SPEED_MULTIPLIER * progress)
	_blocker = Control.new()
	_blocker.name = "HomeBlueTransitionInputBlocker"
	_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	_blocker.z_index = RenderingServer.CANVAS_ITEM_Z_MAX
	add_child(_blocker)
	_sync_layout()
	get_viewport().size_changed.connect(_sync_layout)
	_trace.phase("logo closing")
	_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_method(_fade_foreground, 1.0, 0.0, FADE_OUT_SECONDS)
	# Same geometry and easing as the entrance, played in reverse.
	_tween.parallel().tween_method(Callable(_logo, "_set_reveal_progress"), progress, 0.0, close_seconds).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_tween.chain().tween_callback(_navigate)

func _process(_delta: float) -> void:
	_trace.sample_frame()
	if _navigated:
		_trace.phase("background blend")

func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion:
		get_viewport().set_input_as_handled()

func _sync_layout() -> void:
	_blocker.size = get_viewport().get_visible_rect().size

func _fade_foreground(opacity: float) -> void:
	if is_instance_valid(_logo):
		_logo.call("set_foreground_opacity", opacity)
	for index: int in range(_buttons.size()):
		if is_instance_valid(_buttons[index]):
			_buttons[index].modulate.a = _button_opacities[index] * opacity

func _navigate() -> void:
	if _navigated:
		return
	_navigated = true
	# Keep the live, now uninterrupted Home backdrop above the new page. Its
	# pattern continues moving; neither a screenshot nor another blue fill is used.
	_home.theme = _home.get_parent_control().theme
	_home.reparent(self, false)
	_trace.begin_build()
	committing = true
	if _action.is_valid():
		_action.call()
	committing = false
	_trace.end_build()
	_action = Callable()
	call_deferred("_blend_destination")

func _blend_destination() -> void:
	if is_queued_for_deletion():
		return
	# Deferred destination layout has created its pattern tween by now. Align
	# its phase so icons replace each other in place, without a pattern jump.
	var destination: Control = get_parent().get("content")
	var old_motion: Control = _home.find_child("PatternMotion", true, false) as Control
	var new_motion: Control = destination.find_child("PatternMotion", true, false) as Control
	if old_motion != null and new_motion != null:
		var signature: Vector2 = old_motion.get_meta("pattern_motion_signature", Vector2.ZERO)
		var old_tween: Tween = old_motion.get_meta("pattern_move_tween", null) as Tween
		var new_tween: Tween = new_motion.get_meta("pattern_move_tween", null) as Tween
		if signature.y > 0.0 and signature == new_motion.get_meta("pattern_motion_signature", Vector2.ZERO) and old_tween != null and new_tween != null:
			new_tween.stop()
			new_tween.play()
			new_tween.custom_step(fmod(old_tween.get_total_elapsed_time(), signature.y))
		# Reuse the live Home icons on the destination's opaque blue surface.
		# Only the two icon layers blend; the fill and gradient never lose alpha.
		_old_pattern = old_motion.get_parent() as Control
		_new_pattern = new_motion.get_parent() as Control
		var old_background := _old_pattern.get_parent() as Control
		var new_background := _new_pattern.get_parent() as Control
		_old_pattern.reparent(new_background, false)
		new_background.move_child(_old_pattern, _new_pattern.get_index())
		_new_pattern.modulate.a = 0.0
		old_background.hide()
	# The remaining Home tree is foreground only (HUD and banner preview).
	# Fading a whole page would composite its lower layers independently and
	# reveal the old grid through its own translucent blue overlay.
	var home_background := _home.get_node_or_null("HomeBackgroundOverlay") as Control
	if home_background != null:
		home_background.hide()
	var home_base := _home.get_node_or_null("PortraitBlueBackground") as Control
	if home_base != null:
		home_base.hide()
	_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_property(_home, "modulate:a", 0.0, BACKGROUND_BLEND_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if _old_pattern != null and _new_pattern != null:
		_tween.parallel().tween_property(_old_pattern, "modulate:a", 0.0, BACKGROUND_BLEND_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tween.parallel().tween_property(_new_pattern, "modulate:a", 1.0, BACKGROUND_BLEND_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_callback(_finish)

func _finish() -> void:
	finished.emit()
	queue_free()

func _exit_tree() -> void:
	_trace.finish()
	# The old pattern was temporarily adopted by the destination. Release it on
	# completion and cancellation, and leave the destination pattern fully shown.
	if is_instance_valid(_old_pattern):
		_old_pattern.queue_free()
	if is_instance_valid(_new_pattern):
		_new_pattern.modulate.a = 1.0
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if get_viewport().size_changed.is_connected(_sync_layout):
		get_viewport().size_changed.disconnect(_sync_layout)
