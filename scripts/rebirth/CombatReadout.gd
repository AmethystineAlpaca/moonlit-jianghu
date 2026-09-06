extends Control
var world: Node3D
const FONT := preload("res://assets/fonts/NotoSansSC.ttf")
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
func _process(_delta: float) -> void:
	visible = world.mode == "play"
	queue_redraw()
func _draw() -> void:
	if not is_instance_valid(world.player): return
	for enemy in world.enemies:
		if not is_instance_valid(enemy) or enemy.dead or enemy.position.distance_to(world.player.position)>12: continue
		if enemy.hp >= enemy.max_hp and enemy.posture == 0 and enemy.action != "broken": continue
		var point: Vector2 = world.camera.unproject_position(enemy.position+Vector3.UP*(3.0 if enemy.boss else 2.3))
		var width := 48.0
		draw_rect(Rect2(point+Vector2(-width/2,-2),Vector2(width,8)),Color(0.02,0.06,0.07,0.8))
		draw_rect(Rect2(point+Vector2(-width/2,0),Vector2(width*enemy.hp/enemy.max_hp,2)),Color("d6c5a9"))
		draw_rect(Rect2(point+Vector2(-width/2,4),Vector2(width*(1.0 if enemy.action == "broken" else enemy.posture/100),2)),Color("efb362"))
		if enemy.action == "broken":
			draw_string(FONT,point+Vector2(-27,-9),"破势 · F",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("ffe0a8"))
