extends Node3D
const F := preload("res://scripts/rebirth/Form.gd")
var world: Node3D
var source: Node3D
var direction := Vector3.FORWARD
var lifetime := 3.0
var reflected := false
func _ready() -> void:
	add_to_group("hostile_projectile")
	rotation.y = atan2(-direction.x,-direction.z)
	F.box(self,Vector3.ZERO,Vector3(0.045,0.045,0.55),F.material(Color("efac79"),0.1,0.4,2))
	F.sphere(self,Vector3(0,0,-0.2),0.06,F.material(Color("ffd7a7"),0,0.4,2))
func _physics_process(delta: float) -> void:
	if world.mode != "play" or world.director.cinematic_left > 0: return
	lifetime -= delta
	var next := position+direction*delta*(14.0 if reflected else 7.5)
	var query := PhysicsRayQueryParameters3D.create(position,next,1)
	if not get_world_3d().direct_space_state.intersect_ray(query).is_empty() or lifetime <= 0:
		queue_free()
		return
	position = next
	if reflected:
		for enemy in world.enemies:
			if is_instance_valid(enemy) and not enemy.dead and Vector2(enemy.position.x-position.x,enemy.position.z-position.z).length() < 0.65:
				enemy.hurt(4,world.player)
				enemy.apply_posture(45)
				world.flash(position,Color("c5ecdf"))
				queue_free()
				return
		return
	if Vector2(world.player.position.x-position.x,world.player.position.z-position.z).length() < 0.65:
		if world.player.guarding and world.player.guard_time < 0.22 and world.player.facing.dot(-direction)>0.2:
			reflect()
			world.combat_event("parry",world.player,source)
			return
		if is_instance_valid(source): world.player.hurt(1.5,source)
		queue_free()

func reflect() -> void:
	if reflected: return
	reflected = true
	remove_from_group("hostile_projectile")
	direction = -direction
	if is_instance_valid(source):
		direction = source.position+Vector3.UP*0.8-position
		direction.y = 0
		direction = direction.normalized()
	rotation.y = atan2(-direction.x,-direction.z)
	lifetime = 2.0
	world.combat_sound("parry")
	world.flash(position,Color("c5ecdf"))
	world.player.stamina = minf(100,world.player.stamina+8)
