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

var _symbol_instance: Node = null
var _playback_player: AnimationPlayer = null
var _playback_end_time: float = -1.0
var _playback_nested_time: float = -1.0
var _playback_speed_scale: float = 1.0

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
	scale = Vector2.ONE * FLASH_TO_GODOT_SCALE * fit_scale

func play_range(start_time: float, end_time: float, nested_time: float = -1.0, playback_speed_scale: float = 1.0) -> void:
	if _symbol_instance == null:
		return
	var player := _find_first_animation_player(_symbol_instance)
	if player == null or !player.has_animation("default"):
		animation_time = end_time
		nested_animation_time = nested_time
		_apply_animation_time()
		emit_signal("playback_finished")
		return
	_stop_playback_state()
	_playback_player = player
	_playback_end_time = maxf(end_time, 0.0)
	_playback_nested_time = nested_time
	_playback_speed_scale = maxf(playback_speed_scale, 0.01)
	if nested_time >= 0.0:
		_apply_nested_animation_time(_symbol_instance, nested_time, _playback_player)
	_playback_player.speed_scale = _playback_speed_scale
	_playback_player.play("default")
	_playback_player.seek(maxf(start_time, 0.0), true)
	set_process(true)

func play_nested_range(root_time: float, nested_start_time: float, nested_end_time: float, playback_speed_scale: float = 1.0) -> void:
	if _symbol_instance == null:
		return
	var root_player := _find_first_animation_player(_symbol_instance)
	animation_time = root_time
	nested_animation_time = nested_start_time
	_apply_animation_time()

	var nested_player := _find_first_visible_nested_animation_player(_symbol_instance, root_player)
	if nested_player == null or !nested_player.has_animation("default"):
		nested_animation_time = nested_end_time
		_apply_animation_time()
		emit_signal("playback_finished")
		return

	_stop_playback_state()
	_playback_player = nested_player
	_playback_end_time = maxf(nested_end_time, 0.0)
	_playback_nested_time = maxf(nested_end_time, 0.0)
	_playback_speed_scale = maxf(playback_speed_scale, 0.01)
	_playback_player.speed_scale = _playback_speed_scale
	_playback_player.play("default")
	_playback_player.seek(maxf(nested_start_time, 0.0), true)
	set_process(true)

func _process(_delta: float) -> void:
	if _playback_player == null:
		set_process(false)
		return
	if _playback_player.current_animation != "default":
		_stop_playback_state()
		emit_signal("playback_finished")
		return
	if _playback_player.current_animation_position + 0.0005 >= _playback_end_time:
		_playback_player.seek(_playback_end_time, true)
		_playback_player.stop(true)
		if _playback_nested_time >= 0.0:
			nested_animation_time = _playback_nested_time
		else:
			animation_time = _playback_end_time
		_apply_animation_time()
		_stop_playback_state()
		emit_signal("playback_finished")

func _stop_playback_state() -> void:
	set_process(false)
	if _playback_player != null:
		_playback_player.speed_scale = 1.0
	_playback_player = null
	_playback_end_time = -1.0
	_playback_nested_time = -1.0
	_playback_speed_scale = 1.0

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

func _apply_nested_animation_time(node: Node, target_time: float, skip_player: AnimationPlayer = null) -> void:
	if node is AnimationPlayer:
		var player: AnimationPlayer = node as AnimationPlayer
		if player != skip_player and player.has_animation("default"):
			player.play("default")
			player.seek(maxf(target_time, 0.0), true)
			player.stop(true)
	for child: Node in node.get_children():
		_apply_nested_animation_time(child, target_time, skip_player)
