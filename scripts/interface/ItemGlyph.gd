extends Control
var item_id := ""
var weapon: Node2D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	weapon = Node2D.new()
	weapon.set_script(preload("res://scripts/player/WeaponRig.gd"))
	weapon.position = Vector2(13, 29)
	weapon.rotation = -0.8
	weapon.sheathed = false
	add_child(weapon)

func _process(_delta: float) -> void:
	position = Vector2(15, get_parent().size.y * 0.5 - 21)
	weapon.weapon_id = item_id
	weapon.visible = item_id in ["iron_sword", "jade_sword", "heavy_saber"]
	queue_redraw()

func _draw() -> void:
	var tint := Color("c8b78b")
	if item_id == "spirit_armor":
		draw_colored_polygon(PackedVector2Array([Vector2(11,8),Vector2(18,12),Vector2(26,8),Vector2(33,15),Vector2(28,20),Vector2(28,35),Vector2(9,35),Vector2(9,20),Vector2(4,15)]), Color("748d90"))
		draw_line(Vector2(18,13),Vector2(18,34),tint,2)
	elif item_id == "jade_talisman":
		draw_circle(Vector2(18,22),12,Color("619d8c"))
		draw_arc(Vector2(18,22),8,0,TAU,20,tint,1.5)
		draw_line(Vector2(18,8),Vector2(18,1),tint,1)
	elif item_id == "healing_pill":
		draw_rect(Rect2(10,10,16,4),tint)
		draw_style_box(preload("res://scripts/interface/JianghuTheme.gd").panel(Color("b4a38b"),tint,0),Rect2(8,15,20,23))
		draw_line(Vector2(18,21),Vector2(18,32),Color("697b65"),2)
		draw_line(Vector2(13,26),Vector2(23,26),Color("697b65"),2)
