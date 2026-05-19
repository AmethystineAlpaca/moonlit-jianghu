extends CharacterBody2D

@export var move_speed: float = 115.0
@export var detection_radius: float = 260.0
@export var leash_radius: float = 360.0
@export var return_stop_distance: float = 8.0
@export var attack_range: float = 30.0
@export var attack_windup: float = 0.35
@export var contact_damage: int = 1
@export var attack_hitback_force: float = 42.0
@export var attack_cooldown: float = 0.75
@export var knockback_decay: float = 650.0
@export var recoil_duration: float = 0.16
@export_enum("enemy", "zombie") var faction: String = "enemy"
@export var dead_body_lifetime: float = 10.0
@export var dead_body_fade_duration: float = 1.0
@export var stagger_threshold: float = 3.0
@export var stagger_recoil_duration: float = 0.35
@export var fear_radius: float = 180.0
@export var launched_duration: float = 0.35
@export var launch_speed_threshold: float = 170.0
@export var slam_damage: int = 1
@export var corpse_flight_max_distance: float = 1300.0
@export var corpse_hit_damage: int = 1
@export var steering_probe_distance: float = 34.0
@export var hit_flash_duration: float = 0.14
@export var hit_pulse_scale: float = 1.22
@export var separation_radius: float = 22.0
@export var separation_strength: float = 0.38
@export var zombie_body_tint: Color = Color(0.58, 1.0, 0.42, 1.0)
@export var visual_accent_color: Color = Color(0.98, 0.36, 0.24, 1.0)
@export var destroy_on_death: bool = false

@onready var health_component: HealthComponent = $HealthComponent
@onready var body: Sprite2D = $Body
@onready var facing_marker: Polygon2D = $FacingMarker
@onready var hp_bar: ProgressBar = $HPBar
var active_warning_node: Node2D = null

const SKELETON_IDLE_TEXTURE := preload("res://assets/xianxia/skeleton_idle.png")
const SKELETON_CORPSE_TEXTURE := preload("res://assets/xianxia/skeleton_corpse.png")
const ENEMY_IDLE_TEXTURE := preload("res://assets/xianxia/evil_rogue_enemy_transparent_pack/godot_scaled/enemy_idle.png")
const ENEMY_LEFT_TEXTURE := preload("res://assets/xianxia/evil_rogue_enemy_transparent_pack/godot_scaled/enemy_left.png")
const ENEMY_RIGHT_TEXTURE := preload("res://assets/xianxia/evil_rogue_enemy_transparent_pack/godot_scaled/enemy_right.png")
const ENEMY_UP_TEXTURE := preload("res://assets/xianxia/evil_rogue_enemy_transparent_pack/godot_scaled/enemy_up.png")
const ENEMY_DOWN_TEXTURE := preload("res://assets/xianxia/evil_rogue_enemy_transparent_pack/godot_scaled/enemy_down.png")

var soul_accent_visual: Polygon2D
var bone_weapon_visual: Polygon2D
var current_target: Node2D
var home_position: Vector2
var facing_direction: Vector2 = Vector2.DOWN
var current_stagger: float = 0.0
var always_chase: bool = false
var attack_timer: float = 0.0
var windup_timer: float = 0.0
var is_winding_up: bool = false
var knockback_velocity: Vector2 = Vector2.ZERO
var hit_flash_timer: float = 0.0
var hit_pulse_timer: float = 0.0
var attack_release_timer: float = 0.0
var recoil_timer: float = 0.0
var launched_timer: float = 0.0
var corpse_flight_timer: float = 0.0
var corpse_start_position: Vector2 = Vector2.ZERO
var slammed_bodies := {}
var is_dying: bool = false
var is_dead_body_settled: bool = false
var death_timer: float = 0.0
var normal_body_scale: Vector2 = Vector2.ONE
var visual_time: float = 0.0
var _run_anim_timer: float = 0.0
var _run_anim_frame: int = 0
const RUN_ANIM_FPS: float = 7.0
var attack_snap_timer: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	_setup_skeleton_visuals()
	_assign_faction_groups()
	_apply_faction_visuals()
	normal_body_scale = body.scale
	body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	home_position = global_position
	current_target = find_nearest_target()
	health_component.health_changed.connect(_on_health_changed)
	health_component.damaged.connect(_on_damaged)
	health_component.died.connect(_on_died)
	_on_health_changed(health_component.current_health, health_component.max_health)

