extends Node2D

const ART_SOURCE_SCALE: float = 2.0
const HERO_ANIMATION_SPEED_SCALE: float = 1.0
const HERO_OUTER_FRAME_SAMPLE_OFFSET: float = 0.5 / 24.0
const HERO_NESTED_FRAME_SAMPLE_OFFSET: float = 0.5 / 24.0
const HERO_MOV_START_FRAME_TIME: float = 0.0
const HERO_MOV_IDLE_FRAME_TIME: float = 4.0 / 24.0 + HERO_NESTED_FRAME_SAMPLE_OFFSET
const HERO_MOV_RECOVERY_START_FRAME_TIME: float = 5.0 / 24.0 + HERO_NESTED_FRAME_SAMPLE_OFFSET
const HERO_MOV_RECOVERY_END_FRAME_TIME: float = 9.0 / 24.0 + HERO_NESTED_FRAME_SAMPLE_OFFSET
const HERO_TYPE_1_TERMINAL_END_FRAME_TIME: float = 40.0 / 24.0
const HERO_TYPE_2_TERMINAL_END_FRAME_TIME: float = 12.0 / 24.0
const LETTER_FEEDBACK_ANIMATION_DURATION: float = 0.42
const RANDOM_CUSTOM_WORD_MAX_LENGTH: int = 7
const RANDOM_CUSTOM_WORD_DIFFICULTY_FILTER: int = 2
const SETTINGS_TOGGLE_ON_VIBRATION_MS: int = 35
const CUSTOM_WORD_NOT_FOUND_VIBRATION_MS: int = 35
const CUSTOM_WORD_RESULT_COLOR_DURATION: float = 1.81
const CUSTOM_WORD_CHECK_DOTS_INTERVAL: float = 0.4
const CUSTOM_WORD_INPUT_DEFAULT_COLOR := Color(0.23, 0.26, 0.52, 1.0)
const SOUND_SETTING_INDEX: int = 3
const THEME_CARD_PRESSED_MODULATE := Color(0.72, 0.72, 0.72, 1.0)
const THEME_PROGRESS_TEXT_OPTICAL_OFFSET_Y: float = -3.0
const APP_VERSION_FALLBACK: String = "3.0.0"
const SINGLE_PLAYER_LEVEL_COUNT: int = 10
const SINGLE_PLAYER_THEME_OPTIONS_PER_LEVEL: int = 3
const SINGLE_PLAYER_MIN_WORDS_PER_LEVEL: int = 3
const SINGLE_PLAYER_MAX_WORDS_PER_LEVEL: int = 8
const MODE_CLASSIC: int = 0
const MODE_TWO_PLAYER: int = 1
const MODE_SINGLE_PLAYER: int = 2
const DIFFICULTY_MODE_HARD: int = 1
const DIFFICULTY_MODE_NORMAL: int = 2
const DIFFICULTY_HARD_NORMAL_TINT := Color("#D866FE")
const DIFFICULTY_HARD_PRESSED_TINT := Color("#B44AD9")
const DIFFICULTY_HARD_SELECTED_TINT := Color("#9638B9")
const DIFFICULTY_HARD_OUTLINE_COLOR := Color("#68267A")
const AUTHOR_VK_URL: String = "https://vk.ru/trinarr_tavern"
const AUTHOR_EMAIL_URL: String = "mailto:trinarr@mail.ru"
const FLASH_STAGE_CONTROL_SCRIPT: GDScript = preload("res://scripts/ui/flash_stage_control.gd")
const FLASH_STAGE_BUTTON_SCRIPT: GDScript = preload("res://scripts/ui/flash_stage_button.gd")
const STAGE_LONG_BUTTON_SCRIPT: GDScript = preload("res://scripts/ui/stage_long_button.gd")
const LONG_BUTTON_COLOR_ORANGE: int = 0
const LONG_BUTTON_COLOR_BLUE: int = 2
const ROUND_BUTTON_COLOR_BLUE: int = 2
const STAGE_ROUND_BUTTON_SCRIPT: GDScript = preload("res://scripts/ui/stage_round_button.gd")
const STAGE_LETTER_BUTTON_SCRIPT: GDScript = preload("res://scripts/ui/stage_letter_button.gd")
const STAGE_TOAST_SCRIPT: GDScript = preload("res://scripts/ui/stage_toast.gd")
const FLASH_STAGE_PANEL_SCRIPT: GDScript = preload("res://scripts/ui/flash_stage_panel.gd")
const FLASH_STAGE_SYMBOL_SCRIPT: GDScript = preload("res://scripts/ui/flash_stage_symbol.gd")
const FLASH_STAGE_TEXTURE_SCRIPT: GDScript = preload("res://scripts/ui/flash_stage_texture.gd")
const FLASH_STAGE_HORIZONTAL_FILL_SCRIPT: GDScript = preload("res://scripts/ui/flash_stage_horizontal_fill.gd")
const FLASH_STAGE_TEXTURE_FILL_SCRIPT: GDScript = preload("res://scripts/ui/flash_stage_texture_fill.gd")
const POPUP_STAGE_CENTER_SCRIPT: GDScript = preload("res://scripts/ui/popup_stage_center.gd")

const RESULT_SEARCH_ICON: Texture2D = preload("res://flash_assets/result_search_icon_343.png")
const RESULT_CLOSE_ICON: Texture2D = preload("res://flash_assets/result_close_icon_43.png")
const CUSTOM_WORD_REFRESH_ICON: Texture2D = preload("res://flash_assets/custom_word_refresh_icon_341.png")
const SINGLE_PLAYER_BACK_ARROW_ICON: Texture2D = preload("res://flash_assets/portrait_back_arrow_icon.png")
const ABOUT_VK_ICON: Texture2D = preload("res://flash_assets/about_vk_icon_87.png")
const ABOUT_MAIL_ICON: Texture2D = preload("res://flash_assets/about_mail_icon_86.png")
const RESULT_SEARCH_COMPACT_ICON_SIZE := Vector2(25.0, 32.0)
const ABOUT_VK_ICON_SIZE := Vector2(34.0, 20.0)
const ABOUT_MAIL_ICON_SIZE := Vector2(33.0, 27.0)
const HERO_BADGE_RING_TEXTURE: Texture2D = preload("res://flash_assets/user_hint_circle_74.png")
const THEME_CARD_TEXTURE: Texture2D = preload("res://flash_assets/theme_card_user_239x90.png")
const THEME_CARD_PROGRESS_TEXTURE: Texture2D = preload("res://flash_assets/theme_card_progress_user_239x65.png")
const THEME_ICON_SPORT_TEXTURE: Texture2D = preload("res://flash_assets/theme_icons/theme_icon_sport.png")
const THEME_ICON_GEOGRAPHY_TEXTURE: Texture2D = preload("res://flash_assets/theme_icons/theme_icon_geography.png")
const THEME_ICON_NATURE_TEXTURE: Texture2D = preload("res://flash_assets/theme_icons/theme_icon_nature.png")
const THEME_ICON_TECHNICS_TEXTURE: Texture2D = preload("res://flash_assets/theme_icons/theme_icon_technics.png")
const THEME_ICON_PEOPLE_TEXTURE: Texture2D = preload("res://flash_assets/theme_icons/theme_icon_people.png")
const THEME_ICON_FOOD_TEXTURE: Texture2D = preload("res://flash_assets/theme_icons/theme_icon_food.png")
const THEME_ICON_SCIENCE_TEXTURE: Texture2D = preload("res://flash_assets/theme_icons/theme_icon_science.png")
const THEME_ICON_HISTORY_TEXTURE: Texture2D = preload("res://flash_assets/theme_icons/theme_icon_history.png")
const THEME_ICON_GENERAL_TEXTURE: Texture2D = preload("res://flash_assets/theme_icons/theme_icon_general.png")
const THEME_ICON_FILM_MUSIC_TEXTURE: Texture2D = preload("res://flash_assets/theme_icons/theme_icon_film_music.png")
const THEME_ICON_TEXTURES: Array[Texture2D] = [
	THEME_ICON_SPORT_TEXTURE,
	THEME_ICON_GEOGRAPHY_TEXTURE,
	THEME_ICON_NATURE_TEXTURE,
	THEME_ICON_TECHNICS_TEXTURE,
	THEME_ICON_PEOPLE_TEXTURE,
	THEME_ICON_FOOD_TEXTURE,
	THEME_ICON_SCIENCE_TEXTURE,
	THEME_ICON_HISTORY_TEXTURE,
	THEME_ICON_GENERAL_TEXTURE,
	THEME_ICON_FILM_MUSIC_TEXTURE,
]
const HINT_ICON_CHECK_TEXTURE: Texture2D = preload("res://flash_assets/user_hint_check_circle_uploaded.png")
const HINT_ICON_CROSS_TEXTURE: Texture2D = preload("res://flash_assets/user_hint_cross_circle_uploaded.png")
const LIFE_HEART_ICON_TEXTURE: Texture2D = preload("res://flash_assets/life_heart_icon.png")
const MENU_PAPER_COVER: Texture2D = preload("res://flash_assets/fon_png.png")
const CORRECT_LETTER_SOUND: AudioStream = preload("res://audio/Yes_New.wav")
const WRONG_LETTER_SOUND: AudioStream = preload("res://audio/No_New.wav")
const LUCKY_DEFEAT_SOUND: AudioStream = preload("res://audio/LuckyDefeat.wav")
const RESULT_WIN_SOUND: AudioStream = preload("res://audio/LuckyWin.wav")
const EL_TIGRE_DEFEAT_SOUND: AudioStream = preload("res://audio/CatDefeat.wav")
const UI_CLICK_SOUND: AudioStream = preload("res://audio/Click.wav")
const POPUP_OPEN_SOUND: AudioStream = preload("res://audio/Popup_Open.wav")
const HERO_TYPE_1_SYMBOL: String = "res://symbols/HeroType1.tscn"
const HERO_TYPE_2_SYMBOL: String = "res://symbols/HeroType2.tscn"
const HERO_AVATAR_LAKI_TEXTURE: Texture2D = preload("res://img/_______3______1_0_SHAPE_0_BOUNDS_154.49_-80.71_SIZE_270_290.png")
const HERO_AVATAR_TIGRE_TEXTURE: Texture2D = preload("res://img/_______405______1_0_SHAPE_0_BOUNDS_-0.96_-0.96_SIZE_366_322.png")

