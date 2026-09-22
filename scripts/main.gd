extends Node2D

const QUIZ_SELECTION: GDScript = preload("res://scripts/core/quiz_selection.gd")

const GAME_DESIGN: GDScript = preload("res://scripts/core/game_design_config.gd")
const HERO_ANIMATION_SPEED_SCALE: float = 1.0
const HERO_OUTER_FRAME_SAMPLE_OFFSET: float = 0.020833333333333332
const HERO_NESTED_FRAME_SAMPLE_OFFSET: float = 0.020833333333333332
const HERO_MOV_START_FRAME_TIME: float = 0.0
const HERO_MOV_IDLE_FRAME_TIME: float = 0.16666666666666666 + HERO_NESTED_FRAME_SAMPLE_OFFSET
const HERO_MOV_RECOVERY_START_FRAME_TIME: float = 0.20833333333333334 + HERO_NESTED_FRAME_SAMPLE_OFFSET
const HERO_MOV_RECOVERY_END_FRAME_TIME: float = 0.375 + HERO_NESTED_FRAME_SAMPLE_OFFSET
const HERO_TYPE_1_TERMINAL_END_FRAME_TIME: float = 1.6666666666666667
const HERO_TYPE_2_TERMINAL_END_FRAME_TIME: float = 0.5
const CUSTOM_WORD_MAX_LENGTH: int = 20
const CUSTOM_WORD_LATIN_ALPHABET_TEXT: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
const CUSTOM_WORD_CYRILLIC_ALPHABET_TEXT: String = "АБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ"
var RANDOM_CUSTOM_WORD_MAX_LENGTH: int = GAME_DESIGN.get_int_range(
	"gameplay.random_custom_word.max_length", 7, 1, 64
)
var RANDOM_CUSTOM_WORD_DIFFICULTY_FILTER: int = GAME_DESIGN.get_int(
	"gameplay.random_custom_word.difficulty_filter", 2
)
var SETTINGS_TOGGLE_ON_VIBRATION_MS: int = GAME_DESIGN.get_int(
	"gameplay.vibration.settings_toggle_ms", 35
)
var CUSTOM_WORD_NOT_FOUND_VIBRATION_MS: int = GAME_DESIGN.get_int(
	"gameplay.vibration.custom_word_not_found_ms", 35
)
var CUSTOM_WORD_RESULT_COLOR_DURATION: float = GAME_DESIGN.get_float(
	"timings.custom_word_result_color_seconds", 1.81
)
const UI_PALETTE: GDScript = preload("res://scripts/ui/ui_palette.gd")
var CUSTOM_WORD_CHECK_DOTS_INTERVAL: float = GAME_DESIGN.get_float_range(
	"timings.custom_word_check_dots_seconds", 0.4, 0.01, 60.0
)
const CUSTOM_WORD_FIELD_DEFAULT_TINT := UI_PALETTE.MARKER_INFO
const SOUND_SETTING_INDEX: int = 3
const APP_VERSION_FALLBACK: String = "3.0.0"
var SINGLE_PLAYER_THEME_OPTIONS_PER_LEVEL: int = GAME_DESIGN.get_int_range(
	"progression.theme_options_per_level", 3, 1, 10
)
var SINGLE_PLAYER_GUIDED_ONBOARDING_REQUIRED_START_LEVEL: int = GAME_DESIGN.get_int_range(
	"progression.guided_onboarding.required_start_level", 3, 1, 1_000_000
)
var SINGLE_PLAYER_THEME_REFRESH_COST: int = GAME_DESIGN.get_int("economy.theme_reroll_cost", 25)
var SINGLE_PLAYER_EXTRA_ATTEMPT_COST: int = GAME_DESIGN.get_int(
	"economy.extra_attempts.base_cost", 25
)
var SINGLE_PLAYER_EXTRA_ATTEMPT_COST_STEP: int = GAME_DESIGN.get_int(
	"economy.extra_attempts.cost_step", 5
)
var SINGLE_PLAYER_EXTRA_ATTEMPT_COUNT: int = GAME_DESIGN.get_int(
	"economy.extra_attempts.base_count", 2
)
var SINGLE_PLAYER_EXTRA_ATTEMPT_COUNT_STEP: int = GAME_DESIGN.get_int(
	"economy.extra_attempts.count_step", 1
)
var SINGLE_PLAYER_EXTRA_ATTEMPT_COUNT_STEP_INTERVAL: int = GAME_DESIGN.get_int_range(
	"economy.extra_attempts.count_step_interval", 2, 1, 1000000
)
var HEART_REFILL_COST: int = GAME_DESIGN.get_int("economy.hearts.refill_cost", 100)
var SINGLE_PLAYER_CHAIN_DIFFICULTY_SPREAD: float = GAME_DESIGN.get_float_range(
	"difficulty.chain_spread", 0.06, 0.0, 1.0
)
var SINGLE_PLAYER_BONUS_LEVEL_DIFFICULTY_OFFSET: float = GAME_DESIGN.get_float_range(
	"difficulty.bonus_level_offset", 0.01, 0.0, 1.0
)
var SINGLE_PLAYER_PLAYED_WORD_PENALTY: float = GAME_DESIGN.get_float(
	"difficulty.played_word_penalty", 0.05
)
var SINGLE_PLAYER_GUESSED_WORD_PENALTY: float = GAME_DESIGN.get_float(
	"difficulty.guessed_word_penalty", 0.12
)
var SINGLE_PLAYER_WORD_PICK_JITTER: float = GAME_DESIGN.get_float(
	"difficulty.word_pick_jitter", 0.012
)
var SINGLE_PLAYER_QUIZ_PICK_WINDOW: float = GAME_DESIGN.get_float_range(
	"difficulty.quiz_pick_window", 0.08, 0.0, 1.0
)
var SINGLE_PLAYER_QUIZ_FIRST_SLOT_RATIO: float = GAME_DESIGN.get_float_range(
	"progression.quiz.first_slot_ratio", 0.5, 0.0, 1.0
)
var SINGLE_PLAYER_QUIZ_LAST_SLOT_END_OFFSET: int = GAME_DESIGN.get_int_range(
	"progression.quiz.last_slot_end_offset", 2, 1, 1000
)
var SINGLE_PLAYER_QUIZ_SECOND_LEVEL_SLOT: int = GAME_DESIGN.get_int(
	"progression.quiz.second_level_slot", 0
)
var SINGLE_PLAYER_QUIZ_ONBOARDING_SLOT: int = GAME_DESIGN.get_int(
	"progression.quiz.onboarding_slot", 1
)
const DIFFICULTY_HARD_NORMAL_TINT := UI_PALETTE.CHALLENGE_NORMAL
const DIFFICULTY_HARD_PRESSED_TINT := UI_PALETTE.CHALLENGE_PRESSED
const DIFFICULTY_HARD_SELECTED_TINT := UI_PALETTE.CHALLENGE_SELECTED
const DIFFICULTY_HARD_OUTLINE_COLOR := UI_PALETTE.CHALLENGE_OUTLINE
const AUTHOR_VK_URL: String = "https://vk.ru/trinarr_tavern"
const AUTHOR_EMAIL_URL: String = "mailto:trinarr@mail.ru"
const LEGAL_TERMS_PROJECT_SETTING: String = "legal/terms_of_service_url"
const LEGAL_TERMS_EN_PROJECT_SETTING: String = "legal/terms_of_service_url_en"
const LEGAL_PRIVACY_PROJECT_SETTING: String = "legal/privacy_policy_url"
const LEGAL_PRIVACY_EN_PROJECT_SETTING: String = "legal/privacy_policy_url_en"
const FLASH_STAGE_CONTROL_SCRIPT: GDScript = preload("res://scripts/ui/flash_stage_control.gd")
const FLASH_STAGE_BUTTON_SCRIPT: GDScript = preload("res://scripts/ui/flash_stage_button.gd")
const BUTTON_TEXT_STYLE_SCRIPT: GDScript = preload("res://scripts/ui/button_text_style.gd")
const STAGE_LONG_BUTTON_SCRIPT: GDScript = preload("res://scripts/ui/stage_long_button.gd")
const LONG_BUTTON_COLOR_ORANGE: int = 0
const LONG_BUTTON_COLOR_GREEN: int = 1
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
const UI_FONTS: GDScript = preload("res://scripts/ui/ui_fonts.gd")
const UI_SECONDARY_BOLD_FONT: Font = preload("res://fonts/BalsamiqSans-Bold.ttf")
const UI_HEADING_FONT: Font = preload("res://fonts/BalsamiqSans-Regular.ttf")
var UI_DISPLAY_FONT: Font = UI_FONTS.display_font()
var UI_BUTTON_FONT: Font = UI_FONTS.button_font()
var UI_REGULAR_FONT: Font = UI_FONTS.regular_font()
var UI_PRIMARY_FONT: Font = UI_FONTS.regular_font()
var UI_QUESTION_COMMENT_FONT: Font = UI_FONTS.question_comment_font()
const UI_HEADING_FONT_SCALE: float = 1.12

