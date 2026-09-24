// Shared by the Home reveal and departure. paper_edge.gdshaderinc comes first.
// Light exposed paper beneath the blue face, with independently torn contours.
uniform vec4 home_fiber_color : source_color = vec4(0.80, 0.85, 0.98, 1.0);

// x/w: blue-to-fiber contours; y/z: fiber-to-opening contours.
// The seeds stay fixed as the bases move, so the paper does not crawl or stretch.
vec4 home_torn_blue_edges(float x, float unit, vec2 bases) {
	float u = x / unit;
	float top_inner = bases.x + (torn_edge(u / 8.0) - 0.5) * 2.4 * unit;
	float bottom_inner = bases.y + (torn_edge(u / 9.0 + 83.0) - 0.5) * 2.4 * unit;
	float top_outer = bases.x + (5.5
		+ (torn_edge(u / 15.0 + 29.0) - 0.5) * 3.0
		+ (torn_edge(u / 3.5 + 147.0) - 0.5) * 1.5) * unit;
	float bottom_outer = bases.y - (5.5
		+ (torn_edge(u / 17.0 + 97.0) - 0.5) * 3.0
		+ (torn_edge(u / 3.8 + 211.0) - 0.5) * 1.5) * unit;
	// Keep the blue silhouettes fixed; reduce each local rim width by 25%.
	top_outer = mix(top_inner, top_outer, 0.75);
	bottom_outer = mix(bottom_inner, bottom_outer, 0.75);
	return vec4(top_inner, top_outer, bottom_outer, bottom_inner);
}

// Coverage within the opening between x/w; its outer boundaries are torn too.
float home_torn_fiber_mask(float y, vec4 edges, float aa) {
	float upper = 1.0 - smoothstep(edges.y - aa, edges.y + aa, y);
	float lower = smoothstep(edges.z - aa, edges.z + aa, y);
	return max(upper, lower);
}

// A clean, flat paper color: no fiber noise or darkening at the blue face.
// Keep the shared signature so Home and departure use the same appearance.
vec3 home_torn_fiber_rgb(vec2 pixel, vec4 edges, float unit) {
	return home_fiber_color.rgb;
}

float home_torn_fiber_shadow(float y, vec4 edges, float unit) {
	// Shadows fall only into the opening, never onto the blue faces or rims.
	if (y < edges.y || y > edges.z) {
		return 0.0;
	}
	float upper_distance = y - edges.y;
	float lower_distance = edges.z - y;
	// Shift the upper cast shadow down, with a short, crisp falloff.
	float upper_offset = 1.5 * unit;
	float upper = 0.15 * (1.0 - smoothstep(upper_offset,
		upper_offset + 0.85 * unit, upper_distance));
	// Light comes from above: tuck the lower shadow core beneath its rim.
	// Only a short, faint falloff remains visible above the lower piece.
	float lower = 0.08 * (1.0 - smoothstep(-0.45 * unit, 0.65 * unit, lower_distance));
	return max(upper, lower);
}
