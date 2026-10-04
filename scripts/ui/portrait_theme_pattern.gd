extends RefCounted
## Pattern/gradient renderer. The supplied background owns all nodes and animation.

static func _optional_node_meta(node: Object, key: StringName) -> Variant:
	return node.get_meta(key) if node.has_meta(key) else null

static func _run_for_live_control(target_ref: WeakRef, action: Callable, args: Array = []) -> void:
	var target := target_ref.get_ref() as Control
	if target == null or !target.is_inside_tree() or !action.is_valid():
		return
	var call_args: Array = [target]
	call_args.append_array(args)
	action.callv(call_args)

static func _layout_multi_theme_pattern(clip_root: Control, motion: Control, theme_textures: Array, icon_modulate: Color, spacing_multiplier: float, icon_scale: float, move_duration_multiplier: float, bottom_alpha: float, full_alpha_screen_ratio: float, base_spacing: float, base_icon_size: float, base_move_duration: float) -> void:
	if clip_root == null or !is_instance_valid(clip_root):
		return
	if motion == null or !is_instance_valid(motion):
		return
	if theme_textures.is_empty():
		return

	var clip_size: Vector2 = clip_root.size
	if clip_size.x <= 0.0 or clip_size.y <= 0.0:
		return

	var signature: Array = [clip_size, theme_textures.duplicate(), icon_modulate,
		spacing_multiplier, icon_scale, move_duration_multiplier, bottom_alpha,
		full_alpha_screen_ratio]
	var existing_tween: Tween = _optional_node_meta(motion, "pattern_move_tween") as Tween
	var tween_running: bool = existing_tween != null and existing_tween.is_valid()
	if motion.get_meta("pattern_layout_signature", []) == signature and tween_running:
		return

	var spacing: float = base_spacing * maxf(spacing_multiplier, 0.05)
	var move_duration: float = base_move_duration * maxf(move_duration_multiplier, 0.01)
	var motion_signature: Vector2 = Vector2(spacing, move_duration)
	var restart_motion: bool = !tween_running or motion.get_meta("pattern_motion_signature", Vector2.ZERO) != motion_signature
	if restart_motion:
		if tween_running:
			existing_tween.kill()
		motion.position = Vector2.ZERO
	var overscan: float = spacing * 2.0
	motion.size = clip_size + Vector2.ONE * overscan * 2.0
	var cols: int = int(ceil((clip_size.x + overscan * 2.0) / spacing)) + 2
	var rows: int = int(ceil((clip_size.y + overscan * 2.0) / spacing)) + 2
	# Keep the existing prefix on resize; allocate/release only the difference.
	var icon_count: int = rows * cols
	while motion.get_child_count() > icon_count:
		motion.get_child(motion.get_child_count() - 1).free()
	var texture_count: int = theme_textures.size()
	var gradient_height: float = maxf(clip_size.y + overscan * 2.0, 1.0)
	var top_alpha: float = icon_modulate.a
	var effective_bottom_alpha: float = top_alpha if bottom_alpha < 0.0 else clampf(bottom_alpha, 0.0, 1.0)
	var clamped_full_alpha_ratio: float = clampf(full_alpha_screen_ratio, 0.0, 1.0)
	for row: int in range(rows):
		for col: int in range(cols):
			var index: int = row * cols + col
			var icon: TextureRect
			if index < motion.get_child_count():
				icon = motion.get_child(index) as TextureRect
			else:
				icon = TextureRect.new()
				motion.add_child(icon)
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			icon.texture = theme_textures[(row * cols + col) % texture_count] as Texture2D
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.size = Vector2.ONE * base_icon_size * maxf(icon_scale, 0.05)
			icon.position = Vector2(
				-overscan
					+ float(col) * spacing
					+ (spacing * 0.5 if row % 2 == 0 else 0.0),
				-overscan + float(row) * spacing
			)
			var icon_center_y: float = icon.position.y + icon.size.y * 0.5
			var screen_y_ratio: float = clampf((icon_center_y + overscan) / gradient_height, 0.0, 1.0)
			var icon_alpha: float = top_alpha
			if bottom_alpha >= 0.0:
				if clamped_full_alpha_ratio > 0.0 and clamped_full_alpha_ratio < 1.0:
					var fade_t: float = clampf(
						(1.0 - screen_y_ratio) / (1.0 - clamped_full_alpha_ratio),
						0.0,
						1.0
					)
					# Softer ease-in: 30% closer to linear than the previous t^2 curve,
					# while still growing slowly at first and accelerating toward the threshold.
					fade_t = pow(fade_t, 1.7)
					icon_alpha = lerpf(effective_bottom_alpha, top_alpha, fade_t)
				else:
					icon_alpha = lerpf(top_alpha, effective_bottom_alpha, screen_y_ratio)
			icon.modulate = Color(icon_modulate.r, icon_modulate.g, icon_modulate.b, icon_alpha)
			icon.rotation_degrees = -18.0

	motion.set_meta("pattern_layout_signature", signature)
	if !restart_motion:
		return
	motion.set_meta("pattern_motion_signature", motion_signature)
	var move_tween := motion.create_tween()
	move_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	move_tween.set_loops()
	var repeat_offset := Vector2(spacing * 0.5, -spacing)
	var move := move_tween.tween_property(
		motion,
		"position",
		repeat_offset,
		move_duration
	)
	move.from(Vector2.ZERO)
	move.set_trans(Tween.TRANS_LINEAR)
	motion.set_meta("pattern_move_tween", move_tween)

