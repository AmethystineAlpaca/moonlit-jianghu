extends SceneTree
var frame := 0
var world: Node3D
func _initialize() -> void: call_deferred("run")
func run() -> void:
	for action in InputMap.get_actions():
		InputMap.action_erase_events(action)
		Input.action_release(action)
	root.size = Vector2i(1280,720)
	world = preload("res://scenes/rebirth/Stillwater.tscn").instantiate()
	world.persist_progress = false
	root.add_child(world)
	current_scene = world
	world.start_run()
	world.set_process_unhandled_input(false)
	world.player.position = Vector3(0,0.05,3)
	world.player.facing = Vector3.FORWARD
	world.ui.toast_timer = 0
	process_frame.connect(step)
func step() -> void:
	frame += 1
	# Close inspection only; shipping gameplay retains its normal camera framing.
	world.camera.size = 7.5
	if frame in [30,115,200]: Input.action_press("attack")
	if frame in [90,175,260]: Input.action_release("attack")
	if frame == 100 or frame == 190:
		world.player.weapon = 1 if frame == 100 else 2
		world.player.make_weapon()
	if frame == 280: Input.action_press("dash")
	if frame == 282: Input.action_release("dash")
	if frame == 300: world.cast(0)
	if frame == 330: root.get_node("Soundscape").shutdown()
