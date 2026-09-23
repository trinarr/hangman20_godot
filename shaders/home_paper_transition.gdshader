shader_type canvas_item;
render_mode unshaded;

// Independent Home background, rendered once before its content is cleared.
uniform sampler2D home_texture : source_color, repeat_disable, filter_linear;
uniform float header_bottom = 80.0;
uniform float header_content_opacity : hint_range(0.0, 1.0) = 1.0;
uniform vec2 canvas_size = vec2(480.0, 800.0);
uniform vec4 logo_rect = vec4(0.0);
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 outline_color : source_color = vec4(0.2353, 0.3059, 0.6235, 1.0);
#include "res://shaders/paper_edge.gdshaderinc"

void fragment() {
	float opacity = COLOR.a;
	vec2 pixel = UV * canvas_size;
	float unit = max(0.01, logo_rect.z / 304.128);
	float original_top = logo_rect.y + logo_rect.w * (490.0 / 1254.0);
	float original_bottom = logo_rect.y + logo_rect.w * (865.0 / 1254.0);
	// Translate each blue piece rigidly, retaining the existing torn silhouette.
	float upper_shift = max(0.0, original_top - header_bottom + 16.0 * unit) * progress;
	float lower_shift = (canvas_size.y - original_bottom + 16.0 * unit) * progress;
	float top = original_top - upper_shift
		+ (torn_edge(pixel.x / unit / 8.0) - 0.5) * 2.4 * unit;
	float bottom = original_bottom + lower_shift
		+ (torn_edge(pixel.x / unit / 9.0 + 83.0) - 0.5) * 2.4 * unit;
	float aa = max(0.65, fwidth(pixel.y));
	float opening = smoothstep(top - aa, top + aa, pixel.y)
		* (1.0 - smoothstep(bottom - aa, bottom + aa, pixel.y));
	vec2 source_uv = UV;
	source_uv.y += (pixel.y < top ? upper_shift : -lower_shift) / canvas_size.y;
	source_uv.y = max(source_uv.y, header_bottom / canvas_size.y);
	vec3 blue = texture(home_texture, clamp(source_uv, vec2(0.0), vec2(1.0))).rgb;
	// Keep a thin torn outline on the blue side, without filling the opening.
	float edge = min(abs(pixel.y - top), abs(pixel.y - bottom));
	float outline = 1.0 - smoothstep(2.0 * unit - aa, 2.0 * unit + aa, edge);
	blue = mix(blue, outline_color.rgb, outline);
	if (pixel.y < header_bottom) {
		// Crossfade the old fixed bar directly into the destination's real bar.
		COLOR = vec4(texture(home_texture, UV).rgb, opacity * header_content_opacity);
	} else {
		// The destination is already laid out underneath. Blue pieces are its mask.
		COLOR = vec4(blue, opacity * (1.0 - opening));
	}
}
