extends Node2D

@export var zombie_scene: PackedScene
@export var aura_scene: PackedScene
@export var puff_scene: PackedScene
@export var resurrection_radius: float = 96.0

func activate(context: Dictionary) -> bool:
	var origin: Vector2 = context.get("origin", global_position)
	var caster = context.get("caster")

	_spawn_aura(origin)

	for corpse in _find_corpses_in_radius(origin, resurrection_radius):
		_spawn_puff(corpse.global_position)
		var zombie := _create_zombie_from_corpse(corpse)
		if zombie == null:
			continue
		corpse.get_parent().add_child(zombie)
		zombie.global_position = corpse.global_position
		if zombie.has_method("_apply_faction_visuals"):
			zombie.call("_apply_faction_visuals")
		if zombie.has_method("set_survival_mode"):
			zombie.set_survival_mode(true)
		corpse.queue_free()

	call_deferred("queue_free")
	return true

func _create_zombie_from_corpse(corpse: Node2D) -> Node2D:
	var source_scene := _get_source_scene(corpse)
	if source_scene == null:
		source_scene = zombie_scene
	if source_scene == null:
		return null

	var zombie := source_scene.instantiate() as Node2D
	if zombie == null:
		return null

	_copy_zombie_stats(corpse, zombie)
	return zombie

func _get_source_scene(corpse: Node2D) -> PackedScene:
	if corpse.scene_file_path.is_empty():
		return null
	return load(corpse.scene_file_path) as PackedScene

func _copy_zombie_stats(corpse: Node2D, zombie: Node2D) -> void:
	zombie.set("faction", "zombie")
	zombie.set("move_speed", float(corpse.get("move_speed")) * 0.5)
	zombie.set("contact_damage", int(corpse.get("contact_damage")))

	var corpse_health := corpse.get_node_or_null("HealthComponent") as HealthComponent
	var zombie_health := zombie.get_node_or_null("HealthComponent") as HealthComponent
	if corpse_health != null and zombie_health != null:
		zombie_health.max_health = corpse_health.max_health

func _find_corpses_in_radius(origin: Vector2, radius: float) -> Array[Node2D]:
	var result: Array[Node2D] = []
	var radius_sq := radius * radius
	for node in get_tree().get_nodes_in_group("corpses"):
		if not (node is Node2D):
			continue
		var corpse := node as Node2D
		if corpse.modulate.a <= 0.05:
			continue
		if corpse.has_method("is_transformable_corpse") and not corpse.is_transformable_corpse():
			continue
		if origin.distance_squared_to(corpse.global_position) > radius_sq:
			continue
		result.append(corpse)
	return result

func _spawn_aura(at: Vector2) -> void:
	if aura_scene == null:
		return
	var aura := aura_scene.instantiate() as Node2D
	if aura == null:
		return
	_get_effect_parent().add_child(aura)
	aura.global_position = at

func _spawn_puff(at: Vector2) -> void:
	if puff_scene == null:
		return
	var puff := puff_scene.instantiate() as Node2D
	if puff == null:
		return
	_get_effect_parent().add_child(puff)
	puff.global_position = at

func _get_effect_parent() -> Node:
	if get_tree().current_scene != null:
		return get_tree().current_scene
	return get_tree().root
