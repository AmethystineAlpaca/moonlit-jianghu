extends Node2D

signal combat_message_requested(message: String)

@export var enemy_scene: PackedScene
@export var fast_enemy_scene: PackedScene
@export var breakable_scene: PackedScene
@export var chest_scene: PackedScene
@export var spawn_margin: float = 36.0
@export var active_enemy_cap: int = 14
@export var active_chest_cap: int = 1
@export var initial_spawn_interval: float = 5.0
@export var minimum_spawn_interval: float = 1.5
@export var spawn_acceleration_per_minute: float = 1.0
@export var chest_spawn_interval: float = 120.0
@export var fast_enemy_grace_seconds: float = 20.0
@export var fast_enemy_base_chance: float = 0.22
@export var fast_enemy_max_chance: float = 0.42
@export var map_half_size: Vector2 = Vector2(680, 440)
@export var spawn_area_half_size: Vector2 = Vector2(640, 400)
@export var navigation_cell_size: float = 32.0
@export var navigation_obstacle_padding: float = 18.0
@export var random_breakable_min_count: int = 50
@export var random_breakable_max_count: int = 100
@export var random_breakable_spawn_attempts: int = 800
@export var random_breakable_clearance: float = 18.0
@export var player_spawn_clearance: float = 120.0
@export var chest_spawn_attempts: int = 1200
@export var chest_spawn_clearance: float = 22.0

var elapsed_time: float = 0.0
var spawn_timer: float = 0.0
var chest_spawn_timer: float = 0.0
var slam_charge: int = 0
var slam_charge_required: int = 3
var path_grid: AStarGrid2D
var path_region: Rect2i
var path_solid_counts := {}
var dynamic_navigation_obstacle_cells := {}
var breakable_rng := RandomNumberGenerator.new()
var chest_rng := RandomNumberGenerator.new()

@onready var enemies_parent: Node2D = $Enemies
@onready var breakables_parent: Node2D = get_node_or_null("Breakables") as Node2D
@onready var chests_parent: Node2D = get_node_or_null("Chests") as Node2D

func _ready() -> void:
	add_to_group("world")
	chest_rng.randomize()
	_spawn_random_breakables()
	_regenerate_grassland()
	_build_path_grid()
	spawn_timer = initial_spawn_interval
	chest_spawn_timer = chest_spawn_interval
	_try_spawn_enemy()
	_setup_night_atmosphere()

func _process(delta: float) -> void:
	elapsed_time += delta
	spawn_timer -= delta

	if spawn_timer <= 0.0:
		_try_spawn_enemy()
		spawn_timer = _get_spawn_interval()

	chest_spawn_timer -= delta
	if chest_spawn_timer <= 0.0:
		_try_spawn_chest()
		chest_spawn_timer = chest_spawn_interval

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reset_scene"):
		get_tree().reload_current_scene()

func report_combat_message(message: String) -> void:
	combat_message_requested.emit(message)

func report_slam(message: String, impact_position: Vector2) -> void:
	report_combat_message(message)
	_add_slam_charge()

func has_slam_charge() -> bool:
	return slam_charge >= slam_charge_required

func consume_slam_charge() -> bool:
	if not has_slam_charge():
		return false

	slam_charge = 0
	return true

func get_path_direction(from_position: Vector2, target_position: Vector2) -> Vector2:
	if path_grid == null:
		return (target_position - from_position).normalized()

	var from_id := _world_to_path_id(from_position)
	var target_id := _find_nearest_walkable_id(_world_to_path_id(target_position))
	from_id = _find_nearest_walkable_id(from_id)
	if not path_region.has_point(from_id) or not path_region.has_point(target_id):
		return (target_position - from_position).normalized()

	var path := path_grid.get_id_path(from_id, target_id)
	if path.size() <= 1:
		return (target_position - from_position).normalized()

	var next_id := path[1] as Vector2i
	if path.size() > 2 and from_position.distance_to(_path_id_to_world(next_id)) < navigation_cell_size * 0.35:
		next_id = path[2] as Vector2i

	var direction := _path_id_to_world(next_id) - from_position
	if direction == Vector2.ZERO:
		return (target_position - from_position).normalized()
	return direction.normalized()

