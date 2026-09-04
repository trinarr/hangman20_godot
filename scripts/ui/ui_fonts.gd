extends RefCounted

const FALLBACK_DISPLAY_FONT: Font = preload("res://fonts/BalsamiqSans-Bold.ttf")
const ROBOTO_FLEX_PATH: String = "res://" + "fonts/RobotoFlex-Variable.ttf"

# Headings.
const ROBOTO_FLEX_DISPLAY_WEIGHT: float = 750.0
const ROBOTO_FLEX_DISPLAY_WIDTH: float = 35.0
const ROBOTO_FLEX_DISPLAY_GRADE: float = -10.0
const ROBOTO_FLEX_DISPLAY_THIN_STROKE: float = 90.0

# Buttons: preserve the current tuning from the supplied ui_fonts.gd.
const ROBOTO_FLEX_BUTTON_WEIGHT: float = 680.0
const ROBOTO_FLEX_BUTTON_WIDTH: float = 25.0
const ROBOTO_FLEX_BUTTON_GRADE: float = -30.0
const ROBOTO_FLEX_BUTTON_THIN_STROKE: float = 80.0

# Shared Roboto Flex axes.
const ROBOTO_FLEX_SLANT: float = 0.0
const ROBOTO_FLEX_THICK_STROKE: float = 80.0

# Subway-style buttons devote more of their height to the caption. Keep this
# separate from heading sizing so page/popup titles are not enlarged.
const DISPLAY_BUTTON_FONT_SCALE: float = 1.25

static func display_button_font_size(font_size: int) -> int:
	return maxi(1, int(round(float(font_size) * DISPLAY_BUTTON_FONT_SCALE)))

static func _roboto_flex_font(
	weight: float,
	width: float,
	grade: float,
	thin_stroke: float
) -> Font:
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
		text_server.name_to_tag("wght"): weight,
		text_server.name_to_tag("wdth"): width,
		text_server.name_to_tag("slnt"): ROBOTO_FLEX_SLANT,
		text_server.name_to_tag("GRAD"): grade,
		text_server.name_to_tag("XOPQ"): ROBOTO_FLEX_THICK_STROKE,
		text_server.name_to_tag("YOPQ"): thin_stroke,
	}
	return variation

static func display_font() -> Font:
	return _roboto_flex_font(
		ROBOTO_FLEX_DISPLAY_WEIGHT,
		ROBOTO_FLEX_DISPLAY_WIDTH,
		ROBOTO_FLEX_DISPLAY_GRADE,
		ROBOTO_FLEX_DISPLAY_THIN_STROKE
	)

static func button_font() -> Font:
	return _roboto_flex_font(
		ROBOTO_FLEX_BUTTON_WEIGHT,
		ROBOTO_FLEX_BUTTON_WIDTH,
		ROBOTO_FLEX_BUTTON_GRADE,
		ROBOTO_FLEX_BUTTON_THIN_STROKE
	)
