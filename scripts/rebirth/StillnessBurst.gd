extends Node3D
## A readable expanding sword cut: damage happens when its visible edge arrives.
const F := preload("res://scripts/rebirth/Form.gd")
var world: Node3D
var age := 0.0
var struck: Array[Node3D] = []
var edge: MeshInstance3D
var echo_edge: MeshInstance3D
var veil: MeshInstance3D
var blades: MultiMeshInstance3D
var light: OmniLight3D
var mat: StandardMaterial3D
const RADIUS := 5.8
const CHARGE := 0.22
func _ready() -> void:
	add_to_group("run_effect")
	mat = F.material(Color(0.68,0.94,0.88,0.8),0.2,0.3,2.8)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	edge = F.ring(self,Vector3(0,0.26,0),1,0.028,mat)
	echo_edge = F.ring(self,Vector3(0,0.21,0),1,0.009,mat)
	veil = F.cylinder(self,Vector3(0,0.15,0),1,0.012,F.material(Color(0.42,0.86,0.8,0.065),0,0.5,0.3),-1,64)
	blades = MultiMeshInstance3D.new()
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	var mesh := PrismMesh.new()
	mesh.size = Vector3(0.065,1.5,0.025)
	instances.mesh = mesh
	instances.instance_count = 16
	blades.multimesh = instances
	blades.material_override = mat
	blades.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(blades)
	light = OmniLight3D.new()
	light.light_color = Color("9ee0d3")
	light.omni_range = 7
	light.light_energy = 0
	add_child(light)

func _physics_process(delta: float) -> void:
	if world.mode != "play" or world.director.cinematic_left > 0: return
	age += delta
	var progress := clampf((age-CHARGE)/0.42,0,1)
	var radius := lerpf(0.4,RADIUS,1-pow(1-progress,2))
	edge.scale = Vector3(radius,1,radius)
	echo_edge.scale = Vector3(radius*0.88,1,radius*0.88)
	veil.scale = Vector3(radius,1,radius)
	var alpha := clampf((0.92-age)*2.4,0,0.8)
	mat.albedo_color.a = alpha
	light.light_energy = sin(progress*PI)*2.2
	veil.transparency = clampf(age/0.8,0,1)
	for i in range(16):
		var a := i*TAU/16+minf(age,CHARGE)*2
		var p := Vector3(cos(a)*radius,0.4+sin(progress*PI)*0.8,sin(a)*radius)
		var basis := Basis.from_euler(Vector3(0,-a,lerpf(0,PI*0.42,progress)))
		basis = basis.scaled(Vector3.ONE*(alpha*0.75))
		blades.multimesh.set_instance_transform(i,Transform3D(basis,p))
	if age >= CHARGE and progress < 1:
		for enemy in world.enemies:
			if not is_instance_valid(enemy) or enemy.dead or enemy in struck: continue
			if enemy.position.distance_to(position) > radius+0.35: continue
			struck.append(enemy)
			var query := PhysicsRayQueryParameters3D.create(position+Vector3.UP,enemy.position+Vector3.UP,1)
			if not get_world_3d().direct_space_state.intersect_ray(query).is_empty(): continue
			enemy.immunity = 0
			enemy.hurt(5.5+world.player.damage_bonus,world.player)
			if not enemy.dead:
				enemy.apply_posture(55)
				if not enemy.boss and enemy.action != "broken":
					enemy.action = "stunned"
					enemy.timer = 0.5
			world.flash(enemy.position+Vector3.UP,Color("c1f4e2"))
		for bolt in get_tree().get_nodes_in_group("hostile_projectile"):
			if bolt.position.distance_to(position) < radius: bolt.reflect()
	if age >= 1: queue_free()
