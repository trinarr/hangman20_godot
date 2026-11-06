shader_type canvas_item;
render_mode unshaded;

uniform sampler2D backside_texture : source_color, filter_linear, repeat_disable;
uniform vec2 canvas_size = vec2(480.0, 800.0);
uniform vec4 logo_rect = vec4(87.936, 142.8, 304.128, 304.128);
uniform float reveal_progress : hint_range(0.0, 1.0) = 0.0;
uniform float shine_progress = -0.30;
uniform float badge_alpha : hint_range(0.0, 1.0) = 0.0;
uniform float badge_scale = 0.65;
uniform float foreground_opacity : hint_range(0.0, 1.0) = 1.0;
uniform bool foreground_only = false;
uniform bool reverse_departure = false;
uniform float departure_inset = 0.0;
#include "res://shaders/paper_edge.gdshaderinc"
#include "res://shaders/home_torn_blue_edge.gdshaderinc"
#include "res://shaders/portrait_grid_paper.gdshaderinc"

#include "res://shaders/home_logo_ink.gdshaderinc"

void fragment() {
	vec2 pixel = UV * canvas_size;
	float unit = max(0.01, logo_rect.z / 304.128);
	// Match the original paper body, excluding the badge projecting above it.
	// Its 375 source pixels correspond to about 91 stage pixels, not 131.
	vec2 edge_bases = logo_rect.y + logo_rect.w * vec2(490.0, 865.0) / 1254.0;
	vec4 edges = home_torn_blue_edges(pixel.x, unit, edge_bases);
	float top = edges.x;
	float bottom = edges.w;
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
		// Original Home paper style, shared with the destination page.
		vec3 paper = portrait_grid_paper(pixel);
		paper *= 1.0 - home_torn_fiber_shadow(pixel.y, edges, unit);

		vec4 ink = sample_title(logo_uv);
		ink.a *= (1.0 - badge_region(logo_uv)) * foreground_opacity;
		vec3 result = mix(paper, ink.rgb, reverse_departure ? 0.0 : ink.a);

		float shadow = (1.0 - smoothstep(0.0, 9.0 * unit, front - pixel.x)) * 0.24;
		result *= 1.0 - shadow * min(1.0, reveal_progress * 10.0);
		// Exposed light fibers on both blue faces, with independently ragged borders.
		float fiber = home_torn_fiber_mask(pixel.y, edges, aa);
		result = mix(result, home_torn_fiber_rgb(pixel, edges, unit), fiber);
		layer = foreground_only
			? vec4(ink.rgb, ink.a * sheet_mask * exposed)
			: vec4(result, sheet_mask * exposed);
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

	// The title sits under the closing blue pieces. The badge is composited
	// afterwards, above them. The foreground finishes fading before reopening.
	if (foreground_only) {
		float inset = departure_inset * unit;
		vec4 moving_edges = edges + vec4(inset, inset, -inset, -inset);
		float visible_title = smoothstep(moving_edges.x - aa, moving_edges.x + aa, pixel.y)
			* (1.0 - smoothstep(moving_edges.w - aa, moving_edges.w + aa, pixel.y));
		// The title is below the fiber rims as well as the blue faces; the badge
		// is composited after this mask and stays above both, as before.
		layer.a *= visible_title * (1.0 - home_torn_fiber_mask(pixel.y, moving_edges, aa));
	}

	// On closing, fade the lettering independently of the moving peel edge.
	if (reverse_departure) {
		vec4 title = sample_title(logo_uv);
		title.a *= (1.0 - badge_region(logo_uv)) * foreground_opacity;
		float alpha = title.a + layer.a * (1.0 - title.a);
		layer = vec4((title.rgb * title.a + layer.rgb * layer.a * (1.0 - title.a))
			/ max(0.0001, alpha), alpha);
	}

	// The badge is independent of both the paper mask and the moving fold.
	// Restore its original atlas position, overlapping the paper's upper edge.
	if ((reveal_progress >= 1.0 || reverse_departure) && badge_alpha > 0.0) {
		vec2 pivot = vec2(980.0, 585.0) / 1254.0;
		vec2 badge_uv = pivot + (logo_uv - pivot) / max(0.01, badge_scale);
		vec4 badge = sample_ink(badge_uv);
		// Sweep in badge-local coordinates; the main lettering never receives shine.
		vec2 badge_local = (badge_uv * 1254.0 - vec2(720.0, 350.0)) / vec2(490.0, 245.0);
		float diagonal = badge_local.x + badge_local.y * 0.28;
		float shine = (1.0 - smoothstep(0.0, 0.12, abs(diagonal - shine_progress))) * 0.46;
		badge.rgb = mix(badge.rgb, vec3(1.0), shine * badge.a);
		badge.a *= badge_region(badge_uv) * badge_alpha * foreground_opacity;
		float combined_alpha = badge.a + layer.a * (1.0 - badge.a);
		vec3 combined_rgb = badge.rgb * badge.a + layer.rgb * layer.a * (1.0 - badge.a);
		layer = vec4(combined_rgb / max(0.0001, combined_alpha), combined_alpha);
	}
	COLOR = layer;
}