func _physics_process(delta: float) -> void:
	visual_time += delta
	if is_dying:
		_update_skeleton_animation(delta)
		_update_death_flight(delta)
		return

	if attack_timer > 0.0:
		attack_timer -= delta
	if windup_timer > 0.0:
		windup_timer -= delta
	if attack_snap_timer > 0.0:
		attack_snap_timer -= delta
	if hit_flash_timer > 0.0:
		hit_flash_timer -= delta
		if hit_flash_timer <= 0.0:
			_apply_faction_visuals()
	if hit_pulse_timer > 0.0:
		hit_pulse_timer -= delta
		var pulse_duration := maxf(hit_flash_duration, 0.001)
		var pulse_t := clampf(hit_pulse_timer / pulse_duration, 0.0, 1.0)
		body.scale = normal_body_scale.lerp(normal_body_scale * hit_pulse_scale, pulse_t)
		if hit_pulse_timer <= 0.0:
			body.scale = normal_body_scale * 1.08 if is_winding_up else normal_body_scale
	if attack_release_timer > 0.0:
		attack_release_timer -= delta
		facing_marker.scale = Vector2.ONE * 1.25
		if attack_release_timer <= 0.0:
			attack_release_timer = 0.0
			facing_marker.scale = Vector2.ONE
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)
	if launched_timer > 0.0:
		launched_timer -= delta
		_check_slam_collisions()
	if recoil_timer > 0.0:
		recoil_timer -= delta
		_cancel_windup()
		velocity = knockback_velocity
		move_and_slide()
		if launched_timer > 0.0:
			_check_slam_collisions()
		return

	current_target = find_nearest_target()
	if current_target == null:
		velocity = knockback_velocity
		move_and_slide()
		return

	var to_target := current_target.global_position - global_position
	var distance_to_target := to_target.length()
	var distance_from_home := global_position.distance_to(home_position)

	if not always_chase and (distance_from_home > leash_radius or current_target.global_position.distance_to(home_position) > leash_radius):
		_return_home()
		return

	if not always_chase and distance_to_target > detection_radius:
		_idle(delta)
		return

	var direction := to_target.normalized()
	if direction != Vector2.ZERO:
		facing_direction = direction
		facing_marker.rotation = direction.angle() - PI * 0.5

	if distance_to_target > attack_range:
		_cancel_windup()
		velocity = _get_path_direction(direction) * move_speed + knockback_velocity + _compute_separation_force()
	else:
		velocity = knockback_velocity
		_update_attack_windup(delta)

	move_and_slide()
	_update_skeleton_animation(delta)

func apply_knockback(direction: Vector2, force: float) -> void:
	if direction == Vector2.ZERO:
		return
	knockback_velocity = direction.normalized() * force
	recoil_timer = recoil_duration
	if force >= launch_speed_threshold:
		launched_timer = launched_duration
		slammed_bodies.clear()

func apply_attack_hitback(direction: Vector2, force: float) -> void:
	if direction == Vector2.ZERO or force <= 0.0:
		return
	knockback_velocity = direction.normalized() * force

func set_survival_mode(enabled: bool) -> void:
	always_chase = enabled
	detection_radius = 9999.0
	leash_radius = 9999.0

func find_nearest_target() -> Node2D:
	var best_target: Node2D = null
	var best_distance := INF
	for candidate in _collect_target_candidates():
		if not _is_valid_target(candidate):
			continue
		var distance := global_position.distance_squared_to(candidate.global_position)
		if distance < best_distance:
			best_distance = distance
			best_target = candidate
	return best_target

func is_attack_target_active() -> bool:
	return not is_dying

func is_transformable_corpse() -> bool:
	return is_dying and not is_queued_for_deletion()

func get_visual_accent_color() -> Color:
	if faction == "zombie":
		return visual_accent_color.lerp(zombie_body_tint, 0.35)
	return visual_accent_color

