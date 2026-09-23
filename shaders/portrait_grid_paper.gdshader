shader_type canvas_item;
render_mode unshaded;
#include "res://shaders/portrait_grid_paper.gdshaderinc"

void fragment() {
	COLOR = vec4(portrait_grid_paper(UV * paper_canvas_size), 1.0) * COLOR;
}
