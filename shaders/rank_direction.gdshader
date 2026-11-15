shader_type canvas_item;
render_mode unshaded;
#include "res://shaders/colored_icon_outline.gdshaderinc"
uniform vec4 source_tint : source_color = vec4(1.0);
#define ICON_SOURCE_TINT source_tint
varying float canvas_alpha;
void vertex() {
	canvas_alpha = COLOR.a;
	VERTEX = icon_outline_vertex(VERTEX, UV, MODEL_MATRIX, CANVAS_MATRIX);
}
void fragment() {
	#include "res://shaders/colored_icon_outline_fragment.gdshaderinc"
	COLOR = vec4(icon_color.rgb, icon_color.a * canvas_alpha);
}
