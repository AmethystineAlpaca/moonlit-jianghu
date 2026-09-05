extends Control
@export var kind: int = 0
var tint := Color("d5c08e")

func _ready() -> void:
	custom_minimum_size = Vector2(44, 42)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var c := size * 0.5
	var ink := Color(tint, 0.18)
	draw_circle(c, 18, ink)
	match kind:
		0:
			draw_arc(c, 14, -2.7, 1.6, 24, tint, 1.5, true)
			draw_arc(c, 9, 0.4, 4.8, 24, tint, 1.5, true)
			draw_line(c + Vector2(-3, -16), c + Vector2(6, -12), tint, 2, true)
			draw_circle(c, 3, tint)
		1:
			var points := PackedVector2Array([c + Vector2(0, -16), c + Vector2(12, -10), c + Vector2(10, 5), c + Vector2(0, 16), c + Vector2(-10, 5), c + Vector2(-12, -10), c + Vector2(0, -16)])
			draw_polyline(points, tint, 1.5, true)
			draw_line(c + Vector2(0, -9), c + Vector2(0, 9), tint, 1.5, true)
		2:
			draw_arc(c - Vector2(5, 0), 17, -1.3, 1.3, 24, tint, 2.5, true)
			draw_line(c + Vector2(-10, 12), c + Vector2(11, -12), tint, 1.5, true)
			draw_line(c + Vector2(-10, 5), c + Vector2(-3, 12), tint, 2, true)
		3:
			for i in range(3):
				var a := i * TAU / 3.0
				draw_arc(c + Vector2.from_angle(a) * 5, 11, a, a + PI, 20, tint, 1.7, true)
		4:
			draw_line(c + Vector2(0, 14), c + Vector2(0, -10), tint, 2, true)
			draw_arc(c + Vector2(-6, -4), 7, -PI, PI * 0.3, 16, tint, 1.5, true)
			draw_arc(c + Vector2(6, 2), 7, -PI * 0.1, PI, 16, tint, 1.5, true)
			draw_circle(c + Vector2(0, -13), 2, tint)
