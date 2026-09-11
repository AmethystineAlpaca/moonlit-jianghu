extends RefCounted

const WEATHERED_SHADER := preload("res://scripts/rebirth/shaders/Weathered.gdshader")
const WATER_SHADER := preload("res://scripts/rebirth/shaders/Lake.gdshader")
const FOLIAGE_SHADER := preload("res://scripts/rebirth/shaders/Foliage.gdshader")

static func material(color: Color, metal := 0.0, roughness := 0.8, emission := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metal
	m.roughness = roughness
	if color.a < 1:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emission > 0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	return m

static func box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material, collision := false) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := instance(parent, mesh, pos, mat)
	if collision:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = size
		shape.shape = box_shape
		body.add_child(shape)
		node.add_child(body)
	return node

static func cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, mat: Material, top := -1.0, sides := 12) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius if top < 0 else top
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = sides
	return instance(parent, mesh, pos, mat)

static func sphere(parent: Node3D, pos: Vector3, radius: float, mat: Material, scale_y := 1.0) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2
	mesh.radial_segments = 12
	mesh.rings = 6
	var node := instance(parent, mesh, pos, mat)
	node.scale.y = scale_y
	return node

static func instance(parent: Node3D, mesh: Mesh, pos: Vector3, mat: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	node.position = pos
	parent.add_child(node)
	return node

static func beam(parent: Node3D, start: Vector3, end: Vector3, width: float, mat: Material) -> MeshInstance3D:
	var node := box(parent, (start + end) / 2, Vector3(width, start.distance_to(end), width), mat)
	var direction := (end-start).normalized()
	if absf(direction.dot(Vector3.UP)) < 0.999:
		node.basis = Basis(Quaternion(Vector3.UP, direction))
	return node

static func ring(parent: Node3D, pos: Vector3, radius: float, width: float, mat: Material) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = maxf(radius-width, 0.01)
	mesh.outer_radius = radius+width
	mesh.rings = 48
	mesh.ring_segments = 6
	return instance(parent, mesh, pos, mat)

static func weathered(color: Color, scale_value := 3.0) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = WEATHERED_SHADER
	mat.set_shader_parameter("tint",color)
	mat.set_shader_parameter("grain",scale_value)
	return mat

static func water() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = WATER_SHADER
	return mat

static func foliage(color: Color, wind_strength := 0.1) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = FOLIAGE_SHADER
	mat.set_shader_parameter("tint", color)
	mat.set_shader_parameter("wind_strength", wind_strength)
	return mat

static func crystal_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var waist := [Vector3(0.13, 0, 0), Vector3(0, 0, 0.13), Vector3(-0.13, 0, 0), Vector3(0, 0, -0.13)]
	for i in range(4):
		var a: Vector3 = waist[i]
		var b: Vector3 = waist[(i + 1) % 4]
		for v in [Vector3(0, 0.43, 0), b, a, Vector3(0, -0.23, 0), a, b]:
			surface.add_vertex(v)
	surface.generate_normals()
	return surface.commit()

static func mountain_mesh(seed_value: int) -> ArrayMesh:
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lower: Array[Vector3] = []
	var shoulder: Array[Vector3] = []
	var crown: Array[Vector3] = []
	for i in range(7):
		var angle := i * TAU / 7.0
		lower.append(Vector3(cos(angle) * random.randf_range(0.8, 1.2), 0, sin(angle) * random.randf_range(0.8, 1.2)))
		shoulder.append(Vector3(cos(angle) * 0.64, random.randf_range(0.4, 0.6), sin(angle) * 0.61))
		crown.append(Vector3(cos(angle) * 0.22 + 0.14, random.randf_range(0.8, 0.98), sin(angle) * 0.25 - 0.08))
	for i in range(7):
		var next := (i + 1) % 7
		for ring_pair in [[lower, shoulder], [shoulder, crown]]:
			var a: Vector3 = ring_pair[0][i]
			var b: Vector3 = ring_pair[0][next]
			var c: Vector3 = ring_pair[1][i]
			var d: Vector3 = ring_pair[1][next]
			for v in [a, c, b, b, c, d]: surface.add_vertex(v)
		for v in [crown[i], Vector3(0.12, 1.09, -0.04), crown[next]]: surface.add_vertex(v)
	surface.generate_normals()
	return surface.commit()

static func paver_mesh() -> ArrayMesh:
	var s := SurfaceTool.new()
	s.begin(Mesh.PRIMITIVE_TRIANGLES)
	var top := [Vector3(-0.45,0.065,-0.61),Vector3(0.45,0.065,-0.61),Vector3(0.48,0.065,-0.58),Vector3(0.48,0.065,0.58),Vector3(0.45,0.065,0.61),Vector3(-0.45,0.065,0.61),Vector3(-0.48,0.065,0.58),Vector3(-0.48,0.065,-0.58)]
	for i in range(8):
		var a: Vector3 = top[i]
		var b: Vector3 = top[(i+1)%8]
		for v in [Vector3(0,0.065,0),b,a]: s.add_vertex(v)
		var low_a := Vector3(a.x*1.025,0,a.z*1.025)
		var low_b := Vector3(b.x*1.025,0,b.z*1.025)
		for v in [a,b,low_b,a,low_b,low_a]: s.add_vertex(v)
	s.generate_normals()
	return s.commit()

static func leaf_mesh() -> ArrayMesh:
	var s := SurfaceTool.new()
	s.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points := [Vector3(0,0,-0.2),Vector3(0.055,0,-0.045),Vector3(0.17,0,-0.08),Vector3(0.10,0,0.025),Vector3(0.14,0,0.11),Vector3(0,0,0.065),Vector3(-0.14,0,0.11),Vector3(-0.1,0,0.025),Vector3(-0.17,0,-0.08),Vector3(-0.055,0,-0.045)]
	for i in range(points.size()):
		for v in [Vector3(0,0.035,0),points[(i+1)%points.size()],points[i]]: s.add_vertex(v)
	s.generate_normals()
	return s.commit()
