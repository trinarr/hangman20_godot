shader_type canvas_item;
render_mode blend_mix;

uniform vec4 color_mult        = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 color_offset_255  = vec4(0.0, 0.0, 0.0, 0.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec4 flash = tex * color_mult + (color_offset_255 / 255.0);
	COLOR = clamp(flash, vec4(0.0), vec4(1.0));
}