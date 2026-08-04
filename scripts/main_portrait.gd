extends "res://scripts/main.gd"

const PORTRAIT_ADAPTIVE_GROUP_SCRIPT: GDScript = preload("res://scripts/ui/portrait_adaptive_group.gd")
const PORTRAIT_STAGE_LAYOUT: GDScript = preload("res://scripts/ui/portrait_stage_layout.gd")
const STAGE_WORD_INPUT_SCRIPT: GDScript = preload("res://scripts/ui/stage_word_input.gd")
const RESULT_WORD_BOUNCE_EFFECT_SCRIPT: GDScript = preload("res://scripts/ui/result_word_bounce_effect.gd")

const PORTRAIT_STAGE_SIZE := Vector2(480.0, 800.0)
const PORTRAIT_HEADER_HEIGHT: float = 80.0
const PORTRAIT_FOOTER_Y: float = 688.0
const PORTRAIT_LONG_BUTTON_SIZE := Vector2(300.0, 64.0)
const PORTRAIT_ROUND_BUTTON_SIZE: float = PORTRAIT_LONG_BUTTON_SIZE.y
const PORTRAIT_PAGE_BACK_BUTTON_SCALE: float = 0.80
const PORTRAIT_PAGE_BACK_BUTTON_SIZE: float = PORTRAIT_ROUND_BUTTON_SIZE * PORTRAIT_PAGE_BACK_BUTTON_SCALE
const PORTRAIT_PAGE_BACK_BUTTON_RECT := Rect2(18.4, 15.4, PORTRAIT_PAGE_BACK_BUTTON_SIZE, PORTRAIT_PAGE_BACK_BUTTON_SIZE)
const PORTRAIT_PAGE_BACK_ICON_SIZE := Vector2(21.6, 26.4)
const PORTRAIT_BACK_ENTRANCE_GAP: float = 24.0
const PORTRAIT_BACK_ENTRANCE_DURATION: float = 0.24
const PORTRAIT_PAGE_TITLE_RECT := Rect2(40.0, 104.0, 400.0, 42.0)
const PORTRAIT_GAME_HEADER_RECT := Rect2(24.0, 104.0, 432.0, 48.0)
const PORTRAIT_CURRENCY_COUNTER_RECT := Rect2(185.03, 21.68, 109.94, 38.64)
const PORTRAIT_CURRENCY_ICON_SIZE: float = 35.42
const PORTRAIT_CURRENCY_COUNTER_PRESSED_SCALE: float = 0.94
const PORTRAIT_CURRENCY_COUNTER_PRESS_DURATION: float = 0.055
const PORTRAIT_CURRENCY_COUNTER_RELEASE_DURATION: float = 0.085
const PORTRAIT_CURRENCY_ADD_BADGE_SIZE: float = 20.0
const PORTRAIT_CURRENCY_ADD_BADGE_GREEN := Color("#35C759")
const PORTRAIT_CURRENCY_ADD_BADGE_BORDER := Color("#167A34")
const PORTRAIT_MAIN_NAV_Y: float = 725.0
const PORTRAIT_MAIN_NAV_HEIGHT: float = 75.0
const PORTRAIT_MAIN_NAV_ITEM_WIDTH: float = 96.0
const PORTRAIT_MAIN_NAV_ACTIVE_RECT_SIZE := Vector2(116.0, 92.0)
const PORTRAIT_MAIN_NAV_ACTIVE_Y: float = 708.0
const PORTRAIT_MAIN_NAV_INACTIVE_ICON_SIZE: float = 52.0
const PORTRAIT_MAIN_NAV_ACTIVE_ICON_SCALE: float = 1.15
const PORTRAIT_MAIN_NAV_ICON_SIZE: float = PORTRAIT_MAIN_NAV_INACTIVE_ICON_SIZE * PORTRAIT_MAIN_NAV_ACTIVE_ICON_SCALE
const PORTRAIT_MAIN_NAV_ACTIVE_ICON_Y: float = 709.0
const PORTRAIT_MAIN_NAV_INACTIVE_ICON_Y: float = 735.0
const PORTRAIT_MAIN_NAV_LABEL_Y: float = 770.0
const PORTRAIT_MAIN_NAV_LABEL_HEIGHT: float = 28.0
const PORTRAIT_MAIN_NAV_LABEL_FONT_SIZE: int = 18
const PORTRAIT_MAIN_NAV_TRANSITION_DURATION: float = 0.16
const PORTRAIT_MAIN_NAV_TRANSITION_TEXT_SCALE: float = 0.82
const PORTRAIT_MAIN_NAV_BOUNCE_SCALE: float = 1.10
const PORTRAIT_MAIN_NAV_BOUNCE_GROW_DURATION: float = 0.08
const PORTRAIT_MAIN_NAV_BOUNCE_SETTLE_DURATION: float = 0.12
const PORTRAIT_PAPER_GRID_SCALE: float = 1.35
const PORTRAIT_MAIN_TAB_SWIPE_MIN_DISTANCE: float = 64.0
const PORTRAIT_MAIN_TAB_SWIPE_MIN_DISTANCE_RATIO: float = 0.14
const PORTRAIT_MAIN_TAB_SWIPE_HORIZONTAL_BIAS: float = 1.35
const PORTRAIT_MAIN_TAB_SWIPE_ACTIVATION_RATIO: float = 0.018
const PORTRAIT_MAIN_TAB_SWIPE_RELEASE_DURATION: float = 0.22
const PORTRAIT_MODAL_POPUP_GROUP: StringName = &"portrait_modal_popup"
const PORTRAIT_TASKS_DIFFICULTY_RECT := Rect2(99.75, 646.0, 280.5, 70.4)
const PORTRAIT_THEME_DIFFICULTY_BASE_RECT := Rect2(90.0, 725.0, 300.0, 64.0)
const PORTRAIT_SMALL_BUTTON_SIZE := Vector2(196.0, 58.0)
const PORTRAIT_FOOTER_LONG_BUTTON_WIDTH_SCALE: float = 0.85
const PORTRAIT_FOOTER_CONTROL_SCALE: float = 1.10
const PORTRAIT_FOOTER_LEFT_ROUND_BUTTON_RECT := Rect2(14.0, 711.0, PORTRAIT_ROUND_BUTTON_SIZE, PORTRAIT_ROUND_BUTTON_SIZE)
const PORTRAIT_FOOTER_CENTER_LONG_BUTTON_RECT := Rect2(90.0, 711.0, PORTRAIT_LONG_BUTTON_SIZE.x, PORTRAIT_LONG_BUTTON_SIZE.y)
const PORTRAIT_FOOTER_RIGHT_ROUND_BUTTON_RECT := Rect2(402.0, 711.0, PORTRAIT_ROUND_BUTTON_SIZE, PORTRAIT_ROUND_BUTTON_SIZE)
const PORTRAIT_MENU_TITLE_MAX_SCALE: float = 1.15
# Dense screens may grow moderately on tall phones, but gameplay is split into
# independent upper and lower groups so the keyboard can stay width-safe while
# moving toward the thumb zone.
const PORTRAIT_GAME_KEYBOARD_MAX_SCALE: float = 1.15
const PORTRAIT_TWO_PLAYER_KEYBOARD_Y_OFFSET: float = 64.0
const PORTRAIT_PROFILE_MAX_SCALE: float = 1.10
const PORTRAIT_HERO_POSITION := Vector2(136.0, 302.0)
const PORTRAIT_HERO_RESULT_POSITION := Vector2(138.0, 500.0)
const PORTRAIT_TWO_PLAYER_HERO_VISUAL_CENTER_OFFSET_X: float = 100.0
const PORTRAIT_RESULT_CONTINUE_BUTTON_RECT := PORTRAIT_FOOTER_CENTER_LONG_BUTTON_RECT
const PORTRAIT_RESULT_WORD_RECT := Rect2(22.0, 582.0, 436.0, 72.0)
const PORTRAIT_RESULT_SEARCH_BUTTON_SIZE: float = 44.0
const PORTRAIT_RESULT_SEARCH_REST_VISUAL_SCALE := Vector2.ONE
const PORTRAIT_RESULT_SEARCH_START_VISUAL_SCALE := PORTRAIT_RESULT_SEARCH_REST_VISUAL_SCALE * 0.72
const PORTRAIT_RESULT_WORD_SEARCH_GAP: float = 10.0
const PORTRAIT_RESULT_SEARCH_ICON_SIZE := Vector2(24.0, 31.0)
const PORTRAIT_RESULT_CHAIN_CARD_RECT := Rect2(83.0, 648.0, 314.0, 40.0)
const PORTRAIT_RESULT_LETTER_BOUNCE_GROW_DURATION: float = 0.068
const PORTRAIT_RESULT_LETTER_BOUNCE_SETTLE_DURATION: float = 0.072
const PORTRAIT_RESULT_LETTER_BOUNCE_GAP: float = 0.0094
const PORTRAIT_RESULT_LETTER_BOUNCE_REFERENCE_LENGTH: float = 5.0
const PORTRAIT_RESULT_LETTER_BOUNCE_MAX_SPEED_MULTIPLIER: float = 2.2
const PORTRAIT_RESULT_LETTER_BOUNCE_NEIGHBOR_STRENGTH: float = 0.42
const PORTRAIT_RESULT_LETTER_BOUNCE_NEIGHBOR_RADIUS: int = 2
const PORTRAIT_RESULT_SEARCH_APPEAR_DURATION: float = 0.18
const PORTRAIT_HERO_BASE_SCALE_MULTIPLIER: float = 0.86
const PORTRAIT_HERO_SCALE_MULTIPLIER: float = PORTRAIT_HERO_BASE_SCALE_MULTIPLIER * 1.15
const PORTRAIT_BACK_ARROW_ICON: Texture2D = preload("res://flash_assets/portrait_back_arrow_icon.png")
const PORTRAIT_HINT_REVEAL_LETTER_ICON: Texture2D = preload("res://flash_assets/hint_reveal_letter_doodle.png")
const PORTRAIT_HINT_REMOVE_WRONG_ICON: Texture2D = preload("res://flash_assets/hint_remove_wrong_doodle.png")
const PORTRAIT_HINT_COMMENT_UNLOCK_ICON: Texture2D = preload("res://flash_assets/hint_comment_unlock_doodle.png")
const PORTRAIT_HINT_USED_GRAYSCALE_SHADER: Shader = preload("res://shaders/hint_icon_grayscale.gdshader")
const PORTRAIT_NAV_PROFILE_ICON: Texture2D = preload("res://flash_assets/nav_profile_icon.png")
const PORTRAIT_NAV_SHOP_ICON: Texture2D = preload("res://flash_assets/nav_shop_icon.png")
const PORTRAIT_NAV_HOME_ICON: Texture2D = preload("res://flash_assets/nav_home_icon.png")
const PORTRAIT_NAV_TASKS_ICON: Texture2D = preload("res://flash_assets/nav_tasks_icon.png")
const PORTRAIT_NAV_SETTINGS_ICON: Texture2D = preload("res://flash_assets/nav_settings_icon.png")

const PORTRAIT_BLUE := Color(0.2706, 0.3098, 0.6078, 1.0)
const PORTRAIT_DARK_BLUE := Color(0.2314, 0.2627, 0.5176, 1.0)
const PORTRAIT_CHALLENGE_POPUP_HEADER := Color("#9638B9")
const PORTRAIT_CHALLENGE_POPUP_BODY := Color("#4A2158")
const PORTRAIT_CHALLENGE_POPUP_SEPARATOR := Color("#D866FE")
const PORTRAIT_CHALLENGE_THEME_CARD := Color("#642B74")
const PORTRAIT_CHALLENGE_THEME_CARD_SELECTED := Color("#7C3590")
const PORTRAIT_CHALLENGE_HUD_PANEL := Color("#642A75")
const PORTRAIT_CHALLENGE_HUD_BORDER := Color("#E19AF4")
const PORTRAIT_INSUFFICIENT_PRICE_COLOR := Color("#FF5C6D")
const PORTRAIT_ORANGE := Color(0.8157, 0.5647, 0.3412, 1.0)
const PORTRAIT_RULE := Color(0.3157, 0.3765, 0.6902, 0.95)
const PORTRAIT_POPUP_DIM_ALPHA: float = 0.874
const PORTRAIT_POPUP_CLOSE_SIZE: float = PORTRAIT_ROUND_BUTTON_SIZE
const PORTRAIT_POPUP_CLOSE_GAP: float = 48.0
const PORTRAIT_POPUP_BUTTON_UNIFORM_SCALE: float = 1.15
const PORTRAIT_POPUP_BUTTON_LENGTH_SCALE: float = 0.85
const PORTRAIT_SINGLE_PLAYER_REFRESH_BUTTON_SCALE: float = 1.10
const PORTRAIT_SINGLE_PLAYER_THEME_CARD_ICON_SIZE: float = 75.14
const PORTRAIT_GAME_HINT_BUTTON_SIZE := Vector2(120.0, PORTRAIT_LONG_BUTTON_SIZE.y)
const PORTRAIT_GAME_HINT_OPEN_BUTTON_RECT := Rect2(42.0, 711.0, PORTRAIT_GAME_HINT_BUTTON_SIZE.x, PORTRAIT_GAME_HINT_BUTTON_SIZE.y)
const PORTRAIT_GAME_HINT_REMOVE_BUTTON_RECT := Rect2(180.0, 711.0, PORTRAIT_GAME_HINT_BUTTON_SIZE.x, PORTRAIT_GAME_HINT_BUTTON_SIZE.y)
const PORTRAIT_GAME_HINT_COMMENT_BUTTON_RECT := Rect2(318.0, 711.0, PORTRAIT_GAME_HINT_BUTTON_SIZE.x, PORTRAIT_GAME_HINT_BUTTON_SIZE.y)
const PORTRAIT_GAME_HINT_ART_SIZE := Vector2(50.0, 50.0)
const PORTRAIT_GAME_HINT_ART_RISE: float = -5.0
const PORTRAIT_GAME_HINT_COUNTER_SIZE: float = 28.0
const PORTRAIT_LIVES_COUNTER_RECT := Rect2(350.66, 21.68, 109.94, 38.64)
const PORTRAIT_LIVES_ICON_SIZE: float = PORTRAIT_CURRENCY_ICON_SIZE
const PORTRAIT_LAST_LIFE_FIRST_BOUNCE_SCALE: float = 1.20
const PORTRAIT_LAST_LIFE_SECOND_BOUNCE_SCALE: float = 1.13
const PORTRAIT_LAST_LIFE_BOUNCE_UP_DURATION: float = 0.12
const PORTRAIT_LAST_LIFE_BOUNCE_DOWN_DURATION: float = 0.14
const PORTRAIT_LAST_LIFE_BETWEEN_BOUNCES: float = 0.06
const PORTRAIT_LAST_LIFE_LOOP_PAUSE: float = 0.72
const PORTRAIT_WORD_LETTER_BOUNCE_START_SCALE := Vector2(0.58, 0.58)
const PORTRAIT_WORD_LETTER_BOUNCE_PEAK_SCALE := Vector2(1.24, 1.24)
const PORTRAIT_WORD_LETTER_BOUNCE_GROW_DURATION: float = 0.18
const PORTRAIT_WORD_LETTER_BOUNCE_SETTLE_DURATION: float = 0.24
const PORTRAIT_CUSTOM_WORD_INPUT_RECT := Rect2(22.0, 0.0, 436.0, 72.0)
const PORTRAIT_CUSTOM_WORD_CHECK_RECT := Rect2(94.0, 518.0, PORTRAIT_LONG_BUTTON_SIZE.x, PORTRAIT_LONG_BUTTON_SIZE.y)
const PORTRAIT_CUSTOM_WORD_RANDOM_RECT := Rect2(94.0, 592.0, PORTRAIT_LONG_BUTTON_SIZE.x, PORTRAIT_LONG_BUTTON_SIZE.y)
const PORTRAIT_COIN_TEST_BUTTON_RECT := Rect2(90.0, 340.0, PORTRAIT_LONG_BUTTON_SIZE.x, PORTRAIT_LONG_BUTTON_SIZE.y)

enum MainTab {
	PROFILE,
	SHOP,
	HOME,
	TASKS,
	SETTINGS,
}

