extends Node
## Reuse the answer press, error shake and 50/50 removal in that order.
signal finished
var _button: Button
var _shake: Callable
var _remove: Callable

func play(button: Button, after_press: Callable, shake: Callable, remove: Callable) -> void:
	_button = button
	_shake = shake
	_remove = remove
	after_press.call(button, _shake_then_remove)

func _shake_then_remove() -> void:
	if is_inside_tree():
		_shake.call(_button, _remove_wrong_answer)

func _remove_wrong_answer() -> void:
	if is_inside_tree():
		_remove.call(_button, _finish)

func _finish() -> void:
	if is_inside_tree():
		finished.emit()
		queue_free()
