extends "res://scripts/ui/portrait_reward_prize.gd"
## Large coin reward for a completed stage. Receives amount and frame controls.
## Emits claim-peak and action intents; never grants or persists any reward.

signal claim_peak(source: Control)
signal double_requested
signal continue_requested

var prize: Control
var prize_glow: Control
var prize_amount: Label
var action: Control
var collect: Control
var collect_hit: Button
var _claim_emitted: bool = false
var _transition_started: bool = false

func stop() -> void:
	super.stop()
	if is_instance_valid(prize):
		PORTRAIT_REWARD_SPARKLES._stop_reward_coin_sparkles(prize, PORTRAIT_FINAL_REWARD_SPARKLE_BASE_SCALE)
	if is_instance_valid(action):
		action.set("attention_bounce_enabled", false)
		action.set("button_disabled", true)
		action.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_instance_valid(collect_hit):
		collect_hit.disabled = true
		collect_hit.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _request_double() -> void:
	if !_stopped:
		double_requested.emit()

func _request_continue() -> void:
	if !_stopped:
		continue_requested.emit()

func _on_claim_peak(source: Control) -> void:
	if _stopped or _claim_emitted or !is_inside_tree():
		return
	_claim_emitted = true
	claim_peak.emit(source)

func build(parent: Control, reward_amount: int, source_rect: Rect2, ads_enabled: bool) -> void:
	if prize != null or _stopped:
		return
	content = parent
	var target_coin_rect: Rect2 = _portrait_final_reward_center_rect(
		PORTRAIT_FINAL_REWARD_COIN_SIZE
	)
	var reward_glow_size: Vector2 = PORTRAIT_FINAL_REWARD_GLOW_SIZE * 1.30
	var target_glow_rect: Rect2 = Rect2(
		target_coin_rect.get_center() - reward_glow_size * 0.5,
		reward_glow_size
	)
	var glow := _stage_final_reward_glow(target_glow_rect)
	# Stage-completion coin rewards use the same shadow-aware coin-pack holder
	# as the one-stage level reward. The old _stage_texture() path bypassed the
	# shader extrusion completely, which is why this screen had no visible shadow.
	var transition_pack := _stage_main_reward_coin_pack_transition(
		source_rect
	)
	transition_pack.name = "StageCoinLargeReward"
	transition_pack.modulate.a = 0.0
	transition_pack.z_index = 20
	var amount_label := _stage_label(
		_portrait_final_reward_amount_rect(target_coin_rect),
		_single_player_reward_chain_count_text(reward_amount),
		int(round(float(PORTRAIT_FINAL_REWARD_COUNT_FONT_SIZE) * 1.20)),
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	amount_label.name = "StageCoinLargeRewardAmount"
	amount_label.add_theme_font_override("font", UI_DISPLAY_FONT)
	amount_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	amount_label.clip_text = false
	BUTTON_TEXT_STYLE_SCRIPT.apply_display(amount_label)
	amount_label.modulate.a = 0.0
	amount_label.z_index = 21

	var reward_content: Control = content
	var bottom_group := Control.new()
	bottom_group.name = "PortraitBottomAttached"
	bottom_group.set_meta("portrait_bottom_attached", true)
	bottom_group.set_anchors_preset(Control.PRESET_FULL_RECT)
	bottom_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(bottom_group)
	content = bottom_group
	var action_button: Control
	var collect_holder: Control = null
	var collect_button: Button = null
	if ads_enabled:
		action_button = _stage_main_button(
			_portrait_primary_bottom_button_rect(PORTRAIT_FINAL_REWARD_DOUBLE_BUTTON_RECT),
			Callable(self, "_request_double"),
			tr("REWARD_DOUBLE"),
			22,
			true,
			0.32,
			false,
			false,
			false,
			LONG_BUTTON_COLOR_BLUE
		)
		action_button.name = "StageCoinRewardDoubleButton"
		action_button.set_meta(&"single_shine_after_reveal", true)
		_configure_final_reward_double_button(action_button)
		var collect_controls: Dictionary = _stage_final_reward_collect_text(
			PORTRAIT_FINAL_REWARD_COLLECT_RECT,
			-1,
			Callable(self, "_request_continue")
		)
		collect_holder = collect_controls.get("holder") as Control
		collect_button = collect_controls.get("button") as Button
	else:
		action_button = _stage_main_button(
			_portrait_primary_bottom_button_rect(PORTRAIT_FINAL_REWARD_DOUBLE_BUTTON_RECT),
			Callable(self, "_request_continue"),
			tr("COMMON_CONTINUE"),
			22,
			false,
			0.32,
			false,
			false,
			false,
			LONG_BUTTON_COLOR_ORANGE
		)
		action_button.name = "StageCoinRewardContinueButton"
		action_button.set("drop_shadow_enabled", true)
		action_button.set_meta(&"attention_after_reveal", true)
	action_button.modulate.a = 0.0
	action_button.z_index = 120
	action_button.set("button_disabled", true)
	content = reward_content
	prize = transition_pack
	prize_glow = glow
	prize_amount = amount_label
	action = action_button
	collect = collect_holder
	collect_hit = collect_button

const LONG_BUTTON_COLOR_ORANGE: int = 0

var UI_DISPLAY_FONT: Font = UI_FONTS.display_font()

const PORTRAIT_GAME_ACTION_Y_SCALE: float = 0.95

const PORTRAIT_SINGLE_REWARD_TITLE_BLOCK_COLOR := PORTRAIT_UI_PALETTE.REWARD_HEADER

const PORTRAIT_FINAL_REWARD_GLOW_SIZE := Vector2(316.0, 316.0)

const PORTRAIT_FINAL_REWARD_COIN_SIZE := Vector2(172.8, 172.8)

const PORTRAIT_FINAL_REWARD_COUNT_FONT_SIZE: int = 40

const PORTRAIT_FINAL_REWARD_DOUBLE_BUTTON_RECT := Rect2(
	90.0,
	606.0 * PORTRAIT_GAME_ACTION_Y_SCALE,
	300.0,
	64.0
)

const PORTRAIT_FINAL_REWARD_COLLECT_RECT := Rect2(
	90.0,
	690.0 * PORTRAIT_GAME_ACTION_Y_SCALE,
	300.0,
	45.0
)

var PORTRAIT_FINAL_REWARD_CHAIN_HOLD_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.final_reward.chain_hold_seconds"
)

