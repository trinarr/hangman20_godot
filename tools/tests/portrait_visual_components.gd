extends Node
## Run via run_content_tests.py --suite portrait_visual_components (isolated save directory).

class TestUI:
	extends "res://scripts/main_portrait.gd"
	func _ready() -> void:
		pass

var root: Window
var ui: Node
var checks: int = 0
var failures: Array[String] = []
var visual_signatures: Dictionary = {}

func _ready() -> void:
	root = get_tree().root
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1
	if !value:
		failures.append(label)

func texture() -> Texture2D:
	var result := GradientTexture2D.new()
	result.gradient = Gradient.new()
	result.width = 16
	result.height = 16
	return result

func control(size_value: Vector2) -> Control:
	var result := Control.new()
	root.add_child(result)
	result.size = size_value
	return result

func snapshot(node: Node) -> Dictionary:
	var result: Dictionary = {"type": node.get_class()}
	if node is CanvasItem:
		result["modulate"] = str(node.modulate)
		result["z"] = node.z_index
	if node is Control:
		result["size"] = str(node.size)
		# PatternMotion advances on wall-clock time; child geometry is deterministic.
		if node.name != &"PatternMotion":
			result["position"] = str(node.position)
		result["rotation"] = node.rotation
		result["mouse_filter"] = node.mouse_filter
		result["clip"] = node.clip_contents
	if node is TextureRect:
		result["expand"] = node.expand_mode
		result["stretch"] = node.stretch_mode
		if node.material is ShaderMaterial:
			result["shadow"] = str(node.material.get_shader_parameter("shadow_color"))
	if node is Node2D:
		result["position"] = str(node.position)
		result["scale"] = str(node.scale)
	if node is Polygon2D:
		result["polygon"] = str(node.polygon)
		result["color"] = str(node.color)
	if node is TextureRect and node.texture is GradientTexture2D:
		result["gradient"] = str(node.texture.gradient.colors)
		result["fill_from"] = str(node.texture.fill_from)
		result["fill_to"] = str(node.texture.fill_to)
	var children: Array = []
	for child: Node in node.get_children():
		children.append(snapshot(child))
	result["children"] = children
	return result

func record(label: String, node: Node) -> void:
	visual_signatures[label] = JSON.stringify(snapshot(node)).sha256_text()

func pattern(clip: Control, motion: Control, textures: Array, speed: float = 1.0, tint: Color = Color(0.2, 0.4, 0.6, 0.5)) -> void:
	ui._layout_multi_theme_pattern(clip, motion, textures, tint, 1.0, 1.0, speed, 0.05, 0.35)

