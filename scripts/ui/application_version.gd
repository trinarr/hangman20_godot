extends RefCounted
## Shared installed version/build label for Settings and the startup screen.
const APP_VERSION_FALLBACK: String = "3.0.0"
const FONT_SIZE: int = 14
const FONT_COLOR: Color = preload("res://scripts/ui/ui_palette.gd").TEXT_PALE_BLUE

static func style_label(label: Label) -> void:
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.begin_bulk_theme_override()
	label.add_theme_font_override("font", preload("res://scripts/ui/ui_fonts.gd").regular_font())
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", FONT_COLOR)
	label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	label.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
	label.add_theme_constant_override("outline_size", 0)
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 0)
	label.end_bulk_theme_override()

static func text(prefix: String = "") -> String:
	var build: String = build_number()
	var value: String = version()
	if !build.is_empty():
		value += " (%s)" % build
	return (Database.tr_text(19, "Version:") if prefix.is_empty() else prefix) + " " + value

static func build_number() -> String:
	if Engine.has_singleton("AndroidRuntime"):
		var runtime: Object = Engine.get_singleton("AndroidRuntime")
		var context: Object = runtime.getApplicationContext()
		if context != null:
			var package_info: Object = context.getPackageManager().getPackageInfo(context.getPackageName(), 0)
			if JavaClassWrapper.get_exception() == null and package_info != null:
				return android_package_build_number(package_info)
		return ""
	# Export presets are available in the editor; Android reads its installed APK.
	var presets := ConfigFile.new()
	if presets.load("res://export_presets.cfg") == OK:
		return str(presets.get_value("preset.0.options", "version/code", ""))
	return ""

static func android_package_build_number(package_info: Object) -> String:
	# JavaObject exposes methods, but not Java instance fields via Object.get().
	# Reflection also supports Android API 24-27, before getLongVersionCode().
	var package_class: Object = package_info.getClass()
	if JavaClassWrapper.get_exception() != null or package_class == null:
		return ""
	var version_field: Object = package_class.getField("versionCode")
	if JavaClassWrapper.get_exception() != null or version_field == null:
		return ""
	var build_number: Variant = version_field.getInt(package_info)
	if JavaClassWrapper.get_exception() != null or !(build_number is int):
		return ""
	return str(build_number) if build_number > 0 else ""

static func version() -> String:
	var configured_version: String = str(
		ProjectSettings.get_setting("application/config/version", APP_VERSION_FALLBACK)
	).strip_edges()
	return configured_version if configured_version != "" else APP_VERSION_FALLBACK

