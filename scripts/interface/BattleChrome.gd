extends Control
const STYLE := preload("res://scripts/interface/JianghuTheme.gd")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _draw() -> void:
	var panels := [Rect2(24, 24, 342, 112), Rect2(1060, 24, 196, 180), Rect2(326, 586, 628, 122)]
	for rect in panels:
		draw_style_box(STYLE.panel(Color(0.025, 0.06, 0.08, 0.92), STYLE.GOLD, 0), rect)
		for corner in [rect.position, rect.position + Vector2(rect.size.x, 0), rect.end, rect.position + Vector2(0, rect.size.y)]:
			var dx := 1.0 if corner.x == rect.position.x else -1.0
			var dy := 1.0 if corner.y == rect.position.y else -1.0
			draw_line(corner, corner + Vector2(10 * dx, 0), STYLE.GOLD, 2)
			draw_line(corner, corner + Vector2(0, 10 * dy), STYLE.GOLD, 2)
	draw_line(Vector2(104, 43), Vector2(104, 116), Color(STYLE.GOLD, 0.3), 1)
	draw_line(Vector2(498, 58), Vector2(782, 58), Color(STYLE.GOLD, 0.4), 1)
