extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/Main.tscn")
const BASIC_ENEMY_SCENE := preload("res://scenes/enemies/BasicEnemy.tscn")
const FAST_ENEMY_SCENE := preload("res://scenes/enemies/FastEnemy.tscn")
const FIRE_LION_SCENE := preload("res://scenes/enemies/FireLionEnemy.tscn")
const ZOMBIE_SCENE := preload("res://scenes/allies/Zombie.tscn")
const OUTPUT_DIR := "res://docs/showcase/images"

var main: Node
var world: Node2D
var player: Node2D
var hud: Node

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))

	main = MAIN_SCENE.instantiate()
	root.add_child(main)
	world = main.get_node("World") as Node2D
	player = world.get_node("Player") as Node2D
	hud = world.get_node("Hud")

	await _settle()
	await _capture_day_world_overview()
	await _capture_day_combat_scene()
	await _capture_inventory_scene()
	await _capture_night_world_scene()
	await _capture_night_combat_scene()
	await _capture_character_portraits()
	quit()

func _settle() -> void:
	for _frame in range(10):
		await process_frame

func _capture_day_world_overview() -> void:
	_set_night(false)
	player.global_position = Vector2(0, 120)
	await _settle()
	_save_viewport("01-day-village.png")

func _capture_day_combat_scene() -> void:
	_set_night(false)
	player.global_position = Vector2(40, 120)
	await _place_fire_lion(Vector2(115, -8))
	await _settle()
	_save_viewport("02-day-fire-lion-encounter.png")

func _place_fire_lion(offset: Vector2) -> void:
	await _place_enemy(FIRE_LION_SCENE, offset)

func _place_enemy(scene: PackedScene, offset: Vector2) -> void:
	var enemies_parent := world.get_node("Enemies")
	for child in enemies_parent.get_children():
		child.queue_free()
	await process_frame

	var enemy := scene.instantiate() as Node2D
	enemy.global_position = player.global_position + offset
	enemies_parent.add_child(enemy)
	if enemy.has_method("set_survival_mode"):
		enemy.set_survival_mode(false)

func _capture_inventory_scene() -> void:
	_set_night(false)
	var event := InputEventAction.new()
	event.action = "toggle_inventory"
	event.pressed = true
	hud.call("_unhandled_input", event)
	await _settle()
	_save_viewport("03-inventory-overlay.png")
	get_root().get_tree().paused = false
	hud.call("_unhandled_input", event)
	await process_frame

func _capture_night_world_scene() -> void:
	_set_night(true)
	player.global_position = Vector2(-260, 120)
	await _settle()
	_save_viewport("04-night-village.png")

func _capture_night_combat_scene() -> void:
	_set_night(true)
	player.global_position = Vector2(40, 120)
	await _place_fire_lion(Vector2(115, -8))
	await _settle()
	_save_viewport("05-night-fire-lion-encounter.png")

func _capture_character_portraits() -> void:
	_set_night(false)
	await _place_enemy(BASIC_ENEMY_SCENE, Vector2(100, -8))
	await _settle()
	_save_viewport("character-bone-wanderer.png")

	_set_night(false)
	await _place_enemy(FAST_ENEMY_SCENE, Vector2(100, -8))
	await _settle()
	_save_viewport("character-ember-runner.png")

	_set_night(true)
	await _place_enemy(FIRE_LION_SCENE, Vector2(115, -8))
	await _settle()
	_save_viewport("character-fire-lion.png")

	_set_night(true)
	await _place_enemy(ZOMBIE_SCENE, Vector2(100, -8))
	await _settle()
	_save_viewport("character-green-revenant.png")

	_set_night(false)
	var enemies_parent := world.get_node("Enemies")
	for child in enemies_parent.get_children():
		child.queue_free()
	player.global_position = Vector2(0, 140)
	await _settle()
	_save_viewport("character-sword-bearer.png")

func _set_night(is_night: bool) -> void:
	var ambience := world.get_node_or_null("NightAmbience")
	if ambience != null:
		ambience.visible = is_night
	var ground := world.get_node_or_null("Ground")
	if ground != null:
		var texture_path := "res://assets/xianxia/land_night.png" if is_night else "res://assets/xianxia/land.png"
		var ground_texture := load(texture_path)
		if ground_texture != null:
			ground.texture = ground_texture
	for light_path in ["Player/PlayerLight", "Player/Sword/WeaponLight"]:
		var light := world.get_node_or_null(light_path)
		if light != null:
			light.visible = is_night

func _save_viewport(file_name: String) -> void:
	var image := root.get_texture().get_image()
	image.save_png("%s/%s" % [OUTPUT_DIR, file_name])
