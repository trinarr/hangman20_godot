shader_type canvas_item;

uniform vec2 button_size = vec2(412.0, 68.0);
uniform float corner_radius = 34.0;
uniform float fraction : hint_range(0.0, 1.0) = 0.0;
uniform vec4 fill_color : source_color;

void fragment() {
	vec2 half_size = max(button_size * 0.5, vec2(0.001));
	float radius = min(corner_radius, min(half_size.x, half_size.y));
	vec2 q = abs(UV * button_size - half_size) - half_size + vec2(radius);
	float distance = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
	float edge = max(fwidth(distance), 0.001);
	float mask = 1.0 - smoothstep(-edge, edge, distance);
	// The fill has a straight right edge, clipped by the button's rounded outline.
	float filled = 1.0 - smoothstep(fraction - 0.5 / max(button_size.x, 1.0),
		fraction + 0.5 / max(button_size.x, 1.0), UV.x);
	COLOR *= vec4(fill_color.rgb, fill_color.a * mask * filled);
}
