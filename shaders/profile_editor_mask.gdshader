shader_type canvas_item;
render_mode unshaded;

#include "res://shaders/paper_edge.gdshaderinc"
#include "res://shaders/home_torn_blue_edge.gdshaderinc"

uniform vec2 source_size = vec2(1.0);
uniform vec4 mask_rect = vec4(0.0, 0.0, 1.0, 1.0);
uniform float corner_radius = 0.0;
uniform float paper_unit = 1.0;
uniform float tear_progress : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 point = UV * source_size;
	vec2 half_size = mask_rect.zw * 0.5;
	float radius = min(corner_radius, min(half_size.x, half_size.y));
	vec2 delta = abs(point - mask_rect.xy - half_size) - (half_size - vec2(radius));
	float distance_to_edge = length(max(delta, vec2(0.0)))
		+ min(max(delta.x, delta.y), 0.0) - radius;
	float aa = max(0.5, fwidth(point.y));
	float coverage = 1.0 - smoothstep(-aa, aa, distance_to_edge);
	// Home's two paper contours, facing outwards with the same exposed rims.
	float unit = max(0.01, paper_unit);
	float top = mask_rect.y;
	float bottom = mask_rect.y + mask_rect.w;
	vec4 edges = home_torn_blue_edges(point.x, unit,
		vec2(bottom - 7.0 * unit, bottom + 100.0 * unit));
	vec4 top_edges = home_torn_blue_edges(point.x, unit,
		vec2(top - 100.0 * unit, top + 7.0 * unit));
	float outer = mix(bottom, edges.y, tear_progress);
	float inner = mix(bottom, edges.x, tear_progress);
	float top_outer = mix(top, top_edges.z, tear_progress);
	float top_inner = mix(top, top_edges.w, tear_progress);
	coverage *= smoothstep(top_outer - aa, top_outer + aa, point.y);
	coverage *= 1.0 - smoothstep(outer - aa, outer + aa, point.y);
	float fiber = max(smoothstep(inner - aa, inner + aa, point.y),
		1.0 - smoothstep(top_inner - aa, top_inner + aa, point.y)) * tear_progress;
	vec4 result = texture(TEXTURE, UV);
	result.rgb = mix(result.rgb, home_torn_fiber_rgb(point, edges, unit), fiber);
	result.a *= coverage;
	COLOR = result;
}
