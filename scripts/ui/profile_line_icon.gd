extends Control
## Small white vector symbols for profile statistics.
var kind := ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0, size / 32.0)
	match kind:
		"stars_earned":
			var points := PackedVector2Array()
			for i in range(10):
				points.append(Vector2(16, 16) + Vector2.from_angle(-PI / 2 + i * PI / 5) * (14 if i % 2 == 0 else 6.5))
			draw_colored_polygon(points, Color.WHITE)
		"levels_completed":
			for i in range(3):
				draw_rect(Rect2(3 + i * 9, 22 - i * 8, 8, 7 + i * 8), Color.WHITE)
		"hard_levels_completed":
			draw_colored_polygon(PackedVector2Array([Vector2(18, 2), Vector2(6, 18), Vector2(14, 18), Vector2(12, 30), Vector2(27, 12), Vector2(18, 12)]), Color.WHITE)
		"quizzes_solved":
			draw_arc(Vector2(16, 11), 8, PI, TAU + PI / 2, 24, Color.WHITE, 3, true)
			draw_line(Vector2(16, 19), Vector2(16, 22), Color.WHITE, 3, true)
			draw_circle(Vector2(16, 28), 2, Color.WHITE)
		"words_solved":
			draw_polyline(PackedVector2Array([Vector2(16, 28), Vector2(3, 25), Vector2(3, 5), Vector2(16, 8), Vector2(29, 5), Vector2(29, 25), Vector2(16, 28), Vector2(16, 8)]), Color.WHITE, 2.5, true)
