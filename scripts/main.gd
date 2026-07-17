extends Node2D

const MENU_BUTTON_SIZE: Vector2 = Vector2(212.0, 49.0)
const ROUND_BUTTON_SIZE: Vector2 = Vector2(62.0, 62.0)
const HEADER_ACTION_BUTTON_RECT: Rect2 = Rect2(639.0, 12.0, 62.0, 62.0)
const HEADER_CLOSE_BUTTON_RECT: Rect2 = Rect2(716.0, 12.0, 62.0, 62.0)
const COMMENT_BUTTON_SIZE: Vector2 = Vector2(212.0, 49.0)
const THEME_BUTTON_SIZE: Vector2 = Vector2(241.0, 91.0)
const KEY_BUTTON_SIZE: Vector2 = Vector2(51.0, 47.0)
const HERO_WRONG_GUESS_ANIMATION_SPEED_SCALE: float = 0.65
const HERO_MOV_START_FRAME_TIME: float = 0.0
const HERO_MOV_IDLE_FRAME_TIME: float = 4.0 / 24.0
const LETTER_MARKER_REVEAL_DURATION: float = 0.2
const FLASH_STAGE_CONTROL_SCRIPT: GDScript = preload("res://scripts/ui/flash_stage_control.gd")
const FLASH_STAGE_BUTTON_SCRIPT: GDScript = preload("res://scripts/ui/flash_stage_button.gd")
const FLASH_STAGE_TEXTURE_BUTTON_SCRIPT: GDScript = preload("res://scripts/ui/flash_stage_texture_button.gd")
const STAGE_LONG_BUTTON_SCRIPT: GDScript = preload("res://scripts/ui/stage_long_button.gd")
const STAGE_ROUND_BUTTON_SCRIPT: GDScript = preload("res://scripts/ui/stage_round_button.gd")
const STAGE_LETTER_BUTTON_SCRIPT: GDScript = preload("res://scripts/ui/stage_letter_button.gd")
const FLASH_STAGE_PANEL_SCRIPT: GDScript = preload("res://scripts/ui/flash_stage_panel.gd")
const FLASH_STAGE_SYMBOL_SCRIPT: GDScript = preload("res://scripts/ui/flash_stage_symbol.gd")
const FLASH_STAGE_TEXTURE_SCRIPT: GDScript = preload("res://scripts/ui/flash_stage_texture.gd")
const FLASH_STAGE_HORIZONTAL_FILL_SCRIPT: GDScript = preload("res://scripts/ui/flash_stage_horizontal_fill.gd")
const FLASH_STAGE_TEXTURE_FILL_SCRIPT: GDScript = preload("res://scripts/ui/flash_stage_texture_fill.gd")
const POPUP_STAGE_CENTER_SCRIPT: GDScript = preload("res://scripts/ui/popup_stage_center.gd")

const ROUND_BUTTON_RECORDS_ICON: Texture2D = preload("res://flash_assets/_____________________png.png")
const DIFFICULTY_STARS_1_TEXTURE: Texture2D = preload("res://flash_assets/difficulty_stars_1.png")
const DIFFICULTY_STARS_2_TEXTURE: Texture2D = preload("res://flash_assets/difficulty_stars_2.png")
const DIFFICULTY_STARS_3_TEXTURE: Texture2D = preload("res://flash_assets/difficulty_stars_3.png")
const TIME_ATTACK_BADGE_OUTER_TEXTURE: Texture2D = preload("res://flash_assets/time_attack_badge_outer_133x133.png")
const TIME_ATTACK_HOURGLASS_TEXTURE: Texture2D = preload("res://flash_assets/time_attack_hourglass_38x46.png")
const TIME_ATTACK_TIMER_ICON_TEXTURE: Texture2D = preload("res://flash_assets/time_attack_timer_icon.png")
const ROUND_BUTTON_CROWN_ICON: Texture2D = preload("res://flash_assets/records_crown_icon.png")
const MAIN_MENU_HOLLOW_STAR_ICON: Texture2D = preload("res://flash_assets/main_menu_hollow_star_icon.png")
const RESULT_SEARCH_ICON: Texture2D = preload("res://flash_assets/result_search_icon_343.png")
const RESULT_CLOSE_ICON: Texture2D = preload("res://flash_assets/result_close_icon_43.png")
const CUSTOM_WORD_REFRESH_ICON: Texture2D = preload("res://flash_assets/custom_word_refresh_icon_341.png")
const CUSTOM_WORD_RANDOM_ICON: Texture2D = preload("res://flash_assets/custom_word_random_icon.png")
const ABOUT_VK_ICON: Texture2D = preload("res://flash_assets/about_vk_icon_87.png")
const ABOUT_MAIL_ICON: Texture2D = preload("res://flash_assets/about_mail_icon_86.png")
const HERO_BADGE_RING_TEXTURE: Texture2D = preload("res://flash_assets/user_hint_circle_74.png")
const HERO_BADGE_TAIL_TEXTURE: Texture2D = preload("res://flash_assets/_________________2_png.png")
const THEME_CARD_TEXTURE: Texture2D = preload("res://flash_assets/theme_card_user_239x90.png")
const THEME_CARD_PROGRESS_TEXTURE: Texture2D = preload("res://flash_assets/theme_card_progress_user_239x65.png")
const HINT_OPEN_BUTTON_TEXTURE: Texture2D = preload("res://flash_assets/user_hint_button_open_18.png")
const HINT_REMOVE_BUTTON_TEXTURE: Texture2D = preload("res://flash_assets/user_hint_button_remove_15.png")
const HINT_ICON_CHECK_TEXTURE: Texture2D = preload("res://flash_assets/user_hint_check_circle_uploaded.png")
const HINT_ICON_CROSS_TEXTURE: Texture2D = preload("res://flash_assets/user_hint_cross_circle_uploaded.png")
const MENU_PAPER_COVER: Texture2D = preload("res://flash_assets/fon_png.png")
const HERO_TYPE_1_SYMBOL: String = "res://symbols/HeroType1.tscn"
const HERO_TYPE_2_SYMBOL: String = "res://symbols/HeroType2.tscn"
const HERO_AVATAR_LAKI_TEXTURE: Texture2D = preload("res://img/_______3______1_0_SHAPE_0_BOUNDS_154.49_-80.71_SIZE_270_290.png")
const HERO_AVATAR_TIGRE_TEXTURE: Texture2D = preload("res://img/_______405______1_0_SHAPE_0_BOUNDS_-0.96_-0.96_SIZE_366_322.png")

var art_root: FlashBackdrop
var ui: Control
var content: Control
var game_timer: Timer
var game_finished: bool = false
var last_result_is_win: bool = false
var last_result_data: Dictionary = {}
var custom_word_edit: LineEdit
var custom_comment_edit: TextEdit
var custom_word_text: String = ""
var custom_comment_text: String = ""
var custom_word_check_request: HTTPRequest = null
var custom_word_check_urls: Array[String] = []
var custom_word_check_text: String = ""
var custom_word_check_state: int = 0 # 0 neutral, 1 checking, 2 found, 3 not found/error
var custom_word_check_label: Label = null
var word_info_visible: bool = false
var hero_animation_overlay: FlashStageSymbol = null
var hero_static_symbol: FlashStageSymbol = null
var settings_popup_return_content: Control = null
var pending_letter_marker: String = ""
var pending_letter_marker_is_correct: bool = false
var round_result_delay_requested: bool = false
var result_transition_generation: int = 0

func _ready() -> void:
	randomize()
	Database.load_language(GameState.language)
	_build_root()
	GameSession.changed.connect(_refresh_game_screen)
	GameSession.round_won.connect(_on_round_won)
	GameSession.round_lost.connect(_on_round_lost)
	show_menu()

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

	game_timer = Timer.new()
	game_timer.name = "TimeAttackTimer"
	game_timer.wait_time = 1.0
	game_timer.one_shot = false
	game_timer.timeout.connect(_on_timer_tick)
	add_child(game_timer)

func _clear(symbol_path: String = "") -> void:
	result_transition_generation += 1
	pending_letter_marker = ""
	pending_letter_marker_is_correct = false
	round_result_delay_requested = false
	_clear_hero_animation_overlay()
	_cancel_custom_word_check()
	custom_word_check_label = null
	hero_static_symbol = null
	_remove_character_select_popup()
	_remove_settings_popup()
	_remove_records_popup()
	_remove_time_attack_popup()
	_remove_clear_theme_popup()
	settings_popup_return_content = null
	_remove_custom_comment_popup()
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
	if callable.is_valid():
		button.pressed.connect(callable)
	content.add_child(button)
	button.set("stage_rect", rect)
	return button

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

func _stage_texture_button(rect: Rect2, callable: Callable, normal_texture: Texture2D, pressed_texture: Texture2D, text: String = "", font_size: int = 20, disabled: bool = false, disabled_texture: Texture2D = null, disabled_overlay_alpha: float = 0.32) -> Control:
	var button: Control = FLASH_STAGE_TEXTURE_BUTTON_SCRIPT.new() as Control
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.set("texture_normal", normal_texture)
	button.set("texture_pressed", pressed_texture)
	button.set("disabled", disabled)
	button.set("texture_disabled", disabled_texture)
	button.set("disabled_overlay_alpha", disabled_overlay_alpha)
	button.connect("pressed", callable)
	content.add_child(button)
	button.set("stage_rect", rect)
	if text != "":
		var label := Label.new()
		label.name = "Text"
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.set_anchors_preset(Control.PRESET_FULL_RECT)
		label.text = text
		label.clip_text = true
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", font_size)
		label.add_theme_color_override("font_color", Color.WHITE if !disabled else Color(1.0, 1.0, 1.0, 0.72))
		label.add_theme_color_override("font_outline_color", Color(0.23, 0.26, 0.52, 1.0))
		label.add_theme_constant_override("outline_size", 3)
		button.add_child(label)
		label.set_anchors_preset(Control.PRESET_FULL_RECT)
	return button



func _stage_symbol(symbol_path: String, stage_position: Vector2, animation_time: float = -1.0, nested_animation_time: float = -1.0) -> Node2D:
	var symbol: Node2D = FLASH_STAGE_SYMBOL_SCRIPT.new() as Node2D
	symbol.z_index = 5
	content.add_child(symbol)
	symbol.set("symbol_path", symbol_path)
	symbol.set("stage_position", stage_position)
	symbol.set("animation_time", animation_time)
	symbol.set("nested_animation_time", nested_animation_time)
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

func _stage_main_button(rect: Rect2, callable: Callable, text: String, font_size: int = 20, disabled: bool = false, disabled_overlay_alpha: float = 0.32, use_normal_texture_when_disabled: bool = false) -> Control:
	var button: FlashStageTextureButton = STAGE_LONG_BUTTON_SCRIPT.new() as FlashStageTextureButton
	button.call("configure", text, font_size, disabled, disabled_overlay_alpha, use_normal_texture_when_disabled)
	if callable.is_valid():
		button.pressed.connect(callable)
	content.add_child(button)
	button.stage_rect = rect
	return button

func _stage_main_icon_button(rect: Rect2, callable: Callable, text: String, icon: Texture2D, icon_size: Vector2, font_size: int = 20, disabled: bool = false, disabled_overlay_alpha: float = 0.32, use_normal_texture_when_disabled: bool = false) -> Control:
	var button: FlashStageTextureButton = STAGE_LONG_BUTTON_SCRIPT.new() as FlashStageTextureButton
	button.call("configure_with_icon", text, icon, icon_size, font_size, disabled, disabled_overlay_alpha, use_normal_texture_when_disabled)
	if callable.is_valid():
		button.pressed.connect(callable)
	content.add_child(button)
	button.stage_rect = rect
	return button

