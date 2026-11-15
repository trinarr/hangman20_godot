extends Control
## Navigation-icon effects; tint only the fill, never the outline or shadow.
const TEXTURE = preload("res://flash_assets/portrait_back_arrow_icon.png")
const SHADER = preload("res://shaders/rank_direction.gdshader")
const ICON_STYLE = preload("res://scripts/ui/portrait_icon_extrusion.gd")
const SIZE := Vector2.ONE * 14.0 * 1.15
# Zero-gap origins match the down arrow above and up arrow below 25px rank ink.
const GAP := 4.0
const UPPER_Y := 8.2 - GAP
const LOWER_Y := 39.5 + GAP
var color := Color.WHITE
var promoted := true
static var _front_materials: Dictionary = {}

static func _front_material(tint: Color) -> ShaderMaterial:
	# Shared profiles are immutable; opacity is supplied by each CanvasItem.
	if !_front_materials.has(tint):
		var material := ShaderMaterial.new()
		material.shader = SHADER
		material.set_shader_parameter("colored_outline", true)
		material.set_shader_parameter("source_tint", tint)
		material.set_shader_parameter("outline_color", ICON_STYLE.OUTLINE.PALETTE.TEXT_DARK)
		material.set_shader_parameter("outline_pixels", ICON_STYLE.OUTLINE.DEFAULT_PIXELS)
		_front_materials[tint] = material
	return _front_materials[tint]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var arrow := ICON_STYLE._add_portrait_icon_with_extrusion_to_holder(
		self, TEXTURE, "Arrow", 1,
		ICON_STYLE.ACTION_SHADOW_ALPHA, ICON_STYLE.ACTION_SHADOW_OFFSET_SCALE
	)
	arrow.material = _front_material(color)
	var shadow: TextureRect = get_node("ArrowExtrusion01")
	var shadow_color: Color = shadow.material.get_shader_parameter("shadow_color")
	# Cast the complete outlined silhouette. The tiny fill-only shadow otherwise
	# stays underneath the front contour instead of projecting visibly below it.
	shadow.set_shadow_material(ICON_STYLE.UI_MATERIALS.icon_shadow(shadow_color, ICON_STYLE.OUTLINE.DEFAULT_PIXELS))
	for visual: TextureRect in [shadow, arrow]:
		visual.pivot_offset = size * 0.5
		visual.rotation = PI * 0.5 if promoted else -PI * 0.5
