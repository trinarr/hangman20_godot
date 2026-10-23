extends Control
## Read-only standings for the tournament created by gameplay or its introduction.
const ROW = preload("res://scripts/ui/leaderboard_row.gd")
const PORTRAITS = preload("res://scripts/ui/leaderboard_portraits.gd")
const CARD = preload("res://scripts/ui/quiz_answer_card_style.gd")
const PALETTE = preload("res://scripts/ui/ui_palette.gd")
const FONTS = preload("res://scripts/ui/ui_fonts.gd")
const TEXT_STYLE = preload("res://scripts/ui/button_text_style.gd")
const STAR = preload("res://flash_assets/star_currency_icon.png")
const COIN_PACK = preload("res://flash_assets/coin_pack_04.png")
const GIFT = preload("res://flash_assets/reward_chest_closed.png")
const REWARD_GLOW = preload("res://flash_assets/final_reward_rotating_glow.png")
const SCROLL = preload("res://scripts/ui/leaderboard_scroll.gd")
const PODIUM_AVATAR_SIZE := ROW.AVATAR_SIZE * 1.5
const PODIUM_HEIGHT := 294.0
var portraits: Node
var score_formatter: Callable
var scroll: ScrollContainer
var rows: VBoxContainer
var podium: Control
var own_row: Control
var _title: Label
var _timer: Timer
var _snapshot: Dictionary = {}
var _rows_key := ""
var _live := true

func _tr(key: String, ru: String, en: String) -> String:
	var translated := TranslationServer.translate(key)
	return translated if translated != key else (ru if Database.interface_language == "ru" else en)

func _ready() -> void:
	name = "TournamentPage"
	if !is_instance_valid(portraits):
		portraits = PORTRAITS.new()
		add_child(portraits)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title = _label(self, Rect2(18, 10, 444, 34), "", 27, Color.WHITE)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	TEXT_STYLE.apply_display(_title)
	podium = Control.new()
	podium.name = "TournamentPodium"
	podium.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(podium)
	scroll = SCROLL.new()
	scroll.name = "TournamentScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	add_child(scroll)
	rows = VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 0)
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.set_list(rows)
	_timer = Timer.new()
	_timer.wait_time = 1.0
	_timer.timeout.connect(func():
		if is_visible_in_tree():
			refresh())
	add_child(_timer)
	_timer.start()
	GameState.tournament_changed.connect(refresh)
	resized.connect(_layout)
	refresh()

func refresh() -> void:
	if !_live:
		return
	_snapshot = GameState.get_tournament_snapshot()
	var phase := str(_snapshot.phase)
	# A deadline can pass before the host's next timer tick. Keep the frozen
	# standings visible until navigation, without exposing legacy actions.
	var has_standings := phase != "idle"
	_title.visible = has_standings
	podium.visible = has_standings
	scroll.visible = has_standings
	if phase == "active":
		var remaining := int(_snapshot.remaining)
		_title.text = _tr("TOURNAMENT_REMAINING", "До конца: %s", "Time left: %s") % ("%02d:%02d:%02d" % [remaining / 3600, (remaining / 60) % 60, remaining % 60])
	elif has_standings:
		_title.text = _tr("TOURNAMENT_FINISHED", "Турнир завершён", "Tournament finished")
	# Rebuild only on score/state changes: ticking seconds never reset the scroll.
	var key := JSON.stringify(_snapshot.get("rows", [])) + phase + JSON.stringify(GameState.get_player_profile())
	if key != _rows_key:
		_rows_key = key
		_rebuild()
	_layout()

func _rebuild() -> void:
	var previous_scroll := scroll.scroll_vertical
	own_row = null
	for child in rows.get_children():
		child.free()
	for child in podium.get_children():
		child.free()
	var entries: Array = _snapshot.get("rows", [])
	if entries.is_empty():
		return
	var rewards: Array = _snapshot.get("rewards", GameState.GAME_DESIGN.get_array("tournament.rewards_coins"))
	for slot in range(3):
		var rank: int = [2, 1, 3][slot]
		var entry: Dictionary = entries[rank - 1]
		var card := _podium_card(entry, int(rewards[rank - 1]), slot)
		podium.add_child(card)
		if bool(entry.mine):
			own_row = card
	for entry: Dictionary in entries.slice(3):
		var card := _row_card(entry)
		rows.add_child(card)
		if bool(entry.mine):
			own_row = card
	scroll.scroll_vertical = previous_scroll

func _name(entry: Dictionary) -> String:
	if bool(entry.mine):
		return GameState.player_name if !GameState.player_name.is_empty() else _tr("TOURNAMENT_YOU", "Вы", "You")
	return str(entry.nickname)

