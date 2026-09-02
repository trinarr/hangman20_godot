extends "res://scripts/main.gd"

const PORTRAIT_GAME_DESIGN: GDScript = preload("res://scripts/core/game_design_config.gd")
const PORTRAIT_UI_PALETTE: GDScript = preload("res://scripts/ui/ui_palette.gd")
const PORTRAIT_ADAPTIVE_GROUP_SCRIPT: GDScript = preload("res://scripts/ui/portrait_adaptive_group.gd")
const PORTRAIT_STAGE_LAYOUT: GDScript = preload("res://scripts/ui/portrait_stage_layout.gd")
const STAGE_WORD_INPUT_SCRIPT: GDScript = preload("res://scripts/ui/stage_word_input.gd")
const STAGE_TOAST_SCRIPT: GDScript = preload("res://scripts/ui/stage_toast.gd")
const RESULT_WORD_BOUNCE_EFFECT_SCRIPT: GDScript = preload("res://scripts/ui/result_word_bounce_effect.gd")
const ROUNDED_RECT_TEXTURE_MASK_SHADER: Shader = preload(
	"res://scripts/ui/rounded_rect_texture_mask.gdshader"
)
const COIN_PACK_04_TEXTURE: Texture2D = preload("res://flash_assets/coin_pack_04.png")
const REWARD_STATUS_CHECK_TEXTURE: Texture2D = preload("res://flash_assets/reward_status_check_wide.png")
const REWARD_STATUS_CROSS_TEXTURE: Texture2D = preload("res://flash_assets/reward_status_cross_wide.png")
const WATCH_AD_ICON_TEXTURE: Texture2D = preload("res://flash_assets/watch_ad_icon.png")
const MAIN_MENU_LOGO_TEXTURE: Texture2D = preload("res://flash_assets/main_menu_logo_hangman_20.png")
const FINAL_REWARD_ROTATING_GLOW_TEXTURE: Texture2D = preload(
	"res://flash_assets/final_reward_rotating_glow.png"
)
const MAIN_MENU_LOGO_SHINE_SHADER: Shader = preload(
	"res://shaders/main_menu_logo_shine.gdshader"
)

const PORTRAIT_STAGE_SIZE := Vector2(480.0, 800.0)
const PORTRAIT_HEADER_HEIGHT: float = 80.0
const PORTRAIT_FOOTER_Y: float = 688.0
const PORTRAIT_AD_BANNER_FALLBACK_HEIGHT: float = 50.0
const PORTRAIT_AD_BANNER_HEIGHT_DP: float = 50.0
const PORTRAIT_ANDROID_BASE_DPI: float = 160.0
const PORTRAIT_AD_TOAST_ANCHOR_Y: float = (
	PORTRAIT_STAGE_SIZE.y - PORTRAIT_AD_BANNER_FALLBACK_HEIGHT - 8.0
)
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
var PORTRAIT_BACK_ENTRANCE_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.back_entrance_seconds", 0.24
)
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
# Every top bar uses one shared resource-counter width. Home fits the same
# plates into the area before Settings; gameplay and rewards center their pair.
const PORTRAIT_RESOURCE_COUNTER_GAP: float = 7.0
const PORTRAIT_RESOURCE_COUNTER_PANEL_WIDTH_SCALE: float = 0.84
const PORTRAIT_RESOURCE_COUNTER_PANEL_HEIGHT_SCALE: float = 0.80
const PORTRAIT_RESOURCE_COUNTER_PANEL_TRAILING_INSET: float = 6.0
const PORTRAIT_RESOURCE_COUNTER_FONT_SCALE: float = 0.90
# Both resource plates are 10% wider than the original 109.94 px layout. Shift
# the complete pair left by the same added half-width so it stays centered.
const PORTRAIT_CURRENCY_COUNTER_RECT := Rect2(105.066, 21.68, 120.934, 38.64)
const PORTRAIT_GAME_CURRENCY_COUNTER_RECT := PORTRAIT_CURRENCY_COUNTER_RECT
const PORTRAIT_HOME_RESOURCE_COUNTER_WIDTH: float = PORTRAIT_CURRENCY_COUNTER_RECT.size.x
const PORTRAIT_CURRENCY_ICON_SIZE: float = 36.6597
const PORTRAIT_RESOURCE_COUNTER_ICON_X_SHIFT: float = PORTRAIT_CURRENCY_ICON_SIZE * 0.28
const PORTRAIT_HEART_ICON_ASPECT_RATIO: float = 1.0
const PORTRAIT_HEART_ICON_LEFT_INSET: float = 2.0
const PORTRAIT_CURRENCY_COUNTER_PRESSED_SCALE: float = 0.94
var PORTRAIT_CURRENCY_COUNTER_PRESS_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.counter_press_seconds", 0.055
)
var PORTRAIT_CURRENCY_COUNTER_RELEASE_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.counter_release_seconds", 0.085
)
const PORTRAIT_CURRENCY_ADD_BADGE_SIZE: float = 20.0
const PORTRAIT_CURRENCY_ADD_BADGE_GREEN := PORTRAIT_UI_PALETTE.SUCCESS
const PORTRAIT_FREE_HINT_BADGE_GREEN := PORTRAIT_UI_PALETTE.SUCCESS_SOFT
const PORTRAIT_CURRENCY_ADD_BADGE_BORDER := PORTRAIT_UI_PALETTE.SUCCESS_BORDER
const PORTRAIT_PAPER_GRID_SCALE: float = 1.35
const PORTRAIT_MODAL_POPUP_GROUP: StringName = &"portrait_modal_popup"
const PORTRAIT_LEGAL_POPUP_GROUP: StringName = &"legal_consent_popup"
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
var PORTRAIT_ROUND_END_KEY_FADE_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.round_end.key_fade_seconds", 0.22
)
var PORTRAIT_ROUND_END_KEY_WAVE_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.round_end.key_wave_seconds", 0.48
)
var PORTRAIT_ROUND_END_KEY_SCALE: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.round_end.key_scale", 1.28
)
var PORTRAIT_ROUND_END_PAPER_FLIP_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.round_end.paper_flip_seconds", 0.92
)
const PORTRAIT_ROUND_END_PAPER_BACKSIDE_MAX_WIDTH: float = 190.0
var PORTRAIT_ROUND_END_ATTEMPTS_FADE_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.round_end.attempts_fade_seconds", 0.20
)
var PORTRAIT_ROUND_END_HINTS_FADE_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.round_end.hints_fade_seconds", 0.18
)
const PORTRAIT_IN_PLACE_RESULT_KEYBOARD_ALPHA: float = 0.70
var PORTRAIT_ATTEMPTS_WARNING_THRESHOLD: int = PORTRAIT_GAME_DESIGN.get_int(
	"timings.animations.attempts_warning.threshold", 2
)
var PORTRAIT_ATTEMPTS_WARNING_BOUNCE_SCALE: Vector2 = Vector2.ONE * PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.attempts_warning.bounce_scale", 1.18
)
var PORTRAIT_ATTEMPTS_WARNING_BOUNCE_GROW_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.attempts_warning.grow_seconds", 0.48
)
var PORTRAIT_ATTEMPTS_WARNING_BOUNCE_SETTLE_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.attempts_warning.settle_seconds", 0.55
)
var PORTRAIT_ATTEMPTS_WARNING_BOUNCE_PAUSE_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.attempts_warning.pause_seconds", 0.12
)
var PORTRAIT_ATTEMPTS_COUNTER_ROLL_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.attempts_warning.counter_roll_seconds", 0.20
)
var PORTRAIT_GAME_ENTRANCE_START_DELAY: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.game_entrance.start_delay_seconds", 0.05
)
var PORTRAIT_GAME_ENTRANCE_SPEED_MULTIPLIER: float = PORTRAIT_GAME_DESIGN.get_float_range(
	"timings.animations.game_entrance.speed_multiplier", 1.30, 0.01, 100.0
)
var PORTRAIT_GAME_HERO_ENTRANCE_FADE_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.game_entrance.hero_fade_seconds", 0.26
)
var PORTRAIT_INLINE_RESULT_CONTINUE_GROW_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.game_entrance.continue_grow_seconds", 0.12
)
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
var PORTRAIT_SINGLE_REWARD_CURRENT_NODE_SCALE: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.reward_chain.current_node_scale", 1.20
)
var PORTRAIT_SINGLE_REWARD_SIDE_NODE_SCALE: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.reward_chain.side_node_scale", 0.90
)
var PORTRAIT_SINGLE_REWARD_CHAIN_ICON_SCALE: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.reward_chain.chain_icon_scale", 0.612
)
const PORTRAIT_SINGLE_REWARD_CHAIN_COUNT_FONT_SIZE: int = 22
const PORTRAIT_SINGLE_REWARD_CHAIN_COUNT_MIN_FONT_SIZE: int = 15
var PORTRAIT_SINGLE_REWARD_STATUS_ICON_SCALE: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.reward_chain.status_icon_scale", 0.574
)
const PORTRAIT_SINGLE_REWARD_CROWN_WIDTH_RATIO: float = 0.46
const PORTRAIT_SINGLE_REWARD_CROWN_HEIGHT_RATIO: float = 0.28
const PORTRAIT_SINGLE_REWARD_CROWN_FILL := PORTRAIT_UI_PALETTE.REWARD_GOLD
const PORTRAIT_SINGLE_REWARD_CROWN_BAND := PORTRAIT_UI_PALETTE.REWARD_GOLD_DARK
const PORTRAIT_SINGLE_REWARD_CROWN_OUTLINE := PORTRAIT_UI_PALETTE.REWARD_GOLD_OUTLINE
const PORTRAIT_SINGLE_REWARD_CROWN_FLY_OFFSET := Vector2(34.0, -52.0)
var PORTRAIT_SINGLE_REWARD_CROWN_FLY_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.reward_chain.crown_fly_seconds", 0.38
)
var PORTRAIT_SINGLE_REWARD_CHECK_COIN_DIM_ALPHA: float = PORTRAIT_GAME_DESIGN.get_float_range(
	"timings.animations.reward_chain.coin_dim_alpha", 0.45, 0.0, 1.0
)
var PORTRAIT_SINGLE_REWARD_CHECK_BOUNCE_START_SCALE: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.reward_chain.check_start_scale", 0.42
)
var PORTRAIT_SINGLE_REWARD_CHECK_BOUNCE_PEAK_SCALE: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.reward_chain.check_peak_scale", 1.16
)
var PORTRAIT_SINGLE_REWARD_CHECK_BOUNCE_GROW_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.reward_chain.check_grow_seconds", 0.15
)
var PORTRAIT_SINGLE_REWARD_CHECK_BOUNCE_SETTLE_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.reward_chain.check_settle_seconds", 0.20
)
var PORTRAIT_SINGLE_REWARD_FLY_COIN_COUNT: int = PORTRAIT_GAME_DESIGN.get_int_range(
	"timings.animations.reward_chain.flying_icon_count", 9, 1, 100
)
var PORTRAIT_SINGLE_REWARD_FLY_COIN_SIZE: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.reward_chain.flying_icon_size", 66.0
)
var PORTRAIT_SINGLE_REWARD_FLY_STAR_SIZE: float = (
	PORTRAIT_SINGLE_REWARD_FLY_COIN_SIZE
	* PORTRAIT_GAME_DESIGN.get_float(
		"timings.animations.reward_chain.flying_star_size_multiplier", 1.10
	)
)
var PORTRAIT_SINGLE_REWARD_FLY_SPREAD_X: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.reward_chain.spread_x", 30.0
)
var PORTRAIT_SINGLE_REWARD_FLY_SPREAD_Y: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.reward_chain.spread_y", 18.0
)
var PORTRAIT_SINGLE_REWARD_FLY_START_DELAY: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.reward_chain.start_delay_seconds", 0.02
)
var PORTRAIT_SINGLE_REWARD_FLY_STAGGER: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.reward_chain.stagger_seconds", 0.09
)
var PORTRAIT_SINGLE_REWARD_FLY_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.reward_chain.flight_seconds", 0.52
)
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
const PORTRAIT_SINGLE_REWARD_TITLE_HEIGHT: float = 52.0
const PORTRAIT_SINGLE_REWARD_SUBTITLE_TOP: float = 10.0
const PORTRAIT_SINGLE_REWARD_SUBTITLE_HEIGHT: float = 32.0
var PORTRAIT_SINGLE_REWARD_TITLE_START_SCALE: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.reward_chain.title_start_scale", 0.52
)
var PORTRAIT_SINGLE_REWARD_TITLE_PEAK_SCALE: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.reward_chain.title_peak_scale", 1.14
)
var PORTRAIT_SINGLE_REWARD_TITLE_GROW_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.reward_chain.title_grow_seconds", 0.16
)
var PORTRAIT_SINGLE_REWARD_TITLE_SETTLE_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.reward_chain.title_settle_seconds", 0.20
)
var PORTRAIT_SINGLE_REWARD_TITLE_MOVE_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.reward_chain.title_move_seconds", 0.28
)
var PORTRAIT_SINGLE_REWARD_BODY_FADE_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.reward_chain.body_fade_seconds", 0.16
)
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
var PORTRAIT_FINAL_REWARD_CHAIN_HOLD_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.final_reward.chain_hold_seconds", 0.252
)
var PORTRAIT_FINAL_REWARD_ICON_CROSSFADE_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.final_reward.icon_crossfade_seconds", 0.162
)
var PORTRAIT_FINAL_REWARD_REPLACE_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.final_reward.replace_seconds", 0.414
)
var PORTRAIT_FINAL_REWARD_BACKGROUND_FADE_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.final_reward.background_fade_seconds", 0.558
)
var PORTRAIT_FINAL_REWARD_PACK_BOUNCE_SCALE: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.final_reward.pack_bounce_scale", 1.18
)
var PORTRAIT_FINAL_REWARD_PACK_BOUNCE_GROW_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.final_reward.pack_bounce_grow_seconds", 0.162
)
var PORTRAIT_FINAL_REWARD_PACK_BOUNCE_SETTLE_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.final_reward.pack_bounce_settle_seconds", 0.27
)
var PORTRAIT_FINAL_REWARD_GLOW_ROTATION_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.final_reward.glow_rotation_seconds", 14.0
)
var PORTRAIT_FINAL_REWARD_ACTION_REVEAL_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.final_reward.action_reveal_seconds", 0.162
)
var PORTRAIT_FINAL_REWARD_DIRECT_THEME_THROUGH_LEVEL: int = PORTRAIT_GAME_DESIGN.get_int_range(
	"progression.direct_theme_selection_after_reward_through_level", 2, 0, 1_000_000
)
var PORTRAIT_FINAL_REWARD_COLLECT_DELAY: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.final_reward.collect_delay_seconds", 0.9
)
const PORTRAIT_FINAL_REWARD_GLOW_ALPHA: float = 0.7
var PORTRAIT_COIN_REFILL_REWARDED_AMOUNT: int = PORTRAIT_GAME_DESIGN.get_int(
	"economy.rewards.coin_refill_ad_coins", 50
)
const PORTRAIT_COIN_REFILL_GLOW_SIZE := PORTRAIT_FINAL_REWARD_GLOW_SIZE * 0.80
const PORTRAIT_COIN_REFILL_ICON_SIZE := PORTRAIT_FINAL_REWARD_COIN_SIZE * 0.80
const PORTRAIT_COIN_REFILL_GLOW_ALPHA: float = PORTRAIT_FINAL_REWARD_GLOW_ALPHA * 0.80
var PORTRAIT_COIN_REFILL_GLOW_ROTATION_DURATION: float = (
	PORTRAIT_FINAL_REWARD_GLOW_ROTATION_DURATION
	/ maxf(
		PORTRAIT_GAME_DESIGN.get_float(
			"timings.animations.final_reward.coin_refill_glow_rotation_speed_multiplier",
			0.70
		),
		0.01
	)
)
const PORTRAIT_FINAL_REWARD_DOUBLE_BUTTON_BONUS_COIN_SIZE := Vector2(28.0, 28.0)
const PORTRAIT_FINAL_REWARD_DOUBLE_BUTTON_PLAY_GAP: float = -8.0
var PORTRAIT_FINAL_REWARD_HOME_COUNT_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.final_reward.home_count_seconds", 1.36
)
const PORTRAIT_FINAL_REWARD_THEME_PATTERN_ICON_SIZE: float = 133.12
const PORTRAIT_FINAL_REWARD_THEME_PATTERN_SPACING: float = 218.7
const PORTRAIT_FINAL_REWARD_THEME_PATTERN_ALPHA: float = 0.12
# A half-cell right plus one cell up is a seamless staggered-lattice vector.
# This duration preserves the current screen-space speed for diagonal motion.
var PORTRAIT_FINAL_REWARD_THEME_PATTERN_MOVE_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.final_reward.pattern_move_seconds", 22.17
)
var PORTRAIT_CURRENCY_ICON_REWARD_BOUNCE_PEAK_SCALE: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.currency_reward.icon_peak_scale", 1.05
)
var PORTRAIT_CURRENCY_COUNTER_REWARD_BOUNCE_PEAK_SCALE: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.currency_reward.counter_peak_scale", 1.10
)
var PORTRAIT_CURRENCY_COUNTER_REWARD_GROW_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.currency_reward.counter_grow_seconds", 0.14
)
var PORTRAIT_CURRENCY_COUNTER_REWARD_SETTLE_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.currency_reward.counter_settle_seconds", 0.16
)
var PORTRAIT_CURRENCY_ICON_REWARD_BOUNCE_GROW_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.currency_reward.icon_bounce_grow_seconds", 0.035
)
var PORTRAIT_CURRENCY_ICON_REWARD_BOUNCE_SETTLE_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.currency_reward.icon_bounce_settle_seconds", 0.05
)
var PORTRAIT_HINT_COUNTER_ROLL_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.hint.counter_roll_seconds", 0.18
)
var PORTRAIT_GAME_HINT_ENTRANCE_START_SCALE: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.hint.entrance_start_scale", 0.72
)
var PORTRAIT_GAME_HINT_ENTRANCE_PEAK_SCALE: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.hint.entrance_peak_scale", 1.12
)
var PORTRAIT_GAME_HINT_ENTRANCE_GROW_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.hint.entrance_grow_seconds", 0.13
)
var PORTRAIT_GAME_HINT_ENTRANCE_SETTLE_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.hint.entrance_settle_seconds", 0.16
)
const PORTRAIT_RESULT_SEARCH_BUTTON_SIZE: float = 44.0
const PORTRAIT_RESULT_SEARCH_REST_VISUAL_SCALE := Vector2.ONE
const PORTRAIT_RESULT_SEARCH_START_VISUAL_SCALE := PORTRAIT_RESULT_SEARCH_REST_VISUAL_SCALE * 0.72
const PORTRAIT_RESULT_WORD_SEARCH_GAP: float = 10.0
const PORTRAIT_RESULT_SEARCH_SAFE_MARGIN: float = 14.0
const PORTRAIT_RESULT_WORD_Y_OFFSET: float = 4.0
const PORTRAIT_RESULT_LETTER_SPACING: int = 2
const PORTRAIT_RESULT_SEARCH_ICON_SIZE := Vector2(24.0, 31.0)
var PORTRAIT_RESULT_LETTER_BOUNCE_GROW_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.result_letters.grow_seconds", 0.068
)
var PORTRAIT_RESULT_LETTER_BOUNCE_SETTLE_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.result_letters.settle_seconds", 0.072
)
var PORTRAIT_RESULT_LETTER_BOUNCE_GAP: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.result_letters.gap_seconds", 0.0094
)
var PORTRAIT_RESULT_LETTER_BOUNCE_REFERENCE_LENGTH: float = PORTRAIT_GAME_DESIGN.get_float_range(
	"timings.animations.result_letters.reference_length", 5.0, 0.01, 100.0
)
var PORTRAIT_RESULT_LETTER_BOUNCE_MAX_SPEED_MULTIPLIER: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.result_letters.maximum_speed_multiplier", 2.2
)
var PORTRAIT_RESULT_LETTER_BOUNCE_NEIGHBOR_STRENGTH: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.result_letters.neighbor_strength", 0.42
)
var PORTRAIT_RESULT_LETTER_BOUNCE_NEIGHBOR_RADIUS: int = PORTRAIT_GAME_DESIGN.get_int(
	"timings.animations.result_letters.neighbor_radius", 2
)
var PORTRAIT_RESULT_SEARCH_APPEAR_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.result_letters.search_appear_seconds", 0.18
)
var PORTRAIT_ATTEMPT_REWARD_BOUNCE_SCALE: Vector2 = Vector2.ONE * PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.attempt_reward.bounce_scale", 1.32
)
var PORTRAIT_ATTEMPT_REWARD_BOUNCE_GROW_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.attempt_reward.grow_seconds", 0.18
)
var PORTRAIT_ATTEMPT_REWARD_BOUNCE_SETTLE_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.attempt_reward.settle_seconds", 0.24
)
const PORTRAIT_HERO_BASE_SCALE_MULTIPLIER: float = 0.86
const PORTRAIT_GAME_HERO_SCALE_MULTIPLIER: float = PORTRAIT_HERO_BASE_SCALE_MULTIPLIER * 1.32
const PORTRAIT_GAME_HERO_Y_LIFT: float = 42.0
const PORTRAIT_GAME_HERO_LEFT_CENTER_X: float = PORTRAIT_STAGE_SIZE.x * 0.25
const PORTRAIT_BACK_ARROW_ICON: Texture2D = preload("res://flash_assets/portrait_back_arrow_icon.png")
const PORTRAIT_HINT_REVEAL_LETTER_ICON: Texture2D = preload("res://flash_assets/hint_reveal_letter_doodle.png")
const PORTRAIT_HINT_REMOVE_WRONG_ICON: Texture2D = preload("res://flash_assets/hint_remove_wrong_doodle.png")
const PORTRAIT_HINT_COMMENT_UNLOCK_ICON: Texture2D = preload("res://flash_assets/hint_comment_unlock_doodle.png")
const PORTRAIT_QUIZ_HINT_FIFTY_FIFTY_ICON: Texture2D = preload("res://flash_assets/hint_quiz_fifty_fifty_doodle.png")
const PORTRAIT_QUIZ_HINT_REPLACE_QUESTION_ICON: Texture2D = preload("res://flash_assets/hint_quiz_replace_question_doodle.png")
const PORTRAIT_HINT_USED_GRAYSCALE_SHADER: Shader = preload("res://shaders/hint_icon_grayscale.gdshader")
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
const PORTRAIT_POPUP_TITLE_SCALE: float = 1.098
const PORTRAIT_POPUP_BUTTON_UNIFORM_SCALE: float = 1.15
const PORTRAIT_POPUP_BUTTON_LENGTH_SCALE: float = 0.85
const PORTRAIT_POPUP_LONG_BUTTON_MIN_SOURCE_WIDTH: float = 280.0
const PORTRAIT_POPUP_LONG_BUTTON_WIDTH: float = 313.6
const PORTRAIT_POPUP_BOTTOM_BUTTON_GAP: float = 18.0
const PORTRAIT_REFILL_STATUS_RECT := Rect2(48.0, 236.0, 384.0, 151.0)
const PORTRAIT_REFILL_STATUS_CORNER_RADIUS: float = 22.0
const PORTRAIT_REFILL_STATUS_GLOW_DIAMETER: float = 144.0
const PORTRAIT_REFILL_HEART_ICON_SIZE := Vector2(95.013, 86.0625)
const PORTRAIT_SINGLE_PLAYER_REFRESH_BUTTON_SCALE: float = 1.10
const PORTRAIT_SINGLE_PLAYER_THEME_CARD_ICON_SIZE: float = 75.14
const PORTRAIT_SINGLE_PLAYER_THEME_CARD_GLOW_SCALE: float = 1.8
const PORTRAIT_SINGLE_PLAYER_THEME_CARD_GLOW_ALPHA: float = 0.46
const PORTRAIT_REFILL_STATUS_GLOW_ALPHA: float = PORTRAIT_SINGLE_PLAYER_THEME_CARD_GLOW_ALPHA * 0.8
const PORTRAIT_SINGLE_PLAYER_SLOT_ICON_GAP: float = 8.0
var PORTRAIT_SINGLE_PLAYER_SLOT_BASE_SPINS: int = PORTRAIT_GAME_DESIGN.get_int(
	"timings.animations.theme_reels.base_spins", 7
)
var PORTRAIT_SINGLE_PLAYER_SLOT_SPINS_PER_REEL: int = PORTRAIT_GAME_DESIGN.get_int(
	"timings.animations.theme_reels.spins_per_reel", 2
)
var PORTRAIT_SINGLE_PLAYER_SLOT_BASE_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.theme_reels.base_seconds", 0.34
)
var PORTRAIT_SINGLE_PLAYER_SLOT_DURATION_STEP: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.theme_reels.step_seconds", 0.06
)
var PORTRAIT_SINGLE_PLAYER_SLOT_ACCELERATION_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.theme_reels.acceleration_seconds", 0.055
)
var PORTRAIT_SINGLE_PLAYER_SLOT_LANDING_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.theme_reels.landing_seconds", 0.006
)
const PORTRAIT_SINGLE_PLAYER_SLOT_SPIN_ICON_ALPHA: float = 0.90
var PORTRAIT_SINGLE_PLAYER_SLOT_REVEAL_STAGGER: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.theme_reels.reveal_stagger_seconds", 0.0
)
var PORTRAIT_SINGLE_PLAYER_SLOT_REVEAL_PEAK_SCALE: Vector2 = Vector2.ONE * PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.theme_reels.reveal_peak_scale", 1.38
)
var PORTRAIT_SINGLE_PLAYER_SLOT_REVEAL_GROW_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.theme_reels.reveal_grow_seconds", 0.08
)
var PORTRAIT_SINGLE_PLAYER_SLOT_REVEAL_SETTLE_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.theme_reels.reveal_settle_seconds", 0.14
)
var PORTRAIT_SINGLE_PLAYER_SLOT_LABEL_FADE_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.theme_reels.label_fade_seconds", 0.14
)
const PORTRAIT_GAME_HINT_BUTTON_SIZE := Vector2.ONE * (PORTRAIT_ROUND_BUTTON_SIZE * 1.144)
const PORTRAIT_GAME_RETRY_BUTTON_SIZE := Vector2(PORTRAIT_LONG_BUTTON_SIZE.x, PORTRAIT_LONG_BUTTON_SIZE.y)
const PORTRAIT_GAME_HINT_KEYBOARD_GAP: float = 40.0
const PORTRAIT_GAME_HINT_Y: float = 650.0
const PORTRAIT_GAME_HINT_OPEN_BUTTON_RECT := Rect2(108.176, PORTRAIT_GAME_HINT_Y - 3.0, PORTRAIT_GAME_HINT_BUTTON_SIZE.x, PORTRAIT_GAME_HINT_BUTTON_SIZE.y)
const PORTRAIT_GAME_HINT_REMOVE_BUTTON_RECT := Rect2(203.392, PORTRAIT_GAME_HINT_Y - 3.0, PORTRAIT_GAME_HINT_BUTTON_SIZE.x, PORTRAIT_GAME_HINT_BUTTON_SIZE.y)
const PORTRAIT_GAME_HINT_COMMENT_BUTTON_RECT := Rect2(298.608, PORTRAIT_GAME_HINT_Y - 3.0, PORTRAIT_GAME_HINT_BUTTON_SIZE.x, PORTRAIT_GAME_HINT_BUTTON_SIZE.y)
const PORTRAIT_GAME_HINT_ART_SIZE := Vector2(50.0, 50.0)
const PORTRAIT_GAME_HINT_COUNTER_SIZE: float = 28.0
var PORTRAIT_WORD_LETTER_BOUNCE_START_SCALE: Vector2 = Vector2.ONE * PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.word_letters.start_scale", 0.58
)
var PORTRAIT_WORD_LETTER_BOUNCE_PEAK_SCALE: Vector2 = Vector2.ONE * PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.word_letters.peak_scale", 1.24
)
var PORTRAIT_WORD_LETTER_BOUNCE_GROW_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.word_letters.grow_seconds", 0.18
)
var PORTRAIT_WORD_LETTER_BOUNCE_SETTLE_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.word_letters.settle_seconds", 0.24
)
const PORTRAIT_CUSTOM_WORD_INPUT_RECT := Rect2(22.0, 0.0, 436.0, 72.0)
const PORTRAIT_CUSTOM_WORD_BUTTON_RISE: float = 64.0
const PORTRAIT_CUSTOM_WORD_CHECK_RECT := Rect2(94.0, 518.0, PORTRAIT_LONG_BUTTON_SIZE.x, PORTRAIT_LONG_BUTTON_SIZE.y)
const PORTRAIT_CUSTOM_WORD_RANDOM_RECT := Rect2(94.0, 592.0, PORTRAIT_LONG_BUTTON_SIZE.x, PORTRAIT_LONG_BUTTON_SIZE.y)

# Quiz mode reuses the standard portrait paper, top resource bar, category cards
# and the game's blue button language. The complete answer/hint block is bottom
# attached so it remains clear of adaptive banners on tall devices.
const PORTRAIT_QUIZ_MENU_BUTTON_RECT := Rect2(90.0, 476.0, PORTRAIT_LONG_BUTTON_SIZE.x, PORTRAIT_LONG_BUTTON_SIZE.y)
const PORTRAIT_QUIZ_THEME_TITLE_RECT := Rect2(34.0, 98.0, 412.0, 44.0)
const PORTRAIT_QUIZ_QUESTION_PANEL_RECT := Rect2(22.0, 120.0, 436.0, 260.0)
const PORTRAIT_QUIZ_QUESTION_RECT := Rect2(40.0, 138.0, 400.0, 224.0)
const PORTRAIT_QUIZ_ANSWER_BUTTON_SIZE := Vector2(412.0, 68.0)
const PORTRAIT_QUIZ_ANSWER_BUTTON_X: float = 34.0
const PORTRAIT_QUIZ_ANSWER_STEP_Y: float = 88.0
const PORTRAIT_QUIZ_ANSWER_HINT_GAP: float = 40.0
const PORTRAIT_QUIZ_HINT_GAP: float = 22.0
const PORTRAIT_QUIZ_ANSWER_CORRECT_COLOR := PORTRAIT_UI_PALETTE.SUCCESS_SOFT
const PORTRAIT_QUIZ_ANSWER_WRONG_COLOR := PORTRAIT_UI_PALETTE.ERROR_SOFT
const PORTRAIT_QUIZ_ENTRANCE_PANEL_OFFSET: float = 32.0
const PORTRAIT_QUIZ_SPEED_NONE: int = 0
const PORTRAIT_QUIZ_SPEED_FAST: int = 1
const PORTRAIT_QUIZ_SPEED_LIGHTNING: int = 2
var PORTRAIT_QUIZ_ENTRANCE_BACKGROUND_FADE_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.quiz.entrance_background_fade_seconds", 0.34
)
var PORTRAIT_QUIZ_ENTRANCE_CONTENT_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.quiz.entrance_content_seconds", 0.34
)
var PORTRAIT_QUIZ_ENTRANCE_PANEL_DURATION: float = (
	PORTRAIT_QUIZ_ENTRANCE_CONTENT_DURATION
	* PORTRAIT_GAME_DESIGN.get_float(
		"timings.animations.quiz.entrance_panel_ratio", 0.80
	)
)
var PORTRAIT_QUIZ_ENTRANCE_ANSWER_STAGGER: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.quiz.entrance_answer_stagger_seconds", 0.045
)
var PORTRAIT_QUIZ_ENTRANCE_QUESTION_FADE_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.quiz.entrance_question_fade_seconds", 0.112
)
var PORTRAIT_QUIZ_LIGHTNING_ANSWER_WINDOW_MSEC: int = PORTRAIT_GAME_DESIGN.get_int(
	"timings.quiz_lightning_answer_window_ms", 3500
)
var PORTRAIT_QUIZ_FAST_ANSWER_WINDOW_MSEC: int = PORTRAIT_GAME_DESIGN.get_int(
	"timings.quiz_fast_answer_window_ms", 5000
)
var PORTRAIT_QUIZ_FAST_REWARD_STARS: int = PORTRAIT_GAME_DESIGN.get_int(
	"economy.rewards.quick_quiz_answer_stars", 1
)
var PORTRAIT_QUIZ_LIGHTNING_REWARD_STARS: int = PORTRAIT_GAME_DESIGN.get_int(
	"economy.rewards.lightning_quiz_answer_stars", 2
)
var PORTRAIT_QUIZ_FEEDBACK_START_SCALE: Vector2 = Vector2.ONE * PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.quiz.feedback_start_scale", 0.64
)
var PORTRAIT_QUIZ_FEEDBACK_PEAK_SCALE: Vector2 = Vector2.ONE * PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.quiz.feedback_peak_scale", 1.14
)
var PORTRAIT_QUIZ_FEEDBACK_GROW_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.quiz.feedback_grow_seconds", 0.16
)
var PORTRAIT_QUIZ_FEEDBACK_SETTLE_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.quiz.feedback_settle_seconds", 0.22
)
var PORTRAIT_QUIZ_FAST_REWARD_FADE_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.quiz.fast_reward_fade_seconds", 0.18
)
var PORTRAIT_QUIZ_FEEDBACK_HOLD_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.quiz.feedback_hold_seconds", 1.0
)
var PORTRAIT_QUIZ_FEEDBACK_EXIT_PEAK_SCALE: Vector2 = Vector2.ONE * PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.quiz.feedback_exit_peak_scale", 1.08
)
var PORTRAIT_QUIZ_FEEDBACK_EXIT_GROW_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.quiz.feedback_exit_grow_seconds", 0.10
)
var PORTRAIT_QUIZ_FEEDBACK_EXIT_HIDE_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.quiz.feedback_exit_hide_seconds", 0.16
)
var PORTRAIT_QUIZ_QUESTION_RESTORE_FADE_DURATION: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.quiz.question_restore_fade_seconds", 0.20
)
const PORTRAIT_QUIZ_FAST_REWARD_ICON_SIZE: float = 42.0

var PORTRAIT_COIN_REFILL_POLL_SECONDS: float = PORTRAIT_GAME_DESIGN.get_float_range(
	"timings.coin_refill_poll_seconds", 1.0, 0.05, 60.0
)
var PORTRAIT_HEART_POPUP_POLL_SECONDS: float = PORTRAIT_GAME_DESIGN.get_float_range(
	"timings.heart_popup_poll_seconds", 1.0, 0.05, 60.0
)
var PORTRAIT_MENU_LOGO_SHINE_DELAY_SECONDS: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.menu_logo_shine_delay_seconds", 0.28
)
var PORTRAIT_MENU_LOGO_SHINE_DURATION_SECONDS: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.menu_logo_shine_duration_seconds", 0.72
)
var PORTRAIT_QUIZ_WRONG_ANSWER_SHAKE_STEP_SECONDS: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.quiz_wrong_answer_shake_step_seconds", 0.065
)
var PORTRAIT_REWARDED_AD_CLOSE_GUARD_SECONDS: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.rewarded_ad_close_guard_seconds", 0.30
)
var PORTRAIT_ATTEMPTS_POPUP_COUNTER_PEAK_SCALE: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.attempts_popup.counter_peak_scale", 1.12
)
var PORTRAIT_ATTEMPTS_POPUP_COUNTER_GROW_SECONDS: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.attempts_popup.counter_grow_seconds", 0.09
)
var PORTRAIT_ATTEMPTS_POPUP_COUNTER_HIDE_SECONDS: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.attempts_popup.counter_hide_seconds", 0.15
)
var PORTRAIT_ATTEMPTS_POPUP_ICON_SPIN_SECONDS: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.attempts_popup.icon_spin_seconds", 0.46
)
var PORTRAIT_ATTEMPTS_POPUP_DESCRIPTION_HIDE_SECONDS: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.attempts_popup.description_hide_seconds", 0.16
)
var PORTRAIT_ATTEMPTS_POPUP_DESCRIPTION_HIDE_DELAY_SECONDS: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.attempts_popup.description_hide_delay_seconds", 0.30
)
var PORTRAIT_ATTEMPTS_POPUP_COUNTER_REVEAL_PEAK_SCALE: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.attempts_popup.counter_reveal_peak_scale", 1.14
)
var PORTRAIT_ATTEMPTS_POPUP_COUNTER_REVEAL_GROW_SECONDS: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.attempts_popup.counter_reveal_grow_seconds", 0.14
)
var PORTRAIT_ATTEMPTS_POPUP_DESCRIPTION_REVEAL_SECONDS: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.attempts_popup.description_reveal_seconds", 0.20
)
var PORTRAIT_ATTEMPTS_POPUP_COUNTER_SETTLE_DELAY_SECONDS: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.attempts_popup.counter_settle_delay_seconds", 0.14
)
var PORTRAIT_ATTEMPTS_POPUP_COUNTER_SETTLE_SECONDS: float = PORTRAIT_GAME_DESIGN.get_float(
	"timings.animations.attempts_popup.counter_settle_seconds", 0.13
)
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
var _portrait_game_keyboard_metrics_snapshot: Dictionary = {}
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
var _portrait_star_counter_visual: Control = null
var _portrait_star_icon_visual: Control = null
var _portrait_heart_icon_visual: Control = null
var _portrait_round_end_bounce_started: bool = false
var _portrait_inline_result_search_button: Control = null
var _portrait_inline_result_word_holder: Control = null
var _portrait_inline_result_marker_holder: Control = null
var _portrait_inline_result_continue_button: Control = null
var _portrait_in_place_result_active: bool = false
var _portrait_in_place_result_is_win: bool = false
var _portrait_attempt_star_collection_active: bool = false
var _portrait_attempt_star_collection_started: bool = false
var _portrait_game_entrance_pending: bool = false
var _portrait_game_entrance_active: bool = false
var _portrait_top_bar_content: Control = null
var _portrait_active_currency_counter_rect: Rect2 = PORTRAIT_CURRENCY_COUNTER_RECT
var _portrait_coin_store_active: bool = false
var _portrait_back_button_visible: bool = false
var _portrait_previous_screen_had_back: bool = false
var _portrait_single_reward_resume_without_intro: bool = false
var _portrait_popup_resume_without_intro: bool = false
var _portrait_final_reward_claim_in_progress: bool = false
var _portrait_final_reward_waiting_for_ad: bool = false
var _portrait_final_reward_earned_ad_reward: bool = false
var _portrait_final_reward_ad_close_pending: bool = false
var _portrait_final_reward_double_button: Control = null
var _portrait_final_reward_continue_button: Control = null
var _portrait_single_reward_continue_button: Control = null
var _portrait_rewarded_action: StringName = &""
var _portrait_rewarded_action_earned: bool = false
var _portrait_rewarded_action_level_index: int = -1
var _portrait_ad_toast: Control = null
var _portrait_interstitial_showing: bool = false
var _portrait_interstitial_pending_action: Callable = Callable()
var _portrait_pending_theme_reroll_presentation: Dictionary = {}
var _portrait_pending_home_reward_amount: int = 0
var _portrait_pending_home_reward_animation_running: bool = false
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
var _startup_guided_resume_checked: bool = false

