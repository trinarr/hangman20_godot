// Shared wordmark sampling for Home and startup.
uniform sampler2D logo_texture : source_color, filter_linear, repeat_disable;

vec4 sample_title(vec2 uv) {
	// Scale the wordmark about its center, independently of the paper.
	vec2 center = vec2(0.5, 677.5 / 1254.0);
	uv = center + (uv - center) / 1.089;
	if (all(greaterThanEqual(uv, vec2(0.0))) && all(lessThanEqual(uv, vec2(1.0)))) {
		return texture(logo_texture, uv);
	}
	return vec4(0.0);
}
