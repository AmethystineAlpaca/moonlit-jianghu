extends RefCounted

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
	var shader := Shader.new()
	shader.code = """shader_type spatial;
uniform vec4 tint:source_color;
uniform float grain=3.0;
varying vec3 wp;
float hash(vec3 p){p=fract(p*0.3183099+vec3(0.1,0.2,0.3));p*=17.0;return fract(p.x*p.y*p.z*(p.x+p.y+p.z));}
float noise(vec3 p){vec3 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);}
void vertex(){wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){float n=noise(wp*grain);float fine=noise(wp*grain*12.0);float moss=smoothstep(0.58,0.8,noise(wp*0.8));ALBEDO=tint.rgb*(0.78+n*0.35+fine*0.14);ALBEDO=mix(ALBEDO,vec3(0.14,0.21,0.15),moss*0.3);ROUGHNESS=0.62+fine*0.25;METALLIC=0.08;NORMAL_MAP=vec3(0.5+(fine-0.5)*0.14,0.5+(n-0.5)*0.12,1.0);}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("tint",color)
	mat.set_shader_parameter("grain",scale_value)
	return mat

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
