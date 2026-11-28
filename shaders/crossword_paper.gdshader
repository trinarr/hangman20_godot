shader_type canvas_item;
render_mode unshaded;

#include "res://shaders/paper_edge.gdshaderinc"
#include "res://shaders/home_torn_blue_edge.gdshaderinc"
#include "res://shaders/whatman_grain.gdshaderinc"

uniform vec2 paper_size;
uniform vec2 paper_pixel_size;
uniform float paper_unit = 1.0;
uniform vec4 paper_color : source_color = vec4(1.0);

void fragment() {
	vec2 pixel = UV * paper_size;
	vec4 edges = home_torn_blue_edges(pixel.x, paper_unit,
		vec2(-12.0, paper_size.y - 2.0));
	float aa = max(0.45, fwidth(pixel.y));
	float coverage = 1.0 - smoothstep(edges.w - aa, edges.w + aa, pixel.y);
	vec3 paper = whatman_paper_color(paper_color.rgb, UV * paper_pixel_size, 1.0);
	paper *= 1.0 - home_torn_fiber_shadow(pixel.y, edges, paper_unit);
	float fiber = home_torn_fiber_mask(pixel.y, edges, aa);
	paper = mix(paper, home_torn_fiber_rgb(pixel, edges, paper_unit), fiber);
	COLOR = vec4(paper, coverage * COLOR.a);
}
