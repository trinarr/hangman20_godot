extends "res://scripts/main.gd"

const PORTRAIT_STAGE_SIZE := Vector2(480.0, 800.0)
const PORTRAIT_HEADER_HEIGHT: float = 102.0
const PORTRAIT_FOOTER_Y: float = 688.0
const PORTRAIT_FOOTER_HEIGHT: float = 112.0
const PORTRAIT_ACTION_BUTTON_RECT := Rect2(338.0, 17.0, 62.0, 62.0)
const PORTRAIT_CLOSE_BUTTON_RECT := Rect2(406.0, 17.0, 62.0, 62.0)
const PORTRAIT_LONG_BUTTON_SIZE := Vector2(270.0, 58.0)
const PORTRAIT_SMALL_BUTTON_SIZE := Vector2(190.0, 52.0)
const PORTRAIT_HERO_POSITION := Vector2(138.0, 282.0)

const PORTRAIT_BLUE := Color(0.2706, 0.3098, 0.6078, 1.0)
const PORTRAIT_DARK_BLUE := Color(0.2314, 0.2627, 0.5176, 1.0)
const PORTRAIT_ORANGE := Color(0.8157, 0.5647, 0.3412, 1.0)
const PORTRAIT_RULE := Color(0.3157, 0.3765, 0.6902, 0.95)

var _portrait_time_attack_difficulty_button: Control = null
var _portrait_custom_word_label: Label = null

func _portrait_screen(header_height: float = PORTRAIT_HEADER_HEIGHT, footer_y: float = -1.0) -> void:
	_stage_texture_fill(0.0, PORTRAIT_STAGE_SIZE.y, MENU_PAPER_COVER)
	_stage_horizontal_fill(0.0, header_height, PORTRAIT_BLUE)
	if footer_y >= 0.0:
		_stage_horizontal_fill(footer_y, PORTRAIT_STAGE_SIZE.y - footer_y, PORTRAIT_BLUE)

