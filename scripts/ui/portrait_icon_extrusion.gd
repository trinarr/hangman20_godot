extends RefCounted
## Icon extrusion. Nodes and deferred callbacks belong to the supplied holder.
const COMBINED_SHADOW = preload("res://scripts/ui/combined_icon_shadow.gd")

const PORTRAIT_UI_PALETTE: GDScript = preload("res://scripts/ui/ui_palette.gd")
const UI_MATERIALS: GDScript = preload("res://scripts/ui/ui_materials.gd")
const OUTLINE = preload("res://scripts/ui/colored_icon_outline.gd")
const ACTION_SHADOW_ALPHA: float = 0.50
const ACTION_SHADOW_OFFSET_SCALE: float = 0.70

static func _run_for_live_control(target_ref: WeakRef, action: Callable, args: Array = []) -> void:
	var target := target_ref.get_ref() as Control
	if target == null or !target.is_inside_tree() or !action.is_valid():
		return
	var call_args: Array = [target]
	call_args.append_array(args)
	action.callv(call_args)

static func _create_portrait_icon_extrusion_layers(
	parent: Control,
	texture: Texture2D,
	prefix: String,
	z_index: int = 0,
	shadow_alpha: float = 1.0
) -> Array[TextureRect]:
	var layers: Array[TextureRect] = []
	if parent == null or !is_instance_valid(parent) or texture == null:
		return layers
	var icon_shadow_base: Color = PORTRAIT_UI_PALETTE.NAV_TEXT_SHADOW
	var shadow_material: ShaderMaterial = UI_MATERIALS.icon_shadow(
		Color(
			icon_shadow_base.r,
			icon_shadow_base.g,
			icon_shadow_base.b,
			clampf(shadow_alpha, 0.0, 1.0)
		)
	)
	var layer := COMBINED_SHADOW.new()
	layer.name = "%sExtrusion01" % prefix
	layer.texture = texture
	layer.set_shadow_material(shadow_material)
	layer.z_index = z_index
	parent.add_child(layer)
	layers.append(layer)
	return layers

static func _layout_portrait_icon_extrusion_layers(
	layers: Array[TextureRect],
	icon_position: Vector2,
	icon_size: Vector2,
	shadow_offset_scale: float = 1.0
) -> void:
	var icon_extent: float = minf(icon_size.x, icon_size.y)
	var resolved_offset_scale: float = maxf(shadow_offset_scale, 0.0)
	var shadow_depth: float = (
		clampf(icon_extent * 0.055, 1.5, 5.0)
		* resolved_offset_scale
	)
	var shadow_offset_x: float = (
		minf(icon_extent * 0.012, 1.5)
		* resolved_offset_scale
	)
	for layer: TextureRect in layers:
		if !is_instance_valid(layer):
			continue
		layer.position = icon_position
		layer.size = icon_size
		layer.set("offset_step", Vector2(shadow_offset_x, shadow_depth))

static func set_shadow_material(layers: Array[TextureRect], material: ShaderMaterial) -> void:
	for layer: TextureRect in layers:
		if is_instance_valid(layer):
			layer.set_shadow_material(material)

static func _layout_portrait_icon_holder_extrusion(
	holder: Control,
	layers: Array[TextureRect],
	shadow_offset_scale: float = 1.0
) -> void:
	if holder == null or !is_instance_valid(holder):
		return
	_layout_portrait_icon_extrusion_layers(
		layers,
		Vector2.ZERO,
		holder.size,
		shadow_offset_scale
	)

static func _add_portrait_icon_with_extrusion_to_holder(
	holder: Control,
	texture: Texture2D,
	prefix: String,
	icon_z_index: int = 1,
	shadow_alpha: float = 1.0,
	shadow_offset_scale: float = 1.0
) -> TextureRect:
	if holder == null or !is_instance_valid(holder) or texture == null:
		return null
	var layers := _create_portrait_icon_extrusion_layers(
		holder,
		texture,
		prefix,
		icon_z_index - 1,
		shadow_alpha
	)
	if !holder.resized.is_connected(_layout_portrait_icon_holder_extrusion):
		holder.resized.connect(
			_layout_portrait_icon_holder_extrusion.bind(
				holder,
				layers,
				shadow_offset_scale
			)
		)
	_run_for_live_control.call_deferred(
		weakref(holder),
		_layout_portrait_icon_holder_extrusion,
		[layers, shadow_offset_scale]
	)
	var icon := TextureRect.new()
	icon.name = prefix
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = texture
	OUTLINE.apply(icon, texture)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.z_index = icon_z_index
	holder.add_child(icon)
	return icon
