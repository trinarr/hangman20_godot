extends "res://scripts/main.gd"

const PORTRAIT_UI_PALETTE: GDScript = preload("res://scripts/ui/ui_palette.gd")
const PORTRAIT_ADAPTIVE_GROUP_SCRIPT: GDScript = preload("res://scripts/ui/portrait_adaptive_group.gd")
const PORTRAIT_STAGE_LAYOUT: GDScript = preload("res://scripts/ui/portrait_stage_layout.gd")
const STAGE_WORD_INPUT_SCRIPT: GDScript = preload("res://scripts/ui/stage_word_input.gd")
const RESULT_WORD_BOUNCE_EFFECT_SCRIPT: GDScript = preload("res://scripts/ui/result_word_bounce_effect.gd")
const COIN_PACK_02_TEXTURE: Texture2D = preload("res://flash_assets/soft_currency_coin_pile.png")
const COIN_PACK_04_TEXTURE: Texture2D = preload("res://flash_assets/coin_pack_04.png")
const COIN_PACK_05_TEXTURE: Texture2D = preload("res://flash_assets/coin_pack_05.png")
const COIN_PACK_06_LARGE_TEXTURE: Texture2D = preload("res://flash_assets/coin_pack_06_large.png")
const REWARD_COIN_TEXTURE: Texture2D = preload("res://flash_assets/coin_pack_01_small.png")
const REWARD_STATUS_CHECK_TEXTURE: Texture2D = preload("res://flash_assets/reward_status_check_wide.png")
const REWARD_STATUS_CROSS_TEXTURE: Texture2D = preload("res://flash_assets/reward_status_cross_wide.png")
const WATCH_AD_ICON_TEXTURE: Texture2D = preload("res://flash_assets/watch_ad_icon.png")
const HEART_RECOVERY_CLOCK_TEXTURE: Texture2D = preload("res://flash_assets/heart_recovery_clock.png")
const MAIN_MENU_LOGO_TEXTURE: Texture2D = preload("res://flash_assets/main_menu_logo_hangman_20.png")
const FINAL_REWARD_ROTATING_GLOW_TEXTURE: Texture2D = preload(
	"res://flash_assets/final_reward_rotating_glow.png"
)

const PORTRAIT_STAGE_SIZE := Vector2(480.0, 800.0)
const PORTRAIT_HEADER_HEIGHT: float = 80.0
const PORTRAIT_FOOTER_Y: float = 688.0
const PORTRAIT_AD_BANNER_FALLBACK_HEIGHT: float = 50.0
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
# Regular screens use a centered coins-and-hearts block. Gameplay deliberately
# keeps only its coin plate centered, leaving the life inventory off the round.
const PORTRAIT_RESOURCE_COUNTER_GAP: float = 28.0
# Both resource plates are 10% wider than the original 109.94 px layout. Shift
# the complete pair left by the same added half-width so it stays centered.
const PORTRAIT_CURRENCY_COUNTER_RECT := Rect2(105.066, 21.68, 120.934, 38.64)
const PORTRAIT_GAME_CURRENCY_COUNTER_RECT := PORTRAIT_CURRENCY_COUNTER_RECT
const PORTRAIT_CURRENCY_ICON_SIZE: float = 35.42
const PORTRAIT_HEART_ICON_ASPECT_RATIO: float = 84.0 / 76.0
const PORTRAIT_HEART_ICON_LEFT_INSET: float = 2.0
const PORTRAIT_CURRENCY_COUNTER_PRESSED_SCALE: float = 0.94
const PORTRAIT_CURRENCY_COUNTER_PRESS_DURATION: float = 0.055
const PORTRAIT_CURRENCY_COUNTER_RELEASE_DURATION: float = 0.085
const PORTRAIT_CURRENCY_ADD_BADGE_SIZE: float = 20.0
const PORTRAIT_CURRENCY_ADD_BADGE_GREEN := PORTRAIT_UI_PALETTE.SUCCESS
const PORTRAIT_FREE_HINT_BADGE_GREEN := PORTRAIT_UI_PALETTE.SUCCESS_SOFT
const PORTRAIT_CURRENCY_ADD_BADGE_BORDER := PORTRAIT_UI_PALETTE.SUCCESS_BORDER
const PORTRAIT_MAIN_NAV_Y: float = 725.0
const PORTRAIT_MAIN_NAV_HEIGHT: float = 75.0
const PORTRAIT_MAIN_NAV_TAB_COUNT: int = 3
const PORTRAIT_MAIN_NAV_ITEM_WIDTH: float = 160.0
const PORTRAIT_MAIN_NAV_ACTIVE_RECT_SIZE := Vector2(156.0, 92.0)
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
const PORTRAIT_SMALL_BUTTON_SIZE := Vector2(196.0, 58.0)
const PORTRAIT_FOOTER_LONG_BUTTON_WIDTH_SCALE: float = 0.85
const PORTRAIT_FOOTER_CONTROL_SCALE: float = 1.10
const PORTRAIT_FOOTER_CENTER_LONG_BUTTON_RECT := Rect2(90.0, 711.0, PORTRAIT_LONG_BUTTON_SIZE.x, PORTRAIT_LONG_BUTTON_SIZE.y)
const PORTRAIT_GAME_ACTION_Y_SCALE: float = 0.95
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
const PORTRAIT_INLINE_RESULT_CONTINUE_GROW_DURATION: float = 0.12
# Reward-screen hero is deliberately only 17% larger than the in-round hero.
# The X offset scales with the hero so the visible artwork (not the Flash origin)
# stays centered on the 480 px portrait stage.
const PORTRAIT_SINGLE_REWARD_HERO_SCALE_MULTIPLIER: float = PORTRAIT_GAME_HERO_SCALE_MULTIPLIER * 1.17
const PORTRAIT_SINGLE_REWARD_HERO_POSITION := Vector2(
	PORTRAIT_STAGE_SIZE.x * 0.5 - PORTRAIT_TWO_PLAYER_HERO_VISUAL_CENTER_OFFSET_X * 1.17,
	525.0
)
# Approximate visible bottom of the clean reward hero in authored stage space.
# The chain position is resolved at runtime from this edge and the physical
# position of the bottom-attached Continue button, so it stays visually centered
# between the character and CTA on both 16:9 and extra-tall phones.
const PORTRAIT_SINGLE_REWARD_HERO_VISUAL_BOTTOM_Y: float = 530.0
const PORTRAIT_SINGLE_REWARD_NODE_MAX_SIZE: float = 102.0
const PORTRAIT_SINGLE_REWARD_NODE_GAP: float = 14.0
const PORTRAIT_SINGLE_REWARD_CHAIN_LINK_THICKNESS: float = 6.0
const PORTRAIT_SINGLE_REWARD_CHAIN_LINK_OVERLAP: float = 10.0
const PORTRAIT_SINGLE_REWARD_CHAIN_LINK_COLOR := PORTRAIT_UI_PALETTE.REWARD_CHAIN
const PORTRAIT_SINGLE_REWARD_CURRENT_NODE_SCALE: float = 1.20
const PORTRAIT_SINGLE_REWARD_SIDE_NODE_SCALE: float = 0.90
const PORTRAIT_SINGLE_REWARD_CHAIN_ICON_SCALE: float = 0.72
const PORTRAIT_SINGLE_REWARD_CHAIN_COUNT_FONT_SIZE: int = 22
const PORTRAIT_SINGLE_REWARD_CHAIN_COUNT_MIN_FONT_SIZE: int = 15
const PORTRAIT_SINGLE_REWARD_STATUS_ICON_SCALE: float = 0.574
const PORTRAIT_SINGLE_REWARD_CROWN_WIDTH_RATIO: float = 0.46
const PORTRAIT_SINGLE_REWARD_CROWN_HEIGHT_RATIO: float = 0.28
const PORTRAIT_SINGLE_REWARD_CROWN_FILL := PORTRAIT_UI_PALETTE.REWARD_GOLD
const PORTRAIT_SINGLE_REWARD_CROWN_BAND := PORTRAIT_UI_PALETTE.REWARD_GOLD_DARK
const PORTRAIT_SINGLE_REWARD_CROWN_OUTLINE := PORTRAIT_UI_PALETTE.REWARD_GOLD_OUTLINE
const PORTRAIT_SINGLE_REWARD_CROWN_FLY_OFFSET := Vector2(34.0, -52.0)
const PORTRAIT_SINGLE_REWARD_CROWN_FLY_DURATION: float = 0.38
const PORTRAIT_SINGLE_REWARD_CHECK_COIN_DIM_ALPHA: float = 0.45
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
const PORTRAIT_SINGLE_REWARD_TITLE_FONT_SIZE: int = 46
const PORTRAIT_SINGLE_REWARD_SUBTITLE_FONT_SIZE: int = 24
const PORTRAIT_SINGLE_REWARD_TITLE_BLOCK_HEIGHT: float = 112.0
const PORTRAIT_SINGLE_REWARD_FAILURE_TITLE_COLOR := PORTRAIT_UI_PALETTE.ERROR_SOFT
const PORTRAIT_SINGLE_REWARD_SUCCESS_TITLE_COLOR := PORTRAIT_UI_PALETTE.SUCCESS_SOFT
const PORTRAIT_SINGLE_REWARD_TITLE_BLOCK_COLOR := PORTRAIT_UI_PALETTE.REWARD_HEADER
const PORTRAIT_SINGLE_REWARD_TITLE_BLOCK_TOP_RECT := Rect2(
	0.0,
	PORTRAIT_HEADER_HEIGHT,
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
const PORTRAIT_SINGLE_REWARD_TITLE_TOP_PADDING: float = 10.0
const PORTRAIT_SINGLE_REWARD_TITLE_HEIGHT: float = 52.0
const PORTRAIT_SINGLE_REWARD_SUBTITLE_TOP: float = 10.0
const PORTRAIT_SINGLE_REWARD_SUBTITLE_HEIGHT: float = 32.0
const PORTRAIT_SINGLE_REWARD_TITLE_START_SCALE: float = 0.52
const PORTRAIT_SINGLE_REWARD_TITLE_PEAK_SCALE: float = 1.14
const PORTRAIT_SINGLE_REWARD_TITLE_GROW_DURATION: float = 0.16
const PORTRAIT_SINGLE_REWARD_TITLE_SETTLE_DURATION: float = 0.20
const PORTRAIT_SINGLE_REWARD_TITLE_MOVE_DURATION: float = 0.28
const PORTRAIT_SINGLE_REWARD_BODY_FADE_DURATION: float = 0.16
const PORTRAIT_FINAL_REWARD_GLOW_SIZE := Vector2(316.0, 316.0)
const PORTRAIT_FINAL_REWARD_COIN_SIZE := Vector2(172.8, 172.8)
const PORTRAIT_FINAL_REWARD_CAPTION_SIZE := Vector2(340.0, 42.0)
const PORTRAIT_FINAL_REWARD_CAPTION_GAP: float = 82.0
const PORTRAIT_FINAL_REWARD_CAPTION_FONT_SIZE: int = 38
const PORTRAIT_FINAL_REWARD_AMOUNT_SIZE := Vector2(300.0, 58.0)
const PORTRAIT_FINAL_REWARD_COUNT_FONT_SIZE: int = 40
const PORTRAIT_FINAL_REWARD_DOUBLE_BUTTON_RECT := Rect2(
	90.0,
	606.0 * PORTRAIT_GAME_ACTION_Y_SCALE,
	300.0,
	64.0
)
const PORTRAIT_FINAL_REWARD_COLLECT_RECT := Rect2(
	90.0,
	690.0 * PORTRAIT_GAME_ACTION_Y_SCALE,
	300.0,
	45.0
)
const PORTRAIT_FINAL_REWARD_CHAIN_HOLD_DURATION: float = 0.252
const PORTRAIT_FINAL_REWARD_ICON_CROSSFADE_DURATION: float = 0.162
const PORTRAIT_FINAL_REWARD_REPLACE_DURATION: float = 0.414
const PORTRAIT_FINAL_REWARD_BACKGROUND_FADE_DURATION: float = 0.558
const PORTRAIT_FINAL_REWARD_PACK_BOUNCE_SCALE: float = 1.18
const PORTRAIT_FINAL_REWARD_PACK_BOUNCE_GROW_DURATION: float = 0.162
const PORTRAIT_FINAL_REWARD_PACK_BOUNCE_SETTLE_DURATION: float = 0.27
const PORTRAIT_FINAL_REWARD_GLOW_ROTATION_DURATION: float = 14.0
const PORTRAIT_FINAL_REWARD_ACTION_REVEAL_DURATION: float = 0.162
const PORTRAIT_FINAL_REWARD_COLLECT_DELAY: float = 0.9
const PORTRAIT_FINAL_REWARD_GLOW_ALPHA: float = 0.7
const PORTRAIT_FINAL_REWARD_DOUBLE_BUTTON_BONUS_COIN_SIZE := Vector2(28.0, 28.0)
const PORTRAIT_FINAL_REWARD_DOUBLE_BUTTON_PLAY_GAP: float = -8.0
const PORTRAIT_FINAL_REWARD_DOUBLE_BUTTON_BONUS_GAP: float = 6.0
const PORTRAIT_FINAL_REWARD_HOME_COUNT_DURATION: float = 1.36
const PORTRAIT_CURRENCY_ICON_REWARD_BOUNCE_PEAK_SCALE: float = 1.22
const PORTRAIT_CURRENCY_COUNTER_REWARD_BOUNCE_PEAK_SCALE: float = 1.06
const PORTRAIT_CURRENCY_ICON_REWARD_BOUNCE_GROW_DURATION: float = 0.035
const PORTRAIT_CURRENCY_ICON_REWARD_BOUNCE_SETTLE_DURATION: float = 0.050
const PORTRAIT_EXTRA_ATTEMPT_HERO_FADE_OUT_DURATION: float = 0.3
const PORTRAIT_EXTRA_ATTEMPT_HERO_FADE_IN_DURATION: float = 0.28
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
const PORTRAIT_NAV_HOME_ICON: Texture2D = preload("res://flash_assets/nav_home_icon.png")
const PORTRAIT_NAV_TASKS_ICON: Texture2D = preload("res://flash_assets/nav_tasks_icon.png")
const PORTRAIT_MENU_SETTINGS_ICON: Texture2D = preload("res://flash_assets/settings_gear_icon.png")
const PORTRAIT_GAME_WORD_PAPER_TEXTURE: Texture2D = preload("res://flash_assets/word_paper_torn.png")
const PORTRAIT_GAME_WORD_PAPER_BACKSIDE_TEXTURE: Texture2D = preload("res://flash_assets/word_paper_backside.png")

const PORTRAIT_BLUE := PORTRAIT_UI_PALETTE.UI_BLUE
const PORTRAIT_DARK_BLUE := PORTRAIT_UI_PALETTE.UI_BLUE_DARK
const PORTRAIT_CHALLENGE_POPUP_HEADER := PORTRAIT_UI_PALETTE.CHALLENGE_SELECTED
const PORTRAIT_CHALLENGE_POPUP_BODY := PORTRAIT_UI_PALETTE.CHALLENGE_BODY
const PORTRAIT_CHALLENGE_POPUP_SEPARATOR := PORTRAIT_UI_PALETTE.CHALLENGE_NORMAL
const PORTRAIT_CHALLENGE_THEME_CARD := PORTRAIT_UI_PALETTE.CHALLENGE_THEME_CARD
const PORTRAIT_CHALLENGE_THEME_CARD_SELECTED := PORTRAIT_UI_PALETTE.CHALLENGE_THEME_CARD_SELECTED
const PORTRAIT_CHALLENGE_HUD_PANEL := PORTRAIT_UI_PALETTE.CHALLENGE_HUD_PANEL
const PORTRAIT_CHALLENGE_HUD_BORDER := PORTRAIT_UI_PALETTE.CHALLENGE_HUD_BORDER
const PORTRAIT_INSUFFICIENT_PRICE_COLOR := PORTRAIT_UI_PALETTE.PRICE_ERROR
const PORTRAIT_ORANGE := PORTRAIT_UI_PALETTE.ACCENT_ORANGE
const PORTRAIT_RULE := PORTRAIT_UI_PALETTE.UI_BLUE_RULE
const PORTRAIT_AD_BADGE_PURPLE := PORTRAIT_UI_PALETTE.AD_PURPLE
const PORTRAIT_POPUP_DIM_ALPHA: float = 0.874
const PORTRAIT_POPUP_CLOSE_SIZE: float = PORTRAIT_ROUND_BUTTON_SIZE * 1.20
const PORTRAIT_POPUP_CLOSE_ICON_FONT_SIZE: int = 39
const PORTRAIT_POPUP_CLOSE_GAP: float = 48.0
const PORTRAIT_POPUP_CORNER_RADIUS: float = 26.0
const PORTRAIT_POPUP_TOP_TRIM: float = 51.3
const PORTRAIT_POPUP_TITLE_SCALE: float = 1.22
const PORTRAIT_POPUP_BUTTON_UNIFORM_SCALE: float = 1.15
const PORTRAIT_POPUP_BUTTON_LENGTH_SCALE: float = 0.85
const PORTRAIT_POPUP_LONG_BUTTON_MIN_SOURCE_WIDTH: float = 280.0
const PORTRAIT_POPUP_LONG_BUTTON_WIDTH: float = 313.6
const PORTRAIT_POPUP_BOTTOM_BUTTON_GAP: float = 18.0
const PORTRAIT_SINGLE_PLAYER_REFRESH_BUTTON_SCALE: float = 1.10
const PORTRAIT_SINGLE_PLAYER_THEME_CARD_ICON_SIZE: float = 75.14
const PORTRAIT_SINGLE_PLAYER_THEME_CARD_GLOW_SCALE: float = 1.8
const PORTRAIT_SINGLE_PLAYER_THEME_CARD_GLOW_ALPHA: float = 0.46
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
const PORTRAIT_GAME_HINT_BUTTON_SIZE := Vector2.ONE * (PORTRAIT_ROUND_BUTTON_SIZE * 1.144)
const PORTRAIT_GAME_RETRY_BUTTON_SIZE := Vector2(PORTRAIT_LONG_BUTTON_SIZE.x, PORTRAIT_LONG_BUTTON_SIZE.y)
const PORTRAIT_GAME_HINT_KEYBOARD_GAP: float = 40.0
const PORTRAIT_GAME_HINT_Y: float = 650.0
const PORTRAIT_GAME_HINT_OPEN_BUTTON_RECT := Rect2(108.176, PORTRAIT_GAME_HINT_Y - 3.0, PORTRAIT_GAME_HINT_BUTTON_SIZE.x, PORTRAIT_GAME_HINT_BUTTON_SIZE.y)
const PORTRAIT_GAME_HINT_REMOVE_BUTTON_RECT := Rect2(203.392, PORTRAIT_GAME_HINT_Y - 3.0, PORTRAIT_GAME_HINT_BUTTON_SIZE.x, PORTRAIT_GAME_HINT_BUTTON_SIZE.y)
const PORTRAIT_GAME_HINT_COMMENT_BUTTON_RECT := Rect2(298.608, PORTRAIT_GAME_HINT_Y - 3.0, PORTRAIT_GAME_HINT_BUTTON_SIZE.x, PORTRAIT_GAME_HINT_BUTTON_SIZE.y)
const PORTRAIT_GAME_HINT_ART_SIZE := Vector2(50.0, 50.0)
const PORTRAIT_GAME_HINT_ART_RISE: float = -5.0
const PORTRAIT_GAME_HINT_COMMENT_ART_Y_OFFSET: float = -4.0
const PORTRAIT_GAME_HINT_COUNTER_SIZE: float = 28.0
const PORTRAIT_WORD_LETTER_BOUNCE_START_SCALE := Vector2(0.58, 0.58)
const PORTRAIT_WORD_LETTER_BOUNCE_PEAK_SCALE := Vector2(1.24, 1.24)
const PORTRAIT_WORD_LETTER_BOUNCE_GROW_DURATION: float = 0.18
const PORTRAIT_WORD_LETTER_BOUNCE_SETTLE_DURATION: float = 0.24
const PORTRAIT_CUSTOM_WORD_INPUT_RECT := Rect2(22.0, 0.0, 436.0, 72.0)
const PORTRAIT_CUSTOM_WORD_BUTTON_RISE: float = 64.0
const PORTRAIT_CUSTOM_WORD_CHECK_RECT := Rect2(94.0, 518.0, PORTRAIT_LONG_BUTTON_SIZE.x, PORTRAIT_LONG_BUTTON_SIZE.y)
const PORTRAIT_CUSTOM_WORD_RANDOM_RECT := Rect2(94.0, 592.0, PORTRAIT_LONG_BUTTON_SIZE.x, PORTRAIT_LONG_BUTTON_SIZE.y)
const PORTRAIT_COIN_STORE_PACK_AMOUNTS: Array[int] = [25, 60, 100, 150, 300, 500]
const PORTRAIT_COIN_STORE_CARD_SIZE := Vector2(132.0, 220.0)
const PORTRAIT_COIN_STORE_GRID_ORIGIN := Vector2(26.0, 174.0)
const PORTRAIT_COIN_STORE_COLUMN_GAP: float = 16.0
const PORTRAIT_COIN_STORE_ROW_GAP: float = 22.0
const PORTRAIT_COIN_STORE_ICON_SIZE := Vector2(112.0, 112.0)
const PORTRAIT_COIN_STORE_AMOUNT_RECT := Rect2(8.0, 156.0, 116.0, 54.0)

enum MainTab {
	TASKS,
	HOME,
	PROFILE,
}

var _main_menu_logo_runtime_texture: Texture2D = null
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
var _portrait_game_back_button: Control = null
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
var _portrait_round_end_bounce_started: bool = false
var _portrait_inline_result_search_button: Control = null
var _portrait_inline_result_word_holder: Control = null
var _portrait_inline_result_marker_holder: Control = null
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
var _portrait_main_tab_swipe_origin_references: Dictionary = {}
var _portrait_main_tab_swipe_building_target: bool = false
var _portrait_main_tab_swipe_animating: bool = false
var _portrait_top_bar_content: Control = null
var _portrait_active_currency_counter_rect: Rect2 = PORTRAIT_CURRENCY_COUNTER_RECT
var _portrait_coin_store_active: bool = false
var _portrait_back_button_visible: bool = false
var _portrait_previous_screen_had_back: bool = false
var _portrait_last_animated_reward_claim_key: String = ""
var _portrait_single_reward_resume_without_intro: bool = false
var _portrait_final_reward_claim_in_progress: bool = false
var _portrait_final_reward_waiting_for_ad: bool = false
var _portrait_final_reward_earned_ad_reward: bool = false
var _portrait_final_reward_double_button: Control = null
var _portrait_rewarded_action: StringName = &""
var _portrait_rewarded_action_earned: bool = false
var _portrait_rewarded_action_level_index: int = -1
var _portrait_pending_home_reward_amount: int = 0
var _portrait_hint_counter_animation_active: bool = false
var _portrait_hint_counter_refresh_requested: bool = false
const PORTRAIT_BUTTON_BADGE_STATE_COINS := "coins"
const PORTRAIT_BUTTON_BADGE_STATE_AD := "ad"
const PORTRAIT_BUTTON_BADGE_STATE_FREE := "free"
var _profile_name_edit: LineEdit = null
var _profile_edit_character_id: int = 1
var _profile_avatar_checks: Dictionary = {}
var _profile_avatar_halos: Dictionary = {}
var single_player_popup_refresh_button: Control = null
var _single_player_popup_refresh_visuals: Array[CanvasItem] = []
var _single_player_popup_refresh_badge_component: Dictionary = {}
var _single_player_popup_refresh_price_badge: Control = null
var _single_player_popup_refresh_badge_shadow: Control = null
var _single_player_popup_refresh_price_coin: CanvasItem = null
var _single_player_popup_refresh_ad_icon: CanvasItem = null
var _single_player_popup_theme_card_visuals: Array = []
var _single_player_theme_slot_animation_nodes: Array[Node] = []
var _single_player_theme_slot_tweens: Array[Tween] = []
var _single_player_theme_slot_animating: bool = false
var _single_player_theme_slot_hide_actions: bool = false
var _single_player_theme_slot_generation: int = 0
var _single_player_theme_slot_final_selection: int = -1
var _single_player_theme_reroll_level_index: int = -1
var _single_player_theme_reroll_used: bool = false
var _single_player_theme_ad_reroll_used: bool = false

func _portrait_ads_service() -> Node:
	return get_node_or_null("/root/YandexAdsService")

func _portrait_ad_banner_height_stage() -> float:
	var ads_service: Node = _portrait_ads_service()
	if ads_service == null or !ads_service.has_method("get_banner_dimension"):
		return PORTRAIT_AD_BANNER_FALLBACK_HEIGHT
	var banner_size_pixels: Vector2 = ads_service.call("get_banner_dimension")
	var window_size: Vector2i = DisplayServer.window_get_size()
	if banner_size_pixels.y <= 0.0 or window_size.x <= 0:
		return PORTRAIT_AD_BANNER_FALLBACK_HEIGHT
	# The portrait stage is fitted to the full physical window width. Convert the
	# native Android banner height back into authored 480-wide stage coordinates.
	return maxf(
		PORTRAIT_AD_BANNER_FALLBACK_HEIGHT,
		banner_size_pixels.y * PORTRAIT_STAGE_SIZE.x / float(window_size.x)
	)

func _portrait_ad_banner_rect() -> Rect2:
	var banner_height: float = _portrait_ad_banner_height_stage()
	return Rect2(
		0.0,
		PORTRAIT_STAGE_SIZE.y - banner_height,
		PORTRAIT_STAGE_SIZE.x,
		banner_height
	)

func _hide_portrait_ad_banner() -> void:
	var ads_service: Node = _portrait_ads_service()
	if ads_service != null and ads_service.has_method("hide_banner"):
		ads_service.call("hide_banner")

func _clear() -> void:
	_hide_portrait_ad_banner()
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
	_portrait_game_back_button = null
	_portrait_final_reward_double_button = null
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
	_portrait_inline_result_search_button = null
	_portrait_inline_result_word_holder = null
	_portrait_inline_result_marker_holder = null
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
		_portrait_active_main_tab >= MainTab.TASKS
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
	_portrait_main_tab_swipe_origin_references.clear()
	_portrait_main_tab_swipe_building_target = false
	_portrait_main_tab_swipe_animating = false

func _capture_portrait_main_tab_swipe_origin_references() -> void:
	_portrait_main_tab_swipe_origin_references = {
		"top_bar": _portrait_top_bar_content,
		"currency_counter_visual": _portrait_currency_counter_visual,
		"currency_coin_icon_visual": _portrait_currency_coin_icon_visual,
		"heart_icon_visual": _portrait_heart_icon_visual,
		"currency_counter_rect": _portrait_active_currency_counter_rect,
		"currency_balance_label": currency_balance_label,
		"heart_count_label": heart_count_label,
		"heart_status_label": heart_status_label,
		"heart_add_badge_visual": heart_add_badge_visual,
		"heart_counter_button": heart_counter_button,
		"coin_store_return_action": coin_store_return_action,
	}

func _restore_portrait_main_tab_swipe_origin_references() -> void:
	if _portrait_main_tab_swipe_origin_references.is_empty():
		return
	_portrait_top_bar_content = _portrait_main_tab_swipe_origin_references.get("top_bar") as Control
	_portrait_currency_counter_visual = _portrait_main_tab_swipe_origin_references.get(
		"currency_counter_visual"
	) as Control
	_portrait_currency_coin_icon_visual = _portrait_main_tab_swipe_origin_references.get(
		"currency_coin_icon_visual"
	) as Control
	_portrait_heart_icon_visual = _portrait_main_tab_swipe_origin_references.get(
		"heart_icon_visual"
	) as Control
	_portrait_active_currency_counter_rect = _portrait_main_tab_swipe_origin_references.get(
		"currency_counter_rect",
		PORTRAIT_CURRENCY_COUNTER_RECT
	)
	currency_balance_label = _portrait_main_tab_swipe_origin_references.get(
		"currency_balance_label"
	) as Label
	heart_count_label = _portrait_main_tab_swipe_origin_references.get("heart_count_label") as Label
	heart_status_label = _portrait_main_tab_swipe_origin_references.get("heart_status_label") as Label
	heart_add_badge_visual = _portrait_main_tab_swipe_origin_references.get(
		"heart_add_badge_visual"
	) as Control
	heart_counter_button = _portrait_main_tab_swipe_origin_references.get(
		"heart_counter_button"
	) as Control
	var saved_return_action: Variant = _portrait_main_tab_swipe_origin_references.get(
		"coin_store_return_action",
		Callable()
	)
	coin_store_return_action = Callable()
	if saved_return_action is Callable:
		coin_store_return_action = saved_return_action

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
		MainTab.TASKS,
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
	_capture_portrait_main_tab_swipe_origin_references()
	_portrait_main_tab_swipe_building_target = true
	tab_action.call()
	_portrait_main_tab_swipe_building_target = false

	_portrait_main_tab_swipe_target_content = content
	if (
		_portrait_main_tab_swipe_target_content == null
		or !is_instance_valid(_portrait_main_tab_swipe_target_content)
		or _portrait_main_tab_swipe_target_content == _portrait_main_tab_swipe_departing_content
	):
		_restore_portrait_main_tab_swipe_origin_references()
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
		# Home no longer owns the shared bottom navigation: its lower edge is
		# reserved for the advertising banner. Profile and Classic keep their
		# existing navigation implementation so they can be wired to new entry
		# points later without rebuilding either screen.
		if target_tab == MainTab.HOME:
			_portrait_active_main_tab = -1
		else:
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
	_restore_portrait_main_tab_swipe_origin_references()
	_portrait_active_main_tab = origin_tab
	_clear_portrait_main_tab_swipe_transition()

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

func _fit_stage_rect_keep_aspect(bounds: Rect2, source_size: Vector2) -> Rect2:
	if source_size.x <= 0.0 or source_size.y <= 0.0:
		return bounds
	var fit_scale: float = min(bounds.size.x / source_size.x, bounds.size.y / source_size.y)
	var fitted_size: Vector2 = source_size * fit_scale
	return Rect2(bounds.get_center() - fitted_size * 0.5, fitted_size)

func _get_main_menu_logo_texture() -> Texture2D:
	if _main_menu_logo_runtime_texture != null:
		return _main_menu_logo_runtime_texture
	var image: Image = Image.new()
	var load_error: int = image.load("res://flash_assets/main_menu_logo_hangman_20.png")
	if load_error == OK and !image.is_empty():
		_main_menu_logo_runtime_texture = ImageTexture.create_from_image(image)
		return _main_menu_logo_runtime_texture
	return MAIN_MENU_LOGO_TEXTURE

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
	currency_return_action: Callable = Callable(),
	show_heart_counter: bool = true
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
	if show_heart_counter:
		_stage_currency_counter(resolved_return_action)
	else:
		_stage_centered_coin_only_counter(resolved_return_action)
		_stage_menu_settings_button()
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
	_portrait_active_currency_counter_rect = counter_rect
	var counter_scale: float = counter_rect.size.y / 48.0
	var panel_color: Color = PORTRAIT_CHALLENGE_HUD_PANEL if challenge_colors else PORTRAIT_DARK_BLUE
	var border_color: Color = PORTRAIT_CHALLENGE_HUD_BORDER if challenge_colors else PORTRAIT_UI_PALETTE.UI_BLUE_LIGHT_BORDER
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
	if counter_is_interactive and !_portrait_coin_store_active:
		_stage_resource_add_badge(icon_rect, counter_scale)
	var balance_rect := Rect2(
		Vector2(counter_rect.position.x + 43.0 * counter_scale, counter_rect.position.y),
		Vector2(counter_rect.size.x - 49.0 * counter_scale, counter_rect.size.y)
	)
	var balance_text: String = _soft_currency_balance_text(GameState.get_soft_currency())
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
	balance_label.add_to_group(&"soft_currency_balance_label")
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
	interactive: bool = true,
	center_horizontally: bool = true,
	track_as_active_counter: bool = true
) -> void:
	var screen_content: Control = content
	if _portrait_top_bar_content != null and is_instance_valid(_portrait_top_bar_content):
		content = _portrait_top_bar_content
	var source_rect: Rect2 = rect if rect.size.x > 0.0 and rect.size.y > 0.0 else PORTRAIT_CURRENCY_COUNTER_RECT
	var counter_x: float = (
		(PORTRAIT_STAGE_SIZE.x - source_rect.size.x) * 0.5
		if center_horizontally
		else source_rect.position.x
	)
	var counter_rect := Rect2(
		counter_x,
		source_rect.position.y,
		source_rect.size.x,
		source_rect.size.y
	)
	if track_as_active_counter:
		_portrait_active_currency_counter_rect = counter_rect
	var counter_scale: float = counter_rect.size.y / 48.0
	var panel_color: Color = PORTRAIT_CHALLENGE_HUD_PANEL if challenge_colors else PORTRAIT_DARK_BLUE
	var border_color: Color = PORTRAIT_CHALLENGE_HUD_BORDER if challenge_colors else PORTRAIT_UI_PALETTE.UI_BLUE_LIGHT_BORDER
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
	if counter_is_interactive and !_portrait_coin_store_active:
		_stage_resource_add_badge(icon_rect, counter_scale)
	var balance_rect := Rect2(
		Vector2(counter_rect.position.x + 43.0 * counter_scale, counter_rect.position.y),
		Vector2(counter_rect.size.x - 49.0 * counter_scale, counter_rect.size.y)
	)
	var balance_text: String = _soft_currency_balance_text(GameState.get_soft_currency())
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
	balance_label.add_to_group(&"soft_currency_balance_label")
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
	var border_color: Color = PORTRAIT_CHALLENGE_HUD_BORDER if challenge_colors else PORTRAIT_UI_PALETTE.UI_BLUE_LIGHT_BORDER
	var resolved_hearts: int = GameState.get_hearts()
	# A full inventory has no available action: omit both the invisible hit area
	# and the plus badge so the complete heart plate behaves as static UI.
	var counter_is_interactive: bool = interactive and resolved_hearts < GameState.MAX_HEARTS
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

	var count_label := _stage_label(
		icon_rect,
		str(resolved_hearts),
		maxi(1, int(round(22.0 * counter_scale))),
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	count_label.add_theme_font_override("font", UI_PRIMARY_FONT)
	count_label.add_theme_color_override("font_outline_color", PORTRAIT_UI_PALETTE.HEART_TEXT_OUTLINE)
	count_label.add_theme_constant_override("outline_size", maxi(2, int(round(4.0 * counter_scale))))
	count_label.z_index = 22
	heart_count_label = count_label

	if counter_is_interactive:
		var add_badge_visual: Control = _stage_resource_add_badge(icon_rect, counter_scale)
		add_badge_visual.set_meta(&"badge_allowed", true)
		add_badge_visual.visible = true
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
		heart_counter_button = _stage_resource_counter_button(
			counter_rect,
			counter_visual,
			Callable(),
			Callable(self, "_show_heart_refill_popup").bind(Callable(), return_action)
		)
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
	return_action: Callable,
	direct_action: Callable = Callable()
) -> Control:
	var counter_action: Callable = direct_action
	if !counter_action.is_valid():
		counter_action = Callable(self, "_open_coin_store").bind(return_action)
		if _portrait_coin_store_active:
			counter_action = Callable(self, "_ignore_resource_counter_press")
		elif return_action.is_valid() and return_action.get_method() == &"show_coin_store":
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
	return counter_button

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
		_portrait_currency_coin_icon_visual == null
		or !is_instance_valid(_portrait_currency_coin_icon_visual)
		or !_portrait_currency_coin_icon_visual.is_inside_tree()
	):
		return
	var coin_icon: Control = _portrait_currency_coin_icon_visual
	var counter_visual: Control = _portrait_currency_counter_visual
	coin_icon.pivot_offset = Vector2.ZERO
	var previous_tween: Tween = coin_icon.get_meta(&"reward_counter_bounce_tween", null) as Tween
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
	var counter_can_bounce: bool = (
		counter_visual != null
		and is_instance_valid(counter_visual)
		and counter_visual.is_inside_tree()
	)
	var counter_rest_scale := Vector2.ONE
	if counter_can_bounce:
		counter_rest_scale = counter_visual.get_meta(
			&"reward_counter_rest_scale",
			Vector2.ZERO
		)
		if counter_rest_scale == Vector2.ZERO:
			counter_rest_scale = counter_visual.scale
			if counter_rest_scale == Vector2.ZERO:
				counter_rest_scale = Vector2.ONE
			counter_visual.set_meta(&"reward_counter_rest_scale", counter_rest_scale)
		counter_visual.scale = counter_rest_scale
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
	if counter_can_bounce:
		var counter_grow := bounce_tween.parallel().tween_property(
			counter_visual,
			"scale",
			counter_rest_scale * PORTRAIT_CURRENCY_COUNTER_REWARD_BOUNCE_PEAK_SCALE,
			PORTRAIT_CURRENCY_ICON_REWARD_BOUNCE_GROW_DURATION
		)
		counter_grow.set_trans(Tween.TRANS_BACK)
		counter_grow.set_ease(Tween.EASE_OUT)
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
	if counter_can_bounce:
		var counter_settle := bounce_tween.parallel().tween_property(
			counter_visual,
			"scale",
			counter_rest_scale,
			PORTRAIT_CURRENCY_ICON_REWARD_BOUNCE_SETTLE_DURATION
		)
		counter_settle.set_trans(Tween.TRANS_BOUNCE)
		counter_settle.set_ease(Tween.EASE_OUT)
	coin_icon.set_meta(&"reward_counter_bounce_tween", bounce_tween)

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
	var outline_color: Color = PORTRAIT_UI_PALETTE.NAV_TEXT_OUTLINE
	var shadow_color: Color = PORTRAIT_UI_PALETTE.NAV_TEXT_SHADOW
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
		MainTab.TASKS:
			return Callable(self, "show_tasks")
		MainTab.PROFILE:
			return Callable(self, "show_profile")
	return Callable()

