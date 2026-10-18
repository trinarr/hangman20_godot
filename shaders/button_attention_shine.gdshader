shader_type canvas_item;
render_mode unshaded;
#include "res://shaders/button_shapes.gdshaderinc"

uniform float shine_progress = -0.35;
uniform float shine_width = 0.16;
uniform float shine_strength = 0.42;
uniform float aspect_ratio = 1.0;

uniform bool round_shape = false;

void fragment() {
	vec2 point = (UV - vec2(0.5)) * vec2(aspect_ratio, 1.0);
	float d = button_distance(point, vec2(aspect_ratio, 1.0), round_shape);
	float edge_softness = max(fwidth(d) * 0.5, 0.0001);
	float shape_mask = 1.0 - smoothstep(-edge_softness, edge_softness, d);
	float diagonal_position = UV.x + UV.y * 0.20;
	float distance_to_shine = abs(diagonal_position - shine_progress);
	float shine_band = 1.0 - smoothstep(shine_width * 0.35, shine_width, distance_to_shine);
	COLOR *= vec4(1.0, 1.0, 1.0, shine_band * shine_strength * shape_mask);
}
