extends Control

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var world := get_tree().get_first_node_in_group("world") as Node2D
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if world == null or player == null:
		return
	var bounds := Vector2(160, 100)
	draw_rect(Rect2(Vector2.ZERO, bounds), Color(0.025, 0.07, 0.08, 0.85))
	draw_rect(Rect2(Vector2.ZERO, bounds), Color("81856b"), false, 1)
	for building in world.get_node("Buildings").get_children():
		if building is Node2D:
			var point: Vector2 = (building.position / Vector2(1440, 960) + Vector2(0.5, 0.5)) * bounds
			draw_rect(Rect2(point - Vector2(5, 3), Vector2(10, 6)), Color("687f73"))
	draw_line(Vector2(80, 1), Vector2(80, 99), Color(0.6, 0.55, 0.4, 0.35), 2)
	draw_line(Vector2(1, 50), Vector2(159, 50), Color(0.6, 0.55, 0.4, 0.35), 2)
	for group in ["obstacles", "hostile_enemies", "chests", "player"]:
		for node in get_tree().get_nodes_in_group(group):
			if not node is Node2D:
				continue
			var point: Vector2 = (world.to_local(node.global_position) / Vector2(1440, 960) + Vector2(0.5, 0.5)) * bounds
			point = point.clamp(Vector2(3, 3), bounds - Vector2(3, 3))
			var color := Color("687f73")
			if group == "hostile_enemies": color = Color("e38c79")
			if group == "chests": color = Color("e6cd85")
			if group == "player": color = Color("bdf8e7")
			draw_rect(Rect2(point - Vector2(2, 2), Vector2(4, 4)), color)
