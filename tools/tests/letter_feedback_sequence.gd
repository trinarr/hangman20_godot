extends Node
## Tests real key feedback and the main action queue with isolated saves.

class TestUI:
	extends "res://scripts/main_portrait.gd"
	var sounds: Array[bool] = []
	func _ready() -> void:
		_build_root()
		_clear()
	func _play_letter_feedback_sound(is_correct: bool) -> void:
		sounds.append(is_correct)
	func _sync_hero_pose_state() -> void:
		pass
	func _play_hero_wrong_guess_animation(_mistakes: int) -> void:
		pass
	func _play_hero_correct_guess_animation() -> void:
		pass
	func _portrait_ads_enabled() -> bool:
		return false

var main: TestUI
var keys: Dictionary = {}
var checks: int = 0
var failures: Array[String] = []
var reveal_scale: Vector2 = Vector2.ZERO
var reveal_bounce_running: bool = false
var reveal_sound_count: int = 0

func _ready() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1
	if !value:
		failures.append(label)

func add_key(letter: String, state: int = 0, animated: bool = false) -> StageLetterButton:
	var button := main._stage_letter_button(Rect2(0, 0, 44, 44), Callable(), letter, state, state != 0, 29, Vector2(44, 44), animated) as StageLetterButton
	keys[letter] = button
	return button

func changed() -> void:
	for letter: String in keys:
		var button: StageLetterButton = keys[letter]
		if !is_instance_valid(button):
			continue
		var state: int = StageLetterButton.LetterState.NORMAL
		if GameSession.correct_letters.has(letter):
			state = StageLetterButton.LetterState.CIRCLED
		elif GameSession.wrong_letters.has(letter) or GameSession.removed_wrong_letters.has(letter):
			state = StageLetterButton.LetterState.CROSSED
		if button.letter_state != state:
			button.configure(letter, state, 29, Vector2(44, 44), state != 0, main.pending_letter_markers.has(letter))

func observe_wrong_reveal(_is_correct: bool, button: StageLetterButton) -> void:
	reveal_scale = button.get_node("Text").scale
	reveal_bounce_running = button._letter_bounce_tween.is_running()
	reveal_sound_count = main.sounds.size()

func start_feedback_paused(button: StageLetterButton) -> void:
	# Isolate the phase assertions from long asset-loading frames.
	button._start_marker_reveal()
	button._letter_bounce_tween.pause()
	if button._marker_tween != null and button._marker_tween.is_valid():
		button._marker_tween.pause()

func resume_feedback(button: StageLetterButton) -> void:
	button._letter_bounce_tween.play()
	if button._marker_tween != null and button._marker_tween.is_valid():
		button._marker_tween.play()

func finish_bounce(button: StageLetterButton) -> void:
	button._letter_bounce_tween.custom_step(1.0)

