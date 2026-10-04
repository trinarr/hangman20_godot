extends RefCounted
## Reward-local glints. Each tween is bound to its sparkle node; no screen reference is retained.

static func _optional_node_meta(node: Object, key: StringName) -> Variant:
	return node.get_meta(key) if node.has_meta(key) else null

static func _build_reward_coin_sparkle(base_size: float = 14.0) -> Node2D:
	var sparkle := Node2D.new()
	sparkle.name = "RewardCoinSparkle"
	sparkle.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var sparkle_size: float = base_size * 1.30

	# Keep the glint close to a compact painted diamond: slightly taller than it is
	# wide, but only by ~20%, so it does not feel stretched vertically.
	var outer_glint := Polygon2D.new()
	outer_glint.name = "OuterGlint"
	outer_glint.polygon = PackedVector2Array([
		Vector2(0.0, -sparkle_size * 0.72),
		Vector2(sparkle_size * 0.18, -sparkle_size * 0.22),
		Vector2(sparkle_size * 0.60, 0.0),
		Vector2(sparkle_size * 0.18, sparkle_size * 0.22),
		Vector2(0.0, sparkle_size * 0.72),
		Vector2(-sparkle_size * 0.18, sparkle_size * 0.22),
		Vector2(-sparkle_size * 0.60, 0.0),
		Vector2(-sparkle_size * 0.18, -sparkle_size * 0.22),
	])
	outer_glint.color = Color(1.0, 0.91, 0.44, 0.72)
	sparkle.add_child(outer_glint)

	var inner_glint := Polygon2D.new()
	inner_glint.name = "InnerGlint"
	inner_glint.polygon = PackedVector2Array([
		Vector2(0.0, -sparkle_size * 0.50),
		Vector2(sparkle_size * 0.12, -sparkle_size * 0.16),
		Vector2(sparkle_size * 0.42, 0.0),
		Vector2(sparkle_size * 0.12, sparkle_size * 0.16),
		Vector2(0.0, sparkle_size * 0.50),
		Vector2(-sparkle_size * 0.12, sparkle_size * 0.16),
		Vector2(-sparkle_size * 0.42, 0.0),
		Vector2(-sparkle_size * 0.12, -sparkle_size * 0.16),
	])
	inner_glint.color = Color(1.0, 1.0, 1.0, 0.98)
	sparkle.add_child(inner_glint)

	var core := Polygon2D.new()
	core.name = "DiamondCore"
	core.polygon = PackedVector2Array([
		Vector2(0.0, -sparkle_size * 0.24),
		Vector2(sparkle_size * 0.20, 0.0),
		Vector2(0.0, sparkle_size * 0.24),
		Vector2(-sparkle_size * 0.20, 0.0),
	])
	core.color = Color(1.0, 1.0, 1.0, 1.0)
	sparkle.add_child(core)
	return sparkle

static func _reward_coin_sparkle_specs(reward_visual: Control) -> Array:
	var is_chest: bool = reward_visual.has_meta(&"reward_chest_open_visual")
	if !is_chest and reward_visual.has_node("ChestOpenVisual"):
		is_chest = true
	if is_chest:
		return [
			{
				"pos": Vector2(0.30, 0.50),
				"size": 13.0,
				"delay": 0.00,
			},
			{
				"pos": Vector2(0.49, 0.44),
				"size": 15.0,
				"delay": 0.32,
			},
			{
				"pos": Vector2(0.66, 0.51),
				"size": 12.0,
				"delay": 0.66,
			},
		]
	return [
		{
			"pos": Vector2(0.36, 0.56),
			"size": 13.0,
			"delay": 0.00,
		},
		{
			"pos": Vector2(0.53, 0.47),
			"size": 15.0,
			"delay": 0.30,
		},
		{
			"pos": Vector2(0.67, 0.58),
			"size": 12.0,
			"delay": 0.62,
		},
	]

