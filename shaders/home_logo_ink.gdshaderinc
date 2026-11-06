// Shared settled lettering and badge sampling for Home and startup.
uniform sampler2D logo_texture : source_color, filter_linear, repeat_disable;
uniform sampler2D title_texture : source_color, filter_linear, repeat_disable;
uniform bool title_chroma_key = false;
// source_color keeps the reference palette consistent in Mobile and Compatibility.
uniform vec4 localized_pencil_color : source_color = vec4(0.004, 0.255, 0.847, 1.0);
uniform vec4 original_pencil_color : source_color = vec4(0.008, 0.208, 0.667, 1.0);
uniform vec4 localized_shadow_color : source_color = vec4(0.792, 0.902, 0.992, 1.0);
uniform vec4 original_shadow_color : source_color = vec4(0.604, 0.776, 0.988, 1.0);
// Red/green encode the two thresholds, converted along with the texture colors.
uniform vec4 localized_shadow_range : source_color = vec4(0.32, 0.65, 0.0, 1.0);

// Split the existing foreground atlas through its transparent gap. The sloped
// boundary follows the tilted badge without cutting the M or the right-hand N.
float badge_region(vec2 uv) {
	vec2 source = uv * 1254.0;
	float lower_edge = source.x < 820.0 ? 550.0 : 676.0 - source.x * 0.105;
	return step(720.0, source.x) * (1.0 - step(lower_edge, source.y));
}

vec4 sample_ink(vec2 uv) {
	vec4 ink = vec4(0.0);
	if (all(greaterThanEqual(uv, vec2(0.0))) && all(lessThanEqual(uv, vec2(1.0)))) {
		ink = texture(logo_texture, uv);
	}
	return ink;
}

// Detect the light shadow beside the green matte. The source has a narrow blue
// fringe there; brightness alone mistakes it for the dark face of a letter.
vec2 localized_edge_sample(vec2 uv) {
	vec3 color = texture(title_texture, uv).rgb;
	float light_shadow = smoothstep(localized_shadow_range.r, localized_shadow_range.g, color.r)
		* (1.0 - smoothstep(0.0, 0.04, color.r - color.b));
	float matte = smoothstep(0.40, 0.65, color.g - max(color.r, color.b));
	return vec2(light_shadow, matte);
}

// Localized lettering uses the same atlas coordinates. Keep the original badge
// texture so its silhouette, bounce pivot and shine are identical in both locales.
vec4 sample_title(vec2 uv) {
	vec4 ink = vec4(0.0);
	if (all(greaterThanEqual(uv, vec2(0.0))) && all(lessThanEqual(uv, vec2(1.0)))) {
		ink = texture(title_texture, uv);
		if (title_chroma_key) {
			// Remove the green key before compositing, including letter counters.
			float key = ink.g - max(ink.r, ink.b);
			ink.a *= 1.0 - smoothstep(0.06, 0.40, key);
			ink.g = mix(ink.g, min(ink.g, max(ink.r, ink.b)), smoothstep(0.0, 0.12, key));
			// Discard the localized orange stroke. The original underline is shared
			// below, so translation cannot change its shape, texture or thickness.
			float warm_ink = smoothstep(0.015, 0.08, ink.r - ink.b);
			ink.a *= 1.0 - warm_ink;

			// Match the English atlas's blue pencil and pale-blue offset shadow.
			// Separate the light shadow from the lettering before correcting them;
			// a global tint would leave the nearly-white rim and oversaturated ink.
			float shadow_weight = smoothstep(localized_shadow_range.r, localized_shadow_range.g, ink.r);
			vec3 pencil = clamp(
				original_pencil_color.rgb
					+ (ink.rgb - localized_pencil_color.rgb) * vec3(1.10, 0.55, 0.55),
				original_pencil_color.rgb * 0.75,
				mix(original_pencil_color.rgb, original_shadow_color.rgb, 0.55)
			);
			vec3 shadow = clamp(
				original_shadow_color.rgb
					+ (ink.rgb - localized_shadow_color.rgb) * vec3(0.35, 0.50, 0.25),
				original_shadow_color.rgb * 0.85, vec3(1.0)
			);
			ink.rgb = mix(pencil, shadow, shadow_weight);
			if (ink.a > 0.0 && shadow_weight < 1.0) {
				vec2 radius = vec2(3.0) / vec2(textureSize(title_texture, 0));
				vec2 nearby = max(
					max(localized_edge_sample(uv + vec2(radius.x, 0.0)),
						localized_edge_sample(uv - vec2(radius.x, 0.0))),
					max(localized_edge_sample(uv + vec2(0.0, radius.y)),
						localized_edge_sample(uv - vec2(0.0, radius.y)))
				);
				// Recolor only the outer shadow fringe. Keep its antialiased alpha,
				// the letter silhouette and the pencil texture unchanged.
				ink.rgb = mix(ink.rgb, original_shadow_color.rgb, nearby.x * nearby.y);
				shadow_weight = max(shadow_weight, nearby.x * nearby.y);
			}

			if (ink.a > 0.0 && shadow_weight > 0.0) {
				// Match the English shadow's smaller downward/leftward overhang.
				// Intersect only the shadow with an inset silhouette: never move or
				// shrink the lettering. Atlas pixels scale with the existing logo.
				vec2 inset_uv = uv + vec2(-2.0, 3.0) / vec2(textureSize(title_texture, 0));
				vec4 inset = texture(title_texture, inset_uv);
				float matte = inset.g - max(inset.r, inset.b);
				float coverage = inset.a * (1.0 - smoothstep(0.06, 0.40, matte));
				coverage *= 1.0 - smoothstep(0.015, 0.08, inset.r - inset.b);
				float trim_weight = shadow_weight * smoothstep(
					original_shadow_color.r * 0.50, original_shadow_color.r * 0.80, ink.r
				);
				ink.a *= mix(1.0, coverage, trim_weight);
			}

			if (uv.y > 0.60) {
				vec4 underline = sample_ink(uv);
				underline.a *= smoothstep(0.015, 0.08, underline.r - underline.b);
				float alpha = underline.a + ink.a * (1.0 - underline.a);
				ink = vec4((underline.rgb * underline.a
					+ ink.rgb * ink.a * (1.0 - underline.a)) / max(alpha, 0.0001), alpha);
			}
		}
	}
	return ink;
}

