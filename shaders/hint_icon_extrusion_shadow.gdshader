shader_type canvas_item;
render_mode unshaded;

// TextureRect-compatible counterpart of the display-text extrusion shader.
// It keeps only the source icon alpha and recolors the silhouette with the
// same project shadow color used by button/headline display text.
uniform vec4 shadow_color : source_color = vec4(0.05, 0.08, 0.24, 0.72);

void fragment() {
	vec4 source = texture(TEXTURE, UV) * COLOR;
	COLOR = vec4(shadow_color.rgb, source.a * shadow_color.a);
}