func _assign_faction_groups() -> void:
	if faction == "zombie":
		add_to_group("zombies")
		remove_from_group("hostile_enemies")
	else:
		add_to_group("hostile_enemies")
		remove_from_group("zombies")

func _apply_faction_visuals() -> void:
	if faction == "zombie":
		body.modulate = Color(0.78, 1.0, 0.72, 1.0)
	else:
		body.modulate = Color.WHITE
	if soul_accent_visual != null:
		soul_accent_visual.color = get_visual_accent_color()
	if bone_weapon_visual != null:
		bone_weapon_visual.color = get_visual_accent_color().lerp(Color(0.88, 0.86, 0.72, 1.0), 0.35)

func _collect_target_candidates() -> Array[Node2D]:
	var candidates: Array[Node2D] = []
	var groups: Array[String] = []
	if faction == "zombie":
		groups.append("hostile_enemies")
	else:
		groups.append("player")
		groups.append("zombies")

	for group_name in groups:
		for node in get_tree().get_nodes_in_group(group_name):
			if node is Node2D:
				candidates.append(node as Node2D)
	return candidates

func _is_valid_target(candidate: Node2D) -> bool:
	if candidate == null or candidate == self or not is_instance_valid(candidate):
		return false
	if candidate.has_method("is_attack_target_active"):
		return candidate.is_attack_target_active()
	return true

func _compute_separation_force() -> Vector2:
	var force := Vector2.ZERO
	for node in get_tree().get_nodes_in_group("enemies"):
		if node == self or not is_instance_valid(node):
			continue
		var other := node as Node2D
		var diff := global_position - other.global_position
		var dist := diff.length()
		if dist > 0.01 and dist < separation_radius:
			force += diff.normalized() * (1.0 - dist / separation_radius) * move_speed * separation_strength
	return force

func _get_chase_direction(preferred_direction: Vector2) -> Vector2:
	if preferred_direction == Vector2.ZERO:
		return Vector2.ZERO
	if not _is_direction_blocked(preferred_direction):
		return preferred_direction

	var best_direction := Vector2.ZERO
	var best_score := INF
	for angle in [PI * 0.28, -PI * 0.28, PI * 0.5, -PI * 0.5, PI * 0.72, -PI * 0.72]:
		var candidate := preferred_direction.rotated(angle).normalized()
		if _is_direction_blocked(candidate):
			continue

		var probe_position := global_position + candidate * steering_probe_distance
		var target_position := global_position + preferred_direction
		if current_target != null and is_instance_valid(current_target):
			target_position = current_target.global_position
		var score := probe_position.distance_to(target_position) - candidate.dot(preferred_direction) * 18.0
		if score < best_score:
			best_score = score
			best_direction = candidate

	if best_direction != Vector2.ZERO:
		return best_direction

	return preferred_direction.rotated(PI * 0.5).normalized()

func _is_direction_blocked(direction: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + direction.normalized() * steering_probe_distance
	)
	query.exclude = [get_rid()]
	query.collide_with_bodies = true
	query.collide_with_areas = false
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return false
	var collider := hit.get("collider") as Node
	if collider != null and collider.is_in_group("corpses"):
		return true
	return collider != null and not collider.is_in_group("player") and not collider.is_in_group("enemies")

func _get_path_direction(fallback_direction: Vector2) -> Vector2:
	var world := get_tree().get_first_node_in_group("world")
	if world != null and world.has_method("get_path_direction") and current_target != null:
		var path_direction: Vector2 = world.get_path_direction(global_position, current_target.global_position)
		if path_direction != Vector2.ZERO:
			facing_direction = path_direction
			facing_marker.rotation = path_direction.angle() - PI * 0.5
			return _get_chase_direction(path_direction)
	return _get_chase_direction(fallback_direction)

func apply_recoil(duration: float) -> void:
	recoil_timer = maxf(recoil_timer, duration)
	_cancel_windup()

func apply_stagger(amount: float) -> void:
	if amount <= 0.0 or is_dying:
		return

	current_stagger += amount
	if current_stagger >= stagger_threshold:
		current_stagger = 0.0
		apply_recoil(stagger_recoil_duration)
		body.modulate = Color(1.0, 0.78, 0.2, 1.0)
		body.scale = normal_body_scale * 1.16
		hit_flash_timer = 0.22
		hit_pulse_timer = 0.22

