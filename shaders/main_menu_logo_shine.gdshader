shader_type canvas_item;

uniform float shine_progress = -0.30;
uniform float shine_width = 0.12;
uniform float shine_strength = 0.46;

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	float diagonal = UV.x + UV.y * 0.28;
	float distance_to_shine = abs(diagonal - shine_progress);
	float band = 1.0 - smoothstep(0.0, shine_width, distance_to_shine);
	float shine = band * shine_strength * base.a;
	COLOR = vec4(mix(base.rgb, vec3(1.0), shine), base.a);
}
