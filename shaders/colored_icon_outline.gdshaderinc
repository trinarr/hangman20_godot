// Width is measured in render-target pixels, independently of icon/tween scale.
uniform bool colored_outline = false;
uniform float outline_pixels : hint_range(0.0, 12.0) = 2.0;
uniform vec4 outline_color : source_color = vec4(0.071, 0.102, 0.322, 1.0);

vec2 icon_outline_vertex(vec2 point, vec2 uv, mat4 model, mat4 canvas) {
	if (!colored_outline) { return point; }
	mat4 transform = canvas * model;
	vec2 scale = vec2(length(transform[0].xy), length(transform[1].xy));
	return point + (uv * 2.0 - 1.0) * (outline_pixels + 1.0) / max(scale, vec2(0.001));
}
