extends RefCounted
const F := preload("res://scripts/rebirth/Form.gd")
static func build(world: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 733
	var grass := MultiMeshInstance3D.new()
	grass.name = "WindGrass"
	var blades := MultiMesh.new()
	blades.transform_format = MultiMesh.TRANSFORM_3D
	blades.use_colors = true
	var mesh := PrismMesh.new()
	mesh.size = Vector3(0.055,0.43,0.035)
	blades.mesh = mesh
	blades.instance_count = 2200
	grass.multimesh = blades
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://scripts/rebirth/shaders/Grass.gdshader")
	grass.material_override = mat
	grass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(grass)
	var beds := [Vector3(-13,0,8),Vector3(13,0,7),Vector3(-15,0,-13),Vector3(14,0,-14),Vector3(-8,0,-18)]
	for p in beds:
		F.cylinder(world,p+Vector3(0,0.09,0),2.3,0.18,F.weathered(Color("3c4f43"),5.0),-1,20)
		F.ring(world,p+Vector3(0,0.12,0),2.35,0.08,world.edge)
	for i in range(2200):
		var center: Vector3 = beds[i % beds.size()]
		var angle := rng.randf()*TAU
		var r := rng.randf_range(0.4,2.22)
		var p := center + Vector3(cos(angle)*r,0.3,sin(angle)*r)
		var basis := Basis.from_euler(Vector3(rng.randf_range(-0.3,0.3),angle,rng.randf_range(-0.25,0.25)))
		basis = basis.scaled(Vector3.ONE*rng.randf_range(0.5,1.2))
		blades.set_instance_transform(i,Transform3D(basis,p))
		blades.set_instance_color(i,Color(rng.randf_range(0.7,1),1,rng.randf_range(0.6,0.9)))
	# The court carries a functional compass rather than a vacant disk.
	var silver := F.material(Color("a3b2a1"),0.55,0.45)
	F.ring(world,Vector3(0,0.12,0),1.3,0.02,silver)
	F.ring(world,Vector3(0,0.12,0),2.7,0.014,world.gold)
	for i in range(8):
		var trigram := Node3D.new()
		trigram.rotation.y = i*TAU/8
		world.add_child(trigram)
		for row in range(3):
			var z := 2.0+row*0.17
			if (i >> row) & 1:
				F.box(trigram,Vector3(0,0.121,z),Vector3(0.7,0.012,0.055),silver)
			else:
				for side in [-1,1]: F.box(trigram,Vector3(side*0.23,0.121,z),Vector3(0.25,0.012,0.055),silver)
	for i in range(24):
		var a := i*TAU/24
		var mark := F.box(world,Vector3(sin(a)*3.45,0.122,cos(a)*3.45),Vector3(0.02,0.01,0.12),world.gold)
		mark.rotation.y = a
	# A central yin/yang-shaped pair of inset arcs.
	for side in [-1,1]:
		F.ring(world,Vector3(0,0.123,side*0.45),0.45,0.02,world.gold)
		F.cylinder(world,Vector3(0,0.124,side*0.45),0.10,0.008,silver,-1,16)
	for p in [Vector3(-8,0,-10),Vector3(8,0,-10)]:
		banner(world,p)
	# Rain channels along the edges and timber benches near resting spaces.
	for x in [-16.8,16.8]:
		F.box(world,Vector3(x,0.045,-2),Vector3(0.18,0.01,31),world.dark)
	for p in [Vector3(-9,0,5),Vector3(9,0,4)]:
		F.box(world,p+Vector3(0,0.58,0),Vector3(2,0.16,0.55),world.wood,true)
		for side in [-1,1]: F.box(world,p+Vector3(side*0.7,0.26,0),Vector3(0.17,0.5,0.4),world.edge)
	# A few carefully placed bronze accents lead the eye toward the mountain hall.
	for side in [-1, 1]:
		var brazier := Vector3(side * 5.8, 0, -15.6)
		F.cylinder(world, brazier + Vector3(0, 0.2, 0), 0.55, 0.4, world.edge, 0.43, 8)
		F.cylinder(world, brazier + Vector3(0, 0.7, 0), 0.31, 0.6, world.gold, 0.45, 8)
		F.ring(world, brazier + Vector3(0, 1.03, 0), 0.44, 0.035, world.gold)
		F.cylinder(world, brazier + Vector3(0, 1.015, 0), 0.38, 0.015, world.dark, -1, 12)
		for i in range(3):
			F.cylinder(world, brazier + Vector3((i-1)*0.12, 1.2, 0), 0.014, 0.4, world.wood, -1, 5)
			F.sphere(world, brazier + Vector3((i-1)*0.12, 1.41, 0), 0.023, F.material(Color("dba578"), 0, 0.8, 1.5))
	var atmosphere := preload("res://scripts/rebirth/CourtyardAtmosphere.gd").new()
	atmosphere.world = world
	world.add_child(atmosphere)

static func banner(world: Node3D, p: Vector3) -> void:
	F.cylinder(world,p+Vector3(0,2.0,0),0.065,4.0,world.wood,-1,8)
	F.sphere(world,p+Vector3(0,4.1,0),0.1,world.gold)
	F.box(world,p+Vector3(0.65,3.8,0),Vector3(1.5,0.07,0.07),world.gold)
	var shader := Shader.new()
	shader.code = """shader_type spatial; render_mode cull_disabled;
uniform vec4 tint:source_color=vec4(0.23,0.36,0.37,1.0);
void vertex(){VERTEX.z+=sin(VERTEX.y*3.0+TIME*2.0)*0.09*UV.y+sin(VERTEX.x*5.0+TIME*1.7)*0.06*UV.y;}
void fragment(){float trim=step(UV.x,0.06)+step(0.94,UV.x)+step(0.97,UV.y);float circle=1.0-smoothstep(0.014,0.025,abs(length((UV-vec2(0.5,0.34))*vec2(1.0,1.7))-0.23));float line=(1.0-step(0.025,abs(UV.x-0.5)))*step(0.19,UV.y)*step(UV.y,0.48);ALBEDO=mix(tint.rgb,vec3(0.65,0.56,0.35),clamp(trim+circle+line,0.0,1.0));ROUGHNESS=0.95;}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	var plane := PlaneMesh.new()
	plane.size = Vector2(1.1,2.2)
	plane.subdivide_width = 8
	plane.subdivide_depth = 12
	var cloth := F.instance(world,plane,p+Vector3(0.67,2.68,0),mat)
	cloth.rotation.x = PI/2
