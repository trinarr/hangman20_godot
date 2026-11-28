float whatman_hash(vec2 point) {
	vec3 value = fract(point.xyx * 0.1031);
	value += dot(value, value.yzx + 33.33);
	return fract((value.x + value.y) * value.z);
}

float whatman_noise(vec2 point) {
	vec2 cell = floor(point);
	vec2 weight = fract(point);
	weight = weight * weight * (3.0 - 2.0 * weight);
	return mix(
		mix(whatman_hash(cell), whatman_hash(cell + vec2(1.0, 0.0)), weight.x),
		mix(whatman_hash(cell + vec2(0.0, 1.0)), whatman_hash(cell + vec2(1.0)), weight.x),
		weight.y
	) - 0.5;
}

vec3 whatman_paper_color(vec3 base_color, vec2 pixel, float strength) {
	float fine_grain = whatman_noise(pixel / 1.4);
	float relief = whatman_noise(pixel / 3.1) - whatman_noise((pixel + vec2(0.8, 1.1)) / 3.1);
	float grain = fine_grain * 0.046 + relief * 0.063 + whatman_noise(pixel / 13.0) * 0.016;
	return clamp(base_color + vec3(grain * strength), vec3(0.0), vec3(1.0));
}
