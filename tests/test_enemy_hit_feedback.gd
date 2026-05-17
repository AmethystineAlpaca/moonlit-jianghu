extends SceneTree

const ENEMY_SCENE := preload("res://scenes/enemies/BasicEnemy.tscn")

var failures := 0

func _initialize() -> void:
	var enemy := ENEMY_SCENE.instantiate()
	root.add_child(enemy)
	await process_frame

	var health := enemy.get_node("HealthComponent") as HealthComponent
	health.take_damage(1)
	await process_frame

	var body := enemy.get_node("Body") as Sprite2D
	var hp_bar := enemy.get_node("HPBar") as ProgressBar
	_assert_true(body.modulate.r > body.modulate.g, "enemy flashes with a warm hit color on damage")
	_assert_true(body.scale.x > 1.0, "enemy body pulses larger on damage")
	_assert_true(hp_bar.modulate.a > 0.95, "enemy HP bar remains readable during hit feedback")

	enemy.free()
	quit(failures)

func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	failures += 1
	push_error(message)
