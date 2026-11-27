extends ColorRect
## Settled Home art without the reveal controller, back face or animation state.
const SHADER: Shader = preload("res://shaders/startup_logo.gdshader")
const PAPER: Texture2D = preload("res://flash_assets/word_paper_torn.png")

var logo_texture: Texture2D = preload("res://flash_assets/main_menu_logo_word_trials.png")
var logo_rect: Rect2

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	color = Color.WHITE
	var ink := ShaderMaterial.new()
	ink.shader = SHADER
	ink.set_shader_parameter("logo_texture", logo_texture)
	ink.set_shader_parameter("paper_texture", PAPER)
	material = ink

func set_geometry(canvas_size: Vector2, rect: Rect2, paper_unit: float) -> void:
	# Match the bounds rounding in Home's Control.get_global_rect(), without
	# keeping a layout-only anchor node in the loading scene.
	rect.size = rect.end - rect.position
	logo_rect = rect
	size = canvas_size
	var ink := material as ShaderMaterial
	ink.set_shader_parameter("canvas_size", canvas_size)
	ink.set_shader_parameter("paper_canvas_size", canvas_size)
	ink.set_shader_parameter("paper_unit", paper_unit)
	ink.set_shader_parameter("logo_rect", Vector4(rect.position.x, rect.position.y, rect.size.x, rect.size.y))
