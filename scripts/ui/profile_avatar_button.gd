extends Button
## Avatar slot; the texture can be supplied later without changing Home layout.
const PALETTE = preload("res://scripts/ui/ui_palette.gd")
const MASK = preload("res://scripts/ui/rounded_rect_texture_mask.gdshader")
var avatar_texture: Texture2D = preload("res://img/_______405______1_0_SHAPE_0_BOUNDS_-0.96_-0.96_SIZE_366_322.png"):
	set(value):
		avatar_texture = value
		if is_instance_valid(_image):
			_image.texture = value
var _press_tween: Tween
var _image: TextureRect

func _ready() -> void:
	resized.connect(_sync_press_pivot)
	button_down.connect(func(): _animate_press(true))
	button_up.connect(func(): _animate_press(false))
	visibility_changed.connect(_reset_press_if_hidden)
	_sync_press_pivot()
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = PALETTE.BUTTON_BLUE_PRESSED if state == "pressed" else PALETTE.BUTTON_BLUE
		style.border_color = PALETTE.BUTTON_BLUE_OUTLINE
		style.set_border_width_all(2)
		style.set_corner_radius_all(12)
		style.shadow_color = Color(0.07, 0.12, 0.24, 0.22)
		style.shadow_size = 1
		style.shadow_offset = Vector2(0, 2 if state != "pressed" else 1)
		add_theme_stylebox_override(state, style)
	_image = TextureRect.new()
	_image.name = "AvatarTexture"
	_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_image.texture = avatar_texture
	_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_image.offset_left = 4
	_image.offset_top = 4
	_image.offset_right = -4
	_image.offset_bottom = -4
	var mask := ShaderMaterial.new()
	mask.shader = MASK
	_image.material = mask
	add_child(_image)
	_image.resized.connect(_sync_mask)
	_sync_mask()

func _sync_mask() -> void:
	var mask := _image.material as ShaderMaterial
	mask.set_shader_parameter("source_size", _image.size)
	mask.set_shader_parameter("mask_rect", Vector4(0, 0, _image.size.x, _image.size.y))
	mask.set_shader_parameter("corner_radius", 8.0)

func _sync_press_pivot() -> void:
	pivot_offset = size * 0.5

func _animate_press(down: bool) -> void:
	if _press_tween != null and _press_tween.is_valid():
		_press_tween.kill()
	_press_tween = create_tween()
	_press_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_press_tween.tween_property(self, "scale", Vector2.ONE * (0.94 if down else 1.0), 0.055 if down else 0.085).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _reset_press_if_hidden() -> void:
	if !is_visible_in_tree():
		if _press_tween != null and _press_tween.is_valid():
			_press_tween.kill()
		scale = Vector2.ONE
