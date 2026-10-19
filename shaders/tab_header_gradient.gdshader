shader_type canvas_item;
render_mode unshaded;

uniform vec4 top_color : source_color;
uniform vec4 bottom_color : source_color;
uniform vec2 rect_size = vec2(210.0, 65.0);

void fragment() {
	vec2 pixel = UV * rect_size;
	float radius = 16.0;
	vec2 center = vec2(clamp(pixel.x, radius, rect_size.x - radius), radius);
	float distance_to_edge = length(pixel - center) - radius;
	float aa = max(fwidth(distance_to_edge), 0.001);
	float coverage = pixel.y < radius ? 1.0 - smoothstep(-aa, aa, distance_to_edge) : 1.0;
	vec4 fill = mix(top_color, bottom_color, UV.y);
	// Match the raised long button's rim and bevel, only along the top edge.
	float depth = pixel.y < radius ? max(-distance_to_edge, 0.0) : pixel.y;
	vec2 normal = pixel.y < radius ? normalize(pixel - center + vec2(0.0, 0.0001)) : vec2(0.0, -1.0);
	float bevel = rect_size.y * 0.10;
	float edge_light = 0.62 + 0.38 * max(-normal.y, 0.0);
	float edge_shade = mix(0.34, edge_light, smoothstep(0.0, rect_size.y * 0.025, depth));
	float shade = mix(edge_shade, 0.819608, smoothstep(bevel * 0.67, bevel, depth));
	// Preserve the existing gradient away from the beveled rim.
	float upper_edge = max(-normal.y, 0.0);
	fill.rgb *= mix(1.0, shade / 0.819608, upper_edge);
	COLOR = vec4(fill.rgb, fill.a * coverage * COLOR.a);
}
