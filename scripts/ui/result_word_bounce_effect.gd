extends RichTextEffect

var bbcode: String = "result_word_bounce"

var grow_duration: float = 0.068
var settle_duration: float = 0.072
var gap_duration: float = 0.0094
var font_size: int = 34
var peak_scale: float = 1.24
var neighbor_strength: float = 0.42
var neighbor_radius: int = 2
var animation_indices: Dictionary = {}

func configure(
	text: String,
	configured_grow_duration: float,
	configured_settle_duration: float,
	configured_gap_duration: float,
	configured_font_size: int,
	configured_peak_scale: float,
	configured_neighbor_strength: float,
	configured_neighbor_radius: int
) -> int:
	grow_duration = maxf(configured_grow_duration, 0.001)
	settle_duration = maxf(configured_settle_duration, 0.001)
	gap_duration = maxf(configured_gap_duration, 0.0)
	font_size = maxi(configured_font_size, 1)
	peak_scale = maxf(configured_peak_scale, 1.0)
	neighbor_strength = clampf(configured_neighbor_strength, 0.0, 1.0)
	neighbor_radius = maxi(configured_neighbor_radius, 0)
	animation_indices.clear()

	var next_animation_index: int = 0
	for character_index in range(text.length()):
		var character: String = text.substr(character_index, 1)
		if character == " " or character == "-" or character == "—":
			continue
		animation_indices[character_index] = next_animation_index
		next_animation_index += 1
	return next_animation_index

func animation_duration() -> float:
	if animation_indices.is_empty():
		return 0.0
	return float(animation_indices.size() - 1) * _letter_start_step() + grow_duration + settle_duration

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var animation_index: int = int(animation_indices.get(char_fx.relative_index, -1))
	if animation_index < 0:
		return true

	# Every pulse affects its own glyph at full strength and nearby glyphs with
	# exponential falloff. Successive pulses begin while the previous one is
	# settling, so their overlapping envelopes read as one travelling wave.
	var strongest_scale_delta: float = 0.0
	var first_pulse_index: int = maxi(animation_index - neighbor_radius, 0)
	var last_pulse_index: int = mini(
		animation_index + neighbor_radius,
		animation_indices.size() - 1
	)
	for pulse_index in range(first_pulse_index, last_pulse_index + 1):
		var pulse_start_time: float = float(pulse_index) * _letter_start_step()
		var pulse_scale_delta: float = _pulse_scale_delta(
			char_fx.elapsed_time - pulse_start_time
		)
		var neighbor_distance: int = absi(animation_index - pulse_index)
		var falloff: float = pow(neighbor_strength, float(neighbor_distance))
		var weighted_scale_delta: float = pulse_scale_delta * falloff
		if absf(weighted_scale_delta) > absf(strongest_scale_delta):
			strongest_scale_delta = weighted_scale_delta

	var glyph_scale: float = 1.0 + strongest_scale_delta

	if !is_equal_approx(glyph_scale, 1.0):
		var text_server: TextServer = TextServerManager.get_primary_interface()
		var glyph_advance: Vector2 = text_server.font_get_glyph_advance(
			char_fx.font,
			font_size,
			char_fx.glyph_index
		)
		var ascent: float = text_server.font_get_ascent(char_fx.font, font_size)
		var descent: float = text_server.font_get_descent(char_fx.font, font_size)
		var glyph_center := Vector2(
			glyph_advance.x * 0.5,
			(descent - ascent) * 0.5
		)
		char_fx.transform = char_fx.transform.scaled_local(
			Vector2(glyph_scale, glyph_scale)
		)
		char_fx.offset += glyph_center * (1.0 - glyph_scale)
	return true

func _letter_start_step() -> float:
	return grow_duration + gap_duration

func _pulse_scale_delta(local_time: float) -> float:
	var peak_delta: float = peak_scale - 1.0
	if local_time >= 0.0 and local_time < grow_duration:
		var grow_progress: float = clampf(local_time / grow_duration, 0.0, 1.0)
		var eased_grow: float = 1.0 - pow(1.0 - grow_progress, 2.0)
		return lerpf(0.0, peak_delta, eased_grow)
	if local_time >= grow_duration and local_time < grow_duration + settle_duration:
		var settle_progress: float = clampf(
			(local_time - grow_duration) / settle_duration,
			0.0,
			1.0
		)
		var eased_settle: float = _ease_out_back(settle_progress)
		return lerpf(peak_delta, 0.0, eased_settle)
	return 0.0

func _ease_out_back(value: float) -> float:
	const OVERSHOOT: float = 1.70158
	const OVERSHOOT_PLUS_ONE: float = OVERSHOOT + 1.0
	var shifted: float = value - 1.0
	return 1.0 + OVERSHOOT_PLUS_ONE * pow(shifted, 3.0) + OVERSHOOT * pow(shifted, 2.0)
