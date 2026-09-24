shader_type canvas_item;
render_mode unshaded;
#include "res://shaders/paper_edge.gdshaderinc"

uniform vec2 paper_size = vec2(564.0, 100.3);
uniform vec2 surface_size = vec2(564.0, 106.3);
uniform float stage_origin_x = -42.0;
// Clean exposed fibers; the cream face keeps its original paper texture.
uniform vec4 torn_rim_color : source_color = vec4(1.0);

void fragment() {
	vec2 pixel = UV * surface_size;
	vec2 edges = paper_edges(stage_origin_x + pixel.x, paper_size.y);
	float aa = max(0.45, fwidth(pixel.y));
	float mask = smoothstep(edges.x - aa, edges.x + aa, pixel.y)
		* (1.0 - smoothstep(edges.y - aa, edges.y + aa, pixel.y));
	// Sample only the clean paper interior, independently of the shadow padding.
	vec2 paper_uv = clamp(pixel / paper_size, vec2(0.0), vec2(1.0));
	vec3 paper = texture(TEXTURE, vec2(mix(0.08, 0.92, paper_uv.x), mix(0.16, 0.80, paper_uv.y))).rgb;
	// A second, independently torn contour gives the lower rim real width.
	// Keep the outside silhouette shared with the animated reverse face.
	float stage_x = stage_origin_x + pixel.x;
	float rim_inner = paper_size.y - 3.0 - 4.125
		+ (torn_edge(stage_x / 8.0 + 29.0) - 0.5) * 1.8;
	// Widen every local section by 30%, retaining the shared outer silhouette.
	rim_inner = edges.y - (edges.y - rim_inner) * 1.30;
	float rim = smoothstep(rim_inner - aa, rim_inner + aa, pixel.y);
	paper = mix(paper, torn_rim_color.rgb, rim);
	// This is a loose sheet on top of the grid: shade beneath the lower edge,
	// never inside the upper edge. The expanded draw rect keeps the falloff intact.
	float distance_below = max(0.0, pixel.y - edges.y);
	// Match Home's upper blue piece: same offset, opacity and blur in stage pixels.
	float shadow_offset = 1.5;
	float shadow = 0.15 * (1.0 - smoothstep(shadow_offset,
		shadow_offset + 0.85, distance_below));
	// Coverage clips the shadow beneath the sheet, including its antialiased rim.
	shadow *= smoothstep(edges.y - aa, edges.y + aa, pixel.y);
	float alpha = mask + shadow;
	vec3 color = (paper * mask) / max(alpha, 0.0001);
	COLOR = vec4(color, alpha);
}
