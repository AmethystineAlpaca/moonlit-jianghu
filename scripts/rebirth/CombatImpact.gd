extends Node3D
const F := preload("res://scripts/rebirth/Form.gd")
var color := Color("f4d49b")
var direction := Vector3.FORWARD
var power := 1.0
var elapsed := 0.0
var rays: MeshInstance3D
var mat: StandardMaterial3D
func _ready() -> void:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in range(11):
		var angle := i*TAU/11+rng.randf_range(-0.12,0.12)
		var radial := Vector3(cos(angle),sin(angle),0)
		var side := Vector3(-sin(angle),cos(angle),0)
		var length := rng.randf_range(0.25,0.8)*power
		for vertex in [radial*0.055+side*0.018,radial*length,radial*0.055-side*0.018]: mesh.surface_add_vertex(vertex)
	mesh.surface_end()
	mat = F.material(color,0,0.3,1.2)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	rays = F.instance(self,mesh,Vector3.ZERO,mat)
	var cam := get_viewport().get_camera_3d()
	if cam: look_at(cam.global_position,Vector3.UP)
func _process(delta: float) -> void:
	elapsed += delta
	scale = Vector3.ONE * lerpf(0.6,1.2,minf(1,elapsed/0.12))
	mat.albedo_color.a = maxf(0,1-elapsed/0.16)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if elapsed > 0.16: queue_free()
