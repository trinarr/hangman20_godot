extends "res://scripts/services/leaderboard.gd"

var transport: Node
var legal := true
var current_stars := 90
var language := "ru"
var profile := {"nickname":"TestPlayer", "character_id":1, "frame_id":4}
var tutorial_completed := true
var use_game_profile := false
var received_ids: Array[String] = []
var save_file := "user://leaderboard_mock_%d.json" % get_instance_id()

func _save_path() -> String:
	return save_file

func environment_save_path() -> String:
	return super._save_path()

func _backend() -> Node:
	return transport

func _legal_accepted() -> bool:
	return legal

func _current_stars() -> int:
	return current_stars

func _current_profile() -> Dictionary:
	return GameState.get_player_profile() if use_game_profile else profile.duplicate(true)

func _tutorial_completed() -> bool:
	return tutorial_completed

func _apply_server_player_id(identifier: String) -> bool:
	received_ids.append(identifier)
	return GameState.apply_server_player_id(identifier) if use_game_profile else false

func _language() -> String:
	return language

func _ready() -> void:
	transport.identity_changed.connect(_on_identity_changed)
