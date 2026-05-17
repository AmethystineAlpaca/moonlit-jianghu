extends CharacterBody2D

signal stamina_changed(current_stamina: float, max_stamina: float)
signal exhaustion_changed(is_exhausted: bool)
signal blocked
signal combat_message_requested(message: String)
signal skill_slots_changed(slot_names: Array[String])
signal active_skill_slots_changed(active_states: Array)

@export var move_speed: float = 180.0
@export var acceleration: float = 1200.0
@export var deceleration: float = 1400.0
@export var melee_damage: int = 1
@export var melee_range: float = 38.0
@export var melee_size: Vector2 = Vector2(54.0, 34.0)
@export var melee_cooldown: float = 0.35
@export var melee_lunge_force: float = 90.0
@export var melee_knockback_force: float = 420.0
@export var hit_pause_duration: float = 0.055
@export var max_stamina: float = 10.0
@export var attack_stamina_cost: float = 2.0
@export var stamina_regen_per_second: float = 2.5
@export var defend_stamina_per_second: float = 4.0
@export var defend_block_amount: int = 1
@export var defend_move_speed_multiplier: float = 0.55
@export var dash_stamina_cost: float = 3.0
@export var dash_speed: float = 520.0
@export var dash_duration: float = 0.14
@export var dash_cooldown: float = 0.35
@export var perfect_guard_window: float = 0.25
@export var perfect_guard_stamina_restore: float = 4.0
@export var counter_window: float = 1.5
@export var counter_damage_bonus: int = 2
@export var counter_knockback_bonus: float = 180.0
@export var normal_stagger_amount: float = 1.0
@export var counter_stagger_amount: float = 2.5
@export var momentum_stagger_bonus: float = 0.75
@export var back_attack_damage_bonus: int = 1
@export var hurt_flash_duration: float = 0.18
@export var hurt_pulse_scale: float = 1.28
@export var attack_hitback_decay: float = 360.0
@export var sword_rest_offset: float = -0.35
@export var sword_swing_arc: float = 1.35
@export var sword_swing_duration: float = 0.16

@onready var facing_marker: Polygon2D = $FacingMarker
@onready var body: Sprite2D = $Body
@onready var selection_ring: Polygon2D = $SelectionRing
@onready var health_component: HealthComponent = $HealthComponent
@onready var guard_ring: Polygon2D = $GuardRing
@onready var damage_ring: Polygon2D = $DamageRing
@onready var attack_preview: Node2D = $AttackPreview
@onready var attack_preview_visual: Polygon2D = $AttackPreview/Visual
@onready var skill_caster: SkillCaster = $SkillCaster
@onready var sword: Node2D = get_node_or_null("Sword") as Node2D

const HIT_SPARK_SCENE := preload("res://scenes/effects/HitSpark.tscn")
const SLASH_TRAIL_SCENE := preload("res://scenes/effects/SlashTrail.tscn")
const TRANSFORM_SKILL := preload("res://resources/skills/Transform.tres")
const DIVINE_LIGHT_SKILL := preload("res://resources/skills/ProtectiveDivineLight.tres")
const ATTACK_VARIANT_NORMAL := "normal"
const ATTACK_VARIANT_COUNTER := "counter"
const ATTACK_VARIANT_BACK_HIT := "back_hit"
const ATTACK_VARIANT_MOMENTUM := "momentum"
const ATTACK_VARIANT_IMPACT := "impact"
const GLOW_OUTLINE_SHADER := preload("res://resources/shaders/glow_outline.gdshader")

