extends SceneTree
## Native visual QA. The last two images deliberately inspect wider scenery;
## they are labeled studies and do not alter the shipping gameplay camera.

const OUTPUT := "res://output/atmosphere/"
var world: Node3D

func _initialize() -> void:
	call_deferred("run")

func shot(filename: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.convert(Image.FORMAT_RGBA8)
	image.save_png(OUTPUT + filename)

func run() -> void:
	root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	for action in InputMap.get_actions():
		InputMap.action_erase_events(action)
		Input.action_release(action)
	world = preload("res://scenes/rebirth/Stillwater.tscn").instantiate()
	world.persist_progress = false
	root.add_child(world)
	current_scene = world
	world.set_process_unhandled_input(false)
	await create_timer(2.0).timeout
	await shot("01-title.png")
	world.start_run()
	await create_timer(2.0).timeout
	await shot("02-court.png")
	print("NATIVE_COURT fps=", Engine.get_frames_per_second(), " draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), " primitives=", Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME), " nodes=", Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	world.player.position = world.seals[0].position + Vector3(1.8, 0.05, 1.2)
	world.interact()
	world.spawn_timer = 30.0
	await create_timer(1.5).timeout
	await shot("03-active-seal.png")
	world.ui.visible = false
	world.complete_seal()
	await create_timer(0.6).timeout
	await shot("04-completion-bloom.png")
	world.set_process(false)
	world.camera.position = Vector3(23, 19, 20)
	world.camera.look_at(Vector3(0, 0, -3), Vector3.UP)
	world.camera.size = 29.0
	await create_timer(0.7).timeout
	await shot("05-lower-angle-study.png")
	world.camera.position = Vector3(25, 27, 28)
	world.camera.look_at(Vector3(-3, 0, -7), Vector3.UP)
	world.camera.size = 44.0
	await create_timer(0.7).timeout
	await shot("06-landscape-study.png")
	print("NATIVE_LANDSCAPE fps=", Engine.get_frames_per_second(), " draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), " primitives=", Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	# Controlled light/framing comparisons; this script never saves game settings.
	world.mode = "title"
	world.ui.visible = true
	world.ui.show_title()
	world.ambient_environment.ambient_light_color = Color("779bb0")
	world.ambient_environment.ambient_light_energy = 0.52
	world.key_light.light_color = Color("ffdab0")
	world.key_light.light_energy = 1.10
	world.camera.position = Vector3(20, 19, 19)
	world.camera.look_at(Vector3(0, 0, -1), Vector3.UP)
	world.camera.size = 26.0
	await create_timer(0.6).timeout
	await shot("07-title-lighting-study.png")
	world.camera.position = Vector3(19, 19, 16)
	world.camera.look_at(Vector3(-1, 2, -4), Vector3.UP)
	world.camera.size = 27.0
	await create_timer(0.6).timeout
	await shot("08-title-depth-study.png")
	world.mode = "play"
	world.ui.clear_modal()
	world.camera.position = world.player.position + Vector3(16, 22, 16)
	world.camera.look_at(world.player.position, Vector3.UP)
	world.camera.size = 13.8
	world.ui.toast_timer = 0
	await create_timer(0.8).timeout
	await shot("09-court-lighting-study.png")
	world.queue_free()
	await process_frame
	quit()
