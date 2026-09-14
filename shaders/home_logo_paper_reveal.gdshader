shader_type canvas_item;
render_mode unshaded;

uniform sampler2D logo_texture : source_color, filter_linear, repeat_disable;
uniform sampler2D title_texture : source_color, filter_linear, repeat_disable;
uniform bool title_chroma_key = false;
uniform sampler2D paper_texture : source_color, filter_linear, repeat_disable;
uniform sampler2D backside_texture : source_color, filter_linear, repeat_disable;
uniform vec2 canvas_size = vec2(480.0, 800.0);
uniform vec4 logo_rect = vec4(87.936, 142.8, 304.128, 304.128);
uniform float reveal_progress : hint_range(0.0, 1.0) = 0.0;
uniform float shine_progress = -0.30;
uniform float badge_alpha : hint_range(0.0, 1.0) = 0.0;
uniform float badge_scale = 0.65;
// Match the blue outline of the original torn-paper logo. Width is in stage pixels.
uniform vec4 tear_outline_color : source_color = vec4(0.2353, 0.3059, 0.6235, 1.0);
uniform float tear_outline_width : hint_range(0.0, 5.0) = 2.0;

#include "res://shaders/paper_edge.gdshaderinc"

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
		}
	}
	return ink;
}

void fragment() {
	vec2 pixel = UV * canvas_size;
	float unit = max(0.01, logo_rect.z / 304.128);
	// Match the original paper body, excluding the badge projecting above it.
	// Its 375 source pixels correspond to about 91 stage pixels, not 131.
	float top = logo_rect.y + logo_rect.w * (490.0 / 1254.0);
	float bottom = logo_rect.y + logo_rect.w * (865.0 / 1254.0);
	float edge_x = pixel.x / unit;
	top += (torn_edge(edge_x / 8.0) - 0.5) * 2.4 * unit;
	bottom += (torn_edge(edge_x / 9.0 + 83.0) - 0.5) * 2.4 * unit;
	float aa = max(0.65, fwidth(pixel.y));
	float sheet_mask = smoothstep(top - aa, top + aa, pixel.y)
		* (1.0 - smoothstep(bottom - aa, bottom + aa, pixel.y));
	vec4 layer = vec4(0.0);
	vec2 logo_uv = (pixel - logo_rect.xy) / logo_rect.zw;

	// Both faces meet at the same antialiased contact line.
	float detached_width = 190.0 * unit * reveal_progress;
	float front = mix(-3.0 * unit, canvas_size.x + 12.0 * unit, reveal_progress);
	if (reveal_progress > 0.0 && reveal_progress < 1.0) {
		front += (torn_edge(pixel.y / (6.0 * unit) + 139.0) - 0.5) * 1.5 * unit;
	}
	float exposed = 1.0 - smoothstep(front - aa, front + aa, pixel.x);

	if (sheet_mask > 0.0 && exposed > 0.0 && reveal_progress > 0.0) {
		float band_y = clamp((pixel.y - top) / (bottom - top), 0.0, 1.0);
		vec3 paper = texture(paper_texture, vec2(
			mix(0.05, 0.95, pixel.x / canvas_size.x), mix(0.12, 0.82, band_y)
		)).rgb;
		vec2 grid_pos = pixel / (15.0 * unit);
		vec2 grid_distance = abs(fract(grid_pos + 0.5) - 0.5) * (15.0 * unit);
		float grid = 1.0 - smoothstep(0.30 * unit, 0.80 * unit,
			min(grid_distance.x, grid_distance.y));
		paper = mix(paper, vec3(0.61, 0.66, 0.85), grid * 0.40);
		// The upper lip casts inward; the lower edge has an outline, not an inner shadow.
		float outline_width = tear_outline_width * unit;
		float upper_lip = max(0.0, pixel.y - top - outline_width);
		paper *= 1.0 - 0.17 * (1.0 - smoothstep(0.0, 3.0 * unit, upper_lip));

		vec4 ink = sample_title(logo_uv);
		ink.a *= 1.0 - badge_region(logo_uv);
		vec3 result = mix(paper, ink.rgb, ink.a);

		float shadow = (1.0 - smoothstep(0.0, 9.0 * unit, front - pixel.x)) * 0.24;
		result *= 1.0 - shadow * min(1.0, reveal_progress * 10.0);
		// Only the white face has blue torn edges; they end at the contact line.
		float edge_distance = min(pixel.y - top, bottom - pixel.y);
		float outline = 1.0 - smoothstep(outline_width - aa, outline_width + aa, edge_distance);
		result = mix(result, tear_outline_color.rgb, outline * tear_outline_color.a);
		layer = vec4(result, sheet_mask * exposed);
	}

	// Keep most of the detached face flat. Only its final 35% widens gently,
	// reaching 7% extra height at the free edge without a visible corner.
	if (detached_width > 0.1 && reveal_progress < 1.0 && pixel.x > front - aa
			&& pixel.x < front + detached_width + aa) {
		float detached_u = clamp((pixel.x - front) / detached_width, 0.0, 1.0);
		float flare = (bottom - top) * 0.035 * smoothstep(0.65, 1.0, detached_u);
		float detached_top = top - flare;
		float detached_bottom = bottom + flare;
		float detached_mask = smoothstep(detached_top - aa, detached_top + aa, pixel.y)
			* (1.0 - smoothstep(detached_bottom - aa, detached_bottom + aa, pixel.y))
			* (1.0 - exposed)
			* (1.0 - smoothstep(front + detached_width - aa, front + detached_width + aa, pixel.x));
		if (detached_mask > 0.0) {
			float band_y = clamp((pixel.y - detached_top) / (detached_bottom - detached_top), 0.0, 1.0);
			vec3 backside = texture(backside_texture, vec2(detached_u, mix(0.10, 0.84, band_y))).rgb;
			// Complementary coverage prevents a transparent hairline at the join.
			float alpha = layer.a + detached_mask;
			layer = vec4((layer.rgb * layer.a + backside * detached_mask) / max(0.0001, alpha), alpha);
		}
	}

	// The badge is independent of both the paper mask and the moving fold.
	// Restore its original atlas position, overlapping the paper's upper edge.
	if (reveal_progress >= 1.0 && badge_alpha > 0.0) {
		vec2 pivot = vec2(980.0, 585.0) / 1254.0;
		vec2 badge_uv = pivot + (logo_uv - pivot) / max(0.01, badge_scale);
		vec4 badge = sample_ink(badge_uv);
		// Sweep in badge-local coordinates; the main lettering never receives shine.
		vec2 badge_local = (badge_uv * 1254.0 - vec2(720.0, 350.0)) / vec2(490.0, 245.0);
		float diagonal = badge_local.x + badge_local.y * 0.28;
		float shine = (1.0 - smoothstep(0.0, 0.12, abs(diagonal - shine_progress))) * 0.46;
		badge.rgb = mix(badge.rgb, vec3(1.0), shine * badge.a);
		badge.a *= badge_region(badge_uv) * badge_alpha;
		float combined_alpha = badge.a + layer.a * (1.0 - badge.a);
		vec3 combined_rgb = badge.rgb * badge.a + layer.rgb * layer.a * (1.0 - badge.a);
		layer = vec4(combined_rgb / max(0.0001, combined_alpha), combined_alpha);
	}
	COLOR = layer;
}
