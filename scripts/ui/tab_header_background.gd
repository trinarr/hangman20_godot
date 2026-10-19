extends ColorRect
## Independent gradient material; only the upper corners are rounded.
const SHADER = preload("res://shaders/tab_header_gradient.gdshader")
const PALETTE = preload("res://scripts/ui/ui_palette.gd")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gradient := ShaderMaterial.new()
	gradient.shader = SHADER
	gradient.set_shader_parameter("top_color", PALETTE.THEME_CARD_SELECTED)
	gradient.set_shader_parameter("bottom_color", PALETTE.UI_BLUE)
	material = gradient
	resized.connect(_sync_size)
	_sync_size()

func _sync_size() -> void:
	if material is ShaderMaterial:
		material.set_shader_parameter("rect_size", size)