var art_root: FlashBackdrop
var ui: Control
var content: Control
var letter_feedback_audio_player: AudioStreamPlayer
var result_audio_player: AudioStreamPlayer
var ui_audio_player: AudioStreamPlayer
var game_finished: bool = false
var last_result_is_win: bool = false
var last_result_data: Dictionary = {}
var single_player_active_level_index: int = -1
var single_player_active_word_slot: int = -1
var single_player_level_definitions_cache: Dictionary = {}
var single_player_level_cache_language: String = ""
var single_player_level_cache_theme_count: int = -1
var custom_word_edit: LineEdit
var custom_word_input_visual: Control = null
var custom_word_text: String = ""
var custom_comment_text: String = ""
var custom_word_check_request: HTTPRequest = null
var custom_word_check_urls: Array[String] = []
var custom_word_check_button: Control = null
var custom_word_check_animation_timer: Timer = null
var custom_word_check_dot_count: int = 0
var custom_word_check_label_base: String = ""
var custom_word_start_button: Control = null
var custom_word_color_generation: int = 0
var hero_animation_overlay: FlashStageSymbol = null
var hero_static_symbol: FlashStageSymbol = null
var hero_pose_round_token: int = 0
var hero_pose_frame_index: int = -1
var hero_nested_pose_time: float = HERO_MOV_IDLE_FRAME_TIME
var hero_terminal_loop_time: float = HERO_MOV_START_FRAME_TIME
var settings_popup_return_content: Control = null
var settings_toggle_buttons: Dictionary = {}
var settings_word_language_buttons: Dictionary = {}
var pending_letter_markers := PackedStringArray()
var pending_letter_marker_is_correct: bool = false
var round_result_delay_requested: bool = false
var result_transition_generation: int = 0
var last_result_sound_key: String = ""

func _ready() -> void:
	randomize()
	Database.load_languages(GameState.interface_language, GameState.word_language)
	_build_root()
	GameSession.hint_letters_selected.connect(_on_hint_letters_selected)
	GameSession.changed.connect(_refresh_game_screen)
	GameSession.round_won.connect(_on_round_won)
	GameSession.round_lost.connect(_on_round_lost)
	show_menu()

# Main.tscn always uses main_portrait.gd. Keep only the small virtual surface
# that shared game logic calls; all screen construction lives in the portrait
# subclass instead of being duplicated here.
func show_menu() -> void:
	pass

func show_theme_select() -> void:
	pass

func show_custom_word() -> void:
	pass

func show_result_screen(_is_win: bool, _data: Dictionary = {}) -> void:
	pass

func _refresh_game_screen() -> void:
	pass

func _create_hero_animation_overlay() -> FlashStageSymbol:
	return null

func _show_about_popup() -> void:
	pass

func _show_single_player_theme_popup(_level_index: int, _theme_index: int) -> void:
	pass

func _show_word_comment_popup() -> void:
	pass

func _build_root() -> void:
	art_root = FlashBackdrop.new()
	art_root.name = "OriginalFlashArt"
	art_root.z_index = 0
	add_child(art_root)

	ui = Control.new()
	ui.name = "RuntimeUI"
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_PASS
	ui.z_index = 100
	add_child(ui)

	letter_feedback_audio_player = AudioStreamPlayer.new()
	letter_feedback_audio_player.name = "LetterFeedbackAudio"
	add_child(letter_feedback_audio_player)

	result_audio_player = AudioStreamPlayer.new()
	result_audio_player.name = "ResultAudio"
	add_child(result_audio_player)

	ui_audio_player = AudioStreamPlayer.new()
	ui_audio_player.name = "UIAudio"
	add_child(ui_audio_player)

func _clear(symbol_path: String = "") -> void:
	_capture_hero_animation_phase()
	result_transition_generation += 1
	custom_word_color_generation += 1
	pending_letter_markers.clear()
	pending_letter_marker_is_correct = false
	round_result_delay_requested = false
	_clear_hero_animation_overlay()
	_cancel_custom_word_check()
	custom_word_check_button = null
	custom_word_start_button = null
	hero_static_symbol = null
	_remove_settings_popup()
	_remove_exit_game_popup()
	_remove_single_player_theme_popup()
	_remove_clear_theme_popup()
	settings_popup_return_content = null
	custom_word_edit = null
	custom_word_input_visual = null
	if art_root != null:
		art_root.show_screen(symbol_path)
	for child: Node in ui.get_children():
		ui.remove_child(child)
		child.queue_free()
	content = Control.new()
	content.name = "FlashStageControls"
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.mouse_filter = Control.MOUSE_FILTER_PASS
	ui.add_child(content)

func _stage_holder(rect: Rect2, mouse_filter: int = Control.MOUSE_FILTER_PASS) -> Control:
	var holder: Control = FLASH_STAGE_CONTROL_SCRIPT.new() as Control
	holder.mouse_filter = mouse_filter
	content.add_child(holder)
	holder.set("stage_rect", rect)
	return holder

