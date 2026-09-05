extends SceneTree
const OUTPUT := "res://output/art-v2"

func _initialize() -> void:
	call_deferred("run")

func settle(frames: int = 12) -> void:
	for i in range(frames): await process_frame

func shot(filename: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	print("Capture ", filename, " format ", image.get_format(), " HDR ", root.use_hdr_2d)
	if root.use_hdr_2d:
		image.convert(Image.FORMAT_RGBA8)
		image.linear_to_srgb()
	image.save_png(OUTPUT + "/" + filename)

func run() -> void:
	root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var title := preload("res://scenes/interface/TitleScreen.tscn").instantiate()
	root.add_child(title)
	current_scene = title
	await create_timer(0.8).timeout
	await shot("01-title.png")
	title.show_settings()
	await settle()
	await shot("02-settings.png")
	title.modal.queue_free()
	title.start_game()
	await create_timer(0.8).timeout
	var world := current_scene.get_node("World")
	var player := world.get_node("Player")
	var hud := world.get_node("Hud")
	world.set_process(false)
	world.get_node("GameFeel").persist_progress = false
	for enemy in get_nodes_in_group("hostile_enemies"): enemy.set_physics_process(false)
	player.position = Vector2(150, 30)
	var event := InputEventAction.new()
	event.action = "toggle_night"
	event.pressed = true
	if world.get_node("NightAmbience").visible: world._unhandled_input(event)
	await create_timer(0.4).timeout
	await shot("03-village-day.png")
	world._unhandled_input(event)
	await settle()
	await shot("04-village-night.png")
	event.action = "toggle_inventory"
	hud._unhandled_input(event)
	await settle()
	await shot("05-inventory.png")
	hud._unhandled_input(event)
	event.action = "pause_game"
	hud._unhandled_input(event)
	await settle()
	await shot("06-pause.png")
	hud._unhandled_input(event)
	var feel := world.get_node("GameFeel")
	player.set_equipped_weapon("heavy_saber")
	player.last_facing_direction = Vector2.LEFT
	player._try_melee_attack()
	await create_timer(0.22).timeout
	await shot("08-heavy-strike.png")
	await create_timer(0.5).timeout
	feel.stage = 1
	feel._show_upgrade()
	await settle()
	await shot("09-growth.png")
	feel.upgrade_panel.select(0)
	feel.boss_spawned = true
	feel._begin_boss()
	await create_timer(0.4).timeout
	feel.boss_node.global_position = player.global_position + Vector2(85,-20)
	feel.boss_node.timer = 0.0
	await create_timer(0.15).timeout
	await shot("10-mountain-guardian.png")
	feel.boss_node.set_physics_process(false)
	feel.kills = 24
	feel.completed = true
	feel._show_result()
	await settle()
	await shot("07-result.png")
	var soundscape := root.get_node_or_null("Soundscape")
	if soundscape != null and is_instance_valid(soundscape.music):
		soundscape.music.stop()
		soundscape.music.stream = null
	current_scene.queue_free()
	await settle()
	quit()
