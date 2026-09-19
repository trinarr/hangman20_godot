class_name StageLongButton
extends "res://scripts/ui/flash_stage_texture_button.gd"

const BUTTON_TEXT_STYLE_SCRIPT: GDScript = preload("res://scripts/ui/button_text_style.gd")
const UI_PALETTE: GDScript = preload("res://scripts/ui/ui_palette.gd")
const UI_FONTS: GDScript = preload("res://scripts/ui/ui_fonts.gd")
const GAME_DESIGN: GDScript = preload("res://scripts/core/game_design_config.gd")
const UI_MATERIALS: GDScript = preload("res://scripts/ui/ui_materials.gd")

const ICON_SHADOW_DEPTH_RATIO: float = 0.055
const ICON_SHADOW_DEPTH_MIN: float = 1.5
const ICON_SHADOW_DEPTH_MAX: float = 5.0
const ICON_SHADOW_OFFSET_X_RATIO: float = 0.012
const ICON_SHADOW_OFFSET_X_MAX: float = 1.5
const ICON_SHADOW_LAYER_T := [0.25, 0.55, 0.80, 1.0]

const NORMAL_LEFT_TEXTURE: Texture2D = preload("res://flash_assets/user_main_button_21_left.png")
const NORMAL_CENTER_TEXTURE: Texture2D = preload("res://flash_assets/user_main_button_21_center.png")
const NORMAL_RIGHT_TEXTURE: Texture2D = preload("res://flash_assets/user_main_button_21_right.png")
const PRESSED_LEFT_TEXTURE: Texture2D = preload("res://flash_assets/user_main_button_23_left.png")
const PRESSED_CENTER_TEXTURE: Texture2D = preload("res://flash_assets/user_main_button_23_center.png")
const PRESSED_RIGHT_TEXTURE: Texture2D = preload("res://flash_assets/user_main_button_23_right.png")

var _attention_bounce_scale_value: float = GAME_DESIGN.get_float_range(
	"timings.animations.button_attention.long.scale", 1.07, 1.0, 1.5
)
var _attention_bounce_grow_duration: float = GAME_DESIGN.get_float(
	"timings.animations.button_attention.long.grow_seconds", 0.8
)
var _attention_bounce_settle_duration: float = GAME_DESIGN.get_float(
	"timings.animations.button_attention.long.settle_seconds", 0.85
)
var _attention_bounce_count: int = GAME_DESIGN.get_int_range(
	"timings.animations.button_attention.bounce_count", 2, 1, 8
)
var _attention_bounce_speed_multiplier: float = GAME_DESIGN.get_float_range(
	"timings.animations.button_attention.speed_multiplier", 1.5, 0.1, 10.0
)
var _attention_shine_duration: float = GAME_DESIGN.get_float(
	"timings.animations.button_attention.shine_seconds", 0.55
)
var _attention_cycle_pause_duration: float = GAME_DESIGN.get_float(
	"timings.animations.button_attention.pause_seconds", 0.1
)
var _attention_shine_width: float = GAME_DESIGN.get_float_range(
	"timings.animations.button_attention.shine_width", 0.16, 0.01, 1.0
)
var _attention_shine_strength: float = GAME_DESIGN.get_float_range(
	"timings.animations.button_attention.shine_strength", 0.42, 0.0, 1.0
)

enum ColorPreset {
	ORANGE,
	GREEN,
	BLUE,
	CUSTOM,
}

# The PNGs are neutral grayscale masks. These tints restore the original
# orange/blue visual language while allowing other palettes to reuse the same
# button slices without recoloring the source assets.
const ORANGE_NORMAL_TINT := UI_PALETTE.BUTTON_ORANGE
const ORANGE_PRESSED_TINT := UI_PALETTE.BUTTON_ORANGE_PRESSED
const ORANGE_SELECTED_TINT := UI_PALETTE.BUTTON_SELECTED_ACCENT
# Match the bright green used for a correctly guessed letter.
const GREEN_NORMAL_TINT := UI_PALETTE.SUCCESS
const GREEN_PRESSED_TINT := UI_PALETTE.SUCCESS_PRESSED
const GREEN_SELECTED_TINT := UI_PALETTE.SUCCESS_SELECTED
const BLUE_NORMAL_TINT := UI_PALETTE.BUTTON_BLUE
const BLUE_PRESSED_TINT := UI_PALETTE.BUTTON_BLUE_PRESSED
const BLUE_SELECTED_TINT := UI_PALETTE.BUTTON_BLUE_SELECTED
const BLUE_OUTLINE_COLOR := UI_PALETTE.BUTTON_BLUE_OUTLINE
const DEFAULT_OUTLINE_COLOR := UI_PALETTE.UI_BLUE_DARK
const DISABLED_TINT := UI_PALETTE.DISABLED
const DISABLED_OPACITY: float = UI_PALETTE.DISABLED_OPACITY
# Opt-in drop shadow used by the primary reward/result CTAs. Keep its press
# response identical to the round hint buttons: 4 px at rest, 3 px while held,
# with the held shadow 15% lighter.
const BUTTON_DROP_SHADOW_COLOR := Color(0.07, 0.12, 0.24, 0.22)
const BUTTON_DROP_SHADOW_PRESSED_COLOR := Color(0.07, 0.12, 0.24, 0.187)
const BUTTON_DROP_SHADOW_OFFSET_Y: float = 3.5
const BUTTON_DROP_SHADOW_PRESSED_OFFSET_Y: float = 3.0
const BUTTON_DROP_SHADOW_UNDERLAP_Y: float = 1.5
# Let the stretchable center run slightly underneath both end caps. The caps are
# drawn afterwards, so this only fills their translucent inner seam pixels and
# prevents the three-slice construction from showing through on faded buttons.
const BUTTON_SLICE_OVERLAP: float = 1.5
const BUTTON_CAP_INNER_TRIM: float = 2.0

