extends CharacterBody3D
const F := preload("res://scripts/rebirth/Form.gd")
var world: Node3D
var hero := false
var boss := false
var kind := 0
var hp := 5.0
var max_hp := 5.0
var stamina := 100.0
var weapon := 0
var damage_bonus := 0.0
var dead := false
var facing := Vector3.FORWARD
var movement := Vector3.ZERO
var clock := 0.0
var action := "idle"
var timer := 0.0
var duration := 0.0
var cooldown := 0.0
var immunity := 0.0
var hit_flash := 0.0
var interrupt_resist := 0.0
var combo := 0
var combo_expire := 0.0
var released := false
var guard_time := 0.0
var guarding := false
var parry_reward := 0.0
var ai_wait := 1.0
var knockback := Vector3.ZERO
var locked := Vector3.FORWARD
var rig: Node3D
var torso: Node3D
var arm: Node3D
var blade: Node3D
var left_leg: Node3D
var right_leg: Node3D
var cape: MeshInstance3D
var warning: MeshInstance3D
var cloth: StandardMaterial3D
var sword_mat: StandardMaterial3D
var trail_points: Array[Vector3] = []
var trail: MeshInstance3D
var base_color: Color
var no_target_time := 0.0
var charge_lane: MeshInstance3D
var attack_buffer := 0.0
var pulse_warning: MeshInstance3D
var left_arm: MeshInstance3D
var puppet: Node3D
var hit_stop := 0.0
var posture := 0.0
var break_meter: MeshInstance3D
var collision_hit := false
var dash_buffer := 0.0
var posture_grace := 0.0
var last_guarded := false
var recall_speed := 0.0
var fatigue_hint := 0.0

func _ready() -> void:
	collision_layer = 2 if hero else 4
	collision_mask = 1 | (4 if hero else 6)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28 if not boss else 0.45
	capsule.height = 1.6 if not boss else 2.2
	collision.shape = capsule
	collision.position.y = capsule.height / 2
	add_child(collision)
	if not hero and not boss: weapon = 2 if kind == 1 else 0
	build_body()
	if boss:
		rig.scale *= 1.35
		max_hp = 65
	elif hero:
		max_hp = 12
	else:
		max_hp = 7 if kind == 2 else 10 + kind * 2
	hp = max_hp
	trail = MeshInstance3D.new()
	trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_parent().add_child(trail)

func build_body() -> void:
	rig = Node3D.new()
	add_child(rig)
	puppet = Node3D.new()
	puppet.set_script(preload("res://scripts/rebirth/CombatPuppet.gd"))
	puppet.actor = self
	rig.add_child(puppet)
	blade = Node3D.new()
	puppet.hand.add_child(blade)
	blade.rotation.x = PI/2
	make_weapon()
	warning = F.sphere(self,Vector3.ZERO,0.09,F.material(Color("ffce86"),0,0.3,2.0))
	warning.visible = false
	charge_lane = F.box(self,Vector3(0,0.04,-3.35),Vector3(1.3,0.015,6.7),F.material(Color(0.94,0.45,0.2,0.25),0,0.7,0.7))
	charge_lane.visible = false
	pulse_warning = F.ring(self,Vector3(0,0.18,0),3.8,0.04,F.material(Color("e2a36a"),0,0.5,0.8))
	pulse_warning.visible = false

func make_weapon() -> void:
	for child in blade.get_children():
		blade.remove_child(child)
		child.queue_free()
	if not hero and not boss and kind == 2:
		F.cylinder(blade,Vector3(0,0.35,0),0.035,1.9,F.material(Color("544f3d")), -1,8)
		F.ring(blade,Vector3(0,1.32,0),0.18,0.025,F.material(Color("c2a76e"),0.6,0.3))
		F.sphere(blade,Vector3(0,1.32,0),0.08,F.material(Color("b2d8cf"),0,0.5,1.3))
		return
	var dark := F.material(Color("293a40"),0.2)
	var gold := F.material(Color("bca06d"),0.7,0.3)
	sword_mat = F.material(Color("d5eee5") if weapon == 2 else Color("cdd7cf"),0.8,0.22,0.15)
	F.box(blade,Vector3(0,0,0.02),Vector3(0.065,0.07,0.27),dark)
	F.box(blade,Vector3(0,0,-0.12),Vector3(0.32,0.055,0.05),gold)
	var length := 1.4 if weapon == 1 else 1.05
	var steel := SurfaceTool.new()
	steel.begin(Mesh.PRIMITIVE_TRIANGLES)
	var width := 0.105 if weapon == 1 else 0.052
	var section := [Vector3(-width,0,-0.15),Vector3(0,-0.035,-0.15),Vector3(width,0,-0.15),Vector3(0,0.035,-0.15)]
	var shoulder: Array[Vector3] = []
	for vertex in section: shoulder.append(vertex+Vector3(0,0,-length*0.82))
	var point := Vector3(0,0,-0.15-length)
	for i in range(4):
		var j := (i+1)%4
		for vertex in [section[i],shoulder[i],section[j],section[j],shoulder[i],shoulder[j],shoulder[i],point,shoulder[j]]:
			steel.add_vertex(vertex)
	steel.generate_normals()
	var edge := steel.commit()
	F.instance(blade,edge,Vector3.ZERO,sword_mat)
	if weapon == 2:
		F.beam(blade,Vector3(0,0,0.15),Vector3(0,-0.28,0.25),0.025,F.material(Color("73b8ad")))

