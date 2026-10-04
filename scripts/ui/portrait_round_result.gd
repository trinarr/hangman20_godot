extends "res://scripts/ui/portrait_presentation.gd"
## In-place round result: solved word, marker, paper peel and result actions.
## The gameplay adapter supplies snapshots and handles rewards/navigation.

signal search_requested
signal continue_requested
signal continue_available
signal attempt_collection_requested
signal attempt_collection_finish_requested
signal hints_finalize_requested

var letters: Array[String] = []
var word_rect: Rect2
var action_rect: Rect2
var paper_mask: Control
var paper_front: Control
var paper_backside: Control
var paper_backside_visual: Control
var keyboard_buttons: Array = []
var back_button: Control
var active: bool = false
var is_win: bool = false
var waiting_for_letters: bool = false
var result_search_button: Control
var result_continue_button: Control
var attempt_collection_pending: bool = false
var continue_caption: String = ""

func configure(parent: Control, bindings: Dictionary, word_letters: Array[String]) -> void:
	content = parent
	letters = word_letters.duplicate()
	word_rect = bindings["word_rect"]
	action_rect = bindings["action_rect"]
	paper_mask = bindings.get("paper_mask")
	paper_front = bindings.get("paper_layer")
	paper_backside = bindings.get("paper_backside")
	paper_backside_visual = bindings.get("paper_backside_visual")
	keyboard_buttons = bindings.get("keyboard_buttons", [])
	back_button = bindings.get("back_button")

func begin(win: bool, animated: bool, wait_for_letters: bool, pending_attempts: bool, caption: String) -> void:
	if active or _stopped:
		return
	active = true
	is_win = win
	continue_caption = caption
	attempt_collection_pending = pending_attempts
	if back_button != null and is_instance_valid(back_button):
		back_button.visible = false
		back_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		back_button.set("disabled", true)
	_dim_portrait_keyboard_for_in_place_result()
	waiting_for_letters = win and animated and wait_for_letters
	if !waiting_for_letters:
		_peel_portrait_word_paper_for_in_place_result(animated)

func gameplay_letters_settled() -> void:
	if active and is_win and waiting_for_letters and !_stopped:
		_peel_portrait_word_paper_for_in_place_result(true)

func attempts_collected() -> void:
	attempt_collection_pending = false
	if !_stopped:
		_reveal_in_place_result_action_after_attempt_stars()

func stop() -> void:
	super.stop()
	active = false
	waiting_for_letters = false
	if is_instance_valid(result_search_button):
		result_search_button.set("disabled", true)
		result_search_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_instance_valid(result_continue_button):
		result_continue_button.set("attention_bounce_enabled", false)
		result_continue_button.set("disabled", true)
		result_continue_button.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _request_search() -> void:
	if !_stopped:
		search_requested.emit()

func _request_continue() -> void:
	if !_stopped:
		continue_requested.emit()

const LONG_BUTTON_COLOR_ORANGE: int = 0

const RESULT_SEARCH_ICON: Texture2D = preload("res://flash_assets/result_search_icon_343.png")

const PORTRAIT_GAME_DESIGN: GDScript = preload("res://scripts/core/game_design_config.gd")

const PORTRAIT_UI_PALETTE: GDScript = preload("res://scripts/ui/ui_palette.gd")

const PORTRAIT_STAGE_LAYOUT: GDScript = preload("res://scripts/ui/portrait_stage_layout.gd")

const WORD_SLOT_LAYOUT_SCRIPT: GDScript = preload("res://scripts/ui/word_slot_layout.gd")

const PORTRAIT_STAGE_SIZE := Vector2(480.0, 800.0)

const PORTRAIT_GAME_WORD_PAPER_HEIGHT: float = 118.0 * 0.85

const PORTRAIT_GAME_WORD_PAPER_Y_OFFSET: float = -18.0 + (118.0 - PORTRAIT_GAME_WORD_PAPER_HEIGHT) * 0.5

var PORTRAIT_ROUND_END_PAPER_FLIP_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.round_end.paper_flip_seconds"
)

const PORTRAIT_ROUND_END_PAPER_BACKSIDE_MAX_WIDTH: float = 190.0

const PORTRAIT_IN_PLACE_RESULT_KEYBOARD_ALPHA: float = 0.70

var PORTRAIT_INLINE_RESULT_CONTINUE_GROW_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.game_entrance.continue_grow_seconds"
)

const PORTRAIT_RESULT_SEARCH_BUTTON_SIZE: float = 44.0

const PORTRAIT_RESULT_SEARCH_REST_VISUAL_SCALE := Vector2.ONE

const PORTRAIT_RESULT_SEARCH_START_VISUAL_SCALE := PORTRAIT_RESULT_SEARCH_REST_VISUAL_SCALE * 0.72

const PORTRAIT_RESULT_SEARCH_PEAK_VISUAL_SCALE := PORTRAIT_RESULT_SEARCH_REST_VISUAL_SCALE * 1.18

const PORTRAIT_RESULT_WORD_SEARCH_GAP: float = 10.0

const PORTRAIT_RESULT_SEARCH_SAFE_MARGIN: float = 14.0

const PORTRAIT_RESULT_WORD_Y_OFFSET: float = 4.0

const PORTRAIT_RESULT_SEARCH_ICON_SIZE := Vector2(24.0, 31.0)

var PORTRAIT_RESULT_LETTER_BOUNCE_GROW_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.result_letters.grow_seconds"
)

var PORTRAIT_RESULT_LETTER_BOUNCE_SETTLE_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.result_letters.settle_seconds"
)

var PORTRAIT_RESULT_LETTER_BOUNCE_GAP: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.result_letters.gap_seconds"
)

const PORTRAIT_RESULT_LETTER_NEIGHBOR_BOUNCE_STRENGTH: float = 0.40

var PORTRAIT_RESULT_LETTER_BOUNCE_REFERENCE_LENGTH: float = PORTRAIT_GAME_DESIGN.get_float_range(
	"timings.animations.result_letters.reference_length",
	0.01,
	100.0
)

