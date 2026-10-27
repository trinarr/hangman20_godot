@tool
extends EditorExportPlugin
## Only in-memory export settings change; project.godot is never saved here.

var _release := false
var _settings: Dictionary = {}

func _get_name() -> String:
	return "HangmanReleaseGuard"

func _export_begin(_features: PackedStringArray, is_debug: bool, _path: String, _flags: int) -> void:
	_release = !is_debug
	var strip_console: bool = _release or get_export_preset().get_exclude_filter().contains("addons/dev-console/*")
	if !strip_console:
		return
	for property: Dictionary in ProjectSettings.get_property_list():
		var key: String = property.name
		if key in ["autoload/DebugLogBridge", "autoload/DevConsole"] or (_release and (
			key == "editor_plugins/enabled" \
			or key.begins_with("dev_console/") \
			or key.begins_with("leaderboard/dev_") \
			or key.begins_with("quiz_statistics/dev_") \
			or key in ["yandex_ads/banner_id", "yandex_ads/interstitial_id", "yandex_ads/rewarded_id"])):
			_settings[key] = {"value": ProjectSettings.get_setting(key), "order": ProjectSettings.get_order(key)}
			ProjectSettings.clear(key)

func _export_file(path: String, _type: String, _features: PackedStringArray) -> void:
	if !_release:
		return
	if path == "res://data/game_design_config.json":
		var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		config.tournament.erase("debug_duration_seconds")
		config.tournament.erase("debug_opponent_stars")
		add_file(path, JSON.stringify(config, "  ", true, true).to_utf8_buffer(), false)
		skip()

func _export_end() -> void:
	for key: String in _settings:
		ProjectSettings.set_setting(key, _settings[key].value)
		ProjectSettings.set_order(key, _settings[key].order)
	_settings.clear()
	_release = false
