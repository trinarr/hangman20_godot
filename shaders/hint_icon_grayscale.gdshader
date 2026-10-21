shader_type canvas_item;

const float DISABLED_OPACITY = 0.85;
varying vec4 canvas_modulate;

void vertex() {
	canvas_modulate = COLOR;
}

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float luminance = dot(source.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(vec3(luminance), source.a * DISABLED_OPACITY) * canvas_modulate;
}
