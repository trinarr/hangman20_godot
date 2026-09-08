extends RefCounted

# Only immutable materials belong here. Animated uniforms (shine progress,
# reveal masks, etc.) must remain owned by the individual control.
const TEXT_SHADOW_SHADER: Shader = preload("res://shaders/display_text_outline_shadow.gdshader")
const ICON_SHADOW_SHADER: Shader = preload("res://shaders/hint_icon_extrusion_shadow.gdshader")
const GRAYSCALE_SHADER: Shader = preload("res://shaders/hint_icon_grayscale.gdshader")

static var _text_shadows: Dictionary = {}
static var _icon_shadows: Dictionary = {}
static var _grayscale: ShaderMaterial = null

static func text_shadow(color: Color) -> ShaderMaterial:
	return _shadow_material(_text_shadows, TEXT_SHADOW_SHADER, color)

static func icon_shadow(color: Color) -> ShaderMaterial:
	return _shadow_material(_icon_shadows, ICON_SHADOW_SHADER, color)

static func _shadow_material(cache: Dictionary, shader: Shader, color: Color) -> ShaderMaterial:
	if cache.has(color):
		return cache[color] as ShaderMaterial
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter(&"shadow_color", color)
	cache[color] = material
	return material

static func grayscale() -> ShaderMaterial:
	if _grayscale == null:
		_grayscale = ShaderMaterial.new()
		_grayscale.shader = GRAYSCALE_SHADER
	return _grayscale
