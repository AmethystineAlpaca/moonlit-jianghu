extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/World.tscn")
const ENEMY_SCENE := preload("res://scenes/enemies/BasicEnemy.tscn")

var failures := 0

func _initialize() -> void:
	await _test_spawn_positions_stay_inside_playable_bounds()
	await _test_spawned_enemy_home_matches_spawn_position()
	quit(failures)

func _test_spawn_positions_stay_inside_playable_bounds() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame

	for index in range(120):
		var position: Vector2 = world.call("_get_spawn_position")
		_assert_true(absf(position.x) <= 640.0, "spawn x stays away from boundary walls")
		_assert_true(absf(position.y) <= 400.0, "spawn y stays away from boundary walls")

	world.free()

func _test_spawned_enemy_home_matches_spawn_position() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame

	var enemies_parent := world.get_node("Enemies")
	for child in enemies_parent.get_children():
		child.queue_free()
	await process_frame

	world.set("enemy_scene", ENEMY_SCENE)
	world.call("_try_spawn_enemy")

	var enemy := enemies_parent.get_child(0)
	_assert_equal(enemy.get("home_position"), enemy.global_position, "enemy home position is initialized at its spawn position")

	world.free()

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
