@tool
extends EditorPlugin

var _export: EditorExportPlugin

func _enter_tree() -> void:
	_export = FirebaseExport.new()
	add_export_plugin(_export)

func _exit_tree() -> void:
	remove_export_plugin(_export)

class FirebaseExport extends EditorExportPlugin:
	func _get_name() -> String:
		return "HangmanFirebase"
	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid
	func _get_android_libraries(_platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		var variant: String = "debug" if debug else "release"
		return PackedStringArray(["HangmanFirebase/bin/%s/HangmanFirebase-%s.aar" % [variant, variant]])
	func _get_android_dependencies(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray(["com.google.firebase:firebase-analytics:24.0.0"])
