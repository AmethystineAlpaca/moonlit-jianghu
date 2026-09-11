extends Control
## World-attached health and poise: bronze means pressure, open brackets mean a finish.
const FONT := preload("res://assets/fonts/StillwaterSans.tres")
const INK := Color("071a20")
const BONE := Color("e6d8b9")
const GOLD := Color("f3c584")
var world: Node3D
var damage_trails: Dictionary = {}
var clock := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	visible = world.mode == "play"
	if not visible: return
	clock += delta
	var current: Dictionary = {}
	for enemy in world.enemies:
		if not is_instance_valid(enemy) or enemy.dead: continue
		var id: int = enemy.get_instance_id()
		var previous: float = damage_trails.get(id,enemy.hp)
		current[id] = move_toward(previous,enemy.hp,delta*maxf(3,enemy.max_hp*0.5))
	damage_trails = current
	queue_redraw()

func text_shadow(at: Vector2, text: String, font_size: int, color: Color) -> void:
	draw_string_outline(FONT,at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,4,Color(INK,0.95))
	draw_string(FONT,at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func _draw() -> void:
	if not is_instance_valid(world.player): return
	for enemy in world.enemies:
		if not is_instance_valid(enemy) or enemy.dead or enemy.position.distance_to(world.player.position)>14: continue
		if world.camera.is_position_behind(enemy.position): continue
		var broken: bool = enemy.action == "broken"
		var threat: bool = enemy.action in ["windup","charge"]
		if enemy.hp >= enemy.max_hp and enemy.posture <= 0 and not broken and not threat: continue
		var point: Vector2 = world.camera.unproject_position(enemy.position+Vector3.UP*(3.2 if enemy.boss else 2.35))
		if point.x < 20 or point.x > 1260 or point.y < 125 or point.y > 572: continue
		var width := 74.0 if enemy.boss else 58.0
		var origin := point+Vector2(-width/2,0)
		draw_rect(Rect2(origin+Vector2(-3,-3),Vector2(width+6,14)),Color(INK,0.9))
		var trail: float = damage_trails.get(enemy.get_instance_id(),enemy.hp)
		draw_rect(Rect2(origin,Vector2(width*clampf(trail/enemy.max_hp,0,1),3)),Color("b17454"))
		draw_rect(Rect2(origin,Vector2(width*clampf(enemy.hp/enemy.max_hp,0,1),3)),BONE)
		var poise: float = 1.0 if broken else clampf(enemy.posture/100,0,1)
		draw_rect(Rect2(origin+Vector2(0,7),Vector2(width,2)),Color(0.65,0.53,0.36,0.19))
		draw_rect(Rect2(origin+Vector2(0,7),Vector2(width*poise,2)),GOLD)
		if broken:
			var pulse := 0.7+sin(clock*7)*0.3
			var bracket := Color(GOLD,pulse)
			for side in [-1,1]:
				var x: float = side*(width*0.5+7)
				draw_polyline(PackedVector2Array([point+Vector2(x-side*4,-4),point+Vector2(x,-4),point+Vector2(x,12),point+Vector2(x-side*4,12)]),bracket,1.5,true)
			text_shadow(point+Vector2(-29,-11),("破势 · ↑" if world.ui.last_input_pad else "破势 · F"),13,GOLD)
		elif threat:
			var remaining: float = clampf(1-enemy.timer/maxf(0.01,enemy.duration),0,1)
			var warning := Color("e7b174") if enemy.kind != 2 else Color("aed8e8")
			draw_line(point+Vector2(-width*0.5,-7),point+Vector2(-width*0.5+width*remaining,-7),warning,1.5,true)
