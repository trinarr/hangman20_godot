shader_type canvas_item;
render_mode unshaded;
#include "res://shaders/portrait_grid_paper.gdshaderinc"
uniform float corner_radius = 8.0;

void fragment() {
	vec2 point = UV * paper_canvas_size;
	vec2 half_size = paper_canvas_size * 0.5;
	vec2 delta = abs(point - half_size) - (half_size - vec2(corner_radius));
	float distance_to_edge = length(max(delta, vec2(0.0))) + min(max(delta.x, delta.y), 0.0) - corner_radius;
	float coverage = 1.0 - smoothstep(-0.5, 0.5, distance_to_edge);
	COLOR = vec4(portrait_grid_paper(point), coverage) * COLOR;
}
