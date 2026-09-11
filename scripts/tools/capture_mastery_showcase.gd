extends SceneTree
## Native rendered QA: real attack/ultimate states, plus a short frame-time sample.
var world: Node3D
var frames: Array[float] = []
var sample := false
var output := "res://output/mastery/"
func _initialize() -> void: call_deferred("run")
func _process(delta: float) -> bool:
	if sample: frames.append(delta*1000)
	return false
func shot(filename: String) -> void:
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	picture.convert(Image.FORMAT_RGBA8)
	picture.save_png(output+filename+".png")
func run() -> void:
	root.size = Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	world = preload("res://scenes/rebirth/Stillwater.tscn").instantiate()
	world.persist_progress = false
	root.add_child(world)
	current_scene = world
	world.set_process_unhandled_input(false)
	for action in InputMap.get_actions():
		InputMap.action_erase_events(action)
		Input.action_release(action)
	await create_timer(2).timeout
	await shot("01-title")
	world.start_run()
	world.player.position = Vector3(0,0.05,2)
	world.player.set_physics_process(false)
	world.ui.toast_timer = 0
	for i in range(4):
		var enemy := preload("res://scripts/rebirth/Duelist.gd").new()
		enemy.world = world
		enemy.kind = i%3
		enemy.position = Vector3(-2.2+i*1.5,0.05,-0.8-float(i%2)*1.3)
		world.add_child(enemy)
		world.enemies.append(enemy)
		enemy.set_physics_process(false)
		enemy.action = "windup"
		enemy.duration = 0.8
		enemy.timer = 0.5
		enemy.locked = (world.player.position-enemy.position).normalized()
		enemy.facing = enemy.locked
		enemy.animate(0.1)
	await create_timer(2).timeout
	world.director.flow = 100
	world.activate_surge()
	for i in range(23):
		await physics_frame
		world.player.animate(1.0/60)
	await shot("02-stillness-cut")
	await create_timer(1).timeout
	world.director.surge_left = 0
	world.player.action = "idle"
	world.player.set_physics_process(true)
	Input.action_press("attack")
	for enemy in world.enemies:
		enemy.hp = enemy.max_hp
		enemy.immunity = 0
		enemy.action = "idle"
		enemy.set_physics_process(true)
	sample = true
	await create_timer(4).timeout
	sample = false
	await shot("03-duel")
	Input.action_release("attack")
	for enemy in world.enemies:
		if is_instance_valid(enemy): enemy.queue_free()
	world.enemies.clear()
	world.player.hp = world.player.max_hp
	world.player.position = Vector3(0,0.05,2)
	world.begin_boss()
	await create_timer(0.8).timeout
	await shot("04-boss-arrival")
	await create_timer(1.2).timeout
	world.boss_node.hp = world.boss_node.max_hp*0.45
	await create_timer(0.5).timeout
	await shot("05-rising-storm")
	frames.sort()
	var total := 0.0
	for time in frames: total += time
	var metrics := {"frames":frames.size(),"mean_ms":total/maxi(frames.size(),1),"p95_ms":frames[int(frames.size()*0.95)],"render_device":RenderingServer.get_video_adapter_name(),"viewport":"1280x720","scenario":"four live enemies, held attack, native render; includes VSync"}
	var file := FileAccess.open(output+"performance.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(metrics,"  "))
	print("MASTERY_NATIVE ",JSON.stringify(metrics))
	world.queue_free()
	await process_frame
	quit()
