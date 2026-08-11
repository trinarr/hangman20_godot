class_name SoftCurrencyCoinPileIcon
extends Control

const COIN_PILE_TEXTURE: Texture2D = preload("res://flash_assets/soft_currency_coin_pile.png")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _draw() -> void:
	if COIN_PILE_TEXTURE == null:
		return
	draw_texture_rect(COIN_PILE_TEXTURE, Rect2(Vector2.ZERO, size), false)
