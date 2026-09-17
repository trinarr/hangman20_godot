shader_type canvas_item;
render_mode unshaded;

// The geometry is rendered by real Label glyphs (including their native
// outline). The shader only recolors those pixels into the project shadow
// color. Stacking several vertically-offset glyph silhouettes creates the
// compact extrusion used by display text without any SubViewport/backbuffer.
uniform vec4 shadow_color : source_color = vec4(0.05, 0.08, 0.24, 0.82);

void fragment() {
	float source_alpha = COLOR.a;
	COLOR = vec4(shadow_color.rgb, source_alpha * shadow_color.a);
}
