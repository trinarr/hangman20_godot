extends RefCounted

const FALLBACK_DISPLAY_FONT: Font = preload("res://fonts/BalsamiqSans-Bold.ttf")
const ROBOTO_FLEX_PATH: String = "res://" + "fonts/RobotoFlex-Variable.ttf"
const ROBOTO_FLEX_DISPLAY_WEIGHT: float = 900.0
const ROBOTO_FLEX_DISPLAY_WIDTH: float = 77.0
const ROBOTO_FLEX_THIN_STROKE: float = 46.0

# Subway-style buttons devote more of their height to the caption. Keep this
# separate from heading sizing so page/popup titles are not enlarged.
const DISPLAY_BUTTON_FONT_SCALE: float = 1.09296

static func display_button_font_size(font_size: int) -> int:
	return maxi(1, int(round(float(font_size) * DISPLAY_BUTTON_FONT_SCALE)))

static func _roboto_flex_font() -> Font:
	if !ResourceLoader.exists(ROBOTO_FLEX_PATH):
		return FALLBACK_DISPLAY_FONT
	var loaded_resource: Resource = ResourceLoader.load(ROBOTO_FLEX_PATH)
	var base_font: Font = loaded_resource as Font
	if base_font == null:
		return FALLBACK_DISPLAY_FONT
	var variation := FontVariation.new()
	variation.base_font = base_font
	var text_server := TextServerManager.get_primary_interface()
	variation.variation_opentype = {
		text_server.name_to_tag("wght"): ROBOTO_FLEX_DISPLAY_WEIGHT,
		text_server.name_to_tag("wdth"): ROBOTO_FLEX_DISPLAY_WIDTH,
		text_server.name_to_tag("YOPQ"): ROBOTO_FLEX_THIN_STROKE,
	}
	return variation

static func display_font() -> Font:
	return _roboto_flex_font()

static func button_font() -> Font:
	return _roboto_flex_font()
