extends RefCounted
## Shared card geometry and contents for global and tournament lists.
const CARD = preload("res://scripts/ui/quiz_answer_card_style.gd")
const PALETTE = preload("res://scripts/ui/ui_palette.gd")
const FONTS = preload("res://scripts/ui/ui_fonts.gd")
const SCORE_PLATE = preload("res://scripts/ui/resource_counter_plate.gd")
const STAR = preload("res://flash_assets/star_currency_icon.png")
const RANK_MEDALS := [
	preload("res://assets/leaderboard/rank_medal_1.png"),
	preload("res://assets/leaderboard/rank_medal_2.png"),
	preload("res://assets/leaderboard/rank_medal_3.png"),
]
const AVATAR_SIZE := 53.0
const ROW_HEIGHT := 78.0
const CARD_CORNER_RADIUS := 14
const CARD_SIDE_MARGIN := 18.4
const CARD_WIDTH := 480.0 - CARD_SIDE_MARGIN * 2.0
const ROW_WIDTH := CARD_WIDTH + 16.0

static func populate(row: Control, entry: Dictionary, mine: bool, portraits: Node, score_formatter: Callable, card_position: Vector2) -> void:
	var shadow := Panel.new()
	shadow.name = "CardShadow"
	shadow.position = card_position + Vector2(0, CARD.LONG_BUTTON.BUTTON_DROP_SHADOW_OFFSET_Y)
	shadow.size = Vector2(CARD_WIDTH, 68)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shadow_style := CARD.shadow_style()
	shadow_style.set_corner_radius_all(CARD_CORNER_RADIUS)
	shadow.add_theme_stylebox_override("panel", shadow_style)
	row.add_child(shadow)
	var face := Panel.new()
	face.name = "CardFace"
	face.position = card_position
	face.size = Vector2(CARD_WIDTH, 68)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := CARD.face_style(PALETTE.BUTTON_SELECTED_ACCENT if mine else PALETTE.PRESS_HIGHLIGHT)
	style.set_corner_radius_all(CARD_CORNER_RADIUS)
	face.add_theme_stylebox_override("panel", style)
	row.add_child(face)
	var card_content: Control = face
	var rank_value := int(entry.get("rank", 0)) if entry.get("rank") != null else 0
	var name_text := str(entry.get("nickname", "ID " + str(entry.get("player_id", ""))))
	var avatar: Button = portraits.create_avatar(entry, AVATAR_SIZE)
	avatar.position = Vector2(59.5 * 0.85, 7)
	var rank_area_width: float = avatar.position.x - avatar.outer_outline_width
	_add_rank(card_content, rank_value, rank_area_width)
	card_content.add_child(avatar)
	var counter_width := SCORE_PLATE.width_for_value("9\u202f999\u202f999", 38.64) * 0.90 * 0.85
	var name_x := avatar.get_rect().end.x + 13.5
	var player_label := _label(card_content, Rect2(name_x, 0, CARD_WIDTH - counter_width - 20 - name_x, 68), name_text, 23)
	player_label.name = "PlayerName"
	player_label.add_theme_font_override("font", FONTS.button_font())
	player_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var score := str(entry.get("stars", 0))
	if score_formatter.is_valid():
		score = str(score_formatter.call(int(entry.get("stars", 0))))
	var font := player_label.get_theme_font("font")
	var font_size := 23
	while font_size > 14 and font.get_string_size(name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > player_label.size.x:
		font_size -= 1
	player_label.add_theme_font_size_override("font_size", font_size)
	var counter := SCORE_PLATE.new()
	counter.name = "PlayerScore"
	counter.position = Vector2(CARD_WIDTH - counter_width - 12, (68.0 - 38.64) * 0.5)
	counter.size = Vector2(counter_width, 38.64)
	counter.icon_texture = STAR
	counter.value = score
	card_content.add_child(counter)
	row.set_meta("leaderboard_entry", entry.duplicate(true))
	row.set_meta("leaderboard_mine", mine)

static func _add_rank(parent: Control, rank_value: int, rank_area_width: float) -> void:
	var rank := str(rank_value) if rank_value > 0 else "100+"
	if rank_value >= 1 and rank_value <= RANK_MEDALS.size():
		var medal := TextureRect.new()
		medal.name = "PlayerRankMedal"
		medal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		medal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		medal.texture = RANK_MEDALS[rank_value - 1]
		medal.position = Vector2((rank_area_width - 38.0) * 0.5, 15)
		medal.size = Vector2(38, 38)
		medal.mouse_filter = Control.MOUSE_FILTER_IGNORE
		medal.set_meta("rank", rank_value)
		parent.add_child(medal)
	else:
		var rank_label := _label(parent, Rect2(0, 0, rank_area_width, 68), rank, 25)
		rank_label.name = "PlayerRank"
		rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rank_label.add_theme_font_override("font", FONTS.button_font())

# Preserve the row, text effects and score plate when only its data changes.
static func update(row: Control, entry: Dictionary, mine: bool, portraits: Node, score_formatter: Callable) -> void:
	var previous: Dictionary = row.get_meta("leaderboard_entry", {})
	var face: Panel = row.get_node("CardFace")
	if row.get_meta("leaderboard_mine", false) != mine:
		var style := CARD.face_style(PALETTE.BUTTON_SELECTED_ACCENT if mine else PALETTE.PRESS_HIGHLIGHT)
		style.set_corner_radius_all(CARD_CORNER_RADIUS)
		face.add_theme_stylebox_override("panel", style)
	var appearance: Dictionary = preload("res://scripts/core/player_profile.gd").resolve_appearance(entry)
	var avatar: Button = face.get_node("PlayerAvatar")
	if avatar.get_meta("character_id") != appearance.character_id or avatar.get_meta("frame_id") != appearance.frame_id:
		var position := avatar.position
		avatar.free()
		avatar = portraits.create_avatar(entry, AVATAR_SIZE)
		avatar.position = position
		face.add_child(avatar)
	if previous.get("rank") != entry.get("rank"):
		var old_rank := face.get_node_or_null("PlayerRankMedal")
		if old_rank == null:
			old_rank = face.get_node_or_null("PlayerRank")
		if old_rank != null:
			old_rank.free()
		_add_rank(face, int(entry.get("rank", 0)) if entry.get("rank") != null else 0, avatar.position.x - avatar.outer_outline_width)
	var label: Label = face.get_node("PlayerName")
	var name_text := str(entry.get("nickname", "ID " + str(entry.get("player_id", ""))))
	if label.text != name_text:
		label.text = name_text
		var font := label.get_theme_font("font")
		var font_size := 23
		while font_size > 14 and font.get_string_size(name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > label.size.x:
			font_size -= 1
		label.add_theme_font_size_override("font_size", font_size)
	if previous.get("stars") != entry.get("stars"):
		var score := str(entry.get("stars", 0))
		if score_formatter.is_valid():
			score = str(score_formatter.call(int(entry.get("stars", 0))))
		face.get_node("PlayerScore").set_value(score)
	row.set_meta("leaderboard_entry", entry.duplicate(true))
	row.set_meta("leaderboard_mine", mine)

static func _label(parent: Control, rect: Rect2, text: String, font_size: int, color: Color = PALETTE.TEXT_DARK) -> Label:
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

