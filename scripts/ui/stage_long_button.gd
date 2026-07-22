class_name StageLongButton
extends "res://scripts/ui/flash_stage_texture_button.gd"

const NORMAL_LEFT_TEXTURE: Texture2D = preload("res://flash_assets/user_main_button_21_left.png")
const NORMAL_CENTER_TEXTURE: Texture2D = preload("res://flash_assets/user_main_button_21_center.png")
const NORMAL_RIGHT_TEXTURE: Texture2D = preload("res://flash_assets/user_main_button_21_right.png")
const PRESSED_LEFT_TEXTURE: Texture2D = preload("res://flash_assets/user_main_button_23_left.png")
const PRESSED_CENTER_TEXTURE: Texture2D = preload("res://flash_assets/user_main_button_23_center.png")
const PRESSED_RIGHT_TEXTURE: Texture2D = preload("res://flash_assets/user_main_button_23_right.png")

var button_text: String = "":
	set(value):
		button_text = value
		_sync_label()

var button_font_size: int = 20:
	set(value):
		button_font_size = value
		_sync_label()

var button_disabled: bool = false:
	set(value):
		button_disabled = value
		disabled = value
		_sync_label()

var selected: bool = false:
	set(value):
		selected = value
		queue_redraw()

var text_color: Color = Color.WHITE:
	set(value):
		text_color = value
		_sync_label()

var disabled_text_color: Color = Color(1.0, 1.0, 1.0, 0.72):
	set(value):
		disabled_text_color = value
		_sync_label()

var outline_color: Color = Color(0.23, 0.26, 0.52, 1.0):
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

var _label: Label = null
var _icon_rect: TextureRect = null
var _use_normal_parts_when_disabled: bool = false

func _ready() -> void:
	press_scale_enabled = true
	_ensure_label()
	_ensure_icon()
	if !resized.is_connected(_sync_content_layout):
		resized.connect(_sync_content_layout)
	super._ready()
	_sync_label()
	_sync_icon()
	_sync_content_layout()

func _draw() -> void:
	var use_pressed_parts: bool = selected or _is_down
	if disabled and _use_normal_parts_when_disabled:
		use_pressed_parts = false
	var left_texture: Texture2D = PRESSED_LEFT_TEXTURE if use_pressed_parts else NORMAL_LEFT_TEXTURE
	var center_texture: Texture2D = PRESSED_CENTER_TEXTURE if use_pressed_parts else NORMAL_CENTER_TEXTURE
	var right_texture: Texture2D = PRESSED_RIGHT_TEXTURE if use_pressed_parts else NORMAL_RIGHT_TEXTURE
	var visual_size: Vector2 = size * visual_scale
	var visual_rect := Rect2((size - visual_size) * 0.5, visual_size)
	_draw_stretchable_background(left_texture, center_texture, right_texture, visual_rect)
	if disabled and disabled_overlay_alpha > 0.0:
		draw_rect(visual_rect, Color(1.0, 1.0, 1.0, disabled_overlay_alpha), true)

func _draw_stretchable_background(left_texture: Texture2D, center_texture: Texture2D, right_texture: Texture2D, rect: Rect2) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return

	var left_source_size: Vector2 = left_texture.get_size()
	var right_source_size: Vector2 = right_texture.get_size()
	var left_width: float = rect.size.y * left_source_size.x / left_source_size.y
	var right_width: float = rect.size.y * right_source_size.x / right_source_size.y
	var cap_width: float = left_width + right_width
	if cap_width > rect.size.x:
		var cap_fit: float = rect.size.x / cap_width
		left_width *= cap_fit
		right_width *= cap_fit

	var center_left: float = rect.position.x + left_width
	var center_right: float = rect.end.x - right_width
	if center_right > center_left:
		var center_rect := Rect2(
			Vector2(center_left, rect.position.y),
			Vector2(center_right - center_left, rect.size.y)
		)
		draw_texture_rect(center_texture, center_rect, false)

	draw_texture_rect(left_texture, Rect2(rect.position, Vector2(left_width, rect.size.y)), false)
	draw_texture_rect(
		right_texture,
		Rect2(Vector2(rect.end.x - right_width, rect.position.y), Vector2(right_width, rect.size.y)),
		false
	)

