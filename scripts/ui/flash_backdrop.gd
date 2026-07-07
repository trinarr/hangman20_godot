class_name FlashBackdrop
extends Node2D

const FLASH_TO_GODOT_SCALE: float = 0.24
const STAGE_SIZE: Vector2 = Vector2(800.0, 480.0)
const MAIN_BACKGROUND: String = "res://symbols/MainFon.tscn"
const FLASH_BLUE: Color = Color(0.2706, 0.3098, 0.6078, 1.0)
const FLASH_DARK_BLUE: Color = Color(0.2314, 0.2627, 0.5176, 1.0)
const FLASH_ORANGE: Color = Color(0.8157, 0.5647, 0.3412, 1.0)

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
	_add_runtime_backdrops(symbol_path)
	if symbol_path.strip_edges() != "":
		_add_symbol(symbol_path)
	_fit_to_viewport()

func clear_screen() -> void:
	for node: Node in _instances:
		if is_instance_valid(node):
			node.queue_free()
	_instances.clear()

func _add_runtime_backdrops(symbol_path: String) -> void:
	if symbol_path.ends_with("MainMenu.tscn"):
		# MainMenu.as: new BitmapData(900, 114, false, 0x454f9b)
		_add_stage_rect("MainMenuBlueRuntimeBackdrop", Rect2(-50.0, 0.0, 900.0, 114.0), FLASH_BLUE)
	elif symbol_path.ends_with("GameTemi.tscn"):
		# GameTemi.as: Head.Mov1 gets 900x87 0x454f9b.
		_add_stage_rect("ThemeBlueRuntimeBackdrop", Rect2(-50.0, 0.0, 900.0, 87.0), FLASH_BLUE)
	elif symbol_path.ends_with("GameMov.tscn"):
		# GameMov.as: Head gets 900x87 0x454f9b.
		_add_stage_rect("GameBlueRuntimeBackdrop", Rect2(-50.0, 0.0, 900.0, 87.0), FLASH_BLUE)
	elif symbol_path.ends_with("SlovMov.tscn"):
		# SlovMov.as creates the top Head strip and the lower comment strip dynamically.
		_add_stage_rect("WordBlueRuntimeBackdropTop", Rect2(-50.0, 0.0, 900.0, 114.0), FLASH_BLUE)
		_add_stage_rect("WordBlueRuntimeBackdropBottom", Rect2(-50.0, 300.0, 900.0, 280.0), FLASH_BLUE)
	elif symbol_path.ends_with("PoiasnOk.tscn"):
		# PoiasnOk.as: center modal blue panels plus orange separator.
		_add_stage_rect("PopupBlueHeaderRuntimeBackdrop", Rect2(70.0, 0.0, 660.0, 87.0), FLASH_BLUE)
		_add_stage_rect("PopupBlueBodyRuntimeBackdrop", Rect2(70.0, 87.0, 660.0, 253.0), FLASH_DARK_BLUE)
		_add_stage_rect("PopupOrangeSeparatorRuntimeBackdrop", Rect2(70.0, 87.0, 660.0, 2.0), FLASH_ORANGE)
	elif symbol_path.ends_with("ReztMovBlock.tscn"):
		# ReztMovBlock.as creates a large blue result backing inside Mov.
		_add_stage_rect("ResultBlueRuntimeBackdrop", Rect2(150.0, 72.0, 500.0, 380.0), FLASH_BLUE)

func _add_stage_rect(node_name: String, stage_rect: Rect2, color: Color) -> void:
	var rect: ColorRect = ColorRect.new()
	rect.name = node_name
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.position = stage_rect.position / FLASH_TO_GODOT_SCALE
	rect.size = stage_rect.size / FLASH_TO_GODOT_SCALE
	_holder.add_child(rect)
	_instances.append(rect)

func _fit_to_viewport() -> void:
	if _holder == null:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var fit_scale: float = min(viewport_size.x / STAGE_SIZE.x, viewport_size.y / STAGE_SIZE.y)
	_holder.scale = Vector2.ONE * FLASH_TO_GODOT_SCALE * fit_scale
	_holder.position = (viewport_size - STAGE_SIZE * fit_scale) * 0.5

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
