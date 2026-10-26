shader_type canvas_item;
#include "res://shaders/colored_icon_outline.gdshaderinc"

const float DISABLED_OPACITY = 0.85;
varying vec4 canvas_modulate;

void vertex() {
	canvas_modulate = COLOR;
	VERTEX = icon_outline_vertex(VERTEX, UV, MODEL_MATRIX, CANVAS_MATRIX);
}

void fragment() {
	vec4 source = outlined_icon(TEXTURE, UV);
	float luminance = dot(source.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(vec3(luminance), source.a * DISABLED_OPACITY) * canvas_modulate;
}