var _quiz_mode_active: bool = false
var _quiz_screen_active: bool = false
var _quiz_selected_theme_index: int = -1
var _quiz_current_question: Dictionary = {}
var _quiz_answer_buttons: Array[Control] = []
var _quiz_hint_buttons: Array[Control] = []
var _quiz_continue_button: Control = null
var _quiz_exit_button: Control = null
var _quiz_answer_locked: bool = false
var _quiz_selected_answer_index: int = -1
var _quiz_fifty_fifty_used: bool = false
var _quiz_fifty_fifty_hidden_indices: Array = []
var _quiz_replace_question_used: bool = false
var _quiz_question_replacing: bool = false
var _quiz_question_label: Label = null
var _quiz_single_player_embedded: bool = false
var _quiz_single_player_target_difficulty: float = 0.5
var _quiz_entrance_generation: int = 0
var _quiz_question_ready_at_msec: int = 0

func _portrait_ads_service() -> Node:
	return get_node_or_null("/root/YandexAdsService")

func _portrait_ads_enabled() -> bool:
	return GameState.are_ads_enabled()

func _portrait_ad_not_ready_message() -> String:
	var translated: String = tr(&"TOAST_AD_NOT_READY")
	if translated != "TOAST_AD_NOT_READY":
		return translated
	# The checked-in optimized Translation resources are regenerated by Godot
	# from the CSV. Keep a runtime fallback so this patch also works immediately
	# when applied without opening the project in the editor first.
	return (
		"Реклама еще не готова"
		if Database.interface_language == "ru"
		else "The ad isn't ready yet"
	)

func _show_portrait_ad_not_ready_toast() -> void:
	if _portrait_ad_toast == null or !is_instance_valid(_portrait_ad_toast):
		var toast_layer := CanvasLayer.new()
		toast_layer.name = "AdStatusToastCanvas"
		toast_layer.layer = 1000
		add_child(toast_layer)

		var toast_root := Control.new()
		toast_root.name = "AdStatusToastRoot"
		toast_root.set_anchors_preset(Control.PRESET_FULL_RECT)
		toast_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if ui != null and is_instance_valid(ui):
			toast_root.theme = ui.theme
		toast_layer.add_child(toast_root)

		var toast_anchor: Control = FLASH_STAGE_CONTROL_SCRIPT.new() as Control
		toast_anchor.name = "AdStatusToastAnchor"
		toast_anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
		toast_root.add_child(toast_anchor)
		toast_anchor.set(
			"stage_rect",
			Rect2(0.0, PORTRAIT_AD_TOAST_ANCHOR_Y, PORTRAIT_STAGE_SIZE.x, 0.0)
		)

		_portrait_ad_toast = STAGE_TOAST_SCRIPT.new() as Control
		_portrait_ad_toast.name = "AdStatusToast"
		toast_anchor.add_child(_portrait_ad_toast)
		_portrait_ad_toast.call("set_available_width", PORTRAIT_STAGE_SIZE.x)
	_portrait_ad_toast.call("show_message", _portrait_ad_not_ready_message(), false)

func _connect_portrait_interstitial_signals(ads_service: Node) -> void:
	var shown_callback := Callable(self, "_on_portrait_interstitial_shown")
	if ads_service.has_signal(&"interstitial_shown") and !ads_service.is_connected(
		&"interstitial_shown",
		shown_callback
	):
		ads_service.connect(&"interstitial_shown", shown_callback)
	var closed_callback := Callable(self, "_on_portrait_interstitial_closed")
	if ads_service.has_signal(&"interstitial_closed") and !ads_service.is_connected(
		&"interstitial_closed",
		closed_callback
	):
		ads_service.connect(&"interstitial_closed", closed_callback)
	var failed_callback := Callable(self, "_on_portrait_interstitial_failed_to_show")
	if ads_service.has_signal(&"interstitial_failed_to_show") and !ads_service.is_connected(
		&"interstitial_failed_to_show",
		failed_callback
	):
		ads_service.connect(&"interstitial_failed_to_show", failed_callback)

func _run_action_after_interstitial_if_ready(action: Callable) -> void:
	if !action.is_valid() or _portrait_interstitial_showing:
		return
	if !GameState.is_interstitial_ready():
		action.call()
		return
	var ads_service: Node = _portrait_ads_service()
	if ads_service == null or !ads_service.has_method("show_interstitial"):
		action.call()
		return
	_connect_portrait_interstitial_signals(ads_service)
	_portrait_interstitial_showing = true
	_portrait_interstitial_pending_action = action
	GameState.set_fullscreen_ad_active(true)
	if !bool(ads_service.call("show_interstitial")):
		GameState.set_fullscreen_ad_active(false)
		_portrait_interstitial_showing = false
		_portrait_interstitial_pending_action = Callable()
		action.call()

func _on_portrait_interstitial_shown() -> void:
	if !_portrait_interstitial_showing:
		return
	# A failed show does not consume the cooldown. Reset only after the native SDK
	# confirms that a full-screen ad has actually appeared.
	GameState.reset_interstitial_timer(true)

func _finish_portrait_interstitial() -> void:
	if !_portrait_interstitial_showing:
		return
	var pending_action: Callable = _portrait_interstitial_pending_action
	_portrait_interstitial_showing = false
	_portrait_interstitial_pending_action = Callable()
	GameState.set_fullscreen_ad_active(false)
	if pending_action.is_valid():
		pending_action.call()

func _on_portrait_interstitial_closed() -> void:
	_finish_portrait_interstitial()

func _on_portrait_interstitial_failed_to_show(_message: String) -> void:
	_finish_portrait_interstitial()

