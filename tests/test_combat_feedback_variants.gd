extends SceneTree

const HIT_SPARK_SCENE := preload("res://scenes/effects/HitSpark.tscn")
const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const BASIC_ENEMY_SCENE := preload("res://scenes/enemies/BasicEnemy.tscn")

var failures := 0
var captured_messages: Array[String] = []

class TestWorld:
	extends Node

	signal combat_message_requested(message: String)

	var slam_charge: int = 3
	var slam_charge_required: int = 3
	var consume_count: int = 0

	func has_slam_charge() -> bool:
		return slam_charge >= slam_charge_required

	func consume_slam_charge() -> bool:
		if not has_slam_charge():
			return false
		slam_charge = 0
		consume_count += 1
		return true

func _initialize() -> void:
	await _test_hit_spark_can_be_configured()
	await _test_combat_message_priority_prefers_counter_over_momentum()
	await _test_combat_message_priority_prefers_impact_over_counter()
	await _test_melee_attack_emits_one_message_for_multiple_hits()
	await _test_impact_whiff_does_not_consume_or_emit()
	await _test_impact_hit_consumes_once_and_emits_one_message()
	await _test_perfect_guard_creates_counter_ready_visual_state()
	quit(failures)

func _test_hit_spark_can_be_configured() -> void:
	var spark := HIT_SPARK_SCENE.instantiate()
	_assert_true(spark.has_method("configure"), "hit spark exposes configure")
	if spark.has_method("configure"):
		spark.elapsed = 0.11
		spark.configure(Color(0.2, 0.9, 1.0, 1.0), Vector2(1.2, 1.2), Vector2(2.4, 2.4), 0.22)
		_assert_equal(spark.start_scale, Vector2(1.2, 1.2), "hit spark configure updates start scale")
		_assert_equal(spark.end_scale, Vector2(2.4, 2.4), "hit spark configure updates end scale")
		_assert_equal(spark.lifetime, 0.22, "hit spark configure updates lifetime")
		_assert_equal(spark.elapsed, 0.0, "hit spark configure resets elapsed time")
	await _free_and_wait(spark)

func _test_combat_message_priority_prefers_counter_over_momentum() -> void:
	var player: Node = _add_player_without_skills(root)
	await process_frame

	_assert_true(player.has_method("_choose_combat_message"), "player exposes combat message priority helper")
	if player.has_method("_choose_combat_message"):
		_assert_equal(player.call("_choose_combat_message", false, true, true, false), "Counter", "counter message wins over momentum")

	await _free_and_wait(player)

func _test_combat_message_priority_prefers_impact_over_counter() -> void:
	var player: Node = _add_player_without_skills(root)
	await process_frame

	_assert_true(player.has_method("_choose_combat_message"), "player exposes combat message priority helper")
	if player.has_method("_choose_combat_message"):
		_assert_equal(player.call("_choose_combat_message", true, true, false, false), "Impact Strike", "impact message wins over counter")

	await _free_and_wait(player)

func _test_melee_attack_emits_one_message_for_multiple_hits() -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene

	var enemy_a := BASIC_ENEMY_SCENE.instantiate()
	var enemy_b := BASIC_ENEMY_SCENE.instantiate()
	var player: Node = _add_player_without_skills(scene)
	scene.add_child(enemy_a)
	scene.add_child(enemy_b)
	player.global_position = Vector2.ZERO
	enemy_a.global_position = Vector2(28.0, -4.0)
	enemy_b.global_position = Vector2(44.0, 4.0)
	await process_frame

	captured_messages.clear()
	player.connect("combat_message_requested", Callable(self, "_capture_combat_message"))
	player.set("last_facing_direction", Vector2.RIGHT)
	player.set("current_input_direction", Vector2.RIGHT)
	player.call("_try_melee_attack")
	await process_frame
	await create_timer(0.26, true, false, true).timeout

	_assert_equal(captured_messages.size(), 1, "melee attack emits at most one special message across multiple hits")
	if captured_messages.size() > 0:
		_assert_equal(captured_messages[0], "Momentum", "melee attack emits the highest priority message that applies")

	current_scene = null
	await _free_and_wait(scene)

func _test_impact_whiff_does_not_consume_or_emit() -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene

	var world := TestWorld.new()
	world.add_to_group("world")
	scene.add_child(world)
	var player: Node = _add_player_without_skills(scene)
	player.global_position = Vector2.ZERO
	await process_frame

	captured_messages.clear()
	player.connect("combat_message_requested", Callable(self, "_capture_combat_message"))
	player.set("last_facing_direction", Vector2.RIGHT)
	player.call("_try_melee_attack")
	await process_frame

	_assert_equal(world.consume_count, 0, "impact charge is not consumed when melee whiffs")
	_assert_equal(world.slam_charge, 3, "impact charge remains available after whiff")
	_assert_equal(captured_messages.size(), 0, "impact whiff emits no player combat message")

	current_scene = null
	await _free_and_wait(scene)

func _test_impact_hit_consumes_once_and_emits_one_message() -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene

	var world := TestWorld.new()
	world.add_to_group("world")
	scene.add_child(world)
	var player: Node = _add_player_without_skills(scene)
	var enemy := BASIC_ENEMY_SCENE.instantiate()
	scene.add_child(enemy)
	player.global_position = Vector2.ZERO
	enemy.global_position = Vector2(32.0, 0.0)
	await process_frame

	captured_messages.clear()
	player.connect("combat_message_requested", Callable(self, "_capture_combat_message"))
	player.set("last_facing_direction", Vector2.RIGHT)
	player.call("_try_melee_attack")
	await process_frame
	await create_timer(0.26, true, false, true).timeout

	_assert_equal(world.consume_count, 1, "impact charge is consumed once when melee hits")
	_assert_equal(world.slam_charge, 0, "impact charge is cleared after hit")
	_assert_equal(captured_messages.size(), 1, "impact hit emits one player combat message")
	if captured_messages.size() > 0:
		_assert_equal(captured_messages[0], "Impact Strike", "impact hit emits impact message")

	current_scene = null
	await _free_and_wait(scene)

func _test_perfect_guard_creates_counter_ready_visual_state() -> void:
	var player: Node = _add_player_without_skills(root)
	await process_frame
	player.set("is_defending", true)
	player.set("perfect_guard_timer", 0.2)
	player.call("handle_enemy_attack", 1, null)
	await process_frame
	_assert_true(player.get("counter_ready_timer") > 0.0, "perfect guard enables counter window")
	_assert_true(player.has_method("_is_counter_ready_visual_active"), "player exposes counter-ready visual helper")
	_assert_true(player.call("_is_counter_ready_visual_active"), "counter-ready visual state is active")
	await _free_and_wait(player)

func _add_player_without_skills(parent: Node) -> Node:
	var player := PLAYER_SCENE.instantiate()
	_disable_player_skills(player)
	parent.add_child(player)
	_disable_player_skills(player)
	return player

func _disable_player_skills(player: Node) -> void:
	var skill_caster := player.get_node_or_null("SkillCaster")
	if skill_caster != null:
		skill_caster.set("skills", [])
		skill_caster.set("active_slots", [false, false, false, false, false])
		skill_caster.set_process(false)
		skill_caster.set_physics_process(false)

func _free_and_wait(node: Node) -> void:
	if node != null and is_instance_valid(node):
		node.free()
	await process_frame

func _capture_combat_message(message: String) -> void:
	captured_messages.append(message)

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