var PORTRAIT_FINAL_REWARD_ICON_CROSSFADE_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.final_reward.icon_crossfade_seconds"
)

var PORTRAIT_FINAL_REWARD_REPLACE_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.final_reward.replace_seconds"
)

var PORTRAIT_FINAL_REWARD_BACKGROUND_FADE_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.final_reward.background_fade_seconds"
)

const PORTRAIT_FINAL_REWARD_GLOW_ALPHA: float = 0.7

const PORTRAIT_BLUE := PORTRAIT_UI_PALETTE.UI_BLUE

func begin_transition(
	chain_holder: Control,
	hero_texture: TextureRect,
	source_coin: Control,
	source_count: Label,
	transition_pack: Control,
	background_overlay: Control,
	title_panel: Panel,
	glow: Control,
	amount_label: Label,
	double_button: Control,
	collect_holder: Control,
	collect_button: Button
) -> void:
	if _stopped or _transition_started:
		return
	_transition_started = true
	if transition_pack == null or !is_instance_valid(transition_pack) or !transition_pack.is_inside_tree():
		return
	var hold_tween := _tween(transition_pack)
	hold_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	hold_tween.tween_interval(PORTRAIT_FINAL_REWARD_CHAIN_HOLD_DURATION)
	hold_tween.finished.connect(Callable(self, "_replace_stage_reward").bind(chain_holder, hero_texture, source_coin, source_count, transition_pack, background_overlay, title_panel, glow, amount_label, double_button, collect_holder, collect_button), CONNECT_ONE_SHOT)

