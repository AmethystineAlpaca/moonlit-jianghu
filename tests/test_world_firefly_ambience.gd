extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/World.tscn")
const REQUIRED_ASSET_PATHS := [
	"res://assets/xianxia/pixel_night_assets/firefly_dot.png",
	"res://assets/xianxia/pixel_night_assets/sparkle_blue.png",
	"res://assets/xianxia/pixel_night_assets/moonlight_patch.png",
	"res://assets/xianxia/pixel_night_assets/light_circle.png",
]

var failures := 0

func _initialize() -> void:
	_test_required_night_assets_exist()
	await _test_world_creates_night_ambience_controller()
	await _test_controller_owns_expected_layer_groups()
	await _test_screen_fx_stays_outside_hud_canvas_layer()
	await _test_particle_and_patch_layers_are_populated()
	await _test_world_keeps_glow_environment_under_night_ambience()
	await _test_world_enemy_instances_have_accent_lights()
	quit(failures)

func _test_required_night_assets_exist() -> void:
	for path in REQUIRED_ASSET_PATHS:
		_assert_true(ResourceLoader.exists(path), "required night ambience asset exists: %s" % path)

func _test_world_creates_night_ambience_controller() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame

	var ambience := world.get_node_or_null("NightAmbience")
	_assert_true(ambience is Node2D, "world creates NightAmbience controller")

	world.free()

func _test_controller_owns_expected_layer_groups() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame

	var ambience := world.get_node_or_null("NightAmbience")
	_assert_true(ambience != null, "NightAmbience exists for layer ownership test")
	if ambience != null:
		for path in [
			"NightEnvironment",
			"NightModulate",
			"FireflyLights",
			"WorldEffects",
			"WorldEffects/FireflyParticles",
			"WorldEffects/SparkleParticles",
			"WorldEffects/MoonlightPatches",
			"ScreenFx",
			"ScreenFx/Vignette",
		]:
			_assert_true(ambience.get_node_or_null(path) != null, "NightAmbience has %s" % path)

	world.free()

func _test_screen_fx_stays_outside_hud_canvas_layer() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame

	var hud := world.get_node_or_null("Hud")
	var night_mod := world.get_node_or_null("NightAmbience/NightModulate")
	var vignette := world.get_node_or_null("NightAmbience/ScreenFx/Vignette")
	_assert_true(hud is CanvasLayer, "HUD remains a CanvasLayer")
	_assert_true(night_mod is CanvasModulate, "NightModulate is a CanvasModulate node")
	if hud != null:
		if night_mod != null:
			_assert_true(not hud.is_ancestor_of(night_mod), "NightModulate is not parented under HUD")
		if vignette != null:
			_assert_true(not hud.is_ancestor_of(vignette), "Vignette is not parented under HUD")

	world.free()

func _test_particle_and_patch_layers_are_populated() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame
	await process_frame

	var fireflies := world.get_node_or_null("NightAmbience/WorldEffects/FireflyParticles") as GPUParticles2D
	var sparkles := world.get_node_or_null("NightAmbience/WorldEffects/SparkleParticles") as GPUParticles2D
	var patches := world.get_node_or_null("NightAmbience/WorldEffects/MoonlightPatches") as Node2D
	_assert_true(fireflies != null, "firefly layer exists")
	_assert_true(sparkles != null, "sparkle layer exists")
	_assert_true(patches != null, "moonlight patch layer exists")
	if fireflies != null:
		_assert_true(fireflies.amount >= 40, "firefly layer is visibly populated")
		_assert_true(fireflies.emitting, "firefly layer emits in night state")
	if sparkles != null:
		_assert_true(sparkles.amount >= 12, "sparkle layer is visibly populated")
		_assert_true(sparkles.amount < fireflies.amount, "sparkle layer stays sparser than fireflies")
	if patches != null:
		_assert_true(patches.get_child_count() >= 3, "moonlight patches create visible breakup")
		_assert_true(patches.get_child_count() <= 6, "moonlight patches stay sparse")

	world.free()

func _test_world_keeps_glow_environment_under_night_ambience() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame

	var world_env := world.get_node_or_null("NightAmbience/NightEnvironment") as WorldEnvironment
	_assert_true(world_env != null, "NightEnvironment exists")
	if world_env != null and world_env.environment != null:
		_assert_true(world_env.environment.glow_enabled, "night environment enables glow")
		_assert_true(world_env.environment.glow_intensity >= 0.35, "night glow intensity is meaningful")

	world.free()

func _test_world_enemy_instances_have_accent_lights() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame

	var enemies := world.get_node_or_null("Enemies")
	_assert_true(enemies != null, "Enemies container exists")
	if enemies != null:
		world.call("_try_spawn_enemy")
		await process_frame
		var found_light := false
		for child in enemies.get_children():
			if child.get_node_or_null("EnemyAccentLight") is PointLight2D:
				found_light = true
				break
		_assert_true(found_light, "spawned enemies expose EnemyAccentLight")

	world.free()

func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	failures += 1
	push_error(message)