func _physics_process(delta: float) -> void:
	if dead:
		puppet.update_pose(delta)
		return
	if hero and world.mode == "play":
		if Input.is_action_just_pressed("attack"): attack_buffer = 0.22
		if Input.is_action_just_pressed("dash") or Input.is_action_just_pressed("use_selected_skill"): dash_buffer = 0.18
	var pose_delta := delta
	if hit_stop > 0 and dash_buffer <= 0: pose_delta = 0
	hit_stop = maxf(0,hit_stop-delta)
	fatigue_hint = maxf(0,fatigue_hint-delta)
	var ending_dash := action == "dash" and timer <= delta
	clock += delta
	interrupt_resist = maxf(0,interrupt_resist-delta)
	posture_grace = maxf(0,posture_grace-delta)
	if posture_grace <= 0: posture = maxf(0,posture-delta*9)
	cooldown = maxf(0,cooldown-delta)
	immunity = maxf(0,immunity-delta)
	hit_flash = maxf(0,hit_flash-delta)
	combo_expire = maxf(0,combo_expire-delta)
	parry_reward = maxf(0,parry_reward-delta)
	stamina = minf(100,stamina + delta * (12 if guarding else 25))
	knockback = knockback.move_toward(Vector3.ZERO,delta*(12 if action == "launch" else 18))
	if world.mode != "play":
		if world.mode == "title": animate(delta)
		return
	if hero: control(delta)
	else: think(delta)
	if action != "idle":
		timer -= pose_delta
		if action == "attack" and not released and timer <= duration*(0.80 if hero else 0.56):
			released = true
			world.melee(self)
		if action == "recall":
			velocity = locked * recall_speed * minf(delta,maxf(0,timer+delta))/delta
		elif action == "dash":
			velocity = locked * 17 + knockback
		elif action == "charge":
			velocity = locked * 13
			if not released and position.distance_to(world.player.position) < 1.4:
				released = true
				world.player.hurt(3,self)
		elif action == "launch":
			velocity = knockback
		else:
			var lunge := locked * 5.0 if hero and action == "attack" and timer > duration*0.65 else Vector3.ZERO
			if not hero and action == "attack" and (boss or kind != 2) and timer < duration*0.85 and timer > duration*0.48:
				lunge = locked*6.5
			velocity = movement * (2.4 if action == "attack" else 0) + knockback + lunge
		if timer <= 0:
			if action == "windup":
				if boss and hp < max_hp * 0.5 and kind % 3 == 0:
					world.boss_pulse(self)
					action = "stunned"
					timer = 1.1
				elif boss and kind % 3 == 2:
					action = "charge"
					duration = 0.52
					timer = duration
					released = false
				else: start_attack()
			else:
				action = "idle"
				ai_wait = (0.5 if hp < max_hp*0.5 else 0.8) if boss else 1.2
	else:
		var traction := (80.0 if movement.length() < 0.1 else 48.0) if hero else 30.0
		velocity = velocity.move_toward(movement * (4.4 if hero else (2.5 if kind == 1 else 1.9)) + knockback,delta*traction)
	velocity.y = 0
	if hero:
		collision_layer = 0 if action in ["dash","recall"] else 2
		collision_mask = 1 if action in ["dash","recall"] else 5
	move_and_slide()
	if ending_dash: velocity = velocity.limit_length(2.0)
	if hero and action == "idle" and timer <= 0 and recall_speed > 0:
		velocity = Vector3.ZERO
		recall_speed = 0
	if action == "launch" and not collision_hit and knockback.length() > 5:
		for i in range(get_slide_collision_count()):
			var collider := get_slide_collision(i).get_collider()
			if collider is StaticBody3D or collider in world.enemies:
				collision_hit = true
				world.crash(self,collider)
				break
	position.y = 0.05
	position.x = clampf(position.x,-17.5,17.5)
	position.z = clampf(position.z,-19,15.5)
	animate(pose_delta)

