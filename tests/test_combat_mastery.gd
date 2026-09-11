extends SceneTree
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func run() -> void:
	var world := preload("res://scenes/rebirth/Stillwater.tscn").instantiate()
	world.persist_progress = false
	root.add_child(world)
	current_scene = world
	world.start_run()
	world.set_process(false)
	var player = world.player
	player.set_physics_process(false)
	player.position = Vector3(0,0.05,4)
	var enemy := preload("res://scripts/rebirth/Duelist.gd").new()
	enemy.world = world
	enemy.kind = 1
	world.add_child(enemy)
	world.enemies.append(enemy)
	enemy.set_physics_process(false)
	enemy.position = player.position+Vector3.FORWARD*1.6
	enemy.locked = Vector3.BACK
	enemy.facing = Vector3.BACK
	await physics_frame
	player.action = "attack"
	player.timer = 0.2
	player.duration = 0.33
	player.stamina = 42
	player.immunity = 0.17
	player.parry_reward = 1.5
	player.hit_stop = 0.1
	player.posture = 30
	var before := [player.timer,player.stamina,player.immunity,player.parry_reward,player.hit_stop,player.posture,player.position]
	world.mode = "pause"
	player._physics_process(0.5)
	check(before == [player.timer,player.stamina,player.immunity,player.parry_reward,player.hit_stop,player.posture,player.position],"pause preserves every combat clock and resource")
	world.mode = "play"
	world.director.cinematic_left = 0.5
	player._physics_process(0.3)
	check(before == [player.timer,player.stamina,player.immunity,player.parry_reward,player.hit_stop,player.posture,player.position],"boss introduction freezes combat without consuming a timed reward")
	world.director.cinematic_left = 0
	player.hit_stop = 0
	player.action = "idle"
	player.immunity = 0
	player.parry_reward = 0
	player.stamina = 70
	player.guarding = true
	enemy.action = "attack"
	enemy.duration = 0.5
	enemy.timer = enemy.duration*(1-enemy.contact_fraction())+0.08
	enemy.released = false
	player.dash(Vector3.RIGHT)
	check(not player.guarding and player.pending_evades.size() == 1,"late dodge captures an actual threatening blade and exits guard")
	enemy.released = true
	player.resolve_perfect_evades()
	check(player.perfect_evade and player.stamina == 62 and player.parry_reward > 0,"a committed attack narrowly evaded restores twelve stamina and arms a counter")
	var health: float = player.hp
	player.hurt(2,enemy)
	player.resolve_perfect_evades()
	check(player.hp == health and player.stamina == 62 and world.director.stats.perfect_dodges == 1,"one dodge cannot farm rewards from overlapping attack checks")
	player.action = "idle"
	player.stamina = 70
	player.parry_reward = 0
	enemy.released = false
	enemy.timer = enemy.duration*(1-enemy.contact_fraction())+0.2
	player.dash(Vector3.RIGHT)
	enemy.released = true
	player.resolve_perfect_evades()
	check(not player.perfect_evade and player.parry_reward == 0,"an early safe dodge grants no mastery reward")
	player.action = "idle"
	player.immunity = 0
	player.guarding = true
	player.guard_time = 0.6
	player.facing = Vector3.FORWARD
	player.stamina = 8
	check(player.hurt(2,enemy) and player.action == "guard_break" and player.stamina == 0,"exhausted frontal guard causes a readable guard break")
	player.cooldown = 0
	player.stamina = 100
	player.start_attack()
	player.dash(Vector3.RIGHT)
	check(player.action == "guard_break","guard break recovery cannot be bypassed by attack or dodge spam")
	player.action = "idle"
	player.immunity = 0
	player.guarding = true
	player.guard_time = 0.1
	player.stamina = 70
	enemy.action = "attack"
	enemy.posture = 0
	check(not player.hurt(2,enemy) and player.parry_reward > 0 and enemy.posture == 55,"frontal timed guard preserves the established parry contract")
	check(world.ui.feedback.defense_kind == "parry" and world.ui.feedback.defense_remaining > 0.6,"parry has its own readable direction and timed feedback")
	enemy.action = "windup"
	enemy.timer = 0.1
	enemy.duration = 0.8
	enemy.locked = Vector3.BACK
	enemy.facing = Vector3.BACK
	player.position = enemy.position+Vector3.RIGHT
	enemy.think(0.1)
	check(enemy.locked == Vector3.BACK and enemy.facing == Vector3.BACK,"late telegraph commits to its advertised direction instead of homing")
	check(enemy.attack_profile() == "thrust" and enemy.melee_cone_dot() > 0.8 and enemy.melee_reach() > 2,"duelist thrust is longer and more precisely avoidable than a knight chop")
	enemy.action = "idle"
	enemy.apply_posture(100)
	enemy.timer = 1.4
	enemy.apply_posture(100)
	check(enemy.action == "broken" and enemy.timer == 1.4,"continued attacks do not infinitely renew an execution window")
	var boss := preload("res://scripts/rebirth/Duelist.gd").new()
	boss.world = world
	boss.boss = true
	world.add_child(boss)
	world.enemies.append(boss)
	boss.set_physics_process(false)
	boss.position = player.position+Vector3.FORWARD*2
	boss.hp = 20
	boss.kind = 2
	boss.ai_wait = 0
	boss.think(0.01)
	check(boss.attack_profile() == "pulse" and boss.duration > 1,"phase two introduces a deliberately longer radial anticipation")
	boss.action = "idle"
	boss.kind = 5
	boss.ai_wait = 0
	boss.think(0.01)
	check(boss.attack_profile() == "sweep" and boss.melee_cone_dot() < 0,"phase two also retains the learned broad sweep instead of repeating three identical threats")
	boss.posture = 0
	var committed_timer: float = boss.timer
	boss.launch(Vector3.FORWARD,14)
	check(boss.action == "windup" and boss.timer == committed_timer and boss.posture == 35,"pressure cannot erase a committed boss attack without first breaking its posture")
	boss.posture = 75
	boss.launch(Vector3.FORWARD,14)
	check(boss.action == "broken","pressure still interrupts the boss when it completes a genuine posture break")
	boss.action = "idle"
	boss.posture = 0
	boss.interrupt_resist = 2.0
	boss.apply_posture(30)
	check(is_equal_approx(boss.posture,10.5),"a recovering boss resists immediate repeat breaks while still accumulating posture")
	boss.interrupt_resist = 0
	boss.apply_posture(30)
	check(is_equal_approx(boss.posture,40.5),"full posture pressure resumes after the boss recovery window")
	world.difficulty = 1
	check(boss.recovery_scale() == 1.0,"standard preserves the established recovery rhythm")
	world.difficulty = 2
	check(boss.recovery_scale() == 0.8,"hard difficulty shortens recovery without secretly speeding up telegraphs")
	player.action = "idle"
	player.guarding = false
	player.animate(0.02)
	check(player.puppet.scarf_mesh.get_surface_count() == 1 and not player.puppet.robe_materials.is_empty(),"hero silhouette and distinct robe palette are attached to the live animated rig")
	current_scene = null
	world.queue_free()
	for i in range(3): await process_frame
	print("Combat mastery: ",failures," failures")
	quit(failures)
