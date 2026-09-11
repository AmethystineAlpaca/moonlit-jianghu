extends Node3D
## Small, deterministic atmosphere batches. Gameplay remains in Stillwater;
## this observer only translates its seal and boss states into scenery.

const F := preload("res://scripts/rebirth/Form.gd")
const BLOOM := preload("res://scripts/rebirth/SealBloom.gd")
const INSCRIPTION := preload("res://scripts/rebirth/shaders/SealInscription.gdshader")
const MAPLE_BEDS := [Vector3(-13,0,8), Vector3(13,0,7), Vector3(-15,0,-13), Vector3(14,0,-14), Vector3(-8,0,-18)]

var world: Node3D
var seal_visuals: Array[Dictionary] = []
var court_material: ShaderMaterial
var court_visible := false
var age := 0.0
var leaf_batch: MultiMeshInstance3D
var ripple_batch: MultiMeshInstance3D
var state_check := 0.0

func _ready() -> void:
	name = "CourtyardAtmosphere"
	var random := RandomNumberGenerator.new()
	random.seed = 10317
	build_rain_ripples(random)
	build_falling_leaves(random)
	build_distant_landscape(random)
	build_lake_mist()
	build_seal_armatures()
	court_material = inscription_material(-1.0)
	court_material.set_shader_parameter("strength", 0.0)
	var plane := PlaneMesh.new()
	plane.size = Vector2(9.8, 9.8)
	var inscription := F.instance(self, plane, Vector3(0, 0.139, 0), court_material)
	inscription.name = "BossCourtInscription"
	inscription.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _process(delta: float) -> void:
	if not is_instance_valid(world): return
	age += delta
	state_check -= delta
	if state_check <= 0.0:
		state_check = 0.1
		update_ritual_states()
	for i in range(seal_visuals.size()):
		var visual: Dictionary = seal_visuals[i]
		var armature: Node3D = visual.armature
		var engaged: bool = visual.state == 1
		armature.rotation.y += delta * (0.42 if engaged else 0.12) * (-1.0 if i == 1 else 1.0)
		armature.position.y = 1.45 + sin(age * 1.3 + i * 2.0) * 0.045
		var halo: Node3D = visual.halo
		halo.rotation.z = sin(age * 0.4 + i) * 0.2

