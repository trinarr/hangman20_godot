@tool
extends EditorPlugin

var export_plugin : AndroidExportPlugin

func _enter_tree():
	export_plugin = AndroidExportPlugin.new()
	add_export_plugin(export_plugin)


func _exit_tree():
	remove_export_plugin(export_plugin)
	export_plugin = null


class AndroidExportPlugin extends EditorExportPlugin:
	const STORE_CONFIG = preload("store_config.gd")
	var _plugin_name = "GodotAndroidYandexAds"

	func _supports_platform(platform):
		if platform is EditorExportPlatformAndroid:
			return true
		return false

	func _get_android_libraries(platform, debug):
		if debug:
			return PackedStringArray([_plugin_name + "/bin/debug/" + _plugin_name + "-debug.aar"])
		else:
			return PackedStringArray([_plugin_name + "/bin/release/" + _plugin_name + "-release.aar"])


	func _get_android_dependencies(platform, debug):
		return PackedStringArray(["com.yandex.android:mobileads-mediation:8.6.0.0"])


	func _get_android_dependencies_maven_repos(platform, debug):
		return PackedStringArray([
			"https://android-sdk.is.com/",
			"https://artifact.bytedance.com/repository/pangle",
			"https://sdk.tapjoy.com/",
			"https://artifactory.bidmachine.io/bidmachine",
			"https://dl-maven-android.mintegral.com/repository/mbridge_android_sdk_oversea",
			"https://cboost.jfrog.io/artifactory/chartboost-ads/",
			"https://dl.appnext.com/",
		])


	func _get_android_manifest_application_element_contents(platform, debug):
		# Keep the SDK provider behind the durable legal/privacy gate in the app.
		var manifest: String = '<meta-data android:name="com.yandex.mobile.ads.AUTOMATIC_SDK_INITIALIZATION" android:value="false" />'
		# Keep partner SDK startup behind the same gate. Yandex's provider also
		# loads Pangle through its debug integration checker even with auto-init off.
		# The public initialize(Context, listener) API prepares Yandex on demand.
		for provider: String in [
			"com.applovin.sdk.AppLovinInitProvider",
			"com.startapp.sdk.adsbase.StartAppInitProvider",
			"com.yandex.mobile.ads.core.initializer.YandexAdsInitializeProvider",
		]:
			manifest += '<provider xmlns:tools="http://schemas.android.com/tools" android:name="%s" tools:node="remove" />' % provider
		# MyTargetContentProvider reads an Integer; boolean false is not sufficient.
		manifest += '<meta-data android:name="com.my.target.autoInitMode" android:value="0" />'
		var preset: EditorExportPreset = get_export_preset()
		if preset != null:
			var store: String = STORE_CONFIG.store_from_features(preset.get_custom_features().split(","))
			manifest += google_application_metadata(STORE_CONFIG.profile(store))
		return manifest

	func google_application_metadata(profile: Dictionary) -> String:
		if !bool(profile.get("google_ads_enabled", false)):
			return ""
		var app_id: String = str(profile.get("google_application_id", "")).strip_edges()
		if app_id.is_empty():
			return ""
		return '<meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" android:value="%s" />' % app_id.xml_escape(true)


	func _get_name():
		return _plugin_name
