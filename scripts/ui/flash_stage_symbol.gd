class_name FlashStageSymbol
extends Node2D

signal playback_finished

const STAGE_SIZE: Vector2 = Vector2(480.0, 800.0)
const PORTRAIT_LAYOUT: GDScript = preload("res://scripts/ui/portrait_stage_layout.gd")
const FLASH_TO_GODOT_SCALE: float = 0.24

var stage_position: Vector2 = Vector2.ZERO:
	set(value):
		stage_position = value
		_sync_to_stage()

var symbol_path: String = "":
	set(value):
		symbol_path = value
		_reload_symbol()

var animation_time: float = -1.0:
	set(value):
		animation_time = value
		_apply_animation_time()

var nested_animation_time: float = -1.0:
	set(value):
		nested_animation_time = value
		_apply_animation_time()

var stage_scale_multiplier: float = 1.0:
	set(value):
		stage_scale_multiplier = value
		_sync_to_stage()

var _symbol_instance: Node = null
var _playback_player: AnimationPlayer = null
var _playback_start_time: float = -1.0
var _playback_end_time: float = -1.0
var _playback_nested_time: float = -1.0
var _playback_speed_scale: float = 1.0
var _playback_loop: bool = false
var _playback_loop_position: float = -1.0

func _ready() -> void:
	if !get_viewport().size_changed.is_connected(_sync_to_stage):
		get_viewport().size_changed.connect(_sync_to_stage)
	set_process(false)
	_reload_symbol()
	_sync_to_stage()

func _exit_tree() -> void:
	if get_viewport() != null and get_viewport().size_changed.is_connected(_sync_to_stage):
		get_viewport().size_changed.disconnect(_sync_to_stage)

func _reload_symbol() -> void:
	_stop_playback_state()
	if _symbol_instance != null:
		remove_child(_symbol_instance)
		_symbol_instance.queue_free()
		_symbol_instance = null
	if !is_inside_tree() or symbol_path.strip_edges() == "":
		return
	if !ResourceLoader.exists(symbol_path):
		push_warning("Flash stage symbol is missing: " + symbol_path)
		return
	var resource: Resource = load(symbol_path)
	if !(resource is PackedScene):
		push_warning("Flash stage symbol is not a PackedScene: " + symbol_path)
		return
	var scene: PackedScene = resource as PackedScene
	_symbol_instance = scene.instantiate()
	add_child(_symbol_instance)
	_apply_animation_time()

func _apply_animation_time() -> void:
	if _symbol_instance == null:
		return
	_apply_animation_time_recursive(_symbol_instance, false)

func _apply_animation_time_recursive(node: Node, root_player_applied: bool) -> bool:
	var applied_root := root_player_applied
	if node is AnimationPlayer:
		var player: AnimationPlayer = node as AnimationPlayer
		if player.has_animation("default"):
			var target_time := animation_time
			if applied_root and nested_animation_time >= 0.0:
				target_time = nested_animation_time
			player.play("default")
			player.seek(maxf(target_time, 0.0), true)
			player.stop(true)
			applied_root = true
	for child: Node in node.get_children():
		applied_root = _apply_animation_time_recursive(child, applied_root)
	return applied_root

func _sync_to_stage() -> void:
	if !is_inside_tree():
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var fit_scale: float = PORTRAIT_LAYOUT.fit_scale(viewport_size)
	var mapped_position := Vector2(stage_position.x, PORTRAIT_LAYOUT.map_y(stage_position.y, viewport_size, self))
	position = Vector2(PORTRAIT_LAYOUT.horizontal_offset(viewport_size), 0.0) + mapped_position * fit_scale
	scale = Vector2.ONE * FLASH_TO_GODOT_SCALE * fit_scale * stage_scale_multiplier

func play_nested_range(root_time: float, nested_start_time: float, nested_end_time: float, playback_speed_scale: float = 1.0) -> void:
	_play_nested(root_time, nested_start_time, nested_end_time, playback_speed_scale, false, nested_start_time)

func play_nested_loop(root_time: float, nested_start_time: float, nested_end_time: float, playback_speed_scale: float = 1.0, initial_time: float = -1.0) -> void:
	var resolved_initial_time: float = nested_start_time if initial_time < 0.0 else initial_time
	_play_nested(root_time, nested_start_time, nested_end_time, playback_speed_scale, true, resolved_initial_time)

func get_nested_playback_position() -> float:
	if _playback_loop and _playback_loop_position >= 0.0:
		return _playback_loop_position
	if _playback_player != null and _playback_player.current_animation == "default":
		return _playback_player.current_animation_position
	return maxf(nested_animation_time, 0.0)

