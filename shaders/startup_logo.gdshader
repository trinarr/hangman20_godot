shader_type canvas_item;
render_mode unshaded;

uniform vec2 canvas_size = vec2(480.0, 800.0);
uniform vec4 logo_rect = vec4(87.936, 142.8, 304.128, 304.128);
#include "res://shaders/paper_edge.gdshaderinc"
#include "res://shaders/home_torn_blue_edge.gdshaderinc"
#include "res://shaders/portrait_grid_paper.gdshaderinc"
#include "res://shaders/home_logo_ink.gdshaderinc"

void fragment() {
	float opacity = COLOR.a;
	vec2 pixel = UV * canvas_size;
	float unit = max(0.01, logo_rect.z / 304.128);
	vec2 edge_bases = logo_rect.y + logo_rect.w * vec2(490.0, 865.0) / 1254.0;
	vec4 edges = home_torn_blue_edges(pixel.x, unit, edge_bases);
	float aa = max(0.65, fwidth(pixel.y));
	float sheet_mask = smoothstep(edges.x - aa, edges.x + aa, pixel.y)
		* (1.0 - smoothstep(edges.w - aa, edges.w + aa, pixel.y));
	vec2 logo_uv = (pixel - logo_rect.xy) / logo_rect.zw;
	vec4 layer = vec4(0.0);
	if (sheet_mask > 0.0) {
		vec3 paper = portrait_grid_paper(pixel);
		paper *= 1.0 - home_torn_fiber_shadow(pixel.y, edges, unit);
		vec4 ink = sample_title(logo_uv);
		ink.a *= 1.0 - badge_region(logo_uv);
		vec3 result = mix(paper, ink.rgb, ink.a);
		float fiber = home_torn_fiber_mask(pixel.y, edges, aa);
		result = mix(result, home_torn_fiber_rgb(pixel, edges, unit), fiber);
		layer = vec4(result, sheet_mask);
	}
	// Preserve Home's settled pivot calculation, including texture-edge rounding.
	vec2 pivot = vec2(980.0, 585.0) / 1254.0;
	vec2 badge_uv = pivot + (logo_uv - pivot);
	vec4 badge = sample_ink(badge_uv);
	badge.a *= badge_region(badge_uv);
	float alpha = badge.a + layer.a * (1.0 - badge.a);
	layer = vec4((badge.rgb * badge.a + layer.rgb * layer.a * (1.0 - badge.a))
		/ max(0.0001, alpha), alpha);
	COLOR = vec4(layer.rgb, layer.a * opacity);
}