var PORTRAIT_RESULT_LETTER_BOUNCE_MAX_SPEED_MULTIPLIER: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.result_letters.maximum_speed_multiplier"
)

var PORTRAIT_RESULT_SEARCH_APPEAR_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.result_letters.search_appear_seconds"
)

var PORTRAIT_WORD_LETTER_BOUNCE_PEAK_SCALE: Vector2 = Vector2.ONE * PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.word_letters.peak_scale"
)

func _portrait_display_word_text(text: String) -> String:
	# Keep stored/session separators untouched, but render compound-word separators
	# with the mathematical minus. It is longer than a hyphen while staying much
	# shorter than an em dash, and the same glyph is used for layout measurement.
	return WORD_SLOT_LAYOUT_SCRIPT.display_text(text)

static func _portrait_result_word_font(width: float = UI_FONTS.ROBOTO_FLEX_BUTTON_WIDTH) -> Font:
	# Result words use the same Roboto Flex profile as regular button captions,
	# but long answers may compress only the wdth axis before any size fallback.
	return UI_FONTS.button_font_with_width(width)

static func _portrait_result_word_text_width(
	text: String,
	font: Font,
	font_size: int
) -> float:
	return font.get_string_size(
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		font_size
	).x

static func _resolve_portrait_result_word_layout(
	word_text: String,
	available_width: float,
	base_font_size: int
) -> Dictionary:
	var resolved_width_axis: float = UI_FONTS.ROBOTO_FLEX_BUTTON_WIDTH
	var resolved_font_size: int = base_font_size
	var resolved_font: Font = _portrait_result_word_font(resolved_width_axis)
	var measured_word_width: float = _portrait_result_word_text_width(
		word_text,
		resolved_font,
		resolved_font_size
	)
	if measured_word_width > available_width:
		var lower_width: float = UI_FONTS.ROBOTO_FLEX_BUTTON_MIN_WIDTH
		var upper_width: float = UI_FONTS.ROBOTO_FLEX_BUTTON_WIDTH
		for _iteration: int in range(8):
			var candidate_width: float = (lower_width + upper_width) * 0.5
			var candidate_font: Font = _portrait_result_word_font(candidate_width)
			var candidate_word_width: float = _portrait_result_word_text_width(
				word_text,
				candidate_font,
				resolved_font_size
			)
			if candidate_word_width <= available_width:
				lower_width = candidate_width
			else:
				upper_width = candidate_width
		resolved_width_axis = floorf(lower_width)
		resolved_font = _portrait_result_word_font(resolved_width_axis)
		measured_word_width = _portrait_result_word_text_width(
			word_text,
			resolved_font,
			resolved_font_size
		)
	if measured_word_width > available_width:
		var minimum_font_size: int = 24
		while measured_word_width > available_width and resolved_font_size > minimum_font_size:
			resolved_font_size -= 1
			measured_word_width = _portrait_result_word_text_width(
				word_text,
				resolved_font,
				resolved_font_size
			)
	return {
		"font": resolved_font,
		"font_size": resolved_font_size,
		"font_width": resolved_width_axis,
		"measured_width": measured_word_width,
	}

