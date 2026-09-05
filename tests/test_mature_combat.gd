extends SceneTree
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func run() -> void:
	var world := preload("res://scenes/world/World.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	world.set_process(false)
	world.get_node("GameFeel").persist_progress = false
	var player := world.get_node("Player")
	player.set_physics_process(false)
	await physics_frame
	await physics_frame
	check(player.get_skill_slot_names().size() == 5 and not player.get_skill_slot_names().has("Empty"), "all five slots are playable")
	var health: HealthComponent = player.health_component
	player.dash_timer = 0.1
	player.apply_incoming_damage(2)
	check(health.current_health == health.max_health, "dash avoids incoming damage")
	player.dash_timer = 0.0
	player.apply_incoming_damage(2)
	player.apply_incoming_damage(2)
	check(health.current_health == health.max_health - 2, "damage grace period prevents stacked hits")
	player._set_stamina(10.0)
	check(player.skill_caster.try_cast_slot(4), "renewal casts while injured")
	check(health.current_health == health.max_health, "renewal restores health")
	check(is_equal_approx(player.current_stamina, 7.0), "successful renewal pays cost once")
	check(not player.skill_caster.try_cast_slot(4), "cooldown blocks repeated casts")
	player.skill_caster.cooldowns[4] = 0.0
	check(not player.skill_caster.try_cast_slot(4), "full health renewal fails")
	check(is_equal_approx(player.current_stamina, 7.0), "failed skill refunds cost")
	check(player.skill_caster.cooldowns[4] == 0.0, "failed skill does not consume cooldown")
	player._set_stamina(10.0)
	for i in range(3):
		player.melee_timer = 0.0
		player._try_melee_attack()
	check(player.combo_step == 3, "three attacks reach finisher")
	player.combo_timer = 0.0
	player.melee_timer = 0.0
	player._try_melee_attack()
	check(player.combo_step == 1, "expired combo starts fresh")
	paused = true
	player._apply_hit_pause()
	check(paused, "hit feedback preserves menu pause")
	paused = false
	var enemy := preload("res://scenes/enemies/BasicEnemy.tscn").instantiate()
	world.get_node("Enemies").add_child(enemy)
	enemy.global_position = player.global_position + Vector2(55, 0)
	enemy.set_physics_process(false)
	player.last_facing_direction = Vector2.RIGHT
	await physics_frame
	await physics_frame
	var enemy_health := enemy.get_node("HealthComponent") as HealthComponent
	var before := enemy_health.current_health
	player._set_stamina(10.0)
	check(player.skill_caster.try_cast_slot(2), "moon cleave casts")
	await create_timer(0.2).timeout
	check(enemy_health.current_health < before, "moon cleave damages a forward target")

	var feel := world.get_node("GameFeel")
	while feel.kills < feel.GOAL:
		var target := preload("res://scenes/enemies/BasicEnemy.tscn").instantiate()
		world.get_node("Enemies").add_child(target)
		target.set_physics_process(false)
		feel._observe_enemies()
		target.get_node("HealthComponent").take_damage(100)
		await process_frame
		if is_instance_valid(feel.upgrade_panel):
			feel.upgrade_panel.select(0)
	await process_frame
	check(feel.boss_spawned and is_instance_valid(feel.boss_node), "24 defeated enemies summon the final boss")
	check(not feel.completed, "the journey requires defeating the final boss")
	feel.boss_node.health.take_damage(100)
	check(feel.completed, "defeating the final boss completes the journey")
	check(feel.result_panel != null, "completion exposes a restart panel")
	for target in get_nodes_in_group("hostile_enemies"):
		check(not target.is_physics_processing(), "victory stops remaining hostile attacks")
	await create_timer(0.8).timeout
	current_scene = null
	world.queue_free()
	await process_frame
	await process_frame
	print("Combat integration: ", failures, " failures")
	quit(failures)
