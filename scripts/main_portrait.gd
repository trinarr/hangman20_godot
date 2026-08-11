extends "res://scripts/main.gd"

const PORTRAIT_ADAPTIVE_GROUP_SCRIPT: GDScript = preload("res://scripts/ui/portrait_adaptive_group.gd")
const PORTRAIT_STAGE_LAYOUT: GDScript = preload("res://scripts/ui/portrait_stage_layout.gd")
const STAGE_WORD_INPUT_SCRIPT: GDScript = preload("res://scripts/ui/stage_word_input.gd")
const STAGE_STATUS_ICON_SCRIPT: GDScript = preload("res://scripts/ui/stage_status_icon.gd")
const SOFT_CURRENCY_COIN_PILE_ICON_SCRIPT: GDScript = preload("res://scripts/ui/soft_currency_coin_pile_icon.gd")
const RESULT_WORD_BOUNCE_EFFECT_SCRIPT: GDScript = preload("res://scripts/ui/result_word_bounce_effect.gd")

const PORTRAIT_STAGE_SIZE := Vector2(480.0, 800.0)
const PORTRAIT_HEADER_HEIGHT: float = 80.0
const PORTRAIT_FOOTER_Y: float = 688.0
const PORTRAIT_ADMOB_BANNER_HEIGHT: float = 50.0
const PORTRAIT_ADMOB_BANNER_SIZE := Vector2(320.0, PORTRAIT_ADMOB_BANNER_HEIGHT)
const PORTRAIT_ADMOB_BANNER_RECT := Rect2(
	(PORTRAIT_STAGE_SIZE.x - PORTRAIT_ADMOB_BANNER_SIZE.x) * 0.5,
	PORTRAIT_STAGE_SIZE.y - PORTRAIT_ADMOB_BANNER_HEIGHT,
	PORTRAIT_ADMOB_BANNER_SIZE.x,
	PORTRAIT_ADMOB_BANNER_SIZE.y
)
const PORTRAIT_GAME_KEYBOARD_BOTTOM_RESERVE: float = PORTRAIT_ADMOB_BANNER_HEIGHT
const PORTRAIT_GAME_INPUT_BLOCK_DOWN_SHIFT: float = 24.0
const PORTRAIT_LONG_BUTTON_SIZE := Vector2(300.0, 64.0)
const PORTRAIT_ROUND_BUTTON_SIZE: float = PORTRAIT_LONG_BUTTON_SIZE.y
const PORTRAIT_PAGE_BACK_BUTTON_SCALE: float = 0.80
const PORTRAIT_PAGE_BACK_BUTTON_SIZE: float = PORTRAIT_ROUND_BUTTON_SIZE * PORTRAIT_PAGE_BACK_BUTTON_SCALE
const PORTRAIT_PAGE_BACK_BUTTON_RECT := Rect2(18.4, 15.4, PORTRAIT_PAGE_BACK_BUTTON_SIZE, PORTRAIT_PAGE_BACK_BUTTON_SIZE)
const PORTRAIT_PAGE_BACK_ICON_SIZE := Vector2(21.6, 26.4)
const PORTRAIT_MENU_SETTINGS_BUTTON_RECT := Rect2(410.4, 15.4, PORTRAIT_PAGE_BACK_BUTTON_SIZE, PORTRAIT_PAGE_BACK_BUTTON_SIZE)
const PORTRAIT_MENU_SETTINGS_ICON_SIZE := Vector2(29.0, 29.0)
const PORTRAIT_BACK_ENTRANCE_GAP: float = 24.0
const PORTRAIT_BACK_ENTRANCE_DURATION: float = 0.24
const PORTRAIT_PAGE_TITLE_RECT := Rect2(40.0, 104.0, 400.0, 42.0)
# Compact text-only gameplay HUD placed in the free space to the right of the
# left-aligned character. The old white attempts/theme pills are intentionally
# removed; these labels are the only in-round status presentation now.
const PORTRAIT_GAME_INFO_X: float = 242.0
const PORTRAIT_GAME_INFO_WIDTH: float = 192.0
# Keep the complete text HUD above the word-paper band. On tall screens this
# block follows half of the extra-height shift together with the hero, while the
# bottom-attached paper moves by the full extra height, so the two can never
# collide as the aspect ratio grows. The labels are center-aligned and packed
# into the open area to the right of the hero.
const PORTRAIT_GAME_INFO_ATTEMPTS_TITLE_RECT := Rect2(PORTRAIT_GAME_INFO_X, 48.0, PORTRAIT_GAME_INFO_WIDTH, 24.0)
const PORTRAIT_GAME_INFO_ATTEMPTS_VALUE_RECT := Rect2(PORTRAIT_GAME_INFO_X, 66.0, PORTRAIT_GAME_INFO_WIDTH, 48.0)
const PORTRAIT_GAME_INFO_THEME_TITLE_RECT := Rect2(PORTRAIT_GAME_INFO_X, 134.0, PORTRAIT_GAME_INFO_WIDTH, 22.0)
const PORTRAIT_GAME_INFO_THEME_LINE_RECT := Rect2(PORTRAIT_GAME_INFO_X, 150.0, PORTRAIT_GAME_INFO_WIDTH, 44.0)
const PORTRAIT_GAME_INFO_TITLE_FONT_SIZE: int = 18
const PORTRAIT_GAME_INFO_ATTEMPTS_FONT_SIZE: int = 44
const PORTRAIT_GAME_INFO_THEME_LINE_FONT_SIZE: int = 34
# Coins and hearts form one centered resource block on every screen.
const PORTRAIT_RESOURCE_COUNTER_GAP: float = 28.0
const PORTRAIT_CURRENCY_COUNTER_RECT := Rect2(116.06, 21.68, 109.94, 38.64)
const PORTRAIT_GAME_CURRENCY_COUNTER_RECT := PORTRAIT_CURRENCY_COUNTER_RECT
const PORTRAIT_CURRENCY_ICON_SIZE: float = 35.42
const PORTRAIT_HEART_ICON_ASPECT_RATIO: float = 84.0 / 76.0
const PORTRAIT_HEART_ICON_LEFT_INSET: float = 2.0
const PORTRAIT_CURRENCY_COUNTER_PRESSED_SCALE: float = 0.94
const PORTRAIT_CURRENCY_COUNTER_PRESS_DURATION: float = 0.055
const PORTRAIT_CURRENCY_COUNTER_RELEASE_DURATION: float = 0.085
const PORTRAIT_CURRENCY_ADD_BADGE_SIZE: float = 20.0
const PORTRAIT_CURRENCY_ADD_BADGE_GREEN := Color("#35C759")
const PORTRAIT_CURRENCY_ADD_BADGE_BORDER := Color("#167A34")
const PORTRAIT_MAIN_NAV_Y: float = 725.0
const PORTRAIT_MAIN_NAV_HEIGHT: float = 75.0
const PORTRAIT_MAIN_NAV_TAB_COUNT: int = 4
const PORTRAIT_MAIN_NAV_ITEM_WIDTH: float = 120.0
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
const PORTRAIT_FOOTER_CENTER_LONG_BUTTON_RECT := Rect2(90.0, 711.0, PORTRAIT_LONG_BUTTON_SIZE.x, PORTRAIT_LONG_BUTTON_SIZE.y)
const PORTRAIT_MENU_TITLE_MAX_SCALE: float = 1.15
# Dense screens may grow moderately on tall phones, but gameplay is split into
# independent upper and lower groups so the keyboard can stay width-safe while
# moving toward the thumb zone.
const PORTRAIT_GAME_KEYBOARD_MAX_SCALE: float = 1.15
const PORTRAIT_TWO_PLAYER_KEYBOARD_Y_OFFSET: float = 64.0
const PORTRAIT_PROFILE_MAX_SCALE: float = 1.10
const PORTRAIT_HERO_POSITION := Vector2(136.0, 302.0)
const PORTRAIT_TWO_PLAYER_HERO_VISUAL_CENTER_OFFSET_X: float = 100.0
const PORTRAIT_GAME_WORD_PAPER_SCREEN_OVERFLOW_X: float = 42.0
const PORTRAIT_GAME_WORD_PAPER_Y_OFFSET: float = -18.0
const PORTRAIT_GAME_WORD_PAPER_HEIGHT: float = 118.0
const PORTRAIT_ROUND_END_KEY_FADE_DURATION: float = 0.22
const PORTRAIT_ROUND_END_KEY_WAVE_DURATION: float = 0.48
const PORTRAIT_ROUND_END_KEY_SCALE: float = 1.28
const PORTRAIT_ROUND_END_PAPER_FLIP_DURATION: float = 0.92
const PORTRAIT_ROUND_END_PAPER_BACKSIDE_MAX_WIDTH: float = 190.0
const PORTRAIT_ROUND_END_ATTEMPTS_FADE_DURATION: float = 0.20
const PORTRAIT_ROUND_END_HINTS_FADE_DURATION: float = 0.18
const PORTRAIT_IN_PLACE_RESULT_KEYBOARD_ALPHA: float = 0.70
const PORTRAIT_ATTEMPTS_WARNING_THRESHOLD: int = 2
const PORTRAIT_ATTEMPTS_WARNING_BOUNCE_SCALE := Vector2(1.18, 1.18)
const PORTRAIT_ATTEMPTS_WARNING_BOUNCE_GROW_DURATION: float = 0.48
const PORTRAIT_ATTEMPTS_WARNING_BOUNCE_SETTLE_DURATION: float = 0.55
const PORTRAIT_ATTEMPTS_WARNING_BOUNCE_PAUSE_DURATION: float = 0.12
const PORTRAIT_ATTEMPTS_COUNTER_ROLL_DURATION: float = 0.20
const PORTRAIT_GAME_ENTRANCE_START_DELAY: float = 0.05
const PORTRAIT_GAME_ENTRANCE_SPEED_MULTIPLIER: float = 1.30
const PORTRAIT_GAME_HERO_ENTRANCE_FADE_DURATION: float = 0.26
const PORTRAIT_GAME_HERO_EXIT_FADE_DURATION: float = 0.24
const PORTRAIT_INLINE_RESULT_TITLE_RECT := Rect2(40.0, 138.0, 400.0, 54.0)
const PORTRAIT_INLINE_RESULT_CONTINUE_BUTTON_RECT := Rect2(99.75, 620.0, 280.5, 70.4)
const PORTRAIT_INLINE_RESULT_TITLE_FADE_DURATION: float = 0.18
const PORTRAIT_INLINE_RESULT_CONTINUE_START_SCALE: float = 0.72
const PORTRAIT_INLINE_RESULT_CONTINUE_PEAK_SCALE: float = 1.10
const PORTRAIT_INLINE_RESULT_CONTINUE_GROW_DURATION: float = 0.12
const PORTRAIT_INLINE_RESULT_CONTINUE_SETTLE_DURATION: float = 0.18
# Reward-screen hero is deliberately only 30% larger than the in-round hero.
# The X offset scales with the hero so the visible artwork (not the Flash origin)
# stays centered on the 480 px portrait stage.
const PORTRAIT_SINGLE_REWARD_HERO_SCALE_MULTIPLIER: float = PORTRAIT_GAME_HERO_SCALE_MULTIPLIER * 1.30
const PORTRAIT_SINGLE_REWARD_HERO_POSITION := Vector2(
	PORTRAIT_STAGE_SIZE.x * 0.5 - PORTRAIT_TWO_PLAYER_HERO_VISUAL_CENTER_OFFSET_X * 1.30,
	525.0
)
# Approximate visible bottom of the clean reward hero in authored stage space.
# The chain position is resolved at runtime from this edge and the physical
# position of the bottom-attached Continue button, so it stays visually centered
# between the character and CTA on both 16:9 and extra-tall phones.
const PORTRAIT_SINGLE_REWARD_HERO_VISUAL_BOTTOM_Y: float = 530.0
const PORTRAIT_SINGLE_REWARD_CHAIN_WIDTH: float = 430.0
const PORTRAIT_SINGLE_REWARD_NODE_MAX_SIZE: float = 102.0
const PORTRAIT_SINGLE_REWARD_NODE_MIN_SIZE: float = 40.0
const PORTRAIT_SINGLE_REWARD_NODE_GAP: float = 14.0
const PORTRAIT_SINGLE_REWARD_CURRENT_NODE_SCALE: float = 1.20
const PORTRAIT_SINGLE_REWARD_SIDE_NODE_SCALE: float = 0.90
const PORTRAIT_SINGLE_REWARD_STATUS_Y: float = 604.0
const PORTRAIT_SINGLE_REWARD_SUMMARY_Y: float = 642.0
const PORTRAIT_SINGLE_REWARD_BONUS_Y: float = 672.0
const PORTRAIT_SINGLE_REWARD_CHAIN_ICON_SCALE: float = 0.72
const PORTRAIT_SINGLE_REWARD_CHAIN_COUNT_FONT_SIZE: int = 22
const PORTRAIT_SINGLE_REWARD_CHAIN_COUNT_MIN_FONT_SIZE: int = 15
const PORTRAIT_SINGLE_REWARD_CHECK_LINE_WIDTH: float = 7.5
const PORTRAIT_SINGLE_REWARD_CLAIM_ICON_FADE_DURATION: float = 0.18
const PORTRAIT_SINGLE_REWARD_CLAIMED_COIN_ALPHA: float = 0.45
const PORTRAIT_SINGLE_REWARD_CHECK_BOUNCE_DELAY: float = 0.12
const PORTRAIT_SINGLE_REWARD_CHECK_BOUNCE_START_SCALE: float = 0.42
const PORTRAIT_SINGLE_REWARD_CHECK_BOUNCE_PEAK_SCALE: float = 1.16
const PORTRAIT_SINGLE_REWARD_CHECK_BOUNCE_GROW_DURATION: float = 0.15
const PORTRAIT_SINGLE_REWARD_CHECK_BOUNCE_SETTLE_DURATION: float = 0.20
const PORTRAIT_SINGLE_REWARD_FLY_COIN_COUNT: int = 9
const PORTRAIT_SINGLE_REWARD_FLY_COIN_SIZE: float = 66.0
const PORTRAIT_SINGLE_REWARD_FLY_SPREAD_X: float = 30.0
const PORTRAIT_SINGLE_REWARD_FLY_SPREAD_Y: float = 18.0
const PORTRAIT_SINGLE_REWARD_FLY_START_DELAY: float = 0.02
const PORTRAIT_SINGLE_REWARD_FLY_STAGGER: float = 0.09
const PORTRAIT_SINGLE_REWARD_FLY_DURATION: float = 0.52
const PORTRAIT_SINGLE_REWARD_TITLE_RECT := Rect2(44.0, 120.0, 392.0, 64.0)
const PORTRAIT_SINGLE_REWARD_SUBTITLE_RECT := Rect2(52.0, 184.0, 376.0, 40.0)
const PORTRAIT_SINGLE_REWARD_TITLE_FONT_SIZE: int = 46
const PORTRAIT_SINGLE_REWARD_SUBTITLE_FONT_SIZE: int = 24
const PORTRAIT_SINGLE_REWARD_BLUE_OVERLAY_COLOR := Color(0.22, 0.46, 0.92, 0.76)
const PORTRAIT_SINGLE_REWARD_TITLE_BLOCK_HEIGHT: float = 112.0
const PORTRAIT_SINGLE_REWARD_TITLE_BLOCK_TOP_RECT := Rect2(
	0.0,
	88.0,
	PORTRAIT_STAGE_SIZE.x,
	PORTRAIT_SINGLE_REWARD_TITLE_BLOCK_HEIGHT
)
const PORTRAIT_SINGLE_REWARD_TITLE_BLOCK_CENTER_RECT := Rect2(
	0.0,
	# Keep the old top edge of the intro block, but extend the taller background
	# downward. Its bottom now starts below the complete hero artwork, so the real
	# clip begins with the character fully hidden and reveals it cleanly as the
	# header moves upward.
	PORTRAIT_SINGLE_REWARD_HERO_VISUAL_BOTTOM_Y - PORTRAIT_HEADER_HEIGHT,
	PORTRAIT_STAGE_SIZE.x,
	PORTRAIT_SINGLE_REWARD_TITLE_BLOCK_HEIGHT
)
const PORTRAIT_SINGLE_REWARD_TITLE_BLOCK_FILL := PORTRAIT_BLUE
const PORTRAIT_SINGLE_REWARD_TITLE_BLOCK_BORDER := PORTRAIT_BLUE
const PORTRAIT_SINGLE_REWARD_TITLE_TOP_PADDING: float = 10.0
const PORTRAIT_SINGLE_REWARD_TITLE_HEIGHT: float = 52.0
const PORTRAIT_SINGLE_REWARD_SUBTITLE_TOP: float = 62.0
const PORTRAIT_SINGLE_REWARD_SUBTITLE_HEIGHT: float = 32.0
const PORTRAIT_SINGLE_REWARD_TITLE_START_SCALE: float = 0.52
const PORTRAIT_SINGLE_REWARD_TITLE_PEAK_SCALE: float = 1.14
const PORTRAIT_SINGLE_REWARD_TITLE_GROW_DURATION: float = 0.16
const PORTRAIT_SINGLE_REWARD_TITLE_SETTLE_DURATION: float = 0.20
const PORTRAIT_SINGLE_REWARD_TITLE_MOVE_DURATION: float = 0.28
const PORTRAIT_SINGLE_REWARD_BODY_FADE_DURATION: float = 0.16
const PORTRAIT_CURRENCY_ICON_REWARD_BOUNCE_PEAK_SCALE: float = 1.16
const PORTRAIT_CURRENCY_ICON_REWARD_BOUNCE_GROW_DURATION: float = 0.035
const PORTRAIT_CURRENCY_ICON_REWARD_BOUNCE_SETTLE_DURATION: float = 0.050
const PORTRAIT_HINT_COUNTER_ROLL_DURATION: float = 0.18
const PORTRAIT_GAME_HINT_ENTRANCE_START_SCALE: float = 0.72
const PORTRAIT_GAME_HINT_ENTRANCE_PEAK_SCALE: float = 1.12
const PORTRAIT_GAME_HINT_ENTRANCE_GROW_DURATION: float = 0.13
const PORTRAIT_GAME_HINT_ENTRANCE_SETTLE_DURATION: float = 0.16
const PORTRAIT_RESULT_SEARCH_BUTTON_SIZE: float = 44.0
const PORTRAIT_RESULT_SEARCH_REST_VISUAL_SCALE := Vector2.ONE
const PORTRAIT_RESULT_SEARCH_START_VISUAL_SCALE := PORTRAIT_RESULT_SEARCH_REST_VISUAL_SCALE * 0.72
const PORTRAIT_RESULT_WORD_SEARCH_GAP: float = 10.0
const PORTRAIT_RESULT_SEARCH_SAFE_MARGIN: float = 14.0
const PORTRAIT_RESULT_WORD_Y_OFFSET: float = 4.0
const PORTRAIT_RESULT_LETTER_SPACING: int = 2
const PORTRAIT_RESULT_SEARCH_ICON_SIZE := Vector2(24.0, 31.0)
const PORTRAIT_RESULT_LETTER_BOUNCE_GROW_DURATION: float = 0.068
const PORTRAIT_RESULT_LETTER_BOUNCE_SETTLE_DURATION: float = 0.072
const PORTRAIT_RESULT_LETTER_BOUNCE_GAP: float = 0.0094
const PORTRAIT_RESULT_LETTER_BOUNCE_REFERENCE_LENGTH: float = 5.0
const PORTRAIT_RESULT_LETTER_BOUNCE_MAX_SPEED_MULTIPLIER: float = 2.2
const PORTRAIT_RESULT_LETTER_BOUNCE_NEIGHBOR_STRENGTH: float = 0.42
const PORTRAIT_RESULT_LETTER_BOUNCE_NEIGHBOR_RADIUS: int = 2
const PORTRAIT_RESULT_SEARCH_APPEAR_DURATION: float = 0.18
const PORTRAIT_HERO_BASE_SCALE_MULTIPLIER: float = 0.86
const PORTRAIT_GAME_HERO_SCALE_MULTIPLIER: float = PORTRAIT_HERO_BASE_SCALE_MULTIPLIER * 1.32
const PORTRAIT_GAME_HERO_Y_LIFT: float = 42.0
const PORTRAIT_GAME_HERO_LEFT_CENTER_X: float = PORTRAIT_STAGE_SIZE.x * 0.25
const PORTRAIT_BACK_ARROW_ICON: Texture2D = preload("res://flash_assets/portrait_back_arrow_icon.png")
const PORTRAIT_HINT_REVEAL_LETTER_ICON: Texture2D = preload("res://flash_assets/hint_reveal_letter_doodle.png")
const PORTRAIT_HINT_REMOVE_WRONG_ICON: Texture2D = preload("res://flash_assets/hint_remove_wrong_doodle.png")
const PORTRAIT_HINT_COMMENT_UNLOCK_ICON: Texture2D = preload("res://flash_assets/hint_comment_unlock_doodle.png")
const PORTRAIT_HINT_USED_GRAYSCALE_SHADER: Shader = preload("res://shaders/hint_icon_grayscale.gdshader")
const PORTRAIT_NAV_PROFILE_ICON: Texture2D = preload("res://flash_assets/nav_profile_icon.png")
const PORTRAIT_NAV_SHOP_ICON: Texture2D = preload("res://flash_assets/nav_shop_icon.png")
const PORTRAIT_NAV_HOME_ICON: Texture2D = preload("res://flash_assets/nav_home_icon.png")
const PORTRAIT_NAV_TASKS_ICON: Texture2D = preload("res://flash_assets/nav_tasks_icon.png")
const PORTRAIT_MENU_SETTINGS_ICON: Texture2D = preload("res://flash_assets/settings_gear_icon.png")
const PORTRAIT_GAME_WORD_PAPER_TEXTURE: Texture2D = preload("res://flash_assets/word_paper_torn.png")
const PORTRAIT_GAME_WORD_PAPER_BACKSIDE_TEXTURE: Texture2D = preload("res://flash_assets/word_paper_backside.png")

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
const PORTRAIT_SINGLE_PLAYER_SLOT_ICON_GAP: float = 8.0
const PORTRAIT_SINGLE_PLAYER_SLOT_BASE_SPINS: int = 7
const PORTRAIT_SINGLE_PLAYER_SLOT_SPINS_PER_REEL: int = 2
const PORTRAIT_SINGLE_PLAYER_SLOT_BASE_DURATION: float = 0.34
const PORTRAIT_SINGLE_PLAYER_SLOT_DURATION_STEP: float = 0.06
const PORTRAIT_SINGLE_PLAYER_SLOT_ACCELERATION_DURATION: float = 0.055
const PORTRAIT_SINGLE_PLAYER_SLOT_LANDING_DURATION: float = 0.006
const PORTRAIT_SINGLE_PLAYER_SLOT_SPIN_ICON_ALPHA: float = 0.90
const PORTRAIT_SINGLE_PLAYER_SLOT_REVEAL_STAGGER: float = 0.0
const PORTRAIT_SINGLE_PLAYER_SLOT_REVEAL_PEAK_SCALE := Vector2(1.38, 1.38)
const PORTRAIT_SINGLE_PLAYER_SLOT_REVEAL_GROW_DURATION: float = 0.08
const PORTRAIT_SINGLE_PLAYER_SLOT_REVEAL_SETTLE_DURATION: float = 0.14
const PORTRAIT_SINGLE_PLAYER_SLOT_LABEL_FADE_DURATION: float = 0.14
const PORTRAIT_GAME_HINT_BUTTON_SIZE := Vector2(120.0, 58.0)
const PORTRAIT_GAME_RETRY_BUTTON_SIZE := Vector2(PORTRAIT_LONG_BUTTON_SIZE.x, PORTRAIT_LONG_BUTTON_SIZE.y)
const PORTRAIT_GAME_HINT_KEYBOARD_GAP: float = 32.0
const PORTRAIT_GAME_HINT_Y: float = 650.0
const PORTRAIT_GAME_HINT_OPEN_BUTTON_RECT := Rect2(42.0, PORTRAIT_GAME_HINT_Y, PORTRAIT_GAME_HINT_BUTTON_SIZE.x, PORTRAIT_GAME_HINT_BUTTON_SIZE.y)
const PORTRAIT_GAME_HINT_REMOVE_BUTTON_RECT := Rect2(180.0, PORTRAIT_GAME_HINT_Y, PORTRAIT_GAME_HINT_BUTTON_SIZE.x, PORTRAIT_GAME_HINT_BUTTON_SIZE.y)
const PORTRAIT_GAME_HINT_COMMENT_BUTTON_RECT := Rect2(318.0, PORTRAIT_GAME_HINT_Y, PORTRAIT_GAME_HINT_BUTTON_SIZE.x, PORTRAIT_GAME_HINT_BUTTON_SIZE.y)
const PORTRAIT_GAME_HINT_ART_SIZE := Vector2(50.0, 50.0)
const PORTRAIT_GAME_HINT_ART_RISE: float = -5.0
const PORTRAIT_GAME_HINT_COMMENT_ART_Y_OFFSET: float = -4.0
const PORTRAIT_GAME_HINT_COUNTER_SIZE: float = 28.0
const PORTRAIT_WORD_LETTER_BOUNCE_START_SCALE := Vector2(0.58, 0.58)
const PORTRAIT_WORD_LETTER_BOUNCE_PEAK_SCALE := Vector2(1.24, 1.24)
const PORTRAIT_WORD_LETTER_BOUNCE_GROW_DURATION: float = 0.18
const PORTRAIT_WORD_LETTER_BOUNCE_SETTLE_DURATION: float = 0.24
const PORTRAIT_CUSTOM_WORD_INPUT_RECT := Rect2(22.0, 0.0, 436.0, 72.0)
const PORTRAIT_CUSTOM_WORD_CHECK_RECT := Rect2(94.0, 518.0, PORTRAIT_LONG_BUTTON_SIZE.x, PORTRAIT_LONG_BUTTON_SIZE.y)
const PORTRAIT_CUSTOM_WORD_RANDOM_RECT := Rect2(94.0, 592.0, PORTRAIT_LONG_BUTTON_SIZE.x, PORTRAIT_LONG_BUTTON_SIZE.y)
const PORTRAIT_COIN_TEST_BUTTON_RECT := Rect2(90.0, 340.0, PORTRAIT_LONG_BUTTON_SIZE.x, PORTRAIT_LONG_BUTTON_SIZE.y)

enum MainTab {
	HOME,
	TASKS,
	SHOP,
	PROFILE,
}

