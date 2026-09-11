extends SceneTree
## Navigation and UI state regressions exercised through real controls/input.
var failures := 0
var world: Node3D
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func _initialize() -> void: call_deferred("run")
func find_button(node: Node, fragment: String) -> Button:
	for child in node.get_children():
		if child is Button and fragment in child.text: return child
		var result := find_button(child,fragment)
		if result != null: return result
	return null
func key(code: int) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	event = InputEventKey.new()
	event.keycode = code
	event.pressed = false
	Input.parse_input_event(event)
func menu_fits(node: Node) -> void:
	for child in node.get_children():
		if child is Button or child is Label:
			var rect: Rect2 = child.get_global_rect()
			check(rect.position.x >= 0 and rect.position.y >= 0 and rect.end.x <= 1281 and rect.end.y <= 721,"menu control stays inside the 1280×720 canvas: "+child.text)
		menu_fits(child)
func run() -> void:
	root.size = Vector2i(1280,720)
	world = preload("res://scenes/rebirth/Stillwater.tscn").instantiate()
	world.persist_progress = false
	root.add_child(world)
	current_scene = world
	await process_frame
	await process_frame
	var ui = world.ui
	check(ui.modal_kind == "title","live title opens on the start menu")
	menu_fits(ui.modal)
	var guide := find_button(ui.modal,"游玩指南")
	check(guide != null,"title exposes a playable guide button")
	guide.pressed.emit()
	await process_frame
	check(ui.modal_kind == "guide" and world.mode == "title","guide is reachable from title without starting combat")
	menu_fits(ui.modal)
	key(KEY_ESCAPE)
	await process_frame
	check(ui.modal_kind == "title","Escape from title guide returns to title")
	find_button(ui.modal,"开始旅程").pressed.emit()
	await process_frame
	check(world.mode == "play" and ui.modal == null,"start button enters the live courtyard")
	check(ui.health.size.y == 6 and ui.stamina.size.y == 3 and ui.flow_bar.size.y == 3,"theme initialization preserves deliberately thin resource bars")
	key(KEY_ESCAPE)
	await process_frame
	check(world.mode == "pause" and ui.modal_kind == "pause","Escape opens pause")
	await process_frame
	check(not ui.hud.visible,"pause hides the HUD so menu headings remain clear")
	find_button(ui.modal,"剑 谱").pressed.emit()
	await process_frame
	check(ui.modal_kind == "guide" and world.mode == "pause","pause can open guide without resuming enemies")
	key(KEY_ESCAPE)
	await process_frame
	check(ui.modal_kind == "pause" and world.mode == "pause","Escape closes the pause guide without leaking through to resume")
	find_button(ui.modal,"继续旅程").pressed.emit()
	await process_frame
	check(world.mode == "play" and ui.modal == null,"resume button returns to gameplay")
	world.player.set_physics_process(false)
	world.player.position = world.seals[0].position+Vector3(1.5,0.05,0)
	world.interact()
	world.spawn_queue = 0
	world.complete_seal()
	await process_frame
	check(ui.modal_kind == "upgrade" and world.available_upgrades.size() == 3,"clearing a lamp presents all three build choices")
	menu_fits(ui.modal)
	var chosen: String = world.available_upgrades[2].key
	var previous: int = world.director.bonuses[chosen]
	key(KEY_3)
	await process_frame
	check(world.mode == "play" and ui.modal == null,"numeric upgrade selection dismisses the modal")
	check(world.director.bonuses[chosen] == previous+1,"third keyboard choice applies the visible third upgrade")
	check(world.player.weapon == 0,"upgrade keyboard shortcut does not also switch weapons")
	world.director.flow = 100
	world.director.chain = 8
	world.director.chain_time = 10
	await process_frame
	await process_frame
	check(ui.skill_states[3].text == "绝技就绪" and "已满" in ui.flow_label.text.replace(" ",""),"full sword energy exposes an explicit ultimate-ready state")
	var pad := InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_RIGHT_SHOULDER
	pad.pressed = false
	ui._input(pad)
	await process_frame
	check(ui.skill_keys[2].text == "B" and ui.skill_keys[3].text == "R3","gamepad labels agree with configured wine and ultimate bindings")
	world.mode = "defeat"
	ui.show_result(false)
	await process_frame
	menu_fits(ui.modal)
	var retry := find_button(ui.modal,"再战此灯")
	check(retry != null,"defeat offers the checkpoint continuation")
	retry.pressed.emit()
	await process_frame
	await process_frame
	world = current_scene
	check(is_instance_valid(world) and world.mode == "play" and world.round_index == 1,"checkpoint result button restores the run with completed lamps")
	current_scene = null
	world.queue_free()
	for i in range(3): await process_frame
	print("Stillwater interface: ",failures," failures")
	quit(failures)
