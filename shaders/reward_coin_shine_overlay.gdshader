shader_type canvas_item;
render_mode unshaded, blend_add;

uniform float shine_progress = -0.32;
uniform float shine_width = 0.16;
uniform float shine_strength = 1.0;
uniform float aspect_ratio = 1.0;

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	float brightness = dot(base.rgb, vec3(0.299, 0.587, 0.114));
	float yellow_mask = smoothstep(0.66, 0.90, base.r)
		* smoothstep(0.40, 0.74, base.g)
		* (1.0 - smoothstep(0.38, 0.72, base.b));
	float bright_mask = smoothstep(0.72, 0.94, brightness);
	float coin_mask = max(yellow_mask, bright_mask) * base.a;
	float diagonal = UV.x + (1.0 - UV.y) * aspect_ratio;
	float distance_to_shine = abs(diagonal - shine_progress);
	// A soft halo makes the motion readable on already bright yellow artwork,
	// while the narrow core produces the crisp sparkle visible on the chest art.
	float halo = 1.0 - smoothstep(shine_width * 0.30, shine_width, distance_to_shine);
	float core = 1.0 - smoothstep(shine_width * 0.06, shine_width * 0.28, distance_to_shine);
	float alpha = (halo * 0.58 + core * 0.72) * shine_strength * coin_mask;
	COLOR = vec4(vec3(1.0), clamp(alpha, 0.0, 1.0));
}
