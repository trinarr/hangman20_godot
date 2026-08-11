class_name SoftCurrencyCoinPileIcon
extends Control

const COIN_TEXTURE: Texture2D = preload("res://flash_assets/soft_currency_coin.png")
const COIN_CONFIGS := [
	{"scale": 0.58, "offset": Vector2(0.08, 0.18), "alpha": 0.88},
	{"scale": 0.58, "offset": Vector2(0.34, 0.18), "alpha": 0.88},
	{"scale": 0.72, "offset": Vector2(0.21, 0.02), "alpha": 1.0},
]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _draw() -> void:
	if COIN_TEXTURE == null:
		return
	for config_variant in COIN_CONFIGS:
		var coin_scale: float = float(config_variant["scale"])
		var offset_ratio: Vector2 = config_variant["offset"] as Vector2
		var coin_rect := Rect2(
			offset_ratio * size,
			size * coin_scale
		)
		var coin_color := Color(1.0, 1.0, 1.0, float(config_variant["alpha"]))
		draw_texture_rect(COIN_TEXTURE, coin_rect, false, coin_color)