func _stage_portrait_result_word_display(
	rect: Rect2,
	continue_button: Control,
	continue_text: Control,
	animate_result: bool,
	bounce_start_delay: float = 0.0
) -> Dictionary:
	# Treat the final word and search button as one centered group. Reserving the
	# search width symmetrically on both sides used to waste the free left margin,
	# forcing long answers to overlap the button even though the screen still had
	# plenty of room on the opposite side.
	var group_side_margin: float = maxf(PORTRAIT_RESULT_SEARCH_SAFE_MARGIN, 18.0)
	var max_group_width: float = maxf(
		PORTRAIT_STAGE_SIZE.x - group_side_margin * 2.0,
		1.0
	)
	var max_word_width: float = maxf(
		max_group_width
		- PORTRAIT_RESULT_WORD_SEARCH_GAP
		- PORTRAIT_RESULT_SEARCH_BUTTON_SIZE,
		1.0
	)
	var word_width: float = minf(rect.size.x, max_word_width)
	var word_text: String = _portrait_display_word_text("".join(letters))

	# The settled result uses the exact same Label + DisplayTextEffect path as a
	# button caption. This avoids the small per-glyph inconsistencies produced by
	# the former RichTextLabel recreation of the button outline/shadow.
	var result_font_size: int = 39
	var result_layout: Dictionary = _resolve_portrait_result_word_layout(
		word_text,
		word_width,
		result_font_size
	)
	var result_font: Font = result_layout.get("font") as Font
	result_font_size = int(result_layout.get("font_size", result_font_size))
	var measured_word_width: float = float(result_layout.get("measured_width", 0.0))
	var result_group_width: float = (
		measured_word_width
		+ PORTRAIT_RESULT_WORD_SEARCH_GAP
		+ PORTRAIT_RESULT_SEARCH_BUTTON_SIZE
	)
	var result_group_x: float = clampf(
		(PORTRAIT_STAGE_SIZE.x - result_group_width) * 0.5,
		group_side_margin,
		maxf(
			group_side_margin,
			PORTRAIT_STAGE_SIZE.x - group_side_margin - result_group_width
		)
	)
	var word_rect := Rect2(
		Vector2(
			result_group_x,
			rect.position.y + PORTRAIT_RESULT_WORD_Y_OFFSET + PORTRAIT_STAGE_SIZE.y * 0.02
		),
		Vector2(maxf(measured_word_width, 1.0), rect.size.y - 10.0)
	)
	var word_holder := _stage_holder(word_rect, Control.MOUSE_FILTER_IGNORE)
	word_holder.z_index = 29
	var word_label := Label.new()
	word_label.name = "ResultWordLabel"
	word_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	word_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	word_label.text = word_text
	word_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	word_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	word_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	word_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	word_label.clip_text = false
	word_label.add_theme_font_override("font", result_font)
	word_label.add_theme_font_size_override("font_size", result_font_size)
	word_label.add_theme_color_override("font_color", Color.WHITE)
	word_holder.add_child(word_label)
	word_label.z_index = 1
	BUTTON_TEXT_STYLE_SCRIPT.apply_display(word_label)

	var animated_letter_count: int = 0
	for letter: String in letters:
		if letter != " " and letter != "-" and letter != "—":
			animated_letter_count += 1
	var speed_multiplier: float = clampf(
		float(animated_letter_count) / PORTRAIT_RESULT_LETTER_BOUNCE_REFERENCE_LENGTH,
		1.0,
		PORTRAIT_RESULT_LETTER_BOUNCE_MAX_SPEED_MULTIPLIER
	)
	var grow_duration: float = PORTRAIT_RESULT_LETTER_BOUNCE_GROW_DURATION / speed_multiplier
	var settle_duration: float = PORTRAIT_RESULT_LETTER_BOUNCE_SETTLE_DURATION / speed_multiplier
	var letter_gap: float = PORTRAIT_RESULT_LETTER_BOUNCE_GAP / speed_multiplier
	var animation_duration: float = 0.0
	var bounce_holder: Control = null
	var bounce_labels: Array = []
	if animate_result and animated_letter_count > 0:
		word_label.visible = false
		var bounce_result: Dictionary = _stage_portrait_result_word_bounce_labels(
			word_holder,
			word_text,
			result_font,
			result_font_size,
			measured_word_width,
			grow_duration,
			settle_duration,
			letter_gap,
			bounce_start_delay
		)
		bounce_holder = bounce_result.get("holder") as Control
		bounce_labels = bounce_result.get("labels", []) as Array
		animation_duration = float(bounce_result.get("duration", 0.0))

	var word_bounds := Rect2(
		word_rect.position,
		Vector2(measured_word_width, word_rect.size.y)
	)
	var search_x: float = word_bounds.end.x + PORTRAIT_RESULT_WORD_SEARCH_GAP
	var search_y: float = word_rect.get_center().y - PORTRAIT_RESULT_SEARCH_BUTTON_SIZE * 0.5
	var marker_left: float = maxf(18.0, word_bounds.position.x - 6.0)
	var marker_right: float = minf(
		PORTRAIT_STAGE_SIZE.x - 18.0,
		search_x + PORTRAIT_RESULT_SEARCH_BUTTON_SIZE + 5.0
	)
	var marker_top: float = word_rect.position.y - 4.0
	var marker_height: float = maxf(
		word_rect.size.y + 8.0,
		PORTRAIT_RESULT_SEARCH_BUTTON_SIZE + 4.0
	)
	var marker_holder := _stage_holder(
		Rect2(
			marker_left,
			marker_top,
			marker_right - marker_left,
			marker_height
		),
		Control.MOUSE_FILTER_IGNORE
	)
	marker_holder.name = "ResultWordMarkerHolder"
	marker_holder.z_index = 29
	var word_marker := _stage_portrait_result_word_marker(marker_holder.size)
	marker_holder.add_child(word_marker)
	var search_button := _stage_round_icon_button(
		Rect2(
			search_x,
			search_y,
			PORTRAIT_RESULT_SEARCH_BUTTON_SIZE,
			PORTRAIT_RESULT_SEARCH_BUTTON_SIZE
		),
		Callable(self, "_request_search"),
		RESULT_SEARCH_ICON,
		PORTRAIT_RESULT_SEARCH_ICON_SIZE
	)
	search_button.z_index = 29
	search_button.set("press_scale_enabled", true)
	search_button.set("drop_shadow_enabled", true)
	search_button.set("drop_shadow_offset_y", 2.0)
	search_button.set("drop_shadow_pressed_offset_y", 1.0)
	search_button.set("visual_scale", PORTRAIT_RESULT_SEARCH_REST_VISUAL_SCALE)
	search_button.visible = !animate_result
	if animate_result:
		call_deferred(
			"_run_for_current_result",
			generation,
			Callable(self, "_play_portrait_result_word_bounce_sequence"),
			[animation_duration, search_button, continue_button, continue_text, word_label, bounce_holder]
		)
	return {
		"word_holder": word_holder,
		"marker_holder": marker_holder,
		"word_marker": word_marker,
		"word_label": word_label,
		"bounce_labels": bounce_labels,
		"search_button": search_button,
	}

func _stage_portrait_result_word_bounce_labels(
	word_holder: Control,
	word_text: String,
	font: Font,
	font_size: int,
	measured_word_width: float,
	grow_duration: float,
	settle_duration: float,
	letter_gap: float,
	start_delay: float = 0.0
) -> Dictionary:
	var bounce_holder := Control.new()
	bounce_holder.name = "ResultWordBounceLetters"
	bounce_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bounce_holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bounce_holder.z_index = 2
	word_holder.add_child(bounce_holder)

	# Position every temporary bounce glyph from the shaped width of the real text
	# prefix. The previous implementation spread the total kerning correction evenly
	# across all pairs, which made long phrases snap when they were swapped back to
	# the settled Label and could look like a second bounce pass.
	var prefix_advances: Array[float] = [0.0]
	for character_index: int in range(word_text.length()):
		var prefix_text: String = word_text.substr(0, character_index + 1)
		prefix_advances.append(
			font.get_string_size(
				prefix_text,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1.0,
				font_size
			).x
		)

	var animation_index: int = 0
	var labels: Array = []
	var bounce_labels: Array = []
	var start_step: float = grow_duration + letter_gap
	for character_index: int in range(word_text.length()):
		var character: String = word_text.substr(character_index, 1)
		if character == " ":
			continue
		var glyph_width: float = maxf(
			font.get_string_size(
				character,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1.0,
				font_size
			).x,
			1.0
		)
		var glyph_x: float = prefix_advances[character_index]
		var letter_label := Label.new()
		letter_label.name = "ResultLetter%02d" % character_index
		letter_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		letter_label.position = Vector2(roundf(glyph_x), 0.0)
		letter_label.size = Vector2(maxf(ceilf(glyph_width), 1.0), word_holder.size.y)
		letter_label.text = character
		letter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		letter_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		letter_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		letter_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		letter_label.clip_text = false
		letter_label.add_theme_font_override("font", font)
		letter_label.add_theme_font_size_override("font_size", font_size)
		letter_label.add_theme_color_override("font_color", Color.WHITE)
		bounce_holder.add_child(letter_label)
		BUTTON_TEXT_STYLE_SCRIPT.apply_display(letter_label)
		labels.append(letter_label)
		if character != "-" and character != "—":
			letter_label.pivot_offset = letter_label.size * 0.5
			letter_label.set_meta("result_word_bounce_contributions", {})
			bounce_labels.append(letter_label)

	animation_index = bounce_labels.size()
	for bounce_index: int in range(animation_index):
		_play_portrait_result_letter_bounce(
			bounce_labels,
			bounce_index,
			start_delay + float(bounce_index) * start_step,
			grow_duration,
			settle_duration,
			letter_gap
		)

	var duration: float = 0.0
	if animation_index > 0:
		duration = (
			start_delay + float(animation_index - 1) * start_step
			+ grow_duration
			+ settle_duration
		)
	return {
		"holder": bounce_holder,
		"labels": labels,
		"duration": duration,
	}

