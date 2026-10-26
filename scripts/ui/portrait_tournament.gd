extends Control
## Read-only standings for the tournament created by gameplay or its introduction.
const ROW = preload("res://scripts/ui/leaderboard_row.gd")
const PORTRAITS = preload("res://scripts/ui/leaderboard_portraits.gd")
const PALETTE = preload("res://scripts/ui/ui_palette.gd")
const FONTS = preload("res://scripts/ui/ui_fonts.gd")
const TEXT_STYLE = preload("res://scripts/ui/button_text_style.gd")
const COIN_PACK = preload("res://flash_assets/coin_pack_04.png")
const GIFT = preload("res://flash_assets/reward_chest_closed.png")
const COUNTDOWN = preload("res://scripts/ui/tournament_countdown.gd")
const ICON_SHADOW = preload("res://scripts/ui/portrait_icon_extrusion.gd")
const LIST_TOP_GAP := 24.0
const SCROLL = preload("res://scripts/ui/leaderboard_scroll.gd")
var portraits: Node
var score_formatter: Callable
var scroll: ScrollContainer
var rows: VBoxContainer
var own_row: Control
var countdown: Control
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
	countdown = COUNTDOWN.new()
	countdown.name = "TournamentTabCountdown"
	countdown.scale = Vector2.ONE * 0.85
	add_child(countdown)
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
	_timer.timeout.connect(refresh)
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
	countdown.visible = has_standings
	scroll.visible = has_standings
	countdown.set_remaining(int(_snapshot.get("remaining", 0)))
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
	var entries: Array = _snapshot.get("rows", [])
	if entries.is_empty():
		return
	var rewards: Array = _snapshot.get("rewards", GameState.GAME_DESIGN.get_array("tournament.rewards_coins"))
	for entry: Dictionary in entries:
		var rank := int(entry.rank)
		var reward := int(rewards[rank - 1]) if rank >= 1 and rank <= mini(3, rewards.size()) else 0
		var card := _row_card(entry, reward)
		rows.add_child(card)
		if bool(entry.mine):
			own_row = card
	scroll.scroll_vertical = previous_scroll

func _name(entry: Dictionary) -> String:
	if bool(entry.mine):
		return GameState.player_name if !GameState.player_name.is_empty() else _tr("TOURNAMENT_YOU", "Вы", "You")
	return str(entry.nickname)

func _row_card(entry: Dictionary, reward: int = 0) -> Control:
	var row := Control.new()
	row.custom_minimum_size = Vector2(ROW.ROW_WIDTH, ROW.ROW_HEIGHT)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ROW.populate(row, _display_entry(entry), bool(entry.mine), portraits, score_formatter, Vector2(8, 0))
	row.set_meta("rank", int(entry.rank))
	if reward > 0:
		var face: Control = row.get_node("CardFace")
		var counter: Control = face.get_node("PlayerScore")
		var reward_rect := Rect2(counter.position.x - 52, 10 if int(entry.rank) == 1 else 4, 48, 48)
		var reward_texture: Texture2D = GIFT if int(entry.rank) == 1 else COIN_PACK
		var shadows := ICON_SHADOW._create_portrait_icon_extrusion_layers(face, reward_texture, "TournamentRewardShadow", 0, ROW.SCORE_PLATE.STYLE.ICON_SHADOW_ALPHA)
		ICON_SHADOW._layout_portrait_icon_extrusion_layers(shadows, reward_rect.position, reward_rect.size)
		var prize := _icon(face, reward_rect, reward_texture)
		prize.name = "TournamentRowReward"
		prize.z_index = 1
		if int(entry.rank) != 1:
			var amount := _label(face, Rect2(reward_rect.position.x - 3, reward_rect.end.y - 18, 54, 26), "x%d" % reward, roundi(16 * 1.15), Color.WHITE)
			amount.name = "TournamentRowRewardAmount"
			amount.z_index = 2
			amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			amount.add_theme_font_override("font", FONTS.display_font())
			TEXT_STYLE.apply_display(amount)
		var nickname: Label = face.get_node("PlayerName")
		nickname.size.x = reward_rect.position.x - 8 - nickname.position.x
		_shrink(nickname, 14)
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
	var list_top := LIST_TOP_GAP
	scroll.position = Vector2(ROW.CARD_SIDE_MARGIN - 8, list_top)
	scroll.size = Vector2(ROW.ROW_WIDTH, maxf(0, size.y - list_top))

func dispose() -> void:
	if !_live:
		return
	_live = false
	_timer.stop()
	if is_instance_valid(countdown):
		countdown.hide()
	if GameState.tournament_changed.is_connected(refresh):
		GameState.tournament_changed.disconnect(refresh)
	if !GameState.tournament_state.is_empty():
		GameState.save_game()

func _exit_tree() -> void:
	dispose()
	if is_instance_valid(countdown) and countdown.get_parent() != self:
		countdown.queue_free()
