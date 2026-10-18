extends Button
## Shared portrait, frame and paper styling for Home and Profile.
const PALETTE = preload("res://scripts/ui/ui_palette.gd")
const MASK = preload("res://scripts/ui/rounded_rect_texture_mask.gdshader")
const PAPER = preload("res://shaders/profile_avatar_paper.gdshader")
const PAPER_STYLE = preload("res://scripts/ui/portrait_paper_background.gd")
const LUCKY = preload("res://img/_______192______1_0_SHAPE_0_BOUNDS_-0.96_-0.96_SIZE_329_709.png")
const EL_TIGRE = preload("res://img/_______405______1_0_SHAPE_0_BOUNDS_-0.96_-0.96_SIZE_366_322.png")
const PROFILE_SIZE := 117.0
var _appearance_scale := 1.0
var paper_background := false
var extra_hit_rect := Rect2()
var frame_color: Color = PALETTE.BUTTON_BLUE_OUTLINE
var frame_width: int = 2
var corner_radius: int = 12
var image_inset: float = 4.0
var avatar_texture: Texture2D = preload("res://img/_______405______1_0_SHAPE_0_BOUNDS_-0.96_-0.96_SIZE_366_322.png"):
	set(value):
		avatar_texture = value
		if is_instance_valid(_image):
			_image.texture = value
var _press_tween: Tween
var _image: TextureRect

func configure_profile_appearance(side: float) -> void:
	_appearance_scale = side / PROFILE_SIZE
	paper_background = true
	frame_color = PALETTE.BUTTON_ORANGE
	frame_width = maxi(1, roundi(6 * _appearance_scale))
	corner_radius = maxi(1, roundi(14 * _appearance_scale))
	image_inset = 8 * _appearance_scale
	refresh_character()

func refresh_character() -> void:
	if GameState.settings.size() > 5 and int(GameState.settings[5]) == 2:
		avatar_texture = EL_TIGRE
	else:
		var portrait := AtlasTexture.new()
		portrait.atlas = LUCKY
		portrait.region = Rect2(28, 0, 470, 470)
		avatar_texture = portrait

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
		style.bg_color = Color.TRANSPARENT if paper_background else (PALETTE.BUTTON_BLUE_PRESSED if state == "pressed" else PALETTE.BUTTON_BLUE)
		style.border_color = frame_color
		style.set_border_width_all(frame_width)
		style.set_corner_radius_all(corner_radius)
		style.shadow_color = Color(0.07, 0.12, 0.24, 0.22)
		style.shadow_size = 1
		style.shadow_offset = Vector2(0, 2 if state != "pressed" else 1)
		add_theme_stylebox_override(state, style)
	if paper_background:
		var paper := ColorRect.new()
		paper.name = "AvatarPaperBackground"
		paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
		paper.position = Vector2.ONE * frame_width
		paper.size = size - Vector2.ONE * frame_width * 2
		var paper_material := ShaderMaterial.new()
		paper_material.shader = PAPER
		PAPER_STYLE.configure_material(paper_material, paper.size)
		paper_material.set_shader_parameter("paper_unit", _appearance_scale)
		paper_material.set_shader_parameter("corner_radius", maxf(0, corner_radius - frame_width))
		paper.material = paper_material
		add_child(paper)
	_image = TextureRect.new()
	_image.name = "AvatarTexture"
	_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_image.texture = avatar_texture
	_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_image.offset_left = image_inset
	_image.offset_top = image_inset
	_image.offset_right = -image_inset
	_image.offset_bottom = -image_inset
	var mask := ShaderMaterial.new()
	mask.shader = MASK
	_image.material = mask
	add_child(_image)
	# Keep previously attached decorations above the portrait.
	move_child(_image, 1 if paper_background else 0)
	_image.resized.connect(_sync_mask)
	_sync_mask()

func _has_point(point: Vector2) -> bool:
	return Rect2(Vector2.ZERO, size).has_point(point) or extra_hit_rect.has_point(point)

func _sync_mask() -> void:
	var mask := _image.material as ShaderMaterial
	mask.set_shader_parameter("source_size", _image.size)
	mask.set_shader_parameter("mask_rect", Vector4(0, 0, _image.size.x, _image.size.y))
	mask.set_shader_parameter("corner_radius", maxf(0, corner_radius - image_inset))

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

func _exit_tree() -> void:
	if _press_tween != null and _press_tween.is_valid():
		_press_tween.kill()