func _play_portrait_result_letter_bounce(
	bounce_labels: Array,
	center_index: int,
	delay: float,
	grow_duration: float,
	settle_duration: float,
	letter_gap: float
) -> void:
	if center_index < 0 or center_index >= bounce_labels.size():
		return
	var center_label: Label = bounce_labels[center_index] as Label
	if center_label == null or !is_instance_valid(center_label):
		return
	var pulse_id: int = center_index
	var peak_scale: float = PORTRAIT_WORD_LETTER_BOUNCE_PEAK_SCALE.x
	var tween: Tween = _tween(center_label)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.bind_node(center_label)
	if delay > 0.0:
		tween.tween_interval(delay)
	var grow := tween.tween_method(
		Callable(self, "_apply_portrait_result_letter_bounce_pulse").bind(
			bounce_labels, center_index, pulse_id
		),
		1.0,
		peak_scale,
		grow_duration
	)
	grow.set_trans(Tween.TRANS_QUAD)
	grow.set_ease(Tween.EASE_OUT)
	var settle := tween.tween_method(
		Callable(self, "_apply_portrait_result_letter_bounce_pulse").bind(
			bounce_labels, center_index, pulse_id
		),
		peak_scale,
		1.0,
		settle_duration
	)
	settle.set_trans(Tween.TRANS_BACK)
	settle.set_ease(Tween.EASE_OUT)
	tween.tween_callback(
		Callable(self, "_finish_portrait_result_letter_bounce_pulse").bind(
			bounce_labels, center_index, pulse_id
		)
	)

	# The right-hand neighbour becomes the next central letter in the wave. If its
	# 40% neighbour pulse settles before the next full pulse reaches its peak, the
	# glyph visibly snaps down and immediately back up. Bridge those two peaks with
	# one monotonic contribution: 40% at this letter's peak -> 100% exactly at the
	# next letter's own peak. The normal next-center pulse then takes over seamlessly.
	var right_index: int = center_index + 1
	if right_index < bounce_labels.size():
		var right_label: Label = bounce_labels[right_index] as Label
		if right_label != null and is_instance_valid(right_label):
			var bridge_id: int = -center_index - 1
			var peak_delta: float = peak_scale - 1.0
			var bridge_start_delta: float = (
				peak_delta * PORTRAIT_RESULT_LETTER_NEIGHBOR_BOUNCE_STRENGTH
			)
			var bridge_duration: float = grow_duration + letter_gap
			var bridge_tween: Tween = _tween(right_label)
			bridge_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			bridge_tween.bind_node(right_label)
			var bridge_delay: float = delay + grow_duration
			if bridge_delay > 0.0:
				bridge_tween.tween_interval(bridge_delay)
			var bridge := bridge_tween.tween_method(
				Callable(self, "_apply_portrait_result_letter_bounce_contribution").bind(
					right_label, bridge_id
				),
				bridge_start_delta,
				peak_delta,
				bridge_duration
			)
			bridge.set_trans(Tween.TRANS_SINE)
			bridge.set_ease(Tween.EASE_IN_OUT)
			bridge_tween.tween_callback(
				Callable(self, "_finish_portrait_result_letter_bounce_contribution").bind(
					right_label, bridge_id
				)
			)

func _apply_portrait_result_letter_bounce_contribution(
	delta: float,
	letter_label: Label,
	contribution_id: int
) -> void:
	if letter_label == null or !is_instance_valid(letter_label):
		return
	var contributions: Dictionary = letter_label.get_meta(
		"result_word_bounce_contributions", {}
	)
	contributions[contribution_id] = delta
	letter_label.set_meta("result_word_bounce_contributions", contributions)
	_refresh_portrait_result_letter_bounce_scale(letter_label, contributions)

func _finish_portrait_result_letter_bounce_contribution(
	letter_label: Label,
	contribution_id: int
) -> void:
	if letter_label == null or !is_instance_valid(letter_label):
		return
	var contributions: Dictionary = letter_label.get_meta(
		"result_word_bounce_contributions", {}
	)
	contributions.erase(contribution_id)
	letter_label.set_meta("result_word_bounce_contributions", contributions)
	_refresh_portrait_result_letter_bounce_scale(letter_label, contributions)

func _apply_portrait_result_letter_bounce_pulse(
	scale_value: float,
	bounce_labels: Array,
	center_index: int,
	pulse_id: int
) -> void:
	var base_delta: float = scale_value - 1.0
	for offset: int in range(-1, 2):
		var label_index: int = center_index + offset
		if label_index < 0 or label_index >= bounce_labels.size():
			continue
		var letter_label: Label = bounce_labels[label_index] as Label
		if letter_label == null or !is_instance_valid(letter_label):
			continue
		var strength: float = (
			1.0
			if offset == 0
			else PORTRAIT_RESULT_LETTER_NEIGHBOR_BOUNCE_STRENGTH
		)
		var contributions: Dictionary = letter_label.get_meta(
			"result_word_bounce_contributions", {}
		)
		contributions[pulse_id] = base_delta * strength
		letter_label.set_meta("result_word_bounce_contributions", contributions)
		_refresh_portrait_result_letter_bounce_scale(letter_label, contributions)

