extends Node3D
## A brief, low silhouette celebration; no gameplay, colliders, or screen flash.
const F := preload("res://scripts/rebirth/Form.gd")
var color := Color("b3ded0")
var radius := 2.6
var triumphant := false
var age := 0.0
var lifetime := 1.65
var rings: Array[MeshInstance3D] = []
var materials: Array[StandardMaterial3D] = []
var sparks: MultiMeshInstance3D
var spark_material: StandardMaterial3D

func _ready() -> void:
	name = "SealBloom"
	lifetime = 2.2 if triumphant else 1.55
	for i in range(2):
		var material := F.material(Color(color, 0.5), 0, 0.6, 0.8)
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		var ring := F.ring(self, Vector3(0, 0.18 + i * 0.025, 0), 1.0, 0.012, material)
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		rings.append(ring)
		materials.append(material)
	var data := MultiMesh.new()
	data.transform_format = MultiMesh.TRANSFORM_3D
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.022, 0.16, 0.022)
	data.mesh = mesh
	data.instance_count = 18 if triumphant else 12
	sparks = MultiMeshInstance3D.new()
	sparks.multimesh = data
	spark_material = F.material(Color(color, 0.6), 0, 0.4, 1.0)
	spark_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sparks.material_override = spark_material
	sparks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sparks)
	update_shapes(0.0)

func _process(delta: float) -> void:
	age += delta
	if age >= lifetime:
		queue_free()
		return
	update_shapes(age / lifetime)

func update_shapes(t: float) -> void:
	for i in range(rings.size()):
		var progress := clampf(t * 1.3 - i * 0.12, 0, 1)
		var expansion := lerpf(0.52, radius, 1.0 - pow(1.0 - progress, 3.0))
		rings[i].scale = Vector3(expansion, 1.0, expansion)
		materials[i].albedo_color.a = (1.0 - progress) * 0.56
	var data := sparks.multimesh
	for i in range(data.instance_count):
		var angle := i * TAU / data.instance_count + t * 0.22
		var distance_value := radius * (0.28 + (i % 3) * 0.13 + t * 0.22)
		var height := 0.25 + sin(t * PI * 0.75) * (1.5 if triumphant else 0.85) + (i % 4) * 0.08
		var p := Vector3(sin(angle) * distance_value, height, cos(angle) * distance_value)
		var basis := Basis.IDENTITY.scaled(Vector3.ONE * maxf(0.02, sin(PI * t)))
		data.set_instance_transform(i, Transform3D(basis, p))
	spark_material.albedo_color.a = maxf(0, sin(PI * t)) * 0.65