func _stage_label(rect: Rect2, text: String, font_size: int = 20, color: Color = Color.WHITE, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var holder: Control = _stage_holder(rect, Control.MOUSE_FILTER_IGNORE)
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.text = text
	label.clip_text = true
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	holder.add_child(label)
	return label

func _stage_button(rect: Rect2, callable: Callable, text: String = "", font_size: int = 20) -> Button:
	var button: Button = FLASH_STAGE_BUTTON_SCRIPT.new() as Button
	button.text = text
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.focus_mode = Control.FOCUS_NONE
	button.flat = true
	_apply_transparent_button_style(button, text != "", font_size)
	_connect_stage_button_action(button, callable)
	content.add_child(button)
	button.set("stage_rect", rect)
	return button

func _connect_stage_button_action(button: Object, callable: Callable, with_click_sound: bool = true) -> void:
	if !callable.is_valid():
		return
	if with_click_sound:
		# Connect feedback before the action. Popup actions then replace this
		# short click with their dedicated open sound on the shared UI player.
		button.connect(&"pressed", Callable(self, "_play_ui_click_sound"))
	button.connect(&"pressed", callable)

func _add_fullscreen_modal_backdrop(close_callable: Callable, alpha: float = 0.58) -> void:
	# The fullscreen popup root must not swallow clicks before they reach the
	# backdrop. Interactive controls inside the popup keep their own STOP filters.
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Popup art is positioned in the original 800x480 Flash stage, but the dimmer
	# must cover the real viewport, including letterbox/pillarbox space on other
	# aspect ratios. Native full-rect Controls avoid clipping to stage bounds.
	var dimmer := ColorRect.new()
	dimmer.name = "ModalDimmer"
	dimmer.color = Color(0.0, 0.0, 0.0, alpha)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	dimmer.gui_input.connect(_on_modal_dimmer_input.bind(close_callable))
	content.add_child(dimmer)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _on_modal_dimmer_input(event: InputEvent, close_callable: Callable) -> void:
	var should_close: bool = false
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		should_close = mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		should_close = touch_event.pressed

	if should_close:
		get_viewport().set_input_as_handled()
		if close_callable.is_valid():
			close_callable.call()

func _center_popup_content(popup_root: Control, popup_top: float, popup_bottom: float) -> Control:
	var centered_content: Control = POPUP_STAGE_CENTER_SCRIPT.new() as Control
	centered_content.name = "CenteredPopupStage"
	centered_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centered_content.set("popup_top", popup_top)
	centered_content.set("popup_bottom", popup_bottom)
	popup_root.add_child(centered_content)
	return centered_content

func _stage_symbol(symbol_path: String, stage_position: Vector2, animation_time: float = -1.0, nested_animation_time: float = -1.0) -> Node2D:
	var symbol: Node2D = FLASH_STAGE_SYMBOL_SCRIPT.new() as Node2D
	symbol.z_index = 5
	symbol.set("symbol_path", symbol_path)
	symbol.set("stage_position", stage_position)
	symbol.set("animation_time", animation_time)
	symbol.set("nested_animation_time", nested_animation_time)
	# Configure the desired hero state before _ready() starts its asynchronous
	# current/next-pose pipeline. This avoids briefly requesting frame zero.
	content.add_child(symbol)
	return symbol

func _stage_panel(rect: Rect2, fill_color: Color, corner_radius: float = 0.0, border_color: Color = Color(0.0, 0.0, 0.0, 0.0), border_width: float = 0.0) -> Control:
	var panel: Control = FLASH_STAGE_PANEL_SCRIPT.new() as Control
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set("fill_color", fill_color)
	panel.set("corner_radius", corner_radius)
	panel.set("border_color", border_color)
	panel.set("border_width", border_width)
	content.add_child(panel)
	panel.set("stage_rect", rect)
	return panel

func _stage_texture(rect: Rect2, texture: Texture2D) -> Control:
	var node: Control = FLASH_STAGE_TEXTURE_SCRIPT.new() as Control
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.set("texture", texture)
	content.add_child(node)
	node.set("stage_rect", rect)
	return node

func _stage_horizontal_fill(stage_y: float, stage_height: float, color: Color) -> Control:
	var node: Control = FLASH_STAGE_HORIZONTAL_FILL_SCRIPT.new() as Control
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.set("fill_color", color)
	content.add_child(node)
	node.set("stage_y", stage_y)
	node.set("stage_height", stage_height)
	return node

func _stage_texture_fill(stage_y: float, stage_height: float, texture: Texture2D) -> Control:
	var node: Control = FLASH_STAGE_TEXTURE_FILL_SCRIPT.new() as Control
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.set("texture", texture)
	content.add_child(node)
	node.set("stage_y", stage_y)
	node.set("stage_height", stage_height)
	return node

func _stage_main_button(rect: Rect2, callable: Callable, text: String, font_size: int = 20, disabled: bool = false, disabled_overlay_alpha: float = 0.32, use_normal_texture_when_disabled: bool = false, selected: bool = false, attention_bounce: bool = false, color_preset: int = LONG_BUTTON_COLOR_BLUE) -> Control:
	var button: FlashStageTextureButton = STAGE_LONG_BUTTON_SCRIPT.new() as FlashStageTextureButton
	button.call("configure", text, font_size, disabled, disabled_overlay_alpha, use_normal_texture_when_disabled, selected)
	button.call("set_color_preset", color_preset)
	button.set("attention_bounce_enabled", attention_bounce)
	_connect_stage_button_action(button, callable)
	content.add_child(button)
	button.stage_rect = rect
	return button

func _stage_main_icon_button(rect: Rect2, callable: Callable, text: String, icon: Texture2D, icon_size: Vector2, font_size: int = 20, disabled: bool = false, disabled_overlay_alpha: float = 0.32, use_normal_texture_when_disabled: bool = false, selected: bool = false, color_preset: int = LONG_BUTTON_COLOR_BLUE) -> Control:
	var button: FlashStageTextureButton = STAGE_LONG_BUTTON_SCRIPT.new() as FlashStageTextureButton
	button.call("configure_with_icon", text, icon, icon_size, font_size, disabled, disabled_overlay_alpha, use_normal_texture_when_disabled, selected)
	button.call("set_color_preset", color_preset)
	_connect_stage_button_action(button, callable)
	content.add_child(button)
	button.stage_rect = rect
	return button

func _disable_button_input_without_changing_visual(button: Control) -> void:
	# Some selected states must stay visually active after their one-time action,
	# but using the regular disabled flag would replace that state with gray.
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.mouse_default_cursor_shape = Control.CURSOR_ARROW

func _stage_round_button(rect: Rect2, callable: Callable, icon_text: String = "", disabled: bool = false, selected: bool = false, disabled_overlay_alpha: float = 0.32, color_preset: int = ROUND_BUTTON_COLOR_BLUE) -> Control:
	var button: FlashStageTextureButton = STAGE_ROUND_BUTTON_SCRIPT.new() as FlashStageTextureButton
	button.call("configure_text", icon_text, disabled, selected, 28, disabled_overlay_alpha)
	button.call("set_color_preset", color_preset)
	_connect_stage_button_action(button, callable)
	content.add_child(button)
	button.stage_rect = rect
	return button

func _stage_round_icon_button(rect: Rect2, callable: Callable, icon: Texture2D, icon_size: Vector2, disabled: bool = false, selected: bool = false, icon_offset: Vector2 = Vector2.ZERO, disabled_overlay_alpha: float = 0.32, color_preset: int = ROUND_BUTTON_COLOR_BLUE) -> Control:
	var button: FlashStageTextureButton = STAGE_ROUND_BUTTON_SCRIPT.new() as FlashStageTextureButton
	button.call("configure_texture", icon, icon_size, disabled, selected, icon_offset, disabled_overlay_alpha)
	button.call("set_color_preset", color_preset)
	_connect_stage_button_action(button, callable)
	content.add_child(button)
	button.stage_rect = rect
	return button

func _stage_letter_button(rect: Rect2, callable: Callable, letter: String, state: int = 0, disabled: bool = false, font_size: int = 29, marker_size: Vector2 = Vector2(44.0, 44.0), animate_marker: bool = false) -> Control:
	var button: FlashStageTextureButton = STAGE_LETTER_BUTTON_SCRIPT.new() as FlashStageTextureButton
	button.call("configure", letter, state, font_size, marker_size, disabled, animate_marker)
	# Letter keys already have correct/wrong feedback and must not layer a click
	# over those gameplay sounds.
	_connect_stage_button_action(button, callable, false)
	content.add_child(button)
	button.stage_rect = rect
	return button

func _stage_line_edit(rect: Rect2, placeholder: String = "") -> LineEdit:
	var holder: Control = _stage_holder(rect)
	var edit := LineEdit.new()
	edit.set_anchors_preset(Control.PRESET_FULL_RECT)
	edit.placeholder_text = placeholder
	edit.max_length = 35
	edit.alignment = HORIZONTAL_ALIGNMENT_LEFT
	edit.add_theme_font_size_override("font_size", 26)
	edit.add_theme_color_override("font_color", Color(0.23, 0.26, 0.52))
	edit.add_theme_color_override("caret_color", Color(0.23, 0.26, 0.52))
	var empty_style := StyleBoxEmpty.new()
	edit.add_theme_stylebox_override("normal", empty_style)
	edit.add_theme_stylebox_override("focus", empty_style)
	holder.add_child(edit)
	return edit

func _apply_transparent_button_style(button: Button, show_text: bool = true, font_size: int = 20) -> void:
	var empty_style := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty_style)
	button.add_theme_stylebox_override("hover", empty_style)
	button.add_theme_stylebox_override("pressed", empty_style)
	button.add_theme_stylebox_override("focus", empty_style)
	button.add_theme_stylebox_override("disabled", empty_style)
	var font_color := Color(0.07, 0.10, 0.32, 1.0) if show_text else Color(1.0, 1.0, 1.0, 0.0)
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", font_color)
	button.add_theme_color_override("font_pressed_color", font_color)
	button.add_theme_color_override("font_disabled_color", Color(font_color.r, font_color.g, font_color.b, 0.45))
	button.add_theme_font_size_override("font_size", font_size)
func _selected_character_id() -> int:
	if GameState.settings.size() > 5:
		return int(GameState.settings[5])
	return 1
func _set_settings_word_language(language_code: String) -> void:
	GameState.set_word_language(language_code)
	Database.load_word_language(GameState.word_language)
	_invalidate_single_player_level_cache()
	_refresh_settings_word_language_buttons()

func _refresh_settings_word_language_buttons() -> void:
	for language_code: String in settings_word_language_buttons:
		var button := settings_word_language_buttons.get(language_code) as Control
		if button == null or !is_instance_valid(button):
			continue
		button.set("selected", language_code == GameState.word_language)

func _remove_settings_popup() -> void:
	_remove_about_popup()
	settings_toggle_buttons.clear()
	settings_word_language_buttons.clear()
	var popup_nodes: Array = get_tree().get_nodes_in_group("settings_popup")
	for node: Node in popup_nodes:
		if is_instance_valid(node) and node.get_parent() != null:
			node.get_parent().remove_child(node)
			node.queue_free()

func _settings_sound_label() -> String:
	return Database.tr_text(65, "Sounds and music")

func _settings_vibration_label() -> String:
	return Database.tr_text(61, "Vibration")

func _settings_word_base_label() -> String:
	return Database.tr_text(12, "Database:")

func _settings_on_label() -> String:
	return Database.tr_text(73, "On")

func _settings_off_label() -> String:
	return Database.tr_text(74, "Off")

func _settings_about_label() -> String:
	return Database.tr_text(11, "About")
func _settings_about_action() -> void:
	_show_about_popup()
func _remove_about_popup() -> void:
	var popup_nodes: Array = get_tree().get_nodes_in_group("about_popup")
	for node: Node in popup_nodes:
		if is_instance_valid(node) and node.get_parent() != null:
			node.get_parent().remove_child(node)
			node.queue_free()

func _about_title_label() -> String:
	return Database.tr_text(11, "About")

func _about_author_text() -> String:
	return Database.tr_text(20, "Author:") + " " + Database.tr_text(18, "Nikita Lukanin")

func _about_version_text() -> String:
	return Database.tr_text(19, "Version:") + " " + _application_version()

func _application_version() -> String:
	var configured_version: String = str(
		ProjectSettings.get_setting("application/config/version", APP_VERSION_FALLBACK)
	).strip_edges()
	return configured_version if configured_version != "" else APP_VERSION_FALLBACK

func _about_contacts_label() -> String:
	return Database.tr_text(21, "Contacts:")

func _about_contact_action(contact_type: String) -> void:
	match contact_type:
		"vk":
			OS.shell_open(AUTHOR_VK_URL)
		"mail":
			OS.shell_open(AUTHOR_EMAIL_URL)
func _toggle_setting(index: int) -> void:
	GameState.settings[index] = 1 if int(GameState.settings[index]) == 2 else 2
	if index == 4 and int(GameState.settings[index]) == 2:
		Input.vibrate_handheld(SETTINGS_TOGGLE_ON_VIBRATION_MS)
	if index == SOUND_SETTING_INDEX:
		_stop_game_audio_if_disabled()
	GameState.save_game()
	_refresh_settings_toggle_button(index)

func _sound_enabled() -> bool:
	return (
		GameState.settings.size() > SOUND_SETTING_INDEX
		and int(GameState.settings[SOUND_SETTING_INDEX]) == 2
	)

func _play_game_sound(player: AudioStreamPlayer, stream: AudioStream) -> void:
	if !_sound_enabled() or player == null or stream == null:
		return
	player.stream = stream
	player.play()

func _play_letter_feedback_sound(is_correct: bool) -> void:
	_play_game_sound(
		letter_feedback_audio_player,
		CORRECT_LETTER_SOUND if is_correct else WRONG_LETTER_SOUND
	)

func _play_ui_click_sound() -> void:
	_play_game_sound(ui_audio_player, UI_CLICK_SOUND)

func _play_popup_open_sound() -> void:
	_play_game_sound(ui_audio_player, POPUP_OPEN_SOUND)

