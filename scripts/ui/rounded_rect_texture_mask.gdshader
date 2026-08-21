shader_type canvas_item;

uniform vec2 source_size = vec2(1.0, 1.0);
uniform vec4 mask_rect = vec4(0.0, 0.0, 1.0, 1.0);
uniform float corner_radius = 0.0;
uniform float opacity = 1.0;

void fragment() {
	vec2 point = UV * source_size;
	vec2 rect_center = mask_rect.xy + mask_rect.zw * 0.5;
	vec2 half_size = mask_rect.zw * 0.5;
	float radius = min(corner_radius, min(half_size.x, half_size.y));
	vec2 rounded_distance = abs(point - rect_center) - (half_size - vec2(radius));
	float signed_distance = length(max(rounded_distance, vec2(0.0)))
		+ min(max(rounded_distance.x, rounded_distance.y), 0.0)
		- radius;
	float mask_alpha = 1.0 - smoothstep(-1.0, 1.0, signed_distance);
	vec4 texture_color = texture(TEXTURE, UV);
	texture_color.a *= mask_alpha * opacity;
	COLOR = texture_color;
}