func control(delta: float) -> void:
	attack_buffer = maxf(0,attack_buffer-delta)
	if Input.is_action_just_pressed("attack"): attack_buffer = 0.2
	var input := Input.get_vector("move_left","move_right","move_up","move_down")
	movement = Vector3(input.x,0,input.y).rotated(Vector3.UP,PI/4)
	guarding = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_action_pressed("defend")
	if guarding:
		guard_time += delta
		movement *= 0.35
	else: guard_time = 0
	if guarding and action == "attack" and released:
		action = "idle"
		cooldown = 0
	if action == "idle" or (action == "attack" and timer < duration*0.24 and cooldown <= 0):
		var aim: Vector3 = world.aim_point() - position
		aim.y = 0
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			if aim.length() > 0.3: facing = aim.normalized()
		elif movement.length() > 0: facing = movement.normalized()
		var stick := Input.get_vector("aim_left","aim_right","aim_up","aim_down")
		if stick.length() > 0.2: facing = Vector3(stick.x,0,stick.y).rotated(Vector3.UP,PI/4).normalized()
		if (Input.is_action_pressed("attack") or attack_buffer > 0) and not guarding: start_attack()
	if dash_buffer > 0:
		dash(movement if movement.length() > 0 else facing)
	dash_buffer = maxf(0,dash_buffer-delta)

func think(delta: float) -> void:
	movement = Vector3.ZERO
	var offset: Vector3 = world.player.position-position
	offset.y = 0
	if action != "idle": return
	ai_wait -= delta
	facing = offset.normalized()
	var ranged := not boss and kind == 2
	if ranged and offset.length() < 3.2:
		movement = -facing*0.7
		return
	if offset.length() > (6.5 if ranged else (2.7 if boss else 1.9)):
		movement = facing
		for other in world.enemies:
			if is_instance_valid(other) and other != self and not other.dead:
				var separation: Vector3 = position-other.position
				separation.y = 0
				if separation.length() < 0.95 and separation.length() > 0.01:
					movement += separation.normalized() * 0.65
		movement = movement.normalized()
		# Deflect around solid architecture instead of running into pillars forever.
		var query := PhysicsRayQueryParameters3D.create(position+Vector3.UP*0.7,position+Vector3.UP*0.7+facing*1.2,1)
		if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():
			movement = facing.rotated(Vector3.UP,PI/2)
	elif ai_wait <= 0:
		var attackers := 0
		for other in world.enemies:
			if is_instance_valid(other) and other != self and other.action in ["windup","attack","charge"]: attackers += 1
		if attackers >= 2:
			movement = facing.rotated(Vector3.UP,PI/2) * 0.4
			return
		action = "windup"
		duration = 1.15 if boss and hp < max_hp*0.5 and (kind+1)%3 == 0 else (0.85 if boss else (1.0 if ranged else 0.8))
		timer = duration
		locked = facing
		kind += 1 if boss else 0

func start_attack() -> void:
	var cost := 23.0 if weapon == 1 else (12.0 if weapon == 2 else 16.0)
	if cooldown > 0 or (hero and action in ["dash","recall","hurt"]): return
	if hero and stamina < cost:
		if fatigue_hint <= 0:
			world.notify("气息未稳", "松开出剑恢复体力 · 格挡或移动调整距离",1.0)
			fatigue_hint = 1.5
		return
	attack_buffer = 0
	if hero:
		stamina -= cost
	combo = combo % 3 + 1 if combo_expire > 0 else 1
	combo_expire = 1.1
	action = "attack"
	duration = (0.46 if weapon == 1 else (0.28 if weapon == 2 else 0.33)) if hero else 0.6
	cooldown = duration * (1.08 if combo == 3 else 0.80)
	timer = duration
	released = false
	locked = facing
	world.combat_sound("heavy" if weapon == 1 else "swing")
	trail_points.clear()

func dash(direction: Vector3) -> void:
	if action == "dash" or action == "recall" or stamina < 20: return
	dash_buffer = 0
	hit_stop = 0
	if hero: world.leave_echo()
	stamina -= 20
	action = "dash"
	timer = 0.2
	duration = timer
	immunity = 0.25
	locked = direction.normalized()
	world.burst(position+Vector3.UP*0.1,Color("91bcb5"),4,0.5)
	world.combat_sound("dash")

