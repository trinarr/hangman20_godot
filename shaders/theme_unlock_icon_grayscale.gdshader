shader_type canvas_item;
render_mode unshaded;
#include "res://shaders/colored_icon_outline.gdshaderinc"

uniform float saturation : hint_range(0.0, 1.0) = 0.0;
uniform vec4 shadow_tint : source_color = vec4(0.25, 0.43, 0.92, 1.0);
uniform vec4 highlight_tint : source_color = vec4(0.62, 0.82, 1.0, 1.0);
varying vec4 canvas_modulate;

void vertex() {
	canvas_modulate = COLOR;
	VERTEX = icon_outline_vertex(VERTEX, UV, MODEL_MATRIX, CANVAS_MATRIX);
}

void fragment() {
	vec4 source = outlined_icon(TEXTURE, UV);
	float luminance = dot(source.rgb, vec3(0.299, 0.587, 0.114));
	vec3 neutral = vec3(luminance);
	vec3 tinted = mix(shadow_tint.rgb, highlight_tint.rgb, luminance);
	vec3 locked = mix(neutral, tinted, 0.42);
	COLOR = vec4(mix(locked, source.rgb, saturation), source.a) * canvas_modulate;
}
