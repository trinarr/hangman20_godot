extends "res://scripts/main.gd"

const PORTRAIT_ADAPTIVE_GROUP_SCRIPT: GDScript = preload("res://scripts/ui/portrait_adaptive_group.gd")
const PORTRAIT_STAGE_LAYOUT: GDScript = preload("res://scripts/ui/portrait_stage_layout.gd")

const PORTRAIT_STAGE_SIZE := Vector2(480.0, 800.0)
const PORTRAIT_HEADER_HEIGHT: float = 102.0
const PORTRAIT_FOOTER_Y: float = 688.0
const PORTRAIT_LONG_BUTTON_SIZE := Vector2(300.0, 64.0)
const PORTRAIT_ROUND_BUTTON_SIZE: float = PORTRAIT_LONG_BUTTON_SIZE.y
const PORTRAIT_ACTION_BUTTON_RECT := Rect2(324.0, 19.0, PORTRAIT_ROUND_BUTTON_SIZE, PORTRAIT_ROUND_BUTTON_SIZE)
const PORTRAIT_CLOSE_BUTTON_RECT := Rect2(404.0, 19.0, PORTRAIT_ROUND_BUTTON_SIZE, PORTRAIT_ROUND_BUTTON_SIZE)
const PORTRAIT_SMALL_BUTTON_SIZE := Vector2(196.0, 58.0)
const PORTRAIT_MENU_TITLE_MAX_SCALE: float = 1.15
# Dense screens may grow moderately on tall phones, but gameplay is split into
# independent upper and lower groups so the keyboard can stay width-safe while
# moving toward the thumb zone.
const PORTRAIT_DENSE_MAX_SCALE: float = 1.15
const PORTRAIT_GAME_KEYBOARD_MAX_SCALE: float = 1.15
const PORTRAIT_RESULT_MAX_SCALE: float = 1.24
const PORTRAIT_PROFILE_MAX_SCALE: float = 1.10
const PORTRAIT_HERO_POSITION := Vector2(136.0, 302.0)
const PORTRAIT_HERO_RESULT_POSITION := Vector2(138.0, 300.0)
const PORTRAIT_HERO_CLASSIC_RESULT_POSITION := Vector2(138.0, 500.0)
const PORTRAIT_HERO_TIME_RESULT_POSITION := Vector2(138.0, 500.0)
const PORTRAIT_RESULT_CLOSE_BUTTON_RECT := Rect2(14.0, 711.0, PORTRAIT_ROUND_BUTTON_SIZE, PORTRAIT_ROUND_BUTTON_SIZE)
const PORTRAIT_RESULT_THEME_BUTTON_RECT := Rect2(402.0, 711.0, PORTRAIT_ROUND_BUTTON_SIZE, PORTRAIT_ROUND_BUTTON_SIZE)
const PORTRAIT_RESULT_CONTINUE_BUTTON_RECT := Rect2(90.0, 711.0, PORTRAIT_LONG_BUTTON_SIZE.x, PORTRAIT_LONG_BUTTON_SIZE.y)
const PORTRAIT_RESULT_HEADER_SEARCH_BUTTON_RECT := Rect2(419.0, 25.0, 49.0, 49.0)
const PORTRAIT_HERO_SCALE_MULTIPLIER: float = 0.86
const PORTRAIT_BACK_ARROW_ICON: Texture2D = preload("res://flash_assets/portrait_back_arrow_icon.png")
const PORTRAIT_RESULT_THEME_MENU_ICON: Texture2D = preload("res://flash_assets/result_theme_menu_icon.png")

const PORTRAIT_BLUE := Color(0.2706, 0.3098, 0.6078, 1.0)
const PORTRAIT_DARK_BLUE := Color(0.2314, 0.2627, 0.5176, 1.0)
const PORTRAIT_ORANGE := Color(0.8157, 0.5647, 0.3412, 1.0)
const PORTRAIT_RULE := Color(0.3157, 0.3765, 0.6902, 0.95)
const PORTRAIT_POPUP_DIM_ALPHA: float = 0.76
const PORTRAIT_POPUP_CLOSE_SIZE: float = PORTRAIT_ROUND_BUTTON_SIZE
const PORTRAIT_POPUP_CLOSE_GAP: float = 48.0
const PORTRAIT_GAME_BACK_BUTTON_RECT := Rect2(14.0, 711.0, PORTRAIT_ROUND_BUTTON_SIZE, PORTRAIT_ROUND_BUTTON_SIZE)
const PORTRAIT_GAME_COMMENT_BUTTON_RECT := Rect2(94.0, 711.0, PORTRAIT_LONG_BUTTON_SIZE.x, PORTRAIT_LONG_BUTTON_SIZE.y)
const PORTRAIT_GAME_HINT_OPEN_RECT := Rect2(135.0, 604.0, 90.0, 46.0)
const PORTRAIT_GAME_HINT_REMOVE_RECT := Rect2(255.0, 604.0, 90.0, 46.0)

var _portrait_time_attack_difficulty_button: Control = null
var _portrait_custom_word_label: Label = null
var _portrait_game_adaptive_group: Control = null
var _portrait_game_hero_stage_position: Vector2 = PORTRAIT_HERO_POSITION
var _profile_name_edit: LineEdit = null
var _profile_edit_character_id: int = 1
var _profile_avatar_checks: Dictionary = {}
var _profile_avatar_halos: Dictionary = {}

func _clear(symbol_path: String = "") -> void:
	_remove_profile_edit_popup()
	super._clear(symbol_path)

func _portrait_begin_adaptive_group(pivot_stage_position: Vector2, max_scale: float, extra_y_shift_factor: float = 0.0) -> Control:
	var previous_content: Control = content
	var adaptive_group: Control = PORTRAIT_ADAPTIVE_GROUP_SCRIPT.new() as Control
	adaptive_group.name = "PortraitAdaptiveGroup"
	adaptive_group.set("pivot_stage_position", pivot_stage_position)
	adaptive_group.set("max_adaptive_scale", max_scale)
	adaptive_group.set("extra_y_shift_factor", extra_y_shift_factor)
	previous_content.add_child(adaptive_group)
	content = adaptive_group
	return previous_content

func _portrait_end_adaptive_group(previous_content: Control) -> void:
	content = previous_content

func _portrait_begin_bottom_attached_group() -> Control:
	var previous_content: Control = content
	var bottom_group := Control.new()
	bottom_group.name = "PortraitBottomAttached"
	bottom_group.set_anchors_preset(Control.PRESET_FULL_RECT)
	bottom_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	previous_content.add_child(bottom_group)
	content = bottom_group
	return previous_content

func _portrait_screen(header_height: float = PORTRAIT_HEADER_HEIGHT, footer_y: float = -1.0) -> void:
	_stage_texture_fill(0.0, PORTRAIT_STAGE_SIZE.y, MENU_PAPER_COVER)
	_stage_horizontal_fill(0.0, header_height, PORTRAIT_BLUE)
	if footer_y >= 0.0:
		_stage_horizontal_fill(footer_y, PORTRAIT_STAGE_SIZE.y - footer_y, PORTRAIT_BLUE)

func _portrait_popup_begin(name: String, group_name: String, layer_index: int, close_callable: Callable, popup_top: float, popup_bottom: float, alpha: float = PORTRAIT_POPUP_DIM_ALPHA) -> Control:
	var previous_content: Control = content
	var popup_layer := CanvasLayer.new()
	popup_layer.name = name + "Canvas"
	popup_layer.layer = layer_index
	popup_layer.add_to_group(group_name)
	add_child(popup_layer)

	var popup_root := Control.new()
	popup_root.name = name + "Layer"
	popup_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup_root.mouse_filter = Control.MOUSE_FILTER_STOP
	popup_layer.add_child(popup_root)
	content = popup_root
	_add_fullscreen_modal_backdrop(close_callable, alpha)
	content = _center_popup_content(popup_root, popup_top, popup_bottom)
	return previous_content

