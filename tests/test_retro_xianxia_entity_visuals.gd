extends SceneTree

const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const BASIC_ENEMY_SCENE := preload("res://scenes/enemies/BasicEnemy.tscn")
const FAST_ENEMY_SCENE := preload("res://scenes/enemies/FastEnemy.tscn")
const ZOMBIE_SCENE := preload("res://scenes/allies/Zombie.tscn")

var failures := 0

func _initialize() -> void:
	await _test_player_is_white_robed_pixel_swordsman()
	await _test_skeleton_enemies_keep_distinct_natural_accents()
	await _test_corpse_keeps_source_skeleton_accent()
	await _test_zombie_keeps_source_accent_with_corruption_tint()
	await _test_player_attack_animation_moves_sword()
	quit(failures)

func _test_player_is_white_robed_pixel_swordsman() -> void:
	var player := PLAYER_SCENE.instantiate()
	root.add_child(player)
	await process_frame

	var body := player.get_node("Body") as Sprite2D
	var sword := player.get_node_or_null("Sword") as Node2D
	_assert_true(body.texture != null, "player has generated pixel body texture")
	_assert_equal(body.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST, "player body keeps crisp pixels")
	_assert_true(sword != null, "player has visible sword visual")
	if body.texture is ImageTexture:
		var image := body.texture.get_image()
		var robe := image.get_pixel(16, 18)
		_assert_true(robe.r > 0.75 and robe.g > 0.75 and robe.b > 0.72, "player robe center is pale celestial white")

	player.free()

func _test_skeleton_enemies_keep_distinct_natural_accents() -> void:
	var basic := BASIC_ENEMY_SCENE.instantiate()
	var fast := FAST_ENEMY_SCENE.instantiate()
	root.add_child(basic)
	root.add_child(fast)
	await process_frame

	var basic_body := basic.get_node("Body") as Sprite2D
	var fast_body := fast.get_node("Body") as Sprite2D
	_assert_true(basic.has_method("get_visual_accent_color"), "basic skeleton exposes visual accent")
	_assert_true(fast.has_method("get_visual_accent_color"), "fast skeleton exposes visual accent")
	_assert_true(basic_body.texture != null, "basic skeleton has generated pixel body texture")
	_assert_true(fast_body.texture != null, "fast skeleton has generated pixel body texture")
	_assert_equal(basic_body.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST, "basic skeleton keeps crisp pixels")
	_assert_equal(fast_body.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST, "fast skeleton keeps crisp pixels")
	if basic.has_method("get_visual_accent_color") and fast.has_method("get_visual_accent_color"):
		var basic_accent: Color = basic.get_visual_accent_color()
		var fast_accent: Color = fast.get_visual_accent_color()
		_assert_true(basic_accent.r > basic_accent.g, "basic skeleton keeps red spirit accent")
		_assert_true(fast_accent.g > basic_accent.g and fast_accent.r >= fast_accent.g, "fast skeleton keeps gold spirit accent")

	basic.free()
	fast.free()

func _test_corpse_keeps_source_skeleton_accent() -> void:
	var enemy := BASIC_ENEMY_SCENE.instantiate()
	root.add_child(enemy)
	await process_frame

	var source_accent: Color = enemy.get_visual_accent_color() if enemy.has_method("get_visual_accent_color") else Color.WHITE
	var health := enemy.get_node("HealthComponent") as HealthComponent
	health.take_damage(health.max_health)
	await process_frame

	var corpse_accent: Color = enemy.get_visual_accent_color() if enemy.has_method("get_visual_accent_color") else Color.BLACK
	_assert_true(enemy.is_in_group("corpses"), "dead skeleton enters corpse group")
	_assert_true(_color_distance(source_accent, corpse_accent) < 0.16, "corpse keeps source skeleton accent")

	enemy.free()

func _test_zombie_keeps_source_accent_with_corruption_tint() -> void:
	var zombie := ZOMBIE_SCENE.instantiate()
	root.add_child(zombie)
	await process_frame

	_assert_true(zombie.has_method("get_visual_accent_color"), "zombie exposes inherited visual accent")
	var accent: Color = zombie.get_visual_accent_color() if zombie.has_method("get_visual_accent_color") else Color.BLACK
	_assert_true(accent.g >= accent.r * 0.65, "zombie accent has visible corruption green")
	_assert_true(accent.r > 0.28, "zombie still keeps warm source identity")

	zombie.free()

func _test_player_attack_animation_moves_sword() -> void:
	var player := PLAYER_SCENE.instantiate()
	root.add_child(player)
	await process_frame

	var sword := player.get_node_or_null("Sword") as Node2D
	if sword == null:
		_assert_true(false, "player sword exists before attack animation")
		player.free()
		return

	var before_rotation := sword.rotation
	player.call("_try_melee_attack")
	await process_frame
	_assert_true(absf(sword.rotation - before_rotation) > 0.05, "player attack animation swings sword")

	player.last_facing_direction = Vector2.RIGHT
	player.sword_swing_timer = 0.0
	player._update_sword_feedback(0.0)
	var right_rest_rotation := sword.rotation
	var expected_right_rest: float = Vector2.RIGHT.angle() - PI * 0.5 + player.sword_rest_offset
	_assert_true(absf(right_rest_rotation - expected_right_rest) < 0.01, "player sword rests along facing direction")

	player.free()

func _color_distance(a: Color, b: Color) -> float:
	return absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)

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