const RESULT_SEARCH_ICON: Texture2D = preload("res://flash_assets/result_search_icon_343.png")
const SOFT_CURRENCY_COIN_TEXTURE: Texture2D = preload("res://flash_assets/soft_currency_coin.png")
const STAR_CURRENCY_TEXTURE: Texture2D = preload("res://flash_assets/star_currency_icon.png")
const SINGLE_PLAYER_REFRESH_ICON: Texture2D = preload("res://flash_assets/custom_word_refresh_icon_341.png")
const ABOUT_VK_ICON: Texture2D = preload("res://flash_assets/about_vk_icon_87.png")
const ABOUT_MAIL_ICON: Texture2D = preload("res://flash_assets/about_mail_icon_86.png")
const ABOUT_VK_ICON_SIZE := Vector2(34.0, 20.0)
const ABOUT_MAIL_ICON_SIZE := Vector2(33.0, 27.0)
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
const MODAL_DIMMER_FADE_IN_DURATION: float = 0.20
const MODAL_DIMMER_FADE_OUT_DURATION: float = 0.16

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
var single_player_level_cache_unlocked_theme_count: int = -1
var single_player_level_cache_difficulty: float = -1.0
var single_player_popup_level_index: int = -1
var single_player_popup_selected_theme: int = -1
var single_player_popup_theme_panels: Dictionary = {}
var single_player_popup_stage_content: Control = null
var single_player_popup_theme_card_nodes: Array[Node] = []
var single_player_popup_play_button: Control = null
var single_player_popup_return_to_menu_on_close: bool = false
var single_player_retry_after_loss: bool = false
var single_player_extra_attempt_offer_count: int = 0
var single_player_extra_attempt_current_cost: int = SINGLE_PLAYER_EXTRA_ATTEMPT_COST
var single_player_extra_attempt_current_count: int = SINGLE_PLAYER_EXTRA_ATTEMPT_COUNT
var single_player_extra_attempt_claim_in_progress: bool = false
var custom_word_edit: LineEdit
var custom_word_input_visual: Control = null
var custom_word_text: String = ""
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
var settings_word_language_changed: bool = false
var pending_letter_markers := PackedStringArray()
var pending_letter_marker_is_correct: bool = false
var result_transition_generation: int = 0
var last_result_sound_key: String = ""
var coin_store_return_action: Callable = Callable()
var stars_balance_label: Label = null
var heart_count_label: Label = null
var heart_status_label: Label = null
var heart_add_badge_visual: Control = null
var heart_counter_button: Control = null
var _last_heart_count_for_animation: int = -1
var _preserve_custom_word_on_next_show: bool = false
var heart_refill_continue_action: Callable = Callable()
var heart_refill_store_return_action: Callable = Callable()
var heart_refill_cancel_action: Callable = Callable()
var heart_refill_reward_acquired: bool = false
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
	if !GameState.stars_changed.is_connected(_on_stars_changed):
		GameState.stars_changed.connect(_on_stars_changed)
	if !GameState.hearts_changed.is_connected(_on_hearts_changed):
		GameState.hearts_changed.connect(_on_hearts_changed)
	_last_heart_count_for_animation = GameState.get_hearts()
	ConsentRegion.changed.connect(_on_ad_region_changed)
	ConsentRegion.refresh()
	_initialize_yandex_ads_from_saved_consent()
	show_menu()
	_prewarm_runtime_assets()

func _on_ad_region_changed() -> void:
	_initialize_yandex_ads_from_saved_consent()

func _initialize_yandex_ads_from_saved_consent() -> bool:
	var ads_service: Node = get_node_or_null("/root/YandexAdsService")
	if !GameState.has_accepted_legal_documents() or !GameState.has_ad_personalization_decision():
		# Expiry/failure also invalidates previously personalized cached ads.
		if ads_service != null and ads_service.has_method("set_user_consent"):
			ads_service.call("set_user_consent", false)
		return false
	if ads_service == null or !is_instance_valid(ads_service):
		return false
	if !ads_service.has_method("initialize_after_consent"):
		return false
	return bool(ads_service.call(
		"initialize_after_consent",
		GameState.allows_ad_personalization()
	))

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

func show_custom_word() -> void:
	pass

func show_result_screen(_is_win: bool, _data: Dictionary = {}) -> void:
	pass

func show_coin_store() -> void:
	pass

func _stage_currency_counter(_return_action: Callable, _rect: Rect2 = Rect2()) -> void:
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

func _on_stars_changed(balance: int) -> void:
	var resolved_balance: int = maxi(balance, 0)
	var balance_text: String = _soft_currency_balance_text(resolved_balance)
	for balance_node: Node in get_tree().get_nodes_in_group(&"stars_balance_label"):
		var balance_label := balance_node as Label
		if balance_label != null and is_instance_valid(balance_label):
			balance_label.text = balance_text
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

func _show_single_player_level_popup(
	_level_index: int,
	_selected_theme: int = -1,
	_retry_after_loss: bool = false,
	_return_to_menu_on_close: bool = false
) -> void:
	pass

func _show_single_player_last_chance_popup(_advance_offer_cost: bool = true) -> void:
	pass

func _show_heart_refill_popup(
	_continue_action: Callable = Callable(),
	_store_return_action: Callable = Callable(),
	_cancel_action: Callable = Callable(),
	_reward_acquired: bool = false
) -> void:
	pass

func _show_in_place_round_result(_is_win: bool, _animated: bool = true) -> void:
	pass

func _show_single_player_forfeit_reward_screen(_show_interstitial: bool = false) -> void:
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

func _clear(preserved_content: Control = null) -> void:
	game_screen_visible = false
	_capture_hero_animation_phase()
	result_transition_generation += 1
	custom_word_color_generation += 1
	pending_letter_markers.clear()
	pending_letter_marker_is_correct = false
	_clear_hero_animation_overlay()
	_cancel_custom_word_check()
	custom_word_check_button = null
	custom_word_start_button = null
	stars_balance_label = null
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
	custom_word_edit = null
	custom_word_input_visual = null
	for child: Node in ui.get_children():
		if child == preserved_content:
			continue
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
	label.add_theme_font_override("font", UI_DISPLAY_FONT)
	BUTTON_TEXT_STYLE_SCRIPT.apply_display(label)
	return label

