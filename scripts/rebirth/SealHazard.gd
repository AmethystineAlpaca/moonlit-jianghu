extends Node3D
const F := preload("res://scripts/rebirth/Form.gd")
var world: Node3D
var timer := 1.25
var ring: MeshInstance3D
var core: MeshInstance3D
func _ready() -> void:
	ring = F.ring(self,Vector3(0,0.19,0),1.7,0.03,F.material(Color("d79663"),0,0.5,0.8))
	core = F.cylinder(self,Vector3(0,0.18,0),1.7,0.008,F.material(Color(0.83,0.45,0.24,0.12)),-1,48)
func _physics_process(delta: float) -> void:
	if not world.encounter:
		queue_free()
		return
	if world.mode != "play" or world.director.cinematic_left > 0: return
	timer -= delta
	core.scale = Vector3.ONE * clampf(1-timer/1.25,0.1,1)
	if timer <= 0:
		world.burst(position+Vector3.UP*0.1,Color("e9bd80"),18,1.7)
		if world.player.position.distance_to(position) < 1.75: world.player.hurt(2,self)
		queue_free()