func _stage_round_button(rect: Rect2, callable: Callable, icon_text: String = "", disabled: bool = false, selected: bool = false, disabled_overlay_alpha: float = 0.32) -> Control:
	var button: FlashStageTextureButton = STAGE_ROUND_BUTTON_SCRIPT.new() as FlashStageTextureButton
	button.call("configure_text", icon_text, disabled, selected, 32, disabled_overlay_alpha)
	if callable.is_valid():
		button.pressed.connect(callable)
	content.add_child(button)
	button.stage_rect = rect
	return button

func _stage_round_icon_button(rect: Rect2, callable: Callable, icon: Texture2D, icon_size: Vector2, disabled: bool = false, selected: bool = false, icon_offset: Vector2 = Vector2.ZERO, disabled_overlay_alpha: float = 0.32) -> Control:
	var button: FlashStageTextureButton = STAGE_ROUND_BUTTON_SCRIPT.new() as FlashStageTextureButton
	button.call("configure_texture", icon, icon_size, disabled, selected, icon_offset, disabled_overlay_alpha)
	if callable.is_valid():
		button.pressed.connect(callable)
	content.add_child(button)
	button.stage_rect = rect
	return button

func _stage_letter_button(rect: Rect2, callable: Callable, letter: String, state: int = 0, disabled: bool = false, font_size: int = 29, marker_size: Vector2 = Vector2(44.0, 44.0), animate_marker: bool = false) -> Control:
	var button: FlashStageTextureButton = STAGE_LETTER_BUTTON_SCRIPT.new() as FlashStageTextureButton
	button.call("configure", letter, state, font_size, marker_size, disabled, animate_marker)
	if callable.is_valid():
		button.pressed.connect(callable)
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

func _stage_text_edit(rect: Rect2, placeholder: String = "") -> TextEdit:
	var holder: Control = _stage_holder(rect)
	var edit := TextEdit.new()
	edit.set_anchors_preset(Control.PRESET_FULL_RECT)
	edit.placeholder_text = placeholder
	edit.add_theme_font_size_override("font_size", 18)
	edit.add_theme_color_override("font_color", Color.WHITE)
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

func _button_text_color() -> Color:
	return Color(0.08, 0.11, 0.35)

func show_menu() -> void:
	game_timer.stop()
	GameSession.discard_current_round()
	_clear("")
	# The main menu is rebuilt completely with native runtime controls. Keep only
	# the original paper texture and the exact Flash header colour; loading the
	# converted MainMenu scene would reintroduce hidden duplicate buttons and all
	# of their obsolete bitmap dependencies.
	# Keep the header height in Flash stage coordinates while filling the real
	# viewport width. Menu controls remain positioned in the original stage.
	_stage_horizontal_fill(0.0, 118.0, Color(0.2706, 0.3098, 0.6078, 1.0))
	_stage_texture_fill(118.0, 362.0, MENU_PAPER_COVER)

	_stage_label(Rect2(84.0, 28.0, 360.0, 58.0), Database.tr_text(0, "HANGMAN"), 38, Color(0.82, 0.56, 0.34), HORIZONTAL_ALIGNMENT_LEFT)
	_stage_label(Rect2(284.0, 112.0, 300.0, 48.0), Database.tr_text(77, "Welcome back!"), 28, Color(0.27, 0.31, 0.61), HORIZONTAL_ALIGNMENT_CENTER)

	_stage_main_button(Rect2(161.0, 188.0, MENU_BUTTON_SIZE.x, MENU_BUTTON_SIZE.y), Callable(self, "show_theme_select"), Database.tr_text(1, "Classic"), 20)
	_stage_main_button(Rect2(161.0, 251.0, MENU_BUTTON_SIZE.x, MENU_BUTTON_SIZE.y), Callable(self, "_show_time_attack_popup"), Database.tr_text(2, "Time Attack"), 20)
	_stage_main_button(Rect2(161.0, 313.0, MENU_BUTTON_SIZE.x, MENU_BUTTON_SIZE.y), Callable(self, "show_custom_word"), Database.tr_text(3, "Two Player"), 20)

	_stage_main_button(Rect2(436.0, 251.0, MENU_BUTTON_SIZE.x, MENU_BUTTON_SIZE.y), Callable(self, "show_settings"), Database.tr_text(5, "Settings"), 20)

	_stage_round_icon_button(Rect2(492.0, 24.0, 62.0, 62.0), Callable(self, "show_records"), ROUND_BUTTON_RECORDS_ICON, Vector2(17.0, 18.0))

	# Achievements are not implemented yet: keep the same round-button component
	# in a disabled, semi-transparent state instead of drawing separate layers.
	var achievements_button := _stage_round_icon_button(Rect2(569.0, 24.0, 62.0, 62.0), Callable(), MAIN_MENU_HOLLOW_STAR_ICON, Vector2(22.0, 21.0), true, false, Vector2.ZERO, 0.0)
	achievements_button.self_modulate = Color(1.0, 1.0, 1.0, 0.55)
	achievements_button.set("icon_modulate", Color(1.0, 1.0, 1.0, 0.72))
	_stage_main_menu_character_button()


func _stage_main_menu_character_button() -> void:
	# Exact MainMenu.xml placement from the original FLA:
	# HeroMov is at (716, 23) inside Head, and Head is shifted by x = -50.
	# The separate blue tail bitmap is at (714, 112), also inside Head.
	# Draw both original assets instead of synthesizing a rounded rectangle or
	# masking the bottom with a solid block.
	_stage_texture(Rect2(664.0, 112.0, 115.0, 33.0), HERO_BADGE_TAIL_TEXTURE)
	_stage_texture(Rect2(666.0, 23.0, 111.0, 111.0), HERO_BADGE_RING_TEXTURE)
	if _selected_character_id() == 2:
		_stage_texture(Rect2(684.0, 53.0, 76.0, 67.0), HERO_AVATAR_TIGRE_TEXTURE)
	else:
		_stage_texture(Rect2(695.0, 50.0, 54.0, 58.0), HERO_AVATAR_LAKI_TEXTURE)
	_stage_button(Rect2(654.0, 11.0, 135.0, 145.0), Callable(self, "_show_character_select_popup"), "")

func _selected_character_id() -> int:
	if GameState.settings.size() > 5:
		return int(GameState.settings[5])
	return 1