var drop_shadow_enabled: bool = false:
	set(value):
		drop_shadow_enabled = value
		queue_redraw()

# Settings selectors use the pressed-depth shadow while selected, so the blue
# state reads as physically engaged even before the user touches it again.
var drop_shadow_selected_uses_pressed_state: bool = false:
	set(value):
		drop_shadow_selected_uses_pressed_state = value
		queue_redraw()

var attention_bounce_enabled: bool = false:
	set(value):
		if attention_bounce_enabled == value:
			return
		attention_bounce_enabled = value
		if attention_bounce_enabled:
			_start_attention_bounce()
		else:
			_stop_attention_bounce(true)

var button_text: String = "":
	set(value):
		button_text = value.to_upper()
		_sync_label()

var button_font_size: int = 20:
	set(value):
		button_font_size = value
		_sync_label()

var button_disabled: bool = false:
	set(value):
		button_disabled = value
		disabled = value
		if button_disabled:
			_stop_single_attention_shine()
			_stop_attention_bounce(true)
		elif attention_bounce_enabled:
			_start_attention_bounce()
		_sync_label()
		_sync_icon()
		_sync_trailing_icon()

var selected: bool = false:
	set(value):
		selected = value
		queue_redraw()

var color_preset: int = ColorPreset.ORANGE

var normal_tint: Color = ORANGE_NORMAL_TINT:
	set(value):
		normal_tint = value
		queue_redraw()

var pressed_tint: Color = ORANGE_PRESSED_TINT:
	set(value):
		pressed_tint = value
		queue_redraw()

var selected_tint: Color = ORANGE_SELECTED_TINT:
	set(value):
		selected_tint = value
		queue_redraw()

var text_color: Color = Color.WHITE:
	set(value):
		text_color = value
		_sync_label()

var disabled_text_color: Color = Color.WHITE:
	set(value):
		disabled_text_color = value
		_sync_label()

var outline_color: Color = DEFAULT_OUTLINE_COLOR:
	set(value):
		outline_color = value
		_sync_label()

var outline_size: int = 3:
	set(value):
		outline_size = value
		_sync_label()

var icon_texture: Texture2D = null:
	set(value):
		icon_texture = value
		_sync_icon()

var icon_stage_size: Vector2 = Vector2(29.0, 24.0):
	set(value):
		icon_stage_size = value
		_sync_content_layout()

var icon_gap_stage: float = 8.0:
	set(value):
		icon_gap_stage = value
		_sync_content_layout()

var icon_before_text: bool = false:
	set(value):
		icon_before_text = value
		_sync_content_layout()

var trailing_icon_texture: Texture2D = null:
	set(value):
		trailing_icon_texture = value
		_sync_trailing_icon()

var trailing_icon_stage_size: Vector2 = Vector2(29.0, 24.0):
	set(value):
		trailing_icon_stage_size = value
		_sync_content_layout()

var trailing_icon_gap_stage: float = 8.0:
	set(value):
		trailing_icon_gap_stage = value
		_sync_content_layout()

var icon_shadow_enabled: bool = false:
	set(value):
		icon_shadow_enabled = value
		_sync_icon()

var trailing_icon_shadow_enabled: bool = false:
	set(value):
		trailing_icon_shadow_enabled = value
		_sync_trailing_icon()

var text_horizontal_padding: float = 0.0:
	set(value):
		text_horizontal_padding = maxf(value, 0.0)
		_sync_content_layout()

var _button_text_font: Font = UI_FONTS.button_font()
var _label: Label = null
var _icon_shadow_layers: Array[TextureRect] = []
var _icon_shadow_material: ShaderMaterial = null
var _icon_rect: TextureRect = null
var _trailing_icon_shadow_layers: Array[TextureRect] = []
var _trailing_icon_shadow_material: ShaderMaterial = null
var _trailing_icon_rect: TextureRect = null
# Disabled long buttons are translucent. Composite the three background slices
# first, then fade the completed face as one CanvasGroup so the 1.5 px overlap
# cannot double-blend at the left/center and center/right seams.
var _disabled_face_group: CanvasGroup = null
var _disabled_face_center: Sprite2D = null
var _disabled_face_left: Sprite2D = null
var _disabled_face_right: Sprite2D = null
var _attention_bounce_tween: Tween = null
var _single_attention_shine_tween: Tween = null

func _ready() -> void:
	press_scale_enabled = true
	_ensure_disabled_face_group()
	_ensure_label()
	_ensure_icon_shadow_layers()
	_ensure_icon()
	_ensure_trailing_icon_shadow_layers()
	_ensure_trailing_icon()
	if !resized.is_connected(_sync_content_layout):
		resized.connect(_sync_content_layout)
	super._ready()
	_sync_label()
	_sync_icon()
	_sync_trailing_icon()
	_sync_content_layout()
	_start_attention_bounce()

