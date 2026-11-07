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
var multiplier_meter: Control
var _meter_enabled: bool = false
var base_amount: int = 0
var deferred_coin_amount: int = 0
var coin_content_builder: Callable
var collect_rect_builder: Callable
var banner_height_stage: float = 50.0
var button_gap_stage: float = -1.0
var _controls_raise: float = 0.0
const COLLECT_WIDTH_SCALE: float = 0.85
const BUTTONS_MIN_RAISE: float = 32.0
const BANNER_BUTTON_GAP: float = 24.0

func _portrait_final_reward_center_rect(size: Vector2) -> Rect2:
	var rect: Rect2 = super._portrait_final_reward_center_rect(size)
	if _meter_enabled:
		# Keep the coin pack clear of the raised meter at the reference aspect.
		rect.position.y -= 45.0
		rect.position.y -= maxf(_controls_raise - BUTTONS_MIN_RAISE, 0.0)
	return rect

func selected_multiplier() -> float:
	return multiplier_meter.selected_multiplier() if is_instance_valid(multiplier_meter) else 2.0

func _sync_final_reward_double_button_content(button: Control) -> void:
	super._sync_final_reward_double_button_content(button)
	if !_meter_enabled:
		return
	button.set("button_text", "%s %d" % [tr("REWARD_GET"), roundi(base_amount * selected_multiplier())])
	button.set("trailing_icon_stage_size", Vector2(28, 28))

func stop() -> void:
	super.stop()
	if is_instance_valid(multiplier_meter):
		multiplier_meter.running = false
	if is_instance_valid(prize):
		PORTRAIT_REWARD_SPARKLES._stop_reward_coin_sparkles(prize, PORTRAIT_FINAL_REWARD_SPARKLE_BASE_SCALE)
	if is_instance_valid(action):
		action.set("attention_bounce_enabled", false)
		action.set("button_disabled", true)
		action.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _meter_enabled and is_instance_valid(collect):
		collect.set("button_disabled", true)
		collect.mouse_filter = Control.MOUSE_FILTER_IGNORE
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

