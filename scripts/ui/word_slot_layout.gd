extends RefCounted

# Shared geometry for the gameplay answer and native two-player input.
# All measurements use the supplied characters, never the current game session.
const UI_FONTS: GDScript = preload("res://scripts/ui/ui_fonts.gd")
const BASE_GAP: float = 10.0
const UNDERLINE_MAX_WIDTH: float = 26.6
const UNDERLINE_GAP: float = 12.0

var _letters: PackedStringArray

func _init(letters: PackedStringArray) -> void:
	_letters = letters.duplicate()

static func display_text(text: String) -> String:
	return text.replace("—", "−").replace("-", "−")

func _glyph_width(
	font: Font,
	letter: String,
	font_size: int
) -> float:
	# Empty input previews occupy a full mark without displaying a glyph.
	if letter.is_empty():
		return UNDERLINE_MAX_WIDTH
	var display_letter: String = display_text(letter)
	return maxf(
		font.get_string_size(
			display_letter,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			font_size
		).x,
		1.0
	)

func _center_step(
	font: Font,
	font_size: int,
	letter_gap: float
) -> float:
	# Keep every non-space letter center on one shared rhythm, but derive that
	# rhythm from the actual neighboring glyph widths instead of pretending every
	# character is as wide as the widest glyph in the word.
	# Reserve room for both the mark and its preferred separation, even when the
	# actual glyph is narrow. Relax this floor only when fitting reduces tracking.
	var tracking_ratio: float = clampf(letter_gap / BASE_GAP, 0.0, 1.0)
	var required_step: float = maxf(
		1.0,
		(UNDERLINE_MAX_WIDTH + UNDERLINE_GAP)
		* tracking_ratio
	)
	var previous_width: float = -1.0
	for raw_letter in _letters:
		var letter: String = str(raw_letter)
		if letter == " ":
			previous_width = -1.0
			continue
		var glyph_width: float = _glyph_width(
			font,
			letter,
			font_size
		)
		if previous_width >= 0.0:
			required_step = maxf(
				required_step,
				(previous_width + glyph_width) * 0.5 + letter_gap
			)
		previous_width = glyph_width
	return required_step

func _metrics(
	font: Font,
	font_size: int,
	letter_gap: float,
	space_width: float
) -> Dictionary:
	var center_step: float = _center_step(
		font,
		font_size,
		letter_gap
	)
	var item_lefts: Array[float] = []
	var item_widths: Array[float] = []
	var item_centers: Array[float] = []
	var previous_center: float = 0.0
	var previous_right: float = 0.0
	var has_previous_glyph: bool = false
	var pending_space_width: float = 0.0

	for raw_letter in _letters:
		var letter: String = str(raw_letter)
		if letter == " ":
			item_lefts.append(previous_right + pending_space_width)
			item_widths.append(space_width)
			item_centers.append(previous_right + pending_space_width + space_width * 0.5)
			pending_space_width += space_width
			continue

		var glyph_width: float = _glyph_width(
			font,
			letter,
			font_size
		)
		var center_x: float = glyph_width * 0.5
		if has_previous_glyph:
			if pending_space_width > 0.0:
				center_x = (
					previous_right
					+ letter_gap
					+ pending_space_width
					+ letter_gap
					+ glyph_width * 0.5
				)
			else:
				center_x = previous_center + center_step
		elif pending_space_width > 0.0:
			center_x = pending_space_width + glyph_width * 0.5

		var left_x: float = center_x - glyph_width * 0.5
		item_lefts.append(left_x)
		item_widths.append(glyph_width)
		item_centers.append(center_x)
		previous_center = center_x
		previous_right = center_x + glyph_width * 0.5
		has_previous_glyph = true
		pending_space_width = 0.0

	var total_width: float = previous_right + pending_space_width
	return {
		"total_width": total_width,
		"center_step": center_step,
		"lefts": item_lefts,
		"widths": item_widths,
		"centers": item_centers,
	}

func _total_width(
	font: Font,
	font_size: int,
	letter_gap: float,
	space_width: float
) -> float:
	var metrics: Dictionary = _metrics(
		font,
		font_size,
		letter_gap,
		space_width
	)
	return float(metrics.get("total_width", 0.0))