func _exit_tree() -> void:
	_stop_single_attention_shine()
	_stop_attention_bounce(false)
	super._exit_tree()

func _set_press_scale(is_pressed: bool, animated: bool = true) -> void:
	# The attention loop and the press response animate the same visual scale.
	# Give the pressed state exclusive control while the finger is down, then
	# resume the loop only after the release scale has returned to rest.
	if is_pressed:
		_stop_single_attention_shine()
		_stop_attention_bounce(false)
	super._set_press_scale(is_pressed, animated)
	if is_pressed or !attention_bounce_enabled or disabled:
		return
	if animated and _press_scale_tween != null and _press_scale_tween.is_valid():
		_press_scale_tween.finished.connect(_start_attention_bounce, CONNECT_ONE_SHOT)
	else:
		_start_attention_bounce()

func _start_attention_bounce() -> void:
	if !attention_bounce_enabled or disabled or _is_down or !is_inside_tree():
		return
	_stop_single_attention_shine()
	_configure_attention_shine(_attention_shine_width, _attention_shine_strength)
	_stop_attention_bounce(false)
	visual_scale = Vector2.ONE
	_attention_bounce_tween = create_tween()
	_attention_bounce_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_attention_bounce_tween.set_loops()
	var bounce_scale: Vector2 = Vector2.ONE * _attention_bounce_scale_value
	var grow_duration: float = _attention_bounce_grow_duration / _attention_bounce_speed_multiplier
	var settle_duration: float = _attention_bounce_settle_duration / _attention_bounce_speed_multiplier
	_attention_bounce_tween.tween_callback(_reset_attention_shine)
	_attention_bounce_tween.tween_method(
		_set_attention_shine_progress,
		ATTENTION_SHINE_START_PROGRESS,
		ATTENTION_SHINE_END_PROGRESS,
		_attention_shine_duration
	)
	for _bounce_index: int in range(_attention_bounce_count):
		var grow_tweener: PropertyTweener = _attention_bounce_tween.tween_property(
			self,
			"visual_scale",
			bounce_scale,
			grow_duration
		)
		grow_tweener.set_trans(Tween.TRANS_QUAD)
		grow_tweener.set_ease(Tween.EASE_OUT)
		var settle_tweener: PropertyTweener = _attention_bounce_tween.tween_property(
			self,
			"visual_scale",
			Vector2.ONE,
			settle_duration
		)
		settle_tweener.set_trans(Tween.TRANS_BACK)
		settle_tweener.set_ease(Tween.EASE_OUT)
	_attention_bounce_tween.tween_interval(_attention_cycle_pause_duration)

func _stop_attention_bounce(reset_scale: bool) -> void:
	if _attention_bounce_tween != null and _attention_bounce_tween.is_valid():
		_attention_bounce_tween.kill()
	_attention_bounce_tween = null
	_reset_attention_shine()
	if reset_scale:
		visual_scale = Vector2.ONE

func play_single_attention_shine() -> void:
	if disabled or !is_inside_tree():
		return
	_stop_single_attention_shine()
	_configure_attention_shine(_attention_shine_width, _attention_shine_strength)
	_reset_attention_shine()
	_single_attention_shine_tween = create_tween()
	_single_attention_shine_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_single_attention_shine_tween.tween_method(
		_set_attention_shine_progress,
		ATTENTION_SHINE_START_PROGRESS,
		ATTENTION_SHINE_END_PROGRESS,
		_attention_shine_duration
	)
	_single_attention_shine_tween.finished.connect(
		_finish_single_attention_shine,
		CONNECT_ONE_SHOT
	)

func _finish_single_attention_shine() -> void:
	_single_attention_shine_tween = null
	_reset_attention_shine()

func _stop_single_attention_shine() -> void:
	if (
		_single_attention_shine_tween != null
		and _single_attention_shine_tween.is_valid()
	):
		_single_attention_shine_tween.kill()
	_single_attention_shine_tween = null
	_reset_attention_shine()

