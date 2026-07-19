extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/World.tscn")
const FIRE_LION_SCENE := preload("res://scenes/enemies/FireLionEnemy.tscn")
const FIRE_LION_SHEET_PATH := "res://assets/xianxia/fire_lion_run_aligned.png"

var failures := 0

func _initialize() -> void:
	await _test_fire_lion_scene_uses_fire_lion_run_sheet()
	await _test_world_can_spawn_fire_lion_enemy()
	quit(failures)

func _test_fire_lion_scene_uses_fire_lion_run_sheet() -> void:
	var fire_lion := FIRE_LION_SCENE.instantiate()
	root.add_child(fire_lion)
	await process_frame

	var body := fire_lion.get_node("Body") as Sprite2D
	_assert_true(body.texture is AtlasTexture, "fire lion body starts on atlas-sliced run frame")
	if body.texture is AtlasTexture:
		var atlas := body.texture as AtlasTexture
		_assert_equal(atlas.atlas.resource_path, FIRE_LION_SHEET_PATH, "fire lion body uses fire_lion_run sheet")
		_assert_equal(atlas.region.position, Vector2(0, 1024), "fire lion idle frame starts from the down row")

	fire_lion.free()

func _test_world_can_spawn_fire_lion_enemy() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame

	var enemies_parent := world.get_node("Enemies")
	for child in enemies_parent.get_children():
		child.queue_free()
	await process_frame

	world.set("enemy_scene", FIRE_LION_SCENE)
	world.set("fire_lion_scene", FIRE_LION_SCENE)
	world.set("fire_lion_spawn_chance", 1.0)
	world.call("_try_spawn_enemy")
	await process_frame

	_assert_equal(enemies_parent.get_child_count(), 1, "world spawns one fire lion enemy")
	if enemies_parent.get_child_count() == 1:
		_assert_equal(enemies_parent.get_child(0).scene_file_path, FIRE_LION_SCENE.resource_path, "spawned enemy is the fire lion scene")

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
