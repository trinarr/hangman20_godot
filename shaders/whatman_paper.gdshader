shader_type canvas_item;
render_mode unshaded;

#include "res://shaders/whatman_grain.gdshaderinc"

uniform vec2 paper_pixel_size;
uniform float grain_strength : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	COLOR.rgb = whatman_paper_color(COLOR.rgb, UV * paper_pixel_size, grain_strength);
}