func _draw() -> void:
	var use_pressed_parts: bool = selected or _is_down
	var background_tint: Color = normal_tint
	if disabled:
		# Reuse the pressed relief so the disabled button has the same inverted
		# highlight/shadow direction, but keep it neutral gray and non-interactive.
		use_pressed_parts = true
		background_tint = Color(DISABLED_TINT.r, DISABLED_TINT.g, DISABLED_TINT.b, 1.0)
	elif selected:
		background_tint = selected_tint
	elif _is_down:
		background_tint = pressed_tint
	var left_texture: Texture2D = PRESSED_LEFT_TEXTURE if use_pressed_parts else NORMAL_LEFT_TEXTURE
	var center_texture: Texture2D = PRESSED_CENTER_TEXTURE if use_pressed_parts else NORMAL_CENTER_TEXTURE
	var right_texture: Texture2D = PRESSED_RIGHT_TEXTURE if use_pressed_parts else NORMAL_RIGHT_TEXTURE
	var visual_size: Vector2 = size * visual_scale
	var visual_rect := Rect2((size - visual_size) * 0.5, visual_size)
	if drop_shadow_enabled:
		var shadow_uses_pressed_offset: bool = (
			_is_down or (selected and drop_shadow_selected_uses_pressed_state)
		)
		var shadow_offset_y: float = (
			BUTTON_DROP_SHADOW_PRESSED_OFFSET_Y
			if shadow_uses_pressed_offset
			else BUTTON_DROP_SHADOW_OFFSET_Y
		) * visual_scale.y
		# Selected settings toggles use the pressed depth immediately, but retain
		# normal shadow opacity until the user actually presses the button.
		var shadow_color: Color = (
			BUTTON_DROP_SHADOW_PRESSED_COLOR if _is_down else BUTTON_DROP_SHADOW_COLOR
		)
		# During the attention bounce only fade the shadow as the button grows.
		# Keep its offset fixed so the shadow does not visually expand away from the
		# button. The settle phase restores the alpha automatically in reverse.
		if !_is_down and visual_scale.y > 1.0:
			var bounce_scale_range: float = maxf(_attention_bounce_scale_value - 1.0, 0.0001)
			var bounce_lift_progress: float = clampf(
				(visual_scale.y - 1.0) / bounce_scale_range,
				0.0,
				1.0
			)
			shadow_color.a *= 1.0 - bounce_lift_progress
		# Use only the exposed lower contour of the vertically shifted capsule.
		# This avoids the extra circular shadow bulges that the full capsule shadow
		# created under the rounded end caps of long buttons.
		_draw_exposed_capsule_shadow(visual_rect, shadow_offset_y, shadow_color)
	_hide_disabled_face_group()
	_draw_stretchable_background(left_texture, center_texture, right_texture, visual_rect, background_tint)

func _draw_capsule_shadow(rect: Rect2, offset_y: float, color: Color) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0 or color.a <= 0.0:
		return
	var shadow_rect := Rect2(rect.position + Vector2(0.0, offset_y), rect.size)
	var radius: float = minf(shadow_rect.size.y * 0.5, shadow_rect.size.x * 0.5)
	var left_center := Vector2(shadow_rect.position.x + radius, shadow_rect.get_center().y)
	var right_center := Vector2(shadow_rect.end.x - radius, shadow_rect.get_center().y)
	if shadow_rect.size.x > radius * 2.0:
		draw_rect(
			Rect2(
				Vector2(left_center.x, shadow_rect.position.y),
				Vector2(right_center.x - left_center.x, shadow_rect.size.y)
			),
			color
		)
	draw_circle(left_center, radius, color)
	if right_center.x > left_center.x:
		draw_circle(right_center, radius, color)

func _draw_filled_capsule(rect: Rect2, color: Color) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0 or color.a <= 0.0:
		return
	var radius: float = minf(rect.size.y * 0.5, rect.size.x * 0.5)
	var left_center := Vector2(rect.position.x + radius, rect.get_center().y)
	var right_center := Vector2(rect.end.x - radius, rect.get_center().y)
	if rect.size.x > radius * 2.0:
		draw_rect(
			Rect2(
				Vector2(left_center.x, rect.position.y),
				Vector2(right_center.x - left_center.x, rect.size.y)
			),
			color
		)
	draw_circle(left_center, radius, color)
	if right_center.x > left_center.x:
		draw_circle(right_center, radius, color)

func _draw_disabled_capsule_face(rect: Rect2) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	# Draw the disabled state as a single capsule instead of reusing the three-slice
	# bitmap face. Because the disabled button is translucent, the original slice
	# shading made its rounded end caps show through as separate internal parts.
	# A single drawn capsule removes those seams completely.
	var border: float = maxf(roundf(2.0 * visual_scale.y), 1.0)
	var outer_color := Color(DEFAULT_OUTLINE_COLOR.r, DEFAULT_OUTLINE_COLOR.g, DEFAULT_OUTLINE_COLOR.b, 0.22)
	var fill_color := Color(DISABLED_TINT.r, DISABLED_TINT.g, DISABLED_TINT.b, DISABLED_OPACITY)
	_draw_filled_capsule(rect, outer_color)
	var inner_rect := Rect2(
		rect.position + Vector2(border, border),
		Vector2(maxf(rect.size.x - border * 2.0, 0.0), maxf(rect.size.y - border * 2.0, 0.0))
	)
	_draw_filled_capsule(inner_rect, fill_color)

func _capsule_lower_contour(rect: Rect2, arc_segments: int = 12) -> PackedVector2Array:
	var points := PackedVector2Array()
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return points
	var radius: float = minf(rect.size.y * 0.5, rect.size.x * 0.5)
	var left_center := Vector2(rect.position.x + radius, rect.position.y + radius)
	var right_center := Vector2(rect.end.x - radius, rect.position.y + radius)
	var segment_count: int = maxi(arc_segments, 2)
	# Leftmost midpoint -> lower-left tangent.
	for index: int in range(segment_count + 1):
		var progress: float = float(index) / float(segment_count)
		var angle: float = PI - progress * PI * 0.5
		points.append(left_center + Vector2(cos(angle), sin(angle)) * radius)
	# Straight bottom edge between the two rounded ends.
	if right_center.x > left_center.x:
		points.append(Vector2(right_center.x, rect.end.y))
	# Lower-right tangent -> rightmost midpoint.
	for index: int in range(1, segment_count + 1):
		var progress: float = float(index) / float(segment_count)
		var angle: float = PI * 0.5 - progress * PI * 0.5
		points.append(right_center + Vector2(cos(angle), sin(angle)) * radius)
	return points

