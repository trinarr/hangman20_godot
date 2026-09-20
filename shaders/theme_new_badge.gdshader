shader_type canvas_item;
render_mode unshaded;

uniform vec2 panel_size = vec2(55.0, 20.0);
uniform float corner_radius = 3.0;
uniform float right_slant = 5.0;
uniform vec4 top_color : source_color = vec4(0.20, 0.85, 0.37, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.12, 0.76, 0.27, 1.0);
uniform bool shadow_pass = false;
uniform vec4 shadow_color : source_color = vec4(0.05, 0.08, 0.24, 0.25);

void fragment() {
	vec2 half_size = panel_size * 0.5;
	vec2 p = UV * panel_size - half_size;
	// The top-right tip projects farther than the bottom-right tip.
	// Keep the left seam vertical and square where the ribbon folds back.
	float radius = 0.0;
	if (p.x > 0.0) {
		p.x += right_slant * UV.y;
		radius = clamp(corner_radius, 0.0, min(half_size.x, half_size.y));
	}
	vec2 q = abs(p) - (half_size - vec2(radius));
	float dist = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
	float coverage = 1.0 - smoothstep(-1.0, 1.0, dist);
	vec4 fill = shadow_pass ? shadow_color : mix(top_color, bottom_color, UV.y);
	// Retain the existing reveal fade and ancestor modulation on both passes.
	COLOR *= vec4(fill.rgb, fill.a * coverage);
}
