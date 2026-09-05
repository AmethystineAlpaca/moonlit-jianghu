extends SceneTree
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func run() -> void:
	var main := preload("res://scenes/main/Main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	var world := main.get_node("World")
	world.set_process(false)
	var player := world.get_node("Player")
	var hud := world.get_node("Hud")
	world.get_node("GameFeel").persist_progress = false
	for enemy in get_nodes_in_group("hostile_enemies"):
		enemy.set_physics_process(false)
	var start: Vector2 = player.global_position
	Input.action_press("move_right")
	for i in range(12): await physics_frame
	Input.action_release("move_right")
	check(player.global_position.x > start.x + 10, "movement input moves the player")
	Input.action_press("dash")
	await physics_frame
	await physics_frame
	Input.action_release("dash")
	check(player.dash_timer > 0.0, "dash input activates the dash state")
	for i in range(12): await physics_frame
	player._set_stamina(10.0)
	Input.action_press("select_skill_3")
	await physics_frame
	await physics_frame
	Input.action_release("select_skill_3")
	check(player.selected_skill_slot == 2 and player.skill_caster.cooldowns[2] > 0.0, "number key selects and casts")
	var pause_event := InputEventAction.new()
	pause_event.action = "pause_game"
	pause_event.pressed = true
	hud._unhandled_input(pause_event)
	await process_frame
	await process_frame
	check(paused and hud.get_node("JourneyPauseMenu").visible, "Escape opens the interactive pause menu")
	var stopped_position: Vector2 = player.global_position
	for i in range(6): await process_frame
	check(player.global_position == stopped_position, "paused gameplay stays still")
	hud._unhandled_input(pause_event)
	await process_frame
	check(not paused, "Escape resumes gameplay")
	var bag_event := InputEventAction.new()
	bag_event.action = "toggle_inventory"
	bag_event.pressed = true
	hud._unhandled_input(bag_event)
	await process_frame
	check(paused and hud.inventory_open, "inventory safely pauses gameplay")
	hud._unhandled_input(bag_event)
	check(not paused and not hud.inventory_open, "closing inventory restores gameplay")
	await create_timer(0.8).timeout
	current_scene = null
	main.queue_free()
	await process_frame
	print("Journey controls: ", failures, " failures")
	quit(failures)