func _draw_exposed_capsule_shadow(rect: Rect2, offset_y: float, color: Color) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0 or offset_y <= 0.0 or color.a <= 0.0:
		return
	# The visible part of a vertically shifted capsule is a band that follows the
	# original lower contour. Build that exact band instead of a rectangular strip,
	# so the shadow keeps the same rounded silhouette at both ends.
	var inner_contour: PackedVector2Array = _capsule_lower_contour(rect)
	if inner_contour.size() < 2:
		return
	var polygon := PackedVector2Array()
	# Start the shadow slightly underneath the button artwork. This hides the thin
	# antialiased gap that can otherwise appear between the button's lower edge and
	# the exposed shadow band, while the opaque button face masks the overlap.
	for point: Vector2 in inner_contour:
		polygon.append(point - Vector2(0.0, BUTTON_DROP_SHADOW_UNDERLAP_Y * visual_scale.y))
	for index: int in range(inner_contour.size() - 1, -1, -1):
		polygon.append(inner_contour[index] + Vector2(0.0, offset_y))
	draw_colored_polygon(polygon, color)

func _ensure_disabled_face_group() -> void:
	if _disabled_face_group != null and is_instance_valid(_disabled_face_group):
		return
	_disabled_face_group = CanvasGroup.new()
	_disabled_face_group.name = "DisabledFaceGroup"
	_disabled_face_group.visible = false
	add_child(_disabled_face_group)

	_disabled_face_center = Sprite2D.new()
	_disabled_face_center.name = "Center"
	_disabled_face_center.centered = false
	_disabled_face_center.z_index = 0
	_disabled_face_group.add_child(_disabled_face_center)

	_disabled_face_left = Sprite2D.new()
	_disabled_face_left.name = "Left"
	_disabled_face_left.centered = false
	_disabled_face_left.z_index = 1
	_disabled_face_group.add_child(_disabled_face_left)

	_disabled_face_right = Sprite2D.new()
	_disabled_face_right.name = "Right"
	_disabled_face_right.centered = false
	_disabled_face_right.z_index = 1
	_disabled_face_group.add_child(_disabled_face_right)

func _hide_disabled_face_group() -> void:
	if _disabled_face_group != null and is_instance_valid(_disabled_face_group):
		_disabled_face_group.visible = false

func _layout_face_sprite(
	sprite: Sprite2D,
	texture: Texture2D,
	rect: Rect2,
	tint_rgb: Color,
	source_region: Rect2 = Rect2()
) -> void:
	if sprite == null or !is_instance_valid(sprite) or texture == null:
		return
	var texture_size: Vector2 = texture.get_size()
	var region: Rect2 = source_region
	if region.size == Vector2.ZERO:
		region = Rect2(Vector2.ZERO, texture_size)
	if region.size.x <= 0.0 or region.size.y <= 0.0 or rect.size.x <= 0.0 or rect.size.y <= 0.0:
		sprite.visible = false
		return
	sprite.visible = true
	sprite.texture = texture
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.position = rect.position
	sprite.scale = Vector2(rect.size.x / region.size.x, rect.size.y / region.size.y)
	# Keep every slice fully opaque inside the CanvasGroup. The group alpha is
	# applied once after composition, which prevents overlap from darkening seams.
	sprite.self_modulate = Color(tint_rgb.r, tint_rgb.g, tint_rgb.b, 1.0)

func _build_slice_layout(
	left_texture: Texture2D,
	center_texture: Texture2D,
	right_texture: Texture2D,
	rect: Rect2
) -> Dictionary:
	var left_source_size: Vector2 = left_texture.get_size()
	var right_source_size: Vector2 = right_texture.get_size()
	var left_width: float = rect.size.y * left_source_size.x / left_source_size.y
	var right_width: float = rect.size.y * right_source_size.x / right_source_size.y
	var cap_width: float = left_width + right_width
	if cap_width > rect.size.x:
		var cap_fit: float = rect.size.x / cap_width
		left_width *= cap_fit
		right_width *= cap_fit

	var snapped_left: float = roundf(rect.position.x)
	var snapped_top: float = roundf(rect.position.y)
	var snapped_right: float = roundf(rect.end.x)
	var snapped_bottom: float = roundf(rect.end.y)
	var snapped_height: float = maxf(1.0, snapped_bottom - snapped_top)
	var total_width: float = maxf(1.0, snapped_right - snapped_left)

	left_width = roundf(left_width)
	right_width = roundf(right_width)
	if left_width + right_width > total_width:
		left_width = floorf(total_width * 0.5)
		right_width = total_width - left_width

	var left_rect := Rect2(Vector2(snapped_left, snapped_top), Vector2(left_width, snapped_height))
	var right_rect := Rect2(Vector2(snapped_right - right_width, snapped_top), Vector2(right_width, snapped_height))
	var center_left: float = left_rect.end.x
	var center_right: float = right_rect.position.x
	var overlap: float = minf(
		roundf(BUTTON_SLICE_OVERLAP * visual_scale.x),
		maxf(0.0, minf(left_width, right_width) - 1.0)
	)
	var center_rect := Rect2()
	if center_right > center_left:
		center_rect = Rect2(
			Vector2(center_left - overlap, snapped_top),
			Vector2(center_right - center_left + overlap * 2.0, snapped_height)
		)
	var left_region := Rect2(Vector2.ZERO, left_source_size)
	var right_region := Rect2(Vector2.ZERO, right_source_size)
	var inner_trim_left: float = minf(BUTTON_CAP_INNER_TRIM, maxf(0.0, left_source_size.x - 2.0))
	var inner_trim_right: float = minf(BUTTON_CAP_INNER_TRIM, maxf(0.0, right_source_size.x - 2.0))
	if inner_trim_left > 0.0:
		left_region.size.x -= inner_trim_left
	if inner_trim_right > 0.0:
		right_region.position.x += inner_trim_right
		right_region.size.x -= inner_trim_right
	return {
		"left_rect": left_rect,
		"center_rect": center_rect,
		"right_rect": right_rect,
		"left_region": left_region,
		"right_region": right_region,
	}

