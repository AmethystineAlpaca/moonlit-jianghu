extends SceneTree

const ENEMY_SCENE := preload("res://scenes/enemies/BasicEnemy.tscn")

var failures := 0

func _initialize() -> void:
	var enemy := ENEMY_SCENE.instantiate()
	root.add_child(enemy)
	await process_frame

	_assert_equal(enemy.get("dead_body_lifetime"), 10.0, "corpse lifetime defaults to 10 seconds")
	_assert_true(enemy.has_method("settle_dead_body"), "enemy can settle a dead body after impact")

	var health := enemy.get_node("HealthComponent") as HealthComponent
	health.take_damage(health.max_health)
	await process_frame

	_assert_true(enemy.get("is_dying"), "enemy enters corpse state immediately on death")

	enemy.set("corpse_flight_timer", 0.0)
	enemy.set("knockback_velocity", Vector2.ZERO)
	enemy.call("settle_dead_body")
	_assert_true(enemy.get_collision_layer_value(1), "settled corpse keeps a collision boundary")
	_assert_true(enemy.get_collision_mask_value(1), "settled corpse keeps collision sensing")
	enemy.call("_update_death_flight", 9.9)
	_assert_false(enemy.is_queued_for_deletion(), "corpse remains before 10 second lifetime")
	_assert_equal(enemy.modulate.a, 1.0, "corpse stays fully visible before fade")

	enemy.call("_update_death_flight", 0.2)
	_assert_false(enemy.is_queued_for_deletion(), "corpse fades instead of vanishing at 10 seconds")
	_assert_true(enemy.modulate.a < 1.0, "corpse starts fading after lifetime")

	enemy.call("_update_death_flight", enemy.get("dead_body_fade_duration"))
	_assert_true(enemy.is_queued_for_deletion(), "corpse is removed after fade completes")

	enemy.free()
	quit(failures)

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
