shader_type canvas_item;
render_mode unshaded;
#include "res://shaders/colored_icon_outline.gdshaderinc"
varying vec4 canvas_modulate;

void vertex() {
	canvas_modulate = COLOR;
	VERTEX = icon_outline_vertex(VERTEX, UV, MODEL_MATRIX, CANVAS_MATRIX);
}

void fragment() {
	COLOR = vec4(vec3(1.0), outlined_icon(TEXTURE, UV).a) * canvas_modulate;
}