func _play_result_sound_once(is_win: bool, data: Dictionary = {}) -> void:
	var sound_key := "%d:%d:%d" % [
		_current_hero_round_token(),
		GameState.current_mode,
		int(is_win),
	]
	if sound_key == last_result_sound_key:
		return
	last_result_sound_key = sound_key
	var stream: AudioStream = RESULT_WIN_SOUND
	if !is_win:
		stream = EL_TIGRE_DEFEAT_SOUND if _selected_character_id() == 2 else LUCKY_DEFEAT_SOUND
	_play_game_sound(result_audio_player, stream)

func _stop_game_audio_if_disabled() -> void:
	if _sound_enabled():
		return
	if letter_feedback_audio_player != null:
		letter_feedback_audio_player.stop()
	if result_audio_player != null:
		result_audio_player.stop()
	if ui_audio_player != null:
		ui_audio_player.stop()

func _refresh_settings_toggle_button(index: int) -> void:
	var button := settings_toggle_buttons.get(index) as Control
	if button == null or !is_instance_valid(button):
		return
	var enabled: bool = int(GameState.settings[index]) == 2
	button.set("button_text", _settings_on_label() if enabled else _settings_off_label())
	button.set("selected", enabled)

func _difficulty_mode_value() -> int:
	return DIFFICULTY_MODE_HARD if int(GameState.settings[2]) == DIFFICULTY_MODE_HARD else DIFFICULTY_MODE_NORMAL

func _difficulty_mode_label(value: int = -1) -> String:
	var resolved: int = _difficulty_mode_value() if value < 0 else value
	if resolved == DIFFICULTY_MODE_HARD:
		return _single_player_text("Сложный режим", "Hard mode")
	return _single_player_text("Обычный режим", "Normal mode")

func _style_difficulty_button(button: Control) -> Control:
	if button == null or _difficulty_mode_value() != DIFFICULTY_MODE_HARD:
		return button
	button.call(
		"set_color_palette",
		DIFFICULTY_HARD_NORMAL_TINT,
		DIFFICULTY_HARD_PRESSED_TINT,
		DIFFICULTY_HARD_SELECTED_TINT
	)
	button.set("outline_color", DIFFICULTY_HARD_OUTLINE_COLOR)
	button.set("outline_size", 4)
	return button

func _cycle_difficulty_mode() -> void:
	if _difficulty_mode_value() == DIFFICULTY_MODE_NORMAL:
		GameState.settings[2] = DIFFICULTY_MODE_HARD
	else:
		GameState.settings[2] = DIFFICULTY_MODE_NORMAL
	GameState.save_game()

func _cycle_classic_difficulty() -> void:
	_cycle_difficulty_mode()
	show_theme_select()

func _theme_icon_texture(theme_index: int) -> Texture2D:
	if theme_index < 0 or theme_index >= THEME_ICON_TEXTURES.size():
		return null
	return THEME_ICON_TEXTURES[theme_index]

func _single_player_text(ru_text: String, en_text: String) -> String:
	return ru_text if GameState.interface_language == "ru" else en_text

func _single_player_play_label() -> String:
	return _single_player_text("Играть", "Play")

func _single_player_levels_title() -> String:
	return _single_player_text("Одиночный режим", "Single player")

func _single_player_level_label() -> String:
	return _single_player_text("Уровень", "Level")

func _single_player_progress_label(played_count: int, total_count: int) -> String:
	var prefix := _single_player_text("Сыграно", "Played")
	return "%s: %d/%d" % [prefix, played_count, total_count]

func _single_player_level_completed_label() -> String:
	return _single_player_text("Уровень пройден!", "Level completed!")

func _single_player_choose_theme_label() -> String:
	return _single_player_text("Выберите тему", "Choose a category")

func _single_player_theme_popup_title() -> String:
	return _single_player_text("Выбрать тему?", "Choose this category?")

func _single_player_theme_start_label() -> String:
	return _single_player_text("Играть", "Play")

func _single_player_theme_cancel_label() -> String:
	return _single_player_text("Отмена", "Cancel")

func _single_player_theme_locked_note() -> String:
	return _single_player_text(
		"После выбора тема закрепится за уровнем",
		"The category will be locked for this level"
	)

func _single_player_word_count_label(word_count: int) -> String:
	if GameState.interface_language != "ru":
		return "%d %s" % [word_count, "word" if word_count == 1 else "words"]
	var last_two: int = word_count % 100
	var last_digit: int = word_count % 10
	var suffix := "слов"
	if last_two < 11 or last_two > 14:
		if last_digit == 1:
			suffix = "слово"
		elif last_digit >= 2 and last_digit <= 4:
			suffix = "слова"
	return "%d %s" % [word_count, suffix]

func _single_player_current_level_number() -> int:
	return GameState.get_single_player_display_level(Database.current_language, SINGLE_PLAYER_LEVEL_COUNT)

func _single_player_next_level_index() -> int:
	return clampi(
		GameState.get_single_player_unlocked_level(Database.current_language),
		0,
		SINGLE_PLAYER_LEVEL_COUNT - 1
	)

func _open_next_single_player_level() -> void:
	single_player_active_word_slot = -1
	show_single_player_level(_single_player_next_level_index())

func _invalidate_single_player_level_cache() -> void:
	single_player_level_definitions_cache.clear()
	single_player_level_cache_language = ""
	single_player_level_cache_theme_count = -1

func _single_player_level_word_target(level_index: int) -> int:
	if SINGLE_PLAYER_LEVEL_COUNT <= 1:
		return SINGLE_PLAYER_MIN_WORDS_PER_LEVEL
	var progress: float = float(clampi(level_index, 0, SINGLE_PLAYER_LEVEL_COUNT - 1)) / float(SINGLE_PLAYER_LEVEL_COUNT - 1)
	return clampi(
		int(round(lerpf(float(SINGLE_PLAYER_MIN_WORDS_PER_LEVEL), float(SINGLE_PLAYER_MAX_WORDS_PER_LEVEL), progress))),
		SINGLE_PLAYER_MIN_WORDS_PER_LEVEL,
		SINGLE_PLAYER_MAX_WORDS_PER_LEVEL
	)

func _single_player_seed(level_index: int, level_seed: int, salt: int) -> int:
	var language_seed: int = 37 if Database.current_language == "ru" else 73
	return int(
		maxi(level_seed, 1)
		+ (level_index + 1) * 1000003
		+ salt * 7919
		+ language_seed
	)

func _single_player_shuffle(values: Array, rng: RandomNumberGenerator) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index: int = rng.randi_range(0, index)
		var temporary: Variant = values[index]
		values[index] = values[swap_index]
		values[swap_index] = temporary

func _single_player_theme_options(level_index: int, level_seed: int, word_count: int) -> Array:
	var eligible: Array = []
	for theme_index in range(Database.get_theme_count()):
		if Database.get_words_by_index(theme_index, 0).size() >= word_count:
			eligible.append(theme_index)
	if eligible.is_empty():
		return []
	var rng := RandomNumberGenerator.new()
	rng.seed = _single_player_seed(level_index, level_seed, 11)
	_single_player_shuffle(eligible, rng)
	eligible.resize(mini(SINGLE_PLAYER_THEME_OPTIONS_PER_LEVEL, eligible.size()))
	return eligible

func _single_player_words_for_theme(level_index: int, level_seed: int, theme_index: int, word_count: int) -> Array:
	var pool: Array = Database.get_words_by_index(theme_index, 0).duplicate(true)
	if pool.is_empty():
		return []
	var rng := RandomNumberGenerator.new()
	rng.seed = _single_player_seed(level_index, level_seed, theme_index + 101)
	_single_player_shuffle(pool, rng)
	var words: Array = []
	for pool_index in range(mini(word_count, pool.size())):
		var picked: Dictionary = pool[pool_index]
		words.append({
			"theme_index": theme_index,
			"word_index": int(picked.get("index", 0)),
			"text": str(picked.get("text", "")),
			"difficulty": int(picked.get("difficulty", 0)),
		})
	return words

func _single_player_level_data(level_index: int) -> Dictionary:
	if level_index < 0 or level_index >= SINGLE_PLAYER_LEVEL_COUNT:
		return {}
	var theme_count: int = Database.get_theme_count()
	var language: String = Database.current_language
	if (
		single_player_level_cache_language != language
		or single_player_level_cache_theme_count != theme_count
	):
		_invalidate_single_player_level_cache()
		single_player_level_cache_language = language
		single_player_level_cache_theme_count = theme_count
	var level_key := str(level_index)
	if single_player_level_definitions_cache.has(level_key):
		var cached: Variant = single_player_level_definitions_cache[level_key]
		if cached is Dictionary:
			return cached
	if theme_count <= 0:
		return {}
	var word_count: int = _single_player_level_word_target(level_index)
	var level_seed: int = GameState.get_or_create_single_level_seed(language, level_index)
	var options: Array = _single_player_theme_options(level_index, level_seed, word_count)
	var selected_theme: int = GameState.get_single_level_selected_theme(language, level_index)
	if selected_theme < 0 or selected_theme >= theme_count:
		selected_theme = -1
	elif !options.has(selected_theme):
		if options.is_empty():
			options.append(selected_theme)
		else:
			options[0] = selected_theme
	var words: Array = []
	if selected_theme >= 0:
		words = _single_player_words_for_theme(level_index, level_seed, selected_theme, word_count)
	var level_data := {
		"index": level_index,
		"theme_options": options,
		"selected_theme_index": selected_theme,
		"word_count": word_count,
		"words": words,
	}
	single_player_level_definitions_cache[level_key] = level_data
	return level_data

func _single_player_level_theme_options(level_index: int) -> Array:
	return Array(_single_player_level_data(level_index).get("theme_options", []))

func _single_player_level_selected_theme(level_index: int) -> int:
	return int(_single_player_level_data(level_index).get("selected_theme_index", -1))

func _single_player_level_words(level_index: int) -> Array:
	return Array(_single_player_level_data(level_index).get("words", []))

