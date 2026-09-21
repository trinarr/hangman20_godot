shader_type canvas_item;
render_mode unshaded;

uniform vec2 fill_size = vec2(1.0, 30.0);
uniform vec4 base_color : source_color;
uniform vec4 highlight_color : source_color;

void fragment() {
	// Always render one full-size rounded pill. Progress is revealed by the parent
	// clip mask, so the artwork slides out from the left instead of collapsing into
	// a tiny/deformed capsule at the start of the animation.
	vec2 half_shape = fill_size * 0.5;
	float radius = min(half_shape.x, half_shape.y);
	vec2 q = abs(UV * fill_size - half_shape) - (half_shape - vec2(radius));
	float distance = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
	float feather = max(fwidth(distance), 0.001);
	float mask = 1.0 - smoothstep(-feather, 0.0, distance);
	float highlight_mix = 1.0 - smoothstep(0.092, 0.108, UV.y);
	vec4 fill = mix(base_color, highlight_color, highlight_mix);
	COLOR *= vec4(fill.rgb, fill.a * mask);
}
