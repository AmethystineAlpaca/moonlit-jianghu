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
	world.start_run()
	var player = world.player
	player.position = Vector3(0,0.05,0)
	player.set_physics_process(false)
	var archer := preload("res://scripts/rebirth/Duelist.gd").new()
	archer.world = world
	archer.kind = 2
	archer.position = Vector3(0,0.05,-5)
	world.add_child(archer)
	world.enemies.append(archer)
	archer.set_physics_process(false)
	archer.locked = Vector3.BACK
	await physics_frame
	world.melee(archer)
	for i in range(60): await physics_frame
	check(player.hp < player.max_hp,"ranged guardian launches a projectile that can hit")
	player.hp = player.max_hp-5
	world.heal()
	check(player.hp == player.max_hp and world.heal_count == 2,"wine heals and consumes one charge")
	world.heal()
	check(world.heal_count == 2,"wine is preserved when already healthy")
	player.immunity = 0
	archer.position = player.position+Vector3(0,0,-1.5)
	archer.immunity = 0
	player.weapon = 1
	player.locked = Vector3.FORWARD
	world.melee(player)
	check(archer.action == "stunned","heavy blade interrupts ordinary guardians")
	player.stamina = 100
	world.cast(1)
	check(world.skill_cooldowns[1] > 0 and player.stamina == 76,"burst has a cooldown and a stamina cost")
	world.cast(1)
	check(player.stamina == 76,"repeated skill input does not charge twice")
	world.begin_boss()
	world.boss_node.set_physics_process(false)
	world.boss_node.hp = 20
	world.boss_node.kind = 2
	world.boss_node.position = player.position+Vector3(0,0,-2)
	world.boss_node.action = "idle"
	world.boss_node.ai_wait = 0
	world.boss_node.think(0.01)
	check(world.boss_node.action == "windup" and world.boss_node.duration > 1,"second phase radial attack has a longer warning")
	world.boss_node.animate(0.01)
	check(world.boss_node.pulse_warning.visible,"second phase warning shows its actual radial area")
	current_scene = null
	world.queue_free()
	for i in range(3): await process_frame
	print("Stillwater combat: ",failures," failures")
	quit(failures)
