class_name FlashBackdrop
extends Node2D

const FLASH_TO_GODOT_SCALE: float = 0.24
const STAGE_SIZE: Vector2 = Vector2(480.0, 800.0)
const PORTRAIT_LAYOUT: GDScript = preload("res://scripts/ui/portrait_stage_layout.gd")
const MAIN_BACKGROUND: String = "res://symbols/MainFon.tscn"

var _holder: Node2D
var _instances: Array[Node] = []

func _ready() -> void:
	_holder = Node2D.new()
	_holder.name = "Stage"
	add_child(_holder)
	_fit_to_viewport()
	get_viewport().size_changed.connect(_fit_to_viewport)

func show_screen(symbol_path: String = "") -> void:
	if _holder == null:
		_holder = Node2D.new()
		_holder.name = "Stage"
		add_child(_holder)
	clear_screen()
	_add_symbol(MAIN_BACKGROUND)
	if symbol_path.strip_edges() != "":
		_add_symbol(symbol_path)
	_fit_to_viewport()

func clear_screen() -> void:
	for node: Node in _instances:
		if is_instance_valid(node):
			node.queue_free()
	_instances.clear()

func _fit_to_viewport() -> void:
	if _holder == null:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var fit_scale: float = PORTRAIT_LAYOUT.fit_scale(viewport_size)
	_holder.scale = Vector2.ONE * FLASH_TO_GODOT_SCALE * fit_scale
	_holder.position = Vector2(PORTRAIT_LAYOUT.horizontal_offset(viewport_size), 0.0)

func _add_symbol(path: String) -> void:
	if !ResourceLoader.exists(path):
		push_warning("Flash symbol is missing: " + path)
		return
	var resource: Resource = load(path)
	if !(resource is PackedScene):
		push_warning("Flash symbol is not a PackedScene: " + path)
		return
	var scene: PackedScene = resource as PackedScene
	var node: Node = scene.instantiate()
	_holder.add_child(node)
	_instances.append(node)
