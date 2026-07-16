class_name StageRoundButton
extends "res://scripts/ui/flash_stage_texture_button.gd"

const NORMAL_TEXTURE: Texture2D = preload("res://flash_assets/user_round_button_36.png")
const PRESSED_TEXTURE: Texture2D = preload("res://flash_assets/user_round_button_38.png")

var icon_text: String = "":
	set(value):
		icon_text = value
		_sync_visuals()

var icon_texture: Texture2D = null:
	set(value):
		icon_texture = value
		_sync_visuals()

var icon_font_size: int = 28:
	set(value):
		icon_font_size = value
		_sync_visuals()

var icon_stage_size: Vector2 = Vector2(27.0, 27.0):
	set(value):
		icon_stage_size = value
		_sync_icon_layout()

var icon_stage_offset: Vector2 = Vector2.ZERO:
	set(value):
		icon_stage_offset = value
		_sync_icon_layout()

var icon_color: Color = Color.WHITE:
	set(value):
		icon_color = value
		_sync_visuals()

var icon_outline_color: Color = Color(0.27, 0.31, 0.61, 1.0):
	set(value):
		icon_outline_color = value
		_sync_visuals()

var icon_outline_size: int = 3:
	set(value):
		icon_outline_size = value
		_sync_visuals()

var icon_modulate: Color = Color.WHITE:
	set(value):
		icon_modulate = value
		_sync_visuals()

var selected: bool = false:
	set(value):
		selected = value
		_sync_background()

var button_disabled: bool = false:
	set(value):
		button_disabled = value
		disabled = value
		_sync_visuals()

var _icon_rect: TextureRect = null
var _icon_label: Label = null

func _ready() -> void:
	press_scale_enabled = true
	_ensure_visual_nodes()
	if !resized.is_connected(_sync_icon_layout):
		resized.connect(_sync_icon_layout)
	_sync_background()
	super._ready()
	_sync_visuals()
	_sync_icon_layout()

func configure_text(text_value: String, disabled_value: bool = false, selected_value: bool = false, font_size_value: int = 28, disabled_overlay_alpha_value: float = 0.32) -> void:
	icon_texture = null
	icon_text = text_value
	icon_font_size = font_size_value
	disabled_overlay_alpha = disabled_overlay_alpha_value
	selected = selected_value
	button_disabled = disabled_value
	_ensure_visual_nodes()
	_sync_visuals()

func configure_texture(texture_value: Texture2D, stage_size_value: Vector2, disabled_value: bool = false, selected_value: bool = false, stage_offset_value: Vector2 = Vector2.ZERO, disabled_overlay_alpha_value: float = 0.32) -> void:
	icon_text = ""
	icon_texture = texture_value
	icon_stage_size = stage_size_value
	icon_stage_offset = stage_offset_value
	disabled_overlay_alpha = disabled_overlay_alpha_value
	selected = selected_value
	button_disabled = disabled_value
	_ensure_visual_nodes()
	_sync_visuals()
	_sync_icon_layout()

func _ensure_visual_nodes() -> void:
	if _icon_rect == null or !is_instance_valid(_icon_rect):
		_icon_rect = TextureRect.new()
		_icon_rect.name = "Icon"
		_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		add_child(_icon_rect)
	if _icon_label == null or !is_instance_valid(_icon_label):
		_icon_label = Label.new()
		_icon_label.name = "Text"
		_icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_icon_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_icon_label.clip_text = true
		_icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_child(_icon_label)

func _sync_background() -> void:
	texture_normal = PRESSED_TEXTURE if selected else NORMAL_TEXTURE
	texture_pressed = PRESSED_TEXTURE
	queue_redraw()

func _sync_visuals() -> void:
	if _icon_rect == null or _icon_label == null:
		return
	var has_texture: bool = icon_texture != null
	_icon_rect.visible = has_texture
	_icon_rect.texture = icon_texture
	_icon_rect.modulate = icon_modulate
	_icon_label.visible = !has_texture and icon_text != ""
	_icon_label.text = icon_text
	_icon_label.add_theme_font_size_override("font_size", icon_font_size)
	_icon_label.add_theme_color_override("font_color", icon_color if !button_disabled else Color(icon_color.r, icon_color.g, icon_color.b, 0.72))
	_icon_label.add_theme_color_override("font_outline_color", icon_outline_color)
	_icon_label.add_theme_constant_override("outline_size", icon_outline_size)

func _sync_icon_layout() -> void:
	if _icon_rect == null or !is_instance_valid(_icon_rect):
		return
	if stage_rect.size.x <= 0.0 or stage_rect.size.y <= 0.0:
		return
	var scale_to_view: Vector2 = Vector2(size.x / stage_rect.size.x, size.y / stage_rect.size.y)
	var actual_size: Vector2 = icon_stage_size * scale_to_view
	var actual_offset: Vector2 = icon_stage_offset * scale_to_view
	_icon_rect.position = size * 0.5 + actual_offset - actual_size * 0.5
	_icon_rect.size = actual_size
	_sync_visual_child_scales()
