extends Area2D

@export var potion_chance: float = 0.5
@export var heal_amount: int = 4
@export var mimic_scene: PackedScene

var is_opened: bool = false

func _ready() -> void:
	add_to_group("chests")
	body_entered.connect(_on_body_entered)

func open(opener: Node) -> void:
	if randf() < potion_chance:
		open_as_potion(opener)
	else:
		open_as_mimic(opener)

func open_as_potion(opener: Node) -> void:
	if is_opened:
		return

	is_opened = true
	var health := _get_health_component(opener)
	if health != null:
		health.heal(heal_amount)
	_report_world_message("Potion")
	queue_free()

func open_as_mimic(_opener: Node) -> void:
	if is_opened:
		return

	is_opened = true
	if mimic_scene != null:
		var mimic := mimic_scene.instantiate() as Node2D
		var enemies_parent := _get_enemies_parent()
		enemies_parent.add_child(mimic)
		mimic.global_position = global_position
		if mimic.has_method("set_survival_mode"):
			mimic.set_survival_mode(true)
	_report_world_message("Mimic")
	queue_free()

func _on_body_entered(body: Node) -> void:
	if body != null and body.is_in_group("player"):
		open(body)

func _get_health_component(node: Node) -> HealthComponent:
	if node == null:
		return null
	return node.get_node_or_null("HealthComponent") as HealthComponent

func _get_enemies_parent() -> Node:
	var world := get_tree().get_first_node_in_group("world")
	if world != null:
		var enemies := world.get_node_or_null("Enemies")
		if enemies != null:
			return enemies
	return get_parent()

func _report_world_message(message: String) -> void:
	var world := get_tree().get_first_node_in_group("world")
	if world != null and world.has_method("report_combat_message"):
		world.report_combat_message(message)