func _podium_card(entry: Dictionary, reward: int, slot: int) -> Control:
	var rank := int(entry.rank)
	var card := Control.new()
	card.name = "PodiumPlace%d" % rank
	card.position = Vector2(8 + slot * 151, PODIUM_AVATAR_SIZE * 0.5 + (0 if rank == 1 else 24))
	card.size = Vector2(142, 244 if rank == 1 else 220)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var color: Color = {1: PALETTE.PAPER_CRACK_LIGHT, 2: PALETTE.UI_BLUE_LIGHT_BORDER, 3: PALETTE.BUTTON_ORANGE}[rank]
	var shadow := _panel(card, Rect2(Vector2(0, 6), card.size), CARD.shadow_style())
	shadow.name = "CardShadow"
	var face := _panel(card, Rect2(Vector2.ZERO, card.size), CARD.face_style(color))
	face.name = "CardFace"
	var avatar: Button = portraits.create_avatar(_display_entry(entry), PODIUM_AVATAR_SIZE)
	avatar.position = Vector2((card.size.x - PODIUM_AVATAR_SIZE) * 0.5, -PODIUM_AVATAR_SIZE * 0.5)
	card.add_child(avatar)
	var medal := _icon(card, Rect2(54, PODIUM_AVATAR_SIZE * 0.5 - 17, 34, 34), ROW.RANK_MEDALS[rank - 1])
	medal.name = "PodiumRankMedal"
	var nickname := _label(card, Rect2(9, 61, 124, 40), _name(entry), 25)
	nickname.add_theme_font_override("font", FONTS.button_font())
	nickname.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nickname.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_shrink(nickname, 16)
	var prize_center := Vector2(71, 150 if rank == 1 else 132)
	var prize_size := Vector2.ONE * (90.0 * 0.8 if rank == 1 else 58.0 * 1.15)
	var glow_size := Vector2.ONE * (120 if rank == 1 else 112)
	var glow := _icon(card, Rect2(prize_center - glow_size * 0.5, glow_size), REWARD_GLOW)
	glow.name = "PodiumRewardGlow"
	glow.modulate.a = 0.7
	var prize := _icon(card, Rect2(prize_center - prize_size * 0.5, prize_size), GIFT if rank == 1 else COIN_PACK)
	prize.name = "PodiumReward"
	if rank != 1:
		var amount := _label(card, Rect2(9, 157, 124, 25), "x%d" % reward, 22, Color.WHITE)
		amount.name = "PodiumRewardAmount"
		amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		amount.add_theme_font_override("font", FONTS.display_font())
		amount.autowrap_mode = TextServer.AUTOWRAP_OFF
		amount.clip_text = false
		TEXT_STYLE.apply_display(amount)
	var score_text := str(entry.stars)
	if score_formatter.is_valid():
		score_text = str(score_formatter.call(int(entry.stars)))
	var score := _label(card, Rect2(9, card.size.y - 41, 91, 35), score_text, 27)
	score.name = "PodiumScore"
	_shrink(score, 14)
	var text_width := minf(91, score.get_theme_font("font").get_string_size(score_text, HORIZONTAL_ALIGNMENT_LEFT, -1, score.get_theme_font_size("font_size")).x)
	score.size.x = text_width
	score.position.x = (142 - text_width - 33) * 0.5
	_icon(card, Rect2(score.position + Vector2(text_width + 6, 4), Vector2(27, 27)), STAR)
	return card

func _row_card(entry: Dictionary) -> Control:
	var row := Control.new()
	row.custom_minimum_size = Vector2(ROW.ROW_WIDTH, ROW.ROW_HEIGHT)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ROW.populate(row, _display_entry(entry), bool(entry.mine), portraits, score_formatter, Vector2(8, 0))
	return row

func _display_entry(entry: Dictionary) -> Dictionary:
	var display_entry := entry.duplicate(true)
	display_entry.nickname = _name(entry)
	if bool(entry.mine):
		display_entry.merge(GameState.get_player_profile(), true)
	return display_entry

func _icon(parent: Control, rect: Rect2, texture: Texture2D) -> TextureRect:
	var icon := TextureRect.new()
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = texture
	icon.position = rect.position
	icon.size = rect.size
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(icon)
	return icon

func _panel(parent: Control, rect: Rect2, style: StyleBox) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	return panel

func _label(parent: Control, rect: Rect2, text: String, font_size: int, color: Color = PALETTE.TEXT_DARK) -> Label:
	var label := Label.new()
	label.position = rect.position
	label.size = rect.size
	label.text = text
	label.clip_text = true
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", FONTS.regular_font())
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _shrink(label: Label, minimum: int) -> void:
	var font_size := label.get_theme_font_size("font_size")
	var font := label.get_theme_font("font")
	while font_size > minimum and font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > label.size.x:
		font_size -= 1
	label.add_theme_font_size_override("font_size", font_size)

func _layout() -> void:
	if !is_node_ready():
		return
	podium.position = Vector2(ROW.CARD_SIDE_MARGIN - 8, 60)
	podium.size = Vector2(ROW.ROW_WIDTH, PODIUM_HEIGHT)
	var list_top := podium.position.y + PODIUM_HEIGHT + 8.0
	scroll.position = Vector2(ROW.CARD_SIDE_MARGIN - 8, list_top)
	scroll.size = Vector2(ROW.ROW_WIDTH, maxf(0, size.y - list_top))

func dispose() -> void:
	if !_live:
		return
	_live = false
	_timer.stop()
	if GameState.tournament_changed.is_connected(refresh):
		GameState.tournament_changed.disconnect(refresh)
	if !GameState.tournament_state.is_empty():
		GameState.save_game()

func _exit_tree() -> void:
	dispose()
