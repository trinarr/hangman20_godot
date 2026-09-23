shader_type canvas_item;
render_mode unshaded;

// Read the still-live Home canvas on the GPU; no CPU screenshot/readback.
uniform sampler2D home_screen : hint_screen_texture, repeat_disable, filter_linear;
uniform float header_bottom = 80.0;
uniform vec4 header_color : source_color;
uniform float header_content_opacity : hint_range(0.0, 1.0) = 1.0;
uniform vec2 canvas_size = vec2(480.0, 800.0);
uniform vec4 logo_rect = vec4(0.0);
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float gather : hint_range(0.0, 1.0) = 0.0;
uniform vec4 outline_color : source_color = vec4(0.2353, 0.3059, 0.6235, 1.0);
#include "res://shaders/paper_edge.gdshaderinc"
#include "res://shaders/portrait_grid_paper.gdshaderinc"

void fragment() {
	float opacity = COLOR.a;
	vec2 pixel = UV * canvas_size;
	float unit = max(0.01, logo_rect.z / 304.128);
	float original_top = logo_rect.y + logo_rect.w * (490.0 / 1254.0);
	float original_bottom = logo_rect.y + logo_rect.w * (865.0 / 1254.0);
	// Translate each blue piece rigidly, retaining the existing torn silhouette.
	float anticipation = 6.0 * unit * gather;
	float upper_shift = max(0.0, original_top - header_bottom + 16.0 * unit) * progress - anticipation;
	float lower_shift = (canvas_size.y - original_bottom + 16.0 * unit) * progress - anticipation;
	float top = original_top - upper_shift
		+ (torn_edge(pixel.x / unit / 8.0) - 0.5) * 2.4 * unit;
	float bottom = original_bottom + lower_shift
		+ (torn_edge(pixel.x / unit / 9.0 + 83.0) - 0.5) * 2.4 * unit;
	float aa = max(0.65, fwidth(pixel.y));
	float sheet = smoothstep(top - aa, top + aa, pixel.y)
		* (1.0 - smoothstep(bottom - aa, bottom + aa, pixel.y));
	// Keep the original Home grid fixed throughout the tear and page handoff.
	vec3 paper = portrait_grid_paper(pixel);
	float lip = max(0.0, pixel.y - top - 2.0 * unit);
	paper *= 1.0 - 0.17 * (1.0 - smoothstep(0.0, 3.0 * unit, lip));
	float edge = min(pixel.y - top, bottom - pixel.y);
	float outline = 1.0 - smoothstep(2.0 * unit - aa, 2.0 * unit + aa, edge);
	paper = mix(paper, outline_color.rgb, outline);
	vec2 source_uv = SCREEN_UV;
	source_uv.y += (pixel.y < top ? upper_shift : -lower_shift) / canvas_size.y;
	// During gathering, extend the blue edge under the fixed bar instead of
	// pulling any of its counters down into the moving piece.
	source_uv.y = max(source_uv.y, header_bottom / canvas_size.y);
	vec3 blue = texture(home_screen, clamp(source_uv, vec2(0.0), vec2(1.0))).rgb;
	if (pixel.y < header_bottom) {
		// Sample the bar at its original position. Its counters have a separate
		// fade, unaffected by either blue-piece motion or the content cover alpha.
		vec3 header = texture(home_screen, SCREEN_UV).rgb;
		COLOR = vec4(mix(header_color.rgb, header, header_content_opacity), 1.0);
	} else {
		COLOR = vec4(mix(blue, paper, sheet), opacity);
	}
}