func _single_player_level_word_count(level_index: int) -> int:
	return int(_single_player_level_data(level_index).get("word_count", _single_player_level_word_target(level_index)))

func _single_player_level_played_count(level_index: int) -> int:
	return GameState.get_single_level_played_count(
		Database.current_language,
		level_index,
		_single_player_level_word_count(level_index)
	)

func _single_player_level_completed(level_index: int) -> bool:
	return GameState.is_single_level_completed(
		Database.current_language,
		level_index,
		_single_player_level_word_count(level_index)
	)

func _single_player_level_word_status(level_index: int, word_slot: int) -> int:
	return GameState.get_single_level_word_status(
		Database.current_language,
		level_index,
		word_slot,
		_single_player_level_word_count(level_index)
	)

func _single_player_next_unplayed_word_slot(level_index: int) -> int:
	for word_slot in range(_single_player_level_word_count(level_index)):
		if _single_player_level_word_status(level_index, word_slot) == 0:
			return word_slot
	return -1

func _single_player_mark_current_word_finished(data: Dictionary, is_win: bool) -> Dictionary:
	if single_player_active_level_index < 0 or single_player_active_word_slot < 0:
		return data
	var result: Dictionary = data.duplicate(true)
	var level_word_count: int = _single_player_level_word_count(single_player_active_level_index)
	var progress: Dictionary = GameState.mark_single_level_word_played(
		Database.current_language,
		single_player_active_level_index,
		single_player_active_word_slot,
		level_word_count,
		SINGLE_PLAYER_LEVEL_COUNT,
		is_win
	)
	if !result.has("lines") or !(result["lines"] is Array):
		result["lines"] = []
	result["single_player_level_index"] = single_player_active_level_index
	result["single_player_word_slot"] = single_player_active_word_slot
	result["single_player_played_count"] = int(progress.get("played_count", 0))
	result["single_player_total_count"] = level_word_count
	result["single_player_level_completed"] = bool(progress.get("completed", false))
	result["single_player_level_perfect"] = bool(progress.get("perfect", false))
	result["single_player_unlocked_next"] = bool(progress.get("unlocked_next", false))
	if bool(progress.get("completed", false)):
		result["lines"].append(_single_player_level_completed_label())
	else:
		result["lines"].append(_single_player_progress_label(int(progress.get("played_count", 0)), level_word_count))
	return result

func _single_player_result_label() -> String:
	if single_player_active_level_index < 0:
		return _single_player_levels_title()
	return "%s %d • %d/%d" % [
		_single_player_level_label(),
		single_player_active_level_index + 1,
		_single_player_level_played_count(single_player_active_level_index),
		_single_player_level_word_count(single_player_active_level_index)
	]

func _single_player_footer_back_rect() -> Rect2:
	var rect := Rect2(14.0, 711.0, 64.0, 64.0)
	if has_method("_portrait_footer_round_button_rect"):
		return call("_portrait_footer_round_button_rect", rect)
	return rect

func _single_player_footer_icon_size(icon_size: Vector2) -> Vector2:
	if has_method("_portrait_footer_icon_size"):
		return call("_portrait_footer_icon_size", icon_size)
	return icon_size

func _stage_single_player_menu_button(rect: Rect2, callable: Callable) -> void:
	# Keep all visible copy inside the actual StageLongButton. This guarantees
	# that the whole orange surface remains one hit target instead of being
	# partially covered by separate stage controls.
	var button := _stage_main_button(
		rect,
		callable,
		"",
		26,
		false,
		0.32,
		false,
		false,
		false,
		LONG_BUTTON_COLOR_ORANGE
	)

	var title_label := Label.new()
	title_label.name = "PlayTitle"
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.position = Vector2(0.0, 3.0)
	title_label.size = Vector2(rect.size.x, rect.size.y * 0.54)
	title_label.text = _single_player_play_label()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	title_label.add_theme_font_size_override("font_size", 27)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_label.add_theme_color_override("font_outline_color", Color(0.48, 0.24, 0.08, 0.92))
	title_label.add_theme_constant_override("outline_size", 2)
	button.add_child(title_label)

	var level_label := Label.new()
	level_label.name = "LevelSubtitle"
	level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_label.position = Vector2(0.0, rect.size.y * 0.51)
	level_label.size = Vector2(rect.size.x, rect.size.y * 0.32)
	level_label.text = "%s %d" % [_single_player_level_label(), _single_player_current_level_number()]
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	level_label.add_theme_font_size_override("font_size", 15)
	level_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.90, 1.0))
	level_label.add_theme_color_override("font_outline_color", Color(0.48, 0.24, 0.08, 0.80))
	level_label.add_theme_constant_override("outline_size", 1)
	button.add_child(level_label)

func _remove_single_player_theme_popup() -> void:
	var popup_nodes: Array = get_tree().get_nodes_in_group("single_player_theme_popup")
	for node: Node in popup_nodes:
		if is_instance_valid(node) and node.get_parent() != null:
			node.get_parent().remove_child(node)
			node.queue_free()

func _stage_single_player_theme_card(
	rect: Rect2,
	theme_index: int,
	word_count: int,
	played_count: int,
	selected: bool,
	disabled: bool,
	action: Callable
) -> void:
	# Reuse the same layered card artwork as Classic mode, expanded to one wide
	# row so the three offered categories read as the main level choices.
	var card := _stage_texture(rect, THEME_CARD_TEXTURE)
	var progress_height: float = rect.size.y * 0.70
	var progress_back := _stage_texture(
		Rect2(rect.position, Vector2(rect.size.x, progress_height)),
		THEME_CARD_PROGRESS_TEXTURE
	)
	var progress_text: String = (
		_single_player_progress_label(played_count, word_count)
		if selected
		else _single_player_word_count_label(word_count)
	)
	var progress_label := _stage_label(
		Rect2(
			rect.position + Vector2(18.0, 6.0 + THEME_PROGRESS_TEXT_OPTICAL_OFFSET_Y),
			Vector2(rect.size.x - 36.0, progress_height - 12.0)
		),
		progress_text,
		20,
		Color(0.43, 0.49, 0.83, 1.0)
	)
	progress_label.clip_text = false

	var theme_icon: Control = null
	var theme_icon_texture: Texture2D = _theme_icon_texture(theme_index)
	if theme_icon_texture != null:
		theme_icon = _stage_texture(
			Rect2(rect.position + Vector2(20.0, 56.0), Vector2(48.0, 48.0)),
			theme_icon_texture
		)
		theme_icon.z_index = 11

	var theme_name: String = Database.get_theme_name(theme_index).to_upper()
	var title_font_size: int = 20 if theme_name.length() > 15 else 26
	var title_label := _stage_label(
		Rect2(rect.position + Vector2(84.0, 55.0), Vector2(rect.size.x - 104.0, 50.0)),
		theme_name,
		title_font_size,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_LEFT
	)
	title_label.clip_text = false
	title_label.add_theme_color_override("font_outline_color", Color(0.42, 0.49, 0.82, 1.0))
	title_label.add_theme_constant_override("outline_size", 2)

	if selected:
		_stage_panel(rect.grow(2.0), Color.TRANSPARENT, 16.0, Color(0.94, 0.58, 0.22, 1.0), 3.0)
	if disabled:
		for item in [card, progress_back, progress_label, theme_icon, title_label]:
			if item != null:
				item.modulate = Color(1.0, 1.0, 1.0, 0.30)

	var theme_button := _stage_button(rect, action, "")
	theme_button.disabled = disabled
	_bind_theme_card_press_state(theme_button, card)

