extends RefCounted
## Fixed inputs for mechanics tests, deliberately independent of shipping balance.
const CONFIG = preload("res://scripts/core/game_design_config.gd")

static func apply(state: Node) -> void:
	CONFIG.get_value("difficulty", {}) # Load other production settings first.
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://tools/tests/mechanics_balance.json"))
	for section: String in fixture:
		CONFIG._config[section] = fixture[section].duplicate(true)
	# Autoload fields were initialized before the test's entry point.
	state.SINGLE_PLAYER_DIFFICULTY_DEFAULT = float(fixture.difficulty.default)
	state.SINGLE_PLAYER_DIFFICULTY_MIN = float(fixture.difficulty.minimum)
	state.SINGLE_PLAYER_DIFFICULTY_MAX = float(fixture.difficulty.maximum)
