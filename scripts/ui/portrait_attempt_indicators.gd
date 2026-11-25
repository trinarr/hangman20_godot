extends Control

const MATERIALS = preload("res://scripts/ui/ui_materials.gd")
const ICON_EXTRUSION = preload("res://scripts/ui/portrait_icon_extrusion.gd")
const COUNTER_STYLE = preload("res://scripts/ui/resource_counter_style.gd")
const HEART_TEXTURE: Texture2D = preload("res://flash_assets/life_heart_icon.png")

const ROW_HEIGHT: float = 25.0

var total: int = 0
var remaining: int = 0
var _row := HBoxContainer.new()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", 3)
	add_child(_row)
	_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_refresh_icons()

func set_attempts(new_total: int, new_remaining: int) -> void:
	if total == new_total and remaining == new_remaining:
		return
	total = new_total
	remaining = new_remaining
	if is_node_ready():
		_refresh_icons()

func _refresh_icons() -> void:
	while _row.get_child_count() > total:
		var holder: Node = _row.get_child(-1)
		_row.remove_child(holder)
		holder.queue_free()
	while _row.get_child_count() < total:
		var holder := Control.new()
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.custom_minimum_size = Vector2.ONE * ROW_HEIGHT
		_row.add_child(holder)
		ICON_EXTRUSION._add_portrait_icon_with_extrusion_to_holder(
			holder, HEART_TEXTURE, "AttemptHeart", 1, COUNTER_STYLE.ICON_SHADOW_ALPHA
		)
	var spent: Material = MATERIALS.grayscale(HEART_TEXTURE)
	var available: Material = MATERIALS.OUTLINE.material()
	for index: int in range(total):
		var icon := _row.get_child(index).get_node("AttemptHeart") as TextureRect
		icon.material = available if index < remaining else spent
