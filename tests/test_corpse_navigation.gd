extends SceneTree

const WORLD_SCRIPT := preload("res://scripts/world/World.gd")

var failures := 0

func _initialize() -> void:
	await _test_registered_corpse_blocks_navigation_path()
	quit(failures)

func _test_registered_corpse_blocks_navigation_path() -> void:
	var world := Node2D.new()
	world.name = "World"
	world.set_script(WORLD_SCRIPT)
	world.set("map_half_size", Vector2(320.0, 160.0))
	world.set("navigation_cell_size", 32.0)
	world.set("navigation_obstacle_padding", 0.0)

	var enemies := Node2D.new()
	enemies.name = "Enemies"
	world.add_child(enemies)
	root.add_child(world)
	await process_frame

	var from_position := Vector2(16.0, 16.0)
	var target_position := Vector2(176.0, 16.0)
	var direct_direction := world.call("get_path_direction", from_position, target_position) as Vector2
	_assert_true(direct_direction.dot(Vector2.RIGHT) > 0.98, "path is direct before corpse blocks it")

	var corpse := CharacterBody2D.new()
	corpse.add_to_group("corpses")
	corpse.add_to_group("enemies")
	corpse.global_position = Vector2(80.0, 16.0)
	var collision_shape := CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	var shape := CircleShape2D.new()
	shape.radius = 20.0
	collision_shape.shape = shape
	corpse.add_child(collision_shape)
	root.add_child(corpse)
	await process_frame

	_assert_true(world.has_method("register_navigation_obstacle"), "world exposes dynamic navigation obstacle registration")
	if world.has_method("register_navigation_obstacle"):
		world.call("register_navigation_obstacle", corpse)
		var corpse_blocked_direction := world.call("get_path_direction", from_position, target_position) as Vector2
		_assert_true(absf(corpse_blocked_direction.y) > 0.1, "registered corpse bends enemy path around it")

		world.call("unregister_navigation_obstacle", corpse)
		var unblocked_direction := world.call("get_path_direction", from_position, target_position) as Vector2
		_assert_true(unblocked_direction.dot(Vector2.RIGHT) > 0.98, "removing corpse restores direct path")

	corpse.free()
	world.free()

func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	failures += 1
	push_error(message)