func _sync_disabled_face_group(
	left_texture: Texture2D,
	center_texture: Texture2D,
	right_texture: Texture2D,
	rect: Rect2,
	tint: Color
) -> void:
	_ensure_disabled_face_group()
	if _disabled_face_group == null or !is_instance_valid(_disabled_face_group):
		return
	var layout: Dictionary = _build_slice_layout(left_texture, center_texture, right_texture, rect)
	var center_rect: Rect2 = layout.get("center_rect", Rect2())
	if center_rect.size.x > 0.0:
		_layout_face_sprite(
			_disabled_face_center,
			center_texture,
			center_rect,
			tint
		)
	else:
		_disabled_face_center.visible = false
	_layout_face_sprite(
		_disabled_face_left,
		left_texture,
		layout.get("left_rect", Rect2()),
		tint,
		layout.get("left_region", Rect2())
	)
	_layout_face_sprite(
		_disabled_face_right,
		right_texture,
		layout.get("right_rect", Rect2()),
		tint,
		layout.get("right_region", Rect2())
	)
	_disabled_face_group.modulate = Color(1.0, 1.0, 1.0, tint.a)
	_disabled_face_group.visible = true

func _draw_stretchable_background(left_texture: Texture2D, center_texture: Texture2D, right_texture: Texture2D, rect: Rect2, tint: Color) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return

	var layout: Dictionary = _build_slice_layout(left_texture, center_texture, right_texture, rect)
	var center_rect: Rect2 = layout.get("center_rect", Rect2())
	if center_rect.size.x > 0.0:
		draw_texture_rect(center_texture, center_rect, false, tint)
	draw_texture_rect_region(
		left_texture,
		layout.get("left_rect", Rect2()),
		layout.get("left_region", Rect2()),
		tint,
		false
	)
	draw_texture_rect_region(
		right_texture,
		layout.get("right_rect", Rect2()),
		layout.get("right_region", Rect2()),
		tint,
		false
	)

func set_color_preset(preset: int) -> void:
	match preset:
		ColorPreset.GREEN:
			color_preset = ColorPreset.GREEN
			_apply_outline_style(DEFAULT_OUTLINE_COLOR, 3)
			_apply_color_palette(GREEN_NORMAL_TINT, GREEN_PRESSED_TINT, GREEN_SELECTED_TINT)
		ColorPreset.BLUE:
			color_preset = ColorPreset.BLUE
			_apply_outline_style(BLUE_OUTLINE_COLOR, 4)
			_apply_color_palette(BLUE_NORMAL_TINT, BLUE_PRESSED_TINT, BLUE_SELECTED_TINT)
		ColorPreset.CUSTOM:
			color_preset = ColorPreset.CUSTOM
		_:
			color_preset = ColorPreset.ORANGE
			_apply_outline_style(DEFAULT_OUTLINE_COLOR, 3)
			_apply_color_palette(ORANGE_NORMAL_TINT, ORANGE_PRESSED_TINT, ORANGE_SELECTED_TINT)

func _apply_outline_style(color: Color, size_value: int) -> void:
	outline_color = color
	outline_size = size_value

func set_color_palette(normal_color: Color, pressed_color: Color, selected_color: Color = ORANGE_SELECTED_TINT) -> void:
	color_preset = ColorPreset.CUSTOM
	_apply_color_palette(normal_color, pressed_color, selected_color)

func _apply_color_palette(normal_color: Color, pressed_color: Color, selected_color: Color) -> void:
	normal_tint = normal_color
	pressed_tint = pressed_color
	selected_tint = selected_color

func configure(text_value: String, font_size_value: int = 20, disabled_value: bool = false, disabled_overlay_alpha_value: float = 0.32, use_normal_texture_when_disabled: bool = false, selected_value: bool = false) -> void:
	icon_texture = null
	trailing_icon_texture = null
	button_text = text_value
	button_font_size = font_size_value
	disabled_overlay_alpha = disabled_overlay_alpha_value
	selected = selected_value
	button_disabled = disabled_value
	_ensure_label()
	_ensure_icon()
	_ensure_trailing_icon()
	_sync_label()
	_sync_icon()
	_sync_trailing_icon()
	_sync_content_layout()

func _ensure_label() -> void:
	if _label != null and is_instance_valid(_label):
		return
	_label = Label.new()
	_label.name = "Text"
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.clip_text = true
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.z_index = 2
	add_child(_label)

