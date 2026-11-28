// Shared paper texture for the Word Trials strip and portrait paper pages.
#include "res://shaders/whatman_grain.gdshaderinc"

uniform sampler2D paper_texture : source_color, filter_linear, repeat_disable;
uniform vec2 paper_canvas_size = vec2(480.0, 800.0);
uniform float paper_unit = 1.0;
// source_color preserves these sRGB reference colors in both rendering modes.
uniform vec4 paper_base_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 paper_grid_color : source_color = vec4(0.760784, 0.768627, 0.886275, 1.0);

vec3 portrait_paper(vec2 pixel) {
	vec2 paper_uv = clamp(pixel / max(paper_canvas_size, vec2(1.0)), vec2(0.0), vec2(1.0));
	vec3 paper = texture(paper_texture, vec2(
		mix(0.05, 0.95, paper_uv.x), mix(0.12, 0.82, paper_uv.y)
	)).rgb;
	// Retain a little paper grain without carrying the warm sheet's yellow tint
	// into the page background. The word's separate torn sheet is unchanged.
	float grain = clamp((1.0 - dot(paper, vec3(0.2126, 0.7152, 0.0722))) * 0.15, 0.0, 0.01);
	return whatman_paper_color(paper_base_color.rgb * (1.0 - grain), pixel, 1.0);
}

vec3 portrait_grid_paper(vec2 pixel) {
	float unit = max(0.01, paper_unit);
	vec2 grid_distance = abs(fract(pixel / (15.0 * unit) + 0.5) - 0.5) * (15.0 * unit);
	float grid = 1.0 - smoothstep(0.30 * unit, 0.80 * unit,
		min(grid_distance.x, grid_distance.y));
	return mix(portrait_paper(pixel), paper_grid_color.rgb, grid * paper_grid_color.a);
}