func register_navigation_obstacle(obstacle: Node2D) -> void:
	if obstacle == null or path_grid == null:
		return

	unregister_navigation_obstacle(obstacle)
	var cells := _get_obstacle_solid_ids(obstacle)
	if cells.is_empty():
		return

	dynamic_navigation_obstacle_cells[obstacle] = cells
	for id in cells:
		_add_path_solid_id(id)

	var exit_callable := Callable(self, "_on_navigation_obstacle_tree_exiting").bind(obstacle)
	if not obstacle.tree_exiting.is_connected(exit_callable):
		obstacle.tree_exiting.connect(exit_callable, CONNECT_ONE_SHOT)

func unregister_navigation_obstacle(obstacle: Node2D) -> void:
	if obstacle == null or not dynamic_navigation_obstacle_cells.has(obstacle):
		return

	var cells: Array = dynamic_navigation_obstacle_cells[obstacle]
	dynamic_navigation_obstacle_cells.erase(obstacle)
	for id in cells:
		_remove_path_solid_id(id)

	var exit_callable := Callable(self, "_on_navigation_obstacle_tree_exiting").bind(obstacle)
	if obstacle.tree_exiting.is_connected(exit_callable):
		obstacle.tree_exiting.disconnect(exit_callable)

func _try_spawn_enemy() -> void:
	if enemy_scene == null:
		return
	if get_tree().get_nodes_in_group("hostile_enemies").size() >= active_enemy_cap:
		return

	var enemy := _pick_enemy_scene().instantiate() as Node2D
	enemy.global_position = _get_spawn_position()
	enemies_parent.add_child(enemy)
	if enemy.has_method("set_survival_mode"):
		enemy.set_survival_mode(true)

func _try_spawn_chest() -> void:
	if chest_scene == null or chests_parent == null:
		return
	if get_tree().get_nodes_in_group("chests").size() >= active_chest_cap:
		return

	var position := _find_random_chest_position()
	if position == Vector2.INF:
		return

	var chest := chest_scene.instantiate() as Node2D
	chest.global_position = position
	chests_parent.add_child(chest)

func _find_random_chest_position() -> Vector2:
	var occupied_rects := _get_breakable_spawn_blockers()
	for chest in get_tree().get_nodes_in_group("chests"):
		if chest is Node2D:
			occupied_rects.append(_get_spawn_rect((chest as Node2D).global_position, _get_chest_spawn_size(chest as Node2D)))

	for _attempt in range(chest_spawn_attempts):
		var position := Vector2(
			chest_rng.randf_range(-spawn_area_half_size.x, spawn_area_half_size.x),
			chest_rng.randf_range(-spawn_area_half_size.y, spawn_area_half_size.y)
		)
		var rect := _get_spawn_rect(position, _get_chest_spawn_size_from_scene())
		if _is_spawn_rect_clear(rect, occupied_rects):
			return position
	return Vector2.INF

func _pick_enemy_scene() -> PackedScene:
	if fast_enemy_scene == null or elapsed_time < fast_enemy_grace_seconds:
		return enemy_scene

	var pressure := clampf((elapsed_time - fast_enemy_grace_seconds) / 90.0, 0.0, 1.0)
	var fast_chance := lerpf(fast_enemy_base_chance, fast_enemy_max_chance, pressure)
	if randf() < fast_chance:
		return fast_enemy_scene
	return enemy_scene

func _get_spawn_interval() -> float:
	var minute_count := elapsed_time / 60.0
	return maxf(minimum_spawn_interval, initial_spawn_interval - minute_count * spawn_acceleration_per_minute)

