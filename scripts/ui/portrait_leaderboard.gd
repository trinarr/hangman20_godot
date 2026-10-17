extends Control
## Native scrolling children share one stage transform; rows never map twice.
const TOURNAMENT_PAGE = preload("res://scripts/ui/portrait_tournament.gd")
const TABS = preload("res://scripts/ui/tabbed_page_style.gd")
const LAYOUT = preload("res://scripts/ui/portrait_stage_layout.gd")
const CARD = preload("res://scripts/ui/quiz_answer_card_style.gd")
const PALETTE = preload("res://scripts/ui/ui_palette.gd")
const FONTS = preload("res://scripts/ui/ui_fonts.gd")
const STAR = preload("res://flash_assets/star_currency_icon.png")
const ELASTIC_SCROLL = preload("res://scripts/ui/leaderboard_scroll.gd")
const LIST_TOP_PADDING := 12.0
const ROW_HEIGHT := 80.0
const CARD_SIDE_MARGIN := 18.4
const CARD_WIDTH := 480.0 - CARD_SIDE_MARGIN * 2.0
const ROW_WIDTH := CARD_WIDTH + 16.0
var service: Node
var score_formatter: Callable
var bottom_inset := 0.0
var scroll: ScrollContainer
var rows: VBoxContainer
var pinned: Control
var own_row: Control
var _snapshot: Dictionary = {}
var _pin_side := ""
var _live := true
var _status: Label
var _retry: Button
var _players: Button
var _weekly: Button
var _has_error := false
var _tournament: Control
var _tournament_selected := false

static func localized(key: String, ru: String, en: String) -> String:
	var translated := TranslationServer.translate(key)
	return translated if translated != key else (ru if Database.interface_language == "ru" else en)

func _ready() -> void:
	name = "LeaderboardScreen"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_players = _tab(1, localized("LEADERBOARD_PLAYERS", "Глобальный", "Global"), false)
	_weekly = _tab(0, localized("LEADERBOARD_TOURNAMENT", "Турнир", "Tournament"), false)
	TABS.select(_weekly, false)
	_players.pressed.connect(func(): _select_tab(false))
	_weekly.pressed.connect(func(): _select_tab(true))
	scroll = ELASTIC_SCROLL.new()
	scroll.name = "LeaderboardScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	add_child(scroll)
	rows = VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 0)
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.set_list(rows)
	scroll.visual_offset_changed.connect(func(): _update_pin.call_deferred())
	scroll.get_v_scroll_bar().value_changed.connect(func(_value: float): _update_pin.call_deferred())
	_status = _label(self, Rect2(35, 172, 410, 80), "", 21, Color.WHITE)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_retry = Button.new()
	_retry.text = localized("LEADERBOARD_RETRY", "Повторить", "Retry")
	_retry.add_theme_stylebox_override("normal", CARD.face_style())
	_retry.add_theme_font_size_override("font_size", 22)
	_retry.add_theme_color_override("font_color", PALETTE.TEXT_DARK)
	_retry.pressed.connect(func(): _load(true))
	add_child(_retry)
	_tournament = TOURNAMENT_PAGE.new()
	add_child(_tournament)
	_tournament.hide()
	get_viewport().size_changed.connect(_layout)
	_layout()
	if is_instance_valid(service):
		service.leaderboard_ready.connect(_received)
		service.sync_failed.connect(_failed)
		var cached: Dictionary = service.cached_snapshot()
		if cached.get("language", "") == ("ru" if Database.interface_language == "ru" else "en"):
			if !cached.is_empty():
				set_snapshot(cached)
	_load(false)
	_layout.call_deferred()

func _tab(index: int, text: String, unavailable: bool) -> Button:
	var button := Button.new()
	button.position = Vector2(26 + index * 218, TABS.TAB_Y)
	button.size = Vector2(210, TABS.TAB_HEIGHT)
	TABS.configure(button, text, !unavailable, unavailable)
	add_child(button)
	return button

func _load(force: bool) -> void:
	if !_live:
		return
	_has_error = false
	_retry.hide()
	_status.visible = _snapshot.is_empty()
	_status.text = localized("LEADERBOARD_LOADING", "Загрузка…", "Loading…")
	_layout()
	if !is_instance_valid(service) or !service.is_configured():
		_failed()
		return
	service.sync_stars(GameState.get_stars())
	service.refresh(force)

func _received(snapshot: Dictionary, _from_cache: bool) -> void:
	if _live:
		set_snapshot(snapshot)

