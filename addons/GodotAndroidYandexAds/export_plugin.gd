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


	func _get_name():
		return _plugin_name
