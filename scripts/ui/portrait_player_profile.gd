extends Control
## Logical 480-unit body: the identity card is fixed; only statistics scroll.
const PALETTE = preload("res://scripts/ui/ui_palette.gd")
const FONTS = preload("res://scripts/ui/ui_fonts.gd")
const TEXT_STYLE = preload("res://scripts/ui/button_text_style.gd")
const SCROLL = preload("res://scripts/ui/leaderboard_scroll.gd")
const AVATAR = preload("res://scripts/ui/profile_avatar_button.gd")
const STAR = preload("res://flash_assets/star_currency_icon.png")
const ICONS := {
	"stars_earned": preload("res://assets/profile/stars.png"),
	"levels_completed": preload("res://assets/profile/levels.png"),
	"hard_levels_completed": preload("res://assets/profile/hard.png"),
	"quizzes_solved": preload("res://assets/profile/quiz.png"),
	"words_solved": preload("res://assets/profile/words.png"),
}
var identity: Panel
var statistics_scroll: ScrollContainer
var _nickname: Label
var _balance: Label
var _values: Dictionary = {}

func _ready() -> void:
	name = "PlayerProfileBody"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	identity = _panel(self, Rect2(18, 16, 444, 128), PALETTE.UI_BLUE_DARK)
	identity.name = "PlayerIdentity"
	var avatar := AVATAR.new()
	avatar.name = "ProfileAvatar"
	avatar.position = Vector2(16, 16)
	avatar.size = Vector2(96, 96)
	avatar.disabled = true
	identity.add_child(avatar)
	_nickname = _label(identity, Rect2(132, 17, 292, 45), "", 30, FONTS.regular_font(700.0))
	_nickname.name = "PlayerNickname"
	_nickname.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	TEXT_STYLE.apply_regular_display(_nickname)
	_icon(identity, STAR, Rect2(133, 77, 29, 29))
	_balance = _label(identity, Rect2(172, 67, 250, 43), "", 29, FONTS.regular_font(700.0))
	_balance.name = "PlayerCurrentStars"
	TEXT_STYLE.apply_regular_display(_balance)
	statistics_scroll = SCROLL.new()
	statistics_scroll.name = "ProfileStatisticsScroll"
	statistics_scroll.position = Vector2(18, 158)
	add_child(statistics_scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	statistics_scroll.set_list(content)
	var title := _label(content, Rect2(0, 0, 444, 38), tr("PROFILE_STATISTICS"), 25, FONTS.display_font())
	title.custom_minimum_size = Vector2(444, 38)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	TEXT_STYLE.apply_display(title)
	var large := HBoxContainer.new()
	large.add_theme_constant_override("separation", 12)
	large.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(large)
	for key: String in ["stars_earned", "levels_completed"]:
		large.add_child(_stat_card(key, true))
	var small := HBoxContainer.new()
	small.add_theme_constant_override("separation", 12)
	small.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(small)
	for key: String in ["hard_levels_completed", "quizzes_solved", "words_solved"]:
		small.add_child(_stat_card(key, false))
	var padding := Control.new()
	padding.custom_minimum_size.y = 18
	padding.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(padding)
	resized.connect(_layout)
	GameState.stars_changed.connect(_on_stars_changed)
	refresh()
	_layout()

func _stat_card(key: String, large: bool) -> Control:
	var width := 216.0 if large else 140.0
	var height := 156.0 if large else 184.0
	var card := _panel(null, Rect2(0, 0, width, height), PALETTE.UI_BLUE_DARK)
	card.name = "ProfileStat_" + key
	card.custom_minimum_size = Vector2(width, height)
	_icon(card, ICONS[key], Rect2(15, 19, 72, 72) if large else Rect2(43, 14, 54, 54))
	var value := _label(card, Rect2(95, 25, 109, 60) if large else Rect2(10, 71, 120, 43), "0", 44 if large else 32, FONTS.regular_font(700.0))
	value.name = "StatValue"
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	TEXT_STYLE.apply_regular_display(value)
	_values[key] = value
	var description := _label(card, Rect2(12, 96, width - 24, 52) if large else Rect2(8, 116, width - 16, 62), tr("PROFILE_STAT_" + key.to_upper()), 20 if large else 16, FONTS.regular_font())
	description.name = "StatDescription"
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return card

func refresh() -> void:
	if !is_node_ready():
		return
	_nickname.text = GameState.player_name if !GameState.player_name.is_empty() else tr("PROFILE_DEFAULT_NAME")
	_balance.text = str(GameState.get_stars())
	var totals := GameState.get_profile_statistics()
	for key: String in _values:
		var label: Label = _values[key]
		label.text = str(totals.get(key, 0))
		var font := label.get_theme_font("font")
		var font_size := 44 if key in ["stars_earned", "levels_completed"] else 32
		while font_size > 16 and font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > label.size.x - 8:
			font_size -= 1
		label.add_theme_font_size_override("font_size", font_size)

func _on_stars_changed(_balance_value: int) -> void:
	refresh()

func _layout() -> void:
	statistics_scroll.size = Vector2(444, maxf(40, size.y - statistics_scroll.position.y))

func _panel(parent: Control, rect: Rect2, color: Color) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(14)
	panel.add_theme_stylebox_override("panel", style)
	if parent != null:
		parent.add_child(panel)
	return panel

func _label(parent: Control, rect: Rect2, text: String, font_size: int, font: Font) -> Label:
	var label := Label.new()
	label.position = rect.position
	label.size = rect.size
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color.WHITE)
	parent.add_child(label)
	return label

func _icon(parent: Control, texture: Texture2D, rect: Rect2) -> void:
	var icon := TextureRect.new()
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = texture
	icon.position = rect.position
	icon.size = rect.size
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(icon)