func trigger_fear_from(source_position: Vector2) -> void:
	if is_dying:
		return

	var away := global_position - source_position
	if away == Vector2.ZERO:
		away = facing_direction
	apply_knockback(away.normalized(), 150.0)
	apply_recoil(0.28)

func is_hit_from_behind(attacker_position: Vector2) -> bool:
	var to_attacker := (attacker_position - global_position).normalized()
	if to_attacker == Vector2.ZERO:
		return false
	return facing_direction.dot(to_attacker) < -0.35

func _check_slam_collisions() -> void:
	if knockback_velocity.length() < launch_speed_threshold * 0.35:
		return

	for index in range(get_slide_collision_count()):
		var collision := get_slide_collision(index)
		var collider := collision.get_collider() as Node
		if collider == null or slammed_bodies.has(collider):
			continue
		slammed_bodies[collider] = true
		if collider.is_in_group("enemies"):
			_handle_enemy_slam(collider as Node2D)
		elif collider.is_in_group("breakables"):
			_handle_breakable_slam(collider)
		else:
			_handle_wall_slam(collision.get_position())

func _handle_enemy_slam(other_enemy: Node2D) -> void:
	var other_health := other_enemy.get_node_or_null("HealthComponent") as HealthComponent
	if other_health != null:
		other_health.take_damage(slam_damage)
	if other_enemy.has_method("apply_knockback"):
		other_enemy.apply_knockback((other_enemy.global_position - global_position).normalized(), 180.0)
	if other_enemy.has_method("apply_recoil"):
		other_enemy.apply_recoil(0.25)
	_take_slam_damage("Crowd Crush", other_enemy.global_position)

func _handle_breakable_slam(breakable: Node) -> void:
	if breakable.has_method("shatter"):
		breakable.shatter()
	_take_slam_damage("Shatter", (breakable as Node2D).global_position)

func _handle_wall_slam(impact_position: Vector2) -> void:
	_take_slam_damage("Wall Slam", impact_position)

func _take_slam_damage(message: String, impact_position: Vector2) -> void:
	launched_timer = 0.0
	apply_recoil(0.28)
	health_component.take_damage(slam_damage)
	var world := get_tree().get_first_node_in_group("world")
	if world != null and world.has_method("report_slam"):
		world.report_slam(message, impact_position)

func _idle(delta: float) -> void:
	_cancel_windup()
	velocity = velocity.move_toward(Vector2.ZERO, move_speed * 4.0 * delta) + knockback_velocity
	move_and_slide()

func _return_home() -> void:
	_cancel_windup()
	var to_home := home_position - global_position
	if to_home.length() <= return_stop_distance:
		velocity = knockback_velocity
	else:
		var direction := to_home.normalized()
		facing_direction = direction
		facing_marker.rotation = direction.angle() - PI * 0.5
		velocity = direction * move_speed + knockback_velocity
	move_and_slide()

func _update_attack_windup(_delta: float) -> void:
	if attack_timer > 0.0:
		_cancel_windup()
		return

	if not is_winding_up:
		is_winding_up = true
		windup_timer = attack_windup
		body.scale = normal_body_scale * 1.08
		facing_marker.color = Color(1.0, 0.35, 0.2, 1.0)
		if current_target != null and is_instance_valid(current_target) and current_target.is_in_group("player"):
			active_warning_node = current_target.get_node_or_null("AttackWarning")
			if active_warning_node:
				active_warning_node.visible = true
		return

	if windup_timer <= 0.0:
		is_winding_up = false
		body.scale = normal_body_scale
		facing_marker.color = Color(1.0, 0.82, 0.68, 1.0)
		if active_warning_node:
			active_warning_node.visible = false
			active_warning_node = null
		attack_snap_timer = 0.16
		attack_release_timer = 0.12
		facing_marker.scale = Vector2.ONE * 1.25
		_try_damage_player()