func _show_character_select_popup() -> void:
	_remove_character_select_popup()

	var previous_content: Control = content
	var popup_layer := CanvasLayer.new()
	popup_layer.name = "CharacterSelectPopupCanvas"
	popup_layer.layer = 100
	popup_layer.add_to_group("character_select_popup")
	add_child(popup_layer)

	var popup_root: Control = Control.new()
	popup_root.name = "CharacterSelectPopupLayer"
	popup_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup_root.mouse_filter = Control.MOUSE_FILTER_STOP
	popup_layer.add_child(popup_root)
	content = popup_root

	_add_fullscreen_modal_backdrop(Callable(self, "_remove_character_select_popup"))
	content = _center_popup_content(popup_root, 0.0, 370.0)

	var popup_x: float = 56.0
	var popup_width: float = 648.0
	var header := _stage_panel(Rect2(popup_x, 0.0, popup_width, 88.0), Color(0.2706, 0.3098, 0.6078, 1.0))
	header.mouse_filter = Control.MOUSE_FILTER_STOP
	var body := _stage_panel(Rect2(popup_x, 88.0, popup_width, 282.0), Color(0.2314, 0.2627, 0.5176, 1.0))
	body.mouse_filter = Control.MOUSE_FILTER_STOP
	var separator := _stage_panel(Rect2(popup_x, 88.0, popup_width, 2.0), Color(0.8157, 0.5647, 0.3412, 1.0))
	separator.mouse_filter = Control.MOUSE_FILTER_STOP

	var title_label := _stage_label(Rect2(popup_x + 21.0, 12.0, 450.0, 50.0), Database.tr_text(9, "Choose the hero:"), 32, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.clip_text = false
	_stage_round_button(Rect2(popup_x + popup_width - 68.0, 12.0, ROUND_BUTTON_SIZE.x, ROUND_BUTTON_SIZE.y), Callable(self, "_remove_character_select_popup"), "×")

	_stage_character_option(1, Rect2(190.0, 150.0, 130.0, 130.0), Database.tr_text(75, "LUCKY"), HERO_AVATAR_LAKI_TEXTURE, Rect2(224.0, 180.0, 64.0, 69.0))
	_stage_character_option(2, Rect2(480.0, 150.0, 130.0, 130.0), Database.tr_text(76, "EL TIGRE"), HERO_AVATAR_TIGRE_TEXTURE, Rect2(498.0, 188.0, 94.0, 82.0))

	content = previous_content

func _stage_character_option(character_id: int, circle_rect: Rect2, label_text: String, avatar_texture: Texture2D, avatar_rect: Rect2) -> void:
	var selected := _selected_character_id() == character_id
	var halo_color := Color(0.336, 0.388, 0.717, 0.86) if selected else Color(0.336, 0.388, 0.717, 0.42)
	_stage_panel(Rect2(circle_rect.position - Vector2(14.0, 14.0), circle_rect.size + Vector2(28.0, 28.0)), halo_color, (circle_rect.size.x + 28.0) * 0.5)
	_stage_panel(circle_rect, Color.WHITE, circle_rect.size.x * 0.5, Color(0.82, 0.56, 0.34, 1.0), 3.0)
	_stage_texture(avatar_rect, avatar_texture)
	_stage_label(Rect2(circle_rect.position.x - 55.0, circle_rect.position.y + 155.0, circle_rect.size.x + 110.0, 42.0), label_text, 27, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_stage_button(Rect2(circle_rect.position - Vector2(20.0, 20.0), circle_rect.size + Vector2(40.0, 88.0)), Callable(self, "_select_character").bind(character_id), "")

func _select_character(character_id: int) -> void:
	while GameState.settings.size() <= 5:
		GameState.settings.append(1)
	GameState.settings[5] = character_id
	GameState.save_game()
	_remove_character_select_popup()
	show_menu()

func _remove_character_select_popup() -> void:
	var popup_nodes: Array = get_tree().get_nodes_in_group("character_select_popup")
	for node: Node in popup_nodes:
		if is_instance_valid(node) and node.get_parent() != null:
			node.get_parent().remove_child(node)
			node.queue_free()

func show_settings() -> void:
	var previous_content: Control = content
	if settings_popup_return_content != null and is_instance_valid(settings_popup_return_content):
		previous_content = settings_popup_return_content
	_remove_settings_popup()
	settings_popup_return_content = previous_content

	var popup_layer := CanvasLayer.new()
	popup_layer.name = "SettingsPopupCanvas"
	popup_layer.layer = 100
	popup_layer.add_to_group("settings_popup")
	add_child(popup_layer)

	var popup_root: Control = Control.new()
	popup_root.name = "SettingsPopupLayer"
	popup_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup_root.mouse_filter = Control.MOUSE_FILTER_STOP
	popup_layer.add_child(popup_root)
	content = popup_root

	_add_fullscreen_modal_backdrop(Callable(self, "_remove_settings_popup"))
	content = _center_popup_content(popup_root, 0.0, 370.0)

	var popup_x: float = 56.0
	var popup_width: float = 648.0
	var header := _stage_panel(Rect2(popup_x, 0.0, popup_width, 88.0), Color(0.2706, 0.3098, 0.6078, 1.0))
	header.mouse_filter = Control.MOUSE_FILTER_STOP
	var body := _stage_panel(Rect2(popup_x, 88.0, popup_width, 282.0), Color(0.2314, 0.2627, 0.5176, 1.0))
	body.mouse_filter = Control.MOUSE_FILTER_STOP
	var top_separator := _stage_panel(Rect2(popup_x, 88.0, popup_width, 2.0), Color(0.8157, 0.5647, 0.3412, 1.0))
	top_separator.mouse_filter = Control.MOUSE_FILTER_STOP
	var middle_separator := _stage_panel(Rect2(popup_x + 372.0, 126.0, 2.0, 132.0), Color(0.3157, 0.3765, 0.6902, 0.95))
	middle_separator.mouse_filter = Control.MOUSE_FILTER_STOP
	var bottom_separator := _stage_panel(Rect2(popup_x + 24.0, 263.0, popup_width - 48.0, 2.0), Color(0.3157, 0.3765, 0.6902, 0.95))
	bottom_separator.mouse_filter = Control.MOUSE_FILTER_STOP

	var title_label := _stage_label(Rect2(popup_x + 21.0, 12.0, 450.0, 50.0), Database.tr_text(5, "Settings"), 32, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.clip_text = false
	_stage_round_button(Rect2(popup_x + popup_width - 68.0, 12.0, ROUND_BUTTON_SIZE.x, ROUND_BUTTON_SIZE.y), Callable(self, "_remove_settings_popup"), "×")

	_stage_label(Rect2(popup_x + 44.0, 125.0, 220.0, 36.0), _settings_sound_label(), 22, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_label(Rect2(popup_x + 44.0, 187.0, 220.0, 36.0), _settings_vibration_label(), 22, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_settings_toggle_button(Rect2(popup_x + 260.0, 123.0, 102.0, 49.0), 3)
	_stage_settings_toggle_button(Rect2(popup_x + 260.0, 185.0, 102.0, 49.0), 4)

	_stage_label(Rect2(popup_x + 444.0, 125.0, 160.0, 36.0), _settings_word_base_label(), 22, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_settings_language_button(Rect2(popup_x + 406.0, 184.0, 102.0, 49.0), "ru", Database.tr_text(80, "Rus"))
	_stage_settings_language_button(Rect2(popup_x + 520.0, 184.0, 102.0, 49.0), "en", Database.tr_text(81, "Eng"))

	_stage_main_button(Rect2(popup_x + 111.0, 296.0, MENU_BUTTON_SIZE.x, MENU_BUTTON_SIZE.y), Callable(self, "_settings_about_action"), _settings_about_label(), 18)
	var remove_ads_button := _stage_main_button(Rect2(popup_x + 349.0, 296.0, MENU_BUTTON_SIZE.x, MENU_BUTTON_SIZE.y), Callable(self, "_settings_remove_ads_action"), _settings_remove_ads_label(), 18, true, 0.0, true)
	remove_ads_button.modulate = Color(1.0, 1.0, 1.0, 0.56)
	var remove_ads_label := remove_ads_button.get_node_or_null("Text") as Label
	if remove_ads_label != null:
		remove_ads_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.82))

	content = previous_content

func _stage_settings_toggle_button(rect: Rect2, setting_index: int) -> void:
	var enabled: bool = int(GameState.settings[setting_index]) == 2
	var texture: Texture2D = HINT_OPEN_BUTTON_TEXTURE if enabled else HINT_REMOVE_BUTTON_TEXTURE
	var label_text: String = _settings_on_label() if enabled else _settings_off_label()
	_stage_texture_button(rect, Callable(self, "_toggle_setting").bind(setting_index), texture, HINT_OPEN_BUTTON_TEXTURE, label_text, 18)

func _stage_settings_language_button(rect: Rect2, language_code: String, label_text: String) -> void:
	var selected: bool = GameState.language == language_code
	var texture: Texture2D = HINT_OPEN_BUTTON_TEXTURE if selected else HINT_REMOVE_BUTTON_TEXTURE
	_stage_texture_button(rect, Callable(self, "_set_settings_language").bind(language_code), texture, HINT_OPEN_BUTTON_TEXTURE, label_text, 18)

func _set_settings_language(language_code: String) -> void:
	GameState.set_language(language_code)
	Database.load_language(GameState.language)
	show_settings()

func _remove_settings_popup() -> void:
	_remove_about_popup()
	var popup_nodes: Array = get_tree().get_nodes_in_group("settings_popup")
	for node: Node in popup_nodes:
		if is_instance_valid(node) and node.get_parent() != null:
			node.get_parent().remove_child(node)
			node.queue_free()

func _settings_sound_label() -> String:
	return Database.tr_text(73, "Sounds and music")

func _settings_vibration_label() -> String:
	return Database.tr_text(69, "Vibration")

func _settings_word_base_label() -> String:
	return Database.tr_text(15, "Database:")

func _settings_on_label() -> String:
	return Database.tr_text(82, "On")

func _settings_off_label() -> String:
	return Database.tr_text(83, "Off")

func _settings_about_label() -> String:
	return Database.tr_text(13, "About")

func _settings_remove_ads_label() -> String:
	return Database.tr_text(70, "Remove ads")

func _settings_about_action() -> void:
	_show_about_popup()

func _show_about_popup() -> void:
	_remove_about_popup()
	var previous_content: Control = content

	var popup_layer := CanvasLayer.new()
	popup_layer.name = "AboutPopupCanvas"
	popup_layer.layer = 110
	popup_layer.add_to_group("about_popup")
	add_child(popup_layer)

	var popup_root := Control.new()
	popup_root.name = "AboutPopupLayer"
	popup_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup_root.mouse_filter = Control.MOUSE_FILTER_STOP
	popup_layer.add_child(popup_root)
	content = popup_root

	_add_fullscreen_modal_backdrop(Callable(self, "_remove_about_popup"), 0.38)
	content = _center_popup_content(popup_root, 0.0, 370.0)

	var popup_x: float = 56.0
	var popup_width: float = 648.0
	var header := _stage_panel(Rect2(popup_x, 0.0, popup_width, 88.0), Color(0.2706, 0.3098, 0.6078, 1.0))
	header.mouse_filter = Control.MOUSE_FILTER_STOP
	var body := _stage_panel(Rect2(popup_x, 88.0, popup_width, 282.0), Color(0.2314, 0.2627, 0.5176, 1.0))
	body.mouse_filter = Control.MOUSE_FILTER_STOP
	var top_separator := _stage_panel(Rect2(popup_x, 88.0, popup_width, 2.0), Color(0.8157, 0.5647, 0.3412, 1.0))
	top_separator.mouse_filter = Control.MOUSE_FILTER_STOP
	var middle_separator := _stage_panel(Rect2(popup_x + 408.0, 160.0, 2.0, 128.0), Color(0.3157, 0.3765, 0.6902, 0.95))
	middle_separator.mouse_filter = Control.MOUSE_FILTER_STOP

	var title_label := _stage_label(Rect2(popup_x + 21.0, 12.0, 430.0, 50.0), _about_title_label(), 32, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.clip_text = false
	_stage_round_button(Rect2(popup_x + popup_width - 146.0, 12.0, ROUND_BUTTON_SIZE.x, ROUND_BUTTON_SIZE.y), Callable(self, "_remove_about_popup"), "←")
	_stage_round_button(Rect2(popup_x + popup_width - 68.0, 12.0, ROUND_BUTTON_SIZE.x, ROUND_BUTTON_SIZE.y), Callable(self, "_close_about_and_settings"), "×")

	var author_label := _stage_label(Rect2(popup_x + 78.0, 160.0, 300.0, 78.0), _about_author_text(), 22, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	author_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	author_label.clip_text = false
	var version_label := _stage_label(Rect2(popup_x + 78.0, 255.0, 260.0, 38.0), _about_version_text(), 22, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	version_label.clip_text = false

	_stage_label(Rect2(popup_x + 462.0, 160.0, 150.0, 38.0), _about_contacts_label(), 22, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_round_icon_button(Rect2(popup_x + 436.0, 208.0, ROUND_BUTTON_SIZE.x, ROUND_BUTTON_SIZE.y), Callable(self, "_about_contact_action").bind("vk"), ABOUT_VK_ICON, Vector2(24.0, 14.0))
	_stage_round_icon_button(Rect2(popup_x + 516.0, 208.0, ROUND_BUTTON_SIZE.x, ROUND_BUTTON_SIZE.y), Callable(self, "_about_contact_action").bind("mail"), ABOUT_MAIL_ICON, Vector2(22.0, 18.0))

	content = previous_content

func _remove_about_popup() -> void:
	var popup_nodes: Array = get_tree().get_nodes_in_group("about_popup")
	for node: Node in popup_nodes:
		if is_instance_valid(node) and node.get_parent() != null:
			node.get_parent().remove_child(node)
			node.queue_free()

func _close_about_and_settings() -> void:
	_remove_about_popup()
	_remove_settings_popup()

func _about_title_label() -> String:
	return Database.tr_text(13, "About")

func _about_author_text() -> String:
	return Database.tr_text(24, "Author:") + " " + Database.tr_text(22, "Nikita Lukanin") + "\n" + Database.tr_text(71, "Bruno Philippsen")

func _about_version_text() -> String:
	return Database.tr_text(23, "Version:") + " 3.0.0"

func _about_contacts_label() -> String:
	return Database.tr_text(25, "Contacts:")

func _about_contact_action(_contact_type: String) -> void:
	pass

func _settings_remove_ads_action() -> void:
	pass

func _toggle_language() -> void:
	GameState.set_language("en" if GameState.language == "ru" else "ru")
	Database.load_language(GameState.language)
	show_settings()

func _cycle_difficulty() -> void:
	GameState.settings[2] = (int(GameState.settings[2]) + 1) % 3
	GameState.save_game()
	show_settings()

func _toggle_setting(index: int) -> void:
	GameState.settings[index] = 1 if int(GameState.settings[index]) == 2 else 2
	if index == 4 and int(GameState.settings[index]) == 2:
		Input.vibrate_handheld(400)
	GameState.save_game()
	show_settings()

func _on_off(value: Variant) -> String:
	return Database.tr_text(82, "On") if int(value) == 2 else Database.tr_text(83, "Off")

func _difficulty_name() -> String:
	match int(GameState.settings[2]):
		2:
			return Database.tr_text(62, "EASY")
		1:
			return Database.tr_text(61, "HARD")
		_:
			return Database.tr_text(60, "GENERAL")

func _difficulty_star_texture(value: int = -1) -> Texture2D:
	var difficulty: int = int(GameState.settings[2]) if value < 0 else value
	match difficulty:
		2:
			return DIFFICULTY_STARS_1_TEXTURE
		1:
			return DIFFICULTY_STARS_3_TEXTURE
		_:
			return DIFFICULTY_STARS_2_TEXTURE

func show_theme_select() -> void:
	_remove_difficulty_popup()
	# Build the category screen without the converted GameTemi symbol. That
	# symbol already contains legacy Flash buttons, which were visible below the
	# runtime round buttons and caused the doubled-button artefact.
	_clear("")
	_stage_texture_fill(0.0, 480.0, MENU_PAPER_COVER)
	# Keep the header height in stage coordinates while filling the real viewport.
	_stage_horizontal_fill(0.0, 86.0, Color(0.2706, 0.3098, 0.6078, 1.0))
	_stage_label(Rect2(60.0, 19.0, 500.0, 50.0), Database.tr_text(32, "Choose the category:"), 30, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	var difficulty_button_rect: Rect2 = HEADER_ACTION_BUTTON_RECT
	var difficulty_texture: Texture2D = _difficulty_star_texture()
	_stage_round_icon_button(difficulty_button_rect, Callable(self, "_show_difficulty_popup"), difficulty_texture, difficulty_texture.get_size())
	_stage_round_button(HEADER_CLOSE_BUTTON_RECT, Callable(self, "show_menu"), "×")

	for i in range(Database.get_theme_count()):
		if i >= 9:
			break
		var col: int = i % 3
		var row: int = int(i / 3)
		var x: float = 26.0 + float(col) * 262.0
		var y: float = 125.0 + float(row) * 113.0
		var words_count: int = Database.get_words_by_index(i, GameState.settings[2]).size()
		var guessed: int = Database.get_number_of_guessed_words(i, true)
		var disabled: bool = words_count == 0
		var completed: bool = words_count > 0 and guessed >= words_count

		var card := _stage_texture(Rect2(x, y, 239.0, 90.0), THEME_CARD_TEXTURE)
		var progress_back := _stage_texture(Rect2(x, y, 239.0, 65.0), THEME_CARD_PROGRESS_TEXTURE)
		var progress_text: String = (
			Database.tr_text(33, "All words are guessed")
			if completed
			else Database.tr_text(34, "Guessed") + ": " + str(guessed) + " " + Database.tr_text(35, "of") + " " + str(words_count)
		)
		var progress_label := _stage_label(Rect2(x + 11.0, y + 7.0, 217.0, 30.0), progress_text, 15, Color(0.43, 0.49, 0.83, 1.0))
		progress_label.clip_text = false
		progress_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.0))
		progress_label.add_theme_constant_override("outline_size", 0)
		var progress_holder := progress_label.get_parent() as Control
		if progress_holder != null:
			progress_holder.z_index = 10

		var title_label := _stage_label(Rect2(x + 8.0, y + 45.0, 223.0, 37.0), Database.get_theme_name(i).to_upper(), 21, Color.WHITE)
		title_label.clip_text = false
		title_label.add_theme_color_override("font_outline_color", Color(0.42, 0.49, 0.82, 1.0))
		title_label.add_theme_constant_override("outline_size", 2)
		var title_holder := title_label.get_parent() as Control
		if title_holder != null:
			title_holder.z_index = 11

		if disabled:
			card.modulate = Color(1.0, 1.0, 1.0, 0.45)
			progress_back.modulate = Color(1.0, 1.0, 1.0, 0.45)
			progress_label.modulate = Color(1.0, 1.0, 1.0, 0.45)
			title_label.modulate = Color(1.0, 1.0, 1.0, 0.45)

		var action: Callable = Callable(self, "_show_clear_theme_popup").bind(i) if completed else Callable(self, "start_classic_game").bind(i)
		var theme_button := _stage_button(Rect2(x, y, 239.0, 90.0), action, "")
		theme_button.disabled = disabled

func _show_clear_theme_popup(theme_index: int) -> void:
	_remove_clear_theme_popup()
	var previous_content: Control = content
	var popup_layer := CanvasLayer.new()
	popup_layer.name = "ClearThemePopupCanvas"
	popup_layer.layer = 125
	popup_layer.add_to_group("clear_theme_popup")
	add_child(popup_layer)

	var popup_root := Control.new()
	popup_root.name = "ClearThemePopupLayer"
	popup_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup_root.mouse_filter = Control.MOUSE_FILTER_STOP
	popup_layer.add_child(popup_root)
	content = popup_root

	_add_fullscreen_modal_backdrop(Callable(self, "_remove_clear_theme_popup"))
	content = _center_popup_content(popup_root, 92.0, 336.0)
	var popup_x: float = 160.0
	var popup_width: float = 480.0
	var header := _stage_panel(Rect2(popup_x, 92.0, popup_width, 82.0), Color(0.2706, 0.3098, 0.6078, 1.0))
	header.mouse_filter = Control.MOUSE_FILTER_STOP
	var body := _stage_panel(Rect2(popup_x, 174.0, popup_width, 162.0), Color(0.2314, 0.2627, 0.5176, 1.0))
	body.mouse_filter = Control.MOUSE_FILTER_STOP
	_stage_panel(Rect2(popup_x, 172.0, popup_width, 2.0), Color(0.8157, 0.5647, 0.3412, 1.0))
	var question := Database.tr_text(29, "Clear the category?") + "\n" + Database.get_theme_name(theme_index).to_upper()
	var question_label := _stage_label(Rect2(popup_x + 32.0, 101.0, popup_width - 64.0, 62.0), question, 25, Color.WHITE)
	question_label.clip_text = false
	_stage_main_button(Rect2(popup_x + 28.0, 238.0, MENU_BUTTON_SIZE.x, MENU_BUTTON_SIZE.y), Callable(self, "_confirm_clear_theme").bind(theme_index), Database.tr_text(30, "Yes"), 20)
	_stage_main_button(Rect2(popup_x + popup_width - 240.0, 238.0, MENU_BUTTON_SIZE.x, MENU_BUTTON_SIZE.y), Callable(self, "_remove_clear_theme_popup"), Database.tr_text(31, "No"), 20)
	content = previous_content

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

func _show_difficulty_popup() -> void:
	_remove_difficulty_popup()
	var previous_content: Control = content

	# A dedicated CanvasLayer keeps every popup element above the category
	# cards. Adding the popup root to RuntimeUI allowed stage controls with their
	# own z-index to bleed through the dark body on some layouts.
	var popup_layer := CanvasLayer.new()
	popup_layer.name = "ThemeDifficultyPopupCanvas"
	popup_layer.layer = 120
	popup_layer.add_to_group("difficulty_popup")
	add_child(popup_layer)

	var popup_root := Control.new()
	popup_root.name = "ThemeDifficultyPopupLayer"
	popup_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup_root.mouse_filter = Control.MOUSE_FILTER_STOP
	popup_layer.add_child(popup_root)
	content = popup_root

	_add_fullscreen_modal_backdrop(Callable(self, "_remove_difficulty_popup"))
	content = _center_popup_content(popup_root, 0.0, 250.0)

	var popup_x: float = 40.0
	var popup_width: float = 720.0
	var header := _stage_panel(Rect2(popup_x, 0.0, popup_width, 76.0), Color(0.2706, 0.3098, 0.6078, 1.0))
	header.mouse_filter = Control.MOUSE_FILTER_STOP
	var body := _stage_panel(Rect2(popup_x, 76.0, popup_width, 174.0), Color(0.2314, 0.2627, 0.5176, 1.0))
	body.mouse_filter = Control.MOUSE_FILTER_STOP
	var separator := _stage_panel(Rect2(popup_x, 76.0, popup_width, 2.0), Color(0.8157, 0.5647, 0.3412, 1.0))
	separator.mouse_filter = Control.MOUSE_FILTER_STOP
	_stage_label(Rect2(popup_x + 34.0, 18.0, 520.0, 42.0), Database.tr_text(63, "Choose the difficulty level:"), 28, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_round_button(Rect2(popup_x + popup_width - 68.0, 10.0, 68.0, 68.0), Callable(self, "_remove_difficulty_popup"), "×")

	var column_separators := [popup_x + 240.0, popup_x + 480.0]
	for sep_x in column_separators:
		var divider := _stage_panel(Rect2(sep_x, 94.0, 2.0, 126.0), Color(0.32, 0.39, 0.69, 0.95))
		divider.mouse_filter = Control.MOUSE_FILTER_STOP
	var top_rule := _stage_panel(Rect2(popup_x + 34.0, 131.0, popup_width - 68.0, 2.0), Color(0.32, 0.39, 0.69, 0.95))
	top_rule.mouse_filter = Control.MOUSE_FILTER_STOP

	var options := [
		{
			"value": 2,
			"title": Database.tr_key(&"DIFFICULTY_EASY", "ПРОСТОЙ"),
			"desc": [Database.tr_text(36, "Hints:") + " 2", Database.tr_text(54, "First and last letter"), Database.tr_text(55, "Easy words")],
			"x": popup_x + 24.0
		},
		{
			"value": 1,
			"title": Database.tr_key(&"DIFFICULTY_HARD", "СЛОЖНЫЙ"),
			"desc": [Database.tr_text(36, "Hints:") + " 1", Database.tr_text(56, "Hard words")],
			"x": popup_x + 264.0
		},
		{
			"value": 0,
			"title": Database.tr_key(&"DIFFICULTY_GENERAL", "ОБЩИЙ"),
			"desc": [Database.tr_text(36, "Hints:") + " 2", Database.tr_text(57, "All words")],
			"x": popup_x + 504.0
		},
	]

	for option in options:
		var base_x: float = float(option["x"])
		var value: int = int(option["value"])
		var selected: bool = value == int(GameState.settings[2])
		var title_label := _stage_label(Rect2(base_x, 96.0, 190.0, 30.0), String(option["title"]), 20, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
		title_label.clip_text = false
		title_label.add_theme_color_override("font_outline_color", Color(0.23, 0.26, 0.52, 0.0))
		title_label.add_theme_constant_override("outline_size", 0)
		var title_holder := title_label.get_parent() as Control
		if title_holder != null:
			title_holder.z_index = 20

		var hit_area := _stage_button(Rect2(base_x - 8.0, 138.0, 210.0, 88.0), Callable(self, "_set_difficulty_from_popup").bind(value), "")
		hit_area.mouse_filter = Control.MOUSE_FILTER_STOP
		var option_button_rect := Rect2(base_x, 148.0, 68.0, 68.0)
		var option_texture: Texture2D = _difficulty_star_texture(value)
		_stage_round_icon_button(option_button_rect, Callable(self, "_set_difficulty_from_popup").bind(value), option_texture, option_texture.get_size(), false, selected)

		var desc: Array = option["desc"] as Array
		var text_y: float = 154.0
		for line in desc:
			var line_label := _stage_label(Rect2(base_x + 88.0, text_y, 130.0, 24.0), String(line), 17, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
			line_label.add_theme_color_override("font_outline_color", Color(0.23, 0.26, 0.52, 0.0))
			line_label.add_theme_constant_override("outline_size", 0)
			text_y += 24.0

	content = previous_content

func _set_difficulty_from_popup(value: int) -> void:
	GameState.settings[2] = value
	GameState.save_game()
	_remove_difficulty_popup()
	show_theme_select()

func _remove_difficulty_popup() -> void:
	var popup_nodes: Array = get_tree().get_nodes_in_group("difficulty_popup")
	for node: Node in popup_nodes:
		if is_instance_valid(node) and node.get_parent() != null:
			node.get_parent().remove_child(node)
			node.queue_free()

func _cycle_difficulty_and_return_theme() -> void:
	_show_difficulty_popup()

func clear_theme_progress(theme_index: int) -> void:
	WordManager.clear_the_theme(theme_index)
	show_theme_select()

func start_classic_game(theme_index: int) -> void:
	word_info_visible = false
	game_finished = false
	last_result_data = {}
	GameState.current_mode = 0
	GameState.current_score = 0
	GameState.current_time_left = 180
	GameState.time_attack_round = 1
	GameState.correct_guess_streak = 0
	GameSession.start_new_round(theme_index, 0)
	GameState.save_game()
	show_game_screen()

func _show_time_attack_popup() -> void:
	_remove_time_attack_popup()
	var previous_content: Control = content

	var popup_layer := CanvasLayer.new()
	popup_layer.name = "TimeAttackPopupCanvas"
	popup_layer.layer = 115
	popup_layer.add_to_group("time_attack_popup")
	add_child(popup_layer)

	var popup_root := Control.new()
	popup_root.name = "TimeAttackPopupLayer"
	popup_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup_root.mouse_filter = Control.MOUSE_FILTER_STOP
	popup_layer.add_child(popup_root)
	content = popup_root

	_add_fullscreen_modal_backdrop(Callable(self, "_remove_time_attack_popup"))
	content = _center_popup_content(popup_root, 0.0, 340.0)

	var popup_x: float = 70.0
	var popup_width: float = 660.0
	var header := _stage_panel(Rect2(popup_x, 0.0, popup_width, 87.0), Color(0.2706, 0.3098, 0.6078, 1.0))
	header.mouse_filter = Control.MOUSE_FILTER_STOP
	var body := _stage_panel(Rect2(popup_x, 87.0, popup_width, 253.0), Color(0.2314, 0.2627, 0.5176, 1.0))
	body.mouse_filter = Control.MOUSE_FILTER_STOP
	var top_separator := _stage_panel(Rect2(popup_x, 87.0, popup_width, 2.0), Color(0.8157, 0.5647, 0.3412, 1.0))
	top_separator.mouse_filter = Control.MOUSE_FILTER_STOP
	var bottom_separator := _stage_panel(Rect2(popup_x + 35.0, 259.0, popup_width - 70.0, 2.0), Color(0.3157, 0.3765, 0.6902, 0.95))
	bottom_separator.mouse_filter = Control.MOUSE_FILTER_STOP

	var title_label := _stage_label(Rect2(popup_x + 21.0, 12.0, 420.0, 50.0), tr("TIME_ATTACK_MODE"), 32, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	title_label.clip_text = false

	var difficulty_button_rect := Rect2(popup_x + popup_width - 146.0, 12.0, ROUND_BUTTON_SIZE.x, ROUND_BUTTON_SIZE.y)
	var difficulty_texture: Texture2D = _difficulty_star_texture()
	_stage_round_icon_button(difficulty_button_rect, Callable(self, "_cycle_time_attack_difficulty"), difficulty_texture, difficulty_texture.get_size())
	_stage_round_button(Rect2(popup_x + popup_width - 68.0, 12.0, ROUND_BUTTON_SIZE.x, ROUND_BUTTON_SIZE.y), Callable(self, "_remove_time_attack_popup"), "×")

	# Original Flash badge assembled from its separate bitmap layers.
	# Draw in source order: blue outer backing, white inner badge, hourglass.
	_stage_texture(Rect2(popup_x + 118.0, 112.0, 133.0, 133.0), TIME_ATTACK_BADGE_OUTER_TEXTURE)
	_stage_texture(Rect2(popup_x + 129.0, 123.0, 111.0, 111.0), HERO_BADGE_RING_TEXTURE)
	_stage_texture(Rect2(popup_x + 165.5, 155.5, 38.0, 46.0), TIME_ATTACK_HOURGLASS_TEXTURE)

	var description_label := _stage_label(Rect2(popup_x + 315.0, 116.0, 285.0, 128.0), tr("TIME_ATTACK_DESCRIPTION"), 18, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	description_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	description_label.clip_text = true

	var record_text: String = tr("RECORD_LABEL") + " " + str(int(GameState.records[2][2]))
	var record_label := _stage_score_with_star(Rect2(popup_x + 54.0, 275.0, 240.0, 38.0), record_text, 21, Color.WHITE)
	record_label.clip_text = false
	_stage_main_button(Rect2(popup_x + 333.0, 276.0, MENU_BUTTON_SIZE.x, MENU_BUTTON_SIZE.y), Callable(self, "_start_time_attack_from_popup"), tr("START"), 20)

	content = previous_content

func _cycle_time_attack_difficulty() -> void:
	GameState.settings[2] = (int(GameState.settings[2]) + 1) % 3
	GameState.save_game()
	_show_time_attack_popup()

func _start_time_attack_from_popup() -> void:
	_remove_time_attack_popup()
	start_time_attack()

func _remove_time_attack_popup() -> void:
	var popup_nodes: Array = get_tree().get_nodes_in_group("time_attack_popup")
	for node: Node in popup_nodes:
		if is_instance_valid(node) and node.get_parent() != null:
			node.get_parent().remove_child(node)
			node.queue_free()

func start_time_attack() -> void:
	word_info_visible = false
	game_finished = false
	last_result_data = {}
	GameState.current_mode = 1
	GameState.current_score = 0
	GameState.current_time_left = 180
	GameState.time_attack_round = 1
	GameState.correct_guess_streak = 0
	GameState.records[2][0] = 0
	GameSession.start_new_round(-1, 1)
	GameState.save_game()
	show_game_screen()
	game_timer.start()

func show_custom_word() -> void:
	game_timer.stop()
	_clear("")

	# SlovMov.as draws the screen from three simple areas: a 114 px blue header,
	# the graph-paper settings area, and a blue footer matching the gameplay screen.
	# Rebuild those areas directly instead of displaying the converted SlovMov
	# scene, which contains duplicate text fields and broken bitmap fragments.
	_stage_texture_fill(0.0, 480.0, MENU_PAPER_COVER)
	_stage_horizontal_fill(0.0, 114.0, Color(0.2706, 0.3098, 0.6078, 1.0))
	_stage_horizontal_fill(387.0, 93.0, Color(0.2706, 0.3098, 0.6078, 1.0))

	# Original input field: Head is shifted by -50 and InputTxt is created at
	# x = 105, y = 27 with width 567, producing this stage-space white capsule.
	_stage_panel(Rect2(55.0, 27.0, 567.0, 54.0), Color.WHITE, 27.0, Color(0.78, 0.80, 0.86, 1.0), 2.0)
	custom_word_edit = _stage_line_edit(Rect2(76.0, 31.0, 525.0, 46.0), Database.tr_text(41, "Input the word"))
	custom_word_edit.max_length = 35
	custom_word_edit.text = custom_word_text
	custom_word_edit.alignment = HORIZONTAL_ALIGNMENT_LEFT
	custom_word_edit.add_theme_font_size_override("font_size", 26)
	custom_word_edit.add_theme_color_override("font_color", Color(0.23, 0.26, 0.52, 1.0))
	custom_word_edit.add_theme_color_override("font_placeholder_color", Color(0.40, 0.43, 0.63, 0.70))
	custom_word_edit.text_changed.connect(_on_custom_word_text_changed)

	_stage_label(Rect2(49.0, 78.0, 245.0, 28.0), _custom_word_max_length_label(), 20, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_label(Rect2(428.0, 78.0, 194.0, 28.0), _custom_word_random_label(), 20, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
	_stage_round_icon_button(HEADER_ACTION_BUTTON_RECT, Callable(self, "_set_random_custom_word"), CUSTOM_WORD_RANDOM_ICON, Vector2(32.0, 27.0))
	# Use the same round close button treatment as on the guessing screen so the
	# close icon has the same look and no deformation.
	_stage_round_button(HEADER_CLOSE_BUTTON_RECT, Callable(self, "show_menu"), "×")

	_stage_label(Rect2(66.0, 151.0, 260.0, 49.0), Database.tr_text(27, "First and last letter"), 22, Color(0.27, 0.31, 0.61, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	_stage_custom_switch(Rect2(347.0, 151.0, 102.0, 49.0), 0)
	_stage_label(Rect2(66.0, 213.0, 260.0, 49.0), Database.tr_text(28, "Hints"), 22, Color(0.27, 0.31, 0.61, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	_stage_custom_switch(Rect2(347.0, 213.0, 102.0, 49.0), 1)

	_stage_main_button(Rect2(511.0, 151.0, MENU_BUTTON_SIZE.x, MENU_BUTTON_SIZE.y), Callable(self, "_check_custom_word_now"), Database.tr_text(68, "Check the word"), 20)
	_stage_main_button(Rect2(511.0, 213.0, MENU_BUTTON_SIZE.x, MENU_BUTTON_SIZE.y), Callable(self, "_show_custom_comment_popup"), Database.tr_text(47, "Comment"), 20)
	var check_color := Color.WHITE
	if custom_word_check_state == 2:
		check_color = Color(0.58, 0.88, 0.72)
	elif custom_word_check_state == 3:
		check_color = Color(0.96, 0.67, 0.77)
	custom_word_check_label = _stage_label(Rect2(497.0, 267.0, 240.0, 34.0), custom_word_check_text, 16, check_color)
	_stage_main_button(Rect2(511.0, 404.0, MENU_BUTTON_SIZE.x, MENU_BUTTON_SIZE.y), Callable(self, "start_custom_game"), _custom_word_start_label(), 20)

func _stage_custom_switch(rect: Rect2, setting_index: int) -> void:
	var enabled: bool = int(GameState.settings[setting_index]) == 2
	var normal_texture: Texture2D = HINT_OPEN_BUTTON_TEXTURE if enabled else HINT_REMOVE_BUTTON_TEXTURE
	_stage_texture_button(rect, Callable(self, "_toggle_custom_setting").bind(setting_index), normal_texture, HINT_OPEN_BUTTON_TEXTURE, _custom_switch_label(enabled), 20)

func _custom_switch_label(enabled: bool) -> String:
	return Database.tr_text(82, "On") if enabled else Database.tr_text(83, "Off")

func _custom_word_max_length_label() -> String:
	return Database.tr_text(84, "Max. 35 characters")

func _custom_word_random_label() -> String:
	return Database.tr_text(85, "Random word")

func _custom_word_start_label() -> String:
	return Database.tr_text(86, "Start game")

func _on_custom_word_text_changed(value: String) -> void:
	_cancel_custom_word_check()
	custom_word_check_state = 0
	custom_word_check_text = ""
	if custom_word_check_label != null:
		custom_word_check_label.text = ""
	custom_word_text = _normalize_custom_word_input(value)
	if custom_word_edit != null and custom_word_edit.text != custom_word_text:
		var caret_column: int = custom_word_edit.caret_column
		custom_word_edit.text = custom_word_text
		custom_word_edit.caret_column = mini(caret_column, custom_word_edit.text.length())
	if custom_word_edit != null:
		custom_word_edit.add_theme_color_override("font_color", Color(0.23, 0.26, 0.52, 1.0))

func _normalize_custom_word_input(value: String) -> String:
	var normalized: String = value.to_upper().replace("-", "—").replace("Ё", "Е")
	var filtered: String = ""
	for i: int in range(normalized.length()):
		var character: String = normalized.substr(i, 1)
		var code: int = character.unicode_at(0)
		var is_supported_letter: bool = (code >= 0x41 and code <= 0x5A) or (code >= 0x410 and code <= 0x42F)
		if is_supported_letter:
			filtered += character
		elif character == " " or character == "—":
			# TextBlock.CheckLast() in the FLA prevents leading and consecutive
			# separators while the word is being typed.
			if filtered != "" and filtered.right(1) != " " and filtered.right(1) != "—":
				filtered += character
	return filtered.substr(0, 35)

func _toggle_custom_setting(index: int) -> void:
	if custom_word_edit != null:
		custom_word_text = custom_word_edit.text
	GameState.settings[index] = 1 if int(GameState.settings[index]) == 2 else 2
	GameState.save_game()
	show_custom_word()

func _set_random_custom_word() -> void:
	var theme_count: int = Database.get_theme_count()
	if theme_count <= 0:
		return
	for _attempt in range(theme_count * 2):
		var theme_index: int = randi() % theme_count
		var words: Array = Database.get_words_by_index(theme_index, 0)
		if words.is_empty():
			continue
		var picked: Dictionary = words[randi() % words.size()]
		custom_word_text = WordManager.normalize_word(str(picked.get("text", "")))
		if custom_word_edit != null:
			custom_word_edit.text = custom_word_text
			custom_word_edit.caret_column = custom_word_edit.text.length()
		return

func _check_custom_word_now() -> void:
	if custom_word_edit == null:
		return
	custom_word_text = WordManager.normalize_word(custom_word_edit.text)
	var language_code: String = _custom_word_language(custom_word_text)
	if !_is_valid_custom_word(custom_word_text) or language_code == "":
		custom_word_check_state = 3
		custom_word_check_text = Database.tr_key(&"WORD_NOT_FOUND", "Word is invalid")
		custom_word_edit.add_theme_color_override("font_color", Color(0.62, 0.25, 0.42, 1.0))
		custom_word_edit.placeholder_text = Database.tr_text(72, "Error! Something goes wrong.")
		_update_custom_word_check_label()
		return

	_cancel_custom_word_check()
	custom_word_check_state = 1
	custom_word_check_text = Database.tr_key(&"WORD_CHECKING", "Checking...")
	custom_word_edit.add_theme_color_override("font_color", Color(0.23, 0.26, 0.52, 1.0))
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
	_update_custom_word_check_label()

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
	custom_word_check_state = 2 if found else 3
	if found:
		custom_word_check_text = Database.tr_key(&"WORD_FOUND", "Word found")
	elif network_error:
		custom_word_check_text = Database.tr_key(&"WORD_CHECK_FAILED", "Check failed")
	else:
		custom_word_check_text = Database.tr_key(&"WORD_NOT_FOUND", "Word not found")
	_cancel_custom_word_check()
	if custom_word_edit != null:
		custom_word_edit.add_theme_color_override("font_color", Color(0.22, 0.55, 0.41, 1.0) if found else Color(0.62, 0.25, 0.42, 1.0))
	_update_custom_word_check_label()

func _update_custom_word_check_label() -> void:
	if custom_word_check_label == null or !is_instance_valid(custom_word_check_label):
		return
	custom_word_check_label.text = custom_word_check_text
	var check_color := Color.WHITE
	if custom_word_check_state == 2:
		check_color = Color(0.58, 0.88, 0.72)
	elif custom_word_check_state == 3:
		check_color = Color(0.96, 0.67, 0.77)
	custom_word_check_label.add_theme_color_override("font_color", check_color)

func _cancel_custom_word_check() -> void:
	custom_word_check_urls.clear()
	if custom_word_check_request != null and is_instance_valid(custom_word_check_request):
		custom_word_check_request.cancel_request()
		custom_word_check_request.queue_free()
	custom_word_check_request = null

func _show_custom_comment_popup() -> void:
	_remove_custom_comment_popup()
	if custom_word_edit != null:
		custom_word_text = custom_word_edit.text

	var previous_content: Control = content
	var popup_layer := CanvasLayer.new()
	popup_layer.name = "CustomCommentPopupCanvas"
	popup_layer.layer = 100
	popup_layer.add_to_group("custom_comment_popup")
	add_child(popup_layer)

	var popup_root: Control = Control.new()
	popup_root.name = "CustomCommentPopupLayer"
	popup_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup_root.mouse_filter = Control.MOUSE_FILTER_STOP
	popup_layer.add_child(popup_root)
	content = popup_root

	_add_fullscreen_modal_backdrop(Callable(self, "_save_and_close_custom_comment_popup"))
	content = _center_popup_content(popup_root, 40.0, 358.0)
	var header := _stage_panel(Rect2(70.0, 40.0, 660.0, 82.0), Color(0.2706, 0.3098, 0.6078, 1.0))
	header.mouse_filter = Control.MOUSE_FILTER_STOP
	var body := _stage_panel(Rect2(70.0, 122.0, 660.0, 236.0), Color(0.2314, 0.2627, 0.5176, 1.0))
	body.mouse_filter = Control.MOUSE_FILTER_STOP
	_stage_panel(Rect2(70.0, 120.0, 660.0, 2.0), Color(0.8157, 0.5647, 0.3412, 1.0))
	_stage_label(Rect2(94.0, 55.0, 420.0, 50.0), Database.tr_text(47, "Comment"), 32, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_panel(Rect2(104.0, 151.0, 592.0, 112.0), Color.WHITE, 18.0, Color(0.78, 0.80, 0.86, 1.0), 2.0)
	custom_comment_edit = _stage_text_edit(Rect2(122.0, 165.0, 556.0, 84.0), Database.tr_text(47, "Comment"))
	custom_comment_edit.text = custom_comment_text
	custom_comment_edit.add_theme_font_size_override("font_size", 21)
	custom_comment_edit.add_theme_color_override("font_color", Color(0.23, 0.26, 0.52, 1.0))
	_stage_main_button(Rect2(488.0, 286.0, MENU_BUTTON_SIZE.x, MENU_BUTTON_SIZE.y), Callable(self, "_save_and_close_custom_comment_popup"), Database.tr_text(87, "OK"), 20)
	_stage_round_icon_button(Rect2(646.0, 50.0, ROUND_BUTTON_SIZE.x, ROUND_BUTTON_SIZE.y), Callable(self, "_save_and_close_custom_comment_popup"), RESULT_CLOSE_ICON, Vector2(21.0, 21.0))
	content = previous_content

func _save_and_close_custom_comment_popup() -> void:
	if custom_comment_edit != null:
		custom_comment_text = custom_comment_edit.text.strip_edges()
	_remove_custom_comment_popup()

func _remove_custom_comment_popup() -> void:
	var popup_nodes: Array = get_tree().get_nodes_in_group("custom_comment_popup")
	for node: Node in popup_nodes:
		if is_instance_valid(node) and node.get_parent() != null:
			node.get_parent().remove_child(node)
			node.queue_free()
	custom_comment_edit = null

func start_custom_game() -> void:
	var source_text: String = custom_word_edit.text if custom_word_edit != null else custom_word_text
	var word := WordManager.normalize_word(source_text)
	if !_is_valid_custom_word(word):
		if custom_word_edit != null:
			custom_word_edit.add_theme_color_override("font_color", Color(0.62, 0.25, 0.42, 1.0))
			custom_word_edit.placeholder_text = Database.tr_text(72, "Error! Something goes wrong.")
		return
	custom_word_text = word
	word_info_visible = false
	game_finished = false
	last_result_data = {}
	GameState.current_mode = 2
	GameState.current_score = 0
	GameState.current_time_left = 180
	GameState.time_attack_round = 1
	GameState.correct_guess_streak = 0
	GameSession.start_custom_round(word, custom_comment_text)
	GameState.save_game()
	show_game_screen()

func _is_valid_custom_word(word: String) -> bool:
	if word.length() == 0:
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

func _refresh_game_screen() -> void:
	if content == null:
		return
	if game_finished:
		show_result_screen(last_result_is_win, last_result_data)
		return
	for child: Node in content.get_children():
		content.remove_child(child)
		child.queue_free()

	# GameMov.as creates the header at y=0 and the original AIR runtime moves
	# the hint/comment controls to the bottom safe area.  These elements are not
	# present as static FLA instances, so the Godot layer must rebuild them in
	# stage coordinates instead of using generic text buttons.
	_stage_texture_fill(0.0, 480.0, MENU_PAPER_COVER)
	_stage_horizontal_fill(0.0, 87.0, Color(0.2706, 0.3098, 0.6078, 1.0))
	_stage_horizontal_fill(387.0, 93.0, Color(0.2706, 0.3098, 0.6078, 1.0))

	_stage_label(Rect2(27.0, 22.0, 625.0, 58.0), GameSession.get_masked_word(), 36, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)

	if GameState.current_mode == 2:
		_stage_round_icon_button(HEADER_ACTION_BUTTON_RECT, Callable(self, "_game_header_action"), CUSTOM_WORD_REFRESH_ICON, Vector2(27.0, 27.0))
	else:
		_stage_round_button(HEADER_ACTION_BUTTON_RECT, Callable(self, "_game_header_action"), _game_header_icon())
	_stage_round_button(HEADER_CLOSE_BUTTON_RECT, Callable(self, "show_menu"), "×")

	hero_static_symbol = _stage_symbol(_hero_symbol_path(), Vector2(26.0, 324.0), _hero_animation_time(), 4.0 / 24.0) as FlashStageSymbol

	var alphabet := Database.get_alphabet()
	var keyboard_start_x: float = 258.0
	var keyboard_start_y: float = 138.0
	var keyboard_step_x: float = 65.0
	var keyboard_step_y: float = 58.0
	var marker_size: Vector2 = Vector2(46.0, 46.0)
	for i in range(alphabet.size()):
		var letter: String = alphabet[i]
		var row: int = int(i / 8)
		var col: int = i % 8
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

		var key_rect := Rect2(x, y, KEY_BUTTON_SIZE.x, KEY_BUTTON_SIZE.y)
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
			32,
			marker_size,
			animate_state
		)

	var open_hint_disabled: bool = !GameSession.can_use_open_letter_hint()
	var remove_hint_disabled: bool = !GameSession.can_use_remove_wrong_hint()
	var comment_disabled: bool = GameSession.get_word_hint().strip_edges() == ""

	# Hint buttons match the original Flash behavior and visuals.
	# Orange is the available state. Blue is only the pressed/already-used state.
	_stage_texture_button(Rect2(160.0, 404.0, 102.0, 49.0), Callable(self, "_use_open_hint"), HINT_REMOVE_BUTTON_TEXTURE, HINT_OPEN_BUTTON_TEXTURE, "", 26, open_hint_disabled, HINT_OPEN_BUTTON_TEXTURE, 0.0)
	_stage_texture(Rect2(199.0, 416.0, 25.0, 25.0), HINT_ICON_CHECK_TEXTURE)

	_stage_texture_button(Rect2(272.0, 404.0, 102.0, 49.0), Callable(self, "_use_remove_hint"), HINT_REMOVE_BUTTON_TEXTURE, HINT_OPEN_BUTTON_TEXTURE, "", 26, remove_hint_disabled, HINT_OPEN_BUTTON_TEXTURE, 0.0)
	_stage_texture(Rect2(311.0, 416.0, 25.0, 25.0), HINT_ICON_CROSS_TEXTURE)

	var comment_button := _stage_main_button(Rect2(460.0, 404.0, COMMENT_BUTTON_SIZE.x, COMMENT_BUTTON_SIZE.y), Callable(self, "_show_word_comment_popup"), Database.tr_text(47, "Comment"), 18, comment_disabled, 0.0)
	if comment_disabled:
		comment_button.modulate = Color(1.0, 1.0, 1.0, 0.56)
		var comment_label := comment_button.get_node_or_null("Text") as Label
		if comment_label != null:
			comment_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.82))

	if GameState.current_mode == 1:
		_stage_time_attack_hud()

	pending_letter_marker = ""
	pending_letter_marker_is_correct = false

func _game_header_icon() -> String:
	if GameState.current_mode == 1:
		return "■"
	if GameState.current_mode == 2:
		return "↻"
	return "☰"

func _game_header_action() -> void:
	if GameState.current_mode == 1:
		# The square button ends the whole Time Attack session immediately.
		# This is different from losing a single word: the final result screen
		# cannot be continued and shows the session's final score.
		game_finished = true
		last_result_is_win = false
		last_result_data = GameSession.finish_time_attack_timeout(false)
		game_timer.stop()
		show_result_screen(false, last_result_data)
	elif GameState.current_mode == 2:
		show_custom_word()
	else:
		show_theme_select()


func _stage_time_attack_hud() -> void:
	_stage_score_with_star(Rect2(58.0, 399.0, 150.0, 28.0), str(GameState.current_score), 19, Color.WHITE)
	_stage_texture(Rect2(23.0, 433.0, 26.0, 26.0), TIME_ATTACK_TIMER_ICON_TEXTURE)

	var time_label := _stage_label(Rect2(58.0, 429.0, 150.0, 28.0), _format_time(GameState.current_time_left), 19, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_apply_result_text_glow(time_label, Color(0.2314, 0.2627, 0.5176, 1.0), 2)

func _stage_score_with_star(rect: Rect2, text: String, font_size: int, font_color: Color, text_align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, glow_color: Color = Color(0.2314, 0.2627, 0.5176, 1.0), glow_size: int = 2) -> Label:
	var holder: Control = _stage_holder(rect, Control.MOUSE_FILTER_IGNORE)
	holder.z_index = 25

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 5)
	match text_align:
		HORIZONTAL_ALIGNMENT_CENTER:
			row.alignment = BoxContainer.ALIGNMENT_CENTER
		HORIZONTAL_ALIGNMENT_RIGHT:
			row.alignment = BoxContainer.ALIGNMENT_END
		_:
			row.alignment = BoxContainer.ALIGNMENT_BEGIN
	holder.add_child(row)

	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	_apply_result_text_glow(label, glow_color, glow_size)
	row.add_child(label)

	var star := TextureRect.new()
	star.mouse_filter = Control.MOUSE_FILTER_IGNORE
	star.texture = MAIN_MENU_HOLLOW_STAR_ICON
	star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	star.custom_minimum_size = Vector2(float(font_size), float(font_size))
	star.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(star)
	return label

func _play_hero_wrong_guess_animation(previous_mistakes: int, current_mistakes: int) -> void:
	_clear_hero_animation_overlay()
	if hero_static_symbol != null and is_instance_valid(hero_static_symbol):
		hero_static_symbol.visible = false
	var overlay := FlashStageSymbol.new()
	overlay.name = "HeroAnimationOverlay"
	overlay.z_index = 150
	overlay.symbol_path = _hero_symbol_path()
	overlay.stage_position = Vector2(26.0, 324.0)
	# In the original AS3 HeroTries.Adder(0) does HeroMov.nextFrame().
	# The visible animation is not the one-frame jump on HeroType1/2 itself;
	# it is the nested HeroMov.Mov timeline of the newly selected frame.
	overlay.animation_time = _hero_animation_time_for_mistakes(current_mistakes)
	overlay.nested_animation_time = HERO_MOV_START_FRAME_TIME
	overlay.playback_finished.connect(_on_hero_wrong_guess_animation_finished)
	add_child(overlay)
	hero_animation_overlay = overlay
	overlay.call_deferred("play_nested_range", _hero_animation_time_for_mistakes(current_mistakes), HERO_MOV_START_FRAME_TIME, HERO_MOV_IDLE_FRAME_TIME, HERO_WRONG_GUESS_ANIMATION_SPEED_SCALE)

func _clear_hero_animation_overlay() -> void:
	if hero_animation_overlay != null and is_instance_valid(hero_animation_overlay):
		hero_animation_overlay.queue_free()
	hero_animation_overlay = null
	if hero_static_symbol != null and is_instance_valid(hero_static_symbol):
		hero_static_symbol.visible = true

func _on_hero_wrong_guess_animation_finished() -> void:
	_clear_hero_animation_overlay()

func _hero_animation_time_for_mistakes(mistake_count: int) -> float:
	var frame_index: int = clampi(mistake_count + 1, 1, 6)
	return float(frame_index) / 24.0

func _hero_symbol_path() -> String:
	if GameState.settings.size() > 5 and int(GameState.settings[5]) == 2:
		return HERO_TYPE_2_SYMBOL
	return HERO_TYPE_1_SYMBOL

func _hero_animation_time() -> float:
	# HeroTries.Adder(0) calls nextFrame() immediately, so the first visible
	# gameplay pose is one Flash frame after the default frame.
	return _hero_animation_time_for_mistakes(GameSession.mistakes)

func _press_letter(letter: String) -> void:
	var previous_mistakes: int = GameSession.mistakes
	pending_letter_marker = letter
	pending_letter_marker_is_correct = GameSession.letters.has(letter)
	round_result_delay_requested = true
	GameSession.guess(letter)
	round_result_delay_requested = false
	if GameSession.mistakes > previous_mistakes:
		_play_hero_wrong_guess_animation(previous_mistakes, GameSession.mistakes)

func _use_open_hint() -> void:
	GameSession.use_open_letter_hint()

func _use_remove_hint() -> void:
	GameSession.use_remove_wrong_hint()

func _toggle_word_info() -> void:
	word_info_visible = !word_info_visible
	_refresh_game_screen()

func _give_up() -> void:
	GameSession.give_up()

func _on_round_won() -> void:
	_finish_round(true)

func _on_round_lost() -> void:
	_finish_round(false)

func _finish_round(is_win: bool) -> void:
	if game_finished:
		return

	if GameState.current_mode == 1:
		# Time Attack is one continuous session. Apply the completed word's
		# bonus/penalty, then immediately replace it with a fresh round without
		# stopping the timer or opening the intermediate result screen.
		GameSession.finish_result(is_win)
		word_info_visible = false
		pending_letter_marker = ""
		pending_letter_marker_is_correct = false
		round_result_delay_requested = false
		_clear_hero_animation_overlay()
		last_result_data = {}
		GameSession.start_new_round(-1, 1)
		GameState.save_game()
		return

	game_finished = true
	last_result_is_win = is_win
	last_result_data = GameSession.finish_result(is_win)
	game_timer.stop()

	var transition_generation: int = result_transition_generation
	if round_result_delay_requested:
		await get_tree().create_timer(LETTER_MARKER_REVEAL_DURATION).timeout
		if transition_generation != result_transition_generation:
			return
	show_result_screen(is_win, last_result_data)

func show_result_screen(is_win: bool, data: Dictionary = {}) -> void:
	game_timer.stop()
	# The original result screen is not a centered modal. ReztMovBlock keeps the
	# game stage visible, replaces the header word with the full answer, shows
	# the hero's current pose on the left and slides only the bottom action bar in.
	_clear("")

	_stage_texture_fill(0.0, 480.0, MENU_PAPER_COVER)
	_stage_horizontal_fill(0.0, 87.0, Color(0.2706, 0.3098, 0.6078, 1.0))
	_stage_horizontal_fill(387.0, 93.0, Color(0.2706, 0.3098, 0.6078, 1.0))

	var full_word: String = _spaced_result_word(GameSession.get_full_word())
	_stage_label(Rect2(27.0, 22.0, 585.0, 58.0), full_word, 36, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)

	_stage_round_icon_button(HEADER_ACTION_BUTTON_RECT, Callable(self, "_open_word_search"), RESULT_SEARCH_ICON, Vector2(18.0, 23.0))
	_stage_round_icon_button(HEADER_CLOSE_BUTTON_RECT, Callable(self, "show_menu"), RESULT_CLOSE_ICON, Vector2(18.0, 18.0))

	hero_static_symbol = _stage_symbol(_hero_symbol_path(), Vector2(26.0, 324.0), _hero_animation_time(), HERO_MOV_IDLE_FRAME_TIME) as FlashStageSymbol

	# A completed Time Attack session has its own final result state. It is not
	# a normal defeat and therefore uses "Game over" instead of "Defeat".
	var time_attack_finished: bool = (
		GameState.current_mode == 1
		and bool(data.get("time_attack_finished", false))
	)
	var title: String
	if time_attack_finished:
		title = str(data.get("title", Database.tr_text(39, "GAME OVER"))).strip_edges()
		if title == "":
			title = Database.tr_text(39, "GAME OVER")
	else:
		title = Database.tr_text(37 if is_win else 38, "VICTORY" if is_win else "DEFEAT").strip_edges()
		if title == "":
			title = "VICTORY" if is_win else "DEFEAT"
	var title_label := _stage_label(Rect2(365.0, 128.0, 365.0, 72.0), title, 42, Color(0.8157, 0.5647, 0.3412), HORIZONTAL_ALIGNMENT_CENTER)
	title_label.clip_text = false
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.z_index = 31
	var title_holder := title_label.get_parent() as Control
	if title_holder != null:
		title_holder.z_index = 30
	_apply_result_text_glow(title_label, Color.WHITE, 3)

	if time_attack_finished:
		var final_score: int = int(data.get("final_score", GameState.current_score))
		var final_score_text: String = Database.tr_key(&"FINAL_SCORE", "Final score:") + " " + str(final_score)
		var final_score_label := _stage_score_with_star(Rect2(395.0, 198.0, 307.0, 38.0), final_score_text, 24, Color(0.2706, 0.3098, 0.6078), HORIZONTAL_ALIGNMENT_CENTER, Color.WHITE, 2)
		final_score_label.clip_text = false

		var final_details: String = _result_data_lines(data)
		if final_details != "":
			var details_label := _stage_label(Rect2(395.0, 241.0, 307.0, 54.0), final_details, 19, Color(0.2706, 0.3098, 0.6078), HORIZONTAL_ALIGNMENT_CENTER)
			details_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
			_apply_result_text_glow(details_label, Color.WHITE, 2)
	else:
		var result_score_line: String = _result_score_line(data)
		if result_score_line != "":
			var score_line_label := _stage_score_with_star(Rect2(395.0, 193.0, 307.0, 34.0), result_score_line, 21, Color(0.2706, 0.3098, 0.6078), HORIZONTAL_ALIGNMENT_CENTER, Color.WHITE, 2)
			score_line_label.clip_text = false
			var remaining_message: String = _result_non_score_lines(data)
			if remaining_message != "":
				var remaining_label := _stage_label(Rect2(395.0, 229.0, 307.0, 42.0), remaining_message, 19, Color(0.2706, 0.3098, 0.6078), HORIZONTAL_ALIGNMENT_CENTER)
				remaining_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
				_apply_result_text_glow(remaining_label, Color.WHITE, 2)
		else:
			var result_message: String = _result_message(is_win, data)
			var message_label := _stage_label(Rect2(395.0, 193.0, 307.0, 67.0), result_message, 21, Color(0.2706, 0.3098, 0.6078), HORIZONTAL_ALIGNMENT_CENTER)
			message_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
			_apply_result_text_glow(message_label, Color.WHITE, 2)

	var show_theme_label: bool = GameState.current_mode == 0
	if show_theme_label:
		var theme_label := _stage_label(Rect2(395.0, 306.0, 307.0, 30.0), _result_theme_label(), 21, Color(0.2706, 0.3098, 0.6078), HORIZONTAL_ALIGNMENT_CENTER)
		_apply_result_text_glow(theme_label, Color.WHITE, 2)

	var show_left_button: bool = GameState.current_mode != 1 and GameState.current_mode != 2
	if show_left_button:
		var left_disabled: bool = GameSession.theme_id < 0 or GameState.current_mode == 2
		var left_button := _stage_main_button(Rect2(161.0, 404.0, MENU_BUTTON_SIZE.x, MENU_BUTTON_SIZE.y), Callable(self, "_result_left_action"), _result_left_button_text(), 18, left_disabled, 0.0)
		if left_disabled:
			left_button.modulate = Color(1.0, 1.0, 1.0, 0.58)
			var left_label := left_button.get_node_or_null("Text") as Label
			if left_label != null:
				left_label.add_theme_color_override("font_color", Color.WHITE)

	_stage_main_button(Rect2(435.0, 404.0, MENU_BUTTON_SIZE.x, MENU_BUTTON_SIZE.y), Callable(self, "_result_right_action"), _result_right_button_text(), 18)

	# Keep the HUD between ordinary Time Attack rounds, but remove it after the
	# entire session has been ended manually or by the timer reaching zero.
	if GameState.current_mode == 1 and !time_attack_finished:
		_stage_time_attack_hud()

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

func _result_score_line(data: Dictionary) -> String:
	var bonus_prefix: String = Database.tr_key(&"POINTS_GAINED", "Bonus:").strip_edges()
	var penalty_prefix: String = Database.tr_key(&"PENALTY", "Penalty:").strip_edges()
	for raw_line in Array(data.get("lines", [])):
		var line: String = str(raw_line).strip_edges()
		if line.begins_with(bonus_prefix) or line.begins_with(penalty_prefix):
			return line
	return ""

func _result_non_score_lines(data: Dictionary) -> String:
	var score_line: String = _result_score_line(data)
	var lines := PackedStringArray()
	for raw_line in Array(data.get("lines", [])):
		var line: String = str(raw_line).strip_edges()
		if line != "" and line != score_line:
			lines.append(line)
	return "\n".join(lines)

func _result_message(is_win: bool, data: Dictionary) -> String:
	var data_lines: String = _result_data_lines(data)
	if data_lines != "":
		return data_lines
	return Database.tr_text(49 if is_win else 50, "Keep going!" if is_win else "You can do better!")

func _result_theme_label() -> String:
	if GameSession.theme_id < 0:
		return Database.tr_text(46, "No category")
	return Database.tr_text(48, "Category:") + " " + Database.get_theme_name(GameSession.theme_id).to_upper()

func _result_left_button_text() -> String:
	if GameState.current_mode == 1:
		return Database.tr_text(53, "Finish game")
	return Database.tr_text(52, "Change category")

func _result_right_button_text() -> String:
	if GameState.current_mode == 1:
		if _is_time_attack_finished_result():
			return Database.tr_text(10, "Restart")
		return Database.tr_text(4, "Continue")
	if GameSession.theme_id < 0:
		return Database.tr_text(10, "Restart")
	return Database.tr_text(4, "Continue")

func _is_time_attack_finished_result() -> bool:
	return (
		GameState.current_mode == 1
		and bool(last_result_data.get("time_attack_finished", false))
	)

func _result_left_action() -> void:
	if GameState.current_mode == 1:
		show_menu()
	else:
		show_theme_select()

func _result_right_action() -> void:
	if GameState.current_mode == 1:
		if _is_time_attack_finished_result() or GameState.current_time_left <= 0:
			start_time_attack()
		else:
			_continue_time_attack()
	else:
		_restart_last_mode()

func _apply_result_text_glow(label: Label, glow_color: Color, outline_size: int) -> void:
	label.add_theme_color_override("font_outline_color", glow_color)
	label.add_theme_constant_override("outline_size", outline_size)

func _continue_time_attack() -> void:
	word_info_visible = false
	game_finished = false
	GameSession.start_new_round(-1, 1)
	GameState.save_game()
	show_game_screen()
	game_timer.start()

func _restart_last_mode() -> void:
	if GameState.current_mode == 2:
		show_custom_word()
	elif GameState.current_mode == 1:
		start_time_attack()
	else:
		start_classic_game(max(0, GameSession.theme_id))

func show_records() -> void:
	_remove_records_popup()

	var previous_content: Control = content
	var popup_layer := CanvasLayer.new()
	popup_layer.name = "RecordsPopupCanvas"
	popup_layer.layer = 100
	popup_layer.add_to_group("records_popup")
	add_child(popup_layer)

	var popup_root := Control.new()
	popup_root.name = "RecordsPopupLayer"
	popup_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup_root.mouse_filter = Control.MOUSE_FILTER_STOP
	popup_layer.add_child(popup_root)
	content = popup_root

	_add_fullscreen_modal_backdrop(Callable(self, "_remove_records_popup"))
	content = _center_popup_content(popup_root, 0.0, 370.0)

	var popup_x: float = 56.0
	var popup_width: float = 648.0
	var header := _stage_panel(Rect2(popup_x, 0.0, popup_width, 88.0), Color(0.2706, 0.3098, 0.6078, 1.0))
	header.mouse_filter = Control.MOUSE_FILTER_STOP
	var body := _stage_panel(Rect2(popup_x, 88.0, popup_width, 282.0), Color(0.2314, 0.2627, 0.5176, 1.0))
	body.mouse_filter = Control.MOUSE_FILTER_STOP
	var top_separator := _stage_panel(Rect2(popup_x, 88.0, popup_width, 2.0), Color(0.8157, 0.5647, 0.3412, 1.0))
	top_separator.mouse_filter = Control.MOUSE_FILTER_STOP

	var left_separator := _stage_panel(Rect2(popup_x + 174.0, 126.0, 2.0, 220.0), Color(0.3157, 0.3765, 0.6902, 0.95))
	left_separator.mouse_filter = Control.MOUSE_FILTER_STOP
	var right_separator := _stage_panel(Rect2(popup_x + 392.0, 126.0, 2.0, 220.0), Color(0.3157, 0.3765, 0.6902, 0.95))
	right_separator.mouse_filter = Control.MOUSE_FILTER_STOP
	var first_row_separator := _stage_panel(Rect2(popup_x + 28.0, 216.0, popup_width - 56.0, 2.0), Color(0.3157, 0.3765, 0.6902, 0.95))
	first_row_separator.mouse_filter = Control.MOUSE_FILTER_STOP
	var second_row_separator := _stage_panel(Rect2(popup_x + 28.0, 300.0, popup_width - 56.0, 2.0), Color(0.3157, 0.3765, 0.6902, 0.95))
	second_row_separator.mouse_filter = Control.MOUSE_FILTER_STOP

	var title_label := _stage_label(Rect2(popup_x + 21.0, 12.0, 430.0, 50.0), tr("RECORDS_TITLE"), 32, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.clip_text = false

	var crown_button := _stage_round_icon_button(Rect2(popup_x + popup_width - 146.0, 12.0, ROUND_BUTTON_SIZE.x, ROUND_BUTTON_SIZE.y), Callable(), ROUND_BUTTON_CROWN_ICON, Vector2(24.0, 20.0), true, false, Vector2.ZERO, 0.0)
	crown_button.self_modulate = Color(1.0, 1.0, 1.0, 0.55)
	_stage_round_button(Rect2(popup_x + popup_width - 68.0, 12.0, ROUND_BUTTON_SIZE.x, ROUND_BUTTON_SIZE.y), Callable(self, "_remove_records_popup"), "×")

	_stage_record_row(132.0, tr("MENU_CLASSIC"), tr("RECORD_EASY_STREAK"), GameState.records[0][2], tr("RECORD_HARD_STREAK"), GameState.records[0][3], popup_x)
	_stage_record_row(218.0, tr("MENU_TIME_ATTACK"), tr("SCORE"), GameState.records[2][2], tr("VICTORIES_PER_GAME"), GameState.records[2][1], popup_x, true)
	_stage_record_row(302.0, tr("MENU_TWO_PLAYER"), tr("VICTORIES"), GameState.records[1][0], tr("DEFEATS"), GameState.records[1][1], popup_x)

	content = previous_content

func _stage_record_row(row_y: float, mode_text: String, left_text: String, left_value: int, right_text: String, right_value: int, popup_x: float, left_value_has_star: bool = false) -> void:
	var mode_label := _stage_label(Rect2(popup_x + 28.0, row_y + 13.0, 132.0, 36.0), mode_text.to_upper(), 18, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	mode_label.clip_text = false

	var left_label := _stage_label(Rect2(popup_x + 188.0, row_y + 2.0, 194.0, 28.0), left_text, 17, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	left_label.clip_text = false
	var left_value_label: Label
	if left_value_has_star:
		left_value_label = _stage_score_with_star(Rect2(popup_x + 188.0, row_y + 31.0, 194.0, 28.0), str(left_value), 19, Color(0.82, 0.56, 0.34, 1.0), HORIZONTAL_ALIGNMENT_LEFT, Color.TRANSPARENT, 0)
	else:
		left_value_label = _stage_label(Rect2(popup_x + 188.0, row_y + 31.0, 194.0, 28.0), str(left_value), 19, Color(0.82, 0.56, 0.34, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	left_value_label.clip_text = false

	var right_label := _stage_label(Rect2(popup_x + 406.0, row_y + 2.0, 210.0, 28.0), right_text, 17, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	right_label.clip_text = false
	var right_value_label := _stage_label(Rect2(popup_x + 406.0, row_y + 31.0, 210.0, 28.0), str(right_value), 19, Color(0.82, 0.56, 0.34, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	right_value_label.clip_text = false

func _remove_records_popup() -> void:
	var popup_nodes: Array = get_tree().get_nodes_in_group("records_popup")
	for node: Node in popup_nodes:
		if is_instance_valid(node) and node.get_parent() != null:
			node.get_parent().remove_child(node)
			node.queue_free()

func _on_timer_tick() -> void:
	if GameState.current_mode != 1 or game_finished:
		return
	GameState.current_time_left = max(0, GameState.current_time_left - 1)
	if GameState.current_time_left <= 0:
		game_finished = true
		last_result_is_win = false
		last_result_data = GameSession.finish_time_attack_timeout()
		game_timer.stop()
		show_result_screen(false, last_result_data)
	else:
		GameState.save_game()
		_refresh_game_screen()

func _format_time(seconds: int) -> String:
	var minutes := int(seconds / 60)
	var sec := int(seconds % 60)
	return "%02d:%02d" % [minutes, sec]

func _show_word_comment_popup() -> void:
	var hint: String = GameSession.get_word_hint().strip_edges()
	if hint == "":
		return

	_remove_word_comment_popup()

	# PoiasnOk.as adds the comment dialog above the whole game screen together
	# with a dark blocker (TemnMov). Use a dedicated CanvasLayer so the popup
	# always sits above the character art and every other runtime control.
	var previous_content: Control = content
	var popup_layer := CanvasLayer.new()
	popup_layer.name = "WordCommentPopupCanvas"
	popup_layer.layer = 100
	popup_layer.add_to_group("word_comment_popup")
	add_child(popup_layer)

	var popup_root: Control = Control.new()
	popup_root.name = "WordCommentPopupLayer"
	popup_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup_root.mouse_filter = Control.MOUSE_FILTER_STOP
	popup_layer.add_child(popup_root)
	content = popup_root

	# TemnMov: dim stage behind the modal. A full-screen invisible button above
	# the dimmer reproduces PoiasnOk.ExtMouseClick() and closes the dialog when
	# the user clicks outside the blue popup window.
	_add_fullscreen_modal_backdrop(Callable(self, "_remove_word_comment_popup"))
	content = _center_popup_content(popup_root, 0.0, 366.0)

	var popup_x: float = 56.0
	var popup_width: float = 648.0
	var header := _stage_panel(Rect2(popup_x, 0.0, popup_width, 88.0), Color(0.2706, 0.3098, 0.6078, 1.0))
	header.mouse_filter = Control.MOUSE_FILTER_STOP
	var body := _stage_panel(Rect2(popup_x, 88.0, popup_width, 278.0), Color(0.2314, 0.2627, 0.5176, 1.0))
	body.mouse_filter = Control.MOUSE_FILTER_STOP
	var top_separator := _stage_panel(Rect2(popup_x, 88.0, popup_width, 2.0), Color(0.8157, 0.5647, 0.3412, 1.0))
	top_separator.mouse_filter = Control.MOUSE_FILTER_STOP
	var bottom_separator := _stage_panel(Rect2(popup_x + 33.0, 295.0, popup_width - 66.0, 2.0), Color(0.4509, 0.4862, 0.7607, 0.75))
	bottom_separator.mouse_filter = Control.MOUSE_FILTER_STOP

	var title_label := _stage_label(Rect2(popup_x + 21.0, 12.0, 360.0, 50.0), Database.tr_text(47, "Comment"), 34, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.clip_text = false
	var hint_label := _stage_label(Rect2(popup_x + 37.0, 114.0, popup_width - 74.0, 115.0), hint, 24, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	hint_label.clip_text = false
	var theme_label := _stage_label(Rect2(popup_x + 330.0, 314.0, 265.0, 34.0), _current_word_source_label(), 24, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
	theme_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	theme_label.clip_text = false

	_stage_round_button(Rect2(popup_x + popup_width - 68.0, 12.0, ROUND_BUTTON_SIZE.x, ROUND_BUTTON_SIZE.y), Callable(self, "_remove_word_comment_popup"), "×")

	content = previous_content

func _current_word_source_label() -> String:
	if GameState.current_mode == 2 or GameSession.theme_id < 0:
		return Database.tr_text(46, "Word from player")
	return Database.tr_text(48, "Category") + " " + Database.get_theme_name(GameSession.theme_id).to_upper()

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
	OS.shell_open("https://yandex.ru/search/?text=" + word.to_lower().uri_encode())

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