func _get_spawn_position() -> Vector2:
	var spawn_half_size := Vector2(
		minf(spawn_area_half_size.x, map_half_size.x - spawn_margin),
		minf(spawn_area_half_size.y, map_half_size.y - spawn_margin)
	)
	var side := randi_range(0, 3)
	match side:
		0:
			return Vector2(randf_range(-spawn_half_size.x, spawn_half_size.x), -spawn_half_size.y)
		1:
			return Vector2(randf_range(-spawn_half_size.x, spawn_half_size.x), spawn_half_size.y)
		2:
			return Vector2(-spawn_half_size.x, randf_range(-spawn_half_size.y, spawn_half_size.y))
		_:
			return Vector2(spawn_half_size.x, randf_range(-spawn_half_size.y, spawn_half_size.y))

func _spawn_random_breakables() -> void:
	if breakable_scene == null or breakables_parent == null:
		return

	breakable_rng.randomize()
	var spawn_count := breakable_rng.randi_range(random_breakable_min_count, random_breakable_max_count)
	var occupied_rects := _get_breakable_spawn_blockers()
	for index in range(spawn_count):
		var position := _find_random_breakable_position(occupied_rects)
		if position == Vector2.INF:
			return

		var breakable := breakable_scene.instantiate() as Node2D
		breakable.name = "RandomCrate%s" % [index + 1]
		breakable.global_position = position
		breakables_parent.add_child(breakable)
		occupied_rects.append(_get_spawn_rect(position, _get_breakable_spawn_size(breakable)))

func _regenerate_grassland() -> void:
	var grassland := get_node_or_null("Grassland")
	if grassland != null and grassland.has_method("_generate"):
		grassland.call("_generate")

func _find_random_breakable_position(occupied_rects: Array[Rect2]) -> Vector2:
	var half_size := _get_breakable_spawn_size_from_scene()
	for _attempt in range(random_breakable_spawn_attempts):
		var position := Vector2(
			breakable_rng.randf_range(-spawn_area_half_size.x, spawn_area_half_size.x),
			breakable_rng.randf_range(-spawn_area_half_size.y, spawn_area_half_size.y)
		)
		var rect := _get_spawn_rect(position, half_size)
		if _is_spawn_rect_clear(rect, occupied_rects):
			return position
	return Vector2.INF

func _get_breakable_spawn_blockers() -> Array[Rect2]:
	var blockers: Array[Rect2] = []
	for obstacle in _collect_navigation_obstacles():
		if obstacle.is_in_group("breakables"):
			blockers.append(_get_spawn_rect(obstacle.global_position, _get_breakable_spawn_size(obstacle)))
		else:
			var size := _get_obstacle_size(obstacle) * 0.5 + Vector2.ONE * random_breakable_clearance
			blockers.append(Rect2(obstacle.global_position - size, size * 2.0))

	var player := get_node_or_null("Player") as Node2D
	if player != null:
		var half_size := Vector2.ONE * player_spawn_clearance
		blockers.append(Rect2(player.global_position - half_size, half_size * 2.0))
	return blockers

func _is_spawn_rect_clear(rect: Rect2, occupied_rects: Array[Rect2]) -> bool:
	if rect.position.x < -map_half_size.x or rect.end.x > map_half_size.x:
		return false
	if rect.position.y < -map_half_size.y or rect.end.y > map_half_size.y:
		return false

	for occupied in occupied_rects:
		if rect.intersects(occupied):
			return false
	return true

func _get_breakable_spawn_size_from_scene() -> Vector2:
	return Vector2(42.0, 42.0) * 0.5 + Vector2.ONE * random_breakable_clearance

func _get_chest_spawn_size_from_scene() -> Vector2:
	return Vector2(34.0, 28.0) * 0.5 + Vector2.ONE * chest_spawn_clearance

func _get_chest_spawn_size(chest: Node2D) -> Vector2:
	var size := _get_obstacle_size(chest)
	if size == Vector2.ZERO:
		size = Vector2(34.0, 28.0)
	return size * 0.5 + Vector2.ONE * chest_spawn_clearance

func _get_breakable_spawn_size(breakable: Node2D) -> Vector2:
	var size := _get_obstacle_size(breakable)
	if size == Vector2.ZERO:
		size = Vector2(42.0, 42.0)
	return size * 0.5 + Vector2.ONE * random_breakable_clearance

