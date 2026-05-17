extends SceneTree

const ENEMY_SCENE := preload("res://scenes/enemies/BasicEnemy.tscn")

var failures := 0

func _initialize() -> void:
	var enemy := ENEMY_SCENE.instantiate()
	root.add_child(enemy)
	await process_frame

	var health := enemy.get_node("HealthComponent") as HealthComponent
	var source_accent: Color = enemy.get_visual_accent_color() if enemy.has_method("get_visual_accent_color") else Color.WHITE
	health.take_damage(health.max_health)
	await process_frame

	var body := enemy.get_node("Body") as Sprite2D
	var corpse_accent: Color = enemy.get_visual_accent_color() if enemy.has_method("get_visual_accent_color") else Color.BLACK
	_assert_true(enemy.is_in_group("corpses"), "dead enemy enters corpse group")
	_assert_true(body.texture != null, "corpse keeps a generated bone-remains texture")
	_assert_true(_color_distance(source_accent, corpse_accent) < 0.16, "corpse keeps enemy skeleton accent color")

	enemy.free()
	quit(failures)

func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	failures += 1
	push_error(message)

func _color_distance(a: Color, b: Color) -> float:
	return absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)
