shader_type canvas_item;
render_mode unshaded;
#include "res://shaders/paper_edge.gdshaderinc"

uniform sampler2D backside_texture : source_color, filter_linear, repeat_disable;
uniform vec2 surface_size = vec2(200.0, 116.3);
uniform float paper_height = 100.3;
uniform float stage_origin_x = 0.0;
uniform float fold_width = 0.0;

void fragment() {
	// Reserve nine pixels before the contact for its shadow and eight above/below
	// the sheet for the slight free-edge expansion. Never scale the whole texture.
	vec2 pixel = UV * surface_size - vec2(9.0, 8.0);
	float aa = max(0.45, fwidth(pixel.y));
	vec4 layer = vec4(0.0);
	if (fold_width > 0.1) {
		vec2 edges = paper_edges(stage_origin_x + pixel.x, paper_height);
		float u = clamp(pixel.x / fold_width, 0.0, 1.0);
		float flare = (edges.y - edges.x) * 0.035 * smoothstep(0.65, 1.0, u);
		float top = edges.x - flare;
		float bottom = edges.y + flare;
		float contact = smoothstep(-aa, aa, pixel.x);
		float free_edge = fold_width + (torn_edge(pixel.y / 6.0 + 139.0) - 0.5) * 1.5;
		float mask = smoothstep(top - aa, top + aa, pixel.y)
			* (1.0 - smoothstep(bottom - aa, bottom + aa, pixel.y))
			* contact * (1.0 - smoothstep(free_edge - aa, free_edge + aa, pixel.x));
		float band_y = clamp((pixel.y - top) / (bottom - top), 0.0, 1.0);
		vec3 backside = texture(backside_texture, vec2(u, mix(0.10, 0.84, band_y))).rgb;
		float shadow = (1.0 - smoothstep(0.0, 9.0, -pixel.x)) * 0.24 * (1.0 - contact);
		shadow *= smoothstep(edges.x - aa, edges.x + aa, pixel.y)
			* (1.0 - smoothstep(edges.y - aa, edges.y + aa, pixel.y));
		float alpha = mask + shadow * (1.0 - mask);
		layer = vec4(backside * mask / max(0.0001, alpha), alpha);
	}
	COLOR = layer;
}