func _heading_font_size(font_size: int) -> int:
	return maxi(1, int(round(float(font_size) * UI_HEADING_FONT_SCALE)))

func _stage_button(rect: Rect2, callable: Callable, text: String = "", font_size: int = 20) -> Button:
	var button: Button = FLASH_STAGE_BUTTON_SCRIPT.new() as Button
	button.text = text.to_upper()
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.focus_mode = Control.FOCUS_NONE
	button.flat = true
	button.add_theme_font_override("font", UI_BUTTON_FONT)
	_apply_transparent_button_style(button, text != "", UI_FONTS.display_button_font_size(font_size))
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
	dimmer.color = Color(0.0, 0.0, 0.0, 0.0)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	dimmer.gui_input.connect(_on_modal_dimmer_input.bind(dimmer, close_callable))
	content.add_child(dimmer)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Let the background darkness arrive together with the popup's opening bounce
	# instead of snapping to the final alpha on the first frame.
	var dimmer_target_color := Color(0.0, 0.0, 0.0, alpha)
	var dimmer_tween := create_tween()
	dimmer_tween.bind_node(dimmer)
	dimmer_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var dimmer_fade_in := dimmer_tween.tween_property(
		dimmer,
		"color",
		dimmer_target_color,
		MODAL_DIMMER_FADE_IN_DURATION
	)
	dimmer_fade_in.set_trans(Tween.TRANS_QUAD)
	dimmer_fade_in.set_ease(Tween.EASE_OUT)

func _spawn_modal_dimmer_fade_out(popup_layer: CanvasLayer, source_dimmer: ColorRect) -> void:
	if (
		popup_layer == null
		or !is_instance_valid(popup_layer)
		or source_dimmer == null
		or !is_instance_valid(source_dimmer)
		or source_dimmer.color.a <= 0.001
	):
		return

	# The popup itself disappears immediately, while a non-interactive copy of its
	# dimmer remains for the short fade-out. This keeps navigation responsive and
	# also lets a replacement popup cross-fade its own dimmer without blocking input.
	var fade_layer := CanvasLayer.new()
	fade_layer.name = "ModalDimmerFadeOutCanvas"
	fade_layer.layer = popup_layer.layer
	add_child(fade_layer)

	var fade_root := Control.new()
	fade_root.name = "ModalDimmerFadeOutRoot"
	fade_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(fade_root)
	fade_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var fade_dimmer := ColorRect.new()
	fade_dimmer.name = "ModalDimmerFadeOut"
	fade_dimmer.color = source_dimmer.color
	fade_dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_root.add_child(fade_dimmer)
	fade_dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var transparent_color := fade_dimmer.color
	transparent_color.a = 0.0
	var fade_tween := create_tween()
	fade_tween.bind_node(fade_layer)
	fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var dimmer_fade_out := fade_tween.tween_property(
		fade_dimmer,
		"color",
		transparent_color,
		MODAL_DIMMER_FADE_OUT_DURATION
	)
	dimmer_fade_out.set_trans(Tween.TRANS_QUAD)
	dimmer_fade_out.set_ease(Tween.EASE_OUT)
	fade_tween.finished.connect(fade_layer.queue_free, CONNECT_ONE_SHOT)

func _remove_popup_group_with_dimmer_fade(group_name: StringName) -> void:
	var popup_nodes: Array = get_tree().get_nodes_in_group(group_name)
	for node: Node in popup_nodes:
		if !is_instance_valid(node) or node.get_parent() == null:
			continue
		var popup_layer := node as CanvasLayer
		if popup_layer != null:
			var dimmer := popup_layer.find_child("ModalDimmer", true, false) as ColorRect
			_spawn_modal_dimmer_fade_out(popup_layer, dimmer)
		node.get_parent().remove_child(node)
		node.queue_free()

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
	button.call("configure", text, UI_FONTS.display_button_font_size(font_size), disabled, disabled_overlay_alpha, use_normal_texture_when_disabled, selected)
	button.call("set_color_preset", color_preset)
	button.set("attention_bounce_enabled", attention_bounce)
	_connect_stage_button_action(button, callable)
	content.add_child(button)
	button.stage_rect = rect
	return button

func _stage_round_button(rect: Rect2, callable: Callable, icon_text: String = "", disabled: bool = false, selected: bool = false, disabled_overlay_alpha: float = 0.32, color_preset: int = ROUND_BUTTON_COLOR_BLUE) -> Control:
	var button: FlashStageTextureButton = STAGE_ROUND_BUTTON_SCRIPT.new() as FlashStageTextureButton
	button.call("configure_text", icon_text, disabled, selected, UI_FONTS.display_button_font_size(28), disabled_overlay_alpha)
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
	if show_text:
		BUTTON_TEXT_STYLE_SCRIPT.apply_display(button)
	else:
		BUTTON_TEXT_STYLE_SCRIPT.apply(button, Color.TRANSPARENT, Color.TRANSPARENT, 0)
	button.add_theme_font_size_override("font_size", font_size)
func _selected_character_id() -> int:
	if GameState.settings.size() > 5:
		return int(GameState.settings[5])
	return 1
func _set_settings_word_language(language_code: String) -> void:
	var previous_language: String = GameState.word_language
	GameState.set_word_language(language_code)
	Database.load_word_language(GameState.word_language)
	_invalidate_single_player_level_cache()
	_refresh_settings_word_language_buttons()
	if GameState.word_language != previous_language:
		settings_word_language_changed = true

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

func _legal_document_url(document_type: String) -> String:
	var use_russian_documents: bool = Database.interface_language == "ru"
	var setting_key: String
	if document_type == "terms":
		setting_key = (
			LEGAL_TERMS_PROJECT_SETTING
			if use_russian_documents
			else LEGAL_TERMS_EN_PROJECT_SETTING
		)
	else:
		setting_key = (
			LEGAL_PRIVACY_PROJECT_SETTING
			if use_russian_documents
			else LEGAL_PRIVACY_EN_PROJECT_SETTING
		)
	return str(ProjectSettings.get_setting(setting_key, "")).strip_edges()

func _open_legal_document(document_type: String) -> void:
	var document_url: String = _legal_document_url(document_type)
	if document_url.is_empty():
		push_warning("Legal document URL is not configured: " + document_type)
		return
	OS.shell_open(document_url)

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

func _style_single_player_level_button(button: Control, level_index: int) -> Control:
	if !_single_player_is_bonus_level(level_index):
		return button
	return _style_hard_button(button)

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
	return tr("CHALLENGE_SHORT_LABEL")

func _single_player_level_failed_label() -> String:
	return tr("LEVEL_FAILURE")

func _single_player_level_completed_reward_label(bonus_coins: int) -> String:
	return tr("LEVEL_COMPLETED_BONUS") % maxi(bonus_coins, 0)

func _single_player_choose_theme_label() -> String:
	return tr("CHOOSE_THEME")

func _single_player_theme_start_label() -> String:
	return tr("PLAY_GAME")

func _single_player_next_level_index() -> int:
	return maxi(GameState.get_single_player_unlocked_level(Database.current_language), 0)

func _single_player_hides_close_controls(level_index: int) -> bool:
	return (
		!GameState.is_single_player_guided_onboarding_completed()
		and level_index >= 0
		and level_index + 1 < SINGLE_PLAYER_GUIDED_ONBOARDING_REQUIRED_START_LEVEL
	)