func _cancel_windup() -> void:
	if not is_winding_up:
		return
	is_winding_up = false
	body.scale = normal_body_scale
	facing_marker.color = Color(1.0, 0.82, 0.68, 1.0)
	if active_warning_node:
		active_warning_node.visible = false
		active_warning_node = null

func _try_damage_player() -> void:
	if attack_timer > 0.0:
		return

	if current_target == null or not is_instance_valid(current_target) or not _is_valid_target(current_target):
		current_target = find_nearest_target()
	if current_target == null:
		return

	var target_health := current_target.get_node_or_null("HealthComponent") as HealthComponent
	if current_target.has_method("handle_enemy_attack"):
		current_target.handle_enemy_attack(contact_damage, self)
		attack_timer = attack_cooldown
	elif current_target.has_method("apply_incoming_damage"):
		current_target.apply_incoming_damage(contact_damage)
		attack_timer = attack_cooldown
	elif target_health != null and target_health.has_method("take_damage"):
		target_health.take_damage(contact_damage)
		attack_timer = attack_cooldown

	if attack_timer > 0.0:
		_apply_attack_hitback(current_target)

func _apply_attack_hitback(target: Node2D) -> void:
	if target == null or not is_instance_valid(target):
		return

	var hit_direction := (target.global_position - global_position).normalized()
	if hit_direction == Vector2.ZERO:
		hit_direction = facing_direction

	if target.has_method("apply_attack_hitback"):
		target.apply_attack_hitback(hit_direction, attack_hitback_force)
	elif target.has_method("apply_knockback"):
		target.apply_knockback(hit_direction, attack_hitback_force)

func _on_health_changed(current_health: int, max_health: int) -> void:
	hp_bar.max_value = max_health
	hp_bar.value = current_health

func _on_damaged(_amount: int) -> void:
	body.modulate = Color(1.0, 0.42, 0.18, 1.0)
	body.scale = normal_body_scale * hit_pulse_scale
	hit_flash_timer = hit_flash_duration
	hit_pulse_timer = hit_flash_duration
	var tilt_dir := -knockback_velocity.normalized() if knockback_velocity.length() > 1.0 else -facing_direction
	body.rotation = tilt_dir.angle() * 0.12
	var tween := create_tween()
	tween.tween_property(body, "rotation", 0.0, 0.14)
	if soul_accent_visual != null:
		soul_accent_visual.modulate = Color(2.0, 2.0, 2.0, 1.0)
		var accent_tween := create_tween()
		accent_tween.tween_property(soul_accent_visual, "modulate", Color.WHITE, 0.18)

func _on_died() -> void:
	attack_release_timer = 0.0
	facing_marker.scale = Vector2.ONE
	if faction == "zombie" or destroy_on_death:
		queue_free()
		return

	is_dying = true
	add_to_group("corpses")
	remove_from_group("hostile_enemies")
	remove_from_group("zombies")
	is_dead_body_settled = false
	death_timer = 0.0
	corpse_flight_timer = 1.0
	corpse_start_position = global_position
	if knockback_velocity.length() < launch_speed_threshold:
		knockback_velocity = facing_direction.normalized() * launch_speed_threshold
	velocity = knockback_velocity
	slammed_bodies.clear()
	_cancel_windup()
	hp_bar.visible = false
	body.texture = SKELETON_CORPSE_TEXTURE
	body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	body.modulate = Color(0.62, 0.60, 0.58, 1.0)
	body.scale = normal_body_scale
	modulate.a = 1.0

func _build_accent_material() -> CanvasItemMaterial:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return mat