func inscription_material(identity: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = INSCRIPTION
	material.set_shader_parameter("identity", identity)
	return material

func build_seal_armatures() -> void:
	var crystal := F.crystal_mesh()
	for i in range(world.seals.size()):
		var seal: Node3D = world.seals[i]
		var armature := Node3D.new()
		armature.name = "JadeArmature"
		armature.position.y = 1.45
		seal.add_child(armature)
		var halo := Node3D.new()
		armature.add_child(halo)
		var light_material := F.material(Color("79b9ad"), 0.42, 0.34, 0.38)
		var outer := F.ring(halo, Vector3.ZERO, 0.58, 0.013, light_material)
		outer.rotation_degrees = Vector3(68, i * 38, 16)
		outer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var inner := F.ring(halo, Vector3.ZERO, 0.43, 0.01, world.gold)
		inner.rotation_degrees = Vector3(25, 32, 55)
		inner.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for n in range(3):
			var angle := n * TAU / 3.0 + i * 0.6
			var fragment := F.instance(armature, crystal, Vector3(sin(angle) * 0.63, 0.02, cos(angle) * 0.63), light_material)
			fragment.scale = Vector3(0.43, 0.38, 0.43)
			fragment.rotation.z = sin(angle) * 0.55
			fragment.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var material := inscription_material(float(i))
		var plane := PlaneMesh.new()
		plane.size = Vector2(5.6, 5.6)
		var glyph := F.instance(seal, plane, Vector3(0, 0.158, 0), material)
		glyph.name = "SealInscription"
		glyph.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		seal_visuals.append({"armature": armature, "halo": halo, "material": material, "light_material": light_material, "state": 0})

func update_ritual_states() -> void:
	for i in range(seal_visuals.size()):
		var state := 2 if world.seal_done[i] else (1 if world.encounter and world.current_seal == i else 0)
		var visual: Dictionary = seal_visuals[i]
		if int(visual.state) == state: continue
		visual.state = state
		var complete := state == 2
		var color := Color("e8c78a") if complete else Color("8bd5c7")
		var material: ShaderMaterial = visual.material
		material.set_shader_parameter("tint", color)
		material.set_shader_parameter("strength", 0.6 if state == 1 else (0.36 if complete else 0.25))
		material.set_shader_parameter("engaged", 1.0 if state == 1 else 0.0)
		var light_material: StandardMaterial3D = visual.light_material
		light_material.albedo_color = color
		light_material.emission = color
		light_material.emission_energy_multiplier = 0.7 if complete else 0.5
		for child in world.seals[i].get_children():
			if child is OmniLight3D:
				child.light_color = color
				child.light_energy = 1.8 if complete else 2.2
		if state > 0:
			bloom(world.seals[i].position, color, 2.6 if complete else 1.85, complete)
	var boss_alive: bool = is_instance_valid(world.boss_node) and not world.boss_node.dead
	if boss_alive != court_visible:
		court_visible = boss_alive
		court_material.set_shader_parameter("strength", 0.29 if boss_alive else 0.0)
		court_material.set_shader_parameter("engaged", 1.0 if boss_alive else 0.0)
		court_material.set_shader_parameter("tint", Color("d9ae76"))
		if boss_alive: bloom(Vector3.ZERO, Color("dfbb80"), 4.0, true)

func bloom(position_value: Vector3, color: Color, radius: float, triumphant: bool) -> void:
	var effect := BLOOM.new()
	effect.position = position_value
	effect.color = color
	effect.radius = radius
	effect.triumphant = triumphant
	add_child(effect)

func build_rain_ripples(random: RandomNumberGenerator) -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(1.1, 1.1)
	var data := MultiMesh.new()
	data.transform_format = MultiMesh.TRANSFORM_3D
	data.use_custom_data = true
	data.mesh = plane
	data.instance_count = 76
	for i in range(data.instance_count):
		var p := Vector3(random.randf_range(-16.8, 16.8), 0.092, random.randf_range(-17.5, 14.5))
		if Vector2(p.x, p.z).length() < 4.2: p.y = 0.136
		var scale_value := random.randf_range(0.45, 1.15)
		data.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * scale_value), p))
		data.set_instance_custom_data(i, Color(random.randf(), random.randf(), 0, 0))
	ripple_batch = MultiMeshInstance3D.new()
	ripple_batch.name = "RainRipples"
	ripple_batch.multimesh = data
	var material := ShaderMaterial.new()
	material.shader = preload("res://scripts/rebirth/shaders/RainRipples.gdshader")
	ripple_batch.material_override = material
	ripple_batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ripple_batch)

func build_falling_leaves(random: RandomNumberGenerator) -> void:
	var data := MultiMesh.new()
	data.transform_format = MultiMesh.TRANSFORM_3D
	data.use_custom_data = true
	data.use_colors = true
	data.mesh = F.leaf_mesh()
	data.instance_count = 65
	for i in range(data.instance_count):
		var center: Vector3 = MAPLE_BEDS[i % MAPLE_BEDS.size()]
		var p := center + Vector3(random.randf_range(-3.2, 3.2), 0.12, random.randf_range(-3.2, 3.2))
		data.set_instance_transform(i, Transform3D(Basis.IDENTITY, p))
		data.set_instance_custom_data(i, Color(random.randf(), random.randf(), random.randf(), 0))
		data.set_instance_color(i, Color(random.randf_range(0.7, 1.3), random.randf_range(0.7, 1.15), 0.8))
	leaf_batch = MultiMeshInstance3D.new()
	leaf_batch.name = "DriftingMapleLeaves"
	leaf_batch.multimesh = data
	leaf_batch.custom_aabb = AABB(Vector3(-21,-1,-23), Vector3(42,9,39))
	var material := ShaderMaterial.new()
	material.shader = preload("res://scripts/rebirth/shaders/FallingLeaves.gdshader")
	leaf_batch.material_override = material
	leaf_batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(leaf_batch)

