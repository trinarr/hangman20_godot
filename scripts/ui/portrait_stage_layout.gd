extends RefCounted

const BASE_SIZE: Vector2 = Vector2(480.0, 800.0)
const FIXED_BOTTOM_START: float = 688.0
const ADAPTIVE_REFERENCE_HEIGHT: float = 1068.0

static func fit_scale(viewport_size: Vector2) -> float:
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return 1.0
	return min(viewport_size.x / BASE_SIZE.x, viewport_size.y / BASE_SIZE.y)

static func horizontal_offset(viewport_size: Vector2) -> float:
	var scale_value: float = fit_scale(viewport_size)
	return (viewport_size.x - BASE_SIZE.x * scale_value) * 0.5

static func expanded_stage_height(viewport_size: Vector2) -> float:
	var scale_value: float = fit_scale(viewport_size)
	if scale_value <= 0.0:
		return BASE_SIZE.y
	return viewport_size.y / scale_value

static func extra_stage_height(viewport_size: Vector2) -> float:
	return maxf(0.0, expanded_stage_height(viewport_size) - BASE_SIZE.y)

static func adaptive_ui_scale(viewport_size: Vector2, max_scale: float = 1.15) -> float:
	var clamped_max: float = maxf(1.0, max_scale)
	var logical_height: float = expanded_stage_height(viewport_size)
	if logical_height <= BASE_SIZE.y:
		return 1.0
	var progress: float = inverse_lerp(BASE_SIZE.y, ADAPTIVE_REFERENCE_HEIGHT, logical_height)
	return lerpf(1.0, clamped_max, clampf(progress, 0.0, 1.0))

static func is_inside_centered_popup(node: Node) -> bool:
	var current: Node = node.get_parent()
	while current != null:
		if current.name == &"CenteredPopupStage":
			return true
		current = current.get_parent()
	return false

static func map_y(stage_y: float, viewport_size: Vector2, node: Node = null) -> float:
	# Keep every UI element at its authored 480x800 size and position. Only the
	# footer region is translated as one rigid block to the physical bottom edge.
	# The extra portrait height is therefore filled exclusively by the tiled
	# background; no controls, cards, characters or spacing are stretched.
	if node != null and is_inside_centered_popup(node):
		return stage_y
	if stage_y < FIXED_BOTTOM_START:
		return stage_y
	return stage_y + extra_stage_height(viewport_size)

static func map_rect_position(stage_rect: Rect2, viewport_size: Vector2, node: Node = null) -> Vector2:
	if node != null and is_inside_centered_popup(node):
		return stage_rect.position
	var mapped_y: float = stage_rect.position.y
	if stage_rect.position.y >= FIXED_BOTTOM_START:
		mapped_y += extra_stage_height(viewport_size)
	return Vector2(stage_rect.position.x, mapped_y)