func _replace_stage_reward(
	chain_holder: Control,
	hero_texture: TextureRect,
	source_coin: Control,
	source_count: Label,
	transition_pack: Control,
	background_overlay: Control,
	title_panel: Panel,
	glow: Control,
	amount_label: Label,
	double_button: Control,
	collect_holder: Control,
	collect_button: Button
) -> void:
	if _stopped or !is_inside_tree():
		return
	if (
		chain_holder == null
		or !is_instance_valid(chain_holder)
		or !chain_holder.is_inside_tree()
		or source_coin == null
		or !is_instance_valid(source_coin)
		or !source_coin.is_inside_tree()
	):
		return

	if hero_texture != null and is_instance_valid(hero_texture):
		hero_texture.pivot_offset = hero_texture.size * 0.5
	var target_coin_rect: Rect2 = _portrait_final_reward_center_rect(
		PORTRAIT_FINAL_REWARD_COIN_SIZE
	)
	var replace_tween := _tween(transition_pack)
	replace_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var move_pack := replace_tween.tween_property(
		transition_pack,
		"stage_rect",
		target_coin_rect,
		PORTRAIT_FINAL_REWARD_REPLACE_DURATION
	)
	move_pack.set_trans(Tween.TRANS_LINEAR)
	replace_tween.parallel().tween_property(
		source_coin,
		"modulate:a",
		0.0,
		PORTRAIT_FINAL_REWARD_ICON_CROSSFADE_DURATION
	)
	if source_count != null and is_instance_valid(source_count) and source_count.is_inside_tree():
		replace_tween.parallel().tween_property(
			source_count,
			"modulate:a",
			0.0,
			PORTRAIT_FINAL_REWARD_ICON_CROSSFADE_DURATION
		)
	replace_tween.parallel().tween_property(
		transition_pack,
		"modulate:a",
		1.0,
		PORTRAIT_FINAL_REWARD_ICON_CROSSFADE_DURATION
	)
	replace_tween.parallel().tween_property(
		chain_holder,
		"modulate:a",
		0.0,
		PORTRAIT_FINAL_REWARD_REPLACE_DURATION * 0.72
	)
	if hero_texture != null and is_instance_valid(hero_texture):
		var hero_fade := replace_tween.parallel().tween_property(
			hero_texture,
			"modulate:a",
			0.0,
			PORTRAIT_FINAL_REWARD_REPLACE_DURATION
		)
		hero_fade.set_trans(Tween.TRANS_QUAD)
		hero_fade.set_ease(Tween.EASE_IN)
	if (
		(background_overlay != null and is_instance_valid(background_overlay))
		or (title_panel != null and is_instance_valid(title_panel))
	):
		var backdrop_tween := _tween(transition_pack)
		backdrop_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		backdrop_tween.set_parallel(true)
		if background_overlay != null and is_instance_valid(background_overlay):
			var backdrop_fade := backdrop_tween.tween_property(
				background_overlay,
				"modulate:a",
				1.0,
				PORTRAIT_FINAL_REWARD_BACKGROUND_FADE_DURATION
			)
			backdrop_fade.set_trans(Tween.TRANS_SINE)
			backdrop_fade.set_ease(Tween.EASE_IN_OUT)
		if title_panel != null and is_instance_valid(title_panel):
			backdrop_tween.tween_method(
				Callable(self, "_set_panel_fill_color").bind(title_panel),
				PORTRAIT_SINGLE_REWARD_TITLE_BLOCK_COLOR,
				PORTRAIT_BLUE,
				PORTRAIT_FINAL_REWARD_BACKGROUND_FADE_DURATION
			)
	replace_tween.finished.connect(Callable(self, "_reveal_stage_reward").bind(transition_pack, glow, amount_label, double_button, collect_holder, collect_button), CONNECT_ONE_SHOT)

func _reveal_stage_reward(transition_pack: Control, glow: Control, amount_label: Label, double_button: Control, collect_holder: Control, collect_button: Button) -> void:
	if _stopped or !is_inside_tree():
		return

	if glow != null and is_instance_valid(glow):
		_start_final_reward_glow_rotation(glow)
		var reveal_tween := _tween(glow)
		reveal_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		reveal_tween.set_parallel(true)
		reveal_tween.tween_property(
			glow,
			"modulate:a",
			PORTRAIT_FINAL_REWARD_GLOW_ALPHA,
			PORTRAIT_FINAL_REWARD_ACTION_REVEAL_DURATION
		)
		if amount_label != null and is_instance_valid(amount_label):
			reveal_tween.tween_property(
				amount_label,
				"modulate:a",
				1.0,
				PORTRAIT_FINAL_REWARD_ACTION_REVEAL_DURATION
			)
	var peak_callback := Callable(
		self,
		"_on_claim_peak"
	).bind(transition_pack)
	await _play_final_reward_pack_bounce(transition_pack, peak_callback)
	if _stopped or !is_inside_tree():
		return
	if collect_holder != null and is_instance_valid(collect_holder):
		_play_reward_coin_sparkles(transition_pack)
	_reveal_final_reward_actions(double_button, collect_holder, collect_button)
