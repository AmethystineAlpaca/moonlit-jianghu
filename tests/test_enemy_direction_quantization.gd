extends SceneTree

const FIRE_LION_SCENE := preload("res://scenes/enemies/FireLionEnemy.tscn")

const FIRE_LION_ROW_DOWN_LEFT_Y := 0.0
const FIRE_LION_ROW_LEFT_Y := 256.0
const FIRE_LION_ROW_UP_LEFT_Y := 512.0
const FIRE_LION_ROW_UP_Y := 768.0
const FIRE_LION_ROW_DOWN_Y := 1024.0

var failures := 0

func _initialize() -> void:
	await _test_enemy_prefers_cardinal_rows_outside_diagonal_window()
	await _test_enemy_uses_diagonal_rows_inside_diagonal_window()
	quit(failures)

func _test_enemy_prefers_cardinal_rows_outside_diagonal_window() -> void:
	var enemy := FIRE_LION_SCENE.instantiate()
	root.add_child(enemy)
	await process_frame

	_assert_row(enemy, Vector2.LEFT, FIRE_LION_ROW_LEFT_Y, false, "pure left uses left row")
	_assert_row(enemy, Vector2(-1.0, 0.2).normalized(), FIRE_LION_ROW_LEFT_Y, false, "shallow down-left stays on left row")
	_assert_row(enemy, Vector2(-0.2, -1.0).normalized(), FIRE_LION_ROW_UP_Y, false, "shallow up-left stays on up row")
	_assert_row(enemy, Vector2(0.2, 1.0).normalized(), FIRE_LION_ROW_DOWN_Y, false, "shallow down-right stays on down row")
	_assert_row(enemy, Vector2.RIGHT, FIRE_LION_ROW_LEFT_Y, true, "pure right mirrors the left row")

	enemy.free()

func _test_enemy_uses_diagonal_rows_inside_diagonal_window() -> void:
	var enemy := FIRE_LION_SCENE.instantiate()
	root.add_child(enemy)
	await process_frame

	_assert_row(enemy, Vector2(-1.0, 1.0).normalized(), FIRE_LION_ROW_DOWN_LEFT_Y, false, "true down-left uses diagonal row")
	_assert_row(enemy, Vector2(-1.0, -1.0).normalized(), FIRE_LION_ROW_UP_LEFT_Y, false, "true up-left uses diagonal row")
	_assert_row(enemy, Vector2(1.0, 1.0).normalized(), FIRE_LION_ROW_DOWN_LEFT_Y, true, "true down-right mirrors down-left row")
	_assert_row(enemy, Vector2(1.0, -1.0).normalized(), FIRE_LION_ROW_UP_LEFT_Y, true, "true up-right mirrors up-left row")

	enemy.free()

func _assert_row(enemy: Node, direction: Vector2, expected_y: float, expected_flip_h: bool, message: String) -> void:
	enemy.set("facing_direction", direction)
	enemy.call("_update_enemy_direction_texture", false, 0.0)
	var body := enemy.get_node("Body") as Sprite2D
	var atlas := body.texture as AtlasTexture
	_assert_true(atlas != null, "%s: enemy body uses atlas texture" % message)
	if atlas == null:
		return
	_assert_equal(atlas.region.position.y, expected_y, "%s: row matches expected direction" % message)
	_assert_equal(body.flip_h, expected_flip_h, "%s: flip_h matches expected direction" % message)

func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	failures += 1
	push_error(message)

func _assert_equal(actual, expected, message: String) -> void:
	if actual == expected:
		return
	failures += 1
	push_error("%s: expected %s, got %s" % [message, expected, actual])
