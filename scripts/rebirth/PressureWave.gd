extends Node3D
const F := preload("res://scripts/rebirth/Form.gd")
var world: Node3D
var direction := Vector3.FORWARD
var elapsed := 0.0
var mat: StandardMaterial3D
func _ready() -> void:
	rotation.y = atan2(-direction.x,-direction.z)
	mat = F.material(Color(0.79,0.9,0.86,0.5),0,0.6,0.3)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	for lane in range(7):
		var mesh := ImmediateMesh.new()
		mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
		for i in range(15):
			var p := float(i)/14
			var angle := lerpf(-0.8,0.8,p)
			var r := 0.3+float(lane)*0.26
			var v := Vector3(sin(angle)*r,0.16+sin(p*PI)*0.10,-cos(angle)*r)
			mesh.surface_add_vertex(v)
			mesh.surface_add_vertex(v+Vector3(0,0,0.04*sin(p*PI)))
		mesh.surface_end()
		F.instance(self,mesh,Vector3.ZERO,mat)
func _process(delta: float) -> void:
	if world.mode != "play": return
	elapsed += delta
	for bolt in get_tree().get_nodes_in_group("hostile_projectile"):
		if bolt.position.distance_to(position+Vector3.UP*0.6) < 2.0: bolt.reflect()
	position += direction*delta*9
	scale = Vector3.ONE*(1+elapsed*1.8)
	mat.albedo_color.a = maxf(0,0.5-elapsed*1.5)
	if elapsed > 0.34: queue_free()
