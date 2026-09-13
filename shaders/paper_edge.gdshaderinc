// Integer noise avoids sin() precision seams on mobile GPUs. Adjacent cells
// share identical endpoints; cubic interpolation also joins their slopes.
float hash(float n) {
	uint h = uint(int(n));
	h = (h ^ (h >> 16u)) * 2146121005u;
	h = (h ^ (h >> 15u)) * 2221713035u;
	h = h ^ (h >> 16u);
	return float(h & 16777215u) / 16777216.0;
}

float torn_edge(float x) {
	float cell = floor(x);
	float t = fract(x);
	t = t * t * (3.0 - 2.0 * t);
	return mix(hash(cell), hash(cell + 1.0), t);
}

// The front and reverse faces use the same stage-space edge coordinates.
vec2 paper_edges(float x, float height) {
	return vec2(
		2.0 + (torn_edge(x / 8.0) - 0.5) * 2.4,
		height - 3.0 + (torn_edge(x / 9.0 + 83.0) - 0.5) * 4.0
			+ (torn_edge(x / 3.5 + 157.0) - 0.5) * 0.8
	);
}
