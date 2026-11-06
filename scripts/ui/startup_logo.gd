extends ColorRect
## Settled Home art without the reveal controller, back face or animation state.
const SHADER: Shader = preload("res://shaders/startup_logo.gdshader")
const LOGO_EN: Texture2D = preload("res://flash_assets/main_menu_logo_hangman_20.png")
const LOGO_RU_PATH: String = "res://flash_assets/main_menu_logo_viselitsa_20.png"
const PAPER: Texture2D = preload("res://flash_assets/word_paper_torn.png")

var logo_texture: Texture2D = LOGO_EN
var title_texture: Texture2D
var title_chroma_key: bool = false
var logo_rect: Rect2
var language: String = "en"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	color = Color.WHITE
	var ink := ShaderMaterial.new()
	ink.shader = SHADER
	ink.set_shader_parameter("logo_texture", logo_texture)
	ink.set_shader_parameter("paper_texture", PAPER)
	material = ink
	set_language(language)

func set_language(value: String) -> void:
	language = value
	title_chroma_key = language == "ru"
	title_texture = load(LOGO_RU_PATH) as Texture2D if title_chroma_key else LOGO_EN
	(material as ShaderMaterial).set_shader_parameter("title_texture", title_texture)
	(material as ShaderMaterial).set_shader_parameter("title_chroma_key", title_chroma_key)

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
