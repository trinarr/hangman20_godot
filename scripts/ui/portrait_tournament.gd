extends Control
## Tournament body uses its host's 480-unit portrait stage transform.
const CARD = preload("res://scripts/ui/quiz_answer_card_style.gd")
const PALETTE = preload("res://scripts/ui/ui_palette.gd")
const FONTS = preload("res://scripts/ui/ui_fonts.gd")
const TEXT_STYLE = preload("res://scripts/ui/button_text_style.gd")
const STAR = preload("res://flash_assets/star_currency_icon.png")
const COIN = preload("res://flash_assets/soft_currency_coin.png")
const SCROLL = preload("res://scripts/ui/leaderboard_scroll.gd")
var scroll: ScrollContainer
var rows: VBoxContainer
var podium: Control
var pinned: Control
var own_row: Control
var _title: Label
var _hint: Label
var _button: Button
var _error: Label
var _timer: Timer
var _snapshot: Dictionary = {}
var _rows_key := ""
var _live := true

func _tr(key: String, ru: String, en: String) -> String:
	var translated := TranslationServer.translate(key)
	return translated if translated != key else (ru if Database.interface_language == "ru" else en)

func _ready() -> void:
	name = "TournamentPage"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title = _label(self, Rect2(18, 10, 444, 34), "", 27, Color.WHITE)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	TEXT_STYLE.apply_display(_title)
	_hint = _label(self, Rect2(18, 47, 444, 42), "", 18, Color.WHITE)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scroll = SCROLL.new()
	scroll.name = "TournamentScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	add_child(scroll)
	rows = VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 10)
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.set_list(rows)
	scroll.visual_offset_changed.connect(_update_pin)
	scroll.get_v_scroll_bar().value_changed.connect(func(_value: float): _update_pin.call_deferred())
	_button = Button.new()
	_button.name = "TournamentAction"
	_button.add_theme_font_override("font", FONTS.display_font())
	_button.add_theme_font_size_override("font_size", 25)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		_button.add_theme_stylebox_override(state, CARD.face_style(PALETTE.BUTTON_ORANGE))
		_button.add_theme_color_override("font_color" if state == "normal" else "font_%s_color" % state, PALETTE.TEXT_DARK)
	_button.pressed.connect(_action)
	add_child(_button)
	_error = _label(self, Rect2(18, 0, 444, 30), "", 16, Color.WHITE)
	_error.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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
	_button.visible = phase != "active"
	_button.disabled = !_snapshot.unlocked and phase == "idle"
	if phase == "active":
		var remaining := int(_snapshot.remaining)
		_title.text = _tr("TOURNAMENT_REMAINING", "До конца: %s", "Time left: %s") % ("%02d:%02d:%02d" % [remaining / 3600, (remaining / 60) % 60, remaining % 60])
		_hint.text = _tr("TOURNAMENT_EARN", "Зарабатывайте звёзды и поднимайтесь в рейтинге", "Earn stars and climb the leaderboard")
	elif phase == "finished" or phase == "claimed":
		_title.text = _tr("TOURNAMENT_FINISHED", "Турнир завершён", "Tournament finished")
		_hint.text = _tr("TOURNAMENT_PLACE", "Ваше место: %d", "Your place: %d") % int(_snapshot.rank)
		_button.text = _tr("TOURNAMENT_NEXT", "Новый турнир", "New tournament") if phase == "claimed" else (_tr("TOURNAMENT_CLAIM", "Забрать %d монет", "Claim %d coins") % int(_snapshot.reward) if int(_snapshot.reward) > 0 else _tr("COMMON_CONTINUE", "Продолжить", "Continue"))
	else:
		_title.text = _tr("TOURNAMENT_TITLE", "Турнир", "Tournament")
		_hint.text = _tr("TOURNAMENT_INTRO", "%d часов · 10 участников · 3 призовых места", "%d hours · 10 players · 3 prize places") % (int(_snapshot.duration) / 3600)
		_button.text = _tr("TOURNAMENT_JOIN", "Участвовать", "Join")
		if !_snapshot.unlocked:
			_hint.text = _tr("TOURNAMENT_LOCKED", "Завершите уровень %d для участия", "Complete level %d to join") % int(_snapshot.unlock_level)
	# Rebuild only on score/state changes: ticking seconds never reset the scroll.
	var key := JSON.stringify(_snapshot.get("rows", [])) + phase + GameState.player_name
	if key != _rows_key:
		_rows_key = key
		_rebuild(phase == "idle")
	_layout()

func _rebuild(preview: bool) -> void:
	var previous_scroll := scroll.scroll_vertical
	own_row = null
	if is_instance_valid(pinned):
		pinned.free()
	pinned = null
	for child in rows.get_children():
		child.free()
	podium = Control.new()
	podium.name = "TournamentPodium"
	podium.custom_minimum_size = Vector2(444, 260)
	podium.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows.add_child(podium)
	var entries: Array = _snapshot.get("rows", [])
	var rewards: Array = _snapshot.get("rewards", GameState.GAME_DESIGN.get_array("tournament.rewards_coins"))
	for slot in range(3):
		var rank: int = [2, 1, 3][slot]
		var entry: Dictionary = {"rank": rank, "nickname": "—", "stars": 0, "mine": false} if preview else entries[rank - 1]
		var card := _podium_card(entry, int(rewards[rank - 1]), slot)
		podium.add_child(card)
		if bool(entry.mine):
			own_row = card
	if !preview:
		for entry: Dictionary in entries.slice(3):
			var card := _row_card(entry)
			rows.add_child(card)
			if bool(entry.mine):
				own_row = card
		for entry: Dictionary in entries:
			if bool(entry.mine):
				pinned = _row_card(entry, true)
				pinned.name = "TournamentPinnedPlayer"
				add_child(pinned)
				break
		var spacer := Control.new()
		spacer.custom_minimum_size.y = 86
		spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rows.add_child(spacer)
	scroll.scroll_vertical = previous_scroll
	_update_pin.call_deferred()