func _portrait_main_tab_label(tab_index: int) -> String:
	match tab_index:
		MainTab.HOME:
			return tr("NAV_HOME").to_upper()
		MainTab.TASKS:
			return tr("NAV_TASKS").to_upper()
		MainTab.PROFILE:
			return tr("NAV_PROFILE").to_upper()
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
	BUTTON_TEXT_STYLE_SCRIPT.apply(label, nav_label_effect_color, nav_label_effect_color)
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
	icon.modulate = PORTRAIT_UI_PALETTE.UI_ICON_SOFT
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
		PORTRAIT_UI_PALETTE.UI_ICON_SOFT,
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
		rest_icon.modulate = PORTRAIT_UI_PALETTE.UI_ICON_SOFT
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
		previous_tab >= MainTab.TASKS
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
		PORTRAIT_UI_PALETTE.TEXT_SOFT_BLUE
	)
	top_rule.z_index = 41

	for tab_index in range(PORTRAIT_MAIN_NAV_TAB_COUNT):
		var tab_action: Callable = _portrait_main_tab_action(tab_index)
		var tab_icon: Texture2D
		var tab_label: String = _portrait_main_tab_label(tab_index)
		match tab_index:
			MainTab.HOME:
				tab_icon = PORTRAIT_NAV_HOME_ICON
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
				inactive_icon.modulate = PORTRAIT_UI_PALETTE.UI_ICON_SOFT
		var tab_button := _stage_button(hit_rect, tab_action, "")
		tab_button.z_index = 46
	content = previous_content

func _show_main_tab_screen(
	screen_builder: Callable,
	active_tab: int,
	force_rebuild: bool = false
) -> void:
	# Tapping the already active tab should not destroy and rebuild the complete
	# page tree. Internal controls may explicitly force a refresh after changing
	# data that affects the current page.
	if (
		!force_rebuild
		and !_portrait_main_tab_swipe_building_target
		and active_tab == _portrait_active_main_tab
	):
		return
	var previous_tab: int = (
		-1
		if _portrait_main_tab_swipe_building_target
		else _portrait_active_main_tab
	)
	screen_builder.call()
	_stage_main_navigation(active_tab, previous_tab)

func show_coin_store() -> void:
	_show_coin_store_screen()

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

func _show_coin_store_screen() -> void:
	_clear()
	_portrait_coin_store_active = true
	_portrait_screen(0.0)
	_stage_portrait_page_header(
		tr("COIN_STORE_TITLE"),
		Callable(self, "_close_coin_store"),
		Callable(self, "show_coin_store"),
		false
	)
	for pack_index in range(PORTRAIT_COIN_STORE_PACK_AMOUNTS.size()):
		_stage_coin_store_pack_card(
			pack_index,
			PORTRAIT_COIN_STORE_PACK_AMOUNTS[pack_index]
		)

func _coin_store_pack_texture(pack_index: int) -> Texture2D:
	match pack_index:
		0:
			return COIN_PACK_02_TEXTURE
		1:
			return COIN_PACK_04_TEXTURE
		2, 3:
			return COIN_PACK_05_TEXTURE
		4, 5:
			return COIN_PACK_06_LARGE_TEXTURE
	return COIN_PACK_02_TEXTURE

func _stage_coin_store_pack_card(pack_index: int, amount: int) -> void:
	var column: int = pack_index % 3
	var row: int = int(pack_index / 3)
	var card_rect := Rect2(
		PORTRAIT_COIN_STORE_GRID_ORIGIN + Vector2(
			float(column) * (PORTRAIT_COIN_STORE_CARD_SIZE.x + PORTRAIT_COIN_STORE_COLUMN_GAP),
			float(row) * (PORTRAIT_COIN_STORE_CARD_SIZE.y + PORTRAIT_COIN_STORE_ROW_GAP)
		),
		PORTRAIT_COIN_STORE_CARD_SIZE
	)
	# Reuse the rounded navy cards from the category-selection popup. Keeping all
	# art below one holder also gives the complete pack the existing pressed tint.
	var card_visual := _stage_holder(card_rect, Control.MOUSE_FILTER_IGNORE)
	card_visual.name = "CoinPackCard%d" % pack_index
	card_visual.z_index = 8
	var card := _portrait_hint_local_panel(
		card_visual,
		Rect2(Vector2.ZERO, card_rect.size),
		PORTRAIT_UI_PALETTE.THEME_CARD_BASE,
		18.0,
		PORTRAIT_RULE,
		2.0
	)
	card.z_index = 0
	var art_panel := _portrait_hint_local_panel(
		card_visual,
		Rect2(8.0, 8.0, card_rect.size.x - 16.0, 140.0),
		PORTRAIT_UI_PALETTE.TEXT_WARM,
		14.0,
		Color(1.0, 1.0, 1.0, 0.78),
		2.0
	)
	art_panel.z_index = 1

	var pack_icon := TextureRect.new()
	pack_icon.name = "CoinPackArt"
	pack_icon.texture = _coin_store_pack_texture(pack_index)
	pack_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pack_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pack_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pack_icon.position = Vector2(
		(card_rect.size.x - PORTRAIT_COIN_STORE_ICON_SIZE.x) * 0.5,
		18.0
	)
	pack_icon.size = PORTRAIT_COIN_STORE_ICON_SIZE
	pack_icon.z_index = 2
	card_visual.add_child(pack_icon)

	var amount_panel := _portrait_hint_local_panel(
		card_visual,
		PORTRAIT_COIN_STORE_AMOUNT_RECT,
		PORTRAIT_ORANGE,
		14.0,
		Color.WHITE,
		2.0
	)
	amount_panel.z_index = 3
	var amount_label := _portrait_hint_local_label(
		amount_panel,
		"+%d" % amount,
		28,
		Color.WHITE
	)
	amount_label.add_theme_color_override("font_outline_color", PORTRAIT_DARK_BLUE)
	amount_label.add_theme_constant_override("outline_size", 3)
	amount_label.z_index = 1

	var pack_button := _stage_button(
		card_rect,
		Callable(self, "_purchase_coin_pack").bind(amount),
		""
	)
	pack_button.z_index = 20
	_bind_theme_card_press_state(pack_button, card_visual)

func _purchase_coin_pack(amount: int) -> void:
	# The project currently has a local prototype purchase flow rather than IAP.
	# Preserve it while exposing the six requested pack sizes through real cards.
	if !PORTRAIT_COIN_STORE_PACK_AMOUNTS.has(amount):
		return
	GameState.add_soft_currency(amount)

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
	_stage_centered_coin_only_counter(
		Callable(self, "_return_to_game_from_coin_store"),
		PORTRAIT_GAME_CURRENCY_COUNTER_RECT,
		_portrait_game_is_challenge_level()
	)
	_stage_menu_settings_button()

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

	var attempts_title_text: String = tr("ATTEMPTS_LABEL")
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

	var theme_caption_text: String = tr("THEME_LABEL")
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

func _portrait_popup_begin(
	name: String,
	group_name: String,
	layer_index: int,
	close_callable: Callable,
	popup_top: float,
	popup_bottom: float,
	show_coin_balance: bool = false,
	alpha: float = PORTRAIT_POPUP_DIM_ALPHA
) -> Control:
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
	if show_coin_balance:
		_stage_popup_coin_balance_above_dimmer(popup_root)
	content = _center_popup_content(popup_root, popup_top, popup_bottom)
	return previous_content

func _stage_popup_coin_balance_above_dimmer(popup_root: Control) -> void:
	var popup_balance_layer := Control.new()
	popup_balance_layer.name = "PopupCoinBalance"
	popup_balance_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup_balance_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup_balance_layer.z_index = 200
	popup_root.add_child(popup_balance_layer)

	var previous_content: Control = content
	var previous_top_bar: Control = _portrait_top_bar_content
	var source_counter_rect: Rect2 = _portrait_active_currency_counter_rect
	_portrait_top_bar_content = null
	content = popup_balance_layer
	_stage_centered_coin_only_counter(
		Callable(),
		source_counter_rect,
		false,
		false,
		false,
		false
	)
	content = previous_content
	_portrait_top_bar_content = previous_top_bar

