class_name FlashStageSymbol
extends Node2D

signal playback_finished

const STAGE_SIZE: Vector2 = Vector2(480.0, 800.0)
const PORTRAIT_LAYOUT: GDScript = preload("res://scripts/ui/portrait_stage_layout.gd")
const FLASH_TO_GODOT_SCALE: float = 0.24
const HERO_FRAME_RATE: float = 24.0
const HERO_TYPE_1_SYMBOL: String = "res://symbols/HeroType1.tscn"
const HERO_TYPE_2_SYMBOL: String = "res://symbols/HeroType2.tscn"
const HERO_TYPE_1_STATES: Array[String] = [
	"res://symbols/_______192.tscn",
	"res://symbols/_______193.tscn",
	"res://symbols/_______90.tscn",
	"res://symbols/_______91.tscn",
	"res://symbols/_______92.tscn",
	"res://symbols/_______93.tscn",
	"res://symbols/_______89.tscn",
]
const HERO_TYPE_2_STATES: Array[String] = [
	"res://symbols/_______94.tscn",
	"res://symbols/_______123.tscn",
	"res://symbols/_______126.tscn",
	"res://symbols/_______127.tscn",
	"res://symbols/_______128.tscn",
	"res://symbols/_______129.tscn",
	"res://symbols/_______131.tscn",
]
const HERO_TYPE_1_OFFSETS: Array[Vector2] = [
	Vector2(266.6667, -645.8334),
	Vector2(154.1667, -750.0001),
	Vector2(37.5, -829.1667),
	Vector2(37.5, -829.1667),
	Vector2(37.5, -829.1667),
	Vector2(37.5, -829.1667),
	Vector2(37.5, -829.1667),
]
const HERO_TYPE_2_OFFSETS: Array[Vector2] = [
	Vector2(100.0, -612.5),
	Vector2(100.0, -612.5),
	Vector2(100.0, -612.5),
	Vector2(100.0, -612.5),
	Vector2(75.0, -520.8334),
	Vector2(75.0, -383.3334),
	Vector2(75.0, -433.3334),
]

# ResourceLoader keeps the requested next pose in its threaded-load cache. This
# dictionary holds a strong reference only to the currently displayed pose; the
# next one is promoted here after its background request has finished.
static var _hero_pose_cache: Dictionary = {}
static var _hero_pose_requests: Dictionary = {}

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
		if _is_hero_type_symbol():
			_reload_symbol()
		else:
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
var _loaded_symbol_path: String = ""
var _pending_symbol_path: String = ""
var _pending_symbol_offset: Vector2 = Vector2.ZERO
var _pending_playback: Dictionary = {}
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
	_pending_playback.clear()
	_pending_symbol_path = ""
	_pending_symbol_offset = Vector2.ZERO
	if !is_inside_tree() or symbol_path.strip_edges() == "":
		_remove_symbol_instance()
		return
	if _is_hero_type_symbol():
		_reload_hero_symbol()
		return
	_remove_symbol_instance()
	if !ResourceLoader.exists(symbol_path):
		push_warning("Flash stage symbol is missing: " + symbol_path)
		return
	var resource: Resource = load(symbol_path)
	if !(resource is PackedScene):
		push_warning("Flash stage symbol is not a PackedScene: " + symbol_path)
		return
	var scene: PackedScene = resource as PackedScene
	_symbol_instance = scene.instantiate()
	_loaded_symbol_path = symbol_path
	add_child(_symbol_instance)
	_apply_animation_time()

func _reload_hero_symbol() -> void:
	var state_index: int = _hero_state_index()
	var target_path: String = _hero_states()[state_index]
	var target_offset: Vector2 = _hero_offsets()[state_index]
	if _symbol_instance != null and _loaded_symbol_path == target_path:
		_apply_animation_time()
		_prune_hero_pose_cache(state_index, false)
		_request_next_hero_pose(state_index)
		return

	_remove_symbol_instance()
	var target_scene: PackedScene = _get_hero_scene_if_ready(target_path)
	if target_scene == null and state_index == 0 and !_hero_pose_requests.has(target_path):
		# The first pose is needed before the player can interact. Load that one
		# synchronously, then prepare every later pose off the main thread.
		target_scene = _load_initial_hero_scene(target_path)
	if target_scene != null:
		_instantiate_hero_pose(target_scene, target_offset, target_path)
		_prune_hero_pose_cache(state_index, false)
		_request_next_hero_pose(state_index)
		return

	_request_hero_scene(target_path)
	_pending_symbol_path = target_path
	_pending_symbol_offset = target_offset
	_prune_hero_pose_cache(state_index, true)

	# A very fast tap can beat the background request. Keep the previous pose on
	# screen and defer the reaction instead of blocking the frame on texture IO.
	if state_index > 0:
		var previous_path: String = _hero_states()[state_index - 1]
		var previous_scene: PackedScene = _cached_hero_scene(previous_path)
		if previous_scene != null:
			_instantiate_hero_pose(previous_scene, _hero_offsets()[state_index - 1], previous_path)
	set_process(true)

