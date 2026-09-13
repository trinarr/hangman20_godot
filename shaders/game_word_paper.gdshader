shader_type canvas_item;
render_mode unshaded;
#include "res://shaders/paper_edge.gdshaderinc"

uniform vec2 paper_size = vec2(564.0, 100.3);
uniform vec2 surface_size = vec2(564.0, 106.3);
uniform float stage_origin_x = -42.0;

void fragment() {
	vec2 pixel = UV * surface_size;
	vec2 edges = paper_edges(stage_origin_x + pixel.x, paper_size.y);
	float aa = max(0.45, fwidth(pixel.y));
	float mask = smoothstep(edges.x - aa, edges.x + aa, pixel.y)
		* (1.0 - smoothstep(edges.y - aa, edges.y + aa, pixel.y));
	// Sample only the clean paper interior, independently of the shadow padding.
	vec2 paper_uv = clamp(pixel / paper_size, vec2(0.0), vec2(1.0));
	vec3 paper = texture(TEXTURE, vec2(mix(0.08, 0.92, paper_uv.x), mix(0.16, 0.80, paper_uv.y))).rgb;
	// This is a loose sheet on top of the grid: shade beneath the lower edge,
	// never inside the upper edge. The expanded draw rect keeps the falloff intact.
	float distance_below = max(0.0, pixel.y - edges.y);
	float shadow = 0.24 * (1.0 - smoothstep(0.0, 5.0, distance_below));
	shadow *= smoothstep(edges.y - aa, edges.y + aa, pixel.y) * (1.0 - mask);
	float alpha = mask + shadow;
	vec3 color = (paper * mask + vec3(0.16, 0.18, 0.26) * shadow) / max(alpha, 0.0001);
	COLOR = vec4(color, alpha);
}