func _finish_portrait_result_letter_bounce_pulse(
	bounce_labels: Array,
	center_index: int,
	pulse_id: int
) -> void:
	for offset: int in range(-1, 2):
		var label_index: int = center_index + offset
		if label_index < 0 or label_index >= bounce_labels.size():
			continue
		var letter_label: Label = bounce_labels[label_index] as Label
		if letter_label == null or !is_instance_valid(letter_label):
			continue
		var contributions: Dictionary = letter_label.get_meta(
			"result_word_bounce_contributions", {}
		)
		contributions.erase(pulse_id)
		letter_label.set_meta("result_word_bounce_contributions", contributions)
		_refresh_portrait_result_letter_bounce_scale(letter_label, contributions)

func _refresh_portrait_result_letter_bounce_scale(
	letter_label: Label,
	contributions: Dictionary
) -> void:
	if letter_label == null or !is_instance_valid(letter_label):
		return
	var selected_delta: float = 0.0
	var strongest_negative_delta: float = 0.0
	for contribution_value: Variant in contributions.values():
		var contribution: float = float(contribution_value)
		if contribution > selected_delta:
			selected_delta = contribution
		elif selected_delta <= 0.0 and contribution < strongest_negative_delta:
			strongest_negative_delta = contribution
	if selected_delta <= 0.0:
		selected_delta = strongest_negative_delta
	var combined_scale: float = maxf(1.0 + selected_delta, 0.01)
	letter_label.scale = Vector2.ONE * combined_scale

func _run_for_current_result(requested_generation: int, action: Callable, args: Array) -> void:
	# A synchronous navigation can free the result before its deferred call runs.
	# Check before dispatch: typed Control arguments cannot accept freed objects.
	if requested_generation != generation or _stopped or !is_inside_tree() or !action.is_valid():
		return
	for argument: Variant in args:
		if typeof(argument) == TYPE_OBJECT and !is_instance_valid(argument):
			return
	action.callv(args)

func _play_portrait_result_word_bounce_sequence(
	animation_duration: float,
	search_button: Control,
	continue_button: Control,
	continue_text: Control,
	settled_word_label: Label,
	bounce_holder: Control
) -> void:
	if settled_word_label == null or !is_instance_valid(settled_word_label):
		return
	if animation_duration <= 0.0:
		_complete_portrait_result_word_bounce_sequence(
			search_button,
			continue_button,
			continue_text,
			settled_word_label,
			bounce_holder
		)
		return
	# Cancel the completion callback with this result if navigation removes it.
	var sequence: Tween = _tween(settled_word_label)
	sequence.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	sequence.tween_interval(animation_duration)
	sequence.tween_callback(
		Callable(self, "_complete_portrait_result_word_bounce_sequence").bind(
			search_button,
			continue_button,
			continue_text,
			settled_word_label,
			bounce_holder
		)
	)

func _complete_portrait_result_word_bounce_sequence(
	search_button: Control,
	continue_button: Control,
	continue_text: Control,
	settled_word_label: Label,
	bounce_holder: Control
) -> void:
	# Swap the temporary per-letter bounce composition for one settled Label. The
	# final frame then uses exactly the same ButtonTextStyle path as button text,
	# including identical shaping, outline and shader shadow.
	if settled_word_label != null and is_instance_valid(settled_word_label):
		settled_word_label.visible = true
	if bounce_holder != null and is_instance_valid(bounce_holder):
		bounce_holder.visible = false
		bounce_holder.queue_free()

	# Once every solved-word letter has completed its bounce, reveal the search
	# button and convert remaining attempts in parallel. Continue still waits for
	# the final star impact.
	if attempt_collection_pending:
		_reveal_portrait_result_actions(search_button, continue_button, continue_text)
		attempt_collection_requested.emit()
		return
	_reveal_portrait_result_actions(search_button, continue_button, continue_text)

