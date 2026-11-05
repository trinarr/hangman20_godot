shader_type canvas_item;
render_mode unshaded;
uniform sampler2D source_tex : filter_linear, repeat_disable;
uniform vec4 shadow_color : source_color = vec4(0.05, 0.08, 0.24, 0.72);
uniform bool colored_outline = false;
uniform float outline_pixels = 2.0;
uniform vec2 icon_size = vec2(1.0);
uniform vec2 fitted_size = vec2(1.0);
uniform vec2 padding = vec2(0.0);
uniform vec2 shadow_extent = vec2(0.0);
uniform vec2 layer_1 = vec2(0.0);
uniform vec2 layer_2 = vec2(0.0);
uniform vec2 layer_3 = vec2(0.0);
uniform vec2 layer_4 = vec2(0.0);
uniform bool use_mask = false;
uniform sampler2D mask_tex : filter_linear, repeat_disable;
uniform vec2 mask_size = vec2(1.0);
uniform vec2 pixel_scale = vec2(1.0);
varying float opacity;
void vertex() {
	opacity = COLOR.a;
	VERTEX += (UV * 2.0 - 1.0) * padding + UV * shadow_extent;
}
float source_alpha(vec2 uv) {
	if (any(lessThan(uv, vec2(0.0))) || any(greaterThan(uv, vec2(1.0)))) { return 0.0; }
	return texture(source_tex, uv).a;
}
float silhouette(vec2 q) {
	if (use_mask) {
		vec2 uv = (q * pixel_scale + vec2(outline_pixels + 1.0)) * 2.0 / mask_size;
		if (any(lessThan(uv, vec2(0.0))) || any(greaterThan(uv, vec2(1.0)))) { return 0.0; }
		return texture(mask_tex, uv).a;
	}
	vec2 uv = q / fitted_size;
	float alpha = source_alpha(uv);
	if (colored_outline) {
		// Budget/oversize fallback: preserve the silhouette without another texture.
		vec2 dx = dFdx(uv) * outline_pixels;
		vec2 dy = dFdy(uv) * outline_pixels;
		float dilation = alpha;
		for (int i = 0; i < 16; i++) {
			float angle = float(i) * 0.3926990817;
			dilation = max(dilation, source_alpha(uv + cos(angle) * dx + sin(angle) * dy));
		}
		alpha += dilation * (1.0 - alpha);
	}
	return alpha;
}
float layer_alpha(vec2 q) {
	float alpha = silhouette(q);
	return alpha * alpha * opacity * shadow_color.a;
}
void fragment() {
	vec2 q = UV * (icon_size + padding * 2.0 + shadow_extent) - padding - (icon_size - fitted_size) * 0.5;
	float remaining = 1.0 - layer_alpha(q - layer_1);
	remaining *= 1.0 - layer_alpha(q - layer_2);
	remaining *= 1.0 - layer_alpha(q - layer_3);
	remaining *= 1.0 - layer_alpha(q - layer_4);
	COLOR = vec4(shadow_color.rgb, 1.0 - remaining);
}