func _remove_symbol_instance() -> void:
	if _symbol_instance == null:
		_loaded_symbol_path = ""
		return
	remove_child(_symbol_instance)
	_symbol_instance.queue_free()
	_symbol_instance = null
	_loaded_symbol_path = ""

func _instantiate_hero_pose(scene: PackedScene, pose_offset: Vector2, resource_path: String) -> void:
	var pose_holder := Node2D.new()
	pose_holder.name = "HeroPose"
	pose_holder.position = pose_offset
	pose_holder.add_child(scene.instantiate())
	_symbol_instance = pose_holder
	_loaded_symbol_path = resource_path
	add_child(_symbol_instance)
	_apply_animation_time()

func _load_initial_hero_scene(resource_path: String) -> PackedScene:
	if !ResourceLoader.exists(resource_path):
		push_warning("Hero pose is missing: " + resource_path)
		return null
	var resource: Resource = ResourceLoader.load(resource_path, "PackedScene")
	if !(resource is PackedScene):
		push_warning("Hero pose is not a PackedScene: " + resource_path)
		return null
	var scene: PackedScene = resource as PackedScene
	_hero_pose_cache[resource_path] = scene
	return scene

func _request_hero_scene(resource_path: String) -> void:
	if _hero_pose_cache.has(resource_path) or _hero_pose_requests.has(resource_path):
		return
	if !ResourceLoader.exists(resource_path):
		push_warning("Hero pose is missing: " + resource_path)
		return
	var request_error: int = ResourceLoader.load_threaded_request(resource_path, "PackedScene", false)
	if request_error == OK:
		_hero_pose_requests[resource_path] = true
	else:
		push_warning("Could not preload hero pose %s (error %d)" % [resource_path, request_error])

func _cached_hero_scene(resource_path: String) -> PackedScene:
	var cached_resource: Variant = _hero_pose_cache.get(resource_path)
	if cached_resource is PackedScene:
		return cached_resource as PackedScene
	return null

func _get_hero_scene_if_ready(resource_path: String) -> PackedScene:
	var cached_scene: PackedScene = _cached_hero_scene(resource_path)
	if cached_scene != null:
		return cached_scene
	if !_hero_pose_requests.has(resource_path):
		return null
	var status: int = ResourceLoader.load_threaded_get_status(resource_path)
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		return null
	if status != ResourceLoader.THREAD_LOAD_LOADED:
		_hero_pose_requests.erase(resource_path)
		push_warning("Background hero pose load failed: " + resource_path)
		return null

	# Calling load_threaded_get before LOADED would block the main thread. The
	# status guard above is what keeps letter feedback and animation frames smooth.
	var resource: Resource = ResourceLoader.load_threaded_get(resource_path)
	_hero_pose_requests.erase(resource_path)
	if !(resource is PackedScene):
		push_warning("Background hero pose is not a PackedScene: " + resource_path)
		return null
	var scene: PackedScene = resource as PackedScene
	_hero_pose_cache[resource_path] = scene
	return scene

func _request_next_hero_pose(state_index: int) -> void:
	var next_index: int = state_index + 1
	if next_index >= _hero_states().size():
		return
	_request_hero_scene(_hero_states()[next_index])

func _prune_hero_pose_cache(state_index: int, keep_previous: bool) -> void:
	var keep_paths: Dictionary = {}
	var states: Array[String] = _hero_states()
	keep_paths[states[state_index]] = true
	if state_index + 1 < states.size():
		keep_paths[states[state_index + 1]] = true
	if keep_previous and state_index > 0:
		keep_paths[states[state_index - 1]] = true
	for cached_path: Variant in _hero_pose_cache.keys():
		if !keep_paths.has(cached_path):
			_hero_pose_cache.erase(cached_path)