func build(parent: Control, reward_amount: int, source_rect: Rect2, ads_enabled: bool, level_number: int = 1) -> void:
	if prize != null or _stopped:
		return
	content = parent
	base_amount = reward_amount
	_meter_enabled = ads_enabled and level_number >= PORTRAIT_GAME_DESIGN.get_int("economy.rewards.stage_ad_multipliers_from_level")
	var collect_rect := Rect2(Vector2(90, PORTRAIT_FINAL_REWARD_COLLECT_RECT.position.y + 24), PORTRAIT_STAGE_LAYOUT.POPUP_COIN_BUTTON_SIZE)
	if _meter_enabled:
		if collect_rect_builder.is_valid():
			collect_rect = collect_rect_builder.call(collect_rect)
		var collect_center_x: float = collect_rect.get_center().x
		collect_rect.size.x *= COLLECT_WIDTH_SCALE
		collect_rect.position.x = collect_center_x - collect_rect.size.x * 0.5
		_controls_raise = maxf(BUTTONS_MIN_RAISE, collect_rect.end.y - (PORTRAIT_STAGE_SIZE.y - banner_height_stage - BANNER_BUTTON_GAP))
		collect_rect.position.y -= _controls_raise
	var target_coin_rect: Rect2 = _portrait_final_reward_center_rect(
		PORTRAIT_FINAL_REWARD_COIN_SIZE
	)
	var reward_glow_size: Vector2 = PORTRAIT_FINAL_REWARD_GLOW_SIZE * 1.30
	var target_glow_rect: Rect2 = Rect2(
		target_coin_rect.get_center() - reward_glow_size * 0.5,
		reward_glow_size
	)
	var glow := _stage_final_reward_glow(target_glow_rect)
	FADE.set_opacity(glow, 0.0)
	# Stage-completion coin rewards use the same shadow-aware coin-pack holder
	# as the one-stage level reward. The old _stage_texture() path bypassed the
	# shader extrusion completely, which is why this screen had no visible shadow.
	var transition_pack := _stage_main_reward_coin_pack_transition(
		source_rect
	)
	transition_pack.name = "StageCoinLargeReward"
	FADE.set_opacity(transition_pack, 0.0)
	transition_pack.z_index = 20
	var amount_label := _stage_label(
		_portrait_final_reward_amount_rect(target_coin_rect),
		_single_player_reward_chain_count_text(reward_amount),
		int(round(float(PORTRAIT_FINAL_REWARD_COUNT_FONT_SIZE) * 1.20)),
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	amount_label.name = "StageCoinLargeRewardAmount"
	amount_label.visible = !_meter_enabled
	amount_label.add_theme_font_override("font", UI_DISPLAY_FONT)
	amount_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	amount_label.clip_text = false
	BUTTON_TEXT_STYLE_SCRIPT.apply_display(amount_label)
	amount_label.modulate.a = 0.0
	amount_label.z_index = 21
	FADE.wrap(amount_label)

	var reward_content: Control = content
	var bottom_group := Control.new()
	bottom_group.name = "PortraitBottomAttached"
	bottom_group.set_meta("portrait_bottom_attached", true)
	bottom_group.set_anchors_preset(Control.PRESET_FULL_RECT)
	bottom_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(bottom_group)
	content = bottom_group
	var action_rect: Rect2 = _portrait_primary_bottom_button_rect(PORTRAIT_FINAL_REWARD_DOUBLE_BUTTON_RECT)
	var action_group_shift: float = 0.0
	if _meter_enabled:
		action_rect.position.y -= _controls_raise
		if button_gap_stage >= 0.0:
			action_group_shift = collect_rect.position.y - action_rect.end.y - button_gap_stage
			action_rect.position.y += action_group_shift
	var action_button: Control
	var collect_holder: Control = null
	var collect_button: Button = null
	if ads_enabled:
		action_button = _stage_main_button(
			action_rect,
			Callable(self, "_request_double"),
			tr("REWARD_GET" if _meter_enabled else "REWARD_GET_X2"),
			22,
			true,
			0.32,
			false,
			false,
			false,
			LONG_BUTTON_COLOR_BLUE
		)
		action_button.name = "StageCoinRewardDoubleButton"
		if _meter_enabled:
			var meter_rect: Rect2 = _portrait_primary_bottom_button_rect(PORTRAIT_FINAL_REWARD_DOUBLE_BUTTON_RECT)
			meter_rect.position.x = 42.0
			meter_rect.position.y -= 121.0
			meter_rect.position.y -= _controls_raise
			meter_rect.position.y += action_group_shift
			meter_rect.size = Vector2((PORTRAIT_STAGE_SIZE.x - 40.0) * 0.9, 94.6)
			var meter_holder: Control = _stage_holder(meter_rect, Control.MOUSE_FILTER_IGNORE)
			meter_holder.name = "StageRewardMultiplierHolder"
			meter_holder.z_index = 120
			multiplier_meter = preload("res://scripts/ui/stage_reward_multiplier.gd").new()
			multiplier_meter.name = "StageRewardMultiplier"
			meter_holder.add_child(multiplier_meter)
			multiplier_meter.size = meter_rect.size
			multiplier_meter.build(action_button)
			multiplier_meter.selection_changed.connect(_update_ad_amount)
			FADE.branch(meter_holder)
			FADE.set_opacity(meter_holder, 0.0)
		action_button.set_meta(&"single_shine_after_reveal", true)
		_configure_final_reward_double_button(action_button)
		if _meter_enabled:
			collect_holder = _stage_main_button(
				collect_rect,
				Callable(self, "_request_continue"), "", 18, true, 0.32, false, false, false, LONG_BUTTON_COLOR_BLUE)
			collect_holder.name = "StageCoinRewardCollect"
			collect_holder.z_index = 120
			collect_holder.set("drop_shadow_enabled", true)
			if coin_content_builder.is_valid():
				var row: Dictionary = coin_content_builder.call(collect_holder, tr("REWARD_GET"), reward_amount)
				var price: Label = row["price"]
				price.remove_from_group(&"portrait_coin_price_badge_label")
			else:
				collect_holder.set("button_text", "%s %d" % [tr("REWARD_GET"), reward_amount])
				collect_holder.set("trailing_icon_texture", SOFT_CURRENCY_COIN_TEXTURE)
			FADE.set_opacity(collect_holder, 0.0)
		else:
			var collect_controls: Dictionary = _stage_final_reward_collect_text(
				PORTRAIT_FINAL_REWARD_COLLECT_RECT, -1, Callable(self, "_request_continue"))
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
	FADE.set_opacity(action_button, 0.0)
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
	# The chain's opacity owner also fades its count; avoid a second alpha on it.
	replace_tween.parallel().tween_property(
		FADE.branch(transition_pack),
		"opacity",
		1.0,
		PORTRAIT_FINAL_REWARD_ICON_CROSSFADE_DURATION
	)
	replace_tween.parallel().tween_property(
		FADE.branch(chain_holder), "opacity",
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
	replace_tween.finished.connect(_hide_replaced_reward_visuals.bind(chain_holder, hero_texture), CONNECT_ONE_SHOT)
	replace_tween.finished.connect(Callable(self, "_reveal_stage_reward").bind(transition_pack, glow, amount_label, double_button, collect_holder, collect_button), CONNECT_ONE_SHOT)

func _hide_replaced_reward_visuals(chain_holder: Control, hero_texture: TextureRect) -> void:
	if _stopped or !is_inside_tree():
		return
	# Alpha-zero text groups still issue offscreen draw calls. These visuals are
	# no longer used once the replacement has finished, so stop submitting them.
	if is_instance_valid(chain_holder):
		chain_holder.hide()
	if is_instance_valid(hero_texture):
		hero_texture.hide()

func _reveal_stage_reward(transition_pack: Control, glow: Control, amount_label: Label, double_button: Control, collect_holder: Control, collect_button: Button) -> void:
	if _stopped or !is_inside_tree():
		return

	if glow != null and is_instance_valid(glow):
		_start_final_reward_glow_rotation(glow)
		var reveal_tween := _tween(glow)
		reveal_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		reveal_tween.set_parallel(true)
		reveal_tween.tween_property(
			FADE.branch(glow),
			"opacity",
			PORTRAIT_FINAL_REWARD_GLOW_ALPHA,
			PORTRAIT_FINAL_REWARD_ACTION_REVEAL_DURATION
		)
		if amount_label != null and is_instance_valid(amount_label):
			reveal_tween.tween_property(
				FADE.wrap(amount_label),
				"opacity",
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
	if is_instance_valid(multiplier_meter):
		multiplier_meter.running = true
		var meter_reveal := _tween(multiplier_meter)
		meter_reveal.tween_property(FADE.branch(multiplier_meter.get_parent()), "opacity", 1.0, PORTRAIT_FINAL_REWARD_ACTION_REVEAL_DURATION)

func _update_ad_amount() -> void:
	if is_instance_valid(action):
		# Icons, fonts and shadows are configured once when the offer is built.
		var caption := "%s %d" % [tr("REWARD_GET"), roundi(base_amount * selected_multiplier())]
		if str(action.get("button_text")) != caption.to_upper():
			action.set("button_text", caption)

func _reveal_final_reward_actions(double_button: Control, holder: Control, hit: Button) -> void:
	if !_meter_enabled:
		super._reveal_final_reward_actions(double_button, holder, hit)
		return
	super._reveal_final_reward_actions(double_button, null, null)
	_schedule_final_reward_collect(holder, _reveal_native_collect.bind(holder))

func _reveal_native_collect(holder: Control) -> void:
	super._reveal_final_reward_actions(holder, null, null)

func defers_coin_collection() -> bool:
	return _meter_enabled
