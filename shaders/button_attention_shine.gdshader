shader_type canvas_item;
render_mode unshaded;

uniform float shine_progress = -0.35;
uniform float shine_width = 0.16;
uniform float shine_strength = 0.42;
uniform float aspect_ratio = 1.0;

float rounded_box_distance(vec2 point, vec2 half_size, float radius) {
	vec2 distance_to_edge = abs(point) - half_size + vec2(radius);
	return min(max(distance_to_edge.x, distance_to_edge.y), 0.0)
		+ length(max(distance_to_edge, vec2(0.0))) - radius;
}

void fragment() {
	vec2 point = (UV - vec2(0.5)) * vec2(aspect_ratio, 1.0);
	vec2 half_size = vec2(aspect_ratio * 0.5, 0.5);
	float corner_radius = min(0.48, half_size.x);
	float edge_softness = max(fwidth(point.x), fwidth(point.y)) * 1.5;
	float shape_mask = 1.0 - smoothstep(
		-edge_softness,
		edge_softness,
		rounded_box_distance(point, half_size, corner_radius)
	);
	float diagonal_position = UV.x + UV.y * 0.20;
	float distance_to_shine = abs(diagonal_position - shine_progress);
	float shine_band = 1.0 - smoothstep(shine_width * 0.35, shine_width, distance_to_shine);
	COLOR = vec4(1.0, 1.0, 1.0, shine_band * shine_strength * shape_mask);
}
