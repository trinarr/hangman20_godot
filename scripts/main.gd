extends Node2D

const HERO_ANIMATION_SPEED_SCALE: float = 1.0
const HERO_OUTER_FRAME_SAMPLE_OFFSET: float = 0.5 / 24.0
const HERO_NESTED_FRAME_SAMPLE_OFFSET: float = 0.5 / 24.0
const HERO_MOV_START_FRAME_TIME: float = 0.0
const HERO_MOV_IDLE_FRAME_TIME: float = 4.0 / 24.0 + HERO_NESTED_FRAME_SAMPLE_OFFSET
const HERO_MOV_RECOVERY_START_FRAME_TIME: float = 5.0 / 24.0 + HERO_NESTED_FRAME_SAMPLE_OFFSET
const HERO_MOV_RECOVERY_END_FRAME_TIME: float = 9.0 / 24.0 + HERO_NESTED_FRAME_SAMPLE_OFFSET
const HERO_TYPE_1_TERMINAL_END_FRAME_TIME: float = 40.0 / 24.0
const HERO_TYPE_2_TERMINAL_END_FRAME_TIME: float = 12.0 / 24.0
const RANDOM_CUSTOM_WORD_MAX_LENGTH: int = 7
const RANDOM_CUSTOM_WORD_DIFFICULTY_FILTER: int = 2
const SETTINGS_TOGGLE_ON_VIBRATION_MS: int = 35
const CUSTOM_WORD_NOT_FOUND_VIBRATION_MS: int = 35
const CUSTOM_WORD_RESULT_COLOR_DURATION: float = 1.81
const UI_PALETTE: GDScript = preload("res://scripts/ui/ui_palette.gd")
const CUSTOM_WORD_CHECK_DOTS_INTERVAL: float = 0.4
const CUSTOM_WORD_INPUT_DEFAULT_COLOR := UI_PALETTE.UI_BLUE_DARK
const SOUND_SETTING_INDEX: int = 3
const THEME_CARD_PRESSED_MODULATE := UI_PALETTE.THEME_CARD_PRESSED
const THEME_PROGRESS_TEXT_OPTICAL_OFFSET_Y: float = -3.0
const APP_VERSION_FALLBACK: String = "3.0.0"
const SINGLE_PLAYER_THEME_OPTIONS_PER_LEVEL: int = 3
const SINGLE_PLAYER_THEME_REFRESH_COST: int = 25
const SINGLE_PLAYER_EXTRA_ATTEMPT_COST: int = 25
const SINGLE_PLAYER_EXTRA_ATTEMPT_COST_STEP: int = 5
const SINGLE_PLAYER_EXTRA_ATTEMPT_COUNT: int = 2
const SINGLE_PLAYER_EXTRA_ATTEMPT_COUNT_STEP: int = 1
const SINGLE_PLAYER_EXTRA_ATTEMPT_COUNT_STEP_INTERVAL: int = 2
const HEART_REFILL_COST: int = 100
const SINGLE_PLAYER_CHAIN_DIFFICULTY_SPREAD: float = 0.06
const SINGLE_PLAYER_PLAYED_WORD_PENALTY: float = 0.05
const SINGLE_PLAYER_GUESSED_WORD_PENALTY: float = 0.12
const SINGLE_PLAYER_WORD_PICK_JITTER: float = 0.012
const SINGLE_PLAYER_QUESTION_PICK_JITTER: float = 0.008
const DIFFICULTY_MODE_HARD: int = 1
const DIFFICULTY_MODE_NORMAL: int = 2
const DIFFICULTY_HARD_NORMAL_TINT := UI_PALETTE.CHALLENGE_NORMAL
const DIFFICULTY_HARD_PRESSED_TINT := UI_PALETTE.CHALLENGE_PRESSED
const DIFFICULTY_HARD_SELECTED_TINT := UI_PALETTE.CHALLENGE_SELECTED
const DIFFICULTY_HARD_OUTLINE_COLOR := UI_PALETTE.CHALLENGE_OUTLINE
const AUTHOR_VK_URL: String = "https://vk.ru/trinarr_tavern"
const AUTHOR_EMAIL_URL: String = "mailto:trinarr@mail.ru"
const FLASH_STAGE_CONTROL_SCRIPT: GDScript = preload("res://scripts/ui/flash_stage_control.gd")
const FLASH_STAGE_BUTTON_SCRIPT: GDScript = preload("res://scripts/ui/flash_stage_button.gd")
const BUTTON_TEXT_STYLE_SCRIPT: GDScript = preload("res://scripts/ui/button_text_style.gd")
const STAGE_LONG_BUTTON_SCRIPT: GDScript = preload("res://scripts/ui/stage_long_button.gd")
const LONG_BUTTON_COLOR_ORANGE: int = 0
const LONG_BUTTON_COLOR_BLUE: int = 2
const ROUND_BUTTON_COLOR_BLUE: int = 2
const STAGE_ROUND_BUTTON_SCRIPT: GDScript = preload("res://scripts/ui/stage_round_button.gd")
const STAGE_LETTER_BUTTON_SCRIPT: GDScript = preload("res://scripts/ui/stage_letter_button.gd")
const FLASH_STAGE_PANEL_SCRIPT: GDScript = preload("res://scripts/ui/flash_stage_panel.gd")
const FLASH_STAGE_SYMBOL_SCRIPT: GDScript = preload("res://scripts/ui/flash_stage_symbol.gd")
const THEME_ASSET_CACHE: GDScript = preload("res://scripts/core/theme_asset_cache.gd")
const FLASH_STAGE_TEXTURE_SCRIPT: GDScript = preload("res://scripts/ui/flash_stage_texture.gd")
const FLASH_STAGE_HORIZONTAL_FILL_SCRIPT: GDScript = preload("res://scripts/ui/flash_stage_horizontal_fill.gd")
const FLASH_STAGE_TEXTURE_FILL_SCRIPT: GDScript = preload("res://scripts/ui/flash_stage_texture_fill.gd")
const POPUP_STAGE_CENTER_SCRIPT: GDScript = preload("res://scripts/ui/popup_stage_center.gd")
const UI_PRIMARY_FONT: Font = preload("res://fonts/BalsamiqSans-Bold.ttf")
const UI_HEADING_FONT: Font = preload("res://fonts/BalsamiqSans-Regular.ttf")
const UI_HEADING_FONT_SCALE: float = 1.12

const RESULT_SEARCH_ICON: Texture2D = preload("res://flash_assets/result_search_icon_343.png")
const SOFT_CURRENCY_COIN_TEXTURE: Texture2D = preload("res://flash_assets/soft_currency_coin.png")
const SINGLE_PLAYER_REFRESH_ICON: Texture2D = preload("res://flash_assets/custom_word_refresh_icon_341.png")
const ABOUT_VK_ICON: Texture2D = preload("res://flash_assets/about_vk_icon_87.png")
const ABOUT_MAIL_ICON: Texture2D = preload("res://flash_assets/about_mail_icon_86.png")
const ABOUT_VK_ICON_SIZE := Vector2(34.0, 20.0)
const ABOUT_MAIL_ICON_SIZE := Vector2(33.0, 27.0)
const HERO_BADGE_RING_TEXTURE: Texture2D = preload("res://flash_assets/user_hint_circle_74.png")
const THEME_CARD_TEXTURE: Texture2D = preload("res://flash_assets/theme_card_user_239x90.png")
const THEME_CARD_PROGRESS_TEXTURE: Texture2D = preload("res://flash_assets/theme_card_progress_user_239x65.png")
const LIFE_HEART_ICON_TEXTURE: Texture2D = preload("res://flash_assets/life_heart_icon.png")
const EXTRA_ATTEMPTS_ICON_TEXTURE: Texture2D = preload("res://flash_assets/extra_attempts_icon.png")
const MENU_PAPER_COVER: Texture2D = preload("res://flash_assets/fon_png.png")
const CORRECT_LETTER_SOUND: AudioStream = preload("res://audio/Yes_New.wav")
const WRONG_LETTER_SOUND: AudioStream = preload("res://audio/No_New.wav")
const LUCKY_DEFEAT_SOUND: AudioStream = preload("res://audio/LuckyDefeat.wav")
const RESULT_WIN_SOUND: AudioStream = preload("res://audio/LuckyWin.wav")
const EL_TIGRE_DEFEAT_SOUND: AudioStream = preload("res://audio/CatDefeat.wav")
const UI_CLICK_SOUND: AudioStream = preload("res://audio/Click.wav")
const POPUP_OPEN_SOUND: AudioStream = preload("res://audio/Popup_Open.wav")
const HERO_AVATAR_LAKI_TEXTURE: Texture2D = preload("res://img/_______3______1_0_SHAPE_0_BOUNDS_154.49_-80.71_SIZE_270_290.png")
const HERO_AVATAR_TIGRE_TEXTURE: Texture2D = preload("res://img/_______405______1_0_SHAPE_0_BOUNDS_-0.96_-0.96_SIZE_366_322.png")

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
var single_player_level_cache_difficulty: float = -1.0
var single_player_popup_level_index: int = -1
var single_player_popup_selected_theme: int = -1
var single_player_popup_theme_panels: Dictionary = {}
var single_player_popup_stage_content: Control = null
var single_player_popup_theme_card_nodes: Array[Node] = []
var single_player_popup_play_button: Control = null
var single_player_popup_refresh_price_label: Label = null
var single_player_retry_after_loss: bool = false
var single_player_extra_attempt_offer_count: int = 0
var single_player_extra_attempt_current_cost: int = SINGLE_PLAYER_EXTRA_ATTEMPT_COST
var single_player_extra_attempt_current_count: int = SINGLE_PLAYER_EXTRA_ATTEMPT_COUNT
var single_player_extra_attempt_claim_in_progress: bool = false
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
var hero_force_default_pose: bool = false
var game_screen_visible: bool = false
var settings_toggle_buttons: Dictionary = {}
var settings_word_language_buttons: Dictionary = {}
var pending_letter_markers := PackedStringArray()
var pending_letter_marker_is_correct: bool = false
var round_result_delay_requested: bool = false
var result_transition_generation: int = 0
var last_result_sound_key: String = ""
var coin_store_return_action: Callable = Callable()
var currency_balance_label: Label = null
var heart_count_label: Label = null
var heart_status_label: Label = null
var heart_add_badge_visual: Control = null
var heart_counter_button: Control = null
var _last_heart_count_for_animation: int = -1
var _preserve_custom_word_on_next_show: bool = false
var heart_refill_continue_action: Callable = Callable()
var heart_refill_store_return_action: Callable = Callable()
var heart_refill_store_is_open: bool = false