func _single_player_theme_selection_is_locked(level_index: int) -> bool:
	return (
		!GameState.is_single_player_guided_onboarding_completed()
		and level_index >= 0
		and level_index + 1 <= SINGLE_PLAYER_GUIDED_ONBOARDING_REQUIRED_START_LEVEL
	)

func _persist_guided_single_player_theme_selection(
	level_index: int,
	theme_index: int,
	retry_after_loss: bool
) -> void:
	if (
		!_single_player_theme_selection_is_locked(level_index)
		or theme_index < 0
	):
		return
	GameState.set_active_single_player_session({
		"kind": "theme",
		"language": Database.current_language,
		"level_index": level_index,
		# Theme selection is a resumable level state, but it precedes the first
		# actual word slot. Zero keeps the common save envelope valid without
		# pretending that a round has already started.
		"word_slot": 0,
		"theme_id": Database.get_theme_id(theme_index),
		"data": {
			"retry_after_loss": retry_after_loss,
		},
	})

func _should_auto_resume_guided_single_player() -> bool:
	if GameState.is_single_player_guided_onboarding_completed():
		return false
	if !GameState.has_resumable_single_player_level():
		return false
	var level_index: int = GameState.get_resumable_single_player_level_index()
	if level_index < 0:
		return false
	var active_session: Dictionary = GameState.get_active_single_player_session()
	if str(active_session.get("kind", "")) == "theme":
		# The level-three theme popup still precedes the configured start boundary.
		return _single_player_theme_selection_is_locked(level_index)
	return _single_player_hides_close_controls(level_index)

func _open_next_single_player_level() -> void:
	single_player_active_level_index = _single_player_next_level_index()
	single_player_active_word_slot = -1
	_show_single_player_level_popup(single_player_active_level_index)

func _invalidate_single_player_level_cache() -> void:
	single_player_level_definitions_cache.clear()
	single_player_level_cache_language = ""
	single_player_level_cache_theme_count = -1
	single_player_level_cache_unlocked_theme_count = -1
	single_player_level_cache_difficulty = -1.0

func _single_player_level_word_target(level_index: int) -> int:
	var level_number: int = maxi(level_index + 1, 1)
	return GAME_DESIGN.level_stage_count_with_bonus(level_number)

func _single_player_level_uses_question(level_index: int, word_count: int) -> bool:
	# Levels 2-4 introduce the embedded quiz with an explicit onboarding order.
	# From level 5 onward the normal question-slot rules apply.
	var level_number: int = maxi(level_index + 1, 1)
	return GAME_DESIGN.level_uses_quiz(level_number, word_count)

func _single_player_is_bonus_level(level_index: int) -> bool:
	var level_number: int = level_index + 1
	return GAME_DESIGN.is_bonus_level(level_number)

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

func _single_player_available_theme_indices(word_count: int = 1) -> Array:
	var available_ids: Array[int] = GameState.get_unlocked_theme_ids(Database.current_language)
	var eligible: Array = []
	for theme_index: int in range(Database.get_theme_count()):
		if (
			available_ids.has(Database.get_theme_id(theme_index))
			and Database.get_words_by_index(theme_index, 0).size() >= word_count
		):
			eligible.append(theme_index)
	return eligible

func _single_player_can_reroll_themes(level_index: int) -> bool:
	return _single_player_available_theme_indices(_single_player_level_word_target(level_index)).size() > SINGLE_PLAYER_THEME_OPTIONS_PER_LEVEL

func _single_player_first_offer_unlocked_theme_index(level_index: int) -> int:
	var language: String = Database.current_language
	var completed_levels: int = GameState.get_theme_unlock_completed_levels(language)
	# A theme unlocked by completing level N is first offered on level N + 1.
	# Keep forcing it while that original set is merely reopened, but stop as soon
	# as the player spends the first reroll so every later roll is fully random.
	if level_index != completed_levels or completed_levels <= 0:
		return -1
	if (
		GameState.get_single_level_theme_reroll_state(language, level_index)
		!= GameState.SINGLE_LEVEL_THEME_REROLL_AVAILABLE
	):
		return -1
	var unlock_progress: Dictionary = GameState.get_theme_unlock_reward_progress(
		completed_levels - 1,
		completed_levels
	)
	if !bool(unlock_progress.get("unlocked", false)):
		return -1
	return Database.get_theme_index_by_id(int(unlock_progress.get("theme_id", -1)))

func _single_player_theme_options(level_index: int, level_seed: int, word_count: int) -> Array:
	var eligible: Array = _single_player_available_theme_indices(word_count)
	if eligible.is_empty():
		return []
	var rng := RandomNumberGenerator.new()
	rng.seed = _single_player_seed(level_index, level_seed, 11)
	_single_player_shuffle(eligible, rng)
	var first_offer_theme: int = _single_player_first_offer_unlocked_theme_index(level_index)
	if first_offer_theme >= 0 and eligible.has(first_offer_theme):
		eligible.erase(first_offer_theme)
		eligible.push_front(first_offer_theme)
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

func _single_player_first_unplayed_slot(level_index: int, word_count: int) -> int:
	for slot: int in range(word_count):
		if GameState.get_single_level_word_status(Database.current_language, level_index, slot, word_count) == 0:
			return slot
	return word_count

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
	var saved: Array = GameState.get_single_level_word_assignments(Database.current_language, level_index)
	var first_unplayed: int = _single_player_first_unplayed_slot(level_index, word_count)
	for word_slot in range(mini(word_count, candidates.size())):
		# A saved assignment survives cache invalidation, a restart, and row reordering.
		if word_slot < saved.size() and saved[word_slot] is Dictionary:
			var previous: Dictionary = saved[word_slot]
			if int(previous.get("theme_index", -1)) == theme_index:
				var found: int = -1
				for candidate_index: int in range(candidates.size()):
					var candidate: Dictionary = candidates[candidate_index]
					if (
						(!str(previous.get("id", "")).is_empty() and candidate.get("id", "") == previous.get("id"))
						or Database.word_progress_key_from_text(str(candidate.get("text", ""))) == Database.word_progress_key_from_text(str(previous.get("text", "")))
					):
						found = candidate_index
						break
				if found >= 0:
					var candidate: Dictionary = candidates[found]
					previous["word_index"] = candidate["index"]
					previous["text"] = candidate["text"]
					previous["id"] = candidate.get("id", "")
					candidates.remove_at(found)
					words.append(previous)
					continue
				elif word_slot < first_unplayed:
					# Completed history may contain a word removed in a content update.
					words.append(previous)
					continue
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
			"id": str(picked.get("id", "")),
			"theme_index": theme_index,
			"word_index": int(picked.get("index", 0)),
			"text": str(picked.get("text", "")),
			"difficulty": float(picked.get("difficulty", 0.0)),
			"target_difficulty": slot_target,
		})
	var committed: Array = words.slice(0, mini(first_unplayed + 1, words.size()))
	if committed != saved:
		GameState.set_single_level_word_assignments(Database.current_language, level_index, committed)
	return words