var sword_visual: Sprite2D
var sword_mount: Node2D
var robe_sash_visual: Polygon2D
var last_facing_direction: Vector2 = Vector2.DOWN
var current_stamina: float
var melee_timer: float = 0.0
var attack_preview_timer: float = 0.0
var attack_visual_timer: float = 0.0
var sword_swing_timer: float = 0.0
var sword_swing_strength: float = 1.0
var hurt_flash_timer: float = 0.0
var hurt_pulse_timer: float = 0.0
var damage_ring_timer: float = 0.0
var block_ring_timer: float = 0.0
var perfect_guard_timer: float = 0.0
var counter_ready_timer: float = 0.0
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO
var attack_hitback_velocity: Vector2 = Vector2.ZERO
var current_input_direction: Vector2 = Vector2.ZERO
var selected_skill_slot: int = 0
var active_skill_slots: Array[bool] = [false, false, false, false, false]
var is_defending: bool = false
var is_exhausted: bool = false
var is_defeated: bool = false
var normal_body_scale: Vector2 = Vector2.ONE
var visual_time: float = 0.0
var _afterimage_timer: float = 0.0
var _afterimage_interval_move: float = 0.07
var _afterimage_interval_dash: float = 0.035

func _ready() -> void:
	_setup_xianxia_visuals()
	normal_body_scale = body.scale
	current_stamina = max_stamina
	health_component.damaged.connect(_on_damaged)
	health_component.died.connect(_on_died)
	if skill_caster != null:
		_ensure_default_transform_skill()
		skill_caster.skill_slots_changed.connect(_on_skill_slots_changed)
		skill_caster.skill_cast_failed.connect(_on_skill_cast_failed)
		skill_caster.skill_cast_started.connect(_on_skill_cast_started)
		skill_caster.active_slots_changed.connect(_on_active_slots_changed)
		active_skill_slots = skill_caster.get_active_slots()
	stamina_changed.emit(current_stamina, max_stamina)
	skill_slots_changed.emit(get_skill_slot_names())
	active_skill_slots_changed.emit(active_skill_slots)

func _physics_process(delta: float) -> void:
	visual_time += delta
	if hurt_flash_timer > 0.0:
		hurt_flash_timer -= delta
		if hurt_flash_timer <= 0.0:
			_refresh_body_feedback()
	if hurt_pulse_timer > 0.0:
		hurt_pulse_timer -= delta
		var pulse_duration := maxf(hurt_flash_duration, 0.001)
		var pulse_t := clampf(hurt_pulse_timer / pulse_duration, 0.0, 1.0)
		body.scale = normal_body_scale.lerp(normal_body_scale * hurt_pulse_scale, pulse_t)
		if hurt_pulse_timer <= 0.0:
			body.scale = normal_body_scale
	if damage_ring_timer > 0.0:
		damage_ring_timer -= delta
		var damage_t := clampf(damage_ring_timer / 0.2, 0.0, 1.0)
		damage_ring.scale = Vector2.ONE.lerp(Vector2(1.45, 1.45), 1.0 - damage_t)
		damage_ring.modulate.a = damage_t
		if damage_ring_timer <= 0.0:
			damage_ring.visible = false
	if block_ring_timer > 0.0:
		block_ring_timer -= delta
		if block_ring_timer <= 0.0:
			_refresh_body_feedback()
	if perfect_guard_timer > 0.0:
		perfect_guard_timer -= delta
	if counter_ready_timer > 0.0:
		counter_ready_timer -= delta
		if counter_ready_timer <= 0.0:
			counter_ready_timer = 0.0
			_refresh_body_feedback()
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta
	attack_hitback_velocity = attack_hitback_velocity.move_toward(Vector2.ZERO, attack_hitback_decay * delta)

	if is_defeated:
		velocity = attack_hitback_velocity
		move_and_slide()
		return

	_update_defense(delta)

	if melee_timer > 0.0:
		melee_timer -= delta
	if attack_preview_timer > 0.0:
		attack_preview_timer -= delta
		if attack_preview_timer <= 0.0:
			attack_preview.visible = false
	if attack_visual_timer > 0.0:
		attack_visual_timer -= delta

	var input_direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)
	current_input_direction = input_direction

	if input_direction != Vector2.ZERO:
		last_facing_direction = input_direction
		facing_marker.rotation = last_facing_direction.angle() - PI * 0.5

	_update_sword_feedback(delta)

	if Input.is_action_just_pressed("dash"):
		_try_dash(input_direction)

	_handle_skill_input()

	if dash_timer > 0.0:
		dash_timer -= delta
		velocity = dash_direction * dash_speed + attack_hitback_velocity
		move_and_slide()
		return

	var effective_move_speed := move_speed
	if is_defending:
		effective_move_speed *= defend_move_speed_multiplier

	var target_velocity := input_direction * effective_move_speed
	var rate := acceleration
	if input_direction == Vector2.ZERO:
		rate = deceleration

	velocity = velocity.move_toward(target_velocity, rate * delta) + attack_hitback_velocity
	move_and_slide()

	if Input.is_action_just_pressed("attack"):
		_try_melee_attack()

	_update_xianxia_animation(delta)