func _reveal_portrait_result_actions(
	search_button: Control,
	continue_button: Control,
	continue_text: Control,
	finished_callback: Callable = Callable()
) -> void:
	if search_button == null or !is_instance_valid(search_button) or !search_button.is_inside_tree():
		if attempt_collection_pending:
			attempt_collection_finish_requested.emit()
		elif finished_callback.is_valid():
			finished_callback.call()
		return
	search_button.visible = true
	search_button.set("disabled", false)
	# Press feedback also writes visual_scale; enable input after the entrance.
	search_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	search_button.modulate = Color(1.0, 1.0, 1.0, 0.0)
	search_button.set("visual_scale", PORTRAIT_RESULT_SEARCH_START_VISUAL_SCALE)
	if continue_button != null and is_instance_valid(continue_button) and continue_button.is_inside_tree():
		continue_button.visible = true
		continue_button.modulate = Color(1.0, 1.0, 1.0, 0.0)
	if continue_text != null and is_instance_valid(continue_text) and continue_text.is_inside_tree():
		continue_text.visible = true
		continue_text.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var reveal_tween: Tween = _tween(search_button)
	reveal_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	reveal_tween.set_parallel(true)
	var fade_tweener: PropertyTweener = reveal_tween.tween_property(
		search_button,
		"modulate",
		Color.WHITE,
		PORTRAIT_RESULT_SEARCH_APPEAR_DURATION
	)
	fade_tweener.set_trans(Tween.TRANS_SINE)
	fade_tweener.set_ease(Tween.EASE_OUT)
	if continue_button != null and is_instance_valid(continue_button) and continue_button.is_inside_tree():
		var continue_fade_tweener: PropertyTweener = reveal_tween.tween_property(
			continue_button,
			"modulate",
			Color.WHITE,
			PORTRAIT_RESULT_SEARCH_APPEAR_DURATION
		)
		continue_fade_tweener.set_trans(Tween.TRANS_SINE)
		continue_fade_tweener.set_ease(Tween.EASE_OUT)
	if continue_text != null and is_instance_valid(continue_text) and continue_text.is_inside_tree():
		var continue_text_fade_tweener: PropertyTweener = reveal_tween.tween_property(
			continue_text,
			"modulate",
			Color.WHITE,
			PORTRAIT_RESULT_SEARCH_APPEAR_DURATION
		)
		continue_text_fade_tweener.set_trans(Tween.TRANS_SINE)
		continue_text_fade_tweener.set_ease(Tween.EASE_OUT)
	var scale_tweener: PropertyTweener = reveal_tween.tween_property(
		search_button,
		"visual_scale",
		PORTRAIT_RESULT_SEARCH_PEAK_VISUAL_SCALE,
		PORTRAIT_RESULT_SEARCH_APPEAR_DURATION
	)
	scale_tweener.set_trans(Tween.TRANS_QUAD)
	scale_tweener.set_ease(Tween.EASE_OUT)
	var settle_tweener: PropertyTweener = reveal_tween.chain().tween_property(
		search_button,
		"visual_scale",
		PORTRAIT_RESULT_SEARCH_REST_VISUAL_SCALE,
		PORTRAIT_RESULT_SEARCH_APPEAR_DURATION
	)
	settle_tweener.set_trans(Tween.TRANS_BACK)
	settle_tweener.set_ease(Tween.EASE_OUT)
	reveal_tween.finished.connect(func() -> void:
		if is_instance_valid(search_button) and search_button.is_inside_tree():
			search_button.mouse_filter = Control.MOUSE_FILTER_STOP
	)
	if finished_callback.is_valid():
		reveal_tween.finished.connect(
			finished_callback,
			CONNECT_ONE_SHOT
		)

func _portrait_result_word_effect_colors(color: Color) -> Dictionary:
	var marker_color: Color = PORTRAIT_UI_PALETTE.MARKER_SUCCESS
	if color == StageLetterButton.CROSSED_COLOR:
		marker_color = PORTRAIT_UI_PALETTE.MARKER_ERROR
	return {
		"outline": marker_color.darkened(0.42),
		"shadow": marker_color.darkened(0.62),
	}

func _apply_portrait_result_word_style(target: Label, color: Color) -> void:
	if target == null or !is_instance_valid(target):
		return
	var effect_colors: Dictionary = _portrait_result_word_effect_colors(color)
	var outline_color: Color = effect_colors.get("outline", Color.BLACK)
	var shadow_color: Color = effect_colors.get("shadow", Color.BLACK)
	target.add_theme_color_override("font_color", Color.WHITE)
	BUTTON_TEXT_STYLE_SCRIPT.apply_display_tinted(
		target,
		outline_color,
		shadow_color
	)

func _set_portrait_result_word_color(result_controls: Dictionary, color: Color) -> void:
	var word_label := result_controls.get("word_label") as Label
	_apply_portrait_result_word_style(word_label, color)
	var bounce_labels: Array = result_controls.get("bounce_labels", []) as Array
	for bounce_label_value: Variant in bounce_labels:
		var bounce_label := bounce_label_value as Label
		_apply_portrait_result_word_style(bounce_label, color)
	_set_portrait_result_word_marker_color(result_controls, color)

func _in_place_result_word_color() -> Color:
	return (
		StageLetterButton.CIRCLED_COLOR
		if is_win
		else StageLetterButton.CROSSED_COLOR
	)

func _stage_in_place_result_word(animated: bool) -> void:
	# Build visible letters once, underneath the paper, before the peel moves.
	# Only their motion waits for the midpoint; the marker and word never vanish.
	var bounce_start_delay: float = PORTRAIT_ROUND_END_PAPER_FLIP_DURATION * 0.5 if animated else 0.0
	var result_controls: Dictionary = _stage_portrait_result_word_display(word_rect, null, null, animated, bounce_start_delay)
	_set_portrait_result_word_color(result_controls, _in_place_result_word_color())
	var search_button := result_controls.get("search_button") as Control
	result_search_button = search_button
	if search_button != null and is_instance_valid(search_button):
		search_button.visible = !animated
		search_button.set("disabled", animated)

func _dim_portrait_keyboard_for_in_place_result() -> void:
	for entry_variant: Variant in keyboard_buttons:
		var entry: Dictionary = entry_variant
		var button := entry.get("button") as Control
		if button == null or !is_instance_valid(button):
			continue
		button.set("disabled", true)
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.modulate.a = PORTRAIT_IN_PLACE_RESULT_KEYBOARD_ALPHA

func _peel_portrait_word_paper_for_in_place_result(animated: bool) -> void:
	waiting_for_letters = false
	_stage_in_place_result_word(animated)
	if paper_front == null or !is_instance_valid(paper_front):
		_finish_in_place_result_paper_peel(null, animated)
		return
	var paper_layer: Control = paper_front
	paper_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if !animated:
		_set_portrait_word_paper_peel_progress(1.0)
		_finish_in_place_result_paper_peel(paper_layer, false)
		return

	_set_portrait_word_paper_peel_progress(0.0)
	var flip_tween := _tween(paper_layer)
	flip_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var mask_tweener := flip_tween.tween_method(
		Callable(self, "_set_portrait_word_paper_peel_progress"),
		0.0,
		1.0,
		PORTRAIT_ROUND_END_PAPER_FLIP_DURATION
	)
	# Keep the peel speed constant from start to finish; the previous QUAD/EASE_OUT
	# curve visibly slowed the paper as it approached the right edge.
	mask_tweener.set_trans(Tween.TRANS_LINEAR)
	flip_tween.finished.connect(
		Callable(self, "_finish_in_place_result_paper_peel").bind(paper_layer, true),
		CONNECT_ONE_SHOT
	)

