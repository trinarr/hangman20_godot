// Include inside fragment(); produces icon_color without passing TEXTURE as a sampler.
vec4 icon_color;
if (!colored_outline) {
	icon_color = texture(TEXTURE, UV);
} else {
	vec2 inset = (outline_pixels + 1.0) * vec2(length(vec2(dFdx(UV.x), dFdy(UV.x))), length(vec2(dFdx(UV.y), dFdy(UV.y))));
	vec2 source_uv = (UV - inset) / max(vec2(1.0) - 2.0 * inset, vec2(0.001));
	vec4 source = vec4(0.0);
	if (!any(lessThan(source_uv, vec2(0.0))) && !any(greaterThan(source_uv, vec2(1.0)))) {
		source = texture(TEXTURE, source_uv);
	}
	vec2 dx = dFdx(source_uv) * outline_pixels;
	vec2 dy = dFdy(source_uv) * outline_pixels;
	float dilation = source.a;
	for (int i = 0; i < 16; i++) {
		float angle = float(i) * 0.3926990817;
		vec2 sample_uv = source_uv + cos(angle) * dx + sin(angle) * dy;
		vec4 sample_color = vec4(0.0);
		if (!any(lessThan(sample_uv, vec2(0.0))) && !any(greaterThan(sample_uv, vec2(1.0)))) {
			sample_color = texture(TEXTURE, sample_uv);
		}
		dilation = max(dilation, sample_color.a);
	}
	float edge = dilation * outline_color.a * (1.0 - source.a);
	float alpha = source.a + edge;
	icon_color = vec4((source.rgb * source.a + outline_color.rgb * edge) / max(alpha, 0.0001), alpha);
}
