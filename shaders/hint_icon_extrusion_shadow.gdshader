shader_type canvas_item;
render_mode unshaded;
#include "res://shaders/colored_icon_outline.gdshaderinc"

// TextureRect-compatible counterpart of the display-text extrusion shader.
// It keeps only the source icon alpha and recolors the silhouette with the
// same project shadow color used by button/headline display text.
uniform vec4 shadow_color : source_color = vec4(0.05, 0.08, 0.24, 0.72);

varying float vertex_alpha;

void vertex() {
	vertex_alpha = COLOR.a;
	VERTEX = icon_outline_vertex(VERTEX, UV, MODEL_MATRIX, CANVAS_MATRIX);
}

void fragment() {
	// Preserve the authored edge coverage (the previous TEXTURE * COLOR applied
	// texture alpha twice), but sample the texture explicitly only once.
	float alpha = outlined_icon(TEXTURE, UV).a;
	COLOR = vec4(shadow_color.rgb, alpha * alpha * vertex_alpha * shadow_color.a);
}
