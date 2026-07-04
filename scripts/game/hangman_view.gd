extends Node2D

@onready var sprite := $Sprite2D


func set_state(mistakes: int):

	sprite.frame = mistakes
