extends RefCounted

const BASE_SIZE: Vector2 = Vector2(480.0, 800.0)
const FIXED_BOTTOM_START: float = 688.0
const ADAPTIVE_REFERENCE_HEIGHT: float = 1068.0
const SAFE_TOP_EXTRA_MARGIN: float = 8.0

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

static func safe_top_inset_pixels(viewport_size: Vector2) -> float:
	# DisplayServer reports the unobscured display rectangle on Android and iOS.
	# Convert its top edge from window pixels to the current root viewport size.
	if !(OS.has_feature("android") or OS.has_feature("ios")):
		return 0.0
	var safe_rect: Rect2i = DisplayServer.get_display_safe_area()
	var window_size: Vector2i = DisplayServer.window_get_size()
	if safe_rect.size.y <= 0 or window_size.x <= 0 or window_size.y <= 0:
		return 0.0
	var window_position: Vector2i = DisplayServer.window_get_position()
	var local_safe_top: float = maxf(0.0, float(safe_rect.position.y - window_position.y))
	if local_safe_top <= 0.0:
		return 0.0
	return local_safe_top * viewport_size.y / float(window_size.y)

static func safe_top_stage(viewport_size: Vector2) -> float:
	var inset_pixels: float = safe_top_inset_pixels(viewport_size)
	if inset_pixels <= 0.0:
		return 0.0
	var scale_value: float = fit_scale(viewport_size)
	if scale_value <= 0.0:
		return 0.0
	return inset_pixels / scale_value + SAFE_TOP_EXTRA_MARGIN

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

static func is_inside_bottom_attached_group(node: Node) -> bool:
	var current: Node = node.get_parent()
	while current != null:
		if current.name == &"PortraitBottomAttached":
			return true
		current = current.get_parent()
	return false

static func map_y(stage_y: float, viewport_size: Vector2, node: Node = null) -> float:
	# Keep authored sizes intact. Regular screen content is translated below the
	# camera/notch safe area, while the footer remains pinned to the physical
	# bottom. Centered popups perform their own safe-area centering.
	if node != null and is_inside_centered_popup(node):
		return stage_y
	if node != null and is_inside_bottom_attached_group(node):
		return stage_y + extra_stage_height(viewport_size)
	if stage_y < FIXED_BOTTOM_START:
		return stage_y + safe_top_stage(viewport_size)
	return stage_y + extra_stage_height(viewport_size)

static func map_fill_y(stage_y: float, viewport_size: Vector2) -> float:
	# Full-screen backgrounds and top header fills must still begin at the real
	# screen edge. Only bottom fills follow the rigid footer translation.
	if stage_y < FIXED_BOTTOM_START:
		return stage_y
	return stage_y + extra_stage_height(viewport_size)

static func map_rect_position(stage_rect: Rect2, viewport_size: Vector2, node: Node = null) -> Vector2:
	if node != null and is_inside_centered_popup(node):
		return stage_rect.position
	if node != null and is_inside_bottom_attached_group(node):
		return Vector2(stage_rect.position.x, stage_rect.position.y + extra_stage_height(viewport_size))
	var mapped_y: float = stage_rect.position.y
	if stage_rect.position.y >= FIXED_BOTTOM_START:
		mapped_y += extra_stage_height(viewport_size)
	else:
		mapped_y += safe_top_stage(viewport_size)
	return Vector2(stage_rect.position.x, mapped_y)