func _try_melee_attack() -> void:
	if melee_timer > 0.0 or is_defending or is_exhausted or current_stamina < attack_stamina_cost or dash_timer > 0.0:
		return

	melee_timer = melee_cooldown
	attack_visual_timer = 0.18
	_set_stamina(current_stamina - attack_stamina_cost)
	_show_attack_preview()
	var world := get_tree().get_first_node_in_group("world")
	var _is_slam: bool = world != null and world.has_method("has_slam_charge") and world.has_slam_charge()
	var _is_counter: bool = counter_ready_timer > 0.0
	var _has_momentum: bool = current_input_direction != Vector2.ZERO and current_input_direction.dot(last_facing_direction) > 0.75
	_spawn_slash_trail(_choose_attack_variant(_is_slam, _is_counter, _has_momentum, false))
	_start_sword_swing(1.0)
	velocity += last_facing_direction * melee_lunge_force

	var is_counter_attack := counter_ready_timer > 0.0
	var has_momentum := current_input_direction != Vector2.ZERO and current_input_direction.dot(last_facing_direction) > 0.75
	var attack_damage := melee_damage
	var attack_knockback := melee_knockback_force
	var stagger_amount := normal_stagger_amount
	var is_impact_attack: bool = world != null and world.has_method("has_slam_charge") and world.has_slam_charge()
	if is_impact_attack:
		attack_knockback += 260.0
		stagger_amount += 2.0
	if is_counter_attack:
		attack_damage += counter_damage_bonus
		attack_knockback += counter_knockback_bonus
		stagger_amount = counter_stagger_amount
		counter_ready_timer = 0.0
		_refresh_body_feedback()
	if has_momentum:
		attack_knockback += 110.0
		stagger_amount += momentum_stagger_bonus

	var shape := RectangleShape2D.new()
	shape.size = melee_size

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(
		last_facing_direction.angle(),
		global_position + last_facing_direction * melee_range
	)
	query.exclude = [get_rid()]
	query.collide_with_bodies = true
	query.collide_with_areas = false

	var hits := get_world_2d().direct_space_state.intersect_shape(query, 16)
	var damaged_enemies := {}
	var landed_hit := false
	var landed_back_hit := false
	for hit in hits:
		var collider := hit.get("collider") as Node
		if collider == null or not collider.is_in_group("enemies"):
			continue
		if collider.is_in_group("zombies"):
			continue
		if damaged_enemies.has(collider):
			continue

		var health := collider.get_node_or_null("HealthComponent") as HealthComponent
		if health != null and health.has_method("take_damage"):
			if collider.has_method("apply_knockback"):
				collider.apply_knockback(last_facing_direction, attack_knockback)
			var final_damage := attack_damage
			var is_back_hit: bool = collider.has_method("is_hit_from_behind") and collider.is_hit_from_behind(global_position)
			var final_stagger_amount := stagger_amount
			if is_back_hit:
				landed_back_hit = true
				final_damage += back_attack_damage_bonus
				final_stagger_amount += 0.75
			if collider.has_method("apply_stagger"):
				collider.apply_stagger(final_stagger_amount)
			var attack_variant := _choose_attack_variant(is_impact_attack, is_counter_attack, has_momentum, is_back_hit)
			_spawn_hit_spark(collider.global_position, attack_variant)
			health.take_damage(final_damage)
			damaged_enemies[collider] = true
			landed_hit = true

	if landed_hit:
		if is_impact_attack and world != null and world.has_method("consume_slam_charge"):
			world.consume_slam_charge()
		var combat_message := _choose_combat_message(is_impact_attack, is_counter_attack, has_momentum, landed_back_hit)
		if combat_message != "":
			combat_message_requested.emit(combat_message)
		_apply_hit_pause()

