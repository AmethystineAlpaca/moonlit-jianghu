extends Control
## Small, scalable ink-and-bronze pictograms. Readiness is shape + text + color.
var kind := "recall"
var accent := Color("a5dacf")
var readiness := 1.0
var enabled := true
var pulse := 0.0
var compact := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(48,48)

func _draw() -> void:
	var center := size*0.5
	var radius := minf(size.x,size.y)*0.40
	var ink := accent if enabled else Color("668580")
	draw_circle(center,radius+3,Color(0.025,0.07,0.075,0.76),true,-1,true)
	draw_arc(center,radius,-PI/2,PI*1.5,48,Color(0.68,0.79,0.73,0.22),1.0,true)
	if readiness > 0:
		draw_arc(center,radius,-PI/2,-PI/2+TAU*clampf(readiness,0,1),48,ink,1.4,true)
	if enabled and pulse > 0:
		draw_arc(center,radius+4,-PI/2,PI*1.5,48,Color(accent,0.18+pulse*0.22),1.0,true)
	var scale_factor := radius/21.0
	draw_set_transform(center,0,Vector2.ONE*scale_factor)
	match kind:
		"recall":
			draw_arc(Vector2.ZERO,11,-1.0,3.8,26,ink,1.6,true)
			draw_polyline(PackedVector2Array([Vector2(-14,-2),Vector2(-8,-7),Vector2(-4,-1)]),ink,1.6,true)
			draw_line(Vector2(-4,5),Vector2(7,-6),ink,2.0,true)
			draw_line(Vector2(4,-7),Vector2(8,-7),ink,1.4,true)
		"burst":
			draw_polyline(PackedVector2Array([Vector2(-11,8),Vector2(0,-11),Vector2(11,8)]),ink,1.8,true)
			draw_line(Vector2(-7,4),Vector2(7,4),ink,1.4,true)
			for side in [-1,1]:
				draw_line(Vector2(side*11,-3),Vector2(side*16,-7),ink,1.6,true)
				draw_line(Vector2(side*13,5),Vector2(side*18,6),ink,1.3,true)
		"wine":
			draw_arc(Vector2(0,-5),4.5,-3.7,0.55,16,ink,1.5,true)
			draw_arc(Vector2(0,6),8.0,-2.1,5.25,26,ink,1.5,true)
			draw_line(Vector2(-4,-11),Vector2(4,-11),ink,2,true)
			draw_line(Vector2(-5,-1),Vector2(5,-1),ink,1.2,true)
			draw_line(Vector2(0,3),Vector2(0,10),ink,1.2,true)
			draw_line(Vector2(-3.5,6.5),Vector2(3.5,6.5),ink,1.2,true)
		"surge", "damage":
			draw_colored_polygon(PackedVector2Array([Vector2(0,-15),Vector2(3,-8),Vector2(2,7),Vector2(-2,7),Vector2(-3,-8)]),ink)
			draw_line(Vector2(-7,7),Vector2(7,7),ink,1.8,true)
			draw_line(Vector2(0,7),Vector2(0,14),ink,2,true)
			if kind == "surge":
				for side in [-1,1]:
					draw_arc(Vector2.ZERO,14,-1.0 if side == 1 else 2.15,1.0 if side == 1 else 4.15,18,ink,1.0,true)
		"resilience":
			draw_polyline(PackedVector2Array([Vector2(0,-13),Vector2(11,-7),Vector2(8,7),Vector2(0,13),Vector2(-8,7),Vector2(-11,-7),Vector2(0,-13)]),ink,1.6,true)
			draw_line(Vector2(0,-6),Vector2(0,7),ink,1.5,true)
			draw_line(Vector2(-5,0),Vector2(5,0),ink,1.5,true)
	draw_set_transform(Vector2.ZERO)
