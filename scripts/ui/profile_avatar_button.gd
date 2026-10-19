extends Button
## Shared portrait, frame and paper styling for Home and Profile.
const PALETTE = preload("res://scripts/ui/ui_palette.gd")
const MASK = preload("res://scripts/ui/rounded_rect_texture_mask.gdshader")
const PAPER = preload("res://shaders/profile_avatar_paper.gdshader")
const PAPER_STYLE = preload("res://scripts/ui/portrait_paper_background.gd")
const CHARACTER = preload("res://scripts/ui/profile_character_preview.gd")
const PROFILE = preload("res://scripts/core/player_profile.gd")
const LUCKY = preload("res://img/_______192______1_0_SHAPE_0_BOUNDS_-0.96_-0.96_SIZE_329_709.png")
const EL_TIGRE = preload("res://img/_______405______1_0_SHAPE_0_BOUNDS_-0.96_-0.96_SIZE_366_322.png")
const PROFILE_SIZE := 117.0
const SMALL_OUTLINE_WIDTH := 1
const LARGE_OUTLINE_WIDTH := SMALL_OUTLINE_WIDTH
var _appearance_scale := 1.0
var outer_outline_width := SMALL_OUTLINE_WIDTH
var paper_background := false
var portrait_enabled := true
var frame_shadow_enabled := true
var solid_background_color := Color.TRANSPARENT
var resting_scale: float = 1.0:
	set(value):
		resting_scale = value
		if _press_tween != null and _press_tween.is_valid():
			_press_tween.kill()
		scale = Vector2.ONE * resting_scale
var extra_hit_rect := Rect2()
var frame_color: Color = PALETTE.BUTTON_BLUE_OUTLINE
var frame_width: int = 2
var corner_radius: int = 12
var image_inset: float = 4.0
var avatar_texture: Texture2D = preload("res://img/_______405______1_0_SHAPE_0_BOUNDS_-0.96_-0.96_SIZE_366_322.png"):
	set(value):
		avatar_texture = value
		if is_instance_valid(_image) and !is_instance_valid(_portrait_viewport):
			_image.texture = value
var _press_tween: Tween
var _image: TextureRect
var _portrait_viewport: SubViewport
var _character: Node2D
var _outer_frame_style: StyleBoxFlat

func configure_profile_appearance(side: float) -> void:
	_appearance_scale = side / PROFILE_SIZE
	outer_outline_width = LARGE_OUTLINE_WIDTH if side >= PROFILE_SIZE else SMALL_OUTLINE_WIDTH
	paper_background = true
	frame_color = PROFILE.FRAME_COLORS[GameState.player_frame_id - 1]
	frame_width = maxi(1, roundi(6 * _appearance_scale)) + 1
	corner_radius = maxi(1, roundi(14 * _appearance_scale))
	image_inset = frame_width
	refresh_character()

func refresh_character() -> void:
	if portrait_enabled and paper_background:
		frame_color = PROFILE.FRAME_COLORS[GameState.player_frame_id - 1]
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			if has_theme_stylebox_override(state):
				(get_theme_stylebox(state) as StyleBoxFlat).border_color = frame_color
	if !portrait_enabled:
		avatar_texture = null
		return
	if GameState.settings.size() > 5 and int(GameState.settings[5]) == 2:
		avatar_texture = EL_TIGRE
	else:
		var portrait := AtlasTexture.new()
		portrait.atlas = LUCKY
		portrait.region = Rect2(28, 0, 470, 470)
		avatar_texture = portrait
	if is_instance_valid(_character):
		_character.show_character(2 if GameState.settings.size() > 5 and int(GameState.settings[5]) == 2 else 1)
		_sync_portrait()

func _ready() -> void:
	if portrait_enabled:
		visible = GameState.is_single_player_guided_onboarding_completed()
		GameState.guided_onboarding_finished.connect(show)
	resized.connect(_sync_press_pivot)
	button_down.connect(func(): _animate_press(true))
	button_up.connect(func(): _animate_press(false))
	visibility_changed.connect(_reset_press_if_hidden)
	_sync_press_pivot()
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_outer_frame_style = StyleBoxFlat.new()
	_outer_frame_style.draw_center = false
	_outer_frame_style.border_color = PALETTE.TEXT_DARK
	_outer_frame_style.set_border_width_all(outer_outline_width)
	_outer_frame_style.set_corner_radius_all(corner_radius + outer_outline_width)
	queue_redraw()
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color.TRANSPARENT if paper_background else (PALETTE.BUTTON_BLUE_PRESSED if state == "pressed" else PALETTE.BUTTON_BLUE)
		if solid_background_color.a > 0.0:
			style.bg_color = solid_background_color
		style.border_color = frame_color
		style.set_border_width_all(frame_width)
		style.set_corner_radius_all(corner_radius)
		if frame_shadow_enabled:
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
	if paper_background and portrait_enabled:
		_portrait_viewport = SubViewport.new()
		_portrait_viewport.name = "CroppedCharacterViewport"
		_portrait_viewport.disable_3d = true
		_portrait_viewport.transparent_bg = true
		_portrait_viewport.world_2d = World2D.new()
		_portrait_viewport.size_2d_override_stretch = true
		add_child(_portrait_viewport)
		_character = CHARACTER.new()
		_portrait_viewport.add_child(_character)
		refresh_character()
		_image.texture = _portrait_viewport.get_texture()

func _draw() -> void:
	if _outer_frame_style != null:
		draw_style_box(_outer_frame_style, Rect2(Vector2.ZERO, size).grow(outer_outline_width))

func _sync_portrait() -> void:
	if !is_instance_valid(_portrait_viewport):
		return
	var logical := _image.size.max(Vector2.ONE)
	var pixel_scale := get_global_transform_with_canvas().get_scale().abs() * get_viewport().get_stretch_transform().get_scale().abs()
	_portrait_viewport.size = Vector2i((logical * pixel_scale).ceil()).max(Vector2i(2, 2))
	_portrait_viewport.size_2d_override = Vector2i(logical.round())
	_character.fit_portrait(Rect2(Vector2.ZERO, logical), _appearance_scale)
	_portrait_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

func _has_point(point: Vector2) -> bool:
	return Rect2(Vector2.ZERO, size).has_point(point) or extra_hit_rect.has_point(point)

func _sync_mask() -> void:
	var mask := _image.material as ShaderMaterial
	mask.set_shader_parameter("source_size", _image.size)
	mask.set_shader_parameter("mask_rect", Vector4(0, 0, _image.size.x, _image.size.y))
	mask.set_shader_parameter("corner_radius", maxf(0, corner_radius - image_inset))
	_sync_portrait()

func _sync_press_pivot() -> void:
	pivot_offset = size * 0.5

func _animate_press(down: bool) -> void:
	if _press_tween != null and _press_tween.is_valid():
		_press_tween.kill()
	_press_tween = create_tween()
	_press_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_press_tween.tween_property(self, "scale", Vector2.ONE * resting_scale * (0.94 if down else 1.0), 0.055 if down else 0.085).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _reset_press_if_hidden() -> void:
	if !is_visible_in_tree():
		if _press_tween != null and _press_tween.is_valid():
			_press_tween.kill()
		scale = Vector2.ONE * resting_scale

func _exit_tree() -> void:
	if _press_tween != null and _press_tween.is_valid():
		_press_tween.kill()
