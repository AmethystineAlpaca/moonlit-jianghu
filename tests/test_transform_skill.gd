extends SceneTree

const ENEMY_SCENE := preload("res://scenes/enemies/BasicEnemy.tscn")
const FAST_ENEMY_SCENE := preload("res://scenes/enemies/FastEnemy.tscn")
const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")

var failures := 0

func _initialize() -> void:
	var transform_scene := load("res://scenes/skills/TransformSkillEffect.tscn") as PackedScene
	_assert_true(transform_scene != null, "transform skill effect scene exists")
	if transform_scene == null:
		quit(failures)
		return

	var player := PLAYER_SCENE.instantiate() as Node2D
	root.add_child(player)
	_disable_player_skills(player)
	player.global_position = Vector2(-42.0, 0.0)
	player.set("last_facing_direction", Vector2.RIGHT)

	var corpse := await _make_settled_corpse(Vector2.ZERO)
	_assert_true(corpse.is_in_group("corpses"), "dead enemy is available as resurrection crop")
	player.global_position = Vector2(-24.0, 0.0)
	_assert_true(player.global_position.distance_to(corpse.global_position) <= 96.0, "player is near corpse before resurrection")
	var effect := transform_scene.instantiate()
	root.add_child(effect)
	var corpse_position := corpse.global_position
	var cast_ok: bool = effect.activate(_make_context(player))
	_assert_true(cast_ok, "clear transform succeeds: %s" % [effect.get("last_failure")])
	_assert_equal(get_nodes_in_group("zombies").size(), 1, "clear transform creates one zombie")
	var zombie := get_first_node_in_group("zombies") as Node2D
	var zombie_position := Vector2.INF
	if zombie != null:
		zombie_position = zombie.global_position
	_assert_true(zombie != null and zombie_position.distance_to(corpse_position) < 0.1, "zombie spawns where corpse was: expected %s got %s" % [corpse_position, zombie_position])
	_assert_equal(zombie.get_node("HealthComponent").get("max_health"), 4, "basic enemy zombie keeps source max HP")
	_assert_equal(zombie.get("contact_damage"), 1, "basic enemy zombie keeps source attack damage")
	_assert_equal(zombie.get("move_speed"), 57.5, "basic enemy zombie moves at half source speed")
	await physics_frame

	_assert_false(is_instance_valid(corpse), "clear transform consumes corpse")
	zombie.queue_free()
	await physics_frame

	var fast_corpse := await _make_settled_corpse(Vector2.ZERO, FAST_ENEMY_SCENE, 2)
	player.global_position = Vector2(-24.0, 0.0)
	effect = transform_scene.instantiate()
	root.add_child(effect)
	cast_ok = effect.activate(_make_context(player))
	_assert_true(cast_ok, "fast enemy transform succeeds: %s" % [effect.get("last_failure")])
	_assert_equal(get_nodes_in_group("zombies").size(), 1, "fast enemy transform creates one zombie")
	var fast_zombie := get_first_node_in_group("zombies") as Node2D
	if fast_zombie != null:
		_assert_equal(fast_zombie.get_node("HealthComponent").get("max_health"), 3, "fast enemy zombie keeps source max HP")
		_assert_equal(fast_zombie.get_node("HealthComponent").get("current_health"), 3, "fast enemy zombie starts at full source HP")
		_assert_equal(fast_zombie.get("contact_damage"), 2, "fast enemy zombie keeps source attack damage")
		_assert_equal(fast_zombie.get("move_speed"), 110.0, "fast enemy zombie moves at half source speed")
		_assert_true(_is_zombie_tinted(fast_zombie), "zombified fast enemy gets a visible green tint")
	await physics_frame
	_assert_false(is_instance_valid(fast_corpse), "fast enemy transform consumes corpse")
	if fast_zombie != null:
		fast_zombie.queue_free()
	await physics_frame

	var missed_corpse := await _make_settled_corpse(Vector2(0.0, 160.0))
	player.global_position = Vector2(-42.0, 0.0)
	await physics_frame
	effect = transform_scene.instantiate()
	root.add_child(effect)
	cast_ok = effect.activate(_make_context(player))
	_assert_true(cast_ok, "resurrection always succeeds even when no corpse is in radius")
	_assert_true(is_instance_valid(missed_corpse), "corpse outside resurrection radius remains a corpse")
	_assert_equal(get_nodes_in_group("zombies").size(), 0, "corpse outside radius is not resurrected")

	quit(failures)

func _make_context(player: Node2D) -> Dictionary:
	var direction: Vector2 = player.get("last_facing_direction")
	return {
		"caster": player,
		"origin": player.global_position,
		"direction": direction,
		"target_position": player.global_position + direction * player.get("melee_range"),
		"zone_range": player.get("melee_range"),
		"zone_size": player.get("melee_size"),
	}

func _disable_player_skills(player: Node) -> void:
	var skill_caster := player.get_node_or_null("SkillCaster")
	if skill_caster == null:
		return
	skill_caster.set("skills", [])
	skill_caster.set("active_slots", [false, false, false, false, false])
	skill_caster.set_process(false)
	skill_caster.set_physics_process(false)

func _make_settled_corpse(position: Vector2, scene: PackedScene = ENEMY_SCENE, damage: int = -1) -> Node2D:
	var enemy := scene.instantiate() as Node2D
	root.add_child(enemy)
	enemy.global_position = position
	await process_frame
	if damage >= 0:
		enemy.set("contact_damage", damage)
	var health := enemy.get_node("HealthComponent") as HealthComponent
	health.take_damage(health.max_health)
	await process_frame
	enemy.call("settle_dead_body")
	enemy.global_position = position
	await physics_frame
	return enemy

func _is_zombie_tinted(zombie: Node2D) -> bool:
	var body := zombie.get_node("Body") as Sprite2D
	return body.modulate.g > body.modulate.r and body.modulate.g > body.modulate.b

func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	failures += 1
	push_error(message)

func _assert_false(value: bool, message: String) -> void:
	_assert_true(not value, message)

func _assert_equal(actual, expected, message: String) -> void:
	if actual == expected:
		return
	failures += 1
	push_error("%s: expected %s, got %s" % [message, expected, actual])