func _finish_in_place_result_paper_peel(paper_layer: Control, animated: bool) -> void:
	_finalize_portrait_word_paper_peel_visuals(paper_layer)
	if !animated and (
		result_search_button != null
		and is_instance_valid(result_search_button)
	):
		result_search_button.set("disabled", false)
		result_search_button.visible = true
	_show_in_place_result_action_button(animated)

func _show_in_place_result_action_button(animated: bool) -> void:
	if content == null or !is_instance_valid(content):
		return
	hints_finalize_requested.emit()
	if (
		result_continue_button != null
		and is_instance_valid(result_continue_button)
	):
		return
	var continue_action := Callable(self, "_request_continue")
	continue_available.emit()
	var action_button := _stage_main_button(
		action_rect,
		continue_action,
		continue_caption,
		22,
		false,
		0.32,
		false,
		false,
		false,
		LONG_BUTTON_COLOR_ORANGE
	)
	action_button.set("drop_shadow_enabled", true)
	action_button.z_index = 50
	result_continue_button = action_button
	if attempt_collection_pending:
		action_button.visible = false
		action_button.modulate.a = 0.0
		action_button.set("disabled", true)
		action_button.set("attention_bounce_enabled", false)
		return
	# Use the shared StageLongButton attention loop. It keeps cycling and yields
	# to the standard pressed-state animation while the player touches the button.
	action_button.set("attention_bounce_enabled", true)
	if !animated:
		action_button.visible = true
		action_button.modulate.a = 1.0
		return

	action_button.visible = true
	action_button.modulate.a = 0.0
	var alpha_tween := _tween(action_button)
	alpha_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	alpha_tween.tween_property(
		action_button,
		"modulate:a",
		1.0,
		PORTRAIT_INLINE_RESULT_CONTINUE_GROW_DURATION
	)

func _reveal_in_place_result_action_after_attempt_stars() -> void:
	var action_button: Control = result_continue_button
	if (
		action_button == null
		or !is_instance_valid(action_button)
		or !action_button.is_inside_tree()
	):
		return
	action_button.visible = true
	action_button.modulate.a = 0.0
	action_button.set("disabled", false)
	action_button.set("attention_bounce_enabled", true)
	var reveal_tween := _tween(action_button)
	reveal_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var fade := reveal_tween.tween_property(
		action_button,
		"modulate:a",
		1.0,
		PORTRAIT_INLINE_RESULT_CONTINUE_GROW_DURATION
	)
	fade.set_trans(Tween.TRANS_SINE)
	fade.set_ease(Tween.EASE_OUT)

static func _build_portrait_result_word_marker_layer(
	layer_name: String,
	layer_size: Vector2,
	stroke_specs: Array,
	stroke_width: float
) -> CanvasGroup:
	var layer := CanvasGroup.new()
	layer.name = layer_name
	layer.self_modulate = Color(1.0, 1.0, 1.0, 0.0)
	var marker_width: float = maxf(layer_size.x, 10.0)
	var marker_height: float = maxf(layer_size.y, 10.0)
	for index in range(stroke_specs.size()):
		var spec: Dictionary = stroke_specs[index]
		var jitter: Array = spec.get("jitter", [])
		var start_x: float = float(spec.get("left", 0.0))
		var end_x: float = marker_width + float(spec.get("right", 0.0))
		var y_start: float = marker_height * float(spec.get("y_start", 0.5))
		var y_end: float = marker_height * float(spec.get("y_end", 0.5))
		var points := PackedVector2Array()
		for point_index in range(jitter.size()):
			var t: float = float(point_index) / maxf(float(jitter.size() - 1), 1.0)
			var y_base: float = lerpf(y_start, y_end, t)
			var y_offset: float = float(jitter[point_index]) * marker_height
			points.append(Vector2(lerpf(start_x, end_x, t), y_base + y_offset))
		var stroke := Line2D.new()
		stroke.name = "%sStroke%d" % [layer_name, index]
		stroke.points = points
		stroke.width = stroke_width
		stroke.begin_cap_mode = Line2D.LINE_CAP_ROUND
		stroke.end_cap_mode = Line2D.LINE_CAP_ROUND
		stroke.joint_mode = Line2D.LINE_JOINT_ROUND
		stroke.default_color = Color.WHITE
		stroke.antialiased = true
		layer.add_child(stroke)
	return layer

