extends SceneTree

const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")

var failures := 0

func _initialize() -> void:
	var player := PLAYER_SCENE.instantiate()
	root.add_child(player)
	await process_frame

	_assert_equal(player.get("selected_skill_slot"), 0, "first skill slot is selected by default")
	_assert_equal(player.call("get_skill_slot_names")[0], "Transform", "first skill slot contains Transform")

	quit(failures)

func _assert_equal(actual, expected, message: String) -> void:
	if actual == expected:
		return
	failures += 1
	push_error("%s: expected %s, got %s" % [message, expected, actual])
