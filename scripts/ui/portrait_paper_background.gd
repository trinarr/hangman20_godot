extends ColorRect

const PAPER_SHADER: Shader = preload("res://shaders/portrait_grid_paper.gdshader")
const PAPER_TEXTURE: Texture2D = preload("res://flash_assets/word_paper_torn.png")
const PORTRAIT_LAYOUT: GDScript = preload("res://scripts/ui/portrait_stage_layout.gd")
# Preserve the original Home grid's adaptive spacing on tall phones.
const MAX_PAPER_SCALE: float = 1.15

static func configure_material(target: ShaderMaterial, viewport_size: Vector2) -> void:
	target.set_shader_parameter("paper_texture", PAPER_TEXTURE)
	target.set_shader_parameter("paper_canvas_size", viewport_size)
	target.set_shader_parameter("paper_unit", PORTRAIT_LAYOUT.fit_scale(viewport_size)
		* PORTRAIT_LAYOUT.adaptive_ui_scale(viewport_size, MAX_PAPER_SCALE))

func _ready() -> void:
	name = "PortraitPaperBackground"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	color = Color.WHITE
	var paper_material := ShaderMaterial.new()
	paper_material.shader = PAPER_SHADER
	material = paper_material
	get_viewport().size_changed.connect(_sync_layout)
	_sync_layout()

func _sync_layout() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	configure_material(material as ShaderMaterial, size)

func _exit_tree() -> void:
	if get_viewport().size_changed.is_connected(_sync_layout):
		get_viewport().size_changed.disconnect(_sync_layout)
