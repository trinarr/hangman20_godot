class_name FlashStageSymbol
extends Node2D

const STAGE_SIZE: Vector2 = Vector2(800.0, 480.0)
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

func _ready() -> void:
	if !get_viewport().size_changed.is_connected(_sync_to_stage):
		get_viewport().size_changed.connect(_sync_to_stage)
	_reload_symbol()
	_sync_to_stage()

func _exit_tree() -> void:
	if get_viewport() != null and get_viewport().size_changed.is_connected(_sync_to_stage):
		get_viewport().size_changed.disconnect(_sync_to_stage)

func _reload_symbol() -> void:
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
	var fit_scale: float = min(viewport_size.x / STAGE_SIZE.x, viewport_size.y / STAGE_SIZE.y)
	var stage_offset: Vector2 = (viewport_size - STAGE_SIZE * fit_scale) * 0.5
	position = stage_offset + stage_position * fit_scale
	scale = Vector2.ONE * FLASH_TO_GODOT_SCALE * fit_scale
