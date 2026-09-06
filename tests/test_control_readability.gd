extends SceneTree
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var world := preload("res://scenes/rebirth/Stillwater.tscn").instantiate()
	world.persist_progress = false
	root.add_child(world)
	current_scene = world
	world.start_run()
	var player = world.player
	player.position = Vector3(0,0.05,5)
	Input.action_press("move_right")
	for i in range(25): await physics_frame
	Input.action_release("move_right")
	var start: Vector3 = player.position
	for i in range(12): await physics_frame
	var drift: float = player.position.distance_to(start)
	print("Walk stop distance: ",drift)
	check(drift < 0.2 and player.velocity.length() < 0.01,"walking retains a short planted stop, not an extended slide")
	player.dash(Vector3.FORWARD)
	for i in range(14): await physics_frame
	start = player.position
	for i in range(15): await physics_frame
	print("Dash post-stop distance: ",player.position.distance_to(start))
	check(player.position.distance_to(start) < 0.25,"dash does not retain its 17 m/s speed into idle")
	player.hit_stop = 0.1
	start = player.position
	Input.action_press("move_left")
	for i in range(4): await physics_frame
	Input.action_release("move_left")
	check(player.position.distance_to(start) > 0.03,"hit pause still processes movement input")
	var enemy := preload("res://scripts/rebirth/Duelist.gd").new()
	enemy.world = world
	enemy.kind = 1
	enemy.position = player.position+Vector3(0,0,-1.5)
	world.add_child(enemy)
	world.enemies.append(enemy)
	enemy.set_physics_process(false)
	player.immunity = 0
	player.guarding = false
	check(player.hurt(2,enemy) and player.action == "hurt","taking damage interrupts the attack with a distinct recoil")
	check(world.ui.feedback.remaining > 0.6 and world.ui.feedback.origin == enemy.position,"damage reports direction and visible local feedback")
	enemy.action = "windup"
	enemy.duration = 0.8
	enemy.timer = 0.3
	enemy.animate(0.01)
	check(not enemy.warning.visible,"ordinary preparation no longer draws an expanding ground ring")
	enemy.action = "attack"
	enemy.duration = 0.6
	enemy.timer = 0.35
	enemy.released = false
	enemy.animate(0.01)
	check(enemy.warning.visible,"blade glint marks the final pre-contact window")
	player.set_physics_process(false)
	player.immunity = 0
	player.guarding = false
	enemy.locked = Vector3.FORWARD
	player.position = enemy.position+Vector3.RIGHT*1.5
	var hp_before: float = player.hp
	world.melee(enemy)
	check(player.hp == hp_before,"sidestepping outside the visible chop direction avoids the hit")
	player.position = enemy.position+Vector3.FORWARD*1.5
	world.melee(enemy)
	check(player.hp < hp_before,"the same chop still connects directly in front")
	player.stamina = 17
	player.weapon = 1
	player.action = "idle"
	player.cooldown = 0
	player.start_attack()
	check(player.action == "idle" and player.stamina == 17 and player.fatigue_hint > 0,"heavy attack checks its actual stamina cost and explains rejected input")
	world.queue_free()
	await process_frame
	print("Control readability: ",failures," failures")
	quit(failures)
