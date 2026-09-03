extends RefCounted

const FALLBACK_DISPLAY_FONT: Font = preload("res://fonts/BalsamiqSans-Bold.ttf")
const NUNITO_PATH: String = "res://" + "fonts/Nunito-Variable.ttf"
const NUNITO_DISPLAY_WEIGHT: float = 900.0

# Subway-style buttons devote more of their height to the caption. Keep this
# separate from heading sizing so page/popup titles are not enlarged.
const DISPLAY_BUTTON_FONT_SCALE: float = 1.09296

static func display_button_font_size(font_size: int) -> int:
	return maxi(1, int(round(float(font_size) * DISPLAY_BUTTON_FONT_SCALE)))

static func _nunito_font(horizontal_scale: float = 1.0) -> Font:
	if !ResourceLoader.exists(NUNITO_PATH):
		return FALLBACK_DISPLAY_FONT
	var loaded_resource: Resource = ResourceLoader.load(NUNITO_PATH)
	var base_font: Font = loaded_resource as Font
	if base_font == null:
		return FALLBACK_DISPLAY_FONT
	var variation := FontVariation.new()
	variation.base_font = base_font
	var text_server := TextServerManager.get_primary_interface()
	variation.variation_opentype = {
		text_server.name_to_tag("wght"): NUNITO_DISPLAY_WEIGHT,
	}
	variation.variation_transform = Transform2D(
		Vector2(horizontal_scale, 0.0),
		Vector2(0.0, 1.0),
		Vector2.ZERO
	)
	return variation

static func display_font() -> Font:
	return _nunito_font()

static func button_font() -> Font:
	return _nunito_font(1.0)
