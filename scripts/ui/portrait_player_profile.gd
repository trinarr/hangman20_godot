extends Control
## Logical 480-unit body: centered identity stays fixed; statistics scroll.
const PALETTE = preload("res://scripts/ui/ui_palette.gd")
const FONTS = preload("res://scripts/ui/ui_fonts.gd")
const TEXT_STYLE = preload("res://scripts/ui/button_text_style.gd")
const SCROLL = preload("res://scripts/ui/leaderboard_scroll.gd")
const AVATAR = preload("res://scripts/ui/profile_avatar_button.gd")
const ROUND_BUTTON = preload("res://scripts/ui/stage_round_button.gd")
const LINE_ICON = preload("res://scripts/ui/profile_line_icon.gd")
const ICON_EXTRUSION = preload("res://scripts/ui/portrait_icon_extrusion.gd")
const PENCIL = preload("res://assets/profile/pencil.png")
const STAT_KEYS := ["stars_earned", "levels_completed", "hard_levels_completed", "quizzes_solved", "words_solved"]
var identity: Control
var statistics_scroll: ScrollContainer
var _nickname: Label
var _avatar: Button
var _values: Dictionary = {}

func _ready() -> void:
	name = "PlayerProfileBody"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	identity = Control.new()
	identity.name = "PlayerIdentity"
	identity.position = Vector2(18, 14)
	identity.size = Vector2(444, 176)
	identity.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(identity)
	_avatar = AVATAR.new()
	_avatar.name = "ProfileAvatar"
	_avatar.position = Vector2(163.5, 4)
	_avatar.size = Vector2(117, 117)
	_avatar.configure_profile_appearance(_avatar.size.x)
	_avatar.extra_hit_rect = Rect2(95, -8, 36, 36)
	identity.add_child(_avatar)
	var edit := ROUND_BUTTON.new()
	edit.name = "ProfileAvatarEdit"
	edit.use_stage_layout = false
	edit.stage_rect = _avatar.extra_hit_rect
	edit.set_color_preset(ROUND_BUTTON.ColorPreset.BLUE)
	edit.drop_shadow_enabled = true
	_avatar.add_child(edit)
	# The avatar owns input and the complete press transform, including the badge.
	edit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art := Control.new()
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.position = Vector2(8, 8)
	art.size = Vector2(20, 20)
	edit.add_child(art)
	ICON_EXTRUSION._add_portrait_icon_with_extrusion_to_holder(art, PENCIL, "Pencil", 1, 0.50, 0.70)
	_nickname = _label(identity, Rect2(78, 124, 288, 46), "", 26, FONTS.regular_font())
	_nickname.name = "PlayerNickname"
	_nickname.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_nickname.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	statistics_scroll = SCROLL.new()
	statistics_scroll.name = "ProfileStatisticsScroll"
	statistics_scroll.position = Vector2(18, 208)
	add_child(statistics_scroll)
	var panel := _panel(null, Rect2(0, 0, 444, 340), PALETTE.UI_BLUE_DARK)
	panel.name = "ProfileStatisticsList"
	panel.custom_minimum_size = Vector2(444, 340)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	statistics_scroll.set_list(panel)
	for index in range(STAT_KEYS.size()):
		_stat_row(panel, STAT_KEYS[index], index)
	resized.connect(_layout)
	refresh()
	_layout()

func _stat_row(parent: Control, key: String, index: int) -> void:
	var row := Control.new()
	row.name = "ProfileStat_" + key
	row.position = Vector2(0, 10 + index * 64)
	row.size = Vector2(444, 64)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(row)
	_vector_icon(row, key, Rect2(18, 18, 28, 28))
	var description := _label(row, Rect2(60, 4, 274, 56), tr("PROFILE_STAT_" + key.to_upper()), 20, FONTS.regular_font())
	description.name = "StatDescription"
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var value := _label(row, Rect2(344, 4, 82, 56), "0", 26, FONTS.regular_font())
	value.name = "StatValue"
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_values[key] = value
	if index < STAT_KEYS.size() - 1:
		var rule := ColorRect.new()
		rule.name = "StatDivider"
		rule.position = Vector2(18, 63)
		rule.size = Vector2(408, 2)
		rule.color = PALETTE.UI_BLUE_RULE
		rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(rule)

func refresh() -> void:
	if !is_node_ready():
		return
	_nickname.text = GameState.player_name if !GameState.player_name.is_empty() else tr("PROFILE_DEFAULT_NAME")
	_avatar.refresh_character()
	var totals := GameState.get_profile_statistics()
	for key: String in _values:
		var label: Label = _values[key]
		label.text = str(totals.get(key, 0))
		var font := label.get_theme_font("font")
		var font_size := 26
		while font_size > 12 and font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > label.size.x:
			font_size -= 1
		label.add_theme_font_size_override("font_size", font_size)

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
	TEXT_STYLE.apply_regular_display(label)
	return label

func _vector_icon(parent: Control, kind: String, rect: Rect2) -> void:
	var icon := LINE_ICON.new()
	icon.kind = kind
	icon.position = rect.position
	icon.size = rect.size
	parent.add_child(icon)
