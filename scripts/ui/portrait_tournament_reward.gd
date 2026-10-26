extends "res://scripts/ui/portrait_stage_reward.gd"
## Presents an already persisted tournament award using campaign reward visuals.
var _host: Node
var _gift := false
var _amount := 0
var _balance_before := 0
var _collection_started := false
var _previous_frame: TextureRect

func stop() -> void:
	super.stop()
	if is_instance_valid(_previous_frame):
		_previous_frame.queue_free()
	if is_instance_valid(_host) and _host.is_inside_tree():
		_host._set_stage_reward_animated_balance(float(GameState.get_soft_currency()), GameState.STAGE_REWARD_COINS)

func present(host: Node, parent: Control, award: Dictionary) -> void:
	_host = host
	_gift = int(award.rank) == 1
	_amount = int(award.amount)
	_balance_before = GameState.get_soft_currency() - _amount
	content = parent
	_build_header(int(award.rank))
	_host._stage_coin_and_star_counters(Callable(), _host.PORTRAIT_GAME_CURRENCY_COUNTER_RECT, false, false)
	_host._set_stage_reward_animated_balance(float(_balance_before), GameState.STAGE_REWARD_COINS)
	var prize_size: Vector2 = host.PORTRAIT_LEVEL_COMPLETION_CHEST_SIZE if _gift else PORTRAIT_FINAL_REWARD_COIN_SIZE
	var rect := _portrait_final_reward_center_rect(prize_size)
	var source_rect := rect
	if award.has("source_rect"):
		var viewport_size := get_viewport_rect().size
		var fit_scale: float = PORTRAIT_STAGE_LAYOUT.fit_scale(viewport_size)
		var source_global: Rect2 = award.source_rect
		source_rect = Rect2((source_global.position - Vector2(PORTRAIT_STAGE_LAYOUT.horizontal_offset(viewport_size), 0)) / fit_scale,
			source_global.size / fit_scale)
		source_rect.position.y -= PORTRAIT_STAGE_LAYOUT.safe_top_stage(viewport_size)
	build(parent, _amount, source_rect, false)
	prize.name = "TournamentGift" if _gift else "TournamentCoins"
	FADE.set_opacity(prize, 1.0)
	if _gift:
		FADE.layout_parent(prize_amount).set("stage_rect", host._portrait_level_completion_amount_rect(rect))
	claim_peak.connect(_collect_coins)
	_crossfade_previous_frame(parent, award.get("previous_frame") as Texture2D)
	var flight := _tween(prize)
	flight.tween_property(prize, "stage_rect", rect, PORTRAIT_FINAL_REWARD_REPLACE_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	flight.finished.connect(Callable(self, "_reveal_stage_reward").bind(prize, prize_glow, prize_amount, action, collect, collect_hit), CONNECT_ONE_SHOT)

func _build_header(rank: int) -> void:
	var block_rect: Rect2 = _host.PORTRAIT_SINGLE_REWARD_TITLE_BLOCK_TOP_RECT
	_host._stage_horizontal_fill(0.0, block_rect.end.y, PORTRAIT_BLUE)
	var color: Color = PORTRAIT_UI_PALETTE.TOURNAMENT_PLACE_COLORS[clampi(rank, 1, 3) - 1]
	var subtitle: Label = _stage_label(Rect2(0, block_rect.position.y + _host.PORTRAIT_SINGLE_REWARD_SUBTITLE_TOP,
		480, _host.PORTRAIT_SINGLE_REWARD_SUBTITLE_HEIGHT), tr("TOURNAMENT_TITLE").to_upper(),
		_host.PORTRAIT_SINGLE_REWARD_SUBTITLE_FONT_SIZE, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, UI_REGULAR_FONT)
	subtitle.name = "TournamentRewardSubtitle"
	BUTTON_TEXT_STYLE_SCRIPT.apply_regular_display(subtitle)
	FADE.wrap(subtitle)
	var title: Label = _stage_label(Rect2(0, block_rect.position.y + 40, 480, _host.PORTRAIT_SINGLE_REWARD_TITLE_HEIGHT),
		tr("TOURNAMENT_PLACE_%d" % rank).to_upper(), _host.PORTRAIT_SINGLE_REWARD_TITLE_FONT_SIZE, color,
		HORIZONTAL_ALIGNMENT_CENTER, UI_DISPLAY_FONT)
	title.name = "TournamentRewardTitle"
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.clip_text = false
	BUTTON_TEXT_STYLE_SCRIPT.apply_display_tinted(title, color.darkened(0.42), color.darkened(0.62))
	FADE.wrap(title)
	for label: Label in [subtitle, title]:
		FADE.set_opacity(label, 0.0)
		_tween(label).tween_property(FADE.wrap(label), "opacity", 1.0, PORTRAIT_FINAL_REWARD_BACKGROUND_FADE_DURATION)

func _crossfade_previous_frame(parent: Control, frame_texture: Texture2D) -> void:
	if frame_texture == null:
		return
	_previous_frame = TextureRect.new()
	_previous_frame.name = "TournamentRewardPreviousFrame"
	_previous_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_previous_frame.texture = frame_texture
	_previous_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_previous_frame.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_previous_frame.z_index = 18
	parent.add_child(_previous_frame)
	_previous_frame.size = get_viewport_rect().size
	var fade := _tween(_previous_frame)
	# Finish replacing the popup before the prize reaches the center.
	fade.tween_property(FADE.branch(_previous_frame), "opacity", 0.0,
		minf(PORTRAIT_FINAL_REWARD_ICON_CROSSFADE_DURATION, PORTRAIT_FINAL_REWARD_REPLACE_DURATION))
	fade.finished.connect(_previous_frame.queue_free, CONNECT_ONE_SHOT)

func _collect_coins(source: Control) -> void:
	if _stopped or _collection_started:
		return
	_collection_started = true
	if _amount <= 0:
		return
	_host._play_single_player_reward_coin_collection(source)
	var count := _tween(self)
	count.tween_method(Callable(_host, "_set_stage_reward_animated_balance").bind(GameState.STAGE_REWARD_COINS),
		float(_balance_before), float(_balance_before + _amount), _host._single_player_reward_collection_duration()).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _stage_main_reward_coin_pack_transition(rect: Rect2, outline_pixels: float = PORTRAIT_ICON_EXTRUSION.OUTLINE.LARGE_REWARD_PIXELS) -> Control:
	if _gift:
		return _host._stage_reward_chest_transition(rect)
	return super._stage_main_reward_coin_pack_transition(rect, outline_pixels)

func _reveal_stage_reward(pack: Control, glow: Control, amount_label: Label, button: Control, collect_holder: Control, collect_button: Button) -> void:
	if _stopped or !is_inside_tree():
		return
	if _gift:
		_start_final_reward_glow_rotation(glow)
		_host._play_level_completion_chest_pressure_burst(pack, glow, amount_label, Callable(self, "_gift_opened"))
	else:
		super._reveal_stage_reward(pack, glow, amount_label, button, collect_holder, collect_button)

func _gift_opened() -> void:
	if _stopped or !is_inside_tree():
		return
	_on_claim_peak(prize)
	_reveal_final_reward_actions(action, collect, collect_hit)
