extends Node2D

@export var orbit_radius: float = 32.0
@export var orbit_speed_rad: float = 4.0
@export var damage: int = 1
@export var lifetime: float = 1.5
@export var hit_dwell: float = 0.6
@export var hit_check_radius: float = 11.0

var caster: Node2D
var _hit_cooldowns: Dictionary = {}
var _life_remaining: float = 0.0
var _is_primary: bool = false
var _query_shape: CircleShape2D

func _ready() -> void:
	_query_shape = CircleShape2D.new()
	_query_shape.radius = hit_check_radius
	tree_exiting.connect(_on_tree_exiting)

func activate(context: Dictionary) -> bool:
	var origin_caster = context.get("caster")
	if not (origin_caster is Node2D):
		call_deferred("queue_free")
		return false

	var existing = origin_caster.get_meta("protective_orb") if origin_caster.has_meta("protective_orb") else null
	if existing is Node and is_instance_valid(existing):
		existing.call("refresh")
		call_deferred("queue_free")
		return true

	caster = origin_caster
	origin_caster.set_meta("protective_orb", self)
	_is_primary = true
	_life_remaining = lifetime
	global_position = _orbit_position()
	return true

func refresh() -> void:
	_life_remaining = lifetime

func _physics_process(delta: float) -> void:
	if not _is_primary:
		return
	if caster == null or not is_instance_valid(caster):
		queue_free()
		return

	_life_remaining -= delta
	if _life_remaining <= 0.0:
		queue_free()
		return

	global_position = _orbit_position()

	for id in _hit_cooldowns.keys():
		_hit_cooldowns[id] -= delta
		if _hit_cooldowns[id] <= 0.0:
			_hit_cooldowns.erase(id)

	_scan_and_hit()

func _orbit_position() -> Vector2:
	var phase := (Time.get_ticks_msec() / 1000.0) * orbit_speed_rad
	return caster.global_position + Vector2(cos(phase), sin(phase)) * orbit_radius

func _scan_and_hit() -> void:
	var space_state := get_world_2d().direct_space_state
	if space_state == null:
		return
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _query_shape
	query.transform = Transform2D(0.0, global_position)
	query.collision_mask = 1
	query.collide_with_bodies = true
	query.collide_with_areas = false
	var hits := space_state.intersect_shape(query, 16)
	for hit in hits:
		var collider := hit.get("collider") as Node
		_try_contact(collider)

func _try_contact(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	var id := node.get_instance_id()
	if _hit_cooldowns.has(id):
		return

	if node.is_in_group("enemies"):
		if node.is_in_group("zombies"):
			return
		var health := node.get_node_or_null("HealthComponent") as HealthComponent
		if health != null:
			health.take_damage(damage)
			_hit_cooldowns[id] = hit_dwell
		return

	if node.is_in_group("breakables") and node.has_method("shatter"):
		node.shatter()
		_hit_cooldowns[id] = hit_dwell

func _on_tree_exiting() -> void:
	if caster != null and is_instance_valid(caster):
		var current = caster.get_meta("protective_orb", null)
		if current == self:
			caster.remove_meta("protective_orb")