func _stage_portrait_popup_close_button(rect: Rect2, callable: Callable) -> Control:
	var button: FlashStageTextureButton = STAGE_ROUND_BUTTON_SCRIPT.new() as FlashStageTextureButton
	button.call("configure_text", "×", false, false, PORTRAIT_POPUP_CLOSE_ICON_FONT_SIZE, 0.32)
	button.call("set_color_preset", ROUND_BUTTON_COLOR_BLUE)
	_connect_stage_button_action(button, callable)
	content.add_child(button)
	button.stage_rect = rect
	return button

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
	# The popup body starts lower now that the title sits on the outer top edge.
	# This removes the old unused title/header space without moving the authored
	# popup content or the bottom edge.
	var popup_rect := Rect2(
		rect.position + Vector2(0.0, PORTRAIT_POPUP_TOP_TRIM),
		Vector2(rect.size.x, rect.size.y - PORTRAIT_POPUP_TOP_TRIM)
	)
	# Use the same light-blue outline as the resource counters in the top HUD.
	# The popup background is solid again; the experimental gradient is disabled.
	var popup_panel := _stage_panel(
		popup_rect,
		body_color,
		PORTRAIT_POPUP_CORNER_RADIUS,
		PORTRAIT_UI_PALETTE.THEME_CARD,
		3.0
	)
	popup_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var resolved_title_font_size: int = maxi(1, int(round(float(title_font_size) * PORTRAIT_POPUP_TITLE_SCALE)))
	var title_height: float = 66.0 if subtitle.is_empty() else 54.0
	var title_rect := Rect2(
		popup_rect.position.x + 16.0,
		popup_rect.position.y - title_height * 0.5 + (-2.0 if !subtitle.is_empty() else 0.0),
		popup_rect.size.x - 32.0,
		title_height
	)
	var title_label := _stage_heading_label(
		title_rect,
		title.to_upper(),
		resolved_title_font_size,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	# Title treatment is intentionally darker than the popup background so the
	# floating title remains legible while crossing the popup edge.
	var title_effect_color: Color = body_color.darkened(0.40)
	title_label.add_theme_font_override("font", UI_PRIMARY_FONT)
	title_label.add_theme_color_override("font_outline_color", title_effect_color)
	title_label.add_theme_constant_override("outline_size", 5)
	title_label.add_theme_color_override(
		"font_shadow_color",
		Color(title_effect_color.r, title_effect_color.g, title_effect_color.b, 0.90)
	)
	title_label.add_theme_constant_override("shadow_offset_x", 3)
	title_label.add_theme_constant_override("shadow_offset_y", 4)
	title_label.add_theme_constant_override("shadow_outline_size", 2)
	title_label.clip_text = false
	if !subtitle.is_empty():
		var subtitle_label := _stage_label(
			Rect2(popup_rect.position.x + 20.0, popup_rect.position.y + 28.0, popup_rect.size.x - 40.0, 28.0),
			subtitle,
			16,
			Color.WHITE,
			HORIZONTAL_ALIGNMENT_CENTER
		)
		subtitle_label.clip_text = false

	var close_x: float = rect.position.x + (rect.size.x - PORTRAIT_POPUP_CLOSE_SIZE) * 0.5
	var close_y: float = rect.end.y + PORTRAIT_POPUP_CLOSE_GAP
	_stage_portrait_popup_close_button(Rect2(close_x, close_y, PORTRAIT_POPUP_CLOSE_SIZE, PORTRAIT_POPUP_CLOSE_SIZE), close_callable)

func _stage_portrait_broken_heart_icon(rect: Rect2) -> Control:
	# Reuse the same life art as the refill popup and draw a bold zig-zag split on
	# top. Keeping this composition code-native avoids shipping a duplicate heart.
	var holder := _stage_holder(rect, Control.MOUSE_FILTER_IGNORE)
	var heart_icon := TextureRect.new()
	heart_icon.name = "BrokenHeartBase"
	heart_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heart_icon.texture = LIFE_HEART_ICON_TEXTURE
	heart_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	heart_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	heart_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(heart_icon)

	var crack_points := PackedVector2Array([
		Vector2(rect.size.x * 0.54, rect.size.y * 0.10),
		Vector2(rect.size.x * 0.43, rect.size.y * 0.37),
		Vector2(rect.size.x * 0.55, rect.size.y * 0.47),
		Vector2(rect.size.x * 0.45, rect.size.y * 0.68),
		Vector2(rect.size.x * 0.54, rect.size.y * 0.91),
	])
	var crack_outline := Line2D.new()
	crack_outline.name = "BrokenHeartCrackOutline"
	crack_outline.points = crack_points
	crack_outline.width = maxf(8.0, rect.size.x * 0.09)
	crack_outline.default_color = PORTRAIT_UI_PALETTE.PAPER_CRACK_DARK
	crack_outline.antialiased = true
	holder.add_child(crack_outline)
	var crack_fill := Line2D.new()
	crack_fill.name = "BrokenHeartCrack"
	crack_fill.points = crack_points
	crack_fill.width = maxf(3.5, rect.size.x * 0.035)
	crack_fill.default_color = PORTRAIT_UI_PALETTE.PAPER_CRACK_LIGHT
	crack_fill.antialiased = true
	holder.add_child(crack_fill)
	holder.z_index = 11
	return holder

func _portrait_popup_button_rect(rect: Rect2) -> Rect2:
	# Popup buttons keep the existing 15% height scale. Full-length popup CTAs
	# share one near-edge-to-edge width, while compact/two-column controls retain
	# their authored row width treatment.
	var scaled_size: Vector2 = rect.size * PORTRAIT_POPUP_BUTTON_UNIFORM_SCALE
	if rect.size.x >= PORTRAIT_POPUP_LONG_BUTTON_MIN_SOURCE_WIDTH:
		scaled_size.x = PORTRAIT_POPUP_LONG_BUTTON_WIDTH
	else:
		scaled_size.x *= PORTRAIT_POPUP_BUTTON_LENGTH_SCALE
	return Rect2(rect.get_center() - scaled_size * 0.5, scaled_size)

func _portrait_popup_bottom_button_y(popup_bottom: float, source_height: float) -> float:
	# Align the visible bottom edge after the popup button's 15% scale-up.
	var scaled_height: float = source_height * PORTRAIT_POPUP_BUTTON_UNIFORM_SCALE
	return popup_bottom - PORTRAIT_POPUP_BOTTOM_BUTTON_GAP - (source_height + scaled_height) * 0.5

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
	# Popup CTAs never use the long-button repeating attention bounce. Opening
	# animation and normal press feedback remain unchanged.
	var button := _stage_main_button(
		_portrait_popup_button_rect(rect),
		callable,
		text,
		_portrait_popup_font_size(font_size),
		disabled,
		disabled_overlay_alpha,
		use_normal_texture_when_disabled,
		selected,
		false,
		color_preset
	)
	button.set("attention_bounce_enabled", false)
	return button

func _stage_portrait_popup_coin_purchase_content(
	button: Control,
	button_text: String,
	price: int,
	price_color: Color = Color.WHITE
) -> Dictionary:
	# Treat the caption, coin and price as one visual block. Measure the complete
	# row first and only then center it inside the button, so every coin purchase
	# CTA uses identical typography and spacing regardless of caption length.
	var resolved_font_size: int = _portrait_popup_font_size(18)
	var caption_text: String = button_text.to_upper()
	var price_text := str(maxi(price, 0))
	var caption_size: Vector2 = UI_PRIMARY_FONT.get_string_size(
		caption_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		resolved_font_size
	)
	var price_size: Vector2 = UI_PRIMARY_FONT.get_string_size(
		price_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		resolved_font_size
	)
	var coin_size := Vector2(28.0, 28.0)
	var caption_coin_gap: float = 10.0
	var coin_price_gap: float = 4.0
	var caption_width: float = ceilf(caption_size.x)
	var price_width: float = ceilf(price_size.x)
	var row_width: float = (
		caption_width
		+ caption_coin_gap
		+ coin_size.x
		+ coin_price_gap
		+ price_width
	)
	var row_x: float = (button.size.x - row_width) * 0.5
	var effect_color: Color = PORTRAIT_UI_PALETTE.with_alpha(PORTRAIT_UI_PALETTE.UI_BLUE_DARK, 0.55)

	var caption_label := Label.new()
	caption_label.name = "PurchaseCaption"
	caption_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption_label.position = Vector2(row_x, 0.0)
	caption_label.size = Vector2(caption_width, button.size.y)
	caption_label.text = caption_text
	caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	caption_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption_label.add_theme_font_override("font", UI_PRIMARY_FONT)
	caption_label.add_theme_font_size_override("font_size", resolved_font_size)
	caption_label.add_theme_color_override("font_color", Color.WHITE)
	BUTTON_TEXT_STYLE_SCRIPT.apply(caption_label, effect_color, effect_color)
	caption_label.z_index = 5
	button.add_child(caption_label)

	var price_coin := TextureRect.new()
	price_coin.name = "PriceCoin"
	price_coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	price_coin.texture = SOFT_CURRENCY_COIN_TEXTURE
	price_coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	price_coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	price_coin.position = Vector2(
		row_x + caption_width + caption_coin_gap,
		(button.size.y - coin_size.y) * 0.5
	)
	price_coin.size = coin_size
	price_coin.z_index = 5
	button.add_child(price_coin)

	var price_label := Label.new()
	price_label.name = "Price"
	price_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	price_label.position = Vector2(
		price_coin.position.x + coin_size.x + coin_price_gap,
		0.0
	)
	price_label.size = Vector2(price_width, button.size.y)
	price_label.text = price_text
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	price_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	price_label.add_theme_font_override("font", UI_PRIMARY_FONT)
	price_label.add_theme_font_size_override("font_size", resolved_font_size)
	price_label.add_theme_color_override("font_color", price_color)
	BUTTON_TEXT_STYLE_SCRIPT.apply(price_label, effect_color, effect_color)
	price_label.z_index = 5
	button.add_child(price_label)
	return {
		"caption": caption_label,
		"coin": price_coin,
		"price": price_label,
	}

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
	# Home is now a standalone landing screen. Profile and Classic remain intact,
	# but their future entry points must be explicit instead of the removed bar or
	# a hidden horizontal swipe from Home.
	_show_menu_screen()

func _show_menu_screen() -> void:
	GameSession.discard_current_round()
	single_player_active_level_index = -1
	single_player_active_word_slot = -1
	single_player_retry_after_loss = false
	_portrait_game_adaptive_group = null
	coin_store_return_action = Callable()
	_clear()

	_portrait_screen(0.0)
	_stage_currency_counter(Callable(self, "show_menu"))

	var menu_title_content: Control = _portrait_begin_adaptive_group(Vector2(240.0, 235.0), PORTRAIT_MENU_TITLE_MAX_SCALE, 0.04)
	# Preserve the logo aspect ratio inside the same 20%-smaller title slot so
	# the square handwritten asset is not stretched horizontally. The texture is
	# loaded from the raw PNG at runtime specifically for this logo, which avoids
	# device-side import/compression color shifts and keeps the authored palette.
	var main_menu_logo_texture: Texture2D = _get_main_menu_logo_texture()
	# Make the logo 15% larger in UI while keeping the same authored center point.
	var main_menu_logo_bounds := Rect2(19.2, 102.52, 441.6, 264.96)
	var main_menu_logo_rect: Rect2 = _fit_stage_rect_keep_aspect(main_menu_logo_bounds, main_menu_logo_texture.get_size())
	var main_menu_logo := _stage_texture(main_menu_logo_rect, main_menu_logo_texture)
	main_menu_logo.modulate = Color.WHITE
	main_menu_logo.self_modulate = Color.WHITE

	# Play one soft diagonal highlight sweep every time the Home screen is entered.
	# The shader keeps the source alpha intact, so the highlight is visible only
	# on the painted logo pixels and never on its transparent background.
	var logo_shine_shader := Shader.new()
	logo_shine_shader.code = """
shader_type canvas_item;

uniform float shine_progress = -0.30;
uniform float shine_width = 0.12;
uniform float shine_strength = 0.46;

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	float diagonal = UV.x + UV.y * 0.28;
	float distance_to_shine = abs(diagonal - shine_progress);
	float band = 1.0 - smoothstep(0.0, shine_width, distance_to_shine);
	float shine = band * shine_strength * base.a;
	COLOR = vec4(mix(base.rgb, vec3(1.0), shine), base.a);
}
"""
	var logo_shine_material := ShaderMaterial.new()
	logo_shine_material.shader = logo_shine_shader
	main_menu_logo.material = logo_shine_material
	var logo_shine_tween := create_tween()
	logo_shine_tween.bind_node(main_menu_logo)
	logo_shine_tween.tween_interval(0.28)
	var set_logo_shine_progress := func(progress: float) -> void:
		if is_instance_valid(logo_shine_material):
			logo_shine_material.set_shader_parameter("shine_progress", progress)
	var logo_shine_motion = logo_shine_tween.tween_method(
		set_logo_shine_progress,
		-0.30,
		1.55,
		0.72
	)
	if logo_shine_motion != null:
		logo_shine_motion.set_trans(Tween.TRANS_SINE)
		logo_shine_motion.set_ease(Tween.EASE_IN_OUT)
	_portrait_end_adaptive_group(menu_title_content)

	var button_x: float = 90.0
	_stage_main_button(Rect2(button_x, 554.0, PORTRAIT_LONG_BUTTON_SIZE.x, PORTRAIT_LONG_BUTTON_SIZE.y), Callable(self, "show_custom_word"), Database.tr_text(2, "Two Player").to_upper(), 22)
	_stage_single_player_menu_button(Rect2(67.5, 632.0, 345.0, 73.6), Callable(self, "_open_next_single_player_level"))
	_stage_portrait_ad_banner()
	if _portrait_pending_home_reward_amount > 0:
		call_deferred("_play_pending_home_reward_animation")

func show_settings() -> void:
	_show_settings_popup()

func _settings_popup_uses_compact_layout() -> bool:
	if game_screen_visible and !game_finished:
		return true
	return (
		_portrait_custom_word_input != null
		and is_instance_valid(_portrait_custom_word_input)
		and _portrait_custom_word_input.is_inside_tree()
	)

func _show_settings_popup() -> void:
	_remove_settings_popup()
	settings_toggle_buttons.clear()
	settings_word_language_buttons.clear()
	var compact_layout: bool = _settings_popup_uses_compact_layout()
	var rect := (
		Rect2(28.0, 250.0, 424.0, 300.0)
		if compact_layout
		else Rect2(28.0, 120.0, 424.0, 560.0)
	)
	var previous_content := _portrait_popup_begin(
		"SettingsPopup",
		"settings_popup",
		130,
		Callable(self, "_remove_settings_popup"),
		rect.position.y,
		rect.end.y
	)
	_portrait_popup_shell(
		rect,
		tr("SETTINGS_TITLE").to_upper(),
		Callable(self, "_remove_settings_popup"),
		28
	)

	var controls_y_offset: float = rect.position.y - 120.0
	_stage_label(Rect2(56.0, 218.0 + controls_y_offset, 250.0, 42.0), _settings_sound_label(), 21, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_settings_toggle_button(Rect2(330.0, 214.0 + controls_y_offset, 102.0, 49.0), 3)
	_stage_label(Rect2(56.0, 286.0 + controls_y_offset, 250.0, 42.0), _settings_vibration_label(), 21, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_settings_toggle_button(Rect2(330.0, 282.0 + controls_y_offset, 102.0, 49.0), 4)

	if !compact_layout:
		_stage_panel(Rect2(56.0, 350.0, 368.0, 2.0), PORTRAIT_RULE)
		_stage_label(Rect2(56.0, 374.0, 150.0, 42.0), _settings_word_base_label(), 21, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
		_stage_settings_word_language_button(Rect2(210.0, 370.0, 102.0, 49.0), "ru", Database.tr_text(71, "Rus"))
		_stage_settings_word_language_button(Rect2(322.0, 370.0, 102.0, 49.0), "en", Database.tr_text(72, "Eng"))
		_stage_panel(Rect2(56.0, 450.0, 368.0, 2.0), PORTRAIT_RULE)

	# Anchor the contact buttons and version to the shell bottom instead of
	# leaving the footer floating beneath the settings controls.
	var footer_bottom_y: float = rect.end.y
	var social_buttons_y: float = footer_bottom_y - 122.0
	var version_y: float = footer_bottom_y - 44.0
	if !compact_layout:
		_stage_round_icon_button(
			Rect2(174.0, social_buttons_y, 58.0, 58.0),
			Callable(self, "_about_contact_action").bind("vk"),
			ABOUT_VK_ICON,
			ABOUT_VK_ICON_SIZE
		)
		_stage_round_icon_button(
			Rect2(248.0, social_buttons_y, 58.0, 58.0),
			Callable(self, "_about_contact_action").bind("mail"),
			ABOUT_MAIL_ICON,
			ABOUT_MAIL_ICON_SIZE
		)
		var version_label := _stage_label(
			Rect2(40.0, version_y, 400.0, 28.0),
			_about_version_text(),
			14,
			PORTRAIT_UI_PALETTE.TEXT_PALE_BLUE,
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
		else tr("CHALLENGES_TITLE")
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
		var progress_label := _stage_label(Rect2(x + 8.0, y + 7.0 + THEME_PROGRESS_TEXT_OPTICAL_OFFSET_Y, 198.0, 44.0), progress_text, 16, PORTRAIT_UI_PALETTE.THEME_PROGRESS_TEXT)
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
		var theme_effect_color: Color = PORTRAIT_UI_PALETTE.with_alpha(PORTRAIT_UI_PALETTE.UI_BLUE_EFFECT, 0.55)
		BUTTON_TEXT_STYLE_SCRIPT.apply(title_label, theme_effect_color, theme_effect_color)
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

	# The standalone Classic screen keeps its difficulty action in the verified
	# gap between the last theme card and the advertising area;
	# the previous y=725 placement was covered by the banner and stopped receiving input.
	var difficulty_rect: Rect2 = PORTRAIT_TASKS_DIFFICULTY_RECT
	# Always bind the context explicitly. The texture button emits a zero-argument
	# signal; relying on the method's default argument left the standalone Classic
	# action disconnected on affected Godot builds.
	var difficulty_action: Callable = Callable(
		self,
		"_cycle_classic_difficulty"
	).bind(with_main_navigation)
	var difficulty_font_size: int = _portrait_footer_font_size(22)
	var difficulty_button := _stage_main_button(
		difficulty_rect,
		difficulty_action,
		_difficulty_mode_label(),
		difficulty_font_size
	)
	_style_difficulty_button(difficulty_button)

func _cycle_classic_difficulty(return_to_tasks: bool = false) -> void:
	_cycle_difficulty_mode()
	if return_to_tasks:
		# The Tasks tab is already active, so its normal same-tab optimization would
		# skip the rebuild and leave the old label/cards on screen until navigation.
		_show_main_tab_screen(
			Callable(self, "_show_theme_select_screen").bind(true),
			MainTab.TASKS,
			true
		)
		return
	show_theme_select()

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
	_single_player_popup_refresh_visuals.clear()
	_single_player_popup_refresh_badge_component.clear()
	_single_player_popup_refresh_price_badge = null
	_single_player_popup_refresh_badge_shadow = null
	_single_player_popup_refresh_price_coin = null
	_single_player_popup_refresh_ad_icon = null
	_single_player_popup_theme_card_visuals.clear()

func _show_single_player_theme_popup(level_index: int, theme_index: int) -> void:
	_show_single_player_level_popup(level_index, theme_index)

func _show_single_player_last_chance_popup() -> void:
	if !GameSession.has_deferred_loss():
		return
	# The final wrong guess immediately updates GameSession, which starts the
	# mechanical Attempts counter roll. Keep the gameplay screen visible until
	# that subtraction animation has fully settled, then open the purchase popup.
	var attempts_roll := _portrait_game_attempts_roll_tween
	if attempts_roll != null and attempts_roll.is_valid():
		await attempts_roll.finished
		if !GameSession.has_deferred_loss():
			return
	_remove_single_player_last_chance_popup()
	var close_action := Callable(self, "_decline_single_player_extra_attempt")
	var previous_content := _portrait_popup_begin(
		"SinglePlayerLastChancePopup",
		"single_player_last_chance_popup",
		140,
		close_action,
		170.0,
		570.0,
		true
	)
	var rect := Rect2(28.0, 170.0, 424.0, 400.0)
	_portrait_popup_shell(
		rect,
		tr("EXTRA_ATTEMPTS_TITLE"),
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
		"+%d" % SINGLE_PLAYER_EXTRA_ATTEMPT_COUNT,
		54,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	attempt_label.add_theme_color_override("font_outline_color", PORTRAIT_UI_PALETTE.with_alpha(PORTRAIT_UI_PALETTE.UI_BLUE_DARK, 0.9))
	attempt_label.add_theme_constant_override("outline_size", 4)
	attempt_label.z_index = 12
	var description_label := _stage_label(
		Rect2(58.0, 402.0, 364.0, 68.0),
		tr("EXTRA_ATTEMPTS_DESCRIPTION"),
		21,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	description_label.clip_text = false
	var purchase_button := _stage_portrait_popup_main_button(
		Rect2(90.0, _portrait_popup_bottom_button_y(rect.end.y, 56.0), 300.0, 56.0),
		Callable(self, "_purchase_single_player_extra_attempt"),
		"",
		18,
		false,
		0.32,
		false,
		false,
		true,
		LONG_BUTTON_COLOR_ORANGE
	)
	_stage_portrait_popup_coin_purchase_content(
		purchase_button,
		tr("COMMON_CONTINUE"),
		SINGLE_PLAYER_EXTRA_ATTEMPT_COST,
		_purchase_price_color(SINGLE_PLAYER_EXTRA_ATTEMPT_COST)
	)
	content = previous_content

func _stage_heart_recovery_timer_counter(counter_rect: Rect2, heart_count: int) -> Label:
	var counter_scale: float = counter_rect.size.y / 48.0
	var panel := _stage_panel(
		counter_rect,
		PORTRAIT_DARK_BLUE,
		counter_rect.size.y * 0.5,
		PORTRAIT_UI_PALETTE.UI_BLUE_LIGHT_BORDER,
		2.0 * counter_scale
	)
	panel.z_index = 13

	# Fill the full counter height with the dimensional PNG clock, matching the
	# visual weight of the heart and coin resource icons.
	var clock_size: float = counter_rect.size.y
	var clock_rect := Rect2(
		Vector2(counter_rect.position.x, counter_rect.position.y),
		Vector2.ONE * clock_size
	)
	var clock_icon := _stage_texture(clock_rect, HEART_RECOVERY_CLOCK_TEXTURE)
	clock_icon.z_index = 14

	var timer_rect := Rect2(
		Vector2(
			counter_rect.position.x + counter_rect.size.y + 2.0 * counter_scale,
			counter_rect.position.y
		),
		Vector2(
			counter_rect.size.x - counter_rect.size.y - 6.0 * counter_scale,
			counter_rect.size.y
		)
	)
	var timer_text: String = _heart_status_text(
		heart_count,
		GameState.get_heart_recovery_seconds()
	)
	var timer_label := _stage_label(
		timer_rect,
		timer_text,
		maxi(1, int(round(25.0 * counter_scale))),
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	timer_label.add_theme_font_override("font", UI_PRIMARY_FONT)
	timer_label.z_index = 14
	_fit_single_line_label_to_width(
		timer_label,
		timer_text,
		timer_rect.size.x,
		maxi(1, int(round(25.0 * counter_scale))),
		maxi(1, int(round(16.0 * counter_scale)))
	)
	return timer_label

func _show_heart_refill_popup(
	continue_action: Callable = Callable(),
	store_return_action: Callable = Callable()
) -> void:
	_remove_heart_refill_popup()
	heart_refill_continue_action = continue_action
	heart_refill_store_return_action = store_return_action
	heart_refill_store_is_open = _portrait_coin_store_active
	var close_action := Callable(self, "_remove_heart_refill_popup")
	var previous_content := _portrait_popup_begin(
		"HeartRefillPopup",
		"heart_refill_popup",
		150,
		close_action,
		145.0,
		582.0,
		true
	)
	var rect := Rect2(28.0, 145.0, 424.0, 437.0)
	_portrait_popup_shell(
		rect,
		tr("HEART_REFILL_TITLE"),
		close_action,
		28
	)
	var body_rect := Rect2(
		rect.position + Vector2(0.0, 80.0),
		Vector2(rect.size.x, rect.size.y - 80.0)
	)

	var current_hearts: int = GameState.get_hearts()
	# Group the heart and recovery copy on the same light-blue surface used by
	# the theme-card treatment, keeping the block visually separate from the popup.
	var heart_status_rect := Rect2(48.0, 236.0, 384.0, 151.0)
	var heart_status_panel := _stage_panel(
		heart_status_rect,
		PORTRAIT_UI_PALETTE.THEME_CARD,
		22.0
	)
	heart_status_panel.z_index = 8
	# Present the life state as one horizontal row: the large heart stays on the
	# left, while the recovery caption and timer sit to its right. Center both the
	# heart/glow and the two-line text block vertically within the blue panel.
	var original_heart_rect := Rect2(79.0, 246.0, 138.0, 125.0)
	var heart_size: Vector2 = original_heart_rect.size * 0.85 * 0.90 * 0.90
	var heart_rect := Rect2(
		Vector2(
			original_heart_rect.position.x,
			heart_status_rect.get_center().y - heart_size.y * 0.5
		),
		heart_size
	)
	# Clip the static rays to the blue panel so they stop cleanly at the rounded
	# backing block rather than at the overall popup body.
	var heart_glow_size := Vector2.ONE * maxf(heart_size.x, heart_size.y) * PORTRAIT_SINGLE_PLAYER_THEME_CARD_GLOW_SCALE
	var heart_glow_rect := Rect2(
		heart_rect.get_center() - heart_glow_size * 0.5,
		heart_glow_size
	)
	var glow_clip := _stage_holder(heart_status_rect, Control.MOUSE_FILTER_IGNORE)
	glow_clip.name = "HeartRefillGlowClip"
	glow_clip.clip_contents = true
	glow_clip.z_index = 9
	var heart_glow := TextureRect.new()
	heart_glow.name = "HeartRefillGlow"
	heart_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heart_glow.texture = FINAL_REWARD_ROTATING_GLOW_TEXTURE
	heart_glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	heart_glow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	heart_glow.position = heart_glow_rect.position - heart_status_rect.position
	heart_glow.size = heart_glow_rect.size
	heart_glow.modulate = Color(
		1.0,
		1.0,
		1.0,
		PORTRAIT_SINGLE_PLAYER_THEME_CARD_GLOW_ALPHA * 0.64
	)
	heart_glow.z_index = 0
	glow_clip.add_child(heart_glow)
	var heart_icon := _stage_texture(heart_rect, LIFE_HEART_ICON_TEXTURE)
	heart_icon.z_index = 11
	var heart_value := _stage_label(
		heart_rect,
		str(current_hearts),
		40,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	heart_value.add_theme_font_override("font", UI_PRIMARY_FONT)
	heart_value.add_theme_color_override("font_outline_color", PORTRAIT_UI_PALETTE.HEART_TEXT_OUTLINE)
	heart_value.add_theme_constant_override("outline_size", 5)
	heart_value.z_index = 12

	var recovery_text_block_rect := Rect2(188.0, 0.0, 224.0, 88.0)
	recovery_text_block_rect.position.y = heart_status_rect.get_center().y - recovery_text_block_rect.size.y * 0.5
	var recovery_text_rect := Rect2(
		recovery_text_block_rect.position.x,
		recovery_text_block_rect.position.y,
		recovery_text_block_rect.size.x,
		30.0
	)
	var recovery_label := _stage_label(
		recovery_text_rect,
		tr("HEART_NEXT_LIFE"),
		20,
		PORTRAIT_UI_PALETTE.TEXT_SECONDARY,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	recovery_label.clip_text = false
	recovery_label.z_index = 12

	var recovery_timer_label := _stage_label(
		Rect2(
			recovery_text_block_rect.position.x,
			recovery_text_block_rect.position.y + 36.0,
			recovery_text_block_rect.size.x,
			52.0
		),
		_heart_status_text(current_hearts, GameState.get_heart_recovery_seconds()),
		36,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	recovery_timer_label.add_theme_font_override("font", UI_PRIMARY_FONT)
	recovery_timer_label.clip_text = false
	recovery_timer_label.z_index = 12
	# Keep the popup copy live without replacing the global top-bar label refs.
	# That way closing the popup does not break the underlying HUD countdown.
	var popup_heart_tick := Timer.new()
	popup_heart_tick.wait_time = 1.0
	popup_heart_tick.one_shot = false
	popup_heart_tick.timeout.connect(func() -> void:
		var live_hearts: int = GameState.get_hearts()
		if is_instance_valid(heart_value):
			heart_value.text = str(live_hearts)
		if is_instance_valid(recovery_timer_label):
			recovery_timer_label.text = _heart_status_text(
				live_hearts,
				GameState.get_heart_recovery_seconds()
			)
	)
	heart_glow.add_child(popup_heart_tick)
	popup_heart_tick.start()

	var purchase_disabled: bool = current_hearts >= GameState.MAX_HEARTS
	var has_enough_coins: bool = GameState.get_soft_currency() >= HEART_REFILL_COST
	var rewarded_heart_button := _stage_portrait_popup_main_button(
		Rect2(90.0, 425.0, 300.0, 56.0),
		Callable(self, "_on_heart_refill_ad_pressed"),
		tr("HEART_GET_ONE"),
		18,
		purchase_disabled,
		0.32,
		false,
		false,
		false,
		LONG_BUTTON_COLOR_BLUE
	)
	rewarded_heart_button.add_to_group(&"heart_refill_ad_button")
	rewarded_heart_button.z_index = 16
	# Use StageLongButton for the complete rewarded row: leading ad icon, native
	# caption and trailing heart are measured together and centered as one block.
	# Crop the authored transparent margins from the ad texture so its visible
	# glyph has the same visual height as the heart icon.
	var rewarded_ad_icon_texture := AtlasTexture.new()
	rewarded_ad_icon_texture.atlas = WATCH_AD_ICON_TEXTURE
	rewarded_ad_icon_texture.region = Rect2(83.0, 49.0, 219.0, 159.0)
	rewarded_heart_button.set("icon_texture", rewarded_ad_icon_texture)
	rewarded_heart_button.set("icon_stage_size", Vector2(34.0, 28.0))
	rewarded_heart_button.set("icon_gap_stage", 8.0)
	rewarded_heart_button.set("icon_before_text", true)
	rewarded_heart_button.set("icon_shadow_enabled", true)
	rewarded_heart_button.set("icon_shadow_offset_stage", Vector2(2.0, 2.0))
	rewarded_heart_button.set("icon_shadow_color", PORTRAIT_UI_PALETTE.AD_ICON_SHADOW)
	rewarded_heart_button.set("trailing_icon_texture", LIFE_HEART_ICON_TEXTURE)
	rewarded_heart_button.set("trailing_icon_stage_size", Vector2(34.0, 28.0))
	rewarded_heart_button.set("trailing_icon_gap_stage", 8.0)
	if rewarded_heart_button.has_method("set_color_palette"):
		rewarded_heart_button.call(
			"set_color_palette",
			PORTRAIT_AD_BADGE_PURPLE,
			PORTRAIT_UI_PALETTE.AD_PURPLE_PRESSED,
			PORTRAIT_UI_PALETTE.AD_PURPLE_SELECTED
		)

	var purchase_button := _stage_portrait_popup_main_button(
		Rect2(90.0, _portrait_popup_bottom_button_y(rect.end.y, 56.0), 300.0, 56.0),
		Callable(self, "_purchase_heart_refill"),
		"",
		18,
		purchase_disabled,
		0.32,
		false,
		false,
		false,
		LONG_BUTTON_COLOR_ORANGE
	)
	# Keep all custom button content inside the button itself. The complete row is
	# centered as one block, using the same font size as the extra-attempt popup.
	purchase_button.z_index = 16
	purchase_button.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE if purchase_disabled else Control.MOUSE_FILTER_STOP
	)
	_stage_portrait_popup_coin_purchase_content(
		purchase_button,
		tr("HEART_REFILL"),
		HEART_REFILL_COST,
		Color.WHITE if has_enough_coins else PORTRAIT_INSUFFICIENT_PRICE_COLOR
	)
	content = previous_content

func _on_heart_refill_ad_pressed() -> void:
	if GameState.get_hearts() >= GameState.MAX_HEARTS:
		return
	_show_portrait_rewarded_action(&"heart_refill")

func _return_to_heart_refill_from_coin_store(
	continue_action: Callable,
	restore_action: Callable
) -> void:
	if restore_action.is_valid():
		restore_action.call()
	else:
		show_menu()
	_show_heart_refill_popup(continue_action, restore_action)

func _restore_single_player_heart_refill_context(level_index: int, theme_index: int) -> void:
	show_tasks()
	_show_single_player_level_popup(level_index, theme_index)

func _show_single_player_level_popup(
	level_index: int,
	selected_theme: int = -1,
	retry_after_loss: bool = false
) -> void:
	_remove_single_player_theme_popup()
	single_player_retry_after_loss = retry_after_loss
	level_index = _prepare_single_player_level_attempt(level_index)
	_single_player_theme_reroll_level_index = level_index
	var persisted_reroll_state: int = GameState.get_single_level_theme_reroll_state(
		Database.current_language,
		level_index
	)
	_single_player_theme_reroll_used = (
		persisted_reroll_state >= GameState.SINGLE_LEVEL_THEME_REROLL_COIN_USED
	)
	_single_player_theme_ad_reroll_used = (
		persisted_reroll_state >= GameState.SINGLE_LEVEL_THEME_REROLL_AD_USED
	)
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
		588.0,
		true
	)
	single_player_popup_stage_content = content
	var rect := Rect2(24.0, 118.0, 432.0, 470.0)
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
		_single_player_choose_theme_label().to_upper(),
		21,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	instruction_label.add_theme_font_override("font", UI_HEADING_FONT)
	instruction_label.clip_text = false
	var card_y: float = 280.0
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
	var refresh_price_badge_rect := Rect2(
		Vector2(
			refresh_button.size.x - refresh_price_badge_size.x * 0.82,
			-refresh_price_badge_size.y * 0.18
		),
		refresh_price_badge_size
	)
	var refresh_ad_badge_size := Vector2(
		PORTRAIT_GAME_HINT_COUNTER_SIZE,
		PORTRAIT_GAME_HINT_COUNTER_SIZE
	)
	var refresh_ad_badge_rect := Rect2(
		Vector2(
			refresh_button.size.x - refresh_ad_badge_size.x * 0.82,
			-refresh_ad_badge_size.y * 0.18
		),
		refresh_ad_badge_size
	)
	_single_player_popup_refresh_badge_component = _create_portrait_button_badge(
		refresh_button,
		{
			"coin_rect": refresh_price_badge_rect,
			"ad_rect": refresh_ad_badge_rect,
			"free_rect": refresh_ad_badge_rect,
			"price": SINGLE_PLAYER_THEME_REFRESH_COST,
			"price_font_size": 13,
			"ad_icon_scale": 1.4025,
			"state": PORTRAIT_BUTTON_BADGE_STATE_COINS,
		}
	)
	_single_player_popup_refresh_badge_shadow = _single_player_popup_refresh_badge_component.get("shadow") as Control
	_single_player_popup_refresh_price_badge = _single_player_popup_refresh_badge_component.get("badge") as Control
	_single_player_popup_refresh_price_coin = _single_player_popup_refresh_badge_component.get("coin") as CanvasItem
	_single_player_popup_refresh_ad_icon = _single_player_popup_refresh_badge_component.get("ad") as CanvasItem
	single_player_popup_refresh_price_label = _single_player_popup_refresh_badge_component.get("label") as Label
	_single_player_popup_refresh_visuals.clear()
	for refresh_visual_variant: Variant in [
		refresh_button,
	]:
		var refresh_visual := refresh_visual_variant as CanvasItem
		if refresh_visual != null:
			_single_player_popup_refresh_visuals.append(refresh_visual)
	_update_single_player_theme_reroll_badge()
	_update_single_player_theme_reroll_button_state()
	var word_count: int = _single_player_level_word_count(level_index)
	_stage_single_player_popup_theme_cards(
		level_index,
		options,
		card_y,
		word_count
	)

	single_player_popup_play_button = _stage_portrait_popup_main_button(
		Rect2(90.0, _portrait_popup_bottom_button_y(rect.end.y, 56.0), 300.0, 56.0),
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
	var authored_card_size := Vector2(128.0, 202.0)
	var card_size := Vector2(authored_card_size.x, authored_card_size.y * 0.9975)
	var challenge_level: bool = _single_player_is_bonus_level(level_index)
	var card_fill: Color = (
		PORTRAIT_UI_PALETTE.THEME_CARD_BASE_CHALLENGE
		if challenge_level
		else PORTRAIT_UI_PALETTE.THEME_CARD_BASE
	)
	var card_border: Color = (
		PORTRAIT_CHALLENGE_POPUP_HEADER
		if challenge_level
		else PORTRAIT_RULE
	)
	for option_index in range(options.size()):
		var theme_index: int = int(options[option_index])
		var card_rect := Rect2(
			39.0 + float(option_index) * 137.0,
			card_y + (authored_card_size.y - card_size.y) * 0.5,
			card_size.x,
			card_size.y
		)
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
		var theme_glow: Control = null
		var word_badge: Control = null
		var word_badge_label: Label = null
		var theme_icon_texture: Texture2D = _theme_icon_texture(theme_index)
		var theme_icon_rect := Rect2()
		if theme_icon_texture != null:
			var theme_icon_size := Vector2.ONE * PORTRAIT_SINGLE_PLAYER_THEME_CARD_ICON_SIZE
			theme_icon_rect = Rect2(
				card_rect.position + Vector2(
					(card_rect.size.x - theme_icon_size.x) * 0.5,
					35.0
				),
				theme_icon_size
			)
			var theme_glow_size := theme_icon_size * PORTRAIT_SINGLE_PLAYER_THEME_CARD_GLOW_SCALE
			var theme_glow_rect := Rect2(
				theme_icon_rect.get_center() - theme_glow_size * 0.5,
				theme_glow_size
			)
			theme_glow = _stage_final_reward_glow(theme_glow_rect, Color.WHITE)
			if theme_glow.get_parent() != null and theme_glow.get_parent() is CanvasItem:
				(theme_glow.get_parent() as CanvasItem).z_index = 11
			theme_glow.modulate = Color(1.0, 1.0, 1.0, PORTRAIT_SINGLE_PLAYER_THEME_CARD_GLOW_ALPHA)
			theme_icon = _stage_texture(theme_icon_rect, theme_icon_texture)
			theme_icon.z_index = 12
			# A single word is the default/minimal case, so do not clutter the theme
			# card with a redundant x1 badge. Keep counters only for multi-word levels.
			if word_count > 1:
				var word_badge_text := "x%d" % word_count
				var word_badge_text_size: Vector2 = UI_PRIMARY_FONT.get_string_size(
					word_badge_text,
					HORIZONTAL_ALIGNMENT_LEFT,
					-1.0,
					16
				)
				var word_badge_diameter: float = maxf(27.0, ceilf(word_badge_text_size.x + 10.0))
				var word_badge_size := Vector2.ONE * word_badge_diameter
				var word_badge_rect := Rect2(
					theme_icon_rect.end - word_badge_size * Vector2(0.86, 0.82),
					word_badge_size
				)
				word_badge = _stage_panel(
					word_badge_rect,
					Color.WHITE,
					word_badge_size.y * 0.5,
					Color(0.0, 0.0, 0.0, 0.0),
					0.0
				)
				word_badge.z_index = 13
				word_badge_label = _stage_label(
					word_badge_rect,
					word_badge_text,
					16,
					PORTRAIT_BLUE,
					HORIZONTAL_ALIGNMENT_CENTER
				)
				word_badge_label.z_index = 14
				word_badge_label.add_theme_font_override("font", UI_PRIMARY_FONT)
				word_badge_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.0))
				word_badge_label.add_theme_constant_override("shadow_offset_x", 0)
				word_badge_label.add_theme_constant_override("shadow_offset_y", 0)
				word_badge_label.add_theme_constant_override("shadow_outline_size", 0)
				word_badge_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.0))
				word_badge_label.add_theme_constant_override("outline_size", 0)
		var theme_name: String = Database.get_theme_name(theme_index).to_upper()
		var theme_name_height: float = 56.0
		var theme_name_rect := Rect2(
			Vector2(
				card_rect.position.x + 6.0,
				card_rect.end.y - theme_name_height - 18.0
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
		theme_label.add_theme_font_override("font", UI_PRIMARY_FONT)
		theme_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		theme_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		theme_label.clip_text = false
		var popup_theme_effect_color := Color(
			PORTRAIT_DARK_BLUE.r,
			PORTRAIT_DARK_BLUE.g,
			PORTRAIT_DARK_BLUE.b,
			0.55
		)
		BUTTON_TEXT_STYLE_SCRIPT.apply(theme_label, popup_theme_effect_color, popup_theme_effect_color)
		var theme_button := _stage_button(
			card_rect,
			Callable(self, "_select_single_player_popup_theme").bind(level_index, theme_index),
			""
		)
		theme_button.disabled = false
		_single_player_popup_theme_card_visuals.append({
			"card_rect": card_rect,
			"theme_icon_rect": theme_icon_rect,
			"theme_index": theme_index,
			"theme_glow": theme_glow,
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
	if level_index != single_player_popup_level_index or _single_player_theme_slot_animating:
		return
	if _single_player_theme_reroll_used:
		if !_single_player_theme_ad_reroll_used:
			_show_portrait_rewarded_action(&"theme_reroll", level_index)
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
	GameState.set_single_level_theme_reroll_state(
		Database.current_language,
		level_index,
		GameState.SINGLE_LEVEL_THEME_REROLL_COIN_USED
	)
	_update_single_player_theme_reroll_badge()
	_update_single_player_theme_reroll_button_state()
	_perform_single_player_theme_reroll(level_index)

func _perform_single_player_theme_reroll(level_index: int) -> void:
	var previous_options: Array = _single_player_level_theme_options(level_index).duplicate()
	var next_options: Array = _reroll_single_player_theme_options(level_index, previous_options)
	_update_single_player_refresh_price(GameState.get_soft_currency())
	if (
		previous_options.size() != next_options.size()
		or next_options.size() != _single_player_popup_theme_card_visuals.size()
	):
		_update_single_player_theme_popup(level_index)
		return
	# Manual rerolls never inherit the automatic opening roll's hidden-controls
	# mode. Keep the controls rendered and only block their input during motion.
	_single_player_theme_slot_hide_actions = false
	_set_single_player_theme_slot_action_visibility(true)
	_start_single_player_theme_slot_animation(
		level_index,
		previous_options,
		next_options,
		-1,
		false
	)

func _update_single_player_theme_reroll_badge() -> void:
	var show_price_badge: bool = !_single_player_theme_reroll_used
	var show_ad_badge: bool = _single_player_theme_reroll_used and !_single_player_theme_ad_reroll_used
	if _single_player_popup_refresh_badge_component.is_empty():
		return
	if show_price_badge:
		_set_portrait_button_badge_state(
			_single_player_popup_refresh_badge_component,
			PORTRAIT_BUTTON_BADGE_STATE_COINS,
			{"price": SINGLE_PLAYER_THEME_REFRESH_COST}
		)
	elif show_ad_badge:
		_set_portrait_button_badge_state(
			_single_player_popup_refresh_badge_component,
			PORTRAIT_BUTTON_BADGE_STATE_AD
		)
	else:
		_set_portrait_button_badge_visible(_single_player_popup_refresh_badge_component, false)

func _update_single_player_theme_reroll_button_state() -> void:
	if single_player_popup_refresh_button == null or !is_instance_valid(single_player_popup_refresh_button):
		return
	var waiting_for_this_ad: bool = (
		_portrait_rewarded_action == &"theme_reroll"
		and _portrait_rewarded_action_level_index == single_player_popup_level_index
	)
	single_player_popup_refresh_button.set(
		"button_disabled",
		_single_player_theme_slot_animating
		or (_single_player_theme_reroll_used and _single_player_theme_ad_reroll_used)
		or waiting_for_this_ad
	)

func _reroll_single_player_theme_options(level_index: int, previous_options: Array) -> Array:
	var next_options: Array = []
	var require_fully_new_options: bool = Database.get_theme_count() >= previous_options.size() * 2
	var max_attempts: int = 16 if require_fully_new_options else 1
	for _attempt_index in range(max_attempts):
		GameState.reset_single_level_attempt(
			Database.current_language,
			level_index,
			true,
			false
		)
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
	_prepare_single_player_theme_slot_animation_visuals(level_index, true)
	var popup_stage: Control = single_player_popup_stage_content
	var start_callable := Callable(
		self,
		"_start_single_player_theme_slot_animation"
	).bind(level_index, previous_options, next_options, final_selected_theme, true)
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
			final_selected_theme,
			true
		)

func _prepare_single_player_theme_slot_animation_visuals(
	level_index: int,
	hide_actions_during_animation: bool
) -> void:
	_single_player_theme_slot_hide_actions = hide_actions_during_animation
	single_player_popup_selected_theme = -1
	_set_single_player_theme_panels_unselected(level_index)
	_set_single_player_theme_static_visuals_visible(false)
	_set_single_player_theme_slot_action_visibility(!hide_actions_during_animation)
	if single_player_popup_refresh_button != null and is_instance_valid(single_player_popup_refresh_button):
		# Match the disabled treatment of the Play button while the reels and
		# their result bounce are still running.
		single_player_popup_refresh_button.set("button_disabled", true)
	if single_player_popup_play_button != null and is_instance_valid(single_player_popup_play_button):
		single_player_popup_play_button.set("button_disabled", true)

func _set_single_player_theme_slot_action_visibility(is_visible: bool) -> void:
	# Only the initial automatic roll is allowed to hide these controls. This
	# guard prevents any later callback from hiding a manual reroll's buttons.
	if !is_visible and !_single_player_theme_slot_hide_actions:
		return
	if single_player_popup_play_button != null and is_instance_valid(single_player_popup_play_button):
		single_player_popup_play_button.visible = is_visible
	for refresh_visual: CanvasItem in _single_player_popup_refresh_visuals:
		if refresh_visual != null and is_instance_valid(refresh_visual):
			refresh_visual.visible = is_visible
	if is_visible:
		_update_single_player_theme_reroll_badge()

func _start_single_player_theme_slot_animation(
	level_index: int,
	previous_options: Array,
	next_options: Array,
	final_selected_theme: int = -1,
	hide_actions_during_animation: bool = false
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
	_prepare_single_player_theme_slot_animation_visuals(
		level_index,
		hide_actions_during_animation
	)

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

	var static_icon_rect: Rect2 = visual.get("theme_icon_rect", Rect2())
	var icon_size := (
		static_icon_rect.size
		if static_icon_rect.size.x > 0.0 and static_icon_rect.size.y > 0.0
		else Vector2.ONE * PORTRAIT_SINGLE_PLAYER_THEME_CARD_ICON_SIZE
	)
	var icon_step: float = icon_size.y + PORTRAIT_SINGLE_PLAYER_SLOT_ICON_GAP
	# Derive the reel landing point from the same static icon rect used by the
	# card. That keeps reel, mask and reveal perfectly aligned after card resizes.
	var icon_x: float = (
		static_icon_rect.position.x - reel_rect.position.x
		if static_icon_rect.size.x > 0.0
		else (reel_rect.size.x - icon_size.x) * 0.5
	)
	var icon_y: float = (
		static_icon_rect.position.y - reel_rect.position.y
		if static_icon_rect.size.y > 0.0
		else 35.0
	)
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
		for key: String in ["theme_glow", "theme_icon", "word_badge", "word_badge_label", "theme_label"]:
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
		else PORTRAIT_UI_PALETTE.THEME_CARD
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
		_single_player_theme_slot_hide_actions = false
		_single_player_theme_slot_final_selection = -1
		return
	var final_selected_theme: int = _single_player_theme_slot_final_selection
	_single_player_theme_slot_final_selection = -1
	_update_single_player_theme_popup(level_index)
	var current_options: Array = _single_player_level_theme_options(level_index)
	if final_selected_theme >= 0 and current_options.has(final_selected_theme):
		_select_single_player_popup_theme(level_index, final_selected_theme)
	# The automatic opening roll kept both actions hidden. Restore their orange
	# state before making them visible, then block clicks through mouse_filter
	# while the cards finish revealing. This avoids a one-frame grey flash.
	if _single_player_theme_slot_hide_actions:
		if single_player_popup_play_button != null and is_instance_valid(single_player_popup_play_button):
			single_player_popup_play_button.set("button_disabled", false)
			single_player_popup_play_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if single_player_popup_refresh_button != null and is_instance_valid(single_player_popup_refresh_button):
			single_player_popup_refresh_button.set("button_disabled", false)
			single_player_popup_refresh_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_single_player_theme_slot_action_visibility(true)
	_start_single_player_theme_slot_reveal(animation_generation)

func _start_single_player_theme_slot_reveal(animation_generation: int) -> void:
	if animation_generation != _single_player_theme_slot_generation:
		return
	var reveal_visuals: Array = []
	for visual_variant: Variant in _single_player_popup_theme_card_visuals:
		if !(visual_variant is Dictionary):
			continue
		var visual: Dictionary = visual_variant
		var theme_glow := visual.get("theme_glow") as Control
		var theme_icon := visual.get("theme_icon") as Control
		var theme_label := visual.get("theme_label") as Control
		var badge_panel := visual.get("word_badge") as Control
		var badge_label := visual.get("word_badge_label") as Control

		if theme_glow != null and is_instance_valid(theme_glow):
			theme_glow.visible = true
			theme_glow.modulate = Color(1.0, 1.0, 1.0, 0.0)
			if !theme_glow.has_meta(&"theme_card_glow_rotation_started"):
				_start_final_reward_glow_rotation(theme_glow)
				theme_glow.set_meta(&"theme_card_glow_rotation_started", true)

		if theme_icon != null and is_instance_valid(theme_icon):
			var icon_rest_position: Vector2 = theme_icon.position
			var icon_rest_scale: Vector2 = theme_icon.scale
			theme_icon.visible = true
			theme_icon.modulate = Color.WHITE
			theme_icon.set_meta(&"slot_reveal_rest_position", icon_rest_position)
			theme_icon.set_meta(&"slot_reveal_rest_scale", icon_rest_scale)
			# Keep the pivot at zero and animate position together with scale below.
			# This preserves the exact viewport-space center at any fit scale and is
			# independent of the current card height.
			theme_icon.pivot_offset = Vector2.ZERO
			theme_icon.position = icon_rest_position
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

	# Manual rerolls keep the existing grey disabled treatment. During the
	# automatic opening reveal the buttons stay orange and visible, with input
	# blocked by mouse_filter until the reveal completes.
	if !_single_player_theme_slot_hide_actions:
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
		# Keep the icon bounce tween byte-for-byte in the same sequential shape it
		# had before the theme glow was added. Glow timing runs on its own tween so
		# it cannot change the bounce delay, settle timing, or center compensation.
		var theme_glow := reveal_visual.get("theme_glow") as Control
		if theme_glow != null and is_instance_valid(theme_glow):
			var glow_tween: Tween = theme_glow.create_tween()
			glow_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			if reveal_delay > 0.0:
				glow_tween.tween_interval(reveal_delay)
			var glow_fade: PropertyTweener = glow_tween.tween_property(
				theme_glow,
				"modulate:a",
				PORTRAIT_SINGLE_PLAYER_THEME_CARD_GLOW_ALPHA,
				PORTRAIT_SINGLE_PLAYER_SLOT_REVEAL_GROW_DURATION + PORTRAIT_SINGLE_PLAYER_SLOT_REVEAL_SETTLE_DURATION
			)
			glow_fade.set_trans(Tween.TRANS_SINE)
			glow_fade.set_ease(Tween.EASE_OUT)
			_single_player_theme_slot_tweens.append(glow_tween)
		var icon_rest_position: Vector2 = theme_icon.get_meta(
			&"slot_reveal_rest_position",
			theme_icon.position
		)
		var icon_rest_center: Vector2 = (
			icon_rest_position + theme_icon.size * icon_rest_scale * 0.5
		)
		var icon_peak_scale: Vector2 = (
			icon_rest_scale * PORTRAIT_SINGLE_PLAYER_SLOT_REVEAL_PEAK_SCALE
		)
		var icon_peak_position: Vector2 = (
			icon_rest_center - theme_icon.size * icon_peak_scale * 0.5
		)
		var icon_grow: PropertyTweener = reveal_tween.tween_property(
			theme_icon,
			"scale",
			icon_peak_scale,
			PORTRAIT_SINGLE_PLAYER_SLOT_REVEAL_GROW_DURATION
		)
		icon_grow.set_trans(Tween.TRANS_QUAD)
		icon_grow.set_ease(Tween.EASE_OUT)
		var icon_grow_position: PropertyTweener = reveal_tween.parallel().tween_property(
			theme_icon,
			"position",
			icon_peak_position,
			PORTRAIT_SINGLE_PLAYER_SLOT_REVEAL_GROW_DURATION
		)
		icon_grow_position.set_trans(Tween.TRANS_QUAD)
		icon_grow_position.set_ease(Tween.EASE_OUT)
		var icon_settle: PropertyTweener = reveal_tween.tween_property(
			theme_icon,
			"scale",
			icon_rest_scale,
			PORTRAIT_SINGLE_PLAYER_SLOT_REVEAL_SETTLE_DURATION
		)
		icon_settle.set_trans(Tween.TRANS_BOUNCE)
		icon_settle.set_ease(Tween.EASE_OUT)
		var icon_settle_position: PropertyTweener = reveal_tween.parallel().tween_property(
			theme_icon,
			"position",
			icon_rest_position,
			PORTRAIT_SINGLE_PLAYER_SLOT_REVEAL_SETTLE_DURATION
		)
		icon_settle_position.set_trans(Tween.TRANS_BOUNCE)
		icon_settle_position.set_ease(Tween.EASE_OUT)
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
		var theme_glow := visual.get("theme_glow") as Control
		if theme_glow != null and is_instance_valid(theme_glow):
			theme_glow.visible = true
			theme_glow.modulate = Color(1.0, 1.0, 1.0, PORTRAIT_SINGLE_PLAYER_THEME_CARD_GLOW_ALPHA)
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
		single_player_popup_play_button.mouse_filter = Control.MOUSE_FILTER_STOP
	if single_player_popup_refresh_button != null and is_instance_valid(single_player_popup_refresh_button):
		single_player_popup_refresh_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_update_single_player_theme_reroll_button_state()
	_single_player_theme_slot_hide_actions = false

func _cancel_single_player_theme_slot_animation() -> void:
	_single_player_theme_slot_generation += 1
	_single_player_theme_slot_animating = false
	_single_player_theme_slot_hide_actions = false
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
		PORTRAIT_BLUE
		if balance >= SINGLE_PLAYER_THEME_REFRESH_COST
		else PORTRAIT_INSUFFICIENT_PRICE_COLOR
	)
	if !_single_player_popup_refresh_badge_component.is_empty():
		_single_player_popup_refresh_badge_component["price_color"] = price_color
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
		else PORTRAIT_UI_PALETTE.THEME_CARD
	)
	var selected_fill: Color = (
		PORTRAIT_CHALLENGE_THEME_CARD_SELECTED
		if challenge_level
		else PORTRAIT_UI_PALETTE.THEME_CARD_SELECTED
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
	if GameState.get_hearts() <= 0:
		var restore_action := Callable(
			self,
			"_restore_single_player_heart_refill_context"
		).bind(level_index, single_player_popup_selected_theme)
		_show_heart_refill_popup(
			Callable(self, "_start_single_player_popup_level").bind(level_index),
			restore_action
		)
		return
	_single_player_theme_reroll_level_index = -1
	_single_player_theme_reroll_used = false
	_single_player_theme_ad_reroll_used = false
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
	var close_action := Callable(self, "_remove_exit_game_popup")
	if GameState.current_mode == GameState.GameMode.TWO_PLAYER:
		var two_player_previous_content := _portrait_popup_begin(
			"ExitGamePopup",
			"exit_game_popup",
			140,
			close_action,
			205.0,
			525.0
		)
		var two_player_rect := Rect2(28.0, 205.0, 424.0, 320.0)
		_portrait_popup_shell(
			two_player_rect,
			_exit_game_title_text().to_upper(),
			close_action,
			27
		)
		var two_player_warning := _stage_label(
			Rect2(58.0, 310.0, 364.0, 70.0),
			_exit_game_warning_text(),
			21,
			Color.WHITE,
			HORIZONTAL_ALIGNMENT_CENTER
		)
		two_player_warning.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		two_player_warning.clip_text = false
		_stage_portrait_popup_main_button(
			Rect2(82.0, 442.0, 145.0, 52.0),
			Callable(self, "_confirm_exit_game").bind(true),
			tr("YES"),
			20
		)
		_stage_portrait_popup_main_button(
			Rect2(253.0, 442.0, 145.0, 52.0),
			close_action,
			tr("NO"),
			20,
			false,
			0.32,
			false,
			false,
			false,
			LONG_BUTTON_COLOR_ORANGE
		)
		content = two_player_previous_content
		return
	var previous_content := _portrait_popup_begin(
		"ExitGamePopup",
		"exit_game_popup",
		140,
		close_action,
		170.0,
		570.0
	)
	var rect := Rect2(28.0, 170.0, 424.0, 400.0)
	_portrait_popup_shell(rect, _exit_game_title_text().to_upper(), close_action, 27)
	_stage_portrait_broken_heart_icon(Rect2(176.0, 266.0, 128.0, 116.0))
	var warning_label := _stage_label(Rect2(58.0, 394.0, 364.0, 54.0), _exit_game_warning_text(), 21, Color.WHITE)
	warning_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	warning_label.clip_text = false
	_stage_portrait_popup_main_button(
		Rect2(82.0, 492.0, 145.0, 52.0),
		Callable(self, "_confirm_exit_game").bind(true),
		tr("YES"),
		20
	)
	_stage_portrait_popup_main_button(Rect2(253.0, 492.0, 145.0, 52.0), close_action, tr("NO"), 20, false, 0.32, false, false, false, LONG_BUTTON_COLOR_ORANGE)
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

	# Keep the complete action stack above the advertising reserve. The group is
	# still bottom-attached, so it follows the physical bottom on tall screens.
	var custom_word_bottom_content: Control = _portrait_begin_bottom_attached_group()
	custom_word_check_button = _stage_main_button(_portrait_custom_word_button_rect(PORTRAIT_CUSTOM_WORD_CHECK_RECT), Callable(self, "_check_custom_word_now"), Database.tr_text(60, "Check the word"), 22, false, 0.0)
	_stage_main_button(_portrait_custom_word_button_rect(PORTRAIT_CUSTOM_WORD_RANDOM_RECT), Callable(self, "_set_random_custom_word"), _custom_word_random_label(), 22)

	# Keep the primary action above the banner without drawing a blue footer.
	custom_word_start_button = _stage_main_button(
		_portrait_custom_word_button_rect(PORTRAIT_FOOTER_CENTER_LONG_BUTTON_RECT),
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
	_portrait_end_adaptive_group(custom_word_bottom_content)
	_stage_portrait_custom_word_field()
	_stage_portrait_ad_banner()

func _portrait_custom_word_button_rect(source_rect: Rect2) -> Rect2:
	# Resolve the original footer sizing first, then raise the result. This keeps
	# every button's existing dimensions while moving the whole stack together.
	var raised_rect: Rect2 = _portrait_footer_long_button_rect(source_rect)
	raised_rect.position.y -= PORTRAIT_CUSTOM_WORD_BUTTON_RISE
	return raised_rect

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
	var keyboard_start_y: float = (
		PORTRAIT_FOOTER_Y - _portrait_ad_banner_height_stage()
	) - 24.0 - keyboard_height
	if GameState.current_mode == GameState.GameMode.TWO_PLAYER:
		keyboard_start_y += PORTRAIT_TWO_PLAYER_KEYBOARD_Y_OFFSET
	else:
		# Keyboard, word and hints share one bottom-attached block. Move the whole
		# block down together so the hint row sits closer to the banner reserve.
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
	_portrait_round_end_bounce_started = false
	_portrait_inline_result_search_button = null
	_portrait_inline_result_word_holder = null
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
	if GameState.current_mode == GameState.GameMode.SINGLE_PLAYER:
		keyboard_start_y -= PORTRAIT_STAGE_SIZE.y * 0.01

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
	# The paper front must stay above the revealed answer, marker underlay and
	# search button throughout the peel animation.
	word_paper_mask.z_index = 40
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
	word_paper_backside.z_index = 41
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
	var back_button := _stage_round_button(
		PORTRAIT_PAGE_BACK_BUTTON_RECT,
		Callable(self, "_show_exit_game_popup"),
		"×"
	)
	_portrait_game_back_button = back_button
	if _portrait_game_is_challenge_level():
		back_button.call(
			"set_color_palette",
			DIFFICULTY_HARD_NORMAL_TINT,
			DIFFICULTY_HARD_PRESSED_TINT,
			DIFFICULTY_HARD_SELECTED_TINT
		)
	_animate_portrait_back_button_entrance(back_button, PORTRAIT_PAGE_BACK_BUTTON_RECT)
	_stage_portrait_ad_banner()
	_portrait_game_runtime_ready = true
	call_deferred("_sync_portrait_attempts_attention_bounce")
	pending_letter_markers.clear()
	pending_letter_marker_is_correct = false
	if play_game_entrance:
		_prepare_portrait_game_entrance()
	if restore_finished_round:
		# Restore the same in-place presentation used when the round ended: peel only
		# the word paper and keep the gameplay composition around the revealed word.
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
	return "%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d" % [
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
		int(GameSession.can_use_open_letter_hint_ad()),
		int(GameSession.can_use_remove_wrong_hint_ad()),
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
	# `GameSession.changed` already requested a hint-row rebuild after marking a
	# one-shot hint as used. Keep that request alive while the free-count badge
	# rolls to zero; otherwise the old active orange button survives indefinitely.
	_portrait_hint_counter_refresh_requested = true
	if hint_key in [GameState.HINT_OPEN_LETTER, GameState.HINT_REMOVE_WRONG]:
		var used_button: Control = _portrait_game_hint_button_for_key(hint_key)
		if used_button != null and is_instance_valid(used_button):
			used_button.set("disabled", true)
			used_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_animate_portrait_hint_counter_roll(hint_key, previous_count, current_count)

func _stage_portrait_ad_banner() -> void:
	# Yandex renders a native Android view above Godot. The Godot holder reserves
	# the same physical-bottom area and remains visible as a preview in the editor.
	var banner_rect: Rect2 = _portrait_ad_banner_rect()
	var banner_slot := _stage_holder(banner_rect, Control.MOUSE_FILTER_IGNORE)
	banner_slot.name = "YandexAdsBannerSlot"
	banner_slot.add_to_group(&"ad_banner_slot")
	banner_slot.z_index = 30
	var ads_service: Node = _portrait_ads_service()
	var native_ads_available: bool = false
	if ads_service != null:
		if ads_service.has_method("is_native_available"):
			native_ads_available = bool(ads_service.call("is_native_available"))
		if ads_service.has_method("show_banner"):
			ads_service.call("show_banner")
	if native_ads_available:
		return
	var banner_panel := _stage_panel(
		banner_rect,
		PORTRAIT_UI_PALETTE.NEUTRAL_SURFACE,
		0.0,
		PORTRAIT_UI_PALETTE.NEUTRAL_BORDER,
		1.0
	)
	banner_panel.z_index = 30
	var banner_label := _stage_label(
		banner_rect,
		"YANDEX ADS • ADAPTIVE STICKY",
		12,
		PORTRAIT_UI_PALETTE.NEUTRAL_TEXT,
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
			rect.position.y + PORTRAIT_RESULT_WORD_Y_OFFSET + PORTRAIT_STAGE_SIZE.y * 0.02
		),
		Vector2(word_width, rect.size.y - 10.0)
	)
	var word_text: String = "".join(GameSession.letters)
	var word_holder := _stage_holder(word_rect, Control.MOUSE_FILTER_IGNORE)
	# The solved word now lives outside the clipping mask. The front paper layer
	# simply stays above it and reveals the text by moving away during the peel.
	word_holder.z_index = 29
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
	word_holder.add_child(word_label)
	word_label.z_index = 1

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
	var marker_left: float = maxf(18.0, word_bounds.position.x - 6.0)
	var marker_right: float = minf(
		PORTRAIT_STAGE_SIZE.x - 18.0,
		search_x + PORTRAIT_RESULT_SEARCH_BUTTON_SIZE + 5.0
	)
	var marker_top: float = word_rect.position.y - 4.0
	var marker_height: float = maxf(
		word_rect.size.y + 8.0,
		PORTRAIT_RESULT_SEARCH_BUTTON_SIZE + 4.0
	)
	var marker_holder := _stage_holder(
		Rect2(
			marker_left,
			marker_top,
			marker_right - marker_left,
			marker_height
		),
		Control.MOUSE_FILTER_IGNORE
	)
	marker_holder.name = "ResultWordMarkerHolder"
	marker_holder.z_index = 29
	var word_marker := _stage_portrait_result_word_marker(marker_holder.size)
	marker_holder.add_child(word_marker)
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
	search_button.z_index = 29
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
		"marker_holder": marker_holder,
		"word_marker": word_marker,
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
	var base_hint_y: float = keyboard_bottom_y + PORTRAIT_GAME_HINT_KEYBOARD_GAP
	# Raise only the action row by exactly 5%. Keyboard metrics stay untouched.
	return base_hint_y * PORTRAIT_GAME_ACTION_Y_SCALE

func _portrait_in_place_result_button_rect() -> Rect2:
	var button_y: float = minf(
		_portrait_game_hint_y(),
		_portrait_ad_banner_rect().position.y - PORTRAIT_GAME_RETRY_BUTTON_SIZE.y - 12.0
	)
	return Rect2(
		Vector2(
			(PORTRAIT_STAGE_SIZE.x - PORTRAIT_GAME_RETRY_BUTTON_SIZE.x) * 0.5,
			button_y
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
	var open_hint_ad_available: bool = GameSession.can_use_open_letter_hint_ad()
	var remove_hint_ad_available: bool = GameSession.can_use_remove_wrong_hint_ad()
	var comment_unlocked: bool = GameSession.comment_hint_unlocked
	var round_inactive: bool = !GameSession.is_active
	var open_hint_disabled: bool = (
		round_inactive
		or (!open_hint_ad_available if open_hint_used else !GameSession.can_use_open_letter_hint())
	)
	var remove_hint_disabled: bool = (
		round_inactive
		or (!remove_hint_ad_available if remove_hint_used else !GameSession.can_use_remove_wrong_hint())
	)
	var comment_disabled: bool = round_inactive or (!comment_unlocked and !GameSession.can_unlock_comment_hint())

	# Place the hint row directly after the last keyboard row. Both controls live
	# in bottom-attached coordinate space, so this gap stays stable on tall phones.
	var hint_y: float = _portrait_game_hint_y()
	var hint_button_y: float = hint_y - (PORTRAIT_GAME_HINT_BUTTON_SIZE.y - 58.0) * 0.5
	var open_rect := Rect2(
		Vector2(PORTRAIT_GAME_HINT_OPEN_BUTTON_RECT.position.x, hint_button_y),
		PORTRAIT_GAME_HINT_OPEN_BUTTON_RECT.size
	)
	var remove_rect := Rect2(
		Vector2(PORTRAIT_GAME_HINT_REMOVE_BUTTON_RECT.position.x, hint_button_y),
		PORTRAIT_GAME_HINT_REMOVE_BUTTON_RECT.size
	)
	var comment_rect := Rect2(
		Vector2(PORTRAIT_GAME_HINT_COMMENT_BUTTON_RECT.position.x, hint_button_y),
		PORTRAIT_GAME_HINT_COMMENT_BUTTON_RECT.size
	)

	# Use the standard round-button component for all hint actions. The doodle art
	# remains a separate child so badges and state changes can be reused unchanged.
	var open_button := _stage_round_button(
		open_rect,
		Callable(self, "_use_open_hint"),
		"",
		open_hint_disabled,
		false,
		0.0,
		LONG_BUTTON_COLOR_BLUE
	)
	var remove_button := _stage_round_button(
		remove_rect,
		Callable(self, "_use_remove_hint"),
		"",
		remove_hint_disabled,
		false,
		0.0,
		LONG_BUTTON_COLOR_BLUE
	)
	var comment_button := _stage_round_button(
		comment_rect,
		Callable(self, "_use_comment_hint"),
		"",
		comment_disabled,
		false,
		0.0,
		LONG_BUTTON_COLOR_ORANGE if comment_unlocked else LONG_BUTTON_COLOR_BLUE
	)

	_portrait_game_hint_buttons.clear()
	open_button.set_meta(&"portrait_hint_key", GameState.HINT_OPEN_LETTER)
	remove_button.set_meta(&"portrait_hint_key", GameState.HINT_REMOVE_WRONG)
	comment_button.set_meta(&"portrait_hint_key", GameState.HINT_COMMENT)
	_portrait_game_hint_buttons.append(open_button)
	_portrait_game_hint_buttons.append(remove_button)
	_portrait_game_hint_buttons.append(comment_button)

	_stage_portrait_hint_art(
		open_button,
		PORTRAIT_HINT_REVEAL_LETTER_ICON,
		open_hint_used and !open_hint_ad_available
	)
	_stage_portrait_hint_art(
		remove_button,
		PORTRAIT_HINT_REMOVE_WRONG_ICON,
		remove_hint_used and !remove_hint_ad_available
	)
	_stage_portrait_hint_art(
		comment_button,
		PORTRAIT_HINT_COMMENT_UNLOCK_ICON,
		false
	)

	# Prices and inventory badges only describe actions that still consume a hint.
	# Used one-shot hints use the shared gray disabled state without a stale badge;
	# the unlocked comment remains a regular free blue action.
	if open_hint_ad_available:
		_stage_portrait_hint_ad_counter(open_button)
	elif !open_hint_used:
		_stage_portrait_hint_counter(open_button, GameState.HINT_OPEN_LETTER)
	if remove_hint_ad_available:
		_stage_portrait_hint_ad_counter(remove_button)
	elif !remove_hint_used:
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
	var art_position := Vector2(
		(button.size.x - PORTRAIT_GAME_HINT_ART_SIZE.x) * 0.5,
		(button.size.y - PORTRAIT_GAME_HINT_ART_SIZE.y) * 0.5 + y_offset
	)
	var art_shadow := TextureRect.new()
	art_shadow.name = "HintArtShadow"
	art_shadow.texture = texture
	art_shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art_shadow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_shadow.set_anchors_preset(Control.PRESET_TOP_LEFT)
	art_shadow.size = PORTRAIT_GAME_HINT_ART_SIZE
	art_shadow.custom_minimum_size = PORTRAIT_GAME_HINT_ART_SIZE
	art_shadow.position = art_position + Vector2(2.0, 2.0)
	art_shadow.modulate = Color(
		PORTRAIT_DARK_BLUE.r,
		PORTRAIT_DARK_BLUE.g,
		PORTRAIT_DARK_BLUE.b,
		0.62
	)
	art_shadow.z_index = 3
	button.add_child(art_shadow)
	var art := TextureRect.new()
	art.name = "HintArt"
	art.texture = texture
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.set_anchors_preset(Control.PRESET_TOP_LEFT)
	art.size = PORTRAIT_GAME_HINT_ART_SIZE
	art.custom_minimum_size = PORTRAIT_GAME_HINT_ART_SIZE
	art.position = art_position
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

func _apply_portrait_panel_style(
	panel: Panel,
	fill_color: Color,
	corner_radius: float,
	border_color: Color = Color.TRANSPARENT,
	border_width: float = 0.0
) -> void:
	if panel == null or !is_instance_valid(panel):
		return
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	var radius: int = maxi(0, int(round(corner_radius)))
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

func _create_portrait_button_badge(button: Control, config: Dictionary = {}) -> Dictionary:
	if button == null or !is_instance_valid(button):
		return {}
	var shadow := Panel.new()
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow.z_index = 7
	button.add_child(shadow)
	var badge := Panel.new()
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.z_index = 8
	button.add_child(badge)
	var holder := Control.new()
	holder.name = "BadgeHolder"
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.position = Vector2.ZERO
	holder.clip_contents = true
	badge.add_child(holder)
	var coin_icon := TextureRect.new()
	coin_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coin_icon.texture = SOFT_CURRENCY_COIN_TEXTURE
	coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin_icon.z_index = 1
	holder.add_child(coin_icon)
	var ad_shadow_icon := TextureRect.new()
	ad_shadow_icon.name = "HintAdIconShadow"
	ad_shadow_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ad_shadow_icon.texture = WATCH_AD_ICON_TEXTURE
	ad_shadow_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ad_shadow_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ad_shadow_icon.modulate = Color(PORTRAIT_DARK_BLUE.r, PORTRAIT_DARK_BLUE.g, PORTRAIT_DARK_BLUE.b, 0.6)
	ad_shadow_icon.z_index = 0
	holder.add_child(ad_shadow_icon)
	var ad_icon := TextureRect.new()
	ad_icon.name = "HintAdIcon"
	ad_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ad_icon.texture = WATCH_AD_ICON_TEXTURE
	ad_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ad_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ad_icon.modulate = Color.WHITE
	ad_icon.z_index = 1
	holder.add_child(ad_icon)
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", UI_PRIMARY_FONT)
	label.z_index = 1
	holder.add_child(label)
	var component := {
		"shadow": shadow,
		"badge": badge,
		"holder": holder,
		"coin": coin_icon,
		"ad_shadow": ad_shadow_icon,
		"ad": ad_icon,
		"label": label,
		"coin_rect": config.get("coin_rect", Rect2()),
		"ad_rect": config.get("ad_rect", Rect2()),
		"free_rect": config.get("free_rect", config.get("ad_rect", Rect2())),
		"price": int(config.get("price", 0)),
		"count": int(config.get("count", 0)),
		"price_font_size": int(config.get("price_font_size", 16)),
		"free_font_size": int(config.get("free_font_size", 17)),
		"ad_icon_scale": float(config.get("ad_icon_scale", 1.0)),
		"price_color": config.get("price_color", PORTRAIT_BLUE),
	}
	_set_portrait_button_badge_state(
		component,
		String(config.get("state", PORTRAIT_BUTTON_BADGE_STATE_COINS))
	)
	return component

func _set_portrait_button_badge_state(
	component: Dictionary,
	state: String,
	update: Dictionary = {}
) -> void:
	if component.is_empty():
		return
	for key in update.keys():
		component[key] = update[key]
	var shadow := component.get("shadow") as Panel
	var badge := component.get("badge") as Panel
	var holder := component.get("holder") as Control
	var coin_icon := component.get("coin") as TextureRect
	var ad_shadow_icon := component.get("ad_shadow") as TextureRect
	var ad_icon := component.get("ad") as TextureRect
	var label := component.get("label") as Label
	if shadow == null or badge == null or holder == null or coin_icon == null or ad_shadow_icon == null or ad_icon == null or label == null:
		return
	var rect: Rect2 = component.get("coin_rect", Rect2())
	match state:
		PORTRAIT_BUTTON_BADGE_STATE_AD:
			rect = component.get("ad_rect", rect)
		PORTRAIT_BUTTON_BADGE_STATE_FREE:
			rect = component.get("free_rect", rect)
	shadow.position = rect.position + Vector2(2.0, 2.0)
	shadow.size = rect.size
	badge.position = rect.position
	badge.size = rect.size
	holder.position = Vector2.ZERO
	holder.size = rect.size
	var corner_radius := rect.size.y * 0.5
	if state == PORTRAIT_BUTTON_BADGE_STATE_AD:
		corner_radius = rect.size.x * 0.5
	_apply_portrait_panel_style(
		shadow,
		Color(PORTRAIT_DARK_BLUE.r, PORTRAIT_DARK_BLUE.g, PORTRAIT_DARK_BLUE.b, 0.28),
		corner_radius,
		Color(0.0, 0.0, 0.0, 0.0),
		0.0
	)
	coin_icon.visible = false
	ad_shadow_icon.visible = false
	ad_icon.visible = false
	label.visible = false
	match state:
		PORTRAIT_BUTTON_BADGE_STATE_COINS:
			_apply_portrait_panel_style(badge, Color.WHITE, corner_radius, Color(0.0, 0.0, 0.0, 0.0), 0.0)
			coin_icon.visible = true
			label.visible = true
			var coin_icon_diameter: float = minf(24.0, rect.size.y - 4.0)
			var coin_icon_x: float = 2.0
			var coin_icon_y: float = (rect.size.y - coin_icon_diameter) * 0.5
			coin_icon.position = Vector2(coin_icon_x, coin_icon_y)
			coin_icon.size = Vector2.ONE * coin_icon_diameter
			var label_x: float = coin_icon_x + coin_icon_diameter - 1.0
			label.position = Vector2(label_x, 0.0)
			label.size = Vector2(maxf(0.0, rect.size.x - label_x - 2.0), rect.size.y)
			label.text = str(maxi(int(component.get("price", 0)), 0))
			label.add_theme_font_size_override("font_size", int(component.get("price_font_size", 16)))
			label.add_theme_color_override("font_color", component.get("price_color", PORTRAIT_BLUE))
			label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.0))
			label.add_theme_constant_override("shadow_offset_x", 0)
			label.add_theme_constant_override("shadow_offset_y", 0)
			label.add_theme_constant_override("shadow_outline_size", 0)
			label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.0))
			label.add_theme_constant_override("outline_size", 0)
		PORTRAIT_BUTTON_BADGE_STATE_AD:
			_apply_portrait_panel_style(badge, PORTRAIT_AD_BADGE_PURPLE, corner_radius, Color(0.0, 0.0, 0.0, 0.0), 0.0)
			ad_shadow_icon.visible = true
			ad_icon.visible = true
			ad_shadow_icon.modulate = Color(PORTRAIT_DARK_BLUE.r, PORTRAIT_DARK_BLUE.g, PORTRAIT_DARK_BLUE.b, 0.6)
			ad_icon.modulate = Color.WHITE
			var ad_icon_size := Vector2(rect.size.x - 6.0, rect.size.y - 12.0) * float(component.get("ad_icon_scale", 1.0))
			var ad_icon_position := (rect.size - ad_icon_size) * 0.5
			ad_shadow_icon.position = ad_icon_position + Vector2(1.0, 1.0)
			ad_shadow_icon.size = ad_icon_size
			ad_icon.position = ad_icon_position
			ad_icon.size = ad_icon_size
		PORTRAIT_BUTTON_BADGE_STATE_FREE:
			_apply_portrait_panel_style(badge, PORTRAIT_FREE_HINT_BADGE_GREEN, rect.size.x * 0.5)
			label.visible = true
			label.position = Vector2.ZERO
			label.size = rect.size
			label.text = str(maxi(int(component.get("count", 0)), 0))
			label.add_theme_font_size_override("font_size", int(component.get("free_font_size", 17)))
			label.add_theme_color_override("font_color", Color.WHITE)
			label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.0))
			label.add_theme_constant_override("shadow_offset_x", 0)
			label.add_theme_constant_override("shadow_offset_y", 0)
			label.add_theme_constant_override("shadow_outline_size", 0)
			label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.0))
			label.add_theme_constant_override("outline_size", 0)
	shadow.visible = state != PORTRAIT_BUTTON_BADGE_STATE_FREE
	badge.visible = true

func _set_portrait_button_badge_visible(component: Dictionary, visible: bool) -> void:
	if component.is_empty():
		return
	if visible:
		return
	for key in ["shadow", "badge", "coin", "ad_shadow", "ad", "label"]:
		var node := component.get(key) as CanvasItem
		if node != null and is_instance_valid(node):
			node.visible = false

func _portrait_button_badge_shadow(
	button: Control,
	local_rect: Rect2,
	corner_radius: float
) -> Panel:
	var component := _create_portrait_button_badge(button, {
		"coin_rect": local_rect,
		"ad_rect": local_rect,
		"free_rect": local_rect,
		"state": PORTRAIT_BUTTON_BADGE_STATE_COINS,
	})
	var shadow := component.get("shadow") as Panel
	if shadow != null and is_instance_valid(shadow):
		_apply_portrait_panel_style(
			shadow,
			Color(PORTRAIT_DARK_BLUE.r, PORTRAIT_DARK_BLUE.g, PORTRAIT_DARK_BLUE.b, 0.28),
			corner_radius,
			Color(0.0, 0.0, 0.0, 0.0),
			0.0
		)
	var badge := component.get("badge") as CanvasItem
	if badge != null and is_instance_valid(badge):
		badge.queue_free()
	return shadow

func _create_portrait_button_ad_badge(
	button: Control,
	badge_rect: Rect2,
	icon_scale_multiplier: float = 1.0
) -> Dictionary:
	var component := _create_portrait_button_badge(button, {
		"coin_rect": badge_rect,
		"ad_rect": badge_rect,
		"free_rect": badge_rect,
		"ad_icon_scale": icon_scale_multiplier,
		"state": PORTRAIT_BUTTON_BADGE_STATE_AD,
	})
	component["icon"] = component.get("ad")
	return component

func _create_portrait_button_price_badge(
	button: Control,
	badge_rect: Rect2,
	price: int
) -> Dictionary:
	return _create_portrait_button_badge(button, {
		"coin_rect": badge_rect,
		"ad_rect": badge_rect,
		"free_rect": badge_rect,
		"price": price,
		"state": PORTRAIT_BUTTON_BADGE_STATE_COINS,
	})

func _style_portrait_hint_counter_badge_label(label: Label) -> void:
	var counter_outline_color := Color(
		PORTRAIT_DARK_BLUE.r,
		PORTRAIT_DARK_BLUE.g,
		PORTRAIT_DARK_BLUE.b,
		0.9
	)
	var counter_shadow_color := Color(
		PORTRAIT_DARK_BLUE.r,
		PORTRAIT_DARK_BLUE.g,
		PORTRAIT_DARK_BLUE.b,
		0.55
	)
	BUTTON_TEXT_STYLE_SCRIPT.apply(label, counter_outline_color, counter_shadow_color)

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

func _stage_portrait_hint_ad_counter(button: Control) -> void:
	if button == null or !is_instance_valid(button):
		return
	var badge_size := Vector2(PORTRAIT_GAME_HINT_COUNTER_SIZE, PORTRAIT_GAME_HINT_COUNTER_SIZE)
	var badge_rect := Rect2(
		Vector2(
			button.size.x - badge_size.x * 0.82,
			-badge_size.y * 0.18
		),
		badge_size
	)
	_create_portrait_button_badge(button, {
		"coin_rect": badge_rect,
		"ad_rect": badge_rect,
		"free_rect": badge_rect,
		"ad_icon_scale": 1.4025,
		"state": PORTRAIT_BUTTON_BADGE_STATE_AD,
	})

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
	var component := _create_portrait_button_badge(button, {
		"coin_rect": badge_rect,
		"ad_rect": badge_rect,
		"free_rect": badge_rect,
		"count": count,
		"state": PORTRAIT_BUTTON_BADGE_STATE_FREE,
	})
	button.set_meta(&"portrait_hint_counter_badge", component.get("badge"))
	button.set_meta(&"portrait_hint_counter_holder", component.get("holder"))
	button.set_meta(&"portrait_hint_counter_label", component.get("label"))

func _stage_portrait_hint_price(button: Control, price: int) -> void:
	if button == null or !is_instance_valid(button):
		return
	var badge_size := Vector2(58.0, PORTRAIT_GAME_HINT_COUNTER_SIZE)
	var badge_rect := Rect2(
		Vector2(
			button.size.x - badge_size.x * 0.82 + 6.0,
			-badge_size.y * 0.18
		),
		badge_size
	)
	_create_portrait_button_badge(button, {
		"coin_rect": badge_rect,
		"ad_rect": badge_rect,
		"free_rect": badge_rect,
		"price": price,
		"state": PORTRAIT_BUTTON_BADGE_STATE_COINS,
	})

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

func _show_single_player_forfeit_reward_screen() -> void:
	_portrait_single_reward_resume_without_intro = false
	_show_single_player_reward_chain_screen()

func _return_to_single_player_last_chance_from_coin_store() -> void:
	_portrait_game_entrance_pending = false
	super.show_game_screen()
	call_deferred("_show_single_player_last_chance_popup")

func _grant_single_player_extra_attempt() -> void:
	var hero_group: Control = _portrait_game_adaptive_group
	if hero_group == null or !is_instance_valid(hero_group) or !hero_group.is_inside_tree():
		super._grant_single_player_extra_attempt()
		return

	# Fade the complete hero layer, including a reaction overlay that may still be
	# visible below the popup. Update the recovered pose while the layer is hidden,
	# then bring that previous state back without the old abrupt frame swap.
	var fade_out := hero_group.create_tween()
	fade_out.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var fade_out_tweener := fade_out.tween_property(
		hero_group,
		"modulate:a",
		0.0,
		PORTRAIT_EXTRA_ATTEMPT_HERO_FADE_OUT_DURATION
	)
	fade_out_tweener.set_trans(Tween.TRANS_QUAD)
	fade_out_tweener.set_ease(Tween.EASE_IN)
	await fade_out.finished

	_clear_hero_animation_overlay()
	GameSession.grant_deferred_attempt(SINGLE_PLAYER_EXTRA_ATTEMPT_COUNT)
	if !is_instance_valid(hero_group) or !hero_group.is_inside_tree():
		return
	hero_group.modulate.a = 0.0
	var fade_in := hero_group.create_tween()
	fade_in.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var fade_in_tweener := fade_in.tween_property(
		hero_group,
		"modulate:a",
		1.0,
		PORTRAIT_EXTRA_ATTEMPT_HERO_FADE_IN_DURATION
	)
	fade_in_tweener.set_trans(Tween.TRANS_QUAD)
	fade_in_tweener.set_ease(Tween.EASE_OUT)

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
	_portrait_inline_result_marker_holder = result_controls.get("marker_holder") as Control
	return result_controls

func _set_portrait_result_word_color(result_controls: Dictionary, color: Color) -> void:
	var word_label := result_controls.get("word_label") as RichTextLabel
	if word_label != null and is_instance_valid(word_label):
		word_label.add_theme_color_override("default_color", Color.WHITE)
		_apply_portrait_standard_text_outline(word_label, 0.9, 4)
		word_label.add_theme_color_override("font_shadow_color", PORTRAIT_BLUE)
		word_label.add_theme_constant_override("shadow_offset_x", 2)
		word_label.add_theme_constant_override("shadow_offset_y", 2)
	_set_portrait_result_word_marker_color(result_controls, color)

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
	# A fast round can finish while the delayed hint-entrance tween is still queued.
	# Cancel that choreography before hiding the row so it cannot reveal the hints
	# again underneath Continue.
	_portrait_game_entrance_active = false
	if (
		_portrait_game_back_button != null
		and is_instance_valid(_portrait_game_back_button)
	):
		_portrait_game_back_button.visible = false
		_portrait_game_back_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_portrait_game_back_button.set("disabled", true)
		_portrait_back_button_visible = false
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
	_finalize_portrait_hints_for_round_end()
	if (
		_portrait_inline_result_continue_button != null
		and is_instance_valid(_portrait_inline_result_continue_button)
	):
		return
	var previous_content: Control = content
	content = _portrait_game_input_group
	var action_button := _stage_main_button(
		_portrait_in_place_result_button_rect(),
		_result_continue_action(),
		_result_continue_button_text(),
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
	is_failed: bool,
	accent_color: Color,
	header_color: Color
) -> void:
	if parent == null or !is_instance_valid(parent):
		return
	var challenge_level: bool = _single_player_is_bonus_level(level_index)
	var card_fill: Color = (
		PORTRAIT_CHALLENGE_THEME_CARD
		if challenge_level
		else PORTRAIT_UI_PALETTE.THEME_CARD
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
	var state_accent: Color = StageLetterButton.CROSSED_COLOR if is_failed else accent_color
	var state_fill: Color = (
		Color(state_accent.r, state_accent.g, state_accent.b, 0.10)
		if is_claimed_or_current
		else Color(header_color.r, header_color.g, header_color.b, 0.055)
	)
	var state_border: Color = (
		state_accent
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

func _stage_single_player_reward_chain_link(
	parent: Control,
	link_rect: Rect2
) -> void:
	if parent == null or !is_instance_valid(parent):
		return
	# One opaque blue strip stays visible in the gap while its ends remain tucked
	# beneath the neighboring z=1 reward tiles.
	var link_bar := ColorRect.new()
	link_bar.name = "RewardChainBlueLine"
	link_bar.color = PORTRAIT_SINGLE_REWARD_CHAIN_LINK_COLOR
	link_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	link_bar.position = link_rect.position
	link_bar.size = link_rect.size
	link_bar.z_index = 0
	parent.add_child(link_bar)

func _stage_single_player_reward_coin_pile(parent: Control, icon_rect: Rect2) -> Control:
	var coin_icon := TextureRect.new()
	coin_icon.name = "RewardCoinIcon"
	coin_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coin_icon.texture = REWARD_COIN_TEXTURE
	coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin_icon.position = icon_rect.position
	coin_icon.size = icon_rect.size
	coin_icon.z_index = 3
	parent.add_child(coin_icon)
	return coin_icon

func _stage_single_player_reward_status_icon(
	parent: Control,
	node_rect: Rect2,
	start_hidden: bool = false,
	is_success: bool = true
) -> Control:
	var icon_size: Vector2 = node_rect.size * PORTRAIT_SINGLE_REWARD_STATUS_ICON_SCALE
	var icon_rect := Rect2(
		node_rect.get_center() - icon_size * 0.5,
		icon_size
	)
	var icon_holder := Control.new()
	icon_holder.name = "RewardStatusCheck" if is_success else "RewardStatusCross"
	icon_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_holder.position = icon_rect.position
	icon_holder.size = icon_rect.size
	icon_holder.pivot_offset = icon_rect.size * 0.5
	parent.add_child(icon_holder)
	icon_holder.z_index = 4
	var status_icon := TextureRect.new()
	status_icon.name = "StatusTexture"
	status_icon.texture = REWARD_STATUS_CHECK_TEXTURE if is_success else REWARD_STATUS_CROSS_TEXTURE
	status_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	status_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	status_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_holder.add_child(status_icon)
	status_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if start_hidden:
		icon_holder.modulate.a = 0.0
		icon_holder.scale = Vector2.ONE * PORTRAIT_SINGLE_REWARD_CHECK_BOUNCE_START_SCALE
	return icon_holder

func _stage_single_player_reward_crown(parent: Control, node_rect: Rect2) -> Control:
	var crown_size := Vector2(
		node_rect.size.x * PORTRAIT_SINGLE_REWARD_CROWN_WIDTH_RATIO,
		node_rect.size.y * PORTRAIT_SINGLE_REWARD_CROWN_HEIGHT_RATIO
	)
	var crown_holder := Control.new()
	crown_holder.name = "FinalRewardCrown"
	crown_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crown_holder.position = Vector2(
		(node_rect.size.x - crown_size.x) * 0.5,
		-crown_size.y * 0.78
	)
	crown_holder.size = crown_size
	crown_holder.pivot_offset = crown_size * 0.5
	crown_holder.z_index = 6
	parent.add_child(crown_holder)

	var crown_points := PackedVector2Array([
		Vector2(crown_size.x * 0.06, crown_size.y * 0.24),
		Vector2(crown_size.x * 0.28, crown_size.y * 0.56),
		Vector2(crown_size.x * 0.49, crown_size.y * 0.10),
		Vector2(crown_size.x * 0.70, crown_size.y * 0.56),
		Vector2(crown_size.x * 0.94, crown_size.y * 0.22),
		Vector2(crown_size.x * 0.84, crown_size.y * 0.88),
		Vector2(crown_size.x * 0.16, crown_size.y * 0.88),
	])
	var crown_fill := Polygon2D.new()
	crown_fill.name = "CrownFill"
	crown_fill.polygon = crown_points
	crown_fill.color = PORTRAIT_SINGLE_REWARD_CROWN_FILL
	crown_holder.add_child(crown_fill)

	var crown_band := Polygon2D.new()
	crown_band.name = "CrownBand"
	crown_band.polygon = PackedVector2Array([
		Vector2(crown_size.x * 0.14, crown_size.y * 0.70),
		Vector2(crown_size.x * 0.86, crown_size.y * 0.70),
		Vector2(crown_size.x * 0.84, crown_size.y * 0.88),
		Vector2(crown_size.x * 0.16, crown_size.y * 0.88),
	])
	crown_band.color = PORTRAIT_SINGLE_REWARD_CROWN_BAND
	crown_holder.add_child(crown_band)

	var outline_points: PackedVector2Array = crown_points.duplicate()
	outline_points.append(crown_points[0])
	var crown_outline := Line2D.new()
	crown_outline.name = "CrownOutline"
	crown_outline.points = outline_points
	crown_outline.width = maxf(2.5, crown_size.y * 0.10)
	crown_outline.default_color = PORTRAIT_SINGLE_REWARD_CROWN_OUTLINE
	crown_outline.antialiased = true
	crown_holder.add_child(crown_outline)
	return crown_holder

func _animate_single_player_failed_reward_marker(
	cross_visual: Control,
	crown_visual: Control
) -> void:
	if cross_visual == null or !is_instance_valid(cross_visual):
		return
	cross_visual.pivot_offset = cross_visual.size * 0.5
	cross_visual.modulate.a = 0.0
	cross_visual.scale = Vector2.ONE * PORTRAIT_SINGLE_REWARD_CHECK_BOUNCE_START_SCALE
	var cross_tween := cross_visual.create_tween()
	cross_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	cross_tween.tween_property(cross_visual, "modulate:a", 1.0, 0.08)
	var cross_grow := cross_tween.parallel().tween_property(
		cross_visual,
		"scale",
		Vector2.ONE * PORTRAIT_SINGLE_REWARD_CHECK_BOUNCE_PEAK_SCALE,
		PORTRAIT_SINGLE_REWARD_CHECK_BOUNCE_GROW_DURATION
	)
	cross_grow.set_trans(Tween.TRANS_BACK)
	cross_grow.set_ease(Tween.EASE_OUT)
	var cross_settle := cross_tween.tween_property(
		cross_visual,
		"scale",
		Vector2.ONE,
		PORTRAIT_SINGLE_REWARD_CHECK_BOUNCE_SETTLE_DURATION
	)
	cross_settle.set_trans(Tween.TRANS_BOUNCE)
	cross_settle.set_ease(Tween.EASE_OUT)

	if crown_visual == null or !is_instance_valid(crown_visual):
		return
	var crown_target: Vector2 = crown_visual.position + PORTRAIT_SINGLE_REWARD_CROWN_FLY_OFFSET
	var crown_tween := crown_visual.create_tween()
	crown_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var crown_fly := crown_tween.tween_property(
		crown_visual,
		"position",
		crown_target,
		PORTRAIT_SINGLE_REWARD_CROWN_FLY_DURATION
	)
	crown_fly.set_trans(Tween.TRANS_QUAD)
	crown_fly.set_ease(Tween.EASE_OUT)
	var crown_turn := crown_tween.parallel().tween_property(
		crown_visual,
		"rotation",
		deg_to_rad(28.0),
		PORTRAIT_SINGLE_REWARD_CROWN_FLY_DURATION
	)
	crown_turn.set_trans(Tween.TRANS_QUAD)
	crown_turn.set_ease(Tween.EASE_OUT)
	crown_tween.parallel().tween_property(
		crown_visual,
		"modulate:a",
		0.0,
		PORTRAIT_SINGLE_REWARD_CROWN_FLY_DURATION
	)

func _stage_single_player_reward_count(
	parent: Control,
	node_rect: Rect2,
	icon_rect: Rect2,
	amount: int,
	font_size: int,
	count_color: Color
) -> Label:
	var count_text: String = _single_player_reward_chain_count_text(amount)
	var count_label := Label.new()
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Keep xN at the same normalized vertical position inside every reward tile.
	# The current tile is larger than side tiles, so scale both the label box and
	# its bottom inset by the same factor. This prevents the active counter from
	# drifting down into the border while preserving the authored side-tile layout.
	var side_node_size: float = (
		PORTRAIT_SINGLE_REWARD_NODE_MAX_SIZE * PORTRAIT_SINGLE_REWARD_SIDE_NODE_SCALE
	)
	var node_layout_scale: float = node_rect.size.y / side_node_size
	var label_height: float = 22.0 * node_layout_scale
	var label_bottom_inset: float = 10.0 * node_layout_scale
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
	# Keep the heavier 4 px counter outline, but use the same deep navy
	# outline/shadow colors as the reward-screen heading.
	_apply_portrait_reward_header_text_effect(count_label, 4)
	count_label.add_theme_constant_override("shadow_offset_x", 3)
	count_label.add_theme_constant_override("shadow_offset_y", 3)
	_fit_single_line_label_to_width(
		count_label,
		count_text,
		count_label.size.x,
		font_size,
		PORTRAIT_SINGLE_REWARD_CHAIN_COUNT_MIN_FONT_SIZE
	)
	return count_label

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

func _play_single_player_reward_coin_collection(
	source_visual: Control,
	continue_button: Control = null
) -> void:
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
		tween.tween_callback(Callable(self, "_bounce_portrait_currency_counter"))
		if coin_index == PORTRAIT_SINGLE_REWARD_FLY_COIN_COUNT - 1:
			# The last impact marks the end of the visible crediting sequence. Only
			# now make Continue available; the later overlay cleanup is technical.
			tween.tween_callback(
				Callable(self, "_reveal_single_player_reward_continue_button").bind(
					continue_button
				)
			)
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

func _single_player_reward_check_reveal_delay() -> float:
	# Reveal the claimed marker halfway between the first launch and the last
	# coin reaching the HUD. The overlay cleanup tail is not part of the flight.
	var last_coin_arrival: float = (
		PORTRAIT_SINGLE_REWARD_FLY_START_DELAY
		+ float(maxi(PORTRAIT_SINGLE_REWARD_FLY_COIN_COUNT - 1, 0)) * PORTRAIT_SINGLE_REWARD_FLY_STAGGER
		+ 0.10
		+ PORTRAIT_SINGLE_REWARD_FLY_DURATION
	)
	return lerpf(PORTRAIT_SINGLE_REWARD_FLY_START_DELAY, last_coin_arrival, 0.5)

func _create_single_player_reward_masked_hero(
	parent: Control,
	initial_title_rect: Rect2,
	hero_mistakes: int = 0
) -> Dictionary:
	var viewport_size: Vector2 = get_viewport_rect().size
	var show_terminal_pose: bool = hero_mistakes >= GameSession.MAX_MISTAKES
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
	# Successful rewards keep their fixed pose cheap. A failed reward uses the
	# normal terminal loop, so only that viewport continues redrawing.
	hero_viewport.render_target_update_mode = (
		SubViewport.UPDATE_ALWAYS if show_terminal_pose else SubViewport.UPDATE_ONCE
	)
	hero_mask.add_child(hero_viewport)

	var reward_hero: FlashStageSymbol = FLASH_STAGE_SYMBOL_SCRIPT.new() as FlashStageSymbol
	reward_hero.z_index = 5
	reward_hero.force_immediate_hero_pose_load = show_terminal_pose
	reward_hero.hero_type = _hero_type()
	reward_hero.stage_position = PORTRAIT_SINGLE_REWARD_HERO_POSITION
	reward_hero.animation_time = _hero_animation_time_for_mistakes(hero_mistakes)
	reward_hero.nested_animation_time = (
		HERO_MOV_START_FRAME_TIME
		if show_terminal_pose
		else HERO_MOV_IDLE_FRAME_TIME
	)
	reward_hero.stage_scale_multiplier = PORTRAIT_SINGLE_REWARD_HERO_SCALE_MULTIPLIER
	hero_viewport.add_child(reward_hero)
	if show_terminal_pose:
		reward_hero.call_deferred(
			"play_nested_loop",
			_hero_animation_time_for_mistakes(hero_mistakes),
			HERO_MOV_START_FRAME_TIME,
			_hero_terminal_loop_end_time(),
			HERO_ANIMATION_SPEED_SCALE,
			HERO_MOV_START_FRAME_TIME
		)

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
	count_visual: Label,
	check_visual: Control,
	continue_button: Control
) -> void:
	# Let stage-layout controls resolve their final size/pivot before animating.
	# Flying coins and the source icon fade begin together; the claimed check then
	# pops into the same reward slot with a centered bounce.
	await get_tree().process_frame
	if !is_inside_tree():
		return
	if coin_visual == null or !is_instance_valid(coin_visual) or !coin_visual.is_inside_tree():
		_reveal_single_player_reward_continue_button(continue_button)
		return
	if count_visual == null or !is_instance_valid(count_visual) or !count_visual.is_inside_tree():
		_reveal_single_player_reward_continue_button(continue_button)
		return
	if check_visual == null or !is_instance_valid(check_visual) or !check_visual.is_inside_tree():
		_reveal_single_player_reward_continue_button(continue_button)
		return

	_play_single_player_reward_coin_collection(coin_visual, continue_button)

	# Keep the reward art and xN fully active while the coins are flying. As soon
	# as the checkmark starts appearing, dim both and keep them dimmed: the
	# checkmark marks the reward as permanently claimed.
	coin_visual.modulate.a = 1.0
	count_visual.modulate.a = 1.0

	check_visual.pivot_offset = check_visual.size * 0.5
	check_visual.modulate.a = 0.0
	check_visual.scale = Vector2.ONE * PORTRAIT_SINGLE_REWARD_CHECK_BOUNCE_START_SCALE
	var check_tween := check_visual.create_tween()
	check_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	check_tween.tween_interval(_single_player_reward_check_reveal_delay())
	check_tween.tween_property(check_visual, "modulate:a", 1.0, 0.08)
	var coin_dim := check_tween.parallel().tween_property(
		coin_visual,
		"modulate:a",
		PORTRAIT_SINGLE_REWARD_CHECK_COIN_DIM_ALPHA,
		0.08
	)
	coin_dim.set_trans(Tween.TRANS_QUAD)
	coin_dim.set_ease(Tween.EASE_OUT)
	var count_dim := check_tween.parallel().tween_property(
		count_visual,
		"modulate:a",
		PORTRAIT_SINGLE_REWARD_CHECK_COIN_DIM_ALPHA,
		0.08
	)
	count_dim.set_trans(Tween.TRANS_QUAD)
	count_dim.set_ease(Tween.EASE_OUT)
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

func _reveal_single_player_reward_continue_button(continue_button: Control) -> void:
	if (
		continue_button == null
		or !is_instance_valid(continue_button)
		or !continue_button.is_inside_tree()
	):
		return
	continue_button.set("disabled", false)
	continue_button.set("attention_bounce_enabled", false)
	var paired_back_button := continue_button.get_meta(
		&"paired_failure_back_button",
		null
	) as Control
	if paired_back_button != null and is_instance_valid(paired_back_button):
		paired_back_button.visible = true
		paired_back_button.modulate.a = 0.0
		paired_back_button.set("disabled", false)
		paired_back_button.mouse_filter = Control.MOUSE_FILTER_STOP
		_portrait_back_button_visible = true
	var button_tween := continue_button.create_tween()
	button_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	button_tween.tween_property(continue_button, "modulate:a", 1.0, 0.12)
	if paired_back_button != null and is_instance_valid(paired_back_button):
		button_tween.parallel().tween_property(
			paired_back_button,
			"modulate:a",
			1.0,
			0.12
		)
	var button_grow := button_tween.parallel().tween_property(
		continue_button,
		"visual_scale",
		Vector2.ONE * 1.06,
		0.12
	)
	button_grow.set_trans(Tween.TRANS_BACK)
	button_grow.set_ease(Tween.EASE_OUT)
	var button_settle := button_tween.tween_property(
		continue_button,
		"visual_scale",
		Vector2.ONE,
		0.16
	)
	button_settle.set_trans(Tween.TRANS_BOUNCE)
	button_settle.set_ease(Tween.EASE_OUT)
	button_tween.finished.connect(
		Callable(self, "_enable_single_player_reward_continue_attention").bind(
			continue_button
		),
		CONNECT_ONE_SHOT
	)

func _enable_single_player_reward_continue_attention(continue_button: Control) -> void:
	if continue_button != null and is_instance_valid(continue_button):
		continue_button.set("attention_bounce_enabled", true)

func _start_single_player_reward_intro_deferred(
	title_block: Control,
	title_visual: Control,
	hero_mask: Control,
	hero_texture: TextureRect,
	reward_body: Control,
	hud_content: Control,
	animate_claim: bool,
	coin_visual: Control,
	count_visual: Label,
	check_visual: Control,
	failure_cross_visual: Control,
	failed_final_crown_visual: Control,
	continue_button: Control,
	completion_callback: Callable = Callable()
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

	if completion_callback.is_valid():
		completion_callback.call()
	elif animate_claim:
		_start_single_player_reward_claim_animation_deferred(
			coin_visual,
			count_visual,
			check_visual,
			continue_button
		)
	else:
		if failure_cross_visual != null and is_instance_valid(failure_cross_visual):
			_animate_single_player_failed_reward_marker(
				failure_cross_visual,
				failed_final_crown_visual
			)
		_reveal_single_player_reward_continue_button(continue_button)

func _stage_final_reward_glow(rect: Rect2, tint_color: Color = Color.WHITE) -> TextureRect:
	# The source glow texture is authored in grayscale, like the long-button
	# textures. White is therefore the neutral/default appearance, while modulate
	# can tint the same asset to any UI color without extra shaders.
	var holder := _stage_holder(rect, Control.MOUSE_FILTER_IGNORE)
	holder.name = "FinalRewardGlowHolder"
	holder.z_index = 10
	var glow := TextureRect.new()
	glow.name = "FinalRewardGlow"
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.texture = FINAL_REWARD_ROTATING_GLOW_TEXTURE
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glow.pivot_offset = rect.size * 0.5
	glow.modulate = Color(tint_color.r, tint_color.g, tint_color.b, 0.0)
	glow.set_meta(&"glow_tint_color", tint_color)
	holder.add_child(glow)
	return glow

func _set_final_reward_glow_color(glow: CanvasItem, tint_color: Color) -> void:
	if glow == null or !is_instance_valid(glow):
		return
	var current_alpha: float = glow.modulate.a
	glow.modulate = Color(tint_color.r, tint_color.g, tint_color.b, current_alpha)
	glow.set_meta(&"glow_tint_color", tint_color)

func _start_final_reward_glow_rotation(glow: Control) -> void:
	if glow == null or !is_instance_valid(glow) or !glow.is_inside_tree():
		return
	glow.pivot_offset = glow.size * 0.5
	var rotation_tween := glow.create_tween()
	rotation_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	rotation_tween.set_loops()
	rotation_tween.tween_property(
		glow,
		"rotation",
		TAU,
		PORTRAIT_FINAL_REWARD_GLOW_ROTATION_DURATION
	).from(0.0)

func _play_final_reward_pack_bounce(pack: Control) -> void:
	if pack == null or !is_instance_valid(pack) or !pack.is_inside_tree():
		return
	# FlashStageTexture stores the viewport fit in Control.scale. Preserve that
	# base transform and compensate for the new center pivot before the bounce.
	var rest_position: Vector2 = pack.position
	var rest_scale: Vector2 = pack.scale
	pack.pivot_offset = pack.size * 0.5
	pack.position = rest_position + (rest_scale - Vector2.ONE) * pack.pivot_offset
	var bounce_tween := pack.create_tween()
	bounce_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var grow := bounce_tween.tween_property(
		pack,
		"scale",
		rest_scale * PORTRAIT_FINAL_REWARD_PACK_BOUNCE_SCALE,
		PORTRAIT_FINAL_REWARD_PACK_BOUNCE_GROW_DURATION
	)
	grow.set_trans(Tween.TRANS_QUAD)
	grow.set_ease(Tween.EASE_OUT)
	var settle := bounce_tween.tween_property(
		pack,
		"scale",
		rest_scale,
		PORTRAIT_FINAL_REWARD_PACK_BOUNCE_SETTLE_DURATION
	)
	settle.set_trans(Tween.TRANS_BOUNCE)
	settle.set_ease(Tween.EASE_OUT)
	await bounce_tween.finished
	if pack == null or !is_instance_valid(pack) or !pack.is_inside_tree():
		return
	pack.pivot_offset = Vector2.ZERO
	pack.position = rest_position

func _set_final_reward_collect_pressed(visual: Control, is_pressed: bool) -> void:
	if visual == null or !is_instance_valid(visual) or !visual.is_inside_tree():
		return
	var previous_tween := visual.get_meta(&"final_reward_press_tween", null) as Tween
	if previous_tween != null and previous_tween.is_valid():
		previous_tween.kill()
	var target_scale := Vector2.ONE * (0.93 if is_pressed else 1.0)
	var target_modulate: Color = PORTRAIT_UI_PALETTE.PRESS_HIGHLIGHT if is_pressed else Color.WHITE
	var press_tween := visual.create_tween()
	press_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	press_tween.set_parallel(true)
	press_tween.tween_property(visual, "scale", target_scale, 0.07)
	press_tween.tween_property(visual, "modulate", target_modulate, 0.07)
	visual.set_meta(&"final_reward_press_tween", press_tween)

func _stage_final_reward_collect_text(rect: Rect2) -> Dictionary:
	var holder := _stage_holder(rect, Control.MOUSE_FILTER_IGNORE)
	holder.name = "FinalRewardCollectText"
	holder.z_index = 120
	var visual := Control.new()
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.position = Vector2.ZERO
	visual.size = rect.size
	visual.pivot_offset = rect.size * 0.5
	holder.add_child(visual)
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.text = tr("NO_THANKS")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", UI_PRIMARY_FONT)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color(PORTRAIT_DARK_BLUE.r, PORTRAIT_DARK_BLUE.g, PORTRAIT_DARK_BLUE.b, 0.8))
	label.add_theme_constant_override("outline_size", 2)
	visual.add_child(label)

	var hit_button := _stage_button(
		rect,
		Callable(self, "_claim_single_player_final_reward"),
		""
	)
	hit_button.name = "FinalRewardCollectButton"
	hit_button.z_index = 121
	hit_button.disabled = true
	hit_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hit_button.button_down.connect(
		Callable(self, "_set_final_reward_collect_pressed").bind(visual, true)
	)
	hit_button.button_up.connect(
		Callable(self, "_set_final_reward_collect_pressed").bind(visual, false)
	)
	hit_button.mouse_exited.connect(
		Callable(self, "_set_final_reward_collect_pressed").bind(visual, false)
	)
	holder.modulate.a = 0.0
	return {
		"holder": holder,
		"visual": visual,
		"button": hit_button,
	}

func _portrait_final_reward_center_rect(size: Vector2) -> Rect2:
	var viewport_size: Vector2 = get_viewport_rect().size
	var logical_height: float = PORTRAIT_STAGE_LAYOUT.expanded_stage_height(viewport_size)
	var safe_top: float = PORTRAIT_STAGE_LAYOUT.safe_top_stage(viewport_size)
	var center_stage_y: float = logical_height * 0.5 - safe_top
	return Rect2(
		Vector2(
			(PORTRAIT_STAGE_SIZE.x - size.x) * 0.5,
			center_stage_y - size.y * 0.5
		),
		size
	)

func _portrait_final_reward_amount_rect(coin_rect: Rect2) -> Rect2:
	return Rect2(
		Vector2(
			(PORTRAIT_STAGE_SIZE.x - PORTRAIT_FINAL_REWARD_AMOUNT_SIZE.x) * 0.5,
			coin_rect.end.y - 26.0
		),
		PORTRAIT_FINAL_REWARD_AMOUNT_SIZE
	)

func _portrait_final_reward_caption_rect(coin_rect: Rect2) -> Rect2:
	return Rect2(
		Vector2(
			(PORTRAIT_STAGE_SIZE.x - PORTRAIT_FINAL_REWARD_CAPTION_SIZE.x) * 0.5,
			coin_rect.position.y - PORTRAIT_FINAL_REWARD_CAPTION_SIZE.y - PORTRAIT_FINAL_REWARD_CAPTION_GAP
		),
		PORTRAIT_FINAL_REWARD_CAPTION_SIZE
	)

func _set_panel_fill_color(color: Color, panel: Panel) -> void:
	if panel == null or !is_instance_valid(panel):
		return
	var style := panel.get_theme_stylebox("panel") as StyleBoxFlat
	if style == null:
		return
	style.bg_color = color
	panel.add_theme_stylebox_override("panel", style)

func _build_portrait_result_word_marker_layer(
	layer_name: String,
	layer_size: Vector2,
	stroke_specs: Array,
	stroke_width: float
) -> CanvasGroup:
	var layer := CanvasGroup.new()
	layer.name = layer_name
	layer.self_modulate = Color(1.0, 1.0, 1.0, 0.0)
	var marker_width: float = maxf(layer_size.x, 10.0)
	var marker_height: float = maxf(layer_size.y, 10.0)
	for index in range(stroke_specs.size()):
		var spec: Dictionary = stroke_specs[index]
		var jitter: Array = spec.get("jitter", [])
		var start_x: float = float(spec.get("left", 0.0))
		var end_x: float = marker_width + float(spec.get("right", 0.0))
		var y_start: float = marker_height * float(spec.get("y_start", 0.5))
		var y_end: float = marker_height * float(spec.get("y_end", 0.5))
		var points := PackedVector2Array()
		for point_index in range(jitter.size()):
			var t: float = float(point_index) / maxf(float(jitter.size() - 1), 1.0)
			var y_base: float = lerpf(y_start, y_end, t)
			var y_offset: float = float(jitter[point_index]) * marker_height
			points.append(Vector2(lerpf(start_x, end_x, t), y_base + y_offset))
		var stroke := Line2D.new()
		stroke.name = "%sStroke%d" % [layer_name, index]
		stroke.points = points
		stroke.width = stroke_width
		stroke.begin_cap_mode = Line2D.LINE_CAP_ROUND
		stroke.end_cap_mode = Line2D.LINE_CAP_ROUND
		stroke.joint_mode = Line2D.LINE_JOINT_ROUND
		stroke.default_color = Color.WHITE
		stroke.antialiased = true
		layer.add_child(stroke)
	return layer

func _stage_portrait_result_word_marker(marker_size: Vector2) -> Node2D:
	# Compose a broad base highlight plus a tighter darker pass on top.
	# Each pass is rendered into its own CanvasGroup so opacity is applied once per
	# layer instead of accumulating at stroke crossings.
	var marker := Node2D.new()
	marker.name = "ResultWordMarker"
	var marker_width: float = maxf(marker_size.x, 10.0)
	var marker_height: float = maxf(marker_size.y, 10.0)
	var base_stroke_specs := [
		{
			"y_start": 0.18,
			"y_end": 0.24,
			"left": -10.0,
			"right": 16.0,
			"jitter": [0.04, -0.03, 0.03, -0.02, 0.04, -0.03, 0.02, -0.02, 0.03],
		},
		{
			"y_start": 0.33,
			"y_end": 0.27,
			"left": -20.0,
			"right": 14.0,
			"jitter": [-0.02, 0.03, -0.03, 0.02, -0.01, 0.03, -0.02, 0.02, -0.02],
		},
		{
			"y_start": 0.45,
			"y_end": 0.56,
			"left": -34.0,
			"right": 30.0,
			"jitter": [0.03, -0.03, 0.04, -0.02, 0.03, -0.02, 0.03, -0.03, 0.02],
		},
		{
			"y_start": 0.66,
			"y_end": 0.58,
			"left": -24.0,
			"right": 18.0,
			"jitter": [-0.03, 0.02, -0.02, 0.03, -0.02, 0.02, -0.01, 0.02, -0.02],
		},
		{
			"y_start": 0.80,
			"y_end": 0.86,
			"left": -8.0,
			"right": 10.0,
			"jitter": [0.03, -0.02, 0.02, -0.03, 0.03, -0.03, 0.02, -0.02, 0.01],
		},
	]
	var base_layer := _build_portrait_result_word_marker_layer(
		"BaseLayer",
		Vector2(marker_width, marker_height),
		base_stroke_specs,
		maxf(marker_height * 0.24, 13.0)
	)
	marker.add_child(base_layer)
	var detail_margin_x: float = 8.0
	var detail_margin_y: float = 4.0
	var detail_size := Vector2(
		maxf(marker_width - detail_margin_x * 2.0, 10.0),
		maxf(marker_height - detail_margin_y * 2.0, 10.0)
	)
	var detail_stroke_specs := [
		{
			"y_start": 0.22,
			"y_end": 0.29,
			"left": -6.0,
			"right": 10.0,
			"jitter": [0.03, -0.02, 0.02, -0.02, 0.03, -0.02, 0.02],
		},
		{
			"y_start": 0.46,
			"y_end": 0.40,
			"left": -12.0,
			"right": 12.0,
			"jitter": [-0.02, 0.02, -0.03, 0.02, -0.01, 0.02, -0.02],
		},
		{
			"y_start": 0.66,
			"y_end": 0.74,
			"left": -8.0,
			"right": 8.0,
			"jitter": [0.02, -0.02, 0.03, -0.02, 0.02, -0.01, 0.01],
		},
	]
	var detail_layer := _build_portrait_result_word_marker_layer(
		"DetailLayer",
		detail_size,
		detail_stroke_specs,
		maxf(detail_size.y * 0.20, 10.0)
	)
	detail_layer.scale = Vector2(1.1, 1.1)
	detail_layer.position = Vector2(detail_margin_x, detail_margin_y) - detail_size * 0.05
	marker.add_child(detail_layer)
	return marker

func _set_portrait_result_word_marker_color(result_controls: Dictionary, color: Color) -> void:
	var marker := result_controls.get("word_marker") as Node2D
	if marker == null or !is_instance_valid(marker):
		return
	var marker_color: Color = PORTRAIT_UI_PALETTE.MARKER_SUCCESS
	if color == StageLetterButton.CROSSED_COLOR:
		marker_color = PORTRAIT_UI_PALETTE.MARKER_ERROR
	var base_layer := marker.get_node_or_null("BaseLayer") as CanvasGroup
	if base_layer != null and is_instance_valid(base_layer):
		base_layer.self_modulate = Color(
			marker_color.r,
			marker_color.g,
			marker_color.b,
			0.35
		)
	var detail_layer := marker.get_node_or_null("DetailLayer") as CanvasGroup
	if detail_layer != null and is_instance_valid(detail_layer):
		var darker := Color(
			clampf(marker_color.r * 0.9, 0.0, 1.0),
			clampf(marker_color.g * 0.9, 0.0, 1.0),
			clampf(marker_color.b * 0.9, 0.0, 1.0),
			0.7
		)
		detail_layer.self_modulate = darker

func _ensure_final_reward_double_button_bonus_icon(button: Control) -> TextureRect:
	if button == null or !is_instance_valid(button):
		return null
	var existing := button.get_node_or_null("BonusCoinIcon") as TextureRect
	if existing != null and is_instance_valid(existing):
		return existing
	var coin_icon := TextureRect.new()
	coin_icon.name = "BonusCoinIcon"
	coin_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin_icon.texture = SOFT_CURRENCY_COIN_TEXTURE
	button.add_child(coin_icon)
	return coin_icon

func _ensure_final_reward_double_button_icon_shadow(button: Control) -> TextureRect:
	if button == null or !is_instance_valid(button):
		return null
	var existing := button.get_node_or_null("AdIconShadow") as TextureRect
	if existing != null and is_instance_valid(existing):
		return existing
	var icon_shadow := TextureRect.new()
	icon_shadow.name = "AdIconShadow"
	icon_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_shadow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_shadow.modulate = Color(
		PORTRAIT_DARK_BLUE.r,
		PORTRAIT_DARK_BLUE.g,
		PORTRAIT_DARK_BLUE.b,
		0.92
	)
	button.add_child(icon_shadow)
	icon_shadow.z_index = 0
	button.move_child(icon_shadow, 0)
	return icon_shadow

func _ensure_final_reward_double_button_icon(button: Control) -> TextureRect:
	if button == null or !is_instance_valid(button):
		return null
	var existing := button.get_node_or_null("AdIcon") as TextureRect
	if existing != null and is_instance_valid(existing):
		return existing
	var ad_icon := TextureRect.new()
	ad_icon.name = "AdIcon"
	ad_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ad_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ad_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ad_icon.texture = WATCH_AD_ICON_TEXTURE
	button.add_child(ad_icon)
	return ad_icon

func _sync_final_reward_double_button_content(button: Control) -> void:
	if button == null or !is_instance_valid(button):
		return
	# Use StageLongButton's native text+icon layout. It measures the caption and
	# icon as one row and centers that complete row inside the authored button.
	button.set("button_text", tr("REWARD_GET_X2"))
	button.set("icon_texture", WATCH_AD_ICON_TEXTURE)
	button.set("icon_stage_size", PORTRAIT_FINAL_REWARD_DOUBLE_BUTTON_BONUS_COIN_SIZE * 2.0)
	button.set("icon_gap_stage", PORTRAIT_FINAL_REWARD_DOUBLE_BUTTON_PLAY_GAP)
	button.set("icon_before_text", true)
	button.set("icon_shadow_enabled", true)
	button.set("icon_shadow_offset_stage", Vector2(2.0, 2.0))
	button.set("icon_shadow_color", PORTRAIT_UI_PALETTE.AD_ICON_SHADOW)
	var label := button.get_node_or_null("Text") as Label
	if label != null and is_instance_valid(label):
		label.visible = true
		label.add_theme_font_override("font", UI_PRIMARY_FONT)
		label.add_theme_font_size_override("font_size", 24)
		label.clip_text = false
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
	var built_in_icon := button.get_node_or_null("Icon") as TextureRect
	if built_in_icon != null and is_instance_valid(built_in_icon):
		built_in_icon.visible = true
	# Legacy final-reward overlay icons are no longer used; the standard button
	# owns its icon through the built-in Icon node.
	for child_name: String in ["AdIcon", "AdIconShadow", "BonusCoinIcon"]:
		var child := button.get_node_or_null(child_name) as CanvasItem
		if child != null and is_instance_valid(child):
			child.visible = false

func _configure_final_reward_double_button(button: Control, bonus_amount: int) -> void:
	if button == null or !is_instance_valid(button):
		return
	_sync_final_reward_double_button_content(button)
	# Keep the standard stretchable long-button slices and only tint them to the
	# same purple used by rewarded-ad indicators.
	if button.has_method("set_color_palette"):
		button.call(
			"set_color_palette",
			PORTRAIT_AD_BADGE_PURPLE,
			PORTRAIT_UI_PALETTE.AD_PURPLE_PRESSED,
			PORTRAIT_UI_PALETTE.AD_PURPLE_SELECTED
		)

func _reveal_final_reward_collect_action(
	collect_holder: Control,
	collect_button: Button
) -> void:
	if collect_holder == null or !is_instance_valid(collect_holder) or !collect_holder.is_inside_tree():
		return
	if collect_button == null or !is_instance_valid(collect_button) or !collect_button.is_inside_tree():
		return
	collect_button.disabled = false
	collect_button.mouse_filter = Control.MOUSE_FILTER_STOP
	var reveal_tween := collect_holder.create_tween()
	reveal_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	reveal_tween.tween_property(
		collect_holder,
		"modulate:a",
		1.0,
		PORTRAIT_FINAL_REWARD_ACTION_REVEAL_DURATION
	)

func _reveal_final_reward_actions(
	double_button: Control,
	collect_holder: Control,
	collect_button: Button
) -> void:
	if double_button == null or !is_instance_valid(double_button) or !double_button.is_inside_tree():
		return
	double_button.set("button_disabled", false)
	double_button.set("visual_scale", Vector2.ONE * 0.94)
	var reveal_tween := double_button.create_tween()
	reveal_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	reveal_tween.set_parallel(true)
	reveal_tween.tween_property(
		double_button,
		"modulate:a",
		1.0,
		PORTRAIT_FINAL_REWARD_ACTION_REVEAL_DURATION
	)
	var button_grow := reveal_tween.tween_property(
		double_button,
		"visual_scale",
		Vector2.ONE,
		PORTRAIT_FINAL_REWARD_ACTION_REVEAL_DURATION
	)
	button_grow.set_trans(Tween.TRANS_BACK)
	button_grow.set_ease(Tween.EASE_OUT)
	if (
		collect_holder != null
		and is_instance_valid(collect_holder)
		and collect_holder.is_inside_tree()
		and collect_button != null
		and is_instance_valid(collect_button)
		and collect_button.is_inside_tree()
	):
		var collect_delay := collect_holder.create_tween()
		collect_delay.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		collect_delay.tween_interval(
			PORTRAIT_FINAL_REWARD_ACTION_REVEAL_DURATION
			+ PORTRAIT_FINAL_REWARD_COLLECT_DELAY
		)
		collect_delay.tween_callback(
			Callable(self, "_reveal_final_reward_collect_action").bind(
				collect_holder,
				collect_button
			)
		)

func _start_single_player_final_reward_transition_deferred(
	chain_holder: Control,
	_hero_mask: Control,
	hero_texture: TextureRect,
	source_coin: Control,
	source_count: Label,
	transition_pack: Control,
	background_overlay: Control,
	title_panel: Panel,
	glow: Control,
	caption_label: Label,
	amount_label: Label,
	target_coin_rect: Rect2,
	double_button: Control,
	collect_holder: Control,
	collect_button: Button
) -> void:
	if transition_pack == null or !is_instance_valid(transition_pack) or !transition_pack.is_inside_tree():
		_reveal_final_reward_actions(double_button, collect_holder, collect_button)
		return
	var hold_tween := transition_pack.create_tween()
	hold_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	hold_tween.tween_interval(PORTRAIT_FINAL_REWARD_CHAIN_HOLD_DURATION)
	await hold_tween.finished
	if (
		chain_holder == null
		or !is_instance_valid(chain_holder)
		or !chain_holder.is_inside_tree()
		or source_coin == null
		or !is_instance_valid(source_coin)
		or !source_coin.is_inside_tree()
		or source_count == null
		or !is_instance_valid(source_count)
		or !source_count.is_inside_tree()
	):
		_reveal_final_reward_actions(double_button, collect_holder, collect_button)
		return

	# The final tile stays visible long enough to read the completed chain. Its
	# regular reward art then crossfades into the authored grand-prize coin pack.
	var crossfade_tween := transition_pack.create_tween()
	crossfade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	crossfade_tween.set_parallel(true)
	crossfade_tween.tween_property(
		source_coin,
		"modulate:a",
		0.0,
		PORTRAIT_FINAL_REWARD_ICON_CROSSFADE_DURATION
	)
	crossfade_tween.tween_property(
		source_count,
		"modulate:a",
		0.0,
		PORTRAIT_FINAL_REWARD_ICON_CROSSFADE_DURATION
	)
	crossfade_tween.tween_property(
		transition_pack,
		"modulate:a",
		1.0,
		PORTRAIT_FINAL_REWARD_ICON_CROSSFADE_DURATION
	)
	await crossfade_tween.finished

	# Grow and move the converted pack into the physical center while the chain
	# fades out and the hero simply disappears through alpha instead of shrinking.
	# Coins are still only credited after the player chooses the main-menu action;
	# this phase is presentation-only.
	if hero_texture != null and is_instance_valid(hero_texture):
		hero_texture.pivot_offset = hero_texture.size * 0.5
	var replace_tween := transition_pack.create_tween()
	replace_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var move_pack := replace_tween.tween_property(
		transition_pack,
		"stage_rect",
		target_coin_rect,
		PORTRAIT_FINAL_REWARD_REPLACE_DURATION
	)
	move_pack.set_trans(Tween.TRANS_QUAD)
	move_pack.set_ease(Tween.EASE_OUT)
	replace_tween.parallel().tween_property(
		chain_holder,
		"modulate:a",
		0.0,
		PORTRAIT_FINAL_REWARD_REPLACE_DURATION * 0.72
	)
	if background_overlay != null and is_instance_valid(background_overlay):
		var backdrop_fade := replace_tween.parallel().tween_property(
			background_overlay,
			"modulate:a",
			1.0,
			PORTRAIT_FINAL_REWARD_BACKGROUND_FADE_DURATION
		)
		backdrop_fade.set_trans(Tween.TRANS_SINE)
		backdrop_fade.set_ease(Tween.EASE_IN_OUT)
	if title_panel != null and is_instance_valid(title_panel):
		replace_tween.parallel().tween_method(
			Callable(self, "_set_panel_fill_color").bind(title_panel),
			PORTRAIT_SINGLE_REWARD_TITLE_BLOCK_COLOR,
			PORTRAIT_BLUE,
			PORTRAIT_FINAL_REWARD_BACKGROUND_FADE_DURATION
		)
	if hero_texture != null and is_instance_valid(hero_texture):
		var hero_fade := replace_tween.parallel().tween_property(
			hero_texture,
			"modulate:a",
			0.0,
			PORTRAIT_FINAL_REWARD_REPLACE_DURATION
		)
		hero_fade.set_trans(Tween.TRANS_QUAD)
		hero_fade.set_ease(Tween.EASE_IN)
	await replace_tween.finished

	if glow != null and is_instance_valid(glow):
		_start_final_reward_glow_rotation(glow)
		var prize_reveal := glow.create_tween()
		prize_reveal.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		prize_reveal.set_parallel(true)
		prize_reveal.tween_property(
			glow,
			"modulate:a",
			PORTRAIT_FINAL_REWARD_GLOW_ALPHA,
			PORTRAIT_FINAL_REWARD_ACTION_REVEAL_DURATION
		)
		if caption_label != null and is_instance_valid(caption_label):
			prize_reveal.tween_property(
				caption_label,
				"modulate:a",
				1.0,
				PORTRAIT_FINAL_REWARD_ACTION_REVEAL_DURATION
			)
		if amount_label != null and is_instance_valid(amount_label):
			prize_reveal.tween_property(
				amount_label,
				"modulate:a",
				1.0,
				PORTRAIT_FINAL_REWARD_ACTION_REVEAL_DURATION
			)
	await _play_final_reward_pack_bounce(transition_pack)
	_reveal_final_reward_actions(double_button, collect_holder, collect_button)

func _show_portrait_rewarded_action(action: StringName, level_index: int = -1) -> bool:
	if action == &"" or _portrait_final_reward_waiting_for_ad or _portrait_rewarded_action != &"":
		return false
	var ads_service: Node = _portrait_ads_service()
	if ads_service == null or !ads_service.has_method("show_rewarded_video"):
		return false
	_connect_portrait_rewarded_action_signals(ads_service)
	_portrait_rewarded_action = action
	_portrait_rewarded_action_level_index = level_index
	_portrait_rewarded_action_earned = false
	_set_portrait_rewarded_action_control_enabled(action, level_index, false)
	if !bool(ads_service.call("show_rewarded_video")):
		_portrait_rewarded_action = &""
		_portrait_rewarded_action_level_index = -1
		_set_portrait_rewarded_action_control_enabled(action, level_index, true)
		return false
	return true

func _connect_portrait_rewarded_action_signals(ads_service: Node) -> void:
	var rewarded_callback := Callable(self, "_on_portrait_rewarded_action_rewarded")
	if ads_service.has_signal(&"rewarded") and !ads_service.is_connected(
		&"rewarded",
		rewarded_callback
	):
		ads_service.connect(&"rewarded", rewarded_callback)
	var closed_callback := Callable(self, "_on_portrait_rewarded_action_closed")
	if ads_service.has_signal(&"rewarded_video_closed") and !ads_service.is_connected(
		&"rewarded_video_closed",
		closed_callback
	):
		ads_service.connect(&"rewarded_video_closed", closed_callback)
	var failed_callback := Callable(self, "_on_portrait_rewarded_action_failed_to_show")
	if ads_service.has_signal(&"rewarded_video_failed_to_show") and !ads_service.is_connected(
		&"rewarded_video_failed_to_show",
		failed_callback
	):
		ads_service.connect(&"rewarded_video_failed_to_show", failed_callback)

func _set_portrait_rewarded_action_control_enabled(
	action: StringName,
	level_index: int,
	enabled: bool
) -> void:
	match action:
		&"hint_open":
			var open_button: Control = _portrait_game_hint_button_for_key(GameState.HINT_OPEN_LETTER)
			if open_button != null and is_instance_valid(open_button):
				open_button.set("button_disabled", !enabled)
		&"hint_remove":
			var remove_button: Control = _portrait_game_hint_button_for_key(GameState.HINT_REMOVE_WRONG)
			if remove_button != null and is_instance_valid(remove_button):
				remove_button.set("button_disabled", !enabled)
		&"theme_reroll":
			if level_index == single_player_popup_level_index:
				_update_single_player_theme_reroll_button_state()
		&"heart_refill":
			var can_use_rewarded_refill: bool = enabled and GameState.get_hearts() < GameState.MAX_HEARTS
			for node: Node in get_tree().get_nodes_in_group(&"heart_refill_ad_button"):
				var refill_ad_button := node as Control
				if refill_ad_button != null and is_instance_valid(refill_ad_button):
					refill_ad_button.set("button_disabled", !can_use_rewarded_refill)

func _on_portrait_rewarded_action_rewarded(_currency: String, _amount: int) -> void:
	if _portrait_rewarded_action != &"":
		_portrait_rewarded_action_earned = true

func _on_portrait_rewarded_action_closed() -> void:
	if _portrait_rewarded_action == &"":
		return
	var action: StringName = _portrait_rewarded_action
	var level_index: int = _portrait_rewarded_action_level_index
	var earned_reward: bool = _portrait_rewarded_action_earned
	_portrait_rewarded_action = &""
	_portrait_rewarded_action_level_index = -1
	_portrait_rewarded_action_earned = false
	if !earned_reward:
		_set_portrait_rewarded_action_control_enabled(action, level_index, true)
		return
	match action:
		&"hint_open":
			if GameSession.can_use_open_letter_hint_ad():
				round_result_delay_requested = true
				GameSession.use_open_letter_hint_ad()
				round_result_delay_requested = false
		&"hint_remove":
			if GameSession.can_use_remove_wrong_hint_ad():
				GameSession.use_remove_wrong_hint_ad()
		&"theme_reroll":
			if (
				level_index == single_player_popup_level_index
				and _single_player_theme_reroll_used
				and !_single_player_theme_ad_reroll_used
				and !_single_player_theme_slot_animating
			):
				_single_player_theme_ad_reroll_used = true
				GameState.set_single_level_theme_reroll_state(
					Database.current_language,
					level_index,
					GameState.SINGLE_LEVEL_THEME_REROLL_AD_USED
				)
				_update_single_player_theme_reroll_badge()
				_update_single_player_theme_reroll_button_state()
				_perform_single_player_theme_reroll(level_index)
		&"heart_refill":
			if GameState.get_hearts() < GameState.MAX_HEARTS:
				GameState.add_hearts(1)
			var popup_nodes: Array = get_tree().get_nodes_in_group(&"heart_refill_popup")
			if !popup_nodes.is_empty():
				var continue_action: Callable = heart_refill_continue_action
				var restore_action: Callable = heart_refill_store_return_action
				_show_heart_refill_popup(continue_action, restore_action)

func _on_portrait_rewarded_action_failed_to_show(_message: String) -> void:
	if _portrait_rewarded_action == &"":
		return
	var action: StringName = _portrait_rewarded_action
	var level_index: int = _portrait_rewarded_action_level_index
	_portrait_rewarded_action = &""
	_portrait_rewarded_action_level_index = -1
	_portrait_rewarded_action_earned = false
	_set_portrait_rewarded_action_control_enabled(action, level_index, true)

func _on_final_reward_double_pressed() -> void:
	if (
		_portrait_final_reward_claim_in_progress
		or _portrait_final_reward_waiting_for_ad
		or _portrait_rewarded_action != &""
	):
		return
	var ads_service: Node = _portrait_ads_service()
	if ads_service == null or !ads_service.has_method("show_rewarded_video"):
		return
	_connect_final_reward_ad_signals(ads_service)
	_portrait_final_reward_waiting_for_ad = true
	_portrait_final_reward_earned_ad_reward = false
	_set_final_reward_double_button_enabled(false)
	if !bool(ads_service.call("show_rewarded_video")):
		# The service starts a preload when an ad is not ready. Keep the reward
		# unclaimed and let the player retry once the rewarded placement is loaded.
		_portrait_final_reward_waiting_for_ad = false
		_set_final_reward_double_button_enabled(true)

func _connect_final_reward_ad_signals(ads_service: Node) -> void:
	var rewarded_callback := Callable(self, "_on_final_reward_ad_rewarded")
	if ads_service.has_signal(&"rewarded") and !ads_service.is_connected(
		&"rewarded",
		rewarded_callback
	):
		ads_service.connect(&"rewarded", rewarded_callback)
	var closed_callback := Callable(self, "_on_final_reward_ad_closed")
	if ads_service.has_signal(&"rewarded_video_closed") and !ads_service.is_connected(
		&"rewarded_video_closed",
		closed_callback
	):
		ads_service.connect(&"rewarded_video_closed", closed_callback)
	var failed_callback := Callable(self, "_on_final_reward_ad_failed_to_show")
	if ads_service.has_signal(&"rewarded_video_failed_to_show") and !ads_service.is_connected(
		&"rewarded_video_failed_to_show",
		failed_callback
	):
		ads_service.connect(&"rewarded_video_failed_to_show", failed_callback)

func _set_final_reward_double_button_enabled(enabled: bool) -> void:
	if (
		_portrait_final_reward_double_button != null
		and is_instance_valid(_portrait_final_reward_double_button)
		and _portrait_final_reward_double_button.is_inside_tree()
	):
		_portrait_final_reward_double_button.set("button_disabled", !enabled)

func _on_final_reward_ad_rewarded(_currency: String, _amount: int) -> void:
	if _portrait_final_reward_waiting_for_ad:
		_portrait_final_reward_earned_ad_reward = true

func _on_final_reward_ad_closed() -> void:
	if !_portrait_final_reward_waiting_for_ad:
		return
	_portrait_final_reward_waiting_for_ad = false
	if _portrait_final_reward_earned_ad_reward:
		_portrait_final_reward_earned_ad_reward = false
		_complete_single_player_final_reward(2)
	else:
		_set_final_reward_double_button_enabled(true)

func _on_final_reward_ad_failed_to_show(_message: String) -> void:
	if !_portrait_final_reward_waiting_for_ad:
		return
	_portrait_final_reward_waiting_for_ad = false
	_portrait_final_reward_earned_ad_reward = false
	_set_final_reward_double_button_enabled(true)

func _claim_single_player_final_reward() -> void:
	_complete_single_player_final_reward(1)

func _complete_single_player_final_reward(reward_multiplier: int) -> void:
	if _portrait_final_reward_claim_in_progress:
		return
	_portrait_final_reward_claim_in_progress = true
	_portrait_final_reward_waiting_for_ad = false
	_portrait_final_reward_earned_ad_reward = false
	if bool(last_result_data.get("single_player_reward_deferred", false)):
		_portrait_pending_home_reward_amount += maxi(
			int(last_result_data.get("single_player_deferred_reward_amount", 0))
			* maxi(reward_multiplier, 1),
			0
		)
	GameSession.discard_current_round()
	game_finished = false
	last_result_data = {}
	single_player_active_word_slot = -1
	show_menu()

func _set_home_reward_animated_balance(value: float) -> void:
	var balance_text: String = _soft_currency_balance_text(int(round(value)))
	for balance_node: Node in get_tree().get_nodes_in_group(&"soft_currency_balance_label"):
		var balance_label := balance_node as Label
		if balance_label != null and is_instance_valid(balance_label):
			balance_label.text = balance_text

func _play_pending_home_reward_animation() -> void:
	var reward_amount: int = _portrait_pending_home_reward_amount
	_portrait_pending_home_reward_amount = 0
	if reward_amount <= 0:
		return
	await get_tree().process_frame
	var previous_balance: int = GameState.get_soft_currency()
	var final_balance: int = previous_balance + reward_amount
	GameState.add_soft_currency(reward_amount)
	if (
		_portrait_currency_coin_icon_visual == null
		or !is_instance_valid(_portrait_currency_coin_icon_visual)
		or !_portrait_currency_coin_icon_visual.is_inside_tree()
	):
		return
	_set_home_reward_animated_balance(float(previous_balance))
	var source := _stage_holder(
		Rect2(208.0, 470.0, 64.0, 64.0),
		Control.MOUSE_FILTER_IGNORE
	)
	source.modulate.a = 0.0
	_play_single_player_reward_coin_collection(source)
	var count_tween := source.create_tween()
	count_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var roll := count_tween.tween_method(
		Callable(self, "_set_home_reward_animated_balance"),
		float(previous_balance),
		float(final_balance),
		PORTRAIT_FINAL_REWARD_HOME_COUNT_DURATION
	)
	roll.set_trans(Tween.TRANS_QUAD)
	roll.set_ease(Tween.EASE_OUT)
	count_tween.tween_callback(Callable(source, "queue_free"))

func _show_single_player_reward_chain_screen() -> void:
	var level_index: int = int(last_result_data.get(
		"single_player_level_index",
		single_player_active_level_index
	))
	if level_index < 0:
		show_menu()
		return
	var is_failure_reward: bool = !last_result_is_win

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
	var is_final_reward: bool = (
		last_result_is_win
		and bool(last_result_data.get("single_player_level_completed", false))
		and current_slot == word_count - 1
	)
	if is_final_reward:
		_portrait_final_reward_claim_in_progress = false
		_portrait_final_reward_waiting_for_ad = false
		_portrait_final_reward_earned_ad_reward = false
	var challenge_level: bool = _single_player_is_bonus_level(level_index)
	var header_color: Color = PORTRAIT_CHALLENGE_POPUP_HEADER if challenge_level else PORTRAIT_BLUE
	var accent_color: Color = StageLetterButton.CIRCLED_COLOR
	var resume_without_intro: bool = _portrait_single_reward_resume_without_intro
	_portrait_single_reward_resume_without_intro = false
	var result_title_color: Color = (
		PORTRAIT_SINGLE_REWARD_FAILURE_TITLE_COLOR
		if is_failure_reward
		else PORTRAIT_SINGLE_REWARD_SUCCESS_TITLE_COLOR
	)

	_clear()
	_portrait_screen()
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
		PORTRAIT_SINGLE_REWARD_TITLE_BLOCK_COLOR,
		0.0,
		PORTRAIT_SINGLE_REWARD_TITLE_BLOCK_COLOR,
		0.0
	)
	title_panel.z_index = 0
	var level_title_text: String = tr("LEVEL_NUMBER") % (level_index + 1)
	var result_heading_text: String = (
		tr("REWARD_NOT_COMPLETED")
		if is_failure_reward
		else (
			tr("REWARD_COMPLETED")
			if is_final_reward
			else tr("REWARD_WORD_GUESSED")
		)
	)
	var reward_title := Label.new()
	reward_title.name = "RewardTitle"
	reward_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reward_title.position = Vector2(0.0, 40.0)
	reward_title.size = Vector2(title_visual.size.x, PORTRAIT_SINGLE_REWARD_TITLE_HEIGHT)
	reward_title.text = result_heading_text
	var reward_title_font_size: int = PORTRAIT_SINGLE_REWARD_TITLE_FONT_SIZE
	if is_final_reward:
		reward_title.position = Vector2(0.0, 40.0)
		reward_title.size = Vector2(title_visual.size.x, PORTRAIT_SINGLE_REWARD_TITLE_HEIGHT)
		reward_title_font_size = PORTRAIT_SINGLE_REWARD_TITLE_FONT_SIZE
	reward_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	reward_title.add_theme_font_override("font", UI_PRIMARY_FONT)
	reward_title.add_theme_font_size_override("font_size", reward_title_font_size)
	reward_title.add_theme_color_override("font_color", result_title_color)
	_apply_portrait_reward_header_text_effect(reward_title, 2)
	reward_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	reward_title.clip_text = false
	_fit_single_line_label_to_width(
		reward_title,
		reward_title.text,
		reward_title.size.x,
		reward_title_font_size,
		20
	)
	reward_title.z_index = 1
	title_visual.add_child(reward_title)
	var reward_subtitle := Label.new()
	reward_subtitle.name = "RewardSubtitle"
	reward_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reward_subtitle.position = Vector2(0.0, PORTRAIT_SINGLE_REWARD_SUBTITLE_TOP)
	reward_subtitle.size = Vector2(title_visual.size.x, PORTRAIT_SINGLE_REWARD_SUBTITLE_HEIGHT)
	reward_subtitle.text = level_title_text
	reward_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	reward_subtitle.add_theme_font_override("font", UI_HEADING_FONT)
	reward_subtitle.add_theme_font_size_override("font_size", PORTRAIT_SINGLE_REWARD_SUBTITLE_FONT_SIZE)
	reward_subtitle.add_theme_color_override("font_color", Color.WHITE)
	reward_subtitle.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.0))
	reward_subtitle.add_theme_constant_override("outline_size", 0)
	reward_subtitle.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.0))
	reward_subtitle.add_theme_constant_override("shadow_offset_x", 0)
	reward_subtitle.add_theme_constant_override("shadow_offset_y", 0)
	reward_subtitle.add_theme_constant_override("shadow_outline_size", 0)
	reward_subtitle.autowrap_mode = TextServer.AUTOWRAP_OFF
	reward_subtitle.clip_text = false
	reward_subtitle.z_index = 1
	title_visual.add_child(reward_subtitle)

	_stage_portrait_ad_banner()

	# Keep the persistent HUD and the celebratory title visible independently.
	# Reward content itself is revealed only after the title finishes its first
	# bounce, making the success/failure title the first screen element shown.
	# Render the hero into a transparent viewport and reveal only the portion below
	# the moving title block. This is a real clip: no covering texture or color is
	# drawn over the paper background.
	var final_reward_background_overlay: Control = null
	if is_final_reward:
		final_reward_background_overlay = _stage_horizontal_fill(
			PORTRAIT_HEADER_HEIGHT,
			PORTRAIT_STAGE_SIZE.y - PORTRAIT_HEADER_HEIGHT,
			PORTRAIT_SINGLE_REWARD_TITLE_BLOCK_COLOR
		)
		final_reward_background_overlay.name = "FinalRewardBackgroundOverlay"
		final_reward_background_overlay.modulate.a = 0.0
		final_reward_background_overlay.z_index = -1
	var masked_hero: Dictionary = _create_single_player_reward_masked_hero(
		reward_screen_content,
		PORTRAIT_SINGLE_REWARD_TITLE_BLOCK_CENTER_RECT,
		GameSession.MAX_MISTAKES if is_failure_reward else 0
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
		(
			Callable()
			if is_final_reward
			else Callable(self, "_return_to_single_player_reward_from_coin_store")
		),
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
	var animate_current_claim: bool = (
		!is_failure_reward
		and !is_final_reward
		and reward_claim_key != _portrait_last_animated_reward_claim_key
	)
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

	# Chain pieces share one fixed-stage parent. Its stage Y stays at zero while
	# children use local coordinates, preventing connectors from jumping to the
	# physical bottom when their midpoint crosses the y=688 layout threshold on
	# tall phones. Tiles and links now remain one inseparable composition.
	var chain_holder := _stage_holder(
		Rect2(Vector2.ZERO, PORTRAIT_STAGE_SIZE),
		Control.MOUSE_FILTER_IGNORE
	)
	chain_holder.name = "SinglePlayerRewardChain"
	chain_holder.z_index = 0

	for link_slot in range(maxi(word_count - 1, 0)):
		var left_size: float = float(node_sizes[link_slot])
		var right_size: float = float(node_sizes[link_slot + 1])
		var left_rect := Rect2(
			float(node_positions_x[link_slot]),
			chain_center_y - left_size * 0.5,
			left_size,
			left_size
		)
		var right_rect := Rect2(
			float(node_positions_x[link_slot + 1]),
			chain_center_y - right_size * 0.5,
			right_size,
			right_size
		)
		var link_start_x: float = left_rect.position.x + left_rect.size.x - PORTRAIT_SINGLE_REWARD_CHAIN_LINK_OVERLAP
		var link_end_x: float = right_rect.position.x + PORTRAIT_SINGLE_REWARD_CHAIN_LINK_OVERLAP
		var link_rect := Rect2(
			link_start_x,
			chain_center_y - PORTRAIT_SINGLE_REWARD_CHAIN_LINK_THICKNESS * 0.5,
			maxf(1.0, link_end_x - link_start_x),
			PORTRAIT_SINGLE_REWARD_CHAIN_LINK_THICKNESS
		)
		# Visually connect adjacent rewards into one continuous chain. A link is
		# considered active as soon as the path reaches the reward on its right.
		_stage_single_player_reward_chain_link(
			chain_holder,
			link_rect
		)

	var current_reward_coin_visual: Control = null
	var current_reward_count_visual: Label = null
	var current_reward_check_icon: Control = null
	var current_reward_coin_stage_rect := Rect2()
	var failure_reward_cross_visual: Control = null
	var failed_final_reward_crown_visual: Control = null
	for word_slot in range(word_count):
		var node_size: float = float(node_sizes[word_slot])
		var node_x: float = float(node_positions_x[word_slot])
		var node_y: float = chain_center_y - node_size * 0.5

		var is_previous: bool = word_slot < current_slot
		var is_current: bool = word_slot == current_slot
		var is_failed_current: bool = is_failure_reward and is_current
		var reward_amount: int = _single_player_reward_for_slot(word_slot, word_count)
		# Reward amounts start fully white. Once a reward is claimed, the checkmark
		# dims both its coin pile and xN; future/unclaimed rewards stay white.
		var count_color: Color = Color.WHITE

		var node_rect := Rect2(node_x, node_y, node_size, node_size)
		var node_holder := Control.new()
		node_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node_holder.position = node_rect.position
		node_holder.size = node_rect.size
		chain_holder.add_child(node_holder)
		node_holder.z_index = 1
		_stage_single_player_reward_tile(
			node_holder,
			node_size,
			level_index,
			word_slot <= current_slot,
			is_current,
			is_failed_current,
			accent_color,
			header_color
		)
		var local_node_rect := Rect2(Vector2.ZERO, Vector2.ONE * node_size)
		var crown_visual: Control = null
		if word_slot == word_count - 1:
			crown_visual = _stage_single_player_reward_crown(node_holder, local_node_rect)
			if is_failed_current:
				failed_final_reward_crown_visual = crown_visual
		# Scale the reward art by the same authored factor as its tile. Do not cap
		# the current slot at the old 72 px limit: the current tile is 4/3 larger
		# than a side tile, so its coin pile should be 4/3 larger as well.
		var coin_size: float = maxf(
			node_size * PORTRAIT_SINGLE_REWARD_CHAIN_ICON_SCALE,
			30.0
		)
		var coin_rect := Rect2(
			(node_size - coin_size) * 0.5,
			(node_size - coin_size) * 0.5 - 4.0,
			coin_size,
			coin_size
		)
		var coin_visual := _stage_single_player_reward_coin_pile(node_holder, coin_rect)
		var is_claimed: bool = (
			is_previous
			or (
				is_current
				and !is_final_reward
				and !animate_current_claim
				and !is_failed_current
			)
		)
		if is_failed_current:
			failure_reward_cross_visual = _stage_single_player_reward_status_icon(
				node_holder,
				local_node_rect,
				true,
				false
			)
		elif is_claimed:
			_stage_single_player_reward_status_icon(node_holder, local_node_rect)
		elif is_current and !is_final_reward:
			current_reward_coin_visual = coin_visual
			current_reward_check_icon = _stage_single_player_reward_status_icon(
				node_holder,
				local_node_rect,
				true
			)

		var count_font_size: int = int(round(
			float(PORTRAIT_SINGLE_REWARD_CHAIN_COUNT_FONT_SIZE) * (1.12 if is_current else 1.0)
		))
		var count_visual := _stage_single_player_reward_count(
			node_holder,
			local_node_rect,
			coin_rect,
			reward_amount,
			count_font_size,
			count_color
		)
		if is_claimed or is_failed_current:
			# Claimed and failed rewards keep both the coin pile and xN inactive.
			# Future rewards stay white.
			coin_visual.modulate.a = PORTRAIT_SINGLE_REWARD_CHECK_COIN_DIM_ALPHA
			count_visual.modulate.a = PORTRAIT_SINGLE_REWARD_CHECK_COIN_DIM_ALPHA
		elif is_current:
			current_reward_coin_visual = coin_visual
			current_reward_count_visual = count_visual
			current_reward_coin_stage_rect = Rect2(
				node_rect.position + coin_rect.position,
				coin_rect.size
			)

	var continue_button: Control = null
	var final_reward_completion := Callable()
	if is_final_reward:
		var reward_amount: int = int(last_result_data.get(
			"single_player_deferred_reward_amount",
			_single_player_reward_for_slot(current_slot, word_count)
		))
		if reward_amount <= 0:
			reward_amount = _single_player_reward_for_slot(current_slot, word_count)
		var target_coin_rect: Rect2 = _portrait_final_reward_center_rect(
			PORTRAIT_FINAL_REWARD_COIN_SIZE
		)
		var target_glow_rect: Rect2 = Rect2(
			target_coin_rect.get_center() - PORTRAIT_FINAL_REWARD_GLOW_SIZE * 0.5,
			PORTRAIT_FINAL_REWARD_GLOW_SIZE
		)
		var glow := _stage_final_reward_glow(target_glow_rect)
		var transition_pack := _stage_texture(
			current_reward_coin_stage_rect,
			COIN_PACK_04_TEXTURE
		)
		transition_pack.name = "FinalRewardCoinPack"
		transition_pack.modulate.a = 0.0
		transition_pack.z_index = 20
		var caption_label := _stage_heading_label(
			_portrait_final_reward_caption_rect(target_coin_rect),
			"",
			PORTRAIT_FINAL_REWARD_CAPTION_FONT_SIZE,
			Color.WHITE,
			HORIZONTAL_ALIGNMENT_CENTER
		)
		caption_label.name = "FinalRewardCaption"
		caption_label.add_theme_font_override("font", UI_PRIMARY_FONT)
		caption_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		caption_label.clip_text = false
		_apply_portrait_reward_header_text_effect(caption_label, 2)
		_fit_single_line_label_to_width(
			caption_label,
			caption_label.text,
			PORTRAIT_FINAL_REWARD_CAPTION_SIZE.x,
			PORTRAIT_FINAL_REWARD_CAPTION_FONT_SIZE,
			18
		)
		caption_label.visible = false
		caption_label.modulate.a = 0.0
		caption_label.z_index = 21
		var amount_label := _stage_label(
			_portrait_final_reward_amount_rect(target_coin_rect),
			_single_player_reward_chain_count_text(reward_amount),
			PORTRAIT_FINAL_REWARD_COUNT_FONT_SIZE,
			Color.WHITE,
			HORIZONTAL_ALIGNMENT_CENTER
		)
		amount_label.name = "FinalRewardAmount"
		amount_label.add_theme_font_override("font", UI_PRIMARY_FONT)
		amount_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		amount_label.clip_text = false
		_apply_portrait_reward_header_text_effect(amount_label, 4)
		amount_label.add_theme_constant_override("shadow_offset_x", 3)
		amount_label.add_theme_constant_override("shadow_offset_y", 3)
		_fit_single_line_label_to_width(
			amount_label,
			amount_label.text,
			PORTRAIT_FINAL_REWARD_AMOUNT_SIZE.x,
			PORTRAIT_FINAL_REWARD_COUNT_FONT_SIZE,
			28
		)
		amount_label.modulate.a = 0.0
		amount_label.z_index = 21

		var final_reward_content: Control = _portrait_begin_bottom_attached_group()
		var double_button := _stage_main_button(
			PORTRAIT_FINAL_REWARD_DOUBLE_BUTTON_RECT,
			Callable(self, "_on_final_reward_double_pressed"),
			tr("REWARD_DOUBLE"),
			22,
			true,
			0.32,
			false,
			false,
			false,
			LONG_BUTTON_COLOR_BLUE
		)
		double_button.name = "FinalRewardDoubleButton"
		_configure_final_reward_double_button(double_button, reward_amount)
		double_button.modulate.a = 0.0
		double_button.z_index = 120
		_portrait_final_reward_double_button = double_button
		var collect_controls: Dictionary = _stage_final_reward_collect_text(
			PORTRAIT_FINAL_REWARD_COLLECT_RECT
		)
		content = final_reward_content
		final_reward_completion = Callable(
			self,
			"_start_single_player_final_reward_transition_deferred"
		).bind(
			chain_holder,
			hero_mask,
			hero_texture,
			current_reward_coin_visual,
			current_reward_count_visual,
			transition_pack,
			final_reward_background_overlay,
			title_panel,
			glow,
			caption_label,
			amount_label,
			target_coin_rect,
			double_button,
			collect_controls.get("holder") as Control,
			collect_controls.get("button") as Button
		)
	else:
		# Put the reward CTA in the same bottom-attached coordinate space as the
		# gameplay retry/continue CTA.
		var reward_content: Control = _portrait_begin_bottom_attached_group()
		continue_button = _stage_main_button(
			_portrait_in_place_result_button_rect(),
			Callable(self, "_continue_from_single_player_reward_chain"),
			(
				tr("REWARD_START_OVER")
				if is_failure_reward
				else _result_continue_button_text()
			),
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
	var failure_back_button: Control = null
	if is_failure_reward:
		# Stage Back only after every full-screen reward layer. Godot resolves GUI
		# picking by scene-tree order, so z_index alone cannot keep an earlier button
		# clickable above controls created later in the reward composition.
		failure_back_button = _stage_round_button(
			PORTRAIT_PAGE_BACK_BUTTON_RECT,
			Callable(self, "_leave_single_player_failure_reward_to_menu"),
			"×"
		)
		failure_back_button.z_index = 200
		failure_back_button.modulate.a = 0.0
		failure_back_button.set("disabled", true)
		failure_back_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		continue_button.set_meta(&"paired_failure_back_button", failure_back_button)
	var reward_hud_content: Control = _portrait_top_bar_content
	if resume_without_intro and !is_final_reward:
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
		if failure_reward_cross_visual != null and is_instance_valid(failure_reward_cross_visual):
			failure_reward_cross_visual.modulate.a = 1.0
			failure_reward_cross_visual.scale = Vector2.ONE
		if failed_final_reward_crown_visual != null and is_instance_valid(failed_final_reward_crown_visual):
			failed_final_reward_crown_visual.modulate.a = 0.0
		if failure_back_button != null and is_instance_valid(failure_back_button):
			failure_back_button.visible = true
			failure_back_button.modulate.a = 1.0
			failure_back_button.set("disabled", false)
			failure_back_button.mouse_filter = Control.MOUSE_FILTER_STOP
			_portrait_back_button_visible = true
		return
	if reward_hud_content != null and is_instance_valid(reward_hud_content):
		reward_hud_content.modulate.a = 0.0

	if (
		animate_current_claim
		and current_reward_coin_visual != null
		and current_reward_count_visual != null
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
		current_reward_count_visual,
		current_reward_check_icon,
		failure_reward_cross_visual,
		failed_final_reward_crown_visual,
		continue_button,
		final_reward_completion
	)

func _continue_from_single_player_reward_chain() -> void:
	if !last_result_is_win:
		_open_single_player_retry_theme_popup()
		return
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

func _leave_single_player_failure_reward_to_menu() -> void:
	_discard_round_for_navigation()
	show_menu()

func _continue_single_player_result() -> void:
	# Both outcomes use the reward-chain interstitial. A loss presents the failed
	# current reward before Start over opens a fresh theme selection.
	_show_single_player_reward_chain_screen()

func _use_open_hint() -> void:
	if GameSession.open_hint_used:
		if GameSession.can_use_open_letter_hint_ad():
			_show_portrait_rewarded_action(&"hint_open")
		return
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
	if GameSession.remove_wrong_hint_used:
		if GameSession.can_use_remove_wrong_hint_ad():
			_show_portrait_rewarded_action(&"hint_remove")
		return
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

func _hide_portrait_hints_for_round_end(animated: bool) -> void:
	for hint_button: Control in _portrait_game_hint_buttons:
		if hint_button == null or !is_instance_valid(hint_button):
			continue
		hint_button.set("disabled", true)
		hint_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if !animated:
			_finalize_portrait_hint_for_round_end(hint_button)
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
		fade_tween.finished.connect(
			Callable(self, "_finalize_portrait_hint_for_round_end").bind(hint_button),
			CONNECT_ONE_SHOT
		)

func _finalize_portrait_hint_for_round_end(hint_button: Control) -> void:
	if hint_button == null or !is_instance_valid(hint_button):
		return
	hint_button.modulate.a = 0.0
	hint_button.visible = false
	hint_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_button.set("disabled", true)

func _finalize_portrait_hints_for_round_end() -> void:
	for hint_button: Control in _portrait_game_hint_buttons:
		_finalize_portrait_hint_for_round_end(hint_button)

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
	# The marker sits outside the moving paper mask so its opacity never changes
	# with the peel. Remove the old instance before rebuilding the bouncing word;
	# otherwise two translucent marker layers briefly overlap and look like an
	# opacity animation halfway through the page turn.
	if (
		_portrait_inline_result_marker_holder != null
		and is_instance_valid(_portrait_inline_result_marker_holder)
	):
		_portrait_inline_result_marker_holder.visible = false
		_portrait_inline_result_marker_holder.queue_free()
	if (
		_portrait_inline_result_search_button != null
		and is_instance_valid(_portrait_inline_result_search_button)
	):
		_portrait_inline_result_search_button.visible = false
		_portrait_inline_result_search_button.queue_free()
	_portrait_inline_result_word_holder = null
	_portrait_inline_result_marker_holder = null
	_portrait_inline_result_search_button = null
	var bounced_controls: Dictionary = _stage_portrait_inline_result_word(true)
	_set_portrait_result_word_color(bounced_controls, word_color)
	_portrait_inline_result_search_button = bounced_controls.get("search_button") as Control

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

func _fit_single_line_label_to_width(label: Label, text: String, available_width: float, max_font_size: int, min_font_size: int) -> void:
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	var font: Font = label.get_theme_font("font")
	var lower_bound: int = mini(min_font_size, max_font_size)
	var upper_bound: int = maxi(max_font_size, min_font_size)
	var resolved_font_size: int = lower_bound
	# Font measurement is relatively expensive during a screen rebuild. Find the
	# largest fitting size with logarithmic probes instead of checking every size.
	while lower_bound <= upper_bound:
		var candidate_size: int = int((lower_bound + upper_bound) / 2)
		var text_width: float = font.get_string_size(
			text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			candidate_size
		).x
		if text_width <= available_width:
			resolved_font_size = candidate_size
			lower_bound = candidate_size + 1
		else:
			upper_bound = candidate_size - 1
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
	_stage_label(Rect2(26.0, 310.0, 428.0, 40.0), tr("RECORDS_TITLE").to_upper(), 27, PORTRAIT_BLUE, HORIZONTAL_ALIGNMENT_LEFT)
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
	var edit_label := _stage_label(Rect2(170.0, 214.0, 250.0, 36.0), tr("PROFILE_TAP_TO_EDIT"), 18, PORTRAIT_UI_PALETTE.TEXT_SECONDARY, HORIZONTAL_ALIGNMENT_LEFT)
	edit_label.clip_text = false
	_stage_label(Rect2(414.0, 188.0, 26.0, 42.0), "›", 30, Color.WHITE)
	_stage_button(card_rect, Callable(self, "_show_profile_edit_popup"), "")

func _portrait_profile_stat_row(y: float, mode_text: String, left_text: String, left_value: int, right_text: String, right_value: int) -> void:
	_stage_panel(Rect2(24.0, y, 432.0, 102.0), PORTRAIT_DARK_BLUE, 18.0, PORTRAIT_RULE, 1.5)
	_stage_label(Rect2(42.0, y + 8.0, 396.0, 30.0), mode_text.to_upper(), 21, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_panel(Rect2(42.0, y + 41.0, 396.0, 1.5), PORTRAIT_RULE)
	_stage_label(Rect2(42.0, y + 48.0, 180.0, 24.0), left_text, 16, PORTRAIT_UI_PALETTE.TEXT_SECONDARY, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_label(Rect2(42.0, y + 70.0, 180.0, 26.0), str(left_value), 22, PORTRAIT_ORANGE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_label(Rect2(244.0, y + 48.0, 194.0, 24.0), right_text, 16, PORTRAIT_UI_PALETTE.TEXT_SECONDARY, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_label(Rect2(244.0, y + 70.0, 194.0, 26.0), str(right_value), 22, PORTRAIT_ORANGE, HORIZONTAL_ALIGNMENT_LEFT)

func _show_profile_edit_popup() -> void:
	_remove_profile_edit_popup()
	_profile_edit_character_id = _selected_character_id()
	_profile_avatar_checks.clear()
	_profile_avatar_halos.clear()
	var previous_content := _portrait_popup_begin("ProfileEditPopup", "profile_edit_popup", 130, Callable(self, "_remove_profile_edit_popup"), 120.0, 680.0)
	var rect := Rect2(28.0, 120.0, 424.0, 560.0)
	_portrait_popup_shell(rect, tr("PROFILE_EDIT_TITLE"), Callable(self, "_remove_profile_edit_popup"), 25)

	_stage_label(Rect2(56.0, 226.0, 368.0, 34.0), tr("PROFILE_PLAYER_NAME"), 19, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_panel(Rect2(56.0, 266.0, 368.0, 58.0), Color.WHITE, 22.0, PORTRAIT_UI_PALETTE.NEUTRAL_BORDER, 2.0)
	_profile_name_edit = _stage_line_edit(Rect2(72.0, 270.0, 336.0, 50.0), _profile_default_name())
	_profile_name_edit.text = _profile_display_name()
	_profile_name_edit.max_length = 18
	_profile_name_edit.add_theme_font_size_override("font_size", 23)

	_stage_label(Rect2(56.0, 346.0, 368.0, 34.0), tr("PROFILE_AVATAR"), 19, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_profile_avatar_choice(1, Rect2(78.0, 404.0, 112.0, 112.0), Rect2(108.0, 431.0, 54.0, 58.0))
	_stage_profile_avatar_choice(2, Rect2(290.0, 404.0, 112.0, 112.0), Rect2(306.0, 437.0, 80.0, 70.0))

	_stage_portrait_popup_main_button(Rect2(90.0, _portrait_popup_bottom_button_y(rect.end.y, PORTRAIT_LONG_BUTTON_SIZE.y), PORTRAIT_LONG_BUTTON_SIZE.x, PORTRAIT_LONG_BUTTON_SIZE.y), Callable(self, "_save_profile_edits"), tr("PROFILE_SAVE"), 20)
	content = previous_content

func _stage_profile_avatar_choice(character_id: int, circle_rect: Rect2, avatar_rect: Rect2) -> void:
	var selected: bool = _profile_edit_character_id == character_id
	var halo_color: Color = PORTRAIT_UI_PALETTE.PROFILE_HALO if selected else PORTRAIT_UI_PALETTE.PROFILE_HALO_IDLE
	var halo := _stage_panel(Rect2(circle_rect.position - Vector2(10.0, 10.0), circle_rect.size + Vector2(20.0, 20.0)), halo_color, 66.0)
	_profile_avatar_halos[character_id] = halo
	_stage_panel(circle_rect, Color.WHITE, 56.0, PORTRAIT_ORANGE, 3.0)
	_stage_texture(avatar_rect, HERO_AVATAR_LAKI_TEXTURE if character_id == 1 else HERO_AVATAR_TIGRE_TEXTURE)
	var check := _stage_label(Rect2(circle_rect.position.x + 72.0, circle_rect.position.y + 70.0, 38.0, 38.0), "✓", 25, PORTRAIT_UI_PALETTE.SUCCESS_SOFT)
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
			halo.set("fill_color", PORTRAIT_UI_PALETTE.PROFILE_HALO if int(key) == _profile_edit_character_id else PORTRAIT_UI_PALETTE.PROFILE_HALO_IDLE)

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
	return tr("PROFILE_DEFAULT_PLAYER")


func _show_word_comment_popup() -> void:
	if !GameSession.can_view_comment_hint():
		return
	var hint: String = GameSession.get_word_hint().strip_edges()
	if hint == "":
		return
	_remove_word_comment_popup()
	var previous_content := _portrait_popup_begin("WordCommentPopup", "word_comment_popup", 100, Callable(self, "_remove_word_comment_popup"), 160.0, 544.0)
	var rect := Rect2(28.0, 160.0, 424.0, 384.0)
	# Lift the centered popup composition above the fullscreen dimmer. The theme
	# icon/glow keep negative local z-indices, so they stay behind the popup shell
	# while remaining above the dimmed screen.
	content.z_index = 10
	# Put the current theme icon behind the floating title and popup body. Since it
	# is staged before the shell, the shell naturally masks the icon's lower half.
	if GameSession.theme_id >= 0:
		var comment_theme_icon_texture: Texture2D = _theme_icon_texture(GameSession.theme_id)
		if comment_theme_icon_texture != null:
			# Decorative theme icon above the comment popup: a little smaller and
			# neutral/grayscale so it does not compete with the popup content.
			var comment_theme_icon_size := Vector2.ONE * (166.4 * 0.85)
			var popup_visual_top: float = rect.position.y + PORTRAIT_POPUP_TOP_TRIM
			var comment_theme_icon_rect := Rect2(
				Vector2(
					rect.get_center().x - comment_theme_icon_size.x * 0.5,
					popup_visual_top - comment_theme_icon_size.y * 0.5 - comment_theme_icon_size.y * 0.10
				),
				comment_theme_icon_size
			)
			var comment_theme_glow_size := comment_theme_icon_size * PORTRAIT_SINGLE_PLAYER_THEME_CARD_GLOW_SCALE
			var comment_theme_glow_rect := Rect2(
				comment_theme_icon_rect.get_center() - comment_theme_glow_size * 0.5,
				comment_theme_glow_size
			)
			var comment_theme_glow := _stage_final_reward_glow(comment_theme_glow_rect, Color.WHITE)
			if comment_theme_glow.get_parent() != null and comment_theme_glow.get_parent() is CanvasItem:
				# Keep the decorative theme art behind the popup shell. The glow helper
				# normally uses a high z-index for reward screens, so override it here.
				(comment_theme_glow.get_parent() as CanvasItem).z_index = -2
			comment_theme_glow.modulate = Color(1.0, 1.0, 1.0, PORTRAIT_SINGLE_PLAYER_THEME_CARD_GLOW_ALPHA * 0.50)
			var comment_theme_icon := _stage_texture(comment_theme_icon_rect, comment_theme_icon_texture)
			var comment_theme_icon_grayscale := ShaderMaterial.new()
			comment_theme_icon_grayscale.shader = PORTRAIT_HINT_USED_GRAYSCALE_SHADER
			comment_theme_icon.material = comment_theme_icon_grayscale
			comment_theme_icon.z_index = -1
	_portrait_popup_shell(rect, Database.tr_text(41, "Comment").to_upper(), Callable(self, "_remove_word_comment_popup"), 30)
	var theme_text: String = _current_word_source_label()
	var theme_label := _stage_label(Rect2(56.0, 238.0, 368.0, 28.0), theme_text, 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	theme_label.clip_text = false
	_fit_single_line_label_to_width(theme_label, theme_text, 368.0, 22, 17)
	var comment_panel_rect := Rect2(48.0, 286.0, 384.0, 238.0)
	var comment_panel := _stage_panel(
		comment_panel_rect,
		PORTRAIT_UI_PALETTE.THEME_CARD,
		22.0
	)
	comment_panel.z_index = 8
	var hint_label := _stage_label(
		Rect2(
			comment_panel_rect.position.x + 18.0,
			comment_panel_rect.position.y + 18.0,
			comment_panel_rect.size.x - 36.0,
			comment_panel_rect.size.y - 36.0
		),
		hint,
		25,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_LEFT
	)
	hint_label.add_theme_font_override("font", UI_HEADING_FONT)
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	hint_label.clip_text = false
	hint_label.z_index = 9
	content = previous_content