func _create_icon_shadow_layers(prefix: String, material: ShaderMaterial) -> Array[TextureRect]:
	var layers: Array[TextureRect] = []
	for index: int in range(ICON_SHADOW_LAYER_T.size()):
		var layer := TextureRect.new()
		layer.name = "%sExtrusion%02d" % [prefix, index + 1]
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		layer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		layer.z_index = 0
		layer.material = material
		add_child(layer)
		move_child(layer, 0)
		layers.append(layer)
	return layers

func _ensure_icon_shadow_layers() -> void:
	if !_icon_shadow_layers.is_empty():
		return
	_icon_shadow_material = UI_MATERIALS.icon_shadow(UI_PALETTE.NAV_TEXT_SHADOW)
	_icon_shadow_layers = _create_icon_shadow_layers("Icon", _icon_shadow_material)

func _ensure_trailing_icon_shadow_layers() -> void:
	if !_trailing_icon_shadow_layers.is_empty():
		return
	_trailing_icon_shadow_material = UI_MATERIALS.icon_shadow(UI_PALETTE.NAV_TEXT_SHADOW)
	_trailing_icon_shadow_layers = _create_icon_shadow_layers("TrailingIcon", _trailing_icon_shadow_material)

func _set_icon_shadow_layers_state(
	layers: Array[TextureRect],
	texture: Texture2D,
	visible: bool
) -> void:
	for layer: TextureRect in layers:
		if layer == null or !is_instance_valid(layer):
			continue
		layer.texture = texture
		layer.visible = visible and texture != null
		layer.modulate = Color(1.0, 1.0, 1.0, DISABLED_OPACITY if button_disabled else 1.0)

func _layout_icon_shadow_layers(
	layers: Array[TextureRect],
	base_position: Vector2,
	icon_size: Vector2
) -> void:
	var icon_extent: float = minf(icon_size.x, icon_size.y)
	var shadow_depth: float = clampf(
		icon_extent * ICON_SHADOW_DEPTH_RATIO,
		ICON_SHADOW_DEPTH_MIN,
		ICON_SHADOW_DEPTH_MAX
	)
	var shadow_offset_x: float = minf(
		icon_extent * ICON_SHADOW_OFFSET_X_RATIO,
		ICON_SHADOW_OFFSET_X_MAX
	)
	for index: int in range(layers.size()):
		var layer: TextureRect = layers[index]
		if layer == null or !is_instance_valid(layer):
			continue
		var layer_t: float = float(ICON_SHADOW_LAYER_T[index])
		layer.position = base_position + Vector2(
			shadow_offset_x * layer_t,
			shadow_depth * layer_t
		)
		layer.size = icon_size

func _ensure_icon() -> void:
	if _icon_rect != null and is_instance_valid(_icon_rect):
		return
	_icon_rect = TextureRect.new()
	_icon_rect.name = "Icon"
	_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon_rect.z_index = 1
	add_child(_icon_rect)

func _ensure_trailing_icon() -> void:
	if _trailing_icon_rect != null and is_instance_valid(_trailing_icon_rect):
		return
	_trailing_icon_rect = TextureRect.new()
	_trailing_icon_rect.name = "TrailingIcon"
	_trailing_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_trailing_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_trailing_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_trailing_icon_rect.z_index = 1
	add_child(_trailing_icon_rect)

func _sync_label() -> void:
	if _label == null or !is_instance_valid(_label):
		return
	_label.text = button_text
	_label.add_theme_font_override("font", _button_text_font)
	_label.add_theme_font_size_override("font_size", button_font_size)
	var label_color: Color = disabled_text_color if button_disabled else text_color
	if button_disabled:
		label_color = Color(label_color.r, label_color.g, label_color.b, label_color.a * DISABLED_OPACITY)
	_label.add_theme_color_override("font_color", label_color)
	BUTTON_TEXT_STYLE_SCRIPT.apply_display(_label)
	_sync_content_layout()

func _sync_icon() -> void:
	if _icon_rect == null or !is_instance_valid(_icon_rect):
		return
	_icon_rect.texture = icon_texture
	_icon_rect.visible = icon_texture != null
	_icon_rect.modulate = Color(1.0, 1.0, 1.0, DISABLED_OPACITY if button_disabled else 1.0)
	_set_icon_shadow_layers_state(
		_icon_shadow_layers,
		icon_texture,
		icon_shadow_enabled and icon_texture != null
	)
	if _icon_rect != null and is_instance_valid(_icon_rect):
		_icon_rect.z_index = 1
	if _label != null and is_instance_valid(_label):
		_label.z_index = 2
	_sync_content_layout()

func _sync_trailing_icon() -> void:
	if _trailing_icon_rect == null or !is_instance_valid(_trailing_icon_rect):
		return
	_trailing_icon_rect.texture = trailing_icon_texture
	_trailing_icon_rect.visible = trailing_icon_texture != null
	_trailing_icon_rect.modulate = Color(
		1.0,
		1.0,
		1.0,
		DISABLED_OPACITY if button_disabled else 1.0
	)
	_trailing_icon_rect.z_index = 1
	_set_icon_shadow_layers_state(
		_trailing_icon_shadow_layers,
		trailing_icon_texture,
		trailing_icon_shadow_enabled and trailing_icon_texture != null
	)
	_sync_content_layout()

