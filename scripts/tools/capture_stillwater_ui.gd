extends SceneTree
## Deterministic, non-persistent visual QA of every interface state.
var world: Node3D
func _initialize() -> void: call_deferred("run")
func shot(name: String) -> void:
	await create_timer(0.36).timeout
	await RenderingServer.frame_post_draw
	var im := root.get_texture().get_image()
	im.convert(Image.FORMAT_RGBA8)
	im.save_png("res://output/ui-polish/"+name+".png")
func run() -> void:
	root.size = Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://output/ui-polish"))
	world = preload("res://scenes/rebirth/Stillwater.tscn").instantiate()
	world.persist_progress = false
	root.add_child(world)
	current_scene = world
	await create_timer(1.0).timeout
	await shot("01-title")
	world.ui.show_guide()
	await shot("02-guide")
	world.start_run()
	world.ui.toast_timer = 0
	world.run_time = 75
	world.director.hints_seen["first_seal"] = true
	await shot("03-court")
	world.player.position = world.seals[0].position+Vector3(1.8,0.05,0)
	await create_timer(1.0).timeout
	await shot("04-lamp")
	world.interact()
	await create_timer(2.0).timeout
	world.director.flow = 100
	world.director.chain = 12
	world.director.chain_time = 10
	world.director.caption("见切  ·  反击时机",Color("f2d79d"))
	world.ui.toast_timer = 0
	await shot("05-combat")
	world.mode = "pause"
	world.ui.show_pause()
	await shot("06-pause")
	world.round_index = 1
	world.prepare_upgrades()
	world.mode = "upgrade"
	world.ui.show_upgrade()
	await shot("07-upgrade")
	world.run_time = 276
	world.kills = 19
	world.director.score = 4326
	world.director.best_chain = 23
	world.director.stats.parries = 7
	world.director.stats.executions = 4
	world.director.stats.recalls = 8
	world.director.stats.perfect_dodges = 5
	world.mode = "victory"
	world.ui.show_result(true)
	await shot("08-victory")
	world.mode = "defeat"
	world.ui.show_result(false)
	await shot("09-defeat")
	root.get_node("Soundscape").shutdown()