func _name(entry: Dictionary) -> String:
	if bool(entry.mine):
		return GameState.player_name if !GameState.player_name.is_empty() else _tr("TOURNAMENT_YOU", "Вы", "You")
	return str(entry.nickname)

func _podium_card(entry: Dictionary, reward: int, slot: int) -> Control:
	var rank := int(entry.rank)
	var card := Control.new()
	card.name = "PodiumPlace%d" % rank
	card.position = Vector2(slot * 151, 10 if rank == 1 else 34)
	card.size = Vector2(142, 244 if rank == 1 else 220)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var color: Color = {1: PALETTE.PAPER_CRACK_LIGHT, 2: PALETTE.UI_BLUE_LIGHT_BORDER, 3: PALETTE.BUTTON_ORANGE}[rank]
	_panel(card, Rect2(Vector2(0, 6), card.size), CARD.shadow_style())
	_panel(card, Rect2(Vector2.ZERO, card.size), CARD.face_style(color))
	var badge := StyleBoxFlat.new()
	badge.bg_color = PALETTE.UI_BLUE if bool(entry.mine) else PALETTE.UI_BLUE_DARK
	badge.set_corner_radius_all(25)
	_panel(card, Rect2(46, 12, 50, 50), badge)
	var rank_label := _label(card, Rect2(46, 12, 50, 50), str(rank), 32, Color.WHITE)
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	TEXT_STYLE.apply_display(rank_label)
	var nickname := _label(card, Rect2(9, 70, 124, 44), _name(entry), 22)
	nickname.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nickname.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_shrink(nickname, 16)
	_counter(card, Vector2(15, 120), 112, int(entry.stars), STAR, 27)
	var reward_style := StyleBoxFlat.new()
	reward_style.bg_color = Color(1, 1, 1, 0.55)
	reward_style.set_corner_radius_all(12)
	var reward_y := card.size.y - 51
	_panel(card, Rect2(10, reward_y, 122, 39), reward_style)
	_counter(card, Vector2(16, reward_y), 110, reward, COIN, 22)
	return card

func _row_card(entry: Dictionary, fixed: bool = false) -> Control:
	var row := Control.new()
	row.custom_minimum_size = Vector2(444, 72)
	row.size = Vector2(480 if fixed else 444, 72)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := CARD.face_style(PALETTE.UI_BLUE_LIGHT_BORDER if bool(entry.mine) else Color.WHITE)
	if fixed:
		style.set_corner_radius_all(0)
		style.set_border_width_all(0)
	else:
		_panel(row, Rect2(0, 6, 444, 66), CARD.shadow_style())
	var face := _panel(row, Rect2(Vector2.ZERO, Vector2(row.size.x, 66 if !fixed else 72)), style)
	face.name = "CardFace"
	var contents := Control.new()
	contents.name = "Contents"
	contents.position.x = 18 if fixed else 0
	contents.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.add_child(contents)
	_label(contents, Rect2(14, 0, 46, 66), str(entry.rank), 24)
	var nickname := _label(contents, Rect2(65, 0, 226, 66), _name(entry), 22)
	nickname.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_shrink(nickname, 15)
	_counter(contents, Vector2(301, 14), 128, int(entry.stars), STAR, 23)
	return row

func _counter(parent: Control, at: Vector2, width: float, amount: int, texture: Texture2D, font_size: int) -> void:
	var label := _label(parent, Rect2(at, Vector2(width - 33, 38)), str(amount), font_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_shrink(label, 14)
	var icon := TextureRect.new()
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = texture
	icon.position = at + Vector2(width - 27, 5)
	icon.size = Vector2(27, 27)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(icon)

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
	var action_height := 86.0 if _button.visible else 0.0
	scroll.position = Vector2(18, 94)
	scroll.size = Vector2(444, maxf(80, size.y - 94 - action_height))
	_button.position = Vector2(50, size.y - 68)
	_button.size = Vector2(380, 54)
	_error.position.y = size.y - 100
	_update_pin.call_deferred()

func _update_pin() -> void:
	if !_live or !is_instance_valid(pinned) or !is_instance_valid(own_row):
		return
	var bounds := scroll.get_global_rect()
	var rect := own_row.get_global_rect()
	var side := "top" if rect.position.y < bounds.position.y - 0.5 else ("bottom" if rect.end.y > bounds.end.y + 0.5 else "")
	pinned.visible = !side.is_empty()
	own_row.modulate.a = 0.0 if pinned.visible else 1.0
	var host_scale := get_global_transform().get_scale().x
	var gutter := get_global_rect().position.x / host_scale
	pinned.position = Vector2(-gutter, scroll.position.y if side == "top" else scroll.position.y + scroll.size.y - 72)
	pinned.size.x = get_viewport_rect().size.x / host_scale
	pinned.get_node("CardFace").size.x = pinned.size.x
	pinned.get_node("CardFace/Contents").position.x = 18 + gutter

func _action() -> void:
	if !_live:
		return
	_error.text = ""
	var phase := str(_snapshot.get("phase", "idle"))
	var ok := GameState.start_tournament() if phase == "idle" or phase == "claimed" else bool(GameState.claim_tournament_reward().get("ok", false))
	refresh()
	if !ok:
		_error.text = _tr("TOURNAMENT_SAVE_ERROR", "Не удалось сохранить. Попробуйте ещё раз", "Couldn't save. Please try again")

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
