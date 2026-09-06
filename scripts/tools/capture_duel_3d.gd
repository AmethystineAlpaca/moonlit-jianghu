extends SceneTree
var frame := 0
var world: Node3D
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size = Vector2i(1280,720)
	world = preload("res://scenes/rebirth/Stillwater.tscn").instantiate()
	world.persist_progress = false
	root.add_child(world)
	current_scene = world
	world.start_run()
	world.player.position = Vector3(0,0.05,3)
	world.begin_boss()
	world.boss_node.position = Vector3(0,0.05,0)
	world.ui.toast_timer = 0
	process_frame.connect(step)
func step() -> void:
	frame += 1
	if world.player.action == "idle": world.player.facing = (world.boss_node.position-world.player.position).normalized()
	if frame == 25:
		Input.action_press("move_up")
		Input.action_press("move_right")
	if frame == 38:
		Input.action_release("move_up")
		Input.action_release("move_right")
		Input.action_press("attack")
	if frame == 80:
		Input.action_release("attack")
		Input.action_press("move_right")
		Input.action_press("dash")
	if frame == 82: Input.action_release("dash")
	if frame == 100:
		Input.action_release("move_right")
		world.cast(0)
	if frame == 130:
		world.player.weapon = 1
		world.player.make_weapon()
		Input.action_press("move_left")
	if frame == 150:
		Input.action_release("move_left")
		Input.action_press("attack")
	if frame == 190:
		Input.action_release("attack")
		world.cast(1)
	if frame == 220:
		world.player.weapon = 2
		world.player.make_weapon()
		Input.action_press("attack")
	if frame == 290:
		print("3D duel performance FPS: ",Engine.get_frames_per_second()," objects: ",Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	if frame == 300:
		for action in ["attack","move_left","move_right"]: Input.action_release(action)
		root.get_node("Soundscape").shutdown()
