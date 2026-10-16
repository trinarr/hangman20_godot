extends "res://scripts/services/leaderboard.gd"

var transport: Node
var legal := true
var current_stars := 90
var language := "ru"

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
