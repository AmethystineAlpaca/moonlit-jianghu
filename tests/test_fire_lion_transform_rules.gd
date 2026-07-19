extends SceneTree

const FIRE_LION_SCENE := preload("res://scenes/enemies/FireLionEnemy.tscn")
const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")

var failures := 0

func _initialize() -> void:
	await _test_fire_lion_corpse_is_not_transformable()
	quit(failures)

func _test_fire_lion_corpse_is_not_transformable() -> void:
	var transform_scene := load("res://scenes/skills/TransformSkillEffect.tscn") as PackedScene
	_assert_true(transform_scene != null, "transform skill effect scene exists")
	if transform_scene == null:
		return

	var player := PLAYER_SCENE.instantiate() as Node2D
	root.add_child(player)
	_disable_player_skills(player)
	player.global_position = Vector2(-24.0, 0.0)
	player.set("last_facing_direction", Vector2.RIGHT)

	var corpse := FIRE_LION_SCENE.instantiate() as Node2D
	root.add_child(corpse)
	await process_frame
	var health := corpse.get_node("HealthComponent") as HealthComponent
	health.take_damage(health.max_health)
	await process_frame
	corpse.call("settle_dead_body")
	await physics_frame

	_assert_true(corpse.has_method("is_transformable_corpse"), "fire lion corpse exposes transform check")
	_assert_true(not corpse.is_transformable_corpse(), "fire lion corpse opts out of transform")

	var effect := transform_scene.instantiate()
	root.add_child(effect)
	var cast_ok: bool = effect.activate(_make_context(player))
	_assert_true(cast_ok, "transform cast still succeeds without targeting fire lion corpse")
	_assert_equal(get_nodes_in_group("zombies").size(), 0, "fire lion corpse does not create a zombie")
	_assert_true(is_instance_valid(corpse), "fire lion corpse remains after transform cast")

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

func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	failures += 1
	push_error(message)

func _assert_equal(actual, expected, message: String) -> void:
	if actual == expected:
		return
	failures += 1
	push_error("%s: expected %s, got %s" % [message, expected, actual])