func _setup_skeleton_visuals() -> void:
	body.texture = SKELETON_IDLE_TEXTURE if faction == "zombie" else ENEMY_IDLE_TEXTURE
	body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	body.centered = true
	facing_marker.visible = false

	soul_accent_visual = get_node_or_null("SoulAccent") as Polygon2D
	if soul_accent_visual == null:
		soul_accent_visual = Polygon2D.new()
		soul_accent_visual.name = "SoulAccent"
		add_child(soul_accent_visual)
		move_child(soul_accent_visual, body.get_index() + 1)
	soul_accent_visual.polygon = PackedVector2Array([
		Vector2(0, -18), Vector2(5, -10), Vector2(0, -4), Vector2(-5, -10)
	])
	soul_accent_visual.color = get_visual_accent_color()
	soul_accent_visual.material = _build_accent_material()
	soul_accent_visual.z_index = 3
	soul_accent_visual.visible = false

	bone_weapon_visual = get_node_or_null("BoneWeapon") as Polygon2D
	if bone_weapon_visual == null:
		bone_weapon_visual = Polygon2D.new()
		bone_weapon_visual.name = "BoneWeapon"
		add_child(bone_weapon_visual)
		move_child(bone_weapon_visual, body.get_index() + 1)
	bone_weapon_visual.polygon = PackedVector2Array([Vector2(8, -4), Vector2(18, -8), Vector2(20, -5), Vector2(10, 2)])
	bone_weapon_visual.color = get_visual_accent_color().lerp(Color(0.88, 0.86, 0.72, 1.0), 0.35)
	bone_weapon_visual.z_index = 2
	bone_weapon_visual.visible = false

