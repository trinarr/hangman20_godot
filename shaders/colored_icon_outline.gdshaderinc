// Width is measured in render-target pixels, independently of icon/tween scale.
uniform bool colored_outline = false;
uniform float outline_pixels : hint_range(0.0, 12.0) = 2.0;
uniform vec4 outline_color : source_color = vec4(0.071, 0.102, 0.322, 1.0);

vec2 icon_outline_vertex(vec2 point, vec2 uv, mat4 model, mat4 canvas) {
	if (!colored_outline) { return point; }
	mat4 transform = canvas * model;
	vec2 scale = vec2(length(transform[0].xy), length(transform[1].xy));
	return point + (uv * 2.0 - 1.0) * (outline_pixels + 1.0) / max(scale, vec2(0.001));
}

vec4 icon_sample(sampler2D tex, vec2 uv) {
	if (any(lessThan(uv, vec2(0.0))) || any(greaterThan(uv, vec2(1.0)))) {
		return vec4(0.0);
	}
	return texture(tex, uv);
}

vec4 outlined_icon(sampler2D tex, vec2 uv) {
	if (!colored_outline) { return texture(tex, uv); }
	vec2 inset = (outline_pixels + 1.0) * vec2(length(vec2(dFdx(uv.x), dFdy(uv.x))), length(vec2(dFdx(uv.y), dFdy(uv.y))));
	vec2 source_uv = (uv - inset) / max(vec2(1.0) - 2.0 * inset, vec2(0.001));
	vec4 source = icon_sample(tex, source_uv);
	vec2 dx = dFdx(source_uv) * outline_pixels;
	vec2 dy = dFdy(source_uv) * outline_pixels;
	float dilation = source.a;
	for (int i = 0; i < 16; i++) {
		float angle = float(i) * 0.3926990817;
		dilation = max(dilation, icon_sample(tex, source_uv + cos(angle) * dx + sin(angle) * dy).a);
	}
	float edge = dilation * outline_color.a * (1.0 - source.a);
	float alpha = source.a + edge;
	return vec4((source.rgb * source.a + outline_color.rgb * edge) / max(alpha, 0.0001), alpha);
}
