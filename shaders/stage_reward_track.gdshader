shader_type canvas_item;
render_mode unshaded;

uniform vec2 fill_size = vec2(396.0, 51.1);
uniform vec2 inset = vec2(2.5);
uniform float bottom_inset = 4.0;
uniform bool segmented = true;
uniform float progress : hint_range(0.0, 1.0) = 1.0;
uniform vec4 track_color : source_color;
uniform vec4 base_color : source_color;
uniform vec4 highlight_color : source_color;
uniform vec4 middle_color : source_color;
uniform vec4 center_color : source_color;

float pill_distance(vec2 point, vec2 size) {
	vec2 half_shape = size * 0.5;
	float radius = min(half_shape.x, half_shape.y);
	vec2 q = abs(point - half_shape) - (half_shape - vec2(radius));
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
}

void fragment() {
	// One shared rectangle prevents Control snapping from moving only the fill.
	vec2 point = UV * fill_size;
	vec2 inner_size = max(fill_size - vec2(inset.x * 2.0, inset.y + bottom_inset), vec2(0.001));
	vec2 inner_uv = (point - inset) / inner_size;
	float outer_distance = pill_distance(point, fill_size);
	float inner_distance = pill_distance(point - inset, inner_size);
	float outer_mask = 1.0 - smoothstep(-max(fwidth(outer_distance), 0.001), 0.0, outer_distance);
	float inner_mask = 1.0 - smoothstep(-max(fwidth(inner_distance), 0.001), 0.0, inner_distance);
	// Reveal a fixed-size pill; the moving front stays straight at partial fill.
	float reveal = clamp((progress - inner_uv.x) / max(fwidth(inner_uv.x), 0.00001) + 0.5, 0.0, 1.0);
	inner_mask *= progress <= 0.0 ? 0.0 : (progress >= 1.0 ? 1.0 : reveal);
	float sector = floor(clamp(inner_uv.x, 0.0, 0.9999) * 5.0);
	vec4 zone = segmented ? (sector == 2.0 ? center_color : ((sector == 1.0 || sector == 3.0) ? middle_color : base_color)) : base_color;
	float highlight_mix = 1.0 - smoothstep(0.092, 0.108, inner_uv.y);
	vec3 highlight = segmented ? mix(zone.rgb, vec3(1.0), 0.25) : highlight_color.rgb;
	vec3 fill_rgb = mix(zone.rgb, highlight, highlight_mix);
	float fill_alpha = zone.a * inner_mask;
	float alpha = fill_alpha + track_color.a * (1.0 - fill_alpha);
	vec3 rgb = (fill_rgb * fill_alpha + track_color.rgb * track_color.a * (1.0 - fill_alpha)) / max(alpha, 0.0001);
	COLOR *= vec4(rgb, alpha * outer_mask);
}
