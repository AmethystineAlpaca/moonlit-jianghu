extends Node2D
@export var mode: int = 0
var last_failure := ""
var age := 0.0
var direction := Vector2.RIGHT
var tint := Color("b1d8c6")
var radius := 140.0
var caster: Node2D
var hit_ids := {}
var released := false
var damage: int = 3

func _ready() -> void:
	z_index = 1800
	var glow := CanvasItemMaterial.new()
	glow.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = glow

func activate(context: Dictionary) -> bool:
	caster = context.get("caster") as Node2D
	if not is_instance_valid(caster):
		queue_free()
		return false
	global_position = caster.global_position
	direction = context.get("direction", Vector2.RIGHT)
	if mode == 2:
		var health := caster.get_node("HealthComponent") as HealthComponent
		if health.current_health >= health.max_health:
			last_failure = "生命已满"
			queue_free()
			return false
		health.heal(3)
		tint = Color("c2d3a4")
	elif mode == 0:
		global_position += direction * 20.0
	else:
		damage = 2
	var feel := get_tree().get_first_node_in_group("game_feel")
	if feel != null: feel.impact(1.3 if mode != 2 else 0.0)
	return true

func _physics_process(delta: float) -> void:
	age += delta
	if mode == 0 and is_instance_valid(caster):
		var next := global_position + direction * 280.0 * delta
		var ray := PhysicsRayQueryParameters2D.create(global_position, next)
		ray.exclude = [caster.get_rid()]
		var blocker := get_world_2d().direct_space_state.intersect_ray(ray)
		if not blocker.is_empty() and not blocker.collider.is_in_group("enemies"):
			queue_free()
			return
		global_position = next
		_hit_targets(26.0)
	elif mode == 1 and age >= 0.14 and not released:
		released = true
		_hit_targets(88.0)
	queue_redraw()
	if age > (0.5 if mode == 0 else 0.7): queue_free()

func _hit_targets(reach: float) -> void:
	if not is_instance_valid(caster): return
	for enemy in get_tree().get_nodes_in_group("hostile_enemies"):
		if not enemy is Node2D or not enemy.is_attack_target_active(): continue
		if hit_ids.has(enemy.get_instance_id()): continue
		if global_position.distance_to(enemy.global_position) > reach: continue
		var ray := PhysicsRayQueryParameters2D.create(caster.global_position, enemy.global_position)
		ray.exclude = [caster.get_rid()]
		var hit := get_world_2d().direct_space_state.intersect_ray(ray)
		if not hit.is_empty() and hit.collider != enemy: continue
		hit_ids[enemy.get_instance_id()] = true
		enemy.get_node("HealthComponent").take_damage(damage)
		enemy.apply_knockback((enemy.global_position - caster.global_position).normalized(), 320.0)
		enemy.apply_stagger(2.0)

func _draw() -> void:
	var progress := clampf(age / (0.5 if mode == 0 else 0.7), 0.0, 1.0)
	var alpha := sin(minf(progress * 2.5, 1.0) * PI * 0.5) * (1.0 - progress)
	if mode == 0:
		draw_set_transform(Vector2.ZERO, direction.angle())
		var outer := PackedVector2Array()
		for i in range(17):
			var t := float(i) / 16.0
			outer.append(Vector2(cos(lerpf(-1.2, 1.2, t)) * 14.0, sin(lerpf(-1.2, 1.2, t)) * 27.0))
		var inner := outer.duplicate()
		inner.reverse()
		for point in inner: outer.append(point - Vector2(4.0, 0))
		draw_colored_polygon(outer, Color(tint, alpha))
		draw_polyline(PackedVector2Array([Vector2(-25,-5),Vector2(-8,-3),Vector2(12,0)]), Color(tint,alpha*0.45),1.0)
		draw_line(Vector2(-18,8),Vector2(2,6),Color(tint,alpha*0.4),1)
	elif mode == 1:
		var r := 18.0 + 70.0 * ease(progress, 0.45)
		for i in range(6):
			var angle := i * TAU / 6.0 + progress * 1.8
			var point := Vector2.from_angle(angle) * r
			var tangent := Vector2.from_angle(angle + 0.65)
			draw_colored_polygon(PackedVector2Array([point + tangent * 14, point + tangent.orthogonal() * 2, point - tangent * 15, point - tangent.orthogonal() * 2]), Color(tint,alpha))
			draw_line(point - tangent * 18, point - tangent * 32, Color(tint, alpha*0.3),1)
	else:
		for i in range(9):
			var x := sin(float(i) * 2.4 + age) * 18.0
			var y := -progress * 42.0 + float(i % 3) * 7.0
			var point := Vector2(x,y)
			draw_colored_polygon(PackedVector2Array([point,point+Vector2(3,-5),point+Vector2(6,-6),point+Vector2(4,-1)]),Color(tint,alpha*0.8))
		draw_arc(Vector2(0,8),18,0.15,PI-0.15,20,Color(tint,alpha*0.35),1)
