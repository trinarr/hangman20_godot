extends RefCounted
## Geometry shared by the HUD currency counters and leaderboard scores.
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
