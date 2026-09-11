extends Node3D
const F := preload("res://scripts/rebirth/Form.gd")
var color := Color("f4d49b")
var direction := Vector3.FORWARD
var power := 1.0
var elapsed := 0.0
var rays: MeshInstance3D
var mat: StandardMaterial3D
var core: MeshInstance3D
var core_material: StandardMaterial3D
var streaks: MeshInstance3D
var streak_material: StandardMaterial3D
func _ready() -> void:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in range(8):
		var angle := i*TAU/8+rng.randf_range(-0.12,0.12)
		var radial := Vector3(cos(angle),sin(angle),0)
		var side := Vector3(-sin(angle),cos(angle),0)
		var length := rng.randf_range(0.28,0.74)*power
		for vertex in [radial*0.055+side*0.020,radial*length,radial*0.055-side*0.020]: mesh.surface_add_vertex(vertex)
	mesh.surface_end()
	mat = F.material(color,0,0.3,1.2)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rays = F.instance(self,mesh,Vector3.ZERO,mat)
	rays.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	core_material = F.material(color.lerp(Color.WHITE,0.65),0,0.2,2.5)
	core_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	core_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	core = F.box(self,Vector3.ZERO,Vector3(0.14,0.14,0.012)*power,core_material)
	core.rotation.z = PI/4
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	streak_material = F.material(color,0,0.3,1.4)
	streak_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	streak_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	streaks = F.box(self,Vector3(0,0,0.015),Vector3(1.0,0.014,0.008)*power,streak_material)
	streaks.rotation.z = rng.randf_range(-0.65,0.65)
	streaks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var cam := get_viewport().get_camera_3d()
	if cam: look_at(cam.global_position,Vector3.UP)
func _process(delta: float) -> void:
	if get_parent().get("mode") in ["pause","upgrade","closing"]: return
	elapsed += delta
	scale = Vector3.ONE * lerpf(0.55,1.18,minf(1,elapsed/0.14))
	mat.albedo_color.a = pow(maxf(0,1-elapsed/0.20),1.7)
	core_material.albedo_color.a = maxf(0,1-elapsed/0.08)
	streak_material.albedo_color.a = maxf(0,1-elapsed/0.12)*0.7
	if elapsed > 0.20: queue_free()
