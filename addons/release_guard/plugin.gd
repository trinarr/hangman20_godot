@tool
extends EditorPlugin

const EXPORT_PLUGIN = preload("res://addons/release_guard/release_export.gd")
var _exporter: EditorExportPlugin

func _enter_tree() -> void:
	_exporter = EXPORT_PLUGIN.new()
	add_export_plugin(_exporter)

func _exit_tree() -> void:
	remove_export_plugin(_exporter)
	_exporter = null
