shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 1.0;
uniform float feather : hint_range(0.0, 0.1) = 0.025;
uniform int reveal_mode = 0;

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float coordinate = 0.0;

	if (reveal_mode == 0) {
		// Draw the correct-letter circle from the 12 o'clock point clockwise.
		// atan(x, -y) uses the top direction as zero despite screen Y growing down.
		vec2 centered_uv = UV - vec2(0.5);
		float angle_from_top_clockwise = atan(centered_uv.x, -centered_uv.y);
		coordinate = mod(angle_from_top_clockwise + 6.28318530718, 6.28318530718) / 6.28318530718;
	} else {
		// Draw the slash from its upper-right end down to its lower-left end.
		coordinate = clamp(((1.0 - UV.x) + UV.y) * 0.5, 0.0, 1.0);
	}

	float reveal = 1.0 - smoothstep(progress, progress + feather, coordinate);
	if (progress >= 0.999) {
		reveal = 1.0;
	}
	COLOR = source * reveal;
}