func _build_skeleton_texture(accent: Color, corrupted: bool) -> Texture2D:
	var image := Image.create(30, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var bone := Color(0.82, 0.80, 0.70, 1.0)
	var bone_light := Color(0.95, 0.92, 0.78, 1.0)
	var bone_shadow := Color(0.45, 0.42, 0.35, 1.0)
	if corrupted:
		bone = bone.lerp(zombie_body_tint, 0.18)
		bone_light = bone_light.lerp(zombie_body_tint, 0.14)
	_fill_rect(image, Rect2i(10, 2, 10, 8), bone_light)
	_fill_rect(image, Rect2i(9, 4, 12, 5), bone)
	_fill_rect(image, Rect2i(12, 6, 2, 2), Color(0.04, 0.04, 0.04, 1.0))
	_fill_rect(image, Rect2i(17, 6, 2, 2), Color(0.04, 0.04, 0.04, 1.0))
	_fill_rect(image, Rect2i(13, 11, 5, 12), bone)
	_fill_rect(image, Rect2i(11, 13, 9, 2), bone_light)
	_fill_rect(image, Rect2i(11, 18, 9, 2), bone_shadow)
	_fill_rect(image, Rect2i(7, 13, 4, 11), bone)
	_fill_rect(image, Rect2i(20, 13, 4, 11), bone)
	_fill_rect(image, Rect2i(11, 23, 4, 7), bone)
	_fill_rect(image, Rect2i(17, 23, 4, 7), bone)
	_fill_rect(image, Rect2i(14, 7, 4, 2), accent)
	_fill_rect(image, Rect2i(14, 16, 4, 2), accent.darkened(0.25))
	return ImageTexture.create_from_image(image)

func _build_skeleton_corpse_texture(accent: Color) -> Texture2D:
	var image := Image.create(32, 24, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var bone := Color(0.72, 0.70, 0.62, 1.0)
	var shadow := Color(0.36, 0.34, 0.30, 1.0)
	_fill_rect(image, Rect2i(5, 12, 14, 4), bone)
	_fill_rect(image, Rect2i(18, 10, 8, 6), bone)
	_fill_rect(image, Rect2i(8, 16, 17, 2), shadow)
	_fill_rect(image, Rect2i(20, 12, 2, 2), Color(0.03, 0.03, 0.03, 1.0))
	_fill_rect(image, Rect2i(24, 12, 2, 2), Color(0.03, 0.03, 0.03, 1.0))
	_fill_rect(image, Rect2i(9, 9, 12, 2), accent)
	_fill_rect(image, Rect2i(14, 7, 4, 2), accent.lightened(0.18))
	return ImageTexture.create_from_image(image)

func _update_skeleton_animation(_delta: float) -> void:
	var moving := velocity.length() > 8.0
	var bob := sin(visual_time * (14.0 if moving else 4.0)) * (1.4 if moving else 0.35)
	var sway := sin(visual_time * (10.0 if moving else 3.0)) * (0.05 if moving else 0.018)
	if is_dying:
		body.position = Vector2(0.0, 4.0)
		body.rotation = 0.0
	elif attack_snap_timer > 0.0:
		body.position = facing_direction * 4.0
		body.rotation = facing_direction.angle() * 0.025
	elif is_winding_up:
		body.position = -facing_direction * 2.5 + Vector2(0.0, bob)
		body.rotation = -facing_direction.angle() * 0.02
	else:
		body.position = Vector2(0.0, bob)
		body.rotation = sway
	_update_enemy_direction_texture(moving, _delta)

func _update_enemy_direction_texture(moving: bool, delta: float) -> void:
	if faction == "zombie" or is_dying:
		return
	if not moving:
		body.texture = ENEMY_IDLE_TEXTURE
		_run_anim_frame = 0
		_run_anim_timer = 0.0
		return
	_run_anim_timer -= delta
	if _run_anim_timer <= 0.0:
		_run_anim_frame = (_run_anim_frame + 1) % 2
		_run_anim_timer = 1.0 / RUN_ANIM_FPS
	if _run_anim_frame == 0:
		body.texture = ENEMY_IDLE_TEXTURE
		return
	var abs_x := absf(facing_direction.x)
	var abs_y := absf(facing_direction.y)
	if abs_x >= abs_y:
		body.texture = ENEMY_RIGHT_TEXTURE if facing_direction.x >= 0.0 else ENEMY_LEFT_TEXTURE
	else:
		body.texture = ENEMY_DOWN_TEXTURE if facing_direction.y >= 0.0 else ENEMY_UP_TEXTURE


func _fill_rect(image: Image, rect: Rect2i, fill: Color) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height():
				image.set_pixel(x, y, fill)

func _update_death_flight(delta: float) -> void:
	death_timer += delta

	if not is_dead_body_settled and global_position.distance_to(corpse_start_position) >= corpse_flight_max_distance:
		settle_dead_body()

	if not is_dead_body_settled and corpse_flight_timer > 0.0 and knockback_velocity.length() > 20.0:
		corpse_flight_timer -= delta
		velocity = knockback_velocity
		move_and_slide()
		_check_corpse_collisions()
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)
		return

	if not is_dead_body_settled:
		settle_dead_body()

	_update_dead_body_fade()

func settle_dead_body() -> void:
	if is_dead_body_settled:
		return

	is_dead_body_settled = true
	corpse_flight_timer = 0.0
	knockback_velocity = Vector2.ZERO
	velocity = Vector2.ZERO
	var world := get_tree().get_first_node_in_group("world")
	if world != null and world.has_method("register_navigation_obstacle"):
		world.register_navigation_obstacle(self)

func _check_corpse_collisions() -> void:
	for index in range(get_slide_collision_count()):
		var collision := get_slide_collision(index)
		var collider := collision.get_collider() as Node
		if collider == null or collider == self or slammed_bodies.has(collider):
			continue
		slammed_bodies[collider] = true
		if collider.is_in_group("enemies"):
			var other_enemy := collider as Node2D
			var other_health := other_enemy.get_node_or_null("HealthComponent") as HealthComponent
			if other_health != null:
				other_health.take_damage(corpse_hit_damage)
			var hit_direction := (other_enemy.global_position - global_position).normalized()
			if hit_direction == Vector2.ZERO:
				hit_direction = knockback_velocity.normalized()
			if other_enemy.has_method("apply_knockback"):
				other_enemy.apply_knockback(hit_direction, 210.0)
			if other_enemy.has_method("apply_recoil"):
				other_enemy.apply_recoil(0.28)
			var world := get_tree().get_first_node_in_group("world")
			if world != null and world.has_method("report_slam"):
				world.report_slam("Corpse Hit", other_enemy.global_position)
			settle_dead_body()
			return
		else:
			var world := get_tree().get_first_node_in_group("world")
			if world != null and world.has_method("report_slam"):
				world.report_slam("Body Slam", collision.get_position())
			settle_dead_body()
			return

func _update_dead_body_fade() -> void:
	if death_timer < dead_body_lifetime:
		modulate.a = 1.0
		return

	var fade_duration := maxf(dead_body_fade_duration, 0.01)
	var fade_t := clampf((death_timer - dead_body_lifetime) / fade_duration, 0.0, 1.0)
	modulate.a = 1.0 - fade_t

	if fade_t >= 1.0:
		queue_free()