func configure(text_value: String, font_size_value: int = 20, disabled_value: bool = false, disabled_overlay_alpha_value: float = 0.32, use_normal_texture_when_disabled: bool = false, selected_value: bool = false) -> void:
	icon_texture = null
	button_text = text_value
	button_font_size = font_size_value
	disabled_overlay_alpha = disabled_overlay_alpha_value
	_use_normal_parts_when_disabled = use_normal_texture_when_disabled
	selected = selected_value
	button_disabled = disabled_value
	_ensure_label()
	_ensure_icon()
	_sync_label()
	_sync_icon()
	_sync_content_layout()

func configure_with_icon(text_value: String, texture_value: Texture2D, icon_size_value: Vector2, font_size_value: int = 20, disabled_value: bool = false, disabled_overlay_alpha_value: float = 0.32, use_normal_texture_when_disabled: bool = false, selected_value: bool = false) -> void:
	button_text = text_value
	button_font_size = font_size_value
	icon_texture = texture_value
	icon_stage_size = icon_size_value
	disabled_overlay_alpha = disabled_overlay_alpha_value
	_use_normal_parts_when_disabled = use_normal_texture_when_disabled
	selected = selected_value
	button_disabled = disabled_value
	_ensure_label()
	_ensure_icon()
	_sync_label()
	_sync_icon()
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
	add_child(_label)

func _ensure_icon() -> void:
	if _icon_rect != null and is_instance_valid(_icon_rect):
		return
	_icon_rect = TextureRect.new()
	_icon_rect.name = "Icon"
	_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(_icon_rect)

func _sync_label() -> void:
	if _label == null or !is_instance_valid(_label):
		return
	_label.text = button_text
	_label.add_theme_font_size_override("font_size", button_font_size)
	_label.add_theme_color_override("font_color", disabled_text_color if button_disabled else text_color)
	_label.add_theme_color_override("font_outline_color", outline_color)
	_label.add_theme_constant_override("outline_size", outline_size)
	_sync_content_layout()

func _sync_icon() -> void:
	if _icon_rect == null or !is_instance_valid(_icon_rect):
		return
	_icon_rect.texture = icon_texture
	_icon_rect.visible = icon_texture != null
	_sync_content_layout()

func _sync_content_layout() -> void:
	if _label == null or !is_instance_valid(_label):
		return
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var has_icon: bool = _icon_rect != null and is_instance_valid(_icon_rect) and icon_texture != null
	if !has_icon or stage_rect.size.x <= 0.0 or stage_rect.size.y <= 0.0:
		_label.position = Vector2.ZERO
		_label.size = size
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if _icon_rect != null and is_instance_valid(_icon_rect):
			_icon_rect.visible = false
		_sync_visual_child_scales()
		return

	_icon_rect.visible = true
	var scale_to_view := Vector2(size.x / stage_rect.size.x, size.y / stage_rect.size.y)
	var actual_icon_size: Vector2 = icon_stage_size * scale_to_view
	if button_text.is_empty():
		_label.position = Vector2.ZERO
		_label.size = size
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_icon_rect.position = (size - actual_icon_size) * 0.5
		_icon_rect.size = actual_icon_size
		_sync_visual_child_scales()
		return

	var actual_gap: float = icon_gap_stage * scale_to_view.x
	var font: Font = _label.get_theme_font("font")
	var text_width: float = font.get_string_size(button_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, button_font_size).x
	var group_width: float = text_width + actual_gap + actual_icon_size.x
	var start_x: float = maxf((size.x - group_width) * 0.5, 0.0)
	_label.position = Vector2(start_x, 0.0)
	_label.size = Vector2(text_width + 2.0, size.y)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_icon_rect.position = Vector2(start_x + text_width + actual_gap, (size.y - actual_icon_size.y) * 0.5)
	_icon_rect.size = actual_icon_size
	_sync_visual_child_scales()
