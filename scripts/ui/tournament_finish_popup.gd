extends Node
## Home owns this watcher and its mandatory, unclaimed tournament reward modal.
const GROUP: StringName = &"tournament_finish_popup"
const ROW = preload("res://scripts/ui/leaderboard_row.gd")
const PORTRAITS = preload("res://scripts/ui/leaderboard_portraits.gd")
const TOURNAMENT = preload("res://scripts/ui/portrait_tournament.gd")
const HOME_BUTTON = preload("res://scripts/ui/home_tournament_button.gd")
const TEXT_STYLE = preload("res://scripts/ui/button_text_style.gd")
const MATERIALS = preload("res://scripts/ui/ui_materials.gd")
var host: Node
var popup: CanvasLayer
var claim_button: Control
var _tournament_id := ""
var _claiming := false
var _error: Label

func _ready() -> void:
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(present_if_needed)
	add_child(timer)
	timer.start()
	GameState.tournament_changed.connect(_refresh)

func _refresh() -> void:
	# A score or claim signal may fire during another screen's construction.
	present_if_needed.call_deferred()

func present_if_needed() -> bool:
	if !is_inside_tree() or is_queued_for_deletion() or !is_instance_valid(host):
		return false
	if is_instance_valid(popup):
		return true
	if host.content != get_parent() or is_instance_valid(host._home_transition) or !GameState.has_accepted_legal_documents():
		return false
	if !get_tree().get_nodes_in_group(host.PORTRAIT_MODAL_POPUP_GROUP).is_empty():
		return false
	var snapshot := GameState.get_tournament_snapshot()
	if str(snapshot.phase) != "finished" or int(snapshot.reward) <= 0:
		return false
	_tournament_id = str(GameState.tournament_state.id)
	_build(snapshot)
	return true