func _ready() -> void:
	Engine.max_fps = 60
	randomize()
	Database.load_languages(GameState.interface_language, GameState.word_language)
	_build_root()
	GameSession.hint_letters_selected.connect(_on_hint_letters_selected)
	GameSession.changed.connect(_persist_active_single_player_word_session)
	GameSession.changed.connect(_refresh_game_screen)
	GameSession.round_won.connect(_on_round_won)
	GameSession.round_lost.connect(_on_round_lost)
	if !GameState.soft_currency_changed.is_connected(_on_soft_currency_changed):
		GameState.soft_currency_changed.connect(_on_soft_currency_changed)
	if !GameState.hearts_changed.is_connected(_on_hearts_changed):
		GameState.hearts_changed.connect(_on_hearts_changed)
	_last_heart_count_for_animation = GameState.get_hearts()
	show_menu()
	_prewarm_runtime_assets()

func _persist_active_single_player_word_session() -> void:
	if (
		GameState.current_mode != GameState.GameMode.SINGLE_PLAYER
		or GameSession.mode != GameState.GameMode.SINGLE_PLAYER
		or !GameSession.is_active
		or single_player_active_level_index < 0
		or single_player_active_word_slot < 0
		or GameSession.word_data == null
	):
		return
	GameState.set_active_single_player_session({
		"kind": "word",
		"language": Database.current_language,
		"level_index": single_player_active_level_index,
		"word_slot": single_player_active_word_slot,
		"theme_id": Database.get_theme_id(GameSession.theme_id),
		"data": GameSession.to_save_data(),
	})

func _prewarm_runtime_assets() -> void:
	THEME_ASSET_CACHE.prewarm()
	FLASH_STAGE_SYMBOL_SCRIPT.prewarm_hero_type(_selected_character_id())

# Main.tscn always uses main_portrait.gd. Keep only the small virtual surface
# that shared game logic calls; all screen construction lives in the portrait
# subclass instead of being duplicated here.
func show_menu() -> void:
	pass

func show_theme_select() -> void:
	pass

func show_tasks() -> void:
	pass

func show_custom_word() -> void:
	pass

func show_result_screen(_is_win: bool, _data: Dictionary = {}) -> void:
	pass

func show_coin_store() -> void:
	pass

func _stage_currency_counter(_return_action: Callable, _rect: Rect2 = Rect2()) -> void:
	pass

func _stage_single_player_level_header(_level_index: int) -> void:
	pass

func _open_coin_store(return_action: Callable = Callable()) -> void:
	_remove_coin_refill_popup()
	coin_store_return_action = return_action
	if !coin_store_return_action.is_valid():
		coin_store_return_action = Callable(self, "show_menu")
	show_coin_store()

func _close_coin_store() -> void:
	var return_action: Callable = coin_store_return_action
	coin_store_return_action = Callable()
	_remove_coin_refill_popup()
	if return_action.is_valid():
		return_action.call()
	else:
		show_menu()

func _grouped_counter_text(value: int) -> String:
	var digits: String = str(maxi(value, 0))
	var grouped_text: String = ""
	for digit_index in range(digits.length()):
		if digit_index > 0 and (digits.length() - digit_index) % 3 == 0:
			# A narrow non-breaking space keeps the group compact and prevents the
			# balance from wrapping between thousands.
			grouped_text += "\u202f"
		grouped_text += digits.substr(digit_index, 1)
	return grouped_text

func _soft_currency_balance_text(balance: int) -> String:
	var resolved_balance: int = maxi(balance, 0)
	if resolved_balance <= 999999:
		return _grouped_counter_text(resolved_balance)
	var tenths_of_thousand: int = int(round(float(resolved_balance) / 100.0))
	var whole_thousands: int = int(tenths_of_thousand / 10)
	var decimal_digit: int = tenths_of_thousand % 10
	var compact_text: String = _grouped_counter_text(whole_thousands)
	if decimal_digit > 0:
		compact_text += ".%d" % decimal_digit
	return compact_text + tr("COMPACT_THOUSANDS_SUFFIX")

func _on_soft_currency_changed(balance: int) -> void:
	var balance_text: String = _soft_currency_balance_text(balance)
	for balance_node: Node in get_tree().get_nodes_in_group(&"soft_currency_balance_label"):
		var balance_label := balance_node as Label
		if balance_label != null and is_instance_valid(balance_label):
			balance_label.text = balance_text
	_update_single_player_refresh_price(maxi(balance, 0))

func _on_hearts_changed(heart_count: int, recovery_seconds: int) -> void:
	var resolved_count: int = clampi(heart_count, 0, GameState.MAX_HEARTS)
	var previous_count: int = _last_heart_count_for_animation
	_last_heart_count_for_animation = resolved_count
	# The only runtime heart increment currently comes from the recovery timer.
	# Trigger a visual hook only on an actual increment, never on the per-second
	# countdown signal or when a heart is spent.
	if previous_count >= 0 and resolved_count > previous_count:
		_on_timer_heart_recovered()
	if heart_count_label != null and is_instance_valid(heart_count_label):
		heart_count_label.text = str(resolved_count)
	if heart_status_label != null and is_instance_valid(heart_status_label):
		heart_status_label.text = _heart_status_text(resolved_count, recovery_seconds)
	if heart_add_badge_visual != null and is_instance_valid(heart_add_badge_visual):
		var badge_allowed: bool = bool(heart_add_badge_visual.get_meta(&"badge_allowed", true))
		heart_add_badge_visual.visible = badge_allowed and resolved_count < GameState.MAX_HEARTS
	if heart_counter_button != null and is_instance_valid(heart_counter_button):
		var counter_is_full: bool = resolved_count >= GameState.MAX_HEARTS
		heart_counter_button.set("disabled", counter_is_full)
		heart_counter_button.mouse_filter = (
			Control.MOUSE_FILTER_IGNORE if counter_is_full else Control.MOUSE_FILTER_STOP
		)

func _on_timer_heart_recovered() -> void:
	pass

func _heart_status_text(heart_count: int, recovery_seconds: int) -> String:
	if heart_count >= GameState.MAX_HEARTS:
		return tr("COMMON_MAX")
	var resolved_seconds: int = maxi(recovery_seconds, 0)
	return "%d:%02d" % [int(resolved_seconds / 60), resolved_seconds % 60]

func _refresh_game_screen() -> void:
	pass

func _create_hero_animation_overlay() -> FlashStageSymbol:
	return null

func _show_single_player_theme_popup(_level_index: int, _theme_index: int) -> void:
	pass

func _show_single_player_level_popup(
	_level_index: int,
	_selected_theme: int = -1,
	_retry_after_loss: bool = false
) -> void:
	pass

func _show_single_player_last_chance_popup(_advance_offer_cost: bool = true) -> void:
	pass

func _show_heart_refill_popup(
	_continue_action: Callable = Callable(),
	_store_return_action: Callable = Callable()
) -> void:
	pass

func _show_in_place_round_result(_is_win: bool, _animated: bool = true) -> void:
	pass

func _show_single_player_forfeit_reward_screen() -> void:
	show_menu()

func _update_single_player_theme_popup(_level_index: int) -> void:
	pass

func _update_single_player_refresh_price(_balance: int) -> void:
	pass

func _show_exit_game_popup() -> void:
	pass