func _get_spawn_rect(position: Vector2, half_size: Vector2) -> Rect2:
	return Rect2(position - half_size, half_size * 2.0)

func _build_path_grid() -> void:
	var cell_size := Vector2(navigation_cell_size, navigation_cell_size)
	var min_id := Vector2i(
		floori(-map_half_size.x / navigation_cell_size) - 1,
		floori(-map_half_size.y / navigation_cell_size) - 1
	)
	var max_id := Vector2i(
		ceili(map_half_size.x / navigation_cell_size) + 1,
		ceili(map_half_size.y / navigation_cell_size) + 1
	)
	path_region = Rect2i(min_id, max_id - min_id + Vector2i.ONE)

	path_grid = AStarGrid2D.new()
	path_grid.region = path_region
	path_grid.cell_size = cell_size
	path_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	path_grid.update()
	path_solid_counts.clear()
	dynamic_navigation_obstacle_cells.clear()

	for id_x in range(path_region.position.x, path_region.end.x):
		for id_y in range(path_region.position.y, path_region.end.y):
			var id := Vector2i(id_x, id_y)
			var world_position := _path_id_to_world(id)
			if absf(world_position.x) > map_half_size.x or absf(world_position.y) > map_half_size.y:
				_add_path_solid_id(id)

	for obstacle in _collect_navigation_obstacles():
		if obstacle.is_in_group("breakables"):
			register_navigation_obstacle(obstacle)
		else:
			_mark_obstacle_solid(obstacle)

func _collect_navigation_obstacles() -> Array[Node2D]:
	var obstacles: Array[Node2D] = []
	for candidate in get_tree().get_nodes_in_group("breakables"):
		if candidate is Node2D:
			obstacles.append(candidate)
	for child in get_children():
		_collect_static_obstacles(child, obstacles)
	return obstacles

func _collect_static_obstacles(node: Node, obstacles: Array[Node2D]) -> void:
	if node is StaticBody2D and not node.is_in_group("breakables"):
		obstacles.append(node as Node2D)
	for child in node.get_children():
		_collect_static_obstacles(child, obstacles)

func _mark_obstacle_solid(obstacle: Node2D) -> void:
	for id in _get_obstacle_solid_ids(obstacle):
		_add_path_solid_id(id)

func _get_obstacle_solid_ids(obstacle: Node2D) -> Array[Vector2i]:
	var ids: Array[Vector2i] = []
	var obstacle_size := _get_obstacle_size(obstacle)
	if obstacle_size == Vector2.ZERO:
		return ids

	var half_size := obstacle_size * 0.5 + Vector2.ONE * navigation_obstacle_padding
	var min_id := _world_to_path_id(obstacle.global_position - half_size)
	var max_id := _world_to_path_id(obstacle.global_position + half_size)
	for id_x in range(min_id.x, max_id.x + 1):
		for id_y in range(min_id.y, max_id.y + 1):
			var id := Vector2i(id_x, id_y)
			if path_region.has_point(id):
				ids.append(id)
	return ids

func _add_path_solid_id(id: Vector2i) -> void:
	var count: int = path_solid_counts.get(id, 0)
	path_solid_counts[id] = count + 1
	path_grid.set_point_solid(id, true)

func _remove_path_solid_id(id: Vector2i) -> void:
	if not path_solid_counts.has(id):
		return

	var count: int = path_solid_counts[id] - 1
	if count > 0:
		path_solid_counts[id] = count
	else:
		path_solid_counts.erase(id)
		path_grid.set_point_solid(id, false)

func _on_navigation_obstacle_tree_exiting(obstacle: Node2D) -> void:
	unregister_navigation_obstacle(obstacle)