func _build(snapshot: Dictionary) -> void:
	var previous: Control = host._portrait_popup_begin("TournamentFinishPopup", str(GROUP), 140,
		Callable(), 145.0, 736.0, false, Callable(), false)
	var stage: Control = host.content
	popup = stage.get_parent().get_parent() as CanvasLayer
	stage.z_index = 10
	var rect := Rect2(28, 145, 424, 591)
	var icon_size := Vector2.ONE * (166.4 * 0.85)
	var icon_rect := Rect2(Vector2(rect.get_center().x - icon_size.x * 0.5,
		rect.position.y + host.PORTRAIT_POPUP_TOP_TRIM - icon_size.y * 0.60), icon_size)
	var glow_size: Vector2 = icon_size * host.PORTRAIT_SINGLE_PLAYER_THEME_CARD_GLOW_SCALE
	var glow: Control = host._stage_final_reward_glow(Rect2(icon_rect.get_center() - glow_size * 0.5, glow_size), Color.WHITE)
	(glow.get_parent() as CanvasItem).z_index = -2
	glow.modulate.a = 0.0
	var trophy: Control = host._stage_texture(icon_rect, HOME_BUTTON.TROPHY)
	trophy.name = "TournamentFinishTrophy"
	trophy.material = MATERIALS.grayscale()
	trophy.z_index = -1
	host._arm_word_comment_theme_icon_intro(stage, trophy, glow)
	host._arm_word_comment_theme_glow_reveal(stage, glow)
	var title := tr("TOURNAMENT_END_TITLE")
	var title_size := 30
	var style: Dictionary = host._portrait_popup_style()
	while title_size > 16:
		var resolved_size := int(round(round(title_size * float(style.title_scale)) * float(style.heading_scale)))
		if host.UI_DISPLAY_FONT.get_string_size(title.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, resolved_size).x <= rect.size.x - 32.0:
			break
		title_size -= 1
	host._portrait_popup_shell(rect, title, Callable(), title_size,
		host.PORTRAIT_BLUE, host.PORTRAIT_DARK_BLUE, host.PORTRAIT_ORANGE, "", false)
	var panel_rect: Rect2 = host.PORTRAIT_REFILL_STATUS_RECT
	var panel: Control = host._stage_panel(panel_rect, host.PORTRAIT_UI_PALETTE.THEME_CARD,
		host.PORTRAIT_REFILL_STATUS_CORNER_RADIUS)
	panel.name = "TournamentFinishDescriptionPanel"
	panel.z_index = 8
	var gift := int(snapshot.rank) == 1
	var reward_texture: Texture2D = TOURNAMENT.GIFT if gift else TOURNAMENT.COIN_PACK
	var reward_size := Vector2.ONE * (115.2 * 0.95 if gift else 108.0 * 0.97)
	var reward_bounds := Rect2(Vector2(139, panel_rect.get_center().y) - reward_size * 0.5, reward_size)
	var reward_rect: Rect2 = host._fit_stage_rect_keep_aspect(reward_bounds, reward_texture.get_size())
	# Raise the reward-chain counter slightly into the coin art, then center the
	# complete art/counter composition rather than the coin texture alone.
	var amount_height := 34.0
	var amount_overlap: float = 26.0 * reward_rect.size.y / host.PORTRAIT_FINAL_REWARD_COIN_SIZE.y + 12.0
	if !gift:
		var block_height := reward_rect.size.y - amount_overlap + amount_height
		reward_rect.position.y = panel_rect.get_center().y - block_height * 0.5
	host._stage_refill_status_glow(panel, panel_rect, reward_rect, &"TournamentFinishRewardGlow")
	var reward: Control = host._stage_texture(reward_rect, reward_texture)
	reward.name = "TournamentFinishReward"
	reward.z_index = 11
	if !gift:
		var amount: Label = host._stage_label(Rect2(67, reward_rect.end.y - amount_overlap, 144, amount_height), "x%d" % int(snapshot.reward), 26,
			Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
		amount.name = "TournamentFinishAmount"
		TEXT_STYLE.apply_display(amount)
		amount.z_index = 11
	var description: Label = host._stage_label(Rect2(211, 247, 207, 126), tr("TOURNAMENT_FINISH_PROMPT"),
		22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	description.name = "TournamentFinishDescription"
	description.add_theme_font_override("font", host.UI_REGULAR_FONT)
	description.clip_text = false
	TEXT_STYLE.apply_regular_display(description)
	description.z_index = 11
	var portraits := PORTRAITS.new()
	stage.add_child(portraits)
	for index in range(3):
		var entry: Dictionary = snapshot.rows[index].duplicate(true)
		var mine := bool(entry.mine)
		if mine:
			entry.merge(GameState.get_player_profile(), true)
		var holder: Control = host._stage_holder(Rect2(48, 405 + index * 68, 384, 64), Control.MOUSE_FILTER_IGNORE)
		holder.name = "TournamentFinishPlayerResult" if mine else "TournamentFinishPlace%d" % (index + 1)
		holder.set_meta("rank", index + 1)
		holder.z_index = 11
		var row := Control.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.scale = Vector2.ONE * (384.0 / ROW.CARD_WIDTH)
		holder.add_child(row)
		ROW.populate(row, entry, mine, portraits, Callable(host, "_grouped_counter_text"), Vector2.ZERO)
	claim_button = host._stage_portrait_popup_main_button(Rect2(90, 646, 300, 56), _claim,
		tr("TOURNAMENT_CLAIM_REWARD"), 18, false, 0.32, false, false, false, host.LONG_BUTTON_COLOR_GREEN)
	claim_button.name = "TournamentFinishClaim"
	claim_button.z_index = 16
	claim_button.set("drop_shadow_enabled", true)
	if stage.open_bounce_complete:
		claim_button.set("attention_bounce_enabled", true)
	else:
		stage.open_bounce_finished.connect(claim_button.set.bind("attention_bounce_enabled", true), CONNECT_ONE_SHOT)
	_error = host._stage_label(Rect2(48, 608, 384, 31), "", 15, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_error.name = "TournamentFinishError"
	_error.z_index = 11
	host.content = previous

func _claim() -> void:
	if _claiming or !is_instance_valid(popup) or str(GameState.tournament_state.get("id", "")) != _tournament_id:
		return
	_claiming = true
	var award := GameState.claim_tournament_reward()
	if !bool(award.get("ok", false)):
		_claiming = false
		_error.text = tr("TOURNAMENT_SAVE_ERROR")
		return
	# The existing reward screen only presents this durable payment.
	_remove_popup()
	host._show_tournament_reward(award)

func _remove_popup() -> void:
	if is_instance_valid(popup) and popup.get_parent() != null:
		popup.hide()
		popup.remove_from_group(GROUP)
		popup.remove_from_group(host.PORTRAIT_MODAL_POPUP_GROUP)
		popup.queue_free()
	popup = null

func _exit_tree() -> void:
	if GameState.tournament_changed.is_connected(_refresh):
		GameState.tournament_changed.disconnect(_refresh)
	_remove_popup()