func build_lake_mist() -> void:
	var positions := [Vector3(-25,-0.5,-6), Vector3(25,-0.6,2), Vector3(-20,-0.4,-30), Vector3(19,-0.4,-31), Vector3(0,-0.5,-38), Vector3(0,-0.5,24)]
	var plane := PlaneMesh.new()
	plane.size = Vector2(25, 12)
	for i in range(positions.size()):
		var material := ShaderMaterial.new()
		material.shader = preload("res://scripts/rebirth/shaders/LakeMist.gdshader")
		material.set_shader_parameter("offset", i * 1.7)
		var mist := F.instance(self, plane, positions[i], material)
		mist.name = "LakeMist%d" % i
		mist.rotation.y = i * 0.6
		mist.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func build_distant_landscape(random: RandomNumberGenerator) -> void:
	for layer in range(2):
		var material := F.material(Color("365661") if layer == 0 else Color("28454d"), 0.05, 0.94)
		var data := MultiMesh.new()
		data.transform_format = MultiMesh.TRANSFORM_3D
		data.mesh = F.mountain_mesh(800 + layer)
		data.instance_count = 9 if layer == 0 else 6
		for i in range(data.instance_count):
			var x := (i - (data.instance_count - 1) * 0.5) * (11.0 if layer == 0 else 13.0)
			var p := Vector3(x, -9.0, (-57.0 if layer == 0 else -39.0) + random.randf_range(-5, 2))
			var mountain_scale := Vector3(random.randf_range(6.5, 10.0), random.randf_range(16.0, 27.0) if layer == 0 else random.randf_range(12.0, 18.0), random.randf_range(5.0, 8.0))
			var basis := Basis.from_euler(Vector3(0, random.randf() * TAU, 0)).scaled(mountain_scale)
			data.set_instance_transform(i, Transform3D(basis, p))
		var ridge := MultiMeshInstance3D.new()
		ridge.name = "DistantRidge%d" % layer
		ridge.multimesh = data
		ridge.material_override = material
		ridge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(ridge)
	build_distant_pagoda(Vector3(-26, 4.0, -31), 0.85)
	build_distant_pagoda(Vector3(29, 3.1, -34), 0.6)

func build_distant_pagoda(p: Vector3, size: float) -> void:
	var tower := Node3D.new()
	tower.name = "MountainPagoda"
	tower.position = p
	tower.scale *= size
	add_child(tower)
	var stone := F.material(Color("29434a"), 0.05, 0.9)
	var roof_material := F.material(Color("263b40"), 0.25, 0.8)
	var lantern := F.material(Color("c1a571"), 0, 0.8, 0.35)
	F.cylinder(tower, Vector3(0,-3,0), 2.4, 6, stone, 1.7, 7)
	var roof_mesh := pagoda_roof_mesh()
	for floor_index in range(3):
		var width := 2.6 - floor_index * 0.47
		var y := floor_index * 1.65
		F.box(tower, Vector3(0,y+0.63,0), Vector3(width*0.68,1.25,width*0.68), stone)
		for x in [-0.45,0.45]:
			F.box(tower, Vector3(x*width,y+0.75,width*0.35), Vector3(0.10,0.6,0.04), lantern)
		var roof := F.instance(tower, roof_mesh, Vector3(0,y+1.2,0), roof_material)
		roof.scale = Vector3(width, 1, width)
	F.cylinder(tower, Vector3(0,5.7,0),0.08,1.3,stone,0.015,6)
	F.sphere(tower, Vector3(0,6.3,0),0.13,lantern)

func pagoda_roof_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var edge := [Vector3(-1,0.18,-1),Vector3(0,-0.03,-1),Vector3(1,0.18,-1),Vector3(1,-0.03,0),Vector3(1,0.18,1),Vector3(0,-0.03,1),Vector3(-1,0.18,1),Vector3(-1,-0.03,0)]
	for i in range(edge.size()):
		for v in [Vector3(0,0.72,0), edge[(i+1)%edge.size()], edge[i]]: surface.add_vertex(v)
	surface.generate_normals()
	return surface.commit()