func _get_obstacle_size(obstacle: Node2D) -> Vector2:
	if "collision_size" in obstacle and obstacle.collision_size != Vector2.ZERO:
		return obstacle.collision_size
	if "size" in obstacle:
		return obstacle.size

	var collision_shape := obstacle.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape != null:
		if collision_shape.shape is RectangleShape2D:
			return (collision_shape.shape as RectangleShape2D).size
		if collision_shape.shape is CircleShape2D:
			var radius := (collision_shape.shape as CircleShape2D).radius
			return Vector2(radius * 2.0, radius * 2.0)
	return Vector2.ZERO

func _world_to_path_id(world_position: Vector2) -> Vector2i:
	return Vector2i(
		floori(world_position.x / navigation_cell_size),
		floori(world_position.y / navigation_cell_size)
	)

func _path_id_to_world(id: Vector2i) -> Vector2:
	return Vector2(id) * navigation_cell_size + Vector2.ONE * navigation_cell_size * 0.5

func _find_nearest_walkable_id(start_id: Vector2i) -> Vector2i:
	if path_region.has_point(start_id) and not path_grid.is_point_solid(start_id):
		return start_id

	for radius in range(1, 7):
		for x_offset in range(-radius, radius + 1):
			for y_offset in range(-radius, radius + 1):
				if abs(x_offset) != radius and abs(y_offset) != radius:
					continue
				var id := start_id + Vector2i(x_offset, y_offset)
				if path_region.has_point(id) and not path_grid.is_point_solid(id):
					return id
	return start_id

func _spawn_smash_mark(impact_position: Vector2) -> void:
	var smash_mark_scene := preload("res://scenes/effects/SmashMark.tscn")
	var smash_mark := smash_mark_scene.instantiate() as Node2D
	add_child(smash_mark)
	smash_mark.global_position = impact_position

func _setup_night_atmosphere() -> void:
	# Night canvas modulate (blue-dark tint)
	var canvas_mod := CanvasModulate.new()
	canvas_mod.name = "NightModulate"
	canvas_mod.color = Color(0.55, 0.62, 0.78)
	add_child(canvas_mod)

	# WorldEnvironment with glow
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.03, 0.06)
	env.glow_enabled = true
	env.glow_intensity = 0.4
	env.glow_bloom = 0.1
	env.set_glow_level(0, 0.8)
	env.set_glow_level(1, 0.8)
	env.set_glow_level(2, 0.8)

	var world_env := WorldEnvironment.new()
	world_env.name = "NightEnvironment"
	world_env.environment = env
	add_child(world_env)

	# Ambient spirit particles
	var spirit_mat := ParticleProcessMaterial.new()
	spirit_mat.direction = Vector3(0.0, -1.0, 0.0)
	spirit_mat.spread = 28.0
	spirit_mat.initial_velocity_min = 4.0
	spirit_mat.initial_velocity_max = 10.0
	spirit_mat.gravity = Vector3(0.0, -2.0, 0.0)
	spirit_mat.scale_min = 0.6
	spirit_mat.scale_max = 1.4
	spirit_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	spirit_mat.emission_box_extents = Vector3(680.0, 440.0, 0.0)

	var color_ramp := Gradient.new()
	color_ramp.set_color(0, Color(0.5, 0.85, 1.0, 0.9))
	color_ramp.set_color(1, Color(0.3, 0.6, 1.0, 0.0))
	var ramp_tex := GradientTexture1D.new()
	ramp_tex.gradient = color_ramp
	spirit_mat.color_ramp = ramp_tex

	var spirit_particles := GPUParticles2D.new()
	spirit_particles.name = "SpiritParticles"
	spirit_particles.amount = 72
	spirit_particles.lifetime = 4.2
	spirit_particles.explosiveness = 0.0
	spirit_particles.randomness = 1.0
	spirit_particles.local_coords = false
	spirit_particles.emitting = true
	spirit_particles.process_material = spirit_mat
	spirit_particles.modulate = Color(0.55, 0.88, 1.0, 1.0)
	spirit_particles.z_index = 10
	add_child(spirit_particles)

func _add_slam_charge() -> void:
	slam_charge += 1
	if slam_charge >= slam_charge_required:
		report_combat_message("Slam Charged")
