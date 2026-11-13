extends SceneTree
## Reproduce sampler compilation failures without game autoloads or user saves.
const SHADERS := [
	"colored_icon_outline", "hint_icon_extrusion_shadow", "hint_icon_grayscale",
	"reward_chest_flash", "theme_unlock_icon_grayscale",
]

func _initialize() -> void:
	var checks: int = 0
	var failures: int = 0
	for name: String in SHADERS:
		var shader := load("res://shaders/%s.gdshader" % name) as Shader
		var material := ShaderMaterial.new()
		material.shader = shader
		# Assigning the uniform triggers the dummy renderer's shader compiler.
		material.set_shader_parameter("colored_outline", true)
		var has_outline: bool = false
		for parameter: Dictionary in shader.get_shader_uniform_list():
			if parameter.name == "colored_outline":
				has_outline = true
		checks += 1
		if !has_outline:
			failures += 1
			push_error("Missing outline uniforms: " + name)
	print("ICON_OUTLINE_COMPILE checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
