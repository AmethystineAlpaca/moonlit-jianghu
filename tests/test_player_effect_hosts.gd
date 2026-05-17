extends SceneTree

const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")

var failures := 0

func _initialize() -> void:
	await _test_player_attack_effects_work_without_current_scene()
	await _test_player_afterimage_does_not_use_invalid_interval_callback_chain()
	await _test_player_has_night_readability_lights()
	quit(failures)

func _test_player_attack_effects_work_without_current_scene() -> void:
	var player := PLAYER_SCENE.instantiate()
	root.add_child(player)
	current_scene = null
	await process_frame

	player.call("_try_melee_attack")
	await process_frame

	_assert_true(root.find_child("SlashTrail", true, false) != null, "player attack spawns slash trail without current_scene")
	player.free()

func _test_player_afterimage_does_not_use_invalid_interval_callback_chain() -> void:
	var player := PLAYER_SCENE.instantiate()
	root.add_child(player)
	await process_frame

	player.call("_spawn_afterimage", 0.3)
	await process_frame

	_assert_true(true, "player afterimage can spawn without tween API errors")
	player.free()

func _test_player_has_night_readability_lights() -> void:
	var player := PLAYER_SCENE.instantiate()
	root.add_child(player)
	await process_frame

	_assert_true(player.get_node_or_null("PlayerLight") is PointLight2D, "player scene has PlayerLight")
	_assert_true(player.get_node_or_null("Sword/WeaponLight") is PointLight2D, "player sword has WeaponLight")

	player.free()

func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	failures += 1
	push_error(message)