static func _ensure_reward_coin_sparkle_layer(reward_visual: Control) -> Control:
	if reward_visual == null or !is_instance_valid(reward_visual):
		return null
	var layer := _optional_node_meta(
		reward_visual,
		&"reward_coin_sparkle_layer"
	) as Control
	if layer == null and reward_visual.has_node("RewardCoinSparkleLayer"):
		layer = reward_visual.get_node("RewardCoinSparkleLayer") as Control
	if layer == null or !is_instance_valid(layer):
		layer = Control.new()
		layer.name = "RewardCoinSparkleLayer"
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.z_index = 4
		reward_visual.add_child(layer)
		layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		reward_visual.set_meta(&"reward_coin_sparkle_layer", layer)
	if layer.get_child_count() == 0:
		var specs: Array = _reward_coin_sparkle_specs(reward_visual)
		for index in range(specs.size()):
			var spec: Dictionary = specs[index]
			var sparkle := _build_reward_coin_sparkle(float(spec.get("size", 14.0)))
			sparkle.name = "Sparkle%d" % index
			sparkle.position = Vector2(
				reward_visual.size.x * float((spec.get("pos", Vector2(0.5, 0.5)) as Vector2).x),
				reward_visual.size.y * float((spec.get("pos", Vector2(0.5, 0.5)) as Vector2).y)
			)
			sparkle.set_meta(&"reward_sparkle_delay", float(spec.get("delay", 0.0)))
			layer.add_child(sparkle)
	return layer

static func _reset_reward_coin_sparkle(sparkle: Node2D, base_scale: float) -> void:
	if sparkle == null or !is_instance_valid(sparkle):
		return
	sparkle.modulate.a = 0.0
	sparkle.scale = Vector2.ONE * base_scale

static func _stop_reward_coin_sparkles(reward_visual: Control, base_scale: float) -> void:
	if reward_visual == null or !is_instance_valid(reward_visual):
		return
	var layer := _optional_node_meta(
		reward_visual,
		&"reward_coin_sparkle_layer"
	) as Control
	if layer == null and reward_visual.has_node("RewardCoinSparkleLayer"):
		layer = reward_visual.get_node("RewardCoinSparkleLayer") as Control
	if layer == null or !is_instance_valid(layer):
		return
	for child in layer.get_children():
		var sparkle := child as Node2D
		if sparkle == null or !is_instance_valid(sparkle):
			continue
		var sparkle_tween := _optional_node_meta(sparkle, &"reward_sparkle_tween") as Tween
		if sparkle_tween != null and sparkle_tween.is_valid():
			sparkle_tween.kill()
		sparkle.set_meta(&"reward_sparkle_tween", null)
		_reset_reward_coin_sparkle(sparkle, base_scale)

static func _play_reward_coin_sparkles(reward_visual: Control, base_scale: float, peak_scale: float, fade_in_duration: float, fade_out_duration: float, loop_delay: float) -> void:
	if (
		reward_visual == null
		or !is_instance_valid(reward_visual)
		or !reward_visual.is_inside_tree()
	):
		return
	var layer: Control = _ensure_reward_coin_sparkle_layer(reward_visual)
	if layer == null or !is_instance_valid(layer):
		return
	_stop_reward_coin_sparkles(reward_visual, base_scale)
	for child in layer.get_children():
		var sparkle := child as Node2D
		if sparkle == null or !is_instance_valid(sparkle):
			continue
		_reset_reward_coin_sparkle(sparkle, base_scale)
		var sparkle_tween := sparkle.create_tween()
		sparkle_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		sparkle_tween.bind_node(sparkle)
		sparkle_tween.set_loops()
		var initial_delay: float = float(sparkle.get_meta(&"reward_sparkle_delay", 0.0)) * 1.3
		if initial_delay > 0.0:
			sparkle_tween.tween_interval(initial_delay)
		var fade_in := sparkle_tween.tween_property(
			sparkle,
			"modulate:a",
			0.95,
			fade_in_duration
		)
		fade_in.set_trans(Tween.TRANS_SINE)
		fade_in.set_ease(Tween.EASE_OUT)
		var scale_in := sparkle_tween.parallel().tween_property(
			sparkle,
			"scale",
			Vector2.ONE * peak_scale,
			fade_in_duration
		)
		scale_in.set_trans(Tween.TRANS_SINE)
		scale_in.set_ease(Tween.EASE_OUT)
		var fade_out := sparkle_tween.tween_property(
			sparkle,
			"modulate:a",
			0.0,
			fade_out_duration
		)
		fade_out.set_trans(Tween.TRANS_SINE)
		fade_out.set_ease(Tween.EASE_IN)
		var scale_out := sparkle_tween.parallel().tween_property(
			sparkle,
			"scale",
			Vector2.ONE * (base_scale * 0.9),
			fade_out_duration
		)
		scale_out.set_trans(Tween.TRANS_SINE)
		scale_out.set_ease(Tween.EASE_IN)
		sparkle_tween.tween_callback(
			_reset_reward_coin_sparkle.bind(sparkle, base_scale)
		)
		if loop_delay > 0.0:
			sparkle_tween.tween_interval(loop_delay)
		sparkle.set_meta(&"reward_sparkle_tween", sparkle_tween)
