shader_type canvas_item;
render_mode unshaded;

void fragment() {
	// COLOR already contains texture alpha multiplied by CanvasItem modulation.
	// Preserve that alpha once; no additional texture sample or light pass.
	COLOR.rgb = vec3(1.0);
}
