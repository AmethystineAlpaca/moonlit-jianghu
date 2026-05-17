extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/World.tscn")
const REQUIRED_ASSET_PATHS := [
	"res://assets/xianxia/firefly_core.png",
	"res://assets/xianxia/firefly_halo.png",
	"res://assets/xianxia/crystal_sparkle.png",
	"res://assets/xianxia/gleam_star.png",
	"res://assets/xianxia/dot_variant_a.png",
	"res://assets/xianxia/dot_variant_b.png",
	"res://assets/xianxia/dot_variant_c.png",
]

var failures := 0

func _initialize() -> void:
	_test_required_ambience_assets_exist()
	await _test_world_creates_ambient_magic_controller()
	await _test_ambient_controller_has_background_layers()
	await _test_ambient_controller_spawns_hero_fireflies()
	await _test_ambient_controller_has_sparse_sparkle_layer()
	quit(failures)

func _test_required_ambience_assets_exist() -> void:
	for path in REQUIRED_ASSET_PATHS:
		_assert_true(ResourceLoader.exists(path), "required ambience asset exists: %s" % path)

func _test_world_creates_ambient_magic_controller() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame

	var controller := world.get_node_or_null("AmbientMagic")
	_assert_true(controller != null, "world creates AmbientMagic controller")
	if controller != null:
		_assert_true(controller is Node2D, "AmbientMagic controller is Node2D-based")

	world.free()

func _test_ambient_controller_has_background_layers() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame

	var controller := world.get_node_or_null("AmbientMagic")
	_assert_true(controller != null, "AmbientMagic controller exists for background layer test")
	if controller != null:
		for node_name in ["BackgroundDotsA", "BackgroundDotsB", "BackgroundDotsC", "HeroLayer", "SparkleLayer"]:
			_assert_true(controller.get_node_or_null(node_name) != null, "AmbientMagic has child %s" % node_name)

	world.free()

func _test_ambient_controller_spawns_hero_fireflies() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame
	await process_frame

	var controller := world.get_node_or_null("AmbientMagic")
	var hero_layer: Node = controller.get_node_or_null("HeroLayer") if controller != null else null
	_assert_true(hero_layer is Node2D, "HeroLayer exists")
	if hero_layer is Node2D:
		_assert_true(hero_layer.get_child_count() >= 10, "hero layer spawns a readable number of fireflies")
		for child in hero_layer.get_children():
			_assert_true(child.get_node_or_null("Core") is Sprite2D, "hero firefly has Core sprite")
			_assert_true(child.get_node_or_null("Halo") is Sprite2D, "hero firefly has Halo sprite")

	world.free()

func _test_ambient_controller_has_sparse_sparkle_layer() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame

	var controller := world.get_node_or_null("AmbientMagic")
	var sparkle_layer: Node = controller.get_node_or_null("SparkleLayer") if controller != null else null
	_assert_true(sparkle_layer is Node2D, "SparkleLayer exists")
	if sparkle_layer is Node2D:
		_assert_true(sparkle_layer.get_child_count() >= 4, "sparkle layer contains sparse accent nodes")
		_assert_true(sparkle_layer.get_child_count() <= 20, "sparkle layer stays sparse")

	world.free()

func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	failures += 1
	push_error(message)