func _sync_content_layout() -> void:
	if _label == null or !is_instance_valid(_label):
		return
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var has_icon: bool = _icon_rect != null and is_instance_valid(_icon_rect) and icon_texture != null
	var has_trailing_icon: bool = (
		_trailing_icon_rect != null
		and is_instance_valid(_trailing_icon_rect)
		and trailing_icon_texture != null
	)
	if (!has_icon and !has_trailing_icon) or stage_rect.size.x <= 0.0 or stage_rect.size.y <= 0.0:
		var horizontal_padding: float = minf(text_horizontal_padding, maxf(size.x * 0.25, 0.0))
		_label.position = Vector2(horizontal_padding, 0.0)
		_label.size = Vector2(maxf(size.x - horizontal_padding * 2.0, 1.0), size.y)
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if _icon_rect != null and is_instance_valid(_icon_rect):
			_icon_rect.visible = false
		for layer: TextureRect in _icon_shadow_layers:
			if layer != null and is_instance_valid(layer):
				layer.visible = false
		for layer: TextureRect in _trailing_icon_shadow_layers:
			if layer != null and is_instance_valid(layer):
				layer.visible = false
		if _trailing_icon_rect != null and is_instance_valid(_trailing_icon_rect):
			_trailing_icon_rect.visible = false
		_sync_visual_child_scales()
		return

	var scale_to_view := Vector2(size.x / stage_rect.size.x, size.y / stage_rect.size.y)
	var actual_icon_size: Vector2 = icon_stage_size * scale_to_view
	var actual_trailing_icon_size: Vector2 = trailing_icon_stage_size * scale_to_view
	var actual_gap: float = icon_gap_stage * scale_to_view.x
	var actual_trailing_gap: float = trailing_icon_gap_stage * scale_to_view.x
	if _icon_rect != null and is_instance_valid(_icon_rect):
		_icon_rect.visible = has_icon
	_set_icon_shadow_layers_state(
		_icon_shadow_layers,
		icon_texture,
		icon_shadow_enabled and has_icon
	)
	_set_icon_shadow_layers_state(
		_trailing_icon_shadow_layers,
		trailing_icon_texture,
		trailing_icon_shadow_enabled and has_trailing_icon
	)
	if _trailing_icon_rect != null and is_instance_valid(_trailing_icon_rect):
		_trailing_icon_rect.visible = has_trailing_icon

	if button_text.is_empty():
		_label.position = Vector2.ZERO
		_label.size = size
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var icon_group_width: float = 0.0
		if has_icon:
			icon_group_width += actual_icon_size.x
		if has_icon and has_trailing_icon:
			icon_group_width += actual_trailing_gap
		if has_trailing_icon:
			icon_group_width += actual_trailing_icon_size.x
		var icon_cursor_x: float = maxf((size.x - icon_group_width) * 0.5, 0.0)
		if has_icon:
			_icon_rect.position = Vector2(icon_cursor_x, (size.y - actual_icon_size.y) * 0.5)
			_icon_rect.size = actual_icon_size
			_layout_icon_shadow_layers(_icon_shadow_layers, _icon_rect.position, actual_icon_size)
			icon_cursor_x += actual_icon_size.x + (actual_trailing_gap if has_trailing_icon else 0.0)
		if has_trailing_icon:
			_trailing_icon_rect.position = Vector2(
				icon_cursor_x,
				(size.y - actual_trailing_icon_size.y) * 0.5
			)
			_trailing_icon_rect.size = actual_trailing_icon_size
			_layout_icon_shadow_layers(
				_trailing_icon_shadow_layers,
				_trailing_icon_rect.position,
				actual_trailing_icon_size
			)
		_sync_visual_child_scales()
		return

	var font: Font = _label.get_theme_font("font")
	var text_width: float = font.get_string_size(
		button_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		button_font_size
	).x
	var group_width: float = text_width
	if has_icon:
		group_width += actual_icon_size.x + actual_gap
	if has_trailing_icon:
		group_width += actual_trailing_gap + actual_trailing_icon_size.x
	var cursor_x: float = maxf((size.x - group_width) * 0.5, 0.0)

	if has_icon and icon_before_text:
		_icon_rect.position = Vector2(cursor_x, (size.y - actual_icon_size.y) * 0.5)
		_icon_rect.size = actual_icon_size
		_layout_icon_shadow_layers(_icon_shadow_layers, _icon_rect.position, actual_icon_size)
		cursor_x += actual_icon_size.x + actual_gap

	_label.position = Vector2(cursor_x, 0.0)
	_label.size = Vector2(text_width + 2.0, size.y)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	cursor_x += text_width

	if has_icon and !icon_before_text:
		cursor_x += actual_gap
		_icon_rect.position = Vector2(cursor_x, (size.y - actual_icon_size.y) * 0.5)
		_icon_rect.size = actual_icon_size
		_layout_icon_shadow_layers(_icon_shadow_layers, _icon_rect.position, actual_icon_size)
		cursor_x += actual_icon_size.x

	if has_trailing_icon:
		cursor_x += actual_trailing_gap
		_trailing_icon_rect.position = Vector2(
			cursor_x,
			(size.y - actual_trailing_icon_size.y) * 0.5
		)
		_trailing_icon_rect.size = actual_trailing_icon_size
		_layout_icon_shadow_layers(
			_trailing_icon_shadow_layers,
			_trailing_icon_rect.position,
			actual_trailing_icon_size
		)
	_sync_visual_child_scales()
