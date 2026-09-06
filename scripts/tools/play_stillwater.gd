extends SceneTree
var world: Node3D
var tick := 0
var next_dodge := 0
func _initialize() -> void:
	call_deferred("run")
func key(code: int) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	world._unhandled_input(event)
func move(direction: Vector3) -> void:
	var local := direction.rotated(Vector3.UP,-PI/4)
	for action in ["move_left","move_right","move_up","move_down"]: Input.action_release(action)
	if local.x > 0.2: Input.action_press("move_right",absf(local.x))
	if local.x < -0.2: Input.action_press("move_left",absf(local.x))
	if local.z > 0.2: Input.action_press("move_down",absf(local.z))
	if local.z < -0.2: Input.action_press("move_up",absf(local.z))
func run() -> void:
	world = preload("res://scenes/rebirth/Stillwater.tscn").instantiate()
	world.persist_progress = false
	root.add_child(world)
	current_scene = world
	world.start_run()
	key(KEY_2)
	Engine.time_scale = 3
	while world.run_time < 180 and world.mode != "victory" and world.mode != "defeat":
		await physics_frame
		tick += 1
		Input.action_release("dash")
		if world.mode == "upgrade":
			world.upgrade(0)
			continue
		var player = world.player
		var target: Node3D
		var distance := INF
		for enemy in world.enemies:
			if is_instance_valid(enemy) and not enemy.dead:
				var d: float = enemy.position.distance_to(player.position)
				if d < distance:
					distance = d
					target = enemy
		if target != null:
			var direction: Vector3 = (target.position-player.position).normalized()
			var screen: Vector2 = world.camera.unproject_position(target.position+Vector3.UP)
			var mouse := InputEventMouseMotion.new()
			mouse.position = screen
			if DisplayServer.get_name() != "headless": Input.parse_input_event(mouse)
			if distance > 1.7:
				move(direction)
			else:
				move(Vector3.ZERO)
				player.facing = direction
			if distance < 2.3: Input.action_press("attack")
			else: Input.action_release("attack")
			if target.action == "windup" and target.timer < 0.26 and tick > next_dodge:
				move(direction.rotated(Vector3.UP,PI/2))
				Input.action_press("dash")
				next_dodge = tick+30
			if player.stamina > 55:
				if distance < 3.5: key(KEY_E)
				if is_instance_valid(world.echo) and distance > 2.5: key(KEY_Q)
			if target.action == "broken" and distance < 3: key(KEY_F)
		else:
			Input.action_release("attack")
			var seal: Node3D
			for i in range(3):
				if not world.seal_done[i]:
					seal = world.seals[i]
					break
			if seal != null:
				move((seal.position-player.position).normalized())
				if world.nearest_seal() >= 0:
					move(Vector3.ZERO)
					key(KEY_F)
		if player.hp <= 6: key(KEY_R)
		if tick % 600 == 0: print("Playtest ",world.run_time,"s seals ",world.round_index," hp ",player.hp," kills ",world.kills)
	print("PLAYTEST_RESULT ",JSON.stringify({"mode":world.mode,"seconds":world.run_time,"hp":world.player.hp,"seals":world.round_index,"kills":world.kills,"wine":world.heal_count}))
	Engine.time_scale = 1
	for action in ["move_left","move_right","move_up","move_down","attack","dash"]: Input.action_release(action)
	current_scene = null
	world.queue_free()
	await process_frame
	quit()
