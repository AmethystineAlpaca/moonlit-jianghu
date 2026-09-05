extends Node2D
var weapon_id := "iron_sword"
var sheathed := true

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var jade := weapon_id == "jade_sword"
	var heavy := weapon_id == "heavy_saber"
	var metal := Color("c7d6d5")
	var edge := Color("f2f0d9")
	var trim := Color("b49a60")
	if jade:
		metal = Color("73b8b1")
		edge = Color("d7f5e6")
	if sheathed:
		draw_colored_polygon(PackedVector2Array([Vector2(0,-2),Vector2(22,-2),Vector2(25,0),Vector2(22,2),Vector2(0,2)]), Color("24343c") if not jade else Color("28554f"))
		draw_line(Vector2(2,-2),Vector2(21,-2), trim, 1)
	elif heavy:
		draw_colored_polygon(PackedVector2Array([Vector2(0,-2),Vector2(21,-3),Vector2(28,0),Vector2(23,5),Vector2(0,3)]), metal.darkened(0.2))
		draw_line(Vector2(0,3),Vector2(23,5), edge, 1)
		draw_line(Vector2(23,5),Vector2(28,0), edge, 1)
	else:
		draw_colored_polygon(PackedVector2Array([Vector2(0,-1),Vector2(23,-1),Vector2(29,0),Vector2(23,2),Vector2(0,2)]), metal)
		draw_line(Vector2(2,-1),Vector2(24,-1), edge, 1)
	draw_rect(Rect2(-2,-4,2,8), trim)
	draw_rect(Rect2(-9,-1,7,3), Color("574c45"))
	for x in [-8,-5]: draw_line(Vector2(x,-1),Vector2(x+1,2), trim.darkened(0.15), 1)
	draw_rect(Rect2(-11,-2,2,4), trim)
	if jade:
		draw_line(Vector2(-11,0),Vector2(-15,5), Color("609b91"), 1)
		draw_rect(Rect2(-16,4,2,4), Color("86bfb0"))
