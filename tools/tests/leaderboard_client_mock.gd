extends "res://scripts/services/leaderboard.gd"

var transport: Node
var legal := true
var current_stars := 90
var language := "ru"
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

func _language() -> String:
	return language

func _ready() -> void:
	transport.identity_changed.connect(_on_identity_changed)