func _single_player_level_question_slot(level_index: int, level_seed: int, word_count: int) -> int:
	if !_single_player_level_uses_question(level_index, word_count):
		return -1
	var saved_slot: int = GameState.get_single_level_question_slot(
		Database.current_language,
		level_index
	)
	var level_number: int = maxi(level_index + 1, 1)
	var first_slot: int = int(floor(float(word_count) * SINGLE_PLAYER_QUIZ_FIRST_SLOT_RATIO))
	var last_slot: int = word_count - SINGLE_PLAYER_QUIZ_LAST_SLOT_END_OFFSET
	# Level 2 introduces the quiz first and finishes with Hangman. Levels 3 and 4
	# keep the quiz in the middle of their new three-stage chains.
	if level_number == 2:
		first_slot = SINGLE_PLAYER_QUIZ_SECOND_LEVEL_SLOT
		last_slot = SINGLE_PLAYER_QUIZ_SECOND_LEVEL_SLOT
	elif GAME_DESIGN.is_quiz_onboarding_level(level_number):
		first_slot = SINGLE_PLAYER_QUIZ_ONBOARDING_SLOT
		last_slot = SINGLE_PLAYER_QUIZ_ONBOARDING_SLOT
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
	target_difficulty: float,
	persist_selection: bool = true
) -> Dictionary:
	var resolved_target_difficulty: float = clampf(target_difficulty, 0.0, 1.0)
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
	var rng := RandomNumberGenerator.new()
	rng.seed = _single_player_seed(level_index, level_seed, theme_index + 809)
	var picked_question: Dictionary = QUIZ_SELECTION.pick(
		questions,
		resolved_target_difficulty,
		SINGLE_PLAYER_QUIZ_PICK_WINDOW,
		GameState.get_single_player_question_history(Database.current_language, theme_index),
		rng
	)
	if picked_question.is_empty():
		return {}
	var picked_id: int = int(picked_question.get("id", -1))
	if picked_id >= 0 and persist_selection:
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
	var unlocked_theme_count: int = GameState.get_unlocked_theme_ids(language).size()
	var adaptive_difficulty: float = GameState.get_single_player_adaptive_difficulty(language)
	if (
		single_player_level_cache_language != language
		or single_player_level_cache_theme_count != theme_count
		or single_player_level_cache_unlocked_theme_count != unlocked_theme_count
		or !is_equal_approx(single_player_level_cache_difficulty, adaptive_difficulty)
	):
		_invalidate_single_player_level_cache()
		single_player_level_cache_language = language
		single_player_level_cache_theme_count = theme_count
		single_player_level_cache_unlocked_theme_count = unlocked_theme_count
		single_player_level_cache_difficulty = adaptive_difficulty
	var level_key := str(level_index)
	if single_player_level_definitions_cache.has(level_key):
		var cached: Variant = single_player_level_definitions_cache[level_key]
		if cached is Dictionary and int(cached.get("selection_stage", -1)) == _single_player_first_unplayed_slot(level_index, _single_player_level_word_target(level_index)):
			return cached
	if theme_count <= 0:
		return {}
	var target_difficulty: float = adaptive_difficulty
	if _single_player_is_bonus_level(level_index):
		target_difficulty = clampf(
			adaptive_difficulty + SINGLE_PLAYER_BONUS_LEVEL_DIFFICULTY_OFFSET,
			GameState.SINGLE_PLAYER_DIFFICULTY_MIN,
			GameState.SINGLE_PLAYER_DIFFICULTY_MAX
		)
	var word_count: int = _single_player_level_word_target(level_index)
	var level_seed: int = GameState.get_or_create_single_level_seed(language, level_index)
	var options: Array = _single_player_theme_options(level_index, level_seed, word_count)
	var selected_theme: int = GameState.get_single_level_selected_theme(language, level_index)
	# Preserve an already-started legacy round, but never re-offer a locked
	# category from an old, unstarted theme selection.
	var saved_session: Dictionary = GameState.get_active_single_player_session()
	var legacy_round_started: bool = (
		_single_player_first_unplayed_slot(level_index, word_count) > 0
		or (int(saved_session.get("level_index", -1)) == level_index
			and str(saved_session.get("language", "")) == language
			and str(saved_session.get("kind", "")) in ["word", "quiz", "next"])
	)
	if selected_theme >= 0 and !GameState.get_unlocked_theme_ids(language).has(Database.get_theme_id(selected_theme)) and !legacy_round_started:
		selected_theme = -1
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
			question_target_difficulty = float(replaced_word.get("target_difficulty", target_difficulty))
			question = _single_player_pick_level_question(
				level_index,
				level_seed,
				selected_theme,
				question_target_difficulty,
				question_slot <= _single_player_first_unplayed_slot(level_index, word_count)
			)
		if question.is_empty():
			question_slot = -1
	var level_data := {
		"index": level_index,
		"selection_stage": _single_player_first_unplayed_slot(level_index, word_count),
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

func _single_player_stage_is_quiz(level_index: int, word_slot: int) -> bool:
	return word_slot == _single_player_level_question_slot_index(level_index)

func _single_player_stage_reward_currency(
	_level_index: int,
	_word_slot: int,
	_word_count: int
) -> String:
	# Hangman and embedded quiz stages now both pay soft currency. Quiz stages
	# differ by amount rather than by currency.
	return GameState.STAGE_REWARD_COINS

func _single_player_stage_reward_amount(
	level_index: int,
	word_slot: int,
	_word_count: int
) -> int:
	if _single_player_stage_is_quiz(level_index, word_slot):
		return maxi(
			int(round(
				float(GameState.WORD_REWARD_COINS)
				* GameState.QUIZ_STAGE_REWARD_COIN_MULTIPLIER
			)),
			0
		)
	return GameState.WORD_REWARD_COINS

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
	# A duplicate result must not replace the durable claim flags with a fresh
	# unclaimed stage payout, even though progress itself is already idempotent.
	if _single_player_level_word_status(single_player_active_level_index, single_player_active_word_slot) != 0:
		var saved: Dictionary = GameState.get_active_single_player_session()
		if (
			str(saved.get("kind", "")) == "next"
			and int(saved.get("level_index", -1)) == single_player_active_level_index
			and int(saved.get("word_slot", -1)) == single_player_active_word_slot
		):
			return Dictionary(Dictionary(saved.get("data", {})).get("result", data)).duplicate(true)
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
	result["theme_unlock_before"] = int(progress.get("theme_unlock_before", 0))
	result["theme_unlock_after"] = int(progress.get("theme_unlock_after", 0))
	result["single_player_level_perfect"] = bool(progress.get("perfect", false))
	result["single_player_chain_failed"] = false
	result["single_player_chain_ended"] = bool(progress.get("completed", false))
	result["single_player_stage_won"] = is_win
	result["single_player_unlocked_next"] = bool(progress.get("unlocked_next", false))
	result["single_player_completion_bonus"] = int(progress.get("completion_bonus", 0))
	var level_completed: bool = bool(progress.get("completed", false))
	var completion_bonus: int = int(progress.get("completion_bonus", 0))
	var has_deferred_completion_reward: bool = (
		defer_final_reward and level_completed and completion_bonus > 0
	)
	result["single_player_reward_deferred"] = has_deferred_completion_reward
	result["single_player_deferred_reward_amount"] = (
		completion_bonus if has_deferred_completion_reward else 0
	)
	result["single_player_difficulty_before"] = float(progress.get("difficulty_before", 0.0))
	result["single_player_difficulty_after"] = float(progress.get("difficulty_after", 0.0))
	var stage_reward_currency: String = ""
	var stage_reward_amount: int = 0
	if is_win:
		stage_reward_currency = _single_player_stage_reward_currency(
			single_player_active_level_index,
			single_player_active_word_slot,
			level_word_count
		)
		stage_reward_amount = _single_player_stage_reward_amount(
			single_player_active_level_index,
			single_player_active_word_slot,
			level_word_count
		)
		result["single_player_stage_reward_currency"] = stage_reward_currency
		result["single_player_stage_reward_amount"] = stage_reward_amount
	if level_completed and int(progress.get("completion_bonus", 0)) > 0:
		result["lines"].append(_single_player_level_completed_reward_label(int(progress.get("completion_bonus", 0))))
	# Every stage, including a successful final stage, remains resumable on its
	# ordinary stage-reward screen until that step is resolved. On a successful
	# final stage the deferred level reward may coexist with this active snapshot;
	# the UI clears the stage snapshot only when it advances to the level summary.
	if stage_reward_currency.is_empty():
		stage_reward_currency = _single_player_stage_reward_currency(
			single_player_active_level_index,
			single_player_active_word_slot,
			level_word_count
		)
	GameState.set_active_single_player_session({
		"kind": "next",
		"language": Database.current_language,
		"level_index": single_player_active_level_index,
		"word_slot": single_player_active_word_slot,
		"theme_id": Database.get_theme_id(
			_single_player_level_selected_theme(single_player_active_level_index)
		),
		"data": {
			"result": result.duplicate(true),
			"reward_currency": stage_reward_currency,
			"reward_amount": stage_reward_amount,
			"reward_claimed": !is_win,
			# Successful quiz stages offer x2 as usual. A one-stage level also uses
			# that same large-reward offer, but for its stage reward itself: there is
			# no separate whole-level completion bonus on such levels.
			"reward_double_resolved": (
				!is_win
				or stage_reward_currency != GameState.STAGE_REWARD_COINS
				or (
					level_word_count > 1
					and !_single_player_stage_is_quiz(
						single_player_active_level_index,
						single_player_active_word_slot
					)
				)
			),
			"reward_double_claimed": false,
		},
	}, false)
	if persist:
		GameState.save_game()
	return result

func _stage_single_player_menu_button(rect: Rect2, callable: Callable) -> Control:
	var resume_available: bool = GameState.has_resumable_single_player_level()
	var level_index: int = (
		GameState.get_resumable_single_player_level_index()
		if resume_available
		else _single_player_next_level_index()
	)
	var challenge_level: bool = _single_player_is_bonus_level(level_index)
	var use_subtitle: bool = resume_available or challenge_level
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
	title_label.name = "ResumeLevel" if resume_available else "LevelTitle"
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.position = Vector2(
		0.0,
		0.0 if use_subtitle else 3.0
	)
	title_label.size = Vector2(
		rect.size.x,
		rect.size.y * (0.60 if use_subtitle else 0.92)
	)
	title_label.text = (
		(tr("LEVEL_NUMBER") % (level_index + 1)).to_upper()
		if resume_available
		else ("%s %d" % [_single_player_level_label(), level_index + 1]).to_upper()
	)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM if use_subtitle else VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_override("font", UI_BUTTON_FONT)
	title_label.add_theme_font_size_override(
		"font_size",
		UI_FONTS.display_button_font_size(28)
	)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	BUTTON_TEXT_STYLE_SCRIPT.apply_display(title_label)
	button.add_child(title_label)

	if use_subtitle:
		var challenge_label := Label.new()
		challenge_label.name = "ResumeAction" if resume_available else "ChallengeSubtitle"
		challenge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		challenge_label.position = Vector2(
			0.0,
			rect.size.y * 0.57
		)
		challenge_label.size = Vector2(
			rect.size.x,
			rect.size.y * 0.30
		)
		challenge_label.text = (
			Database.tr_text(3, "Continue").to_upper()
			if resume_available
			else _single_player_challenge_level_label().to_upper()
		)
		challenge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		challenge_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		challenge_label.add_theme_font_override("font", UI_BUTTON_FONT)
		challenge_label.add_theme_font_size_override(
			"font_size",
			UI_FONTS.display_button_font_size(15)
		)
		challenge_label.add_theme_color_override(
			"font_color",
			Color.WHITE if resume_available else UI_PALETTE.CHALLENGE_TEXT
		)
		BUTTON_TEXT_STYLE_SCRIPT.apply_display(challenge_label)
		button.add_child(challenge_label)
	return button

func _remove_single_player_theme_popup() -> void:
	_clear_single_player_popup_theme_cards()
	_remove_popup_group_with_dimmer_fade(&"single_player_theme_popup")
	single_player_popup_level_index = -1
	single_player_popup_selected_theme = -1
	single_player_popup_theme_panels.clear()
	single_player_popup_stage_content = null
	single_player_popup_play_button = null
	single_player_popup_return_to_menu_on_close = false

func _close_single_player_theme_popup_to_menu() -> void:
	_remove_single_player_theme_popup()
	show_menu()

func _remove_single_player_last_chance_popup() -> void:
	_remove_popup_group_with_dimmer_fade(&"single_player_last_chance_popup")

func _remove_heart_refill_popup() -> void:
	_remove_popup_group_with_dimmer_fade(&"heart_refill_popup")
	heart_refill_continue_action = Callable()
	heart_refill_store_return_action = Callable()
	heart_refill_cancel_action = Callable()
	heart_refill_reward_acquired = false
	heart_refill_store_is_open = false

func _remove_coin_refill_popup() -> void:
	_remove_popup_group_with_dimmer_fade(&"coin_refill_popup")

func _purchase_heart_refill() -> void:
	if GameState.get_hearts() >= GameState.MAX_HEARTS:
		return
	if GameState.get_soft_currency() < HEART_REFILL_COST:
		if heart_refill_store_is_open:
			_remove_heart_refill_popup()
			return
		var continue_action: Callable = heart_refill_continue_action
		var restore_action: Callable = heart_refill_store_return_action
		var cancel_action: Callable = heart_refill_cancel_action
		var reward_acquired: bool = heart_refill_reward_acquired
		_remove_heart_refill_popup()
		_open_coin_store(
			Callable(self, "_return_to_heart_refill_from_coin_store").bind(
				continue_action,
				restore_action,
				cancel_action,
				reward_acquired
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
	selected_theme: int = -1,
	return_to_menu_on_close: bool = false
) -> void:
	# Coin refill is a stacked modal in the portrait UI. When it was opened from
	# the theme picker, that picker is still alive underneath it, so rebuilding
	# the picker would restart its presentation and replace its original backdrop
	# (for example the completed-level reward screen) with Home. Simply reveal the
	# existing picker after the coin modal is removed. Keep the old rebuild path as
	# a fallback for contexts where the underlying modal was actually destroyed.
	if !get_tree().get_nodes_in_group("single_player_theme_popup").is_empty():
		return
	show_menu()
	_show_single_player_level_popup(
		level_index,
		selected_theme,
		retry_after_loss,
		return_to_menu_on_close
	)

func _purchase_single_player_extra_attempt() -> void:
	if single_player_extra_attempt_claim_in_progress:
		return
	if !GameSession.has_deferred_loss():
		_remove_single_player_last_chance_popup()
		return
	var free_offer: bool = _single_player_extra_attempt_is_free()
	var purchase_cost: int = _single_player_extra_attempt_cost()
	if !free_offer and GameState.get_soft_currency() < purchase_cost:
		_remove_single_player_last_chance_popup()
		_open_coin_store(Callable(self, "_return_to_single_player_last_chance_from_coin_store"))
		return
	single_player_extra_attempt_claim_in_progress = true
	if !free_offer and !GameState.spend_soft_currency(purchase_cost, false):
		single_player_extra_attempt_claim_in_progress = false
		return
	_remove_single_player_last_chance_popup()
	_grant_single_player_extra_attempt()

func _single_player_extra_attempt_is_free() -> bool:
	return (
		single_player_active_level_index >= 0
		and single_player_active_level_index < 2
	)

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
	# Both price and bundle-size progression are scoped to the current stage.
	# With count_step_interval = 1, every new popup grows the bundle by one:
	# +2, +3, +4, ... until the stage changes.
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

func _prepare_single_player_extra_attempt_offers(_level_index: int) -> void:
	# Every word/quiz stage starts its own offer progression.
	_reset_single_player_extra_attempt_offers()

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
	# Advertising is unlocked by the actual start of the configured level, not by
	# merely opening its theme-selection popup. The call is idempotent for every
	# subsequent stage and restores the gate correctly for a resumed level.
	if level_index + 1 >= SINGLE_PLAYER_GUIDED_ONBOARDING_REQUIRED_START_LEVEL:
		GameState.complete_single_player_guided_onboarding(true)
	GameState.activate_ads_for_level(level_index)
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
	GameState.activate_ads_for_level(level_index)
	var word_info: Dictionary = words[word_slot]
	single_player_active_level_index = level_index
	single_player_active_word_slot = word_slot
	_prepare_single_player_extra_attempt_offers(level_index)
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
		show_menu()

func _discard_round_for_navigation() -> void:
	result_transition_generation += 1
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
	result["single_player_level_perfect"] = false
	result["single_player_chain_failed"] = false
	result["single_player_stage_won"] = false
	result["single_player_forfeit_reward"] = true
	result["single_player_reward_granted"] = false
	return result

func _single_player_strip_win_rewards_for_forfeit(source_result: Dictionary) -> Dictionary:
	var result: Dictionary = source_result.duplicate(true)
	var remaining_attempt_reward: int = maxi(
		int(result.get("remaining_attempt_star_reward_amount", 0)),
		0
	)
	if remaining_attempt_reward > 0:
		GameState.spend_stars(remaining_attempt_reward, false)
	if bool(result.get("single_player_reward_deferred", false)):
		GameState.clear_pending_single_player_reward(false)
	for reward_key: String in [
		"remaining_attempt_star_reward_amount",
		"remaining_attempt_star_balance_before",
		"single_player_stage_reward_currency",
		"single_player_stage_reward_amount",
		"single_player_reward_deferred",
		"single_player_deferred_reward_amount",
	]:
		result.erase(reward_key)
	return result

func _forfeit_single_player_round(_show_failure_reward: bool = false) -> void:
	var level_index: int = single_player_active_level_index
	var forfeit_result: Dictionary = last_result_data.duplicate(true)
	# A forced exit is a loss of the current stage, not a reset of the whole level.
	# Preserve every earlier status so the reward chain can show its existing checks
	# together with a cross on the stage that the player abandoned.
	result_transition_generation += 1
	var should_lose_heart: bool = false
	var has_stage_failure: bool = false
	if (
		!game_finished
		and (GameSession.is_active or _single_player_embedded_question_active())
		and level_index >= 0
		and single_player_active_word_slot >= 0
	):
		game_finished = true
		var defer_forfeit_level_reward: bool = (
			single_player_active_word_slot
				== _single_player_level_word_count(level_index) - 1
		)
		forfeit_result = _single_player_mark_current_word_finished(
			{},
			false,
			false,
			defer_forfeit_level_reward,
			false
		)
		should_lose_heart = true
		has_stage_failure = true
	elif (
		game_finished
		and last_result_is_win
		and level_index >= 0
		and single_player_active_word_slot >= 0
		and !bool(last_result_data.get("single_player_level_completed", false))
	):
		# Exiting from the solved-stage result still counts as abandoning that stage.
		# Revoke rewards granted before Continue, replace its saved status with a loss,
		# and keep the rest of the level intact.
		forfeit_result = _single_player_strip_win_rewards_for_forfeit(last_result_data)
		forfeit_result = _single_player_mark_current_word_finished(
			forfeit_result,
			false,
			false,
			false,
			false
		)
		GameState.record_single_player_forfeit(Database.current_language, false)
		should_lose_heart = true
		has_stage_failure = true
	elif (
		game_finished
		and !last_result_is_win
		and level_index >= 0
		and single_player_active_word_slot >= 0
	):
		# A naturally failed stage has already consumed its heart and saved status.
		# Back/Exit should simply reveal that same failed node on the reward chain.
		has_stage_failure = true
	if should_lose_heart:
		GameState.lose_heart(false)
	if has_stage_failure:
		GameSession.discard_current_round()
		GameState.save_game()
		last_result_data = _single_player_forfeit_reward_data(forfeit_result, level_index)
		last_result_is_win = false
		hero_force_default_pose = false
		# Only a newly forced loss should trigger the extra interstitial opportunity.
		# A naturally failed stage has already consumed its heart and should simply
		# reveal the existing failed node without another ad trigger.
		_show_single_player_forfeit_reward_screen(should_lose_heart)
		return
	GameSession.discard_current_round()
	game_finished = false
	last_result_data = {}
	single_player_active_word_slot = -1
	show_menu()

func _remove_exit_game_popup() -> void:
	_remove_popup_group_with_dimmer_fade(&"exit_game_popup")
func _custom_word_start_label() -> String:
	return Database.tr_text(77, "Start game")

func _on_custom_word_text_changed(value: String) -> void:
	_reset_custom_word_check_feedback()
	var previous_word_text: String = custom_word_text
	# Keep Android/iOS IME composition entirely owned by the native LineEdit.
	# Normalize only the game/visual value; assigning LineEdit.text or its caret
	# from text_changed can invalidate an active mobile composition session.
	custom_word_text = _normalize_custom_word_input(value)
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
	var input_language: String = ""
	for i: int in range(normalized.length()):
		var character: String = normalized.substr(i, 1)
		var character_language: String = _custom_word_character_language(character)
		if character_language != "":
			# The first actual letter locks the word to one alphabet. Keep the
			# native LineEdit untouched for mobile IME safety, but ignore letters
			# from the other script in the visual/game value.
			if input_language == "":
				input_language = character_language
			if character_language == input_language:
				filtered += character
		elif character == " " or character == "—":
			# TextBlock.CheckLast() in the FLA prevents leading and consecutive
			# separators while the word is being typed.
			if filtered != "" and filtered.right(1) != " " and filtered.right(1) != "—":
				filtered += character
	return filtered.substr(0, CUSTOM_WORD_MAX_LENGTH)

func _custom_word_character_language(character: String) -> String:
	if character.length() != 1:
		return ""
	var code: int = character.unicode_at(0)
	if code >= 0x41 and code <= 0x5A:
		return "en"
	if code >= 0x410 and code <= 0x42F:
		return "ru"
	return ""

func _custom_word_alphabet(language_code: String) -> PackedStringArray:
	var alphabet_text: String = ""
	if language_code == "en":
		alphabet_text = CUSTOM_WORD_LATIN_ALPHABET_TEXT
	elif language_code == "ru":
		alphabet_text = CUSTOM_WORD_CYRILLIC_ALPHABET_TEXT
	var result := PackedStringArray()
	for i: int in range(alphabet_text.length()):
		result.append(alphabet_text.substr(i, 1))
	return result

func _active_game_alphabet() -> PackedStringArray:
	if GameState.current_mode == GameState.GameMode.TWO_PLAYER and GameSession.word_data != null:
		var custom_language: String = _custom_word_language(GameSession.word_data.text)
		var custom_alphabet: PackedStringArray = _custom_word_alphabet(custom_language)
		if !custom_alphabet.is_empty():
			return custom_alphabet
	return Database.get_alphabet()

func _set_custom_word_field_tint(color: Color) -> void:
	if custom_word_input_visual != null and is_instance_valid(custom_word_input_visual):
		custom_word_input_visual.call("set_marker_tint", color)

func _sync_custom_word_input_visual() -> void:
	if custom_word_input_visual != null and is_instance_valid(custom_word_input_visual):
		custom_word_input_visual.call("set_display_text", custom_word_text)

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
	# The dictionary/search action is meaningless without a word. Keep it disabled
	# in the same empty-input state as Start game, but do not interrupt an active
	# lookup (that state already owns the button until the request is cancelled).
	if (
		custom_word_check_button != null
		and is_instance_valid(custom_word_check_button)
		and custom_word_check_request == null
		and bool(custom_word_check_button.get("button_disabled")) != should_disable
	):
		custom_word_check_button.set("button_disabled", should_disable)

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
	custom_word_text = _normalize_custom_word_input(custom_word_edit.text)
	var language_code: String = _custom_word_language(custom_word_text)
	if !_is_valid_custom_word(custom_word_text) or language_code == "":
		_set_temporary_custom_word_field_tint(UI_PALETTE.MARKER_ERROR)
		custom_word_edit.placeholder_text = Database.tr_text(64, "Error! Something goes wrong.")
		_show_custom_word_toast(&"TOAST_WORD_NOT_FOUND", false)
		_vibrate_custom_word_not_found()
		return

	_cancel_custom_word_check()
	_hide_custom_word_toast()
	_reset_custom_word_field_tint()
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
		_reset_custom_word_field_tint()
	elif custom_word_edit != null:
		# Match the hangman result word: the marker and the text effect switch
		# together to the shared success/error palette.
		_set_temporary_custom_word_field_tint(
			UI_PALETTE.MARKER_SUCCESS if found else UI_PALETTE.MARKER_ERROR
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

func _set_temporary_custom_word_field_tint(color: Color) -> void:
	custom_word_color_generation += 1
	var color_generation: int = custom_word_color_generation
	_set_custom_word_field_tint(color)
	await get_tree().create_timer(CUSTOM_WORD_RESULT_COLOR_DURATION).timeout
	if color_generation != custom_word_color_generation:
		return
	_set_custom_word_field_tint(CUSTOM_WORD_FIELD_DEFAULT_TINT)

func _reset_custom_word_field_tint() -> void:
	custom_word_color_generation += 1
	_set_custom_word_field_tint(CUSTOM_WORD_FIELD_DEFAULT_TINT)

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
	custom_word_check_button.set("button_disabled", is_checking or custom_word_text.is_empty())
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
	_reset_custom_word_field_tint()

func start_custom_game() -> void:
	var source_text: String = custom_word_edit.text if custom_word_edit != null else custom_word_text
	var word := _normalize_custom_word_input(source_text)
	if !_is_valid_custom_word(word):
		if custom_word_edit != null:
			_set_custom_word_field_tint(UI_PALETTE.MARKER_ERROR)
			custom_word_edit.placeholder_text = Database.tr_text(64, "Error! Something goes wrong.")
		return
	custom_word_text = word
	game_finished = false
	last_result_data = {}
	single_player_active_level_index = -1
	single_player_active_word_slot = -1
	GameState.current_mode = GameState.GameMode.TWO_PLAYER
	GameSession.start_custom_round(word)
	show_game_screen()

func _is_valid_custom_word(word: String) -> bool:
	if word.length() == 0 or word.length() > CUSTOM_WORD_MAX_LENGTH:
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
	var language: String = ""
	for i in range(word.length()):
		var character_language: String = _custom_word_character_language(word.substr(i, 1))
		if character_language == "":
			continue
		if language == "":
			language = character_language
		elif character_language != language:
			return ""
	return language

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
	var guess_was_correct: bool = GameSession.guess(letter, should_defer_loss)
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
	GameSession.use_open_letter_hint()

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

func _grant_remaining_attempt_star_reward(result: Dictionary, is_win: bool) -> Dictionary:
	var rewarded_result: Dictionary = result.duplicate(true)
	if !is_win or GameState.current_mode == GameState.GameMode.TWO_PLAYER:
		return rewarded_result
	var remaining_attempts: int = GameSession.get_remaining_attempts()
	if remaining_attempts <= 0:
		return rewarded_result
	var previous_balance: int = GameState.get_stars()
	var final_balance: int = GameState.add_stars(remaining_attempts, false)
	var credited_amount: int = maxi(final_balance - previous_balance, 0)
	if credited_amount <= 0:
		return rewarded_result
	rewarded_result["remaining_attempt_star_reward_amount"] = credited_amount
	rewarded_result["remaining_attempt_star_balance_before"] = previous_balance
	return rewarded_result

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
		GameState.current_mode == GameState.GameMode.SINGLE_PLAYER
		and single_player_active_level_index >= 0
		and single_player_active_word_slot
			== _single_player_level_word_count(single_player_active_level_index) - 1
	)
	var award_immediate_win_coins: bool = (
		GameState.current_mode != GameState.GameMode.SINGLE_PLAYER
	)
	last_result_data = GameSession.finish_result(is_win, award_immediate_win_coins)
	last_result_data = _grant_remaining_attempt_star_reward(last_result_data, is_win)
	if GameState.current_mode == GameState.GameMode.SINGLE_PLAYER:
		if !is_win:
			GameState.lose_heart(false)
		last_result_data = _single_player_mark_current_word_finished(
			last_result_data,
			is_win,
			true,
			defer_single_player_final_reward
		)
	elif last_result_data.has("remaining_attempt_star_reward_amount"):
		# Classic finish_result() saves its own progress before this bonus is added.
		# Commit the star balance separately so closing during the result animation
		# cannot lose or repeat the reward.
		GameState.save_game()
	# All round results now use the same in-place presentation. In particular,
	# Single Player victories follow Classic exactly instead of entering the old
	# dedicated win transition after the final letter feedback delay.
	_show_in_place_round_result(is_win)

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
		and bool(last_result_data.get("single_player_level_completed", false))
		and GameState.is_pending_single_player_reward_presented()
	):
		# Once the whole-level reward screen has been reached, backing out is no
		# longer an unfinished-level state. Grant any not-yet-animated base rewards,
		# treat x2 as skipped, and return Home without creating Resume/Continue.
		GameState.settle_presented_pending_single_player_reward(true)
		_discard_round_for_navigation()
		show_menu()
		return
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
	if level_completed:
		GameSession.discard_current_round()
		game_finished = false
		last_result_data = {}
		single_player_active_word_slot = -1
		show_menu()
	else:
		_start_next_single_player_word(level_index)

func _remove_word_comment_popup() -> void:
	_remove_popup_group_with_dimmer_fade(&"word_comment_popup")

func _open_word_search() -> void:
	var word := GameSession.get_full_word().strip_edges()
	if word == "":
		return
	OS.shell_open("https://www.google.com/search?q=" + word.to_lower().uri_encode())

func _unhandled_input(event: InputEvent) -> void:
	if !get_tree().get_nodes_in_group("legal_consent_popup").is_empty():
		if event is InputEventKey and event.pressed and !event.echo:
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and !event.echo:
		if event.keycode == KEY_ESCAPE:
			if !get_tree().get_nodes_in_group("single_player_last_chance_popup").is_empty():
				_decline_single_player_extra_attempt()
				get_viewport().set_input_as_handled()
			elif (
				!get_tree().get_nodes_in_group("single_player_theme_popup").is_empty()
			):
				if single_player_popup_return_to_menu_on_close:
					_close_single_player_theme_popup_to_menu()
				elif (
					single_player_retry_after_loss
					and !_single_player_theme_selection_is_locked(
						single_player_popup_level_index
					)
				):
					_close_single_player_retry_popup()
				get_viewport().set_input_as_handled()
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
		if letter.length() == 1 and _active_game_alphabet().has(letter):
			_press_letter(letter)