func _show_word_comment_popup() -> void:
	pass

func _build_root() -> void:
	ui = Control.new()
	ui.name = "RuntimeUI"
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_PASS
	ui.z_index = 100
	ThemeDB.fallback_font = UI_PRIMARY_FONT
	var runtime_theme := Theme.new()
	runtime_theme.default_font = UI_PRIMARY_FONT
	ui.theme = runtime_theme
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

func _clear() -> void:
	game_screen_visible = false
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
	currency_balance_label = null
	heart_count_label = null
	heart_status_label = null
	heart_add_badge_visual = null
	heart_counter_button = null
	hero_static_symbol = null
	settings_toggle_buttons.clear()
	settings_word_language_buttons.clear()
	_remove_exit_game_popup()
	_remove_coin_refill_popup()
	_remove_heart_refill_popup()
	_remove_single_player_last_chance_popup()
	_remove_single_player_theme_popup()
	_remove_clear_theme_popup()
	custom_word_edit = null
	custom_word_input_visual = null
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

func _stage_heading_label(
	rect: Rect2,
	text: String,
	font_size: int,
	color: Color = Color.WHITE,
	align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER
) -> Label:
	var label := _stage_label(rect, text, _heading_font_size(font_size), color, align)
	label.add_theme_font_override("font", UI_HEADING_FONT)
	return label

func _heading_font_size(font_size: int) -> int:
	return maxi(1, int(round(float(font_size) * UI_HEADING_FONT_SCALE)))

func _stage_button(rect: Rect2, callable: Callable, text: String = "", font_size: int = 20) -> Button:
	var button: Button = FLASH_STAGE_BUTTON_SCRIPT.new() as Button
	button.text = text.to_upper()
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
	dimmer.gui_input.connect(_on_modal_dimmer_input.bind(dimmer, close_callable))
	content.add_child(dimmer)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _on_modal_dimmer_input(
	event: InputEvent,
	dimmer: Control,
	close_callable: Callable
) -> void:
	var should_close: bool = false
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		should_close = mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		should_close = touch_event.pressed

	if should_close:
		get_viewport().set_input_as_handled()
		if (
			dimmer == null
			or !is_instance_valid(dimmer)
			or dimmer.get_meta(&"modal_close_pending", false)
		):
			return
		dimmer.set_meta(&"modal_close_pending", true)
		if close_callable.is_valid():
			# Keep the upper dimmer alive until the current input dispatch finishes.
			# Otherwise a popup restored by this close can receive the same tap and
			# immediately close as well.
			close_callable.call_deferred()

func _center_popup_content(popup_root: Control, popup_top: float, popup_bottom: float) -> Control:
	var centered_content: Control = POPUP_STAGE_CENTER_SCRIPT.new() as Control
	centered_content.name = "CenteredPopupStage"
	centered_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centered_content.set("popup_top", popup_top)
	centered_content.set("popup_bottom", popup_bottom)
	popup_root.add_child(centered_content)
	return centered_content

func _stage_hero_symbol(hero_type: int, stage_position: Vector2, animation_time: float = -1.0, nested_animation_time: float = -1.0) -> FlashStageSymbol:
	var symbol: FlashStageSymbol = FLASH_STAGE_SYMBOL_SCRIPT.new() as FlashStageSymbol
	symbol.z_index = 5
	symbol.hero_type = hero_type
	symbol.stage_position = stage_position
	symbol.animation_time = animation_time
	symbol.nested_animation_time = nested_animation_time
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
	edit.add_theme_color_override("font_color", UI_PALETTE.UI_BLUE_DARK)
	edit.add_theme_color_override("caret_color", UI_PALETTE.UI_BLUE_DARK)
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
	var font_color: Color = UI_PALETTE.TEXT_DARK if show_text else Color(1.0, 1.0, 1.0, 0.0)
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", font_color)
	button.add_theme_color_override("font_pressed_color", font_color)
	button.add_theme_color_override("font_disabled_color", Color(font_color.r, font_color.g, font_color.b, 0.45))
	var text_effect_color: Color = UI_PALETTE.TEXT_SHADOW_DARK if show_text else Color.TRANSPARENT
	BUTTON_TEXT_STYLE_SCRIPT.apply(
		button,
		text_effect_color,
		text_effect_color,
		3 if show_text else 0
	)
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

func _about_version_text() -> String:
	return Database.tr_text(19, "Version:") + " " + _application_version()

func _application_version() -> String:
	var configured_version: String = str(
		ProjectSettings.get_setting("application/config/version", APP_VERSION_FALLBACK)
	).strip_edges()
	return configured_version if configured_version != "" else APP_VERSION_FALLBACK

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
		return tr("DIFFICULTY_HARD_MODE")
	return tr("DIFFICULTY_NORMAL_MODE")

func _style_hard_button(button: Control) -> Control:
	if button == null:
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

func _style_difficulty_button(button: Control) -> Control:
	if _difficulty_mode_value() != DIFFICULTY_MODE_HARD:
		return button
	return _style_hard_button(button)

func _style_single_player_level_button(button: Control, level_index: int) -> Control:
	if !_single_player_is_bonus_level(level_index):
		return button
	return _style_hard_button(button)

func _cycle_difficulty_mode() -> void:
	if _difficulty_mode_value() == DIFFICULTY_MODE_NORMAL:
		GameState.settings[2] = DIFFICULTY_MODE_HARD
	else:
		GameState.settings[2] = DIFFICULTY_MODE_NORMAL
	GameState.save_game()

func _cycle_classic_difficulty(return_to_tasks: bool = false) -> void:
	_cycle_difficulty_mode()
	if return_to_tasks:
		show_tasks()
	else:
		show_theme_select()

func _theme_icon_texture(theme_index: int) -> Texture2D:
	var theme_id: int = Database.get_theme_id(theme_index)
	if theme_id <= 0:
		return null
	return THEME_ASSET_CACHE.get_icon(theme_id) as Texture2D

func _theme_icon_mono_texture(theme_index: int) -> Texture2D:
	var theme_id: int = Database.get_theme_id(theme_index)
	if theme_id <= 0:
		return null
	return THEME_ASSET_CACHE.get_icon(theme_id, true) as Texture2D

func _single_player_level_label() -> String:
	return tr("LEVEL_LABEL")

func _single_player_challenge_level_label() -> String:
	return tr("CHALLENGE_LEVEL_LABEL")

func _single_player_level_failed_label() -> String:
	return tr("LEVEL_FAILURE")

func _single_player_level_completed_reward_label(bonus_coins: int) -> String:
	return tr("LEVEL_COMPLETED_BONUS") % maxi(bonus_coins, 0)

func _single_player_chain_failed_label() -> String:
	return tr("CHAIN_TRY_BETTER")

func _single_player_choose_theme_label() -> String:
	return tr("CHOOSE_THEME")

func _single_player_theme_start_label() -> String:
	return tr("PLAY_GAME")

func _single_player_next_level_index() -> int:
	return maxi(GameState.get_single_player_unlocked_level(Database.current_language), 0)

func _open_next_single_player_level() -> void:
	single_player_active_level_index = _single_player_next_level_index()
	single_player_active_word_slot = -1
	_show_single_player_level_popup(single_player_active_level_index)

func _invalidate_single_player_level_cache() -> void:
	single_player_level_definitions_cache.clear()
	single_player_level_cache_language = ""
	single_player_level_cache_theme_count = -1
	single_player_level_cache_difficulty = -1.0

func _single_player_level_word_target(level_index: int) -> int:
	var level_number: int = maxi(level_index + 1, 1)
	if level_number == 1:
		return 1
	var word_count: int = 2
	if level_number > 18:
		word_count = 5
	elif level_number >= 8:
		word_count = 4
	elif level_number >= 5:
		word_count = 3
	if _single_player_is_bonus_level(level_index):
		word_count += 2
	return word_count

func _single_player_level_uses_question(level_index: int, word_count: int) -> bool:
	# Levels 2-4 are intentionally two-part onboarding levels: one word followed
	# by one quiz question. From level 5 onward the normal question-slot rules
	# apply to every level with at least three parts.
	var level_number: int = maxi(level_index + 1, 1)
	if level_number >= 2 and level_number <= 4:
		return word_count >= 2
	return word_count >= 3

func _single_player_is_bonus_level(level_index: int) -> bool:
	var level_number: int = level_index + 1
	return level_number > 0 and level_number % 10 == 0

func _prepare_single_player_level_attempt(level_index: int) -> int:
	level_index = maxi(level_index, 0)
	for _migration_step in range(32):
		var word_count: int = _single_player_level_word_target(level_index)
		var selected_theme: int = GameState.get_single_level_selected_theme(
			Database.current_language,
			level_index
		)
		if selected_theme < 0:
			return level_index
		if GameState.is_single_level_failed(Database.current_language, level_index, word_count):
			GameState.reset_single_level_attempt(Database.current_language, level_index)
			_invalidate_single_player_level_cache()
			return level_index
		if !GameState.is_single_level_completed(Database.current_language, level_index, word_count):
			return level_index
		# Older saves could contain a completed tenth level that was previously
		# capped by the finite campaign. Advance it into the endless ladder.
		GameState.ensure_single_player_next_level_unlocked(Database.current_language, level_index)
		level_index += 1
	return level_index

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