static func _stage_portrait_result_word_marker(marker_size: Vector2) -> Node2D:
	# Compose a broad base highlight plus a tighter darker pass on top.
	# Each pass is rendered into its own CanvasGroup so opacity is applied once per
	# layer instead of accumulating at stroke crossings.
	var marker := Node2D.new()
	marker.name = "ResultWordMarker"
	var marker_width: float = maxf(marker_size.x, 10.0)
	var marker_height: float = maxf(marker_size.y, 10.0)
	var base_stroke_specs := [
		{
			"y_start": 0.18,
			"y_end": 0.24,
			"left": -10.0,
			"right": 16.0,
			"jitter": [0.04, -0.03, 0.03, -0.02, 0.04, -0.03, 0.02, -0.02, 0.03],
		},
		{
			"y_start": 0.33,
			"y_end": 0.27,
			"left": -20.0,
			"right": 14.0,
			"jitter": [-0.02, 0.03, -0.03, 0.02, -0.01, 0.03, -0.02, 0.02, -0.02],
		},
		{
			"y_start": 0.45,
			"y_end": 0.56,
			"left": -34.0,
			"right": 30.0,
			"jitter": [0.03, -0.03, 0.04, -0.02, 0.03, -0.02, 0.03, -0.03, 0.02],
		},
		{
			"y_start": 0.66,
			"y_end": 0.58,
			"left": -24.0,
			"right": 18.0,
			"jitter": [-0.03, 0.02, -0.02, 0.03, -0.02, 0.02, -0.01, 0.02, -0.02],
		},
		{
			"y_start": 0.80,
			"y_end": 0.86,
			"left": -8.0,
			"right": 10.0,
			"jitter": [0.03, -0.02, 0.02, -0.03, 0.03, -0.03, 0.02, -0.02, 0.01],
		},
	]
	var base_layer := _build_portrait_result_word_marker_layer(
		"BaseLayer",
		Vector2(marker_width, marker_height),
		base_stroke_specs,
		maxf(marker_height * 0.24, 13.0)
	)
	marker.add_child(base_layer)
	var detail_margin_x: float = 8.0
	var detail_margin_y: float = 4.0
	var detail_size := Vector2(
		maxf(marker_width - detail_margin_x * 2.0, 10.0),
		maxf(marker_height - detail_margin_y * 2.0, 10.0)
	)
	var detail_stroke_specs := [
		{
			"y_start": 0.22,
			"y_end": 0.29,
			"left": -6.0,
			"right": 10.0,
			"jitter": [0.03, -0.02, 0.02, -0.02, 0.03, -0.02, 0.02],
		},
		{
			"y_start": 0.46,
			"y_end": 0.40,
			"left": -12.0,
			"right": 12.0,
			"jitter": [-0.02, 0.02, -0.03, 0.02, -0.01, 0.02, -0.02],
		},
		{
			"y_start": 0.66,
			"y_end": 0.74,
			"left": -8.0,
			"right": 8.0,
			"jitter": [0.02, -0.02, 0.03, -0.02, 0.02, -0.01, 0.01],
		},
	]
	var detail_layer := _build_portrait_result_word_marker_layer(
		"DetailLayer",
		detail_size,
		detail_stroke_specs,
		maxf(detail_size.y * 0.20, 10.0)
	)
	detail_layer.scale = Vector2(1.1, 1.1)
	detail_layer.position = Vector2(detail_margin_x, detail_margin_y) - detail_size * 0.05
	marker.add_child(detail_layer)
	return marker

func _set_portrait_result_word_marker_color(result_controls: Dictionary, color: Color) -> void:
	var marker := result_controls.get("word_marker") as Node2D
	if marker == null or !is_instance_valid(marker):
		return
	var marker_color: Color = PORTRAIT_UI_PALETTE.MARKER_SUCCESS
	if color == StageLetterButton.CROSSED_COLOR:
		marker_color = PORTRAIT_UI_PALETTE.MARKER_ERROR
	var base_layer := marker.get_node_or_null("BaseLayer") as CanvasGroup
	if base_layer != null and is_instance_valid(base_layer):
		base_layer.self_modulate = Color(
			marker_color.r,
			marker_color.g,
			marker_color.b,
			0.35
		)
	var detail_layer := marker.get_node_or_null("DetailLayer") as CanvasGroup
	if detail_layer != null and is_instance_valid(detail_layer):
		var darker := Color(
			clampf(marker_color.r * 0.9, 0.0, 1.0),
			clampf(marker_color.g * 0.9, 0.0, 1.0),
			clampf(marker_color.b * 0.9, 0.0, 1.0),
			0.7
		)
		detail_layer.self_modulate = darker

func _set_portrait_word_paper_peel_progress(progress: float) -> void:
	var p: float = clampf(progress, 0.0, 1.0)
	if (
		paper_mask == null
		or !is_instance_valid(paper_mask)
		or paper_front == null
		or !is_instance_valid(paper_front)
	):
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	# The mask's left edge travels across the physical viewport. Compensate the
	# paper layer by the exact opposite X offset so the front face never scales or
	# slides; only its visible portion is clipped away.
	var mask_x: float = viewport_size.x * p
	paper_mask.visible = p < 0.999
	paper_front.visible = true
	paper_front.modulate = Color.WHITE
	paper_mask.set_anchors_preset(Control.PRESET_TOP_LEFT)
	paper_mask.position = Vector2(mask_x, 0.0)
	paper_mask.size = Vector2(
		maxf(1.0, viewport_size.x - mask_x),
		viewport_size.y
	)
	paper_front.position = Vector2(-mask_x, 0.0)

	if (
		paper_backside == null
		or !is_instance_valid(paper_backside)
		or paper_backside_visual == null
		or !is_instance_valid(paper_backside_visual)
	):
		return

	var fit_scale: float = PORTRAIT_STAGE_LAYOUT.fit_scale(viewport_size)
	if fit_scale <= 0.0:
		return
	var horizontal_offset: float = PORTRAIT_STAGE_LAYOUT.horizontal_offset(viewport_size)
	var fold_stage_x: float = (mask_x - horizontal_offset) / fit_scale
	paper_backside.set(
		"stage_rect",
		Rect2(
			fold_stage_x,
			word_rect.position.y + PORTRAIT_GAME_WORD_PAPER_Y_OFFSET,
			PORTRAIT_ROUND_END_PAPER_BACKSIDE_MAX_WIDTH,
			PORTRAIT_GAME_WORD_PAPER_HEIGHT
		)
	)
	_sync_portrait_word_paper_backside_material(fold_stage_x, p)
	# Keep the reverse face opaque throughout the peel, as on Home.
	paper_backside.modulate.a = 1.0
	paper_backside.visible = p > 0.001 and p < 0.999

func _sync_portrait_word_paper_backside_material(stage_x: float, width_ratio: float) -> void:
	var shader_material := paper_backside_visual.material as ShaderMaterial
	shader_material.set_shader_parameter("stage_origin_x", stage_x)
	shader_material.set_shader_parameter("fold_width", PORTRAIT_ROUND_END_PAPER_BACKSIDE_MAX_WIDTH * width_ratio)

func _finalize_portrait_word_paper_peel_visuals(paper_layer: Control) -> void:
	if paper_layer != null and is_instance_valid(paper_layer):
		paper_layer.visible = false
	if paper_mask != null and is_instance_valid(paper_mask):
		paper_mask.visible = false
	if paper_backside != null and is_instance_valid(paper_backside):
		paper_backside.visible = false
	if (
		paper_backside_visual != null
		and is_instance_valid(paper_backside_visual)
	):
		_sync_portrait_word_paper_backside_material(0.0, 0.0)
