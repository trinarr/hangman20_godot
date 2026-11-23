extends RefCounted

const GAME_DESIGN: GDScript = preload("res://scripts/core/game_design_config.gd")
const OFFSETS: Array[float] = [-5.0, 5.0, -4.0, 4.0, -2.0, 2.0, 0.0]

static func append_steps(tween: Tween, target: Object, property_path: NodePath, rest_x: float = 0.0) -> void:
	var step_seconds: float = GAME_DESIGN.get_float("timings.quiz_wrong_answer_shake_step_seconds")
	for offset_x: float in OFFSETS:
		var step := tween.tween_property(target, property_path, rest_x + offset_x, step_seconds)
		step.set_trans(Tween.TRANS_QUAD)
		step.set_ease(Tween.EASE_IN_OUT)
