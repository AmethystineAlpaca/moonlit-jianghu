extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/World.tscn")

var failures := 0
var chest_scene: PackedScene
var mimic_scene: PackedScene

func _initialize() -> void:
	chest_scene = load("res://scenes/world/ChestEncounter.tscn") as PackedScene
	mimic_scene = load("res://scenes/enemies/ChestMimic.tscn") as PackedScene
	_assert_true(chest_scene != null, "chest encounter scene exists")
	_assert_true(mimic_scene != null, "chest mimic scene exists")
	if chest_scene == null or mimic_scene == null:
		quit(failures)
		return

	await _test_world_spawns_chest_after_two_minutes()
	await _test_potion_chest_restores_player_health()
	await _test_monster_chest_spawns_double_health_mimic()
	await _test_mimic_disappears_on_death()
	quit(failures)

func _test_world_spawns_chest_after_two_minutes() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame

	var chests_parent := world.get_node("Chests")
	for child in chests_parent.get_children():
		child.queue_free()
	await process_frame

	world.set("chest_scene", chest_scene)
	world.set("chest_spawn_timer", 0.0)
	world.call("_try_spawn_chest")

	_assert_equal(chests_parent.get_child_count(), 1, "world spawns a chest encounter")
	var chest := chests_parent.get_child(0) as Node2D
	_assert_true(absf(chest.global_position.x) <= world.get("spawn_area_half_size").x, "chest x stays inside spawn area")
	_assert_true(absf(chest.global_position.y) <= world.get("spawn_area_half_size").y, "chest y stays inside spawn area")

	world.free()

func _test_potion_chest_restores_player_health() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame

	var player := world.get_node("Player")
	var health := player.get_node("HealthComponent") as HealthComponent
	health.take_damage(4)
	var damaged_health := health.current_health

	var chest := chest_scene.instantiate()
	world.get_node("Chests").add_child(chest)
	chest.call("open_as_potion", player)

	_assert_true(health.current_health > damaged_health, "potion chest restores health")
	_assert_true(chest.is_queued_for_deletion(), "opened potion chest is removed")

	world.free()

func _test_monster_chest_spawns_double_health_mimic() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame

	var chest := chest_scene.instantiate() as Node2D
	chest.set("mimic_scene", mimic_scene)
	chest.global_position = Vector2(88.0, -42.0)
	world.get_node("Chests").add_child(chest)
	chest.call("open_as_mimic", world.get_node("Player"))

	var enemies_parent := world.get_node("Enemies")
	_assert_equal(enemies_parent.get_child_count(), 2, "monster chest adds one mimic to existing initial enemy")
	var mimic := enemies_parent.get_child(enemies_parent.get_child_count() - 1) as Node2D
	_assert_equal(mimic.global_position, Vector2(88.0, -42.0), "mimic appears where the chest opened")
	_assert_equal(mimic.get_node("HealthComponent").get("max_health"), 8, "mimic has double basic enemy health")
	_assert_true(mimic.is_in_group("hostile_enemies"), "mimic is a hostile enemy")
	_assert_true(chest.is_queued_for_deletion(), "opened monster chest is removed")

	world.free()

func _test_mimic_disappears_on_death() -> void:
	var mimic := mimic_scene.instantiate()
	root.add_child(mimic)
	await process_frame

	var health := mimic.get_node("HealthComponent") as HealthComponent
	health.take_damage(health.max_health)
	await process_frame

	_assert_false(is_instance_valid(mimic), "dead mimic disappears immediately")
	_assert_equal(get_nodes_in_group("corpses").size(), 0, "dead mimic does not create a corpse")

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