func show_single_player_level(level_index: int) -> void:
	level_index = clampi(level_index, 0, SINGLE_PLAYER_LEVEL_COUNT - 1)
	single_player_active_level_index = level_index
	single_player_active_word_slot = -1
	_clear("")
	var footer_y: float = 688.0
	var screen_blue := Color(0.2706, 0.3098, 0.6078, 1.0)
	_stage_texture_fill(0.0, footer_y, MENU_PAPER_COVER)
	_stage_horizontal_fill(footer_y, 800.0 - footer_y, screen_blue)
	var level_title := _stage_label(
		Rect2(24.0, 14.0, 432.0, 70.0),
		"%s %d" % [_single_player_level_label(), level_index + 1],
		38,
		screen_blue,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	level_title.clip_text = false
	var selected_theme: int = _single_player_level_selected_theme(level_index)
	var instruction_text: String = _single_player_choose_theme_label()
	if selected_theme >= 0:
		instruction_text = _single_player_text("Продолжите выбранную тему", "Continue the selected category")
	var instruction_label := _stage_label(
		Rect2(36.0, 82.0, 408.0, 46.0),
		instruction_text,
		21,
		screen_blue,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	instruction_label.clip_text = false
	_stage_round_icon_button(
		_single_player_footer_back_rect(),
		Callable(self, "show_menu"),
		SINGLE_PLAYER_BACK_ARROW_ICON,
		_single_player_footer_icon_size(Vector2(27.0, 33.0))
	)

	var word_count: int = _single_player_level_word_count(level_index)
	var played_count: int = _single_player_level_played_count(level_index)
	var theme_options: Array = _single_player_level_theme_options(level_index)
	if theme_options.is_empty():
		var unavailable_label := _stage_label(
			Rect2(42.0, 260.0, 396.0, 100.0),
			_single_player_text("Нет доступных тем", "No categories available"),
			24,
			screen_blue,
			HORIZONTAL_ALIGNMENT_CENTER
		)
		unavailable_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		unavailable_label.clip_text = false
		return

	var card_rect := Rect2(30.0, 144.0, 420.0, 112.0)
	for option_index in range(theme_options.size()):
		var theme_index: int = int(theme_options[option_index])
		var is_selected: bool = selected_theme == theme_index
		var disabled: bool = selected_theme >= 0 and !is_selected
		var action: Callable = Callable(self, "_show_single_player_theme_popup").bind(level_index, theme_index)
		if is_selected:
			action = Callable(self, "_start_next_single_player_word").bind(level_index)
		_stage_single_player_theme_card(
			Rect2(card_rect.position + Vector2(0.0, float(option_index) * 144.0), card_rect.size),
			theme_index,
			word_count,
			played_count,
			is_selected,
			disabled,
			action
		)

func _confirm_single_player_theme_selection(level_index: int, theme_index: int) -> void:
	_remove_single_player_theme_popup()
	var options: Array = _single_player_level_theme_options(level_index)
	if !options.has(theme_index):
		return
	var existing_theme: int = GameState.get_single_level_selected_theme(Database.current_language, level_index)
	if existing_theme < 0:
		GameState.select_single_level_theme(
			Database.current_language,
			level_index,
			theme_index,
			_single_player_level_word_count(level_index)
		)
	_invalidate_single_player_level_cache()
	single_player_active_level_index = level_index
	single_player_active_word_slot = -1
	_start_next_single_player_word(level_index)

func _start_next_single_player_word(level_index: int) -> void:
	if _single_player_level_selected_theme(level_index) < 0:
		show_single_player_level(level_index)
		return
	var next_slot: int = _single_player_next_unplayed_word_slot(level_index)
	if next_slot < 0:
		_open_next_single_player_level()
		return
	_start_single_player_word(level_index, next_slot)

func _start_single_player_word(level_index: int, word_slot: int) -> void:
	var words: Array = _single_player_level_words(level_index)
	if word_slot < 0 or word_slot >= words.size():
		return
	if _single_player_level_word_status(level_index, word_slot) != 0:
		return
	var word_info: Dictionary = words[word_slot]
	single_player_active_level_index = level_index
	single_player_active_word_slot = word_slot
	game_finished = false
	last_result_data = {}
	GameState.current_mode = MODE_SINGLE_PLAYER
	var word := WordData.new(
		str(word_info.get("text", "")),
		int(word_info.get("difficulty", 0)),
		int(word_info.get("theme_index", -1)),
		int(word_info.get("word_index", -1))
	)
	GameState.mark_single_player_word_shown(
		Database.current_language,
		word.theme_index,
		word.index,
		Database.get_words_by_index(word.theme_index, 0).size()
	)
	GameSession.start_round(word, word.index, word.theme_index, MODE_SINGLE_PLAYER)
	GameState.save_game()
	show_game_screen()

func _bind_theme_card_press_state(button: BaseButton, card: CanvasItem) -> void:
	if button.disabled:
		return
	button.button_down.connect(_set_theme_card_pressed.bind(card, true))
	button.button_up.connect(_set_theme_card_pressed.bind(card, false))
	button.mouse_exited.connect(_set_theme_card_pressed.bind(card, false))

func _set_theme_card_pressed(card: CanvasItem, is_pressed: bool) -> void:
	if card == null or !is_instance_valid(card):
		return
	card.modulate = THEME_CARD_PRESSED_MODULATE if is_pressed else Color.WHITE
func _confirm_clear_theme(theme_index: int) -> void:
	WordManager.clear_the_theme(theme_index)
	_remove_clear_theme_popup()
	show_theme_select()

func _remove_clear_theme_popup() -> void:
	var popup_nodes: Array = get_tree().get_nodes_in_group("clear_theme_popup")
	for node: Node in popup_nodes:
		if is_instance_valid(node) and node.get_parent() != null:
			node.get_parent().remove_child(node)
			node.queue_free()
func start_classic_game(theme_index: int) -> void:
	game_finished = false
	last_result_data = {}
	single_player_active_level_index = -1
	single_player_active_word_slot = -1
	GameState.current_mode = MODE_CLASSIC
	GameSession.start_new_round(theme_index)
	GameState.save_game()
	show_game_screen()

func _exit_game_warning_text() -> String:
	if GameState.current_mode == MODE_SINGLE_PLAYER:
		return _single_player_text("Будет засчитано поражение", "A defeat will be recorded")
	return _single_player_text("Вы потеряете свой прогресс", "You will lose your progress")
func _confirm_exit_game() -> void:
	_remove_exit_game_popup()
	if GameState.current_mode == MODE_SINGLE_PLAYER:
		_forfeit_single_player_round()
		return
	show_menu()

func _forfeit_single_player_round() -> void:
	var level_index: int = single_player_active_level_index
	# A result transition may already be waiting for the letter-marker animation.
	# In that case the round has already been recorded, so only cancel the delayed
	# result screen and return to the level without recording it a second time.
	result_transition_generation += 1
	round_result_delay_requested = false
	if !game_finished and GameSession.is_active and level_index >= 0 and single_player_active_word_slot >= 0:
		game_finished = true
		_single_player_mark_current_word_finished({}, false)
	GameSession.discard_current_round()
	game_finished = false
	last_result_data = {}
	single_player_active_word_slot = -1
	if level_index >= 0:
		show_single_player_level(level_index)
	else:
		show_menu()

func _remove_exit_game_popup() -> void:
	var popup_nodes: Array = get_tree().get_nodes_in_group("exit_game_popup")
	for node: Node in popup_nodes:
		if is_instance_valid(node) and node.get_parent() != null:
			node.get_parent().remove_child(node)
			node.queue_free()
func _custom_word_random_label() -> String:
	return "Случайное" if Database.interface_language == "ru" else "Random"

func _custom_word_start_label() -> String:
	return Database.tr_text(77, "Start game")

func _on_custom_word_text_changed(value: String) -> void:
	_reset_custom_word_check_feedback()
	custom_word_text = _normalize_custom_word_input(value)
	if custom_word_edit != null and custom_word_edit.text != custom_word_text:
		var caret_column: int = custom_word_edit.caret_column
		custom_word_edit.text = custom_word_text
		custom_word_edit.caret_column = mini(caret_column, custom_word_edit.text.length())
	_sync_custom_word_input_visual()
	_sync_custom_word_start_bounce()

func _normalize_custom_word_input(value: String) -> String:
	var normalized: String = value.to_upper().replace("-", "—").replace("Ё", "Е")
	var filtered: String = ""
	var allowed_letters: PackedStringArray = Database.get_alphabet()
	for i: int in range(normalized.length()):
		var character: String = normalized.substr(i, 1)
		if allowed_letters.has(character):
			filtered += character
		elif character == " " or character == "—":
			# TextBlock.CheckLast() in the FLA prevents leading and consecutive
			# separators while the word is being typed.
			if filtered != "" and filtered.right(1) != " " and filtered.right(1) != "—":
				filtered += character
	return filtered.substr(0, 15)

func _set_custom_word_input_color(color: Color) -> void:
	if custom_word_input_visual != null and is_instance_valid(custom_word_input_visual):
		custom_word_input_visual.set("text_color", color)
	elif custom_word_edit != null and is_instance_valid(custom_word_edit):
		custom_word_edit.add_theme_color_override("font_color", color)

func _sync_custom_word_input_visual() -> void:
	if custom_word_input_visual != null and is_instance_valid(custom_word_input_visual):
		custom_word_input_visual.call("refresh_display")

func _sync_custom_word_start_bounce() -> void:
	if custom_word_start_button == null or !is_instance_valid(custom_word_start_button):
		return
	var has_word: bool = !custom_word_text.is_empty()
	custom_word_start_button.set("button_disabled", !has_word)
	custom_word_start_button.set("attention_bounce_enabled", has_word)

func _set_random_custom_word() -> void:
	var theme_count: int = Database.get_theme_count()
	if theme_count <= 0:
		return
	var candidates: PackedStringArray = []
	for theme_index: int in range(theme_count):
		# Database difficulty filter 2 is the original game's easy/simple pool.
		var words: Array = Database.get_words_by_index(theme_index, RANDOM_CUSTOM_WORD_DIFFICULTY_FILTER)
		for picked: Dictionary in words:
			var candidate: String = _normalize_custom_word_input(str(picked.get("text", "")))
			if _is_random_custom_word_candidate(candidate):
				candidates.append(candidate)
	if candidates.is_empty():
		return
	_reset_custom_word_check_feedback()
	custom_word_text = candidates[randi() % candidates.size()]
	if custom_word_edit != null:
		custom_word_edit.text = custom_word_text
		custom_word_edit.caret_column = custom_word_edit.text.length()
		_sync_custom_word_input_visual()
	_sync_custom_word_start_bounce()

func _is_random_custom_word_candidate(word: String) -> bool:
	return (
		!word.is_empty()
		and word.length() <= RANDOM_CUSTOM_WORD_MAX_LENGTH
		and !word.contains(" ")
		and !word.contains("—")
		and !word.contains("-")
	)

func _check_custom_word_now() -> void:
	if custom_word_edit == null:
		return
	custom_word_text = WordManager.normalize_word(custom_word_edit.text)
	var language_code: String = _custom_word_language(custom_word_text)
	if !_is_valid_custom_word(custom_word_text) or language_code == "":
		_set_temporary_custom_word_input_color(Color(0.62, 0.25, 0.42, 1.0))
		custom_word_edit.placeholder_text = Database.tr_text(64, "Error! Something goes wrong.")
		_show_custom_word_toast(&"TOAST_WORD_NOT_FOUND", false)
		_vibrate_custom_word_not_found()
		return

	_cancel_custom_word_check()
	_hide_custom_word_toast()
	_reset_custom_word_input_color()
	_set_custom_word_checking(true)
	var encoded_lower: String = custom_word_text.to_lower().uri_encode()
	var title_case: String = custom_word_text.substr(0, 1) + custom_word_text.substr(1).to_lower()
	custom_word_check_urls = [
		"https://" + language_code + ".wiktionary.org/wiki/" + encoded_lower,
		"https://" + language_code + ".wiktionary.org/wiki/" + title_case.uri_encode(),
	]
	custom_word_check_request = HTTPRequest.new()
	custom_word_check_request.name = "CustomWordWiktionaryCheck"
	custom_word_check_request.timeout = 10.0
	custom_word_check_request.request_completed.connect(_on_custom_word_check_completed)
	add_child(custom_word_check_request)
	_request_next_custom_word_url()

func _request_next_custom_word_url() -> void:
	if custom_word_check_request == null or custom_word_check_urls.is_empty():
		_set_custom_word_check_result(false, false)
		return
	var url: String = custom_word_check_urls.pop_front()
	var error: Error = custom_word_check_request.request(url)
	if error != OK:
		_set_custom_word_check_result(false, true)

func _on_custom_word_check_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		_set_custom_word_check_result(true, false)
		return
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 404 and !custom_word_check_urls.is_empty():
		_request_next_custom_word_url()
		return
	_set_custom_word_check_result(false, response_code != 404)

func _set_custom_word_check_result(found: bool, network_error: bool) -> void:
	var result_key: StringName
	if found:
		result_key = &"TOAST_WORD_FOUND"
	elif network_error:
		result_key = &"TOAST_ERROR"
	else:
		result_key = &"TOAST_WORD_NOT_FOUND"
	_cancel_custom_word_check()
	if network_error:
		_reset_custom_word_input_color()
	elif custom_word_edit != null:
		_set_temporary_custom_word_input_color(
			Color(0.22, 0.55, 0.41, 1.0) if found else Color(0.62, 0.25, 0.42, 1.0)
		)
	if !found and !network_error:
		_vibrate_custom_word_not_found()
	_show_custom_word_toast(result_key, found)

func _show_custom_word_toast(message_key: StringName, is_success: bool) -> void:
	if custom_word_input_visual == null or !is_instance_valid(custom_word_input_visual):
		return
	custom_word_input_visual.call("show_validation_toast", message_key, is_success)

func _hide_custom_word_toast() -> void:
	if custom_word_input_visual == null or !is_instance_valid(custom_word_input_visual):
		return
	custom_word_input_visual.call("hide_validation_toast")

func _set_temporary_custom_word_input_color(color: Color) -> void:
	custom_word_color_generation += 1
	var color_generation: int = custom_word_color_generation
	_set_custom_word_input_color(color)
	await get_tree().create_timer(CUSTOM_WORD_RESULT_COLOR_DURATION).timeout
	if color_generation != custom_word_color_generation:
		return
	_set_custom_word_input_color(CUSTOM_WORD_INPUT_DEFAULT_COLOR)

func _reset_custom_word_input_color() -> void:
	custom_word_color_generation += 1
	_set_custom_word_input_color(CUSTOM_WORD_INPUT_DEFAULT_COLOR)

func _vibrate_custom_word_not_found() -> void:
	if GameState.settings.size() > 4 and int(GameState.settings[4]) == 2:
		Input.vibrate_handheld(CUSTOM_WORD_NOT_FOUND_VIBRATION_MS)

func _cancel_custom_word_check() -> void:
	custom_word_check_urls.clear()
	if custom_word_check_request != null and is_instance_valid(custom_word_check_request):
		custom_word_check_request.cancel_request()
		custom_word_check_request.queue_free()
	custom_word_check_request = null
	_set_custom_word_checking(false)

func _set_custom_word_checking(is_checking: bool) -> void:
	if !is_checking:
		_stop_custom_word_check_text_animation()
	if custom_word_check_button == null or !is_instance_valid(custom_word_check_button):
		return
	# The shared disabled state is a neutral gray mask and blocks pointer input.
	custom_word_check_button.set("selected", false)
	custom_word_check_button.set("button_disabled", is_checking)
	custom_word_check_button.modulate = Color.WHITE
	if is_checking:
		_start_custom_word_check_text_animation()

func _start_custom_word_check_text_animation() -> void:
	if custom_word_check_button == null or !is_instance_valid(custom_word_check_button):
		return
	custom_word_check_label_base = Database.tr_text(60, "Check the word")
	custom_word_check_dot_count = 0
	_update_custom_word_check_text()
	if custom_word_check_animation_timer == null or !is_instance_valid(custom_word_check_animation_timer):
		custom_word_check_animation_timer = Timer.new()
		custom_word_check_animation_timer.name = "CustomWordCheckDotsTimer"
		custom_word_check_animation_timer.wait_time = CUSTOM_WORD_CHECK_DOTS_INTERVAL
		custom_word_check_animation_timer.one_shot = false
		custom_word_check_animation_timer.timeout.connect(_advance_custom_word_check_dots)
		add_child(custom_word_check_animation_timer)
	custom_word_check_animation_timer.start()

func _stop_custom_word_check_text_animation() -> void:
	if custom_word_check_animation_timer != null and is_instance_valid(custom_word_check_animation_timer):
		custom_word_check_animation_timer.stop()
	custom_word_check_dot_count = 0
	if custom_word_check_label_base.is_empty():
		custom_word_check_label_base = Database.tr_text(60, "Check the word")
	_update_custom_word_check_text()

func _advance_custom_word_check_dots() -> void:
	if custom_word_check_button == null or !is_instance_valid(custom_word_check_button):
		_stop_custom_word_check_text_animation()
		return
	custom_word_check_dot_count = (custom_word_check_dot_count + 1) % 4
	_update_custom_word_check_text()

func _update_custom_word_check_text() -> void:
	if custom_word_check_button == null or !is_instance_valid(custom_word_check_button):
		return
	var dots: String = ""
	for _index: int in range(custom_word_check_dot_count):
		dots += "."
	custom_word_check_button.set("button_text", custom_word_check_label_base + dots)

func _reset_custom_word_check_feedback() -> void:
	_cancel_custom_word_check()
	_hide_custom_word_toast()
	_reset_custom_word_input_color()

func start_custom_game() -> void:
	var source_text: String = custom_word_edit.text if custom_word_edit != null else custom_word_text
	var word := WordManager.normalize_word(source_text)
	if !_is_valid_custom_word(word):
		if custom_word_edit != null:
			_set_custom_word_input_color(Color(0.62, 0.25, 0.42, 1.0))
			custom_word_edit.placeholder_text = Database.tr_text(64, "Error! Something goes wrong.")
		return
	custom_word_text = word
	game_finished = false
	last_result_data = {}
	single_player_active_level_index = -1
	single_player_active_word_slot = -1
	GameState.current_mode = MODE_TWO_PLAYER
	GameSession.start_custom_round(word, custom_comment_text)
	GameState.save_game()
	show_game_screen()

func _is_valid_custom_word(word: String) -> bool:
	if word.length() == 0 or word.length() > 15:
		return false
	if word.begins_with(" ") or word.begins_with("—") or word.ends_with(" ") or word.ends_with("—"):
		return false
	if _custom_word_language(word) == "":
		return false
	var has_letter := false
	var previous_separator := false
	for i in range(word.length()):
		var ch := word.substr(i, 1)
		if ch == " " or ch == "—" or ch == "-":
			if previous_separator:
				return false
			previous_separator = true
			continue
		previous_separator = false
		var code: int = ch.unicode_at(0)
		if !((code >= 0x41 and code <= 0x5A) or (code >= 0x410 and code <= 0x42F)):
			return false
		has_letter = true
	return has_letter

func _custom_word_language(word: String) -> String:
	var has_latin := false
	var has_cyrillic := false
	for i in range(word.length()):
		var code: int = word.substr(i, 1).unicode_at(0)
		if code >= 0x41 and code <= 0x5A:
			has_latin = true
		elif code >= 0x410 and code <= 0x42F:
			has_cyrillic = true
	if has_latin == has_cyrillic:
		return ""
	return "en" if has_latin else "ru"

func show_game_screen() -> void:
	# The converted GameMov scene contains button frame debris and large nested
	# helper symbols that the original AS3 created/controlled at runtime.  Drawing
	# it as a static backdrop caused the white dead spots and wrong orange button
	# ghosts on the gameplay screen.  Rebuild this screen from MainFon + runtime
	# Flash-stage controls instead.
	_clear("")
	_refresh_game_screen()
func _play_hero_animation_range(nested_start_time: float, nested_end_time: float) -> void:
	_clear_hero_animation_overlay()
	if hero_static_symbol != null and is_instance_valid(hero_static_symbol):
		hero_static_symbol.visible = false
	var overlay: FlashStageSymbol = _create_hero_animation_overlay()
	overlay.animation_time = _hero_animation_time()
	overlay.nested_animation_time = nested_start_time
	overlay.playback_finished.connect(_on_hero_animation_finished)
	hero_animation_overlay = overlay
	overlay.call_deferred(
		"play_nested_range",
		_hero_animation_time(),
		nested_start_time,
		nested_end_time,
		HERO_ANIMATION_SPEED_SCALE
	)

func _play_hero_wrong_guess_animation(current_mistakes: int) -> void:
	_sync_hero_pose_state()
	if _hero_uses_terminal_loop(current_mistakes):
		_configure_hero_static_animation()
		return
	# HeroTries.Adder(0) advances the outer pose. Its nested timeline then plays
	# the original reaction frames 0..4 and holds on frame 4.
	_play_hero_animation_range(HERO_MOV_START_FRAME_TIME, HERO_MOV_IDLE_FRAME_TIME)

func _play_hero_correct_guess_animation() -> void:
	# In the original AS3 a correct letter resumes the current Mov timeline from
	# Flash frame 6 (CreateJS/Godot frame index 5) through its stop on frame 9.
	_play_hero_animation_range(HERO_MOV_RECOVERY_START_FRAME_TIME, HERO_MOV_RECOVERY_END_FRAME_TIME)

func _clear_hero_animation_overlay() -> void:
	if hero_animation_overlay != null and is_instance_valid(hero_animation_overlay):
		hero_animation_overlay.queue_free()
	hero_animation_overlay = null
	if hero_static_symbol != null and is_instance_valid(hero_static_symbol):
		hero_static_symbol.visible = true

func _on_hero_animation_finished() -> void:
	_clear_hero_animation_overlay()

func _hero_frame_index_for_mistakes(mistake_count: int) -> int:
	return clampi(mistake_count, 0, 6)

func _hero_animation_time_for_mistakes(mistake_count: int) -> float:
	# Imported Flash keys are rounded to milliseconds (0.042, 0.083, ...), while
	# exact 24 FPS boundaries can fall just before them (1 / 24 = 0.041666...).
	# Sampling halfway through the outer frame selects every discrete pose safely.
	return float(_hero_frame_index_for_mistakes(mistake_count)) / 24.0 + HERO_OUTER_FRAME_SAMPLE_OFFSET

func _hero_symbol_path() -> String:
	if GameState.settings.size() > 5 and int(GameState.settings[5]) == 2:
		return HERO_TYPE_2_SYMBOL
	return HERO_TYPE_1_SYMBOL

func _hero_animation_time() -> float:
	# Flash currentFrame is one-based: its original `7 - currentFrame` counter
	# maps zero mistakes to outer frame index 0 and the sixth mistake to index 6.
	return _hero_animation_time_for_mistakes(GameSession.mistakes)

func _current_hero_round_token() -> int:
	if GameSession.word_data == null:
		return 0
	return GameSession.word_data.get_instance_id()

func _sync_hero_pose_state() -> void:
	var round_token: int = _current_hero_round_token()
	var frame_index: int = _hero_frame_index_for_mistakes(GameSession.mistakes)
	if round_token == hero_pose_round_token and frame_index == hero_pose_frame_index:
		return
	hero_pose_round_token = round_token
	hero_pose_frame_index = frame_index
	hero_nested_pose_time = HERO_MOV_IDLE_FRAME_TIME
	hero_terminal_loop_time = HERO_MOV_START_FRAME_TIME

func _hero_nested_display_time() -> float:
	_sync_hero_pose_state()
	return hero_nested_pose_time

func _hero_uses_terminal_loop(mistake_count: int = -1) -> bool:
	var resolved_mistakes: int = GameSession.mistakes if mistake_count < 0 else mistake_count
	return _hero_frame_index_for_mistakes(resolved_mistakes) == 6

func _hero_terminal_loop_end_time() -> float:
	if GameState.settings.size() > 5 and int(GameState.settings[5]) == 2:
		return HERO_TYPE_2_TERMINAL_END_FRAME_TIME
	return HERO_TYPE_1_TERMINAL_END_FRAME_TIME

func _capture_hero_animation_phase() -> void:
	if !_hero_uses_terminal_loop():
		return
	if hero_static_symbol == null or !is_instance_valid(hero_static_symbol):
		return
	hero_terminal_loop_time = hero_static_symbol.get_nested_playback_position()

func _configure_hero_static_animation() -> void:
	if hero_static_symbol == null or !is_instance_valid(hero_static_symbol):
		return
	_sync_hero_pose_state()
	hero_static_symbol.nested_animation_time = hero_nested_pose_time
	if _hero_uses_terminal_loop():
		hero_static_symbol.call_deferred(
			"play_nested_loop",
			_hero_animation_time(),
			HERO_MOV_START_FRAME_TIME,
			_hero_terminal_loop_end_time(),
			HERO_ANIMATION_SPEED_SCALE,
			hero_terminal_loop_time
		)

func _press_letter(letter: String) -> void:
	_sync_hero_pose_state()
	var round_token_before_guess: int = _current_hero_round_token()
	var previous_mistakes: int = GameSession.mistakes
	var guess_is_available: bool = (
		GameSession.is_active
		and !GameSession.correct_letters.has(letter)
		and !GameSession.wrong_letters.has(letter)
		and !GameSession.removed_wrong_letters.has(letter)
	)
	var is_correct_letter: bool = GameSession.letters.has(letter)
	var should_play_recovery: bool = (
		guess_is_available
		and is_correct_letter
		and !_hero_uses_terminal_loop()
		and is_equal_approx(hero_nested_pose_time, HERO_MOV_IDLE_FRAME_TIME)
	)
	if should_play_recovery:
		# Set the resting phase before guess() emits changed, so the rebuilt static
		# symbol is already waiting on frame 9 underneath the transition overlay.
		hero_nested_pose_time = HERO_MOV_RECOVERY_END_FRAME_TIME
	pending_letter_markers.clear()
	pending_letter_markers.append(letter)
	pending_letter_marker_is_correct = is_correct_letter
	round_result_delay_requested = true
	var guess_was_correct: bool = GameSession.guess(letter)
	round_result_delay_requested = false
	if guess_is_available:
		_play_letter_feedback_sound(guess_was_correct)
	# A round signal can replace the current screen synchronously. Never let the
	# previous word's animation appear over the newly built result screen.
	if round_token_before_guess != _current_hero_round_token():
		return
	if GameSession.mistakes > previous_mistakes:
		_play_hero_wrong_guess_animation(GameSession.mistakes)
	elif guess_was_correct and should_play_recovery:
		_play_hero_correct_guess_animation()

func _use_open_hint() -> void:
	# If the hint reveals the final letter, keep the gameplay screen visible long
	# enough for the standard circle-and-bounce feedback to finish.
	round_result_delay_requested = true
	GameSession.use_open_letter_hint()
	round_result_delay_requested = false

func _use_remove_hint() -> void:
	GameSession.use_remove_wrong_hint()

func _use_comment_hint() -> void:
	if GameSession.comment_hint_unlocked:
		_show_word_comment_popup()
		return
	if GameSession.unlock_comment_hint():
		_show_word_comment_popup()

func _on_hint_letters_selected(letters: PackedStringArray, is_correct: bool) -> void:
	# GameSession emits this before `changed`, so the rebuilt keyboard can use the
	# same marker reveal and bounce path as a regular letter press.
	pending_letter_markers = letters.duplicate()
	pending_letter_marker_is_correct = is_correct
	if !letters.is_empty():
		# A remove-letter hint can cross out several keys, but it is one action
		# and therefore produces exactly one feedback sound.
		_play_letter_feedback_sound(is_correct)

func _on_round_won() -> void:
	_finish_round(true)

func _on_round_lost() -> void:
	_finish_round(false)

func _finish_round(is_win: bool) -> void:
	if game_finished:
		return

	game_finished = true
	last_result_is_win = is_win
	last_result_data = GameSession.finish_result(is_win)
	if GameState.current_mode == MODE_SINGLE_PLAYER:
		last_result_data = _single_player_mark_current_word_finished(last_result_data, is_win)

	var transition_generation: int = result_transition_generation
	if round_result_delay_requested:
		await get_tree().create_timer(LETTER_FEEDBACK_ANIMATION_DURATION).timeout
		if transition_generation != result_transition_generation:
			return
	show_result_screen(is_win, last_result_data)
func _spaced_result_word(word: String) -> String:
	var characters := PackedStringArray()
	for i in range(word.length()):
		characters.append(word.substr(i, 1))
	return " ".join(characters)

func _result_data_lines(data: Dictionary) -> String:
	var lines := PackedStringArray()
	for line in Array(data.get("lines", [])):
		var value: String = str(line).strip_edges()
		if value != "":
			lines.append(value)
	return "\n".join(lines)

func _result_message(is_win: bool, data: Dictionary) -> String:
	var data_lines: String = _result_data_lines(data)
	if data_lines != "":
		return data_lines
	return Database.tr_text(43 if is_win else 44, "Keep going!" if is_win else "You can do better!")

func _result_theme_label() -> String:
	if GameState.current_mode == MODE_SINGLE_PLAYER:
		return _single_player_result_label()
	if GameSession.theme_id < 0:
		return Database.tr_text(40, "No category")
	return Database.tr_text(42, "Category:") + " " + Database.get_theme_name(GameSession.theme_id).to_upper()

func _result_right_button_text() -> String:
	if GameState.current_mode == MODE_SINGLE_PLAYER:
		return Database.tr_text(3, "Continue")
	if GameSession.theme_id < 0:
		return Database.tr_text(8, "Restart")
	return Database.tr_text(3, "Continue")

func _result_right_action() -> void:
	_restart_last_mode()

func _apply_result_text_glow(label: Label, glow_color: Color, outline_size: int) -> void:
	label.add_theme_color_override("font_outline_color", glow_color)
	label.add_theme_constant_override("outline_size", outline_size)

func _restart_last_mode() -> void:
	if GameState.current_mode == MODE_TWO_PLAYER:
		show_custom_word()
	elif GameState.current_mode == MODE_SINGLE_PLAYER:
		if _single_player_level_completed(single_player_active_level_index):
			_open_next_single_player_level()
		else:
			_start_next_single_player_word(single_player_active_level_index)
	else:
		start_classic_game(max(0, GameSession.theme_id))
func _current_word_source_label() -> String:
	if GameState.current_mode == MODE_TWO_PLAYER or GameSession.theme_id < 0:
		return Database.tr_text(40, "Word from player")
	return Database.tr_text(42, "Category") + " " + Database.get_theme_name(GameSession.theme_id).to_upper()

func _remove_word_comment_popup() -> void:
	var popup_nodes: Array = get_tree().get_nodes_in_group("word_comment_popup")
	for node: Node in popup_nodes:
		if is_instance_valid(node) and node.get_parent() != null:
			node.get_parent().remove_child(node)
			node.queue_free()

func _open_word_search() -> void:
	var word := GameSession.get_full_word().strip_edges()
	if word == "":
		return
	OS.shell_open("https://www.google.com/search?q=" + word.to_lower().uri_encode())

func _unhandled_input(event: InputEvent) -> void:
	if game_finished or !GameSession.is_active:
		return
	if event is InputEventKey and event.pressed and !event.echo:
		if event.keycode == KEY_ESCAPE:
			show_menu()
			return
		var letter := OS.get_keycode_string(event.keycode).to_upper()
		letter = WordManager.normalize_word(letter)
		if letter.length() == 1 and Database.get_alphabet().has(letter):
			_press_letter(letter)