func resolve(available_size: Vector2, font_size: int = 34) -> Dictionary:
	# Use compact tracking for short answers and a distinct blank between words.
	# Measure the complete answer, including hidden letters, so guesses never move
	# the other slots. Long answers can use the full available paper width below.
	var base_space_width: float = 34.0
	var base_gap: float = BASE_GAP
	var effective_font_size: int = maxi(font_size, 1)
	var full_font_width: float = UI_FONTS.ROBOTO_FLEX_GAME_WORD_WIDTH
	var minimum_font_width: float = UI_FONTS.ROBOTO_FLEX_GAME_WORD_MIN_WIDTH
	# Keep full tracking through the first half of the available wdth range. Only
	# after wdth has travelled 50% of the way toward its minimum do both values
	# compress together. With the current 100 -> 25 range this threshold is 62.5.
	var gap_shrink_start_width: float = minimum_font_width + (
		full_font_width - minimum_font_width
	) * 0.5
	var word_font_width: float = full_font_width
	var word_font: Font = UI_FONTS.gameplay_word_font(word_font_width)
	var slot_gap: float = base_gap
	var total_width: float = _total_width(
		word_font,
		effective_font_size,
		slot_gap,
		base_space_width
	)

	if total_width > available_size.x:
		# Stage 1: reduce only wdth down to the 50%-toward-minimum threshold while
		# preserving the authored tracking unchanged.
		var threshold_font: Font = UI_FONTS.gameplay_word_font(gap_shrink_start_width)
		var threshold_total_width: float = _total_width(
			threshold_font,
			effective_font_size,
			base_gap,
			base_space_width
		)
		if threshold_total_width <= available_size.x:
			var lower_width: float = gap_shrink_start_width
			var upper_width: float = full_font_width
			for _iteration: int in range(8):
				var candidate_width: float = (lower_width + upper_width) * 0.5
				var candidate_font: Font = UI_FONTS.gameplay_word_font(candidate_width)
				var candidate_total_width: float = _total_width(
					candidate_font,
					effective_font_size,
					base_gap,
					base_space_width
				)
				if candidate_total_width <= available_size.x:
					lower_width = candidate_width
				else:
					upper_width = candidate_width
			word_font_width = maxf(gap_shrink_start_width, floorf(lower_width))
			word_font = UI_FONTS.gameplay_word_font(word_font_width)
			total_width = _total_width(
				word_font,
				effective_font_size,
				base_gap,
				base_space_width
			)
		else:
			word_font_width = gap_shrink_start_width
			word_font = threshold_font
			total_width = threshold_total_width

	if total_width > available_size.x:
		# Stage 2: from the threshold to minimum wdth, shrink tracking in lockstep.
		# At the threshold gap == base_gap; at minimum wdth gap == 0. Tracking is
		# never allowed to become negative.
		var lower_width: float = minimum_font_width
		var upper_width: float = gap_shrink_start_width
		for _iteration: int in range(8):
			var candidate_width: float = (lower_width + upper_width) * 0.5
			var candidate_progress: float = clampf(
				(candidate_width - minimum_font_width)
				/ maxf(gap_shrink_start_width - minimum_font_width, 0.001),
				0.0,
				1.0
			)
			var candidate_gap: float = base_gap * candidate_progress
			var candidate_font: Font = UI_FONTS.gameplay_word_font(candidate_width)
			var candidate_total_width: float = _total_width(
				candidate_font,
				effective_font_size,
				candidate_gap,
				base_space_width
			)
			if candidate_total_width <= available_size.x:
				lower_width = candidate_width
			else:
				upper_width = candidate_width
		# Round toward the fitting side. Rounding up can exceed the available width
		# and incorrectly trigger the minimum-width/font-size fallback below.
		word_font_width = clampf(
			floorf(lower_width),
			minimum_font_width,
			gap_shrink_start_width
		)
		word_font = UI_FONTS.gameplay_word_font(word_font_width)
		var resolved_progress: float = clampf(
			(word_font_width - minimum_font_width)
			/ maxf(gap_shrink_start_width - minimum_font_width, 0.001),
			0.0,
			1.0
		)
		slot_gap = maxf(0.0, base_gap * resolved_progress)
		total_width = _total_width(
			word_font,
			effective_font_size,
			slot_gap,
			base_space_width
		)

	if total_width > available_size.x:
		# Stage 3: only after wdth is fully condensed and tracking has reached zero
		# may the font size shrink. Keep the minimum conservative so text remains
		# readable while still guaranteeing fit for unusually long catalog entries.
		word_font_width = minimum_font_width
		word_font = UI_FONTS.gameplay_word_font(word_font_width)
		slot_gap = 0.0
		total_width = _total_width(
			word_font,
			effective_font_size,
			slot_gap,
			base_space_width
		)
		var minimum_font_size: int = 20
		while total_width > available_size.x and effective_font_size > minimum_font_size:
			effective_font_size -= 1
			total_width = _total_width(
				word_font,
				effective_font_size,
				slot_gap,
				base_space_width
			)

	# Fill the paper for long answers, including compressed ones: quantized font
	# widths and integer font sizes can leave spare room after fitting. Short words
	# keep their compact natural spacing instead of expanding to fill the strip.
	var non_space_count: int = 0
	for letter in _letters:
		if str(letter) != " ":
			non_space_count += 1
	var can_expand_word_layout: bool = (
		non_space_count >= 12
		or word_font_width < full_font_width
		or effective_font_size < maxi(font_size, 1)
	)
	if can_expand_word_layout:
		var expansion_target_width: float = available_size.x
		var maximum_expanded_gap: float = maxf(
			slot_gap,
			available_size.x / float(maxi(non_space_count - 1, 1))
		)
		var maximum_expanded_width: float = _total_width(
			word_font,
			effective_font_size,
			maximum_expanded_gap,
			base_space_width
		)
		if total_width < expansion_target_width - 0.5:
			if maximum_expanded_width <= expansion_target_width:
				slot_gap = maximum_expanded_gap
				total_width = maximum_expanded_width
			else:
				var lower_gap: float = slot_gap
				var upper_gap: float = maximum_expanded_gap
				for _iteration: int in range(12):
					var candidate_gap: float = (lower_gap + upper_gap) * 0.5
					var candidate_width: float = _total_width(
						word_font,
						effective_font_size,
						candidate_gap,
						base_space_width
					)
					if candidate_width <= expansion_target_width:
						lower_gap = candidate_gap
					else:
						upper_gap = candidate_gap
				slot_gap = lower_gap
				total_width = _total_width(
					word_font,
					effective_font_size,
					slot_gap,
					base_space_width
				)

	# Fit decisions above use the same real-glyph metrics that drive rendering.
	# Centers remain evenly spaced inside each word segment, while each Label keeps
	# its own actual glyph width. This prevents a single wide character from making
	# the whole answer look artificially compressed.
	var layout_metrics: Dictionary = _metrics(
		word_font,
		effective_font_size,
		slot_gap,
		base_space_width
	)
	total_width = float(layout_metrics.get("total_width", total_width))
	var layout_lefts: Array = layout_metrics.get("lefts", []) as Array
	var layout_widths: Array = layout_metrics.get("widths", []) as Array
	var layout_centers: Array = layout_metrics.get("centers", []) as Array
	var layout: Array = []
	for i in range(_letters.size()):
		var letter: String = str(_letters[i])
		var is_space: bool = letter == " "
		layout.append({
			"letter": letter,
			"is_space": is_space,
			"is_dash": letter == "-" or letter == "—",
			"left": float(layout_lefts[i]),
			"width": float(layout_widths[i]),
			"center": float(layout_centers[i]),
		})

	# Hidden-letter strokes must remain visually separate even after long answers
	# have exhausted Roboto Flex wdth and start reducing tracking. Resolve one
	# shared underline width for the complete word, then apply it to every hidden
	# letter. This keeps all strokes identical instead of letting narrow glyphs
	# produce shorter lines than wide glyphs.
	# Keep the preferred gap while the answer fits with normal tracking. Only
	# long answers that require tighter tracking reduce it toward the 4 px floor.
	var underline_max_width: float = UNDERLINE_MAX_WIDTH
	var underline_min_width: float = 6.0
	var underline_min_gap: float = lerpf(
		4.0,
		UNDERLINE_GAP,
		clampf(slot_gap / base_gap, 0.0, 1.0)
	)
	var shared_underline_width: float = underline_max_width
	var underline_centers: Array[float] = []
	for scan_item_value in layout:
		var scan_item: Dictionary = scan_item_value
		if !bool(scan_item["is_space"]) and !bool(scan_item["is_dash"]):
			underline_centers.append(float(scan_item["center"]))
	if underline_centers.size() > 1:
		var minimum_center_distance: float = INF
		for i in range(1, underline_centers.size()):
			minimum_center_distance = minf(
				minimum_center_distance,
				underline_centers[i] - underline_centers[i - 1]
			)
		shared_underline_width = clampf(
			minimum_center_distance - underline_min_gap,
			underline_min_width,
			underline_max_width
		)
	var compressed_word_layout: bool = (
		word_font_width < UI_FONTS.ROBOTO_FLEX_GAME_WORD_WIDTH - 0.5
		or slot_gap < base_gap - 0.5
	)
	var underline_height: float = 3.5 if compressed_word_layout else 4.0
	var start_x: float = (available_size.x - total_width) * 0.5
	var baseline_y: float = available_size.y - 8.0
	# Bottom-aligned labels end 10 px above the slot bottom. Their font descent
	# separates that edge from the capital-letter baseline. Move the marks 30%
	# toward this baseline, keeping the letter positions and paper height intact.
	var letter_baseline_y: float = (
		available_size.y - 10.0
		- word_font.get_descent(effective_font_size)
	)
	baseline_y = lerpf(letter_baseline_y, baseline_y, 0.7)

	return {
		"items": layout,
		"font": word_font,
		"font_size": effective_font_size,
		"font_width": word_font_width,
		"total_width": total_width,
		"center_step": layout_metrics.get("center_step", 1.0),
		"gap": slot_gap,
		"start_x": start_x,
		"baseline_y": baseline_y,
		"underline_width": shared_underline_width,
		"underline_height": underline_height,
	}
