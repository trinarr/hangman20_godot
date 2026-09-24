shader_type canvas_item;
render_mode unshaded;

// Independent Home background, rendered once before its content is cleared.
uniform sampler2D home_texture : source_color, repeat_disable, filter_linear;
uniform float header_bottom = 80.0;
uniform float header_content_opacity : hint_range(0.0, 1.0) = 1.0;
uniform vec2 canvas_size = vec2(480.0, 800.0);
uniform vec4 logo_rect = vec4(0.0);
uniform bool destination_ready = false;
uniform float gather_distance = 6.0;
uniform float gather : hint_range(0.0, 1.0) = 0.0;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
#include "res://shaders/paper_edge.gdshaderinc"
#include "res://shaders/home_torn_blue_edge.gdshaderinc"
#include "res://shaders/portrait_grid_paper.gdshaderinc"

void fragment() {
	float opacity = COLOR.a;
	vec2 pixel = UV * canvas_size;
	float unit = max(0.01, logo_rect.z / 304.128);
	float original_top = logo_rect.y + logo_rect.w * (490.0 / 1254.0);
	float original_bottom = logo_rect.y + logo_rect.w * (865.0 / 1254.0);
	// Translate each blue piece rigidly, retaining the existing torn silhouette.
	float anticipation = gather_distance * unit * gather;
	float upper_shift = max(0.0, original_top - header_bottom + 16.0 * unit) * progress - anticipation;
	float lower_shift = (canvas_size.y - original_bottom + 16.0 * unit) * progress - anticipation;
	vec4 edges = home_torn_blue_edges(pixel.x, unit,
		vec2(original_top - upper_shift, original_bottom + lower_shift));
	float top = edges.x;
	float bottom = edges.w;
	float aa = max(0.65, fwidth(pixel.y));
	float opening = smoothstep(top - aa, top + aa, pixel.y)
		* (1.0 - smoothstep(bottom - aa, bottom + aa, pixel.y));
	float source_y = pixel.y + (pixel.y < top ? upper_shift : -lower_shift);
	// Extend the body beyond its screen bounds instead of stretching its first
	// row under the fixed header. Half-texel insets keep counters out of filtering.
	float half_texel = 0.5 / float(textureSize(home_texture, 0).y);
	float body_top = header_bottom / canvas_size.y + half_texel;
	float body_bottom = 1.0 - half_texel;
	float body_span = max(half_texel, body_bottom - body_top);
	float reflected_y = mod(source_y / canvas_size.y - body_top, 2.0 * body_span);
	reflected_y = body_top + body_span - abs(reflected_y - body_span);
	vec3 blue = texture(home_texture, vec2(UV.x, reflected_y)).rgb;
	// The same exposed paper rim as Home, translated without changing thickness.
	float fiber = home_torn_fiber_mask(pixel.y, edges, aa);
	vec3 fiber_rgb = home_torn_fiber_rgb(pixel, edges, unit);
	float shadow = home_torn_fiber_shadow(pixel.y, edges, unit);
	if (pixel.y < header_bottom) {
		// Crossfade the old fixed bar directly into the destination's real bar.
		COLOR = vec4(texture(home_texture, UV).rgb, opacity * header_content_opacity);
	} else if (!destination_ready) {
		// Retain Home paper while the foreground fades, before navigation.
		vec3 paper = portrait_grid_paper(pixel);
		paper *= 1.0 - shadow;
		paper = mix(paper, fiber_rgb, fiber);
		COLOR = vec4(mix(blue, paper, opening), opacity);
	} else {
		// Draw both light paper rims and their shadows over the real destination.
		// Straight-alpha composition keeps their thickness/strength unchanged
		// when the opaque Home paper is replaced by a transparent opening.
		float blue_alpha = 1.0 - opening;
		float fiber_alpha = opening * fiber;
		float shadow_alpha = opening * (1.0 - fiber) * shadow;
		float alpha = blue_alpha + fiber_alpha + shadow_alpha;
		vec3 premultiplied = blue * blue_alpha + fiber_rgb * fiber_alpha;
		COLOR = vec4(premultiplied / max(alpha, 0.00001), opacity * alpha);
	}
}
