extends Node2D

@onready var flow := get_node_or_null("GameFlow")
@onready var controller := get_node_or_null("GameController")
@onready var word_label := get_node_or_null("UI/WordLabel")

func _ready() -> void:
	if flow != null and flow.has_method("start_game"):
		flow.start_game(0)

func _input(event: InputEvent) -> void:
	if controller == null:
		return
	if event is InputEventKey and event.pressed and !event.echo:
		var letter := OS.get_keycode_string(event.keycode).to_upper()
		if letter.length() == 1:
			controller.on_letter_input(letter)

func _process(_delta: float) -> void:
	if word_label != null:
		word_label.set("text", WordManager.get_masked_word())

func start_game(theme_index: int = 0) -> void:
	if flow != null and flow.has_method("start_game"):
		flow.start_game(theme_index)

func _on_win() -> void:
	print("WIN")

func _on_lose() -> void:
	print("LOSE")
