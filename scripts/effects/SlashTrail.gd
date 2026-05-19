extends Node2D

var _elapsed: float = 0.0
var _lifetime: float = 0.12
var _arc: Polygon2D
var _core: Polygon2D

func setup(facing: Vector2, variant: String, _melee_range: float) -> void:
	_arc = get_node_or_null("Arc") as Polygon2D
	_core = get_node_or_null("Core") as Polygon2D
	if _arc == null:
		return
	rotation = facing.angle()
	match variant:
		"counter":
			_arc.color = Color(0.4, 1.0, 0.9, 0.72)
			_arc.scale = Vector2(1.35, 1.35)
			if _core:
				_core.color = Color(0.92, 1.0, 0.98, 0.95)
				_core.scale = Vector2(1.35, 1.35)
			_lifetime = 0.15
		"back_hit":
			_arc.color = Color(0.65, 0.35, 1.0, 0.72)
			_arc.scale = Vector2(1.1, 1.1)
			if _core:
				_core.color = Color(0.95, 0.92, 1.0, 0.95)
				_core.scale = Vector2(1.1, 1.1)
			_lifetime = 0.13
		_:
			_arc.color = Color(0.45, 0.82, 1.0, 0.72)
			_arc.scale = Vector2.ONE
			if _core:
				_core.color = Color(0.92, 0.97, 1.0, 0.95)
				_core.scale = Vector2.ONE
			_lifetime = 0.10

func _process(delta: float) -> void:
	_elapsed += delta
	var t := clampf(_elapsed / _lifetime, 0.0, 1.0)
	modulate.a = 1.0 - t
	if _elapsed >= _lifetime:
		queue_free()
