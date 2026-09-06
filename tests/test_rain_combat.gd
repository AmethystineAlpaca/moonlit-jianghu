extends SceneTree
var failures := 0
func check(value: bool, text: String) -> void:
	if not value:
		failures += 1
		push_error(text)
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
	var enemy := preload("res://scripts/rebirth/Duelist.gd").new()
	enemy.world = world
	enemy.kind = 1
	enemy.position = Vector3(0,0.05,-1.5)
	world.add_child(enemy)
	world.enemies.append(enemy)
	enemy.set_physics_process(false)
	await physics_frame
	await physics_frame
	player.facing = Vector3.FORWARD
	var before: float = enemy.hp
	Input.action_press("attack")
	var ticks := 0
	while ticks < 10 and enemy.hp == before:
		await physics_frame
		ticks += 1
	Input.action_release("attack")
	print("Input-to-contact physics ticks: ",ticks)
	check(ticks <= 7 and enemy.hp < before,"straight sword contacts within roughly 100 ms of input")
	check(player.puppet.animation != null and player.puppet.skeleton.get_bone_count() > 20,"combat uses an actual animated skeleton")
	player.set_physics_process(false)
	player.position = Vector3(-3,0.05,3)
	player.action = "idle"
	player.stamina = 100
	world.leave_echo()
	player.position = Vector3(3,0.05,3)
	enemy.position = Vector3(0,0.05,3)
	enemy.immunity = 0
	before = enemy.hp
	world.cast(0)
	check(player.action == "recall" and world.echo == null,"recall consumes the echo and starts a return move")
	check(enemy.hp < before and enemy.posture >= 42,"recall cuts targets across the actual return line")
	player.action = "idle"
	player.stamina = 100
	world.skill_cooldowns[0] = 0
	world.cast(0)
	check(player.stamina == 100,"a missing echo does not consume a skill cost")
	enemy.hp = enemy.max_hp
	enemy.dead = false
	enemy.posture = 0
	enemy.position = player.position+Vector3(0,0,-2)
	player.facing = Vector3.FORWARD
	enemy.immunity = 0
	world.cast(1)
	check(enemy.action == "launch" and enemy.knockback.length() >= 13,"pressure attack launches an enemy visibly")
	enemy.apply_posture(100)
	check(enemy.action == "broken","posture creates a distinct execution opportunity")
	check(world.try_execute() and enemy.dead,"execution finishes a broken ordinary enemy")
	var caster := preload("res://scripts/rebirth/Duelist.gd").new()
	caster.world = world
	caster.kind = 2
	caster.position = player.position+Vector3(0,0,-4)
	world.add_child(caster)
	world.enemies.append(caster)
	caster.set_physics_process(false)
	var bolt := preload("res://scripts/rebirth/SpiritBolt.gd").new()
	bolt.world = world
	bolt.source = caster
	bolt.position = player.position+Vector3(0,0.8,-0.3)
	bolt.direction = Vector3.BACK
	world.add_child(bolt)
	player.guarding = true
	player.guard_time = 0.1
	player.facing = Vector3.FORWARD
	bolt._physics_process(0.01)
	check(bolt.reflected,"a timed guard reflects a projectile instead of only absorbing damage")
	var victim := preload("res://scripts/rebirth/Duelist.gd").new()
	victim.world = world
	victim.kind = 1
	victim.position = Vector3(6,0.05,5)
	world.add_child(victim)
	world.enemies.append(victim)
	var wall := StaticBody3D.new()
	wall.position = Vector3(6,1,2)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2,2,0.2)
	shape.shape = box
	wall.add_child(shape)
	world.add_child(wall)
	await physics_frame
	victim.launch(Vector3.FORWARD,14)
	before = victim.hp
	for i in range(25): await physics_frame
	check(victim.position.z < 3.5 and victim.collision_hit and victim.hp < before,"launch visibly travels and an actual wall collision deals impact damage")
	player.position = Vector3(8,0.05,8)
	player.action = "idle"
	player.stamina = 100
	world.leave_echo()
	player.position = Vector3(10.5,0.05,8)
	player.guarding = false
	world.skill_cooldowns[0] = 0
	world.cast(0)
	player.set_physics_process(true)
	for i in range(25): await physics_frame
	player.set_physics_process(false)
	check(player.position.distance_to(Vector3(8,0.05,8)) < 0.25,"recall movement returns to its marker without overshooting")
	current_scene = null
	world.queue_free()
	for i in range(3): await process_frame
	print("Rain combat: ",failures," failures")
	quit(failures)
