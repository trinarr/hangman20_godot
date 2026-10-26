extends RefCounted
## Immutable default material; animated/disabled effects retain their own shaders.
const SHADER = preload("res://shaders/colored_icon_outline.gdshader")
const PALETTE = preload("res://scripts/ui/ui_palette.gd")
const DEFAULT_PIXELS := 2.0
const THEME_PIXELS := 5.0
const POPUP_PIXELS := 5.0
const CHAIN_PIXELS := 5.0
const LARGE_REWARD_PIXELS := 8.0
const PATHS := [
	"res://flash_assets/star_currency_icon.png", "res://flash_assets/soft_currency_coin.png",
	"res://flash_assets/life_heart_icon.png", "res://flash_assets/coin_pack_04.png",
	"res://flash_assets/reward_chest_closed.png", "res://flash_assets/reward_chest_open.png",
	"res://flash_assets/tournament_trophy_front.png", "res://assets/tournament/start_trophy_low.png",
	"res://flash_assets/extra_attempts_icon.png",
]
static var _materials: Dictionary = {}

static func supports(texture: Texture2D) -> bool:
	return texture != null and (texture.resource_path in PATHS or texture.resource_path.begins_with("res://flash_assets/theme_icons/"))

static func material(outline_pixels: float = DEFAULT_PIXELS) -> ShaderMaterial:
	var width := clampf(outline_pixels, 0.0, 12.0)
	if !_materials.has(width):
		var result := ShaderMaterial.new()
		result.shader = SHADER
		result.set_shader_parameter("colored_outline", true)
		result.set_shader_parameter("outline_color", PALETTE.TEXT_DARK)
		result.set_shader_parameter("outline_pixels", width)
		_materials[width] = result
	return _materials[width]

static func apply(target: CanvasItem, texture: Texture2D, outline_pixels: float = DEFAULT_PIXELS) -> void:
	if supports(texture):
		target.material = material(outline_pixels)
	elif target.material != null and target.material in _materials.values():
		target.material = null
