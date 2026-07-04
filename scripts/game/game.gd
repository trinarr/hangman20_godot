extends Node2D

@onready var flow := $GameFlow

@onready var controller := $GameController
@onready var word_label := $WordLabel


func _ready():

	flow.start_game(0) # временно тема 0


func _input(event):

	if event is InputEventKey and event.pressed:

		var letter := OS.get_keycode_string(event.keycode)

		if letter.length() == 1:

			controller.on_letter_input(letter)


func _process(delta):

	word_label.text = WordManager.get_masked_word()


func _on_win():

	print("WIN")


func _on_lose():

	print("LOSE")
