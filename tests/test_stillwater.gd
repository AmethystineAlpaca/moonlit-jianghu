extends SceneTree
var failures := 0
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var world := preload("res://scenes/rebirth/Stillwater.tscn").instantiate()
	world.persist_progress = false
	root.add_child(world)
	current_scene = world
	await process_frame
	check(world.mode == "title" and world.ui.modal != null,"game starts in its live title")
	world.start_run()
	check(world.mode == "play" and world.ui.modal == null,"start enters the 3D courtyard")
	var player = world.player
	var start: Vector3 = player.position
	Input.action_press("move_right")
	for i in range(15): await physics_frame
	Input.action_release("move_right")
	check(player.position.distance_to(start) > 0.3,"camera relative movement responds to input")
	player.stamina = 100
	player.start_attack()
	check(player.action == "attack" and not player.released,"attacks begin with anticipation")
	player.dash(Vector3.RIGHT)
	check(player.action == "dash" and player.immunity > 0,"dash cancels windup and grants immunity")
	for i in range(20): await physics_frame
	var enemy := preload("res://scripts/rebirth/Duelist.gd").new()
	enemy.world = world
	enemy.position = player.position+Vector3(0,0,-1.2)
	world.add_child(enemy)
	world.enemies.append(enemy)
	enemy.set_physics_process(false)
	player.facing = Vector3.FORWARD
	player.locked = Vector3.FORWARD
	var before: float = enemy.hp
	world.melee(player)
	check(enemy.hp < before,"a melee strike damages a forward opponent")
	player.immunity = 0
	player.guarding = true
	player.guard_time = 0.1
	player.stamina = 100
	var health: float = player.hp
	player.hurt(2,enemy)
	check(player.hp == health and player.parry_reward > 0,"timed frontal guard rewards a parry")
	player.guarding = false
	world.mode = "pause"
	var old_position: Vector3 = player.position
	Input.action_press("move_left")
	for i in range(8): await physics_frame
	Input.action_release("move_left")
	check(player.position == old_position,"pause freezes gameplay")
	world.resume()
	enemy.dead = true
	enemy.queue_free()
	await process_frame
	player.set_physics_process(false)
	for i in range(3):
		player.position = world.seals[i].position+Vector3(1.5,0.05,0)
		world.interact()
		check(world.encounter and world.spawn_queue > 0,"each seal starts an encounter")
		world.spawn_queue = 0
		world.complete_seal()
		if i < 2:
			check(world.mode == "upgrade","cleared seals offer a build choice")
			world.upgrade(i)
	check(world.round_index == 3 and is_instance_valid(world.boss_node),"third seal summons the final duelist")
	world.boss_node.set_physics_process(false)
	world.boss_node.timer = 0
	world.boss_node.action = "idle"
	world.boss_node.ai_wait = 0
	world.boss_node.position = player.position+Vector3(0,0,-1.8)
	world.boss_node.think(0.02)
	check(world.boss_node.action == "windup","boss warns before striking")
	world.boss_node.immunity = 0
	world.boss_node.hurt(100,player)
	check(world.mode == "victory","defeating the boss resolves the journey")
	current_scene = null
	world.queue_free()
	for i in range(3): await process_frame
	print("Stillwater integration: ",failures," failures")
	quit(failures)