func _single_player_slot_difficulty(target_difficulty: float, word_slot: int, word_count: int) -> float:
	if word_count <= 1:
		return target_difficulty
	var chain_progress: float = float(word_slot) / float(word_count - 1)
	var offset: float = lerpf(
		-SINGLE_PLAYER_CHAIN_DIFFICULTY_SPREAD,
		SINGLE_PLAYER_CHAIN_DIFFICULTY_SPREAD,
		chain_progress
	)
	return clampf(
		target_difficulty + offset,
		GameState.SINGLE_PLAYER_DIFFICULTY_MIN,
		GameState.SINGLE_PLAYER_DIFFICULTY_MAX
	)

func _single_player_words_for_theme(
	level_index: int,
	level_seed: int,
	theme_index: int,
	word_count: int,
	target_difficulty: float
) -> Array:
	var candidates: Array = Database.get_words_by_index(theme_index, 0).duplicate(true)
	if candidates.is_empty():
		return []
	var rng := RandomNumberGenerator.new()
	rng.seed = _single_player_seed(level_index, level_seed, theme_index + 101)
	var theme_progress: Dictionary = GameState.ensure_single_player_theme_progress(
		Database.current_language,
		theme_index,
		candidates.size()
	)
	var played_keys: Dictionary = theme_progress.get("played", {})
	var guessed_keys: Dictionary = theme_progress.get("guessed", {})
	var progress_word_keys: Array[String] = Database.get_word_progress_keys(theme_index)
	var words: Array = []
	for word_slot in range(mini(word_count, candidates.size())):
		var slot_target: float = _single_player_slot_difficulty(target_difficulty, word_slot, word_count)
		var picked_pool_index: int = -1
		var picked_score: float = INF
		for pool_index in range(candidates.size()):
			var candidate: Dictionary = candidates[pool_index]
			var candidate_word_index: int = int(candidate.get("index", -1))
			var repeat_penalty: float = 0.0
			var candidate_key: String = (
				progress_word_keys[candidate_word_index]
				if candidate_word_index >= 0 and candidate_word_index < progress_word_keys.size()
				else ""
			)
			if bool(played_keys.get(candidate_key, false)):
				repeat_penalty += SINGLE_PLAYER_PLAYED_WORD_PENALTY
			if bool(guessed_keys.get(candidate_key, false)):
				repeat_penalty += SINGLE_PLAYER_GUESSED_WORD_PENALTY
			var score: float = (
				absf(float(candidate.get("difficulty", 0.0)) - slot_target)
				+ repeat_penalty
				+ rng.randf_range(0.0, SINGLE_PLAYER_WORD_PICK_JITTER)
			)
			if score < picked_score:
				picked_score = score
				picked_pool_index = pool_index
		if picked_pool_index < 0:
			break
		var picked: Dictionary = candidates[picked_pool_index]
		candidates.remove_at(picked_pool_index)
		words.append({
			"theme_index": theme_index,
			"word_index": int(picked.get("index", 0)),
			"text": str(picked.get("text", "")),
			"difficulty": float(picked.get("difficulty", 0.0)),
			"target_difficulty": slot_target,
		})
	return words

func _single_player_level_question_slot(level_index: int, level_seed: int, word_count: int) -> int:
	if !_single_player_level_uses_question(level_index, word_count):
		return -1
	var saved_slot: int = GameState.get_single_level_question_slot(
		Database.current_language,
		level_index
	)
	var level_number: int = maxi(level_index + 1, 1)
	var first_slot: int = int(floor(float(word_count) * 0.5))
	var last_slot: int = word_count - 2
	# The second, third and fourth levels are always "word -> quiz". Their quiz
	# therefore occupies the second/final slot instead of using the later-half
	# placement rule used by normal 3+ part levels.
	if level_number >= 2 and level_number <= 4 and word_count == 2:
		first_slot = 1
		last_slot = 1
	if saved_slot >= first_slot and saved_slot <= last_slot:
		return saved_slot
	if first_slot > last_slot:
		first_slot = last_slot
	var available_slots: Array[int] = []
	for slot_index: int in range(first_slot, last_slot + 1):
		if GameState.get_single_level_word_status(
			Database.current_language,
			level_index,
			slot_index,
			word_count
		) == 0:
			available_slots.append(slot_index)
	if available_slots.is_empty():
		return -1
	var rng := RandomNumberGenerator.new()
	rng.seed = _single_player_seed(level_index, level_seed, 503)
	var question_slot: int = available_slots[rng.randi_range(0, available_slots.size() - 1)]
	GameState.set_single_level_question_slot(
		Database.current_language,
		level_index,
		question_slot
	)
	return question_slot

func _single_player_pick_level_question(
	level_index: int,
	level_seed: int,
	theme_index: int,
	target_difficulty: float
) -> Dictionary:
	var saved_question_id: int = GameState.get_single_level_question_id(
		Database.current_language,
		level_index
	)
	if saved_question_id >= 0:
		var saved_question := Database.get_quiz_question_by_id(theme_index, saved_question_id)
		if !saved_question.is_empty():
			return saved_question

	var questions: Array = Database.get_quiz_questions_by_theme_index(theme_index)
	if questions.is_empty():
		return {}
	var unseen_questions: Array = []
	for question_variant: Variant in questions:
		if !(question_variant is Dictionary):
			continue
		var question: Dictionary = question_variant
		var question_id: int = int(question.get("id", -1))
		if !GameState.has_single_player_question_been_seen(
			Database.current_language,
			theme_index,
			question_id
		):
			unseen_questions.append(question)
	# An endless campaign can eventually exhaust a finite theme pool. Avoid every
	# repeat while unseen questions remain; only after the full theme was seen do
	# we allow a new cycle rather than leaving the level without a question.
	var pool: Array = unseen_questions if !unseen_questions.is_empty() else questions
	var rng := RandomNumberGenerator.new()
	rng.seed = _single_player_seed(level_index, level_seed, theme_index + 809)
	var best_question: Dictionary = {}
	var best_score: float = INF
	for question_variant: Variant in pool:
		if !(question_variant is Dictionary):
			continue
		var question: Dictionary = question_variant
		var score: float = (
			absf(float(question.get("difficulty", 0.5)) - target_difficulty)
			+ rng.randf_range(0.0, SINGLE_PLAYER_QUESTION_PICK_JITTER)
		)
		if score < best_score:
			best_score = score
			best_question = question
	if best_question.is_empty():
		return {}
	var picked_question: Dictionary = best_question.duplicate(true)
	var picked_id: int = int(picked_question.get("id", -1))
	if picked_id >= 0:
		GameState.set_single_level_question_id(
			Database.current_language,
			level_index,
			picked_id
		)
	return picked_question

func _single_player_level_data(level_index: int) -> Dictionary:
	if level_index < 0:
		return {}
	var theme_count: int = Database.get_theme_count()
	var language: String = Database.current_language
	var adaptive_difficulty: float = GameState.get_single_player_adaptive_difficulty(language)
	if (
		single_player_level_cache_language != language
		or single_player_level_cache_theme_count != theme_count
		or !is_equal_approx(single_player_level_cache_difficulty, adaptive_difficulty)
	):
		_invalidate_single_player_level_cache()
		single_player_level_cache_language = language
		single_player_level_cache_theme_count = theme_count
		single_player_level_cache_difficulty = adaptive_difficulty
	var level_key := str(level_index)
	if single_player_level_definitions_cache.has(level_key):
		var cached: Variant = single_player_level_definitions_cache[level_key]
		if cached is Dictionary:
			return cached
	if theme_count <= 0:
		return {}
	var target_difficulty: float = adaptive_difficulty
	if _single_player_is_bonus_level(level_index):
		target_difficulty = clampf(
			adaptive_difficulty + GameState.SINGLE_PLAYER_SUCCESS_DIFFICULTY_STEP,
			GameState.SINGLE_PLAYER_DIFFICULTY_MIN,
			GameState.SINGLE_PLAYER_DIFFICULTY_MAX
		)
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
		words = _single_player_words_for_theme(
			level_index,
			level_seed,
			selected_theme,
			word_count,
			target_difficulty
		)
	var question_slot: int = -1
	var question: Dictionary = {}
	var question_target_difficulty: float = target_difficulty
	if (
		selected_theme >= 0
		and _single_player_level_uses_question(level_index, word_count)
		and words.size() >= word_count
	):
		question_slot = _single_player_level_question_slot(level_index, level_seed, word_count)
		if question_slot >= 0 and question_slot < words.size():
			var replaced_word: Dictionary = words[question_slot]
			question_target_difficulty = float(replaced_word.get("difficulty", target_difficulty))
			question = _single_player_pick_level_question(
				level_index,
				level_seed,
				selected_theme,
				question_target_difficulty
			)
		if question.is_empty():
			question_slot = -1
	var level_data := {
		"index": level_index,
		"theme_options": options,
		"selected_theme_index": selected_theme,
		"word_count": word_count,
		"words": words,
		"question_slot": question_slot,
		"question": question,
		"question_target_difficulty": question_target_difficulty,
		"target_difficulty": target_difficulty,
		"is_bonus_level": _single_player_is_bonus_level(level_index),
	}
	single_player_level_definitions_cache[level_key] = level_data
	return level_data

