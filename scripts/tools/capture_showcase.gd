extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/Main.tscn")
const FIRE_LION_SCENE := preload("res://scenes/enemies/FireLionEnemy.tscn")
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
	await _capture_world_overview()
	await _capture_combat_scene()
	await _capture_inventory_scene()
	await _capture_night_scene()
	quit()

func _settle() -> void:
	for _frame in range(10):
		await process_frame

func _capture_world_overview() -> void:
	player.global_position = Vector2(0, 120)
	await _settle()
	_save_viewport("01-world-overview.png")

func _capture_combat_scene() -> void:
	player.global_position = Vector2(40, 120)
	var enemies_parent := world.get_node("Enemies")
	for child in enemies_parent.get_children():
		child.queue_free()
	await process_frame

	var fire_lion := FIRE_LION_SCENE.instantiate() as Node2D
	fire_lion.global_position = player.global_position + Vector2(115, -8)
	enemies_parent.add_child(fire_lion)
	if fire_lion.has_method("set_survival_mode"):
		fire_lion.set_survival_mode(false)
	await _settle()
	_save_viewport("02-fire-lion-encounter.png")

func _capture_inventory_scene() -> void:
	var event := InputEventAction.new()
	event.action = "toggle_inventory"
	event.pressed = true
	hud.call("_unhandled_input", event)
	await _settle()
	_save_viewport("03-inventory-overlay.png")
	get_root().get_tree().paused = false

func _capture_night_scene() -> void:
	var ambience := world.get_node_or_null("NightAmbience")
	if ambience != null:
		ambience.visible = true
	var ground := world.get_node_or_null("Ground")
	if ground != null:
		var night_texture := load("res://assets/xianxia/land_night.png")
		if night_texture != null:
			ground.texture = night_texture
	player.global_position = Vector2(-260, 120)
	await _settle()
	_save_viewport("04-night-village.png")

func _save_viewport(file_name: String) -> void:
	var image := root.get_texture().get_image()
	image.save_png("%s/%s" % [OUTPUT_DIR, file_name])
