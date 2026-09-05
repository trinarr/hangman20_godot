extends RefCounted

const UI_PALETTE: GDScript = preload("res://scripts/ui/ui_palette.gd")

# Shared shadow profile for small rounded UI badges:
# free counters, ad counters, coin prices, theme-stage counters, etc.
const SHADOW_ALPHA: float = 0.25
const LAYER_COUNT: int = 4

const SHADOW_DEPTH_RATIO: float = 0.055
const SHADOW_DEPTH_MIN: float = 1.5
const SHADOW_DEPTH_MAX: float = 5.0
const SHADOW_OFFSET_X_RATIO: float = 0.012
const SHADOW_OFFSET_X_MAX: float = 1.8

const LAYER_DEPTHS: Array[float] = [0.25, 0.55, 0.80, 1.0]

const SHADER_CODE: String = """
shader_type canvas_item;
render_mode unshaded;

uniform vec4 shadow_color : source_color = vec4(0.05, 0.08, 0.24, 0.5);
uniform vec2 panel_size = vec2(32.0, 32.0);
uniform float corner_radius = 16.0;

void fragment() {
	vec2 half_size = panel_size * 0.5;
	vec2 p = UV * panel_size - half_size;
	float radius = clamp(corner_radius, 0.0, min(half_size.x, half_size.y));
	vec2 q = abs(p) - (half_size - vec2(radius));
	float dist = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
	float alpha = 1.0 - smoothstep(-1.0, 1.0, dist);
	COLOR = vec4(shadow_color.rgb, shadow_color.a * alpha);
}
"""

static func create_layers(
	parent: Control,
	prefix: String,
	z_index: int = -1
) -> Array[ColorRect]:
	var layers: Array[ColorRect] = []
	if parent == null or !is_instance_valid(parent):
		return layers

	var shader := Shader.new()
	shader.code = SHADER_CODE
	var shadow_base: Color = UI_PALETTE.NAV_TEXT_SHADOW

	for layer_index: int in range(LAYER_COUNT):
		var shadow_material := ShaderMaterial.new()
		shadow_material.shader = shader
		shadow_material.set_shader_parameter(
			"shadow_color",
			Color(
				shadow_base.r,
				shadow_base.g,
				shadow_base.b,
				SHADOW_ALPHA
			)
		)

		var layer := ColorRect.new()
		layer.name = "%sExtrusion%02d" % [prefix, layer_index + 1]
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.color = Color.WHITE
		layer.show_behind_parent = true
		layer.z_index = z_index
		layer.material = shadow_material
		parent.add_child(layer)
		layers.append(layer)

	return layers

static func layout_layers(
	layers: Array[ColorRect],
	panel_size: Vector2,
	corner_radius: float
) -> void:
	var panel_extent: float = minf(panel_size.x, panel_size.y)
	var shadow_depth: float = clampf(
		panel_extent * SHADOW_DEPTH_RATIO,
		SHADOW_DEPTH_MIN,
		SHADOW_DEPTH_MAX
	)
	var shadow_offset_x: float = minf(
		panel_extent * SHADOW_OFFSET_X_RATIO,
		SHADOW_OFFSET_X_MAX
	)

	for layer_index: int in range(layers.size()):
		var layer: ColorRect = layers[layer_index]
		if layer == null or !is_instance_valid(layer):
			continue

		var layer_t: float = LAYER_DEPTHS[
			mini(layer_index, LAYER_DEPTHS.size() - 1)
		]
		layer.position = Vector2(
			shadow_offset_x * layer_t,
			shadow_depth * layer_t
		)
		layer.size = panel_size

		var material := layer.material as ShaderMaterial
		if material != null:
			material.set_shader_parameter("panel_size", panel_size)
			material.set_shader_parameter("corner_radius", corner_radius)

static func set_visible(layers: Array, visible_value: bool) -> void:
	for layer_variant: Variant in layers:
		var layer := layer_variant as CanvasItem
		if layer != null and is_instance_valid(layer):
			layer.visible = visible_value
