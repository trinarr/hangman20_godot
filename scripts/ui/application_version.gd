extends RefCounted
## Shared installed version/build label for Settings and the startup screen.
const APP_VERSION_FALLBACK: String = "3.0.0"

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