func run() -> void:
	ui = TestUI.new()
	root.add_child(ui)
	var tex: Texture2D = texture()
	# Public adapters retain their contracts and null-input behavior.
	check(ui._create_portrait_icon_extrusion_layers(null, tex, "Null").is_empty(), "null icon parent")
	var empty_holder: Control = control(Vector2(80, 60))
	check(ui._create_portrait_icon_extrusion_layers(empty_holder, null, "Null").is_empty(), "null icon texture")
	empty_holder.free()
	check(ui._add_portrait_icon_with_extrusion_to_holder(null, tex, "Null") == null, "null holder")
	var empty_layers: Array[TextureRect] = []
	ui._layout_portrait_icon_holder_extrusion(null, empty_layers)
	ui._add_multi_theme_pattern(null, [], "Null", Color.WHITE, 1.0, 1.0, 1.0, -1.0, 0.0)
	ui._add_full_rect_gradient_overlay(null, Color.WHITE, Color.BLACK)
	ui._play_reward_coin_sparkles(null)
	ui._stop_reward_coin_sparkles(null)
	check(ui._ensure_reward_coin_sparkle_layer(null) == null, "null sparkle reward")
	# Deferred icon layout and resize retain shadow nodes, texture and stacking.
	var holder: Control = control(Vector2(80, 60))
	var icon: TextureRect = ui._add_portrait_icon_with_extrusion_to_holder(holder, tex, "Icon", 3, 0.7, 0.5)
	await get_tree().process_frame
	check(holder.get_child_count() == 5, "four shadows and foreground")
	check(icon.texture == tex and icon.z_index == 3, "foreground texture and stacking")
	var shadows: Array[Node] = holder.get_children().slice(0, 4)
	for shadow: TextureRect in shadows:
		check(shadow.texture == tex and shadow.z_index == 2, "shadow texture and stacking")
		check(shadow.size == holder.size and shadow.mouse_filter == Control.MOUSE_FILTER_IGNORE, "shadow initial layout")
	record("icon_initial", holder)
	holder.size = Vector2(140, 100)
	await get_tree().process_frame
	check(holder.get_children().slice(0, 4) == shadows, "resize reuses shadow nodes")
	for shadow: TextureRect in shadows:
		check(shadow.size == holder.size, "shadow follows holder resize")
	record("icon_resized", holder)
	holder.free()
	# Repeated pattern refresh does not reset scrolling; resize reuses the prefix.
	var clip: Control = control(Vector2(480, 800))
	var motion := Control.new()
	clip.add_child(motion)
	var textures: Array = [tex, texture()]
	pattern(clip, motion, textures)
	var initial: Array[Node] = motion.get_children()
	var tween: Tween = motion.get_meta("pattern_move_tween")
	record("pattern_initial", clip)
	pattern(clip, motion, textures)
	check(motion.get_children() == initial and motion.get_meta("pattern_move_tween") == tween, "pattern refresh preserves nodes and motion")
	clip.size.y = 1100
	pattern(clip, motion, textures)
	check(motion.get_child(0) == initial[0] and motion.get_child_count() > initial.size(), "larger pattern reuses prefix")
	check(motion.get_meta("pattern_move_tween") == tween, "resize preserves motion")
	clip.size.y = 400
	pattern(clip, motion, textures, 1.0, Color(0.7, 0.3, 0.1, 0.6))
	check(motion.get_child(0) == initial[0] and motion.get_child_count() < initial.size(), "smaller pattern reuses prefix")
	record("pattern_resized", clip)
	textures[0] = texture()
	pattern(clip, motion, textures)
	check(motion.get_child(0).texture == textures[0], "pattern textures refresh")
	pattern(clip, motion, textures, 2.0)
	check(!tween.is_valid() and motion.get_meta("pattern_move_tween") != tween, "speed replaces old tween")
	var replacement: Tween = motion.get_meta("pattern_move_tween")
	clip.free()
	await get_tree().process_frame
	check(!replacement.is_valid(), "pattern deletion stops tween")
	# Actual background factory handles deferred creation and resize.
	var background: Control = control(Vector2(480, 800))
	ui._add_multi_theme_pattern(background, [tex], "Pattern", Color(0.5, 0.5, 0.5, 0.3), 0.9, 0.8, 1.2, 0.02, 0.4)
	ui._add_full_rect_gradient_overlay(background, Color(0.1, 0.2, 0.3, 0.4), Color(0.5, 0.6, 0.7, 0.8), "Gradient")
	await get_tree().process_frame
	var factory_clip: Control = background.get_node("Pattern")
	var factory_motion: Control = factory_clip.get_node("PatternMotion")
	check(factory_motion.get_child_count() > 0, "pattern factory deferred layout")
	record("background", background)
	background.size.y = 1200
	await get_tree().process_frame
	check(factory_clip.size.y == 1200 and factory_motion.get_child_count() > 0, "background resize")
	background.free()
	# Reward glints preserve all shapes, placement, restart and stop behavior.
	for chest: bool in [false, true]:
		var reward: Control = control(Vector2(200, 160))
		if chest:
			reward.set_meta(&"reward_chest_open_visual", true)
		var layer: Control = ui._ensure_reward_coin_sparkle_layer(reward)
		check(layer.get_child_count() == 3 and layer.z_index == 4, "sparkle layer and count")
		check(ui._ensure_reward_coin_sparkle_layer(reward) == layer and layer.get_child_count() == 3, "sparkle layer reused")
		record("chest_glints" if chest else "coin_glints", reward)
		ui._play_reward_coin_sparkles(reward)
		var old_tweens: Array[Tween] = []
		for sparkle: Node2D in layer.get_children():
			old_tweens.append(sparkle.get_meta(&"reward_sparkle_tween"))
			check(old_tweens[-1].is_valid() and old_tweens[-1].is_running(), "sparkle started")
		old_tweens[0].custom_step(0.1)
		check(layer.get_child(0).modulate.a > 0.0, "sparkle fade advances")
		record("chest_glints_animated" if chest else "coin_glints_animated", reward)
		ui._play_reward_coin_sparkles(reward)
		for old: Tween in old_tweens:
			check(!old.is_valid(), "sparkle restart kills old tween")
		ui._stop_reward_coin_sparkles(reward)
		for sparkle: Node2D in layer.get_children():
			check(!sparkle.has_meta(&"reward_sparkle_tween"), "stopped tween cleared")
			check(is_zero_approx(sparkle.modulate.a) and sparkle.scale == Vector2.ONE * 0.82, "stopped sparkle reset")
		ui._play_reward_coin_sparkles(reward)
		var live_tween: Tween = layer.get_child(0).get_meta(&"reward_sparkle_tween")
		reward.free()
		await get_tree().process_frame
		check(!live_tween.is_valid(), "reward deletion stops sparkle tween")
	# Close during setup: weak deferred callbacks must ignore freed nodes.
	var doomed_holder: Control = control(Vector2(80, 60))
	ui._add_portrait_icon_with_extrusion_to_holder(doomed_holder, tex, "Doomed")
	doomed_holder.free()
	var doomed_background: Control = control(Vector2(480, 800))
	ui._add_multi_theme_pattern(doomed_background, [tex], "Doomed", Color.WHITE, 1.0, 1.0, 1.0, -1.0, 0.0)
	doomed_background.free()
	await get_tree().process_frame
	await get_tree().process_frame
	check(true, "deferred callbacks survive deleted parents without script errors")
	ui.free()
	print("PORTRAIT_VISUAL_SIGNATURES " + JSON.stringify(visual_signatures))
	print("PORTRAIT_VISUAL_COMPONENTS " + JSON.stringify({"checks": checks, "failures": failures}))
	get_tree().quit(0 if failures.is_empty() else 1)
