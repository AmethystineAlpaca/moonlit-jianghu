extends SceneTree

const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const WORLD_SCENE := preload("res://scenes/world/World.tscn")
const ENEMY_SCENE := preload("res://scenes/enemies/BasicEnemy.tscn")

var failures := 0

func _initialize() -> void:
	await _test_player_hit_feedback_is_obvious()
	await _test_enemy_attack_gives_player_tiny_hitback()
	await _test_danger_overlay_tracks_low_health()
	quit(failures)

func _test_player_hit_feedback_is_obvious() -> void:
	var player := PLAYER_SCENE.instantiate()
	root.add_child(player)
	await process_frame

	var health := player.get_node("HealthComponent") as HealthComponent
	health.take_damage(1)
	await process_frame

	var body := player.get_node("Body") as Sprite2D
	var damage_ring := player.get_node("DamageRing") as Polygon2D
	_assert_true(body.modulate.r > body.modulate.g, "player body flashes red on damage")
	_assert_true(body.scale.x > 1.0, "player body visibly pulses larger on damage")
	_assert_true(damage_ring.visible, "player damage ring appears on damage")

	player.free()

func _test_enemy_attack_gives_player_tiny_hitback() -> void:
	var player := PLAYER_SCENE.instantiate() as Node2D
	root.add_child(player)
	player.global_position = Vector2(20.0, 0.0)

	var enemy := ENEMY_SCENE.instantiate() as Node2D
	root.add_child(enemy)
	enemy.global_position = Vector2.ZERO
	await process_frame

	enemy.set("current_target", player)
	var hit_direction := (player.global_position - enemy.global_position).normalized()
	enemy.call("_try_damage_player")
	var hitback: Vector2 = player.get("attack_hitback_velocity")
	_assert_true(is_equal_approx(hitback.length(), enemy.get("attack_hitback_force")), "enemy attack gives player a tiny hitback")
	_assert_true(hitback.normalized().dot(hit_direction) > 0.99, "enemy attack pushes player away from enemy")

	enemy.free()
	player.free()

func _test_danger_overlay_tracks_low_health() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame

	var player := world.get_node("Player")
	var hud := world.get_node("Hud")
	var health := player.get_node("HealthComponent") as HealthComponent
	var danger_overlay := hud.get_node("DangerOverlay") as ColorRect

	health.take_damage(5)
	await process_frame
	_assert_false(danger_overlay.visible, "danger overlay stays hidden above last two HP")

	health.take_damage(1)
	await process_frame
	_assert_true(danger_overlay.visible, "danger overlay appears at two HP")
	_assert_true(danger_overlay.color.a > 0.0, "danger overlay has visible red tint")

	health.heal(3)
	await process_frame
	_assert_false(danger_overlay.visible, "danger overlay clears after healing out of danger")

	world.free()

func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	failures += 1
	push_error(message)

func _assert_false(value: bool, message: String) -> void:
	_assert_true(not value, message)

func _assert_equal(actual, expected, message: String) -> void:
	if actual == expected:
		return
	failures += 1
	push_error("%s: expected %s, got %s" % [message, expected, actual])
