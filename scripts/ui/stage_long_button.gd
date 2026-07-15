class_name StageLongButton
extends "res://scripts/ui/flash_stage_texture_button.gd"

const NORMAL_TEXTURE: Texture2D = preload("res://flash_assets/user_main_button_21.png")
const PRESSED_TEXTURE: Texture2D = preload("res://flash_assets/user_main_button_23.png")

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

var _label: Label = null

func _ready() -> void:
	texture_normal = NORMAL_TEXTURE
	texture_pressed = PRESSED_TEXTURE
	_ensure_label()
	super._ready()
	_sync_label()

func configure(text_value: String, font_size_value: int = 20, disabled_value: bool = false, disabled_overlay_alpha_value: float = 0.32, use_normal_texture_when_disabled: bool = false) -> void:
	button_text = text_value
	button_font_size = font_size_value
	disabled_overlay_alpha = disabled_overlay_alpha_value
	texture_disabled = NORMAL_TEXTURE if use_normal_texture_when_disabled else null
	button_disabled = disabled_value
	_ensure_label()
	_sync_label()

func _ensure_label() -> void:
	if _label != null and is_instance_valid(_label):
		return
	_label = Label.new()
	_label.name = "Text"
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label.clip_text = true
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_label)

func _sync_label() -> void:
	if _label == null or !is_instance_valid(_label):
		return
	_label.text = button_text
	_label.add_theme_font_size_override("font_size", button_font_size)
	_label.add_theme_color_override("font_color", disabled_text_color if button_disabled else text_color)
	_label.add_theme_color_override("font_outline_color", outline_color)
	_label.add_theme_constant_override("outline_size", outline_size)
