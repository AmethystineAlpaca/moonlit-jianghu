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
	await physics_frame
	for weapon in ["iron_sword", "heavy_saber", "jade_sword"]:
		player.set_equipped_weapon(weapon)
		player.melee_timer = 0.0
		player.dash_timer = 0.0
		player.dash_cooldown_timer = 0.0
		player._set_stamina(10.0)
		player._try_melee_attack()
		check(player.attack_pending_timer > 0, "each weapon has an actual windup")
		check(host.find_child("SlashTrail", true, false) == null, "no impact before windup")
		player._try_dash(Vector2.RIGHT)
		check(player.attack_pending_timer == 0, "dodge cancels the pending strike")
		for i in range(35): await physics_frame
		check(host.find_child("SlashTrail", true, false) == null, "canceled strike never releases")
	player.set_equipped_weapon("heavy_saber")
	var heavy: float = player.melee_cooldown
	player.set_equipped_weapon("jade_sword")
	check(player.melee_cooldown < heavy, "light and heavy weapons have different cadence")
	check(player._get_attack_frames_for_direction(Vector2.LEFT).size() == 6, "new body atlas supplies all strike poses")
	current_scene = null
	host.queue_free()
	await process_frame
	quit(failures)