func run() -> void:
	GameState.current_mode = GameState.GameMode.TWO_PLAYER
	GameSession.start_custom_round("АБВА")
	main = TestUI.new()
	add_child(main)
	GameSession.changed.connect(changed)
	GameSession.hint_letters_selected.connect(main._on_hint_letters_selected)
	var wrong: StageLetterButton = add_key("Г")
	wrong.marker_reveal_started.connect(observe_wrong_reveal.bind(wrong))
	main._press_letter("Г")
	check(GameSession.wrong_letters.has("Г"), "wrong guess recorded immediately")
	check(main.sounds.is_empty(), "wrong guess has no immediate sound")
	check(!wrong.get_node("Marker").visible, "cross hidden before deferred bounce")
	start_feedback_paused(wrong)
	await get_tree().process_frame
	resume_feedback(wrong)
	var bounce: Tween = wrong._letter_bounce_tween
	check(bounce != null and bounce.is_running(), "wrong letter starts bounce")
	check(wrong._marker_tween == null and !wrong.get_node("Marker").visible, "cross waits for growth")
	var growth_duration: float = StageLetterButton.LETTER_MARK_BOUNCE_GROW_DURATION / StageLetterButton.WRONG_LETTER_FEEDBACK_SPEED
	bounce.custom_step(growth_duration * 0.4)
	check(wrong.get_node("Text").scale.x > 1.0, "letter grows before stroke")
	check(main.sounds.is_empty(), "sound waits during growth")
	var mid_bounce_scale: Vector2 = wrong.get_node("Text").scale
	wrong.configure("Г", 1, 29, Vector2(44, 44), true, false)
	check(wrong._letter_bounce_tween == bounce and bounce.is_running(), "same-state refresh preserves feedback")
	check(wrong.get_node("Text").scale == mid_bounce_scale, "refresh preserves bounce scale")
	check(!wrong.get_node("Marker").visible, "refresh does not flash a full cross")
	bounce.custom_step(growth_duration * 0.8)
	check(reveal_scale.is_equal_approx(StageLetterButton.LETTER_MARK_BOUNCE_SCALE), "stroke starts at peak scale")
	check(reveal_bounce_running and reveal_sound_count == 1, "sound starts during the bounce")
	check(wrong.get_node("Text").scale.x < reveal_scale.x and bounce.is_running(), "letter is shrinking while stroke starts")
	check(wrong.get_node("Marker").visible and wrong._marker_tween.is_running(), "stroke runs during settling")
	check(main.sounds == [false], "sound starts with stroke exactly once")
	check(is_zero_approx(float(wrong.get_node("Marker").material.get_shader_parameter("progress"))), "stroke starts at zero")
	check(wrong.get_node("Marker").z_index > wrong.get_node("Text").z_index, "cross remains above letter")
	wrong.configure("Г", 1, 29, Vector2(44, 44), true, false)
	check(wrong.get_node("Marker").visible and wrong._marker_tween.is_running(), "settling refresh preserves revealed stroke")
	finish_bounce(wrong)
	check(wrong.get_node("Text").scale.is_equal_approx(Vector2.ONE), "letter still settles normally")
	check(main.sounds.size() == 1, "settling does not repeat sound")
	wrong._marker_tween.custom_step(1.0)
	check(is_equal_approx(float(wrong.get_node("Marker").material.get_shader_parameter("progress")), 1.0), "stroke completes")
	check(main.sounds.size() == 1, "completion does not repeat sound")
	main._press_letter("Г")
	check(main.sounds.size() == 1 and main._pending_wrong_letter_feedback.is_empty(), "duplicate guess has no sound")
	# Different quick guesses keep independent feedback actions.
	var first: StageLetterButton = add_key("Д")
	var second: StageLetterButton = add_key("Ж")
	main._press_letter("Д")
	main._press_letter("Ж")
	start_feedback_paused(first)
	start_feedback_paused(second)
	await get_tree().process_frame
	resume_feedback(first)
	resume_feedback(second)
	check(main.sounds.size() == 1, "quick guesses wait for their bounces")
	finish_bounce(first)
	check(main.sounds.size() == 2, "first quick guess gets a sound")
	finish_bounce(second)
	check(main.sounds.size() == 3, "second quick guess gets its own sound")
	# Several removed letters share one action and one sound.
	var removed_a: StageLetterButton = add_key("К")
	var removed_b: StageLetterButton = add_key("Л")
	GameSession.removed_wrong_letters.append_array(PackedStringArray(["К", "Л"]))
	GameSession.hint_letters_selected.emit(PackedStringArray(["К", "Л"]), false)
	GameSession.changed.emit()
	check(main.sounds.size() == 3, "remove hint has no immediate sound")
	start_feedback_paused(removed_a)
	start_feedback_paused(removed_b)
	await get_tree().process_frame
	resume_feedback(removed_a)
	resume_feedback(removed_b)
	finish_bounce(removed_b)
	check(main.sounds.size() == 4, "first removed-letter stroke produces sound")
	finish_bounce(removed_a)
	check(main.sounds.size() == 4 and main._pending_wrong_letter_feedback.is_empty(), "multi-letter hint produces one sound")
	# Correct letters retain concurrent circle/bounce and immediate feedback.
	var correct: StageLetterButton = add_key("А")
	main._press_letter("А")
	check(main.sounds == [false, false, false, false, true], "correct sound unchanged")
	start_feedback_paused(correct)
	await get_tree().process_frame
	resume_feedback(correct)
	check(correct._letter_bounce_tween.is_running() and correct._marker_tween.is_running(), "correct circle and bounce stay concurrent")
	check(correct.get_node("Marker").z_index == correct.get_node("Text").z_index, "correct circle retains original stacking")
	# Restored/static crosses do not replay feedback.
	var restored: StageLetterButton = add_key("М", 1, false)
	await get_tree().process_frame
	check(restored.get_node("Marker").visible and restored._letter_bounce_tween == null, "restored cross is immediate and static")
	check(main.sounds.size() == 5, "restore produces no sound")
	# Reconfiguration cancels an old delayed reveal.
	main._queue_wrong_letter_feedback(PackedStringArray(["Н"]))
	var canceled: StageLetterButton = add_key("Н", 1, true)
	start_feedback_paused(canceled)
	await get_tree().process_frame
	var canceled_bounce: Tween = canceled._letter_bounce_tween
	canceled.configure("Н", 0)
	check(!canceled_bounce.is_valid(), "state change cancels old bounce")
	await get_tree().process_frame
	check(!canceled.get_node("Marker").visible and main.sounds.size() == 5, "canceled stroke remains silent")
	main._pending_wrong_letter_feedback.clear()
	# Closing a screen clears queues and kills delayed callbacks.
	main._queue_wrong_letter_feedback(PackedStringArray(["О"]))
	var closing: StageLetterButton = add_key("О", 1, true)
	start_feedback_paused(closing)
	await get_tree().process_frame
	var closing_bounce: Tween = closing._letter_bounce_tween
	var old_generation: int = main.result_transition_generation
	keys.clear()
	main._clear()
	check(main._pending_wrong_letter_feedback.is_empty(), "screen clear discards pending sound")
	await get_tree().process_frame
	check(!is_instance_valid(closing) and !closing_bounce.is_valid(), "screen clear destroys key and bounce")
	main._queue_wrong_letter_feedback(PackedStringArray(["О"]))
	main._on_letter_marker_reveal_started(false, "О", old_generation)
	check(main.sounds.size() == 5 and main._pending_wrong_letter_feedback.has("О"), "old screen callback cannot consume new action")
	main._on_letter_marker_reveal_started(false, "О", main.result_transition_generation)
	check(main.sounds.size() == 6 and main._pending_wrong_letter_feedback.is_empty(), "current screen callback consumes action")
	GameSession.changed.disconnect(changed)
	GameSession.hint_letters_selected.disconnect(main._on_hint_letters_selected)
	main.queue_free()
	await get_tree().process_frame
	print("LETTER_FEEDBACK_SEQUENCE " + JSON.stringify({"checks": checks, "failures": failures}))
	get_tree().quit(0 if failures.is_empty() else 1)