func _poll_pending_hero_pose() -> bool:
	if _pending_symbol_path == "":
		return false
	var target_scene: PackedScene = _get_hero_scene_if_ready(_pending_symbol_path)
	if target_scene == null:
		if !_hero_pose_requests.has(_pending_symbol_path):
			# A missing/corrupt pose must not leave an animation overlay waiting
			# forever. Keep the fallback pose and release non-looping callers.
			_pending_symbol_path = ""
			_pending_symbol_offset = Vector2.ZERO
			var failed_playback: Dictionary = _pending_playback.duplicate()
			_pending_playback.clear()
			if !failed_playback.is_empty() and !bool(failed_playback["should_loop"]):
				emit_signal("playback_finished")
		return false
	var target_path: String = _pending_symbol_path
	var target_offset: Vector2 = _pending_symbol_offset
	_pending_symbol_path = ""
	_pending_symbol_offset = Vector2.ZERO
	_remove_symbol_instance()
	_instantiate_hero_pose(target_scene, target_offset, target_path)
	var state_index: int = _hero_states().find(target_path)
	if state_index >= 0:
		_prune_hero_pose_cache(state_index, false)
		_request_next_hero_pose(state_index)
	_resume_pending_playback()
	return true

func _resume_pending_playback() -> void:
	if _pending_playback.is_empty():
		return
	var playback: Dictionary = _pending_playback.duplicate()
	_pending_playback.clear()
	_play_nested(
		float(playback["root_time"]),
		float(playback["start_time"]),
		float(playback["end_time"]),
		float(playback["speed_scale"]),
		bool(playback["should_loop"]),
		float(playback["initial_time"])
	)

func _is_hero_type_symbol() -> bool:
	return symbol_path == HERO_TYPE_1_SYMBOL or symbol_path == HERO_TYPE_2_SYMBOL

func _hero_states() -> Array[String]:
	return HERO_TYPE_2_STATES if symbol_path == HERO_TYPE_2_SYMBOL else HERO_TYPE_1_STATES

func _hero_offsets() -> Array[Vector2]:
	return HERO_TYPE_2_OFFSETS if symbol_path == HERO_TYPE_2_SYMBOL else HERO_TYPE_1_OFFSETS

func _hero_state_index() -> int:
	return clampi(int(floor(maxf(animation_time, 0.0) * HERO_FRAME_RATE)), 0, _hero_states().size() - 1)

func _apply_animation_time() -> void:
	if _symbol_instance == null:
		return
	if _is_hero_type_symbol():
		_apply_direct_hero_time_recursive(_symbol_instance)
		return
	_apply_animation_time_recursive(_symbol_instance, false)

func _apply_direct_hero_time_recursive(node: Node) -> void:
	if node is AnimationPlayer:
		var player: AnimationPlayer = node as AnimationPlayer
		if player.has_animation("default"):
			player.play("default")
			player.seek(maxf(nested_animation_time, 0.0), true)
			player.stop(true)
	for child: Node in node.get_children():
		_apply_direct_hero_time_recursive(child)

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
	_stop_playback_state()
	animation_time = root_time
	nested_animation_time = initial_time
	_apply_animation_time()
	if _symbol_instance == null or (_is_hero_type_symbol() and _loaded_symbol_path != _hero_states()[_hero_state_index()]):
		_pending_playback = {
			"root_time": root_time,
			"start_time": nested_start_time,
			"end_time": nested_end_time,
			"speed_scale": playback_speed_scale,
			"should_loop": should_loop,
			"initial_time": initial_time,
		}
		set_process(true)
		return

	var root_player := _find_first_animation_player(_symbol_instance)

	var nested_player: AnimationPlayer = root_player if _is_hero_type_symbol() else _find_first_visible_nested_animation_player(_symbol_instance, root_player)
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
	if _pending_symbol_path != "":
		_poll_pending_hero_pose()
		if _pending_symbol_path != "":
			return
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
	if _playback_player != null:
		_playback_player.speed_scale = 1.0
	_playback_player = null
	_playback_start_time = -1.0
	_playback_end_time = -1.0
	_playback_nested_time = -1.0
	_playback_speed_scale = 1.0
	_playback_loop = false
	_playback_loop_position = -1.0
	set_process(_pending_symbol_path != "")

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
