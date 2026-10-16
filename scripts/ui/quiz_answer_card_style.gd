extends RefCounted
## Shared native card face used by quiz answers and leaderboard rows.
const LONG_BUTTON = preload("res://scripts/ui/stage_long_button.gd")

static func face_style(fill: Color = Color.WHITE) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(32)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

static func shadow_style() -> StyleBoxFlat:
	var style := face_style(LONG_BUTTON.BUTTON_DROP_SHADOW_COLOR)
	return style
