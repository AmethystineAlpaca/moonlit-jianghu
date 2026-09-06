extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	var im := root.get_texture().get_image()
	im.convert(Image.FORMAT_RGBA8)
	im.save_png(path)
func run() -> void:
	root.size = Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://output/rebirth"))
	var world := preload("res://scenes/rebirth/Stillwater.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	await create_timer(2.0).timeout
	await shot("res://output/rebirth/01-title.png")
	world.start_run()
	await create_timer(2.0).timeout
	await shot("res://output/rebirth/02-court.png")
	world.player.position = Vector3(-10,0.05,-5)
	await create_timer(1.0).timeout
	world.interact()
	await create_timer(2.0).timeout
	await shot("res://output/rebirth/03-seal.png")
	world.mode = "pause"
	world.ui.show_pause()
	await create_timer(0.2).timeout
	await shot("res://output/rebirth/04-pause.png")
	root.get_node("Soundscape").shutdown()
