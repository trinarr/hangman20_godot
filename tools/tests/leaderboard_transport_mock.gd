extends "res://tools/tests/quiz_statistics_mock.gd"

var dev := true

func _uses_dev() -> bool:
	return dev

func leaderboard_is_configured() -> bool:
	return true
