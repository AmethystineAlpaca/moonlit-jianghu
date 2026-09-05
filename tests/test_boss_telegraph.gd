extends SceneTree
var failures := 0
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var host := Node2D.new()
	root.add_child(host)
	current_scene = host
	var player := preload("res://scenes/player/Player.tscn").instantiate()
	host.add_child(player)
	player.position = Vector2(160,0)
	player.set_physics_process(false)
	var boss := preload("res://scenes/boss/MountainGuardian.tscn").instantiate()
	host.add_child(boss)
	boss.set_physics_process(false)
	boss.timer = 0
	boss._physics_process(0.016)
	check(boss.state == "windup" and boss.is_winding_up, "charge is announced before release")
	var locked: Vector2 = boss.direction
	player.position = Vector2(0,160)
	boss._physics_process(0.3)
	check(boss.direction == locked, "telegraphed charge does not track a dodging player")
	check(boss.state == "windup", "warning lasts long enough to react")
	boss._physics_process(0.7)
	check(boss.state == "charge", "charge releases after warning")
	boss.state = "approach"
	boss.attack_index = 2
	boss.timer = 0
	boss._physics_process(0.016)
	check(boss.state == "pulse_windup", "third attack changes to a radial warning")
	boss.health.take_damage(100)
	check(not boss.is_attack_target_active(), "dead boss cannot remain an active target")
	current_scene = null
	host.queue_free()
	await process_frame
	quit(failures)
