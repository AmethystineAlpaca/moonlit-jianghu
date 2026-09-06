extends SceneTree
var frame := 0
var world: Node3D
var enemy: Node3D
var guard_until := 0
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(1280,720)
	world = preload("res://scenes/rebirth/Stillwater.tscn").instantiate()
	world.persist_progress = false
	root.add_child(world)
	current_scene = world
	world.start_run()
	world.set_process_unhandled_input(false)
	for action in InputMap.get_actions():
		InputMap.action_erase_events(action)
		Input.action_release(action)
	world.player.position = Vector3(0,0.05,3)
	enemy = preload("res://scripts/rebirth/Duelist.gd").new()
	enemy.world = world
	enemy.kind = 1
	enemy.position = Vector3(0,0.05,1.2)
	world.add_child(enemy)
	world.enemies.append(enemy)
	world.ui.toast_timer = 0
	process_frame.connect(step)
func step() -> void:
	frame += 1
	world.player.facing = (enemy.position-world.player.position).normalized()
	if frame > 105 and enemy.action == "attack" and enemy.timer < 0.46 and not enemy.released and guard_until < frame:
		Input.action_press("defend")
		guard_until = frame+8
	if frame == guard_until: Input.action_release("defend")
	if frame == 240: Input.action_press("attack")
	if frame == 295: Input.action_release("attack")
	if frame == 320: Input.action_press("dash")
	if frame == 322: Input.action_release("dash")
	if frame == 350: world.cast(0)
	if frame == 400:
		print("Feedback capture HP: ",world.player.hp)
		root.get_node("Soundscape").shutdown()
