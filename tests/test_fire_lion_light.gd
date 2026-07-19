extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/World.tscn")
const FIRE_LION_SCENE := preload("res://scenes/enemies/FireLionEnemy.tscn")

var failures := 0

func _initialize() -> void:
	await _test_fire_lion_light_is_warm_and_broad_at_night()
	await _test_fire_lion_light_dims_in_daylight()
	await _test_fire_lion_light_flickers_over_time()
	await _test_fire_lion_corpse_light_goes_dark()
	quit(failures)

func _test_fire_lion_light_is_warm_and_broad_at_night() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame

	var enemy := FIRE_LION_SCENE.instantiate()
	world.get_node("Enemies").add_child(enemy)
	await process_frame

	var light := enemy.get_node("EnemyAccentLight") as PointLight2D
	_assert_true(light != null, "fire lion exposes an accent light")
	if light != null:
		_assert_true(light.texture_scale >= 4.4, "fire lion light uses a much broader soft radius")
		_assert_true(light.energy >= 0.72, "fire lion light is strongly bright at night")
		_assert_true(light.color.r >= light.color.g and light.color.g > light.color.b, "fire lion light stays in warm orange-yellow range")

	world.free()

func _test_fire_lion_light_dims_in_daylight() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame

	var enemy := FIRE_LION_SCENE.instantiate()
	world.get_node("Enemies").add_child(enemy)
	await process_frame

	var light := enemy.get_node("EnemyAccentLight") as PointLight2D
	var night_energy := light.energy if light != null else 0.0
	var ambience := world.get_node("NightAmbience")
	ambience.visible = false
	await process_frame

	if light != null:
		_assert_true(light.energy < night_energy * 0.5, "fire lion light becomes much weaker in daylight")

	world.free()

func _test_fire_lion_light_flickers_over_time() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame

	var enemy := FIRE_LION_SCENE.instantiate()
	world.get_node("Enemies").add_child(enemy)
	await process_frame

	var light := enemy.get_node("EnemyAccentLight") as PointLight2D
	_assert_true(light != null, "fire lion light exists for flicker test")
	if light != null:
		var start_color := light.color
		var start_energy := light.energy
		enemy.call("_update_fire_lion_light", 0.21)
		enemy.call("_update_fire_lion_light", 0.19)
		_assert_true(start_color != light.color or not is_equal_approx(start_energy, light.energy), "fire lion light shifts color or energy over time")

	world.free()

func _test_fire_lion_corpse_light_goes_dark() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame

	var enemy := FIRE_LION_SCENE.instantiate()
	world.get_node("Enemies").add_child(enemy)
	await process_frame

	var health := enemy.get_node("HealthComponent") as HealthComponent
	health.take_damage(health.max_health)
	await process_frame

	var light := enemy.get_node("EnemyAccentLight") as PointLight2D
	_assert_true(light != null, "fire lion corpse still has an accent light")
	if light != null:
		_assert_true(not light.visible, "fire lion corpse turns its light off after death")

	world.free()

func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	failures += 1
	push_error(message)
