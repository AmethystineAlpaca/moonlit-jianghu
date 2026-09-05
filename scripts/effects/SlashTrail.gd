extends Node2D
var _elapsed := 0.0
var _lifetime := 0.16
var _arc: Polygon2D
var _core: Polygon2D

func setup(facing: Vector2, variant: String, _melee_range: float) -> void:
	rotation = facing.angle()
	z_index = 1800
	_arc = $Arc
	_core = $Core
	var material := CanvasItemMaterial.new()
	material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_arc.material = material
	_core.material = material
	var tint := Color("bdcfc9")
	var radius := 36.0
	if variant == "impact":
		tint = Color("dfbd83")
		radius = 42.0
		_lifetime = 0.21
	elif variant == "counter": tint = Color("8ed5c1")
	elif variant == "back_hit": tint = Color("d8a898")
	elif variant == "momentum": tint = Color("a1c9d2")
	_arc.color = Color(tint, 0.5)
	_core.color = Color("f1f2df")
	_arc.polygon = _ribbon(radius, 6.0)
	_core.polygon = _ribbon(radius + 0.7, 1.4)

func _ribbon(radius: float, width: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(19):
		var t := float(i) / 18.0
		points.append(Vector2.from_angle(lerpf(-1.15, 1.15, t)) * radius)
	for i in range(18, -1, -1):
		var t := float(i) / 18.0
		points.append(Vector2.from_angle(lerpf(-1.15, 1.15, t)) * (radius - sin(t * PI) * width))
	return points

func _process(delta: float) -> void:
	_elapsed += delta
	var progress := clampf(_elapsed / _lifetime, 0.0, 1.0)
	modulate.a = pow(1.0 - progress, 1.5)
	scale = Vector2.ONE * (0.92 + progress * 0.13)
	if progress >= 1.0: queue_free()