var _portrait_custom_word_input: Control = null
var _portrait_game_adaptive_group: Control = null
var _portrait_game_hero_stage_position: Vector2 = PORTRAIT_HERO_POSITION
var _portrait_game_input_group: Control = null
var _portrait_game_word_paper_mask: Control = null
var _portrait_game_word_paper_layer: Control = null
var _portrait_game_word_paper_backside: Control = null
var _portrait_game_word_paper_backside_visual: TextureRect = null
var _portrait_game_word_slots_root: Control = null
var _portrait_game_word_rect := Rect2()
var _portrait_game_keyboard_buttons: Array = []
var _portrait_game_hint_buttons: Array[Control] = []
var _portrait_game_hint_signature: String = ""
var _portrait_game_attempts_controls: Array[Control] = []
var _portrait_game_attempts_value_label: Label = null
var _portrait_game_attempts_bounce_tween: Tween = null
var _portrait_game_attempts_roll_tween: Tween = null
var _portrait_game_attempts_roll_clip: Control = null
var _portrait_game_attempts_displayed_value: int = -1
var _portrait_game_runtime_ready: bool = false
var _portrait_currency_counter_visual: Control = null
var _portrait_currency_coin_icon_visual: Control = null
var _portrait_heart_icon_visual: Control = null
var _portrait_round_end_transition_active: bool = false
var _portrait_round_end_bounce_started: bool = false
var _portrait_inline_result_visible: bool = false
var _portrait_inline_result_search_button: Control = null
var _portrait_inline_result_word_holder: Control = null
var _portrait_inline_result_title_label: Label = null
var _portrait_inline_result_continue_button: Control = null
var _portrait_in_place_result_active: bool = false
var _portrait_in_place_result_is_win: bool = false
var _portrait_game_entrance_pending: bool = false
var _portrait_game_entrance_active: bool = false
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
var _portrait_coin_store_active: bool = false
var _portrait_back_button_visible: bool = false
var _portrait_previous_screen_had_back: bool = false
var _portrait_last_animated_reward_claim_key: String = ""
var _portrait_single_reward_resume_without_intro: bool = false
var _portrait_hint_counter_animation_active: bool = false
var _portrait_hint_counter_refresh_requested: bool = false
var _profile_name_edit: LineEdit = null
var _profile_edit_character_id: int = 1
var _profile_avatar_checks: Dictionary = {}
var _profile_avatar_halos: Dictionary = {}
var single_player_popup_refresh_button: Control = null
var _single_player_popup_theme_card_visuals: Array = []
var _single_player_theme_slot_animation_nodes: Array[Node] = []
var _single_player_theme_slot_tweens: Array[Tween] = []
var _single_player_theme_slot_animating: bool = false
var _single_player_theme_slot_generation: int = 0
var _single_player_theme_slot_final_selection: int = -1
var _single_player_theme_reroll_level_index: int = -1
var _single_player_theme_reroll_used: bool = false

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
	_remove_settings_popup()
	_remove_profile_edit_popup()
	_portrait_custom_word_input = null
	_portrait_top_bar_content = null
	_portrait_coin_store_active = false
	_portrait_game_adaptive_group = null
	_portrait_game_input_group = null
	_portrait_game_word_paper_mask = null
	_portrait_game_word_paper_layer = null
	_portrait_game_word_paper_backside = null
	_portrait_game_word_paper_backside_visual = null
	_portrait_game_word_slots_root = null
	_portrait_game_word_rect = Rect2()
	_portrait_game_keyboard_buttons.clear()
	_portrait_game_hint_buttons.clear()
	_portrait_game_hint_signature = ""
	_stop_portrait_attempts_attention_bounce(true)
	_portrait_game_attempts_controls.clear()
	_portrait_game_attempts_value_label = null
	if _portrait_game_attempts_roll_tween != null and _portrait_game_attempts_roll_tween.is_valid():
		_portrait_game_attempts_roll_tween.kill()
	_portrait_game_attempts_roll_tween = null
	if _portrait_game_attempts_roll_clip != null and is_instance_valid(_portrait_game_attempts_roll_clip):
		_portrait_game_attempts_roll_clip.queue_free()
	_portrait_game_attempts_roll_clip = null
	_portrait_game_attempts_displayed_value = -1
	_portrait_currency_counter_visual = null
	_portrait_currency_coin_icon_visual = null
	_portrait_game_runtime_ready = false
	_portrait_hint_counter_animation_active = false
	_portrait_hint_counter_refresh_requested = false
	_portrait_in_place_result_active = false
	_portrait_in_place_result_is_win = false
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
		_portrait_active_main_tab >= MainTab.HOME
		and _portrait_active_main_tab <= MainTab.PROFILE
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
		MainTab.HOME,
		MainTab.PROFILE
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

func _portrait_scaled_footer_control_rect(rect: Rect2) -> Rect2:
	var scaled_size: Vector2 = rect.size * PORTRAIT_FOOTER_CONTROL_SCALE
	return Rect2(rect.get_center() - scaled_size * 0.5, scaled_size)

func _portrait_footer_font_size(font_size: int) -> int:
	return int(round(float(font_size) * PORTRAIT_FOOTER_CONTROL_SCALE))

func _portrait_begin_bottom_attached_group() -> Control:
	var previous_content: Control = content
	var bottom_group := Control.new()
	bottom_group.name = "PortraitBottomAttached"
	# Do not rely on the node name to identify this layout container. Godot may
	# replace duplicate sibling names with internal names such as @Control@123,
	# which previously made the second bottom-attached group (the hint row) lose
	# its physical-bottom translation on tall screens.
	bottom_group.set_meta("portrait_bottom_attached", true)
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

func _portrait_screen_without_header(footer_y: float = -1.0) -> void:
	var paper_background := _stage_texture_fill(0.0, PORTRAIT_STAGE_SIZE.y, MENU_PAPER_COVER)
	paper_background.set("tile_scale", PORTRAIT_PAPER_GRID_SCALE)
	paper_background.z_index = -2
	var screen_content: Control = content
	content = _portrait_create_top_bar_group()
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

func _stage_menu_settings_button() -> void:
	var screen_content: Control = content
	if _portrait_top_bar_content != null and is_instance_valid(_portrait_top_bar_content):
		content = _portrait_top_bar_content
	var settings_button := _stage_round_icon_button(
		PORTRAIT_MENU_SETTINGS_BUTTON_RECT,
		Callable(self, "show_settings"),
		PORTRAIT_MENU_SETTINGS_ICON,
		PORTRAIT_MENU_SETTINGS_ICON_SIZE
	)
	if game_screen_visible and _portrait_game_is_challenge_level():
		settings_button.call(
			"set_color_palette",
			DIFFICULTY_HARD_NORMAL_TINT,
			DIFFICULTY_HARD_PRESSED_TINT,
			DIFFICULTY_HARD_SELECTED_TINT
		)
	content = screen_content

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
	challenge_colors: bool = false,
	interactive: bool = true
) -> void:
	var screen_content: Control = content
	if _portrait_top_bar_content != null and is_instance_valid(_portrait_top_bar_content):
		content = _portrait_top_bar_content
	var counter_rect: Rect2 = rect if rect.size.x > 0.0 and rect.size.y > 0.0 else PORTRAIT_CURRENCY_COUNTER_RECT
	var counter_scale: float = counter_rect.size.y / 48.0
	var panel_color: Color = PORTRAIT_CHALLENGE_HUD_PANEL if challenge_colors else PORTRAIT_DARK_BLUE
	var border_color: Color = PORTRAIT_CHALLENGE_HUD_BORDER if challenge_colors else Color(0.72, 0.77, 0.91, 1.0)
	# Keep resource counters pressable in the shop as well. Their action is
	# resolved centrally below so pressing them while the shop is already open
	# only plays the normal press feedback instead of rebuilding the same screen.
	var counter_is_interactive: bool = interactive
	var counter_parent_content: Control = content
	var counter_visual := Control.new()
	counter_visual.name = "CurrencyCounterVisual"
	counter_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	counter_parent_content.add_child(counter_visual)
	counter_visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	counter_visual.pivot_offset = _portrait_stage_point_to_viewport(
		counter_rect.get_center(),
		counter_visual
	)
	_portrait_currency_counter_visual = counter_visual
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
	_portrait_currency_coin_icon_visual = coin_icon
	if counter_is_interactive:
		_stage_resource_add_badge(icon_rect, counter_scale)
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
	if counter_is_interactive:
		_stage_resource_counter_button(counter_rect, counter_visual, return_action)
	content = screen_content

	var heart_rect := Rect2(
		counter_rect.position + Vector2(counter_rect.size.x + PORTRAIT_RESOURCE_COUNTER_GAP, 0.0),
		counter_rect.size
	)
	_stage_heart_counter(return_action, heart_rect, challenge_colors, interactive)
	# Every screen that exposes the global resources shares the same top bar.
	# Staging Settings here keeps the right corner consistent for main tabs,
	# gameplay, result, shop, and nested pages without per-screen omissions.
	_stage_menu_settings_button()

func _stage_centered_coin_only_counter(
	return_action: Callable,
	rect: Rect2 = Rect2(),
	challenge_colors: bool = false,
	interactive: bool = true
) -> void:
	var screen_content: Control = content
	if _portrait_top_bar_content != null and is_instance_valid(_portrait_top_bar_content):
		content = _portrait_top_bar_content
	var source_rect: Rect2 = rect if rect.size.x > 0.0 and rect.size.y > 0.0 else PORTRAIT_CURRENCY_COUNTER_RECT
	var counter_rect := Rect2(
		(PORTRAIT_STAGE_SIZE.x - source_rect.size.x) * 0.5,
		source_rect.position.y,
		source_rect.size.x,
		source_rect.size.y
	)
	var counter_scale: float = counter_rect.size.y / 48.0
	var panel_color: Color = PORTRAIT_CHALLENGE_HUD_PANEL if challenge_colors else PORTRAIT_DARK_BLUE
	var border_color: Color = PORTRAIT_CHALLENGE_HUD_BORDER if challenge_colors else Color(0.72, 0.77, 0.91, 1.0)
	var counter_is_interactive: bool = interactive
	var counter_parent_content: Control = content
	var counter_visual := Control.new()
	counter_visual.name = "CurrencyCounterVisual"
	counter_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	counter_parent_content.add_child(counter_visual)
	counter_visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	counter_visual.pivot_offset = _portrait_stage_point_to_viewport(
		counter_rect.get_center(),
		counter_visual
	)
	_portrait_currency_counter_visual = counter_visual
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
	_portrait_currency_coin_icon_visual = coin_icon
	if counter_is_interactive:
		_stage_resource_add_badge(icon_rect, counter_scale)
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
	if counter_is_interactive:
		_stage_resource_counter_button(counter_rect, counter_visual, return_action)
	content = screen_content