func _portrait_popup_shell(rect: Rect2, title: String, close_callable: Callable, title_font_size: int = 28) -> void:
	# Portrait popups are bottom-anchored by PopupStageCenter. Their authored
	# height is content-specific, so the top edge moves while the bottom edge and
	# thumb-reachable close button stay at a stable screen position.
	var header_rect := Rect2(rect.position, Vector2(rect.size.x, 80.0))
	var body_rect := Rect2(rect.position + Vector2(0.0, 80.0), Vector2(rect.size.x, rect.size.y - 80.0))
	var header := _stage_panel(header_rect, PORTRAIT_BLUE)
	header.mouse_filter = Control.MOUSE_FILTER_STOP
	var body := _stage_panel(body_rect, PORTRAIT_DARK_BLUE)
	body.mouse_filter = Control.MOUSE_FILTER_STOP
	var separator := _stage_panel(Rect2(rect.position.x, rect.position.y + 79.0, rect.size.x, 2.0), PORTRAIT_ORANGE)
	separator.mouse_filter = Control.MOUSE_FILTER_STOP
	var title_label := _stage_label(Rect2(rect.position.x + 20.0, rect.position.y + 10.0, rect.size.x - 40.0, 56.0), title, title_font_size, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	title_label.clip_text = false

	var close_x: float = rect.position.x + (rect.size.x - PORTRAIT_POPUP_CLOSE_SIZE) * 0.5
	var close_y: float = rect.end.y + PORTRAIT_POPUP_CLOSE_GAP
	_stage_round_button(Rect2(close_x, close_y, PORTRAIT_POPUP_CLOSE_SIZE, PORTRAIT_POPUP_CLOSE_SIZE), close_callable, "×")

func show_menu() -> void:
	game_timer.stop()
	GameSession.discard_current_round()
	_portrait_game_adaptive_group = null
	_clear("")

	# The main menu uses only the paper background. The profile avatar and
	# settings button stay pinned to opposite top corners without a blue header.
	_stage_texture_fill(0.0, PORTRAIT_STAGE_SIZE.y, MENU_PAPER_COVER)
	_stage_main_menu_character_button()
	_stage_round_button(PORTRAIT_CLOSE_BUTTON_RECT, Callable(self, "show_settings"), "⚙")

	# Keep the title visually centered, but do not scale the action buttons.
	# Long buttons use the same authored 300x64 size everywhere in the app; only
	# their vertical group is shifted lower on tall screens for thumb reach.
	var menu_title_content: Control = _portrait_begin_adaptive_group(Vector2(240.0, 260.0), PORTRAIT_MENU_TITLE_MAX_SCALE, 0.04)
	var title_label := _stage_label(Rect2(40.0, 188.0, 400.0, 88.0), Database.tr_text(0, "HANGMAN"), 50, PORTRAIT_ORANGE, HORIZONTAL_ALIGNMENT_CENTER)
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_portrait_end_adaptive_group(menu_title_content)

	var menu_buttons_content: Control = _portrait_begin_adaptive_group(Vector2(240.0, 570.0), 1.0, 0.22)
	var button_x: float = 90.0
	_stage_main_button(Rect2(button_x, 500.0, PORTRAIT_LONG_BUTTON_SIZE.x, PORTRAIT_LONG_BUTTON_SIZE.y), Callable(self, "show_theme_select"), Database.tr_text(1, "Classic"), 22)
	_stage_main_button(Rect2(button_x, 570.0, PORTRAIT_LONG_BUTTON_SIZE.x, PORTRAIT_LONG_BUTTON_SIZE.y), Callable(self, "_show_time_attack_popup"), Database.tr_text(2, "Time Attack"), 22)
	_stage_main_button(Rect2(button_x, 640.0, PORTRAIT_LONG_BUTTON_SIZE.x, PORTRAIT_LONG_BUTTON_SIZE.y), Callable(self, "show_custom_word"), Database.tr_text(3, "Two Player"), 22)
	_portrait_end_adaptive_group(menu_buttons_content)

func _stage_main_menu_character_button() -> void:
	var badge_rect := Rect2(8.0, 10.0, 86.0, 86.0)
	_stage_texture(badge_rect, HERO_BADGE_RING_TEXTURE)
	if _selected_character_id() == 2:
		_stage_texture(Rect2(21.0, 32.0, 60.0, 53.0), HERO_AVATAR_TIGRE_TEXTURE)
	else:
		_stage_texture(Rect2(30.0, 30.0, 43.0, 47.0), HERO_AVATAR_LAKI_TEXTURE)
	_stage_button(Rect2(2.0, 4.0, 100.0, 100.0), Callable(self, "show_profile"), "")

func _show_character_select_popup() -> void:
	_remove_character_select_popup()
	var previous_content := _portrait_popup_begin("CharacterSelectPopup", "character_select_popup", 100, Callable(self, "_remove_character_select_popup"), 170.0, 540.0)
	var rect := Rect2(28.0, 170.0, 424.0, 370.0)
	_portrait_popup_shell(rect, Database.tr_text(9, "Choose the hero:"), Callable(self, "_remove_character_select_popup"), 27)
	_stage_character_option(1, Rect2(62.0, 310.0, 120.0, 120.0), Database.tr_text(75, "LUCKY"), HERO_AVATAR_LAKI_TEXTURE, Rect2(91.0, 338.0, 62.0, 66.0))
	_stage_character_option(2, Rect2(298.0, 310.0, 120.0, 120.0), Database.tr_text(76, "EL TIGRE"), HERO_AVATAR_TIGRE_TEXTURE, Rect2(313.0, 344.0, 90.0, 79.0))
	content = previous_content

func show_settings() -> void:
	var previous_content: Control = content
	if settings_popup_return_content != null and is_instance_valid(settings_popup_return_content):
		previous_content = settings_popup_return_content
	_remove_settings_popup()
	settings_popup_return_content = previous_content
	var stored_previous := _portrait_popup_begin("SettingsPopup", "settings_popup", 100, Callable(self, "_remove_settings_popup"), 90.0, 580.0)
	var rect := Rect2(28.0, 90.0, 424.0, 490.0)
	_portrait_popup_shell(rect, Database.tr_text(5, "Settings"), Callable(self, "_remove_settings_popup"), 30)

	_stage_label(Rect2(56.0, 192.0, 250.0, 42.0), _settings_sound_label(), 21, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_settings_toggle_button(Rect2(330.0, 188.0, 102.0, 49.0), 3)
	_stage_label(Rect2(56.0, 260.0, 250.0, 42.0), _settings_vibration_label(), 21, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_settings_toggle_button(Rect2(330.0, 256.0, 102.0, 49.0), 4)
	_stage_panel(Rect2(56.0, 328.0, 368.0, 2.0), PORTRAIT_RULE)
	_stage_label(Rect2(56.0, 352.0, 190.0, 42.0), _settings_word_base_label(), 21, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_settings_language_button(Rect2(210.0, 350.0, 102.0, 49.0), "ru", Database.tr_text(80, "Rus"))
	_stage_settings_language_button(Rect2(322.0, 350.0, 102.0, 49.0), "en", Database.tr_text(81, "Eng"))
	_stage_panel(Rect2(56.0, 430.0, 368.0, 2.0), PORTRAIT_RULE)
	_stage_main_button(Rect2(44.0, 492.0, PORTRAIT_SMALL_BUTTON_SIZE.x, PORTRAIT_SMALL_BUTTON_SIZE.y), Callable(self, "_settings_about_action"), _settings_about_label(), 18)
	var remove_ads_button := _stage_main_button(Rect2(246.0, 492.0, PORTRAIT_SMALL_BUTTON_SIZE.x, PORTRAIT_SMALL_BUTTON_SIZE.y), Callable(self, "_settings_remove_ads_action"), _settings_remove_ads_label(), 18, true, 0.0, true)
	remove_ads_button.modulate = Color(1.0, 1.0, 1.0, 0.56)
	var remove_ads_label := remove_ads_button.get_node_or_null("Text") as Label
	if remove_ads_label != null:
		remove_ads_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.82))
	content = stored_previous

func _show_about_popup() -> void:
	_remove_about_popup()
	var previous_content := _portrait_popup_begin("AboutPopup", "about_popup", 110, Callable(self, "_remove_about_popup"), 130.0, 520.0, PORTRAIT_POPUP_DIM_ALPHA)
	var rect := Rect2(28.0, 130.0, 424.0, 390.0)
	_portrait_popup_shell(rect, _about_title_label(), Callable(self, "_remove_about_popup"), 30)
	var author_label := _stage_label(Rect2(56.0, 240.0, 368.0, 96.0), _about_author_text(), 21, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	author_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	author_label.clip_text = false
	var version_label := _stage_label(Rect2(56.0, 348.0, 368.0, 42.0), _about_version_text(), 20, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	version_label.clip_text = false
	_stage_panel(Rect2(56.0, 410.0, 368.0, 2.0), PORTRAIT_RULE)
	_stage_label(Rect2(56.0, 438.0, 180.0, 40.0), _about_contacts_label(), 21, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_round_icon_button(Rect2(224.0, 426.0, 62.0, 62.0), Callable(self, "_about_contact_action").bind("vk"), ABOUT_VK_ICON, Vector2(24.0, 14.0))
	_stage_round_icon_button(Rect2(306.0, 426.0, 62.0, 62.0), Callable(self, "_about_contact_action").bind("mail"), ABOUT_MAIL_ICON, Vector2(22.0, 18.0))
	content = previous_content

func show_theme_select() -> void:
	_remove_difficulty_popup()
	_clear("")
	# Keep the category cards on the graph-paper background and move all screen
	# navigation into a rigid footer block that follows the physical bottom edge.
	_portrait_screen(0.0, PORTRAIT_FOOTER_Y)
	var theme_title: String = Database.tr_text(32, "Choose the category:").strip_edges()
	if theme_title.ends_with(":"):
		theme_title = theme_title.substr(0, theme_title.length() - 1)
	_stage_label(Rect2(24.0, 14.0, 432.0, 70.0), theme_title, 38, PORTRAIT_BLUE, HORIZONTAL_ALIGNMENT_CENTER)

	for i in range(Database.get_theme_count()):
		var col: int = i % 2
		var row: int = int(i / 2)
		var x: float = 18.0 + float(col) * 230.0
		var y: float = 118.0 + float(row) * 104.0
		var words_count: int = Database.get_words_by_index(i, GameState.settings[2]).size()
		var guessed: int = Database.get_number_of_guessed_words(i, true)
		var guessed_percent: int = int(round(float(guessed) * 100.0 / float(words_count))) if words_count > 0 else 0
		var disabled: bool = words_count == 0
		var completed: bool = words_count > 0 and guessed >= words_count
		var card := _stage_texture(Rect2(x, y, 214.0, 88.0), THEME_CARD_TEXTURE)
		var progress_back := _stage_texture(Rect2(x, y, 214.0, 63.0), THEME_CARD_PROGRESS_TEXTURE)
		var progress_text: String = Database.tr_text(34, "Guessed") + ": " + str(guessed_percent) + "%"
		var progress_label := _stage_label(Rect2(x + 8.0, y + 7.0, 198.0, 28.0), progress_text, 16, Color(0.43, 0.49, 0.83, 1.0))
		progress_label.clip_text = false
		var theme_name: String = Database.get_theme_name(i).to_upper()
		var title_font_size: int = 19 if theme_name.length() > 12 else 23
		var title_label := _stage_label(Rect2(x + 6.0, y + 44.0, 202.0, 36.0), theme_name, title_font_size, Color.WHITE)
		title_label.clip_text = false
		title_label.add_theme_color_override("font_outline_color", Color(0.42, 0.49, 0.82, 1.0))
		title_label.add_theme_constant_override("outline_size", 2)
		if disabled:
			card.modulate = Color(1.0, 1.0, 1.0, 0.45)
			progress_back.modulate = Color(1.0, 1.0, 1.0, 0.45)
			progress_label.modulate = Color(1.0, 1.0, 1.0, 0.45)
			title_label.modulate = Color(1.0, 1.0, 1.0, 0.45)
		var action: Callable = Callable(self, "_show_clear_theme_popup").bind(i) if completed else Callable(self, "start_classic_game").bind(i)
		var theme_button := _stage_button(Rect2(x, y, 214.0, 88.0), action, "")
		theme_button.disabled = disabled

	# Footer controls are intentionally authored at y >= PORTRAIT_FOOTER_Y so
	# portrait_stage_layout moves the entire blue block to the actual screen bottom.
	_stage_round_icon_button(Rect2(14.0, 711.0, PORTRAIT_ROUND_BUTTON_SIZE, PORTRAIT_ROUND_BUTTON_SIZE), Callable(self, "show_menu"), PORTRAIT_BACK_ARROW_ICON, Vector2(27.0, 33.0))
	var difficulty_texture: Texture2D = _difficulty_star_texture()
	_stage_main_icon_button(Rect2(94.0, 711.0, PORTRAIT_LONG_BUTTON_SIZE.x, PORTRAIT_LONG_BUTTON_SIZE.y), Callable(self, "_show_difficulty_popup"), _portrait_difficulty_button_label(), difficulty_texture, difficulty_texture.get_size(), 22)

func _portrait_difficulty_button_label() -> String:
	return "Сложность:" if Database.current_language == "ru" else "Difficulty:"

func _show_clear_theme_popup(theme_index: int) -> void:
	_remove_clear_theme_popup()
	var previous_content := _portrait_popup_begin("ClearThemePopup", "clear_theme_popup", 125, Callable(self, "_remove_clear_theme_popup"), 250.0, 540.0)
	var rect := Rect2(35.0, 250.0, 410.0, 290.0)
	_portrait_popup_shell(rect, Database.tr_text(29, "Clear the category?"), Callable(self, "_remove_clear_theme_popup"), 25)
	var theme_name := Database.get_theme_name(theme_index).to_upper()
	var question_label := _stage_label(Rect2(65.0, 350.0, 350.0, 58.0), theme_name, 24, Color.WHITE)
	question_label.clip_text = false
	_stage_main_button(Rect2(44.0, 454.0, PORTRAIT_SMALL_BUTTON_SIZE.x, PORTRAIT_SMALL_BUTTON_SIZE.y), Callable(self, "_confirm_clear_theme").bind(theme_index), Database.tr_text(30, "Yes"), 20)
	_stage_main_button(Rect2(246.0, 454.0, PORTRAIT_SMALL_BUTTON_SIZE.x, PORTRAIT_SMALL_BUTTON_SIZE.y), Callable(self, "_remove_clear_theme_popup"), Database.tr_text(31, "No"), 20)
	content = previous_content

func _show_difficulty_popup() -> void:
	_remove_difficulty_popup()
	var previous_content := _portrait_popup_begin("ThemeDifficultyPopup", "difficulty_popup", 120, Callable(self, "_remove_difficulty_popup"), 100.0, 620.0)
	var rect := Rect2(28.0, 100.0, 424.0, 520.0)
	_portrait_popup_shell(rect, Database.tr_text(63, "Choose the difficulty level:"), Callable(self, "_remove_difficulty_popup"), 24)
	var options := [
		{"value": 2, "title": Database.tr_key(&"DIFFICULTY_EASY", "ПРОСТОЙ"), "desc": Database.tr_text(55, "Easy words")},
		{"value": 1, "title": Database.tr_key(&"DIFFICULTY_HARD", "СЛОЖНЫЙ"), "desc": Database.tr_text(56, "Hard words")},
		{"value": 0, "title": Database.tr_key(&"DIFFICULTY_GENERAL", "ОБЩИЙ"), "desc": Database.tr_text(57, "All words")},
	]
	for index in range(options.size()):
		var option: Dictionary = options[index]
		var value: int = int(option["value"])
		var y: float = 215.0 + float(index) * 145.0
		if index > 0:
			_stage_panel(Rect2(54.0, y - 20.0, 372.0, 2.0), PORTRAIT_RULE)
		var selected: bool = value == int(GameState.settings[2])
		var option_texture: Texture2D = _difficulty_star_texture(value)
		_stage_round_icon_button(Rect2(56.0, y + 2.0, PORTRAIT_ROUND_BUTTON_SIZE, PORTRAIT_ROUND_BUTTON_SIZE), Callable(self, "_set_difficulty_from_popup").bind(value), option_texture, option_texture.get_size(), false, selected)
		var title_label := _stage_label(Rect2(146.0, y - 2.0, 250.0, 34.0), str(option["title"]), 22, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
		title_label.clip_text = false
		var desc_label := _stage_label(Rect2(146.0, y + 36.0, 260.0, 38.0), str(option["desc"]), 16, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
		desc_label.clip_text = false
		_stage_button(Rect2(44.0, y - 8.0, 382.0, 90.0), Callable(self, "_set_difficulty_from_popup").bind(value), "")
	content = previous_content

func _show_time_attack_popup() -> void:
	_remove_time_attack_popup()
	var previous_content := _portrait_popup_begin("TimeAttackPopup", "time_attack_popup", 115, Callable(self, "_remove_time_attack_popup"), 120.0, 674.0)
	var rect := Rect2(28.0, 120.0, 424.0, 554.0)
	_portrait_popup_shell(rect, tr("TIME_ATTACK_MODE"), Callable(self, "_remove_time_attack_popup"), 29)
	var difficulty_texture: Texture2D = _difficulty_star_texture()
	_portrait_time_attack_difficulty_button = _stage_round_icon_button(Rect2(316.0, 129.0, 62.0, 62.0), Callable(self, "_cycle_time_attack_difficulty"), difficulty_texture, difficulty_texture.get_size())
	_stage_texture(Rect2(174.0, 238.0, 133.0, 133.0), TIME_ATTACK_BADGE_OUTER_TEXTURE)
	_stage_texture(Rect2(185.0, 249.0, 111.0, 111.0), HERO_BADGE_RING_TEXTURE)
	_stage_texture(Rect2(221.5, 281.0, 38.0, 46.0), TIME_ATTACK_HOURGLASS_TEXTURE)
	var description_label := _stage_label(Rect2(62.0, 382.0, 356.0, 96.0), tr("TIME_ATTACK_DESCRIPTION"), 18, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	description_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	description_label.clip_text = true
	var record_text: String = tr("RECORD_LABEL") + " " + str(int(GameState.records[2][2]))
	var record_label := _stage_score_with_star(Rect2(74.0, 500.0, 332.0, 38.0), record_text, 21, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	record_label.clip_text = false
	_stage_main_button(Rect2(90.0, 586.0, PORTRAIT_LONG_BUTTON_SIZE.x, PORTRAIT_LONG_BUTTON_SIZE.y), Callable(self, "_start_time_attack_from_popup"), tr("START"), 22)
	content = previous_content

func _cycle_time_attack_difficulty() -> void:
	GameState.settings[2] = (int(GameState.settings[2]) + 1) % 3
	GameState.save_game()
	if _portrait_time_attack_difficulty_button != null and is_instance_valid(_portrait_time_attack_difficulty_button):
		var difficulty_texture: Texture2D = _difficulty_star_texture()
		_portrait_time_attack_difficulty_button.call("configure_texture", difficulty_texture, difficulty_texture.get_size())

func show_custom_word() -> void:
	game_timer.stop()
	_clear("")
	# Two-player words no longer support comments, gameplay hints, or automatic
	# opening of the first and last letters.
	var settings_changed: bool = false
	if int(GameState.settings[0]) != 1:
		GameState.settings[0] = 1
		settings_changed = true
	if int(GameState.settings[1]) != 1:
		GameState.settings[1] = 1
		settings_changed = true
	if settings_changed:
		GameState.save_game()
	custom_comment_text = ""

	_portrait_screen(124.0, PORTRAIT_FOOTER_Y)
	# Reuse the same word display as the guessing screen: plain white text on the
	# blue header, without a separate white input capsule.
	_portrait_custom_word_label = _stage_label(Rect2(20.0, 18.0, 290.0, 68.0), _custom_word_display_text(), 34, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_portrait_custom_word_label.clip_text = true

	# Keep an invisible LineEdit only as the existing validation/checking state
	# holder. All visible input is performed through the on-screen letter keys.
	custom_word_edit = LineEdit.new()
	custom_word_edit.visible = false
	custom_word_edit.max_length = 35
	custom_word_edit.text = custom_word_text
	custom_word_edit.text_changed.connect(_on_custom_word_text_changed)
	content.add_child(custom_word_edit)

	_stage_label(Rect2(20.0, 80.0, 205.0, 30.0), _custom_word_max_length_label(), 19, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_label(Rect2(190.0, 80.0, 125.0, 30.0), _custom_word_random_label(), 19, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
	_stage_round_icon_button(PORTRAIT_ACTION_BUTTON_RECT, Callable(self, "_set_random_custom_word"), CUSTOM_WORD_RANDOM_ICON, Vector2(38.0, 32.0))

	var custom_word_root_content: Control = _portrait_begin_adaptive_group(Vector2(240.0, 350.0), PORTRAIT_DENSE_MAX_SCALE, 0.12)
	_stage_custom_word_keyboard()

	_stage_main_button(Rect2(120.0, 505.0, 240.0, 54.0), Callable(self, "_check_custom_word_now"), Database.tr_text(68, "Check the word"), 21)
	var check_color := Color.WHITE
	if custom_word_check_state == 2:
		check_color = Color(0.58, 0.88, 0.72)
	elif custom_word_check_state == 3:
		check_color = Color(0.96, 0.67, 0.77)
	custom_word_check_label = _stage_label(Rect2(60.0, 563.0, 360.0, 28.0), custom_word_check_text, 17, check_color)
	_portrait_end_adaptive_group(custom_word_root_content)

	# Match the category screen footer: navigation on the left and the primary
	# action centered inside the rigid bottom blue block.
	_stage_round_icon_button(Rect2(14.0, 711.0, PORTRAIT_ROUND_BUTTON_SIZE, PORTRAIT_ROUND_BUTTON_SIZE), Callable(self, "show_menu"), PORTRAIT_BACK_ARROW_ICON, Vector2(27.0, 33.0))
	_stage_main_button(Rect2(94.0, 711.0, PORTRAIT_LONG_BUTTON_SIZE.x, PORTRAIT_LONG_BUTTON_SIZE.y), Callable(self, "start_custom_game"), _custom_word_start_label(), 22)

func _stage_custom_word_keyboard() -> void:
	var alphabet: PackedStringArray = Database.get_alphabet()
	var columns: int = 6
	var keyboard_start_x: float = 48.0
	var keyboard_start_y: float = 145.0
	var keyboard_step_x: float = 64.0
	var keyboard_step_y: float = 48.0
	var key_size := Vector2(50.0, 46.0)
	for i in range(alphabet.size()):
		var letter: String = alphabet[i]
		var row: int = int(i / columns)
		var col: int = i % columns
		var x: float = keyboard_start_x + float(col) * keyboard_step_x
		var y: float = keyboard_start_y + float(row) * keyboard_step_y
		var key_rect := Rect2(x, y, key_size.x, key_size.y)
		_stage_letter_button(key_rect, Callable(self, "_append_custom_word_character").bind(letter), letter)

	_stage_main_button(Rect2(42.0, 442.0, 164.0, 50.0), Callable(self, "_append_custom_word_character").bind(" "), _custom_word_space_label(), 17)
	_stage_main_button(Rect2(211.0, 442.0, 72.0, 50.0), Callable(self, "_append_custom_word_character").bind("—"), "—", 20)
	_stage_main_button(Rect2(288.0, 442.0, 150.0, 50.0), Callable(self, "_remove_custom_word_character"), "⌫", 22)

func _custom_word_space_label() -> String:
	return "Пробел" if Database.current_language == "ru" else "Space"

func _append_custom_word_character(character: String) -> void:
	if custom_word_edit == null or custom_word_text.length() >= 35:
		return
	var updated: String = _normalize_custom_word_input(custom_word_text + character)
	_set_custom_word_from_keyboard(updated)

func _remove_custom_word_character() -> void:
	if custom_word_edit == null or custom_word_text.is_empty():
		return
	_set_custom_word_from_keyboard(custom_word_text.substr(0, custom_word_text.length() - 1))

func _custom_word_display_text() -> String:
	if custom_word_text.is_empty():
		return Database.tr_text(41, "Input the word")
	return custom_word_text

func _sync_custom_word_display() -> void:
	if _portrait_custom_word_label != null and is_instance_valid(_portrait_custom_word_label):
		_portrait_custom_word_label.text = _custom_word_display_text()

func _set_custom_word_from_keyboard(value: String) -> void:
	custom_word_text = value
	if custom_word_edit != null:
		custom_word_edit.text = custom_word_text
		custom_word_edit.caret_column = custom_word_edit.text.length()
	_sync_custom_word_display()

func _on_custom_word_text_changed(value: String) -> void:
	super._on_custom_word_text_changed(value)
	_sync_custom_word_display()

func _set_random_custom_word() -> void:
	super._set_random_custom_word()
	_sync_custom_word_display()

func start_custom_game() -> void:
	# Two-player rounds always start without comments, hints, or edge letters.
	GameState.settings[0] = 1
	GameState.settings[1] = 1
	custom_comment_text = ""
	super.start_custom_game()

func _refresh_game_screen() -> void:
	if content == null:
		return
	if game_finished:
		show_result_screen(last_result_is_win, last_result_data)
		return
	for child: Node in content.get_children():
		content.remove_child(child)
		child.queue_free()

	var viewport_size: Vector2 = get_viewport_rect().size
	var extra_stage_height: float = PORTRAIT_STAGE_LAYOUT.extra_stage_height(viewport_size)
	var upper_block_shift: float = extra_stage_height * 0.5
	_portrait_screen(0.0, PORTRAIT_FOOTER_Y)

	# All gameplay modes share one portrait composition: the hero stays on the
	# left beside hints, but is centered when Two Player has no hint controls.
	# The word and keyboard remain attached to the footer in every mode.
	var hero_pivot := Vector2(138.0, 206.0 + upper_block_shift)
	var hero_stage_position := Vector2(76.0, 222.0 + upper_block_shift)
	if GameState.current_mode == 2:
		# Two-player rounds have no hint controls, so use their free column and
		# center the hero (the symbol pivot is 62 px to the right of its origin).
		hero_pivot.x = PORTRAIT_STAGE_SIZE.x * 0.5
		hero_stage_position.x = hero_pivot.x - 62.0
	var hero_root_content: Control = _portrait_begin_adaptive_group(
		hero_pivot,
		1.0,
		0.0
	)
	_portrait_game_adaptive_group = content
	_portrait_game_hero_stage_position = hero_stage_position
	hero_static_symbol = _stage_symbol(_hero_symbol_path(), hero_stage_position, _hero_animation_time(), 4.0 / 24.0) as FlashStageSymbol
	if hero_static_symbol != null:
		hero_static_symbol.stage_scale_multiplier = PORTRAIT_HERO_SCALE_MULTIPLIER

	var stage_upper_hints: bool = GameState.current_mode != 2
	var open_hint_rect := Rect2(
		340.0,
		124.0 + upper_block_shift,
		PORTRAIT_GAME_HINT_OPEN_RECT.size.x,
		PORTRAIT_GAME_HINT_OPEN_RECT.size.y
	)
	var remove_hint_rect := Rect2(
		340.0,
		186.0 + upper_block_shift,
		PORTRAIT_GAME_HINT_REMOVE_RECT.size.x,
		PORTRAIT_GAME_HINT_REMOVE_RECT.size.y
	)

	if GameState.current_mode == 1:
		var hud_y: float = 2.0 + upper_block_shift
		_stage_portrait_time_attack_hud(
			Rect2(46.0, hud_y, 190.0, 40.0),
			Rect2(310.0, hud_y, 140.0, 40.0)
		)

	if stage_upper_hints:
		var open_hint_disabled: bool = !GameSession.can_use_open_letter_hint()
		var remove_hint_disabled: bool = !GameSession.can_use_remove_wrong_hint()
		_stage_portrait_hint_buttons(
			open_hint_rect,
			remove_hint_rect,
			open_hint_disabled,
			remove_hint_disabled
		)
	_portrait_end_adaptive_group(hero_root_content)

	var alphabet := Database.get_alphabet()
	var columns: int = 6
	var keyboard_step_x: float = 66.0
	var keyboard_step_y: float = 48.0
	var key_size := Vector2(50.0, 46.0)
	var marker_size := Vector2(44.0, 44.0)
	var keyboard_font_size: int = 29

	# Match the successful Classic keyboard in every mode. The bottom attached
	# group keeps the footer gap stable, while the same adaptive scale preserves
	# the larger Two Player letter size and spacing on tall screens.
	var keyboard_scale: float = PORTRAIT_STAGE_LAYOUT.adaptive_ui_scale(
		viewport_size,
		PORTRAIT_GAME_KEYBOARD_MAX_SCALE
	)
	keyboard_step_x *= keyboard_scale
	keyboard_step_y *= keyboard_scale
	key_size *= keyboard_scale
	marker_size *= keyboard_scale
	keyboard_font_size = int(round(29.0 * keyboard_scale))

	var keyboard_total_width: float = key_size.x + float(columns - 1) * keyboard_step_x
	var keyboard_start_x: float = (PORTRAIT_STAGE_SIZE.x - keyboard_total_width) * 0.5
	var keyboard_rows: int = int(ceil(float(alphabet.size()) / float(columns)))
	var keyboard_height: float = key_size.y + float(maxi(0, keyboard_rows - 1)) * keyboard_step_y
	var keyboard_footer_gap: float = 24.0
	var keyboard_start_y: float = PORTRAIT_FOOTER_Y - keyboard_footer_gap - keyboard_height

	var keyboard_root_content: Control = _portrait_begin_bottom_attached_group()
	_stage_portrait_game_word_display(Rect2(22.0, keyboard_start_y - 120.0, 436.0, 64.0), 34)

	for i in range(alphabet.size()):
		var letter: String = alphabet[i]
		var row: int = int(i / columns)
		var col: int = i % columns
		var x: float = keyboard_start_x + float(col) * keyboard_step_x
		var y: float = keyboard_start_y + float(row) * keyboard_step_y
		var was_correct: bool = GameSession.correct_letters.has(letter)
		var was_wrong: bool = GameSession.wrong_letters.has(letter)
		var was_removed: bool = GameSession.removed_wrong_letters.has(letter)
		var state: int = StageLetterButton.LetterState.NORMAL
		if was_correct:
			state = StageLetterButton.LetterState.CIRCLED
		elif was_wrong or was_removed:
			state = StageLetterButton.LetterState.CROSSED
		var key_rect := Rect2(x, y, key_size.x, key_size.y)
		var animate_state: bool = letter == pending_letter_marker and (
			(state == StageLetterButton.LetterState.CIRCLED and pending_letter_marker_is_correct)
			or (state == StageLetterButton.LetterState.CROSSED and !pending_letter_marker_is_correct)
		)
		_stage_letter_button(
			key_rect,
			Callable(self, "_press_letter").bind(letter),
			letter,
			state,
			!GameSession.is_active or state != StageLetterButton.LetterState.NORMAL,
			keyboard_font_size,
			marker_size,
			animate_state
		)
	_portrait_end_adaptive_group(keyboard_root_content)

	var comment_disabled: bool = GameSession.get_word_hint().strip_edges() == ""
	_stage_round_icon_button(PORTRAIT_GAME_BACK_BUTTON_RECT, Callable(self, "_game_footer_back_action"), PORTRAIT_BACK_ARROW_ICON, Vector2(27.0, 33.0))
	var comment_button := _stage_main_button(PORTRAIT_GAME_COMMENT_BUTTON_RECT, Callable(self, "_show_word_comment_popup"), Database.tr_text(47, "Comment"), 22, comment_disabled, 0.0)
	if GameState.current_mode == 0:
		_stage_round_icon_button(PORTRAIT_RESULT_THEME_BUTTON_RECT, Callable(self, "show_theme_select"), PORTRAIT_RESULT_THEME_MENU_ICON, Vector2(32.0, 30.0))
	if comment_disabled:
		comment_button.modulate = Color(1.0, 1.0, 1.0, 0.56)
		var comment_label := comment_button.get_node_or_null("Text") as Label
		if comment_label != null:
			comment_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.82))
	pending_letter_marker = ""
	pending_letter_marker_is_correct = false

func _game_footer_back_action() -> void:
	_game_header_action()

func _stage_portrait_game_word_display(rect: Rect2, font_size: int = 34) -> void:
	if GameSession.letters.is_empty():
		return

	var layout: Array = []
	var total_width: float = 0.0
	var base_slot_width: float = 38.0
	var base_space_width: float = 18.0
	var base_gap: float = 10.0
	for i in range(GameSession.letters.size()):
		var letter: String = GameSession.letters[i]
		var is_space: bool = letter == " "
		var item_width: float = base_space_width if is_space else base_slot_width
		layout.append({
			"letter": letter,
			"revealed": bool(GameSession.revealed[i]),
			"is_space": is_space,
			"is_dash": letter == "-" or letter == "—",
			"width": item_width,
		})
		total_width += item_width
		if i < GameSession.letters.size() - 1:
			total_width += base_gap

	var scale: float = min(1.0, rect.size.x / max(total_width, 1.0))
	var slot_gap: float = base_gap * scale
	var underline_width: float = 30.0 * scale
	var underline_height: float = max(3.0, 4.0 * scale)
	var effective_font_size: int = maxi(24, int(round(font_size * max(scale, 0.82))))
	var start_x: float = rect.position.x + (rect.size.x - total_width * scale) * 0.5
	var baseline_y: float = rect.position.y + rect.size.y - 8.0
	var x: float = start_x

	for i in range(layout.size()):
		var item: Dictionary = layout[i]
		var item_width: float = float(item["width"]) * scale
		var letter: String = str(item["letter"])
		var is_space: bool = bool(item["is_space"])
		var is_dash: bool = bool(item["is_dash"])
		var revealed: bool = bool(item["revealed"])
		if !revealed and !is_space and !is_dash:
			_stage_panel(Rect2(
				x + (item_width - underline_width) * 0.5,
				baseline_y,
				underline_width,
				underline_height
			), PORTRAIT_ORANGE)
		if (revealed and !is_space) or is_dash:
			var letter_label := _stage_label(Rect2(x, rect.position.y, item_width, rect.size.y - 10.0), letter, effective_font_size, PORTRAIT_BLUE, HORIZONTAL_ALIGNMENT_CENTER)
			letter_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			letter_label.clip_text = false
		x += item_width
		if i < layout.size() - 1:
			x += slot_gap

func _stage_portrait_hint_buttons(open_hint_rect: Rect2, remove_hint_rect: Rect2, open_hint_disabled: bool, remove_hint_disabled: bool) -> void:
	_stage_texture_button(open_hint_rect, Callable(self, "_use_open_hint"), HINT_REMOVE_BUTTON_TEXTURE, HINT_OPEN_BUTTON_TEXTURE, "", 26, open_hint_disabled, HINT_REMOVE_BUTTON_TEXTURE, 0.44)
	var open_hint_icon := _stage_texture(Rect2(
		open_hint_rect.position.x + (open_hint_rect.size.x - 28.0) * 0.5,
		open_hint_rect.position.y + (open_hint_rect.size.y - 28.0) * 0.5,
		28.0,
		28.0
	), HINT_ICON_CHECK_TEXTURE)
	if open_hint_disabled:
		open_hint_icon.modulate = Color(1.0, 1.0, 1.0, 0.66)
	_stage_texture_button(remove_hint_rect, Callable(self, "_use_remove_hint"), HINT_REMOVE_BUTTON_TEXTURE, HINT_OPEN_BUTTON_TEXTURE, "", 26, remove_hint_disabled, HINT_OPEN_BUTTON_TEXTURE, 0.0)
	_stage_texture(Rect2(
		remove_hint_rect.position.x + (remove_hint_rect.size.x - 28.0) * 0.5,
		remove_hint_rect.position.y + (remove_hint_rect.size.y - 28.0) * 0.5,
		28.0,
		28.0
	), HINT_ICON_CROSS_TEXTURE)

func _stage_portrait_time_attack_hud(timer_rect: Rect2, score_rect: Rect2) -> void:
	var timer_icon_size := Vector2(31.0, 31.0)
	var timer_icon_y: float = timer_rect.position.y + (timer_rect.size.y - timer_icon_size.y) * 0.5
	_stage_texture(Rect2(timer_rect.position.x, timer_icon_y, timer_icon_size.x, timer_icon_size.y), TIME_ATTACK_TIMER_ICON_TEXTURE)
	var time_label := _stage_label(
		Rect2(timer_rect.position.x + 38.0, timer_rect.position.y, timer_rect.size.x - 38.0, timer_rect.size.y),
		_format_time(GameState.current_time_left),
		22,
		PORTRAIT_BLUE,
		HORIZONTAL_ALIGNMENT_LEFT
	)
	time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_stage_score_with_star(
		score_rect,
		str(GameState.current_score),
		22,
		PORTRAIT_BLUE,
		HORIZONTAL_ALIGNMENT_CENTER,
		Color.WHITE,
		1
	)

func _play_hero_wrong_guess_animation(current_mistakes: int) -> void:
	_clear_hero_animation_overlay()
	if hero_static_symbol != null and is_instance_valid(hero_static_symbol):
		hero_static_symbol.visible = false
	var overlay := FlashStageSymbol.new()
	overlay.name = "HeroAnimationOverlay"
	overlay.z_index = 150
	overlay.symbol_path = _hero_symbol_path()
	overlay.stage_position = _portrait_game_hero_stage_position
	overlay.stage_scale_multiplier = PORTRAIT_HERO_SCALE_MULTIPLIER
	overlay.animation_time = _hero_animation_time_for_mistakes(current_mistakes)
	overlay.nested_animation_time = HERO_MOV_START_FRAME_TIME
	overlay.playback_finished.connect(_on_hero_wrong_guess_animation_finished)
	if _portrait_game_adaptive_group != null and is_instance_valid(_portrait_game_adaptive_group):
		_portrait_game_adaptive_group.add_child(overlay)
	else:
		add_child(overlay)
	hero_animation_overlay = overlay
	overlay.call_deferred("play_nested_range", _hero_animation_time_for_mistakes(current_mistakes), HERO_MOV_START_FRAME_TIME, HERO_MOV_IDLE_FRAME_TIME, HERO_WRONG_GUESS_ANIMATION_SPEED_SCALE)

func _portrait_result_title_color(is_win: bool, time_attack_finished: bool = false) -> Color:
	if time_attack_finished:
		return PORTRAIT_ORANGE
	return StageLetterButton.CIRCLED_COLOR if is_win else StageLetterButton.CROSSED_COLOR

func show_result_screen(is_win: bool, data: Dictionary = {}) -> void:
	game_timer.stop()
	_portrait_game_adaptive_group = null
	_clear("")
	_portrait_screen(PORTRAIT_HEADER_HEIGHT, PORTRAIT_FOOTER_Y)
	var full_word: String = _spaced_result_word(GameSession.get_full_word())
	var result_word_label := _stage_label(Rect2(20.0, 18.0, 440.0, 68.0), full_word, 29, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	result_word_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_word_label.clip_text = true
	if GameState.current_mode == 0:
		_show_classic_result_content(is_win, data)
		return
	if GameState.current_mode == 2:
		_show_two_player_result_content(is_win, data)
		return
	var time_attack_finished: bool = GameState.current_mode == 1 and bool(data.get("time_attack_finished", false))
	if time_attack_finished:
		_show_time_attack_finished_result_content(data)
		return
	_stage_round_icon_button(PORTRAIT_ACTION_BUTTON_RECT, Callable(self, "_open_word_search"), RESULT_SEARCH_ICON, Vector2(23.0, 29.0))
	_stage_round_icon_button(PORTRAIT_CLOSE_BUTTON_RECT, Callable(self, "show_menu"), RESULT_CLOSE_ICON, Vector2(23.0, 23.0))
	var result_root_content: Control = _portrait_begin_adaptive_group(Vector2(240.0, 410.0), PORTRAIT_RESULT_MAX_SCALE, 0.12)
	hero_static_symbol = _stage_symbol(_hero_symbol_path(), PORTRAIT_HERO_RESULT_POSITION, _hero_animation_time(), HERO_MOV_IDLE_FRAME_TIME) as FlashStageSymbol
	if hero_static_symbol != null:
		hero_static_symbol.stage_scale_multiplier = PORTRAIT_HERO_SCALE_MULTIPLIER
	var title: String = Database.tr_text(37 if is_win else 38, "VICTORY" if is_win else "DEFEAT").strip_edges()
	var title_label := _stage_label(Rect2(48.0, 330.0, 384.0, 70.0), title, 38, _portrait_result_title_color(is_win, time_attack_finished))
	title_label.clip_text = false
	_apply_result_text_glow(title_label, Color.WHITE, 2)
	var result_score_line: String = _result_score_line(data)
	if result_score_line != "":
		_stage_score_with_star(Rect2(64.0, 410.0, 352.0, 38.0), result_score_line, 21, PORTRAIT_BLUE, HORIZONTAL_ALIGNMENT_CENTER, Color.WHITE, 1)
		var remaining_message: String = _result_non_score_lines(data)
		if remaining_message != "":
			var remaining_label := _stage_label(Rect2(64.0, 456.0, 352.0, 58.0), remaining_message, 19, PORTRAIT_BLUE)
			remaining_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	else:
		var result_message: String = _result_message(is_win, data)
		var message_label := _stage_label(Rect2(64.0, 410.0, 352.0, 82.0), result_message, 20, PORTRAIT_BLUE)
		message_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	if GameState.current_mode == 0:
		_stage_label(Rect2(64.0, 540.0, 352.0, 42.0), _result_theme_label(), 20, PORTRAIT_BLUE)
	_portrait_end_adaptive_group(result_root_content)
	var show_left_button: bool = GameState.current_mode == 0
	if show_left_button:
		_stage_main_button(Rect2(14.0, 708.0, 220.0, 57.0), Callable(self, "_result_left_action"), _result_left_button_text(), 20)
	_stage_main_button(Rect2(248.0, 708.0, 220.0, 57.0), Callable(self, "_result_right_action"), _result_right_button_text(), 20)

func _show_two_player_result_content(is_win: bool, data: Dictionary) -> void:
	# The two-player result uses the same thumb-friendly composition as the final
	# Time Attack screen: compact search in the header, centered result copy and
	# hero, plus close/restart controls in the rigid footer.
	_stage_round_icon_button(PORTRAIT_RESULT_HEADER_SEARCH_BUTTON_RECT, Callable(self, "_open_word_search"), RESULT_SEARCH_ICON, Vector2(16.0, 20.0))

	var result_root_content: Control = _portrait_begin_adaptive_group(Vector2(240.0, 390.0), 1.15, 0.08)
	var title: String = Database.tr_text(37 if is_win else 38, "VICTORY" if is_win else "DEFEAT").strip_edges()
	if title == "":
		title = "VICTORY" if is_win else "DEFEAT"
	var title_label := _stage_label(Rect2(40.0, 150.0, 400.0, 66.0), title, 38, _portrait_result_title_color(is_win))
	title_label.clip_text = false
	_apply_result_text_glow(title_label, Color.WHITE, 2)

	var subtitle: String = _result_message(is_win, data)
	var subtitle_label := _stage_label(Rect2(52.0, 216.0, 376.0, 72.0), subtitle, 21, PORTRAIT_BLUE)
	subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	subtitle_label.clip_text = false

	hero_static_symbol = _stage_symbol(_hero_symbol_path(), PORTRAIT_HERO_TIME_RESULT_POSITION, _hero_animation_time(), HERO_MOV_IDLE_FRAME_TIME) as FlashStageSymbol
	if hero_static_symbol != null:
		hero_static_symbol.stage_scale_multiplier = PORTRAIT_HERO_SCALE_MULTIPLIER
	_portrait_end_adaptive_group(result_root_content)

	_stage_round_icon_button(PORTRAIT_RESULT_CLOSE_BUTTON_RECT, Callable(self, "show_menu"), RESULT_CLOSE_ICON, Vector2(23.0, 23.0))
	_stage_main_button(PORTRAIT_RESULT_CONTINUE_BUTTON_RECT, Callable(self, "_result_right_action"), _result_right_button_text(), 22)

func _show_time_attack_finished_result_content(data: Dictionary) -> void:
	# Match the classic result layout: compact search in the header, result copy
	# above a centered hero, and thumb-reachable controls in the rigid footer.
	_stage_round_icon_button(PORTRAIT_RESULT_HEADER_SEARCH_BUTTON_RECT, Callable(self, "_open_word_search"), RESULT_SEARCH_ICON, Vector2(16.0, 20.0))

	var result_root_content: Control = _portrait_begin_adaptive_group(Vector2(240.0, 390.0), 1.15, 0.08)
	var title: String = str(data.get("title", Database.tr_text(39, "GAME OVER"))).strip_edges()
	if title == "":
		title = Database.tr_text(39, "GAME OVER")
	var title_label := _stage_label(Rect2(40.0, 150.0, 400.0, 66.0), title, 38, _portrait_result_title_color(false, true))
	title_label.clip_text = false
	_apply_result_text_glow(title_label, Color.WHITE, 2)

	var final_score: int = int(data.get("final_score", GameState.current_score))
	var final_score_text: String = Database.tr_key(&"FINAL_SCORE", "Final score:") + " " + str(final_score)
	_stage_score_with_star(Rect2(52.0, 216.0, 376.0, 42.0), final_score_text, 22, PORTRAIT_BLUE, HORIZONTAL_ALIGNMENT_CENTER, Color.WHITE, 1)

	var final_details: String = _result_data_lines(data)
	if final_details != "":
		var details_label := _stage_label(Rect2(52.0, 260.0, 376.0, 58.0), final_details, 19, PORTRAIT_BLUE)
		details_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		details_label.clip_text = false

	hero_static_symbol = _stage_symbol(_hero_symbol_path(), PORTRAIT_HERO_TIME_RESULT_POSITION, _hero_animation_time(), HERO_MOV_IDLE_FRAME_TIME) as FlashStageSymbol
	if hero_static_symbol != null:
		hero_static_symbol.stage_scale_multiplier = PORTRAIT_HERO_SCALE_MULTIPLIER
	_portrait_end_adaptive_group(result_root_content)

	_stage_round_icon_button(PORTRAIT_RESULT_CLOSE_BUTTON_RECT, Callable(self, "show_menu"), RESULT_CLOSE_ICON, Vector2(23.0, 23.0))
	_stage_main_button(PORTRAIT_RESULT_CONTINUE_BUTTON_RECT, Callable(self, "_result_right_action"), _result_right_button_text(), 22)

func _show_classic_result_content(is_win: bool, data: Dictionary) -> void:
	var result_root_content: Control = _portrait_begin_adaptive_group(Vector2(240.0, 390.0), 1.15, 0.08)
	var title: String = Database.tr_text(37 if is_win else 38, "VICTORY" if is_win else "DEFEAT").strip_edges()
	var title_label := _stage_label(Rect2(40.0, 150.0, 400.0, 66.0), title, 38, _portrait_result_title_color(is_win))
	title_label.clip_text = false
	_apply_result_text_glow(title_label, Color.WHITE, 2)

	var subtitle: String = _result_non_score_lines(data)
	if subtitle == "":
		subtitle = Database.tr_text(49 if is_win else 50, "Keep going!" if is_win else "You can do better!")
	var subtitle_label := _stage_label(Rect2(52.0, 216.0, 376.0, 58.0), subtitle, 21, PORTRAIT_BLUE)
	subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	subtitle_label.clip_text = false

	var result_score_line: String = _result_score_line(data)
	if result_score_line != "":
		_stage_score_with_star(Rect2(64.0, 274.0, 352.0, 38.0), result_score_line, 20, PORTRAIT_BLUE, HORIZONTAL_ALIGNMENT_CENTER, Color.WHITE, 1)

	hero_static_symbol = _stage_symbol(_hero_symbol_path(), PORTRAIT_HERO_CLASSIC_RESULT_POSITION, _hero_animation_time(), HERO_MOV_IDLE_FRAME_TIME) as FlashStageSymbol
	if hero_static_symbol != null:
		hero_static_symbol.stage_scale_multiplier = PORTRAIT_HERO_SCALE_MULTIPLIER
	_portrait_end_adaptive_group(result_root_content)

	var bottom_info_content: Control = _portrait_begin_bottom_attached_group()
	var theme_label := _stage_label(Rect2(40.0, 616.0, 400.0, 50.0), _result_theme_label(), 20, PORTRAIT_BLUE, HORIZONTAL_ALIGNMENT_CENTER)
	theme_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	theme_label.clip_text = false
	_portrait_end_adaptive_group(bottom_info_content)

	# Word search remains in the header, but uses a compact 70% round button.
	_stage_round_icon_button(PORTRAIT_RESULT_HEADER_SEARCH_BUTTON_RECT, Callable(self, "_open_word_search"), RESULT_SEARCH_ICON, Vector2(16.0, 20.0))
	_stage_round_icon_button(PORTRAIT_RESULT_CLOSE_BUTTON_RECT, Callable(self, "show_menu"), RESULT_CLOSE_ICON, Vector2(23.0, 23.0))
	_stage_round_icon_button(PORTRAIT_RESULT_THEME_BUTTON_RECT, Callable(self, "show_theme_select"), PORTRAIT_RESULT_THEME_MENU_ICON, Vector2(32.0, 30.0))
	_stage_main_button(PORTRAIT_RESULT_CONTINUE_BUTTON_RECT, Callable(self, "_result_right_action"), _result_right_button_text(), 22)

func show_records() -> void:
	show_profile()

func show_profile() -> void:
	game_timer.stop()
	_clear("")
	_portrait_screen(112.0)
	_stage_label(Rect2(22.0, 24.0, 330.0, 62.0), _profile_text("ПРОФИЛЬ", "PROFILE"), 36, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_round_button(PORTRAIT_CLOSE_BUTTON_RECT, Callable(self, "show_menu"), "×")

	var profile_root_content: Control = _portrait_begin_adaptive_group(Vector2(240.0, 430.0), PORTRAIT_PROFILE_MAX_SCALE, 0.08)
	_stage_profile_header_card()
	_stage_label(Rect2(26.0, 310.0, 428.0, 40.0), _profile_text("СТАТИСТИКА", "STATISTICS"), 27, PORTRAIT_BLUE, HORIZONTAL_ALIGNMENT_LEFT)
	_portrait_profile_stat_row(354.0, tr("MENU_CLASSIC"), tr("RECORD_EASY_STREAK"), int(GameState.records[0][2]), tr("RECORD_HARD_STREAK"), int(GameState.records[0][3]), false)
	_portrait_profile_stat_row(468.0, tr("MENU_TIME_ATTACK"), tr("SCORE"), int(GameState.records[2][2]), tr("VICTORIES_PER_GAME"), int(GameState.records[2][1]), true)
	_portrait_profile_stat_row(582.0, tr("MENU_TWO_PLAYER"), tr("VICTORIES"), int(GameState.records[1][0]), tr("DEFEATS"), int(GameState.records[1][1]), false)
	_portrait_end_adaptive_group(profile_root_content)

func _stage_profile_header_card() -> void:
	var card_rect := Rect2(24.0, 136.0, 432.0, 150.0)
	var card := _stage_panel(card_rect, PORTRAIT_DARK_BLUE, 22.0, PORTRAIT_RULE, 2.0)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	_stage_texture(Rect2(42.0, 157.0, 108.0, 108.0), HERO_BADGE_RING_TEXTURE)
	if _selected_character_id() == 2:
		_stage_texture(Rect2(59.0, 185.0, 74.0, 65.0), HERO_AVATAR_TIGRE_TEXTURE)
	else:
		_stage_texture(Rect2(69.0, 181.0, 54.0, 58.0), HERO_AVATAR_LAKI_TEXTURE)
	var name_label := _stage_label(Rect2(170.0, 166.0, 250.0, 48.0), _profile_display_name(), 31, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	name_label.clip_text = true
	var edit_label := _stage_label(Rect2(170.0, 214.0, 250.0, 36.0), _profile_text("Нажмите, чтобы изменить", "Tap to edit"), 18, Color(0.76, 0.80, 1.0, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	edit_label.clip_text = false
	_stage_label(Rect2(414.0, 188.0, 26.0, 42.0), "›", 30, Color.WHITE)
	_stage_button(card_rect, Callable(self, "_show_profile_edit_popup"), "")

func _portrait_profile_stat_row(y: float, mode_text: String, left_text: String, left_value: int, right_text: String, right_value: int, score_has_star: bool) -> void:
	_stage_panel(Rect2(24.0, y, 432.0, 102.0), PORTRAIT_DARK_BLUE, 18.0, PORTRAIT_RULE, 1.5)
	_stage_label(Rect2(42.0, y + 8.0, 396.0, 30.0), mode_text.to_upper(), 21, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_panel(Rect2(42.0, y + 41.0, 396.0, 1.5), PORTRAIT_RULE)
	_stage_label(Rect2(42.0, y + 48.0, 180.0, 24.0), left_text, 16, Color(0.80, 0.83, 1.0, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	if score_has_star:
		_stage_score_with_star(Rect2(42.0, y + 70.0, 180.0, 26.0), str(left_value), 22, PORTRAIT_ORANGE, HORIZONTAL_ALIGNMENT_LEFT, Color.TRANSPARENT, 0)
	else:
		_stage_label(Rect2(42.0, y + 70.0, 180.0, 26.0), str(left_value), 22, PORTRAIT_ORANGE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_label(Rect2(244.0, y + 48.0, 194.0, 24.0), right_text, 16, Color(0.80, 0.83, 1.0, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	_stage_label(Rect2(244.0, y + 70.0, 194.0, 26.0), str(right_value), 22, PORTRAIT_ORANGE, HORIZONTAL_ALIGNMENT_LEFT)

func _show_profile_edit_popup() -> void:
	_remove_profile_edit_popup()
	_profile_edit_character_id = _selected_character_id()
	_profile_avatar_checks.clear()
	_profile_avatar_halos.clear()
	var previous_content := _portrait_popup_begin("ProfileEditPopup", "profile_edit_popup", 130, Callable(self, "_remove_profile_edit_popup"), 120.0, 680.0)
	var rect := Rect2(28.0, 120.0, 424.0, 560.0)
	_portrait_popup_shell(rect, _profile_text("Редактировать профиль", "Edit profile"), Callable(self, "_remove_profile_edit_popup"), 25)

	_stage_label(Rect2(56.0, 226.0, 368.0, 34.0), _profile_text("Имя игрока", "Player name"), 19, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_panel(Rect2(56.0, 266.0, 368.0, 58.0), Color.WHITE, 22.0, Color(0.78, 0.80, 0.86, 1.0), 2.0)
	_profile_name_edit = _stage_line_edit(Rect2(72.0, 270.0, 336.0, 50.0), _profile_default_name())
	_profile_name_edit.text = _profile_display_name()
	_profile_name_edit.max_length = 18
	_profile_name_edit.add_theme_font_size_override("font_size", 23)

	_stage_label(Rect2(56.0, 346.0, 368.0, 34.0), _profile_text("Аватар", "Avatar"), 19, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_profile_avatar_choice(1, Rect2(78.0, 404.0, 112.0, 112.0), Rect2(108.0, 431.0, 54.0, 58.0))
	_stage_profile_avatar_choice(2, Rect2(290.0, 404.0, 112.0, 112.0), Rect2(306.0, 437.0, 80.0, 70.0))

	_stage_main_button(Rect2(90.0, 592.0, PORTRAIT_LONG_BUTTON_SIZE.x, PORTRAIT_LONG_BUTTON_SIZE.y), Callable(self, "_save_profile_edits"), _profile_text("Сохранить", "Save"), 20)
	content = previous_content

func _stage_profile_avatar_choice(character_id: int, circle_rect: Rect2, avatar_rect: Rect2) -> void:
	var selected: bool = _profile_edit_character_id == character_id
	var halo_color := Color(0.42, 0.48, 0.82, 0.95) if selected else Color(0.32, 0.37, 0.67, 0.50)
	var halo := _stage_panel(Rect2(circle_rect.position - Vector2(10.0, 10.0), circle_rect.size + Vector2(20.0, 20.0)), halo_color, 66.0)
	_profile_avatar_halos[character_id] = halo
	_stage_panel(circle_rect, Color.WHITE, 56.0, PORTRAIT_ORANGE, 3.0)
	_stage_texture(avatar_rect, HERO_AVATAR_LAKI_TEXTURE if character_id == 1 else HERO_AVATAR_TIGRE_TEXTURE)
	var check := _stage_label(Rect2(circle_rect.position.x + 72.0, circle_rect.position.y + 70.0, 38.0, 38.0), "✓", 25, Color(0.30, 0.68, 0.48, 1.0))
	check.visible = selected
	_profile_avatar_checks[character_id] = check
	_stage_button(Rect2(circle_rect.position - Vector2(12.0, 12.0), circle_rect.size + Vector2(24.0, 24.0)), Callable(self, "_select_profile_avatar").bind(character_id), "")

func _select_profile_avatar(character_id: int) -> void:
	_profile_edit_character_id = clampi(character_id, 1, 2)
	for key in _profile_avatar_checks.keys():
		var check := _profile_avatar_checks[key] as Label
		if check != null:
			check.visible = int(key) == _profile_edit_character_id
	for key in _profile_avatar_halos.keys():
		var halo: Control = _profile_avatar_halos[key] as Control
		if halo != null:
			halo.set("fill_color", Color(0.42, 0.48, 0.82, 0.95) if int(key) == _profile_edit_character_id else Color(0.32, 0.37, 0.67, 0.50))

func _save_profile_edits() -> void:
	var entered_name: String = _profile_name_edit.text.strip_edges() if _profile_name_edit != null else ""
	GameState.player_name = entered_name if entered_name != "" else _profile_default_name()
	while GameState.settings.size() <= 5:
		GameState.settings.append(1)
	GameState.settings[5] = _profile_edit_character_id
	GameState.save_game()
	_remove_profile_edit_popup()
	show_profile()

func _remove_profile_edit_popup() -> void:
	var popup_nodes: Array = get_tree().get_nodes_in_group("profile_edit_popup")
	for node: Node in popup_nodes:
		if is_instance_valid(node) and node.get_parent() != null:
			node.get_parent().remove_child(node)
			node.queue_free()
	_profile_name_edit = null
	_profile_avatar_checks.clear()
	_profile_avatar_halos.clear()

func _profile_display_name() -> String:
	var saved_name: String = GameState.player_name.strip_edges()
	return saved_name if saved_name != "" else _profile_default_name()

func _profile_default_name() -> String:
	return _profile_text("Игрок", "Player")

func _profile_text(russian_text: String, english_text: String) -> String:
	return russian_text if GameState.language == "ru" else english_text

func _show_word_comment_popup() -> void:
	var hint: String = GameSession.get_word_hint().strip_edges()
	if hint == "":
		return
	_remove_word_comment_popup()
	var previous_content := _portrait_popup_begin("WordCommentPopup", "word_comment_popup", 100, Callable(self, "_remove_word_comment_popup"), 160.0, 612.0)
	var rect := Rect2(28.0, 160.0, 424.0, 452.0)
	_portrait_popup_shell(rect, Database.tr_text(47, "Comment"), Callable(self, "_remove_word_comment_popup"), 30)
	var hint_label := _stage_label(Rect2(56.0, 282.0, 368.0, 190.0), hint, 22, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	hint_label.clip_text = false
	_stage_panel(Rect2(56.0, 512.0, 368.0, 2.0), Color(0.4509, 0.4862, 0.7607, 0.75))
	var theme_label := _stage_label(Rect2(56.0, 538.0, 368.0, 48.0), _current_word_source_label(), 19, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
	theme_label.clip_text = false
	content = previous_content
