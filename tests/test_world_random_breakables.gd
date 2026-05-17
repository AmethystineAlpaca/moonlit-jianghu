extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/World.tscn")

var failures := 0

func _initialize() -> void:
	await _test_world_adds_limited_random_breakables()
	await _test_random_breakables_do_not_overlap_obstacles_or_each_other()
	quit(failures)

func _test_world_adds_limited_random_breakables() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame

	var breakables := _get_breakables(world)
	_assert_true(breakables.size() >= 53, "world adds many more random breakables")
	_assert_true(breakables.size() <= 103, "world keeps random breakables under the expanded cap")

	world.free()

func _test_random_breakables_do_not_overlap_obstacles_or_each_other() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame

	var breakables := _get_breakables(world)
	for index in range(breakables.size()):
		var breakable := breakables[index]
		var breakable_rect := _get_world_rect(world, breakable, Vector2(18.0, 18.0))
		for other_index in range(index + 1, breakables.size()):
			var other_rect := _get_world_rect(world, breakables[other_index], Vector2(18.0, 18.0))
			_assert_true(not breakable_rect.intersects(other_rect), "breakables do not overlap each other")

		for obstacle in _get_static_obstacles(world):
			if obstacle == breakable:
				continue
			var obstacle_rect := _get_world_rect(world, obstacle, Vector2(12.0, 12.0))
			_assert_true(not breakable_rect.intersects(obstacle_rect), "random breakables avoid static obstacles")

	world.free()

func _get_breakables(world: Node) -> Array[Node2D]:
	var result: Array[Node2D] = []
	for node in world.get_tree().get_nodes_in_group("breakables"):
		if world.is_ancestor_of(node) and node is Node2D:
			result.append(node as Node2D)
	return result

func _get_static_obstacles(world: Node) -> Array[Node2D]:
	var result: Array[Node2D] = []
	_collect_static_obstacles(world, result)
	return result

func _collect_static_obstacles(node: Node, result: Array[Node2D]) -> void:
	if node is StaticBody2D and not node.is_in_group("breakables"):
		result.append(node as Node2D)
	for child in node.get_children():
		_collect_static_obstacles(child, result)

func _get_world_rect(world: Node, node: Node2D, padding: Vector2) -> Rect2:
	var size := world.call("_get_obstacle_size", node) as Vector2
	var half_size := size * 0.5 + padding
	return Rect2(node.global_position - half_size, half_size * 2.0)

func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	failures += 1
	push_error(message)