func _stage_heart_counter(
	return_action: Callable,
	counter_rect: Rect2,
	challenge_colors: bool = false,
	interactive: bool = true
) -> void:
	var screen_content: Control = content
	if _portrait_top_bar_content != null and is_instance_valid(_portrait_top_bar_content):
		content = _portrait_top_bar_content
	var counter_scale: float = counter_rect.size.y / 48.0
	var panel_color: Color = PORTRAIT_CHALLENGE_HUD_PANEL if challenge_colors else PORTRAIT_DARK_BLUE
	var border_color: Color = PORTRAIT_CHALLENGE_HUD_BORDER if challenge_colors else Color(0.72, 0.77, 0.91, 1.0)
	var counter_is_interactive: bool = interactive
	var counter_parent_content: Control = content
	var counter_visual := Control.new()
	counter_visual.name = "HeartCounterVisual"
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
	# Match the coin icon height while preserving the source heart's wider
	# aspect ratio. Keep the complete texture inside the panel, using the same
	# left inset and vertical centering as the coin counter.
	var heart_icon_size := Vector2(
		PORTRAIT_CURRENCY_ICON_SIZE * PORTRAIT_HEART_ICON_ASPECT_RATIO,
		PORTRAIT_CURRENCY_ICON_SIZE
	)
	var icon_rect := Rect2(
		Vector2(
			counter_rect.position.x + PORTRAIT_HEART_ICON_LEFT_INSET * counter_scale,
			counter_rect.position.y + (counter_rect.size.y - heart_icon_size.y) * 0.5
		),
		heart_icon_size
	)
	var heart_icon: Control = _stage_texture(icon_rect, LIFE_HEART_ICON_TEXTURE)
	heart_icon.z_index = 21
	_portrait_heart_icon_visual = heart_icon

	var resolved_hearts: int = GameState.get_hearts()
	var count_label := _stage_label(
		icon_rect,
		str(resolved_hearts),
		maxi(1, int(round(22.0 * counter_scale))),
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	count_label.add_theme_font_override("font", UI_PRIMARY_FONT)
	count_label.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.06, 0.95))
	count_label.add_theme_constant_override("outline_size", maxi(2, int(round(4.0 * counter_scale))))
	count_label.z_index = 22
	heart_count_label = count_label

	if counter_is_interactive:
		var add_badge_visual: Control = _stage_resource_add_badge(icon_rect, counter_scale)
		add_badge_visual.set_meta(&"badge_allowed", true)
		add_badge_visual.visible = resolved_hearts < GameState.MAX_HEARTS
		heart_add_badge_visual = add_badge_visual

	var status_rect := Rect2(
		Vector2(counter_rect.position.x + 52.0 * counter_scale, counter_rect.position.y),
		Vector2(counter_rect.size.x - 58.0 * counter_scale, counter_rect.size.y)
	)
	var recovery_seconds: int = GameState.get_heart_recovery_seconds()
	var status_text: String = _heart_status_text(resolved_hearts, recovery_seconds)
	var status_font_size: int = maxi(1, int(round(25.0 * counter_scale)))
	var status_min_font_size: int = maxi(1, int(round(16.0 * counter_scale)))
	var status_label := _stage_label(
		status_rect,
		status_text,
		status_font_size,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	status_label.add_theme_font_override("font", UI_PRIMARY_FONT)
	status_label.z_index = 21
	heart_status_label = status_label
	_fit_single_line_label_to_width(status_label, status_text, status_rect.size.x, status_font_size, status_min_font_size)
	content = counter_parent_content
	if counter_is_interactive:
		_stage_resource_counter_button(counter_rect, counter_visual, return_action)
	content = screen_content

func _stage_resource_add_badge(icon_rect: Rect2, counter_scale: float) -> Control:
	var badge_parent: Control = content
	var badge_visual := Control.new()
	badge_visual.name = "ResourceAddBadgeVisual"
	badge_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_parent.add_child(badge_visual)
	badge_visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content = badge_visual
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
	add_badge.z_index = 23
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
	plus_horizontal.z_index = 24
	var plus_vertical := _stage_panel(
		Rect2(
			plus_center - Vector2(plus_stroke, plus_arm) * 0.5,
			Vector2(plus_stroke, plus_arm)
		),
		Color.WHITE,
		plus_stroke * 0.5
	)
	plus_vertical.z_index = 24
	content = badge_parent
	return badge_visual

func _stage_resource_counter_button(
	counter_rect: Rect2,
	counter_visual: Control,
	return_action: Callable
) -> void:
	var counter_action: Callable = Callable(self, "_open_coin_store").bind(return_action)
	if _portrait_coin_store_active:
		counter_action = Callable(self, "_ignore_resource_counter_press")
	elif return_action.is_valid() and return_action.get_method() in [&"show_coin_store", &"_show_coin_store_tab"]:
		counter_action = return_action
	var counter_button := _stage_button(counter_rect, counter_action, "")
	counter_button.z_index = 25
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

func _ignore_resource_counter_press() -> void:
	# The shop is already visible. Keep the button and its press animation, but
	# do not rebuild or push the same store screen again.
	pass

func _set_currency_counter_pressed(
	counter_visual: Control,
	counter_rect: Rect2,
	is_pressed: bool
) -> void:
	if counter_visual == null or !is_instance_valid(counter_visual) or !counter_visual.is_inside_tree():
		return
	counter_visual.pivot_offset = _portrait_stage_point_to_viewport(
		counter_rect.get_center(),
		counter_visual
	)
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

func _bounce_portrait_currency_counter() -> void:
	if (
		_portrait_currency_counter_visual == null
		or !is_instance_valid(_portrait_currency_counter_visual)
		or !_portrait_currency_counter_visual.is_inside_tree()
	):
		return
	var counter_visual: Control = _portrait_currency_counter_visual
	counter_visual.pivot_offset = _portrait_stage_point_to_viewport(
		PORTRAIT_CURRENCY_COUNTER_RECT.get_center(),
		counter_visual
	)
	var previous_tween: Tween = counter_visual.get_meta(&"reward_bounce_tween", null) as Tween
	if previous_tween != null and previous_tween.is_valid():
		previous_tween.kill()
	var rest_scale: Vector2 = counter_visual.scale
	if rest_scale == Vector2.ZERO:
		rest_scale = Vector2.ONE
	var bounce_tween := counter_visual.create_tween()
	bounce_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var grow := bounce_tween.tween_property(counter_visual, "scale", rest_scale * 1.12, 0.12)
	grow.set_trans(Tween.TRANS_BACK)
	grow.set_ease(Tween.EASE_OUT)
	var settle := bounce_tween.tween_property(counter_visual, "scale", rest_scale, 0.18)
	settle.set_trans(Tween.TRANS_BOUNCE)
	settle.set_ease(Tween.EASE_OUT)
	counter_visual.set_meta(&"reward_bounce_tween", bounce_tween)

func _bounce_portrait_currency_coin_icon() -> void:
	if (
		_portrait_currency_coin_icon_visual == null
		or !is_instance_valid(_portrait_currency_coin_icon_visual)
		or !_portrait_currency_coin_icon_visual.is_inside_tree()
	):
		return
	var coin_icon: Control = _portrait_currency_coin_icon_visual
	coin_icon.pivot_offset = Vector2.ZERO
	var previous_tween: Tween = coin_icon.get_meta(&"reward_icon_bounce_tween", null) as Tween
	if previous_tween != null and previous_tween.is_valid():
		previous_tween.kill()
	var rest_scale: Vector2 = coin_icon.get_meta(&"reward_icon_rest_scale", Vector2.ZERO)
	var rest_position: Vector2 = coin_icon.position
	if rest_scale == Vector2.ZERO:
		rest_scale = coin_icon.scale
		if rest_scale == Vector2.ZERO:
			rest_scale = Vector2.ONE
		coin_icon.set_meta(&"reward_icon_rest_scale", rest_scale)
	if coin_icon.has_meta(&"reward_icon_rest_position"):
		rest_position = coin_icon.get_meta(&"reward_icon_rest_position", coin_icon.position)
	else:
		coin_icon.set_meta(&"reward_icon_rest_position", rest_position)
	# FlashStageTexture is authored with a top-left pivot. Changing pivot_offset on
	# the live stage node shifts its apparent position because the node already has
	# the adaptive fit scale applied. Keep the original pivot untouched and
	# compensate position while scaling so the visual center stays perfectly fixed.
	coin_icon.scale = rest_scale
	coin_icon.position = rest_position
	var peak_scale: Vector2 = rest_scale * PORTRAIT_CURRENCY_ICON_REWARD_BOUNCE_PEAK_SCALE
	var peak_position: Vector2 = rest_position - coin_icon.size * (peak_scale - rest_scale) * 0.5
	var bounce_tween := coin_icon.create_tween()
	bounce_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var grow_scale := bounce_tween.tween_property(
		coin_icon,
		"scale",
		peak_scale,
		PORTRAIT_CURRENCY_ICON_REWARD_BOUNCE_GROW_DURATION
	)
	grow_scale.set_trans(Tween.TRANS_BACK)
	grow_scale.set_ease(Tween.EASE_OUT)
	var grow_position := bounce_tween.parallel().tween_property(
		coin_icon,
		"position",
		peak_position,
		PORTRAIT_CURRENCY_ICON_REWARD_BOUNCE_GROW_DURATION
	)
	grow_position.set_trans(Tween.TRANS_BACK)
	grow_position.set_ease(Tween.EASE_OUT)
	var settle_scale := bounce_tween.tween_property(
		coin_icon,
		"scale",
		rest_scale,
		PORTRAIT_CURRENCY_ICON_REWARD_BOUNCE_SETTLE_DURATION
	)
	settle_scale.set_trans(Tween.TRANS_BOUNCE)
	settle_scale.set_ease(Tween.EASE_OUT)
	var settle_position := bounce_tween.parallel().tween_property(
		coin_icon,
		"position",
		rest_position,
		PORTRAIT_CURRENCY_ICON_REWARD_BOUNCE_SETTLE_DURATION
	)
	settle_position.set_trans(Tween.TRANS_BOUNCE)
	settle_position.set_ease(Tween.EASE_OUT)
	coin_icon.set_meta(&"reward_icon_bounce_tween", bounce_tween)

func _apply_portrait_standard_text_outline(target: Control, alpha: float = 0.82, outline_size: int = 2) -> void:
	if target == null or !is_instance_valid(target):
		return
	var effect_color := Color(
		0.26,
		0.34,
		0.68,
		alpha
	)
	target.add_theme_color_override("font_outline_color", effect_color)
	target.add_theme_constant_override("outline_size", outline_size)
	target.add_theme_color_override("font_shadow_color", effect_color)
	target.add_theme_constant_override("shadow_offset_x", 2)
	target.add_theme_constant_override("shadow_offset_y", 2)
	target.add_theme_constant_override("shadow_outline_size", 0)

func _apply_portrait_reward_header_text_effect(target: Control, outline_size: int = 2) -> void:
	if target == null or !is_instance_valid(target):
		return
	var outline_color := Color(0.08, 0.12, 0.34, 0.92)
	var shadow_color := Color(0.05, 0.08, 0.24, 0.72)
	target.add_theme_color_override("font_outline_color", outline_color)
	target.add_theme_constant_override("outline_size", outline_size)
	target.add_theme_color_override("font_shadow_color", shadow_color)
	target.add_theme_constant_override("shadow_offset_x", 2)
	target.add_theme_constant_override("shadow_offset_y", 2)
	target.add_theme_constant_override("shadow_outline_size", 0)

func _portrait_main_tab_action(tab_index: int) -> Callable:
	match tab_index:
		MainTab.HOME:
			return Callable(self, "show_menu")
		MainTab.SHOP:
			return Callable(self, "_show_coin_store_tab")
		MainTab.TASKS:
			return Callable(self, "show_tasks")
		MainTab.PROFILE:
			return Callable(self, "show_profile")
	return Callable()

func _portrait_main_tab_label(tab_index: int) -> String:
	match tab_index:
		MainTab.HOME:
			return _profile_text("Главная", "Home").to_upper()
		MainTab.SHOP:
			return _profile_text("Магазин", "Shop").to_upper()
		MainTab.TASKS:
			return _profile_text("Задания", "Tasks").to_upper()
		MainTab.PROFILE:
			return _profile_text("Профиль", "Profile").to_upper()
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
		previous_tab >= MainTab.HOME
		and previous_tab <= MainTab.PROFILE
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

	for tab_index in range(PORTRAIT_MAIN_NAV_TAB_COUNT):
		var tab_action: Callable = _portrait_main_tab_action(tab_index)
		var tab_icon: Texture2D
		var tab_label: String = _portrait_main_tab_label(tab_index)
		match tab_index:
			MainTab.HOME:
				tab_icon = PORTRAIT_NAV_HOME_ICON
			MainTab.SHOP:
				tab_icon = PORTRAIT_NAV_SHOP_ICON
			MainTab.TASKS:
				tab_icon = PORTRAIT_NAV_TASKS_ICON
			MainTab.PROFILE:
				tab_icon = PORTRAIT_NAV_PROFILE_ICON

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

func _open_coin_store(return_action: Callable = Callable()) -> void:
	# Any shop opened from active gameplay must return without scheduling the
	# gameplay entrance again. This also covers the insufficient-coins path from
	# hint buttons, which originates in the base class with show_game_screen().
	var resolved_return_action: Callable = return_action
	if (
		game_screen_visible
		and return_action.is_valid()
		and return_action.get_method() == &"show_game_screen"
	):
		resolved_return_action = Callable(self, "_return_to_game_from_coin_store")
	super._open_coin_store(resolved_return_action)

func _show_coin_store_screen(with_main_navigation: bool) -> void:
	_clear()
	_portrait_coin_store_active = true
	if with_main_navigation:
		_portrait_screen(0.0, PORTRAIT_MAIN_NAV_Y)
		# Resource counters stay fully interactive and retain their plus badges.
		# Their centralized shop action is a no-op while this screen is active.
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

func _portrait_top_right_coin_badge_rect(button_rect: Rect2, badge_size: Vector2) -> Rect2:
	return Rect2(
		Vector2(
			button_rect.end.x - badge_size.x * 0.82,
			button_rect.position.y - badge_size.y * 0.18
		),
		badge_size
	)

func _stage_single_player_level_header(level_index: int) -> void:
	_stage_portrait_page_header(
		"%s %d" % [_single_player_level_label(), level_index + 1],
		Callable(self, "show_menu"),
		Callable(self, "show_single_player_level").bind(level_index)
	)

func _stage_portrait_game_header() -> void:
	_stage_currency_counter(
		Callable(self, "_return_to_game_from_coin_store"),
		PORTRAIT_GAME_CURRENCY_COUNTER_RECT,
		_portrait_game_is_challenge_level()
	)

func _stage_portrait_game_info_text(y_shift: float = 0.0) -> void:
	var theme_text: String = ""
	if GameState.current_mode != GameState.GameMode.TWO_PLAYER and GameSession.theme_id >= 0:
		theme_text = String(Database.get_theme_name(GameSession.theme_id)).to_upper()

	var show_theme_block: bool = !theme_text.is_empty()
	var additional_y_shift: float = -10.0 if GameState.current_mode == GameState.GameMode.TWO_PLAYER else 0.0
	var group_center_y: float = 104.0 + y_shift + additional_y_shift
	var attempts_block_height: float = 66.0
	var theme_block_height: float = 60.0
	var block_gap: float = 30.0
	var total_group_height: float = attempts_block_height
	if show_theme_block:
		total_group_height += block_gap + theme_block_height
	var group_top: float = group_center_y - total_group_height * 0.5

	var attempts_title_rect := PORTRAIT_GAME_INFO_ATTEMPTS_TITLE_RECT
	attempts_title_rect.position.y = group_top
	var attempts_value_rect := PORTRAIT_GAME_INFO_ATTEMPTS_VALUE_RECT
	attempts_value_rect.position.y = group_top + 18.0

	var attempts_title_text: String = _single_player_text("Попытки", "Attempts")
	var attempts_title := _stage_label(
		attempts_title_rect,
		attempts_title_text,
		PORTRAIT_GAME_INFO_TITLE_FONT_SIZE,
		PORTRAIT_DARK_BLUE,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	attempts_title.add_theme_font_override("font", UI_HEADING_FONT)
	attempts_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	attempts_title.clip_text = false
	attempts_title.z_index = 12

	var attempts_value_text: String = str(GameSession.get_remaining_attempts())
	var attempts_value := _stage_label(
		attempts_value_rect,
		attempts_value_text,
		PORTRAIT_GAME_INFO_ATTEMPTS_FONT_SIZE,
		PORTRAIT_BLUE,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	attempts_value.add_theme_font_override("font", UI_HEADING_FONT)
	attempts_value.autowrap_mode = TextServer.AUTOWRAP_OFF
	attempts_value.clip_text = false
	attempts_value.z_index = 12
	var attempts_holder := attempts_value.get_parent() as Control
	if attempts_holder != null:
		# Keep the resting digit completely unclipped. The mechanical-roll effect
		# creates its own temporary padded mask, so the normal warning bounce can
		# grow outside this holder without cutting off the bottom of the glyph.
		attempts_holder.clip_contents = false
	_portrait_game_attempts_value_label = attempts_value
	_portrait_game_attempts_displayed_value = GameSession.get_remaining_attempts()

	# Keep the existing attempts-animation collection as the generic gameplay HUD
	# collection so the new text fades in/out at the same moments as before.
	_portrait_game_attempts_controls.append(attempts_title)
	_portrait_game_attempts_controls.append(attempts_value)

	if !show_theme_block:
		return

	var theme_title_rect := PORTRAIT_GAME_INFO_THEME_TITLE_RECT
	theme_title_rect.position.y = group_top + attempts_block_height + block_gap
	var theme_line_rect := PORTRAIT_GAME_INFO_THEME_LINE_RECT
	theme_line_rect.position.y = theme_title_rect.position.y + 16.0

	var theme_caption_text: String = _single_player_text("Тема", "Theme")
	var theme_caption := _stage_label(
		theme_title_rect,
		theme_caption_text,
		PORTRAIT_GAME_INFO_TITLE_FONT_SIZE,
		PORTRAIT_DARK_BLUE,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	theme_caption.add_theme_font_override("font", UI_HEADING_FONT)
	theme_caption.autowrap_mode = TextServer.AUTOWRAP_OFF
	theme_caption.clip_text = false
	theme_caption.z_index = 12

	var theme_line_label := _stage_label(
		theme_line_rect,
		theme_text,
		PORTRAIT_GAME_INFO_THEME_LINE_FONT_SIZE,
		PORTRAIT_BLUE,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	theme_line_label.add_theme_font_override("font", UI_HEADING_FONT)
	_fit_single_line_label_to_width(
		theme_line_label,
		theme_text,
		theme_line_rect.size.x,
		PORTRAIT_GAME_INFO_THEME_LINE_FONT_SIZE,
		maxi(
			int(round(float(PORTRAIT_GAME_INFO_THEME_LINE_FONT_SIZE) * 0.8)),
			PORTRAIT_GAME_INFO_THEME_LINE_FONT_SIZE - 7
		)
	)
	theme_line_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	theme_line_label.clip_text = false
	theme_line_label.z_index = 12
	_portrait_game_attempts_controls.append(theme_caption)
	_portrait_game_attempts_controls.append(theme_line_label)

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
	single_player_retry_after_loss = false
	_portrait_game_adaptive_group = null
	coin_store_return_action = Callable()
	_clear()

	_portrait_screen(0.0, PORTRAIT_MAIN_NAV_Y)
	_stage_currency_counter(Callable(self, "_show_coin_store_tab"))

	var menu_title_content: Control = _portrait_begin_adaptive_group(Vector2(240.0, 230.0), PORTRAIT_MENU_TITLE_MAX_SCALE, 0.04)
	var title_label := _stage_heading_label(Rect2(40.0, 160.0, 400.0, 88.0), Database.tr_text(0, "HANGMAN").to_upper(), 50, PORTRAIT_ORANGE, HORIZONTAL_ALIGNMENT_CENTER)
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_portrait_end_adaptive_group(menu_title_content)

	var button_x: float = 90.0
	_stage_main_button(Rect2(button_x, 554.0, PORTRAIT_LONG_BUTTON_SIZE.x, PORTRAIT_LONG_BUTTON_SIZE.y), Callable(self, "show_custom_word"), Database.tr_text(2, "Two Player").to_upper(), 22)
	_stage_single_player_menu_button(Rect2(67.5, 632.0, 345.0, 73.6), Callable(self, "_open_next_single_player_level"))

func show_settings() -> void:
	_show_settings_popup()

func _show_settings_popup() -> void:
	_remove_settings_popup()
	settings_toggle_buttons.clear()
	settings_word_language_buttons.clear()
	var previous_content := _portrait_popup_begin(
		"SettingsPopup",
		"settings_popup",
		130,
		Callable(self, "_remove_settings_popup"),
		120.0,
		680.0
	)
	var rect := Rect2(28.0, 120.0, 424.0, 560.0)
	_portrait_popup_shell(
		rect,
		_profile_text("Настройки", "Settings").to_upper(),
		Callable(self, "_remove_settings_popup"),
		28
	)

	_stage_label(Rect2(56.0, 218.0, 250.0, 42.0), _settings_sound_label(), 21, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_settings_toggle_button(Rect2(330.0, 214.0, 102.0, 49.0), 3)
	_stage_label(Rect2(56.0, 286.0, 250.0, 42.0), _settings_vibration_label(), 21, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_settings_toggle_button(Rect2(330.0, 282.0, 102.0, 49.0), 4)
	_stage_panel(Rect2(56.0, 350.0, 368.0, 2.0), PORTRAIT_RULE)
	_stage_label(Rect2(56.0, 374.0, 150.0, 42.0), _settings_word_base_label(), 21, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_settings_word_language_button(Rect2(210.0, 370.0, 102.0, 49.0), "ru", Database.tr_text(71, "Rus"))
	_stage_settings_word_language_button(Rect2(322.0, 370.0, 102.0, 49.0), "en", Database.tr_text(72, "Eng"))
	_stage_panel(Rect2(56.0, 450.0, 368.0, 2.0), PORTRAIT_RULE)

	_stage_round_icon_button(
		Rect2(174.0, 492.0, 58.0, 58.0),
		Callable(self, "_about_contact_action").bind("vk"),
		ABOUT_VK_ICON,
		ABOUT_VK_ICON_SIZE
	)
	_stage_round_icon_button(
		Rect2(248.0, 492.0, 58.0, 58.0),
		Callable(self, "_about_contact_action").bind("mail"),
		ABOUT_MAIL_ICON,
		ABOUT_MAIL_ICON_SIZE
	)
	var version_label := _stage_label(
		Rect2(40.0, 574.0, 400.0, 28.0),
		_about_version_text(),
		14,
		Color(0.78, 0.82, 0.96, 0.88),
		HORIZONTAL_ALIGNMENT_CENTER
	)
	version_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	version_label.clip_text = false
	content = previous_content

func _remove_settings_popup() -> void:
	var popup_nodes: Array = get_tree().get_nodes_in_group("settings_popup")
	for node: Node in popup_nodes:
		if is_instance_valid(node) and node.get_parent() != null:
			node.get_parent().remove_child(node)
			node.queue_free()
	settings_toggle_buttons.clear()
	settings_word_language_buttons.clear()

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
		_stage_currency_counter(Callable(self, "_show_coin_store_tab"))
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
func _remove_single_player_theme_popup() -> void:
	_cancel_single_player_theme_slot_animation()
	super._remove_single_player_theme_popup()
	single_player_popup_refresh_button = null
	_single_player_popup_theme_card_visuals.clear()

func _show_single_player_theme_popup(level_index: int, theme_index: int) -> void:
	_show_single_player_level_popup(level_index, theme_index)

func _show_single_player_last_chance_popup() -> void:
	_remove_single_player_last_chance_popup()
	if !GameSession.has_deferred_loss():
		return
	var close_action := Callable(self, "_decline_single_player_extra_attempt")
	var previous_content := _portrait_popup_begin(
		"SinglePlayerLastChancePopup",
		"single_player_last_chance_popup",
		140,
		close_action,
		170.0,
		570.0
	)
	var rect := Rect2(28.0, 170.0, 424.0, 400.0)
	_portrait_popup_shell(
		rect,
		_single_player_text("ЕЩЁ ОДНА ПОПЫТКА?", "ONE MORE TRY?"),
		close_action,
		27
	)
	var attempt_badge_rect := Rect2(176.0, 270.0, 128.0, 128.0)
	var attempt_badge := _stage_panel(
		attempt_badge_rect,
		PORTRAIT_ORANGE,
		attempt_badge_rect.size.x * 0.5,
		Color.WHITE,
		3.0
	)
	attempt_badge.z_index = 11
	var attempt_label := _stage_label(
		attempt_badge_rect,
		"+1",
		54,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	attempt_label.add_theme_color_override("font_outline_color", Color(0.23, 0.26, 0.52, 0.9))
	attempt_label.add_theme_constant_override("outline_size", 4)
	attempt_label.z_index = 12
	var description_label := _stage_label(
		Rect2(58.0, 402.0, 364.0, 68.0),
		_single_player_text(
			"Добавьте 1 попытку,\nчтобы продолжить игру",
			"Add 1 try\nto continue the game"
		),
		21,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	description_label.clip_text = false
	var purchase_button := _stage_portrait_popup_main_button(
		Rect2(90.0, 492.0, 300.0, 56.0),
		Callable(self, "_purchase_single_player_extra_attempt"),
		"%s  %d" % [
			_single_player_text("Продолжить", "Continue"),
			SINGLE_PLAYER_EXTRA_ATTEMPT_COST,
		],
		18,
		false,
		0.32,
		false,
		false,
		true,
		LONG_BUTTON_COLOR_GREEN
	)
	purchase_button.set("icon_texture", SOFT_CURRENCY_COIN_TEXTURE)
	purchase_button.set("icon_stage_size", Vector2(28.0, 28.0))
	content = previous_content

func _show_single_player_level_popup(
	level_index: int,
	selected_theme: int = -1,
	retry_after_loss: bool = false
) -> void:
	_remove_single_player_theme_popup()
	single_player_retry_after_loss = retry_after_loss
	level_index = _prepare_single_player_level_attempt(level_index)
	if _single_player_theme_reroll_level_index != level_index:
		_single_player_theme_reroll_level_index = level_index
		_single_player_theme_reroll_used = false
	# Theme options are deterministic from the persisted level seed. Only the
	# first creation of that seed should play the generation reels; reopening an
	# already generated level must show the same cards immediately.
	var theme_options_were_generated: bool = GameState.has_single_level_seed(
		Database.current_language,
		level_index
	)
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
	var close_action := (
		Callable(self, "_close_single_player_retry_popup")
		if retry_after_loss
		else Callable(self, "_remove_single_player_theme_popup")
	)
	var previous_content := _portrait_popup_begin(
		"SinglePlayerLevelPopup",
		"single_player_theme_popup",
		135,
		close_action,
		118.0,
		578.0
	)
	single_player_popup_stage_content = content
	var rect := Rect2(24.0, 118.0, 432.0, 460.0)
	var challenge_level: bool = _single_player_is_bonus_level(level_index)
	_portrait_popup_shell(
		rect,
		("%s %d" % [_single_player_level_label(), level_index + 1]).to_upper(),
		close_action,
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
	var card_y: float = 270.0
	# Center the complete reroll button in the free vertical strip between the
	# popup header separator and the top edge of the theme cards. Its price badge
	# then remains clear of both neighboring elements as well.
	var header_bottom_y: float = rect.position.y + 81.0
	var refresh_button_size := Vector2(48.0, 48.0) * PORTRAIT_SINGLE_PLAYER_REFRESH_BUTTON_SCALE
	var refresh_center := Vector2(394.0, (header_bottom_y + card_y) * 0.5)
	var refresh_button_rect := Rect2(
		refresh_center - refresh_button_size * 0.5,
		refresh_button_size
	)
	var refresh_button := _stage_round_icon_button(
		refresh_button_rect,
		Callable(self, "_refresh_single_player_theme_popup").bind(level_index),
		SINGLE_PLAYER_REFRESH_ICON,
		Vector2(27.0, 27.0) * PORTRAIT_SINGLE_PLAYER_REFRESH_BUTTON_SCALE,
		false
	)
	single_player_popup_refresh_button = refresh_button
	if challenge_level:
		refresh_button.call(
			"set_color_palette",
			DIFFICULTY_HARD_NORMAL_TINT,
			DIFFICULTY_HARD_PRESSED_TINT,
			DIFFICULTY_HARD_SELECTED_TINT
		)
	refresh_button.z_index = 15
	var refresh_price_badge_size := Vector2(44.0, 22.0)
	var refresh_price_badge_rect: Rect2 = _portrait_top_right_coin_badge_rect(
		refresh_button_rect,
		refresh_price_badge_size
	)
	var price_badge := _stage_panel(
		refresh_price_badge_rect,
		PORTRAIT_CHALLENGE_POPUP_HEADER if challenge_level else PORTRAIT_DARK_BLUE,
		11.0,
		PORTRAIT_CHALLENGE_POPUP_SEPARATOR if challenge_level else PORTRAIT_RULE,
		1.0
	)
	price_badge.z_index = 16
	var price_coin := _stage_texture(
		Rect2(
			refresh_price_badge_rect.position + Vector2(3.0, 3.0),
			Vector2(16.0, 16.0)
		),
		SOFT_CURRENCY_COIN_TEXTURE
	)
	price_coin.z_index = 17
	single_player_popup_refresh_price_label = _stage_label(
		Rect2(
			Vector2(refresh_price_badge_rect.position.x + 18.0, refresh_price_badge_rect.position.y),
			Vector2(refresh_price_badge_rect.size.x - 20.0, refresh_price_badge_rect.size.y)
		),
		str(SINGLE_PLAYER_THEME_REFRESH_COST),
		13,
		_purchase_price_color(SINGLE_PLAYER_THEME_REFRESH_COST),
		HORIZONTAL_ALIGNMENT_CENTER
	)
	single_player_popup_refresh_price_label.add_theme_font_override("font", UI_PRIMARY_FONT)
	single_player_popup_refresh_price_label.z_index = 17
	_update_single_player_theme_reroll_button_state()
	var word_count: int = _single_player_level_word_count(level_index)
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
		18,
		selected_theme < 0,
		0.32,
		false,
		false,
		true,
		LONG_BUTTON_COLOR_ORANGE
	)
	if selected_theme >= 0:
		_select_single_player_popup_theme(level_index, selected_theme)
	# A freshly generated set arrives through the same reel animation as a paid
	# reroll, but only after the popup itself has completed its opening bounce.
	# Existing seeded options never reroll merely because the popup was reopened.
	if !theme_options_were_generated:
		var opening_options: Array = _single_player_theme_slot_opening_options(options)
		_schedule_single_player_theme_slot_opening_animation(
			level_index,
			opening_options,
			options,
			selected_theme
		)
	content = previous_content

func _stage_single_player_popup_theme_cards(
	level_index: int,
	options: Array,
	card_y: float,
	word_count: int
) -> void:
	_clear_single_player_theme_slot_nodes()
	_single_player_popup_theme_card_visuals.clear()
	_clear_single_player_popup_theme_cards()
	if single_player_popup_stage_content == null or !is_instance_valid(single_player_popup_stage_content):
		return
	var previous_content: Control = content
	content = single_player_popup_stage_content
	var first_card_node_index: int = content.get_child_count()
	var card_size := Vector2(128.0, 202.0)
	var challenge_level: bool = _single_player_is_bonus_level(level_index)
	var card_fill: Color = (
		Color(0.19, 0.24, 0.56, 1.0)
		if challenge_level
		else Color(0.16, 0.20, 0.48, 1.0)
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
		var theme_icon: Control = null
		var word_badge: Control = null
		var word_badge_label: Label = null
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
			theme_icon = _stage_texture(theme_icon_rect, theme_icon_texture)
			var word_badge_size := Vector2(48.0, 27.0)
			var word_badge_rect := Rect2(
				theme_icon_rect.end - word_badge_size * Vector2(0.86, 0.82),
				word_badge_size
			)
			word_badge = _stage_panel(
				word_badge_rect,
				PORTRAIT_ORANGE,
				word_badge_size.y * 0.5,
				Color.WHITE,
				1.5
			)
			word_badge.z_index = 13
			word_badge_label = _stage_label(
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
		_single_player_popup_theme_card_visuals.append({
			"card_rect": card_rect,
			"theme_index": theme_index,
			"theme_icon": theme_icon,
			"word_badge": word_badge,
			"word_badge_label": word_badge_label,
			"theme_label": theme_label,
			"theme_button": theme_button,
		})
	for child_index in range(first_card_node_index, content.get_child_count()):
		single_player_popup_theme_card_nodes.append(content.get_child(child_index))
	content = previous_content

func _refresh_single_player_theme_popup(level_index: int) -> void:
	if (
		level_index != single_player_popup_level_index
		or _single_player_theme_slot_animating
		or _single_player_theme_reroll_used
	):
		return
	if GameState.get_soft_currency() < SINGLE_PLAYER_THEME_REFRESH_COST:
		_open_coin_store(
			Callable(self, "_return_to_single_player_theme_popup").bind(
				level_index,
				single_player_retry_after_loss
			)
		)
		return
	if !GameState.spend_soft_currency(SINGLE_PLAYER_THEME_REFRESH_COST):
		return
	_single_player_theme_reroll_used = true
	_update_single_player_theme_reroll_button_state()
	var previous_options: Array = _single_player_level_theme_options(level_index).duplicate()
	var next_options: Array = _reroll_single_player_theme_options(level_index, previous_options)
	_update_single_player_refresh_price(GameState.get_soft_currency())
	if (
		previous_options.size() != next_options.size()
		or next_options.size() != _single_player_popup_theme_card_visuals.size()
	):
		_update_single_player_theme_popup(level_index)
		return
	_start_single_player_theme_slot_animation(level_index, previous_options, next_options)

func _update_single_player_theme_reroll_button_state() -> void:
	if single_player_popup_refresh_button == null or !is_instance_valid(single_player_popup_refresh_button):
		return
	single_player_popup_refresh_button.set(
		"button_disabled",
		_single_player_theme_slot_animating or _single_player_theme_reroll_used
	)

func _reroll_single_player_theme_options(level_index: int, previous_options: Array) -> Array:
	var next_options: Array = []
	var require_fully_new_options: bool = Database.get_theme_count() >= previous_options.size() * 2
	var max_attempts: int = 16 if require_fully_new_options else 1
	for _attempt_index in range(max_attempts):
		GameState.reset_single_level_attempt(Database.current_language, level_index)
		_invalidate_single_player_level_cache()
		next_options = _single_player_level_theme_options(level_index)
		if !require_fully_new_options or _single_player_theme_options_are_fully_new(
			previous_options,
			next_options
		):
			break
	return next_options

func _single_player_theme_options_are_fully_new(
	previous_options: Array,
	next_options: Array
) -> bool:
	if previous_options.size() != next_options.size():
		return false
	for theme_variant: Variant in next_options:
		if previous_options.has(theme_variant):
			return false
	return true

func _single_player_theme_slot_opening_options(final_options: Array) -> Array:
	var opening_options: Array = []
	var theme_count: int = Database.get_theme_count()
	if theme_count <= 1:
		return final_options.duplicate()
	for option_index in range(final_options.size()):
		var final_theme: int = int(final_options[option_index])
		var start_theme: int = int(randi() % theme_count)
		var attempts: int = 0
		while start_theme == final_theme and attempts < theme_count * 2:
			start_theme = int(randi() % theme_count)
			attempts += 1
		opening_options.append(start_theme)
	return opening_options

func _schedule_single_player_theme_slot_opening_animation(
	level_index: int,
	previous_options: Array,
	next_options: Array,
	final_selected_theme: int = -1
) -> void:
	if (
		single_player_popup_stage_content == null
		or !is_instance_valid(single_player_popup_stage_content)
	):
		return
	# Hide the generated result before the popup entrance so the player never
	# sees the final cards flash before their reels begin.
	_prepare_single_player_theme_slot_animation_visuals(level_index)
	var popup_stage: Control = single_player_popup_stage_content
	var start_callable := Callable(
		self,
		"_start_single_player_theme_slot_animation"
	).bind(level_index, previous_options, next_options, final_selected_theme)
	if bool(popup_stage.get("open_bounce_complete")):
		start_callable.call()
		return
	if popup_stage.has_signal(&"open_bounce_finished"):
		popup_stage.connect(
			&"open_bounce_finished",
			start_callable,
			CONNECT_ONE_SHOT
		)
	else:
		# Compatibility fallback for a custom popup stage without the completion
		# signal. One deferred frame still prevents starting during construction.
		call_deferred(
			"_start_single_player_theme_slot_animation",
			level_index,
			previous_options,
			next_options,
			final_selected_theme
		)

func _prepare_single_player_theme_slot_animation_visuals(level_index: int) -> void:
	single_player_popup_selected_theme = -1
	_set_single_player_theme_panels_unselected(level_index)
	_set_single_player_theme_static_visuals_visible(false)
	if single_player_popup_refresh_button != null and is_instance_valid(single_player_popup_refresh_button):
		# Match the disabled treatment of the Play button while the reels and
		# their result bounce are still running.
		single_player_popup_refresh_button.set("button_disabled", true)
	if single_player_popup_play_button != null and is_instance_valid(single_player_popup_play_button):
		single_player_popup_play_button.set("button_disabled", true)

func _start_single_player_theme_slot_animation(
	level_index: int,
	previous_options: Array,
	next_options: Array,
	final_selected_theme: int = -1
) -> void:
	if (
		_single_player_theme_slot_animating
		or single_player_popup_stage_content == null
		or !is_instance_valid(single_player_popup_stage_content)
	):
		return
	_single_player_theme_slot_animating = true
	_single_player_theme_slot_final_selection = final_selected_theme
	_single_player_theme_slot_generation += 1
	var animation_generation: int = _single_player_theme_slot_generation
	_prepare_single_player_theme_slot_animation_visuals(level_index)

	var previous_content: Control = content
	content = single_player_popup_stage_content
	var theme_count: int = Database.get_theme_count()
	for reel_index in range(next_options.size()):
		var visual: Dictionary = _single_player_popup_theme_card_visuals[reel_index]
		var start_theme: int = int(previous_options[reel_index])
		var final_theme: int = int(next_options[reel_index])
		var sequence: Array = _single_player_theme_slot_sequence(
			start_theme,
			final_theme,
			reel_index,
			theme_count
		)
		var reel_data: Dictionary = _stage_single_player_theme_slot_reel(visual, sequence)
		var track := reel_data.get("track") as Control
		if track == null or !is_instance_valid(track):
			continue
		var distance: float = float(reel_data.get("distance", 0.0))
		var icon_step: float = float(reel_data.get("icon_step", 0.0))
		var duration: float = (
			PORTRAIT_SINGLE_PLAYER_SLOT_BASE_DURATION
			+ float(reel_index) * PORTRAIT_SINGLE_PLAYER_SLOT_DURATION_STEP
		)
		var settle_duration: float = minf(
			PORTRAIT_SINGLE_PLAYER_SLOT_LANDING_DURATION,
			duration * 0.05
		)
		# Accelerate hard into a much higher cruising speed, then keep that
		# speed until the selected icon reaches the center. Splitting the motion
		# this way makes the reel feel snappier without reducing the number of
		# themes that pass through the card.
		var settle_overshoot: float = minf(3.0, icon_step * 0.04)
		var spin_target: float = distance + settle_overshoot
		var acceleration_duration: float = minf(
			PORTRAIT_SINGLE_PLAYER_SLOT_ACCELERATION_DURATION,
			duration * 0.35
		)
		var cruise_duration: float = maxf(duration - acceleration_duration, 0.001)
		# For quadratic ease-in, this distance keeps the velocity continuous at
		# the transition from acceleration to the linear maximum-speed phase.
		var speed_denominator: float = maxf(
			duration - acceleration_duration * 0.5,
			0.001
		)
		var acceleration_distance: float = spin_target * (
			(acceleration_duration * 0.5) / speed_denominator
		)
		var tween: Tween = track.create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		var acceleration_tweener: PropertyTweener = tween.tween_property(
			track,
			"position",
			Vector2(0.0, acceleration_distance),
			acceleration_duration
		)
		acceleration_tweener.set_trans(Tween.TRANS_QUAD)
		acceleration_tweener.set_ease(Tween.EASE_IN)
		var cruise_tweener: PropertyTweener = tween.tween_property(
			track,
			"position",
			Vector2(0.0, spin_target),
			cruise_duration
		)
		cruise_tweener.set_trans(Tween.TRANS_LINEAR)
		cruise_tweener.set_ease(Tween.EASE_IN_OUT)
		var icon_below_final := reel_data.get("icon_below_final") as CanvasItem
		if icon_below_final != null and is_instance_valid(icon_below_final):
			tween.tween_callback(
				Callable(self, "_hide_single_player_theme_slot_icon").bind(
					icon_below_final
				)
			)
		var landing_tweener: PropertyTweener = tween.tween_property(
			track,
			"position",
			Vector2(0.0, distance),
			settle_duration
		)
		landing_tweener.set_trans(Tween.TRANS_CUBIC)
		landing_tweener.set_ease(Tween.EASE_OUT)
		_single_player_theme_slot_tweens.append(tween)
		if reel_index == next_options.size() - 1:
			tween.finished.connect(
				Callable(self, "_finish_single_player_theme_slot_animation").bind(
					level_index,
					animation_generation
				),
				CONNECT_ONE_SHOT
			)
	content = previous_content

func _single_player_theme_slot_sequence(
	start_theme: int,
	final_theme: int,
	reel_index: int,
	theme_count: int
) -> Array:
	var sequence: Array = [start_theme]
	if theme_count <= 0:
		sequence.append(final_theme)
		return sequence
	var spin_count: int = (
		PORTRAIT_SINGLE_PLAYER_SLOT_BASE_SPINS
		+ reel_index * PORTRAIT_SINGLE_PLAYER_SLOT_SPINS_PER_REEL
	)
	# Drop one redundant intermediate icon from the tail of every reel. It
	# shortens the wait and avoids the extra theme directly before the result.
	var intermediate_count: int = maxi(spin_count - 1, 0)
	var previous_theme: int = start_theme
	for spin_index in range(intermediate_count):
		var next_theme: int = int(randi() % theme_count)
		if theme_count > 1:
			var attempts: int = 0
			while (
				next_theme == previous_theme
				or (spin_index == intermediate_count - 1 and next_theme == final_theme)
			) and attempts < theme_count * 2:
				next_theme = int(randi() % theme_count)
				attempts += 1
		sequence.append(next_theme)
		previous_theme = next_theme
	sequence.append(final_theme)
	return sequence

func _stage_single_player_theme_slot_reel(
	visual: Dictionary,
	sequence: Array
) -> Dictionary:
	var card_rect: Rect2 = visual.get("card_rect", Rect2())
	# Clip the moving icons at the actual top and bottom edges of the whole
	# theme card. This keeps the reel visible throughout the complete card
	# instead of cutting it off inside a smaller icon-only viewport.
	var reel_rect := card_rect
	var reel_view: Control = _stage_holder(reel_rect, Control.MOUSE_FILTER_IGNORE)
	reel_view.name = "ThemeSlotReel"
	reel_view.clip_contents = true
	reel_view.z_index = 20
	_single_player_theme_slot_animation_nodes.append(reel_view)

	var track := Control.new()
	track.name = "ThemeSlotTrack"
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.position = Vector2.ZERO
	track.size = reel_rect.size
	reel_view.add_child(track)

	var icon_size := Vector2.ONE * PORTRAIT_SINGLE_PLAYER_THEME_CARD_ICON_SIZE
	var icon_step: float = icon_size.y + PORTRAIT_SINGLE_PLAYER_SLOT_ICON_GAP
	var icon_x: float = (reel_rect.size.x - icon_size.x) * 0.5
	# Match the authored resting position of the normal card icon so swapping
	# the reel for the final static icon is visually seamless.
	var icon_y: float = 35.0
	var icon_below_final: CanvasItem = null
	for sequence_index in range(sequence.size()):
		var theme_index: int = int(sequence[sequence_index])
		var texture: Texture2D = _theme_icon_texture(theme_index)
		if texture == null:
			continue
		var icon := TextureRect.new()
		icon.name = "ThemeSlotIcon%d" % sequence_index
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = texture
		# Keep the reel readable as motion rather than a stack of competing
		# images. The selected static icon returns to full opacity for bounce.
		icon.modulate = Color(1.0, 1.0, 1.0, PORTRAIT_SINGLE_PLAYER_SLOT_SPIN_ICON_ALPHA)
		icon.position = Vector2(icon_x, icon_y - float(sequence_index) * icon_step)
		icon.size = icon_size
		track.add_child(icon)
		if sequence_index == sequence.size() - 2:
			icon_below_final = icon
	return {
		"track": track,
		"distance": maxf(float(sequence.size() - 1) * icon_step, 0.0),
		"icon_step": icon_step,
		"icon_below_final": icon_below_final,
	}

func _hide_single_player_theme_slot_icon(icon: CanvasItem) -> void:
	if icon != null and is_instance_valid(icon):
		icon.visible = false

func _set_single_player_theme_static_visuals_visible(visible_value: bool) -> void:
	for visual_variant: Variant in _single_player_popup_theme_card_visuals:
		if !(visual_variant is Dictionary):
			continue
		var visual: Dictionary = visual_variant
		for key: String in ["theme_icon", "word_badge", "word_badge_label", "theme_label"]:
			var node := visual.get(key) as CanvasItem
			if node != null and is_instance_valid(node):
				node.visible = visible_value
		var theme_button := visual.get("theme_button") as Control
		if theme_button != null and is_instance_valid(theme_button):
			theme_button.mouse_filter = (
				Control.MOUSE_FILTER_STOP
				if visible_value
				else Control.MOUSE_FILTER_IGNORE
			)

func _set_single_player_theme_panels_unselected(level_index: int) -> void:
	var challenge_level: bool = _single_player_is_bonus_level(level_index)
	var fill_color: Color = (
		PORTRAIT_CHALLENGE_THEME_CARD
		if challenge_level
		else Color(0.30, 0.35, 0.68, 1.0)
	)
	var border_color: Color = (
		PORTRAIT_CHALLENGE_POPUP_HEADER
		if challenge_level
		else PORTRAIT_RULE
	)
	for panel_variant: Variant in single_player_popup_theme_panels.values():
		var panel := panel_variant as Control
		if panel == null or !is_instance_valid(panel):
			continue
		panel.set("fill_color", fill_color)
		panel.set("border_color", border_color)
		panel.set("border_width", 2.0)

func _finish_single_player_theme_slot_animation(
	level_index: int,
	animation_generation: int
) -> void:
	if (
		animation_generation != _single_player_theme_slot_generation
		or !_single_player_theme_slot_animating
	):
		return
	_single_player_theme_slot_tweens.clear()
	_clear_single_player_theme_slot_nodes()
	if (
		level_index != single_player_popup_level_index
		or single_player_popup_stage_content == null
		or !is_instance_valid(single_player_popup_stage_content)
	):
		_single_player_theme_slot_animating = false
		_single_player_theme_slot_final_selection = -1
		return
	var final_selected_theme: int = _single_player_theme_slot_final_selection
	_single_player_theme_slot_final_selection = -1
	_update_single_player_theme_popup(level_index)
	var current_options: Array = _single_player_level_theme_options(level_index)
	if final_selected_theme >= 0 and current_options.has(final_selected_theme):
		_select_single_player_popup_theme(level_index, final_selected_theme)
	_start_single_player_theme_slot_reveal(animation_generation)

func _start_single_player_theme_slot_reveal(animation_generation: int) -> void:
	if animation_generation != _single_player_theme_slot_generation:
		return
	var reveal_visuals: Array = []
	for visual_variant: Variant in _single_player_popup_theme_card_visuals:
		if !(visual_variant is Dictionary):
			continue
		var visual: Dictionary = visual_variant
		var theme_icon := visual.get("theme_icon") as Control
		var theme_label := visual.get("theme_label") as Control
		var badge_panel := visual.get("word_badge") as Control
		var badge_label := visual.get("word_badge_label") as Control

		if theme_icon != null and is_instance_valid(theme_icon):
			var icon_rest_position: Vector2 = theme_icon.position
			var icon_rest_scale: Vector2 = theme_icon.scale
			theme_icon.visible = true
			theme_icon.modulate = Color.WHITE
			theme_icon.set_meta(&"slot_reveal_rest_position", icon_rest_position)
			theme_icon.set_meta(&"slot_reveal_rest_scale", icon_rest_scale)
			# FlashStageTexture already carries the viewport fit scale. Moving the
			# pivot without compensating its position makes scaling pull the icon
			# toward a corner. This keeps the visual center fixed during bounce.
			theme_icon.pivot_offset = theme_icon.size * 0.5
			theme_icon.position = (
				icon_rest_position
				+ (icon_rest_scale - Vector2.ONE) * theme_icon.pivot_offset
			)
			theme_icon.scale = icon_rest_scale
			reveal_visuals.append(visual)

		# Names and counters stay hidden through the reel stop and the first
		# half of the icon bounce. Their fade begins at the maximum icon scale.
		if theme_label != null and is_instance_valid(theme_label):
			theme_label.visible = false
			theme_label.scale = Vector2.ONE
			theme_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
		if badge_panel != null and is_instance_valid(badge_panel):
			badge_panel.visible = false
			badge_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
		if badge_label != null and is_instance_valid(badge_label):
			badge_label.visible = false
			badge_label.scale = Vector2.ONE
			badge_label.modulate = Color(1.0, 1.0, 1.0, 0.0)

		var theme_button := visual.get("theme_button") as Control
		if theme_button != null and is_instance_valid(theme_button):
			theme_button.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if single_player_popup_play_button != null and is_instance_valid(single_player_popup_play_button):
		single_player_popup_play_button.set("button_disabled", true)
	if single_player_popup_refresh_button != null and is_instance_valid(single_player_popup_refresh_button):
		single_player_popup_refresh_button.set("button_disabled", true)

	if reveal_visuals.is_empty():
		_start_single_player_theme_slot_labels_reveal(animation_generation)
		return

	for visual_index in range(reveal_visuals.size()):
		var reveal_visual: Dictionary = reveal_visuals[visual_index]
		var theme_icon := reveal_visual.get("theme_icon") as Control
		if theme_icon == null or !is_instance_valid(theme_icon):
			continue
		var icon_rest_scale: Vector2 = theme_icon.get_meta(
			&"slot_reveal_rest_scale",
			theme_icon.scale
		)
		var reveal_delay: float = float(visual_index) * PORTRAIT_SINGLE_PLAYER_SLOT_REVEAL_STAGGER
		var reveal_tween: Tween = theme_icon.create_tween()
		reveal_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		if reveal_delay > 0.0:
			reveal_tween.tween_interval(reveal_delay)
		var icon_grow: PropertyTweener = reveal_tween.tween_property(
			theme_icon,
			"scale",
			icon_rest_scale * PORTRAIT_SINGLE_PLAYER_SLOT_REVEAL_PEAK_SCALE,
			PORTRAIT_SINGLE_PLAYER_SLOT_REVEAL_GROW_DURATION
		)
		icon_grow.set_trans(Tween.TRANS_QUAD)
		icon_grow.set_ease(Tween.EASE_OUT)
		var icon_settle: PropertyTweener = reveal_tween.tween_property(
			theme_icon,
			"scale",
			icon_rest_scale,
			PORTRAIT_SINGLE_PLAYER_SLOT_REVEAL_SETTLE_DURATION
		)
		icon_settle.set_trans(Tween.TRANS_BOUNCE)
		icon_settle.set_ease(Tween.EASE_OUT)
		_single_player_theme_slot_tweens.append(reveal_tween)

	# Start the text and counter fade exactly when the icons reach their maximum
	# scale. The fade then runs in parallel with the settling half of the bounce.
	var label_trigger_icon := reveal_visuals[0].get("theme_icon") as Control
	if label_trigger_icon == null or !is_instance_valid(label_trigger_icon):
		_start_single_player_theme_slot_labels_reveal(animation_generation)
		return
	var label_trigger_tween: Tween = label_trigger_icon.create_tween()
	label_trigger_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	label_trigger_tween.tween_interval(PORTRAIT_SINGLE_PLAYER_SLOT_REVEAL_GROW_DURATION)
	label_trigger_tween.tween_callback(
		Callable(self, "_start_single_player_theme_slot_labels_reveal").bind(
			animation_generation
		)
	)
	_single_player_theme_slot_tweens.append(label_trigger_tween)

func _start_single_player_theme_slot_labels_reveal(animation_generation: int) -> void:
	if animation_generation != _single_player_theme_slot_generation:
		return
	var fade_controls: Array[Control] = []
	for visual_variant: Variant in _single_player_popup_theme_card_visuals:
		if !(visual_variant is Dictionary):
			continue
		var visual: Dictionary = visual_variant
		var theme_label := visual.get("theme_label") as Control
		var badge_panel := visual.get("word_badge") as Control
		var badge_label := visual.get("word_badge_label") as Control
		for control_variant: Variant in [theme_label, badge_panel, badge_label]:
			var reveal_control := control_variant as Control
			if reveal_control != null and is_instance_valid(reveal_control):
				reveal_control.visible = true
				reveal_control.modulate = Color(1.0, 1.0, 1.0, 0.0)
				fade_controls.append(reveal_control)

	if fade_controls.is_empty():
		_finish_single_player_theme_slot_reveal(animation_generation)
		return
	var fade_owner: Control = fade_controls[0]
	var fade_tween: Tween = fade_owner.create_tween()
	fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_tween.set_parallel(true)
	for fade_control: Control in fade_controls:
		var fade: PropertyTweener = fade_tween.tween_property(
			fade_control,
			"modulate",
			Color.WHITE,
			PORTRAIT_SINGLE_PLAYER_SLOT_LABEL_FADE_DURATION
		)
		fade.set_trans(Tween.TRANS_SINE)
		fade.set_ease(Tween.EASE_OUT)
	_single_player_theme_slot_tweens.append(fade_tween)
	fade_tween.finished.connect(
		Callable(self, "_finish_single_player_theme_slot_reveal").bind(
			animation_generation
		),
		CONNECT_ONE_SHOT
	)

func _restore_single_player_theme_icon_bounce_transform(visual: Dictionary) -> void:
	var theme_icon := visual.get("theme_icon") as Control
	if theme_icon == null or !is_instance_valid(theme_icon):
		return
	var rest_position: Vector2 = theme_icon.get_meta(
		&"slot_reveal_rest_position",
		theme_icon.position
	)
	var rest_scale: Vector2 = theme_icon.get_meta(
		&"slot_reveal_rest_scale",
		theme_icon.scale
	)
	theme_icon.position = rest_position
	theme_icon.scale = rest_scale
	theme_icon.pivot_offset = Vector2.ZERO
	theme_icon.modulate = Color.WHITE
	theme_icon.remove_meta(&"slot_reveal_rest_position")
	theme_icon.remove_meta(&"slot_reveal_rest_scale")

func _finish_single_player_theme_slot_reveal(animation_generation: int) -> void:
	if animation_generation != _single_player_theme_slot_generation:
		return
	_single_player_theme_slot_animating = false
	_single_player_theme_slot_tweens.clear()
	for visual_variant: Variant in _single_player_popup_theme_card_visuals:
		if !(visual_variant is Dictionary):
			continue
		var visual: Dictionary = visual_variant
		_restore_single_player_theme_icon_bounce_transform(visual)
		var theme_label := visual.get("theme_label") as Control
		if theme_label != null and is_instance_valid(theme_label):
			theme_label.visible = true
			theme_label.scale = Vector2.ONE
			theme_label.modulate = Color.WHITE
			theme_label.pivot_offset = Vector2.ZERO
		var badge_panel := visual.get("word_badge") as Control
		if badge_panel != null and is_instance_valid(badge_panel):
			badge_panel.visible = true
			# Preserve the FlashStagePanel viewport-fit scale.
			badge_panel.modulate = Color.WHITE
		var badge_label := visual.get("word_badge_label") as Control
		if badge_label != null and is_instance_valid(badge_label):
			badge_label.visible = true
			badge_label.scale = Vector2.ONE
			badge_label.modulate = Color.WHITE
			badge_label.pivot_offset = Vector2.ZERO
		var theme_button := visual.get("theme_button") as Control
		if theme_button != null and is_instance_valid(theme_button):
			theme_button.mouse_filter = Control.MOUSE_FILTER_STOP
	if single_player_popup_play_button != null and is_instance_valid(single_player_popup_play_button):
		single_player_popup_play_button.set("button_disabled", false)
	_update_single_player_theme_reroll_button_state()

func _cancel_single_player_theme_slot_animation() -> void:
	_single_player_theme_slot_generation += 1
	_single_player_theme_slot_animating = false
	_single_player_theme_slot_final_selection = -1
	for tween: Tween in _single_player_theme_slot_tweens:
		if tween != null and tween.is_valid():
			tween.kill()
	_single_player_theme_slot_tweens.clear()
	_clear_single_player_theme_slot_nodes()

func _clear_single_player_theme_slot_nodes() -> void:
	for node: Node in _single_player_theme_slot_animation_nodes:
		if node != null and is_instance_valid(node):
			if node.get_parent() != null:
				node.get_parent().remove_child(node)
			node.queue_free()
	_single_player_theme_slot_animation_nodes.clear()

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

func _start_single_player_popup_level(level_index: int) -> void:
	if level_index != single_player_popup_level_index or single_player_popup_selected_theme < 0:
		return
	_single_player_theme_reroll_level_index = -1
	_single_player_theme_reroll_used = false
	super._start_single_player_popup_level(level_index)

func _show_exit_game_popup() -> void:
	# An in-place result has already been recorded and has no live progress left to
	# protect. The gameplay Back button therefore leaves immediately, matching the
	# device Back action, instead of asking for confirmation a second time.
	if (
		game_finished
		and (
			!last_result_is_win
			or GameState.current_mode != GameState.GameMode.SINGLE_PLAYER
		)
	):
		_result_back_action()
		return
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

func show_game_screen() -> void:
	# Only actual navigation into the active gameplay page gets the entrance
	# animation. Regular GameSession.changed rebuilds must stay visually stable.
	_portrait_game_entrance_pending = !game_finished
	super.show_game_screen()

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
	var keyboard_start_y: float = (PORTRAIT_FOOTER_Y - PORTRAIT_GAME_KEYBOARD_BOTTOM_RESERVE) - 24.0 - keyboard_height
	if GameState.current_mode == GameState.GameMode.TWO_PLAYER:
		keyboard_start_y += PORTRAIT_TWO_PLAYER_KEYBOARD_Y_OFFSET
	else:
		# Keyboard, word and hints share one bottom-attached block. Move the whole
		# block down together so the hint row sits closer to the AdMob reserve.
		keyboard_start_y += PORTRAIT_GAME_INPUT_BLOCK_DOWN_SHIFT
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
	# Keep the gameplay tree alive for the whole round. Guesses and hints update
	# only the controls whose state changed instead of recreating every node.
	if (
		_portrait_game_runtime_ready
		and _portrait_game_input_group != null
		and is_instance_valid(_portrait_game_input_group)
	):
		_refresh_portrait_game_runtime_state()
		return
	var restore_finished_round: bool = game_finished
	var play_game_entrance: bool = _portrait_game_entrance_pending and !restore_finished_round
	_portrait_game_entrance_pending = false
	_portrait_game_entrance_active = false
	_portrait_game_input_group = null
	_portrait_game_word_paper_mask = null
	_portrait_game_word_paper_layer = null
	_portrait_game_word_paper_backside = null
	_portrait_game_word_paper_backside_visual = null
	_portrait_game_word_slots_root = null
	_portrait_game_word_rect = Rect2()
	_portrait_game_keyboard_buttons.clear()
	_portrait_game_hint_buttons.clear()
	_portrait_game_hint_signature = ""
	_stop_portrait_attempts_attention_bounce(true)
	_portrait_game_attempts_controls.clear()
	_portrait_game_attempts_value_label = null
	if _portrait_game_attempts_roll_tween != null and _portrait_game_attempts_roll_tween.is_valid():
		_portrait_game_attempts_roll_tween.kill()
	_portrait_game_attempts_roll_tween = null
	if _portrait_game_attempts_roll_clip != null and is_instance_valid(_portrait_game_attempts_roll_clip):
		_portrait_game_attempts_roll_clip.queue_free()
	_portrait_game_attempts_roll_clip = null
	_portrait_game_attempts_displayed_value = -1
	_portrait_round_end_transition_active = false
	_portrait_round_end_bounce_started = false
	_portrait_inline_result_visible = false
	_portrait_inline_result_search_button = null
	_portrait_inline_result_word_holder = null
	_portrait_inline_result_title_label = null
	_portrait_inline_result_continue_button = null
	_portrait_in_place_result_active = false
	_portrait_in_place_result_is_win = false
	_capture_hero_animation_phase()
	for child: Node in content.get_children():
		content.remove_child(child)
		child.queue_free()

	var viewport_size: Vector2 = get_viewport_rect().size
	var extra_stage_height: float = PORTRAIT_STAGE_LAYOUT.extra_stage_height(viewport_size)
	var upper_block_shift: float = extra_stage_height * 0.5
	_portrait_screen(0.0, -1.0, _portrait_game_header_color())
	_stage_portrait_game_header()

	# Center the visible hangman character in the LEFT half of the gameplay area.
	# The imported symbol has a wide empty origin, so hero_stage_position below
	# compensates for it while hero_pivot represents the visual center.
	var hero_pivot := Vector2(PORTRAIT_GAME_HERO_LEFT_CENTER_X, 222.0 - PORTRAIT_GAME_HERO_Y_LIFT + upper_block_shift)
	var hero_stage_position := Vector2(
		hero_pivot.x - PORTRAIT_TWO_PLAYER_HERO_VISUAL_CENTER_OFFSET_X,
		238.0 - PORTRAIT_GAME_HERO_Y_LIFT + upper_block_shift
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
		hero_static_symbol.stage_scale_multiplier = PORTRAIT_GAME_HERO_SCALE_MULTIPLIER
	_configure_hero_static_animation()

	_portrait_end_adaptive_group(hero_root_content)

	# Keep the new text-only HUD beside the character, including the same extra
	# vertical shift used by the hero on taller portrait screens.
	_stage_portrait_game_info_text(upper_block_shift)

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

	# Word, keyboard and hints deliberately live in ONE bottom-attached group.
	# This makes the entire input cluster translate as a single unit on tall
	# screens instead of letting the hint row drift independently.
	var input_root_content: Control = _portrait_begin_bottom_attached_group()
	_portrait_game_input_group = content
	_portrait_game_word_rect = game_word_rect

	# Keep the paper and current word inside a clipping mask. During the round-end
	# page turn, the mask edge moves from left to right while the actual paper art
	# stays fixed in screen space. This reveals the solved word underneath without
	# shrinking or deforming the sheet.
	var word_paper_mask := Control.new()
	word_paper_mask.name = "PortraitGameWordPaperMask"
	word_paper_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	word_paper_mask.clip_contents = true
	word_paper_mask.z_index = 30
	content.add_child(word_paper_mask)
	word_paper_mask.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_portrait_game_word_paper_mask = word_paper_mask

	var word_paper_layer := Control.new()
	word_paper_layer.name = "PortraitGameWordPaperLayer"
	word_paper_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	word_paper_mask.add_child(word_paper_layer)
	word_paper_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_portrait_game_word_paper_layer = word_paper_layer
	var input_group_content: Control = content
	content = word_paper_layer
	_stage_portrait_game_word_display(game_word_rect, 34)
	content = input_group_content

	# The darker reverse side uses a fixed-width stage holder. Only the child
	# TextureRect scales on X around its LEFT edge. Resizing FlashStageTexture's
	# stage_rect used to re-stretch the entire wide source image every frame, which
	# made the fold look squashed instead of physically opening from the contact line.
	var backside_rect := Rect2(
		0.0,
		game_word_rect.position.y + PORTRAIT_GAME_WORD_PAPER_Y_OFFSET,
		PORTRAIT_ROUND_END_PAPER_BACKSIDE_MAX_WIDTH,
		PORTRAIT_GAME_WORD_PAPER_HEIGHT
	)
	var word_paper_backside := _stage_holder(backside_rect, Control.MOUSE_FILTER_IGNORE)
	word_paper_backside.z_index = 31
	word_paper_backside.visible = false
	_portrait_game_word_paper_backside = word_paper_backside

	var word_paper_backside_visual := TextureRect.new()
	word_paper_backside_visual.name = "PortraitGameWordPaperBacksideVisual"
	word_paper_backside_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	word_paper_backside_visual.texture = PORTRAIT_GAME_WORD_PAPER_BACKSIDE_TEXTURE
	word_paper_backside_visual.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	word_paper_backside_visual.stretch_mode = TextureRect.STRETCH_SCALE
	word_paper_backside.add_child(word_paper_backside_visual)
	# Keep the reverse-side texture at one authored local size. Its X transform is
	# then a literal horizontal scale around the fold line, independent from stage
	# rect remapping or anchor layout.
	word_paper_backside_visual.set_anchors_preset(Control.PRESET_TOP_LEFT)
	word_paper_backside_visual.position = Vector2.ZERO
	word_paper_backside_visual.size = Vector2(
		PORTRAIT_ROUND_END_PAPER_BACKSIDE_MAX_WIDTH,
		PORTRAIT_GAME_WORD_PAPER_HEIGHT
	)
	word_paper_backside_visual.custom_minimum_size = word_paper_backside_visual.size
	word_paper_backside_visual.pivot_offset = Vector2(0.0, PORTRAIT_GAME_WORD_PAPER_HEIGHT * 0.5)
	word_paper_backside_visual.scale = Vector2(0.0, 1.0)
	_portrait_game_word_paper_backside_visual = word_paper_backside_visual

	# Explicitly initialize the page-turn mask in its fully closed/front-facing
	# state. PRESET_FULL_RECT alone can still have a zero-sized clip rect during
	# the first layout pass, which made the normal paper and guessed word vanish.
	_set_portrait_word_paper_peel_progress(0.0)

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
		var key_button := _stage_letter_button(
			key_rect,
			Callable(self, "_press_letter").bind(letter),
			letter,
			state,
			!GameSession.is_active or state != StageLetterButton.LetterState.NORMAL,
			keyboard_font_size,
			marker_size,
			animate_state
		)
		_portrait_game_keyboard_buttons.append({
			"button": key_button,
			"letter": letter,
			"stage_x": x,
			"font_size": keyboard_font_size,
			"marker_size": marker_size,
			"state": state,
			"rest_disabled": !GameSession.is_active or state != StageLetterButton.LetterState.NORMAL,
		})
	if GameState.current_mode != GameState.GameMode.TWO_PLAYER:
		_stage_portrait_hint_buttons()
	_portrait_end_adaptive_group(input_root_content)

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
	_stage_portrait_admob_banner_placeholder()
	_portrait_game_runtime_ready = true
	call_deferred("_sync_portrait_attempts_attention_bounce")
	pending_letter_markers.clear()
	pending_letter_marker_is_correct = false
	if play_game_entrance:
		_prepare_portrait_game_entrance()
	if restore_finished_round:
		# Victory is restored with the same in-place presentation in every mode:
		# peel only the word paper, keep the gameplay composition, and color the
		# solved word green. Single Player used to restore a separate result layout.
		call_deferred("_show_in_place_round_result", last_result_is_win, false)

func _refresh_portrait_game_runtime_state() -> void:
	_refresh_portrait_attempts_value()
	_sync_portrait_attempts_attention_bounce()

	_rebuild_portrait_game_word_slots()
	_refresh_portrait_game_keyboard()
	_refresh_portrait_game_hints_if_needed()

	# Preserve one hero node across guesses. FlashStageSymbol already streams the
	# next pose in the background, so updating it is cheaper than rebuilding the
	# complete character hierarchy.
	_capture_hero_animation_phase()
	if hero_static_symbol != null and is_instance_valid(hero_static_symbol):
		hero_static_symbol.animation_time = _hero_animation_time()
		hero_static_symbol.nested_animation_time = _hero_nested_display_time()
		_configure_hero_static_animation()

	pending_letter_markers.clear()
	pending_letter_marker_is_correct = false

func _refresh_portrait_attempts_value() -> void:
	var attempts_label: Label = _portrait_game_attempts_value_label
	if attempts_label == null or !is_instance_valid(attempts_label):
		_portrait_game_attempts_displayed_value = GameSession.get_remaining_attempts()
		return
	var next_value: int = GameSession.get_remaining_attempts()
	if _portrait_game_attempts_displayed_value < 0:
		_portrait_game_attempts_displayed_value = next_value
		attempts_label.text = str(next_value)
		return
	if next_value == _portrait_game_attempts_displayed_value:
		return
	# Spending an attempt uses a mechanical-counter transition: the old digit
	# drops down while the new digit rolls in from above. Positive changes (for
	# example a purchased last-chance attempt) update immediately.
	if next_value > _portrait_game_attempts_displayed_value:
		if _portrait_game_attempts_roll_tween != null and _portrait_game_attempts_roll_tween.is_valid():
			_portrait_game_attempts_roll_tween.kill()
		_portrait_game_attempts_roll_tween = null
		if _portrait_game_attempts_roll_clip != null and is_instance_valid(_portrait_game_attempts_roll_clip):
			_portrait_game_attempts_roll_clip.queue_free()
		_portrait_game_attempts_roll_clip = null
		_portrait_game_attempts_displayed_value = next_value
		attempts_label.position = Vector2.ZERO
		attempts_label.visible = true
		attempts_label.text = str(next_value)
		return
	_play_portrait_attempts_counter_roll(next_value)

func _play_portrait_attempts_counter_roll(next_value: int) -> void:
	var old_label: Label = _portrait_game_attempts_value_label
	if old_label == null or !is_instance_valid(old_label):
		_portrait_game_attempts_displayed_value = next_value
		return
	var holder := old_label.get_parent() as Control
	if holder == null or !is_instance_valid(holder):
		old_label.text = str(next_value)
		_portrait_game_attempts_displayed_value = next_value
		return
	if _portrait_game_attempts_roll_tween != null and _portrait_game_attempts_roll_tween.is_valid():
		_portrait_game_attempts_roll_tween.kill()
	_portrait_game_attempts_roll_tween = null
	if _portrait_game_attempts_roll_clip != null and is_instance_valid(_portrait_game_attempts_roll_clip):
		_portrait_game_attempts_roll_clip.queue_free()
	_portrait_game_attempts_roll_clip = null
	old_label.visible = true
	_stop_portrait_attempts_attention_bounce(true)
	holder.clip_contents = false
	old_label.position = Vector2.ZERO
	old_label.scale = Vector2.ONE

	# Animate copies inside a temporary padded clipping window. The original
	# label never changes anchors/position, so after the roll the Attempts value
	# lands at exactly the same baseline it had before this animation existed.
	var roll_padding: float = 9.0
	var roll_clip := Control.new()
	roll_clip.name = "AttemptsMechanicalRollClip"
	roll_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	roll_clip.position = Vector2(0.0, -roll_padding)
	roll_clip.size = Vector2(holder.size.x, holder.size.y + roll_padding * 2.0)
	roll_clip.clip_contents = true
	roll_clip.z_index = old_label.z_index + 1
	holder.add_child(roll_clip)
	_portrait_game_attempts_roll_clip = roll_clip

	var old_roll_label := old_label.duplicate() as Label
	old_roll_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	old_roll_label.position = Vector2(0.0, roll_padding)
	old_roll_label.size = holder.size
	old_roll_label.scale = Vector2.ONE
	roll_clip.add_child(old_roll_label)

	var new_roll_label := old_label.duplicate() as Label
	new_roll_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	new_roll_label.text = str(next_value)
	new_roll_label.position = Vector2(0.0, -holder.size.y)
	new_roll_label.size = holder.size
	new_roll_label.scale = Vector2.ONE
	roll_clip.add_child(new_roll_label)
	old_label.visible = false

	var roll_distance: float = holder.size.y + roll_padding
	_portrait_game_attempts_roll_tween = roll_clip.create_tween()
	_portrait_game_attempts_roll_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var old_move := _portrait_game_attempts_roll_tween.parallel().tween_property(
		old_roll_label,
		"position:y",
		roll_padding + roll_distance,
		PORTRAIT_ATTEMPTS_COUNTER_ROLL_DURATION
	)
	old_move.set_trans(Tween.TRANS_CUBIC)
	old_move.set_ease(Tween.EASE_IN_OUT)
	var new_move := _portrait_game_attempts_roll_tween.parallel().tween_property(
		new_roll_label,
		"position:y",
		roll_padding,
		PORTRAIT_ATTEMPTS_COUNTER_ROLL_DURATION
	)
	new_move.set_trans(Tween.TRANS_CUBIC)
	new_move.set_ease(Tween.EASE_IN_OUT)
	_portrait_game_attempts_roll_tween.tween_callback(
		Callable(self, "_finish_portrait_attempts_counter_roll").bind(old_label, roll_clip, next_value)
	)

func _finish_portrait_attempts_counter_roll(old_label: Label, roll_clip: Control, next_value: int) -> void:
	if roll_clip != null and is_instance_valid(roll_clip):
		roll_clip.queue_free()
	_portrait_game_attempts_roll_clip = null
	if old_label != null and is_instance_valid(old_label):
		old_label.text = str(next_value)
		old_label.position = Vector2.ZERO
		old_label.scale = Vector2.ONE
		old_label.visible = true
		_portrait_game_attempts_value_label = old_label
	_portrait_game_attempts_displayed_value = next_value
	_portrait_game_attempts_roll_tween = null
	_sync_portrait_attempts_attention_bounce()

func _sync_portrait_attempts_attention_bounce() -> void:
	var attempts_label: Label = _portrait_game_attempts_value_label
	var remaining_attempts: int = GameSession.get_remaining_attempts()
	var should_bounce: bool = (
		attempts_label != null
		and is_instance_valid(attempts_label)
		and attempts_label.is_inside_tree()
		and GameSession.is_active
		and !game_finished
		and !_portrait_game_entrance_active
		and !_portrait_round_end_transition_active
		and !_portrait_in_place_result_active
		and (_portrait_game_attempts_roll_tween == null or !_portrait_game_attempts_roll_tween.is_valid())
		and remaining_attempts > 0
		and remaining_attempts <= PORTRAIT_ATTEMPTS_WARNING_THRESHOLD
	)
	if !should_bounce:
		_stop_portrait_attempts_attention_bounce(true)
		return
	if (
		_portrait_game_attempts_bounce_tween != null
		and _portrait_game_attempts_bounce_tween.is_valid()
	):
		return

	attempts_label.pivot_offset = attempts_label.size * 0.5
	attempts_label.scale = Vector2.ONE
	_portrait_game_attempts_bounce_tween = attempts_label.create_tween()
	_portrait_game_attempts_bounce_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_portrait_game_attempts_bounce_tween.set_loops()
	var grow_tweener: PropertyTweener = _portrait_game_attempts_bounce_tween.tween_property(
		attempts_label,
		"scale",
		PORTRAIT_ATTEMPTS_WARNING_BOUNCE_SCALE,
		PORTRAIT_ATTEMPTS_WARNING_BOUNCE_GROW_DURATION
	)
	grow_tweener.set_trans(Tween.TRANS_QUAD)
	grow_tweener.set_ease(Tween.EASE_OUT)
	var settle_tweener: PropertyTweener = _portrait_game_attempts_bounce_tween.tween_property(
		attempts_label,
		"scale",
		Vector2.ONE,
		PORTRAIT_ATTEMPTS_WARNING_BOUNCE_SETTLE_DURATION
	)
	settle_tweener.set_trans(Tween.TRANS_BACK)
	settle_tweener.set_ease(Tween.EASE_OUT)
	_portrait_game_attempts_bounce_tween.tween_interval(
		PORTRAIT_ATTEMPTS_WARNING_BOUNCE_PAUSE_DURATION
	)

func _stop_portrait_attempts_attention_bounce(reset_scale: bool) -> void:
	if (
		_portrait_game_attempts_bounce_tween != null
		and _portrait_game_attempts_bounce_tween.is_valid()
	):
		_portrait_game_attempts_bounce_tween.kill()
	_portrait_game_attempts_bounce_tween = null
	if (
		reset_scale
		and _portrait_game_attempts_value_label != null
		and is_instance_valid(_portrait_game_attempts_value_label)
	):
		_portrait_game_attempts_value_label.scale = Vector2.ONE

func _rebuild_portrait_game_word_slots() -> void:
	if (
		_portrait_game_word_slots_root == null
		or !is_instance_valid(_portrait_game_word_slots_root)
		or _portrait_game_word_rect.size.x <= 0.0
	):
		return
	for child: Node in _portrait_game_word_slots_root.get_children():
		_portrait_game_word_slots_root.remove_child(child)
		child.queue_free()
	var previous_content: Control = content
	content = _portrait_game_word_slots_root
	_stage_portrait_word_slots(_portrait_game_word_rect, 34, false, false)
	content = previous_content

func _refresh_portrait_game_keyboard() -> void:
	for entry_variant: Variant in _portrait_game_keyboard_buttons:
		var entry: Dictionary = entry_variant
		var button := entry.get("button") as StageLetterButton
		if button == null or !is_instance_valid(button):
			continue
		var letter: String = str(entry.get("letter", ""))
		var state: int = StageLetterButton.LetterState.NORMAL
		if GameSession.correct_letters.has(letter):
			state = StageLetterButton.LetterState.CIRCLED
		elif GameSession.wrong_letters.has(letter) or GameSession.removed_wrong_letters.has(letter):
			state = StageLetterButton.LetterState.CROSSED
		var disabled_value: bool = !GameSession.is_active or state != StageLetterButton.LetterState.NORMAL
		var animate_state: bool = (
			state != int(entry.get("state", StageLetterButton.LetterState.NORMAL))
			and pending_letter_markers.has(letter)
			and (
				(state == StageLetterButton.LetterState.CIRCLED and pending_letter_marker_is_correct)
				or (state == StageLetterButton.LetterState.CROSSED and !pending_letter_marker_is_correct)
			)
		)
		if state != int(entry.get("state", -1)) or disabled_value != bool(entry.get("rest_disabled", false)):
			var marker_size_value: Vector2 = entry.get("marker_size", Vector2(44.0, 44.0))
			button.configure(
				letter,
				state,
				int(entry.get("font_size", 29)),
				marker_size_value,
				disabled_value,
				animate_state
			)
			entry["state"] = state
			entry["rest_disabled"] = disabled_value

func _portrait_game_hint_state_signature() -> String:
	if GameState.current_mode == GameState.GameMode.TWO_PLAYER:
		return "two_player"
	return "%d:%d:%d:%d:%d:%d:%d:%d:%d:%d" % [
		int(GameSession.is_active),
		int(GameSession.open_hint_used),
		int(GameSession.remove_wrong_hint_used),
		int(GameSession.comment_hint_unlocked),
		GameState.get_hint_count(GameState.HINT_OPEN_LETTER),
		GameState.get_hint_count(GameState.HINT_REMOVE_WRONG),
		GameState.get_hint_count(GameState.HINT_COMMENT),
		int(GameSession.can_use_open_letter_hint()),
		int(GameSession.can_use_remove_wrong_hint()),
		int(GameSession.can_unlock_comment_hint()),
	]

func _refresh_portrait_game_hints_if_needed() -> void:
	if GameState.current_mode == GameState.GameMode.TWO_PLAYER:
		return
	var next_signature: String = _portrait_game_hint_state_signature()
	if _portrait_hint_counter_animation_active:
		_portrait_hint_counter_refresh_requested = true
		return
	if next_signature == _portrait_game_hint_signature:
		return
	for hint_button: Control in _portrait_game_hint_buttons:
		if hint_button == null or !is_instance_valid(hint_button):
			continue
		hint_button.visible = false
		hint_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hint_button.queue_free()
	_portrait_game_hint_buttons.clear()
	var previous_content: Control = content
	content = _portrait_game_input_group
	_stage_portrait_hint_buttons()
	content = previous_content
	_portrait_hint_counter_refresh_requested = false

func _portrait_game_hint_button_for_key(hint_key: String) -> Control:
	for hint_button: Control in _portrait_game_hint_buttons:
		if hint_button == null or !is_instance_valid(hint_button):
			continue
		if String(hint_button.get_meta(&"portrait_hint_key", "")) == hint_key:
			return hint_button
	return null

func _animate_portrait_hint_counter_roll(hint_key: String, from_count: int, to_count: int) -> void:
	var button: Control = _portrait_game_hint_button_for_key(hint_key)
	if button == null or !is_instance_valid(button):
		_portrait_hint_counter_animation_active = false
		if _portrait_hint_counter_refresh_requested:
			_refresh_portrait_game_hints_if_needed()
		return
	var holder: Control = button.get_meta(&"portrait_hint_counter_holder", null) as Control
	var current_label: Label = button.get_meta(&"portrait_hint_counter_label", null) as Label
	if holder == null or !is_instance_valid(holder) or current_label == null or !is_instance_valid(current_label):
		_portrait_hint_counter_animation_active = false
		if _portrait_hint_counter_refresh_requested:
			_refresh_portrait_game_hints_if_needed()
		return
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var next_label := _create_portrait_hint_counter_badge_label(holder, str(maxi(to_count, 0)))
	next_label.position = Vector2(0.0, -holder.size.y)
	next_label.modulate.a = 1.0
	var tween := holder.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var old_move := tween.parallel().tween_property(
		current_label,
		"position:y",
		holder.size.y,
		PORTRAIT_HINT_COUNTER_ROLL_DURATION
	)
	old_move.set_trans(Tween.TRANS_CUBIC)
	old_move.set_ease(Tween.EASE_IN_OUT)
	var new_move := tween.parallel().tween_property(
		next_label,
		"position:y",
		0.0,
		PORTRAIT_HINT_COUNTER_ROLL_DURATION
	)
	new_move.set_trans(Tween.TRANS_CUBIC)
	new_move.set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(Callable(self, "_finish_portrait_hint_counter_roll").bind(button, current_label, next_label))

func _finish_portrait_hint_counter_roll(button: Control, old_label: Label, new_label: Label) -> void:
	if old_label != null and is_instance_valid(old_label):
		old_label.queue_free()
	if button != null and is_instance_valid(button) and new_label != null and is_instance_valid(new_label):
		button.set_meta(&"portrait_hint_counter_label", new_label)
	_portrait_hint_counter_animation_active = false
	if _portrait_hint_counter_refresh_requested:
		_refresh_portrait_game_hints_if_needed()

func _play_portrait_hint_spend_animation_if_needed(
	hint_key: String,
	previous_count: int,
	current_count: int
) -> void:
	if previous_count <= 0 or current_count >= previous_count:
		return
	_portrait_hint_counter_animation_active = true
	_portrait_hint_counter_refresh_requested = false
	_animate_portrait_hint_counter_roll(hint_key, previous_count, current_count)

func _stage_portrait_admob_banner_placeholder() -> void:
	# Reserve a real 320×50 mobile-banner slot at the physical bottom. The named
	# holder can later be used as the anchor/registration point for the AdMob view.
	var banner_slot := _stage_holder(PORTRAIT_ADMOB_BANNER_RECT, Control.MOUSE_FILTER_IGNORE)
	banner_slot.name = "AdMobBannerSlot"
	banner_slot.add_to_group(&"admob_banner_slot")
	banner_slot.z_index = 30
	var banner_panel := _stage_panel(
		PORTRAIT_ADMOB_BANNER_RECT,
		Color(0.97, 0.97, 0.98, 1.0),
		0.0,
		Color(0.72, 0.75, 0.82, 1.0),
		1.0
	)
	banner_panel.z_index = 30
	var banner_label := _stage_label(
		PORTRAIT_ADMOB_BANNER_RECT,
		"ADMOB 320×50",
		12,
		Color(0.43, 0.46, 0.54, 1.0),
		HORIZONTAL_ALIGNMENT_CENTER
	)
	banner_label.add_theme_font_override("font", UI_PRIMARY_FONT)
	banner_label.z_index = 31

func _stage_portrait_game_word_paper(rect: Rect2) -> void:
	# Use the restored cream/yellow torn paper strip as a single full-width asset.
	# It intentionally overflows beyond the left/right screen edges so the ends
	# are clipped by the viewport and only the central paper body is visible.
	var paper_rect := Rect2(
		-PORTRAIT_GAME_WORD_PAPER_SCREEN_OVERFLOW_X,
		rect.position.y + PORTRAIT_GAME_WORD_PAPER_Y_OFFSET,
		PORTRAIT_STAGE_SIZE.x + PORTRAIT_GAME_WORD_PAPER_SCREEN_OVERFLOW_X * 2.0,
		PORTRAIT_GAME_WORD_PAPER_HEIGHT
	)
	var paper_texture := _stage_texture(paper_rect, PORTRAIT_GAME_WORD_PAPER_TEXTURE)
	paper_texture.z_index = -2

func _stage_portrait_game_word_display(rect: Rect2, font_size: int = 34) -> void:
	_stage_portrait_game_word_paper(rect)
	var slots_root := Control.new()
	slots_root.name = "PortraitGameWordSlots"
	slots_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(slots_root)
	slots_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_portrait_game_word_slots_root = slots_root
	var previous_content: Control = content
	content = slots_root
	_stage_portrait_word_slots(rect, font_size, false, false)
	content = previous_content

func _stage_portrait_result_word_display(
	rect: Rect2,
	continue_button: Control,
	continue_text: Control,
	animate_result: bool
) -> Dictionary:
	var reserved_width: float = (
		PORTRAIT_RESULT_SEARCH_BUTTON_SIZE
		+ PORTRAIT_RESULT_WORD_SEARCH_GAP
		+ PORTRAIT_RESULT_SEARCH_SAFE_MARGIN
	)
	# The result is a single shaped line, so the font controls glyph advances and
	# kerning. The search button is appended after the measured text without
	# participating in the answer's centering.
	var word_width: float = minf(
		rect.size.x,
		PORTRAIT_STAGE_SIZE.x - reserved_width * 2.0
	)
	var word_rect := Rect2(
		Vector2(
			(PORTRAIT_STAGE_SIZE.x - word_width) * 0.5,
			rect.position.y + PORTRAIT_RESULT_WORD_Y_OFFSET
		),
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
	var result_font_variation := FontVariation.new()
	result_font_variation.base_font = UI_HEADING_FONT
	result_font_variation.set("spacing_glyph", PORTRAIT_RESULT_LETTER_SPACING)
	word_label.add_theme_font_override("normal_font", result_font_variation)
	word_label.add_theme_color_override("default_color", PORTRAIT_BLUE)
	word_holder.add_child(word_label)

	var result_font: Font = result_font_variation
	var result_font_size: int = 34
	var measured_word_width: float = result_font.get_string_size(
		word_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		result_font_size
	).x
	if measured_word_width > word_width:
		result_font_size = maxi(
			12,
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
	return {
		"word_holder": word_holder,
		"word_label": word_label,
		"search_button": search_button,
	}

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

func _portrait_game_hint_y() -> float:
	var keyboard_metrics: Dictionary = _portrait_game_keyboard_metrics(get_viewport_rect().size)
	var alphabet_count: int = Database.get_alphabet().size()
	var columns: int = int(keyboard_metrics["columns"])
	var keyboard_rows: int = int(ceil(float(alphabet_count) / float(columns)))
	var keyboard_key_size: Vector2 = keyboard_metrics["key_size"]
	var keyboard_bottom_y: float = (
		float(keyboard_metrics["start_y"])
		+ float(maxi(keyboard_rows - 1, 0)) * float(keyboard_metrics["step_y"])
		+ keyboard_key_size.y
	)
	return keyboard_bottom_y + PORTRAIT_GAME_HINT_KEYBOARD_GAP

func _portrait_in_place_result_button_rect() -> Rect2:
	var button_y: float = minf(
		_portrait_game_hint_y(),
		PORTRAIT_ADMOB_BANNER_RECT.position.y - PORTRAIT_GAME_RETRY_BUTTON_SIZE.y - 12.0
	)
	return Rect2(
		Vector2(
			(PORTRAIT_STAGE_SIZE.x - PORTRAIT_GAME_RETRY_BUTTON_SIZE.x) * 0.5,
			button_y
		),
		PORTRAIT_GAME_RETRY_BUTTON_SIZE
	)

func _portrait_reward_continue_button_rect() -> Rect2:
	return Rect2(
		Vector2(
			(PORTRAIT_STAGE_SIZE.x - PORTRAIT_GAME_RETRY_BUTTON_SIZE.x) * 0.5,
			PORTRAIT_ADMOB_BANNER_RECT.position.y - PORTRAIT_GAME_RETRY_BUTTON_SIZE.y - 12.0
		),
		PORTRAIT_GAME_RETRY_BUTTON_SIZE
	)

func _portrait_stage_point_to_viewport(stage_point: Vector2, reference_node: Node = null) -> Vector2:
	var viewport_size: Vector2 = get_viewport_rect().size
	var fit_scale: float = PORTRAIT_STAGE_LAYOUT.fit_scale(viewport_size)
	var mapped_position: Vector2 = PORTRAIT_STAGE_LAYOUT.map_rect_position(
		Rect2(stage_point, Vector2.ZERO),
		viewport_size,
		reference_node
	)
	return Vector2(PORTRAIT_STAGE_LAYOUT.horizontal_offset(viewport_size), 0.0) + mapped_position * fit_scale

func _stage_portrait_hint_buttons() -> void:
	# Called while the shared game-input bottom group is active. Badges are
	# children of the buttons, so keyboard + hints + badges translate together.
	var open_hint_used: bool = GameSession.open_hint_used
	var remove_hint_used: bool = GameSession.remove_wrong_hint_used
	var comment_unlocked: bool = GameSession.comment_hint_unlocked
	var round_inactive: bool = !GameSession.is_active
	var open_hint_disabled: bool = round_inactive or open_hint_used or !GameSession.can_use_open_letter_hint()
	var remove_hint_disabled: bool = round_inactive or remove_hint_used or !GameSession.can_use_remove_wrong_hint()
	var comment_disabled: bool = round_inactive or (!comment_unlocked and !GameSession.can_unlock_comment_hint())

	# Place the hint row directly after the last keyboard row. Both controls live
	# in bottom-attached coordinate space, so this gap stays stable on tall phones.
	var hint_y: float = _portrait_game_hint_y()
	var open_rect := Rect2(
		Vector2(PORTRAIT_GAME_HINT_OPEN_BUTTON_RECT.position.x, hint_y),
		PORTRAIT_GAME_HINT_OPEN_BUTTON_RECT.size
	)
	var remove_rect := Rect2(
		Vector2(PORTRAIT_GAME_HINT_REMOVE_BUTTON_RECT.position.x, hint_y),
		PORTRAIT_GAME_HINT_REMOVE_BUTTON_RECT.size
	)
	var comment_rect := Rect2(
		Vector2(PORTRAIT_GAME_HINT_COMMENT_BUTTON_RECT.position.x, hint_y),
		PORTRAIT_GAME_HINT_COMMENT_BUTTON_RECT.size
	)

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

	_portrait_game_hint_buttons.clear()
	open_button.set_meta(&"portrait_hint_key", GameState.HINT_OPEN_LETTER)
	remove_button.set_meta(&"portrait_hint_key", GameState.HINT_REMOVE_WRONG)
	comment_button.set_meta(&"portrait_hint_key", GameState.HINT_COMMENT)
	_portrait_game_hint_buttons.append(open_button)
	_portrait_game_hint_buttons.append(remove_button)
	_portrait_game_hint_buttons.append(comment_button)

	_stage_portrait_hint_art(open_button, PORTRAIT_HINT_REVEAL_LETTER_ICON, open_hint_used)
	_stage_portrait_hint_art(remove_button, PORTRAIT_HINT_REMOVE_WRONG_ICON, remove_hint_used)
	_stage_portrait_hint_art(
		comment_button,
		PORTRAIT_HINT_COMMENT_UNLOCK_ICON,
		false,
		PORTRAIT_GAME_HINT_COMMENT_ART_Y_OFFSET
	)

	# Prices and inventory badges only describe actions that still consume a hint.
	# Used one-shot hints use the shared gray disabled state without a stale badge;
	# the unlocked comment remains a regular free blue action.
	if !open_hint_used:
		_stage_portrait_hint_counter(open_button, GameState.HINT_OPEN_LETTER)
	if !remove_hint_used:
		_stage_portrait_hint_counter(remove_button, GameState.HINT_REMOVE_WRONG)
	if !comment_unlocked:
		_stage_portrait_hint_counter(comment_button, GameState.HINT_COMMENT)
	_portrait_game_hint_signature = _portrait_game_hint_state_signature()

func _stage_portrait_hint_art(
	button: Control,
	texture: Texture2D,
	grayscale: bool = false,
	y_offset: float = 0.0
) -> void:
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
		-PORTRAIT_GAME_HINT_ART_RISE + y_offset
	)
	if grayscale:
		var grayscale_material := ShaderMaterial.new()
		grayscale_material.shader = PORTRAIT_HINT_USED_GRAYSCALE_SHADER
		art.material = grayscale_material
	art.z_index = 4
	button.add_child(art)

func _portrait_hint_local_panel(
	button: Control,
	local_rect: Rect2,
	fill_color: Color,
	corner_radius: float,
	border_color: Color = Color.TRANSPARENT,
	border_width: float = 0.0
) -> Panel:
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.position = local_rect.position
	panel.size = local_rect.size
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	var radius: int = int(round(corner_radius))
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	if border_width > 0.0:
		var resolved_border_width: int = maxi(1, int(round(border_width)))
		style.border_color = border_color
		style.border_width_left = resolved_border_width
		style.border_width_top = resolved_border_width
		style.border_width_right = resolved_border_width
		style.border_width_bottom = resolved_border_width
	panel.add_theme_stylebox_override("panel", style)
	panel.z_index = 8
	button.add_child(panel)
	return panel

func _portrait_hint_local_label(
	parent: Control,
	text: String,
	font_size: int,
	color: Color,
	align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER
) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.text = text
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", UI_PRIMARY_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.z_index = 1
	parent.add_child(label)
	return label

func _style_portrait_hint_counter_badge_label(label: Label) -> void:
	var counter_effect_color := Color(
		PORTRAIT_DARK_BLUE.r,
		PORTRAIT_DARK_BLUE.g,
		PORTRAIT_DARK_BLUE.b,
		0.55
	)
	label.add_theme_color_override("font_outline_color", counter_effect_color)
	label.add_theme_constant_override("outline_size", 1)
	label.add_theme_color_override("font_shadow_color", counter_effect_color)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.add_theme_constant_override("shadow_outline_size", 0)

func _create_portrait_hint_counter_badge_label(parent: Control, text: String) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.position = Vector2.ZERO
	label.size = parent.size
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", UI_PRIMARY_FONT)
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.z_index = 1
	parent.add_child(label)
	_style_portrait_hint_counter_badge_label(label)
	return label

func _stage_portrait_hint_counter(button: Control, hint_key: String) -> void:
	if button == null or !is_instance_valid(button):
		return
	var count: int = GameState.get_hint_count(hint_key)
	if count <= 0:
		_stage_portrait_hint_price(button, GameState.get_hint_cost(hint_key))
		return
	var badge_size := Vector2(PORTRAIT_GAME_HINT_COUNTER_SIZE, PORTRAIT_GAME_HINT_COUNTER_SIZE)
	var badge_rect := Rect2(
		Vector2(
			button.size.x - badge_size.x * 0.82,
			-badge_size.y * 0.18
		),
		badge_size
	)
	var badge := _portrait_hint_local_panel(
		button,
		badge_rect,
		PORTRAIT_DARK_BLUE,
		badge_size.x * 0.5
	)
	var holder := Control.new()
	holder.name = "HintCounterHolder"
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.position = Vector2.ZERO
	holder.size = badge.size
	holder.clip_contents = true
	badge.add_child(holder)
	var counter_label := _create_portrait_hint_counter_badge_label(holder, str(maxi(count, 0)))
	button.set_meta(&"portrait_hint_counter_badge", badge)
	button.set_meta(&"portrait_hint_counter_holder", holder)
	button.set_meta(&"portrait_hint_counter_label", counter_label)

func _stage_portrait_hint_price(button: Control, price: int) -> void:
	if button == null or !is_instance_valid(button):
		return
	var badge_size := Vector2(58.0, PORTRAIT_GAME_HINT_COUNTER_SIZE)
	var badge_rect := Rect2(
		Vector2(
			button.size.x - badge_size.x * 0.82,
			-badge_size.y * 0.18
		),
		badge_size
	)
	var badge := _portrait_hint_local_panel(
		button,
		badge_rect,
		PORTRAIT_DARK_BLUE,
		badge_size.y * 0.5,
		Color(0.72, 0.77, 0.91, 1.0),
		1.5
	)
	var coin_icon := TextureRect.new()
	coin_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coin_icon.texture = SOFT_CURRENCY_COIN_TEXTURE
	coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin_icon.position = Vector2(2.0, 2.0)
	coin_icon.size = Vector2(24.0, 24.0)
	coin_icon.z_index = 1
	badge.add_child(coin_icon)
	var price_label := Label.new()
	price_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	price_label.position = Vector2(25.0, 0.0)
	price_label.size = Vector2(badge_size.x - 27.0, badge_size.y)
	price_label.text = str(maxi(price, 0))
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	price_label.add_theme_font_override("font", UI_PRIMARY_FONT)
	price_label.add_theme_font_size_override("font_size", 16)
	price_label.add_theme_color_override("font_color", _purchase_price_color(price))
	price_label.z_index = 1
	badge.add_child(price_label)

func _create_hero_animation_overlay() -> FlashStageSymbol:
	var overlay := FlashStageSymbol.new()
	overlay.name = "HeroAnimationOverlay"
	overlay.z_index = 150
	overlay.hero_type = _hero_type()
	overlay.stage_position = _portrait_game_hero_stage_position
	overlay.stage_scale_multiplier = PORTRAIT_GAME_HERO_SCALE_MULTIPLIER
	overlay.animation_time = _hero_animation_time()
	if _portrait_game_adaptive_group != null and is_instance_valid(_portrait_game_adaptive_group):
		_portrait_game_adaptive_group.add_child(overlay)
	else:
		add_child(overlay)
	return overlay

func _prepare_portrait_game_entrance() -> void:
	_portrait_game_entrance_active = true
	# Entrance has its own page-turn state. Do not run the round-end peel formula
	# backwards: the reverse-side fold has a different width curve while the sheet
	# is being laid back down. Start with the face completely masked.
	_set_portrait_word_paper_entrance_progress(0.0)
	# The character joins the same opening choreography through a simple fade.
	# Keep its stage transform untouched so only opacity changes.
	if hero_static_symbol != null and is_instance_valid(hero_static_symbol):
		hero_static_symbol.modulate.a = 0.0
	# Attempts should not be visible during the opening choreography. They appear
	# only after both the paper and keyboard have completed their entrance.
	for attempts_control: Control in _portrait_game_attempts_controls:
		if attempts_control == null or !is_instance_valid(attempts_control):
			continue
		attempts_control.visible = false
		attempts_control.modulate.a = 0.0
	for entry_variant: Variant in _portrait_game_keyboard_buttons:
		var entry: Dictionary = entry_variant
		var button := entry.get("button") as Control
		if button == null or !is_instance_valid(button):
			continue
		var rest_visual_scale: Vector2 = button.get("visual_scale")
		button.set_meta(&"portrait_entrance_rest_visual_scale", rest_visual_scale)
		button.set_meta(&"portrait_entrance_rest_mouse_filter", button.mouse_filter)
		button.modulate.a = 0.0
		# `disabled = true` resets visual_scale through the shared press-state
		# handler. Apply the enlarged entrance scale only AFTER blocking input so
		# the first visible frame is the exact reverse of the round-end animation.
		button.set("disabled", true)
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.set("visual_scale", rest_visual_scale * PORTRAIT_ROUND_END_KEY_SCALE)

	# Hints must not flash in before the keyboard entrance. Keep their authored
	# disabled/click state, but render them only after the final keyboard key has
	# settled, using a short bounce.
	for hint_button: Control in _portrait_game_hint_buttons:
		if hint_button == null or !is_instance_valid(hint_button):
			continue
		var rest_hint_scale: Vector2 = hint_button.get("visual_scale")
		hint_button.set_meta(&"portrait_entrance_rest_visual_scale", rest_hint_scale)
		hint_button.set_meta(&"portrait_entrance_rest_mouse_filter", hint_button.mouse_filter)
		hint_button.set_meta(&"portrait_entrance_rest_disabled", bool(hint_button.get("disabled")))
		hint_button.modulate.a = 0.0
		hint_button.set(
			"visual_scale",
			rest_hint_scale * PORTRAIT_GAME_HINT_ENTRANCE_START_SCALE
		)
		hint_button.set("disabled", true)
		hint_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	call_deferred("_play_portrait_game_entrance")

func _play_portrait_game_entrance() -> void:
	if !_portrait_game_entrance_active or !game_screen_visible or game_finished:
		return
	var entrance_start_delay: float = PORTRAIT_GAME_ENTRANCE_START_DELAY / PORTRAIT_GAME_ENTRANCE_SPEED_MULTIPLIER
	var paper_duration: float = PORTRAIT_ROUND_END_PAPER_FLIP_DURATION / PORTRAIT_GAME_ENTRANCE_SPEED_MULTIPLIER
	var key_wave_duration: float = PORTRAIT_ROUND_END_KEY_WAVE_DURATION / PORTRAIT_GAME_ENTRANCE_SPEED_MULTIPLIER
	var key_fade_duration: float = PORTRAIT_ROUND_END_KEY_FADE_DURATION / PORTRAIT_GAME_ENTRANCE_SPEED_MULTIPLIER
	if hero_static_symbol != null and is_instance_valid(hero_static_symbol):
		hero_static_symbol.modulate.a = 0.0
		var hero_tween := hero_static_symbol.create_tween()
		hero_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		if entrance_start_delay > 0.0:
			hero_tween.tween_interval(entrance_start_delay)
		var hero_fade := hero_tween.tween_property(
			hero_static_symbol,
			"modulate:a",
			1.0,
			PORTRAIT_GAME_HERO_ENTRANCE_FADE_DURATION / PORTRAIT_GAME_ENTRANCE_SPEED_MULTIPLIER
		)
		hero_fade.set_trans(Tween.TRANS_QUAD)
		hero_fade.set_ease(Tween.EASE_OUT)
	var paper_tween := create_tween()
	paper_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if entrance_start_delay > 0.0:
		paper_tween.tween_interval(entrance_start_delay)
	var paper_reveal := paper_tween.tween_method(
		Callable(self, "_set_portrait_word_paper_entrance_progress"),
		0.0,
		1.0,
		paper_duration
	)
	paper_reveal.set_trans(Tween.TRANS_QUAD)
	paper_reveal.set_ease(Tween.EASE_IN_OUT)

	var valid_buttons: Array = []
	var min_x: float = INF
	var max_x: float = -INF
	for entry_variant: Variant in _portrait_game_keyboard_buttons:
		var entry: Dictionary = entry_variant
		var button := entry.get("button") as Control
		if button == null or !is_instance_valid(button):
			continue
		var stage_x: float = float(entry.get("stage_x", 0.0))
		valid_buttons.append(entry)
		min_x = minf(min_x, stage_x)
		max_x = maxf(max_x, stage_x)
	var x_range: float = maxf(max_x - min_x, 1.0)
	var latest_key_finish: float = 0.0
	for entry_variant: Variant in valid_buttons:
		var entry: Dictionary = entry_variant
		var button := entry.get("button") as Control
		var stage_x: float = float(entry.get("stage_x", 0.0))
		# True reverse of the exit wave: the rightmost keys return first.
		var delay: float = entrance_start_delay + (
			(max_x - stage_x) / x_range
		) * key_wave_duration
		latest_key_finish = maxf(
			latest_key_finish,
			delay + key_fade_duration
		)
		var rest_visual_scale: Vector2 = button.get_meta(
			&"portrait_entrance_rest_visual_scale",
			Vector2.ONE
		)
		var alpha_tween := button.create_tween()
		alpha_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		alpha_tween.tween_interval(delay)
		var alpha_tweener := alpha_tween.tween_property(
			button,
			"modulate:a",
			1.0,
			key_fade_duration
		)
		alpha_tweener.set_trans(Tween.TRANS_QUAD)
		alpha_tweener.set_ease(Tween.EASE_OUT)
		var scale_tween := button.create_tween()
		scale_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		scale_tween.tween_interval(delay)
		var scale_tweener := scale_tween.tween_property(
			button,
			"visual_scale",
			rest_visual_scale,
			key_fade_duration
		)
		# Mirror the disappearance scale tween: enlarged -> normal without an
		# overshoot, while alpha rises on the same per-key wave.
		scale_tweener.set_trans(Tween.TRANS_QUAD)
		scale_tweener.set_ease(Tween.EASE_OUT)

	# Attempts join the entrance from its first visible frame instead of popping in
	# after the keyboard/paper have finished. Keep the same tiny start delay as the
	# core choreography and fade the complete pill in as those animations begin.
	var attempts_fade_duration: float = (
		PORTRAIT_ROUND_END_ATTEMPTS_FADE_DURATION
		/ PORTRAIT_GAME_ENTRANCE_SPEED_MULTIPLIER
	)
	for attempts_control: Control in _portrait_game_attempts_controls:
		if attempts_control == null or !is_instance_valid(attempts_control):
			continue
		attempts_control.visible = true
		attempts_control.modulate.a = 0.0
		var attempts_tween := attempts_control.create_tween()
		attempts_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		if entrance_start_delay > 0.0:
			attempts_tween.tween_interval(entrance_start_delay)
		var attempts_fade := attempts_tween.tween_property(
			attempts_control,
			"modulate:a",
			1.0,
			attempts_fade_duration
		)
		attempts_fade.set_trans(Tween.TRANS_QUAD)
		attempts_fade.set_ease(Tween.EASE_OUT)

	var core_entrance_finish: float = maxf(
		entrance_start_delay + paper_duration,
		latest_key_finish
	)

	# Hints enter only after the keyboard wave has completely settled.
	var hint_tween := create_tween()
	hint_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if latest_key_finish > 0.0:
		hint_tween.tween_interval(latest_key_finish)
	hint_tween.tween_callback(Callable(self, "_play_portrait_game_hint_entrance_bounce"))

	var hint_finish: float = (
		latest_key_finish
		+ PORTRAIT_GAME_HINT_ENTRANCE_GROW_DURATION
		+ PORTRAIT_GAME_HINT_ENTRANCE_SETTLE_DURATION
	)
	var entrance_finish: float = maxf(
		core_entrance_finish,
		hint_finish
	)
	var finish_tween := create_tween()
	finish_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	finish_tween.tween_interval(entrance_finish)
	finish_tween.tween_callback(Callable(self, "_finish_portrait_game_entrance"))

func _play_portrait_game_hint_entrance_bounce() -> void:
	if !_portrait_game_entrance_active:
		return
	for hint_button: Control in _portrait_game_hint_buttons:
		if hint_button == null or !is_instance_valid(hint_button):
			continue
		var rest_scale: Vector2 = hint_button.get_meta(
			&"portrait_entrance_rest_visual_scale",
			Vector2.ONE
		)
		# Restore the authored gameplay visual state before the bounce. Input stays
		# blocked by MOUSE_FILTER_IGNORE until the entrance finishes, so an available
		# hint no longer bounces in using the temporary gray disabled skin.
		hint_button.set(
			"disabled",
			bool(hint_button.get_meta(&"portrait_entrance_rest_disabled", false))
		)
		hint_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hint_button.visible = true
		hint_button.modulate.a = 0.0
		var alpha_tween := hint_button.create_tween()
		alpha_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		alpha_tween.tween_property(
			hint_button,
			"modulate:a",
			1.0,
			PORTRAIT_GAME_HINT_ENTRANCE_GROW_DURATION
		)
		var bounce_tween := hint_button.create_tween()
		bounce_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		var grow := bounce_tween.tween_property(
			hint_button,
			"visual_scale",
			rest_scale * PORTRAIT_GAME_HINT_ENTRANCE_PEAK_SCALE,
			PORTRAIT_GAME_HINT_ENTRANCE_GROW_DURATION
		)
		grow.set_trans(Tween.TRANS_BACK)
		grow.set_ease(Tween.EASE_OUT)
		var settle := bounce_tween.tween_property(
			hint_button,
			"visual_scale",
			rest_scale,
			PORTRAIT_GAME_HINT_ENTRANCE_SETTLE_DURATION
		)
		settle.set_trans(Tween.TRANS_BOUNCE)
		settle.set_ease(Tween.EASE_OUT)

func _finish_portrait_game_entrance() -> void:
	if !_portrait_game_entrance_active:
		return
	_set_portrait_word_paper_peel_progress(0.0)
	if hero_static_symbol != null and is_instance_valid(hero_static_symbol):
		hero_static_symbol.modulate.a = 1.0
	for attempts_control: Control in _portrait_game_attempts_controls:
		if attempts_control == null or !is_instance_valid(attempts_control):
			continue
		attempts_control.visible = true
		attempts_control.modulate.a = 1.0
	for entry_variant: Variant in _portrait_game_keyboard_buttons:
		var entry: Dictionary = entry_variant
		var button := entry.get("button") as Control
		if button == null or !is_instance_valid(button):
			continue
		button.modulate.a = 1.0
		button.set(
			"visual_scale",
			button.get_meta(&"portrait_entrance_rest_visual_scale", Vector2.ONE)
		)
		button.set("disabled", bool(entry.get("rest_disabled", false)))
		button.mouse_filter = int(button.get_meta(
			&"portrait_entrance_rest_mouse_filter",
			Control.MOUSE_FILTER_STOP
		))
		button.remove_meta(&"portrait_entrance_rest_visual_scale")
		button.remove_meta(&"portrait_entrance_rest_mouse_filter")
	for hint_button: Control in _portrait_game_hint_buttons:
		if hint_button == null or !is_instance_valid(hint_button):
			continue
		hint_button.modulate.a = 1.0
		hint_button.set(
			"visual_scale",
			hint_button.get_meta(&"portrait_entrance_rest_visual_scale", Vector2.ONE)
		)
		hint_button.set(
			"disabled",
			bool(hint_button.get_meta(&"portrait_entrance_rest_disabled", false))
		)
		hint_button.mouse_filter = int(hint_button.get_meta(
			&"portrait_entrance_rest_mouse_filter",
			Control.MOUSE_FILTER_STOP
		))
		hint_button.remove_meta(&"portrait_entrance_rest_visual_scale")
		hint_button.remove_meta(&"portrait_entrance_rest_mouse_filter")
		hint_button.remove_meta(&"portrait_entrance_rest_disabled")
	_portrait_game_entrance_active = false
	_sync_portrait_attempts_attention_bounce()

func _on_timer_heart_recovered() -> void:
	if (
		_portrait_heart_icon_visual == null
		or !is_instance_valid(_portrait_heart_icon_visual)
		or !_portrait_heart_icon_visual.is_inside_tree()
	):
		return
	var heart_icon: Control = _portrait_heart_icon_visual
	var rest_scale: Vector2 = heart_icon.scale
	var bounce_tween := heart_icon.create_tween()
	bounce_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var grow := bounce_tween.tween_property(heart_icon, "scale", rest_scale * 1.20, 0.12)
	grow.set_trans(Tween.TRANS_BACK)
	grow.set_ease(Tween.EASE_OUT)
	var settle := bounce_tween.tween_property(heart_icon, "scale", rest_scale, 0.18)
	settle.set_trans(Tween.TRANS_BOUNCE)
	settle.set_ease(Tween.EASE_OUT)

func show_result_screen(is_win: bool, _data: Dictionary = {}) -> void:
	# Round completion now stays on the gameplay screen. If another screen has
	# temporarily cleared the game UI, rebuild the finished gameplay state first;
	# _refresh_game_screen() will restore the in-place result without opening the old
	# dedicated result screen.
	if !game_screen_visible or _portrait_game_input_group == null or !is_instance_valid(_portrait_game_input_group):
		show_game_screen()
		return
	# Single Player wins now deliberately follow the Classic victory flow too:
	# the paper peels away in place and the solved word is shown in green.
	_show_in_place_round_result(is_win, true)

func _return_to_game_from_coin_store() -> void:
	# Returning from the modal shop is not a fresh gameplay navigation. Rebuild
	# the current stage without scheduling the one-shot entrance choreography.
	_portrait_game_entrance_pending = false
	super.show_game_screen()

func _return_to_single_player_reward_from_coin_store() -> void:
	# The modal shop clears the current UI tree. Rebuild the reward screen directly
	# in its settled state so returning from the shop does not replay the intro,
	# reward flight, check bounce, or Continue-button entrance.
	_portrait_single_reward_resume_without_intro = true
	_show_single_player_reward_chain_screen()

func _return_to_single_player_last_chance_from_coin_store() -> void:
	_portrait_game_entrance_pending = false
	super.show_game_screen()
	call_deferred("_show_single_player_last_chance_popup")

func _stage_portrait_inline_result_word(animate_result: bool = false) -> Dictionary:
	if (
		_portrait_game_input_group == null
		or !is_instance_valid(_portrait_game_input_group)
		or _portrait_game_word_rect.size.x <= 0.0
	):
		return {}
	var previous_content: Control = content
	content = _portrait_game_input_group
	var result_controls: Dictionary = _stage_portrait_result_word_display(
		_portrait_game_word_rect,
		null,
		null,
		animate_result
	)
	content = previous_content
	_portrait_inline_result_word_holder = result_controls.get("word_holder") as Control
	return result_controls

func _set_portrait_result_word_color(result_controls: Dictionary, color: Color) -> void:
	var word_label := result_controls.get("word_label") as RichTextLabel
	if word_label != null and is_instance_valid(word_label):
		word_label.add_theme_color_override("default_color", color)
		var outline_size: int = 4 if color == StageLetterButton.CIRCLED_COLOR else 3
		_apply_portrait_standard_text_outline(word_label, 0.94, outline_size)
		word_label.add_theme_constant_override("shadow_offset_x", 3)
		word_label.add_theme_constant_override("shadow_offset_y", 3)

func _in_place_result_word_color() -> Color:
	return (
		StageLetterButton.CIRCLED_COLOR
		if _portrait_in_place_result_is_win
		else StageLetterButton.CROSSED_COLOR
	)

func _stage_in_place_result_word(animated: bool) -> void:
	var result_controls: Dictionary = _stage_portrait_inline_result_word(false)
	_set_portrait_result_word_color(result_controls, _in_place_result_word_color())
	var search_button := result_controls.get("search_button") as Control
	_portrait_inline_result_search_button = search_button
	if search_button != null and is_instance_valid(search_button):
		search_button.visible = !animated
		search_button.set("disabled", animated)

func _show_in_place_round_result(is_win: bool, animated: bool = true) -> void:
	if _portrait_in_place_result_active:
		return
	if _portrait_game_input_group == null or !is_instance_valid(_portrait_game_input_group):
		show_game_screen()
		return
	_portrait_in_place_result_active = true
	_portrait_in_place_result_is_win = is_win
	_stop_portrait_attempts_attention_bounce(true)
	_play_result_sound_once(is_win, last_result_data)
	# Keep the inactive keyboard, attempts and the hero pose reached during this
	# round exactly where they are. Only the hint row leaves while the full answer is
	# uncovered; Two Player simply has no hint row to remove.
	_dim_portrait_keyboard_for_in_place_result()
	_hide_portrait_hints_for_round_end(animated)
	_portrait_round_end_bounce_started = false
	_stage_in_place_result_word(animated)
	_peel_portrait_word_paper_for_in_place_result(animated)

func _dim_portrait_keyboard_for_in_place_result() -> void:
	for entry_variant: Variant in _portrait_game_keyboard_buttons:
		var entry: Dictionary = entry_variant
		var button := entry.get("button") as Control
		if button == null or !is_instance_valid(button):
			continue
		button.set("disabled", true)
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.modulate.a = PORTRAIT_IN_PLACE_RESULT_KEYBOARD_ALPHA

func _peel_portrait_word_paper_for_in_place_result(animated: bool) -> void:
	if _portrait_game_word_paper_layer == null or !is_instance_valid(_portrait_game_word_paper_layer):
		_finish_in_place_result_paper_peel(null, animated)
		return
	var paper_layer: Control = _portrait_game_word_paper_layer
	paper_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if !animated:
		_set_portrait_word_paper_peel_progress(1.0)
		_finish_in_place_result_paper_peel(paper_layer, false)
		return

	_set_portrait_word_paper_peel_progress(0.0)
	var flip_tween := create_tween()
	flip_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var mask_tweener := flip_tween.tween_method(
		Callable(self, "_set_portrait_word_paper_peel_progress"),
		0.0,
		1.0,
		PORTRAIT_ROUND_END_PAPER_FLIP_DURATION
	)
	mask_tweener.set_trans(Tween.TRANS_QUAD)
	mask_tweener.set_ease(Tween.EASE_OUT)
	flip_tween.finished.connect(
		Callable(self, "_finish_in_place_result_paper_peel").bind(paper_layer, true),
		CONNECT_ONE_SHOT
	)

	var bounce_start_tween := create_tween()
	bounce_start_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	bounce_start_tween.tween_interval(PORTRAIT_ROUND_END_PAPER_FLIP_DURATION * 0.5)
	bounce_start_tween.tween_callback(
		Callable(self, "_start_in_place_result_word_bounce")
	)

func _start_in_place_result_word_bounce() -> void:
	if _portrait_round_end_bounce_started or !_portrait_in_place_result_active:
		return
	_portrait_round_end_bounce_started = true
	_replace_portrait_inline_result_word_with_bounce(_in_place_result_word_color())

func _finish_in_place_result_paper_peel(paper_layer: Control, animated: bool) -> void:
	_finalize_portrait_word_paper_peel_visuals(paper_layer)
	if animated:
		if !_portrait_round_end_bounce_started:
			_start_in_place_result_word_bounce()
	elif (
		_portrait_inline_result_search_button != null
		and is_instance_valid(_portrait_inline_result_search_button)
	):
		_portrait_inline_result_search_button.set("disabled", false)
		_portrait_inline_result_search_button.visible = true
	_show_in_place_result_action_button(animated)

func _show_in_place_result_action_button(animated: bool) -> void:
	if _portrait_game_input_group == null or !is_instance_valid(_portrait_game_input_group):
		return
	if (
		_portrait_inline_result_continue_button != null
		and is_instance_valid(_portrait_inline_result_continue_button)
	):
		return
	var previous_content: Control = content
	content = _portrait_game_input_group
	var action_text: String = (
		_single_player_text("Повторить", "Retry")
		if GameState.current_mode == GameState.GameMode.SINGLE_PLAYER and !_portrait_in_place_result_is_win
		else _result_continue_button_text()
	)
	var action_button := _stage_main_button(
		_portrait_in_place_result_button_rect(),
		_result_continue_action(),
		action_text,
		22,
		false,
		0.32,
		false,
		false,
		false,
		LONG_BUTTON_COLOR_ORANGE
	)
	action_button.z_index = 50
	_portrait_inline_result_continue_button = action_button
	content = previous_content
	# Use the shared StageLongButton attention loop. It keeps cycling and yields
	# to the standard pressed-state animation while the player touches the button.
	action_button.set("attention_bounce_enabled", true)
	if !animated:
		action_button.visible = true
		action_button.modulate.a = 1.0
		return

	action_button.visible = true
	action_button.modulate.a = 0.0
	var alpha_tween := action_button.create_tween()
	alpha_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	alpha_tween.tween_property(
		action_button,
		"modulate:a",
		1.0,
		PORTRAIT_INLINE_RESULT_CONTINUE_GROW_DURATION
	)

func _single_player_reward_for_slot(word_slot: int, word_count: int) -> int:
	var reward: int = GameState.WORD_REWARD_COINS
	if word_slot == word_count - 1:
		reward += (
			GameState.SINGLE_PLAYER_LEVEL_BASE_BONUS_COINS
			+ maxi(word_count, 0) * GameState.SINGLE_PLAYER_LEVEL_WORD_BONUS_COINS
		)
	return reward

func _single_player_reward_chain_count_text(amount: int) -> String:
	return "x%d" % maxi(amount, 0)

func _single_player_reward_chain_center_y() -> float:
	var viewport_size: Vector2 = get_viewport_rect().size
	var extra_height: float = PORTRAIT_STAGE_LAYOUT.extra_stage_height(viewport_size)
	var safe_top: float = PORTRAIT_STAGE_LAYOUT.safe_top_stage(viewport_size)
	var continue_top_y: float = _portrait_in_place_result_button_rect().position.y + extra_height
	# Reward nodes are regular stage content (safe-top shifted), while Continue is
	# bottom-attached (extra-height shifted). Convert both edges to the same
	# authored coordinate space before taking the midpoint.
	return (
		PORTRAIT_SINGLE_REWARD_HERO_VISUAL_BOTTOM_Y
		+ continue_top_y
		- safe_top
	) * 0.5

func _stage_single_player_reward_tile(
	parent: Control,
	node_size: float,
	level_index: int,
	is_claimed_or_current: bool,
	is_current: bool,
	accent_color: Color,
	header_color: Color
) -> void:
	if parent == null or !is_instance_valid(parent):
		return
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
	var card_rect := Rect2(Vector2.ZERO, Vector2.ONE * node_size)
	var card := _portrait_hint_local_panel(
		parent,
		card_rect,
		card_fill,
		18.0,
		card_border,
		2.0
	)
	card.z_index = 1
	var state_fill: Color = (
		Color(accent_color.r, accent_color.g, accent_color.b, 0.10)
		if is_claimed_or_current
		else Color(header_color.r, header_color.g, header_color.b, 0.055)
	)
	var state_border: Color = (
		accent_color
		if is_claimed_or_current
		else Color(header_color.r, header_color.g, header_color.b, 0.38)
	)
	var overlay := _portrait_hint_local_panel(
		parent,
		card_rect,
		state_fill,
		18.0,
		state_border,
		6.0 if is_current else 3.0
	)
	overlay.z_index = 2

func _stage_single_player_reward_coin_pile(parent: Control, icon_rect: Rect2) -> Control:
	var pile_icon: Control = SOFT_CURRENCY_COIN_PILE_ICON_SCRIPT.new() as Control
	pile_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pile_icon.position = icon_rect.position
	pile_icon.size = icon_rect.size
	pile_icon.z_index = 3
	parent.add_child(pile_icon)
	return pile_icon

func _stage_single_player_reward_check(
	parent: Control,
	node_rect: Rect2,
	start_hidden: bool = false
) -> Control:
	var check_size: Vector2 = node_rect.size * 0.72
	var check_rect := Rect2(
		Vector2(
			node_rect.get_center().x - check_size.x * 0.5,
			node_rect.position.y + node_rect.size.y * 0.08
		),
		check_size
	)
	var check_holder := Control.new()
	check_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	check_holder.position = check_rect.position
	check_holder.size = check_rect.size
	check_holder.pivot_offset = check_rect.size * 0.5
	parent.add_child(check_holder)
	check_holder.z_index = 4
	var shadow_icon: Control = STAGE_STATUS_ICON_SCRIPT.new() as Control
	shadow_icon.name = "RewardClaimedCheckShadow"
	shadow_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	check_holder.add_child(shadow_icon)
	shadow_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shadow_icon.position += Vector2(2.0, 2.0)
	shadow_icon.modulate = Color(0.12, 0.22, 0.48, 0.75)
	shadow_icon.call("configure", true, PORTRAIT_SINGLE_REWARD_CHECK_LINE_WIDTH + 1.0)
	var outline_icon: Control = STAGE_STATUS_ICON_SCRIPT.new() as Control
	outline_icon.name = "RewardClaimedCheckOutline"
	outline_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	check_holder.add_child(outline_icon)
	outline_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outline_icon.modulate = Color(0.12, 0.22, 0.48, 0.92)
	outline_icon.call("configure", true, PORTRAIT_SINGLE_REWARD_CHECK_LINE_WIDTH + 2.0)
	var check_icon: Control = STAGE_STATUS_ICON_SCRIPT.new() as Control
	check_icon.name = "RewardClaimedCheck"
	check_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	check_holder.add_child(check_icon)
	check_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	check_icon.call("configure", true, PORTRAIT_SINGLE_REWARD_CHECK_LINE_WIDTH)
	if start_hidden:
		check_holder.modulate.a = 0.0
		check_holder.scale = Vector2.ONE * PORTRAIT_SINGLE_REWARD_CHECK_BOUNCE_START_SCALE
	return check_holder

func _stage_single_player_reward_count(
	parent: Control,
	node_rect: Rect2,
	icon_rect: Rect2,
	amount: int,
	font_size: int,
	count_color: Color
) -> void:
	var count_text: String = _single_player_reward_chain_count_text(amount)
	var count_label := Label.new()
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Anchor the amount to the lower part of its own reward tile. This keeps xN
	# visually between the coin art and the bottom edge instead of floating over
	# the middle of the icon, while remaining stable when the whole chain moves.
	var label_height: float = 22.0
	var label_bottom_inset: float = 4.0
	var label_y: float = node_rect.size.y - label_height - label_bottom_inset
	count_label.position = Vector2(0.0, label_y)
	count_label.size = Vector2(node_rect.size.x, label_height)
	count_label.text = count_text
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_label.add_theme_font_size_override("font_size", font_size)
	count_label.add_theme_color_override("font_color", count_color)
	count_label.z_index = 5
	parent.add_child(count_label)
	count_label.add_theme_font_override("font", UI_PRIMARY_FONT)
	count_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	count_label.clip_text = false
	# Match the exact outline/shadow weight used by the green solved word.
	_apply_portrait_standard_text_outline(count_label, 0.94, 4)
	count_label.add_theme_constant_override("shadow_offset_x", 3)
	count_label.add_theme_constant_override("shadow_offset_y", 3)
	_fit_single_line_label_to_width(
		count_label,
		count_text,
		count_label.size.x,
		font_size,
		PORTRAIT_SINGLE_REWARD_CHAIN_COUNT_MIN_FONT_SIZE
	)

func _control_center_in_control_space(source: Control, target_space: Control) -> Vector2:
	if (
		source == null
		or !is_instance_valid(source)
		or target_space == null
		or !is_instance_valid(target_space)
	):
		return Vector2.ZERO
	var source_center_global: Vector2 = (
		source.get_global_transform_with_canvas() * (source.size * 0.5)
	)
	return target_space.get_global_transform_with_canvas().affine_inverse() * source_center_global

func _play_single_player_reward_coin_collection(source_visual: Control) -> void:
	if ui == null or !is_instance_valid(ui):
		return
	if source_visual == null or !is_instance_valid(source_visual) or !source_visual.is_inside_tree():
		return
	if (
		_portrait_currency_coin_icon_visual == null
		or !is_instance_valid(_portrait_currency_coin_icon_visual)
		or !_portrait_currency_coin_icon_visual.is_inside_tree()
	):
		return
	var overlay_layer := CanvasLayer.new()
	overlay_layer.name = "SinglePlayerRewardCoinCanvas"
	overlay_layer.layer = 100
	add_child(overlay_layer)
	var overlay := Control.new()
	overlay.name = "SinglePlayerRewardCoinOverlay"
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay_layer.add_child(overlay)

	var coin_size := Vector2.ONE * PORTRAIT_SINGLE_REWARD_FLY_COIN_SIZE
	var source_viewport_center: Vector2 = _control_center_in_control_space(source_visual, overlay)
	var target_center: Vector2 = _control_center_in_control_space(
		_portrait_currency_coin_icon_visual,
		overlay
	)
	for coin_index in range(PORTRAIT_SINGLE_REWARD_FLY_COIN_COUNT):
		var coin := TextureRect.new()
		coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		coin.texture = SOFT_CURRENCY_COIN_TEXTURE
		coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		coin.size = coin_size
		coin.pivot_offset = coin_size * 0.5
		coin.position = source_viewport_center - coin_size * 0.5
		coin.scale = Vector2.ONE
		coin.modulate.a = 0.0
		overlay.add_child(coin)

		var spread_sign: float = -1.0 if coin_index % 2 == 0 else 1.0
		var spread_step: float = float(coin_index / 2 + 1)
		var start_offset := Vector2(
			spread_sign * spread_step * PORTRAIT_SINGLE_REWARD_FLY_SPREAD_X * 0.42,
			-float(coin_index % 3) * PORTRAIT_SINGLE_REWARD_FLY_SPREAD_Y
		)
		var flight_start := source_viewport_center + start_offset - coin_size * 0.5
		var flight_end := target_center - coin_size * 0.5

		var tween := coin.create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_interval(
			PORTRAIT_SINGLE_REWARD_FLY_START_DELAY
			+ float(coin_index) * PORTRAIT_SINGLE_REWARD_FLY_STAGGER
		)
		tween.parallel().tween_property(coin, "modulate:a", 1.0, 0.08)
		var rise := tween.tween_property(coin, "position", flight_start, 0.10)
		rise.set_trans(Tween.TRANS_SINE)
		rise.set_ease(Tween.EASE_OUT)
		var fly := tween.tween_property(coin, "position", flight_end, PORTRAIT_SINGLE_REWARD_FLY_DURATION)
		fly.set_trans(Tween.TRANS_CUBIC)
		fly.set_ease(Tween.EASE_IN)
		# Every coin is absorbed by the exact center of the HUD coin icon. Pulse the
		# icon at the moment of impact, then remove the flying copy immediately.
		tween.tween_callback(Callable(self, "_bounce_portrait_currency_coin_icon"))
		tween.tween_callback(Callable(coin, "queue_free"))

	var cleanup_delay: float = (
		PORTRAIT_SINGLE_REWARD_FLY_START_DELAY
		+ float(maxi(PORTRAIT_SINGLE_REWARD_FLY_COIN_COUNT - 1, 0)) * PORTRAIT_SINGLE_REWARD_FLY_STAGGER
		+ 0.10
		+ PORTRAIT_SINGLE_REWARD_FLY_DURATION
		+ 0.12
	)
	var cleanup_tween := overlay.create_tween()
	cleanup_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	cleanup_tween.tween_interval(cleanup_delay)
	cleanup_tween.tween_callback(Callable(overlay_layer, "queue_free"))

func _single_player_reward_coin_collection_total_duration() -> float:
	return (
		PORTRAIT_SINGLE_REWARD_FLY_START_DELAY
		+ float(maxi(PORTRAIT_SINGLE_REWARD_FLY_COIN_COUNT - 1, 0)) * PORTRAIT_SINGLE_REWARD_FLY_STAGGER
		+ 0.10
		+ PORTRAIT_SINGLE_REWARD_FLY_DURATION
		+ 0.12
	)

func _create_single_player_reward_masked_hero(parent: Control, initial_title_rect: Rect2) -> Dictionary:
	var viewport_size: Vector2 = get_viewport_rect().size
	var hero_mask := Control.new()
	hero_mask.name = "SinglePlayerRewardHeroMask"
	hero_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_mask.clip_contents = true
	hero_mask.z_index = 4
	parent.add_child(hero_mask)

	var hero_viewport := SubViewport.new()
	hero_viewport.name = "SinglePlayerRewardHeroViewport"
	hero_viewport.disable_3d = true
	hero_viewport.transparent_bg = true
	hero_viewport.size = Vector2i(
		maxi(1, int(round(viewport_size.x))),
		maxi(1, int(round(viewport_size.y)))
	)
	hero_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	hero_mask.add_child(hero_viewport)

	var reward_hero: FlashStageSymbol = FLASH_STAGE_SYMBOL_SCRIPT.new() as FlashStageSymbol
	reward_hero.z_index = 5
	reward_hero.hero_type = _hero_type()
	reward_hero.stage_position = PORTRAIT_SINGLE_REWARD_HERO_POSITION
	reward_hero.animation_time = _hero_animation_time_for_mistakes(0)
	reward_hero.nested_animation_time = HERO_MOV_IDLE_FRAME_TIME
	reward_hero.stage_scale_multiplier = PORTRAIT_SINGLE_REWARD_HERO_SCALE_MULTIPLIER
	hero_viewport.add_child(reward_hero)

	var hero_texture := TextureRect.new()
	hero_texture.name = "SinglePlayerRewardHeroTexture"
	hero_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_texture.texture = hero_viewport.get_texture()
	hero_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero_texture.stretch_mode = TextureRect.STRETCH_SCALE
	hero_mask.add_child(hero_texture)
	_set_single_player_reward_hero_mask_from_title_rect(initial_title_rect, hero_mask, hero_texture)
	return {
		"mask": hero_mask,
		"texture": hero_texture,
		"viewport": hero_viewport,
		"hero": reward_hero,
	}

func _set_single_player_reward_hero_mask_from_title_rect(
	title_rect: Rect2,
	hero_mask: Control,
	hero_texture: TextureRect
) -> void:
	if hero_mask == null or !is_instance_valid(hero_mask):
		return
	if hero_texture == null or !is_instance_valid(hero_texture):
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var mask_top_stage: float = clampf(
		title_rect.position.y + title_rect.size.y,
		0.0,
		PORTRAIT_STAGE_SIZE.y
	)
	var mask_top_viewport: float = _portrait_stage_point_to_viewport(
		Vector2(0.0, mask_top_stage)
	).y
	mask_top_viewport = clampf(mask_top_viewport, 0.0, viewport_size.y)
	hero_mask.position = Vector2(0.0, mask_top_viewport)
	hero_mask.size = Vector2(
		viewport_size.x,
		maxf(1.0, viewport_size.y - mask_top_viewport)
	)
	hero_texture.position = Vector2(0.0, -mask_top_viewport)
	hero_texture.size = viewport_size

func _start_single_player_reward_claim_animation_deferred(
	coin_visual: Control,
	check_visual: Control
) -> void:
	# Let stage-layout controls resolve their final size/pivot before animating.
	# Flying coins and the source icon fade begin together; the claimed check then
	# pops into the same reward slot with a centered bounce.
	await get_tree().process_frame
	if !is_inside_tree():
		return
	if coin_visual == null or !is_instance_valid(coin_visual) or !coin_visual.is_inside_tree():
		return
	if check_visual == null or !is_instance_valid(check_visual) or !check_visual.is_inside_tree():
		return

	_play_single_player_reward_coin_collection(coin_visual)

	var coin_fade := coin_visual.create_tween()
	coin_fade.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var fade_tweener := coin_fade.tween_property(
		coin_visual,
		"modulate:a",
		PORTRAIT_SINGLE_REWARD_CLAIMED_COIN_ALPHA,
		PORTRAIT_SINGLE_REWARD_CLAIM_ICON_FADE_DURATION
	)
	fade_tweener.set_trans(Tween.TRANS_QUAD)
	fade_tweener.set_ease(Tween.EASE_OUT)

	check_visual.pivot_offset = check_visual.size * 0.5
	check_visual.modulate.a = 0.0
	check_visual.scale = Vector2.ONE * PORTRAIT_SINGLE_REWARD_CHECK_BOUNCE_START_SCALE
	var check_tween := check_visual.create_tween()
	check_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	check_tween.tween_interval(_single_player_reward_coin_collection_total_duration())
	check_tween.tween_property(check_visual, "modulate:a", 1.0, 0.08)
	var grow := check_tween.parallel().tween_property(
		check_visual,
		"scale",
		Vector2.ONE * PORTRAIT_SINGLE_REWARD_CHECK_BOUNCE_PEAK_SCALE,
		PORTRAIT_SINGLE_REWARD_CHECK_BOUNCE_GROW_DURATION
	)
	grow.set_trans(Tween.TRANS_BACK)
	grow.set_ease(Tween.EASE_OUT)
	var settle := check_tween.tween_property(
		check_visual,
		"scale",
		Vector2.ONE,
		PORTRAIT_SINGLE_REWARD_CHECK_BOUNCE_SETTLE_DURATION
	)
	settle.set_trans(Tween.TRANS_BOUNCE)
	settle.set_ease(Tween.EASE_OUT)

func _start_single_player_reward_intro_deferred(
	title_block: Control,
	title_visual: Control,
	hero_mask: Control,
	hero_texture: TextureRect,
	reward_body: Control,
	hud_content: Control,
	animate_claim: bool,
	coin_visual: Control,
	check_visual: Control,
	continue_button: Control
) -> void:
	await get_tree().process_frame
	if !is_inside_tree():
		return
	if title_block == null or !is_instance_valid(title_block) or !title_block.is_inside_tree():
		return
	if title_visual == null or !is_instance_valid(title_visual) or !title_visual.is_inside_tree():
		return
	if reward_body == null or !is_instance_valid(reward_body) or !reward_body.is_inside_tree():
		return
	if hud_content != null and is_instance_valid(hud_content):
		hud_content.modulate.a = 0.0
	if continue_button != null and is_instance_valid(continue_button):
		continue_button.modulate.a = 0.0
		continue_button.set("visual_scale", Vector2.ONE * 0.94)
		continue_button.set("attention_bounce_enabled", false)
		continue_button.set("disabled", true)

	title_visual.pivot_offset = title_visual.size * 0.5
	title_block.modulate.a = 0.0
	title_visual.scale = Vector2.ONE * PORTRAIT_SINGLE_REWARD_TITLE_START_SCALE
	title_block.set("stage_rect", PORTRAIT_SINGLE_REWARD_TITLE_BLOCK_CENTER_RECT)
	_set_single_player_reward_hero_mask_from_title_rect(
		PORTRAIT_SINGLE_REWARD_TITLE_BLOCK_CENTER_RECT,
		hero_mask,
		hero_texture
	)
	var title_tween := title_visual.create_tween()
	title_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	title_tween.tween_property(
		title_block,
		"modulate:a",
		1.0,
		PORTRAIT_SINGLE_REWARD_TITLE_GROW_DURATION
	)
	var grow := title_tween.parallel().tween_property(
		title_visual,
		"scale",
		Vector2.ONE * PORTRAIT_SINGLE_REWARD_TITLE_PEAK_SCALE,
		PORTRAIT_SINGLE_REWARD_TITLE_GROW_DURATION
	)
	grow.set_trans(Tween.TRANS_BACK)
	grow.set_ease(Tween.EASE_OUT)
	var settle := title_tween.tween_property(
		title_visual,
		"scale",
		Vector2.ONE,
		PORTRAIT_SINGLE_REWARD_TITLE_SETTLE_DURATION
	)
	settle.set_trans(Tween.TRANS_BOUNCE)
	settle.set_ease(Tween.EASE_OUT)
	await title_tween.finished
	var move_tween := title_block.create_tween()
	move_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var move_rect := move_tween.tween_property(
		title_block,
		"stage_rect",
		PORTRAIT_SINGLE_REWARD_TITLE_BLOCK_TOP_RECT,
		PORTRAIT_SINGLE_REWARD_TITLE_MOVE_DURATION
	)
	move_rect.set_trans(Tween.TRANS_QUAD)
	move_rect.set_ease(Tween.EASE_OUT)
	var move_mask := move_tween.parallel().tween_method(
		Callable(self, "_set_single_player_reward_hero_mask_from_title_rect").bind(
			hero_mask,
			hero_texture
		),
		PORTRAIT_SINGLE_REWARD_TITLE_BLOCK_CENTER_RECT,
		PORTRAIT_SINGLE_REWARD_TITLE_BLOCK_TOP_RECT,
		PORTRAIT_SINGLE_REWARD_TITLE_MOVE_DURATION
	)
	move_mask.set_trans(Tween.TRANS_QUAD)
	move_mask.set_ease(Tween.EASE_OUT)
	await move_tween.finished

	if reward_body == null or !is_instance_valid(reward_body) or !reward_body.is_inside_tree():
		return
	var body_tween := reward_body.create_tween()
	body_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	body_tween.tween_property(
		reward_body,
		"modulate:a",
		1.0,
		PORTRAIT_SINGLE_REWARD_BODY_FADE_DURATION
	)
	if hud_content != null and is_instance_valid(hud_content):
		body_tween.parallel().tween_property(
			hud_content,
			"modulate:a",
			1.0,
			PORTRAIT_SINGLE_REWARD_BODY_FADE_DURATION
		)
	await body_tween.finished

	if animate_claim:
		_start_single_player_reward_claim_animation_deferred(coin_visual, check_visual)
		await get_tree().create_timer(
			_single_player_reward_coin_collection_total_duration()
			+ PORTRAIT_SINGLE_REWARD_CHECK_BOUNCE_GROW_DURATION
			+ PORTRAIT_SINGLE_REWARD_CHECK_BOUNCE_SETTLE_DURATION
			+ 0.04
		).timeout
	if continue_button != null and is_instance_valid(continue_button) and continue_button.is_inside_tree():
		continue_button.set("disabled", false)
		var button_tween := continue_button.create_tween()
		button_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		button_tween.tween_property(continue_button, "modulate:a", 1.0, 0.12)
		var button_grow := button_tween.parallel().tween_property(continue_button, "visual_scale", Vector2.ONE * 1.06, 0.12)
		button_grow.set_trans(Tween.TRANS_BACK)
		button_grow.set_ease(Tween.EASE_OUT)
		var button_settle := button_tween.tween_property(continue_button, "visual_scale", Vector2.ONE, 0.16)
		button_settle.set_trans(Tween.TRANS_BOUNCE)
		button_settle.set_ease(Tween.EASE_OUT)
		await button_tween.finished
		if continue_button != null and is_instance_valid(continue_button):
			continue_button.set("attention_bounce_enabled", true)

func _show_single_player_reward_chain_screen() -> void:
	var level_index: int = int(last_result_data.get(
		"single_player_level_index",
		single_player_active_level_index
	))
	if level_index < 0:
		show_menu()
		return

	var word_count: int = maxi(
		int(last_result_data.get(
			"single_player_total_count",
			_single_player_level_word_count(level_index)
		)),
		1
	)
	var current_slot: int = clampi(
		int(last_result_data.get(
			"single_player_word_slot",
			single_player_active_word_slot
		)),
		0,
		word_count - 1
	)
	var challenge_level: bool = _single_player_is_bonus_level(level_index)
	var header_color: Color = PORTRAIT_CHALLENGE_POPUP_HEADER if challenge_level else PORTRAIT_BLUE
	var accent_color: Color = StageLetterButton.CIRCLED_COLOR
	var resume_without_intro: bool = _portrait_single_reward_resume_without_intro
	_portrait_single_reward_resume_without_intro = false

	_clear()
	_portrait_screen_without_header(-1.0)
	var reward_screen_content: Control = content
	var title_block := _stage_holder(
		PORTRAIT_SINGLE_REWARD_TITLE_BLOCK_CENTER_RECT,
		Control.MOUSE_FILTER_IGNORE
	)
	title_block.z_index = 30
	title_block.modulate.a = 0.0
	var title_visual := Control.new()
	title_visual.name = "SinglePlayerRewardTitleVisual"
	title_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_visual.position = Vector2.ZERO
	title_visual.size = PORTRAIT_SINGLE_REWARD_TITLE_BLOCK_CENTER_RECT.size
	title_visual.pivot_offset = title_visual.size * 0.5
	title_block.add_child(title_visual)
	var title_panel := _portrait_hint_local_panel(
		title_visual,
		Rect2(Vector2.ZERO, title_visual.size),
		PORTRAIT_SINGLE_REWARD_TITLE_BLOCK_FILL,
		0.0,
		PORTRAIT_SINGLE_REWARD_TITLE_BLOCK_BORDER,
		0.0
	)
	title_panel.z_index = 0
	var reward_title := Label.new()
	reward_title.name = "RewardTitle"
	reward_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reward_title.position = Vector2(0.0, PORTRAIT_SINGLE_REWARD_TITLE_TOP_PADDING)
	reward_title.size = Vector2(title_visual.size.x, PORTRAIT_SINGLE_REWARD_TITLE_HEIGHT)
	reward_title.text = _single_player_text("ОТЛИЧНО!", "WELL DONE!")
	reward_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	reward_title.add_theme_font_override("font", UI_PRIMARY_FONT)
	reward_title.add_theme_font_size_override("font_size", PORTRAIT_SINGLE_REWARD_TITLE_FONT_SIZE)
	reward_title.add_theme_color_override("font_color", PORTRAIT_ORANGE)
	_apply_portrait_reward_header_text_effect(reward_title, 2)
	reward_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	reward_title.clip_text = false
	reward_title.z_index = 1
	title_visual.add_child(reward_title)
	var reward_subtitle := Label.new()
	reward_subtitle.name = "RewardSubtitle"
	reward_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reward_subtitle.position = Vector2(0.0, PORTRAIT_SINGLE_REWARD_SUBTITLE_TOP)
	reward_subtitle.size = Vector2(title_visual.size.x, PORTRAIT_SINGLE_REWARD_SUBTITLE_HEIGHT)
	reward_subtitle.text = _single_player_text("Слово отгадано", "Word guessed")
	reward_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	reward_subtitle.add_theme_font_override("font", UI_HEADING_FONT)
	reward_subtitle.add_theme_font_size_override("font_size", PORTRAIT_SINGLE_REWARD_SUBTITLE_FONT_SIZE)
	reward_subtitle.add_theme_color_override("font_color", Color.WHITE)
	_apply_portrait_reward_header_text_effect(reward_subtitle, 1)
	reward_subtitle.autowrap_mode = TextServer.AUTOWRAP_OFF
	reward_subtitle.clip_text = false
	reward_subtitle.z_index = 1
	title_visual.add_child(reward_subtitle)

	_stage_portrait_admob_banner_placeholder()

	# Keep the persistent HUD and the celebratory title visible independently.
	# Reward content itself is revealed only after the title finishes its first
	# bounce, making ОТЛИЧНО!/WELL DONE! the first reward-screen element shown.
	# Render the hero into a transparent viewport and reveal only the portion below
	# the moving title block. This is a real clip: no covering texture or color is
	# drawn over the paper background.
	var masked_hero: Dictionary = _create_single_player_reward_masked_hero(
		reward_screen_content,
		PORTRAIT_SINGLE_REWARD_TITLE_BLOCK_CENTER_RECT
	)
	var hero_mask := masked_hero.get("mask") as Control
	var hero_texture := masked_hero.get("texture") as TextureRect
	var reward_body := Control.new()
	reward_body.name = "SinglePlayerRewardBody"
	reward_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reward_body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	reward_body.modulate.a = 0.0
	reward_screen_content.add_child(reward_body)
	content = reward_body
	_stage_centered_coin_only_counter(
		Callable(self, "_return_to_single_player_reward_from_coin_store"),
		PORTRAIT_GAME_CURRENCY_COUNTER_RECT,
		challenge_level,
		false
	)

	# Keep the just-earned reward locked to the horizontal center. Neighboring
	# rewards expand away from it. Reward tiles now keep a fixed authored size; if
	# a long chain does not fit fully on screen, outer tiles are allowed to run
	# offscreen instead of shrinking.
	var left_count: int = current_slot
	var right_count: int = maxi(word_count - current_slot - 1, 0)
	var node_gap: float = PORTRAIT_SINGLE_REWARD_NODE_GAP
	var normal_node_size: float = PORTRAIT_SINGLE_REWARD_NODE_MAX_SIZE * PORTRAIT_SINGLE_REWARD_SIDE_NODE_SCALE
	var current_node_size: float = PORTRAIT_SINGLE_REWARD_NODE_MAX_SIZE * PORTRAIT_SINGLE_REWARD_CURRENT_NODE_SCALE
	var reward_claim_key: String = "%s:%d:%d" % [
		Database.current_language,
		level_index,
		current_slot,
	]
	var animate_current_claim: bool = reward_claim_key != _portrait_last_animated_reward_claim_key
	var chain_center_y: float = _single_player_reward_chain_center_y()
	var node_sizes: Array = []
	var node_positions_x: Array = []
	for word_slot in range(word_count):
		var is_current_slot: bool = word_slot == current_slot
		var slot_size: float = current_node_size if is_current_slot else normal_node_size
		var slot_x: float = PORTRAIT_STAGE_SIZE.x * 0.5 - slot_size * 0.5
		if word_slot < current_slot:
			var left_distance: int = current_slot - word_slot
			slot_x = (
				PORTRAIT_STAGE_SIZE.x * 0.5
				- current_node_size * 0.5
				- float(left_distance) * node_gap
				- float(left_distance) * normal_node_size
			)
		elif word_slot > current_slot:
			var right_distance: int = word_slot - current_slot
			slot_x = (
				PORTRAIT_STAGE_SIZE.x * 0.5
				+ current_node_size * 0.5
				+ float(right_distance) * node_gap
				+ float(right_distance - 1) * normal_node_size
			)
		node_sizes.append(slot_size)
		node_positions_x.append(slot_x)

	var current_reward_coin_visual: Control = null
	var current_reward_check_icon: Control = null
	for word_slot in range(word_count):
		var node_size: float = float(node_sizes[word_slot])
		var node_x: float = float(node_positions_x[word_slot])
		var node_y: float = chain_center_y - node_size * 0.5

		var is_previous: bool = word_slot < current_slot
		var is_current: bool = word_slot == current_slot
		var node_border: Color = (
			accent_color
			if word_slot <= current_slot
			else Color(header_color.r, header_color.g, header_color.b, 0.38)
		)
		var node_fill: Color = (
			Color(accent_color.r, accent_color.g, accent_color.b, 0.10)
			if word_slot <= current_slot
			else Color(header_color.r, header_color.g, header_color.b, 0.055)
		)
		var reward_amount: int = _single_player_reward_for_slot(word_slot, word_count)
		var count_color: Color = (
			Color.WHITE
			if word_slot <= current_slot
			else Color(1.0, 1.0, 1.0, 0.72)
		)

		var node_rect := Rect2(node_x, node_y, node_size, node_size)
		var node_holder := _stage_holder(node_rect, Control.MOUSE_FILTER_IGNORE)
		node_holder.z_index = 1
		_stage_single_player_reward_tile(
			node_holder,
			node_size,
			level_index,
			word_slot <= current_slot,
			is_current,
			accent_color,
			header_color
		)
		var local_node_rect := Rect2(Vector2.ZERO, Vector2.ONE * node_size)
		var coin_size: float = clampf(node_size * PORTRAIT_SINGLE_REWARD_CHAIN_ICON_SCALE, 30.0, 72.0)
		var coin_rect := Rect2(
			(node_size - coin_size) * 0.5,
			(node_size - coin_size) * 0.5 - 4.0,
			coin_size,
			coin_size
		)
		var coin_visual := _stage_single_player_reward_coin_pile(node_holder, coin_rect)
		var is_claimed: bool = is_previous or (is_current and !animate_current_claim)
		if is_claimed:
			# Keep the actual reward visible after collection. The check is a status
			# overlay, not a replacement for the coin icon.
			coin_visual.modulate.a = PORTRAIT_SINGLE_REWARD_CLAIMED_COIN_ALPHA
			_stage_single_player_reward_check(node_holder, local_node_rect)
		elif is_current:
			current_reward_coin_visual = coin_visual
			current_reward_check_icon = _stage_single_player_reward_check(node_holder, local_node_rect, true)

		var count_font_size: int = int(round(
			float(PORTRAIT_SINGLE_REWARD_CHAIN_COUNT_FONT_SIZE) * (1.12 if is_current else 1.0)
		))
		_stage_single_player_reward_count(
			node_holder,
			local_node_rect,
			coin_rect,
			reward_amount,
			count_font_size,
			count_color
		)

	# Put the reward CTA in the same bottom-attached coordinate space as the
	# gameplay retry/continue CTA. _portrait_begin_bottom_attached_group() already
	# switches `content` to the new group; keep its return value only for restore.
	var reward_content: Control = _portrait_begin_bottom_attached_group()
	var continue_button := _stage_main_button(
		# Use the exact same authored rect as the gameplay result CTA. Both buttons
		# now live in an identical bottom-attached group, so their physical Y is
		# pixel-for-pixel the same on every portrait aspect ratio.
		_portrait_in_place_result_button_rect(),
		Callable(self, "_continue_from_single_player_reward_chain"),
		_result_continue_button_text(),
		22,
		false,
		0.32,
		false,
		false,
		false,
		LONG_BUTTON_COLOR_ORANGE
	)
	continue_button.z_index = 120
	continue_button.modulate.a = 0.0
	continue_button.set("disabled", true)
	content = reward_content
	content = reward_screen_content
	var reward_hud_content: Control = _portrait_top_bar_content
	if resume_without_intro:
		title_block.set("stage_rect", PORTRAIT_SINGLE_REWARD_TITLE_BLOCK_TOP_RECT)
		title_block.modulate.a = 1.0
		title_visual.scale = Vector2.ONE
		_set_single_player_reward_hero_mask_from_title_rect(
			PORTRAIT_SINGLE_REWARD_TITLE_BLOCK_TOP_RECT,
			hero_mask,
			hero_texture
		)
		reward_body.modulate.a = 1.0
		if reward_hud_content != null and is_instance_valid(reward_hud_content):
			reward_hud_content.modulate.a = 1.0
		continue_button.modulate.a = 1.0
		continue_button.set("visual_scale", Vector2.ONE)
		continue_button.set("disabled", false)
		continue_button.set("attention_bounce_enabled", true)
		return
	if reward_hud_content != null and is_instance_valid(reward_hud_content):
		reward_hud_content.modulate.a = 0.0

	if (
		animate_current_claim
		and current_reward_coin_visual != null
		and current_reward_check_icon != null
	):
		_portrait_last_animated_reward_claim_key = reward_claim_key
	call_deferred(
		"_start_single_player_reward_intro_deferred",
		title_block,
		title_visual,
		hero_mask,
		hero_texture,
		reward_body,
		reward_hud_content,
		animate_current_claim,
		current_reward_coin_visual,
		current_reward_check_icon,
		continue_button
	)

func _continue_from_single_player_reward_chain() -> void:
	var level_index: int = int(last_result_data.get(
		"single_player_level_index",
		single_player_active_level_index
	))
	var level_completed: bool = bool(last_result_data.get(
		"single_player_level_completed",
		false
	))
	if level_completed:
		GameSession.discard_current_round()
		game_finished = false
		last_result_data = {}
		single_player_active_word_slot = -1
		show_menu()
		return
	_start_next_single_player_word(level_index)

func _continue_single_player_result() -> void:
	# A loss keeps the existing retry flow. A win first opens the reward-chain
	# interstitial; only the next tap advances the level chain.
	if !last_result_is_win:
		_open_single_player_retry_theme_popup()
		return
	_show_single_player_reward_chain_screen()

func _use_open_hint() -> void:
	var previous_count: int = GameState.get_hint_count(GameState.HINT_OPEN_LETTER)
	if previous_count > 0:
		_portrait_hint_counter_animation_active = true
		_portrait_hint_counter_refresh_requested = false
	super._use_open_hint()
	if previous_count > 0 and GameState.get_hint_count(GameState.HINT_OPEN_LETTER) >= previous_count:
		_portrait_hint_counter_animation_active = false
	_play_portrait_hint_spend_animation_if_needed(
		GameState.HINT_OPEN_LETTER,
		previous_count,
		GameState.get_hint_count(GameState.HINT_OPEN_LETTER)
	)

func _use_remove_hint() -> void:
	var previous_count: int = GameState.get_hint_count(GameState.HINT_REMOVE_WRONG)
	if previous_count > 0:
		_portrait_hint_counter_animation_active = true
		_portrait_hint_counter_refresh_requested = false
	super._use_remove_hint()
	if previous_count > 0 and GameState.get_hint_count(GameState.HINT_REMOVE_WRONG) >= previous_count:
		_portrait_hint_counter_animation_active = false
	_play_portrait_hint_spend_animation_if_needed(
		GameState.HINT_REMOVE_WRONG,
		previous_count,
		GameState.get_hint_count(GameState.HINT_REMOVE_WRONG)
	)

func _use_comment_hint() -> void:
	if GameSession.comment_hint_unlocked:
		super._use_comment_hint()
		return
	var previous_count: int = GameState.get_hint_count(GameState.HINT_COMMENT)
	if previous_count > 0:
		_portrait_hint_counter_animation_active = true
		_portrait_hint_counter_refresh_requested = false
	super._use_comment_hint()
	if previous_count > 0 and GameState.get_hint_count(GameState.HINT_COMMENT) >= previous_count:
		_portrait_hint_counter_animation_active = false
	_play_portrait_hint_spend_animation_if_needed(
		GameState.HINT_COMMENT,
		previous_count,
		GameState.get_hint_count(GameState.HINT_COMMENT)
	)

func _hide_portrait_keyboard_for_round_end(animated: bool) -> float:
	var valid_buttons: Array = []
	var min_x: float = INF
	var max_x: float = -INF
	for entry_variant: Variant in _portrait_game_keyboard_buttons:
		var entry: Dictionary = entry_variant
		var button := entry.get("button") as Control
		if button == null or !is_instance_valid(button):
			continue
		var stage_x: float = float(entry.get("stage_x", 0.0))
		valid_buttons.append({"button": button, "stage_x": stage_x})
		min_x = minf(min_x, stage_x)
		max_x = maxf(max_x, stage_x)
	if valid_buttons.is_empty():
		return 0.0
	var x_range: float = maxf(max_x - min_x, 1.0)
	for entry_variant: Variant in valid_buttons:
		var entry: Dictionary = entry_variant
		var button := entry.get("button") as Control
		var stage_x: float = float(entry.get("stage_x", 0.0))
		button.set("disabled", true)
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Do not touch the Control transform used by the stage layout here. Letter
		# buttons carry the viewport fit scale on `button.scale`; changing their pivot
		# while that scale is active shifts the whole keyboard left/up for one frame.
		# Animate only the button's internal visual scale so the first animation frame
		# is pixel-identical to the gameplay position.
		if !animated:
			button.modulate.a = 0.0
			button.visible = false
			continue
		var delay: float = ((stage_x - min_x) / x_range) * PORTRAIT_ROUND_END_KEY_WAVE_DURATION
		var rest_visual_scale: Vector2 = button.get("visual_scale")
		var tween := button.create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_interval(delay)
		var alpha_tweener := tween.tween_property(
			button,
			"modulate:a",
			0.0,
			PORTRAIT_ROUND_END_KEY_FADE_DURATION
		)
		alpha_tweener.set_trans(Tween.TRANS_QUAD)
		alpha_tweener.set_ease(Tween.EASE_IN)
		var scale_tween := button.create_tween()
		scale_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		scale_tween.tween_interval(delay)
		var scale_tweener := scale_tween.tween_property(
			button,
			"visual_scale",
			rest_visual_scale * PORTRAIT_ROUND_END_KEY_SCALE,
			PORTRAIT_ROUND_END_KEY_FADE_DURATION
		)
		scale_tweener.set_trans(Tween.TRANS_QUAD)
		scale_tweener.set_ease(Tween.EASE_OUT)
	return PORTRAIT_ROUND_END_KEY_WAVE_DURATION + PORTRAIT_ROUND_END_KEY_FADE_DURATION

func _hide_portrait_attempts_for_round_end(animated: bool) -> void:
	for attempts_control: Control in _portrait_game_attempts_controls:
		if attempts_control == null or !is_instance_valid(attempts_control):
			continue
		attempts_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if !animated:
			attempts_control.modulate.a = 0.0
			attempts_control.visible = false
			continue
		var fade_tween := attempts_control.create_tween()
		fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		var fade_tweener := fade_tween.tween_property(
			attempts_control,
			"modulate:a",
			0.0,
			PORTRAIT_ROUND_END_ATTEMPTS_FADE_DURATION
		)
		fade_tweener.set_trans(Tween.TRANS_QUAD)
		fade_tweener.set_ease(Tween.EASE_IN)

func _hide_portrait_hints_for_round_end(animated: bool) -> void:
	for hint_button: Control in _portrait_game_hint_buttons:
		if hint_button == null or !is_instance_valid(hint_button):
			continue
		hint_button.set("disabled", true)
		hint_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if !animated:
			hint_button.modulate.a = 0.0
			hint_button.visible = false
			continue
		var fade_tween := hint_button.create_tween()
		fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		var fade_tweener := fade_tween.tween_property(
			hint_button,
			"modulate:a",
			0.0,
			PORTRAIT_ROUND_END_HINTS_FADE_DURATION
		)
		fade_tweener.set_trans(Tween.TRANS_QUAD)
		fade_tweener.set_ease(Tween.EASE_IN)

func _set_portrait_word_paper_entrance_progress(progress: float) -> void:
	var reveal: float = clampf(progress, 0.0, 1.0)
	if (
		_portrait_game_word_paper_mask == null
		or !is_instance_valid(_portrait_game_word_paper_mask)
		or _portrait_game_word_paper_layer == null
		or !is_instance_valid(_portrait_game_word_paper_layer)
	):
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	# Lay the page back down from right to left. The clipping boundary travels
	# from the right edge toward the left while the front texture itself stays
	# fixed in screen space. This is deliberately separate from the exit formula.
	var hidden_progress: float = 1.0 - reveal
	var mask_x: float = viewport_size.x * hidden_progress
	_portrait_game_word_paper_mask.visible = reveal > 0.001
	_portrait_game_word_paper_layer.visible = true
	_portrait_game_word_paper_layer.modulate = Color.WHITE
	_portrait_game_word_paper_mask.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_portrait_game_word_paper_mask.position = Vector2(mask_x, 0.0)
	_portrait_game_word_paper_mask.size = Vector2(
		maxf(1.0, viewport_size.x - mask_x),
		viewport_size.y
	)
	_portrait_game_word_paper_layer.position = Vector2(-mask_x, 0.0)

	if (
		_portrait_game_word_paper_backside == null
		or !is_instance_valid(_portrait_game_word_paper_backside)
		or _portrait_game_word_paper_backside_visual == null
		or !is_instance_valid(_portrait_game_word_paper_backside_visual)
	):
		return

	var fit_scale: float = PORTRAIT_STAGE_LAYOUT.fit_scale(viewport_size)
	if fit_scale <= 0.0:
		return
	var horizontal_offset: float = PORTRAIT_STAGE_LAYOUT.horizontal_offset(viewport_size)
	var fold_stage_x: float = (mask_x - horizontal_offset) / fit_scale

	# Entrance is the exact geometric reverse of the exit peel. At the start the
	# reverse side has full horizontal scale but sits beyond the right screen edge;
	# while the fold travels left it progressively contracts to zero. This keeps
	# the reverse texture attached to the fold line without the broken mid-curve
	# expansion from the previous implementation.
	var fold_curve: float = hidden_progress
	_portrait_game_word_paper_backside.set(
		"stage_rect",
		Rect2(
			fold_stage_x,
			_portrait_game_word_rect.position.y + PORTRAIT_GAME_WORD_PAPER_Y_OFFSET,
			PORTRAIT_ROUND_END_PAPER_BACKSIDE_MAX_WIDTH,
			PORTRAIT_GAME_WORD_PAPER_HEIGHT
		)
	)
	_portrait_game_word_paper_backside_visual.scale = Vector2(fold_curve, 1.0)
	# Never fade the reverse side during unfold. Its visibility is controlled only
	# by the fold geometry and screen clipping.
	_portrait_game_word_paper_backside.modulate.a = 1.0
	_portrait_game_word_paper_backside.visible = (
		reveal > 0.001
		and reveal < 0.999
		and fold_curve > 0.005
	)

func _set_portrait_word_paper_peel_progress(progress: float) -> void:
	var p: float = clampf(progress, 0.0, 1.0)
	if (
		_portrait_game_word_paper_mask == null
		or !is_instance_valid(_portrait_game_word_paper_mask)
		or _portrait_game_word_paper_layer == null
		or !is_instance_valid(_portrait_game_word_paper_layer)
	):
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	# The mask's left edge travels across the physical viewport. Compensate the
	# paper layer by the exact opposite X offset so the front face never scales or
	# slides; only its visible portion is clipped away.
	var mask_x: float = viewport_size.x * p
	_portrait_game_word_paper_mask.visible = p < 0.999
	_portrait_game_word_paper_layer.visible = true
	_portrait_game_word_paper_layer.modulate = Color.WHITE
	_portrait_game_word_paper_mask.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_portrait_game_word_paper_mask.position = Vector2(mask_x, 0.0)
	_portrait_game_word_paper_mask.size = Vector2(
		maxf(1.0, viewport_size.x - mask_x),
		viewport_size.y
	)
	_portrait_game_word_paper_layer.position = Vector2(-mask_x, 0.0)

	if (
		_portrait_game_word_paper_backside == null
		or !is_instance_valid(_portrait_game_word_paper_backside)
		or _portrait_game_word_paper_backside_visual == null
		or !is_instance_valid(_portrait_game_word_paper_backside_visual)
	):
		return

	var fit_scale: float = PORTRAIT_STAGE_LAYOUT.fit_scale(viewport_size)
	if fit_scale <= 0.0:
		return
	var horizontal_offset: float = PORTRAIT_STAGE_LAYOUT.horizontal_offset(viewport_size)
	var fold_stage_x: float = (mask_x - horizontal_offset) / fit_scale
	_portrait_game_word_paper_backside.set(
		"stage_rect",
		Rect2(
			fold_stage_x,
			_portrait_game_word_rect.position.y + PORTRAIT_GAME_WORD_PAPER_Y_OFFSET,
			PORTRAIT_ROUND_END_PAPER_BACKSIDE_MAX_WIDTH,
			PORTRAIT_GAME_WORD_PAPER_HEIGHT
		)
	)
	_portrait_game_word_paper_backside_visual.scale = Vector2(p, 1.0)
	# Entrance fades the reverse side at its endpoints. Reset its opacity here so
	# a later round-end peel always uses the normal fully opaque backside.
	_portrait_game_word_paper_backside.modulate.a = 1.0
	_portrait_game_word_paper_backside.visible = p > 0.001 and p < 0.999

func _replace_portrait_inline_result_word_with_bounce(
	word_color: Color = PORTRAIT_BLUE
) -> void:
	if (
		_portrait_inline_result_word_holder != null
		and is_instance_valid(_portrait_inline_result_word_holder)
	):
		_portrait_inline_result_word_holder.visible = false
		_portrait_inline_result_word_holder.queue_free()
	if (
		_portrait_inline_result_search_button != null
		and is_instance_valid(_portrait_inline_result_search_button)
	):
		_portrait_inline_result_search_button.visible = false
		_portrait_inline_result_search_button.queue_free()
	_portrait_inline_result_word_holder = null
	_portrait_inline_result_search_button = null
	var bounced_controls: Dictionary = _stage_portrait_inline_result_word(true)
	_set_portrait_result_word_color(bounced_controls, word_color)
	_portrait_inline_result_search_button = bounced_controls.get("search_button") as Control

func _start_portrait_inline_result_bounce_during_peel() -> void:
	if _portrait_round_end_bounce_started or !_portrait_round_end_transition_active:
		return
	_portrait_round_end_bounce_started = true
	# Replace the static solved word with the same animated result word once half
	# of the paper has already been uncovered. The still-masked right side remains
	# naturally hidden by the paper while the bounce wave begins on the left.
	_replace_portrait_inline_result_word_with_bounce()

func _portrait_inline_result_title_text() -> String:
	var title: String = Database.tr_text(33, "VICTORY").strip_edges()
	if title.is_empty():
		title = "VICTORY"
	return title

func _show_portrait_inline_result_chrome(is_win: bool, animated: bool) -> void:
	# Only a Single Player victory uses the titled result transition. Every defeat,
	# plus Classic and Two Player victories, uses the shared in-place reveal.
	if !is_win or GameState.current_mode != GameState.GameMode.SINGLE_PLAYER:
		return
	if (
		_portrait_inline_result_title_label != null
		and is_instance_valid(_portrait_inline_result_title_label)
	):
		return
	if _portrait_game_input_group == null or !is_instance_valid(_portrait_game_input_group):
		return

	var previous_content: Control = content
	var game_root := _portrait_game_input_group.get_parent() as Control
	if game_root != null:
		content = game_root
	var title: String = _portrait_inline_result_title_text()
	var title_label := _stage_heading_label(
		PORTRAIT_INLINE_RESULT_TITLE_RECT,
		title,
		38,
		StageLetterButton.CIRCLED_COLOR
	)
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	title_label.clip_text = false
	_fit_single_line_label_to_width(
		title_label,
		title,
		PORTRAIT_INLINE_RESULT_TITLE_RECT.size.x,
		_heading_font_size(38),
		_heading_font_size(23)
	)
	var title_holder := title_label.get_parent() as CanvasItem
	if title_holder != null:
		title_holder.z_index = 50
	_apply_result_text_glow(title_label, Color.WHITE, 2)
	_portrait_inline_result_title_label = title_label

	content = _portrait_game_input_group
	var continue_button := _stage_main_button(
		PORTRAIT_INLINE_RESULT_CONTINUE_BUTTON_RECT,
		_result_continue_action(),
		_result_continue_button_text(),
		_portrait_footer_font_size(22),
		false,
		0.32,
		false,
		false,
		false,
		LONG_BUTTON_COLOR_ORANGE
	)
	if GameState.current_mode == GameState.GameMode.SINGLE_PLAYER:
		_style_single_player_level_button(
			continue_button,
			int(last_result_data.get(
				"single_player_level_index",
				single_player_active_level_index
			))
		)
	continue_button.z_index = 50
	_portrait_inline_result_continue_button = continue_button
	content = previous_content

	if !animated:
		title_label.modulate.a = 1.0
		continue_button.visible = true
		continue_button.modulate.a = 1.0
		continue_button.set("visual_scale", Vector2.ONE)
		return

	title_label.modulate.a = 0.0
	var title_tween := title_label.create_tween()
	title_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var title_fade := title_tween.tween_property(
		title_label,
		"modulate:a",
		1.0,
		PORTRAIT_INLINE_RESULT_TITLE_FADE_DURATION
	)
	title_fade.set_trans(Tween.TRANS_QUAD)
	title_fade.set_ease(Tween.EASE_OUT)

	continue_button.visible = true
	continue_button.modulate.a = 0.0
	continue_button.set(
		"visual_scale",
		Vector2.ONE * PORTRAIT_INLINE_RESULT_CONTINUE_START_SCALE
	)
	var continue_alpha := continue_button.create_tween()
	continue_alpha.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	continue_alpha.tween_property(
		continue_button,
		"modulate:a",
		1.0,
		PORTRAIT_INLINE_RESULT_CONTINUE_GROW_DURATION
	)
	var continue_bounce := continue_button.create_tween()
	continue_bounce.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var grow := continue_bounce.tween_property(
		continue_button,
		"visual_scale",
		Vector2.ONE * PORTRAIT_INLINE_RESULT_CONTINUE_PEAK_SCALE,
		PORTRAIT_INLINE_RESULT_CONTINUE_GROW_DURATION
	)
	grow.set_trans(Tween.TRANS_BACK)
	grow.set_ease(Tween.EASE_OUT)
	var settle := continue_bounce.tween_property(
		continue_button,
		"visual_scale",
		Vector2.ONE,
		PORTRAIT_INLINE_RESULT_CONTINUE_SETTLE_DURATION
	)
	settle.set_trans(Tween.TRANS_BOUNCE)
	settle.set_ease(Tween.EASE_OUT)

func _peel_portrait_word_paper_for_round_end(animated: bool) -> void:
	if _portrait_game_word_paper_layer == null or !is_instance_valid(_portrait_game_word_paper_layer):
		_finish_portrait_word_paper_peel(null, animated)
		return
	var paper_layer: Control = _portrait_game_word_paper_layer
	paper_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if !animated:
		if _portrait_game_word_paper_mask != null and is_instance_valid(_portrait_game_word_paper_mask):
			_portrait_game_word_paper_mask.visible = false
		if _portrait_game_word_paper_backside != null and is_instance_valid(_portrait_game_word_paper_backside):
			_portrait_game_word_paper_backside.visible = false
		paper_layer.visible = false
		_finish_portrait_word_paper_peel(paper_layer, false)
		return

	_set_portrait_word_paper_peel_progress(0.0)
	_portrait_round_end_bounce_started = false
	var flip_tween := create_tween()
	flip_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var mask_tweener := flip_tween.tween_method(
		Callable(self, "_set_portrait_word_paper_peel_progress"),
		0.0,
		1.0,
		PORTRAIT_ROUND_END_PAPER_FLIP_DURATION
	)
	# Start the sheet movement visibly on the same frame as the first keyboard
	# fade. EASE_OUT removes the old slow ease-in that made the paper appear to
	# wait even though both tweens were created together.
	mask_tweener.set_trans(Tween.TRANS_QUAD)
	mask_tweener.set_ease(Tween.EASE_OUT)
	flip_tween.finished.connect(
		Callable(self, "_finish_portrait_word_paper_peel").bind(paper_layer, false),
		CONNECT_ONE_SHOT
	)

	var bounce_start_tween := create_tween()
	bounce_start_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	bounce_start_tween.tween_interval(PORTRAIT_ROUND_END_PAPER_FLIP_DURATION * 0.5)
	bounce_start_tween.tween_callback(
		Callable(self, "_start_portrait_inline_result_bounce_during_peel")
	)

func _hide_portrait_hero_after_word_paper(animated: bool) -> void:
	# The character stays visible through the entire keyboard/paper exit. Only once
	# the sheet has fully finished peeling do we remove the character, for both
	# victory and defeat. Restored finished rounds skip the tween and stay hidden.
	if hero_static_symbol == null or !is_instance_valid(hero_static_symbol):
		return
	if !animated:
		hero_static_symbol.modulate.a = 0.0
		return
	var hero_fade_tween := hero_static_symbol.create_tween()
	hero_fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var fade := hero_fade_tween.tween_property(
		hero_static_symbol,
		"modulate:a",
		0.0,
		PORTRAIT_GAME_HERO_EXIT_FADE_DURATION
	)
	fade.set_trans(Tween.TRANS_QUAD)
	fade.set_ease(Tween.EASE_OUT)

func _finalize_portrait_word_paper_peel_visuals(paper_layer: Control) -> void:
	if paper_layer != null and is_instance_valid(paper_layer):
		paper_layer.visible = false
	if _portrait_game_word_paper_mask != null and is_instance_valid(_portrait_game_word_paper_mask):
		_portrait_game_word_paper_mask.visible = false
	if _portrait_game_word_paper_backside != null and is_instance_valid(_portrait_game_word_paper_backside):
		_portrait_game_word_paper_backside.visible = false
	if (
		_portrait_game_word_paper_backside_visual != null
		and is_instance_valid(_portrait_game_word_paper_backside_visual)
	):
		_portrait_game_word_paper_backside_visual.scale = Vector2(0.0, 1.0)

func _finish_portrait_word_paper_peel(paper_layer: Control, play_result_bounce: bool = false) -> void:
	var animate_result_chrome: bool = _portrait_round_end_transition_active
	_finalize_portrait_word_paper_peel_visuals(paper_layer)

	_hide_portrait_hero_after_word_paper(animate_result_chrome)

	# Animated exits now start the result bounce at 50% paper progress. Keep the
	# old boolean path only as a safe fallback for direct/nonstandard callers.
	if play_result_bounce and !_portrait_round_end_bounce_started:
		_start_portrait_inline_result_bounce_during_peel()
	elif !play_result_bounce and !_portrait_round_end_bounce_started:
		if (
			_portrait_inline_result_search_button != null
			and is_instance_valid(_portrait_inline_result_search_button)
		):
			_portrait_inline_result_search_button.set("disabled", false)

	_portrait_round_end_transition_active = false
	_portrait_inline_result_visible = true
	# The dedicated result screen is no longer part of the round flow. Once the
	# keyboard, attempts, hints and paper have all cleared, reveal the result title
	# and the Continue action directly on the gameplay screen.
	_show_portrait_inline_result_chrome(last_result_is_win, animate_result_chrome)

func _begin_portrait_inline_word_reveal(animated: bool) -> void:
	if !_portrait_round_end_transition_active and animated:
		return
	var result_controls: Dictionary = _stage_portrait_inline_result_word(false)
	_portrait_inline_result_search_button = result_controls.get("search_button") as Control
	if (
		_portrait_inline_result_search_button != null
		and is_instance_valid(_portrait_inline_result_search_button)
	):
		_portrait_inline_result_search_button.set("disabled", animated)
		# The static solved word sits under the peeling sheet, but its search button
		# must not peek out early. The animated result recreates this button hidden
		# and reveals it only after the bounce wave has passed the final letter.
		_portrait_inline_result_search_button.visible = !animated
	_peel_portrait_word_paper_for_round_end(animated)

func _show_portrait_inline_round_result(
	is_win: bool,
	data: Dictionary,
	animated: bool = true
) -> void:
	if !is_win or GameState.current_mode != GameState.GameMode.SINGLE_PLAYER:
		_show_in_place_round_result(is_win, animated)
		return
	if _portrait_round_end_transition_active or _portrait_inline_result_visible:
		return
	if (
		_portrait_game_input_group == null
		or !is_instance_valid(_portrait_game_input_group)
	):
		return
	_stop_portrait_attempts_attention_bounce(true)
	_play_result_sound_once(is_win, data)
	_portrait_round_end_transition_active = animated

	# Attempts, hints, keyboard and paper all start their exit on the same frame.
	# Hints fade as a single row while keyboard letters keep their left-to-right
	# scale/fade wave; the slower paper turn overlaps both animations.
	_hide_portrait_attempts_for_round_end(animated)
	_hide_portrait_hints_for_round_end(animated)
	_hide_portrait_keyboard_for_round_end(animated)
	_begin_portrait_inline_word_reveal(animated)

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
	_stage_currency_counter(Callable(self, "_show_coin_store_tab"))
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