func _play_nested(root_time: float, nested_start_time: float, nested_end_time: float, playback_speed_scale: float, should_loop: bool, initial_time: float) -> void:
	if _symbol_instance == null:
		return
	_stop_playback_state()
	var root_player := _find_first_animation_player(_symbol_instance)
	animation_time = root_time
	nested_animation_time = initial_time
	_apply_animation_time()

	var nested_player := _find_first_visible_nested_animation_player(_symbol_instance, root_player)
	if nested_player == null or !nested_player.has_animation("default"):
		nested_animation_time = nested_end_time
		_apply_animation_time()
		if !should_loop:
			emit_signal("playback_finished")
		return

	var nested_animation: Animation = nested_player.get_animation("default")
	var animation_length: float = nested_animation.length
	var range_start: float = clampf(nested_start_time, 0.0, animation_length)
	var range_end: float = clampf(nested_end_time, range_start, animation_length)
	if range_end <= range_start + 0.0005:
		nested_animation_time = range_end
		_apply_animation_time()
		if !should_loop:
			emit_signal("playback_finished")
		return

	_playback_player = nested_player
	_playback_start_time = range_start
	_playback_end_time = range_end
	_playback_nested_time = range_end
	_playback_speed_scale = maxf(playback_speed_scale, 0.01)
	_playback_loop = should_loop
	var playback_initial_time: float = clampf(initial_time, range_start, range_end)
	if should_loop and playback_initial_time + 0.0005 >= range_end:
		playback_initial_time = range_start
	_playback_player.speed_scale = _playback_speed_scale
	_playback_player.play("default")
	_playback_player.seek(playback_initial_time, true)
	if should_loop:
		# Imported Flash clips are not marked as looping Godot animations. Drive
		# their terminal cycle explicitly so the last frame cannot stop playback
		# before the original hanging/swaying animation wraps to its first frame.
		_playback_loop_position = playback_initial_time
		_playback_player.pause()
	set_process(true)

func _process(delta: float) -> void:
	if _playback_player == null:
		set_process(false)
		return
	if _playback_loop:
		var loop_duration: float = _playback_end_time - _playback_start_time
		if loop_duration <= 0.0005:
			_stop_playback_state()
			return
		_playback_loop_position = _playback_start_time + fposmod(
			_playback_loop_position - _playback_start_time + delta * _playback_speed_scale,
			loop_duration
		)
		if _playback_player.current_animation != "default":
			_playback_player.play("default")
		_playback_player.seek(_playback_loop_position, true)
		_playback_player.pause()
		return
	if _playback_player.current_animation != "default":
		if _playback_loop:
			_restart_nested_loop()
			return
		_stop_playback_state()
		emit_signal("playback_finished")
		return
	if _playback_player.current_animation_position + 0.0005 >= _playback_end_time:
		if _playback_loop:
			_restart_nested_loop()
			return
		_playback_player.seek(_playback_end_time, true)
		_playback_player.stop(true)
		if _playback_nested_time >= 0.0:
			nested_animation_time = _playback_nested_time
		else:
			animation_time = _playback_end_time
		_apply_animation_time()
		_stop_playback_state()
		emit_signal("playback_finished")

func _restart_nested_loop() -> void:
	if _playback_player == null:
		return
	_playback_player.speed_scale = _playback_speed_scale
	_playback_player.play("default")
	_playback_player.seek(_playback_start_time, true)

func _stop_playback_state() -> void:
	set_process(false)
	if _playback_player != null:
		_playback_player.speed_scale = 1.0
	_playback_player = null
	_playback_start_time = -1.0
	_playback_end_time = -1.0
	_playback_nested_time = -1.0
	_playback_speed_scale = 1.0
	_playback_loop = false
	_playback_loop_position = -1.0

func _find_first_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child: Node in node.get_children():
		var found := _find_first_animation_player(child)
		if found != null:
			return found
	return null

func _find_first_visible_nested_animation_player(node: Node, skip_player: AnimationPlayer = null) -> AnimationPlayer:
	if node is AnimationPlayer:
		var player: AnimationPlayer = node as AnimationPlayer
		if player != skip_player and player.has_animation("default") and _is_node_visible_through_parents(player):
			return player
	for child: Node in node.get_children():
		var found := _find_first_visible_nested_animation_player(child, skip_player)
		if found != null:
			return found
	return null

func _is_node_visible_through_parents(node: Node) -> bool:
	var current: Node = node
	while current != null and current != self:
		if current is CanvasItem and !(current as CanvasItem).visible:
			return false
		current = current.get_parent()
	return true
