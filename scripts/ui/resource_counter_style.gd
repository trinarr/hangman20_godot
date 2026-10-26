extends RefCounted
## Geometry and icon shadow shared by HUD counters and leaderboard scores.
const PALETTE = preload("res://scripts/ui/ui_palette.gd")
const ICON_SHADOW_ALPHA := PALETTE.NAV_TEXT_SHADOW.a * 0.3
const PANEL_WIDTH_SCALE := 0.84
const PANEL_HEIGHT_SCALE := 0.80
const TRAILING_INSET := 6.0
const FONT_SCALE := 0.90
const ICON_SIZE := 36.6597
const STAR_ICON_OFFSET := Vector2(-2, -1)

static func panel_rect(rect: Rect2) -> Rect2:
	var panel_size := rect.size * Vector2(PANEL_WIDTH_SCALE, PANEL_HEIGHT_SCALE)
	var right := rect.end.x - 2.0 * rect.size.y / 48.0
	return Rect2(Vector2(right - panel_size.x, rect.get_center().y - panel_size.y * 0.5), panel_size)

static func value_rect(rect: Rect2) -> Rect2:
	var factor := rect.size.y / 48.0
	var panel := panel_rect(rect)
	var left := rect.position.x + 43.0 * factor
	var right := panel.end.x - TRAILING_INSET * factor
	return Rect2(Vector2(left, panel.position.y), Vector2(maxf(1.0, right - left), panel.size.y))
