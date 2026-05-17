extends SceneTree

const ENEMY_SCENE := preload("res://scenes/enemies/BasicEnemy.tscn")
const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")

var failures := 0

func _initialize() -> void:
	var zombie_scene := load("res://scenes/allies/Zombie.tscn") as PackedScene
	_assert_true(zombie_scene != null, "zombie scene exists")
	if zombie_scene == null:
		quit(failures)
		return

	var player := PLAYER_SCENE.instantiate() as Node2D
	root.add_child(player)
	player.global_position = Vector2(100.0, 0.0)

	var enemy := ENEMY_SCENE.instantiate() as Node2D
	root.add_child(enemy)
	enemy.global_position = Vector2.ZERO
	await process_frame

	var zombie := zombie_scene.instantiate() as Node2D
	root.add_child(zombie)
	zombie.global_position = Vector2(30.0, 0.0)
	await process_frame

	_assert_true(zombie.is_in_group("zombies"), "zombie is in zombies group")
	_assert_true(zombie.is_in_group("enemies"), "zombie remains player-attackable")
	_assert_equal(zombie.get("move_speed"), 57.5, "zombie speed is half of normal basic enemy")
	_assert_equal(zombie.get_node("HealthComponent").get("max_health"), 4, "zombie has normal enemy health")

	_assert_equal(enemy.call("find_nearest_target"), zombie, "normal enemy targets nearer zombie over player")
	_assert_equal(zombie.call("find_nearest_target"), enemy, "zombie targets nearest hostile enemy")
	_assert_equal(enemy.get("current_target"), zombie, "normal enemy retargets to nearer zombie during AI update")

	enemy.set("current_target", zombie)
	enemy.call("_try_damage_player")
	_assert_equal(zombie.get_node("HealthComponent").get("current_health"), 3, "normal enemy can damage zombie")
	_assert_equal(zombie.get("knockback_velocity"), Vector2.RIGHT * enemy.get("attack_hitback_force"), "enemy attack gives zombie a tiny hitback")
	await create_timer(zombie.get("hit_flash_duration") + 0.05).timeout
	_assert_true(_is_zombie_tinted(zombie), "zombie keeps its green tint after hit flash clears")

	var zombie_health := zombie.get_node("HealthComponent") as HealthComponent
	zombie_health.take_damage(zombie_health.max_health)
	await process_frame
	_assert_false(is_instance_valid(zombie), "dead zombie disappears immediately instead of becoming a corpse")
	_assert_equal(get_nodes_in_group("corpses").size(), 0, "dead zombie does not create a transformable corpse")

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

func _is_zombie_tinted(zombie: Node2D) -> bool:
	var body := zombie.get_node("Body") as Sprite2D
	return body.modulate.g > body.modulate.r and body.modulate.g > body.modulate.b
