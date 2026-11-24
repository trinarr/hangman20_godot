shader_type canvas_item;
render_mode unshaded;

uniform vec4 pattern_color : source_color;
uniform vec2 icon_size;
uniform vec2 tear_fade_y;
varying float icon_center_y;

void vertex() {
	icon_center_y = (MODEL_MATRIX * vec4(icon_size * 0.5, 0.0, 1.0)).y;
}

void fragment() {
	float above_tear = 1.0 - smoothstep(tear_fade_y.x, tear_fade_y.y, icon_center_y);
	COLOR = vec4(pattern_color.rgb, COLOR.a * pattern_color.a * above_tear);
}