func _handle_skill_input() -> void:
	for index in range(5):
		if Input.is_action_just_pressed("select_skill_%s" % [index + 1]):
			_toggle_skill_slot(index)
			return

func _toggle_skill_slot(slot_index: int) -> void:
	if skill_caster == null:
		return
	skill_caster.toggle_slot(slot_index)

func _show_attack_preview() -> void:
	var half_width := melee_size.x * 0.5
	var reach := melee_size.y
	attack_preview_visual.polygon = PackedVector2Array(
		[
			Vector2.ZERO,
			Vector2(reach, -half_width),
			Vector2(reach + 14.0, 0.0),
			Vector2(reach, half_width)
		]
	)
	attack_preview.position = last_facing_direction * melee_range
	attack_preview.rotation = last_facing_direction.angle()
	attack_preview.visible = true
	attack_preview_timer = 0.12

func _start_sword_swing(strength: float = 1.0) -> void:
	if sword == null:
		return
	sword_swing_timer = sword_swing_duration
	sword_swing_strength = maxf(strength, 0.1)
	_update_sword_feedback(sword_swing_duration * 0.08)

func _update_sword_feedback(_delta: float) -> void:
	if sword == null:
		return

	var facing_angle := last_facing_direction.angle() - PI * 0.5
	var swing_offset := sword_rest_offset
	if sword_swing_timer > 0.0:
		sword_swing_timer -= _delta
		var progress := 1.0 - clampf(sword_swing_timer / maxf(sword_swing_duration, 0.001), 0.0, 1.0)
		var eased := sin(progress * PI)
		swing_offset += eased * sword_swing_arc * sword_swing_strength
		if sword_swing_timer <= 0.0:
			sword_swing_timer = 0.0
	sword.rotation = facing_angle + swing_offset

func _setup_xianxia_visuals() -> void:
	body.texture = _build_player_texture()
	body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	body.centered = true
	var outline_mat := ShaderMaterial.new()
	outline_mat.shader = GLOW_OUTLINE_SHADER
	outline_mat.set_shader_parameter("outline_color", Color(0.25, 0.88, 0.82, 0.85))
	outline_mat.set_shader_parameter("outline_width", 1.2)
	outline_mat.set_shader_parameter("glow_strength", 0.55)
	body.material = outline_mat

	sword_mount = sword
	sword_visual = sword_mount as Sprite2D
	if sword_visual == null and sword_mount == null:
		sword_visual = Sprite2D.new()
		sword_visual.name = "Sword"
		add_child(sword_visual)
		move_child(sword_visual, body.get_index() + 1)
		sword_mount = sword_visual
		sword = sword_mount
	if sword_visual != null:
		sword_visual.texture = _build_sword_texture()
		sword_visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sword_visual.centered = true
		sword_visual.z_index = 2
	if sword_mount != null:
		sword_mount.position = Vector2(13.0, 1.0)
		sword_mount.rotation = -0.68
		sword_mount.z_index = 2

	var blade := sword_mount.get_node_or_null("Blade") as Polygon2D if sword_mount != null else null
	if blade != null:
		blade.color = Color(0.78, 0.94, 1.0, 1.0)
	var guard_poly := sword_mount.get_node_or_null("Guard") as Polygon2D if sword_mount != null else null
	if guard_poly != null:
		guard_poly.color = Color(0.55, 0.82, 0.96, 1.0)

	robe_sash_visual = get_node_or_null("RobeSash") as Polygon2D
	if robe_sash_visual == null:
		robe_sash_visual = Polygon2D.new()
		robe_sash_visual.name = "RobeSash"
		add_child(robe_sash_visual)
		move_child(robe_sash_visual, body.get_index() + 1)
	robe_sash_visual.color = Color(0.58, 0.88, 0.98, 0.78)
	robe_sash_visual.polygon = PackedVector2Array([Vector2(-9, 3), Vector2(9, 3), Vector2(7, 8), Vector2(-7, 8)])
	robe_sash_visual.z_index = 3

