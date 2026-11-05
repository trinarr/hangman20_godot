extends TextureRect
## Four authored extrusion samples in one draw. The material belongs to this node.
const SHADER = preload("res://shaders/combined_icon_shadow.gdshader")
const CACHE = preload("res://scripts/ui/icon_outline_mask_cache.gd")
var offset_step := Vector2.ZERO
var _cache: Node
var _entry: Dictionary = {}
var _key: Array = []
var _state: Array = []

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	material = ShaderMaterial.new()
	material.shader = SHADER

func set_shadow_material(source: ShaderMaterial) -> void:
	for parameter in ["shadow_color", "colored_outline", "outline_pixels"]:
		var value: Variant = source.get_shader_parameter(parameter)
		if value == null:
			value = RenderingServer.shader_get_parameter_default(source.shader.get_rid(), parameter)
		material.set_shader_parameter(parameter, value)
	_key.clear()

func _enter_tree() -> void:
	if !RenderingServer.frame_pre_draw.is_connected(_sync_mask):
		RenderingServer.frame_pre_draw.connect(_sync_mask)

func _exit_tree() -> void:
	RenderingServer.frame_pre_draw.disconnect(_sync_mask)
	_release()

func _release() -> void:
	if _entry.is_empty() and _state.is_empty() and _key.is_empty():
		return
	if is_instance_valid(_cache):
		_cache.release(_entry)
	_entry = {}
	_key.clear()
	_state.clear()
	material.set_shader_parameter("use_mask", false)

func _sync_mask() -> void:
	if texture == null or !is_visible_in_tree() or size.x <= 0.0 or size.y <= 0.0:
		_release()
		return
	var transform := get_viewport().get_final_transform() * get_global_transform_with_canvas()
	var pixels := Vector2(transform.x.length(), transform.y.length()).max(Vector2.ONE * 0.001)
	var factor := minf(size.x / texture.get_width(), size.y / texture.get_height())
	var fitted := texture.get_size() * factor
	var outlined: bool = material.get_shader_parameter("colored_outline") == true
	var width: float = float(material.get_shader_parameter("outline_pixels")) if outlined else 0.0
	var local_transform := get_transform()
	var snapped := get_viewport().gui_snap_controls_to_pixels and absf(sin(rotation * 4.0)) < 0.00001
	var shared_pivot: bool = get_parent().has_method("_sync_visual_child_scales") and get_parent().get("press_scale_enabled") == true
	var state := [texture.get_instance_id(), size, pixels, offset_step, outlined, width, local_transform, snapped, shared_pivot]
	if state == _state and (!outlined or !_entry.is_empty()):
		return
	var offsets: Array[Vector2] = []
	var extent := Vector2.ZERO
	for fraction: float in [0.25, 0.55, 0.80, 1.0]:
		var offset := offset_step * fraction
		# Flash buttons scale every child about their shared visual centre by
		# changing each child's pivot. The former offsets scale with them.
		if shared_pivot:
			offset = local_transform.basis_xform(offset)
		if snapped:
			# Control rounds each old layer's local translation independently.
			# Preserve those positions when all four silhouettes share one draw.
			offset = (local_transform.origin + offset + Vector2.ONE * 0.5).floor() - (local_transform.origin + Vector2.ONE * 0.5).floor()
		offset = local_transform.affine_inverse().basis_xform(offset)
		offsets.append(offset)
		extent = extent.max(offset)
	_state = state
	material.set_shader_parameter("source_tex", texture)
	material.set_shader_parameter("icon_size", size)
	material.set_shader_parameter("fitted_size", fitted)
	material.set_shader_parameter("shadow_extent", extent)
	for index in range(4):
		material.set_shader_parameter("layer_%d" % (index + 1), offsets[index])
	material.set_shader_parameter("padding", Vector2.ONE * (width + 1.0) / pixels if outlined else Vector2.ZERO)
	if !outlined:
		if !_entry.is_empty(): _release()
		return
	var physical_size := (fitted * pixels * 64.0).round() / 64.0
	var key := [texture.get_instance_id(), physical_size, width]
	if key != _key or _entry.is_empty():
		_release()
		_cache = CACHE.for_control(self)
		_entry = _cache.acquire(texture, physical_size, width)
		_key = key
		_state = state
	material.set_shader_parameter("use_mask", !_entry.is_empty())
	if !_entry.is_empty():
		material.set_shader_parameter("mask_tex", _entry.viewport.get_texture())
		material.set_shader_parameter("mask_size", Vector2(_entry.viewport.size))
		material.set_shader_parameter("pixel_scale", physical_size / fitted)