func _portrait_ad_banner_height_stage() -> float:
	# Resolve the fixed 50 dp banner reserve before the asynchronous ad request
	# finishes. Reading getBannerHeight() here made the value jump from the fallback
	# to the native pixel height halfway through a round, so persistent keyboard and
	# newly rebuilt hint buttons could end up using different layouts.
	if !OS.has_feature("android"):
		return PORTRAIT_AD_BANNER_FALLBACK_HEIGHT
	var window_size: Vector2i = DisplayServer.window_get_size()
	var screen_dpi: int = DisplayServer.screen_get_dpi()
	if window_size.x <= 0 or screen_dpi <= 0:
		return PORTRAIT_AD_BANNER_FALLBACK_HEIGHT
	var banner_height_pixels: float = (
		PORTRAIT_AD_BANNER_HEIGHT_DP
		* float(screen_dpi)
		/ PORTRAIT_ANDROID_BASE_DPI
	)
	return maxf(
		PORTRAIT_AD_BANNER_FALLBACK_HEIGHT,
		banner_height_pixels * PORTRAIT_STAGE_SIZE.x / float(window_size.x)
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
	_quiz_screen_active = false
	_quiz_question_ready_at_msec = 0
	_quiz_answer_buttons.clear()
	_quiz_exit_button = null
	_portrait_previous_screen_had_back = _portrait_back_button_visible
	_portrait_back_button_visible = false
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
	_portrait_game_keyboard_metrics_snapshot.clear()
	_portrait_game_keyboard_buttons.clear()
	_portrait_game_hint_buttons.clear()
	_portrait_game_hint_signature = ""
	_portrait_game_back_button = null
	_portrait_final_reward_double_button = null
	_portrait_final_reward_continue_button = null
	_portrait_single_reward_continue_button = null
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
	_portrait_star_counter_visual = null
	_portrait_star_icon_visual = null
	_portrait_inline_result_search_button = null
	_portrait_inline_result_word_holder = null
	_portrait_inline_result_marker_holder = null
	_portrait_inline_result_continue_button = null
	_portrait_game_runtime_ready = false
	_portrait_hint_counter_animation_active = false
	_portrait_hint_counter_refresh_requested = false
	_portrait_in_place_result_active = false
	_portrait_in_place_result_is_win = false
	_portrait_attempt_star_collection_active = false
	_portrait_attempt_star_collection_started = false
	super._clear()

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

func _portrait_resource_counter_panel_rect(
	counter_rect: Rect2
) -> Rect2:
	var panel_size := Vector2(
		counter_rect.size.x * PORTRAIT_RESOURCE_COUNTER_PANEL_WIDTH_SCALE,
		counter_rect.size.y * PORTRAIT_RESOURCE_COUNTER_PANEL_HEIGHT_SCALE
	)
	var counter_scale: float = counter_rect.size.y / 48.0
	var panel_right: float = counter_rect.end.x - 2.0 * counter_scale
	return Rect2(
		Vector2(
			panel_right - panel_size.x,
			counter_rect.get_center().y - panel_size.y * 0.5
		),
		panel_size
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
	# Keep resource counters pressable in the shop as well. Their action is
	# resolved centrally below so pressing them while the shop is already open
	# only plays the normal press feedback instead of rebuilding the same screen.
	var counter_is_interactive: bool = interactive and _portrait_ads_enabled()
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
	var icon_rect := Rect2(
		counter_rect.position + Vector2(
			2.0 * counter_scale + PORTRAIT_RESOURCE_COUNTER_ICON_X_SHIFT,
			(counter_rect.size.y - PORTRAIT_CURRENCY_ICON_SIZE) * 0.5
		),
		Vector2(PORTRAIT_CURRENCY_ICON_SIZE, PORTRAIT_CURRENCY_ICON_SIZE)
	)
	var panel_rect: Rect2 = _portrait_resource_counter_panel_rect(counter_rect)
	var panel := _stage_panel(
		panel_rect,
		panel_color,
		panel_rect.size.y * 0.5,
		Color.TRANSPARENT,
		0.0
	)
	panel.z_index = 20
	var coin_icon := _stage_texture(icon_rect, SOFT_CURRENCY_COIN_TEXTURE)
	coin_icon.z_index = 21
	_portrait_currency_coin_icon_visual = coin_icon
	if counter_is_interactive and !_portrait_coin_store_active:
		_stage_resource_add_badge(icon_rect, counter_scale)
	var balance_left: float = counter_rect.position.x + 43.0 * counter_scale
	var balance_right: float = (
		panel_rect.end.x - PORTRAIT_RESOURCE_COUNTER_PANEL_TRAILING_INSET * counter_scale
	)
	var balance_rect := Rect2(
		Vector2(balance_left, panel_rect.position.y),
		Vector2(maxf(1.0, balance_right - balance_left), panel_rect.size.y)
	)
	var balance_text: String = _soft_currency_balance_text(GameState.get_soft_currency())
	var balance_font_size: int = maxi(1, int(round(
		24.0 * counter_scale * PORTRAIT_RESOURCE_COUNTER_FONT_SCALE
	)))
	var balance_min_font_size: int = maxi(1, int(round(
		14.0 * counter_scale * PORTRAIT_RESOURCE_COUNTER_FONT_SCALE
	)))
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
	track_as_active_counter: bool = true,
	direct_action: Callable = Callable()
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
	var counter_is_interactive: bool = interactive and _portrait_ads_enabled()
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
	var icon_rect := Rect2(
		counter_rect.position + Vector2(
			2.0 * counter_scale + PORTRAIT_RESOURCE_COUNTER_ICON_X_SHIFT,
			(counter_rect.size.y - PORTRAIT_CURRENCY_ICON_SIZE) * 0.5
		),
		Vector2(PORTRAIT_CURRENCY_ICON_SIZE, PORTRAIT_CURRENCY_ICON_SIZE)
	)
	var panel_rect: Rect2 = _portrait_resource_counter_panel_rect(counter_rect)
	var panel := _stage_panel(
		panel_rect,
		panel_color,
		panel_rect.size.y * 0.5,
		Color.TRANSPARENT,
		0.0
	)
	panel.z_index = 20
	var coin_icon := _stage_texture(icon_rect, SOFT_CURRENCY_COIN_TEXTURE)
	coin_icon.z_index = 21
	_portrait_currency_coin_icon_visual = coin_icon
	if counter_is_interactive and (!_portrait_coin_store_active or direct_action.is_valid()):
		_stage_resource_add_badge(icon_rect, counter_scale)
	var balance_left: float = counter_rect.position.x + 43.0 * counter_scale
	var balance_right: float = (
		panel_rect.end.x - PORTRAIT_RESOURCE_COUNTER_PANEL_TRAILING_INSET * counter_scale
	)
	var balance_rect := Rect2(
		Vector2(balance_left, panel_rect.position.y),
		Vector2(maxf(1.0, balance_right - balance_left), panel_rect.size.y)
	)
	var balance_text: String = _soft_currency_balance_text(GameState.get_soft_currency())
	var balance_font_size: int = maxi(1, int(round(
		24.0 * counter_scale * PORTRAIT_RESOURCE_COUNTER_FONT_SCALE
	)))
	var balance_min_font_size: int = maxi(1, int(round(
		14.0 * counter_scale * PORTRAIT_RESOURCE_COUNTER_FONT_SCALE
	)))
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
		_stage_resource_counter_button(
			counter_rect,
			counter_visual,
			return_action,
			direct_action
		)
	content = screen_content

func _stage_star_counter(
	counter_rect: Rect2,
	challenge_colors: bool = false
) -> void:
	var screen_content: Control = content
	if _portrait_top_bar_content != null and is_instance_valid(_portrait_top_bar_content):
		content = _portrait_top_bar_content
	var counter_scale: float = counter_rect.size.y / 48.0
	var panel_color: Color = PORTRAIT_CHALLENGE_HUD_PANEL if challenge_colors else PORTRAIT_DARK_BLUE
	var counter_parent_content: Control = content
	var counter_visual := Control.new()
	counter_visual.name = "StarCounterVisual"
	counter_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	counter_parent_content.add_child(counter_visual)
	counter_visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	counter_visual.pivot_offset = _portrait_stage_point_to_viewport(
		counter_rect.get_center(),
		counter_visual
	)
	_portrait_star_counter_visual = counter_visual
	content = counter_visual
	var icon_rect := Rect2(
		counter_rect.position + Vector2(
			2.0 * counter_scale + PORTRAIT_RESOURCE_COUNTER_ICON_X_SHIFT,
			(counter_rect.size.y - PORTRAIT_CURRENCY_ICON_SIZE) * 0.5
		),
		Vector2(PORTRAIT_CURRENCY_ICON_SIZE, PORTRAIT_CURRENCY_ICON_SIZE)
	)
	var panel_rect: Rect2 = _portrait_resource_counter_panel_rect(counter_rect)
	var panel := _stage_panel(
		panel_rect,
		panel_color,
		panel_rect.size.y * 0.5,
		Color.TRANSPARENT,
		0.0
	)
	panel.z_index = 20
	var star_icon := _stage_texture(icon_rect, STAR_CURRENCY_TEXTURE)
	star_icon.z_index = 21
	_portrait_star_icon_visual = star_icon
	var balance_left: float = counter_rect.position.x + 43.0 * counter_scale
	var balance_right: float = (
		panel_rect.end.x - PORTRAIT_RESOURCE_COUNTER_PANEL_TRAILING_INSET * counter_scale
	)
	var balance_rect := Rect2(
		Vector2(balance_left, panel_rect.position.y),
		Vector2(maxf(1.0, balance_right - balance_left), panel_rect.size.y)
	)
	var balance_text: String = _soft_currency_balance_text(GameState.get_stars())
	var balance_font_size: int = maxi(1, int(round(
		24.0 * counter_scale * PORTRAIT_RESOURCE_COUNTER_FONT_SCALE
	)))
	var balance_min_font_size: int = maxi(1, int(round(
		14.0 * counter_scale * PORTRAIT_RESOURCE_COUNTER_FONT_SCALE
	)))
	var balance_label := _stage_label(
		balance_rect,
		balance_text,
		balance_font_size,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	balance_label.add_theme_font_override("font", UI_PRIMARY_FONT)
	balance_label.add_to_group(&"stars_balance_label")
	stars_balance_label = balance_label
	balance_label.z_index = 21
	_fit_single_line_label_to_width(
		balance_label,
		balance_text,
		balance_rect.size.x,
		balance_font_size,
		balance_min_font_size
	)
	content = counter_parent_content
	content = screen_content

func _stage_coin_and_star_counters(
	return_action: Callable,
	rect: Rect2 = Rect2(),
	challenge_colors: bool = false,
	interactive: bool = true
) -> void:
	var source_rect: Rect2 = (
		rect
		if rect.size.x > 0.0 and rect.size.y > 0.0
		else PORTRAIT_CURRENCY_COUNTER_RECT
	)
	var total_width: float = source_rect.size.x * 2.0 + PORTRAIT_RESOURCE_COUNTER_GAP
	var coin_rect := Rect2(
		(PORTRAIT_STAGE_SIZE.x - total_width) * 0.5,
		source_rect.position.y,
		source_rect.size.x,
		source_rect.size.y
	)
	_stage_centered_coin_only_counter(
		return_action,
		coin_rect,
		challenge_colors,
		interactive,
		false
	)
	var star_rect := Rect2(
		coin_rect.position + Vector2(coin_rect.size.x + PORTRAIT_RESOURCE_COUNTER_GAP, 0.0),
		coin_rect.size
	)
	_stage_star_counter(star_rect, challenge_colors)

func _stage_home_resource_counters(return_action: Callable) -> void:
	var counter_size := Vector2(
		PORTRAIT_HOME_RESOURCE_COUNTER_WIDTH,
		PORTRAIT_CURRENCY_COUNTER_RECT.size.y
	)
	var total_width: float = (
		counter_size.x * 3.0 + PORTRAIT_RESOURCE_COUNTER_GAP * 2.0
	)
	var available_width: float = PORTRAIT_MENU_SETTINGS_BUTTON_RECT.position.x
	var coin_rect := Rect2(
		(available_width - total_width) * 0.5,
		PORTRAIT_CURRENCY_COUNTER_RECT.position.y,
		counter_size.x,
		counter_size.y
	)
	_stage_centered_coin_only_counter(
		return_action,
		coin_rect,
		false,
		true,
		false
	)
	var heart_rect := Rect2(
		coin_rect.position + Vector2(coin_rect.size.x + PORTRAIT_RESOURCE_COUNTER_GAP, 0.0),
		coin_rect.size
	)
	_stage_heart_counter(return_action, heart_rect)
	var star_rect := Rect2(
		heart_rect.position + Vector2(heart_rect.size.x + PORTRAIT_RESOURCE_COUNTER_GAP, 0.0),
		heart_rect.size
	)
	_stage_star_counter(star_rect)
	_stage_menu_settings_button()

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
	# Match the coin icon height while preserving the source heart's wider
	# artwork proportions inside its new square 128x128 texture canvas. Keep the
	# complete texture aligned with the coin and star icons.
	var heart_icon_size := Vector2(
		PORTRAIT_CURRENCY_ICON_SIZE * PORTRAIT_HEART_ICON_ASPECT_RATIO,
		PORTRAIT_CURRENCY_ICON_SIZE
	)
	var icon_rect := Rect2(
		Vector2(
			counter_rect.position.x
			+ PORTRAIT_HEART_ICON_LEFT_INSET * counter_scale
			+ PORTRAIT_RESOURCE_COUNTER_ICON_X_SHIFT,
			counter_rect.position.y + (counter_rect.size.y - heart_icon_size.y) * 0.5
		),
		heart_icon_size
	)
	var panel_rect: Rect2 = _portrait_resource_counter_panel_rect(counter_rect)
	var panel := _stage_panel(
		panel_rect,
		panel_color,
		panel_rect.size.y * 0.5,
		Color.TRANSPARENT,
		0.0
	)
	panel.z_index = 20
	var heart_icon: Control = _stage_texture(icon_rect, LIFE_HEART_ICON_TEXTURE)
	heart_icon.z_index = 21
	_portrait_heart_icon_visual = heart_icon

	var count_label := _stage_label(
		icon_rect,
		str(resolved_hearts),
		maxi(1, int(round(
			22.0 * counter_scale * PORTRAIT_RESOURCE_COUNTER_FONT_SCALE
		))),
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

	var status_left: float = counter_rect.position.x + 52.0 * counter_scale
	var status_right: float = (
		panel_rect.end.x - PORTRAIT_RESOURCE_COUNTER_PANEL_TRAILING_INSET * counter_scale
	)
	var status_rect := Rect2(
		Vector2(status_left, panel_rect.position.y),
		Vector2(maxf(1.0, status_right - status_left), panel_rect.size.y)
	)
	var recovery_seconds: int = GameState.get_heart_recovery_seconds()
	var status_text: String = _heart_status_text(resolved_hearts, recovery_seconds)
	var status_font_size: int = maxi(1, int(round(
		25.0 * counter_scale * PORTRAIT_RESOURCE_COUNTER_FONT_SCALE
	)))
	var status_min_font_size: int = maxi(1, int(round(
		16.0 * counter_scale * PORTRAIT_RESOURCE_COUNTER_FONT_SCALE
	)))
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

func _set_portrait_resource_counter_collection_active(
	reward_currency: String,
	active: bool
) -> void:
	var icon_visual: Control = (
		_portrait_star_icon_visual
		if reward_currency == GameState.STAGE_REWARD_STARS
		else _portrait_currency_coin_icon_visual
	)
	var counter_visual: Control = (
		_portrait_star_counter_visual
		if reward_currency == GameState.STAGE_REWARD_STARS
		else _portrait_currency_counter_visual
	)
	if (
		icon_visual == null
		or !is_instance_valid(icon_visual)
		or !icon_visual.is_inside_tree()
	):
		return
	var resource_icon: Control = icon_visual
	resource_icon.pivot_offset = Vector2.ZERO
	var rest_scale: Vector2 = resource_icon.get_meta(&"reward_icon_rest_scale", Vector2.ZERO)
	var rest_position: Vector2 = resource_icon.position
	if rest_scale == Vector2.ZERO:
		rest_scale = resource_icon.scale
		if rest_scale == Vector2.ZERO:
			rest_scale = Vector2.ONE
		resource_icon.set_meta(&"reward_icon_rest_scale", rest_scale)
	if resource_icon.has_meta(&"reward_icon_rest_position"):
		rest_position = resource_icon.get_meta(&"reward_icon_rest_position", resource_icon.position)
	else:
		resource_icon.set_meta(&"reward_icon_rest_position", rest_position)
	var counter_can_scale: bool = (
		counter_visual != null
		and is_instance_valid(counter_visual)
		and counter_visual.is_inside_tree()
	)
	var counter_rest_scale := Vector2.ONE
	if counter_can_scale:
		counter_rest_scale = counter_visual.get_meta(
			&"reward_counter_rest_scale",
			Vector2.ZERO
		)
		if counter_rest_scale == Vector2.ZERO:
			counter_rest_scale = counter_visual.scale
			if counter_rest_scale == Vector2.ZERO:
				counter_rest_scale = Vector2.ONE
			counter_visual.set_meta(&"reward_counter_rest_scale", counter_rest_scale)
		var previous_counter_tween: Tween = counter_visual.get_meta(
			&"reward_counter_hold_tween",
			null
		) as Tween
		if previous_counter_tween != null and previous_counter_tween.is_valid():
			previous_counter_tween.kill()
		counter_visual.set_meta(&"reward_counter_collection_active", active)
	var previous_icon_hold_tween: Tween = resource_icon.get_meta(
		&"reward_counter_icon_hold_tween",
		null
	) as Tween
	if previous_icon_hold_tween != null and previous_icon_hold_tween.is_valid():
		previous_icon_hold_tween.kill()
	if !active:
		var previous_impact_tween: Tween = resource_icon.get_meta(
			&"reward_icon_impact_tween",
			null
		) as Tween
		if previous_impact_tween != null and previous_impact_tween.is_valid():
			previous_impact_tween.kill()

	# The icon is a child of the complete counter visual. While the plate is held
	# enlarged, counteract that parent transform so the icon keeps its normal
	# visible size between impacts. Impact bounces are handled separately below.
	var counter_peak: float = maxf(
		PORTRAIT_CURRENCY_COUNTER_REWARD_BOUNCE_PEAK_SCALE,
		0.001
	)
	var target_icon_scale: Vector2 = rest_scale / counter_peak if active else rest_scale
	var target_icon_position: Vector2 = (
		rest_position - resource_icon.size * (target_icon_scale - rest_scale) * 0.5
	)
	var duration: float = (
		PORTRAIT_CURRENCY_COUNTER_REWARD_GROW_DURATION
		if active
		else PORTRAIT_CURRENCY_COUNTER_REWARD_SETTLE_DURATION
	)
	var collection_tween := resource_icon.create_tween()
	collection_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var icon_scale_tweener := collection_tween.tween_property(
		resource_icon,
		"scale",
		target_icon_scale,
		duration
	)
	icon_scale_tweener.set_trans(Tween.TRANS_SINE)
	icon_scale_tweener.set_ease(Tween.EASE_IN_OUT)
	var icon_position_tweener := collection_tween.parallel().tween_property(
		resource_icon,
		"position",
		target_icon_position,
		duration
	)
	icon_position_tweener.set_trans(Tween.TRANS_SINE)
	icon_position_tweener.set_ease(Tween.EASE_IN_OUT)
	resource_icon.set_meta(&"reward_counter_icon_hold_tween", collection_tween)
	if counter_can_scale:
		var target_counter_scale: Vector2 = (
			counter_rest_scale * PORTRAIT_CURRENCY_COUNTER_REWARD_BOUNCE_PEAK_SCALE
			if active
			else counter_rest_scale
		)
		var counter_scale_tweener := collection_tween.parallel().tween_property(
			counter_visual,
			"scale",
			target_counter_scale,
			duration
		)
		counter_scale_tweener.set_trans(Tween.TRANS_SINE)
		counter_scale_tweener.set_ease(Tween.EASE_IN_OUT)
		counter_visual.set_meta(&"reward_counter_hold_tween", collection_tween)

func _bounce_portrait_resource_counter_icon(reward_currency: String) -> void:
	var resource_icon: Control = (
		_portrait_star_icon_visual
		if reward_currency == GameState.STAGE_REWARD_STARS
		else _portrait_currency_coin_icon_visual
	)
	var counter_visual: Control = (
		_portrait_star_counter_visual
		if reward_currency == GameState.STAGE_REWARD_STARS
		else _portrait_currency_counter_visual
	)
	if (
		resource_icon == null
		or !is_instance_valid(resource_icon)
		or !resource_icon.is_inside_tree()
	):
		return
	var previous_tween: Tween = resource_icon.get_meta(&"reward_icon_impact_tween", null) as Tween
	if previous_tween != null and previous_tween.is_valid():
		previous_tween.kill()
	var rest_scale: Vector2 = resource_icon.get_meta(&"reward_icon_rest_scale", Vector2.ONE)
	var rest_position: Vector2 = resource_icon.get_meta(
		&"reward_icon_rest_position",
		resource_icon.position
	)
	var counter_is_held: bool = (
		counter_visual != null
		and is_instance_valid(counter_visual)
		and bool(counter_visual.get_meta(&"reward_counter_collection_active", false))
	)
	var parent_scale: float = (
		maxf(PORTRAIT_CURRENCY_COUNTER_REWARD_BOUNCE_PEAK_SCALE, 0.001)
		if counter_is_held
		else 1.0
	)
	var local_rest_scale: Vector2 = rest_scale / parent_scale
	var local_peak_scale: Vector2 = (
		rest_scale * PORTRAIT_CURRENCY_ICON_REWARD_BOUNCE_PEAK_SCALE / parent_scale
	)
	var local_rest_position: Vector2 = (
		rest_position - resource_icon.size * (local_rest_scale - rest_scale) * 0.5
	)
	var local_peak_position: Vector2 = (
		rest_position - resource_icon.size * (local_peak_scale - rest_scale) * 0.5
	)
	resource_icon.scale = local_rest_scale
	resource_icon.position = local_rest_position
	var impact_tween := resource_icon.create_tween()
	impact_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var grow_scale := impact_tween.tween_property(
		resource_icon,
		"scale",
		local_peak_scale,
		PORTRAIT_CURRENCY_ICON_REWARD_BOUNCE_GROW_DURATION
	)
	grow_scale.set_trans(Tween.TRANS_BACK)
	grow_scale.set_ease(Tween.EASE_OUT)
	var grow_position := impact_tween.parallel().tween_property(
		resource_icon,
		"position",
		local_peak_position,
		PORTRAIT_CURRENCY_ICON_REWARD_BOUNCE_GROW_DURATION
	)
	grow_position.set_trans(Tween.TRANS_BACK)
	grow_position.set_ease(Tween.EASE_OUT)
	var settle_scale := impact_tween.tween_property(
		resource_icon,
		"scale",
		local_rest_scale,
		PORTRAIT_CURRENCY_ICON_REWARD_BOUNCE_SETTLE_DURATION
	)
	settle_scale.set_trans(Tween.TRANS_BOUNCE)
	settle_scale.set_ease(Tween.EASE_OUT)
	var settle_position := impact_tween.parallel().tween_property(
		resource_icon,
		"position",
		local_rest_position,
		PORTRAIT_CURRENCY_ICON_REWARD_BOUNCE_SETTLE_DURATION
	)
	settle_position.set_trans(Tween.TRANS_BOUNCE)
	settle_position.set_ease(Tween.EASE_OUT)
	resource_icon.set_meta(&"reward_icon_impact_tween", impact_tween)

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

func show_coin_store() -> void:
	if !_portrait_ads_enabled():
		return
	_show_coin_refill_popup()

func _open_coin_store(return_action: Callable = Callable()) -> void:
	if !_portrait_ads_enabled():
		return
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

func _close_coin_store() -> void:
	_portrait_coin_store_active = false
	super._close_coin_store()

func _coin_refill_ad_cooldown_text(seconds: int) -> String:
	var resolved_seconds: int = maxi(seconds, 0)
	var hours: int = int(resolved_seconds / 3600)
	var minutes: int = int((resolved_seconds % 3600) / 60)
	var seconds_part: int = resolved_seconds % 60
	return "%d:%02d:%02d" % [hours, minutes, seconds_part]

func _coin_refill_ad_icon_texture() -> Texture2D:
	var rewarded_ad_icon_texture := AtlasTexture.new()
	rewarded_ad_icon_texture.atlas = WATCH_AD_ICON_TEXTURE
	rewarded_ad_icon_texture.region = Rect2(83.0, 49.0, 219.0, 159.0)
	return rewarded_ad_icon_texture

func _stage_coin_refill_ad_counter(button: Control) -> void:
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
	var component := _create_portrait_button_badge(button, {
		"coin_rect": badge_rect,
		"ad_rect": badge_rect,
		"free_rect": badge_rect,
		"count": GameState.get_coin_refill_ad_views_remaining(),
		"state": PORTRAIT_BUTTON_BADGE_STATE_FREE,
	})
	button.set_meta(&"coin_refill_ad_badge_component", component)

func _coin_refill_ad_button_timer(button: Control) -> Timer:
	if button == null or !is_instance_valid(button):
		return null
	var existing := button.get_node_or_null("CoinRefillCooldownTimer") as Timer
	if existing != null:
		return existing
	var timer := Timer.new()
	timer.name = "CoinRefillCooldownTimer"
	timer.wait_time = PORTRAIT_COIN_REFILL_POLL_SECONDS
	timer.one_shot = false
	timer.timeout.connect(Callable(self, "_on_coin_refill_ad_cooldown_tick").bind(button))
	button.add_child(timer)
	return timer

func _stop_coin_refill_ad_button_timer(button: Control) -> void:
	if button == null or !is_instance_valid(button):
		return
	var timer := button.get_node_or_null("CoinRefillCooldownTimer") as Timer
	if timer == null:
		return
	timer.stop()
	timer.queue_free()

func _refresh_coin_refill_ad_button(button: Control, interaction_enabled: bool = true) -> void:
	if button == null or !is_instance_valid(button):
		return
	var remaining: int = GameState.get_coin_refill_ad_views_remaining()
	var cooldown_seconds: int = GameState.get_coin_refill_ad_cooldown_seconds()
	var cooldown_active: bool = remaining <= 0 and cooldown_seconds > 0
	var component_variant: Variant = button.get_meta(&"coin_refill_ad_badge_component", {})
	var component: Dictionary = component_variant if component_variant is Dictionary else {}
	if cooldown_active:
		button.set("button_disabled", true)
		button.set("button_text", _coin_refill_ad_cooldown_text(cooldown_seconds))
		button.set("icon_texture", null)
		button.set("icon_shadow_enabled", false)
		_set_portrait_button_badge_visible(component, false)
		var cooldown_timer := _coin_refill_ad_button_timer(button)
		if cooldown_timer != null and cooldown_timer.is_stopped():
			cooldown_timer.start()
		return

	_stop_coin_refill_ad_button_timer(button)
	button.set("button_text", tr("COMMON_FREE"))
	button.set("icon_texture", button.get_meta(&"coin_refill_ad_icon_texture", null))
	button.set("icon_shadow_enabled", true)
	button.set("button_disabled", !interaction_enabled)
	_set_portrait_button_badge_state(
		component,
		PORTRAIT_BUTTON_BADGE_STATE_FREE,
		{"count": remaining}
	)

func _on_coin_refill_ad_cooldown_tick(button: Control) -> void:
	if button == null or !is_instance_valid(button):
		return
	_refresh_coin_refill_ad_button(
		button,
		_portrait_rewarded_action != &"coin_refill"
	)

func _show_coin_refill_popup() -> void:
	_remove_coin_refill_popup()
	_portrait_coin_store_active = true
	var close_action := Callable(self, "_close_coin_store")
	var previous_content := _portrait_popup_begin(
		"CoinRefillPopup",
		"coin_refill_popup",
		170,
		close_action,
		145.0,
		560.0,
		true,
		coin_store_return_action
	)
	var rect := Rect2(28.0, 145.0, 424.0, 415.0)
	_portrait_popup_shell(rect, tr("COIN_STORE_TITLE"), close_action, 28)

	# Reuse the main-prize composition without the refill popups' blue status card:
	# one large coin pack, the rotating glow and the x50 counter form the focal point.
	var coin_rect := Rect2(
		Vector2(
			(PORTRAIT_STAGE_SIZE.x - PORTRAIT_COIN_REFILL_ICON_SIZE.x) * 0.5,
			268.0
		),
		PORTRAIT_COIN_REFILL_ICON_SIZE
	)
	var glow_rect := Rect2(
		coin_rect.get_center() - PORTRAIT_COIN_REFILL_GLOW_SIZE * 0.5,
		PORTRAIT_COIN_REFILL_GLOW_SIZE
	)
	var glow := _stage_final_reward_glow(glow_rect)
	glow.name = "CoinRefillGlow"
	glow.modulate = Color(1.0, 1.0, 1.0, PORTRAIT_COIN_REFILL_GLOW_ALPHA)
	_start_final_reward_glow_rotation(
		glow,
		PORTRAIT_COIN_REFILL_GLOW_ROTATION_DURATION
	)

	var coin_icon := _stage_texture(coin_rect, COIN_PACK_04_TEXTURE)
	coin_icon.name = "CoinRefillIcon"
	coin_icon.add_to_group(&"coin_refill_reward_source")
	coin_icon.z_index = 20
	call_deferred("_play_final_reward_pack_bounce", coin_icon)

	var amount_label := _stage_label(
		_portrait_final_reward_amount_rect(coin_rect),
		_single_player_reward_chain_count_text(PORTRAIT_COIN_REFILL_REWARDED_AMOUNT),
		PORTRAIT_FINAL_REWARD_COUNT_FONT_SIZE,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	amount_label.name = "CoinRefillAmount"
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
	amount_label.z_index = 21

	var rewarded_coin_button := _stage_portrait_popup_main_button(
		Rect2(
			90.0,
			_portrait_popup_bottom_button_y(rect.end.y, 56.0),
			300.0,
			56.0
		),
		Callable(self, "_on_coin_refill_ad_pressed"),
		tr("COMMON_FREE"),
		18,
		false,
		0.32,
		false,
		false,
		false,
		LONG_BUTTON_COLOR_BLUE
	)
	rewarded_coin_button.name = "CoinRefillAdButton"
	rewarded_coin_button.add_to_group(&"coin_refill_ad_button")
	rewarded_coin_button.z_index = 22
	rewarded_coin_button.visible = _portrait_ads_enabled()
	var rewarded_ad_icon_texture: Texture2D = _coin_refill_ad_icon_texture()
	rewarded_coin_button.set_meta(&"coin_refill_ad_icon_texture", rewarded_ad_icon_texture)
	rewarded_coin_button.set("icon_texture", rewarded_ad_icon_texture)
	rewarded_coin_button.set("icon_stage_size", Vector2(34.0, 28.0))
	rewarded_coin_button.set("icon_gap_stage", 9.0)
	rewarded_coin_button.set("icon_before_text", true)
	rewarded_coin_button.set("icon_shadow_enabled", true)
	rewarded_coin_button.set("icon_shadow_offset_stage", Vector2(2.0, 2.0))
	rewarded_coin_button.set("icon_shadow_color", PORTRAIT_UI_PALETTE.AD_ICON_SHADOW)
	if rewarded_coin_button.has_method("set_color_palette"):
		rewarded_coin_button.call(
			"set_color_palette",
			PORTRAIT_AD_BADGE_PURPLE,
			PORTRAIT_UI_PALETTE.AD_PURPLE_PRESSED,
			PORTRAIT_UI_PALETTE.AD_PURPLE_SELECTED
		)
	_stage_coin_refill_ad_counter(rewarded_coin_button)
	_refresh_coin_refill_ad_button(rewarded_coin_button, true)
	content = previous_content

func _on_coin_refill_ad_pressed() -> void:
	if !GameState.can_watch_coin_refill_ad():
		for node: Node in get_tree().get_nodes_in_group(&"coin_refill_ad_button"):
			_refresh_coin_refill_ad_button(node as Control, true)
		return
	_show_portrait_rewarded_action(&"coin_refill")

func _play_coin_refill_reward_animation(previous_balance: int, final_balance: int) -> void:
	# Capture the large x50 pack position while the refill popup still exists, then
	# close the popup before starting the visible reward delivery. This keeps the
	# flying coins above the returned screen instead of underneath the modal.
	var source_visual: Control = null
	for node: Node in get_tree().get_nodes_in_group(&"coin_refill_reward_source"):
		var candidate := node as Control
		if candidate != null and is_instance_valid(candidate) and candidate.is_inside_tree():
			source_visual = candidate
			break
	if source_visual == null:
		_close_coin_store()
		return

	var source_center_canvas: Vector2 = (
		source_visual.get_global_transform_with_canvas() * (source_visual.size * 0.5)
	)
	_close_coin_store()

	# The return action may rebuild the underlying screen and HUD. Give it a few
	# frames to expose a valid destination coin icon before starting the animation.
	for _frame_index in range(8):
		if (
			_portrait_currency_coin_icon_visual != null
			and is_instance_valid(_portrait_currency_coin_icon_visual)
			and _portrait_currency_coin_icon_visual.is_inside_tree()
		):
			break
		await get_tree().process_frame
	if (
		ui == null
		or !is_instance_valid(ui)
		or _portrait_currency_coin_icon_visual == null
		or !is_instance_valid(_portrait_currency_coin_icon_visual)
		or !_portrait_currency_coin_icon_visual.is_inside_tree()
	):
		return

	# Recreate an invisible one-pixel source at the popup coin pack's former canvas
	# position. The shared reward animation reads this point synchronously, while
	# the actual popup is already gone.
	var source_stub := Control.new()
	source_stub.name = "CoinRefillRewardSourceStub"
	source_stub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	source_stub.size = Vector2.ONE
	ui.add_child(source_stub)
	var source_center_ui: Vector2 = (
		ui.get_global_transform_with_canvas().affine_inverse() * source_center_canvas
	)
	source_stub.position = source_center_ui - source_stub.size * 0.5

	# add_soft_currency() has already emitted the final balance to every HUD label.
	# Restore the pre-reward number after the returned screen has been built, then
	# animate the visible count alongside the flying coins.
	_set_home_reward_animated_balance(float(previous_balance))
	_play_single_player_reward_coin_collection(source_stub)

	var count_tween := source_stub.create_tween()
	count_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var roll := count_tween.tween_method(
		Callable(self, "_set_home_reward_animated_balance"),
		float(previous_balance),
		float(final_balance),
		PORTRAIT_FINAL_REWARD_HOME_COUNT_DURATION
	)
	roll.set_trans(Tween.TRANS_QUAD)
	roll.set_ease(Tween.EASE_OUT)
	count_tween.tween_callback(Callable(source_stub, "queue_free"))

func show_tasks() -> void:
	coin_store_return_action = Callable()
	_show_theme_select_screen(false)

func _stage_single_player_level_header(level_index: int) -> void:
	_stage_portrait_page_header(
		"%s %d" % [_single_player_level_label(), level_index + 1],
		Callable(self, "show_menu"),
		Callable(self, "show_single_player_level").bind(level_index)
	)

func _stage_portrait_game_header() -> void:
	var coin_store_return_action := Callable(self, "_return_to_game_from_coin_store")
	if GameState.current_mode == GameState.GameMode.TWO_PLAYER:
		_stage_centered_coin_only_counter(
			coin_store_return_action,
			PORTRAIT_GAME_CURRENCY_COUNTER_RECT
		)
	else:
		_stage_coin_and_star_counters(
			coin_store_return_action,
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
	coin_store_return_action: Callable = Callable(),
	close_on_dimmer: bool = true,
	alpha: float = PORTRAIT_POPUP_DIM_ALPHA
) -> Control:
	var resume_without_intro: bool = _portrait_popup_resume_without_intro
	_portrait_popup_resume_without_intro = false
	if !resume_without_intro:
		_play_popup_open_sound()
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
	var dimmer_close_callable: Callable = close_callable if close_on_dimmer else Callable()
	_add_fullscreen_modal_backdrop(dimmer_close_callable, alpha)
	if show_coin_balance:
		_stage_popup_coin_balance_above_dimmer(
			popup_root,
			close_callable,
			coin_store_return_action
		)
	content = _center_popup_content(popup_root, popup_top, popup_bottom)
	if resume_without_intro and content.has_method(&"settle_without_open_bounce"):
		content.call(&"settle_without_open_bounce")
	return previous_content

func _stage_refill_status_glow(
	status_panel: Control,
	status_rect: Rect2,
	icon_rect: Rect2,
	glow_name: StringName
) -> TextureRect:
	var glow_size := (
		Vector2.ONE
		* PORTRAIT_REFILL_STATUS_GLOW_DIAMETER
		* PORTRAIT_SINGLE_PLAYER_THEME_CARD_GLOW_SCALE
	)
	var glow_rect := Rect2(
		icon_rect.get_center() - glow_size * 0.5,
		glow_size
	)
	var glow := TextureRect.new()
	glow.name = glow_name
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.texture = FINAL_REWARD_ROTATING_GLOW_TEXTURE
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glow.position = glow_rect.position - status_rect.position
	glow.size = glow_rect.size
	glow.modulate = Color.WHITE
	# FlashStagePanel is custom-drawn, so CanvasItem.clip_children does not expose
	# its rounded StyleBox as a reliable child mask. Mask the glow explicitly in
	# its own local coordinates instead.
	var mask_rect := Rect2(status_rect.position - glow_rect.position, status_rect.size)
	var mask_material := ShaderMaterial.new()
	mask_material.shader = ROUNDED_RECT_TEXTURE_MASK_SHADER
	mask_material.set_shader_parameter(&"source_size", glow_rect.size)
	mask_material.set_shader_parameter(
		&"mask_rect",
		Vector4(
			mask_rect.position.x,
			mask_rect.position.y,
			mask_rect.size.x,
			mask_rect.size.y
		)
	)
	mask_material.set_shader_parameter(
		&"corner_radius",
		PORTRAIT_REFILL_STATUS_CORNER_RADIUS
	)
	mask_material.set_shader_parameter(&"opacity", PORTRAIT_REFILL_STATUS_GLOW_ALPHA)
	glow.material = mask_material
	glow.z_index = 1
	status_panel.add_child(glow)
	return glow

func _stage_popup_coin_balance_above_dimmer(
	popup_root: Control,
	_close_callable: Callable,
	coin_store_return_action: Callable
) -> void:
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
	# The coin-refill popup already is the destination of this counter, so its
	# balance is display-only and must not show another plus badge. Paid popups
	# retain the usual clickable counter that opens coin refill.
	var counter_is_interactive: bool = !_portrait_coin_store_active
	_stage_centered_coin_only_counter(
		coin_store_return_action,
		source_counter_rect,
		false,
		counter_is_interactive,
		false,
		false,
		Callable()
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
	subtitle: String = "",
	show_close_button: bool = true
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
			Rect2(popup_rect.position.x + 20.0, popup_rect.position.y + 28.0, popup_rect.size.x - 40.0, 32.0),
			subtitle,
			21,
			Color.WHITE,
			HORIZONTAL_ALIGNMENT_CENTER
		)
		subtitle_label.add_theme_font_override("font", UI_PRIMARY_FONT)
		subtitle_label.clip_text = false

	if show_close_button:
		var close_x: float = rect.position.x + (rect.size.x - PORTRAIT_POPUP_CLOSE_SIZE) * 0.5
		var close_y: float = rect.end.y + PORTRAIT_POPUP_CLOSE_GAP
		_stage_portrait_popup_close_button(
			Rect2(close_x, close_y, PORTRAIT_POPUP_CLOSE_SIZE, PORTRAIT_POPUP_CLOSE_SIZE),
			close_callable
		)

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
	_quiz_mode_active = false
	_quiz_screen_active = false
	_quiz_selected_theme_index = -1
	_quiz_current_question.clear()
	_quiz_answer_buttons.clear()
	_quiz_single_player_embedded = false
	_quiz_single_player_target_difficulty = 0.5
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
	var home_background_overlay := _stage_horizontal_fill(
		PORTRAIT_HEADER_HEIGHT,
		PORTRAIT_STAGE_SIZE.y - PORTRAIT_HEADER_HEIGHT,
		PORTRAIT_SINGLE_REWARD_TITLE_BLOCK_COLOR
	)
	home_background_overlay.name = "HomeBackgroundOverlay"
	home_background_overlay.z_index = -1
	_add_multi_theme_pattern(
		home_background_overlay,
		_collect_theme_pattern_textures(true),
		"HomeThemePattern",
		Color(1.0, 1.0, 1.0, 0.13),
		0.92,
		1.10,
		0.87,
		0.0,
		0.70
	)
	_add_full_rect_gradient_overlay(
		home_background_overlay,
		Color(PORTRAIT_DARK_BLUE.r, PORTRAIT_DARK_BLUE.g, PORTRAIT_DARK_BLUE.b, 0.0),
		PORTRAIT_UI_PALETTE.with_alpha(PORTRAIT_DARK_BLUE, 0.7),
		"HomeBackgroundGradient"
	)
	_stage_home_resource_counters(Callable(self, "show_menu"))

	var menu_title_content: Control = _portrait_begin_adaptive_group(Vector2(240.0, 235.0), PORTRAIT_MENU_TITLE_MAX_SCALE, 0.04)
	# Preserve the logo aspect ratio and reuse the imported texture on every visit.
	var main_menu_logo_texture: Texture2D = MAIN_MENU_LOGO_TEXTURE
	# Make the logo 32% larger than the authored source size and place it closer
	# to the visual center of the Home screen while preserving its aspect ratio.
	var main_menu_logo_bounds := Rect2(-13.44, 142.8, 506.88, 304.128)
	var main_menu_logo_rect: Rect2 = _fit_stage_rect_keep_aspect(main_menu_logo_bounds, main_menu_logo_texture.get_size())
	var main_menu_logo_glow_outer_size := main_menu_logo_rect.size * 1.34
	var main_menu_logo_glow_outer_rect := Rect2(
		main_menu_logo_rect.get_center() - main_menu_logo_glow_outer_size * 0.5,
		main_menu_logo_glow_outer_size
	)
	var main_menu_logo_glow_outer := _stage_texture(
		main_menu_logo_glow_outer_rect,
		FINAL_REWARD_ROTATING_GLOW_TEXTURE
	)
	main_menu_logo_glow_outer.modulate = Color(0.47, 0.83, 1.0, 0.17)
	main_menu_logo_glow_outer.z_index = -2
	var main_menu_logo_glow_inner_size := main_menu_logo_rect.size * 1.16
	var main_menu_logo_glow_inner_rect := Rect2(
		main_menu_logo_rect.get_center() - main_menu_logo_glow_inner_size * 0.5,
		main_menu_logo_glow_inner_size
	)
	var main_menu_logo_glow_inner := _stage_texture(
		main_menu_logo_glow_inner_rect,
		FINAL_REWARD_ROTATING_GLOW_TEXTURE
	)
	main_menu_logo_glow_inner.modulate = Color(0.60, 0.88, 1.0, 0.24)
	main_menu_logo_glow_inner.z_index = -1
	var main_menu_logo := _stage_texture(main_menu_logo_rect, main_menu_logo_texture)
	main_menu_logo.modulate = Color.WHITE
	main_menu_logo.self_modulate = Color.WHITE

	# Play one soft diagonal highlight sweep every time the Home screen is entered.
	# The shader keeps the source alpha intact, so the highlight is visible only
	# on the painted logo pixels and never on its transparent background.
	var logo_shine_material := ShaderMaterial.new()
	logo_shine_material.shader = MAIN_MENU_LOGO_SHINE_SHADER
	main_menu_logo.material = logo_shine_material
	var logo_shine_tween := create_tween()
	logo_shine_tween.bind_node(main_menu_logo)
	logo_shine_tween.tween_interval(PORTRAIT_MENU_LOGO_SHINE_DELAY_SECONDS)
	var set_logo_shine_progress := func(progress: float) -> void:
		if is_instance_valid(logo_shine_material):
			logo_shine_material.set_shader_parameter("shine_progress", progress)
	var logo_shine_motion = logo_shine_tween.tween_method(
		set_logo_shine_progress,
		-0.30,
		1.55,
		PORTRAIT_MENU_LOGO_SHINE_DURATION_SECONDS
	)
	if logo_shine_motion != null:
		logo_shine_motion.set_trans(Tween.TRANS_SINE)
		logo_shine_motion.set_ease(Tween.EASE_IN_OUT)
	_portrait_end_adaptive_group(menu_title_content)

	_stage_main_button(Rect2(67.5, 578.0, 345.0, 73.6), Callable(self, "show_custom_word"), Database.tr_text(2, "Two Player").to_upper(), 22)
	var single_player_action := Callable(self, "_open_next_single_player_level")
	if GameState.has_resumable_single_player_level():
		single_player_action = Callable(self, "_resume_saved_single_player_level")
	_stage_single_player_menu_button(
		Rect2(33.0, 670.0, 414.0, 88.32),
		single_player_action
	)
	_stage_portrait_ad_banner()
	if _portrait_pending_home_reward_amount > 0:
		call_deferred("_play_pending_home_reward_animation")
	if !GameState.has_accepted_legal_documents():
		call_deferred("_show_legal_consent_popup")
	elif !_startup_guided_resume_checked:
		_startup_guided_resume_checked = true
		if _should_auto_resume_guided_single_player():
			call_deferred("_resume_saved_single_player_level")

func _restore_single_player_language(language: String) -> void:
	var normalized_language: String = "ru" if language.to_lower().begins_with("ru") else "en"
	if Database.current_language != normalized_language:
		GameState.word_language = normalized_language
		Database.load_word_language(normalized_language)
		_invalidate_single_player_level_cache()

func _resume_saved_single_player_level() -> void:
	var pending: Dictionary = GameState.get_pending_single_player_reward()
	if !pending.is_empty():
		_restore_single_player_language(str(pending.get("language", Database.current_language)))
		var level_index: int = int(pending.get("level_index", -1))
		var word_count: int = maxi(int(pending.get("word_count", 1)), 1)
		var word_slot: int = clampi(int(pending.get("word_slot", word_count - 1)), 0, word_count - 1)
		var reward_amount: int = maxi(int(pending.get("amount", 0)), 0)
		if level_index < 0 or reward_amount <= 0:
			GameState.clear_active_single_player_session(true)
			show_menu()
			return
		GameState.activate_ads_for_level(level_index)
		GameState.current_mode = GameState.GameMode.SINGLE_PLAYER
		single_player_active_level_index = level_index
		single_player_active_word_slot = word_slot
		game_finished = true
		last_result_is_win = true
		last_result_data = {
			"lines": [],
			"single_player_level_index": level_index,
			"single_player_word_slot": word_slot,
			"single_player_played_count": word_count,
			"single_player_total_count": word_count,
			"single_player_level_completed": true,
			"single_player_level_perfect": true,
			"single_player_chain_failed": false,
			"single_player_chain_ended": true,
			"single_player_completion_bonus": maxi(reward_amount - GameState.WORD_REWARD_COINS, 0),
			"single_player_reward_deferred": true,
			"single_player_deferred_reward_amount": reward_amount,
		}
		_show_single_player_reward_chain_screen()
		return

	var session: Dictionary = GameState.get_active_single_player_session()
	if session.is_empty():
		show_menu()
		return
	_restore_single_player_language(str(session.get("language", Database.current_language)))
	var level_index: int = int(session.get("level_index", -1))
	var word_slot: int = int(session.get("word_slot", -1))
	var kind: String = str(session.get("kind", ""))
	if level_index < 0 or word_slot < 0:
		GameState.clear_active_single_player_session(true)
		show_menu()
		return
	GameState.activate_ads_for_level(level_index)
	GameState.current_mode = GameState.GameMode.SINGLE_PLAYER
	single_player_active_level_index = level_index
	single_player_active_word_slot = word_slot
	game_finished = false
	last_result_data = {}
	last_result_is_win = false
	match kind:
		"theme":
			var theme_data_variant: Variant = session.get("data", {})
			var retry_after_loss: bool = false
			if theme_data_variant is Dictionary:
				retry_after_loss = bool(
					Dictionary(theme_data_variant).get("retry_after_loss", false)
				)
			var selected_theme: int = Database.get_theme_index_by_id(
				int(session.get("theme_id", -1))
			)
			_show_single_player_level_popup(
				level_index,
				selected_theme,
				retry_after_loss
			)
			return
		"word":
			var word_data_variant: Variant = session.get("data", {})
			if (
				word_data_variant is Dictionary
				and GameSession.restore_from_save_data(Dictionary(word_data_variant))
			):
				show_game_screen()
				if GameSession.has_deferred_loss():
					call_deferred("_show_single_player_last_chance_popup", false)
				return
		"quiz":
			var quiz_data_variant: Variant = session.get("data", {})
			if quiz_data_variant is Dictionary:
				var data: Dictionary = Dictionary(quiz_data_variant)
				var question_variant: Variant = data.get("question", {})
				var theme_index: int = Database.get_theme_index_by_id(int(session.get("theme_id", -1)))
				var question: Dictionary = (
					Dictionary(question_variant)
					if question_variant is Dictionary
					else {}
				)
				if !question.is_empty() and theme_index >= 0:
					GameSession.discard_current_round()
					GameState.current_mode = GameState.GameMode.SINGLE_PLAYER
					_quiz_mode_active = true
					_quiz_single_player_embedded = true
					_quiz_selected_theme_index = theme_index
					_quiz_current_question = question.duplicate(true)
					_quiz_single_player_target_difficulty = clampf(
						float(data.get("target_difficulty", 0.5)),
						0.0,
						SINGLE_PLAYER_QUIZ_TARGET_MAXIMUM
					)
					_quiz_answer_locked = false
					_quiz_selected_answer_index = -1
					_quiz_fifty_fifty_used = bool(data.get("fifty_fifty_used", false))
					var hidden_variant: Variant = data.get("hidden_indices", [])
					_quiz_fifty_fifty_hidden_indices = (
						Array(hidden_variant).duplicate()
						if hidden_variant is Array
						else []
					)
					_quiz_replace_question_used = bool(data.get("replace_question_used", false))
					_quiz_question_replacing = false
					_show_quiz_game_screen()
					return
		"next":
			var next_data_variant: Variant = session.get("data", {})
			var stage_reward: Dictionary = GameState.get_active_single_player_stage_reward()
			if next_data_variant is Dictionary:
				var next_data: Dictionary = next_data_variant
				var result_variant: Variant = next_data.get("result", {})
				if result_variant is Dictionary:
					game_finished = true
					last_result_data = Dictionary(result_variant).duplicate(true)
					# Older `next` snapshots only represented victories. New ones
					# persist the outcome explicitly so a failed stage is resumable.
					last_result_is_win = bool(last_result_data.get(
						"single_player_stage_won",
						true
					))
					_portrait_single_reward_resume_without_intro = bool(
						!last_result_is_win or stage_reward.get("claimed", false)
					)
					_show_single_player_reward_chain_screen()
					return
			_start_next_single_player_word(level_index)
			return
	GameState.clear_active_single_player_session(true)
	_open_next_single_player_level()

func _legal_interface_text(russian_text: String, english_text: String) -> String:
	return russian_text if Database.interface_language == "ru" else english_text

func _create_portrait_legal_link(
	text: String,
	document_type: String,
	font_size: int = 21
) -> LinkButton:
	var link := LinkButton.new()
	link.name = "LegalLink_" + document_type
	link.text = text
	link.mouse_filter = Control.MOUSE_FILTER_STOP
	link.focus_mode = Control.FOCUS_NONE
	link.underline = LinkButton.UNDERLINE_MODE_ALWAYS
	link.add_theme_font_override("font", UI_PRIMARY_FONT)
	link.add_theme_font_size_override("font_size", font_size)
	link.add_theme_color_override("font_color", PORTRAIT_UI_PALETTE.SUCCESS_SOFT)
	link.add_theme_color_override("font_hover_color", PORTRAIT_UI_PALETTE.SUCCESS)
	link.add_theme_color_override("font_pressed_color", PORTRAIT_UI_PALETTE.SUCCESS_PRESSED)
	link.add_theme_color_override("font_focus_color", PORTRAIT_UI_PALETTE.SUCCESS_SOFT)
	link.add_theme_color_override("font_outline_color", PORTRAIT_UI_PALETTE.UI_BLUE_DARK)
	link.add_theme_constant_override("outline_size", 2)
	_connect_stage_button_action(link, Callable(self, "_open_legal_document").bind(document_type))
	return link

func _stage_portrait_legal_link(
	rect: Rect2,
	text: String,
	document_type: String,
	font_size: int = 21
) -> LinkButton:
	var holder := _stage_holder(rect, Control.MOUSE_FILTER_PASS)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(center)
	var link := _create_portrait_legal_link(text, document_type, font_size)
	center.add_child(link)
	return link

func _stage_portrait_legal_links_row(rect: Rect2, font_size: int = 17) -> void:
	var holder := _stage_holder(rect, Control.MOUSE_FILTER_PASS)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(center)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_theme_constant_override("separation", 12)
	center.add_child(row)

	row.add_child(_create_portrait_legal_link(
		_legal_interface_text("Конфиденциальность", "Privacy"),
		"privacy",
		font_size
	))

	var separator := Label.new()
	separator.text = "·"
	separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	separator.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	separator.add_theme_font_override("font", UI_PRIMARY_FONT)
	separator.add_theme_font_size_override("font_size", font_size)
	separator.add_theme_color_override("font_color", PORTRAIT_UI_PALETTE.TEXT_PALE_BLUE)
	separator.add_theme_color_override("font_outline_color", PORTRAIT_UI_PALETTE.UI_BLUE_DARK)
	separator.add_theme_constant_override("outline_size", 2)
	row.add_child(separator)

	row.add_child(_create_portrait_legal_link(
		_legal_interface_text("Условия", "Terms"),
		"terms",
		font_size
	))

func _on_portrait_legal_text_meta_clicked(meta: Variant) -> void:
	var document_type := str(meta)
	if document_type == "terms" or document_type == "privacy":
		_open_legal_document(document_type)

func _stage_portrait_legal_inline_text(rect: Rect2) -> RichTextLabel:
	var holder := _stage_holder(rect, Control.MOUSE_FILTER_PASS)
	var legal_text := RichTextLabel.new()
	legal_text.name = "LegalConsentText"
	legal_text.mouse_filter = Control.MOUSE_FILTER_STOP
	legal_text.focus_mode = Control.FOCUS_NONE
	legal_text.bbcode_enabled = true
	legal_text.fit_content = false
	legal_text.scroll_active = false
	legal_text.selection_enabled = false
	legal_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	legal_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	legal_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	legal_text.add_theme_font_override("normal_font", UI_HEADING_FONT)
	legal_text.add_theme_font_override("bold_font", UI_HEADING_FONT)
	legal_text.add_theme_font_size_override("normal_font_size", 22)
	legal_text.add_theme_font_size_override("bold_font_size", 22)
	legal_text.add_theme_color_override("default_color", Color.WHITE)
	legal_text.add_theme_color_override(
		"font_outline_color",
		PORTRAIT_UI_PALETTE.UI_BLUE_DARK
	)
	legal_text.add_theme_constant_override("outline_size", 2)
	var link_color: String = PORTRAIT_UI_PALETTE.SUCCESS_SOFT.to_html(false)
	legal_text.text = _legal_interface_text(
		(
			"[center]Пожалуйста, прочитайте и примите наши "
			+ "[url=terms][u][color=#%s]Условия обслуживания[/color][/u][/url] " % link_color
			+ "и [url=privacy][u][color=#%s]Политику[/color][/u][/url][/center]" % link_color
		),
		(
			"[center]Please read and accept our "
			+ "[url=terms][u][color=#%s]Terms of Service[/color][/u][/url] " % link_color
			+ "and [url=privacy][u][color=#%s]Privacy Policy[/color][/u][/url][/center]" % link_color
		)
	)
	legal_text.meta_clicked.connect(Callable(self, "_on_portrait_legal_text_meta_clicked"))
	holder.add_child(legal_text)
	return legal_text

func _show_legal_consent_popup() -> void:
	if GameState.has_accepted_legal_documents():
		return
	_remove_legal_consent_popup()
	_hide_portrait_ad_banner()
	var rect := Rect2(28.0, 225.0, 424.0, 280.0)
	var previous_content := _portrait_popup_begin(
		"LegalConsentPopup",
		str(PORTRAIT_LEGAL_POPUP_GROUP),
		500,
		Callable(),
		rect.position.y,
		rect.end.y,
		false,
		Callable(),
		false
	)
	_portrait_popup_shell(
		rect,
		_legal_interface_text("Добро пожаловать", "Welcome"),
		Callable(),
		27,
		PORTRAIT_BLUE,
		PORTRAIT_DARK_BLUE,
		PORTRAIT_ORANGE,
		"",
		false
	)
	_stage_portrait_legal_inline_text(Rect2(54.0, 294.0, 372.0, 116.0))
	_stage_portrait_popup_main_button(
		Rect2(
			90.0,
			_portrait_popup_bottom_button_y(rect.end.y, 56.0),
			300.0,
			56.0
		),
		Callable(self, "_accept_legal_documents"),
		_legal_interface_text("Принять", "Accept"),
		22,
		false,
		0.0,
		false,
		false,
		false,
		LONG_BUTTON_COLOR_ORANGE
	)
	content = previous_content

func _remove_legal_consent_popup() -> void:
	for node: Node in get_tree().get_nodes_in_group(PORTRAIT_LEGAL_POPUP_GROUP):
		if is_instance_valid(node) and node.get_parent() != null:
			node.get_parent().remove_child(node)
			node.queue_free()

func _accept_legal_documents() -> void:
	if !GameState.accept_legal_documents():
		return
	_remove_legal_consent_popup()
	_show_menu_screen()

func show_settings() -> void:
	_show_settings_popup()

func _settings_popup_uses_compact_layout() -> bool:
	if _quiz_screen_active:
		return true
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

	# Anchor the contact buttons, legal links, and version to the shell bottom instead of
	# leaving the footer floating beneath the settings controls.
	var footer_bottom_y: float = rect.end.y
	var social_buttons_y: float = footer_bottom_y - 142.0
	var legal_links_y: float = footer_bottom_y - 76.0
	var version_y: float = footer_bottom_y - 39.0
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
		_stage_portrait_legal_links_row(
			Rect2(rect.position.x, legal_links_y, rect.size.x, 30.0),
			17
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

func _quiz_menu_label() -> String:
	return "ВИКТОРИНА" if Database.interface_language == "ru" else "QUIZ"

func _quiz_theme_select_title() -> String:
	return "ВЫБЕРИТЕ ТЕМУ" if Database.interface_language == "ru" else "CHOOSE A TOPIC"

func _quiz_question_count_text(question_count: int) -> String:
	if Database.interface_language != "ru":
		return "%d QUESTIONS" % question_count
	var remainder_100: int = question_count % 100
	var remainder_10: int = question_count % 10
	var noun: String = "ВОПРОСОВ"
	if remainder_100 < 11 or remainder_100 > 14:
		if remainder_10 == 1:
			noun = "ВОПРОС"
		elif remainder_10 >= 2 and remainder_10 <= 4:
			noun = "ВОПРОСА"
	return "%d %s" % [question_count, noun]

func show_quiz_theme_select() -> void:
	_quiz_mode_active = true
	_quiz_screen_active = false
	_quiz_single_player_embedded = false
	_quiz_single_player_target_difficulty = 0.5
	_show_quiz_theme_select_screen()

func _show_quiz_theme_select_screen() -> void:
	_clear()
	_quiz_mode_active = true
	_portrait_screen(0.0)
	_stage_portrait_page_header(
		_quiz_theme_select_title(),
		Callable(self, "show_menu"),
		Callable(self, "show_quiz_theme_select")
	)

	for theme_index in range(Database.get_theme_count()):
		var col: int = theme_index % 2
		var row: int = int(theme_index / 2)
		var x: float = 18.0 + float(col) * 230.0
		var y: float = 154.0 + float(row) * 96.0
		var question_count: int = Database.get_quiz_question_count_by_theme_index(theme_index)
		var disabled: bool = question_count <= 0
		var card := _stage_texture(Rect2(x, y, 214.0, 88.0), THEME_CARD_TEXTURE)
		var progress_back := _stage_texture(Rect2(x, y, 214.0, 63.0), THEME_CARD_PROGRESS_TEXTURE)
		var progress_label := _stage_label(
			Rect2(x + 8.0, y + 7.0 + THEME_PROGRESS_TEXT_OPTICAL_OFFSET_Y, 198.0, 44.0),
			_quiz_question_count_text(question_count),
			16,
			PORTRAIT_UI_PALETTE.THEME_PROGRESS_TEXT
		)
		progress_label.clip_text = false

		var theme_name: String = Database.get_theme_name(theme_index).to_upper()
		var theme_icon_texture: Texture2D = _theme_icon_texture(theme_index)
		var theme_icon: Control = null
		if theme_icon_texture != null:
			theme_icon = _stage_texture(Rect2(x + 12.0, y + 42.0, 34.0, 34.0), theme_icon_texture)
			theme_icon.z_index = 11
		var title_font_size: int = 17 if theme_name.length() > 12 else 21
		var title_label := _stage_label(
			Rect2(x + 52.0, y + 41.0, 152.0, 38.0),
			theme_name,
			title_font_size,
			Color.WHITE,
			HORIZONTAL_ALIGNMENT_LEFT
		)
		title_label.clip_text = false
		var theme_effect_color: Color = PORTRAIT_UI_PALETTE.with_alpha(
			PORTRAIT_UI_PALETTE.UI_BLUE_EFFECT,
			0.55
		)
		BUTTON_TEXT_STYLE_SCRIPT.apply(title_label, theme_effect_color, theme_effect_color)

		if disabled:
			card.modulate = Color(1.0, 1.0, 1.0, 0.45)
			progress_back.modulate = Color(1.0, 1.0, 1.0, 0.45)
			progress_label.modulate = Color(1.0, 1.0, 1.0, 0.45)
			if theme_icon != null:
				theme_icon.modulate = Color(1.0, 1.0, 1.0, 0.45)
			title_label.modulate = Color(1.0, 1.0, 1.0, 0.45)

		var theme_button := _stage_button(
			Rect2(x, y, 214.0, 88.0),
			Callable(self, "_start_quiz_theme").bind(theme_index),
			""
		)
		theme_button.disabled = disabled
		_bind_theme_card_press_state(theme_button, card)

func _start_quiz_theme(theme_index: int) -> void:
	var questions: Array = Database.get_quiz_questions_by_theme_index(theme_index)
	if questions.is_empty():
		show_quiz_theme_select()
		return
	_quiz_mode_active = true
	_quiz_single_player_embedded = false
	_quiz_single_player_target_difficulty = 0.5
	_quiz_selected_theme_index = theme_index
	var selected_question: Dictionary = questions[randi_range(0, questions.size() - 1)]
	_quiz_current_question = selected_question.duplicate(true)
	_quiz_answer_locked = false
	_quiz_selected_answer_index = -1
	_quiz_fifty_fifty_used = false
	_quiz_fifty_fifty_hidden_indices.clear()
	_quiz_replace_question_used = false
	_quiz_question_replacing = false
	_show_quiz_game_screen()

func _single_player_embedded_question_active() -> bool:
	return _quiz_single_player_embedded and _quiz_screen_active and !game_finished

func _persist_active_single_player_quiz_session() -> void:
	if (
		!_quiz_single_player_embedded
		or game_finished
		or single_player_active_level_index < 0
		or single_player_active_word_slot < 0
		or _quiz_selected_theme_index < 0
		or _quiz_current_question.is_empty()
	):
		return
	GameState.set_active_single_player_session({
		"kind": "quiz",
		"language": Database.current_language,
		"level_index": single_player_active_level_index,
		"word_slot": single_player_active_word_slot,
		"theme_id": Database.get_theme_id(_quiz_selected_theme_index),
		"data": {
			"question": _quiz_current_question.duplicate(true),
			"target_difficulty": _quiz_single_player_target_difficulty,
			"fifty_fifty_used": _quiz_fifty_fifty_used,
			"hidden_indices": _quiz_fifty_fifty_hidden_indices.duplicate(),
			"replace_question_used": _quiz_replace_question_used,
		},
	})

func _start_single_player_question(level_index: int, word_slot: int) -> void:
	if _single_player_level_word_status(level_index, word_slot) != 0:
		return
	GameState.activate_ads_for_level(level_index)
	var level_question_slot: int = _single_player_level_question_slot_index(level_index)
	var question: Dictionary = _single_player_level_question(level_index)
	var theme_index: int = _single_player_level_selected_theme(level_index)
	if word_slot != level_question_slot or question.is_empty() or theme_index < 0:
		super._start_single_player_question(level_index, word_slot)
		return

	GameSession.discard_current_round()
	single_player_active_level_index = level_index
	single_player_active_word_slot = word_slot
	_prepare_single_player_extra_attempt_offers(level_index)
	game_finished = false
	last_result_data = {}
	last_result_is_win = false
	GameState.current_mode = GameState.GameMode.SINGLE_PLAYER
	_quiz_mode_active = true
	_quiz_single_player_embedded = true
	_quiz_single_player_target_difficulty = _single_player_level_question_target_difficulty(level_index)
	_quiz_selected_theme_index = theme_index
	_quiz_current_question = question.duplicate(true)
	_quiz_answer_locked = false
	_quiz_selected_answer_index = -1
	_quiz_fifty_fifty_used = false
	_quiz_fifty_fifty_hidden_indices.clear()
	_quiz_replace_question_used = false
	_quiz_question_replacing = false
	var question_id: int = int(_quiz_current_question.get("id", -1))
	if question_id >= 0:
		GameState.mark_single_player_question_seen(
			Database.current_language,
			theme_index,
			question_id,
			false
		)
	_persist_active_single_player_quiz_session()
	_show_quiz_game_screen()

func _record_single_player_quiz_result(is_win: bool) -> void:
	if !_quiz_single_player_embedded or game_finished:
		return
	game_finished = true
	last_result_is_win = is_win
	hero_force_default_pose = false
	var result: Dictionary = {"lines": []}
	var word_count: int = _single_player_level_word_count(single_player_active_level_index)
	var defer_final_reward: bool = (
		is_win
		and single_player_active_word_slot == word_count - 1
	)
	if !is_win:
		GameState.lose_heart(false)
	last_result_data = _single_player_mark_current_word_finished(
		result,
		is_win,
		true,
		defer_final_reward
	)

func _mark_quiz_question_ready() -> void:
	if _quiz_screen_active and !_quiz_answer_locked and !_quiz_question_replacing:
		_quiz_question_ready_at_msec = Time.get_ticks_msec()
	else:
		_quiz_question_ready_at_msec = 0

func _take_quiz_speed_tier() -> int:
	if _quiz_question_ready_at_msec <= 0:
		return PORTRAIT_QUIZ_SPEED_NONE
	var elapsed_msec: int = Time.get_ticks_msec() - _quiz_question_ready_at_msec
	_quiz_question_ready_at_msec = 0
	if elapsed_msec < 0:
		return PORTRAIT_QUIZ_SPEED_NONE
	if elapsed_msec <= PORTRAIT_QUIZ_LIGHTNING_ANSWER_WINDOW_MSEC:
		return PORTRAIT_QUIZ_SPEED_LIGHTNING
	if elapsed_msec <= PORTRAIT_QUIZ_FAST_ANSWER_WINDOW_MSEC:
		return PORTRAIT_QUIZ_SPEED_FAST
	return PORTRAIT_QUIZ_SPEED_NONE

func _quiz_speed_reward_amount(speed_tier: int) -> int:
	if speed_tier == PORTRAIT_QUIZ_SPEED_LIGHTNING:
		return maxi(PORTRAIT_QUIZ_LIGHTNING_REWARD_STARS, 0)
	if speed_tier == PORTRAIT_QUIZ_SPEED_FAST:
		return maxi(PORTRAIT_QUIZ_FAST_REWARD_STARS, 0)
	return 0

func _quiz_question_font_size(question_text: String) -> int:
	# Match the comment popup typography for quiz questions. The larger question
	# card gives enough room for the same 25 px heading style in this mode.
	return 25

func _quiz_answer_font_size(_answer_text: String) -> int:
	# Keep quiz answers consistently readable. Long answers are allowed to wrap
	# onto a second line instead of shrinking the font to fit a single line.
	return 20

func _stage_quiz_answer_button(rect: Rect2, text: String, font_size: int) -> Button:
	# Quiz answers use a native Button for the white/card face and a separate
	# Label child for the copy. Keeping the text separate lets a wrong answer
	# shake horizontally without moving the button itself.
	var holder: Control = _stage_holder(rect, Control.MOUSE_FILTER_PASS)
	var answer_corner_radius: int = int(round(PORTRAIT_LONG_BUTTON_SIZE.y * 0.5))

	var shadow_panel := Panel.new()
	shadow_panel.name = "QuizAnswerShadow"
	shadow_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	shadow_panel.offset_top = 6.0
	shadow_panel.offset_bottom = 6.0
	var shadow_style := StyleBoxFlat.new()
	shadow_style.bg_color = Color(0.07, 0.12, 0.24, 0.22)
	shadow_style.corner_radius_top_left = answer_corner_radius
	shadow_style.corner_radius_top_right = answer_corner_radius
	shadow_style.corner_radius_bottom_left = answer_corner_radius
	shadow_style.corner_radius_bottom_right = answer_corner_radius
	shadow_panel.add_theme_stylebox_override("panel", shadow_style)
	holder.add_child(shadow_panel)

	var button := Button.new()
	button.name = "QuizAnswerButton"
	button.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.text = ""
	button.focus_mode = Control.FOCUS_NONE

	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color.WHITE
	normal_style.corner_radius_top_left = answer_corner_radius
	normal_style.corner_radius_top_right = answer_corner_radius
	normal_style.corner_radius_bottom_left = answer_corner_radius
	normal_style.corner_radius_bottom_right = answer_corner_radius
	normal_style.content_margin_left = 18.0
	normal_style.content_margin_right = 18.0
	normal_style.content_margin_top = 8.0
	normal_style.content_margin_bottom = 8.0

	# Keep every interactive visual state white. The only press feedback is the
	# same 0.94 scale depression used by the standard long-button component.
	var hover_style := normal_style.duplicate() as StyleBoxFlat
	var pressed_style := normal_style.duplicate() as StyleBoxFlat
	var disabled_style := normal_style.duplicate() as StyleBoxFlat
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("focus", normal_style)
	button.add_theme_stylebox_override("disabled", disabled_style)
	holder.add_child(button)
	button.set_meta(&"quiz_answer_holder", holder)
	button.set_meta(&"quiz_answer_shadow", shadow_panel)
	button.set_meta(&"quiz_answer_keep_shadow_hidden", false)

	var answer_label := Label.new()
	answer_label.name = "QuizAnswerText"
	answer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	answer_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	answer_label.offset_left = 18.0
	answer_label.offset_top = 8.0
	answer_label.offset_right = -18.0
	answer_label.offset_bottom = -8.0
	answer_label.text = text
	answer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	answer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	answer_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	answer_label.clip_text = true
	answer_label.add_theme_font_override("font", UI_HEADING_FONT)
	answer_label.add_theme_font_size_override("font_size", font_size)
	answer_label.add_theme_color_override("font_color", PORTRAIT_UI_PALETTE.TEXT_DARK)
	button.add_child(answer_label)
	button.set_meta(&"quiz_answer_label", answer_label)

	# Match FlashStageTextureButton's standard long-button press motion while
	# keeping the native Button as the hit target. Scale the white face and its
	# shadow together around the same visual center.
	button.pivot_offset = holder.size * 0.5
	shadow_panel.pivot_offset = holder.size * 0.5 - shadow_panel.position
	button.button_down.connect(
		Callable(self, "_set_quiz_answer_press_scale").bind(button, shadow_panel, true)
	)
	button.button_up.connect(
		Callable(self, "_set_quiz_answer_press_scale").bind(button, shadow_panel, false)
	)
	button.mouse_exited.connect(
		Callable(self, "_set_quiz_answer_press_scale").bind(button, shadow_panel, false)
	)
	return button

func _set_quiz_answer_press_scale(button: Button, shadow_panel: Panel, is_pressed: bool) -> void:
	if button == null or !is_instance_valid(button) or shadow_panel == null or !is_instance_valid(shadow_panel):
		return
	# A depressed quiz answer sits flush against the surface, just like the
	# standard long buttons: hide its drop shadow for the duration of the press.
	# Once an answer has been selected, keep that answer's shadow hidden even if
	# a late button-up / mouse-exit signal arrives after the result was applied.
	var keep_shadow_hidden: bool = bool(
		button.get_meta(&"quiz_answer_keep_shadow_hidden", false)
	)
	shadow_panel.visible = !is_pressed and !keep_shadow_hidden
	var previous_tween_variant: Variant = button.get_meta(&"quiz_press_scale_tween", null)
	if previous_tween_variant is Tween:
		var previous_tween := previous_tween_variant as Tween
		if previous_tween.is_valid():
			previous_tween.kill()
	var target_scale := Vector2.ONE * (0.94 if is_pressed else 1.0)
	var duration: float = (
		PORTRAIT_CURRENCY_COUNTER_PRESS_DURATION
		if is_pressed
		else PORTRAIT_CURRENCY_COUNTER_RELEASE_DURATION
	)
	var tween := button.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	var button_scale_tweener := tween.tween_property(button, "scale", target_scale, duration)
	button_scale_tweener.set_trans(Tween.TRANS_QUAD)
	button_scale_tweener.set_ease(Tween.EASE_OUT)
	var shadow_scale_tweener := tween.tween_property(shadow_panel, "scale", target_scale, duration)
	shadow_scale_tweener.set_trans(Tween.TRANS_QUAD)
	shadow_scale_tweener.set_ease(Tween.EASE_OUT)
	button.set_meta(&"quiz_press_scale_tween", tween)


func _quiz_answer_shadow(button: Button) -> Panel:
	if button == null or !is_instance_valid(button):
		return null
	var shadow_variant: Variant = button.get_meta(&"quiz_answer_shadow", null)
	return shadow_variant as Panel if shadow_variant is Panel else null

func _quiz_answer_label(button: Button) -> Label:
	if button == null or !is_instance_valid(button):
		return null
	var label_variant: Variant = button.get_meta(&"quiz_answer_label", null)
	return label_variant as Label if label_variant is Label else null

func _set_quiz_answer_fill(button: Button, fill_color: Color) -> void:
	if button == null or !is_instance_valid(button):
		return
	var base_style := button.get_theme_stylebox("normal") as StyleBoxFlat
	if base_style == null:
		return
	for state_name: StringName in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		var state_style := base_style.duplicate() as StyleBoxFlat
		state_style.bg_color = fill_color
		button.add_theme_stylebox_override(state_name, state_style)

func _disable_quiz_answer_buttons() -> void:
	for answer_control: Control in _quiz_answer_buttons:
		var answer_button := answer_control as Button
		if answer_button != null and is_instance_valid(answer_button):
			answer_button.disabled = true

func _hide_quiz_exit_button() -> void:
	if _quiz_exit_button == null or !is_instance_valid(_quiz_exit_button):
		return
	_quiz_exit_button.visible = false
	_quiz_exit_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quiz_exit_button.set("disabled", true)
	_portrait_back_button_visible = false

func _hide_quiz_hint_buttons() -> void:
	for hint_button: Control in _quiz_hint_buttons:
		if hint_button != null and is_instance_valid(hint_button):
			hint_button.visible = false

func _show_quiz_continue_button(animated: bool) -> void:
	_hide_quiz_hint_buttons()
	if _quiz_continue_button == null or !is_instance_valid(_quiz_continue_button):
		return
	_quiz_continue_button.visible = true
	_quiz_continue_button.set("attention_bounce_enabled", false)
	if !animated:
		_quiz_continue_button.modulate.a = 1.0
		_quiz_continue_button.set("attention_bounce_enabled", true)
		return
	_quiz_continue_button.modulate.a = 0.0
	var fade_tween := _quiz_continue_button.create_tween()
	fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_tween.tween_property(
		_quiz_continue_button,
		"modulate:a",
		1.0,
		PORTRAIT_INLINE_RESULT_CONTINUE_GROW_DURATION
	)
	fade_tween.finished.connect(
		Callable(self, "_enable_quiz_continue_attention"),
		CONNECT_ONE_SHOT
	)

func _enable_quiz_continue_attention() -> void:
	if _quiz_continue_button == null or !is_instance_valid(_quiz_continue_button):
		return
	_quiz_continue_button.set("attention_bounce_enabled", true)

func _quiz_correct_feedback_text(speed_tier: int) -> String:
	if Database.interface_language == "ru":
		if speed_tier == PORTRAIT_QUIZ_SPEED_LIGHTNING:
			return "Молниеносно!"
		return "Вот это скорость!" if speed_tier == PORTRAIT_QUIZ_SPEED_FAST else "Верно!"
	if speed_tier == PORTRAIT_QUIZ_SPEED_LIGHTNING:
		return "Lightning fast!"
	return "That was fast!" if speed_tier == PORTRAIT_QUIZ_SPEED_FAST else "Correct!"

func _style_quiz_feedback_label(
	label: Label,
	font_size: int,
	font_color: Color
) -> void:
	var effect_color: Color = PORTRAIT_DARK_BLUE.darkened(0.38)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", UI_HEADING_FONT)
	label.add_theme_font_size_override("font_size", _heading_font_size(font_size))
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_color_override("font_outline_color", effect_color)
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_color_override(
		"font_shadow_color",
		Color(effect_color.r, effect_color.g, effect_color.b, 0.88)
	)
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 4)
	label.add_theme_constant_override("shadow_outline_size", 2)

func _create_quiz_correct_feedback(speed_tier: int) -> Dictionary:
	if _quiz_question_label == null or !is_instance_valid(_quiz_question_label):
		return {}
	var question_holder := _quiz_question_label.get_parent() as Control
	if question_holder == null or !is_instance_valid(question_holder):
		return {}

	_quiz_question_label.visible = false
	var feedback_root := Control.new()
	feedback_root.name = "QuizCorrectFeedback"
	feedback_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	question_holder.add_child(feedback_root)
	feedback_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	feedback_root.z_index = _quiz_question_label.z_index + 1

	var feedback_label := Label.new()
	feedback_label.name = "QuizCorrectFeedbackLabel"
	feedback_label.text = _quiz_correct_feedback_text(speed_tier)
	var has_speed_reward: bool = speed_tier != PORTRAIT_QUIZ_SPEED_NONE
	feedback_label.position = Vector2(0.0, 16.0 if has_speed_reward else 0.0)
	feedback_label.size = Vector2(
		feedback_root.size.x,
		118.0 if has_speed_reward else feedback_root.size.y
	)
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_quiz_feedback_label(
		feedback_label,
		34 if has_speed_reward else 38,
		PORTRAIT_QUIZ_ANSWER_CORRECT_COLOR
	)
	feedback_root.add_child(feedback_label)
	feedback_label.pivot_offset = feedback_label.size * 0.5
	feedback_label.scale = PORTRAIT_QUIZ_FEEDBACK_START_SCALE

	var reward_source: Control = null
	var reward_row: Control = null
	if has_speed_reward:
		reward_row = Control.new()
		reward_row.name = "QuizFastAnswerReward"
		reward_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		reward_row.position = Vector2((feedback_root.size.x - 96.0) * 0.5, 108.0)
		reward_row.size = Vector2(96.0, 48.0)
		reward_row.modulate.a = 0.0
		feedback_root.add_child(reward_row)

		var reward_amount_label := Label.new()
		reward_amount_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		reward_amount_label.position = Vector2(0.0, 0.0)
		reward_amount_label.size = Vector2(52.0, 48.0)
		reward_amount_label.text = "+%d" % _quiz_speed_reward_amount(speed_tier)
		_style_quiz_feedback_label(reward_amount_label, 28, Color.WHITE)
		reward_amount_label.add_theme_font_override("font", UI_PRIMARY_FONT)
		reward_row.add_child(reward_amount_label)

		var reward_icon := TextureRect.new()
		reward_icon.name = "QuizFastAnswerStarIcon"
		reward_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		reward_icon.texture = STAR_CURRENCY_TEXTURE
		reward_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		reward_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		reward_icon.position = Vector2(52.0, 3.0)
		reward_icon.size = Vector2.ONE * PORTRAIT_QUIZ_FAST_REWARD_ICON_SIZE
		reward_row.add_child(reward_icon)
		reward_source = reward_icon

	return {
		"root": feedback_root,
		"feedback_label": feedback_label,
		"reward_row": reward_row,
		"reward_source": reward_source,
	}

func _finish_quiz_fast_answer_star_collection() -> void:
	_set_stage_reward_animated_balance(
		float(GameState.get_stars()),
		GameState.STAGE_REWARD_STARS
	)
	_show_quiz_continue_button(true)

func _play_quiz_fast_answer_star_collection(
	source_visual: Control,
	previous_balance: int,
	final_balance: int
) -> void:
	if (
		source_visual == null
		or !is_instance_valid(source_visual)
		or !source_visual.is_inside_tree()
	):
		_finish_quiz_fast_answer_star_collection()
		return
	_set_stage_reward_animated_balance(
		float(previous_balance),
		GameState.STAGE_REWARD_STARS
	)
	_play_single_player_reward_resource_collection(
		source_visual,
		GameState.STAGE_REWARD_STARS,
		null,
		Callable(self, "_finish_quiz_fast_answer_star_collection")
	)
	var balance_tween := create_tween()
	balance_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var balance_roll := balance_tween.tween_method(
		Callable(self, "_set_stage_reward_animated_balance").bind(
			GameState.STAGE_REWARD_STARS
		),
		float(previous_balance),
		float(final_balance),
		_single_player_reward_collection_duration()
	)
	balance_roll.set_trans(Tween.TRANS_QUAD)
	balance_roll.set_ease(Tween.EASE_OUT)

func _finish_quiz_correct_question_feedback(
	feedback_root: Control,
	reward_source: Control,
	speed_tier: int,
	previous_balance: int,
	final_balance: int
) -> void:
	if (
		!_quiz_screen_active
		or _quiz_question_label == null
		or !is_instance_valid(_quiz_question_label)
	):
		if feedback_root != null and is_instance_valid(feedback_root):
			feedback_root.queue_free()
		_set_stage_reward_animated_balance(
			float(GameState.get_stars()),
			GameState.STAGE_REWARD_STARS
		)
		return

	_quiz_question_label.visible = true
	_quiz_question_label.modulate = Color.WHITE
	if speed_tier != PORTRAIT_QUIZ_SPEED_NONE:
		_play_quiz_fast_answer_star_collection(
			reward_source,
			previous_balance,
			final_balance
		)
	else:
		_show_quiz_continue_button(true)
	if feedback_root != null and is_instance_valid(feedback_root):
		feedback_root.queue_free()

func _play_quiz_correct_question_feedback(
	speed_tier: int,
	previous_balance: int,
	final_balance: int
) -> void:
	var feedback: Dictionary = _create_quiz_correct_feedback(speed_tier)
	var feedback_root := feedback.get("root") as Control
	var feedback_label := feedback.get("feedback_label") as Label
	var reward_row := feedback.get("reward_row") as Control
	var reward_source := feedback.get("reward_source") as Control
	if (
		feedback_root == null
		or !is_instance_valid(feedback_root)
		or feedback_label == null
		or !is_instance_valid(feedback_label)
	):
		if _quiz_question_label != null and is_instance_valid(_quiz_question_label):
			_quiz_question_label.visible = true
		if speed_tier != PORTRAIT_QUIZ_SPEED_NONE:
			_finish_quiz_fast_answer_star_collection()
		else:
			_show_quiz_continue_button(true)
		return

	var feedback_tween := feedback_label.create_tween()
	feedback_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var grow := feedback_tween.tween_property(
		feedback_label,
		"scale",
		PORTRAIT_QUIZ_FEEDBACK_PEAK_SCALE,
		PORTRAIT_QUIZ_FEEDBACK_GROW_DURATION
	)
	grow.set_trans(Tween.TRANS_BACK)
	grow.set_ease(Tween.EASE_OUT)
	var settle := feedback_tween.tween_property(
		feedback_label,
		"scale",
		Vector2.ONE,
		PORTRAIT_QUIZ_FEEDBACK_SETTLE_DURATION
	)
	settle.set_trans(Tween.TRANS_BOUNCE)
	settle.set_ease(Tween.EASE_OUT)
	if reward_row != null and is_instance_valid(reward_row):
		var reward_fade := feedback_tween.tween_property(
			reward_row,
			"modulate:a",
			1.0,
			PORTRAIT_QUIZ_FAST_REWARD_FADE_DURATION
		)
		reward_fade.set_trans(Tween.TRANS_SINE)
		reward_fade.set_ease(Tween.EASE_OUT)
	feedback_tween.tween_interval(PORTRAIT_QUIZ_FEEDBACK_HOLD_DURATION)
	# Pop only the green feedback text out before restoring the question. The
	# static +N/star row keeps its authored scale throughout this exit bounce.
	var exit_grow := feedback_tween.tween_property(
		feedback_label,
		"scale",
		PORTRAIT_QUIZ_FEEDBACK_EXIT_PEAK_SCALE,
		PORTRAIT_QUIZ_FEEDBACK_EXIT_GROW_DURATION
	)
	exit_grow.set_trans(Tween.TRANS_QUAD)
	exit_grow.set_ease(Tween.EASE_OUT)
	# Keep the original question fully hidden until both feedback elements have
	# faded out. Its restore fade is appended as the next tween step below.
	_quiz_question_label.visible = true
	_quiz_question_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var exit_hide := feedback_tween.tween_property(
		feedback_label,
		"scale",
		Vector2.ZERO,
		PORTRAIT_QUIZ_FEEDBACK_EXIT_HIDE_DURATION
	)
	exit_hide.set_trans(Tween.TRANS_BACK)
	exit_hide.set_ease(Tween.EASE_IN)
	var feedback_exit_fade := feedback_tween.parallel().tween_property(
		feedback_label,
		"modulate:a",
		0.0,
		PORTRAIT_QUIZ_FEEDBACK_EXIT_HIDE_DURATION
	)
	feedback_exit_fade.set_trans(Tween.TRANS_SINE)
	feedback_exit_fade.set_ease(Tween.EASE_IN)
	if reward_row != null and is_instance_valid(reward_row):
		var reward_exit_fade := feedback_tween.parallel().tween_property(
			reward_row,
			"modulate:a",
			0.0,
			PORTRAIT_QUIZ_FEEDBACK_EXIT_HIDE_DURATION
		)
		reward_exit_fade.set_trans(Tween.TRANS_SINE)
		reward_exit_fade.set_ease(Tween.EASE_IN)
	# Start restoring the question only after the entire exit step is complete.
	var question_restore := feedback_tween.tween_property(
		_quiz_question_label,
		"modulate:a",
		1.0,
		PORTRAIT_QUIZ_QUESTION_RESTORE_FADE_DURATION
	)
	question_restore.set_trans(Tween.TRANS_SINE)
	question_restore.set_ease(Tween.EASE_OUT)
	feedback_tween.tween_callback(
		Callable(self, "_finish_quiz_correct_question_feedback").bind(
			feedback_root,
			reward_source,
			speed_tier,
			previous_balance,
			final_balance
		)
	)

func _create_quiz_wrong_feedback() -> Dictionary:
	if _quiz_question_label == null or !is_instance_valid(_quiz_question_label):
		return {}
	var question_holder := _quiz_question_label.get_parent() as Control
	if question_holder == null or !is_instance_valid(question_holder):
		return {}

	_quiz_question_label.visible = false
	var feedback_root := Control.new()
	feedback_root.name = "QuizWrongFeedback"
	feedback_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	question_holder.add_child(feedback_root)
	feedback_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	feedback_root.z_index = _quiz_question_label.z_index + 1

	var feedback_visual := Control.new()
	feedback_visual.name = "QuizWrongFeedbackVisual"
	feedback_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feedback_visual.size = Vector2(132.0, 72.0)
	feedback_visual.position = (feedback_root.size - feedback_visual.size) * 0.5
	feedback_visual.pivot_offset = feedback_visual.size * 0.5
	feedback_visual.scale = PORTRAIT_QUIZ_FEEDBACK_START_SCALE
	feedback_visual.modulate.a = 0.0
	feedback_root.add_child(feedback_visual)

	var loss_label := Label.new()
	loss_label.name = "QuizWrongHeartLossLabel"
	loss_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	loss_label.position = Vector2.ZERO
	loss_label.size = Vector2(68.0, feedback_visual.size.y)
	loss_label.text = "-1"
	_style_quiz_feedback_label(loss_label, 42, Color.WHITE)
	loss_label.add_theme_font_override("font", UI_PRIMARY_FONT)
	feedback_visual.add_child(loss_label)

	var heart_icon := TextureRect.new()
	heart_icon.name = "QuizWrongHeartIcon"
	heart_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heart_icon.texture = LIFE_HEART_ICON_TEXTURE
	heart_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	heart_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	heart_icon.position = Vector2(70.0, 8.0)
	heart_icon.size = Vector2.ONE * 56.0
	feedback_visual.add_child(heart_icon)

	return {
		"root": feedback_root,
		"visual": feedback_visual,
	}

func _finish_quiz_wrong_question_feedback(feedback_root: Control) -> void:
	if (
		_quiz_screen_active
		and _quiz_question_label != null
		and is_instance_valid(_quiz_question_label)
	):
		_quiz_question_label.visible = true
		_quiz_question_label.modulate = Color.WHITE
		_show_quiz_continue_button(true)
	if feedback_root != null and is_instance_valid(feedback_root):
		feedback_root.queue_free()

func _play_quiz_wrong_question_feedback() -> void:
	var feedback: Dictionary = _create_quiz_wrong_feedback()
	var feedback_root := feedback.get("root") as Control
	var feedback_visual := feedback.get("visual") as Control
	if (
		feedback_root == null
		or !is_instance_valid(feedback_root)
		or feedback_visual == null
		or !is_instance_valid(feedback_visual)
	):
		if _quiz_question_label != null and is_instance_valid(_quiz_question_label):
			_quiz_question_label.visible = true
			_quiz_question_label.modulate = Color.WHITE
		_show_quiz_continue_button(true)
		return

	var feedback_tween := feedback_visual.create_tween()
	feedback_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var grow := feedback_tween.tween_property(
		feedback_visual,
		"scale",
		PORTRAIT_QUIZ_FEEDBACK_PEAK_SCALE,
		PORTRAIT_QUIZ_FEEDBACK_GROW_DURATION
	)
	grow.set_trans(Tween.TRANS_BACK)
	grow.set_ease(Tween.EASE_OUT)
	var fade_in := feedback_tween.parallel().tween_property(
		feedback_visual,
		"modulate:a",
		1.0,
		PORTRAIT_QUIZ_FEEDBACK_GROW_DURATION
	)
	fade_in.set_trans(Tween.TRANS_SINE)
	fade_in.set_ease(Tween.EASE_OUT)
	var settle := feedback_tween.tween_property(
		feedback_visual,
		"scale",
		Vector2.ONE,
		PORTRAIT_QUIZ_FEEDBACK_SETTLE_DURATION
	)
	settle.set_trans(Tween.TRANS_BOUNCE)
	settle.set_ease(Tween.EASE_OUT)
	feedback_tween.tween_interval(PORTRAIT_QUIZ_FEEDBACK_HOLD_DURATION)
	var exit_grow := feedback_tween.tween_property(
		feedback_visual,
		"scale",
		PORTRAIT_QUIZ_FEEDBACK_EXIT_PEAK_SCALE,
		PORTRAIT_QUIZ_FEEDBACK_EXIT_GROW_DURATION
	)
	exit_grow.set_trans(Tween.TRANS_QUAD)
	exit_grow.set_ease(Tween.EASE_OUT)
	_quiz_question_label.visible = true
	_quiz_question_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var exit_hide := feedback_tween.tween_property(
		feedback_visual,
		"scale",
		Vector2.ZERO,
		PORTRAIT_QUIZ_FEEDBACK_EXIT_HIDE_DURATION
	)
	exit_hide.set_trans(Tween.TRANS_BACK)
	exit_hide.set_ease(Tween.EASE_IN)
	var exit_fade := feedback_tween.parallel().tween_property(
		feedback_visual,
		"modulate:a",
		0.0,
		PORTRAIT_QUIZ_FEEDBACK_EXIT_HIDE_DURATION
	)
	exit_fade.set_trans(Tween.TRANS_SINE)
	exit_fade.set_ease(Tween.EASE_IN)
	var question_restore := feedback_tween.tween_property(
		_quiz_question_label,
		"modulate:a",
		1.0,
		PORTRAIT_QUIZ_QUESTION_RESTORE_FADE_DURATION
	)
	question_restore.set_trans(Tween.TRANS_SINE)
	question_restore.set_ease(Tween.EASE_OUT)
	feedback_tween.tween_callback(
		Callable(self, "_finish_quiz_wrong_question_feedback").bind(feedback_root)
	)

func _finish_quiz_correct_answer_bounce(
	button: Button,
	shadow_panel: Panel,
	finished_callback: Callable
) -> void:
	if button != null and is_instance_valid(button):
		button.scale = Vector2.ONE
	if shadow_panel != null and is_instance_valid(shadow_panel):
		shadow_panel.scale = Vector2.ONE
		shadow_panel.visible = true
	if finished_callback.is_valid():
		finished_callback.call()

func _play_quiz_correct_answer_bounce(
	button: Button,
	finished_callback: Callable = Callable()
) -> void:
	if button == null or !is_instance_valid(button):
		if finished_callback.is_valid():
			finished_callback.call()
		return

	# Never scale the FlashStageControl holder itself: its scale already contains
	# the viewport fit factor, so resetting it to Vector2.ONE shrinks the answer
	# and makes the bounce appear left-aligned on tall devices. Bounce the local
	# button face (and its shadow when visible) around their own centers instead.
	var press_tween_variant: Variant = button.get_meta(&"quiz_press_scale_tween", null)
	if press_tween_variant is Tween:
		var press_tween := press_tween_variant as Tween
		if press_tween.is_valid():
			press_tween.kill()

	var previous_tween_variant: Variant = button.get_meta(&"quiz_result_bounce_tween", null)
	if previous_tween_variant is Tween:
		var previous_tween := previous_tween_variant as Tween
		if previous_tween.is_valid():
			previous_tween.kill()

	button.scale = Vector2.ONE
	button.pivot_offset = button.size * 0.5
	var shadow_panel := _quiz_answer_shadow(button)
	if shadow_panel != null and is_instance_valid(shadow_panel):
		shadow_panel.scale = Vector2.ONE
		shadow_panel.pivot_offset = shadow_panel.size * 0.5
		# Result bounces are cleaner without the offset shadow moving underneath
		# the scaled button. Restore it only after the button fully settles.
		shadow_panel.visible = false

	var bounce_tween := button.create_tween()
	bounce_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var grow := bounce_tween.tween_property(button, "scale", Vector2.ONE * 1.10, 0.17)
	grow.set_trans(Tween.TRANS_BACK)
	grow.set_ease(Tween.EASE_OUT)

	var settle := bounce_tween.tween_property(button, "scale", Vector2.ONE, 0.34)
	settle.set_trans(Tween.TRANS_BOUNCE)
	settle.set_ease(Tween.EASE_OUT)
	bounce_tween.finished.connect(
		Callable(self, "_finish_quiz_correct_answer_bounce").bind(
			button,
			shadow_panel,
			finished_callback
		),
		CONNECT_ONE_SHOT
	)
	button.set_meta(&"quiz_result_bounce_tween", bounce_tween)

func _run_quiz_feedback_after_press_return(button: Button, callback: Callable) -> void:
	if button == null or !is_instance_valid(button):
		if callback.is_valid():
			callback.call()
		return
	# The answer's pressed signal can arrive while the release-scale tween is still
	# bringing the face back from 0.94 to 1.0. Wait for that exact tween instead
	# of starting result feedback on top of the press animation.
	if button.button_pressed:
		button.button_up.connect(
			Callable(self, "_run_quiz_feedback_after_press_return").bind(button, callback),
			CONNECT_ONE_SHOT
		)
		return
	var press_tween_variant: Variant = button.get_meta(&"quiz_press_scale_tween", null)
	if press_tween_variant is Tween:
		var press_tween := press_tween_variant as Tween
		if press_tween.is_valid() and press_tween.is_running():
			press_tween.finished.connect(callback, CONNECT_ONE_SHOT)
			return
	if callback.is_valid():
		callback.call()

func _finish_quiz_answer_text_shake(
	answer_label: Label,
	rest_position: Vector2,
	finished_callback: Callable
) -> void:
	if answer_label != null and is_instance_valid(answer_label):
		answer_label.position = rest_position
	if finished_callback.is_valid():
		finished_callback.call()

func _play_quiz_answer_text_shake(button: Button, finished_callback: Callable = Callable()) -> void:
	var answer_label := _quiz_answer_label(button)
	if answer_label == null or !is_instance_valid(answer_label):
		if finished_callback.is_valid():
			finished_callback.call()
		return
	var previous_tween_variant: Variant = answer_label.get_meta(&"quiz_text_shake_tween", null)
	if previous_tween_variant is Tween:
		var previous_tween := previous_tween_variant as Tween
		if previous_tween.is_valid():
			previous_tween.kill()
	var rest_position: Vector2 = answer_label.position
	var shake_tween := answer_label.create_tween()
	shake_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	# Keep the error cue readable but restrained: smaller travel and a slower
	# left/right cadence than the first implementation.
	for offset_x: float in [-5.0, 5.0, -4.0, 4.0, -2.0, 2.0, 0.0]:
		var shake_step := shake_tween.tween_property(
			answer_label,
			"position:x",
			rest_position.x + offset_x,
			PORTRAIT_QUIZ_WRONG_ANSWER_SHAKE_STEP_SECONDS
		)
		shake_step.set_trans(Tween.TRANS_QUAD)
		shake_step.set_ease(Tween.EASE_IN_OUT)
	shake_tween.finished.connect(
		Callable(self, "_finish_quiz_answer_text_shake").bind(
			answer_label,
			rest_position,
			finished_callback
		),
		CONNECT_ONE_SHOT
	)
	answer_label.set_meta(&"quiz_text_shake_tween", shake_tween)

func _quiz_correct_answer_index() -> int:
	return int(_quiz_current_question.get("correct_index", -1))

func _reveal_quiz_correct_answer(
	correct_index: int,
	show_continue_after_bounce: bool = true
) -> void:
	if !_quiz_screen_active or correct_index < 0 or correct_index >= _quiz_answer_buttons.size():
		return
	var correct_button := _quiz_answer_buttons[correct_index] as Button
	if correct_button == null or !is_instance_valid(correct_button):
		return
	_set_quiz_answer_fill(correct_button, PORTRAIT_QUIZ_ANSWER_CORRECT_COLOR)
	var finished_callback := Callable()
	if show_continue_after_bounce:
		finished_callback = Callable(self, "_show_quiz_continue_button").bind(true)
	_play_quiz_correct_answer_bounce(
		correct_button,
		finished_callback
	)

func _on_quiz_answer_selected(answer_index: int) -> void:
	if _quiz_answer_locked or !_quiz_screen_active:
		return
	var correct_index: int = _quiz_correct_answer_index()
	if (
		answer_index < 0
		or answer_index >= _quiz_answer_buttons.size()
		or correct_index < 0
		or correct_index >= _quiz_answer_buttons.size()
	):
		return
	var correct_answer: bool = answer_index == correct_index
	var speed_tier: int = _take_quiz_speed_tier()
	if !correct_answer:
		speed_tier = PORTRAIT_QUIZ_SPEED_NONE
	var speed_reward_amount: int = _quiz_speed_reward_amount(speed_tier)
	var previous_star_balance: int = GameState.get_stars()
	var final_star_balance: int = previous_star_balance
	if speed_reward_amount > 0:
		final_star_balance = GameState.add_stars(speed_reward_amount, true)
		# The bonus is already durable, but its HUD value waits for the visual
		# collection that starts after the original question returns.
		_set_stage_reward_animated_balance(
			float(previous_star_balance),
			GameState.STAGE_REWARD_STARS
		)
	_quiz_answer_locked = true
	_quiz_selected_answer_index = answer_index
	_hide_quiz_exit_button()
	if _quiz_single_player_embedded:
		_record_single_player_quiz_result(correct_answer)
	_disable_quiz_answer_buttons()
	_hide_quiz_hint_buttons()

	var selected_button := _quiz_answer_buttons[answer_index] as Button
	if selected_button == null or !is_instance_valid(selected_button):
		return
	if correct_answer:
		_set_quiz_answer_fill(selected_button, PORTRAIT_QUIZ_ANSWER_CORRECT_COLOR)
		_play_quiz_correct_answer_bounce(selected_button)
		_play_quiz_correct_question_feedback(
			speed_tier,
			previous_star_balance,
			final_star_balance
		)
		return

	_set_quiz_answer_fill(selected_button, PORTRAIT_QUIZ_ANSWER_WRONG_COLOR)
	if _quiz_single_player_embedded:
		_play_quiz_wrong_question_feedback()
	_run_quiz_feedback_after_press_return(
		selected_button,
		Callable(self, "_play_quiz_answer_text_shake").bind(
			selected_button,
			Callable(self, "_reveal_quiz_correct_answer").bind(
				correct_index,
				!_quiz_single_player_embedded
			)
		)
	)

func _restore_quiz_answer_result_state() -> void:
	if !_quiz_answer_locked:
		return
	_hide_quiz_exit_button()
	var correct_index: int = _quiz_correct_answer_index()
	if correct_index < 0 or correct_index >= _quiz_answer_buttons.size():
		return
	_disable_quiz_answer_buttons()
	if (
		_quiz_selected_answer_index >= 0
		and _quiz_selected_answer_index < _quiz_answer_buttons.size()
	):
		var selected_button := _quiz_answer_buttons[_quiz_selected_answer_index] as Button
		if selected_button != null and is_instance_valid(selected_button):
			_set_quiz_answer_fill(
				selected_button,
				PORTRAIT_QUIZ_ANSWER_CORRECT_COLOR
				if _quiz_selected_answer_index == correct_index
				else PORTRAIT_QUIZ_ANSWER_WRONG_COLOR
			)
	if _quiz_selected_answer_index != correct_index:
		var correct_button := _quiz_answer_buttons[correct_index] as Button
		if correct_button != null and is_instance_valid(correct_button):
			_set_quiz_answer_fill(correct_button, PORTRAIT_QUIZ_ANSWER_CORRECT_COLOR)
	_show_quiz_continue_button(false)

func _portrait_quiz_answer_start_y(answer_count: int) -> float:
	# Keep the whole answer stack tied to the hint row. Because answers and hints
	# are rendered in the same bottom-attached group, this remains a true 40 px
	# stage gap on tall screens instead of growing with the extra screen height.
	var visible_answer_count: int = clampi(answer_count, 0, 4)
	if visible_answer_count <= 0:
		return _portrait_quiz_hint_button_y()
	var answer_block_height: float = (
		PORTRAIT_QUIZ_ANSWER_BUTTON_SIZE.y
		+ float(visible_answer_count - 1) * PORTRAIT_QUIZ_ANSWER_STEP_Y
	)
	return (
		_portrait_quiz_hint_button_y()
		- PORTRAIT_QUIZ_ANSWER_HINT_GAP
		- answer_block_height
	)

func _portrait_quiz_hint_button_y() -> float:
	# Quiz has no keyboard, but its hint row should sit at exactly the same stage
	# position as the hint row in the normal single-player guessing screen. Keep
	# this independent of GameState.current_mode so visiting Two Player first does
	# not move the quiz controls down.
	var viewport_size: Vector2 = get_viewport_rect().size
	var keyboard_scale: float = PORTRAIT_STAGE_LAYOUT.adaptive_ui_scale(
		viewport_size,
		PORTRAIT_GAME_KEYBOARD_MAX_SCALE
	)
	var columns: int = 6
	var alphabet_count: int = Database.get_alphabet().size()
	var keyboard_rows: int = int(ceil(float(alphabet_count) / float(columns)))
	var keyboard_step_y: float = 48.0 * keyboard_scale
	var keyboard_key_height: float = 46.0 * keyboard_scale
	var keyboard_height: float = (
		keyboard_key_height
		+ float(maxi(0, keyboard_rows - 1)) * keyboard_step_y
	)
	var keyboard_start_y: float = (
		PORTRAIT_FOOTER_Y - _portrait_ad_banner_height_stage()
	) - 24.0 - keyboard_height + PORTRAIT_GAME_INPUT_BLOCK_DOWN_SHIFT
	var keyboard_bottom_y: float = keyboard_start_y + keyboard_height
	var hint_center_y: float = (
		keyboard_bottom_y + PORTRAIT_GAME_HINT_KEYBOARD_GAP
	) * PORTRAIT_GAME_ACTION_Y_SCALE
	return hint_center_y - (PORTRAIT_GAME_HINT_BUTTON_SIZE.y - 58.0) * 0.5

func _stage_portrait_quiz_hint_counter(button: Control, hint_key: String) -> void:
	if button == null or !is_instance_valid(button):
		return
	var free_size := Vector2(PORTRAIT_GAME_HINT_COUNTER_SIZE, PORTRAIT_GAME_HINT_COUNTER_SIZE)
	var free_rect := Rect2(
		Vector2(
			button.size.x - free_size.x * 0.82,
			-free_size.y * 0.18
		),
		free_size
	)
	var price_size := Vector2(58.0, PORTRAIT_GAME_HINT_COUNTER_SIZE)
	var price_rect := Rect2(
		Vector2(
			button.size.x - price_size.x * 0.82 + 6.0,
			-price_size.y * 0.18
		),
		price_size
	)
	var count: int = GameState.get_hint_count(hint_key)
	var component := _create_portrait_button_badge(button, {
		"coin_rect": price_rect,
		"ad_rect": free_rect,
		"free_rect": free_rect,
		"price": GameState.get_hint_cost(hint_key),
		"count": count,
		"state": (
			PORTRAIT_BUTTON_BADGE_STATE_FREE
			if count > 0
			else PORTRAIT_BUTTON_BADGE_STATE_COINS
		),
	})
	button.set_meta(&"quiz_hint_key", hint_key)
	button.set_meta(&"quiz_hint_badge_component", component)

func _refresh_portrait_quiz_hint_counter(button: Control, hint_key: String) -> void:
	if button == null or !is_instance_valid(button):
		return
	var component_variant: Variant = button.get_meta(&"quiz_hint_badge_component", {})
	if !(component_variant is Dictionary):
		return
	var component: Dictionary = component_variant
	var count: int = GameState.get_hint_count(hint_key)
	_set_portrait_button_badge_state(
		component,
		(
			PORTRAIT_BUTTON_BADGE_STATE_FREE
			if count > 0
			else PORTRAIT_BUTTON_BADGE_STATE_COINS
		),
		{
			"count": count,
			"price": GameState.get_hint_cost(hint_key),
		}
	)

func _pay_for_quiz_hint(hint_key: String, button: Control) -> bool:
	if !GameState.can_pay_for_hint(hint_key):
		_open_coin_store(Callable(self, "_return_to_quiz_from_coin_store"))
		return false
	var payment: int = GameState.pay_for_hint(
		hint_key,
		false
	)
	if payment == GameState.HintPayment.FAILED:
		_open_coin_store(Callable(self, "_return_to_quiz_from_coin_store"))
		return false
	_refresh_portrait_quiz_hint_counter(button, hint_key)
	return true

func _return_to_quiz_from_coin_store() -> void:
	# The coin store is a modal overlay, so closing it must not rebuild the quiz
	# screen or replay its entrance choreography. Refresh only the UI values that
	# may have changed while the popup was open and leave every quiz node in place.
	if !_quiz_screen_active:
		return
	var balance_text: String = _soft_currency_balance_text(GameState.get_soft_currency())
	for balance_node: Node in get_tree().get_nodes_in_group(&"soft_currency_balance_label"):
		var balance_label := balance_node as Label
		if balance_label != null and is_instance_valid(balance_label):
			balance_label.text = balance_text
	for hint_button: Control in _quiz_hint_buttons:
		if hint_button == null or !is_instance_valid(hint_button):
			continue
		var hint_key_variant: Variant = hint_button.get_meta(&"quiz_hint_key", "")
		var hint_key: String = str(hint_key_variant)
		if !hint_key.is_empty():
			_refresh_portrait_quiz_hint_counter(hint_button, hint_key)

func _refresh_quiz_question_in_place() -> bool:
	if (
		!_quiz_screen_active
		or _quiz_question_label == null
		or !is_instance_valid(_quiz_question_label)
		or _quiz_continue_button == null
		or !is_instance_valid(_quiz_continue_button)
	):
		return false
	var answers_variant: Variant = _quiz_current_question.get("answers", [])
	if !(answers_variant is Array):
		return false
	var answers: Array = Array(answers_variant)
	var visible_answer_count: int = mini(4, answers.size())
	if visible_answer_count != _quiz_answer_buttons.size():
		return false

	_quiz_entrance_generation += 1
	var question_text: String = str(
		_quiz_current_question.get("question", "")
	).strip_edges()
	_quiz_question_label.text = question_text
	_quiz_question_label.add_theme_font_size_override(
		"font_size",
		_quiz_question_font_size(question_text)
	)
	_quiz_question_label.modulate = Color.WHITE

	for answer_index in range(visible_answer_count):
		var answer_button := _quiz_answer_buttons[answer_index] as Button
		if answer_button == null or !is_instance_valid(answer_button):
			return false
		var answer_text: String = str(answers[answer_index]).strip_edges()
		_prepare_quiz_answer_for_replacement(answer_button, answer_text, 0.0)
		answer_button.disabled = false
		answer_button.mouse_filter = Control.MOUSE_FILTER_STOP

	_quiz_continue_button.visible = false
	_quiz_continue_button.modulate.a = 1.0
	_quiz_continue_button.set("attention_bounce_enabled", false)
	for hint_button: Control in _quiz_hint_buttons:
		if hint_button == null or !is_instance_valid(hint_button):
			continue
		hint_button.visible = true
		hint_button.modulate = Color.WHITE
		hint_button.mouse_filter = Control.MOUSE_FILTER_STOP
		hint_button.set("button_disabled", false)
		var hint_key: String = str(hint_button.get_meta(&"quiz_hint_key", ""))
		if !hint_key.is_empty():
			_refresh_portrait_quiz_hint_counter(hint_button, hint_key)
	_mark_quiz_question_ready()
	return true

func _on_quiz_continue_pressed() -> void:
	if !_quiz_screen_active or _quiz_selected_theme_index < 0:
		return
	if _quiz_single_player_embedded:
		if !game_finished:
			return
		_quiz_single_player_embedded = false
		_quiz_mode_active = false
		_quiz_screen_active = false
		_show_single_player_reward_chain_screen()
		return
	var questions: Array = Database.get_quiz_questions_by_theme_index(_quiz_selected_theme_index)
	if questions.is_empty():
		return

	# Prefer a different question from the current theme. Only fall back to the
	# current one when the theme contains a single available question.
	var current_id: int = int(_quiz_current_question.get("id", -1))
	var current_text: String = str(_quiz_current_question.get("question", ""))
	var candidates: Array = []
	for question_variant: Variant in questions:
		if !(question_variant is Dictionary):
			continue
		var question: Dictionary = question_variant
		var same_question: bool = (
			(current_id >= 0 and int(question.get("id", -2)) == current_id)
			or (current_id < 0 and str(question.get("question", "")) == current_text)
		)
		if !same_question:
			candidates.append(question)

	var next_question: Dictionary
	if !candidates.is_empty():
		next_question = candidates[randi_range(0, candidates.size() - 1)]
	else:
		next_question = questions[randi_range(0, questions.size() - 1)]

	_quiz_current_question = next_question.duplicate(true)
	_quiz_answer_locked = false
	_quiz_selected_answer_index = -1
	_quiz_fifty_fifty_used = false
	_quiz_fifty_fifty_hidden_indices.clear()
	_quiz_replace_question_used = false
	_quiz_question_replacing = false
	if !_refresh_quiz_question_in_place():
		_show_quiz_game_screen()

func _on_quiz_continue_trigger_pressed() -> void:
	var correct_answer_selected: bool = (
		_quiz_selected_answer_index >= 0
		and _quiz_selected_answer_index == _quiz_correct_answer_index()
	)
	if correct_answer_selected:
		_run_action_after_interstitial_if_ready(
			Callable(self, "_on_quiz_continue_pressed")
		)
	else:
		_on_quiz_continue_pressed()

func _finish_quiz_fifty_fifty_removal(button: Button, shadow_panel: Panel) -> void:
	if button != null and is_instance_valid(button):
		button.scale = Vector2.ONE
		button.visible = false
		button.modulate.a = 1.0
	if shadow_panel != null and is_instance_valid(shadow_panel):
		shadow_panel.scale = Vector2.ONE
		shadow_panel.visible = false
		shadow_panel.modulate.a = 1.0

func _play_quiz_fifty_fifty_removal(button: Button) -> void:
	if button == null or !is_instance_valid(button):
		return
	button.disabled = true
	button.modulate.a = 1.0
	button.pivot_offset = button.size * 0.5
	var shadow_panel := _quiz_answer_shadow(button)
	if shadow_panel != null and is_instance_valid(shadow_panel):
		shadow_panel.modulate.a = 1.0
		shadow_panel.scale = Vector2.ONE
		shadow_panel.pivot_offset = shadow_panel.size * 0.5
		# 50/50 removal also runs without a shadow for the full bounce/fade.
		shadow_panel.visible = false

	var previous_tween_variant: Variant = button.get_meta(&"quiz_fifty_fifty_tween", null)
	if previous_tween_variant is Tween:
		var previous_tween := previous_tween_variant as Tween
		if previous_tween.is_valid():
			previous_tween.kill()

	# Both eliminated answers run this animation in the same frame. Keep the
	# bounce restrained and slower than before, while fading both the face and
	# shadow out through alpha during the collapse.
	var tween := button.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var grow := tween.tween_property(button, "scale", Vector2.ONE * 1.10, 0.14)
	grow.set_trans(Tween.TRANS_BACK)
	grow.set_ease(Tween.EASE_OUT)

	var vanish := tween.tween_property(button, "scale", Vector2.ONE * 0.90, 0.23)
	vanish.set_trans(Tween.TRANS_QUAD)
	vanish.set_ease(Tween.EASE_IN)
	var face_fade := tween.parallel().tween_property(button, "modulate:a", 0.0, 0.23)
	face_fade.set_trans(Tween.TRANS_SINE)
	face_fade.set_ease(Tween.EASE_IN)
	tween.finished.connect(
		Callable(self, "_finish_quiz_fifty_fifty_removal").bind(button, shadow_panel),
		CONNECT_ONE_SHOT
	)
	button.set_meta(&"quiz_fifty_fifty_tween", tween)

func _apply_quiz_fifty_fifty_hidden_state() -> void:
	for hidden_index: int in _quiz_fifty_fifty_hidden_indices:
		if hidden_index < 0 or hidden_index >= _quiz_answer_buttons.size():
			continue
		var answer_button := _quiz_answer_buttons[hidden_index] as Button
		if answer_button == null or !is_instance_valid(answer_button):
			continue
		answer_button.disabled = true
		answer_button.visible = false
		var shadow_panel := _quiz_answer_shadow(answer_button)
		if shadow_panel != null and is_instance_valid(shadow_panel):
			shadow_panel.visible = false

func _on_quiz_fifty_fifty_pressed() -> void:
	if _quiz_answer_locked or _quiz_fifty_fifty_used or !_quiz_screen_active:
		return
	var correct_index: int = _quiz_correct_answer_index()
	if correct_index < 0 or correct_index >= _quiz_answer_buttons.size():
		return

	var wrong_indices: Array = []
	for answer_index: int in range(_quiz_answer_buttons.size()):
		if answer_index != correct_index:
			wrong_indices.append(answer_index)
	if wrong_indices.size() < 2:
		return
	wrong_indices.shuffle()

	var fifty_hint_button: Control = null
	if !_quiz_hint_buttons.is_empty():
		fifty_hint_button = _quiz_hint_buttons[0]
	if !_pay_for_quiz_hint(GameState.HINT_QUIZ_FIFTY_FIFTY, fifty_hint_button):
		return

	_quiz_fifty_fifty_used = true
	_quiz_fifty_fifty_hidden_indices = [wrong_indices[0], wrong_indices[1]]
	if _quiz_single_player_embedded:
		_persist_active_single_player_quiz_session()
	else:
		GameState.save_game()
	if !_quiz_hint_buttons.is_empty():
		var fifty_button: Control = _quiz_hint_buttons[0]
		if fifty_button != null and is_instance_valid(fifty_button):
			fifty_button.set("button_disabled", true)

	# Launch both removal tweens in the same frame so the two wrong answers
	# bounce out simultaneously.
	for hidden_index: int in _quiz_fifty_fifty_hidden_indices:
		var answer_button := _quiz_answer_buttons[hidden_index] as Button
		if answer_button != null and is_instance_valid(answer_button):
			_play_quiz_fifty_fifty_removal(answer_button)

func _quiz_replacement_question() -> Dictionary:
	var questions: Array = Database.get_quiz_questions_by_theme_index(_quiz_selected_theme_index)
	if questions.size() <= 1:
		return {}
	var current_id: int = int(_quiz_current_question.get("id", -1))
	var current_text: String = str(_quiz_current_question.get("question", ""))
	var target_difficulty: float = (
		_quiz_single_player_target_difficulty
		if _quiz_single_player_embedded
		else float(_quiz_current_question.get("difficulty", 0.5))
	)
	target_difficulty = minf(target_difficulty, SINGLE_PLAYER_QUIZ_TARGET_MAXIMUM)
	var unseen_candidates: Array = []
	var fallback_candidates: Array = []
	for question_variant: Variant in questions:
		if !(question_variant is Dictionary):
			continue
		var question: Dictionary = question_variant
		var question_id: int = int(question.get("id", -1))
		var same_question: bool = (
			(current_id >= 0 and question_id == current_id)
			or (current_id < 0 and str(question.get("question", "")) == current_text)
		)
		if same_question:
			continue
		fallback_candidates.append(question)
		if (
			!_quiz_single_player_embedded
			or !GameState.has_single_player_question_been_seen(
				Database.current_language,
				_quiz_selected_theme_index,
				question_id
			)
		):
			unseen_candidates.append(question)
	var candidates: Array = unseen_candidates
	if candidates.is_empty():
		candidates = fallback_candidates
	if candidates.is_empty():
		return {}

	var nearest_distance: float = INF
	for question_variant: Variant in candidates:
		var question: Dictionary = question_variant
		nearest_distance = minf(
			nearest_distance,
			absf(float(question.get("difficulty", 0.5)) - target_difficulty)
		)
	var close_candidates: Array = []
	var allowed_distance: float = nearest_distance + 0.08
	for question_variant: Variant in candidates:
		var question: Dictionary = question_variant
		var distance: float = absf(float(question.get("difficulty", 0.5)) - target_difficulty)
		if distance <= allowed_distance:
			close_candidates.append(question)
	var pool: Array = close_candidates if !close_candidates.is_empty() else candidates
	return (pool[randi_range(0, pool.size() - 1)] as Dictionary).duplicate(true)

func _set_quiz_hint_buttons_temporarily_disabled(disabled: bool) -> void:
	for hint_index: int in range(_quiz_hint_buttons.size()):
		var hint_button: Control = _quiz_hint_buttons[hint_index]
		if hint_button == null or !is_instance_valid(hint_button):
			continue
		var should_disable: bool = disabled
		if !disabled:
			should_disable = (
				(hint_index == 0 and _quiz_fifty_fifty_used)
				or (hint_index == 1 and _quiz_replace_question_used)
			)
		hint_button.set("button_disabled", should_disable)

func _prepare_quiz_answer_for_replacement(
	button: Button,
	answer_text: String,
	right_offset: float
) -> void:
	if button == null or !is_instance_valid(button):
		return
	var press_tween_variant: Variant = button.get_meta(&"quiz_press_scale_tween", null)
	if press_tween_variant is Tween:
		var press_tween := press_tween_variant as Tween
		if press_tween.is_valid():
			press_tween.kill()
	var fifty_tween_variant: Variant = button.get_meta(&"quiz_fifty_fifty_tween", null)
	if fifty_tween_variant is Tween:
		var fifty_tween := fifty_tween_variant as Tween
		if fifty_tween.is_valid():
			fifty_tween.kill()
	var result_tween_variant: Variant = button.get_meta(&"quiz_result_bounce_tween", null)
	if result_tween_variant is Tween:
		var result_tween := result_tween_variant as Tween
		if result_tween.is_valid():
			result_tween.kill()

	button.visible = true
	button.disabled = true
	button.scale = Vector2.ONE
	button.modulate = Color.WHITE
	button.position.x = right_offset
	button.set_meta(&"quiz_answer_keep_shadow_hidden", false)
	_set_quiz_answer_fill(button, Color.WHITE)
	var answer_label := _quiz_answer_label(button)
	if answer_label != null and is_instance_valid(answer_label):
		var shake_tween_variant: Variant = answer_label.get_meta(&"quiz_text_shake_tween", null)
		if shake_tween_variant is Tween:
			var shake_tween := shake_tween_variant as Tween
			if shake_tween.is_valid():
				shake_tween.kill()
		answer_label.text = answer_text
		answer_label.position.x = 18.0
		answer_label.modulate = Color.WHITE

	var shadow_panel := _quiz_answer_shadow(button)
	if shadow_panel != null and is_instance_valid(shadow_panel):
		shadow_panel.visible = true
		shadow_panel.scale = Vector2.ONE
		shadow_panel.modulate = Color.WHITE
		shadow_panel.position.x = right_offset

func _on_quiz_replace_question_pressed() -> void:
	if (
		!_quiz_screen_active
		or _quiz_answer_locked
		or _quiz_replace_question_used
		or _quiz_question_replacing
	):
		return
	var next_question: Dictionary = _quiz_replacement_question()
	if next_question.is_empty():
		return
	if _quiz_question_label == null or !is_instance_valid(_quiz_question_label):
		return
	var replace_hint_button: Control = null
	if _quiz_hint_buttons.size() > 1:
		replace_hint_button = _quiz_hint_buttons[1]
	if !_pay_for_quiz_hint(GameState.HINT_QUIZ_REPLACE_QUESTION, replace_hint_button):
		return

	_quiz_replace_question_used = true
	_quiz_question_replacing = true
	_quiz_current_question = next_question
	if _quiz_single_player_embedded:
		var replacement_id: int = int(_quiz_current_question.get("id", -1))
		if replacement_id >= 0:
			GameState.set_single_level_question_id(
				Database.current_language,
				single_player_active_level_index,
				replacement_id,
				false
			)
			GameState.mark_single_player_question_seen(
				Database.current_language,
				_quiz_selected_theme_index,
				replacement_id,
				false
			)
			_invalidate_single_player_level_cache()
		_persist_active_single_player_quiz_session()
	else:
		GameState.save_game()
	_set_quiz_hint_buttons_temporarily_disabled(true)
	for answer_control: Control in _quiz_answer_buttons:
		var answer_button := answer_control as Button
		if answer_button != null and is_instance_valid(answer_button):
			answer_button.disabled = true

	# Fade the old question out while the current answers travel off-screen to
	# the left. Hidden 50/50 answers simply stay hidden until the new set arrives.
	var slide_distance: float = maxf(get_viewport_rect().size.x, 480.0)
	var outgoing := create_tween()
	outgoing.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	outgoing.set_parallel(true)
	var question_fade_out := outgoing.tween_property(
		_quiz_question_label,
		"modulate:a",
		0.0,
		0.20
	)
	question_fade_out.set_trans(Tween.TRANS_SINE)
	question_fade_out.set_ease(Tween.EASE_IN)
	var outgoing_answer_order: int = 0
	for answer_control: Control in _quiz_answer_buttons:
		var answer_button := answer_control as Button
		if answer_button == null or !is_instance_valid(answer_button) or !answer_button.visible:
			continue
		var answer_delay: float = float(outgoing_answer_order) * PORTRAIT_QUIZ_ENTRANCE_ANSWER_STAGGER
		var answer_out := outgoing.tween_property(
			answer_button,
			"position:x",
			-slide_distance,
			0.26
		)
		answer_out.set_delay(answer_delay)
		answer_out.set_trans(Tween.TRANS_QUAD)
		answer_out.set_ease(Tween.EASE_IN)
		var shadow_panel := _quiz_answer_shadow(answer_button)
		if shadow_panel != null and is_instance_valid(shadow_panel) and shadow_panel.visible:
			var shadow_out := outgoing.tween_property(
				shadow_panel,
				"position:x",
				-slide_distance,
				0.26
			)
			shadow_out.set_delay(answer_delay)
			shadow_out.set_trans(Tween.TRANS_QUAD)
			shadow_out.set_ease(Tween.EASE_IN)
		outgoing_answer_order += 1
	await outgoing.finished
	if !_quiz_screen_active or _quiz_question_label == null or !is_instance_valid(_quiz_question_label):
		_quiz_question_replacing = false
		return

	_quiz_answer_locked = false
	_quiz_selected_answer_index = -1
	_quiz_fifty_fifty_used = false
	_quiz_fifty_fifty_hidden_indices.clear()
	_persist_active_single_player_quiz_session()

	var new_question_text: String = str(_quiz_current_question.get("question", "")).strip_edges()
	_quiz_question_label.text = new_question_text
	_quiz_question_label.add_theme_font_size_override(
		"font_size",
		_quiz_question_font_size(new_question_text)
	)
	_quiz_question_label.modulate.a = 0.0

	var answers_variant: Variant = _quiz_current_question.get("answers", [])
	var answers: Array = Array(answers_variant) if answers_variant is Array else []
	for answer_index: int in range(_quiz_answer_buttons.size()):
		var answer_button := _quiz_answer_buttons[answer_index] as Button
		if answer_button == null or !is_instance_valid(answer_button):
			continue
		if answer_index >= answers.size():
			answer_button.visible = false
			continue
		_prepare_quiz_answer_for_replacement(
			answer_button,
			str(answers[answer_index]).strip_edges(),
			slide_distance
		)

	# Bring the new answers in from the right while the replacement question fades
	# back in. The panel itself stays fixed so the transition reads as content swap.
	var incoming := create_tween()
	incoming.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	incoming.set_parallel(true)
	var question_fade_in := incoming.tween_property(
		_quiz_question_label,
		"modulate:a",
		1.0,
		0.24
	)
	question_fade_in.set_trans(Tween.TRANS_SINE)
	question_fade_in.set_ease(Tween.EASE_OUT)
	var incoming_answer_order: int = 0
	for answer_control: Control in _quiz_answer_buttons:
		var answer_button := answer_control as Button
		if answer_button == null or !is_instance_valid(answer_button) or !answer_button.visible:
			continue
		var answer_delay: float = float(incoming_answer_order) * PORTRAIT_QUIZ_ENTRANCE_ANSWER_STAGGER
		var answer_in := incoming.tween_property(answer_button, "position:x", 0.0, 0.34)
		answer_in.set_delay(answer_delay)
		answer_in.set_trans(Tween.TRANS_CUBIC)
		answer_in.set_ease(Tween.EASE_OUT)
		var shadow_panel := _quiz_answer_shadow(answer_button)
		if shadow_panel != null and is_instance_valid(shadow_panel):
			var shadow_in := incoming.tween_property(shadow_panel, "position:x", 0.0, 0.34)
			shadow_in.set_delay(answer_delay)
			shadow_in.set_trans(Tween.TRANS_CUBIC)
			shadow_in.set_ease(Tween.EASE_OUT)
		incoming_answer_order += 1
	await incoming.finished
	if !_quiz_screen_active:
		_quiz_question_replacing = false
		return

	for answer_control: Control in _quiz_answer_buttons:
		var answer_button := answer_control as Button
		if answer_button != null and is_instance_valid(answer_button) and answer_button.visible:
			answer_button.disabled = false
	_quiz_question_replacing = false
	_set_quiz_hint_buttons_temporarily_disabled(false)
	_mark_quiz_question_ready()

func _stage_portrait_quiz_hint_buttons() -> void:
	# Quiz uses dedicated 50/50 and question-replacement controls. Both are wired
	# directly in this screen and keep independent per-question used states.
	var button_width: float = PORTRAIT_GAME_HINT_BUTTON_SIZE.x
	var total_width: float = button_width * 2.0 + PORTRAIT_QUIZ_HINT_GAP
	var first_x: float = (PORTRAIT_STAGE_SIZE.x - total_width) * 0.5
	var hint_button_y: float = _portrait_quiz_hint_button_y()
	var open_button := _stage_round_button(
		Rect2(first_x, hint_button_y, button_width, PORTRAIT_GAME_HINT_BUTTON_SIZE.y),
		Callable(self, "_on_quiz_fifty_fifty_pressed"),
		"",
		false,
		false,
		0.0,
		LONG_BUTTON_COLOR_ORANGE
	)
	var remove_button := _stage_round_button(
		Rect2(
			first_x + button_width + PORTRAIT_QUIZ_HINT_GAP,
			hint_button_y,
			button_width,
			PORTRAIT_GAME_HINT_BUTTON_SIZE.y
		),
		Callable(self, "_on_quiz_replace_question_pressed"),
		"",
		false,
		false,
		0.0,
		LONG_BUTTON_COLOR_ORANGE
	)
	# Quiz mode uses its own hint imagery: 50/50 and question replacement.
	_stage_portrait_hint_art(open_button, PORTRAIT_QUIZ_HINT_FIFTY_FIFTY_ICON, false)
	_stage_portrait_hint_art(remove_button, PORTRAIT_QUIZ_HINT_REPLACE_QUESTION_ICON, false)
	_stage_portrait_quiz_hint_counter(open_button, GameState.HINT_QUIZ_FIFTY_FIFTY)
	_stage_portrait_quiz_hint_counter(remove_button, GameState.HINT_QUIZ_REPLACE_QUESTION)
	_quiz_hint_buttons = [open_button, remove_button]
	if _quiz_fifty_fifty_used:
		open_button.set("button_disabled", true)
	if _quiz_replace_question_used or _quiz_question_replacing:
		remove_button.set("button_disabled", true)

func _stage_portrait_quiz_continue_button() -> Control:
	# Use the exact same long orange action component and authored action-row rect
	# as the in-place result screen from the normal word-guessing mode.
	var continue_button := _stage_main_button(
		_portrait_in_place_result_button_rect(),
		Callable(self, "_on_quiz_continue_trigger_pressed"),
		tr("COMMON_CONTINUE"),
		22,
		false,
		0.32,
		false,
		false,
		false,
		LONG_BUTTON_COLOR_ORANGE
	)
	continue_button.z_index = 50
	continue_button.visible = false
	continue_button.set("attention_bounce_enabled", false)
	return continue_button

func _quiz_entrance_is_current(generation: int) -> bool:
	return generation == _quiz_entrance_generation and _quiz_screen_active

func _prepare_quiz_screen_entrance(
	quiz_background: Control,
	question_shadow: Control,
	question_panel: Control,
	question_label: Label
) -> void:
	_quiz_entrance_generation += 1
	var generation: int = _quiz_entrance_generation
	if quiz_background == null or !is_instance_valid(quiz_background):
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var fit_scale: float = PORTRAIT_STAGE_LAYOUT.fit_scale(viewport_size)
	var panel_offset: float = PORTRAIT_QUIZ_ENTRANCE_PANEL_OFFSET * fit_scale
	var slide_distance: float = maxf(viewport_size.x, PORTRAIT_STAGE_SIZE.x)

	quiz_background.modulate.a = 0.0
	if question_shadow != null and is_instance_valid(question_shadow):
		question_shadow.set_meta(&"quiz_entrance_rest_y", question_shadow.position.y)
		question_shadow.position.y -= panel_offset
		question_shadow.modulate.a = 0.0
	if question_panel != null and is_instance_valid(question_panel):
		question_panel.set_meta(&"quiz_entrance_rest_y", question_panel.position.y)
		question_panel.position.y -= panel_offset
		question_panel.modulate.a = 0.0
	if question_label != null and is_instance_valid(question_label):
		question_label.modulate.a = 0.0

	for answer_control: Control in _quiz_answer_buttons:
		var answer_button := answer_control as Button
		if answer_button == null or !is_instance_valid(answer_button) or !answer_button.visible:
			continue
		answer_button.set_meta(&"quiz_entrance_rest_mouse_filter", answer_button.mouse_filter)
		answer_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		answer_button.position.x = slide_distance
		var shadow_panel := _quiz_answer_shadow(answer_button)
		if shadow_panel != null and is_instance_valid(shadow_panel) and shadow_panel.visible:
			shadow_panel.position.x = slide_distance

	for hint_button: Control in _quiz_hint_buttons:
		if hint_button == null or !is_instance_valid(hint_button):
			continue
		var rest_scale: Vector2 = hint_button.get("visual_scale")
		hint_button.set_meta(&"quiz_entrance_rest_visual_scale", rest_scale)
		hint_button.set_meta(&"quiz_entrance_rest_mouse_filter", hint_button.mouse_filter)
		hint_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hint_button.modulate.a = 0.0
		hint_button.set(
			"visual_scale",
			rest_scale * PORTRAIT_GAME_HINT_ENTRANCE_START_SCALE
		)

	call_deferred(
		"_play_quiz_screen_entrance",
		generation,
		quiz_background,
		question_shadow,
		question_panel,
		question_label
	)

func _play_quiz_screen_entrance(
	generation: int,
	quiz_background: Control,
	question_shadow: Control,
	question_panel: Control,
	question_label: Label
) -> void:
	if !_quiz_entrance_is_current(generation):
		return
	if quiz_background == null or !is_instance_valid(quiz_background):
		return

	# Match the grand-prize reveal: the blue patterned backdrop fades in as one
	# complete layer before any quiz content is introduced.
	var background_tween := quiz_background.create_tween()
	background_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var backdrop_fade := background_tween.tween_property(
		quiz_background,
		"modulate:a",
		1.0,
		PORTRAIT_QUIZ_ENTRANCE_BACKGROUND_FADE_DURATION
	)
	backdrop_fade.set_trans(Tween.TRANS_SINE)
	backdrop_fade.set_ease(Tween.EASE_IN_OUT)
	await background_tween.finished
	if !_quiz_entrance_is_current(generation):
		return

	# The question card descends from above while fading in. Answers enter as a
	# short cascade from right to left: the top answer starts immediately and
	# every lower answer follows a little later.
	var content_tween := create_tween()
	content_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	content_tween.set_parallel(true)
	if question_shadow != null and is_instance_valid(question_shadow):
		content_tween.tween_property(
			question_shadow,
			"position:y",
			float(question_shadow.get_meta(&"quiz_entrance_rest_y", question_shadow.position.y)),
			PORTRAIT_QUIZ_ENTRANCE_PANEL_DURATION
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		content_tween.tween_property(
			question_shadow,
			"modulate:a",
			1.0,
			PORTRAIT_QUIZ_ENTRANCE_PANEL_DURATION
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if question_panel != null and is_instance_valid(question_panel):
		content_tween.tween_property(
			question_panel,
			"position:y",
			float(question_panel.get_meta(&"quiz_entrance_rest_y", question_panel.position.y)),
			PORTRAIT_QUIZ_ENTRANCE_PANEL_DURATION
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		content_tween.tween_property(
			question_panel,
			"modulate:a",
			1.0,
			PORTRAIT_QUIZ_ENTRANCE_PANEL_DURATION
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var visible_answer_order: int = 0
	for answer_control: Control in _quiz_answer_buttons:
		var answer_button := answer_control as Button
		if answer_button == null or !is_instance_valid(answer_button) or !answer_button.visible:
			continue
		var answer_delay: float = float(visible_answer_order) * PORTRAIT_QUIZ_ENTRANCE_ANSWER_STAGGER
		var answer_slide := content_tween.tween_property(
			answer_button,
			"position:x",
			0.0,
			PORTRAIT_QUIZ_ENTRANCE_CONTENT_DURATION
		)
		answer_slide.set_delay(answer_delay)
		answer_slide.set_trans(Tween.TRANS_CUBIC)
		answer_slide.set_ease(Tween.EASE_OUT)
		var shadow_panel := _quiz_answer_shadow(answer_button)
		if shadow_panel != null and is_instance_valid(shadow_panel) and shadow_panel.visible:
			var shadow_slide := content_tween.tween_property(
				shadow_panel,
				"position:x",
				0.0,
				PORTRAIT_QUIZ_ENTRANCE_CONTENT_DURATION
			)
			shadow_slide.set_delay(answer_delay)
			shadow_slide.set_trans(Tween.TRANS_CUBIC)
			shadow_slide.set_ease(Tween.EASE_OUT)
		visible_answer_order += 1
	# Do not wait for the staggered answer cascade to finish here. The theme
	# bounce should begin the instant the question card itself reaches its final
	# position; lower answers can keep sliding in underneath that animation.
	var question_card_wait := create_tween()
	question_card_wait.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	question_card_wait.tween_interval(PORTRAIT_QUIZ_ENTRANCE_PANEL_DURATION)
	await question_card_wait.finished
	if !_quiz_entrance_is_current(generation):
		return

	# The theme title has already arrived together with the question card. Once
	# that shared slide is complete, reveal only the question text through alpha.
	if question_label != null and is_instance_valid(question_label):
		var question_tween := question_label.create_tween()
		question_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		var question_fade := question_tween.tween_property(
			question_label,
			"modulate:a",
			1.0,
			PORTRAIT_QUIZ_ENTRANCE_QUESTION_FADE_DURATION
		)
		question_fade.set_trans(Tween.TRANS_SINE)
		question_fade.set_ease(Tween.EASE_OUT)
		await question_tween.finished
	if !_quiz_entrance_is_current(generation):
		return

	# Finish with the same short hint-button bounce used by the word-guessing
	# entrance. Both quiz hints appear simultaneously.
	for hint_button: Control in _quiz_hint_buttons:
		if hint_button == null or !is_instance_valid(hint_button):
			continue
		var rest_scale: Vector2 = hint_button.get_meta(
			&"quiz_entrance_rest_visual_scale",
			Vector2.ONE
		)
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

	var hint_wait := create_tween()
	hint_wait.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	hint_wait.tween_interval(
		PORTRAIT_GAME_HINT_ENTRANCE_GROW_DURATION
		+ PORTRAIT_GAME_HINT_ENTRANCE_SETTLE_DURATION
	)
	await hint_wait.finished
	if !_quiz_entrance_is_current(generation):
		return

	for answer_control: Control in _quiz_answer_buttons:
		var answer_button := answer_control as Button
		if answer_button == null or !is_instance_valid(answer_button) or !answer_button.visible:
			continue
		answer_button.mouse_filter = int(answer_button.get_meta(
			&"quiz_entrance_rest_mouse_filter",
			Control.MOUSE_FILTER_STOP
		))
	for hint_button: Control in _quiz_hint_buttons:
		if hint_button == null or !is_instance_valid(hint_button):
			continue
		hint_button.mouse_filter = int(hint_button.get_meta(
			&"quiz_entrance_rest_mouse_filter",
			Control.MOUSE_FILTER_STOP
		))
	_mark_quiz_question_ready()

func _show_quiz_game_screen() -> void:
	if !_quiz_mode_active or _quiz_selected_theme_index < 0 or _quiz_current_question.is_empty():
		show_quiz_theme_select()
		return
	_clear()
	_quiz_mode_active = true
	_quiz_screen_active = true
	_portrait_screen(0.0)

	# Quiz levels use a solid dark-blue playfield instead of the standard
	# graph-paper texture, but now also reuse the animated theme pattern from
	# the main-reward screen so each quiz topic gets its own moving backdrop.
	var quiz_background := _stage_horizontal_fill(
		PORTRAIT_HEADER_HEIGHT,
		PORTRAIT_STAGE_SIZE.y - PORTRAIT_HEADER_HEIGHT,
		PORTRAIT_SINGLE_REWARD_TITLE_BLOCK_COLOR
	)
	quiz_background.z_index = -1
	_add_final_reward_theme_pattern(quiz_background, _quiz_selected_theme_index)

	# Keep the normal gameplay resource/header treatment, but omit the character,
	# attempts counter and theme title entirely.
	_stage_coin_and_star_counters(
		Callable(self, "_return_to_quiz_from_coin_store"),
		PORTRAIT_GAME_CURRENCY_COUNTER_RECT
	)
	_stage_menu_settings_button()
	var hide_quiz_close: bool = (
		_quiz_single_player_embedded
		and _single_player_hides_close_controls(single_player_active_level_index)
	)
	if !hide_quiz_close:
		var quiz_back_action: Callable = (
			Callable(self, "_show_exit_game_popup")
			if _quiz_single_player_embedded
			else Callable(self, "show_quiz_theme_select")
		)
		# Match the normal word-guessing screen: gameplay exits use the round X button
		# rather than the page-navigation arrow.
		var back_button := _stage_round_button(
			PORTRAIT_PAGE_BACK_BUTTON_RECT,
			quiz_back_action,
			"×"
		)
		_quiz_exit_button = back_button
		_animate_portrait_back_button_entrance(back_button, PORTRAIT_PAGE_BACK_BUTTON_RECT)

	# Reuse the answer-button shadow treatment under the question card as well,
	# then draw the bordered light-blue surface on top.
	var question_shadow_rect := PORTRAIT_QUIZ_QUESTION_PANEL_RECT
	question_shadow_rect.position += Vector2(0.0, 6.0)
	var question_shadow := _stage_panel(
		question_shadow_rect,
		Color(0.07, 0.12, 0.24, 0.22),
		22.0
	)
	question_shadow.z_index = 0
	var question_panel := _stage_panel(
		PORTRAIT_QUIZ_QUESTION_PANEL_RECT,
		PORTRAIT_UI_PALETTE.THEME_CARD,
		22.0,
		PORTRAIT_UI_PALETTE.UI_BLUE_LIGHT_BORDER,
		3.0
	)
	question_panel.z_index = 1

	# Attach the theme title directly to the question panel. It has no entrance
	# tween of its own: panel motion/alpha automatically carries the title with it.
	var theme_name: String = Database.get_theme_name(_quiz_selected_theme_index)
	var theme_label := Label.new()
	theme_label.name = "QuizThemeTitle"
	theme_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme_label.position = (
		PORTRAIT_QUIZ_THEME_TITLE_RECT.position
		- PORTRAIT_QUIZ_QUESTION_PANEL_RECT.position
	)
	theme_label.size = PORTRAIT_QUIZ_THEME_TITLE_RECT.size
	theme_label.text = theme_name
	theme_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	theme_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	theme_label.add_theme_font_size_override("font_size", _heading_font_size(26))
	var quiz_theme_title_effect_color: Color = PORTRAIT_DARK_BLUE.darkened(0.40)
	theme_label.add_theme_font_override("font", UI_PRIMARY_FONT)
	theme_label.add_theme_color_override("font_color", Color.WHITE)
	theme_label.add_theme_color_override("font_outline_color", quiz_theme_title_effect_color)
	theme_label.add_theme_constant_override("outline_size", 5)
	theme_label.add_theme_color_override(
		"font_shadow_color",
		Color(
			quiz_theme_title_effect_color.r,
			quiz_theme_title_effect_color.g,
			quiz_theme_title_effect_color.b,
			0.90
		)
	)
	theme_label.add_theme_constant_override("shadow_offset_x", 3)
	theme_label.add_theme_constant_override("shadow_offset_y", 4)
	theme_label.add_theme_constant_override("shadow_outline_size", 2)
	theme_label.clip_text = false
	theme_label.z_index = 3
	question_panel.add_child(theme_label)

	var question_text: String = str(_quiz_current_question.get("question", "")).strip_edges()
	var question_label := _stage_label(
		PORTRAIT_QUIZ_QUESTION_RECT,
		question_text,
		_quiz_question_font_size(question_text),
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	question_label.add_theme_font_override("font", UI_HEADING_FONT)
	question_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	question_label.clip_text = false
	question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question_label.z_index = 2
	_quiz_question_label = question_label

	var answers_variant: Variant = _quiz_current_question.get("answers", [])
	var answers: Array = Array(answers_variant) if answers_variant is Array else []
	var visible_answer_count: int = mini(4, answers.size())
	# Answers and hints share one bottom-attached group again, but the answer stack
	# is now positioned from the hint row instead of from a hard-coded Y. This
	# guarantees the requested 40 px gap on tall screens without overlap.
	var answer_hint_group_content: Control = _portrait_begin_bottom_attached_group()
	var answer_start_y: float = _portrait_quiz_answer_start_y(visible_answer_count)
	_quiz_answer_buttons.clear()
	_quiz_hint_buttons.clear()
	_quiz_continue_button = null
	for answer_index in range(visible_answer_count):
		var answer_text: String = str(answers[answer_index]).strip_edges()
		var answer_button := _stage_quiz_answer_button(
			Rect2(
				PORTRAIT_QUIZ_ANSWER_BUTTON_X,
				answer_start_y + float(answer_index) * PORTRAIT_QUIZ_ANSWER_STEP_Y,
				PORTRAIT_QUIZ_ANSWER_BUTTON_SIZE.x,
				PORTRAIT_QUIZ_ANSWER_BUTTON_SIZE.y
			),
			answer_text,
			_quiz_answer_font_size(answer_text)
		)
		answer_button.set_meta(&"quiz_answer_index", answer_index)
		answer_button.pressed.connect(Callable(self, "_play_ui_click_sound"))
		answer_button.pressed.connect(
			Callable(self, "_on_quiz_answer_selected").bind(answer_index)
		)
		_quiz_answer_buttons.append(answer_button)

	_apply_quiz_fifty_fifty_hidden_state()
	_stage_portrait_quiz_hint_buttons()
	_quiz_continue_button = _stage_portrait_quiz_continue_button()
	_portrait_end_adaptive_group(answer_hint_group_content)
	var should_animate_quiz_intro: bool = (
		!_quiz_answer_locked
		and !_quiz_fifty_fifty_used
		and !_quiz_replace_question_used
		and !_quiz_question_replacing
	)
	if should_animate_quiz_intro:
		_prepare_quiz_screen_entrance(
			quiz_background,
			question_shadow,
			question_panel,
			question_label
		)
	else:
		_quiz_entrance_generation += 1
	_restore_quiz_answer_result_state()
	if !should_animate_quiz_intro and !_quiz_answer_locked:
		_mark_quiz_question_ready()
	_stage_portrait_ad_banner()

func show_theme_select() -> void:
	_show_theme_select_screen(false)

func _show_theme_select_screen(_with_main_navigation: bool) -> void:
	_clear()
	_portrait_screen(0.0)
	_stage_portrait_page_header(
		tr("CHALLENGES_TITLE"),
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
		var action: Callable = Callable(self, "_show_clear_theme_popup").bind(i, false) if completed else Callable(self, "start_classic_game").bind(i)
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
	).bind(false)
	var difficulty_font_size: int = _portrait_footer_font_size(22)
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
	_single_player_popup_refresh_visuals.clear()
	_single_player_popup_refresh_badge_component.clear()
	_single_player_popup_refresh_price_badge = null
	_single_player_popup_refresh_badge_shadow = null
	_single_player_popup_refresh_price_coin = null
	_single_player_popup_refresh_ad_icon = null
	_single_player_popup_theme_card_visuals.clear()

func _show_single_player_theme_popup(level_index: int, theme_index: int) -> void:
	_show_single_player_level_popup(level_index, theme_index)

func _show_single_player_last_chance_popup(advance_offer_cost: bool = true) -> void:
	if !GameSession.has_deferred_loss():
		return
	var free_offer: bool = _single_player_extra_attempt_is_free()
	# The final wrong guess immediately updates GameSession, which starts the
	# mechanical Attempts counter roll. Keep the gameplay screen visible until
	# that subtraction animation has fully settled, then open the purchase popup.
	var attempts_roll := _portrait_game_attempts_roll_tween
	if attempts_roll != null and attempts_roll.is_valid():
		await attempts_roll.finished
		if !GameSession.has_deferred_loss():
			return
	# Preserve the amount shown by the previous offer. Every second popup can
	# increase the purchased-attempt bundle; when that happens the modal should
	# visibly transform from the previous amount into the new one instead of
	# appearing with the larger value already applied.
	var previous_attempt_count: int = _single_player_extra_attempt_count()
	var purchase_cost: int = (
		_advance_single_player_extra_attempt_offer()
		if advance_offer_cost
		else _single_player_extra_attempt_cost()
	)
	if free_offer:
		purchase_cost = 0
	var attempt_count: int = _single_player_extra_attempt_count()
	var animate_attempt_count_increase: bool = (
		advance_offer_cost and attempt_count > previous_attempt_count
	)
	_remove_single_player_last_chance_popup()
	var close_action := Callable(self, "_decline_single_player_extra_attempt")
	var popup_bottom: float = 503.0 if free_offer else 582.0
	var previous_content := _portrait_popup_begin(
		"SinglePlayerLastChancePopup",
		"single_player_last_chance_popup",
		140,
		close_action,
		145.0,
		popup_bottom,
		!free_offer,
		Callable(self, "_return_to_single_player_last_chance_from_coin_store"),
		true
	)
	var rect := Rect2(28.0, 145.0, 424.0, popup_bottom - 145.0)
	_portrait_popup_shell(
		rect,
		tr("EXTRA_ATTEMPTS_TITLE"),
		close_action,
		28,
		PORTRAIT_BLUE,
		PORTRAIT_DARK_BLUE,
		PORTRAIT_ORANGE,
		"",
		true
	)
	# Match the life-refill popup: keep the reward art and explanatory copy on a
	# single light-blue status surface, then present ad and coin choices below it.
	var attempts_status_rect := PORTRAIT_REFILL_STATUS_RECT
	var attempts_status_panel := _stage_panel(
		attempts_status_rect,
		PORTRAIT_UI_PALETTE.THEME_CARD,
		PORTRAIT_REFILL_STATUS_CORNER_RADIUS
	)
	attempts_status_panel.z_index = 8
	var attempt_icon_rect := Rect2(68.0, 240.0, 144.0, 144.0)
	_stage_refill_status_glow(
		attempts_status_panel,
		attempts_status_rect,
		attempt_icon_rect,
		&"ExtraAttemptsGlow"
	)
	# Keep the stage-mapped outer node completely static. FlashStageTexture already
	# carries the viewport fit scale, so changing its pivot would visually offset it.
	# Draw the authored arrows in a local 1x-scale child and rotate only that child.
	var attempt_icon := _stage_texture(
		attempt_icon_rect,
		null
	)
	attempt_icon.z_index = 11
	var attempt_icon_spin_visual := TextureRect.new()
	attempt_icon_spin_visual.name = "ExtraAttemptsSpinVisual"
	attempt_icon_spin_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	attempt_icon_spin_visual.texture = EXTRA_ATTEMPTS_ICON_TEXTURE
	attempt_icon_spin_visual.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	attempt_icon_spin_visual.stretch_mode = TextureRect.STRETCH_SCALE
	attempt_icon_spin_visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	attempt_icon.add_child(attempt_icon_spin_visual)
	var displayed_attempt_count: int = (
		previous_attempt_count if animate_attempt_count_increase else attempt_count
	)
	var attempt_label := _stage_label(
		attempt_icon_rect,
		"+%d" % displayed_attempt_count,
		54,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	attempt_label.add_theme_font_override("font", UI_PRIMARY_FONT)
	attempt_label.add_theme_color_override(
		"font_outline_color",
		PORTRAIT_UI_PALETTE.with_alpha(PORTRAIT_UI_PALETTE.UI_BLUE_DARK, 0.96)
	)
	attempt_label.add_theme_constant_override("outline_size", 5)
	attempt_label.add_theme_color_override(
		"font_shadow_color",
		PORTRAIT_UI_PALETTE.with_alpha(PORTRAIT_UI_PALETTE.TEXT_SHADOW_DARK, 0.82)
	)
	attempt_label.add_theme_constant_override("shadow_offset_x", 2)
	attempt_label.add_theme_constant_override("shadow_offset_y", 3)
	attempt_label.z_index = 12
	var description_label := _stage_label(
		Rect2(204.0, 246.0, 208.0, 126.0),
		_single_player_extra_attempt_description(displayed_attempt_count),
		20,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	description_label.add_theme_font_override("font", UI_HEADING_FONT)
	description_label.clip_text = false
	description_label.z_index = 11

	if !free_offer:
		var rewarded_attempt_button := _stage_portrait_popup_main_button(
			Rect2(90.0, 425.0, 300.0, 56.0),
			Callable(self, "_on_single_player_extra_attempt_ad_pressed"),
			tr("COMMON_CONTINUE"),
			18,
			false,
			0.32,
			false,
			false,
			false,
			LONG_BUTTON_COLOR_BLUE
		)
		rewarded_attempt_button.add_to_group(&"single_player_last_chance_ad_button")
		rewarded_attempt_button.z_index = 16
		rewarded_attempt_button.visible = _portrait_ads_enabled()
		var rewarded_ad_icon_texture := AtlasTexture.new()
		rewarded_ad_icon_texture.atlas = WATCH_AD_ICON_TEXTURE
		rewarded_ad_icon_texture.region = Rect2(83.0, 49.0, 219.0, 159.0)
		rewarded_attempt_button.set("icon_texture", rewarded_ad_icon_texture)
		rewarded_attempt_button.set("icon_stage_size", Vector2(34.0, 28.0))
		rewarded_attempt_button.set("icon_gap_stage", 9.0)
		rewarded_attempt_button.set("icon_before_text", true)
		rewarded_attempt_button.set("icon_shadow_enabled", true)
		rewarded_attempt_button.set("icon_shadow_offset_stage", Vector2(2.0, 2.0))
		rewarded_attempt_button.set("icon_shadow_color", PORTRAIT_UI_PALETTE.AD_ICON_SHADOW)
		if rewarded_attempt_button.has_method("set_color_palette"):
			rewarded_attempt_button.call(
				"set_color_palette",
				PORTRAIT_AD_BADGE_PURPLE,
				PORTRAIT_UI_PALETTE.AD_PURPLE_PRESSED,
				PORTRAIT_UI_PALETTE.AD_PURPLE_SELECTED
			)

	var purchase_button := _stage_portrait_popup_main_button(
		Rect2(90.0, _portrait_popup_bottom_button_y(rect.end.y, 56.0), 300.0, 56.0),
		Callable(self, "_purchase_single_player_extra_attempt"),
		tr("COMMON_FREE") if free_offer else "",
		18,
		false,
		0.32,
		false,
		false,
		false,
		LONG_BUTTON_COLOR_GREEN if free_offer else LONG_BUTTON_COLOR_ORANGE
	)
	purchase_button.z_index = 16
	purchase_button.set("attention_bounce_enabled", free_offer)
	if !free_offer:
		_stage_portrait_popup_coin_purchase_content(
			purchase_button,
			tr("COMMON_CONTINUE"),
			purchase_cost,
			_purchase_price_color(purchase_cost)
		)
	content = previous_content
	if animate_attempt_count_increase:
		# Keep both purchase choices fully interactive while the offer value animates.
		# All tweens below are bound to popup-owned nodes, so closing/replacing the
		# popup simply invalidates that animation without touching the new UI.
		call_deferred(
			"_play_single_player_extra_attempt_offer_increase",
			attempt_icon_spin_visual,
			attempt_label,
			description_label,
			previous_attempt_count,
			attempt_count
		)

func _play_single_player_extra_attempt_offer_increase(
	attempt_icon: Control,
	attempt_label: Label,
	description_label: Label,
	previous_attempt_count: int,
	new_attempt_count: int
) -> void:
	if (
		attempt_icon == null
		or !is_instance_valid(attempt_icon)
		or !attempt_icon.is_inside_tree()
		or attempt_label == null
		or !is_instance_valid(attempt_label)
		or !attempt_label.is_inside_tree()
		or description_label == null
		or !is_instance_valid(description_label)
		or !description_label.is_inside_tree()
	):
		return
	if new_attempt_count <= previous_attempt_count:
		return

	var attempt_icon_origin_position: Vector2 = attempt_icon.position
	var attempt_icon_origin_scale: Vector2 = attempt_icon.scale
	attempt_icon.pivot_offset = attempt_icon.size * 0.5
	attempt_icon.position = attempt_icon_origin_position
	attempt_icon.scale = attempt_icon_origin_scale
	attempt_icon.rotation = 0.0
	attempt_label.pivot_offset = attempt_label.size * 0.5
	attempt_label.scale = Vector2.ONE
	description_label.modulate.a = 1.0

	# First give the player enough time to read the amount currently on offer.
	var hold_tween := attempt_label.create_tween()
	hold_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	hold_tween.tween_interval(0.32)
	await hold_tween.finished
	if !is_instance_valid(attempt_label) or !attempt_label.is_inside_tree():
		return

	# Bounce the old counter away: a short overshoot makes the disappearance feel
	# like the same family of bounce used elsewhere in the portrait UI.
	var counter_out := attempt_label.create_tween()
	counter_out.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var counter_grow := counter_out.tween_property(
		attempt_label,
		"scale",
		Vector2.ONE * PORTRAIT_ATTEMPTS_POPUP_COUNTER_PEAK_SCALE,
		PORTRAIT_ATTEMPTS_POPUP_COUNTER_GROW_SECONDS
	)
	counter_grow.set_trans(Tween.TRANS_QUAD)
	counter_grow.set_ease(Tween.EASE_OUT)
	var counter_hide := counter_out.tween_property(
		attempt_label,
		"scale",
		Vector2.ZERO,
		PORTRAIT_ATTEMPTS_POPUP_COUNTER_HIDE_SECONDS
	)
	counter_hide.set_trans(Tween.TRANS_BACK)
	counter_hide.set_ease(Tween.EASE_IN)
	await counter_out.finished
	if !is_instance_valid(attempt_icon) or !attempt_icon.is_inside_tree():
		return

	# With the number gone, make the authored double-arrow icon perform exactly
	# one full turn. Fade the old explanatory copy near the end of that turn so
	# the replacement can arrive together with the new counter.
	var spin_tween := attempt_icon.create_tween()
	spin_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	spin_tween.set_parallel(true)
	var spin := spin_tween.tween_property(
		attempt_icon,
		"rotation",
		TAU,
		PORTRAIT_ATTEMPTS_POPUP_ICON_SPIN_SECONDS
	)
	spin.set_trans(Tween.TRANS_QUAD)
	spin.set_ease(Tween.EASE_IN_OUT)
	var copy_fade := spin_tween.tween_property(
		description_label,
		"modulate:a",
		0.0,
		PORTRAIT_ATTEMPTS_POPUP_DESCRIPTION_HIDE_SECONDS
	)
	copy_fade.set_delay(PORTRAIT_ATTEMPTS_POPUP_DESCRIPTION_HIDE_DELAY_SECONDS)
	copy_fade.set_trans(Tween.TRANS_SINE)
	copy_fade.set_ease(Tween.EASE_IN_OUT)
	await spin_tween.finished
	if (
		!is_instance_valid(attempt_label)
		or !attempt_label.is_inside_tree()
		or !is_instance_valid(description_label)
		or !description_label.is_inside_tree()
	):
		return
	attempt_icon.rotation = 0.0
	attempt_icon.position = attempt_icon_origin_position
	attempt_icon.scale = attempt_icon_origin_scale
	attempt_label.text = "+%d" % new_attempt_count
	attempt_label.scale = Vector2.ZERO
	description_label.text = _single_player_extra_attempt_description(new_attempt_count)
	description_label.modulate.a = 0.0

	# Reveal the new number with a bounce. The refreshed explanatory text fades in
	# at the same time, so the two pieces read as one offer upgrade.
	var reveal_tween := attempt_label.create_tween()
	reveal_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	reveal_tween.set_parallel(true)
	var counter_in := reveal_tween.tween_property(
		attempt_label,
		"scale",
		Vector2.ONE * PORTRAIT_ATTEMPTS_POPUP_COUNTER_REVEAL_PEAK_SCALE,
		PORTRAIT_ATTEMPTS_POPUP_COUNTER_REVEAL_GROW_SECONDS
	)
	counter_in.set_trans(Tween.TRANS_BACK)
	counter_in.set_ease(Tween.EASE_OUT)
	var description_in := reveal_tween.tween_property(
		description_label,
		"modulate:a",
		1.0,
		PORTRAIT_ATTEMPTS_POPUP_DESCRIPTION_REVEAL_SECONDS
	)
	description_in.set_trans(Tween.TRANS_SINE)
	description_in.set_ease(Tween.EASE_OUT)
	var settle_tween := attempt_label.create_tween()
	settle_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	settle_tween.tween_interval(PORTRAIT_ATTEMPTS_POPUP_COUNTER_SETTLE_DELAY_SECONDS)
	var counter_settle := settle_tween.tween_property(
		attempt_label,
		"scale",
		Vector2.ONE,
		PORTRAIT_ATTEMPTS_POPUP_COUNTER_SETTLE_SECONDS
	)
	counter_settle.set_trans(Tween.TRANS_QUAD)
	counter_settle.set_ease(Tween.EASE_IN_OUT)
	# Do not await the final settle: there is no input state to restore anymore.
	# If the player acts while it is running, the popup is free to close/rebuild
	# and the node-bound tween disappears with the old popup.

func _purchase_single_player_extra_attempt() -> void:
	# The buttons stay live during the value animation. Once the rewarded-ad path
	# has actually been chosen, ignore a second purchase-path click during the tiny
	# hand-off window before the native ad covers the game; this prevents a double
	# grant without locking either button merely because the visual animation runs.
	if _portrait_rewarded_action == &"extra_attempt":
		return
	super._purchase_single_player_extra_attempt()

func _on_single_player_extra_attempt_ad_pressed() -> void:
	if !GameSession.has_deferred_loss():
		return
	_show_portrait_rewarded_action(&"extra_attempt")

func _show_heart_refill_popup(
	continue_action: Callable = Callable(),
	store_return_action: Callable = Callable(),
	cancel_action: Callable = Callable(),
	reward_acquired: bool = false
) -> void:
	_remove_heart_refill_popup()
	heart_refill_continue_action = continue_action
	heart_refill_store_return_action = store_return_action
	heart_refill_cancel_action = cancel_action
	heart_refill_reward_acquired = reward_acquired
	heart_refill_store_is_open = _portrait_coin_store_active
	var close_action := Callable(self, "_close_heart_refill_popup")
	var previous_content := _portrait_popup_begin(
		"HeartRefillPopup",
		"heart_refill_popup",
		150,
		close_action,
		145.0,
		582.0,
		true,
		Callable(self, "_return_to_heart_refill_from_coin_store").bind(
			continue_action,
			store_return_action,
			cancel_action,
			reward_acquired
		)
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
	var heart_status_rect := PORTRAIT_REFILL_STATUS_RECT
	var heart_status_panel := _stage_panel(
		heart_status_rect,
		PORTRAIT_UI_PALETTE.THEME_CARD,
		PORTRAIT_REFILL_STATUS_CORNER_RADIUS
	)
	heart_status_panel.z_index = 8
	# Present the life state as one horizontal row: the large heart stays on the
	# left, while the recovery caption and timer sit to its right. Center both the
	# heart/glow and the two-line text block vertically within the blue panel.
	var heart_size: Vector2 = PORTRAIT_REFILL_HEART_ICON_SIZE
	var heart_rect := Rect2(
		Vector2(
			79.0,
			heart_status_rect.get_center().y - heart_size.y * 0.5
		),
		heart_size
	)
	var heart_glow := _stage_refill_status_glow(
		heart_status_panel,
		heart_status_rect,
		heart_rect,
		&"HeartRefillGlow"
	)
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
	popup_heart_tick.wait_time = PORTRAIT_HEART_POPUP_POLL_SECONDS
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
	rewarded_heart_button.visible = _portrait_ads_enabled()
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

func _close_heart_refill_popup() -> void:
	var continue_action: Callable = heart_refill_continue_action
	var cancel_action: Callable = heart_refill_cancel_action
	var reward_acquired: bool = heart_refill_reward_acquired
	_remove_heart_refill_popup()
	if reward_acquired and continue_action.is_valid():
		continue_action.call_deferred()
	elif cancel_action.is_valid():
		cancel_action.call_deferred()

func _return_to_heart_refill_from_coin_store(
	continue_action: Callable,
	restore_action: Callable,
	cancel_action: Callable = Callable(),
	reward_acquired: bool = false
) -> void:
	if restore_action.is_valid():
		restore_action.call()
	else:
		show_menu()
	_portrait_popup_resume_without_intro = true
	_show_heart_refill_popup(
		continue_action,
		restore_action,
		cancel_action,
		reward_acquired
	)

func _restore_single_player_heart_refill_context(level_index: int, theme_index: int) -> void:
	show_tasks()
	_show_single_player_level_popup(level_index, theme_index)

func _show_single_player_level_popup(
	level_index: int,
	selected_theme: int = -1,
	retry_after_loss: bool = false,
	return_to_menu_on_close: bool = false
) -> void:
	_quiz_single_player_embedded = false
	_quiz_single_player_target_difficulty = 0.5
	_remove_single_player_theme_popup()
	single_player_retry_after_loss = retry_after_loss
	single_player_popup_return_to_menu_on_close = return_to_menu_on_close
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
	var theme_selection_locked: bool = _single_player_theme_selection_is_locked(level_index)
	_persist_guided_single_player_theme_selection(
		level_index,
		selected_theme,
		retry_after_loss
	)
	var close_action := Callable(self, "_remove_single_player_theme_popup")
	if retry_after_loss:
		close_action = Callable(self, "_close_single_player_retry_popup")
	elif return_to_menu_on_close:
		close_action = Callable(self, "_close_single_player_theme_popup_to_menu")
	var previous_content := _portrait_popup_begin(
		"SinglePlayerLevelPopup",
		"single_player_theme_popup",
		135,
		close_action,
		118.0,
		568.0,
		true,
		Callable(self, "_return_to_single_player_theme_popup").bind(
			level_index,
			retry_after_loss,
			selected_theme,
			return_to_menu_on_close
		),
		!theme_selection_locked
	)
	single_player_popup_stage_content = content
	var rect := Rect2(24.0, 118.0, 432.0, 450.0)
	var challenge_level: bool = _single_player_is_bonus_level(level_index)
	_portrait_popup_shell(
		rect,
		("%s %d" % [_single_player_level_label(), level_index + 1]).to_upper(),
		close_action,
		29,
		PORTRAIT_CHALLENGE_POPUP_HEADER if challenge_level else PORTRAIT_BLUE,
		PORTRAIT_CHALLENGE_POPUP_BODY if challenge_level else PORTRAIT_DARK_BLUE,
		PORTRAIT_CHALLENGE_POPUP_SEPARATOR if challenge_level else PORTRAIT_ORANGE,
		_single_player_challenge_level_label() if challenge_level else "",
		!theme_selection_locked
	)
	var instruction_y: float = 208.0
	var instruction_label := _stage_label(
		Rect2(44.0, instruction_y, 392.0, 38.0),
		_single_player_choose_theme_label().to_upper(),
		21,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	instruction_label.add_theme_font_override("font", UI_PRIMARY_FONT)
	instruction_label.clip_text = false
	var card_y: float = 256.0
	# Place the reroll/ad control in the same bottom CTA row as the orange Play
	# button. The row spans the popup's full content width. The round control uses
	# exactly the same visible height as the orange button.
	var bottom_button_height: float = 56.0 * PORTRAIT_POPUP_BUTTON_UNIFORM_SCALE
	var bottom_button_y: float = rect.end.y - PORTRAIT_POPUP_BOTTOM_BUTTON_GAP - bottom_button_height
	var bottom_row_left: float = rect.position.x + 20.0
	var bottom_row_right: float = rect.end.x - 20.0
	var bottom_row_gap: float = 10.0
	var refresh_button_size := Vector2.ONE * bottom_button_height
	var refresh_button_rect := Rect2(
		Vector2(bottom_row_right - refresh_button_size.x, bottom_button_y),
		refresh_button_size
	)
	var play_button_rect := Rect2(
		Vector2(bottom_row_left, bottom_button_y),
		Vector2(
			refresh_button_rect.position.x - bottom_row_gap - bottom_row_left,
			bottom_button_height
		)
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

	single_player_popup_play_button = _stage_main_button(
		play_button_rect,
		Callable(self, "_start_single_player_popup_level").bind(level_index),
		_single_player_theme_start_label(),
		_portrait_popup_font_size(18),
		selected_theme < 0,
		0.32,
		false,
		false,
		false,
		LONG_BUTTON_COLOR_ORANGE
	)
	single_player_popup_play_button.set("attention_bounce_enabled", false)
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
	var card_gap: float = 12.0
	var card_row_left: float = 44.0
	var card_row_right: float = 436.0
	var target_card_width: float = (card_row_right - card_row_left - card_gap * 2.0) / 3.0
	var card_scale: float = target_card_width / authored_card_size.x
	var card_size := Vector2(target_card_width, authored_card_size.y * 0.9975 * card_scale)
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
			card_row_left + float(option_index) * (card_size.x + card_gap),
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
		if _portrait_ads_enabled() and !_single_player_theme_ad_reroll_used:
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
	if !GameState.spend_soft_currency(SINGLE_PLAYER_THEME_REFRESH_COST, false):
		return
	_single_player_theme_reroll_used = true
	GameState.set_single_level_theme_reroll_state(
		Database.current_language,
		level_index,
		GameState.SINGLE_LEVEL_THEME_REROLL_COIN_USED,
		false
	)
	_update_single_player_theme_reroll_badge()
	_update_single_player_theme_reroll_button_state()
	_perform_single_player_theme_reroll(level_index)

func _perform_single_player_theme_reroll(level_index: int) -> void:
	var previous_options: Array = _single_player_level_theme_options(level_index).duplicate()
	var next_options: Array = _reroll_single_player_theme_options(level_index, previous_options)
	_animate_single_player_theme_reroll(level_index, previous_options, next_options)

func _animate_single_player_theme_reroll(
	level_index: int,
	previous_options: Array,
	next_options: Array
) -> void:
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

func _present_pending_single_player_theme_ad_reroll(level_index: int) -> void:
	var pending: Dictionary = _portrait_pending_theme_reroll_presentation
	_portrait_pending_theme_reroll_presentation = {}
	if (
		int(pending.get("level_index", -1)) != level_index
		or level_index != single_player_popup_level_index
	):
		_update_single_player_theme_reroll_button_state()
		return
	var previous_options: Array = Array(pending.get("previous_options", [])).duplicate()
	var next_options: Array = Array(pending.get("next_options", [])).duplicate()
	_animate_single_player_theme_reroll(level_index, previous_options, next_options)

func _update_single_player_theme_reroll_badge() -> void:
	var show_price_badge: bool = !_single_player_theme_reroll_used
	var show_ad_badge: bool = (
		_portrait_ads_enabled()
		and _single_player_theme_reroll_used
		and !_single_player_theme_ad_reroll_used
	)
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
	var ad_action_available: bool = (
		_portrait_ads_enabled()
		and !_single_player_theme_ad_reroll_used
	)
	# Keep the reroll control in the popup after both rerolls are exhausted.
	# Its disabled state already renders the round button in neutral gray and
	# blocks pointer input, so removing it only makes the CTA row jump visually.
	single_player_popup_refresh_button.visible = true
	single_player_popup_refresh_button.set(
		"button_disabled",
		_single_player_theme_slot_animating
		or (_single_player_theme_reroll_used and !ad_action_available)
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
		256.0,
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
	# Every price badge registers its price and normal color on the label. Updating
	# the shared group keeps all visible button counters in sync when the balance
	# changes, not only the theme-reroll counter.
	for price_node: Node in get_tree().get_nodes_in_group(&"portrait_coin_price_badge_label"):
		var price_label := price_node as Label
		if price_label == null or !is_instance_valid(price_label):
			continue
		var badge_price: int = maxi(
			int(price_label.get_meta(&"portrait_coin_price", 0)),
			0
		)
		var sufficient_color: Color = price_label.get_meta(
			&"portrait_coin_price_sufficient_color",
			PORTRAIT_BLUE
		)
		var price_color: Color = (
			sufficient_color
			if balance >= badge_price
			else PORTRAIT_INSUFFICIENT_PRICE_COLOR
		)
		price_label.add_theme_color_override("font_color", price_color)

func _select_single_player_popup_theme(level_index: int, theme_index: int) -> void:
	if level_index != single_player_popup_level_index:
		return
	if !_single_player_level_theme_options(level_index).has(theme_index):
		return
	single_player_popup_selected_theme = theme_index
	_persist_guided_single_player_theme_selection(
		level_index,
		theme_index,
		single_player_retry_after_loss
	)
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
		var two_player_rect := Rect2(28.0, 235.0, 424.0, 260.0)
		var two_player_previous_content := _portrait_popup_begin(
			"ExitGamePopup",
			"exit_game_popup",
			140,
			close_action,
			two_player_rect.position.y,
			two_player_rect.end.y
		)
		_portrait_popup_shell(
			two_player_rect,
			_exit_game_title_text().to_upper(),
			close_action,
			27
		)
		var two_player_warning := _stage_label(
			Rect2(58.0, 322.0, 364.0, 70.0),
			_exit_game_warning_text(),
			21,
			Color.WHITE,
			HORIZONTAL_ALIGNMENT_CENTER
		)
		two_player_warning.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		two_player_warning.clip_text = false
		var two_player_button_y: float = _portrait_popup_bottom_button_y(
			two_player_rect.end.y,
			52.0
		)
		_stage_portrait_popup_main_button(
			Rect2(82.0, two_player_button_y, 145.0, 52.0),
			Callable(self, "_confirm_exit_game").bind(true),
			tr("YES"),
			20
		)
		_stage_portrait_popup_main_button(
			Rect2(253.0, two_player_button_y, 145.0, 52.0),
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
		145.0,
		582.0
	)
	var rect := Rect2(28.0, 145.0, 424.0, 437.0)
	_portrait_popup_shell(rect, _exit_game_title_text().to_upper(), close_action, 27)
	# Match the refill popups: keep the warning art and copy together on one
	# light-blue status card, with the broken heart on the left and text on the right.
	var exit_status_rect := PORTRAIT_REFILL_STATUS_RECT
	var exit_status_panel := _stage_panel(
		exit_status_rect,
		PORTRAIT_UI_PALETTE.THEME_CARD,
		PORTRAIT_REFILL_STATUS_CORNER_RADIUS
	)
	exit_status_panel.name = "ExitLifeStatus"
	exit_status_panel.z_index = 8
	var exit_heart_size: Vector2 = PORTRAIT_REFILL_HEART_ICON_SIZE
	var exit_heart_rect := Rect2(
		Vector2(
			79.0,
			exit_status_rect.get_center().y - exit_heart_size.y * 0.5
		),
		exit_heart_size
	)
	_stage_refill_status_glow(
		exit_status_panel,
		exit_status_rect,
		exit_heart_rect,
		&"ExitLifeGlow"
	)
	var exit_heart := _stage_portrait_broken_heart_icon(exit_heart_rect)
	exit_heart.z_index = 11
	var warning_label := _stage_label(
		Rect2(204.0, 248.0, 208.0, 112.0),
		_exit_game_warning_text(),
		21,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	warning_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	warning_label.clip_text = false
	warning_label.z_index = 11
	_stage_portrait_popup_main_button(
		Rect2(90.0, 425.0, 300.0, 56.0),
		close_action,
		tr("COMMON_CONTINUE"),
		18,
		false,
		0.32,
		false,
		false,
		false,
		LONG_BUTTON_COLOR_ORANGE
	)
	var exit_button := _stage_portrait_popup_main_button(
		Rect2(
			90.0,
			_portrait_popup_bottom_button_y(rect.end.y, 56.0),
			300.0,
			56.0
		),
		Callable(self, "_confirm_exit_game").bind(true),
		"%s  −1" % tr("COMMON_EXIT"),
		18,
		false,
		0.32,
		false,
		false,
		false,
		LONG_BUTTON_COLOR_BLUE
	)
	exit_button.set("trailing_icon_texture", LIFE_HEART_ICON_TEXTURE)
	exit_button.set("trailing_icon_stage_size", Vector2(34.0, 28.0))
	exit_button.set("trailing_icon_gap_stage", 8.0)
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
		Callable(self, "_return_to_custom_word_from_coin_store"),
		false
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
	_portrait_game_keyboard_metrics_snapshot.clear()
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
	_portrait_attempt_star_collection_active = false
	_portrait_attempt_star_collection_started = false
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
	# The persistent keyboard, paper and every later hint-button rebuild must share
	# the exact same authored coordinates for the entire round. In particular, do
	# not re-read native ad state when a used hint changes its button presentation.
	_portrait_game_keyboard_metrics_snapshot = keyboard_metrics.duplicate(true)
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

	if !(
		GameState.current_mode == GameState.GameMode.SINGLE_PLAYER
		and _single_player_hides_close_controls(single_player_active_level_index)
	):
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
	return "%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d" % [
		int(_portrait_ads_enabled()),
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
	if !_portrait_ads_enabled():
		_hide_portrait_ad_banner()
		return
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
	var base_space_width: float = 20.7
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
		_complete_portrait_result_word_bounce_sequence(
			search_button,
			continue_button,
			continue_text
		)
		return
	var sequence: Tween = create_tween()
	sequence.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	sequence.tween_interval(animation_duration)
	sequence.tween_callback(
		Callable(self, "_complete_portrait_result_word_bounce_sequence").bind(
			search_button,
			continue_button,
			continue_text
		)
	)

func _complete_portrait_result_word_bounce_sequence(
	search_button: Control,
	continue_button: Control,
	continue_text: Control
) -> void:
	# Once every solved-word letter has completed its bounce, reveal the search
	# button and convert remaining attempts in parallel. Continue still waits for
	# the final star impact.
	if _portrait_attempt_star_collection_active:
		_reveal_portrait_result_actions(search_button, continue_button, continue_text)
		_start_portrait_attempt_star_collection()
		return
	_reveal_portrait_result_actions(search_button, continue_button, continue_text)

func _reveal_portrait_result_actions(
	search_button: Control,
	continue_button: Control,
	continue_text: Control,
	finished_callback: Callable = Callable()
) -> void:
	if search_button == null or !is_instance_valid(search_button) or !search_button.is_inside_tree():
		if _portrait_attempt_star_collection_active:
			_finish_portrait_attempt_star_collection()
		elif finished_callback.is_valid():
			finished_callback.call()
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
	if finished_callback.is_valid():
		reveal_tween.finished.connect(
			finished_callback,
			CONNECT_ONE_SHOT
		)

func _remaining_attempt_star_reward_amount() -> int:
	return maxi(int(last_result_data.get("remaining_attempt_star_reward_amount", 0)), 0)

func _remaining_attempt_star_balance_before() -> int:
	return maxi(int(last_result_data.get(
		"remaining_attempt_star_balance_before",
		GameState.get_stars()
	)), 0)

func _prepare_portrait_attempt_star_collection(animated: bool) -> void:
	var reward_amount: int = _remaining_attempt_star_reward_amount()
	_portrait_attempt_star_collection_active = (
		animated
		and _portrait_in_place_result_is_win
		and reward_amount > 0
	)
	_portrait_attempt_star_collection_started = false
	if reward_amount <= 0:
		return
	if _portrait_attempt_star_collection_active:
		# GameState already contains the durable final balance. Reconstruct the
		# visible pre-reward value until the flying stars reach the HUD.
		_set_stage_reward_animated_balance(
			float(_remaining_attempt_star_balance_before()),
			GameState.STAGE_REWARD_STARS
		)
		return
	_set_portrait_attempts_result_value(0)
	_set_stage_reward_animated_balance(
		float(GameState.get_stars()),
		GameState.STAGE_REWARD_STARS
	)

func _set_portrait_attempts_result_value(value: int) -> void:
	var resolved_value: int = maxi(value, 0)
	if _portrait_game_attempts_roll_tween != null and _portrait_game_attempts_roll_tween.is_valid():
		_portrait_game_attempts_roll_tween.kill()
	_portrait_game_attempts_roll_tween = null
	if _portrait_game_attempts_roll_clip != null and is_instance_valid(_portrait_game_attempts_roll_clip):
		_portrait_game_attempts_roll_clip.queue_free()
	_portrait_game_attempts_roll_clip = null
	_portrait_game_attempts_displayed_value = resolved_value
	if (
		_portrait_game_attempts_value_label != null
		and is_instance_valid(_portrait_game_attempts_value_label)
	):
		_portrait_game_attempts_value_label.text = str(resolved_value)
		_portrait_game_attempts_value_label.position = Vector2.ZERO
		_portrait_game_attempts_value_label.scale = Vector2.ONE
		_portrait_game_attempts_value_label.visible = true

func _start_portrait_attempt_star_collection() -> void:
	if (
		!_portrait_attempt_star_collection_active
		or _portrait_attempt_star_collection_started
	):
		return
	_portrait_attempt_star_collection_started = true
	var reward_amount: int = _remaining_attempt_star_reward_amount()
	var source_label: Label = _portrait_game_attempts_value_label
	var destination_icon: Control = _portrait_star_icon_visual
	if (
		reward_amount <= 0
		or source_label == null
		or !is_instance_valid(source_label)
		or !source_label.is_inside_tree()
		or destination_icon == null
		or !is_instance_valid(destination_icon)
		or !destination_icon.is_inside_tree()
	):
		_finish_portrait_attempt_star_collection()
		return

	var generation: int = result_transition_generation
	source_label.pivot_offset = source_label.size * 0.5
	source_label.scale = Vector2.ONE
	var bounce_tween := source_label.create_tween()
	bounce_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var grow := bounce_tween.tween_property(
		source_label,
		"scale",
		PORTRAIT_ATTEMPT_REWARD_BOUNCE_SCALE,
		PORTRAIT_ATTEMPT_REWARD_BOUNCE_GROW_DURATION
	)
	grow.set_trans(Tween.TRANS_QUAD)
	grow.set_ease(Tween.EASE_OUT)
	var settle := bounce_tween.tween_property(
		source_label,
		"scale",
		Vector2.ONE,
		PORTRAIT_ATTEMPT_REWARD_BOUNCE_SETTLE_DURATION
	)
	settle.set_trans(Tween.TRANS_BOUNCE)
	settle.set_ease(Tween.EASE_OUT)
	# Complete the bounce first. Only after the digit has returned to its normal
	# size do the standard reward stars appear over it and start flying.
	bounce_tween.tween_callback(
		Callable(self, "_launch_portrait_attempt_star_collection").bind(
			generation,
			source_label
		)
	)

func _launch_portrait_attempt_star_collection(
	generation: int,
	source_label: Label
) -> void:
	if (
		generation != result_transition_generation
		or !_portrait_attempt_star_collection_active
		or source_label == null
		or !is_instance_valid(source_label)
		or !source_label.is_inside_tree()
	):
		_finish_portrait_attempt_star_collection()
		return

	var previous_balance: int = _remaining_attempt_star_balance_before()
	# Reuse the exact reward-screen resource collection: it owns the standard
	# number of stars, spread, timing, flight curve and HUD impact bounce.
	_play_single_player_reward_resource_collection(
		source_label,
		GameState.STAGE_REWARD_STARS,
		null,
		Callable(self, "_finish_portrait_attempt_star_collection")
	)
	_portrait_game_attempts_displayed_value = 0
	source_label.text = "0"

	var balance_tween := source_label.create_tween()
	balance_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var balance_roll := balance_tween.tween_method(
		Callable(self, "_set_stage_reward_animated_balance").bind(
			GameState.STAGE_REWARD_STARS
		),
		float(previous_balance),
		float(GameState.get_stars()),
		_single_player_reward_collection_duration()
	)
	balance_roll.set_trans(Tween.TRANS_QUAD)
	balance_roll.set_ease(Tween.EASE_OUT)

func _finish_portrait_attempt_star_collection() -> void:
	if !_portrait_attempt_star_collection_active and !_portrait_attempt_star_collection_started:
		return
	_portrait_attempt_star_collection_active = false
	_portrait_attempt_star_collection_started = false
	_set_portrait_attempts_result_value(0)
	_set_stage_reward_animated_balance(
		float(GameState.get_stars()),
		GameState.STAGE_REWARD_STARS
	)
	_reveal_in_place_result_action_after_attempt_stars()

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
	var keyboard_metrics: Dictionary = _portrait_game_keyboard_metrics_snapshot
	if keyboard_metrics.is_empty():
		keyboard_metrics = _portrait_game_keyboard_metrics(get_viewport_rect().size)
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
	var open_hint_ad_available: bool = (
		_portrait_ads_enabled() and GameSession.can_use_open_letter_hint_ad()
	)
	var remove_hint_ad_available: bool = (
		_portrait_ads_enabled() and GameSession.can_use_remove_wrong_hint_ad()
	)
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
		LONG_BUTTON_COLOR_ORANGE
	)
	var remove_button := _stage_round_button(
		remove_rect,
		Callable(self, "_use_remove_hint"),
		"",
		remove_hint_disabled,
		false,
		0.0,
		LONG_BUTTON_COLOR_ORANGE
	)
	var comment_button := _stage_round_button(
		comment_rect,
		Callable(self, "_use_comment_hint"),
		"",
		comment_disabled,
		false,
		0.0,
		LONG_BUTTON_COLOR_BLUE if comment_unlocked else LONG_BUTTON_COLOR_ORANGE
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
	# the unlocked/used comment switches to the blue state.
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
			var badge_price: int = maxi(int(component.get("price", 0)), 0)
			var price_color: Color = (
				component.get("price_color", PORTRAIT_BLUE)
				if GameState.get_soft_currency() >= badge_price
				else PORTRAIT_INSUFFICIENT_PRICE_COLOR
			)
			label.set_meta(&"portrait_coin_price", badge_price)
			label.set_meta(
				&"portrait_coin_price_sufficient_color",
				component.get("price_color", PORTRAIT_BLUE)
			)
			label.add_to_group(&"portrait_coin_price_badge_label")
			var coin_icon_diameter: float = minf(24.0, rect.size.y - 4.0)
			var coin_icon_x: float = 2.0
			var coin_icon_y: float = (rect.size.y - coin_icon_diameter) * 0.5
			coin_icon.position = Vector2(coin_icon_x, coin_icon_y)
			coin_icon.size = Vector2.ONE * coin_icon_diameter
			var label_x: float = coin_icon_x + coin_icon_diameter - 1.0
			label.position = Vector2(label_x, 0.0)
			label.size = Vector2(maxf(0.0, rect.size.x - label_x - 2.0), rect.size.y)
			label.text = str(badge_price)
			label.add_theme_font_size_override("font_size", int(component.get("price_font_size", 16)))
			label.add_theme_color_override("font_color", price_color)
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

func _show_single_player_forfeit_reward_screen(show_interstitial: bool = false) -> void:
	_portrait_single_reward_resume_without_intro = false
	var show_reward_action := Callable(self, "_show_single_player_reward_chain_screen")
	if show_interstitial:
		_run_action_after_interstitial_if_ready(show_reward_action)
		return
	show_reward_action.call()

func _return_to_single_player_last_chance_from_coin_store() -> void:
	_portrait_game_entrance_pending = false
	super.show_game_screen()
	_portrait_popup_resume_without_intro = true
	call_deferred("_show_single_player_last_chance_popup", false)

func _grant_single_player_extra_attempt() -> void:
	# Apply and persist the attempt before any presentation work. A native ad can
	# return through an Android lifecycle transition where the process is killed
	# before an awaited tween completes.
	_clear_hero_animation_overlay()
	GameSession.grant_deferred_attempt(_single_player_extra_attempt_count())
	single_player_extra_attempt_claim_in_progress = false

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
	_prepare_portrait_attempt_star_collection(animated)
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
	var continue_action: Callable = _result_continue_action()
	if _portrait_in_place_result_is_win:
		continue_action = Callable(
			self,
			"_run_action_after_interstitial_if_ready"
		).bind(continue_action)
	var action_button := _stage_main_button(
		_portrait_in_place_result_button_rect(),
		continue_action,
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
	if _portrait_attempt_star_collection_active:
		action_button.visible = false
		action_button.modulate.a = 0.0
		action_button.set("disabled", true)
		action_button.set("attention_bounce_enabled", false)
		return
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

func _reveal_in_place_result_action_after_attempt_stars() -> void:
	var action_button: Control = _portrait_inline_result_continue_button
	if (
		action_button == null
		or !is_instance_valid(action_button)
		or !action_button.is_inside_tree()
	):
		return
	action_button.visible = true
	action_button.modulate.a = 0.0
	action_button.set("disabled", false)
	action_button.set("attention_bounce_enabled", true)
	var reveal_tween := action_button.create_tween()
	reveal_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var fade := reveal_tween.tween_property(
		action_button,
		"modulate:a",
		1.0,
		PORTRAIT_INLINE_RESULT_CONTINUE_GROW_DURATION
	)
	fade.set_trans(Tween.TRANS_SINE)
	fade.set_ease(Tween.EASE_OUT)

func _single_player_reward_for_slot(level_index: int, word_slot: int, word_count: int) -> int:
	var currency: String = _single_player_stage_reward_currency(
		level_index,
		word_slot,
		word_count
	)
	var reward: int = (
		GameState.WORD_REWARD_STARS
		if currency == GameState.STAGE_REWARD_STARS
		else GameState.WORD_REWARD_COINS
	)
	if word_slot == word_count - 1 and currency == GameState.STAGE_REWARD_COINS:
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

func _stage_single_player_reward_resource_icon(
	parent: Control,
	icon_rect: Rect2,
	reward_currency: String
) -> Control:
	var resource_icon := TextureRect.new()
	resource_icon.name = (
		"RewardStarIcon"
		if reward_currency == GameState.STAGE_REWARD_STARS
		else "RewardCoinIcon"
	)
	resource_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	resource_icon.texture = (
		STAR_CURRENCY_TEXTURE
		if reward_currency == GameState.STAGE_REWARD_STARS
		else SOFT_CURRENCY_COIN_TEXTURE
	)
	resource_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	resource_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	resource_icon.position = icon_rect.position
	resource_icon.size = icon_rect.size
	resource_icon.z_index = 3
	parent.add_child(resource_icon)
	return resource_icon

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
	_play_single_player_reward_resource_collection(
		source_visual,
		GameState.STAGE_REWARD_COINS,
		continue_button
	)

func _play_single_player_reward_resource_collection(
	source_visual: Control,
	reward_currency: String,
	continue_button: Control = null,
	finished_callback: Callable = Callable()
) -> void:
	if ui == null or !is_instance_valid(ui):
		if finished_callback.is_valid():
			finished_callback.call()
		return
	if source_visual == null or !is_instance_valid(source_visual) or !source_visual.is_inside_tree():
		if finished_callback.is_valid():
			finished_callback.call()
		return
	var destination_icon: Control = (
		_portrait_star_icon_visual
		if reward_currency == GameState.STAGE_REWARD_STARS
		else _portrait_currency_coin_icon_visual
	)
	if (
		destination_icon == null
		or !is_instance_valid(destination_icon)
		or !destination_icon.is_inside_tree()
	):
		if finished_callback.is_valid():
			finished_callback.call()
		return
	var overlay_layer := CanvasLayer.new()
	overlay_layer.name = "SinglePlayerRewardResourceCanvas"
	overlay_layer.layer = 100
	add_child(overlay_layer)
	var overlay := Control.new()
	overlay.name = "SinglePlayerRewardResourceOverlay"
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay_layer.add_child(overlay)

	var resource_size := Vector2.ONE * (
		PORTRAIT_SINGLE_REWARD_FLY_STAR_SIZE
		if reward_currency == GameState.STAGE_REWARD_STARS
		else PORTRAIT_SINGLE_REWARD_FLY_COIN_SIZE
	)
	var resource_texture: Texture2D = (
		STAR_CURRENCY_TEXTURE
		if reward_currency == GameState.STAGE_REWARD_STARS
		else SOFT_CURRENCY_COIN_TEXTURE
	)
	var source_viewport_center: Vector2 = _control_center_in_control_space(source_visual, overlay)
	var target_center: Vector2 = _control_center_in_control_space(
		destination_icon,
		overlay
	)
	# Grow the destination once and keep it at peak scale for the complete stream.
	# Repeated impact bounces briefly returned the counter to rest between units.
	_set_portrait_resource_counter_collection_active(reward_currency, true)
	for resource_index in range(PORTRAIT_SINGLE_REWARD_FLY_COIN_COUNT):
		var resource_icon := TextureRect.new()
		resource_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		resource_icon.texture = resource_texture
		resource_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		resource_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		resource_icon.size = resource_size
		resource_icon.pivot_offset = resource_size * 0.5
		resource_icon.position = source_viewport_center - resource_size * 0.5
		resource_icon.scale = Vector2.ONE
		resource_icon.modulate.a = 0.0
		overlay.add_child(resource_icon)

		var spread_sign: float = -1.0 if resource_index % 2 == 0 else 1.0
		var spread_step: float = float(resource_index / 2 + 1)
		var start_offset := Vector2(
			spread_sign * spread_step * PORTRAIT_SINGLE_REWARD_FLY_SPREAD_X * 0.42,
			-float(resource_index % 3) * PORTRAIT_SINGLE_REWARD_FLY_SPREAD_Y
		)
		var flight_start := source_viewport_center + start_offset - resource_size * 0.5
		var flight_end := target_center - resource_size * 0.5

		var tween := resource_icon.create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_interval(
			PORTRAIT_SINGLE_REWARD_FLY_START_DELAY
			+ float(resource_index) * PORTRAIT_SINGLE_REWARD_FLY_STAGGER
		)
		tween.parallel().tween_property(resource_icon, "modulate:a", 1.0, 0.08)
		var rise := tween.tween_property(resource_icon, "position", flight_start, 0.10)
		rise.set_trans(Tween.TRANS_SINE)
		rise.set_ease(Tween.EASE_OUT)
		var fly := tween.tween_property(resource_icon, "position", flight_end, PORTRAIT_SINGLE_REWARD_FLY_DURATION)
		fly.set_trans(Tween.TRANS_CUBIC)
		fly.set_ease(Tween.EASE_IN)
		var icon_bounce_callback := Callable(
			self,
			"_bounce_portrait_resource_counter_icon"
		).bind(reward_currency)
		tween.tween_callback(icon_bounce_callback)
		if resource_index == PORTRAIT_SINGLE_REWARD_FLY_COIN_COUNT - 1:
			# Let the last icon impact finish before the plate returns to rest.
			tween.tween_interval(_portrait_resource_icon_bounce_duration())
			tween.tween_callback(
				Callable(self, "_set_portrait_resource_counter_collection_active").bind(
					reward_currency,
					false
				)
			)
			# The last impact marks the end of the visible crediting sequence. Only
			# now make Continue available; the later overlay cleanup is technical.
			tween.tween_callback(
				Callable(self, "_reveal_single_player_reward_continue_button").bind(
					continue_button
				)
			)
			if finished_callback.is_valid():
				tween.tween_callback(finished_callback)
		tween.tween_callback(Callable(resource_icon, "queue_free"))

	var cleanup_delay: float = _single_player_reward_collection_duration() + 0.04
	var cleanup_tween := overlay.create_tween()
	cleanup_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	cleanup_tween.tween_interval(cleanup_delay)
	cleanup_tween.tween_callback(Callable(overlay_layer, "queue_free"))

func _single_player_reward_collection_duration() -> float:
	return _single_player_reward_flight_duration() + _portrait_resource_collection_tail_duration()

func _single_player_reward_flight_duration() -> float:
	return (
		PORTRAIT_SINGLE_REWARD_FLY_START_DELAY
		+ float(maxi(PORTRAIT_SINGLE_REWARD_FLY_COIN_COUNT - 1, 0)) * PORTRAIT_SINGLE_REWARD_FLY_STAGGER
		+ 0.10
		+ PORTRAIT_SINGLE_REWARD_FLY_DURATION
	)

func _portrait_resource_icon_bounce_duration() -> float:
	return (
		PORTRAIT_CURRENCY_ICON_REWARD_BOUNCE_GROW_DURATION
		+ PORTRAIT_CURRENCY_ICON_REWARD_BOUNCE_SETTLE_DURATION
	)

func _portrait_resource_collection_tail_duration() -> float:
	return (
		_portrait_resource_icon_bounce_duration()
		+ PORTRAIT_CURRENCY_COUNTER_REWARD_SETTLE_DURATION
	)

func _set_stage_reward_animated_balance(value: float, reward_currency: String) -> void:
	var balance_text: String = _soft_currency_balance_text(int(round(value)))
	var label_group: StringName = (
		&"stars_balance_label"
		if reward_currency == GameState.STAGE_REWARD_STARS
		else &"soft_currency_balance_label"
	)
	for balance_node: Node in get_tree().get_nodes_in_group(label_group):
		var balance_label := balance_node as Label
		if balance_label != null and is_instance_valid(balance_label):
			balance_label.text = balance_text

func _single_player_reward_check_reveal_delay() -> float:
	# Reveal the claimed marker halfway between the first launch and the last
	# resource reaching the HUD. The overlay cleanup tail is not part of the flight.
	return lerpf(
		PORTRAIT_SINGLE_REWARD_FLY_START_DELAY,
		_single_player_reward_flight_duration(),
		0.5
	)

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
	resource_visual: Control,
	count_visual: Label,
	check_visual: Control,
	continue_button: Control,
	reward_currency: String
) -> void:
	# Let stage-layout controls resolve their final size/pivot before animating.
	# Flying resource copies and the source icon fade begin together; the claimed check then
	# pops into the same reward slot with a centered bounce.
	await get_tree().process_frame
	if !is_inside_tree():
		return
	if resource_visual == null or !is_instance_valid(resource_visual) or !resource_visual.is_inside_tree():
		_reveal_single_player_reward_continue_button(continue_button)
		return
	if count_visual == null or !is_instance_valid(count_visual) or !count_visual.is_inside_tree():
		_reveal_single_player_reward_continue_button(continue_button)
		return
	if check_visual == null or !is_instance_valid(check_visual) or !check_visual.is_inside_tree():
		_reveal_single_player_reward_continue_button(continue_button)
		return

	var previous_balance: int = (
		GameState.get_stars()
		if reward_currency == GameState.STAGE_REWARD_STARS
		else GameState.get_soft_currency()
	)
	var claim_result: Dictionary = GameState.claim_active_single_player_stage_reward(true)
	var credited_amount: int = maxi(int(claim_result.get("amount", 0)), 0)
	if credited_amount <= 0:
		_reveal_single_player_reward_continue_button(continue_button)
		return
	var resolved_currency: String = str(claim_result.get("currency", reward_currency))
	var final_balance: int = previous_balance + credited_amount
	_set_stage_reward_animated_balance(float(previous_balance), resolved_currency)
	_play_single_player_reward_resource_collection(
		resource_visual,
		resolved_currency,
		continue_button
	)
	var count_tween := count_visual.create_tween()
	count_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var count_roll := count_tween.tween_method(
		Callable(self, "_set_stage_reward_animated_balance").bind(resolved_currency),
		float(previous_balance),
		float(final_balance),
		_single_player_reward_collection_duration()
	)
	count_roll.set_trans(Tween.TRANS_QUAD)
	count_roll.set_ease(Tween.EASE_OUT)

	# Keep the reward art and xN fully active while the resources are flying. As soon
	# as the checkmark starts appearing, dim both and keep them dimmed: the
	# checkmark marks the reward as permanently claimed.
	resource_visual.modulate.a = 1.0
	count_visual.modulate.a = 1.0

	check_visual.pivot_offset = check_visual.size * 0.5
	check_visual.modulate.a = 0.0
	check_visual.scale = Vector2.ONE * PORTRAIT_SINGLE_REWARD_CHECK_BOUNCE_START_SCALE
	var check_tween := check_visual.create_tween()
	check_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	check_tween.tween_interval(_single_player_reward_check_reveal_delay())
	check_tween.tween_property(check_visual, "modulate:a", 1.0, 0.08)
	var resource_dim := check_tween.parallel().tween_property(
		resource_visual,
		"modulate:a",
		PORTRAIT_SINGLE_REWARD_CHECK_COIN_DIM_ALPHA,
		0.08
	)
	resource_dim.set_trans(Tween.TRANS_QUAD)
	resource_dim.set_ease(Tween.EASE_OUT)
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
	resource_visual: Control,
	count_visual: Label,
	check_visual: Control,
	failure_cross_visual: Control,
	failed_final_crown_visual: Control,
	continue_button: Control,
	reward_currency: String,
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
			resource_visual,
			count_visual,
			check_visual,
			continue_button,
			reward_currency
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

func _start_final_reward_glow_rotation(
	glow: Control,
	duration: float = PORTRAIT_FINAL_REWARD_GLOW_ROTATION_DURATION
) -> void:
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
		duration
	).from(0.0)

func _play_final_reward_pack_bounce(
	pack: Control,
	peak_callback: Callable = Callable()
) -> void:
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
	if peak_callback.is_valid():
		# This callback runs after the grow phase has reached its exact target
		# scale and before the settling phase starts shrinking the prize again.
		bounce_tween.tween_callback(peak_callback)
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

func _stage_final_reward_collect_text(rect: Rect2, next_level_index: int = -1) -> Dictionary:
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
	_apply_portrait_reward_header_text_effect(label, 3)
	visual.add_child(label)

	var collect_action := Callable(self, "_claim_single_player_final_reward")
	if next_level_index >= 0:
		collect_action = Callable(
			self,
			"_claim_single_player_final_reward_and_open_next_theme"
		).bind(next_level_index)
	var hit_button := _stage_button(
		rect,
		collect_action,
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
	reveal_tween.finished.connect(
		Callable(self, "_finish_final_reward_action_reveal").bind(double_button),
		CONNECT_ONE_SHOT
	)
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

func _finish_final_reward_action_reveal(button: Control) -> void:
	if button == null or !is_instance_valid(button) or !button.is_inside_tree():
		return
	if (
		bool(button.get_meta(&"single_shine_after_reveal", false))
		and button.has_method("play_single_attention_shine")
	):
		button.call("play_single_attention_shine")
	_enable_final_reward_continue_attention(button)

func _enable_final_reward_continue_attention(button: Control) -> void:
	if button == null or !is_instance_valid(button) or !button.is_inside_tree():
		return
	if !bool(button.get_meta(&"attention_after_reveal", false)):
		return
	button.set("attention_bounce_enabled", true)

func _stop_final_reward_continue_attention() -> void:
	if (
		_portrait_final_reward_continue_button == null
		or !is_instance_valid(_portrait_final_reward_continue_button)
	):
		return
	_portrait_final_reward_continue_button.set_meta(&"attention_after_reveal", false)
	_portrait_final_reward_continue_button.set("attention_bounce_enabled", false)

func _stop_single_reward_continue_attention() -> void:
	if (
		_portrait_single_reward_continue_button == null
		or !is_instance_valid(_portrait_single_reward_continue_button)
	):
		return
	_portrait_single_reward_continue_button.set("attention_bounce_enabled", false)

func _start_early_final_reward_claim_at_pack_peak(
	transition_pack: Control,
	double_button: Control,
	collect_holder: Control,
	collect_button: Button
) -> void:
	_play_early_final_reward_coin_claim(transition_pack)
	_reveal_final_reward_actions(double_button, collect_holder, collect_button)

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
	collect_button: Button,
	claim_before_actions: bool
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

	# Move the grand-prize pack immediately after the short chain hold. Crossfade
	# the regular reward art into it during the flight instead of pausing first.
	# The chain fades out and the hero simply disappears through alpha instead of
	# shrinking.
	# Guided levels credit their coins at the peak of the center bounce. Later
	# levels retain their regular claim / rewarded-ad flow.
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
	move_pack.set_trans(Tween.TRANS_LINEAR)
	replace_tween.parallel().tween_property(
		source_coin,
		"modulate:a",
		0.0,
		PORTRAIT_FINAL_REWARD_ICON_CROSSFADE_DURATION
	)
	replace_tween.parallel().tween_property(
		source_count,
		"modulate:a",
		0.0,
		PORTRAIT_FINAL_REWARD_ICON_CROSSFADE_DURATION
	)
	replace_tween.parallel().tween_property(
		transition_pack,
		"modulate:a",
		1.0,
		PORTRAIT_FINAL_REWARD_ICON_CROSSFADE_DURATION
	)
	replace_tween.parallel().tween_property(
		chain_holder,
		"modulate:a",
		0.0,
		PORTRAIT_FINAL_REWARD_REPLACE_DURATION * 0.72
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
	# The background transition is intentionally independent: it lasts longer
	# than the icon flight and must not delay the center bounce after arrival.
	if (
		(background_overlay != null and is_instance_valid(background_overlay))
		or (title_panel != null and is_instance_valid(title_panel))
	):
		var backdrop_tween := transition_pack.create_tween()
		backdrop_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		backdrop_tween.set_parallel(true)
		if background_overlay != null and is_instance_valid(background_overlay):
			var backdrop_fade := backdrop_tween.tween_property(
				background_overlay,
				"modulate:a",
				1.0,
				PORTRAIT_FINAL_REWARD_BACKGROUND_FADE_DURATION
			)
			backdrop_fade.set_trans(Tween.TRANS_SINE)
			backdrop_fade.set_ease(Tween.EASE_IN_OUT)
		if title_panel != null and is_instance_valid(title_panel):
			backdrop_tween.tween_method(
				Callable(self, "_set_panel_fill_color").bind(title_panel),
				PORTRAIT_SINGLE_REWARD_TITLE_BLOCK_COLOR,
				PORTRAIT_BLUE,
				PORTRAIT_FINAL_REWARD_BACKGROUND_FADE_DURATION
			)
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
	var pack_peak_callback := Callable()
	if claim_before_actions:
		pack_peak_callback = Callable(
			self,
			"_start_early_final_reward_claim_at_pack_peak"
		).bind(
			transition_pack,
			double_button,
			collect_holder,
			collect_button
		)
	await _play_final_reward_pack_bounce(transition_pack, pack_peak_callback)
	if !claim_before_actions:
		_reveal_final_reward_actions(double_button, collect_holder, collect_button)

func _layout_final_reward_theme_pattern(clip_root: Control, motion: Control, mono_texture: Texture2D) -> void:
	if clip_root == null or !is_instance_valid(clip_root):
		return
	if motion == null or !is_instance_valid(motion):
		return
	if mono_texture == null:
		return

	# Resize events can arrive several times while the safe area / ad banner is
	# settling. Never clear a valid pattern while the new layout still has a zero
	# or transitional size. The next real `resized` signal will rebuild it.
	var clip_size: Vector2 = clip_root.size
	if clip_size.x <= 0.0 or clip_size.y <= 0.0:
		return

	var existing_tween: Tween = motion.get_meta("pattern_move_tween", null) as Tween
	if existing_tween != null and is_instance_valid(existing_tween):
		existing_tween.kill()
	for child: Node in motion.get_children():
		# Rebuild synchronously. The old implementation queued the children for
		# deletion and then yielded a frame, which allowed overlapping resize calls
		# to leave the pattern permanently empty.
		child.free()

	var spacing: float = PORTRAIT_FINAL_REWARD_THEME_PATTERN_SPACING
	var overscan: float = spacing * 2.0
	motion.position = Vector2.ZERO
	motion.size = clip_size + Vector2.ONE * overscan * 2.0
	var cols: int = int(ceil((clip_size.x + overscan * 2.0) / spacing)) + 2
	var rows: int = int(ceil((clip_size.y + overscan * 2.0) / spacing)) + 2
	for row: int in range(rows):
		for col: int in range(cols):
			var icon := TextureRect.new()
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			icon.texture = mono_texture
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.size = Vector2.ONE * PORTRAIT_FINAL_REWARD_THEME_PATTERN_ICON_SIZE
			icon.position = Vector2(
				-overscan
					+ float(col) * spacing
					+ (spacing * 0.5 if row % 2 == 0 else 0.0),
				-overscan + float(row) * spacing
			)
			icon.modulate = Color(1.0, 1.0, 1.0, PORTRAIT_FINAL_REWARD_THEME_PATTERN_ALPHA)
			icon.rotation_degrees = -18.0
			motion.add_child(icon)

	var move_tween := motion.create_tween()
	move_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	move_tween.set_loops()
	var repeat_offset := Vector2(spacing * 0.5, -spacing)
	var move := move_tween.tween_property(
		motion,
		"position",
		repeat_offset,
		PORTRAIT_FINAL_REWARD_THEME_PATTERN_MOVE_DURATION
	)
	move.from(Vector2.ZERO)
	move.set_trans(Tween.TRANS_LINEAR)
	motion.set_meta("pattern_move_tween", move_tween)

func _add_final_reward_theme_pattern(background_overlay: Control, theme_index: int) -> void:
	if background_overlay == null or !is_instance_valid(background_overlay):
		return
	var mono_texture: Texture2D = _theme_icon_mono_texture(theme_index)
	if mono_texture == null:
		return
	var clip_root := Control.new()
	clip_root.name = "FinalRewardThemePattern"
	clip_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_root.clip_contents = true
	clip_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	clip_root.offset_left = 0.0
	clip_root.offset_top = 0.0
	clip_root.offset_right = 0.0
	clip_root.offset_bottom = 0.0
	background_overlay.add_child(clip_root)

	var motion := Control.new()
	motion.name = "PatternMotion"
	motion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	motion.position = Vector2.ZERO
	clip_root.add_child(motion)
	clip_root.resized.connect(Callable(self, "_layout_final_reward_theme_pattern").bind(clip_root, motion, mono_texture))
	call_deferred("_layout_final_reward_theme_pattern", clip_root, motion, mono_texture)

func _collect_theme_pattern_textures(use_mono_icons: bool = true) -> Array:
	var textures: Array = []
	for theme_index: int in range(Database.get_theme_count()):
		var theme_texture: Texture2D = (
			_theme_icon_mono_texture(theme_index)
			if use_mono_icons
			else _theme_icon_texture(theme_index)
		)
		if theme_texture != null:
			textures.append(theme_texture)
	return textures

func _layout_multi_theme_pattern(clip_root: Control, motion: Control, theme_textures: Array, icon_modulate: Color = Color(1.0, 1.0, 1.0, PORTRAIT_FINAL_REWARD_THEME_PATTERN_ALPHA), spacing_multiplier: float = 1.0, icon_scale: float = 1.0, move_duration_multiplier: float = 1.0, bottom_alpha: float = -1.0, full_alpha_screen_ratio: float = 0.0) -> void:
	if clip_root == null or !is_instance_valid(clip_root):
		return
	if motion == null or !is_instance_valid(motion):
		return
	if theme_textures.is_empty():
		return

	var clip_size: Vector2 = clip_root.size
	if clip_size.x <= 0.0 or clip_size.y <= 0.0:
		return

	var existing_tween: Tween = motion.get_meta("pattern_move_tween", null) as Tween
	if existing_tween != null and is_instance_valid(existing_tween):
		existing_tween.kill()
	for child: Node in motion.get_children():
		child.free()

	var spacing: float = PORTRAIT_FINAL_REWARD_THEME_PATTERN_SPACING * maxf(spacing_multiplier, 0.05)
	var overscan: float = spacing * 2.0
	motion.position = Vector2.ZERO
	motion.size = clip_size + Vector2.ONE * overscan * 2.0
	var cols: int = int(ceil((clip_size.x + overscan * 2.0) / spacing)) + 2
	var rows: int = int(ceil((clip_size.y + overscan * 2.0) / spacing)) + 2
	var texture_count: int = theme_textures.size()
	var gradient_height: float = maxf(clip_size.y + overscan * 2.0, 1.0)
	var top_alpha: float = icon_modulate.a
	var effective_bottom_alpha: float = top_alpha if bottom_alpha < 0.0 else clampf(bottom_alpha, 0.0, 1.0)
	var clamped_full_alpha_ratio: float = clampf(full_alpha_screen_ratio, 0.0, 1.0)
	for row: int in range(rows):
		for col: int in range(cols):
			var icon := TextureRect.new()
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			icon.texture = theme_textures[(row * cols + col) % texture_count] as Texture2D
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.size = Vector2.ONE * PORTRAIT_FINAL_REWARD_THEME_PATTERN_ICON_SIZE * maxf(icon_scale, 0.05)
			icon.position = Vector2(
				-overscan
					+ float(col) * spacing
					+ (spacing * 0.5 if row % 2 == 0 else 0.0),
				-overscan + float(row) * spacing
			)
			var icon_center_y: float = icon.position.y + icon.size.y * 0.5
			var screen_y_ratio: float = clampf((icon_center_y + overscan) / gradient_height, 0.0, 1.0)
			var icon_alpha: float = top_alpha
			if bottom_alpha >= 0.0:
				if clamped_full_alpha_ratio > 0.0 and clamped_full_alpha_ratio < 1.0:
					var fade_t: float = clampf(
						(1.0 - screen_y_ratio) / (1.0 - clamped_full_alpha_ratio),
						0.0,
						1.0
					)
					# Softer ease-in: 30% closer to linear than the previous t^2 curve,
					# while still growing slowly at first and accelerating toward the threshold.
					fade_t = pow(fade_t, 1.7)
					icon_alpha = lerpf(effective_bottom_alpha, top_alpha, fade_t)
				else:
					icon_alpha = lerpf(top_alpha, effective_bottom_alpha, screen_y_ratio)
			icon.modulate = Color(icon_modulate.r, icon_modulate.g, icon_modulate.b, icon_alpha)
			icon.rotation_degrees = -18.0
			motion.add_child(icon)

	var move_tween := motion.create_tween()
	move_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	move_tween.set_loops()
	var repeat_offset := Vector2(spacing * 0.5, -spacing)
	var move := move_tween.tween_property(
		motion,
		"position",
		repeat_offset,
		PORTRAIT_FINAL_REWARD_THEME_PATTERN_MOVE_DURATION * maxf(move_duration_multiplier, 0.01)
	)
	move.from(Vector2.ZERO)
	move.set_trans(Tween.TRANS_LINEAR)
	motion.set_meta("pattern_move_tween", move_tween)

func _add_multi_theme_pattern(background_overlay: Control, theme_textures: Array, pattern_name: String = "MultiThemePattern", icon_modulate: Color = Color(1.0, 1.0, 1.0, PORTRAIT_FINAL_REWARD_THEME_PATTERN_ALPHA), spacing_multiplier: float = 1.0, icon_scale: float = 1.0, move_duration_multiplier: float = 1.0, bottom_alpha: float = -1.0, full_alpha_screen_ratio: float = 0.0) -> void:
	if background_overlay == null or !is_instance_valid(background_overlay):
		return
	if theme_textures.is_empty():
		return
	var clip_root := Control.new()
	clip_root.name = pattern_name
	clip_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_root.clip_contents = true
	clip_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	clip_root.offset_left = 0.0
	clip_root.offset_top = 0.0
	clip_root.offset_right = 0.0
	clip_root.offset_bottom = 0.0
	background_overlay.add_child(clip_root)

	var motion := Control.new()
	motion.name = "PatternMotion"
	motion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	motion.position = Vector2.ZERO
	clip_root.add_child(motion)
	clip_root.resized.connect(Callable(self, "_layout_multi_theme_pattern").bind(clip_root, motion, theme_textures, icon_modulate, spacing_multiplier, icon_scale, move_duration_multiplier, bottom_alpha, full_alpha_screen_ratio))
	call_deferred("_layout_multi_theme_pattern", clip_root, motion, theme_textures, icon_modulate, spacing_multiplier, icon_scale, move_duration_multiplier, bottom_alpha, full_alpha_screen_ratio)

func _add_full_rect_gradient_overlay(background_overlay: Control, top_color: Color, bottom_color: Color, overlay_name: String = "GradientOverlay") -> void:
	if background_overlay == null or !is_instance_valid(background_overlay):
		return
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([top_color, bottom_color])
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	var gradient_texture := GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.fill = GradientTexture2D.FILL_LINEAR
	gradient_texture.fill_from = Vector2(0.5, 0.0)
	gradient_texture.fill_to = Vector2(0.5, 1.0)
	gradient_texture.width = 1
	gradient_texture.height = 256
	var overlay := TextureRect.new()
	overlay.name = overlay_name
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.texture = gradient_texture
	overlay.stretch_mode = TextureRect.STRETCH_SCALE
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.offset_left = 0.0
	overlay.offset_top = 0.0
	overlay.offset_right = 0.0
	overlay.offset_bottom = 0.0
	# Keep the gradient above the patterned body but below the top-bar surface
	# and all interactive Home controls. The parent background itself sits at -1.
	overlay.z_index = 0
	background_overlay.add_child(overlay)


func _show_portrait_rewarded_action(action: StringName, level_index: int = -1) -> bool:
	if (
		!_portrait_ads_enabled()
		or action == &""
		or _portrait_final_reward_waiting_for_ad
		or _portrait_rewarded_action != &""
	):
		return false
	var ads_service: Node = _portrait_ads_service()
	if ads_service == null or !ads_service.has_method("show_rewarded_video"):
		_show_portrait_ad_not_ready_toast()
		return false
	_connect_portrait_rewarded_action_signals(ads_service)
	if action == &"theme_reroll":
		_portrait_pending_theme_reroll_presentation = {}
	_portrait_rewarded_action = action
	_portrait_rewarded_action_level_index = level_index
	_portrait_rewarded_action_earned = false
	_set_portrait_rewarded_action_control_enabled(action, level_index, false)
	if !bool(ads_service.call("show_rewarded_video")):
		_portrait_rewarded_action = &""
		_portrait_rewarded_action_level_index = -1
		_set_portrait_rewarded_action_control_enabled(action, level_index, true)
		_show_portrait_ad_not_ready_toast()
		return false
	GameState.set_fullscreen_ad_active(true)
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
		&"coin_refill":
			for node: Node in get_tree().get_nodes_in_group(&"coin_refill_ad_button"):
				var coin_refill_button := node as Control
				if coin_refill_button != null and is_instance_valid(coin_refill_button):
					_refresh_coin_refill_ad_button(coin_refill_button, enabled)
		&"extra_attempt":
			var can_use_rewarded_attempt: bool = enabled and GameSession.has_deferred_loss()
			for node: Node in get_tree().get_nodes_in_group(&"single_player_last_chance_ad_button"):
				var attempt_ad_button := node as Control
				if attempt_ad_button != null and is_instance_valid(attempt_ad_button):
					attempt_ad_button.set("button_disabled", !can_use_rewarded_attempt)

func _grant_portrait_rewarded_action(action: StringName, level_index: int) -> void:
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
				var previous_options: Array = _single_player_level_theme_options(
					level_index
				).duplicate()
				_single_player_theme_ad_reroll_used = true
				GameState.set_single_level_theme_reroll_state(
					Database.current_language,
					level_index,
					GameState.SINGLE_LEVEL_THEME_REROLL_AD_USED,
					false
				)
				var next_options: Array = _reroll_single_player_theme_options(
					level_index,
					previous_options
				)
				# The seed and ad-use state are durable immediately, but the reels must
				# stay pending until the native fullscreen ad has been dismissed.
				_portrait_pending_theme_reroll_presentation = {
					"level_index": level_index,
					"previous_options": previous_options,
					"next_options": next_options,
				}
				_update_single_player_theme_reroll_badge()
				_update_single_player_theme_reroll_button_state()
		&"heart_refill":
			if GameState.get_hearts() < GameState.MAX_HEARTS:
				GameState.add_hearts(1)
			var popup_nodes: Array = get_tree().get_nodes_in_group(&"heart_refill_popup")
			if !popup_nodes.is_empty():
				var continue_action: Callable = heart_refill_continue_action
				var restore_action: Callable = heart_refill_store_return_action
				var cancel_action: Callable = heart_refill_cancel_action
				_show_heart_refill_popup(
					continue_action,
					restore_action,
					cancel_action,
					true
				)
		&"coin_refill":
			# Count only successfully rewarded ads. Persist the coin grant and the
			# remaining-view/cooldown state together in the same save write, then keep
			# the popup alive long enough to visibly deliver the coins into the HUD.
			var previous_balance: int = GameState.get_soft_currency()
			GameState.add_soft_currency(PORTRAIT_COIN_REFILL_REWARDED_AMOUNT, false)
			GameState.consume_coin_refill_ad_view(true)
			var final_balance: int = GameState.get_soft_currency()
			_play_coin_refill_reward_animation(previous_balance, final_balance)
		&"extra_attempt":
			if GameSession.has_deferred_loss():
				_remove_single_player_last_chance_popup()
				_grant_single_player_extra_attempt()

func _on_portrait_rewarded_action_rewarded(_currency: String, _amount: int) -> void:
	if _portrait_rewarded_action == &"" or _portrait_rewarded_action_earned:
		return
	_portrait_rewarded_action_earned = true
	# Persist the earned benefit on the SDK's reward callback. Android may kill
	# the process before the later dismiss callback is delivered.
	_grant_portrait_rewarded_action(
		_portrait_rewarded_action,
		_portrait_rewarded_action_level_index
	)
	GameState.reset_interstitial_timer(true)

func _on_portrait_rewarded_action_closed() -> void:
	if _portrait_rewarded_action == &"":
		return
	var action: StringName = _portrait_rewarded_action
	var level_index: int = _portrait_rewarded_action_level_index
	var earned_reward: bool = _portrait_rewarded_action_earned
	GameState.set_fullscreen_ad_active(false)
	_portrait_rewarded_action = &""
	_portrait_rewarded_action_level_index = -1
	_portrait_rewarded_action_earned = false
	if earned_reward and action == &"theme_reroll":
		_present_pending_single_player_theme_ad_reroll(level_index)
	elif !earned_reward:
		_set_portrait_rewarded_action_control_enabled(action, level_index, true)

func _on_portrait_rewarded_action_failed_to_show(_message: String) -> void:
	if _portrait_rewarded_action == &"":
		return
	var action: StringName = _portrait_rewarded_action
	var level_index: int = _portrait_rewarded_action_level_index
	GameState.set_fullscreen_ad_active(false)
	_portrait_rewarded_action = &""
	_portrait_rewarded_action_level_index = -1
	_portrait_rewarded_action_earned = false
	if action == &"theme_reroll":
		_portrait_pending_theme_reroll_presentation = {}
	_set_portrait_rewarded_action_control_enabled(action, level_index, true)
	_show_portrait_ad_not_ready_toast()

func _on_final_reward_double_pressed() -> void:
	if (
		!_portrait_ads_enabled()
		or _portrait_final_reward_claim_in_progress
		or _portrait_final_reward_waiting_for_ad
		or _portrait_rewarded_action != &""
	):
		return
	var ads_service: Node = _portrait_ads_service()
	if ads_service == null or !ads_service.has_method("show_rewarded_video"):
		_show_portrait_ad_not_ready_toast()
		return
	if (
		ads_service.has_method("can_request_rewarded_video")
		and !bool(ads_service.call("can_request_rewarded_video"))
	):
		_show_portrait_ad_not_ready_toast()
		return
	_connect_final_reward_ad_signals(ads_service)
	_portrait_final_reward_waiting_for_ad = true
	_portrait_final_reward_earned_ad_reward = false
	_portrait_final_reward_ad_close_pending = false
	_set_final_reward_double_button_enabled(false)
	if !bool(ads_service.call("show_rewarded_video")):
		# The service starts a preload when an ad is not ready. Keep this request
		# pending: the loaded callback below opens that same ad automatically.
		return
	GameState.set_fullscreen_ad_active(true)

func _connect_final_reward_ad_signals(ads_service: Node) -> void:
	var loaded_callback := Callable(self, "_on_final_reward_ad_loaded")
	if ads_service.has_signal(&"rewarded_video_loaded") and !ads_service.is_connected(
		&"rewarded_video_loaded",
		loaded_callback
	):
		ads_service.connect(&"rewarded_video_loaded", loaded_callback)
	var load_failed_callback := Callable(self, "_on_final_reward_ad_failed_to_load")
	if ads_service.has_signal(&"rewarded_video_failed_to_load") and !ads_service.is_connected(
		&"rewarded_video_failed_to_load",
		load_failed_callback
	):
		ads_service.connect(&"rewarded_video_failed_to_load", load_failed_callback)
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

func _on_final_reward_ad_loaded() -> void:
	if !_portrait_final_reward_waiting_for_ad or _portrait_final_reward_claim_in_progress:
		return
	var ads_service: Node = _portrait_ads_service()
	var ad_shown: bool = (
		ads_service != null
		and ads_service.has_method("show_rewarded_video")
		and bool(ads_service.call("show_rewarded_video"))
	)
	if !ad_shown:
		_portrait_final_reward_waiting_for_ad = false
		_portrait_final_reward_earned_ad_reward = false
		_portrait_final_reward_ad_close_pending = false
		_set_final_reward_double_button_enabled(true)
		_show_portrait_ad_not_ready_toast()
		return
	GameState.set_fullscreen_ad_active(true)

func _on_final_reward_ad_failed_to_load(_error_code: int) -> void:
	if !_portrait_final_reward_waiting_for_ad:
		return
	_portrait_final_reward_waiting_for_ad = false
	GameState.set_fullscreen_ad_active(false)
	_portrait_final_reward_earned_ad_reward = false
	_portrait_final_reward_ad_close_pending = false
	_set_final_reward_double_button_enabled(true)
	_show_portrait_ad_not_ready_toast()

func _on_final_reward_ad_rewarded(_currency: String, _amount: int) -> void:
	if (
		!_portrait_final_reward_waiting_for_ad
		or _portrait_final_reward_earned_ad_reward
	):
		return
	_portrait_final_reward_earned_ad_reward = true
	var ad_already_closed: bool = _portrait_final_reward_ad_close_pending
	# Persist the x2 grant on the SDK reward callback so a process kill cannot
	# lose it. Keep the reward screen alive behind the native ad: Home and its coin
	# animation are presented only after the close callback restores the game.
	_complete_single_player_final_reward(2, false)
	GameState.reset_interstitial_timer(true)
	if ad_already_closed:
		_finish_single_player_final_reward_claim()

func _resolve_final_reward_ad_close_without_reward() -> void:
	# Give a late `rewarded` signal a short grace window after Android restores
	# the game view. This also lets viewport/safe-area resizing settle before the
	# final-reward screen resumes.
	await get_tree().create_timer(
		PORTRAIT_REWARDED_AD_CLOSE_GUARD_SECONDS,
		true,
		false,
		true
	).timeout
	if (
		!_portrait_final_reward_waiting_for_ad
		or !_portrait_final_reward_ad_close_pending
	):
		return
	_portrait_final_reward_ad_close_pending = false
	if _portrait_final_reward_earned_ad_reward:
		_finish_single_player_final_reward_claim()
	else:
		_portrait_final_reward_waiting_for_ad = false
		_set_final_reward_double_button_enabled(true)

func _on_final_reward_ad_closed() -> void:
	if !_portrait_final_reward_waiting_for_ad:
		return
	GameState.set_fullscreen_ad_active(false)
	if _portrait_final_reward_earned_ad_reward:
		_finish_single_player_final_reward_claim()
		return
	_portrait_final_reward_ad_close_pending = true
	call_deferred("_resolve_final_reward_ad_close_without_reward")

func _on_final_reward_ad_failed_to_show(_message: String) -> void:
	if !_portrait_final_reward_waiting_for_ad:
		return
	GameState.set_fullscreen_ad_active(false)
	_portrait_final_reward_waiting_for_ad = false
	_portrait_final_reward_earned_ad_reward = false
	_portrait_final_reward_ad_close_pending = false
	_set_final_reward_double_button_enabled(true)
	_show_portrait_ad_not_ready_toast()

func _claim_single_player_final_reward() -> void:
	_complete_single_player_final_reward(1)

func _play_early_final_reward_coin_claim(source_visual: Control) -> void:
	var previous_balance: int = GameState.get_soft_currency()
	var credited_reward_amount: int = _complete_single_player_final_reward(
		1,
		false,
		false
	)
	if credited_reward_amount <= 0:
		return
	var final_balance: int = previous_balance + credited_reward_amount
	_set_stage_reward_animated_balance(
		float(previous_balance),
		GameState.STAGE_REWARD_COINS
	)
	_play_single_player_reward_coin_collection(source_visual)
	var count_tween := create_tween()
	count_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var roll := count_tween.tween_method(
		Callable(self, "_set_stage_reward_animated_balance").bind(
			GameState.STAGE_REWARD_COINS
		),
		float(previous_balance),
		float(final_balance),
		_single_player_reward_collection_duration()
	)
	roll.set_trans(Tween.TRANS_QUAD)
	roll.set_ease(Tween.EASE_OUT)

func _claim_single_player_final_reward_and_open_next_theme(
	next_level_index: int
) -> void:
	if !_portrait_final_reward_claim_in_progress:
		_complete_single_player_final_reward(1, false, false)
	_finish_single_player_final_reward_claim(next_level_index)

func _complete_single_player_final_reward(
	reward_multiplier: int,
	present_immediately: bool = true,
	queue_home_animation: bool = true
) -> int:
	if _portrait_final_reward_claim_in_progress:
		return 0
	_portrait_final_reward_claim_in_progress = true
	var credited_reward_amount: int = GameState.claim_pending_single_player_reward(
		maxi(reward_multiplier, 1)
	)
	if credited_reward_amount > 0 and queue_home_animation:
		_portrait_pending_home_reward_amount += credited_reward_amount
	if present_immediately:
		_finish_single_player_final_reward_claim()
	return credited_reward_amount

func _finish_single_player_final_reward_claim(next_theme_level_index: int = -1) -> void:
	_stop_final_reward_continue_attention()
	if next_theme_level_index < 0:
		var completed_level_index: int = int(last_result_data.get(
			"single_player_level_index",
			single_player_active_level_index
		))
		next_theme_level_index = _direct_theme_level_after_completed_level(
			completed_level_index
		)
	GameState.set_fullscreen_ad_active(false)
	_portrait_final_reward_waiting_for_ad = false
	_portrait_final_reward_earned_ad_reward = false
	_portrait_final_reward_ad_close_pending = false
	GameSession.discard_current_round()
	game_finished = false
	last_result_data = {}
	single_player_active_word_slot = -1
	if next_theme_level_index >= 0:
		# Levels 1 and 2 continue directly from the final-reward presentation. Keep
		# that screen alive as the dimmed backdrop instead of briefly rebuilding Home.
		# The balance label has already been updated by GameState, so this reward must
		# not be replayed later as a delayed Home collection animation.
		_portrait_pending_home_reward_amount = 0
		_show_single_player_level_popup(next_theme_level_index, -1, false, true)
		return
	show_menu()

func _set_home_reward_animated_balance(value: float) -> void:
	var balance_text: String = _soft_currency_balance_text(int(round(value)))
	for balance_node: Node in get_tree().get_nodes_in_group(&"soft_currency_balance_label"):
		var balance_label := balance_node as Label
		if balance_label != null and is_instance_valid(balance_label):
			balance_label.text = balance_text

func _play_pending_home_reward_animation() -> void:
	if _portrait_pending_home_reward_animation_running:
		return
	if _portrait_pending_home_reward_amount <= 0:
		return
	_portrait_pending_home_reward_animation_running = true

	# The Home tree, safe-area offset and ad banner can all settle over several
	# frames on a real device. Do not consume the pending presentation until the
	# destination coin icon actually exists. If Home is rebuilt during this
	# window, the saved reward remains untouched and the animation can retry on
	# the next Home entry.
	var destination_ready: bool = false
	for _frame_index: int in range(8):
		await get_tree().process_frame
		if (
			_portrait_currency_coin_icon_visual != null
			and is_instance_valid(_portrait_currency_coin_icon_visual)
			and _portrait_currency_coin_icon_visual.is_inside_tree()
		):
			destination_ready = true
			break
	if !destination_ready:
		_portrait_pending_home_reward_animation_running = false
		return

	var reward_amount: int = _portrait_pending_home_reward_amount
	_portrait_pending_home_reward_amount = 0
	_portrait_pending_home_reward_animation_running = false
	if reward_amount <= 0:
		return

	# The reward has already been persisted by _complete_single_player_final_reward().
	# Reconstruct the visual start value instead of touching GameState again.
	var final_balance: int = GameState.get_soft_currency()
	var previous_balance: int = maxi(final_balance - reward_amount, 0)
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
	var is_failed_final_stage: bool = (
		is_failure_reward
		and bool(last_result_data.get("single_player_level_completed", false))
		and current_slot == word_count - 1
	)
	# Quiz slots do not keep an active GameSession round, so GameSession.theme_id
	# is -1 by the time their reward screen is shown. Resolve the reward theme
	# from the level definition and retain the active round as a safe fallback.
	var reward_theme_index: int = _single_player_level_selected_theme(level_index)
	if reward_theme_index < 0:
		reward_theme_index = GameSession.theme_id
	if is_final_reward:
		_portrait_final_reward_claim_in_progress = false
		_portrait_final_reward_waiting_for_ad = false
		_portrait_final_reward_earned_ad_reward = false
		_portrait_final_reward_ad_close_pending = false
	var challenge_level: bool = _single_player_is_bonus_level(level_index)
	var header_color: Color = PORTRAIT_CHALLENGE_POPUP_HEADER if challenge_level else PORTRAIT_BLUE
	var accent_color: Color = StageLetterButton.CIRCLED_COLOR
	var resume_without_intro: bool = _portrait_single_reward_resume_without_intro
	_portrait_single_reward_resume_without_intro = false
	var result_title_color: Color = PORTRAIT_SINGLE_REWARD_SUCCESS_TITLE_COLOR
	if is_failure_reward and !is_failed_final_stage:
		result_title_color = PORTRAIT_SINGLE_REWARD_FAILURE_TITLE_COLOR

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
	var level_title_text: String = (tr("LEVEL_NUMBER") % (level_index + 1)).to_upper()
	var result_heading_text: String = tr("REWARD_STAGE_COMPLETED")
	if is_final_reward:
		result_heading_text = tr("REWARD_MAIN_PRIZE")
	elif is_failed_final_stage:
		result_heading_text = tr("REWARD_LEVEL_FINISHED")
	elif is_failure_reward:
		result_heading_text = tr("REWARD_STAGE_FAILED")
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
		# The animated theme pattern belongs only to the main reward body. Keep it
		# below the top currency bar and below the dark reward header strip, so it
		# does not bleed into the upper bar area.
		var final_reward_pattern_top: float = (
			PORTRAIT_SINGLE_REWARD_TITLE_BLOCK_TOP_RECT.position.y
			+ PORTRAIT_SINGLE_REWARD_TITLE_BLOCK_TOP_RECT.size.y
		)
		final_reward_background_overlay = _stage_horizontal_fill(
			final_reward_pattern_top,
			PORTRAIT_STAGE_SIZE.y - final_reward_pattern_top,
			PORTRAIT_SINGLE_REWARD_TITLE_BLOCK_COLOR
		)
		final_reward_background_overlay.name = "FinalRewardBackgroundOverlay"
		final_reward_background_overlay.modulate.a = 0.0
		# Keep the themed backdrop above the screen base background so the
		# animated pattern remains visible, but still behind the reward content
		# that is added afterwards.
		final_reward_background_overlay.z_index = 0
		_add_final_reward_theme_pattern(final_reward_background_overlay, reward_theme_index)
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
	_stage_coin_and_star_counters(
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
	var active_stage_reward: Dictionary = GameState.get_active_single_player_stage_reward()
	var current_reward_already_claimed: bool = bool(
		active_stage_reward.get("claimed", false)
	)
	var animate_current_claim: bool = (
		!is_failure_reward
		and !is_final_reward
		and !active_stage_reward.is_empty()
		and !current_reward_already_claimed
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

	var current_reward_resource_visual: Control = null
	var current_reward_count_visual: Label = null
	var current_reward_check_icon: Control = null
	var current_reward_resource_stage_rect := Rect2()
	var current_reward_currency: String = GameState.STAGE_REWARD_COINS
	var failure_reward_cross_visual: Control = null
	var failed_final_reward_crown_visual: Control = null
	for word_slot in range(word_count):
		var node_size: float = float(node_sizes[word_slot])
		var node_x: float = float(node_positions_x[word_slot])
		var node_y: float = chain_center_y - node_size * 0.5

		var is_previous: bool = word_slot < current_slot
		var is_current: bool = word_slot == current_slot
		var slot_status: int = _single_player_level_word_status(level_index, word_slot)
		var is_failed_slot: bool = slot_status == 2
		var is_failed_current: bool = is_failed_slot and is_current
		var reward_currency: String = _single_player_stage_reward_currency(
			level_index,
			word_slot,
			word_count
		)
		var reward_amount: int = _single_player_reward_for_slot(
			level_index,
			word_slot,
			word_count
		)
		# Reward amounts start fully white. Once a reward is claimed, the checkmark
		# dims both its resource icon and xN; future rewards stay white.
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
			is_failed_slot,
			accent_color,
			header_color
		)
		var local_node_rect := Rect2(Vector2.ZERO, Vector2.ONE * node_size)
		var crown_visual: Control = null
		if word_slot == word_count - 1:
			crown_visual = _stage_single_player_reward_crown(node_holder, local_node_rect)
			if is_failed_current:
				failed_final_reward_crown_visual = crown_visual
		# Scale the reward art by the same authored factor as its tile. The current
		# tile is 4/3 larger than a side tile, so its resource icon follows it.
		var resource_size: float = maxf(
			node_size * PORTRAIT_SINGLE_REWARD_CHAIN_ICON_SCALE,
			30.0
		)
		var resource_rect := Rect2(
			(node_size - resource_size) * 0.5,
			(node_size - resource_size) * 0.5 - 4.0,
			resource_size,
			resource_size
		)
		var resource_visual := _stage_single_player_reward_resource_icon(
			node_holder,
			resource_rect,
			reward_currency
		)
		var is_claimed: bool = (
			(is_previous and slot_status == 1)
			or (
				is_current
				and !is_final_reward
				and current_reward_already_claimed
				and !is_failed_current
			)
		)
		if is_failed_slot:
			var failed_cross := _stage_single_player_reward_status_icon(
				node_holder,
				local_node_rect,
				is_current,
				false
			)
			if is_current:
				failure_reward_cross_visual = failed_cross
		elif is_claimed:
			_stage_single_player_reward_status_icon(node_holder, local_node_rect)
		elif is_current and !is_final_reward:
			current_reward_resource_visual = resource_visual
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
			resource_rect,
			reward_amount,
			count_font_size,
			count_color
		)
		if is_claimed or is_failed_slot:
			# Claimed and failed rewards keep both the icon and xN inactive.
			# Future rewards stay white.
			resource_visual.modulate.a = PORTRAIT_SINGLE_REWARD_CHECK_COIN_DIM_ALPHA
			count_visual.modulate.a = PORTRAIT_SINGLE_REWARD_CHECK_COIN_DIM_ALPHA
		elif is_current:
			current_reward_resource_visual = resource_visual
			current_reward_count_visual = count_visual
			current_reward_resource_stage_rect = Rect2(
				node_rect.position + resource_rect.position,
				resource_rect.size
			)
			current_reward_currency = reward_currency

	var continue_button: Control = null
	var final_reward_completion := Callable()
	if is_final_reward:
		var reward_amount: int = int(last_result_data.get(
			"single_player_deferred_reward_amount",
			_single_player_reward_for_slot(level_index, current_slot, word_count)
		))
		if reward_amount <= 0:
			reward_amount = _single_player_reward_for_slot(
				level_index,
				current_slot,
				word_count
			)
		var target_coin_rect: Rect2 = _portrait_final_reward_center_rect(
			PORTRAIT_FINAL_REWARD_COIN_SIZE
		)
		var target_glow_rect: Rect2 = Rect2(
			target_coin_rect.get_center() - PORTRAIT_FINAL_REWARD_GLOW_SIZE * 0.5,
			PORTRAIT_FINAL_REWARD_GLOW_SIZE
		)
		var glow := _stage_final_reward_glow(target_glow_rect)
		var transition_pack := _stage_texture(
			current_reward_resource_stage_rect,
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
		var final_action_button: Control
		var collect_holder: Control = null
		var collect_button: Button = null
		var opens_next_theme_directly: bool = (
			level_index + 1 <= PORTRAIT_FINAL_REWARD_DIRECT_THEME_THROUGH_LEVEL
		)
		if _portrait_ads_enabled():
			final_action_button = _stage_main_button(
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
			final_action_button.name = "FinalRewardDoubleButton"
			final_action_button.set_meta(&"single_shine_after_reveal", true)
			_configure_final_reward_double_button(final_action_button, reward_amount)
			_portrait_final_reward_double_button = final_action_button
			var collect_controls: Dictionary = _stage_final_reward_collect_text(
				PORTRAIT_FINAL_REWARD_COLLECT_RECT,
				level_index + 1
			)
			collect_holder = collect_controls.get("holder") as Control
			collect_button = collect_controls.get("button") as Button
		else:
			var continue_action := Callable(self, "_claim_single_player_final_reward")
			if opens_next_theme_directly:
				continue_action = Callable(
					self,
					"_claim_single_player_final_reward_and_open_next_theme"
				).bind(level_index + 1)
			final_action_button = _stage_main_button(
				PORTRAIT_FINAL_REWARD_DOUBLE_BUTTON_RECT,
				continue_action,
				tr("COMMON_CONTINUE"),
				22,
				false,
				0.32,
				false,
				false,
				false,
				LONG_BUTTON_COLOR_ORANGE
			)
			final_action_button.name = "FinalRewardContinueButton"
			_portrait_final_reward_continue_button = final_action_button
			final_action_button.set("attention_bounce_enabled", false)
			final_action_button.set_meta(
				&"attention_after_reveal",
				opens_next_theme_directly
			)
		final_action_button.modulate.a = 0.0
		final_action_button.z_index = 120
		final_action_button.set("button_disabled", true)
		content = final_reward_content
		final_reward_completion = Callable(
			self,
			"_start_single_player_final_reward_transition_deferred"
		).bind(
			chain_holder,
			hero_mask,
			hero_texture,
			current_reward_resource_visual,
			current_reward_count_visual,
			transition_pack,
			final_reward_background_overlay,
			title_panel,
			glow,
			caption_label,
			amount_label,
			target_coin_rect,
			final_action_button,
			collect_holder,
			collect_button,
			opens_next_theme_directly and !_portrait_ads_enabled()
		)
	else:
		# Put the reward CTA in the same bottom-attached coordinate space as the
		# gameplay retry/continue CTA.
		var reward_content: Control = _portrait_begin_bottom_attached_group()
		continue_button = _stage_main_button(
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
		_portrait_single_reward_continue_button = continue_button
		content = reward_content
	content = reward_screen_content
	var failure_back_button: Control = null
	if (
		!is_final_reward
		and !_single_player_hides_close_controls(level_index)
	):
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

	call_deferred(
		"_start_single_player_reward_intro_deferred",
		title_block,
		title_visual,
		hero_mask,
		hero_texture,
		reward_body,
		reward_hud_content,
		animate_current_claim,
		current_reward_resource_visual,
		current_reward_count_visual,
		current_reward_check_icon,
		failure_reward_cross_visual,
		failed_final_reward_crown_visual,
		continue_button,
		current_reward_currency,
		final_reward_completion
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
	if !last_result_is_win and GameState.get_hearts() <= 0:
		_show_heart_refill_popup(
			Callable(self, "_continue_single_player_stage_after_refill").bind(level_index),
			Callable(self, "_return_to_single_player_reward_from_coin_store"),
			Callable(self, "_cancel_single_player_stage_heart_refill").bind(level_index)
		)
		return
	if level_completed:
		_finish_completed_single_player_stage_result()
		return
	_start_next_single_player_word(level_index)

func _continue_single_player_stage_after_refill(level_index: int) -> void:
	if GameState.get_hearts() <= 0:
		return
	if bool(last_result_data.get("single_player_level_completed", false)):
		_finish_completed_single_player_stage_result()
		return
	_start_next_single_player_word(level_index)

func _direct_theme_level_after_completed_level(level_index: int) -> int:
	if (
		level_index >= 0
		and level_index + 1 <= PORTRAIT_FINAL_REWARD_DIRECT_THEME_THROUGH_LEVEL
	):
		return level_index + 1
	return -1

func _finish_completed_single_player_stage_result(open_next_theme_popup: bool = true) -> void:
	var completed_level_index: int = int(last_result_data.get(
		"single_player_level_index",
		single_player_active_level_index
	))
	var next_theme_level_index: int = (
		completed_level_index + 1 if completed_level_index >= 0 else -1
	)
	GameState.clear_active_single_player_session(true)
	GameSession.discard_current_round()
	game_finished = false
	last_result_data = {}
	single_player_active_word_slot = -1
	if open_next_theme_popup and next_theme_level_index >= 0:
		_stop_single_reward_continue_attention()
		_show_single_player_level_popup(next_theme_level_index, -1, false, true)
		return
	show_menu()

func _cancel_single_player_stage_heart_refill(level_index: int) -> void:
	# Closing without a coin or rewarded-ad refill discards the whole attempt,
	# even if the passive timer happened to restore a heart while the popup was open.
	GameState.reset_single_level_attempt(
		Database.current_language,
		level_index,
		true,
		true,
		false
	)
	GameState.relock_single_player_level_if_latest(
		Database.current_language,
		level_index,
		false
	)
	GameState.save_game()
	_invalidate_single_player_level_cache()
	GameSession.discard_current_round()
	game_finished = false
	last_result_data = {}
	single_player_active_word_slot = -1
	show_menu()

func _leave_single_player_failure_reward_to_menu() -> void:
	# Once every stage has been played, the reward-chain X is an alternative
	# completion action, not an interrupted level. Clear the resumable snapshot
	# exactly like Continue does, but go straight Home instead of opening the
	# next-theme popup. Earlier reward nodes remain resumable when leaving mid-level.
	if bool(last_result_data.get("single_player_level_completed", false)):
		_finish_completed_single_player_stage_result(false)
		return
	_discard_round_for_navigation()
	show_menu()

func _continue_single_player_result() -> void:
	# Both outcomes use the reward-chain interstitial. A failed stage shows its
	# missed reward, then Continue advances through the same level chain.
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
	_show_profile_screen()

func _show_profile_screen() -> void:
	coin_store_return_action = Callable()
	_clear()
	_portrait_screen(0.0)
	_stage_portrait_page_header(
		tr("NAV_PROFILE").to_upper(),
		Callable(self, "show_menu"),
		Callable(self, "show_profile")
	)

	var profile_root_content: Control = _portrait_begin_adaptive_group(Vector2(240.0, 430.0), PORTRAIT_PROFILE_MAX_SCALE, 0.08)
	_stage_profile_header_card()
	_stage_label(Rect2(26.0, 310.0, 428.0, 40.0), tr("RECORDS_TITLE").to_upper(), 27, PORTRAIT_BLUE, HORIZONTAL_ALIGNMENT_LEFT)
	_portrait_profile_stat_row(392.0, tr("MENU_CLASSIC"), tr("RECORD_EASY_STREAK"), int(GameState.records[0][2]), tr("RECORD_HARD_STREAK"), int(GameState.records[0][3]))
	_portrait_end_adaptive_group(profile_root_content)
	_stage_portrait_ad_banner()

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
			# Keep the colored source art neutral behind the popup while retaining its
			# richer authored silhouette and internal details.
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
	var comment_popup_title: String = (
		Database.get_theme_name(GameSession.theme_id)
		if GameState.current_mode != GameState.GameMode.TWO_PLAYER and GameSession.theme_id >= 0
		else Database.tr_text(40, "Word from player")
	)
	_portrait_popup_shell(
		rect,
		comment_popup_title,
		Callable(self, "_remove_word_comment_popup"),
		30,
		PORTRAIT_BLUE,
		PORTRAIT_DARK_BLUE,
		PORTRAIT_ORANGE,
		tr("COMMENT").to_upper()
	)
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
