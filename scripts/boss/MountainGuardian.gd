extends CharacterBody2D

signal defeated
var is_winding_up := false
var windup_timer := 0.0
var attack_windup := 0.85
var is_dying := false
var timer := 1.4
var state := "approach"
var direction := Vector2.LEFT
var strike_origin := Vector2.ZERO
var locked_target := Vector2.ZERO
var knockback := Vector2.ZERO
var elapsed := 0.0
var attack_index := 0
var body: Sprite2D
var health: HealthComponent
var shadow: Polygon2D
var base_scale := Vector2.ONE
var hit_flash := 0.0

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("hostile_enemies")
	add_to_group("boss")
	collision_layer = 1
	collision_mask = 1
	health = $HealthComponent
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	body = Sprite2D.new()
	body.texture = load("res://assets/art_v2/mountain_guardian.png")
	body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	body.position = Vector2(0, -20)
	base_scale = Vector2.ONE * 0.72
	body.scale = base_scale
	add_child(body)

func _physics_process(delta: float) -> void:
	elapsed += delta
	z_index = int(global_position.y) + 500
	if is_dying: return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null or not player.is_attack_target_active(): return
	hit_flash = maxf(0.0, hit_flash - delta)
	body.modulate = Color("ffd6aa") if hit_flash > 0.0 else Color.WHITE
	body.flip_h = direction.x > 0.0
	body.scale = base_scale * Vector2(1.0 + sin(elapsed * 3.0) * 0.018, 1.0 - sin(elapsed * 3.0) * 0.018)
	knockback = knockback.move_toward(Vector2.ZERO, 600 * delta)
	timer -= delta
	match state:
		"approach":
			direction = (player.global_position - global_position).normalized()
			var world := get_tree().get_first_node_in_group("world")
			if world != null: direction = world.get_path_direction(global_position, player.global_position)
			velocity = direction * 48.0 + knockback
			move_and_slide()
			if timer <= 0.0:
				attack_index += 1
				state = "pulse_windup" if attack_index % 3 == 0 else "windup"
				is_winding_up = true
				attack_windup = 1.15 if state == "pulse_windup" else 0.9
				windup_timer = attack_windup
				strike_origin = global_position
				locked_target = player.global_position
				direction = (locked_target - global_position).normalized()
				timer = attack_windup
		"windup", "pulse_windup":
			windup_timer = maxf(timer, 0.0)
			velocity = Vector2.ZERO
			if timer <= 0.0:
				is_winding_up = false
				if state == "pulse_windup":
					_release_pulse(player)
					state = "recover"
					timer = 1.1
				else:
					state = "charge"
					timer = 0.45
		"charge":
			velocity = direction * 420.0
			move_and_slide()
			if global_position.distance_to(player.global_position) < 42.0:
				player.handle_enemy_attack(2, self)
				state = "recover"
				timer = 1.2
			elif timer <= 0.0 or get_slide_collision_count() > 0:
				state = "recover"
				timer = 1.2
		"recover":
			velocity = Vector2.ZERO
			if timer <= 0.0:
				state = "approach"
				timer = 0.8 if health.current_health < health.max_health / 2 else 1.3
	queue_redraw()

func _release_pulse(player: Node2D) -> void:
	if global_position.distance_to(player.global_position) <= 105.0:
		player.handle_enemy_attack(2, self)
	var effect := preload("res://scenes/skills/JadeTempest.tscn").instantiate()
	get_parent().add_child(effect)
	effect.global_position = global_position
	effect.tint = Color("dda06a")
	effect.radius = 105.0
	var material := CanvasItemMaterial.new()
	material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	effect.material = material
	effect.z_index = 2000

func _draw() -> void:
	draw_set_transform(Vector2(0, 7), 0, Vector2(1, 0.32))
	draw_circle(Vector2.ZERO, 34, Color(0.02, 0.03, 0.04, 0.4))
	draw_set_transform(Vector2.ZERO)
	if state == "windup":
		var end := direction * 190.0
		var perpendicular := direction.orthogonal() * 20
		draw_colored_polygon(PackedVector2Array([-perpendicular, perpendicular, end + perpendicular, end - perpendicular]), Color(0.95, 0.48, 0.22, 0.2))
		draw_line(Vector2.ZERO, end, Color(1, 0.72, 0.4, 0.8), 2)
	if state == "pulse_windup":
		draw_circle(Vector2.ZERO, 105, Color(0.85, 0.4, 0.15, 0.12))
		draw_arc(Vector2.ZERO, 105, 0, TAU, 64, Color(1, 0.65, 0.3, 0.8), 2)

func is_attack_target_active() -> bool:
	return not is_dying

func apply_knockback(vector: Vector2, force: float) -> void:
	knockback = vector * minf(force * 0.15, 60.0)

func apply_stagger(_amount: float) -> void:
	pass

func is_hit_from_behind(origin: Vector2) -> bool:
	return (origin - global_position).normalized().dot(direction) < -0.4

func _on_damaged(_amount: int) -> void:
	hit_flash = 0.14

func _on_died() -> void:
	is_dying = true
	is_winding_up = false
	remove_from_group("hostile_enemies")
	collision_layer = 0
	collision_mask = 0
	defeated.emit()
	var tween := create_tween()
	tween.tween_property(body, "modulate:a", 0.0, 1.2)
	tween.tween_callback(queue_free)