static func _add_multi_theme_pattern(background_overlay: Control, theme_textures: Array, pattern_name: String, icon_modulate: Color, spacing_multiplier: float, icon_scale: float, move_duration_multiplier: float, bottom_alpha: float, full_alpha_screen_ratio: float, base_spacing: float, base_icon_size: float, base_move_duration: float) -> void:
	if background_overlay == null or !is_instance_valid(background_overlay):
		return
	if theme_textures.is_empty():
		return
	var clip_root := Control.new()
	clip_root.name = pattern_name
	clip_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_root.clip_contents = true
	clip_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	clip_root.offset_left = 0.0
	clip_root.offset_top = 0.0
	clip_root.offset_right = 0.0
	clip_root.offset_bottom = 0.0
	background_overlay.add_child(clip_root)

	var motion := Control.new()
	motion.name = "PatternMotion"
	motion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	motion.position = Vector2.ZERO
	clip_root.add_child(motion)
	clip_root.resized.connect(_layout_multi_theme_pattern.bind(clip_root, motion, theme_textures, icon_modulate, spacing_multiplier, icon_scale, move_duration_multiplier, bottom_alpha, full_alpha_screen_ratio, base_spacing, base_icon_size, base_move_duration))
	_run_for_live_control.call_deferred(
		weakref(clip_root),
		_layout_multi_theme_pattern,
		[motion, theme_textures, icon_modulate, spacing_multiplier, icon_scale,
			move_duration_multiplier, bottom_alpha, full_alpha_screen_ratio,
			base_spacing, base_icon_size, base_move_duration]
	)

static func _add_full_rect_gradient_overlay(background_overlay: Control, top_color: Color, bottom_color: Color, overlay_name: String = "GradientOverlay") -> void:
	if background_overlay == null or !is_instance_valid(background_overlay):
		return
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([top_color, bottom_color])
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	var gradient_texture := GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.fill = GradientTexture2D.FILL_LINEAR
	gradient_texture.fill_from = Vector2(0.5, 0.0)
	gradient_texture.fill_to = Vector2(0.5, 1.0)
	gradient_texture.width = 1
	gradient_texture.height = 256
	var overlay := TextureRect.new()
	overlay.name = overlay_name
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.texture = gradient_texture
	overlay.stretch_mode = TextureRect.STRETCH_SCALE
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.offset_left = 0.0
	overlay.offset_top = 0.0
	overlay.offset_right = 0.0
	overlay.offset_bottom = 0.0
	# Keep the gradient above the patterned body but below the top-bar surface
	# and all interactive Home controls. The parent background itself sits at -1.
	overlay.z_index = 0
	background_overlay.add_child(overlay)
