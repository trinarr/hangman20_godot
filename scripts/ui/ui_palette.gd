class_name UIPalette
extends RefCounted

# Central UI palette.
# Change gameplay/interface colors here instead of hardcoding Color(...) values
# in individual screens or controls.

# Core blue UI.
const UI_BLUE := Color("#454F9B")
const UI_BLUE_DARK := Color("#3B4384")
const UI_BLUE_RULE := Color(0.3157, 0.3765, 0.6902, 0.95)
const UI_BLUE_LIGHT_BORDER := Color("#B8C4E8")
const UI_BLUE_EFFECT := Color("#6B7DD1")
const TEXT_SECONDARY := Color("#D1DBFF")
const TEXT_DARK := Color("#121A52")
const TEXT_SHADOW_DARK := Color(0.02, 0.04, 0.16, 0.30)
const TEXT_PALE_BLUE := Color(0.78, 0.82, 0.96, 0.88)
const HEART_TEXT_OUTLINE := Color(0.08, 0.04, 0.06, 0.95)
const NAV_TEXT_OUTLINE := Color(0.08, 0.12, 0.34, 0.92)
const NAV_TEXT_SHADOW := Color(0.05, 0.08, 0.24, 0.72)

# Standard buttons.
const BUTTON_BLUE := Color("#728EFF")
const BUTTON_BLUE_PRESSED := Color("#5B74E0")
const BUTTON_BLUE_SELECTED := Color("#4B61C7")
const BUTTON_BLUE_OUTLINE := Color("#2F438C")
const BUTTON_ORANGE := Color("#FEB06A")
const BUTTON_ORANGE_PRESSED := Color("#DC8446")
# Historical selected treatment shared by orange/green presets.
const BUTTON_SELECTED_ACCENT := Color("#8CA1FF")
const ACCENT_ORANGE := Color("#D09057")
const DISABLED := Color("#999999")
const DISABLED_OPACITY: float = 0.85

# Rewarded ads.
const AD_PURPLE := Color("#BB11E0")
const AD_PURPLE_PRESSED := Color("#9710B5")
const AD_PURPLE_SELECTED := Color("#86109F")

# Success / failure semantics.
const SUCCESS := Color("#21D44A")
const SUCCESS_PRESSED := Color("#1AA338")
const SUCCESS_SELECTED := Color("#1DBB41")
const SUCCESS_SOFT := Color("#56D782")
const SUCCESS_BORDER := Color("#167A34")
const ERROR := Color("#FA3338")
const ERROR_SOFT := Color("#F45B77")
const PRICE_ERROR := Color("#FF5C6D")

# Challenge / hard-mode palette.
const CHALLENGE_NORMAL := Color("#D866FE")
const CHALLENGE_PRESSED := Color("#B44AD9")
const CHALLENGE_SELECTED := Color("#9638B9")
const CHALLENGE_OUTLINE := Color("#68267A")
const CHALLENGE_BODY := Color("#4A2158")
const CHALLENGE_THEME_CARD := Color("#642B74")
const CHALLENGE_THEME_CARD_SELECTED := Color("#7C3590")
const CHALLENGE_HUD_PANEL := Color("#642A75")
const CHALLENGE_HUD_BORDER := Color("#E19AF4")
const CHALLENGE_TEXT := Color("#FAE8FF")

# Theme cards.
const THEME_CARD_BASE := Color("#29337A")
const THEME_CARD_BASE_CHALLENGE := Color("#303D8F")
const THEME_CARD := Color("#4C59AD")
const THEME_CARD_SELECTED := Color("#616EC2")
const THEME_CARD_PRESSED := Color("#B8B8B8")
const THEME_PROGRESS_TEXT := Color("#6E7DD4")
const PRESS_HIGHLIGHT := Color("#B8C4FA")

# Reward screen and result markers.
const REWARD_HEADER := Color("#6371CB")
const REWARD_CHAIN := Color("#2E73C9")
const REWARD_GOLD := Color("#FFD84A")
const REWARD_GOLD_DARK := Color("#F3A928")
const REWARD_GOLD_OUTLINE := Color("#173A7A")
const MARKER_SUCCESS := Color("#86DE8A")
const MARKER_ERROR := Color("#FF99A2")

# Profile / neutral surfaces.
const NEUTRAL_SURFACE := Color("#F7F7FA")
const NEUTRAL_BORDER := Color("#B8BFD1")
const NEUTRAL_TEXT := Color("#6E758A")
const PROFILE_HALO := Color(0.42, 0.48, 0.82, 0.95)
const PROFILE_HALO_IDLE := Color(0.32, 0.37, 0.67, 0.50)

# Decorative paper accents.
const PAPER_CRACK_DARK := Color("#1C2661")
const PAPER_CRACK_LIGHT := Color("#FFF2C7")

# Small status surfaces.
const TOAST_BACKGROUND := Color(0.2314, 0.2627, 0.5176, 0.96)

static func with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)