func hurt(amount: float, source: Node3D) -> bool:
	last_guarded = false
	if dead or immunity > 0: return false
	if hero and guarding and source is CharacterBody3D and facing.dot((source.position-position).normalized()) > 0.0 and stamina >= 12:
		stamina -= 12
		if guard_time < 0.22:
			parry_reward = 2.0
			stamina = minf(100,stamina+24)
			source.action = "stunned"
			source.timer = 0.45
			source.apply_posture(55)
			world.combat_sound("parry")
			hit_stop = 0.035
			source.hit_stop = 0.065
			world.notify("见切", "下一击强化", 1.1)
			world.flash(position+Vector3.UP,Color("e9d49a"))
			world.impact(0.2,1.3)
		else:
			action = "block_hit"
			duration = 0.12
			timer = duration
			world.combat_sound("guard")
			world.burst(position+Vector3.UP,Color("d2d7c6"),5,0.6)
		return false
	if not hero and source == world.player and action == "idle" and (boss or kind == 0) and facing.dot((source.position-position).normalized()) > 0.35:
		last_guarded = true
		action = "block_hit"
		duration = 0.16
		timer = duration
		amount *= 0.35
		world.combat_sound("guard")
	else:
		world.combat_sound("hit")
	hp = maxf(0,hp-amount)
	hit_flash = 0.065
	immunity = 0.55 if hero else 0.12
	knockback = (position-source.position).normalized() * (3 if boss else 8)
	knockback.y = 0
	if not hero and not boss and not last_guarded and action not in ["windup","attack","broken","launch"]:
		action = "stunned"
		timer = 0.2
	if hero:
		action = "hurt"
		duration = 0.22
		timer = duration
		released = true
		guarding = false
		world.ui.feedback.receive_hit(source.position,amount)
	hit_stop = 0.035 if not hero else 0.025
	if source == world.player: source.hit_stop = 0.012
	world.burst(position+Vector3.UP,Color("a8d5c7") if hero else Color("f1be86"),9,1.0)
	world.impact(0.12 if hero else 0.07,0.7)
	if hp <= 0:
		dead = true
		collision_layer = 0
		collision_mask = 0
		world.fallen(self)
		action = "dead"
		var tween := create_tween()
		tween.tween_interval(0.6)
		if not hero:
			tween.chain().tween_property(rig,"scale",Vector3.ZERO,0.5).set_delay(0.8)
			tween.chain().tween_callback(queue_free)
	return true

func animate(delta: float) -> void:
	rig.rotation.y = lerp_angle(rig.rotation.y,atan2(-facing.x,-facing.z),minf(1,delta*30))
	puppet.update_pose(delta)
	warning.visible = not hero and action == "attack" and not released and timer <= duration*0.56+0.16
	pulse_warning.visible = boss and action == "windup" and hp < max_hp*0.5 and kind % 3 == 0
	charge_lane.visible = boss and action == "windup" and kind % 3 == 2
	if charge_lane.visible:
		charge_lane.position = locked * 3.35 + Vector3.UP*0.18
		charge_lane.rotation.y = atan2(-locked.x,-locked.z)
	if warning.visible:
		warning.global_position = blade.to_global(Vector3(0,0,-1.1))
		warning.scale = Vector3.ONE
	if action == "attack":
		var p := 1.0-timer/duration
		if p > 0.06 and p < 0.55:
			trail_points.append(blade.to_global(Vector3(0,0,-1.55 if weapon == 1 else -1.2)))
			if trail_points.size() > 7: trail_points.pop_front()
	if action != "attack" and not trail_points.is_empty(): trail_points.pop_front()
	draw_trail()

func draw_trail() -> void:
	if trail_points.size() < 2:
		trail.mesh = null
		return
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in range((trail_points.size()-1)*3+1):
		var sample := float(i)/3.0
		var index := mini(int(sample),trail_points.size()-2)
		var weight := sample-index
		var p: Vector3 = trail_points[index].cubic_interpolate(trail_points[index+1],trail_points[maxi(0,index-1)],trail_points[mini(trail_points.size()-1,index+2)],weight)
		var age := float(i)/float((trail_points.size()-1)*3)
		var center := global_position + Vector3.UP*1.0
		mesh.surface_set_color(Color(1,1,1,age*0.65))
		mesh.surface_add_vertex(p)
		mesh.surface_add_vertex(p.lerp(center,0.075*sin(age*PI)))
	mesh.surface_end()
	trail.mesh = mesh
	var trail_color := Color(0.77,0.91,0.85,0.55) if weapon == 2 else (Color(0.94,0.74,0.43,0.55) if weapon == 1 else Color(0.9,0.94,0.88,0.5))
	var m := F.material(trail_color if hero else Color(0.95,0.55,0.3,0.55),0,0.3,0.4)
	m.vertex_color_use_as_albedo = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	trail.material_override = m

func _exit_tree() -> void:
	if is_instance_valid(trail): trail.queue_free()

func launch(direction: Vector3, force: float) -> void:
	if dead: return
	action = "launch"
	duration = 0.55
	timer = duration
	knockback = direction.normalized() * (force*0.4 if boss else force)
	knockback.y = 0
	collision_hit = false
	apply_posture(35)

func apply_posture(amount: float) -> void:
	if dead or hero: return
	posture = minf(100,posture+amount)
	posture_grace = 2.5
	if posture >= 100:
		action = "broken"
		timer = 2.6
		duration = timer
		posture = 0
		posture_grace = 3.0
		world.notify("破 势", "靠近按 F 追斩",1.25)
		world.flash(position+Vector3.UP,Color("f0c483"))