func _portrait_popup_begin(name: String, group_name: String, layer_index: int, close_callable: Callable, popup_top: float, popup_bottom: float, alpha: float = 0.58) -> Control:
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
	var header_rect := Rect2(rect.position, Vector2(rect.size.x, 80.0))
	var body_rect := Rect2(rect.position + Vector2(0.0, 80.0), Vector2(rect.size.x, rect.size.y - 80.0))
	var header := _stage_panel(header_rect, PORTRAIT_BLUE)
	header.mouse_filter = Control.MOUSE_FILTER_STOP
	var body := _stage_panel(body_rect, PORTRAIT_DARK_BLUE)
	body.mouse_filter = Control.MOUSE_FILTER_STOP
	var separator := _stage_panel(Rect2(rect.position.x, rect.position.y + 79.0, rect.size.x, 2.0), PORTRAIT_ORANGE)
	separator.mouse_filter = Control.MOUSE_FILTER_STOP
	var title_label := _stage_label(Rect2(rect.position.x + 20.0, rect.position.y + 10.0, rect.size.x - 100.0, 56.0), title, title_font_size, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	title_label.clip_text = false
	_stage_round_button(Rect2(rect.position.x + rect.size.x - 68.0, rect.position.y + 9.0, 62.0, 62.0), close_callable, "×")

func show_menu() -> void:
	game_timer.stop()
	GameSession.discard_current_round()
	_clear("")
	_portrait_screen(112.0)

	_stage_label(Rect2(22.0, 24.0, 300.0, 62.0), Database.tr_text(0, "HANGMAN"), 34, PORTRAIT_ORANGE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_round_icon_button(PORTRAIT_ACTION_BUTTON_RECT, Callable(self, "show_records"), ROUND_BUTTON_RECORDS_ICON, Vector2(17.0, 18.0))
	var achievements_button := _stage_round_icon_button(PORTRAIT_CLOSE_BUTTON_RECT, Callable(), MAIN_MENU_HOLLOW_STAR_ICON, Vector2(22.0, 21.0), true, false, Vector2.ZERO, 0.0)
	achievements_button.self_modulate = Color(1.0, 1.0, 1.0, 0.55)
	achievements_button.set("icon_modulate", Color(1.0, 1.0, 1.0, 0.72))

	_stage_main_menu_character_button()
	_stage_label(Rect2(70.0, 254.0, 340.0, 42.0), Database.tr_text(77, "Welcome back!"), 25, PORTRAIT_BLUE)

	var button_x: float = 105.0
	_stage_main_button(Rect2(button_x, 314.0, PORTRAIT_LONG_BUTTON_SIZE.x, PORTRAIT_LONG_BUTTON_SIZE.y), Callable(self, "show_theme_select"), Database.tr_text(1, "Classic"), 20)
	_stage_main_button(Rect2(button_x, 384.0, PORTRAIT_LONG_BUTTON_SIZE.x, PORTRAIT_LONG_BUTTON_SIZE.y), Callable(self, "_show_time_attack_popup"), Database.tr_text(2, "Time Attack"), 20)
	_stage_main_button(Rect2(button_x, 454.0, PORTRAIT_LONG_BUTTON_SIZE.x, PORTRAIT_LONG_BUTTON_SIZE.y), Callable(self, "show_custom_word"), Database.tr_text(3, "Two Player"), 20)

	_stage_main_button(Rect2(button_x, 544.0, PORTRAIT_LONG_BUTTON_SIZE.x, PORTRAIT_LONG_BUTTON_SIZE.y), Callable(self, "show_settings"), Database.tr_text(5, "Settings"), 20)

func _stage_main_menu_character_button() -> void:
	_stage_texture(Rect2(182.0, 204.0, 115.0, 33.0), HERO_BADGE_TAIL_TEXTURE)
	_stage_texture(Rect2(184.0, 115.0, 111.0, 111.0), HERO_BADGE_RING_TEXTURE)
	if _selected_character_id() == 2:
		_stage_texture(Rect2(202.0, 145.0, 76.0, 67.0), HERO_AVATAR_TIGRE_TEXTURE)
	else:
		_stage_texture(Rect2(213.0, 142.0, 54.0, 58.0), HERO_AVATAR_LAKI_TEXTURE)
	_stage_button(Rect2(170.0, 104.0, 140.0, 145.0), Callable(self, "_show_character_select_popup"), "")

func _show_character_select_popup() -> void:
	_remove_character_select_popup()
	var previous_content := _portrait_popup_begin("CharacterSelectPopup", "character_select_popup", 100, Callable(self, "_remove_character_select_popup"), 170.0, 630.0)
	var rect := Rect2(28.0, 170.0, 424.0, 460.0)
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
	var stored_previous := _portrait_popup_begin("SettingsPopup", "settings_popup", 100, Callable(self, "_remove_settings_popup"), 90.0, 710.0)
	var rect := Rect2(28.0, 90.0, 424.0, 620.0)
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
	var previous_content := _portrait_popup_begin("AboutPopup", "about_popup", 110, Callable(self, "_remove_about_popup"), 130.0, 670.0, 0.38)
	var rect := Rect2(28.0, 130.0, 424.0, 540.0)
	_portrait_popup_shell(rect, _about_title_label(), Callable(self, "_close_about_and_settings"), 30)
	_stage_round_button(Rect2(316.0, 139.0, 62.0, 62.0), Callable(self, "_remove_about_popup"), "←")
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
	_portrait_screen(96.0)
	_stage_label(Rect2(20.0, 18.0, 300.0, 58.0), Database.tr_text(32, "Choose the category:"), 26, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	var difficulty_texture: Texture2D = _difficulty_star_texture()
	_stage_round_icon_button(PORTRAIT_ACTION_BUTTON_RECT, Callable(self, "_show_difficulty_popup"), difficulty_texture, difficulty_texture.get_size())
	_stage_round_button(PORTRAIT_CLOSE_BUTTON_RECT, Callable(self, "show_menu"), "×")

	for i in range(Database.get_theme_count()):
		if i >= 9:
			break
		var col: int = i % 2
		var row: int = int(i / 2)
		var x: float = 18.0 + float(col) * 230.0
		var y: float = 118.0 + float(row) * 104.0
		var words_count: int = Database.get_words_by_index(i, GameState.settings[2]).size()
		var guessed: int = Database.get_number_of_guessed_words(i, true)
		var disabled: bool = words_count == 0
		var completed: bool = words_count > 0 and guessed >= words_count
		var card := _stage_texture(Rect2(x, y, 214.0, 88.0), THEME_CARD_TEXTURE)
		var progress_back := _stage_texture(Rect2(x, y, 214.0, 63.0), THEME_CARD_PROGRESS_TEXTURE)
		var progress_text: String = Database.tr_text(33, "All words are guessed") if completed else Database.tr_text(34, "Guessed") + ": " + str(guessed) + " " + Database.tr_text(35, "of") + " " + str(words_count)
		var progress_label := _stage_label(Rect2(x + 8.0, y + 7.0, 198.0, 28.0), progress_text, 13, Color(0.43, 0.49, 0.83, 1.0))
		progress_label.clip_text = false
		var title_label := _stage_label(Rect2(x + 6.0, y + 44.0, 202.0, 36.0), Database.get_theme_name(i).to_upper(), 19, Color.WHITE)
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

func _show_clear_theme_popup(theme_index: int) -> void:
	_remove_clear_theme_popup()
	var previous_content := _portrait_popup_begin("ClearThemePopup", "clear_theme_popup", 125, Callable(self, "_remove_clear_theme_popup"), 250.0, 550.0)
	var rect := Rect2(35.0, 250.0, 410.0, 300.0)
	_portrait_popup_shell(rect, Database.tr_text(29, "Clear the category?"), Callable(self, "_remove_clear_theme_popup"), 25)
	var theme_name := Database.get_theme_name(theme_index).to_upper()
	var question_label := _stage_label(Rect2(65.0, 350.0, 350.0, 58.0), theme_name, 24, Color.WHITE)
	question_label.clip_text = false
	_stage_main_button(Rect2(44.0, 454.0, PORTRAIT_SMALL_BUTTON_SIZE.x, PORTRAIT_SMALL_BUTTON_SIZE.y), Callable(self, "_confirm_clear_theme").bind(theme_index), Database.tr_text(30, "Yes"), 20)
	_stage_main_button(Rect2(246.0, 454.0, PORTRAIT_SMALL_BUTTON_SIZE.x, PORTRAIT_SMALL_BUTTON_SIZE.y), Callable(self, "_remove_clear_theme_popup"), Database.tr_text(31, "No"), 20)
	content = previous_content

func _show_difficulty_popup() -> void:
	_remove_difficulty_popup()
	var previous_content := _portrait_popup_begin("ThemeDifficultyPopup", "difficulty_popup", 120, Callable(self, "_remove_difficulty_popup"), 100.0, 700.0)
	var rect := Rect2(28.0, 100.0, 424.0, 600.0)
	_portrait_popup_shell(rect, Database.tr_text(63, "Choose the difficulty level:"), Callable(self, "_remove_difficulty_popup"), 24)
	var options := [
		{"value": 2, "title": Database.tr_key(&"DIFFICULTY_EASY", "ПРОСТОЙ"), "desc": Database.tr_text(36, "Hints:") + " 2 · " + Database.tr_text(55, "Easy words")},
		{"value": 1, "title": Database.tr_key(&"DIFFICULTY_HARD", "СЛОЖНЫЙ"), "desc": Database.tr_text(36, "Hints:") + " 1 · " + Database.tr_text(56, "Hard words")},
		{"value": 0, "title": Database.tr_key(&"DIFFICULTY_GENERAL", "ОБЩИЙ"), "desc": Database.tr_text(36, "Hints:") + " 2 · " + Database.tr_text(57, "All words")},
	]
	for index in range(options.size()):
		var option: Dictionary = options[index]
		var value: int = int(option["value"])
		var y: float = 215.0 + float(index) * 145.0
		if index > 0:
			_stage_panel(Rect2(54.0, y - 20.0, 372.0, 2.0), PORTRAIT_RULE)
		var selected: bool = value == int(GameState.settings[2])
		var option_texture: Texture2D = _difficulty_star_texture(value)
		_stage_round_icon_button(Rect2(56.0, y, 68.0, 68.0), Callable(self, "_set_difficulty_from_popup").bind(value), option_texture, option_texture.get_size(), false, selected)
		var title_label := _stage_label(Rect2(146.0, y - 2.0, 250.0, 34.0), str(option["title"]), 22, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
		title_label.clip_text = false
		var desc_label := _stage_label(Rect2(146.0, y + 36.0, 260.0, 38.0), str(option["desc"]), 16, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
		desc_label.clip_text = false
		_stage_button(Rect2(44.0, y - 8.0, 382.0, 90.0), Callable(self, "_set_difficulty_from_popup").bind(value), "")
	content = previous_content

func _show_time_attack_popup() -> void:
	_remove_time_attack_popup()
	var previous_content := _portrait_popup_begin("TimeAttackPopup", "time_attack_popup", 115, Callable(self, "_remove_time_attack_popup"), 120.0, 680.0)
	var rect := Rect2(28.0, 120.0, 424.0, 560.0)
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
	_stage_main_button(Rect2(105.0, 590.0, PORTRAIT_LONG_BUTTON_SIZE.x, PORTRAIT_LONG_BUTTON_SIZE.y), Callable(self, "_start_time_attack_from_popup"), tr("START"), 20)
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
	_portrait_custom_word_label = _stage_label(Rect2(20.0, 20.0, 300.0, 62.0), _custom_word_display_text(), 29, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_portrait_custom_word_label.clip_text = true

	# Keep an invisible LineEdit only as the existing validation/checking state
	# holder. All visible input is performed through the on-screen letter keys.
	custom_word_edit = LineEdit.new()
	custom_word_edit.visible = false
	custom_word_edit.max_length = 35
	custom_word_edit.text = custom_word_text
	custom_word_edit.text_changed.connect(_on_custom_word_text_changed)
	content.add_child(custom_word_edit)

	_stage_label(Rect2(20.0, 78.0, 205.0, 30.0), _custom_word_max_length_label(), 17, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_label(Rect2(205.0, 78.0, 119.0, 30.0), _custom_word_random_label(), 17, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
	_stage_round_icon_button(PORTRAIT_ACTION_BUTTON_RECT, Callable(self, "_set_random_custom_word"), CUSTOM_WORD_RANDOM_ICON, Vector2(32.0, 27.0))
	_stage_round_button(PORTRAIT_CLOSE_BUTTON_RECT, Callable(self, "show_menu"), "×")

	_stage_custom_word_keyboard()

	_stage_main_button(Rect2(134.0, 570.0, 212.0, 49.0), Callable(self, "_check_custom_word_now"), Database.tr_text(68, "Check the word"), 19)
	var check_color := Color.WHITE
	if custom_word_check_state == 2:
		check_color = Color(0.58, 0.88, 0.72)
	elif custom_word_check_state == 3:
		check_color = Color(0.96, 0.67, 0.77)
	custom_word_check_label = _stage_label(Rect2(70.0, 622.0, 340.0, 24.0), custom_word_check_text, 15, check_color)
	_stage_main_button(Rect2(250.0, 715.0, 212.0, 49.0), Callable(self, "start_custom_game"), _custom_word_start_label(), 20)

func _stage_custom_word_keyboard() -> void:
	var alphabet: PackedStringArray = Database.get_alphabet()
	var columns: int = 6
	var keyboard_start_x: float = 34.0
	var keyboard_start_y: float = 142.0
	var keyboard_step_x: float = 69.0
	var keyboard_step_y: float = 54.0
	var key_size := Vector2(50.0, 46.0)
	for i in range(alphabet.size()):
		var letter: String = alphabet[i]
		var row: int = int(i / columns)
		var col: int = i % columns
		var x: float = keyboard_start_x + float(col) * keyboard_step_x
		var y: float = keyboard_start_y + float(row) * keyboard_step_y
		var key_rect := Rect2(x, y, key_size.x, key_size.y)
		_stage_label(Rect2(x - 5.0, y - 7.0, key_size.x + 10.0, key_size.y + 12.0), letter, 29, PORTRAIT_BLUE)
		_stage_button(key_rect, Callable(self, "_append_custom_word_character").bind(letter), "")

	_stage_main_button(Rect2(28.0, 476.0, 170.0, 48.0), Callable(self, "_append_custom_word_character").bind(" "), _custom_word_space_label(), 17)
	_stage_main_button(Rect2(205.0, 476.0, 78.0, 48.0), Callable(self, "_append_custom_word_character").bind("—"), "—", 20)
	_stage_main_button(Rect2(290.0, 476.0, 162.0, 48.0), Callable(self, "_remove_custom_word_character"), "⌫", 22)

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
	_portrait_screen(PORTRAIT_HEADER_HEIGHT, PORTRAIT_FOOTER_Y)
	_stage_label(Rect2(20.0, 20.0, 300.0, 62.0), GameSession.get_masked_word(), 29, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	if GameState.current_mode == 2:
		_stage_round_icon_button(PORTRAIT_ACTION_BUTTON_RECT, Callable(self, "_game_header_action"), CUSTOM_WORD_REFRESH_ICON, Vector2(27.0, 27.0))
	else:
		_stage_round_button(PORTRAIT_ACTION_BUTTON_RECT, Callable(self, "_game_header_action"), _game_header_icon())
	_stage_round_button(PORTRAIT_CLOSE_BUTTON_RECT, Callable(self, "show_menu"), "×")

	hero_static_symbol = _stage_symbol(_hero_symbol_path(), PORTRAIT_HERO_POSITION, _hero_animation_time(), 4.0 / 24.0) as FlashStageSymbol
	if GameState.current_mode == 1:
		_stage_time_attack_hud()

	var alphabet := Database.get_alphabet()
	var columns: int = 6
	var keyboard_start_x: float = 36.0
	var keyboard_start_y: float = 346.0
	var keyboard_step_x: float = 69.0
	var keyboard_step_y: float = 54.0
	var key_size := Vector2(50.0, 46.0)
	var marker_size := Vector2(54.0, 54.0)
	for i in range(alphabet.size()):
		var letter: String = alphabet[i]
		var row: int = int(i / columns)
		var col: int = i % columns
		var x: float = keyboard_start_x + float(col) * keyboard_step_x
		var y: float = keyboard_start_y + float(row) * keyboard_step_y
		var was_correct: bool = GameSession.correct_letters.has(letter)
		var was_wrong: bool = GameSession.wrong_letters.has(letter)
		var was_removed: bool = GameSession.removed_wrong_letters.has(letter)
		var letter_color: Color = PORTRAIT_BLUE
		if was_correct:
			letter_color = Color(0.42, 0.69, 0.58, 1.0)
		elif was_wrong or was_removed:
			letter_color = Color(0.84, 0.59, 0.64, 1.0)
		var key_rect := Rect2(x, y, key_size.x, key_size.y)
		var marker_rect := Rect2(key_rect.position + (key_rect.size - marker_size) * 0.5 + Vector2(0.0, -1.0), marker_size)
		var label_rect := Rect2(key_rect.position + Vector2(-5.0, -7.0), key_rect.size + Vector2(10.0, 12.0))
		if was_correct:
			if letter == pending_letter_marker and pending_letter_marker_is_correct:
				_stage_animated_letter_marker(marker_rect, LETTER_CORRECT_TEXTURE, true)
			else:
				_stage_texture(marker_rect, LETTER_CORRECT_TEXTURE)
		elif was_wrong or was_removed:
			if letter == pending_letter_marker and !pending_letter_marker_is_correct:
				_stage_animated_letter_marker(marker_rect, LETTER_WRONG_TEXTURE, false)
			else:
				_stage_texture(marker_rect, LETTER_WRONG_TEXTURE)
		_stage_label(label_rect, letter, 29, letter_color)
		var button := _stage_button(key_rect, Callable(self, "_press_letter").bind(letter), "", 20)
		button.disabled = !GameSession.is_active or was_correct or was_wrong or was_removed

	if GameState.current_mode != 2:
		var open_hint_disabled: bool = !GameSession.can_use_open_letter_hint()
		var remove_hint_disabled: bool = !GameSession.can_use_remove_wrong_hint()
		var comment_disabled: bool = GameSession.get_word_hint().strip_edges() == ""
		_stage_texture_button(Rect2(18.0, 716.0, 102.0, 49.0), Callable(self, "_use_open_hint"), HINT_REMOVE_BUTTON_TEXTURE, HINT_OPEN_BUTTON_TEXTURE, "", 26, open_hint_disabled, HINT_OPEN_BUTTON_TEXTURE, 0.0)
		_stage_texture(Rect2(57.0, 728.0, 25.0, 25.0), HINT_ICON_CHECK_TEXTURE)
		_stage_texture_button(Rect2(126.0, 716.0, 102.0, 49.0), Callable(self, "_use_remove_hint"), HINT_REMOVE_BUTTON_TEXTURE, HINT_OPEN_BUTTON_TEXTURE, "", 26, remove_hint_disabled, HINT_OPEN_BUTTON_TEXTURE, 0.0)
		_stage_texture(Rect2(165.0, 728.0, 25.0, 25.0), HINT_ICON_CROSS_TEXTURE)
		var comment_button := _stage_main_button(Rect2(250.0, 716.0, 212.0, 49.0), Callable(self, "_show_word_comment_popup"), Database.tr_text(47, "Comment"), 18, comment_disabled, 0.0)
		if comment_disabled:
			comment_button.modulate = Color(1.0, 1.0, 1.0, 0.56)
	pending_letter_marker = ""
	pending_letter_marker_is_correct = false

func _stage_time_attack_hud() -> void:
	_stage_score_with_star(Rect2(20.0, 286.0, 180.0, 32.0), str(GameState.current_score), 19, PORTRAIT_BLUE, HORIZONTAL_ALIGNMENT_LEFT, Color.WHITE, 1)
	_stage_texture(Rect2(346.0, 288.0, 26.0, 26.0), TIME_ATTACK_TIMER_ICON_TEXTURE)
	var time_label := _stage_label(Rect2(378.0, 284.0, 82.0, 34.0), _format_time(GameState.current_time_left), 19, PORTRAIT_BLUE, HORIZONTAL_ALIGNMENT_LEFT)
	time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _play_hero_wrong_guess_animation(previous_mistakes: int, current_mistakes: int) -> void:
	_clear_hero_animation_overlay()
	if hero_static_symbol != null and is_instance_valid(hero_static_symbol):
		hero_static_symbol.visible = false
	var overlay := FlashStageSymbol.new()
	overlay.name = "HeroAnimationOverlay"
	overlay.z_index = 150
	overlay.symbol_path = _hero_symbol_path()
	overlay.stage_position = PORTRAIT_HERO_POSITION
	overlay.animation_time = _hero_animation_time_for_mistakes(current_mistakes)
	overlay.nested_animation_time = HERO_MOV_START_FRAME_TIME
	overlay.playback_finished.connect(_on_hero_wrong_guess_animation_finished)
	add_child(overlay)
	hero_animation_overlay = overlay
	overlay.call_deferred("play_nested_range", _hero_animation_time_for_mistakes(current_mistakes), HERO_MOV_START_FRAME_TIME, HERO_MOV_IDLE_FRAME_TIME, HERO_WRONG_GUESS_ANIMATION_SPEED_SCALE)

func show_result_screen(is_win: bool, data: Dictionary = {}) -> void:
	game_timer.stop()
	_clear("")
	_portrait_screen(PORTRAIT_HEADER_HEIGHT, PORTRAIT_FOOTER_Y)
	var full_word: String = _spaced_result_word(GameSession.get_full_word())
	_stage_label(Rect2(20.0, 20.0, 300.0, 62.0), full_word, 29, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_round_icon_button(PORTRAIT_ACTION_BUTTON_RECT, Callable(self, "_open_word_search"), RESULT_SEARCH_ICON, Vector2(18.0, 23.0))
	_stage_round_icon_button(PORTRAIT_CLOSE_BUTTON_RECT, Callable(self, "show_menu"), RESULT_CLOSE_ICON, Vector2(18.0, 18.0))
	hero_static_symbol = _stage_symbol(_hero_symbol_path(), Vector2(138.0, 300.0), _hero_animation_time(), HERO_MOV_IDLE_FRAME_TIME) as FlashStageSymbol
	var time_attack_finished: bool = GameState.current_mode == 1 and bool(data.get("time_attack_finished", false))
	var title: String
	if time_attack_finished:
		title = str(data.get("title", Database.tr_text(39, "GAME OVER"))).strip_edges()
		if title == "":
			title = Database.tr_text(39, "GAME OVER")
	else:
		title = Database.tr_text(37 if is_win else 38, "VICTORY" if is_win else "DEFEAT").strip_edges()
	var title_label := _stage_label(Rect2(48.0, 330.0, 384.0, 70.0), title, 38, PORTRAIT_ORANGE)
	title_label.clip_text = false
	_apply_result_text_glow(title_label, Color.WHITE, 2)
	if time_attack_finished:
		var final_score: int = int(data.get("final_score", GameState.current_score))
		var final_score_text: String = Database.tr_key(&"FINAL_SCORE", "Final score:") + " " + str(final_score)
		_stage_score_with_star(Rect2(64.0, 410.0, 352.0, 40.0), final_score_text, 23, PORTRAIT_BLUE, HORIZONTAL_ALIGNMENT_CENTER, Color.WHITE, 1)
		var final_details: String = _result_data_lines(data)
		if final_details != "":
			var details_label := _stage_label(Rect2(64.0, 458.0, 352.0, 72.0), final_details, 19, PORTRAIT_BLUE)
			details_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	else:
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
	var show_left_button: bool = GameState.current_mode == 0
	if show_left_button:
		_stage_main_button(Rect2(18.0, 716.0, 212.0, 49.0), Callable(self, "_result_left_action"), _result_left_button_text(), 18)
	_stage_main_button(Rect2(250.0, 716.0, 212.0, 49.0), Callable(self, "_result_right_action"), _result_right_button_text(), 18)

func show_records() -> void:
	_remove_records_popup()
	var previous_content := _portrait_popup_begin("RecordsPopup", "records_popup", 100, Callable(self, "_remove_records_popup"), 80.0, 720.0)
	var rect := Rect2(28.0, 80.0, 424.0, 640.0)
	_portrait_popup_shell(rect, tr("RECORDS_TITLE"), Callable(self, "_remove_records_popup"), 27)
	var crown_button := _stage_round_icon_button(Rect2(316.0, 89.0, 62.0, 62.0), Callable(), ROUND_BUTTON_CROWN_ICON, Vector2(24.0, 20.0), true, false, Vector2.ZERO, 0.0)
	crown_button.self_modulate = Color(1.0, 1.0, 1.0, 0.55)
	_portrait_record_row(190.0, tr("MENU_CLASSIC"), tr("RECORD_EASY_STREAK"), GameState.records[0][2], tr("RECORD_HARD_STREAK"), GameState.records[0][3], false)
	_portrait_record_row(345.0, tr("MENU_TIME_ATTACK"), tr("SCORE"), GameState.records[2][2], tr("VICTORIES_PER_GAME"), GameState.records[2][1], true)
	_portrait_record_row(500.0, tr("MENU_TWO_PLAYER"), tr("VICTORIES"), GameState.records[1][0], tr("DEFEATS"), GameState.records[1][1], false)
	content = previous_content

func _portrait_record_row(y: float, mode_text: String, left_text: String, left_value: int, right_text: String, right_value: int, score_has_star: bool) -> void:
	_stage_label(Rect2(54.0, y, 372.0, 34.0), mode_text.to_upper(), 19, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_label(Rect2(54.0, y + 42.0, 180.0, 30.0), left_text, 16, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	if score_has_star:
		_stage_score_with_star(Rect2(54.0, y + 72.0, 180.0, 30.0), str(left_value), 19, PORTRAIT_ORANGE, HORIZONTAL_ALIGNMENT_LEFT, Color.TRANSPARENT, 0)
	else:
		_stage_label(Rect2(54.0, y + 72.0, 180.0, 30.0), str(left_value), 19, PORTRAIT_ORANGE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_label(Rect2(252.0, y + 42.0, 174.0, 30.0), right_text, 16, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_label(Rect2(252.0, y + 72.0, 174.0, 30.0), str(right_value), 19, PORTRAIT_ORANGE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_panel(Rect2(54.0, y + 126.0, 372.0, 2.0), PORTRAIT_RULE)

func _show_word_comment_popup() -> void:
	var hint: String = GameSession.get_word_hint().strip_edges()
	if hint == "":
		return
	_remove_word_comment_popup()
	var previous_content := _portrait_popup_begin("WordCommentPopup", "word_comment_popup", 100, Callable(self, "_remove_word_comment_popup"), 160.0, 640.0)
	var rect := Rect2(28.0, 160.0, 424.0, 480.0)
	_portrait_popup_shell(rect, Database.tr_text(47, "Comment"), Callable(self, "_remove_word_comment_popup"), 30)
	var hint_label := _stage_label(Rect2(56.0, 282.0, 368.0, 190.0), hint, 22, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	hint_label.clip_text = false
	_stage_panel(Rect2(56.0, 512.0, 368.0, 2.0), Color(0.4509, 0.4862, 0.7607, 0.75))
	var theme_label := _stage_label(Rect2(56.0, 538.0, 368.0, 48.0), _current_word_source_label(), 19, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
	theme_label.clip_text = false
	content = previous_content
