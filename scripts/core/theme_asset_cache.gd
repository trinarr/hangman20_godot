class_name ThemeAssetCache
extends RefCounted

# Theme art is needed only after the player opens a category screen. Keeping the
# paths here avoids loading all twenty textures while the first frame is still
# being assembled. A background request warms both catalogs from the Home screen.
const COLOR_ICON_PATHS := {
	1: "res://flash_assets/theme_icons/theme_icon_sport.png",
	2: "res://flash_assets/theme_icons/theme_icon_geography.png",
	3: "res://flash_assets/theme_icons/theme_icon_nature.png",
	4: "res://flash_assets/theme_icons/theme_icon_technics.png",
	5: "res://flash_assets/theme_icons/theme_icon_people.png",
	6: "res://flash_assets/theme_icons/theme_icon_food.png",
	7: "res://flash_assets/theme_icons/theme_icon_science.png",
	8: "res://flash_assets/theme_icons/theme_icon_history.png",
	9: "res://flash_assets/theme_icons/theme_icon_general.png",
	10: "res://flash_assets/theme_icons/theme_icon_film_music.png",
}

const MONO_ICON_PATHS := {
	1: "res://flash_assets/theme_icons_mono/theme_icon_sport_white.png",
	2: "res://flash_assets/theme_icons_mono/theme_icon_geography_white.png",
	3: "res://flash_assets/theme_icons_mono/theme_icon_nature_white.png",
	4: "res://flash_assets/theme_icons_mono/theme_icon_technics_white.png",
	5: "res://flash_assets/theme_icons_mono/theme_icon_people_white.png",
	6: "res://flash_assets/theme_icons_mono/theme_icon_food_white.png",
	7: "res://flash_assets/theme_icons_mono/theme_icon_science_white.png",
	8: "res://flash_assets/theme_icons_mono/theme_icon_history_white.png",
	9: "res://flash_assets/theme_icons_mono/theme_icon_general_white.png",
	10: "res://flash_assets/theme_icons_mono/theme_icon_film_music_white.png",
}

static var _cache: Dictionary = {}
static var _requests: Dictionary = {}

static func prewarm() -> void:
	for path_variant: Variant in COLOR_ICON_PATHS.values():
		_request(str(path_variant))
	for path_variant: Variant in MONO_ICON_PATHS.values():
		_request(str(path_variant))

static func get_icon(theme_id: int, monochrome: bool = false) -> Texture2D:
	var catalog: Dictionary = MONO_ICON_PATHS if monochrome else COLOR_ICON_PATHS
	var path: String = str(catalog.get(theme_id, ""))
	if path.is_empty():
		return null
	var cached: Variant = _cache.get(path)
	if cached is Texture2D:
		return cached as Texture2D

	var threaded_texture: Texture2D = _take_threaded_texture_if_ready(path)
	if threaded_texture != null:
		return threaded_texture

	# An immediate category tap can beat the background request. Loading only the
	# requested texture preserves correct UI while the remaining catalog continues
	# in the worker pool.
	var resource: Resource = ResourceLoader.load(path, "Texture2D")
	_requests.erase(path)
	if resource is Texture2D:
		var texture := resource as Texture2D
		_cache[path] = texture
		return texture
	return null

static func _request(path: String) -> void:
	if path.is_empty() or _cache.has(path) or _requests.has(path):
		return
	if !ResourceLoader.exists(path):
		return
	var error: int = ResourceLoader.load_threaded_request(path, "Texture2D", false)
	if error == OK:
		_requests[path] = true

static func _take_threaded_texture_if_ready(path: String) -> Texture2D:
	if !_requests.has(path):
		return null
	var status: int = ResourceLoader.load_threaded_get_status(path)
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		return null
	_requests.erase(path)
	if status != ResourceLoader.THREAD_LOAD_LOADED:
		return null
	var resource: Resource = ResourceLoader.load_threaded_get(path)
	if resource is Texture2D:
		var texture := resource as Texture2D
		_cache[path] = texture
		return texture
	return null