var _portrait_custom_word_input: Control = null
var _portrait_game_adaptive_group: Control = null
var _portrait_game_hero_stage_position: Vector2 = PORTRAIT_HERO_POSITION
var _portrait_active_main_tab: int = -1
var _portrait_main_tab_swipe_touch_index: int = -1
var _portrait_main_tab_swipe_start_position := Vector2.ZERO
var _portrait_main_tab_swipe_last_position := Vector2.ZERO
var _portrait_main_tab_swipe_origin_tab: int = -1
var _portrait_main_tab_swipe_target_tab: int = -1
var _portrait_main_tab_swipe_tab_step: int = 0
var _portrait_main_tab_swipe_departing_content: Control = null
var _portrait_main_tab_swipe_target_content: Control = null
var _portrait_main_tab_swipe_departing_navigation: Control = null
var _portrait_main_tab_swipe_target_navigation: Control = null
var _portrait_main_tab_swipe_departing_top_bar: Control = null
var _portrait_main_tab_swipe_target_top_bar: Control = null
var _portrait_main_tab_swipe_building_target: bool = false
var _portrait_main_tab_swipe_animating: bool = false
var _portrait_top_bar_content: Control = null
var _portrait_back_button_visible: bool = false
var _portrait_previous_screen_had_back: bool = false
var _profile_name_edit: LineEdit = null
var _profile_edit_character_id: int = 1
var _profile_avatar_checks: Dictionary = {}
var _profile_avatar_halos: Dictionary = {}
func _clear() -> void:
	_portrait_previous_screen_had_back = _portrait_back_button_visible
	_portrait_back_button_visible = false
	var preserved_swipe_content: Control = null
	if (
		_portrait_main_tab_swipe_building_target
		and content != null
		and is_instance_valid(content)
		and content.get_parent() == ui
	):
		preserved_swipe_content = content
		ui.remove_child(preserved_swipe_content)
	_remove_profile_edit_popup()
	_portrait_custom_word_input = null
	_portrait_top_bar_content = null
	if !_portrait_main_tab_swipe_building_target:
		_portrait_active_main_tab = -1
		_reset_portrait_main_tab_swipe()
		_clear_portrait_main_tab_swipe_transition()
	super._clear()
	if preserved_swipe_content != null and is_instance_valid(preserved_swipe_content):
		ui.add_child(preserved_swipe_content)
		ui.move_child(preserved_swipe_content, ui.get_child_count() - 1)

func _input(event: InputEvent) -> void:
	if !_portrait_main_tab_swipe_is_available():
		_reset_portrait_main_tab_swipe()
		return

	if event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			if _portrait_main_tab_swipe_touch_index < 0:
				_portrait_main_tab_swipe_touch_index = touch_event.index
				_portrait_main_tab_swipe_start_position = touch_event.position
				_portrait_main_tab_swipe_last_position = touch_event.position
				_portrait_main_tab_swipe_origin_tab = _portrait_active_main_tab
			return
		if touch_event.index != _portrait_main_tab_swipe_touch_index:
			return
		var touch_was_canceled: bool = touch_event.canceled
		var has_interactive_target: bool = (
			_portrait_main_tab_swipe_target_content != null
			and is_instance_valid(_portrait_main_tab_swipe_target_content)
		)
		var should_commit: bool = false
		if has_interactive_target:
			var viewport_width: float = get_viewport().get_visible_rect().size.x
			var minimum_distance: float = maxf(
				PORTRAIT_MAIN_TAB_SWIPE_MIN_DISTANCE,
				viewport_width * PORTRAIT_MAIN_TAB_SWIPE_MIN_DISTANCE_RATIO
			)
			should_commit = (
				!touch_was_canceled
				and absf(_portrait_main_tab_swipe_departing_content.position.x) >= minimum_distance
			)
		_reset_portrait_main_tab_swipe()
		if has_interactive_target:
			_animate_portrait_main_tab_swipe(should_commit)
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var drag_event := event as InputEventScreenDrag
		if drag_event.index == _portrait_main_tab_swipe_touch_index:
			_portrait_main_tab_swipe_last_position = drag_event.position
			if _update_portrait_main_tab_swipe(drag_event.position):
				get_viewport().set_input_as_handled()

func _portrait_main_tab_swipe_is_available() -> bool:
	return (
		_portrait_active_main_tab >= MainTab.PROFILE
		and _portrait_active_main_tab <= MainTab.SETTINGS
		and !_portrait_main_tab_swipe_building_target
		and !_portrait_main_tab_swipe_animating
		and get_tree().get_first_node_in_group(PORTRAIT_MODAL_POPUP_GROUP) == null
	)

func _reset_portrait_main_tab_swipe() -> void:
	_portrait_main_tab_swipe_touch_index = -1
	_portrait_main_tab_swipe_start_position = Vector2.ZERO
	_portrait_main_tab_swipe_last_position = Vector2.ZERO

func _clear_portrait_main_tab_swipe_transition() -> void:
	_portrait_main_tab_swipe_origin_tab = -1
	_portrait_main_tab_swipe_target_tab = -1
	_portrait_main_tab_swipe_tab_step = 0
	_portrait_main_tab_swipe_departing_content = null
	_portrait_main_tab_swipe_target_content = null
	_portrait_main_tab_swipe_departing_navigation = null
	_portrait_main_tab_swipe_target_navigation = null
	_portrait_main_tab_swipe_departing_top_bar = null
	_portrait_main_tab_swipe_target_top_bar = null
	_portrait_main_tab_swipe_building_target = false
	_portrait_main_tab_swipe_animating = false

func _update_portrait_main_tab_swipe(pointer_position: Vector2) -> bool:
	var swipe_delta: Vector2 = pointer_position - _portrait_main_tab_swipe_start_position
	var horizontal_distance: float = absf(swipe_delta.x)
	var vertical_distance: float = absf(swipe_delta.y)
	var viewport_width: float = get_viewport().get_visible_rect().size.x
	if _portrait_main_tab_swipe_target_content == null:
		var activation_distance: float = maxf(
			12.0,
			viewport_width * PORTRAIT_MAIN_TAB_SWIPE_ACTIVATION_RATIO
		)
		if horizontal_distance < activation_distance:
			return false
		if horizontal_distance < vertical_distance * PORTRAIT_MAIN_TAB_SWIPE_HORIZONTAL_BIAS:
			return false
		var tab_step: int = 1 if swipe_delta.x < 0.0 else -1
		if !_prepare_portrait_main_tab_swipe_target(tab_step):
			return false

	var drag_x: float = (
		clampf(swipe_delta.x, -viewport_width, 0.0)
		if _portrait_main_tab_swipe_tab_step > 0
		else clampf(swipe_delta.x, 0.0, viewport_width)
	)
	_set_portrait_main_tab_swipe_positions(drag_x, viewport_width)
	return true

func _prepare_portrait_main_tab_swipe_target(tab_step: int) -> bool:
	var target_tab: int = clampi(
		_portrait_active_main_tab + tab_step,
		MainTab.PROFILE,
		MainTab.SETTINGS
	)
	if target_tab == _portrait_active_main_tab:
		return false
	var tab_action: Callable = _portrait_main_tab_action(target_tab)
	if !tab_action.is_valid() or content == null or !is_instance_valid(content):
		return false

	_portrait_main_tab_swipe_origin_tab = _portrait_active_main_tab
	_portrait_main_tab_swipe_target_tab = target_tab
	_portrait_main_tab_swipe_tab_step = tab_step
	_portrait_main_tab_swipe_departing_content = content
	_portrait_main_tab_swipe_departing_navigation = content.find_child(
		"PortraitMainNavigation",
		true,
		false
	) as Control
	_portrait_main_tab_swipe_departing_top_bar = content.find_child(
		"PortraitTopBar",
		true,
		false
	) as Control
	_portrait_main_tab_swipe_departing_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait_main_tab_swipe_building_target = true
	tab_action.call()
	_portrait_main_tab_swipe_building_target = false

	_portrait_main_tab_swipe_target_content = content
	if (
		_portrait_main_tab_swipe_target_content == null
		or !is_instance_valid(_portrait_main_tab_swipe_target_content)
		or _portrait_main_tab_swipe_target_content == _portrait_main_tab_swipe_departing_content
	):
		_clear_portrait_main_tab_swipe_transition()
		return false
	_portrait_main_tab_swipe_target_navigation = content.find_child(
		"PortraitMainNavigation",
		true,
		false
	) as Control
	_portrait_main_tab_swipe_target_top_bar = content.find_child(
		"PortraitTopBar",
		true,
		false
	) as Control
	if _portrait_main_tab_swipe_target_navigation != null:
		_portrait_main_tab_swipe_target_navigation.visible = false
	if _portrait_main_tab_swipe_target_top_bar != null:
		_portrait_main_tab_swipe_target_top_bar.visible = false
	return true

func _set_portrait_main_tab_swipe_positions(drag_x: float, viewport_width: float) -> void:
	if (
		_portrait_main_tab_swipe_departing_content == null
		or _portrait_main_tab_swipe_target_content == null
	):
		return
	_portrait_main_tab_swipe_departing_content.position.x = drag_x
	_portrait_main_tab_swipe_target_content.position.x = (
		drag_x + float(_portrait_main_tab_swipe_tab_step) * viewport_width
	)
	if _portrait_main_tab_swipe_departing_navigation != null:
		_portrait_main_tab_swipe_departing_navigation.position.x = -drag_x
	if _portrait_main_tab_swipe_departing_top_bar != null:
		_portrait_main_tab_swipe_departing_top_bar.position.x = -drag_x

func _animate_portrait_main_tab_swipe(commit: bool) -> void:
	if (
		_portrait_main_tab_swipe_departing_content == null
		or _portrait_main_tab_swipe_target_content == null
	):
		_clear_portrait_main_tab_swipe_transition()
		return
	_portrait_main_tab_swipe_animating = true
	var viewport_width: float = get_viewport().get_visible_rect().size.x
	var departing_end_x: float = (
		-float(_portrait_main_tab_swipe_tab_step) * viewport_width
		if commit
		else 0.0
	)
	var target_end_x: float = (
		0.0
		if commit
		else float(_portrait_main_tab_swipe_tab_step) * viewport_width
	)
	var tween: Tween = _portrait_main_tab_swipe_departing_content.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(
		_portrait_main_tab_swipe_departing_content,
		"position:x",
		departing_end_x,
		PORTRAIT_MAIN_TAB_SWIPE_RELEASE_DURATION
	)
	tween.tween_property(
		_portrait_main_tab_swipe_target_content,
		"position:x",
		target_end_x,
		PORTRAIT_MAIN_TAB_SWIPE_RELEASE_DURATION
	)
	if _portrait_main_tab_swipe_departing_navigation != null:
		tween.tween_property(
			_portrait_main_tab_swipe_departing_navigation,
			"position:x",
			-departing_end_x,
			PORTRAIT_MAIN_TAB_SWIPE_RELEASE_DURATION
		)
	if _portrait_main_tab_swipe_departing_top_bar != null:
		tween.tween_property(
			_portrait_main_tab_swipe_departing_top_bar,
			"position:x",
			-departing_end_x,
			PORTRAIT_MAIN_TAB_SWIPE_RELEASE_DURATION
		)
	tween.finished.connect(
		Callable(self, "_complete_portrait_main_tab_swipe").bind(commit),
		CONNECT_ONE_SHOT
	)

func _complete_portrait_main_tab_swipe(commit: bool) -> void:
	var origin_tab: int = _portrait_main_tab_swipe_origin_tab
	var target_tab: int = _portrait_main_tab_swipe_target_tab
	var departing_content: Control = _portrait_main_tab_swipe_departing_content
	var target_content: Control = _portrait_main_tab_swipe_target_content
	var departing_navigation: Control = _portrait_main_tab_swipe_departing_navigation
	var target_navigation: Control = _portrait_main_tab_swipe_target_navigation
	var departing_top_bar: Control = _portrait_main_tab_swipe_departing_top_bar
	var target_top_bar: Control = _portrait_main_tab_swipe_target_top_bar
	if commit and target_content != null and is_instance_valid(target_content):
		if departing_navigation != null and is_instance_valid(departing_navigation):
			departing_navigation.visible = false
		if departing_top_bar != null and is_instance_valid(departing_top_bar):
			departing_top_bar.visible = false
		if target_top_bar != null and is_instance_valid(target_top_bar):
			target_top_bar.position.x = 0.0
			target_top_bar.visible = true
		if departing_content != null and is_instance_valid(departing_content):
			departing_content.queue_free()
		target_content.position.x = 0.0
		target_content.mouse_filter = Control.MOUSE_FILTER_PASS
		if target_navigation != null and is_instance_valid(target_navigation):
			var navigation_parent: Node = target_navigation.get_parent()
			if navigation_parent != null:
				navigation_parent.remove_child(target_navigation)
			target_navigation.queue_free()
		content = target_content
		# The preview navigation is static and hidden during the drag. Rebuild it
		# only after the page arrives so the old tab shrinks and the new tab grows
		# with the original enter/leave animation in the fixed bottom bar.
		_stage_main_navigation(target_tab, origin_tab)
		_play_ui_click_sound()
		_clear_portrait_main_tab_swipe_transition()
		return

	if target_content != null and is_instance_valid(target_content):
		target_content.queue_free()
	if departing_content != null and is_instance_valid(departing_content):
		departing_content.position.x = 0.0
		departing_content.mouse_filter = Control.MOUSE_FILTER_PASS
		content = departing_content
	_portrait_active_main_tab = origin_tab
	var restore_action: Callable = _portrait_main_tab_action(origin_tab)
	_clear_portrait_main_tab_swipe_transition()
	if restore_action.is_valid():
		restore_action.call_deferred()

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

func _portrait_footer_long_button_rect(rect: Rect2) -> Rect2:
	var shortened_width: float = rect.size.x * PORTRAIT_FOOTER_LONG_BUTTON_WIDTH_SCALE
	var shortened_rect := Rect2(
		Vector2(rect.position.x + (rect.size.x - shortened_width) * 0.5, rect.position.y),
		Vector2(shortened_width, rect.size.y)
	)
	if rect.position.y < PORTRAIT_FOOTER_Y:
		return shortened_rect
	return _portrait_scaled_footer_control_rect(shortened_rect)

func _portrait_footer_round_button_rect(rect: Rect2) -> Rect2:
	return _portrait_scaled_footer_control_rect(rect)

func _portrait_scaled_footer_control_rect(rect: Rect2) -> Rect2:
	var scaled_size: Vector2 = rect.size * PORTRAIT_FOOTER_CONTROL_SCALE
	return Rect2(rect.get_center() - scaled_size * 0.5, scaled_size)

func _portrait_footer_font_size(font_size: int) -> int:
	return int(round(float(font_size) * PORTRAIT_FOOTER_CONTROL_SCALE))

func _portrait_footer_icon_size(icon_size: Vector2) -> Vector2:
	return icon_size * PORTRAIT_FOOTER_CONTROL_SCALE

func _portrait_begin_bottom_attached_group() -> Control:
	var previous_content: Control = content
	var bottom_group := Control.new()
	bottom_group.name = "PortraitBottomAttached"
	bottom_group.set_anchors_preset(Control.PRESET_FULL_RECT)
	bottom_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	previous_content.add_child(bottom_group)
	content = bottom_group
	return previous_content

func _portrait_create_top_bar_group() -> Control:
	var top_bar := Control.new()
	top_bar.name = "PortraitTopBar"
	top_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(top_bar)
	_portrait_top_bar_content = top_bar
	return top_bar

func _portrait_screen(
	_header_height: float = PORTRAIT_HEADER_HEIGHT,
	footer_y: float = -1.0,
	header_color: Color = PORTRAIT_BLUE
) -> void:
	var paper_background := _stage_texture_fill(0.0, PORTRAIT_STAGE_SIZE.y, MENU_PAPER_COVER)
	paper_background.set("tile_scale", PORTRAIT_PAPER_GRID_SCALE)
	paper_background.z_index = -2
	var screen_content: Control = content
	content = _portrait_create_top_bar_group()
	_stage_horizontal_fill(0.0, PORTRAIT_HEADER_HEIGHT, header_color)
	content = screen_content
	if footer_y >= 0.0:
		_stage_horizontal_fill(footer_y, PORTRAIT_STAGE_SIZE.y - footer_y, PORTRAIT_BLUE)

func _stage_portrait_page_header(
	title: String,
	back_callable: Callable,
	currency_return_action: Callable = Callable()
) -> void:
	var screen_content: Control = content
	if _portrait_top_bar_content != null and is_instance_valid(_portrait_top_bar_content):
		content = _portrait_top_bar_content
	if back_callable.is_valid():
		var back_button := _stage_round_icon_button(
			PORTRAIT_PAGE_BACK_BUTTON_RECT,
			back_callable,
			PORTRAIT_BACK_ARROW_ICON,
			PORTRAIT_PAGE_BACK_ICON_SIZE
		)
		_animate_portrait_back_button_entrance(back_button, PORTRAIT_PAGE_BACK_BUTTON_RECT)
	var resolved_return_action: Callable = currency_return_action
	if !resolved_return_action.is_valid():
		resolved_return_action = back_callable
	if !resolved_return_action.is_valid():
		resolved_return_action = Callable(self, "show_menu")
	_stage_currency_counter(resolved_return_action)
	content = screen_content
	_stage_portrait_page_title(title)