func _build_player_texture() -> Texture2D:
	var image := Image.create(32, 36, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var shadow := Color(0.52, 0.68, 0.76, 1.0)
	var robe := Color(0.91, 0.94, 0.91, 1.0)
	var robe_light := Color(0.99, 0.98, 0.91, 1.0)
	var trim := Color(0.54, 0.87, 0.94, 1.0)
	var hair := Color(0.08, 0.08, 0.12, 1.0)
	var skin := Color(0.92, 0.74, 0.58, 1.0)
	_fill_rect(image, Rect2i(12, 2, 8, 5), hair)
	_fill_rect(image, Rect2i(11, 6, 10, 5), skin)
	_fill_rect(image, Rect2i(10, 5, 3, 14), hair)
	_fill_rect(image, Rect2i(20, 6, 2, 12), hair)
	_fill_rect(image, Rect2i(9, 11, 14, 18), shadow)
	_fill_rect(image, Rect2i(10, 10, 12, 20), robe)
	_fill_rect(image, Rect2i(13, 11, 6, 18), robe_light)
	_fill_rect(image, Rect2i(9, 15, 3, 10), trim)
	_fill_rect(image, Rect2i(20, 15, 3, 10), trim)
	_fill_rect(image, Rect2i(12, 28, 8, 4), Color(0.72, 0.78, 0.82, 1.0))
	_fill_rect(image, Rect2i(14, 7, 2, 1), Color(0.12, 0.1, 0.12, 1.0))
	_fill_rect(image, Rect2i(18, 7, 2, 1), Color(0.12, 0.1, 0.12, 1.0))
	return ImageTexture.create_from_image(image)

func _build_sword_texture() -> Texture2D:
	var image := Image.create(28, 28, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var blade := Color(0.88, 0.96, 1.0, 1.0)
	var edge := Color(0.45, 0.74, 0.88, 1.0)
	var hilt := Color(0.82, 0.65, 0.28, 1.0)
	for i in range(4, 23):
		image.set_pixel(i, 24 - i, blade)
		image.set_pixel(i, 25 - i, edge)
		if i < 20:
			image.set_pixel(i + 1, 24 - i, blade)
	_fill_rect(image, Rect2i(17, 8, 8, 2), hilt)
	_fill_rect(image, Rect2i(21, 8, 2, 7), Color(0.33, 0.2, 0.12, 1.0))
	return ImageTexture.create_from_image(image)

func _update_xianxia_animation(_delta: float) -> void:
	if sword_mount == null:
		return

	var moving := current_input_direction != Vector2.ZERO
	var is_dashing := dash_timer > 0.0
	if is_dashing or moving:
		var interval := _afterimage_interval_dash if is_dashing else _afterimage_interval_move
		_afterimage_timer -= _delta
		if _afterimage_timer <= 0.0:
			_afterimage_timer = interval
			var alpha := 0.55 if is_dashing else 0.30
			_spawn_afterimage(alpha)
	else:
		_afterimage_timer = 0.0
	var walk_bob := sin(visual_time * 12.0) * 1.6 if moving else sin(visual_time * 3.0) * 0.45
	body.position = Vector2(0.0, walk_bob)
	if robe_sash_visual != null:
		robe_sash_visual.position = Vector2(sin(visual_time * 8.0) * (1.2 if moving else 0.35), walk_bob)

	if dash_timer > 0.0:
		body.rotation = dash_direction.angle() * 0.03
		sword_mount.position = last_facing_direction * 17.0 + Vector2(0.0, walk_bob)
		sword_mount.modulate = Color(0.72, 0.94, 1.0, 0.86)
		return

	body.rotation = sin(visual_time * 9.0) * (0.025 if moving else 0.01)
	if attack_visual_timer > 0.0:
		sword_mount.position = last_facing_direction * 20.0 + Vector2(0.0, walk_bob)
		sword_mount.modulate = Color(0.9, 0.98, 1.0, 1.0)
	else:
		sword_mount.position = Vector2(13.0, 1.0 + walk_bob * 0.45)
		sword_mount.modulate = Color.WHITE

func _spawn_afterimage(alpha: float) -> void:
	var ghost := Sprite2D.new()
	ghost.texture = body.texture
	ghost.scale = body.scale
	ghost.rotation = body.rotation
	ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ghost.modulate = Color(0.55, 0.88, 1.0, alpha)
	ghost.z_index = body.z_index - 1
	ghost.global_position = body.global_position
	ghost.global_rotation = body.global_rotation
	get_parent().call_deferred("add_child", ghost)
	var fade_time := 0.12 if dash_timer <= 0.0 else 0.08
	get_tree().create_tween().tween_property(ghost, "modulate:a", 0.0, fade_time).set_delay(0.02)
	get_tree().create_tween().tween_interval(fade_time + 0.03).tween_callback(ghost.queue_free)

func _fill_rect(image: Image, rect: Rect2i, fill: Color) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height():
				image.set_pixel(x, y, fill)

func _choose_attack_variant(is_impact_attack: bool, is_counter_attack: bool, has_momentum: bool, is_back_hit: bool) -> String:
	if is_impact_attack:
		return ATTACK_VARIANT_IMPACT
	if is_counter_attack:
		return ATTACK_VARIANT_COUNTER
	if is_back_hit:
		return ATTACK_VARIANT_BACK_HIT
	if has_momentum:
		return ATTACK_VARIANT_MOMENTUM
	return ATTACK_VARIANT_NORMAL

func _choose_combat_message(is_impact_attack: bool, is_counter_attack: bool, has_momentum: bool, is_back_hit: bool) -> String:
	var variant := _choose_attack_variant(is_impact_attack, is_counter_attack, has_momentum, is_back_hit)
	match variant:
		ATTACK_VARIANT_COUNTER:
			return "Counter"
		ATTACK_VARIANT_IMPACT:
			return "Impact Strike"
		ATTACK_VARIANT_BACK_HIT:
			return "Back Hit"
		ATTACK_VARIANT_MOMENTUM:
			return "Momentum"
		_:
			return ""

func _get_variant_spark_color(variant: String) -> Color:
	match variant:
		ATTACK_VARIANT_COUNTER:
			return Color(0.18, 1.0, 0.9, 1.0)
		ATTACK_VARIANT_IMPACT:
			return Color(1.0, 0.9, 0.28, 1.0)
		ATTACK_VARIANT_BACK_HIT:
			return Color(1.0, 0.32, 0.22, 1.0)
		ATTACK_VARIANT_MOMENTUM:
			return Color(0.45, 0.82, 1.0, 1.0)
		_:
			return Color.WHITE

func _get_variant_spark_end_scale(variant: String) -> Vector2:
	match variant:
		ATTACK_VARIANT_COUNTER:
			return Vector2(2.1, 2.1)
		ATTACK_VARIANT_IMPACT:
			return Vector2(2.35, 2.35)
		ATTACK_VARIANT_BACK_HIT:
			return Vector2(1.95, 1.95)
		ATTACK_VARIANT_MOMENTUM:
			return Vector2(1.85, 1.85)
		_:
			return Vector2(1.6, 1.6)

func _spawn_hit_spark(effect_position: Vector2, variant: String = ATTACK_VARIANT_NORMAL) -> void:
	var spark := HIT_SPARK_SCENE.instantiate() as Node2D
	get_tree().current_scene.add_child(spark)
	spark.global_position = effect_position
	if spark.has_method("configure"):
		spark.configure(
			_get_variant_spark_color(variant),
			Vector2(0.75, 0.75),
			_get_variant_spark_end_scale(variant),
			0.18 if variant == ATTACK_VARIANT_NORMAL else 0.22
		)

func _spawn_slash_trail(variant: String) -> void:
	var trail := SLASH_TRAIL_SCENE.instantiate() as Node2D
	get_tree().current_scene.add_child(trail)
	trail.global_position = global_position + last_facing_direction * melee_range
	if trail.has_method("setup"):
		trail.setup(last_facing_direction, variant, melee_range)

func _apply_hit_pause() -> void:
	get_tree().paused = true
	await get_tree().create_timer(hit_pause_duration, true, false, true).timeout
	get_tree().paused = false

func _on_damaged(_amount: int) -> void:
	body.modulate = Color(1.0, 0.18, 0.12, 1.0)
	body.scale = normal_body_scale * hurt_pulse_scale
	hurt_flash_timer = hurt_flash_duration
	hurt_pulse_timer = hurt_flash_duration
	damage_ring.visible = true
	damage_ring.scale = Vector2.ONE
	damage_ring.modulate.a = 1.0
	damage_ring_timer = 0.2

func _on_died() -> void:
	is_defeated = true
	is_defending = false
	is_exhausted = false
	body.modulate = Color(0.45, 0.45, 0.45, 1.0)
	body.scale = normal_body_scale
	selection_ring.color = Color(0.4, 0.4, 0.4, 0.35)
	guard_ring.visible = false
	damage_ring.visible = false
	attack_preview.visible = false

func apply_incoming_damage(amount: int) -> void:
	if amount <= 0:
		return

	var final_damage := amount
	if is_defending and current_stamina > 0.0:
		final_damage = maxi(amount - defend_block_amount, 0)
		if final_damage < amount:
			blocked.emit()
			selection_ring.color = Color(0.2, 0.95, 1.0, 0.7)
			block_ring_timer = 0.18

	if final_damage > 0:
		health_component.take_damage(final_damage)

func apply_attack_hitback(direction: Vector2, force: float) -> void:
	if direction == Vector2.ZERO or force <= 0.0:
		return
	attack_hitback_velocity = direction.normalized() * force

func is_attack_target_active() -> bool:
	return not is_defeated

func _is_counter_ready_visual_active() -> bool:
	return counter_ready_timer > 0.0 and not is_defeated

func _update_defense(delta: float) -> void:
	var wants_defense := Input.is_action_pressed("defend")
	var next_is_defending := wants_defense and current_stamina > 0.0 and not is_exhausted and dash_timer <= 0.0

	if next_is_defending:
		_set_stamina(current_stamina - defend_stamina_per_second * delta)
		if current_stamina <= 0.0:
			next_is_defending = false
	else:
		_set_stamina(current_stamina + stamina_regen_per_second * delta)

	if is_defending != next_is_defending:
		is_defending = next_is_defending
		if is_defending:
			perfect_guard_timer = perfect_guard_window
		_refresh_body_feedback()

func _set_stamina(value: float) -> void:
	var previous_stamina := current_stamina
	var was_exhausted := is_exhausted
	current_stamina = clampf(value, 0.0, max_stamina)
	if current_stamina <= 0.0:
		is_exhausted = true
	if is_exhausted and is_equal_approx(current_stamina, max_stamina):
		is_exhausted = false
		_refresh_body_feedback()
	if was_exhausted != is_exhausted:
		exhaustion_changed.emit(is_exhausted)
	if not is_equal_approx(previous_stamina, current_stamina):
		stamina_changed.emit(current_stamina, max_stamina)

func can_spend_stamina(amount: float) -> bool:
	return not is_exhausted and not is_defeated and current_stamina >= amount

func spend_stamina(amount: float) -> void:
	_set_stamina(current_stamina - amount)

func get_skill_origin() -> Vector2:
	return global_position

func get_skill_direction() -> Vector2:
	return last_facing_direction

func get_skill_slot_names() -> Array[String]:
	if skill_caster == null:
		return ["Empty", "Empty", "Empty", "Empty", "Empty"]
	return skill_caster.get_slot_names()

func _ensure_default_transform_skill() -> void:
	while skill_caster.skills.size() < SkillCaster.SLOT_COUNT:
		skill_caster.skills.append(null)
	if skill_caster.skills[0] == null:
		skill_caster.skills[0] = TRANSFORM_SKILL
	if skill_caster.skills[1] == null:
		skill_caster.skills[1] = DIVINE_LIGHT_SKILL

func _on_skill_slots_changed(slot_names: Array[String]) -> void:
	skill_slots_changed.emit(slot_names)

func _on_skill_cast_failed(message: String) -> void:
	combat_message_requested.emit(message)

func _on_skill_cast_started(_message: String) -> void:
	pass

func _on_active_slots_changed(active_states: Array[bool]) -> void:
	active_skill_slots = active_states.duplicate()
	active_skill_slots_changed.emit(active_skill_slots)

func _refresh_body_feedback() -> void:
	if is_defeated:
		body.modulate = Color(0.45, 0.45, 0.45, 1.0)
	elif _is_counter_ready_visual_active():
		body.modulate = Color(0.5, 1.0, 0.92, 1.0)
	elif is_exhausted:
		body.modulate = Color(0.78, 0.78, 0.78, 1.0)
	elif is_defending:
		body.modulate = Color(0.55, 0.78, 1.0, 1.0)
	else:
		body.modulate = Color.WHITE

	if _is_counter_ready_visual_active():
		selection_ring.color = Color(0.1, 1.0, 0.9, 0.62)
		guard_ring.visible = true
	elif is_defending:
		selection_ring.color = Color(0.42, 0.78, 1.0, 0.45)
		guard_ring.visible = true
	elif is_exhausted:
		selection_ring.color = Color(0.55, 0.55, 0.55, 0.35)
		guard_ring.visible = false
	else:
		selection_ring.color = Color(1.0, 0.93, 0.55, 0.38)
		guard_ring.visible = false

func _try_dash(input_direction: Vector2) -> void:
	if dash_cooldown_timer > 0.0 or is_exhausted or is_defeated or current_stamina < dash_stamina_cost:
		return

	dash_direction = input_direction
	if dash_direction == Vector2.ZERO:
		dash_direction = last_facing_direction
	if dash_direction == Vector2.ZERO:
		return

	is_defending = false
	_refresh_body_feedback()
	_set_stamina(current_stamina - dash_stamina_cost)
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	combat_message_requested.emit("Dash")

func handle_enemy_attack(amount: int, enemy: Node2D) -> void:
	if amount <= 0:
		return

	if is_defending and perfect_guard_timer > 0.0:
		_set_stamina(current_stamina + perfect_guard_stamina_restore)
		counter_ready_timer = counter_window
		blocked.emit()
		combat_message_requested.emit("Perfect Guard - Counter Ready")
		block_ring_timer = 0.25
		_refresh_body_feedback()
		if enemy != null:
			if enemy.has_method("apply_knockback"):
				enemy.apply_knockback((enemy.global_position - global_position).normalized(), melee_knockback_force + counter_knockback_bonus)
			if enemy.has_method("apply_stagger"):
				enemy.apply_stagger(counter_stagger_amount)
		return

	apply_incoming_damage(amount)
