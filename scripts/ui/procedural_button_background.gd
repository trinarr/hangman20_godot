extends ColorRect
## Direct analytic button rendering. No image atlas, generated bitmap or viewport.
const SHADER: Shader = preload("res://shaders/procedural_button.gdshader")
var _shader_material: ShaderMaterial
var _signature: Array = []

func _init() -> void:
	name = "ProceduralButtonBackground"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	show_behind_parent = true
	visible = false
	color = Color.WHITE
	_shader_material = ShaderMaterial.new()
	_shader_material.shader = SHADER
	material = _shader_material

func configure(body: Vector2, visual: Vector2, round_shape: bool, tint: Color,
	pressed_relief: bool, shadow: Color, offset: float) -> void:
	visible = body.x > 0.0 and body.y > 0.0 and visual.x > 0.0 and visual.y > 0.0
	if !visible:
		return
	var margin := maxf(2.0, offset + 2.0)
	# Child controls receive visual_scale from the owner too. Set it explicitly
	# here so initial setup, resizing and animated press all use it exactly once.
	position = -Vector2.ONE * margin
	size = body + Vector2.ONE * margin * 2.0
	pivot_offset = body * 0.5 - position
	scale = visual
	var signature: Array = [body, margin, round_shape, tint, pressed_relief, shadow, offset]
	if signature == _signature:
		return
	_signature = signature
	_shader_material.set_shader_parameter("body_size", body)
	_shader_material.set_shader_parameter("padding", margin)
	_shader_material.set_shader_parameter("round_shape", round_shape)
	_shader_material.set_shader_parameter("face_tint", tint)
	_shader_material.set_shader_parameter("relief_pressed", pressed_relief)
	_shader_material.set_shader_parameter("shadow_color", shadow)
	_shader_material.set_shader_parameter("shadow_offset", offset)