func _animate_portrait_back_button_entrance(button: Control, final_rect: Rect2) -> void:
	if button == null or !is_instance_valid(button) or !button.is_inside_tree():
		return
	var should_animate: bool = (
		!_portrait_back_button_visible
		and !_portrait_previous_screen_had_back
	)
	_portrait_back_button_visible = true
	if !should_animate:
		return
	var start_rect: Rect2 = final_rect
	start_rect.position.x = -final_rect.size.x - PORTRAIT_BACK_ENTRANCE_GAP
	button.set("stage_rect", start_rect)
	var tween: Tween = button.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var slide_tweener: PropertyTweener = tween.tween_property(
		button,
		"stage_rect",
		final_rect,
		PORTRAIT_BACK_ENTRANCE_DURATION
	)
	slide_tweener.set_trans(Tween.TRANS_QUAD)
	slide_tweener.set_ease(Tween.EASE_OUT)

func _stage_portrait_page_title(title: String, color: Color = PORTRAIT_BLUE) -> void:
	var title_label := _stage_heading_label(
		PORTRAIT_PAGE_TITLE_RECT,
		title,
		30,
		color,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	title_label.clip_text = false
	_fit_single_line_label_to_width(
		title_label,
		title,
		PORTRAIT_PAGE_TITLE_RECT.size.x,
		_heading_font_size(30),
		_heading_font_size(20)
	)

func _stage_currency_counter(
	return_action: Callable,
	rect: Rect2 = Rect2(),
	challenge_colors: bool = false
) -> void:
	var screen_content: Control = content
	if _portrait_top_bar_content != null and is_instance_valid(_portrait_top_bar_content):
		content = _portrait_top_bar_content
	var counter_rect: Rect2 = rect if rect.size.x > 0.0 and rect.size.y > 0.0 else PORTRAIT_CURRENCY_COUNTER_RECT
	var counter_scale: float = counter_rect.size.y / 48.0
	var panel_color: Color = PORTRAIT_CHALLENGE_HUD_PANEL if challenge_colors else PORTRAIT_DARK_BLUE
	var border_color: Color = PORTRAIT_CHALLENGE_HUD_BORDER if challenge_colors else Color(0.72, 0.77, 0.91, 1.0)
	var counter_parent_content: Control = content
	var counter_visual := Control.new()
	counter_visual.name = "CurrencyCounterVisual"
	counter_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	counter_parent_content.add_child(counter_visual)
	counter_visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content = counter_visual
	var panel := _stage_panel(
		counter_rect,
		panel_color,
		counter_rect.size.y * 0.5,
		border_color,
		2.0 * counter_scale
	)
	panel.z_index = 20
	var icon_rect := Rect2(
		counter_rect.position + Vector2(2.0 * counter_scale, (counter_rect.size.y - PORTRAIT_CURRENCY_ICON_SIZE) * 0.5),
		Vector2(PORTRAIT_CURRENCY_ICON_SIZE, PORTRAIT_CURRENCY_ICON_SIZE)
	)
	var coin_icon := _stage_texture(icon_rect, SOFT_CURRENCY_COIN_TEXTURE)
	coin_icon.z_index = 21
	var add_badge_size: float = PORTRAIT_CURRENCY_ADD_BADGE_SIZE * counter_scale
	var add_badge_rect := Rect2(
		icon_rect.end - Vector2.ONE * add_badge_size * 0.82,
		Vector2.ONE * add_badge_size
	)
	var add_badge := _stage_panel(
		add_badge_rect,
		PORTRAIT_CURRENCY_ADD_BADGE_GREEN,
		add_badge_size * 0.5,
		PORTRAIT_CURRENCY_ADD_BADGE_BORDER,
		maxf(1.0, 1.5 * counter_scale)
	)
	add_badge.z_index = 22
	# Draw the plus as two solid strokes instead of a font glyph. At the compact
	# HUD scale a glyph can be clipped down to an indistinguishable green dot,
	# while these arms remain crisp on every viewport density.
	var plus_arm: float = add_badge_size * 0.58
	var plus_stroke: float = maxf(2.0, add_badge_size * 0.20)
	var plus_center: Vector2 = add_badge_rect.get_center()
	var plus_horizontal := _stage_panel(
		Rect2(
			plus_center - Vector2(plus_arm, plus_stroke) * 0.5,
			Vector2(plus_arm, plus_stroke)
		),
		Color.WHITE,
		plus_stroke * 0.5
	)
	plus_horizontal.z_index = 23
	var plus_vertical := _stage_panel(
		Rect2(
			plus_center - Vector2(plus_stroke, plus_arm) * 0.5,
			Vector2(plus_stroke, plus_arm)
		),
		Color.WHITE,
		plus_stroke * 0.5
	)
	plus_vertical.z_index = 23
	var balance_rect := Rect2(
		Vector2(counter_rect.position.x + 43.0 * counter_scale, counter_rect.position.y),
		Vector2(counter_rect.size.x - 49.0 * counter_scale, counter_rect.size.y)
	)
	var balance_text: String = str(GameState.get_soft_currency())
	var balance_font_size: int = maxi(1, int(round(24.0 * counter_scale)))
	var balance_min_font_size: int = maxi(1, int(round(14.0 * counter_scale)))
	var balance_label := _stage_label(
		balance_rect,
		balance_text,
		balance_font_size,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	balance_label.add_theme_font_override("font", UI_PRIMARY_FONT)
	currency_balance_label = balance_label
	balance_label.z_index = 21
	_fit_single_line_label_to_width(balance_label, balance_text, balance_rect.size.x, balance_font_size, balance_min_font_size)
	content = counter_parent_content
	var counter_action: Callable = Callable(self, "_open_coin_store").bind(return_action)
	if return_action.is_valid() and return_action.get_method() in [&"show_coin_store", &"_show_coin_store_tab"]:
		counter_action = return_action
	var counter_button := _stage_button(counter_rect, counter_action, "")
	counter_button.z_index = 24
	counter_button.button_down.connect(
		Callable(self, "_set_currency_counter_pressed").bind(
			counter_visual,
			counter_rect,
			true
		)
	)
	counter_button.button_up.connect(
		Callable(self, "_set_currency_counter_pressed").bind(
			counter_visual,
			counter_rect,
			false
		)
	)
	counter_button.mouse_exited.connect(
		Callable(self, "_set_currency_counter_pressed").bind(
			counter_visual,
			counter_rect,
			false
		)
	)
	content = screen_content

func _set_currency_counter_pressed(
	counter_visual: Control,
	counter_rect: Rect2,
	is_pressed: bool
) -> void:
	if counter_visual == null or !is_instance_valid(counter_visual) or !counter_visual.is_inside_tree():
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var fit_scale: float = PORTRAIT_STAGE_LAYOUT.fit_scale(viewport_size)
	var mapped_position: Vector2 = Vector2(
		PORTRAIT_STAGE_LAYOUT.horizontal_offset(viewport_size),
		0.0
	) + PORTRAIT_STAGE_LAYOUT.map_rect_position(
		counter_rect,
		viewport_size,
		counter_visual
	) * fit_scale
	counter_visual.pivot_offset = mapped_position + counter_rect.size * fit_scale * 0.5
	var previous_tween: Tween = counter_visual.get_meta(&"press_tween", null) as Tween
	if previous_tween != null and previous_tween.is_valid():
		previous_tween.kill()
	var target_scale: Vector2 = (
		Vector2.ONE * PORTRAIT_CURRENCY_COUNTER_PRESSED_SCALE
		if is_pressed
		else Vector2.ONE
	)
	var duration: float = (
		PORTRAIT_CURRENCY_COUNTER_PRESS_DURATION
		if is_pressed
		else PORTRAIT_CURRENCY_COUNTER_RELEASE_DURATION
	)
	var press_tween: Tween = counter_visual.create_tween()
	press_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var scale_tweener: PropertyTweener = press_tween.tween_property(
		counter_visual,
		"scale",
		target_scale,
		duration
	)
	scale_tweener.set_trans(Tween.TRANS_QUAD)
	scale_tweener.set_ease(Tween.EASE_OUT)
	counter_visual.set_meta(&"press_tween", press_tween)

func _portrait_main_tab_action(tab_index: int) -> Callable:
	match tab_index:
		MainTab.PROFILE:
			return Callable(self, "show_profile")
		MainTab.SHOP:
			return Callable(self, "_show_coin_store_tab")
		MainTab.HOME:
			return Callable(self, "show_menu")
		MainTab.TASKS:
			return Callable(self, "show_tasks")
		MainTab.SETTINGS:
			return Callable(self, "show_settings")
	return Callable()

func _portrait_main_tab_label(tab_index: int) -> String:
	match tab_index:
		MainTab.PROFILE:
			return _profile_text("Профиль", "Profile").to_upper()
		MainTab.SHOP:
			return _profile_text("Магазин", "Shop").to_upper()
		MainTab.HOME:
			return _profile_text("Главная", "Home").to_upper()
		MainTab.TASKS:
			return _profile_text("Задания", "Tasks").to_upper()
		MainTab.SETTINGS:
			return _profile_text("Настройки", "Settings").to_upper()
	return ""

func _portrait_main_nav_icon_rect(tab_x: float, is_active: bool) -> Rect2:
	var icon_size: float = PORTRAIT_MAIN_NAV_ICON_SIZE if is_active else PORTRAIT_MAIN_NAV_INACTIVE_ICON_SIZE
	var icon_y: float = PORTRAIT_MAIN_NAV_ACTIVE_ICON_Y if is_active else PORTRAIT_MAIN_NAV_INACTIVE_ICON_Y
	var icon_center_x: float = tab_x + PORTRAIT_MAIN_NAV_ITEM_WIDTH * 0.5
	if is_active:
		icon_center_x = _portrait_main_nav_active_x(tab_x) + PORTRAIT_MAIN_NAV_ACTIVE_RECT_SIZE.x * 0.5
	return Rect2(
		icon_center_x - icon_size * 0.5,
		icon_y,
		icon_size,
		icon_size
	)

func _portrait_main_nav_active_x(tab_x: float) -> float:
	var centered_x: float = tab_x + (
		PORTRAIT_MAIN_NAV_ITEM_WIDTH - PORTRAIT_MAIN_NAV_ACTIVE_RECT_SIZE.x
	) * 0.5
	return clampf(
		centered_x,
		0.0,
		PORTRAIT_STAGE_SIZE.x - PORTRAIT_MAIN_NAV_ACTIVE_RECT_SIZE.x
	)

func _portrait_main_nav_label_rect(tab_x: float) -> Rect2:
	return Rect2(
		_portrait_main_nav_active_x(tab_x),
		PORTRAIT_MAIN_NAV_LABEL_Y,
		PORTRAIT_MAIN_NAV_ACTIVE_RECT_SIZE.x,
		PORTRAIT_MAIN_NAV_LABEL_HEIGHT
	)

func _stage_main_nav_label(tab_x: float, tab_label: String) -> Label:
	var label_rect: Rect2 = _portrait_main_nav_label_rect(tab_x)
	var label := _stage_label(
		label_rect,
		tab_label,
		PORTRAIT_MAIN_NAV_LABEL_FONT_SIZE,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	label.z_index = 44
	label.clip_text = false
	var nav_label_effect_color := Color(
		PORTRAIT_DARK_BLUE.r,
		PORTRAIT_DARK_BLUE.g,
		PORTRAIT_DARK_BLUE.b,
		0.55
	)
	label.add_theme_color_override("font_outline_color", nav_label_effect_color)
	label.add_theme_constant_override("outline_size", 1)
	label.add_theme_color_override("font_shadow_color", nav_label_effect_color)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.add_theme_constant_override("shadow_outline_size", 0)
	var bold_font := FontVariation.new()
	bold_font.base_font = label.get_theme_font("font")
	bold_font.variation_embolden = 0.75
	label.add_theme_font_override("font", bold_font)
	_fit_single_line_label_to_width(
		label,
		tab_label,
		label_rect.size.x,
		PORTRAIT_MAIN_NAV_LABEL_FONT_SIZE,
		12
	)
	label.pivot_offset = label_rect.size * 0.5
	return label

func _animate_main_nav_tab_enter(icon: Control, label: Label, final_icon_rect: Rect2) -> void:
	icon.modulate = Color(0.92, 0.94, 1.0, 1.0)
	label.scale = Vector2.ONE * PORTRAIT_MAIN_NAV_TRANSITION_TEXT_SCALE
	label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var tween: Tween = icon.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	var icon_size_tweener: PropertyTweener = tween.tween_property(
		icon,
		"stage_rect",
		final_icon_rect,
		PORTRAIT_MAIN_NAV_TRANSITION_DURATION
	)
	icon_size_tweener.set_trans(Tween.TRANS_QUAD)
	icon_size_tweener.set_ease(Tween.EASE_OUT)
	tween.tween_property(icon, "modulate", Color.WHITE, PORTRAIT_MAIN_NAV_TRANSITION_DURATION)
	var label_scale_tweener: PropertyTweener = tween.tween_property(
		label,
		"scale",
		Vector2.ONE,
		PORTRAIT_MAIN_NAV_TRANSITION_DURATION
	)
	label_scale_tweener.set_trans(Tween.TRANS_QUAD)
	label_scale_tweener.set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate", Color.WHITE, PORTRAIT_MAIN_NAV_TRANSITION_DURATION)
	tween.finished.connect(
		Callable(self, "_play_main_nav_icon_bounce").bind(icon),
		CONNECT_ONE_SHOT
	)

func _play_main_nav_icon_bounce(icon: Control) -> void:
	if icon == null or !is_instance_valid(icon) or !icon.is_inside_tree():
		return
	# Transform around the texture's local center. Animating stage_rect also
	# remaps its authored position every frame and can drift sideways inside the
	# bottom-attached coordinate group on tall screens.
	var rest_position: Vector2 = icon.position
	var rest_scale: Vector2 = icon.scale
	icon.pivot_offset = icon.size * 0.5
	icon.position = rest_position + (rest_scale - Vector2.ONE) * icon.pivot_offset
	var tween: Tween = icon.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var grow_tweener: PropertyTweener = tween.tween_property(
		icon,
		"scale",
		rest_scale * PORTRAIT_MAIN_NAV_BOUNCE_SCALE,
		PORTRAIT_MAIN_NAV_BOUNCE_GROW_DURATION
	)
	grow_tweener.set_trans(Tween.TRANS_QUAD)
	grow_tweener.set_ease(Tween.EASE_OUT)
	var settle_tweener: PropertyTweener = tween.tween_property(
		icon,
		"scale",
		rest_scale,
		PORTRAIT_MAIN_NAV_BOUNCE_SETTLE_DURATION
	)
	settle_tweener.set_trans(Tween.TRANS_BOUNCE)
	settle_tweener.set_ease(Tween.EASE_OUT)
	tween.finished.connect(
		Callable(self, "_finish_main_nav_icon_bounce").bind(icon, rest_position),
		CONNECT_ONE_SHOT
	)

func _finish_main_nav_icon_bounce(icon: Control, rest_position: Vector2) -> void:
	if icon == null or !is_instance_valid(icon) or !icon.is_inside_tree():
		return
	icon.pivot_offset = Vector2.ZERO
	icon.position = rest_position

func _animate_main_nav_tab_leave(icon: Control, label: Label, final_icon_rect: Rect2) -> void:
	var label_holder: Control = label.get_parent() as Control
	var tween: Tween = icon.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	var icon_size_tweener: PropertyTweener = tween.tween_property(
		icon,
		"stage_rect",
		final_icon_rect,
		PORTRAIT_MAIN_NAV_TRANSITION_DURATION
	)
	icon_size_tweener.set_trans(Tween.TRANS_SINE)
	icon_size_tweener.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(
		icon,
		"modulate",
		Color(0.92, 0.94, 1.0, 1.0),
		PORTRAIT_MAIN_NAV_TRANSITION_DURATION
	)
	var label_scale_tweener: PropertyTweener = tween.tween_property(
		label,
		"scale",
		Vector2.ONE * PORTRAIT_MAIN_NAV_TRANSITION_TEXT_SCALE,
		PORTRAIT_MAIN_NAV_TRANSITION_DURATION
	)
	label_scale_tweener.set_trans(Tween.TRANS_SINE)
	label_scale_tweener.set_ease(Tween.EASE_IN)
	tween.tween_property(
		label,
		"modulate",
		Color(1.0, 1.0, 1.0, 0.0),
		PORTRAIT_MAIN_NAV_TRANSITION_DURATION
	)
	tween.finished.connect(
		Callable(self, "_finish_main_nav_tab_leave").bind(
			icon,
			label_holder,
			final_icon_rect
		),
		CONNECT_ONE_SHOT
	)

func _finish_main_nav_tab_leave(
	icon: Control,
	label_holder: Control,
	final_icon_rect: Rect2
) -> void:
	# Replace the animated texture with a clean, static instance. Reusing the
	# tweened Control could retain a transform frame from the active-tab bounce,
	# which made the Tasks icon sit too low until the navigation was rebuilt.
	if icon != null and is_instance_valid(icon) and icon.is_inside_tree():
		var icon_parent: Node = icon.get_parent()
		var rest_icon: Control = FLASH_STAGE_TEXTURE_SCRIPT.new() as Control
		rest_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rest_icon.set("texture", icon.get("texture"))
		rest_icon.modulate = Color(0.92, 0.94, 1.0, 1.0)
		rest_icon.z_index = 42
		icon_parent.add_child(rest_icon)
		rest_icon.set("stage_rect", final_icon_rect)
		icon.queue_free()
	if label_holder != null and is_instance_valid(label_holder):
		label_holder.queue_free()

func _stage_main_navigation(active_tab: int, previous_tab: int = -1) -> void:
	if !_portrait_main_tab_swipe_building_target:
		_portrait_active_main_tab = active_tab
		_reset_portrait_main_tab_swipe()
	var animates_switch: bool = (
		previous_tab >= MainTab.PROFILE
		and previous_tab <= MainTab.SETTINGS
		and previous_tab != active_tab
	)
	# Keep every navigation element in one bottom-attached coordinate space.
	# The active tab intentionally begins above PORTRAIT_MAIN_NAV_Y; without
	# this group, tall screens map it as regular content while the blue bar is
	# pinned to the bottom, separating both the visuals and their hit areas.
	var previous_content: Control = _portrait_begin_bottom_attached_group()
	content.name = "PortraitMainNavigation"
	content.visible = !_portrait_main_tab_swipe_building_target
	var navigation_panel := _stage_panel(
		Rect2(0.0, PORTRAIT_MAIN_NAV_Y, PORTRAIT_STAGE_SIZE.x, PORTRAIT_MAIN_NAV_HEIGHT),
		PORTRAIT_BLUE
	)
	navigation_panel.z_index = 40
	var top_rule := _stage_panel(
		Rect2(0.0, PORTRAIT_MAIN_NAV_Y, PORTRAIT_STAGE_SIZE.x, 2.0),
		Color(0.68, 0.75, 0.94, 1.0)
	)
	top_rule.z_index = 41

	for tab_index in range(5):
		var tab_action: Callable = _portrait_main_tab_action(tab_index)
		var tab_icon: Texture2D
		var tab_label: String = _portrait_main_tab_label(tab_index)
		match tab_index:
			MainTab.PROFILE:
				tab_icon = PORTRAIT_NAV_PROFILE_ICON
			MainTab.SHOP:
				tab_icon = PORTRAIT_NAV_SHOP_ICON
			MainTab.HOME:
				tab_icon = PORTRAIT_NAV_HOME_ICON
			MainTab.TASKS:
				tab_icon = PORTRAIT_NAV_TASKS_ICON
			_:
				tab_icon = PORTRAIT_NAV_SETTINGS_ICON

		var tab_x: float = float(tab_index) * PORTRAIT_MAIN_NAV_ITEM_WIDTH
		var is_active: bool = tab_index == active_tab
		var was_active: bool = animates_switch and tab_index == previous_tab
		var hit_rect := Rect2(tab_x, PORTRAIT_MAIN_NAV_ACTIVE_Y, PORTRAIT_MAIN_NAV_ITEM_WIDTH, PORTRAIT_MAIN_NAV_ACTIVE_RECT_SIZE.y)
		if is_active:
			# Compose a rounded cap with a square body: only the upper corners of
			# the selected tab are rounded, while its lower edge joins the bar.
			var active_cap := _stage_panel(
				Rect2(_portrait_main_nav_active_x(tab_x), PORTRAIT_MAIN_NAV_ACTIVE_Y, PORTRAIT_MAIN_NAV_ACTIVE_RECT_SIZE.x, 36.0),
				PORTRAIT_ORANGE,
				18.0
			)
			active_cap.z_index = 42
			var active_body := _stage_panel(
				Rect2(_portrait_main_nav_active_x(tab_x), PORTRAIT_MAIN_NAV_ACTIVE_Y + 18.0, PORTRAIT_MAIN_NAV_ACTIVE_RECT_SIZE.x, PORTRAIT_MAIN_NAV_ACTIVE_RECT_SIZE.y - 18.0),
				PORTRAIT_ORANGE
			)
			active_body.z_index = 42
			var active_icon := _stage_texture(
				_portrait_main_nav_icon_rect(tab_x, !animates_switch),
				tab_icon
			)
			active_icon.z_index = 43
			var active_label := _stage_main_nav_label(tab_x, tab_label)
			if animates_switch:
				_animate_main_nav_tab_enter(
					active_icon,
					active_label,
					_portrait_main_nav_icon_rect(tab_x, true)
				)
		else:
			var inactive_icon := _stage_texture(
				_portrait_main_nav_icon_rect(tab_x, was_active),
				tab_icon
			)
			inactive_icon.z_index = 42
			if was_active:
				var departing_label := _stage_main_nav_label(tab_x, tab_label)
				_animate_main_nav_tab_leave(
					inactive_icon,
					departing_label,
					_portrait_main_nav_icon_rect(tab_x, false)
				)
			else:
				inactive_icon.modulate = Color(0.92, 0.94, 1.0, 1.0)
		var tab_button := _stage_button(hit_rect, tab_action, "")
		tab_button.z_index = 46
	content = previous_content

func _show_main_tab_screen(screen_builder: Callable, active_tab: int) -> void:
	var previous_tab: int = (
		-1
		if _portrait_main_tab_swipe_building_target
		else _portrait_active_main_tab
	)
	screen_builder.call()
	_stage_main_navigation(active_tab, previous_tab)

func _show_coin_store_tab() -> void:
	coin_store_return_action = Callable()
	_show_main_tab_screen(Callable(self, "_show_coin_store_screen").bind(true), MainTab.SHOP)

func show_coin_store() -> void:
	_show_coin_store_screen(false)

func _show_coin_store_screen(with_main_navigation: bool) -> void:
	_clear()
	if with_main_navigation:
		_portrait_screen(0.0, PORTRAIT_MAIN_NAV_Y)
		_stage_currency_counter(Callable(self, "_show_coin_store_tab"))
		_stage_portrait_page_title(_portrait_main_tab_label(MainTab.SHOP))
	else:
		_portrait_screen(0.0)
		_stage_portrait_page_header(
			tr("COIN_STORE_TITLE"),
			Callable(self, "_close_coin_store"),
			Callable(self, "show_coin_store")
		)
	_stage_main_button(
		PORTRAIT_COIN_TEST_BUTTON_RECT,
		Callable(self, "_grant_test_coins"),
		_single_player_text("ТЕСТ: +100 МОНЕТ", "TEST: +100 COINS"),
		22
	)

func _grant_test_coins() -> void:
	GameState.add_soft_currency(100)

func show_tasks() -> void:
	coin_store_return_action = Callable()
	_show_main_tab_screen(Callable(self, "_show_theme_select_screen").bind(true), MainTab.TASKS)

func _stage_single_player_level_header(level_index: int) -> void:
	_stage_portrait_page_header(
		"%s %d" % [_single_player_level_label(), level_index + 1],
		Callable(self, "show_menu"),
		Callable(self, "show_single_player_level").bind(level_index)
	)

func _portrait_game_header_texts() -> Dictionary:
	var title: String = ""
	var subtitle: String = ""
	match GameState.current_mode:
		GameState.GameMode.TWO_PLAYER:
			title = _single_player_text("2 игрока", "2 players")
		GameState.GameMode.SINGLE_PLAYER:
			var level_number: int = single_player_active_level_index + 1
			if level_number <= 0:
				level_number = _single_player_current_level_number()
			title = "%s %d" % [_single_player_level_label(), level_number]
			if GameSession.theme_id >= 0:
				subtitle = _portrait_sentence_case(Database.get_theme_name(GameSession.theme_id))
		_:
			title = _single_player_text("Классика", "Classic")
			if GameSession.theme_id >= 0:
				subtitle = _portrait_sentence_case(Database.get_theme_name(GameSession.theme_id))
	return {
		"title": title,
		"subtitle": subtitle,
	}

func _portrait_sentence_case(text: String) -> String:
	var lowered_text: String = text.to_lower()
	if lowered_text.is_empty():
		return lowered_text
	return lowered_text.substr(0, 1).to_upper() + lowered_text.substr(1)

func _stage_portrait_game_header() -> void:
	var header_texts: Dictionary = _portrait_game_header_texts()
	var title: String = str(header_texts["title"])
	var subtitle: String = str(header_texts["subtitle"])
	var header_text: String = title
	var heading_font_size: int = 24
	if !subtitle.is_empty():
		header_text += " • " + subtitle
	header_text = header_text.to_upper()

	var title_label := _stage_heading_label(
		PORTRAIT_GAME_HEADER_RECT,
		header_text,
		heading_font_size,
		PORTRAIT_BLUE,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	title_label.clip_text = false
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_fit_single_line_label_to_width(
		title_label,
		header_text,
		PORTRAIT_GAME_HEADER_RECT.size.x,
		_heading_font_size(heading_font_size),
		_heading_font_size(13)
	)
	_stage_currency_counter(
		Callable(self, "show_game_screen"),
		Rect2(),
		_portrait_game_is_challenge_level()
	)

func _portrait_game_is_challenge_level() -> bool:
	return (
		GameState.current_mode == GameState.GameMode.SINGLE_PLAYER
		and _single_player_is_bonus_level(single_player_active_level_index)
	)

func _portrait_game_header_color() -> Color:
	if _portrait_game_is_challenge_level():
		return PORTRAIT_CHALLENGE_POPUP_HEADER
	return PORTRAIT_BLUE

func _portrait_popup_begin(name: String, group_name: String, layer_index: int, close_callable: Callable, popup_top: float, popup_bottom: float, alpha: float = PORTRAIT_POPUP_DIM_ALPHA) -> Control:
	_play_popup_open_sound()
	_reset_portrait_main_tab_swipe()
	var previous_content: Control = content
	var popup_layer := CanvasLayer.new()
	popup_layer.name = name + "Canvas"
	popup_layer.layer = layer_index
	popup_layer.add_to_group(group_name)
	popup_layer.add_to_group(PORTRAIT_MODAL_POPUP_GROUP)
	add_child(popup_layer)

	var popup_root := Control.new()
	popup_root.name = name + "Layer"
	popup_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup_root.mouse_filter = Control.MOUSE_FILTER_STOP
	popup_root.theme = ui.theme
	popup_layer.add_child(popup_root)
	content = popup_root
	_add_fullscreen_modal_backdrop(close_callable, alpha)
	content = _center_popup_content(popup_root, popup_top, popup_bottom)
	return previous_content

func _portrait_popup_shell(
	rect: Rect2,
	title: String,
	close_callable: Callable,
	title_font_size: int = 28,
	header_color: Color = PORTRAIT_BLUE,
	body_color: Color = PORTRAIT_DARK_BLUE,
	separator_color: Color = PORTRAIT_ORANGE,
	subtitle: String = ""
) -> void:
	# PopupStageCenter centers the authored body bounds and scales the complete
	# modal composition around that center on every supported aspect ratio.
	var header_rect := Rect2(rect.position, Vector2(rect.size.x, 80.0))
	var body_rect := Rect2(rect.position + Vector2(0.0, 80.0), Vector2(rect.size.x, rect.size.y - 80.0))
	var header := _stage_panel(header_rect, header_color)
	header.mouse_filter = Control.MOUSE_FILTER_STOP
	var body := _stage_panel(body_rect, body_color)
	body.mouse_filter = Control.MOUSE_FILTER_STOP
	var separator := _stage_panel(Rect2(rect.position.x, rect.position.y + 79.0, rect.size.x, 2.0), separator_color)
	separator.mouse_filter = Control.MOUSE_FILTER_STOP
	var title_rect := Rect2(
		rect.position.x + 20.0,
		rect.position.y + (3.0 if !subtitle.is_empty() else 10.0),
		rect.size.x - 40.0,
		56.0 if subtitle.is_empty() else 42.0
	)
	var title_label := _stage_heading_label(
		title_rect,
		title,
		title_font_size,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	title_label.clip_text = false
	if !subtitle.is_empty():
		var subtitle_label := _stage_label(
			Rect2(rect.position.x + 20.0, rect.position.y + 43.0, rect.size.x - 40.0, 28.0),
			subtitle,
			16,
			Color.WHITE,
			HORIZONTAL_ALIGNMENT_CENTER
		)
		subtitle_label.clip_text = false

	var close_x: float = rect.position.x + (rect.size.x - PORTRAIT_POPUP_CLOSE_SIZE) * 0.5
	var close_y: float = rect.end.y + PORTRAIT_POPUP_CLOSE_GAP
	_stage_round_button(Rect2(close_x, close_y, PORTRAIT_POPUP_CLOSE_SIZE, PORTRAIT_POPUP_CLOSE_SIZE), close_callable, "×")

func _portrait_popup_button_rect(rect: Rect2) -> Rect2:
	# Popup action buttons first receive a uniform 15% scale-up. Their horizontal
	# length is then reduced by 15%, preserving the larger height and touch target
	# without making two-button rows wider than their authored popup layout.
	var scaled_size: Vector2 = rect.size * PORTRAIT_POPUP_BUTTON_UNIFORM_SCALE
	scaled_size.x *= PORTRAIT_POPUP_BUTTON_LENGTH_SCALE
	return Rect2(rect.get_center() - scaled_size * 0.5, scaled_size)

func _portrait_popup_font_size(font_size: int) -> int:
	return int(round(float(font_size) * PORTRAIT_POPUP_BUTTON_UNIFORM_SCALE))

func _stage_portrait_popup_main_button(
	rect: Rect2,
	callable: Callable,
	text: String,
	font_size: int = 20,
	disabled: bool = false,
	disabled_overlay_alpha: float = 0.32,
	use_normal_texture_when_disabled: bool = false,
	selected: bool = false,
	attention_bounce: bool = false,
	color_preset: int = LONG_BUTTON_COLOR_BLUE
) -> Control:
	return _stage_main_button(
		_portrait_popup_button_rect(rect),
		callable,
		text,
		_portrait_popup_font_size(font_size),
		disabled,
		disabled_overlay_alpha,
		use_normal_texture_when_disabled,
		selected,
		attention_bounce,
		color_preset
	)

func _stage_settings_toggle_button(rect: Rect2, setting_index: int) -> void:
	var enabled: bool = int(GameState.settings[setting_index]) == 2
	var label_text: String = _settings_on_label() if enabled else _settings_off_label()
	var button := _stage_portrait_popup_main_button(
		rect,
		Callable(self, "_toggle_setting").bind(setting_index),
		label_text,
		18,
		false,
		0.0,
		false,
		enabled,
		false,
		LONG_BUTTON_COLOR_ORANGE
	)
	settings_toggle_buttons[setting_index] = button

func _stage_settings_word_language_button(rect: Rect2, language_code: String, label_text: String) -> void:
	var selected: bool = GameState.word_language == language_code
	var button := _stage_portrait_popup_main_button(
		rect,
		Callable(self, "_set_settings_word_language").bind(language_code),
		label_text,
		18,
		false,
		0.0,
		false,
		selected,
		false,
		LONG_BUTTON_COLOR_ORANGE
	)
	settings_word_language_buttons[language_code] = button

func show_menu() -> void:
	_show_main_tab_screen(Callable(self, "_show_menu_screen"), MainTab.HOME)

func _show_menu_screen() -> void:
	GameSession.discard_current_round()
	single_player_active_level_index = -1
	single_player_active_word_slot = -1
	_portrait_game_adaptive_group = null
	coin_store_return_action = Callable()
	_clear()

	_portrait_screen(0.0, PORTRAIT_MAIN_NAV_Y)
	_stage_currency_counter(Callable(self, "show_menu"))

	var menu_title_content: Control = _portrait_begin_adaptive_group(Vector2(240.0, 230.0), PORTRAIT_MENU_TITLE_MAX_SCALE, 0.04)
	var title_label := _stage_heading_label(Rect2(40.0, 160.0, 400.0, 88.0), Database.tr_text(0, "HANGMAN").to_upper(), 50, PORTRAIT_ORANGE, HORIZONTAL_ALIGNMENT_CENTER)
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_portrait_end_adaptive_group(menu_title_content)

	var button_x: float = 90.0
	_stage_main_button(Rect2(button_x, 554.0, PORTRAIT_LONG_BUTTON_SIZE.x, PORTRAIT_LONG_BUTTON_SIZE.y), Callable(self, "show_custom_word"), Database.tr_text(2, "Two Player").to_upper(), 22)
	_stage_single_player_menu_button(Rect2(67.5, 632.0, 345.0, 73.6), Callable(self, "_open_next_single_player_level"))

func show_settings() -> void:
	_show_main_tab_screen(Callable(self, "_show_settings_screen"), MainTab.SETTINGS)

func _show_settings_screen() -> void:
	coin_store_return_action = Callable()
	_clear()
	_portrait_screen(0.0, PORTRAIT_MAIN_NAV_Y)
	var settings_body_fill := _stage_horizontal_fill(
		PORTRAIT_HEADER_HEIGHT,
		PORTRAIT_STAGE_SIZE.y - PORTRAIT_HEADER_HEIGHT,
		PORTRAIT_DARK_BLUE
	)
	settings_body_fill.set("follows_safe_top_inset", true)
	_stage_currency_counter(Callable(self, "show_settings"))
	_stage_portrait_page_title(_portrait_main_tab_label(MainTab.SETTINGS), Color.WHITE)
	_stage_label(Rect2(56.0, 176.0, 250.0, 42.0), _settings_sound_label(), 21, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_settings_toggle_button(Rect2(330.0, 172.0, 102.0, 49.0), 3)
	_stage_label(Rect2(56.0, 244.0, 250.0, 42.0), _settings_vibration_label(), 21, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_settings_toggle_button(Rect2(330.0, 240.0, 102.0, 49.0), 4)
	_stage_panel(Rect2(56.0, 312.0, 368.0, 2.0), PORTRAIT_RULE)
	_stage_label(Rect2(56.0, 336.0, 150.0, 42.0), _settings_word_base_label(), 21, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_settings_word_language_button(Rect2(210.0, 332.0, 102.0, 49.0), "ru", Database.tr_text(71, "Rus"))
	_stage_settings_word_language_button(Rect2(322.0, 332.0, 102.0, 49.0), "en", Database.tr_text(72, "Eng"))
	_stage_panel(Rect2(56.0, 412.0, 368.0, 2.0), PORTRAIT_RULE)

	var settings_footer_content: Control = _portrait_begin_bottom_attached_group()
	_stage_round_icon_button(
		Rect2(174.0, 616.0, 58.0, 58.0),
		Callable(self, "_about_contact_action").bind("vk"),
		ABOUT_VK_ICON,
		ABOUT_VK_ICON_SIZE
	)
	_stage_round_icon_button(
		Rect2(248.0, 616.0, 58.0, 58.0),
		Callable(self, "_about_contact_action").bind("mail"),
		ABOUT_MAIL_ICON,
		ABOUT_MAIL_ICON_SIZE
	)
	var version_label := _stage_label(
		Rect2(40.0, 678.0, 400.0, 28.0),
		_about_version_text(),
		14,
		Color(0.78, 0.82, 0.96, 0.88),
		HORIZONTAL_ALIGNMENT_CENTER
	)
	version_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	version_label.clip_text = false
	_portrait_end_adaptive_group(settings_footer_content)

func show_theme_select() -> void:
	_show_theme_select_screen(false)

func _show_theme_select_screen(with_main_navigation: bool) -> void:
	_clear()
	if with_main_navigation:
		_portrait_screen(0.0, PORTRAIT_MAIN_NAV_Y)
	else:
		_portrait_screen(0.0)
	var theme_title: String = (
		_portrait_main_tab_label(MainTab.TASKS)
		if with_main_navigation
		else _single_player_text("ИСПЫТАНИЯ", "CHALLENGES")
	)
	if with_main_navigation:
		_stage_currency_counter(Callable(self, "show_tasks"))
		_stage_portrait_page_title(theme_title)
	else:
		_stage_portrait_page_header(
			theme_title,
			Callable(self, "show_menu"),
			Callable(self, "show_theme_select")
		)

	for i in range(Database.get_theme_count()):
		var col: int = i % 2
		var row: int = int(i / 2)
		var x: float = 18.0 + float(col) * 230.0
		var y: float = 154.0 + float(row) * 96.0
		var words_count: int = Database.get_words_by_index(i, GameState.settings[2]).size()
		var guessed: int = Database.get_number_of_guessed_words(i, true)
		var guessed_percent: int = int(round(float(guessed) * 100.0 / float(words_count))) if words_count > 0 else 0
		var disabled: bool = words_count == 0
		var completed: bool = words_count > 0 and guessed >= words_count
		var card := _stage_texture(Rect2(x, y, 214.0, 88.0), THEME_CARD_TEXTURE)
		var progress_back := _stage_texture(Rect2(x, y, 214.0, 63.0), THEME_CARD_PROGRESS_TEXTURE)
		var progress_text: String = Database.tr_text(30, "Guessed") + ": " + str(guessed_percent) + "%"
		var progress_label := _stage_label(Rect2(x + 8.0, y + 7.0 + THEME_PROGRESS_TEXT_OPTICAL_OFFSET_Y, 198.0, 44.0), progress_text, 16, Color(0.43, 0.49, 0.83, 1.0))
		progress_label.clip_text = false
		var theme_name: String = Database.get_theme_name(i).to_upper()
		var theme_icon_texture: Texture2D = _theme_icon_texture(i)
		var theme_icon: Control = null
		if theme_icon_texture != null:
			theme_icon = _stage_texture(Rect2(x + 12.0, y + 42.0, 34.0, 34.0), theme_icon_texture)
			theme_icon.z_index = 11
		var title_font_size: int = 17 if theme_name.length() > 12 else 21
		var title_label := _stage_label(Rect2(x + 52.0, y + 41.0, 152.0, 38.0), theme_name, title_font_size, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
		title_label.clip_text = false
		var theme_effect_color := Color(0.42, 0.49, 0.82, 0.55)
		title_label.add_theme_color_override("font_outline_color", theme_effect_color)
		title_label.add_theme_constant_override("outline_size", 1)
		title_label.add_theme_color_override("font_shadow_color", theme_effect_color)
		title_label.add_theme_constant_override("shadow_offset_x", 2)
		title_label.add_theme_constant_override("shadow_offset_y", 2)
		title_label.add_theme_constant_override("shadow_outline_size", 0)
		if disabled:
			card.modulate = Color(1.0, 1.0, 1.0, 0.45)
			progress_back.modulate = Color(1.0, 1.0, 1.0, 0.45)
			progress_label.modulate = Color(1.0, 1.0, 1.0, 0.45)
			if theme_icon != null:
				theme_icon.modulate = Color(1.0, 1.0, 1.0, 0.45)
			title_label.modulate = Color(1.0, 1.0, 1.0, 0.45)
		var action: Callable = Callable(self, "_show_clear_theme_popup").bind(i, with_main_navigation) if completed else Callable(self, "start_classic_game").bind(i)
		var theme_button := _stage_button(Rect2(x, y, 214.0, 88.0), action, "")
		theme_button.disabled = disabled
		_bind_theme_card_press_state(theme_button, card)

	var difficulty_rect: Rect2
	var difficulty_action: Callable
	var difficulty_font_size: int = _portrait_footer_font_size(22)
	if with_main_navigation:
		difficulty_rect = PORTRAIT_TASKS_DIFFICULTY_RECT
		difficulty_action = Callable(self, "_cycle_classic_difficulty").bind(true)
	else:
		difficulty_rect = _portrait_footer_long_button_rect(PORTRAIT_THEME_DIFFICULTY_BASE_RECT)
		difficulty_action = Callable(self, "_cycle_classic_difficulty")
	var difficulty_button := _stage_main_button(
		difficulty_rect,
		difficulty_action,
		_difficulty_mode_label(),
		difficulty_font_size
	)
	_style_difficulty_button(difficulty_button)

func _show_clear_theme_popup(theme_index: int, return_to_tasks: bool = false) -> void:
	_remove_clear_theme_popup()
	var previous_content := _portrait_popup_begin("ClearThemePopup", "clear_theme_popup", 125, Callable(self, "_remove_clear_theme_popup"), 250.0, 540.0)
	var rect := Rect2(35.0, 250.0, 410.0, 290.0)
	_portrait_popup_shell(rect, Database.tr_text(25, "Clear the category?"), Callable(self, "_remove_clear_theme_popup"), 25)
	var theme_name := Database.get_theme_name(theme_index).to_upper()
	var question_label := _stage_label(Rect2(65.0, 350.0, 350.0, 58.0), theme_name, 24, Color.WHITE)
	question_label.clip_text = false
	_stage_portrait_popup_main_button(Rect2(44.0, 454.0, PORTRAIT_SMALL_BUTTON_SIZE.x, PORTRAIT_SMALL_BUTTON_SIZE.y), Callable(self, "_confirm_clear_theme").bind(theme_index, return_to_tasks), Database.tr_text(26, "Yes"), 20)
	_stage_portrait_popup_main_button(Rect2(246.0, 454.0, PORTRAIT_SMALL_BUTTON_SIZE.x, PORTRAIT_SMALL_BUTTON_SIZE.y), Callable(self, "_remove_clear_theme_popup"), Database.tr_text(27, "No"), 20, false, 0.32, false, false, false, LONG_BUTTON_COLOR_ORANGE)
	content = previous_content
func _show_single_player_theme_popup(level_index: int, theme_index: int) -> void:
	_show_single_player_level_popup(level_index, theme_index)

func _show_single_player_level_popup(level_index: int, selected_theme: int = -1) -> void:
	_remove_single_player_theme_popup()
	level_index = _prepare_single_player_level_attempt(level_index)
	var options: Array = _single_player_level_theme_options(level_index)
	if options.is_empty():
		return
	var persisted_theme: int = GameState.get_single_level_selected_theme(
		Database.current_language,
		level_index
	)
	if persisted_theme >= 0:
		selected_theme = persisted_theme
	elif !options.has(selected_theme):
		selected_theme = int(options[0])
	single_player_active_level_index = level_index
	single_player_active_word_slot = -1
	single_player_popup_level_index = level_index
	single_player_popup_selected_theme = selected_theme
	var previous_content := _portrait_popup_begin(
		"SinglePlayerLevelPopup",
		"single_player_theme_popup",
		135,
		Callable(self, "_remove_single_player_theme_popup"),
		118.0,
		578.0
	)
	single_player_popup_stage_content = content
	var rect := Rect2(24.0, 118.0, 432.0, 460.0)
	var challenge_level: bool = _single_player_is_bonus_level(level_index)
	_portrait_popup_shell(
		rect,
		("%s %d" % [_single_player_level_label(), level_index + 1]).to_upper(),
		Callable(self, "_remove_single_player_theme_popup"),
		29,
		PORTRAIT_CHALLENGE_POPUP_HEADER if challenge_level else PORTRAIT_BLUE,
		PORTRAIT_CHALLENGE_POPUP_BODY if challenge_level else PORTRAIT_DARK_BLUE,
		PORTRAIT_CHALLENGE_POPUP_SEPARATOR if challenge_level else PORTRAIT_ORANGE,
		_single_player_challenge_level_label() if challenge_level else ""
	)
	var instruction_y: float = 210.0
	var instruction_label := _stage_label(
		Rect2(48.0, instruction_y, 384.0, 38.0),
		_single_player_choose_theme_label(),
		21,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	instruction_label.clip_text = false
	var refresh_base_rect := Rect2(370.0, instruction_y - 6.0, 48.0, 48.0)
	var refresh_button_rect := Rect2(
		refresh_base_rect.get_center() - refresh_base_rect.size * PORTRAIT_SINGLE_PLAYER_REFRESH_BUTTON_SCALE * 0.5,
		refresh_base_rect.size * PORTRAIT_SINGLE_PLAYER_REFRESH_BUTTON_SCALE
	)
	var refresh_button := _stage_round_icon_button(
		refresh_button_rect,
		Callable(self, "_refresh_single_player_theme_popup").bind(level_index),
		SINGLE_PLAYER_REFRESH_ICON,
		Vector2(27.0, 27.0) * PORTRAIT_SINGLE_PLAYER_REFRESH_BUTTON_SCALE,
		false
	)
	if challenge_level:
		refresh_button.call(
			"set_color_palette",
			DIFFICULTY_HARD_NORMAL_TINT,
			DIFFICULTY_HARD_PRESSED_TINT,
			DIFFICULTY_HARD_SELECTED_TINT
		)
	refresh_button.z_index = 15
	var price_badge := _stage_panel(
		Rect2(390.0, instruction_y + 26.0, 44.0, 22.0),
		PORTRAIT_CHALLENGE_POPUP_HEADER if challenge_level else PORTRAIT_DARK_BLUE,
		11.0,
		PORTRAIT_CHALLENGE_POPUP_SEPARATOR if challenge_level else PORTRAIT_RULE,
		1.0
	)
	price_badge.z_index = 16
	var price_coin := _stage_texture(
		Rect2(393.0, instruction_y + 29.0, 16.0, 16.0),
		SOFT_CURRENCY_COIN_TEXTURE
	)
	price_coin.z_index = 17
	single_player_popup_refresh_price_label = _stage_label(
		Rect2(408.0, instruction_y + 26.0, 24.0, 22.0),
		str(SINGLE_PLAYER_THEME_REFRESH_COST),
		13,
		_purchase_price_color(SINGLE_PLAYER_THEME_REFRESH_COST),
		HORIZONTAL_ALIGNMENT_CENTER
	)
	single_player_popup_refresh_price_label.add_theme_font_override("font", UI_PRIMARY_FONT)
	single_player_popup_refresh_price_label.z_index = 17
	var word_count: int = _single_player_level_word_count(level_index)
	var card_y: float = 270.0
	_stage_single_player_popup_theme_cards(
		level_index,
		options,
		card_y,
		word_count
	)

	single_player_popup_play_button = _stage_portrait_popup_main_button(
		Rect2(90.0, 500.0, 300.0, 56.0),
		Callable(self, "_start_single_player_popup_level").bind(level_index),
		_single_player_theme_start_label(),
		22,
		selected_theme < 0,
		0.32,
		false,
		false,
		true,
		LONG_BUTTON_COLOR_ORANGE
	)
	if selected_theme >= 0:
		_select_single_player_popup_theme(level_index, selected_theme)
	content = previous_content

func _stage_single_player_popup_theme_cards(
	level_index: int,
	options: Array,
	card_y: float,
	word_count: int
) -> void:
	_clear_single_player_popup_theme_cards()
	if single_player_popup_stage_content == null or !is_instance_valid(single_player_popup_stage_content):
		return
	var previous_content: Control = content
	content = single_player_popup_stage_content
	var first_card_node_index: int = content.get_child_count()
	var card_size := Vector2(128.0, 202.0)
	var challenge_level: bool = _single_player_is_bonus_level(level_index)
	var card_fill: Color = (
		PORTRAIT_CHALLENGE_THEME_CARD
		if challenge_level
		else Color(0.30, 0.35, 0.68, 1.0)
	)
	var card_border: Color = (
		PORTRAIT_CHALLENGE_POPUP_HEADER
		if challenge_level
		else PORTRAIT_RULE
	)
	for option_index in range(options.size()):
		var theme_index: int = int(options[option_index])
		var card_rect := Rect2(39.0 + float(option_index) * 137.0, card_y, card_size.x, card_size.y)
		var card := _stage_panel(
			card_rect,
			card_fill,
			18.0,
			card_border,
			2.0
		)
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		single_player_popup_theme_panels[theme_index] = card
		var theme_icon_texture: Texture2D = _theme_icon_texture(theme_index)
		if theme_icon_texture != null:
			var theme_icon_size := Vector2.ONE * PORTRAIT_SINGLE_PLAYER_THEME_CARD_ICON_SIZE
			var theme_icon_rect := Rect2(
				card_rect.position + Vector2(
					(card_rect.size.x - theme_icon_size.x) * 0.5,
					35.0
				),
				theme_icon_size
			)
			_stage_texture(theme_icon_rect, theme_icon_texture)
			var word_badge_size := Vector2(43.0, 25.0)
			var word_badge_rect := Rect2(
				theme_icon_rect.end - word_badge_size * Vector2(0.86, 0.82),
				word_badge_size
			)
			var word_badge := _stage_panel(
				word_badge_rect,
				PORTRAIT_ORANGE,
				word_badge_size.y * 0.5,
				Color.WHITE,
				1.5
			)
			word_badge.z_index = 13
			var word_badge_label := _stage_label(
				word_badge_rect,
				"x%d" % word_count,
				16,
				Color.WHITE,
				HORIZONTAL_ALIGNMENT_CENTER
			)
			word_badge_label.z_index = 14
			var badge_effect_color := Color(
				PORTRAIT_DARK_BLUE.r,
				PORTRAIT_DARK_BLUE.g,
				PORTRAIT_DARK_BLUE.b,
				0.55
			)
			word_badge_label.add_theme_color_override("font_outline_color", badge_effect_color)
			word_badge_label.add_theme_constant_override("outline_size", 1)
			word_badge_label.add_theme_color_override("font_shadow_color", badge_effect_color)
			word_badge_label.add_theme_constant_override("shadow_offset_x", 2)
			word_badge_label.add_theme_constant_override("shadow_offset_y", 2)
			word_badge_label.add_theme_constant_override("shadow_outline_size", 0)
		var theme_name: String = Database.get_theme_name(theme_index).to_upper()
		var theme_name_height: float = 56.0
		var theme_name_rect := Rect2(
			Vector2(
				card_rect.position.x + 6.0,
				card_rect.end.y - theme_name_height - 24.0
			),
			Vector2(card_rect.size.x - 12.0, theme_name_height)
		)
		var theme_label := _stage_label(
			theme_name_rect,
			theme_name,
			17 if theme_name.length() <= 15 else 16,
			Color.WHITE,
			HORIZONTAL_ALIGNMENT_CENTER
		)
		theme_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		theme_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		theme_label.clip_text = false
		var popup_theme_effect_color := Color(
			PORTRAIT_DARK_BLUE.r,
			PORTRAIT_DARK_BLUE.g,
			PORTRAIT_DARK_BLUE.b,
			0.55
		)
		theme_label.add_theme_color_override("font_outline_color", popup_theme_effect_color)
		theme_label.add_theme_constant_override("outline_size", 1)
		theme_label.add_theme_color_override("font_shadow_color", popup_theme_effect_color)
		theme_label.add_theme_constant_override("shadow_offset_x", 2)
		theme_label.add_theme_constant_override("shadow_offset_y", 2)
		theme_label.add_theme_constant_override("shadow_outline_size", 0)
		var theme_button := _stage_button(
			card_rect,
			Callable(self, "_select_single_player_popup_theme").bind(level_index, theme_index),
			""
		)
		theme_button.disabled = false
	for child_index in range(first_card_node_index, content.get_child_count()):
		single_player_popup_theme_card_nodes.append(content.get_child(child_index))
	content = previous_content

func _update_single_player_theme_popup(level_index: int) -> void:
	if level_index != single_player_popup_level_index:
		return
	var options: Array = _single_player_level_theme_options(level_index)
	if options.is_empty():
		return
	var selected_theme: int = int(options[0])
	single_player_popup_selected_theme = selected_theme
	_stage_single_player_popup_theme_cards(
		level_index,
		options,
		270.0,
		_single_player_level_word_count(level_index)
	)
	_select_single_player_popup_theme(level_index, selected_theme)
	_update_single_player_refresh_price(GameState.get_soft_currency())

func _purchase_price_color(price: int) -> Color:
	return (
		Color.WHITE
		if GameState.get_soft_currency() >= maxi(price, 0)
		else PORTRAIT_INSUFFICIENT_PRICE_COLOR
	)

func _update_single_player_refresh_price(balance: int) -> void:
	if (
		single_player_popup_refresh_price_label == null
		or !is_instance_valid(single_player_popup_refresh_price_label)
	):
		return
	var price_color: Color = (
		Color.WHITE
		if balance >= SINGLE_PLAYER_THEME_REFRESH_COST
		else PORTRAIT_INSUFFICIENT_PRICE_COLOR
	)
	single_player_popup_refresh_price_label.add_theme_color_override("font_color", price_color)

func _select_single_player_popup_theme(level_index: int, theme_index: int) -> void:
	if level_index != single_player_popup_level_index:
		return
	if !_single_player_level_theme_options(level_index).has(theme_index):
		return
	single_player_popup_selected_theme = theme_index
	var selection_color: Color = (
		DIFFICULTY_HARD_NORMAL_TINT
		if _single_player_is_bonus_level(level_index)
		else PORTRAIT_ORANGE
	)
	var challenge_level: bool = _single_player_is_bonus_level(level_index)
	var unselected_fill: Color = (
		PORTRAIT_CHALLENGE_THEME_CARD
		if challenge_level
		else Color(0.30, 0.35, 0.68, 1.0)
	)
	var selected_fill: Color = (
		PORTRAIT_CHALLENGE_THEME_CARD_SELECTED
		if challenge_level
		else Color(0.38, 0.43, 0.76, 1.0)
	)
	var unselected_border: Color = (
		PORTRAIT_CHALLENGE_POPUP_HEADER
		if challenge_level
		else PORTRAIT_RULE
	)
	for option_theme in single_player_popup_theme_panels.keys():
		var panel := single_player_popup_theme_panels.get(option_theme) as Control
		if panel == null or !is_instance_valid(panel):
			continue
		var is_selected: bool = int(option_theme) == theme_index
		panel.set("fill_color", selected_fill if is_selected else unselected_fill)
		panel.set("border_color", selection_color if is_selected else unselected_border)
		panel.set("border_width", 4.0 if is_selected else 2.0)
	if (
		single_player_popup_play_button != null
		and is_instance_valid(single_player_popup_play_button)
		and bool(single_player_popup_play_button.get("button_disabled"))
	):
		single_player_popup_play_button.set("button_disabled", false)

func _show_exit_game_popup() -> void:
	_remove_exit_game_popup()
	var previous_content := _portrait_popup_begin("ExitGamePopup", "exit_game_popup", 140, Callable(self, "_remove_exit_game_popup"), 306.0, 536.0)
	var rect := Rect2(60.0, 306.0, 360.0, 230.0)
	var header := _stage_panel(Rect2(rect.position, Vector2(rect.size.x, 80.0)), PORTRAIT_BLUE)
	header.mouse_filter = Control.MOUSE_FILTER_STOP
	var body := _stage_panel(Rect2(rect.position + Vector2(0.0, 80.0), Vector2(rect.size.x, 150.0)), PORTRAIT_DARK_BLUE)
	body.mouse_filter = Control.MOUSE_FILTER_STOP
	var separator := _stage_panel(Rect2(rect.position.x, rect.position.y + 79.0, rect.size.x, 2.0), PORTRAIT_ORANGE)
	separator.mouse_filter = Control.MOUSE_FILTER_STOP

	var title_label := _stage_heading_label(Rect2(82.0, 316.0, 316.0, 56.0), tr("EXIT_GAME_CONFIRM").to_upper(), 27, Color.WHITE)
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.clip_text = false
	var warning_label := _stage_label(Rect2(82.0, 398.0, 316.0, 40.0), _exit_game_warning_text(), 18, Color(0.92, 0.94, 1.0))
	warning_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	warning_label.clip_text = false
	_stage_portrait_popup_main_button(Rect2(82.0, 456.0, 145.0, 52.0), Callable(self, "_confirm_exit_game"), tr("YES"), 20)
	_stage_portrait_popup_main_button(Rect2(253.0, 456.0, 145.0, 52.0), Callable(self, "_remove_exit_game_popup"), tr("NO"), 20, false, 0.32, false, false, false, LONG_BUTTON_COLOR_ORANGE)
	var close_x: float = rect.position.x + (rect.size.x - PORTRAIT_POPUP_CLOSE_SIZE) * 0.5
	var close_y: float = rect.end.y + PORTRAIT_POPUP_CLOSE_GAP
	_stage_round_button(
		Rect2(close_x, close_y, PORTRAIT_POPUP_CLOSE_SIZE, PORTRAIT_POPUP_CLOSE_SIZE),
		Callable(self, "_remove_exit_game_popup"),
		"×"
	)
	content = previous_content

func show_custom_word() -> void:
	_clear()
	# Two-player words do not support comments, gameplay hints, or automatic
	# opening of edge letters. GameSession enforces that rule directly.
	custom_comment_text = ""
	if !_preserve_custom_word_on_next_show or custom_word_text.is_empty():
		_set_random_custom_word()
	_preserve_custom_word_on_next_show = false

	# Match the category screen: graph-paper background with a shared top
	# navigation row and no footer backdrop.
	_portrait_screen(0.0)
	_stage_portrait_page_header(
		Database.tr_text(37, "Input the word").to_upper(),
		Callable(self, "show_menu"),
		Callable(self, "_return_to_custom_word_from_coin_store")
	)

	# Attach both actions to the footer and apply the same 85% width treatment
	# as the Start Game button. This keeps their visual and touch sizes equal.
	var custom_word_bottom_content: Control = _portrait_begin_bottom_attached_group()
	custom_word_check_button = _stage_main_button(_portrait_footer_long_button_rect(PORTRAIT_CUSTOM_WORD_CHECK_RECT), Callable(self, "_check_custom_word_now"), Database.tr_text(60, "Check the word"), 22, false, 0.0)
	_stage_main_button(_portrait_footer_long_button_rect(PORTRAIT_CUSTOM_WORD_RANDOM_RECT), Callable(self, "_set_random_custom_word"), _custom_word_random_label(), 22)
	_portrait_end_adaptive_group(custom_word_bottom_content)

	# Keep the primary action bottom-attached without drawing a blue footer.
	custom_word_start_button = _stage_main_button(
		_portrait_footer_long_button_rect(PORTRAIT_FOOTER_CENTER_LONG_BUTTON_RECT),
		Callable(self, "start_custom_game"),
		_custom_word_start_label(),
		_portrait_footer_font_size(22),
		custom_word_text.is_empty(),
		0.32,
		false,
		false,
		!custom_word_text.is_empty(),
		LONG_BUTTON_COLOR_ORANGE
	)
	_stage_portrait_custom_word_field()

func _return_to_custom_word_from_coin_store() -> void:
	_preserve_custom_word_on_next_show = true
	show_custom_word()

func _stage_portrait_custom_word_field() -> void:
	var word_input := STAGE_WORD_INPUT_SCRIPT.new() as StageWordInput
	if word_input == null:
		push_error("Could not instantiate the custom-word input")
		return

	# Set authored geometry before entering the tree. The base control can then
	# complete _ready() with a real size instead of briefly initializing at 0×0.
	var custom_word_input_rect: Rect2 = PORTRAIT_CUSTOM_WORD_INPUT_RECT
	custom_word_input_rect.position.y = (
		PORTRAIT_STAGE_LAYOUT.expanded_stage_height(get_viewport_rect().size)
		- custom_word_input_rect.size.y
	) * 0.5
	word_input.stage_rect = custom_word_input_rect
	content.add_child(word_input)

	# Theme-dependent child controls are configured only after the component is
	# inside the scene tree. This also keeps an input failure from hiding the
	# already-created Check, Random and Start actions.
	word_input.configure(custom_word_text, 15, 34)
	word_input.avoid_virtual_keyboard = true
	_portrait_custom_word_input = word_input
	custom_word_input_visual = word_input
	custom_word_edit = word_input.get_line_edit()
	if custom_word_edit != null and !custom_word_edit.text_changed.is_connected(_on_custom_word_text_changed):
		custom_word_edit.text_changed.connect(_on_custom_word_text_changed)

func start_custom_game() -> void:
	# Two-player rounds always start without comments or hints.
	custom_comment_text = ""
	super.start_custom_game()

func _portrait_game_keyboard_metrics(viewport_size: Vector2) -> Dictionary:
	var alphabet := Database.get_alphabet()
	var columns: int = 6
	var keyboard_scale: float = PORTRAIT_STAGE_LAYOUT.adaptive_ui_scale(
		viewport_size,
		PORTRAIT_GAME_KEYBOARD_MAX_SCALE
	)
	var keyboard_step_x: float = 66.0 * keyboard_scale
	var keyboard_step_y: float = 48.0 * keyboard_scale
	var key_size := Vector2(50.0, 46.0) * keyboard_scale
	var marker_size := Vector2(44.0, 44.0) * keyboard_scale
	var keyboard_rows: int = int(ceil(float(alphabet.size()) / float(columns)))
	var keyboard_height: float = key_size.y + float(maxi(0, keyboard_rows - 1)) * keyboard_step_y
	var keyboard_start_y: float = PORTRAIT_FOOTER_Y - 24.0 - keyboard_height
	if GameState.current_mode == GameState.GameMode.TWO_PLAYER:
		keyboard_start_y += PORTRAIT_TWO_PLAYER_KEYBOARD_Y_OFFSET
	return {
		"columns": columns,
		"step_x": keyboard_step_x,
		"step_y": keyboard_step_y,
		"key_size": key_size,
		"marker_size": marker_size,
		"font_size": int(round(29.0 * keyboard_scale)),
		"start_y": keyboard_start_y,
		"word_rect": Rect2(22.0, keyboard_start_y - 120.0, 436.0, 64.0),
	}

func _refresh_game_screen() -> void:
	# Starting a round emits GameSession.changed before show_game_screen() clears
	# the previous page. Ignore that hidden rebuild; otherwise it consumes the
	# one-shot Back-button entrance before the gameplay page becomes visible.
	if !game_screen_visible:
		return
	if content == null:
		return
	if game_finished:
		show_result_screen(last_result_is_win, last_result_data)
		return
	_capture_hero_animation_phase()
	for child: Node in content.get_children():
		content.remove_child(child)
		child.queue_free()

	var viewport_size: Vector2 = get_viewport_rect().size
	var extra_stage_height: float = PORTRAIT_STAGE_LAYOUT.extra_stage_height(viewport_size)
	var upper_block_shift: float = extra_stage_height * 0.5
	_portrait_screen(0.0, -1.0, _portrait_game_header_color())
	_stage_portrait_game_header()
	_stage_portrait_lives_counter()

	# The hangman character should remain horizontally centered on the screen in
	# every gameplay mode.  Compensate for the imported symbol's empty origin so
	# the visible art, not the symbol pivot, sits in the middle.
	var hero_pivot := Vector2(PORTRAIT_STAGE_SIZE.x * 0.5, 222.0 + upper_block_shift)
	var hero_stage_position := Vector2(
		hero_pivot.x - PORTRAIT_TWO_PLAYER_HERO_VISUAL_CENTER_OFFSET_X,
		238.0 + upper_block_shift
	)
	var hero_root_content: Control = _portrait_begin_adaptive_group(
		hero_pivot,
		1.0,
		0.0
	)
	_portrait_game_adaptive_group = content
	_portrait_game_hero_stage_position = hero_stage_position
	hero_static_symbol = _stage_hero_symbol(_hero_type(), hero_stage_position, _hero_animation_time(), _hero_nested_display_time())
	if hero_static_symbol != null:
		hero_static_symbol.stage_scale_multiplier = PORTRAIT_HERO_SCALE_MULTIPLIER
	_configure_hero_static_animation()

	_portrait_end_adaptive_group(hero_root_content)

	var alphabet := Database.get_alphabet()
	var keyboard_metrics: Dictionary = _portrait_game_keyboard_metrics(viewport_size)
	var columns: int = int(keyboard_metrics["columns"])
	var keyboard_step_x: float = float(keyboard_metrics["step_x"])
	var keyboard_step_y: float = float(keyboard_metrics["step_y"])
	var key_size: Vector2 = keyboard_metrics["key_size"]
	var marker_size: Vector2 = keyboard_metrics["marker_size"]
	var keyboard_font_size: int = int(keyboard_metrics["font_size"])

	var keyboard_total_width: float = key_size.x + float(columns - 1) * keyboard_step_x
	var keyboard_start_x: float = (PORTRAIT_STAGE_SIZE.x - keyboard_total_width) * 0.5
	var keyboard_start_y: float = float(keyboard_metrics["start_y"])
	var game_word_rect: Rect2 = keyboard_metrics["word_rect"]

	var keyboard_root_content: Control = _portrait_begin_bottom_attached_group()
	_stage_portrait_game_word_display(game_word_rect, 34)

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
		var animate_state: bool = pending_letter_markers.has(letter) and (
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

	# Keep the confirmed round-exit action in the same compact top-left
	# navigation position used by the footerless selection screens.
	var back_button := _stage_round_icon_button(
		PORTRAIT_PAGE_BACK_BUTTON_RECT,
		Callable(self, "_show_exit_game_popup"),
		PORTRAIT_BACK_ARROW_ICON,
		PORTRAIT_PAGE_BACK_ICON_SIZE
	)
	if _portrait_game_is_challenge_level():
		back_button.call(
			"set_color_palette",
			DIFFICULTY_HARD_NORMAL_TINT,
			DIFFICULTY_HARD_PRESSED_TINT,
			DIFFICULTY_HARD_SELECTED_TINT
		)
	_animate_portrait_back_button_entrance(back_button, PORTRAIT_PAGE_BACK_BUTTON_RECT)
	if GameState.current_mode != GameState.GameMode.TWO_PLAYER:
		_stage_portrait_hint_buttons()
	pending_letter_markers.clear()
	pending_letter_marker_is_correct = false

func _stage_portrait_game_word_display(rect: Rect2, font_size: int = 34) -> void:
	_stage_portrait_word_slots(rect, font_size, false, false)

func _stage_portrait_result_word_display(
	rect: Rect2,
	continue_button: Control,
	continue_text: Control,
	animate_result: bool
) -> void:
	var reserved_width: float = PORTRAIT_RESULT_SEARCH_BUTTON_SIZE + PORTRAIT_RESULT_WORD_SEARCH_GAP
	# The result is a single shaped line, so the font controls glyph advances and
	# kerning. The search button is appended after the measured text without
	# participating in the answer's centering.
	var word_width: float = minf(
		rect.size.x,
		PORTRAIT_STAGE_SIZE.x - reserved_width * 2.0
	)
	var word_rect := Rect2(
		Vector2((PORTRAIT_STAGE_SIZE.x - word_width) * 0.5, rect.position.y),
		Vector2(word_width, rect.size.y - 10.0)
	)
	var word_text: String = "".join(GameSession.letters)
	var word_holder := _stage_holder(word_rect, Control.MOUSE_FILTER_IGNORE)
	word_holder.z_index = 20
	var word_label := RichTextLabel.new()
	word_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	word_label.focus_mode = Control.FOCUS_NONE
	word_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	word_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	word_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	word_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	word_label.scroll_active = false
	word_label.selection_enabled = false
	word_label.context_menu_enabled = false
	word_label.clip_contents = false
	word_label.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	word_label.add_theme_font_override("normal_font", UI_HEADING_FONT)
	word_label.add_theme_color_override("default_color", PORTRAIT_BLUE)
	word_holder.add_child(word_label)

	var result_font: Font = word_label.get_theme_font("normal_font")
	var result_font_size: int = 34
	var measured_word_width: float = result_font.get_string_size(
		word_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		result_font_size
	).x
	if measured_word_width > word_width:
		result_font_size = maxi(
			18,
			int(floor(float(result_font_size) * word_width / measured_word_width))
		)
		measured_word_width = result_font.get_string_size(
			word_text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			result_font_size
		).x
	word_label.add_theme_font_size_override("normal_font_size", result_font_size)

	var animated_letter_count: int = 0
	for letter: String in GameSession.letters:
		if letter != " " and letter != "-" and letter != "—":
			animated_letter_count += 1
	var speed_multiplier: float = clampf(
		float(animated_letter_count) / PORTRAIT_RESULT_LETTER_BOUNCE_REFERENCE_LENGTH,
		1.0,
		PORTRAIT_RESULT_LETTER_BOUNCE_MAX_SPEED_MULTIPLIER
	)
	var grow_duration: float = PORTRAIT_RESULT_LETTER_BOUNCE_GROW_DURATION / speed_multiplier
	var settle_duration: float = PORTRAIT_RESULT_LETTER_BOUNCE_SETTLE_DURATION / speed_multiplier
	var letter_gap: float = PORTRAIT_RESULT_LETTER_BOUNCE_GAP / speed_multiplier
	var animation_duration: float = 0.0
	if animate_result:
		var bounce_effect: RichTextEffect = RESULT_WORD_BOUNCE_EFFECT_SCRIPT.new() as RichTextEffect
		bounce_effect.call(
			"configure",
			word_text,
			grow_duration,
			settle_duration,
			letter_gap,
			result_font_size,
			PORTRAIT_WORD_LETTER_BOUNCE_PEAK_SCALE.x,
			PORTRAIT_RESULT_LETTER_BOUNCE_NEIGHBOR_STRENGTH,
			PORTRAIT_RESULT_LETTER_BOUNCE_NEIGHBOR_RADIUS
		)
		animation_duration = float(bounce_effect.call("animation_duration"))
		word_label.push_customfx(bounce_effect, {})
		word_label.add_text(word_text)
		word_label.pop()
	else:
		word_label.add_text(word_text)

	var word_bounds := Rect2(
		Vector2(
			(PORTRAIT_STAGE_SIZE.x - measured_word_width) * 0.5,
			word_rect.position.y
		),
		Vector2(measured_word_width, word_rect.size.y)
	)
	var search_x: float = word_bounds.end.x + PORTRAIT_RESULT_WORD_SEARCH_GAP
	# RichTextLabel centers the shaped line inside word_rect. Center the search
	# button on that same rect so its vertical alignment follows the text layout
	# automatically instead of relying on a device-specific optical offset.
	var search_y: float = word_rect.get_center().y - PORTRAIT_RESULT_SEARCH_BUTTON_SIZE * 0.5
	var search_button := _stage_round_icon_button(
		Rect2(
			search_x,
			search_y,
			PORTRAIT_RESULT_SEARCH_BUTTON_SIZE,
			PORTRAIT_RESULT_SEARCH_BUTTON_SIZE
		),
		Callable(self, "_open_word_search"),
		RESULT_SEARCH_ICON,
		PORTRAIT_RESULT_SEARCH_ICON_SIZE
	)
	search_button.z_index = 20
	search_button.set("press_scale_enabled", true)
	search_button.set("visual_scale", PORTRAIT_RESULT_SEARCH_REST_VISUAL_SCALE)
	search_button.visible = !animate_result
	if animate_result:
		call_deferred(
			"_play_portrait_result_word_bounce_sequence",
			animation_duration,
			search_button,
			continue_button,
			continue_text
		)

func _stage_portrait_word_slots(
	rect: Rect2,
	font_size: int,
	reveal_all: bool,
	collect_result_letters: bool
) -> Dictionary:
	var animated_letters: Array = []
	if GameSession.letters.is_empty():
		return {
			"bounds": Rect2(rect.position, Vector2.ZERO),
			"animated_letters": animated_letters,
			"font_size": font_size,
			"letter_center_y": rect.position.y + (rect.size.y - 10.0) * 0.5,
		}

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
			"revealed": reveal_all or bool(GameSession.revealed[i]),
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
			letter_label.add_theme_font_override("font", UI_HEADING_FONT)
			# Each revealed letter occupies an identical single-line slot. Disabling
			# wrapping and resetting the full-rect offsets after parenting prevents
			# wide glyphs from changing the label's line box and jumping vertically.
			letter_label.autowrap_mode = TextServer.AUTOWRAP_OFF
			letter_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
			letter_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			letter_label.vertical_alignment = (
				VERTICAL_ALIGNMENT_CENTER
				if collect_result_letters
				else VERTICAL_ALIGNMENT_BOTTOM
			)
			letter_label.clip_text = false
			var animate_reveal: bool = (
				!collect_result_letters
				and revealed
				and !is_dash
				and pending_letter_marker_is_correct
				and pending_letter_markers.has(letter)
			)
			if animate_reveal:
				_prepare_portrait_word_letter_bounce(letter_label)
			if collect_result_letters and !is_space and !is_dash:
				var letter_holder := letter_label.get_parent() as CanvasItem
				if letter_holder != null:
					letter_holder.z_index = 20
				animated_letters.append(letter_label)
		x += item_width
		if i < layout.size() - 1:
			x += slot_gap

	return {
		"bounds": Rect2(start_x, rect.position.y, total_width * scale, rect.size.y),
		"animated_letters": animated_letters,
		"font_size": effective_font_size,
		"letter_center_y": rect.position.y + (rect.size.y - 10.0) * 0.5,
	}

func _play_portrait_result_word_bounce_sequence(
	animation_duration: float,
	search_button: Control,
	continue_button: Control,
	continue_text: Control
) -> void:
	if animation_duration <= 0.0:
		_reveal_portrait_result_actions(search_button, continue_button, continue_text)
		return
	var sequence: Tween = create_tween()
	sequence.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	sequence.tween_interval(animation_duration)
	sequence.tween_callback(
		Callable(self, "_reveal_portrait_result_actions").bind(search_button, continue_button, continue_text)
	)

func _reveal_portrait_result_actions(search_button: Control, continue_button: Control, continue_text: Control) -> void:
	if search_button == null or !is_instance_valid(search_button) or !search_button.is_inside_tree():
		return
	search_button.visible = true
	search_button.modulate = Color(1.0, 1.0, 1.0, 0.0)
	search_button.set("visual_scale", PORTRAIT_RESULT_SEARCH_START_VISUAL_SCALE)
	if continue_button != null and is_instance_valid(continue_button) and continue_button.is_inside_tree():
		continue_button.visible = true
		continue_button.modulate = Color(1.0, 1.0, 1.0, 0.0)
	if continue_text != null and is_instance_valid(continue_text) and continue_text.is_inside_tree():
		continue_text.visible = true
		continue_text.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var reveal_tween: Tween = create_tween()
	reveal_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	reveal_tween.set_parallel(true)
	var fade_tweener: PropertyTweener = reveal_tween.tween_property(
		search_button,
		"modulate",
		Color.WHITE,
		PORTRAIT_RESULT_SEARCH_APPEAR_DURATION
	)
	fade_tweener.set_trans(Tween.TRANS_SINE)
	fade_tweener.set_ease(Tween.EASE_OUT)
	if continue_button != null and is_instance_valid(continue_button) and continue_button.is_inside_tree():
		var continue_fade_tweener: PropertyTweener = reveal_tween.tween_property(
			continue_button,
			"modulate",
			Color.WHITE,
			PORTRAIT_RESULT_SEARCH_APPEAR_DURATION
		)
		continue_fade_tweener.set_trans(Tween.TRANS_SINE)
		continue_fade_tweener.set_ease(Tween.EASE_OUT)
	if continue_text != null and is_instance_valid(continue_text) and continue_text.is_inside_tree():
		var continue_text_fade_tweener: PropertyTweener = reveal_tween.tween_property(
			continue_text,
			"modulate",
			Color.WHITE,
			PORTRAIT_RESULT_SEARCH_APPEAR_DURATION
		)
		continue_text_fade_tweener.set_trans(Tween.TRANS_SINE)
		continue_text_fade_tweener.set_ease(Tween.EASE_OUT)
	var scale_tweener: PropertyTweener = reveal_tween.tween_property(
		search_button,
		"visual_scale",
		PORTRAIT_RESULT_SEARCH_REST_VISUAL_SCALE,
		PORTRAIT_RESULT_SEARCH_APPEAR_DURATION
	)
	scale_tweener.set_trans(Tween.TRANS_BACK)
	scale_tweener.set_ease(Tween.EASE_OUT)

func _prepare_portrait_word_letter_bounce(letter_label: Label) -> void:
	# Every occurrence of the newly revealed letter gets its own tween, so words
	# with repeated letters animate all matching slots at the same time.
	letter_label.pivot_offset = letter_label.size * 0.5
	letter_label.scale = PORTRAIT_WORD_LETTER_BOUNCE_START_SCALE
	call_deferred("_play_portrait_word_letter_bounce", letter_label)

func _play_portrait_word_letter_bounce(letter_label: Label) -> void:
	if letter_label == null or !is_instance_valid(letter_label) or !letter_label.is_inside_tree():
		return
	letter_label.pivot_offset = letter_label.size * 0.5
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var grow_tweener: PropertyTweener = tween.tween_property(
		letter_label,
		"scale",
		PORTRAIT_WORD_LETTER_BOUNCE_PEAK_SCALE,
		PORTRAIT_WORD_LETTER_BOUNCE_GROW_DURATION
	)
	grow_tweener.set_trans(Tween.TRANS_QUAD)
	grow_tweener.set_ease(Tween.EASE_OUT)
	var settle_tweener: PropertyTweener = tween.tween_property(
		letter_label,
		"scale",
		Vector2.ONE,
		PORTRAIT_WORD_LETTER_BOUNCE_SETTLE_DURATION
	)
	settle_tweener.set_trans(Tween.TRANS_BACK)
	settle_tweener.set_ease(Tween.EASE_OUT)

func _stage_portrait_hint_buttons() -> void:
	var open_hint_used: bool = GameSession.open_hint_used
	var remove_hint_used: bool = GameSession.remove_wrong_hint_used
	var comment_unlocked: bool = GameSession.comment_hint_unlocked
	var open_hint_disabled: bool = open_hint_used or !GameSession.can_use_open_letter_hint()
	var remove_hint_disabled: bool = remove_hint_used or !GameSession.can_use_remove_wrong_hint()
	var comment_disabled: bool = !comment_unlocked and !GameSession.can_unlock_comment_hint()

	var open_rect: Rect2 = PORTRAIT_GAME_HINT_OPEN_BUTTON_RECT
	var remove_rect: Rect2 = PORTRAIT_GAME_HINT_REMOVE_BUTTON_RECT
	var comment_rect: Rect2 = PORTRAIT_GAME_HINT_COMMENT_BUTTON_RECT

	# The authored long-button component remains the clickable base. The larger
	# doodle artwork is staged separately so it can rise above the button, like a
	# physical hint item resting on the top edge.
	var open_button := _stage_main_button(
		open_rect,
		Callable(self, "_use_open_hint"),
		"",
		14,
		open_hint_disabled,
		0.0,
		false,
		false,
		false,
		LONG_BUTTON_COLOR_ORANGE
	)
	var remove_button := _stage_main_button(
		remove_rect,
		Callable(self, "_use_remove_hint"),
		"",
		14,
		remove_hint_disabled,
		0.0,
		false,
		false,
		false,
		LONG_BUTTON_COLOR_ORANGE
	)
	var comment_button := _stage_main_button(
		comment_rect,
		Callable(self, "_use_comment_hint"),
		"",
		13,
		comment_disabled,
		0.0,
		false,
		false,
		false,
		LONG_BUTTON_COLOR_BLUE if comment_unlocked else LONG_BUTTON_COLOR_ORANGE
	)

	_stage_portrait_hint_art(open_button, PORTRAIT_HINT_REVEAL_LETTER_ICON, open_hint_used)
	_stage_portrait_hint_art(remove_button, PORTRAIT_HINT_REMOVE_WRONG_ICON, remove_hint_used)
	_stage_portrait_hint_art(comment_button, PORTRAIT_HINT_COMMENT_UNLOCK_ICON)

	# Prices and inventory badges only describe actions that still consume a hint.
	# Used one-shot hints use the shared gray disabled state without a stale badge;
	# the unlocked comment remains a regular free blue action.
	if !open_hint_used:
		_stage_portrait_hint_counter(open_rect, GameState.HINT_OPEN_LETTER)
	if !remove_hint_used:
		_stage_portrait_hint_counter(remove_rect, GameState.HINT_REMOVE_WRONG)
	if !comment_unlocked:
		_stage_portrait_hint_counter(comment_rect, GameState.HINT_COMMENT)

func _stage_portrait_hint_art(button: Control, texture: Texture2D, grayscale: bool = false) -> void:
	if button == null:
		return
	var art := TextureRect.new()
	art.name = "HintArt"
	art.texture = texture
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.set_anchors_preset(Control.PRESET_TOP_LEFT)
	art.size = PORTRAIT_GAME_HINT_ART_SIZE
	art.custom_minimum_size = PORTRAIT_GAME_HINT_ART_SIZE
	art.position = Vector2(
		(button.size.x - PORTRAIT_GAME_HINT_ART_SIZE.x) * 0.5,
		-PORTRAIT_GAME_HINT_ART_RISE
	)
	if grayscale:
		var grayscale_material := ShaderMaterial.new()
		grayscale_material.shader = PORTRAIT_HINT_USED_GRAYSCALE_SHADER
		art.material = grayscale_material
	art.z_index = 4
	button.add_child(art)

func _stage_portrait_hint_counter(button_rect: Rect2, hint_key: String) -> void:
	var count: int = GameState.get_hint_count(hint_key)
	if count <= 0:
		_stage_portrait_hint_price(button_rect, GameState.get_hint_cost(hint_key))
		return
	var badge_size := Vector2(PORTRAIT_GAME_HINT_COUNTER_SIZE, PORTRAIT_GAME_HINT_COUNTER_SIZE)
	var badge_rect := Rect2(
		Vector2(
			button_rect.end.x - badge_size.x * 0.72,
			button_rect.end.y - badge_size.y * 0.82
		),
		badge_size
	)
	_stage_panel(badge_rect, PORTRAIT_DARK_BLUE, badge_size.x * 0.5)
	var counter_label := _stage_label(
		badge_rect,
		str(maxi(count, 0)),
		17,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	var counter_effect_color := Color(
		PORTRAIT_DARK_BLUE.r,
		PORTRAIT_DARK_BLUE.g,
		PORTRAIT_DARK_BLUE.b,
		0.55
	)
	counter_label.add_theme_color_override("font_outline_color", counter_effect_color)
	counter_label.add_theme_constant_override("outline_size", 1)
	counter_label.add_theme_color_override("font_shadow_color", counter_effect_color)
	counter_label.add_theme_constant_override("shadow_offset_x", 2)
	counter_label.add_theme_constant_override("shadow_offset_y", 2)
	counter_label.add_theme_constant_override("shadow_outline_size", 0)

func _stage_portrait_hint_price(button_rect: Rect2, price: int) -> void:
	var badge_size := Vector2(58.0, PORTRAIT_GAME_HINT_COUNTER_SIZE)
	var badge_rect := Rect2(
		Vector2(
			button_rect.end.x - badge_size.x * 0.88,
			button_rect.end.y - badge_size.y * 0.82
		),
		badge_size
	)
	var badge := _stage_panel(
		badge_rect,
		PORTRAIT_DARK_BLUE,
		badge_size.y * 0.5,
		Color(0.72, 0.77, 0.91, 1.0),
		1.5
	)
	badge.z_index = 8
	var mini_coin_rect := Rect2(
		badge_rect.position + Vector2(2.0, 2.0),
		Vector2(24.0, 24.0)
	)
	var coin_icon := _stage_texture(mini_coin_rect, SOFT_CURRENCY_COIN_TEXTURE)
	coin_icon.z_index = 9
	var price_label := _stage_label(
		Rect2(
			Vector2(badge_rect.position.x + 25.0, badge_rect.position.y),
			Vector2(badge_rect.size.x - 27.0, badge_rect.size.y)
		),
		str(maxi(price, 0)),
		16,
		_purchase_price_color(price),
		HORIZONTAL_ALIGNMENT_CENTER
	)
	price_label.add_theme_font_override("font", UI_PRIMARY_FONT)
	price_label.z_index = 9

func _stage_portrait_lives_counter() -> void:
	var counter_rect: Rect2 = PORTRAIT_LIVES_COUNTER_RECT
	var counter_scale: float = counter_rect.size.y / 48.0
	var challenge_colors: bool = _portrait_game_is_challenge_level()
	var panel_color: Color = PORTRAIT_CHALLENGE_HUD_PANEL if challenge_colors else PORTRAIT_DARK_BLUE
	var border_color: Color = PORTRAIT_CHALLENGE_HUD_BORDER if challenge_colors else Color(0.72, 0.77, 0.91, 1.0)
	var counter_panel := _stage_panel(
		counter_rect,
		panel_color,
		counter_rect.size.y * 0.5,
		border_color,
		2.0 * counter_scale
	)
	counter_panel.z_index = 20
	var heart_rect := Rect2(
		counter_rect.position + Vector2(
			2.0 * counter_scale,
			(counter_rect.size.y - PORTRAIT_LIVES_ICON_SIZE) * 0.5
		),
		Vector2(PORTRAIT_LIVES_ICON_SIZE, PORTRAIT_LIVES_ICON_SIZE)
	)
	var heart_icon: Control = _stage_texture(heart_rect, LIFE_HEART_ICON_TEXTURE)
	heart_icon.z_index = 21
	if GameSession.is_active and GameSession.get_remaining_attempts() == 1:
		_start_portrait_last_life_heart_bounce(heart_icon)

	var label_rect := Rect2(
		Vector2(counter_rect.position.x + 43.0 * counter_scale, counter_rect.position.y),
		Vector2(counter_rect.size.x - 49.0 * counter_scale, counter_rect.size.y)
	)
	var lives_label := _stage_label(
		label_rect,
		str(GameSession.get_remaining_attempts()),
		maxi(1, int(round(24.0 * counter_scale))),
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	lives_label.add_theme_font_override("font", UI_HEADING_FONT)
	lives_label.z_index = 21
	lives_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _start_portrait_last_life_heart_bounce(heart_icon: Control) -> void:
	if heart_icon == null or !is_instance_valid(heart_icon):
		return
	var resting_scale: Vector2 = heart_icon.scale
	var center_pivot: Vector2 = heart_icon.size * 0.5
	# FlashStageTexture already carries the viewport fit scale. Changing its pivot
	# after that scale has been applied would move the rendered icon immediately.
	# Offset the local position first so the current visual bounds stay unchanged,
	# then all tweened scale changes happen around the same visible center.
	heart_icon.position += (resting_scale - Vector2.ONE) * center_pivot
	heart_icon.pivot_offset = center_pivot
	var bounce_tween: Tween = heart_icon.create_tween()
	bounce_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	bounce_tween.set_loops()

	var first_up: PropertyTweener = bounce_tween.tween_property(
		heart_icon,
		"scale",
		resting_scale * PORTRAIT_LAST_LIFE_FIRST_BOUNCE_SCALE,
		PORTRAIT_LAST_LIFE_BOUNCE_UP_DURATION
	)
	first_up.set_trans(Tween.TRANS_BACK)
	first_up.set_ease(Tween.EASE_OUT)

	var first_down: PropertyTweener = bounce_tween.tween_property(
		heart_icon,
		"scale",
		resting_scale,
		PORTRAIT_LAST_LIFE_BOUNCE_DOWN_DURATION
	)
	first_down.set_trans(Tween.TRANS_SINE)
	first_down.set_ease(Tween.EASE_IN_OUT)
	bounce_tween.tween_interval(PORTRAIT_LAST_LIFE_BETWEEN_BOUNCES)

	var second_up: PropertyTweener = bounce_tween.tween_property(
		heart_icon,
		"scale",
		resting_scale * PORTRAIT_LAST_LIFE_SECOND_BOUNCE_SCALE,
		PORTRAIT_LAST_LIFE_BOUNCE_UP_DURATION
	)
	second_up.set_trans(Tween.TRANS_BACK)
	second_up.set_ease(Tween.EASE_OUT)

	var second_down: PropertyTweener = bounce_tween.tween_property(
		heart_icon,
		"scale",
		resting_scale,
		PORTRAIT_LAST_LIFE_BOUNCE_DOWN_DURATION
	)
	second_down.set_trans(Tween.TRANS_SINE)
	second_down.set_ease(Tween.EASE_IN_OUT)
	bounce_tween.tween_interval(PORTRAIT_LAST_LIFE_LOOP_PAUSE)

func _create_hero_animation_overlay() -> FlashStageSymbol:
	var overlay := FlashStageSymbol.new()
	overlay.name = "HeroAnimationOverlay"
	overlay.z_index = 150
	overlay.hero_type = _hero_type()
	overlay.stage_position = _portrait_game_hero_stage_position
	overlay.stage_scale_multiplier = PORTRAIT_HERO_SCALE_MULTIPLIER
	overlay.animation_time = _hero_animation_time()
	if _portrait_game_adaptive_group != null and is_instance_valid(_portrait_game_adaptive_group):
		_portrait_game_adaptive_group.add_child(overlay)
	else:
		add_child(overlay)
	return overlay

func _portrait_result_title_color(is_win: bool) -> Color:
	return StageLetterButton.CIRCLED_COLOR if is_win else StageLetterButton.CROSSED_COLOR

func _stage_single_player_result_chain_progress(data: Dictionary, is_win: bool) -> void:
	if GameState.current_mode != GameState.GameMode.SINGLE_PLAYER:
		return
	var total_count: int = maxi(int(data.get("single_player_total_count", 0)), 0)
	var current_slot: int = clampi(int(data.get("single_player_word_slot", 0)), 0, maxi(total_count - 1, 0))
	if total_count <= 0:
		return

	var card := _stage_panel(
		PORTRAIT_RESULT_CHAIN_CARD_RECT,
		PORTRAIT_BLUE,
		13.0,
		PORTRAIT_ORANGE,
		2.0
	)
	card.z_index = 20
	var progress_text: String = _single_player_text(
		"СЛОВО %d ИЗ %d",
		"WORD %d OF %d"
	) % [current_slot + 1, total_count]
	var progress_label := _stage_label(
		Rect2(93.0, 649.0, 294.0, 22.0),
		progress_text,
		16,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	progress_label.clip_text = false
	var progress_holder := progress_label.get_parent() as CanvasItem
	if progress_holder != null:
		progress_holder.z_index = 21

	var track_rect := Rect2(105.0, 676.0, 270.0, 7.0)
	var gap: float = 4.0
	var segment_width: float = (track_rect.size.x - gap * float(total_count - 1)) / float(total_count)
	for segment_index in range(total_count):
		var segment_color := Color(0.36, 0.41, 0.72, 1.0)
		if segment_index < current_slot:
			segment_color = PORTRAIT_ORANGE
		elif segment_index == current_slot:
			segment_color = StageLetterButton.CIRCLED_COLOR if is_win else StageLetterButton.CROSSED_COLOR
		var segment := _stage_panel(
			Rect2(
				track_rect.position + Vector2(float(segment_index) * (segment_width + gap), 0.0),
				Vector2(segment_width, track_rect.size.y)
			),
			segment_color,
			4.0
		)
		segment.z_index = 21

func show_result_screen(is_win: bool, data: Dictionary = {}) -> void:
	_show_portrait_result_screen(is_win, data, true)

func _return_to_result_from_coin_store() -> void:
	_show_portrait_result_screen(last_result_is_win, last_result_data, false)

func _show_portrait_result_screen(is_win: bool, data: Dictionary, animate_result: bool) -> void:
	_play_result_sound_once(is_win, data)
	_portrait_game_adaptive_group = null
	_clear()
	_portrait_screen(0.0)
	_stage_currency_counter(Callable(self, "_return_to_result_from_coin_store"))
	var close_button := _stage_round_icon_button(
		PORTRAIT_PAGE_BACK_BUTTON_RECT,
		Callable(self, "_result_back_action"),
		RESULT_CLOSE_ICON,
		Vector2(23.0, 23.0)
	)
	close_button.z_index = 20

	var result_controls: Dictionary = _show_result_content(is_win, data, animate_result)
	var continue_button: Control = result_controls.get("continue_button") as Control
	var continue_text: Control = result_controls.get("continue_text") as Control
	var word_content: Control = _portrait_begin_bottom_attached_group()
	_stage_portrait_result_word_display(
		PORTRAIT_RESULT_WORD_RECT,
		continue_button,
		continue_text,
		animate_result
	)
	_stage_single_player_result_chain_progress(data, is_win)
	_portrait_end_adaptive_group(word_content)

func _stage_portrait_result_mode_theme_label(rect: Rect2, animate_result: bool) -> Label:
	var header_texts: Dictionary = _portrait_game_header_texts()
	var mode_theme_text: String = str(header_texts["title"])
	var theme_text: String = str(header_texts["subtitle"])
	if !theme_text.is_empty():
		mode_theme_text += " • " + theme_text
	var mode_theme_label := _stage_label(
		rect,
		mode_theme_text,
		22,
		PORTRAIT_BLUE,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	mode_theme_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	mode_theme_label.clip_text = false
	var mode_theme_holder := mode_theme_label.get_parent() as CanvasItem
	if mode_theme_holder != null:
		mode_theme_holder.z_index = 20
	_fit_single_line_label_to_width(mode_theme_label, mode_theme_text, rect.size.x, 22, 15)
	mode_theme_label.visible = !animate_result
	return mode_theme_label

func _show_result_content(is_win: bool, data: Dictionary, animate_result: bool) -> Dictionary:
	var result_root_content: Control = _portrait_begin_adaptive_group(Vector2(240.0, 390.0), 1.15, 0.08)
	var title: String = Database.tr_text(33 if is_win else 34, "VICTORY" if is_win else "DEFEAT").strip_edges()
	if title == "":
		title = "VICTORY" if is_win else "DEFEAT"
	var title_label := _stage_heading_label(Rect2(40.0, 142.0, 400.0, 54.0), title, 38, _portrait_result_title_color(is_win))
	title_label.clip_text = false
	var title_holder := title_label.get_parent() as CanvasItem
	if title_holder != null:
		title_holder.z_index = 20
	_apply_result_text_glow(title_label, Color.WHITE, 2)

	var subtitle: String = _result_message(is_win, data)
	var subtitle_label := _stage_label(Rect2(52.0, 196.0, 376.0, 44.0), subtitle, 21, PORTRAIT_BLUE)
	subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle_label.clip_text = false
	var subtitle_holder := subtitle_label.get_parent() as CanvasItem
	if subtitle_holder != null:
		subtitle_holder.z_index = 20
	var mode_theme_label: Label = null
	if GameState.current_mode == GameState.GameMode.SINGLE_PLAYER:
		mode_theme_label = _stage_portrait_result_mode_theme_label(
			Rect2(28.0, 250.0, 424.0, 36.0),
			animate_result
		)

	hero_static_symbol = _stage_hero_symbol(_hero_type(), PORTRAIT_HERO_RESULT_POSITION, _hero_animation_time(), _hero_nested_display_time())
	if hero_static_symbol != null:
		hero_static_symbol.stage_scale_multiplier = PORTRAIT_HERO_SCALE_MULTIPLIER
	_configure_hero_static_animation()
	_portrait_end_adaptive_group(result_root_content)

	var bottom_content: Control = _portrait_begin_bottom_attached_group()
	if mode_theme_label == null:
		mode_theme_label = _stage_portrait_result_mode_theme_label(
			Rect2(28.0, 660.0, 424.0, 42.0),
			animate_result
		)
	var continue_button := _stage_main_button(
		_portrait_footer_long_button_rect(PORTRAIT_RESULT_CONTINUE_BUTTON_RECT),
		_result_continue_action(),
		_result_continue_button_text(),
		_portrait_footer_font_size(22),
		false,
		0.32,
		false,
		false,
		true,
		LONG_BUTTON_COLOR_ORANGE
	)
	if GameState.current_mode == GameState.GameMode.SINGLE_PLAYER:
		_style_single_player_level_button(
			continue_button,
			int(data.get("single_player_level_index", single_player_active_level_index))
		)
	continue_button.z_index = 20
	continue_button.visible = !animate_result
	_portrait_end_adaptive_group(bottom_content)
	return {
		"continue_button": continue_button,
		"continue_text": mode_theme_label,
	}

func _fit_single_line_label_to_width(label: Label, text: String, available_width: float, max_font_size: int, min_font_size: int) -> void:
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	var font: Font = label.get_theme_font("font")
	var resolved_font_size: int = maxi(max_font_size, min_font_size)
	while resolved_font_size > min_font_size:
		var text_width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, resolved_font_size).x
		if text_width <= available_width:
			break
		resolved_font_size -= 1
	label.add_theme_font_size_override("font_size", resolved_font_size)

func show_profile() -> void:
	_show_main_tab_screen(Callable(self, "_show_profile_screen"), MainTab.PROFILE)

func _show_profile_screen() -> void:
	coin_store_return_action = Callable()
	_clear()
	_portrait_screen(0.0, PORTRAIT_MAIN_NAV_Y)
	_stage_currency_counter(Callable(self, "show_profile"))
	_stage_portrait_page_title(_portrait_main_tab_label(MainTab.PROFILE))

	var profile_root_content: Control = _portrait_begin_adaptive_group(Vector2(240.0, 430.0), PORTRAIT_PROFILE_MAX_SCALE, 0.08)
	_stage_profile_header_card()
	_stage_label(Rect2(26.0, 310.0, 428.0, 40.0), _profile_text("СТАТИСТИКА", "STATISTICS"), 27, PORTRAIT_BLUE, HORIZONTAL_ALIGNMENT_LEFT)
	_portrait_profile_stat_row(392.0, tr("MENU_CLASSIC"), tr("RECORD_EASY_STREAK"), int(GameState.records[0][2]), tr("RECORD_HARD_STREAK"), int(GameState.records[0][3]))
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

func _portrait_profile_stat_row(y: float, mode_text: String, left_text: String, left_value: int, right_text: String, right_value: int) -> void:
	_stage_panel(Rect2(24.0, y, 432.0, 102.0), PORTRAIT_DARK_BLUE, 18.0, PORTRAIT_RULE, 1.5)
	_stage_label(Rect2(42.0, y + 8.0, 396.0, 30.0), mode_text.to_upper(), 21, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_panel(Rect2(42.0, y + 41.0, 396.0, 1.5), PORTRAIT_RULE)
	_stage_label(Rect2(42.0, y + 48.0, 180.0, 24.0), left_text, 16, Color(0.80, 0.83, 1.0, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
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

	_stage_portrait_popup_main_button(Rect2(90.0, 592.0, PORTRAIT_LONG_BUTTON_SIZE.x, PORTRAIT_LONG_BUTTON_SIZE.y), Callable(self, "_save_profile_edits"), _profile_text("Сохранить", "Save"), 20)
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
	return russian_text if GameState.interface_language == "ru" else english_text

func _show_word_comment_popup() -> void:
	if !GameSession.can_view_comment_hint():
		return
	var hint: String = GameSession.get_word_hint().strip_edges()
	if hint == "":
		return
	_remove_word_comment_popup()
	var previous_content := _portrait_popup_begin("WordCommentPopup", "word_comment_popup", 100, Callable(self, "_remove_word_comment_popup"), 160.0, 612.0)
	var rect := Rect2(28.0, 160.0, 424.0, 452.0)
	_portrait_popup_shell(rect, Database.tr_text(41, "Comment").to_upper(), Callable(self, "_remove_word_comment_popup"), 30)
	var hint_label := _stage_label(Rect2(56.0, 270.0, 368.0, 220.0), hint, 25, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	hint_label.add_theme_font_override("font", UI_HEADING_FONT)
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	hint_label.clip_text = false
	_stage_panel(Rect2(56.0, 506.0, 368.0, 2.0), Color(0.4509, 0.4862, 0.7607, 0.75))
	var theme_text: String = _current_word_source_label()
	var theme_label := _stage_label(Rect2(56.0, 526.0, 368.0, 60.0), theme_text, 22, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
	theme_label.clip_text = false
	_fit_single_line_label_to_width(theme_label, theme_text, 368.0, 22, 17)
	content = previous_content
