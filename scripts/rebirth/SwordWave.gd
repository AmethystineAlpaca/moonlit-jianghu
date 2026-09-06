extends Node3D
const F := preload("res://scripts/rebirth/Form.gd")
var world: Node3D
var direction := Vector3.FORWARD
var lifetime := 0.65
var hit := []
func _ready() -> void:
	rotation.y = atan2(-direction.x,-direction.z)
	var mat := F.material(Color("b5e1d3"),0.1,0.3,2)
	for i in range(15):
		var a := lerpf(-1.2,1.2,float(i)/14)
		F.box(self,Vector3(sin(a)*0.9,0,-cos(a)*0.4),Vector3(0.13,0.055,0.08),mat)
func _physics_process(delta: float) -> void:
	if world.mode != "play": return
	lifetime -= delta
	var next := position+direction*delta*15
	var query := PhysicsRayQueryParameters3D.create(position,next,1)
	if not get_world_3d().direct_space_state.intersect_ray(query).is_empty() or lifetime <= 0:
		queue_free()
		return
	position = next
	for enemy in world.enemies:
		if not is_instance_valid(enemy) or enemy.dead or enemy in hit: continue
		if Vector2(enemy.position.x-position.x,enemy.position.z-position.z).length() < 1.2:
			hit.append(enemy)
			enemy.hurt(3.5+world.player.damage_bonus,world.player)
