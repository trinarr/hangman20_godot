extends RefCounted

# Only immutable materials belong here. Animated uniforms (shine progress,
# reveal masks, etc.) must remain owned by the individual control.
const TEXT_SHADOW_SHADER: Shader = preload("res://shaders/display_text_outline_shadow.gdshader")
const ICON_SHADOW_SHADER: Shader = preload("res://shaders/hint_icon_extrusion_shadow.gdshader")
const GRAYSCALE_SHADER: Shader = preload("res://shaders/hint_icon_grayscale.gdshader")
const OUTLINE = preload("res://scripts/ui/colored_icon_outline.gd")

static var _text_shadows: Dictionary = {}
static var _icon_shadows: Dictionary = {}
static var _outlined_icon_shadows: Dictionary = {}
static var _grayscale: ShaderMaterial = null
static var _outlined_grayscale: ShaderMaterial = null

static func text_shadow(color: Color) -> ShaderMaterial:
	return _shadow_material(_text_shadows, TEXT_SHADOW_SHADER, color)

static func icon_shadow(color: Color, outline_pixels: float = 0.0) -> ShaderMaterial:
	if outline_pixels > 0.0:
		var key := [color, outline_pixels]
		if !_outlined_icon_shadows.has(key):
			var material := ShaderMaterial.new()
			material.shader = ICON_SHADOW_SHADER
			material.set_shader_parameter("shadow_color", color)
			material.set_shader_parameter("colored_outline", true)
			material.set_shader_parameter("outline_pixels", outline_pixels)
			_outlined_icon_shadows[key] = material
		return _outlined_icon_shadows[key]
	return _shadow_material(_icon_shadows, ICON_SHADOW_SHADER, color)

static func _shadow_material(cache: Dictionary, shader: Shader, color: Color) -> ShaderMaterial:
	if cache.has(color):
		return cache[color] as ShaderMaterial
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter(&"shadow_color", color)
	cache[color] = material
	return material

static func grayscale(texture: Texture2D = null) -> ShaderMaterial:
	if OUTLINE.supports(texture):
		if _outlined_grayscale == null:
			_outlined_grayscale = ShaderMaterial.new()
			_outlined_grayscale.shader = GRAYSCALE_SHADER
			_outlined_grayscale.set_shader_parameter("colored_outline", true)
			_outlined_grayscale.set_shader_parameter("outline_color", OUTLINE.PALETTE.TEXT_DARK)
		return _outlined_grayscale
	if _grayscale == null:
		_grayscale = ShaderMaterial.new()
		_grayscale.shader = GRAYSCALE_SHADER
	return _grayscale
