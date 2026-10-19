shader_type canvas_item;
render_mode unshaded;

uniform bool upper_piece = true;
uniform float depth = 8.0;
#include "res://shaders/paper_edge.gdshaderinc"
#include "res://shaders/home_torn_blue_edge.gdshaderinc"

void fragment() {
	// Reuse Home's directional cast-shadow profile on a straight panel edge.
	float y = UV.y * depth;
	vec4 edges = upper_piece ? vec4(0.0, 0.0, 10000.0, 10000.0)
		: vec4(-10000.0, -10000.0, depth, depth);
	float shadow = home_torn_fiber_shadow(y, edges, 3.0);
	COLOR = vec4(0.0, 0.0, 0.0, shadow * COLOR.a);
}