func _single_player_level_theme_options(level_index: int) -> Array:
	return Array(_single_player_level_data(level_index).get("theme_options", []))

func _single_player_level_selected_theme(level_index: int) -> int:
	return int(_single_player_level_data(level_index).get("selected_theme_index", -1))

func _single_player_level_words(level_index: int) -> Array:
	return Array(_single_player_level_data(level_index).get("words", []))

func _single_player_level_question_slot_index(level_index: int) -> int:
	return int(_single_player_level_data(level_index).get("question_slot", -1))

func _single_player_level_question(level_index: int) -> Dictionary:
	var question_variant: Variant = _single_player_level_data(level_index).get("question", {})
	if question_variant is Dictionary:
		var question: Dictionary = question_variant
		return question.duplicate(true)
	return {}

func _single_player_level_question_target_difficulty(level_index: int) -> float:
	return float(_single_player_level_data(level_index).get(
		"question_target_difficulty",
		GameState.get_single_player_adaptive_difficulty(Database.current_language)
	))

func _single_player_level_word_count(level_index: int) -> int:
	return int(_single_player_level_data(level_index).get("word_count", _single_player_level_word_target(level_index)))

func _single_player_level_played_count(level_index: int) -> int:
	return GameState.get_single_level_played_count(
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

func _single_player_mark_current_word_finished(
	data: Dictionary,
	is_win: bool,
	failure_affects_difficulty: bool = true,
	defer_final_reward: bool = false,
	persist: bool = true
) -> Dictionary:
	if single_player_active_level_index < 0 or single_player_active_word_slot < 0:
		return data
	var result: Dictionary = data.duplicate(true)
	var level_word_count: int = _single_player_level_word_count(single_player_active_level_index)
	var progress: Dictionary = GameState.mark_single_level_word_played(
		Database.current_language,
		single_player_active_level_index,
		single_player_active_word_slot,
		level_word_count,
		is_win,
		failure_affects_difficulty,
		-1,
		!defer_final_reward,
		false
	)
	if !result.has("lines") or !(result["lines"] is Array):
		result["lines"] = []
	result["single_player_level_index"] = single_player_active_level_index
	result["single_player_word_slot"] = single_player_active_word_slot
	result["single_player_played_count"] = int(progress.get("played_count", 0))
	result["single_player_total_count"] = level_word_count
	result["single_player_level_completed"] = bool(progress.get("completed", false))
	result["single_player_level_perfect"] = bool(progress.get("perfect", false))
	result["single_player_chain_failed"] = bool(progress.get("failed", false))
	result["single_player_chain_ended"] = bool(progress.get("chain_ended", false))
	result["single_player_unlocked_next"] = bool(progress.get("unlocked_next", false))
	result["single_player_completion_bonus"] = int(progress.get("completion_bonus", 0))
	var level_completed: bool = bool(progress.get("completed", false))
	result["single_player_reward_deferred"] = defer_final_reward and level_completed
	result["single_player_deferred_reward_amount"] = (
		GameState.WORD_REWARD_COINS + int(progress.get("completion_bonus", 0))
		if defer_final_reward and level_completed
		else 0
	)
	result["single_player_difficulty_before"] = float(progress.get("difficulty_before", 0.0))
	result["single_player_difficulty_after"] = float(progress.get("difficulty_after", 0.0))
	if level_completed:
		result["lines"].append(_single_player_level_completed_reward_label(int(progress.get("completion_bonus", 0))))
	elif bool(progress.get("failed", false)):
		result["lines"].append(_single_player_chain_failed_label())
	if level_completed:
		# mark_single_level_word_played() has already replaced the active snapshot
		# with a durable pending reward when this is the deferred final result.
		GameState.clear_active_single_player_session(false)
	elif is_win:
		GameState.set_active_single_player_session({
			"kind": "next",
			"language": Database.current_language,
			"level_index": single_player_active_level_index,
			"word_slot": single_player_active_word_slot,
			"theme_id": Database.get_theme_id(
				_single_player_level_selected_theme(single_player_active_level_index)
			),
			"data": {},
		}, false)
	else:
		GameState.clear_active_single_player_session(false)
	if persist:
		GameState.save_game()
	return result

func _stage_single_player_menu_button(rect: Rect2, callable: Callable) -> void:
	var level_index: int = _single_player_next_level_index()
	var challenge_level: bool = _single_player_is_bonus_level(level_index)
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
	_style_single_player_level_button(button, level_index)

	var title_label := Label.new()
	title_label.name = "LevelTitle"
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.position = Vector2(0.0, 0.0 if challenge_level else 3.0)
	title_label.size = Vector2(rect.size.x, rect.size.y * (0.60 if challenge_level else 0.92))
	title_label.text = ("%s %d" % [_single_player_level_label(), level_index + 1]).to_upper()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM if challenge_level else VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	var title_effect_color: Color = (
		Color(DIFFICULTY_HARD_OUTLINE_COLOR.r, DIFFICULTY_HARD_OUTLINE_COLOR.g, DIFFICULTY_HARD_OUTLINE_COLOR.b, 0.55)
		if challenge_level
		else UI_PALETTE.with_alpha(UI_PALETTE.UI_BLUE_DARK, 0.55)
	)
	BUTTON_TEXT_STYLE_SCRIPT.apply(title_label, title_effect_color, title_effect_color)
	button.add_child(title_label)

	if challenge_level:
		var challenge_label := Label.new()
		challenge_label.name = "ChallengeSubtitle"
		challenge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		challenge_label.position = Vector2(0.0, rect.size.y * 0.57)
		challenge_label.size = Vector2(rect.size.x, rect.size.y * 0.30)
		challenge_label.text = _single_player_challenge_level_label().to_upper()
		challenge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		challenge_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		challenge_label.add_theme_font_size_override("font_size", 15)
		challenge_label.add_theme_color_override("font_color", UI_PALETTE.CHALLENGE_TEXT)
		var challenge_effect_color := Color(
			DIFFICULTY_HARD_OUTLINE_COLOR.r,
			DIFFICULTY_HARD_OUTLINE_COLOR.g,
			DIFFICULTY_HARD_OUTLINE_COLOR.b,
			0.52
		)
		BUTTON_TEXT_STYLE_SCRIPT.apply(challenge_label, challenge_effect_color, challenge_effect_color)
		button.add_child(challenge_label)

func _remove_single_player_theme_popup() -> void:
	_clear_single_player_popup_theme_cards()
	var popup_nodes: Array = get_tree().get_nodes_in_group("single_player_theme_popup")
	for node: Node in popup_nodes:
		if is_instance_valid(node) and node.get_parent() != null:
			node.get_parent().remove_child(node)
			node.queue_free()
	single_player_popup_level_index = -1
	single_player_popup_selected_theme = -1
	single_player_popup_theme_panels.clear()
	single_player_popup_stage_content = null
	single_player_popup_play_button = null
	single_player_popup_refresh_price_label = null

func _remove_single_player_last_chance_popup() -> void:
	var popup_nodes: Array = get_tree().get_nodes_in_group("single_player_last_chance_popup")
	for node: Node in popup_nodes:
		if is_instance_valid(node) and node.get_parent() != null:
			node.get_parent().remove_child(node)
			node.queue_free()

func _remove_heart_refill_popup() -> void:
	var popup_nodes: Array = get_tree().get_nodes_in_group("heart_refill_popup")
	for node: Node in popup_nodes:
		if is_instance_valid(node) and node.get_parent() != null:
			node.get_parent().remove_child(node)
			node.queue_free()
	heart_refill_continue_action = Callable()
	heart_refill_store_return_action = Callable()
	heart_refill_store_is_open = false

func _remove_coin_refill_popup() -> void:
	var popup_nodes: Array = get_tree().get_nodes_in_group("coin_refill_popup")
	for node: Node in popup_nodes:
		if is_instance_valid(node) and node.get_parent() != null:
			node.get_parent().remove_child(node)
			node.queue_free()

func _purchase_heart_refill() -> void:
	if GameState.get_hearts() >= GameState.MAX_HEARTS:
		return
	if GameState.get_soft_currency() < HEART_REFILL_COST:
		if heart_refill_store_is_open:
			_remove_heart_refill_popup()
			return
		var continue_action: Callable = heart_refill_continue_action
		var restore_action: Callable = heart_refill_store_return_action
		_remove_heart_refill_popup()
		_open_coin_store(
			Callable(self, "_return_to_heart_refill_from_coin_store").bind(
				continue_action,
				restore_action
			)
		)
		return
	if !GameState.spend_soft_currency(HEART_REFILL_COST, false):
		return
	var continue_action: Callable = heart_refill_continue_action
	GameState.refill_hearts(true)
	_remove_heart_refill_popup()
	if continue_action.is_valid():
		continue_action.call_deferred()

func _clear_single_player_popup_theme_cards() -> void:
	for card_node: Node in single_player_popup_theme_card_nodes:
		if card_node != null and is_instance_valid(card_node):
			if card_node.get_parent() != null:
				card_node.get_parent().remove_child(card_node)
			card_node.queue_free()
	single_player_popup_theme_card_nodes.clear()
	single_player_popup_theme_panels.clear()

func _stage_single_player_theme_card(
	rect: Rect2,
	theme_index: int,
	word_count: int,
	_played_count: int,
	selected: bool,
	disabled: bool,
	action: Callable
) -> void:
	# Reuse the same layered card artwork as Classic mode, expanded to one wide
	# row so the three offered categories read as the main level choices.
	var card := _stage_texture(rect, THEME_CARD_TEXTURE)

	var theme_icon: Control = null
	var word_badge: Control = null
	var word_badge_label: Label = null
	var theme_icon_texture: Texture2D = _theme_icon_texture(theme_index)
	var theme_icon_rect := Rect2(rect.position + Vector2(20.0, 18.0), Vector2(64.0, 64.0))
	if theme_icon_texture != null:
		theme_icon = _stage_texture(theme_icon_rect, theme_icon_texture)
		theme_icon.z_index = 11
		var word_badge_size := Vector2(43.0, 25.0)
		var word_badge_rect := Rect2(
			theme_icon_rect.end - word_badge_size * Vector2(0.86, 0.82),
			word_badge_size
		)
		word_badge = _stage_panel(
			word_badge_rect,
			UI_PALETTE.ACCENT_ORANGE,
			word_badge_size.y * 0.5,
			Color.WHITE,
			1.5
		)
		word_badge.z_index = 12
		word_badge_label = _stage_label(
			word_badge_rect,
			"x%d" % word_count,
			16,
			Color.WHITE,
			HORIZONTAL_ALIGNMENT_CENTER
		)
		word_badge_label.z_index = 13
		var badge_effect_color: Color = UI_PALETTE.with_alpha(UI_PALETTE.UI_BLUE_DARK, 0.55)
		BUTTON_TEXT_STYLE_SCRIPT.apply(word_badge_label, badge_effect_color, badge_effect_color)

	var theme_name: String = Database.get_theme_name(theme_index).to_upper()
	var title_font_size: int = 20 if theme_name.length() > 15 else 26
	var title_label := _stage_label(
		Rect2(
			rect.position + Vector2(100.0, rect.size.y - 45.0),
			Vector2(rect.size.x - 118.0, 35.0)
		),
		theme_name,
		title_font_size,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_LEFT
	)
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	title_label.clip_text = false
	var theme_title_effect_color: Color = UI_PALETTE.with_alpha(UI_PALETTE.UI_BLUE_EFFECT, 0.55)
	BUTTON_TEXT_STYLE_SCRIPT.apply(title_label, theme_title_effect_color, theme_title_effect_color)

	if selected:
		_stage_panel(rect.grow(2.0), Color.TRANSPARENT, 16.0, UI_PALETTE.ACCENT_ORANGE, 3.0)
	if disabled:
		for item in [card, theme_icon, word_badge, word_badge_label, title_label]:
			if item != null:
				item.modulate = Color(1.0, 1.0, 1.0, 0.30)

	var theme_button := _stage_button(rect, action, "")
	theme_button.disabled = disabled
	_bind_theme_card_press_state(theme_button, card)

func show_single_player_level(level_index: int) -> void:
	level_index = _prepare_single_player_level_attempt(level_index)
	single_player_active_level_index = level_index
	single_player_active_word_slot = -1
	_clear()
	var screen_blue: Color = UI_PALETTE.UI_BLUE
	_stage_texture_fill(0.0, 800.0, MENU_PAPER_COVER)
	_stage_single_player_level_header(level_index)
	var selected_theme: int = _single_player_level_selected_theme(level_index)
	var instruction_text: String = _single_player_choose_theme_label()
	if selected_theme >= 0:
		instruction_text = tr("CONTINUE_SELECTED_THEME")
	if _single_player_is_bonus_level(level_index):
		instruction_text += "\n" + tr("CHALLENGE_LEVEL_PLUS_TWO_WORDS")
	var instruction_label := _stage_label(
		Rect2(36.0, 114.0, 408.0, 50.0),
		instruction_text,
		17 if _single_player_is_bonus_level(level_index) else 19,
		screen_blue,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	instruction_label.clip_text = false

	var word_count: int = _single_player_level_word_count(level_index)
	var played_count: int = _single_player_level_played_count(level_index)
	var theme_options: Array = _single_player_level_theme_options(level_index)
	if theme_options.is_empty():
		var unavailable_label := _stage_label(
			Rect2(42.0, 260.0, 396.0, 100.0),
			tr("NO_THEMES_AVAILABLE"),
			24,
			screen_blue,
			HORIZONTAL_ALIGNMENT_CENTER
		)
		unavailable_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		unavailable_label.clip_text = false
		return

	var card_rect := Rect2(30.0, 166.0, 420.0, 112.0)
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
	if existing_theme != theme_index:
		if existing_theme >= 0:
			# A saved choice identifies the current chain, not a permanent UI lock.
			# Keep the offered cards stable while replacing that chain with the
			# newly confirmed category.
			GameState.reset_single_level_attempt(Database.current_language, level_index, false)
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

func _start_single_player_popup_level(level_index: int) -> void:
	if level_index != single_player_popup_level_index or single_player_popup_selected_theme < 0:
		return
	single_player_retry_after_loss = false
	_confirm_single_player_theme_selection(level_index, single_player_popup_selected_theme)

func _refresh_single_player_theme_popup(level_index: int) -> void:
	if level_index != single_player_popup_level_index:
		return
	if GameState.get_soft_currency() < SINGLE_PLAYER_THEME_REFRESH_COST:
		_open_coin_store(
			Callable(self, "_return_to_single_player_theme_popup").bind(
				level_index,
				single_player_retry_after_loss
			)
		)
		return
	if !GameState.spend_soft_currency(SINGLE_PLAYER_THEME_REFRESH_COST, false):
		return
	GameState.reset_single_level_attempt(Database.current_language, level_index)
	_invalidate_single_player_level_cache()
	_update_single_player_theme_popup(level_index)

func _return_to_single_player_theme_popup(
	level_index: int,
	retry_after_loss: bool = false,
	selected_theme: int = -1
) -> void:
	show_menu()
	_show_single_player_level_popup(level_index, selected_theme, retry_after_loss)

func _purchase_single_player_extra_attempt() -> void:
	if single_player_extra_attempt_claim_in_progress:
		return
	if !GameSession.has_deferred_loss():
		_remove_single_player_last_chance_popup()
		return
	var purchase_cost: int = _single_player_extra_attempt_cost()
	if GameState.get_soft_currency() < purchase_cost:
		_remove_single_player_last_chance_popup()
		_open_coin_store(Callable(self, "_return_to_single_player_last_chance_from_coin_store"))
		return
	single_player_extra_attempt_claim_in_progress = true
	if !GameState.spend_soft_currency(purchase_cost, false):
		single_player_extra_attempt_claim_in_progress = false
		return
	_remove_single_player_last_chance_popup()
	_grant_single_player_extra_attempt()

func _single_player_extra_attempt_cost() -> int:
	return maxi(single_player_extra_attempt_current_cost, SINGLE_PLAYER_EXTRA_ATTEMPT_COST)

func _single_player_extra_attempt_count() -> int:
	return maxi(single_player_extra_attempt_current_count, SINGLE_PLAYER_EXTRA_ATTEMPT_COUNT)

func _single_player_extra_attempt_description(attempt_count: int) -> String:
	var description_key: StringName = &"EXTRA_ATTEMPTS_DESCRIPTION"
	if attempt_count >= 5:
		description_key = &"EXTRA_ATTEMPTS_DESCRIPTION_MANY"
	return tr(description_key) % attempt_count

func _advance_single_player_extra_attempt_offer() -> int:
	single_player_extra_attempt_current_cost = (
		SINGLE_PLAYER_EXTRA_ATTEMPT_COST
		+ single_player_extra_attempt_offer_count * SINGLE_PLAYER_EXTRA_ATTEMPT_COST_STEP
	)
	single_player_extra_attempt_current_count = mini(
		SINGLE_PLAYER_EXTRA_ATTEMPT_COUNT
		+ floori(
			float(single_player_extra_attempt_offer_count)
			/ float(SINGLE_PLAYER_EXTRA_ATTEMPT_COUNT_STEP_INTERVAL)
		) * SINGLE_PLAYER_EXTRA_ATTEMPT_COUNT_STEP,
		GameSession.MAX_MISTAKES
	)
	single_player_extra_attempt_offer_count += 1
	return single_player_extra_attempt_current_cost

func _reset_single_player_extra_attempt_offers() -> void:
	single_player_extra_attempt_offer_count = 0
	single_player_extra_attempt_current_cost = SINGLE_PLAYER_EXTRA_ATTEMPT_COST
	single_player_extra_attempt_current_count = SINGLE_PLAYER_EXTRA_ATTEMPT_COUNT

func _grant_single_player_extra_attempt() -> void:
	# A reaction overlay from the previous wrong guess can still be playing under
	# the modal. Remove it before the session signal refreshes the restored pose,
	# otherwise the static hero remains hidden until that old animation finishes.
	_clear_hero_animation_overlay()
	GameSession.grant_deferred_attempt(_single_player_extra_attempt_count())
	single_player_extra_attempt_claim_in_progress = false

func _decline_single_player_extra_attempt() -> void:
	_remove_single_player_last_chance_popup()
	GameSession.resolve_deferred_loss()

func _return_to_single_player_last_chance_from_coin_store() -> void:
	show_game_screen()
	call_deferred("_show_single_player_last_chance_popup", false)

func _close_single_player_retry_popup() -> void:
	single_player_retry_after_loss = false
	_remove_single_player_theme_popup()
	show_menu()

func _single_player_embedded_question_active() -> bool:
	return false

func _start_single_player_question(level_index: int, word_slot: int) -> void:
	# Landscape/base implementations that do not provide the quiz UI can still
	# play the replaced word instead of getting stuck on the level slot.
	_start_single_player_word(level_index, word_slot)

func _start_next_single_player_word(level_index: int) -> void:
	if _single_player_level_selected_theme(level_index) < 0:
		_show_single_player_level_popup(level_index)
		return
	var next_slot: int = _single_player_next_unplayed_word_slot(level_index)
	if next_slot < 0:
		_open_next_single_player_level()
		return
	if next_slot == _single_player_level_question_slot_index(level_index):
		_start_single_player_question(level_index, next_slot)
	else:
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
	_reset_single_player_extra_attempt_offers()
	game_finished = false
	last_result_data = {}
	GameState.current_mode = GameState.GameMode.SINGLE_PLAYER
	var word := WordData.new(
		str(word_info.get("text", "")),
		float(word_info.get("difficulty", 0.0)),
		int(word_info.get("theme_index", -1)),
		int(word_info.get("word_index", -1))
	)
	GameState.mark_single_player_word_shown(
		Database.current_language,
		word.theme_index,
		word.index,
		Database.get_words_by_index(word.theme_index, 0).size(),
		word.text,
		false
	)
	GameSession.start_round(word, GameState.GameMode.SINGLE_PLAYER)
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
func _confirm_clear_theme(theme_index: int, return_to_tasks: bool = false) -> void:
	WordManager.clear_the_theme(theme_index)
	_remove_clear_theme_popup()
	if return_to_tasks:
		show_tasks()
	else:
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
	GameState.current_mode = GameState.GameMode.CLASSIC
	GameSession.start_new_round(theme_index)
	show_game_screen()

func _exit_game_warning_text() -> String:
	if GameState.current_mode == GameState.GameMode.SINGLE_PLAYER:
		return tr("EXIT_LEVEL_HEART_WARNING")
	return tr("EXIT_PROGRESS_WARNING")

func _exit_game_title_text() -> String:
	if GameState.current_mode == GameState.GameMode.SINGLE_PLAYER:
		return tr("EXIT_LEVEL_CONFIRM")
	return tr("EXIT_GAME_CONFIRM")

func _confirm_exit_game(confirmed_by_popup: bool = false) -> void:
	_remove_exit_game_popup()
	if GameState.current_mode == GameState.GameMode.SINGLE_PLAYER:
		_forfeit_single_player_round(confirmed_by_popup)
		return
	var return_to_custom_word: bool = GameState.current_mode == GameState.GameMode.TWO_PLAYER
	_discard_round_for_navigation()
	if return_to_custom_word:
		_preserve_custom_word_on_next_show = true
		show_custom_word()
	else:
		show_tasks()

func _discard_round_for_navigation() -> void:
	result_transition_generation += 1
	round_result_delay_requested = false
	GameSession.discard_current_round()
	game_finished = false
	last_result_data = {}
	single_player_active_level_index = -1
	single_player_active_word_slot = -1

func _single_player_forfeit_reward_data(source_result: Dictionary, level_index: int) -> Dictionary:
	var result: Dictionary = source_result.duplicate(true)
	var word_count: int = maxi(_single_player_level_word_count(level_index), 1)
	var word_slot: int = clampi(single_player_active_word_slot, 0, word_count - 1)
	result["title"] = _single_player_level_failed_label()
	result["lines"] = [_single_player_level_failed_label()]
	result["single_player_level_index"] = level_index
	result["single_player_word_slot"] = word_slot
	result["single_player_total_count"] = word_count
	result["single_player_level_completed"] = false
	result["single_player_level_perfect"] = false
	result["single_player_chain_failed"] = true
	result["single_player_chain_ended"] = true
	result["single_player_unlocked_next"] = false
	result["single_player_completion_bonus"] = 0
	result["single_player_forfeit_reward"] = true
	result["single_player_reward_granted"] = false
	return result

func _forfeit_single_player_round(show_failure_reward: bool = false) -> void:
	var level_index: int = single_player_active_level_index
	var level_completed: bool = bool(last_result_data.get("single_player_level_completed", false))
	var chain_failed: bool = bool(last_result_data.get("single_player_chain_failed", false))
	var forfeit_result: Dictionary = last_result_data.duplicate(true)
	var reward_was_granted: bool = game_finished and last_result_is_win
	# A result transition may already be waiting for the letter-marker animation.
	# In that case the round has already been recorded, so only cancel the delayed
	# result screen and return to the level without recording it a second time.
	result_transition_generation += 1
	round_result_delay_requested = false
	var should_lose_heart: bool = false
	if (
		!game_finished
		and (GameSession.is_active or _single_player_embedded_question_active())
		and level_index >= 0
		and single_player_active_word_slot >= 0
	):
		game_finished = true
		forfeit_result = _single_player_mark_current_word_finished({}, false, false, false, false)
		chain_failed = true
		should_lose_heart = true
	elif game_finished and level_index >= 0 and !level_completed and !chain_failed:
		# Leaving after a successfully guessed word still forfeits the unfinished
		# chain, but intentionally leaves adaptive difficulty unchanged.
		GameState.record_single_player_forfeit(Database.current_language, false)
		should_lose_heart = true
	if should_lose_heart:
		GameState.lose_heart(false)
	if level_index >= 0 and !level_completed:
		GameState.reset_single_level_attempt(
			Database.current_language,
			level_index,
			true,
			true,
			false
		)
		_invalidate_single_player_level_cache()
	if show_failure_reward and should_lose_heart and level_index >= 0 and !level_completed:
		# A successfully guessed word has already credited its regular reward before
		# the result Back button can open the confirmation popup. Revoke that credit
		# so a confirmed forfeit has the same zero-reward outcome as leaving mid-word.
		if reward_was_granted:
			GameState.spend_soft_currency(GameState.WORD_REWARD_COINS, false)
		GameState.save_game()
		last_result_data = _single_player_forfeit_reward_data(forfeit_result, level_index)
		last_result_is_win = false
		hero_force_default_pose = false
		_show_single_player_forfeit_reward_screen()
		return
	if should_lose_heart or (level_index >= 0 and !level_completed):
		GameState.save_game()
	GameSession.discard_current_round()
	game_finished = false
	last_result_data = {}
	single_player_active_word_slot = -1
	show_menu()

func _remove_exit_game_popup() -> void:
	var popup_nodes: Array = get_tree().get_nodes_in_group("exit_game_popup")
	for node: Node in popup_nodes:
		if is_instance_valid(node) and node.get_parent() != null:
			node.get_parent().remove_child(node)
			node.queue_free()
func _custom_word_random_label() -> String:
	return tr("RANDOM_WORD")

func _custom_word_start_label() -> String:
	return Database.tr_text(77, "Start game")

func _on_custom_word_text_changed(value: String) -> void:
	_reset_custom_word_check_feedback()
	var previous_word_text: String = custom_word_text
	custom_word_text = _normalize_custom_word_input(value)
	if custom_word_edit != null and custom_word_edit.text != custom_word_text:
		var caret_column: int = custom_word_edit.caret_column
		custom_word_edit.text = custom_word_text
		custom_word_edit.caret_column = mini(caret_column, custom_word_edit.text.length())
	_sync_custom_word_input_visual()
	# When the player appends letters, animate only the newly entered glyphs with
	# the exact same reveal bounce as letters on the guessing screen.
	if (
		custom_word_input_visual != null
		and is_instance_valid(custom_word_input_visual)
		and custom_word_text.length() > previous_word_text.length()
		and custom_word_text.begins_with(previous_word_text)
	):
		custom_word_input_visual.call_deferred(
			"play_new_letter_bounce",
			previous_word_text.length()
		)
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
	var should_disable: bool = !has_word
	# A random-word roll keeps the CTA enabled. Avoid assigning the same state:
	# StageLongButton would otherwise recreate its looping attention tween and
	# visibly restart the cycle on every roll.
	if bool(custom_word_start_button.get("button_disabled")) != should_disable:
		custom_word_start_button.set("button_disabled", should_disable)
	if bool(custom_word_start_button.get("attention_bounce_enabled")) != has_word:
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
	if custom_word_input_visual != null and is_instance_valid(custom_word_input_visual):
		custom_word_input_visual.call_deferred("play_word_bounce")
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
		_set_temporary_custom_word_input_color(UI_PALETTE.ERROR_SOFT)
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
			UI_PALETTE.SUCCESS_SOFT if found else UI_PALETTE.ERROR_SOFT
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
			_set_custom_word_input_color(UI_PALETTE.ERROR_SOFT)
			custom_word_edit.placeholder_text = Database.tr_text(64, "Error! Something goes wrong.")
		return
	custom_word_text = word
	game_finished = false
	last_result_data = {}
	single_player_active_level_index = -1
	single_player_active_word_slot = -1
	GameState.current_mode = GameState.GameMode.TWO_PLAYER
	GameSession.start_custom_round(word, custom_comment_text)
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
	# ghosts on the gameplay screen. Rebuild it from runtime stage controls.
	hero_force_default_pose = false
	_clear()
	game_screen_visible = true
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

func _hero_type() -> int:
	if GameState.settings.size() > 5 and int(GameState.settings[5]) == 2:
		return FlashStageSymbol.HeroType.EL_TIGRE
	return FlashStageSymbol.HeroType.LUCKY

func _hero_animation_time() -> float:
	# Flash currentFrame is one-based: its original `7 - currentFrame` counter
	# maps zero mistakes to outer frame index 0 and the sixth mistake to index 6.
	if hero_force_default_pose:
		return _hero_animation_time_for_mistakes(0)
	return _hero_animation_time_for_mistakes(GameSession.mistakes)

func _current_hero_round_token() -> int:
	if GameSession.word_data == null:
		return 0
	return GameSession.word_data.get_instance_id()

func _sync_hero_pose_state() -> void:
	var round_token: int = _current_hero_round_token()
	var frame_index: int = 0 if hero_force_default_pose else _hero_frame_index_for_mistakes(GameSession.mistakes)
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
	if hero_force_default_pose:
		return false
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
	if GameSession.has_deferred_loss():
		return
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
	var should_defer_loss: bool = (
		guess_is_available
		and !is_correct_letter
		and GameState.current_mode == GameState.GameMode.SINGLE_PLAYER
		and GameSession.get_remaining_attempts() == 1
	)
	round_result_delay_requested = true
	var guess_was_correct: bool = GameSession.guess(letter, should_defer_loss)
	round_result_delay_requested = false
	if guess_is_available:
		_play_letter_feedback_sound(guess_was_correct)
	if GameSession.has_deferred_loss():
		call_deferred("_show_single_player_last_chance_popup")
		return
	# A round signal can replace the current screen synchronously. Never let the
	# previous word's animation appear over the newly built result screen.
	if round_token_before_guess != _current_hero_round_token():
		return
	if GameSession.mistakes > previous_mistakes:
		_play_hero_wrong_guess_animation(GameSession.mistakes)
	elif guess_was_correct and should_play_recovery:
		_play_hero_correct_guess_animation()

func _use_open_hint() -> void:
	if !_can_activate_hint(GameState.HINT_OPEN_LETTER, GameSession.can_use_open_letter_hint()):
		return
	# If the hint reveals the final letter, keep the gameplay screen visible long
	# enough for the standard circle-and-bounce feedback to finish.
	round_result_delay_requested = true
	GameSession.use_open_letter_hint()
	round_result_delay_requested = false

func _use_remove_hint() -> void:
	if !_can_activate_hint(GameState.HINT_REMOVE_WRONG, GameSession.can_use_remove_wrong_hint()):
		return
	GameSession.use_remove_wrong_hint()

func _use_comment_hint() -> void:
	if GameSession.comment_hint_unlocked:
		_show_word_comment_popup()
		return
	if !_can_activate_hint(GameState.HINT_COMMENT, GameSession.can_unlock_comment_hint()):
		return
	if GameSession.unlock_comment_hint():
		_show_word_comment_popup()

func _can_activate_hint(hint_key: String, hint_is_available: bool) -> bool:
	if !hint_is_available:
		return false
	if !GameState.can_pay_for_hint(hint_key):
		_open_coin_store(Callable(self, "show_game_screen"))
		return false
	return true

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
	# Keep the hero in the pose reached during the round. The pristine/default
	# pose is reserved for the Single Player reward interstitial and should never
	# replace the gameplay pose just because the word was solved.
	hero_force_default_pose = false
	var defer_single_player_final_reward: bool = (
		is_win
		and GameState.current_mode == GameState.GameMode.SINGLE_PLAYER
		and single_player_active_level_index >= 0
		and single_player_active_word_slot
			== _single_player_level_word_count(single_player_active_level_index) - 1
	)
	last_result_data = GameSession.finish_result(is_win, !defer_single_player_final_reward)
	if GameState.current_mode == GameState.GameMode.SINGLE_PLAYER:
		if !is_win:
			GameState.lose_heart(false)
		last_result_data = _single_player_mark_current_word_finished(
			last_result_data,
			is_win,
			true,
			defer_single_player_final_reward
		)
		# Sequential level play normally guarantees that the last word completes
		# the chain. If imported/corrupt progress says otherwise, preserve the
		# ordinary per-word reward instead of silently dropping it.
		if (
			defer_single_player_final_reward
			and !bool(last_result_data.get("single_player_level_completed", false))
		):
			GameState.add_soft_currency(GameState.WORD_REWARD_COINS)
	# All round results now use the same in-place presentation. In particular,
	# Single Player victories follow Classic exactly instead of entering the old
	# dedicated win transition after the final letter feedback delay.
	_show_in_place_round_result(is_win)

func _open_single_player_retry_theme_popup() -> void:
	var level_index: int = single_player_active_level_index
	if level_index < 0:
		show_menu()
		return
	GameState.reset_single_level_attempt(Database.current_language, level_index)
	_invalidate_single_player_level_cache()
	GameSession.discard_current_round()
	game_finished = false
	last_result_data = {}
	single_player_active_word_slot = -1
	_show_single_player_level_popup(level_index, -1, true)

func _result_continue_button_text() -> String:
	return Database.tr_text(3, "Continue")

func _result_continue_action() -> Callable:
	match GameState.current_mode:
		GameState.GameMode.TWO_PLAYER:
			return Callable(self, "_continue_two_player_result")
		GameState.GameMode.SINGLE_PLAYER:
			return Callable(self, "_continue_single_player_result")
		_:
			return Callable(self, "_continue_classic_result")

func _result_back_action() -> void:
	if (
		GameState.current_mode == GameState.GameMode.SINGLE_PLAYER
		and last_result_is_win
		and !bool(last_result_data.get("single_player_level_completed", false))
	):
		_show_exit_game_popup()
		return
	_confirm_exit_game()

func _continue_classic_result() -> void:
	start_classic_game(max(0, GameSession.theme_id))

func _continue_two_player_result() -> void:
	show_custom_word()

func _continue_single_player_result() -> void:
	var level_index: int = single_player_active_level_index
	var level_completed: bool = bool(last_result_data.get("single_player_level_completed", false))
	if !last_result_is_win:
		_open_single_player_retry_theme_popup()
		return
	if level_completed:
		GameSession.discard_current_round()
		game_finished = false
		last_result_data = {}
		single_player_active_word_slot = -1
		show_menu()
	else:
		_start_next_single_player_word(level_index)

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
	if event is InputEventKey and event.pressed and !event.echo:
		if event.keycode == KEY_ESCAPE:
			if !get_tree().get_nodes_in_group("single_player_last_chance_popup").is_empty():
				_decline_single_player_extra_attempt()
			elif (
				single_player_retry_after_loss
				and !get_tree().get_nodes_in_group("single_player_theme_popup").is_empty()
			):
				_close_single_player_retry_popup()
			elif game_finished:
				_result_back_action()
			elif GameSession.is_active:
				_show_exit_game_popup()
			return
	if game_finished or !GameSession.is_active:
		return
	if event is InputEventKey and event.pressed and !event.echo:
		var letter := OS.get_keycode_string(event.keycode).to_upper()
		letter = WordManager.normalize_word(letter)
		if letter.length() == 1 and Database.get_alphabet().has(letter):
			_press_letter(letter)