func _failed() -> void:
	if !_live:
		return
	_has_error = true
	_status.show()
	_status.text = localized("LEADERBOARD_ERROR", "Не удалось загрузить рейтинг", "Couldn't load leaderboard")
	_retry.show()
	_layout()

func set_snapshot(snapshot: Dictionary) -> void:
	if !_live:
		return
	scroll.reset_scroll_effect()
	_snapshot = snapshot.duplicate(true)
	_has_error = false
	_status.hide()
	_retry.hide()
	own_row = null
	if is_instance_valid(pinned):
		pinned.free()
		pinned = null
	for child in rows.get_children():
		child.free()
	var me: Dictionary = snapshot.get("me") if snapshot.get("me") is Dictionary else {}
	var top: Array = snapshot.get("top", [])
	if !top.is_empty():
		var top_padding := Control.new()
		top_padding.name = "LeaderboardTopPadding"
		top_padding.custom_minimum_size.y = LIST_TOP_PADDING
		top_padding.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rows.add_child(top_padding)
	for entry: Dictionary in top:
		var mine := !me.is_empty() and str(entry.get("player_id", "")) == str(me.get("player_id", ""))
		var row := _card(entry, mine)
		rows.add_child(row)
		if mine:
			own_row = row
	if !me.is_empty() and int(me.get("stars", 0)) > 0:
		pinned = _card(me, true, true)
		pinned.name = "PinnedPlayer"
		add_child(pinned)
		if own_row == null:
			var spacer := Control.new()
			spacer.custom_minimum_size.y = ROW_HEIGHT
			spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
			rows.add_child(spacer)
	if top.is_empty():
		_status.text = localized("LEADERBOARD_EMPTY", "Пока нет участников", "No players yet")
		_status.show()
	_layout()
	_update_pin.call_deferred()

func _card(entry: Dictionary, mine: bool, fixed: bool = false) -> Control:
	var row := Control.new()
	row.custom_minimum_size = Vector2(ROW_WIDTH, ROW_HEIGHT)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if !fixed:
		var shadow := Panel.new()
		shadow.position = Vector2(8, CARD.LONG_BUTTON.BUTTON_DROP_SHADOW_OFFSET_Y)
		shadow.size = Vector2(CARD_WIDTH, 68)
		shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shadow.add_theme_stylebox_override("panel", CARD.shadow_style())
		row.add_child(shadow)
	var face := Panel.new()
	face.name = "CardFace"
	face.position = Vector2.ZERO if fixed else Vector2(8, 0)
	face.size = Vector2(480, ROW_HEIGHT) if fixed else Vector2(CARD_WIDTH, 68)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := CARD.face_style(PALETTE.UI_BLUE_LIGHT_BORDER if mine else Color.WHITE)
	if fixed:
		style.set_corner_radius_all(0)
		style.set_border_width_all(0)
	face.add_theme_stylebox_override("panel", style)
	row.add_child(face)
	var card_content: Control = face
	if fixed:
		card_content = Control.new()
		card_content.name = "CardContents"
		card_content.position = Vector2(CARD_SIDE_MARGIN, (ROW_HEIGHT - 68) * 0.5)
		card_content.size = Vector2(CARD_WIDTH, 68)
		card_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		face.add_child(card_content)
	var rank := str(int(entry.get("rank", 0))) if entry.get("rank") != null else ""
	if entry.get("rank") == null:
		rank = ("Топ %d%%" if Database.interface_language == "ru" else "Top %d%%") % int(entry.get("top_percent", 100))
	var name_text := str(entry.get("nickname", "")) if bool(entry.get("is_filler", false)) else "ID " + str(entry.get("player_id", ""))
	_label(card_content, Rect2(14, 0, 70, 68), rank, 15 if rank.contains("%") else 24)
	var player_label := _label(card_content, Rect2(86, 0, CARD_WIDTH - 254, 68), name_text, 22)
	player_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var score := str(entry.get("stars", 0))
	if score_formatter.is_valid():
		score = str(score_formatter.call(int(entry.get("stars", 0))))
	var score_label := _label(card_content, Rect2(CARD_WIDTH - 164, 0, 114, 68), score, 22)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	for label: Label in [player_label, score_label]:
		var font := label.get_theme_font("font")
		var font_size := 22
		while font_size > 14 and font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > label.size.x:
			font_size -= 1
		label.add_theme_font_size_override("font_size", font_size)
	var icon := TextureRect.new()
	icon.name = "LeaderboardStarIcon"
	# Set expansion before the texture: its native minimum size must never
	# enlarge the Control before the authored 26x26 rectangle is applied.
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = STAR
	icon.position = Vector2(CARD_WIDTH - 40, 21)
	icon.size = Vector2(26, 26)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_content.add_child(icon)
	return row

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

