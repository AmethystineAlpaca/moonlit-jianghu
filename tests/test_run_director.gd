extends SceneTree
var failures := 0
var world: Node3D
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	if value: return
	failures += 1
	push_error(message)
func dummy(at: Vector3) -> Node3D:
	var enemy := preload("res://scripts/rebirth/Duelist.gd").new()
	enemy.world = world
	enemy.kind = 1
	enemy.position = at
	world.add_child(enemy)
	world.enemies.append(enemy)
	enemy.set_physics_process(false)
	enemy.max_hp = 100
	enemy.hp = 100
	return enemy
func run() -> void:
	world = preload("res://scenes/rebirth/Stillwater.tscn").instantiate()
	world.persist_progress = false
	root.add_child(world)
	current_scene = world
	world.start_run()
	world.player.set_physics_process(false)
	world.player.position = Vector3(4,0.05,4)
	var enemy := dummy(Vector3(4,0.05,1.5))
	await physics_frame
	var director = world.director
	world.player.guarding = false
	world.player.immunity = 0
	world.player.hurt(2,enemy)
	check(director.stats.damage_taken == 2 and world.player.hp == 10,"actual incoming damage is counted once and standard difficulty preserves damage")
	world.difficulty = 0
	world.player.immunity = 0
	world.player.hurt(2,enemy)
	check(is_equal_approx(world.player.hp,8.56),"story difficulty scales damage without changing combat input windows")
	world.difficulty = 1
	director.flow = 0
	world.player.action = "idle"
	world.player.stamina = 100
	world.activate_surge()
	check(director.surge_left == 0 and world.player.stamina == 100,"unearned ultimate has no side effects")
	for i in range(5): world.combat_event("parry",world.player,enemy)
	check(director.technique_ready and director.flow == 100 and director.stats.parries == 5,"mastery fills a capped, manually triggered sword-intent meter")
	world.player.stamina = 40
	world.activate_surge()
	check(director.surge_active and director.flow == 0 and world.player.stamina == 75,"ultimate consumes full meter and grants its advertised recovery")
	world.activate_surge()
	check(director.stats.surges == 1,"holding or repeating ultimate input cannot double spend or stack")
	var before: float = enemy.hp
	for i in range(48): await physics_frame
	check(enemy.hp < before and enemy.hp >= before-7,"expanding ultimate hits a reachable target once rather than every frame")
	check(enemy.posture == 55,"ultimate creates a deliberate posture opening")
	var paused_flow: float = director.flow
	var paused_surge: float = director.surge_left
	var run_time: float = world.run_time
	world.mode = "pause"
	for i in range(8): await physics_frame
	check(director.flow == paused_flow and director.surge_left == paused_surge and world.run_time == run_time,"pause freezes run rhythm, buff duration and run clock")
	world.resume()
	world.round_index = 1
	world.seal_done[0] = true
	world.mode = "upgrade"
	world.prepare_upgrades()
	world.upgrade(2)
	check(world.director.bonuses.echo == 1 and world.player.damage_bonus == 0,"echo upgrade changes a technique instead of granting generic damage")
	world.player.action = "idle"
	world.player.position = Vector3(4,0.05,4)
	world.leave_echo()
	check(is_equal_approx(world.echo.life,6.0),"echo technique extends the actual marker lifetime")
	world.player.position.x += 3
	world.skill_cooldowns[0] = 0
	world.player.stamina = 100
	world.cast(0)
	check(is_equal_approx(world.skill_cooldowns[0],2.1),"echo technique shortens the real cooldown")
	world.director.cinematic_left = 0.4
	var bolt := preload("res://scripts/rebirth/SpiritBolt.gd").new()
	bolt.world = world
	bolt.source = enemy
	bolt.position = Vector3(5,0.8,5)
	world.add_child(bolt)
	var bolt_start: Vector3 = bolt.position
	bolt._physics_process(0.1)
	check(bolt.position == bolt_start and bolt.lifetime == 3,"cinematics also freeze projectiles so frozen players cannot be hit")
	world.director.cinematic_left = 0
	world.player.position = Vector3(-7,0.05,-4)
	world.capture_checkpoint()
	var score_at_checkpoint: int = director.score
	world.combat_event("kill",enemy,world.player)
	world.player.hp = 0
	world.player.dead = true
	world.mode = "defeat"
	world.retry_from_checkpoint()
	for i in range(5): await process_frame
	world = current_scene
	check(world.mode == "play" and world.round_index == 1 and world.seal_done == [true,false,false],"retry preserves completed seals and resumes play")
	check(not world.player.dead and world.player.hp == world.player.max_hp and world.director.bonuses.echo == 1,"retry restores the living hero and earned technique")
	check(world.director.score == score_at_checkpoint and world.director.stats.retries == 1,"checkpoint rollback prevents kill-score farming and records the retry")
	world.begin_boss()
	world.boss_node.set_physics_process(false)
	world.player.set_physics_process(false)
	world.director.cinematic_left = 0
	world.player.position = Vector3(0,0.05,0)
	world.boss_node.position = Vector3(0,0.05,-1.5)
	world.boss_node.action = "broken"
	world.boss_node.posture = 100
	world.boss_node.timer = 2
	world.player.action = "idle"
	check(world.try_execute() and not world.boss_node.dead and world.boss_node.posture == 0,"surviving boss execution empties posture instead of enabling an infinite execution loop")
	check(world.boss_node.interrupt_resist > 0,"surviving boss has a brief interval to recover its footing")
	world.player.action = "idle"
	world.player.parry_reward = 2
	world.player.locked = Vector3.FORWARD
	world.boss_node.immunity = 1
	world.melee(world.player)
	check(world.player.parry_reward == 2 and world.boss_node.posture == 0,"rejected damage does not consume a counter or grant posture through immunity")
	world.director.cinematic_left = 0
	world.boss_node.hp = world.boss_node.max_hp*0.4
	world.director.update(0.02)
	check(world.boss_phase == 2 and world.director.cinematic_left > 0,"boss phase transition has one guarded cinematic boundary")
	world.director.cinematic_left = 0
	world.director.update(0.02)
	check(world.director.cinematic_left == 0,"boss transition does not replay every frame below half health")
	current_scene = null
	world.queue_free()
	for i in range(4): await process_frame
	print("Run director: ",failures," failures")
	quit(failures)
