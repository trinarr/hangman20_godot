extends RefCounted

const FALLBACK_DISPLAY_FONT: Font = preload("res://fonts/BalsamiqSans-Bold.ttf")
const NUNITO_SANS_PATH: String = "res://" + "fonts/NunitoSans-Variable.ttf"
const NUNITO_SANS_DISPLAY_WEIGHT: float = 1000.0
const NUNITO_SANS_DISPLAY_WIDTH: float = 85.0

static func display_font() -> Font:
	if !ResourceLoader.exists(NUNITO_SANS_PATH):
		return FALLBACK_DISPLAY_FONT
	var loaded_resource: Resource = ResourceLoader.load(NUNITO_SANS_PATH)
	var base_font: Font = loaded_resource as Font
	if base_font == null:
		return FALLBACK_DISPLAY_FONT
	var variation := FontVariation.new()
	variation.base_font = base_font
	var text_server := TextServerManager.get_primary_interface()
	variation.variation_opentype = {
		text_server.name_to_tag("wght"): NUNITO_SANS_DISPLAY_WEIGHT,
		text_server.name_to_tag("wdth"): NUNITO_SANS_DISPLAY_WIDTH,
	}
	return variation