func set_bottom_inset(value: float) -> void:
	bottom_inset = value
	if is_node_ready():
		_layout()

func _layout() -> void:
	if !is_node_ready() or !_live:
		return
	var viewport_size := get_viewport_rect().size
	var factor: float = LAYOUT.fit_scale(viewport_size)
	position = Vector2(LAYOUT.horizontal_offset(viewport_size), 0)
	scale = Vector2.ONE * factor
	size = Vector2(480, LAYOUT.expanded_stage_height(viewport_size))
	var safe: float = LAYOUT.safe_top_stage(viewport_size)
	_players.position.y = TABS.TAB_Y + safe
	_weekly.position.y = TABS.TAB_Y + safe
	var list_top := TABS.CONTENT_Y + safe + (104.0 if _has_error else 0.0)
	scroll.position = Vector2(CARD_SIDE_MARGIN - 8, list_top)
	scroll.size = Vector2(ROW_WIDTH, maxf(80, size.y - bottom_inset - 12 - list_top))
	_status.size.y = 44 if _has_error else 80
	_status.position.y = TABS.CONTENT_Y + 12 + safe if _has_error else TABS.CONTENT_Y + 42 + safe
	_retry.position = Vector2(145, TABS.CONTENT_Y + 64 + safe)
	_retry.size = Vector2(190, 44)
	_tournament.position = Vector2(0, TABS.CONTENT_Y + safe)
	_tournament.size = Vector2(480, maxf(180, size.y - bottom_inset - 12 - TABS.CONTENT_Y - safe))
	_sync_tab_visibility()
	_update_pin.call_deferred()

func _select_tab(tournament: bool) -> void:
	if !_live:
		return
	_tournament_selected = tournament
	TABS.select(_players, !tournament)
	TABS.select(_weekly, tournament)
	_sync_tab_visibility()
	if tournament:
		_tournament.refresh()
	else:
		_update_pin.call_deferred()

func _sync_tab_visibility() -> void:
	scroll.visible = !_tournament_selected
	_status.visible = !_tournament_selected and (_has_error or _snapshot.get("top", []).is_empty())
	_retry.visible = !_tournament_selected and _has_error
	_tournament.visible = _tournament_selected
	if is_instance_valid(pinned) and _tournament_selected:
		pinned.hide()

func _update_pin() -> void:
	if !_live or !is_instance_valid(pinned):
		_pin_side = ""
		return
	_pin_side = "bottom"
	if is_instance_valid(own_row):
		own_row.modulate.a = 1.0
		var top := own_row.get_global_rect().position.y
		var bounds := scroll.get_global_rect()
		if top < bounds.position.y - 0.5:
			_pin_side = "top"
		elif top + 72 * scale.y <= bounds.end.y + 0.5:
			_pin_side = ""
		if !_pin_side.is_empty():
			own_row.modulate.a = 0.0
	pinned.visible = !_tournament_selected and !_pin_side.is_empty()
	# Cover the full physical viewport, including centered-stage side gutters.
	var viewport_size := get_viewport_rect().size
	var gutter: float = LAYOUT.horizontal_offset(viewport_size) / scale.x
	pinned.position = Vector2(-gutter, scroll.position.y if _pin_side == "top" else scroll.position.y + scroll.size.y - ROW_HEIGHT)
	pinned.size = Vector2(viewport_size.x / scale.x, ROW_HEIGHT)
	var face: Panel = pinned.get_node("CardFace")
	face.size = pinned.size
	face.get_node("CardContents").position.x = CARD_SIDE_MARGIN + gutter

func dispose() -> void:
	_live = false
	if is_instance_valid(_tournament):
		_tournament.dispose()
	if is_instance_valid(service):
		if service.leaderboard_ready.is_connected(_received):
			service.leaderboard_ready.disconnect(_received)
		if service.sync_failed.is_connected(_failed):
			service.sync_failed.disconnect(_failed)

func _exit_tree() -> void:
	dispose()
	if get_viewport().size_changed.is_connected(_layout):
		get_viewport().size_changed.disconnect(_layout)
