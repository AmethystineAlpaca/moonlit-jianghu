extends Node3D
const F := preload("res://scripts/rebirth/Form.gd")
const ACTOR := preload("res://scripts/rebirth/Duelist.gd")
const INTERFACE := preload("res://scripts/rebirth/StillwaterUI.gd")
var player: CharacterBody3D
var camera: Camera3D
var ui: CanvasLayer
var mode := "title"
var enemies: Array[Node3D] = []
var seals: Array[Node3D] = []
var seal_done := [false,false,false]
var current_seal := -1
var encounter := false
var round_index := 0
var spawn_queue := 0
var spawn_timer := 0.0
var boss_node: Node3D
var elapsed := 0.0
var run_time := 0.0
var kills := 0
var skill_cooldowns := [0.0,0.0]
var shake := 0.0
var shake_enabled := true
var rng := RandomNumberGenerator.new()
var stone: Material
var edge: Material
var dark: Material
var wood: Material
var gold: Material
var leaves: Material
var audio: AudioStreamPlayer
var fireflies: Array[Node3D] = []
var intro_time := 0.0
var heal_count := 3
var last_mouse := Vector2.ZERO
var camera_target := Vector3.ZERO
var activated := false
var best := 0.0
var persist_progress := true
var hazard_timer := 5.0
var echo: Node3D
var combat_voices: Array[AudioStreamPlayer] = []
var sound_bank: Dictionary = {}
var voice_index := 0
var sound_clock := {}
var mouse_aim_time := -10.0

func _ready() -> void:
	get_viewport().use_hdr_2d = false
	get_viewport().msaa_3d = Viewport.MSAA_4X
	rng.seed = 47029
	process_mode = Node.PROCESS_MODE_ALWAYS
	configure_gamepad()
	build_environment()
	player = ACTOR.new()
	player.hero = true
	player.world = self
	player.position = Vector3(0,0.05,7)
	add_child(player)
	camera_target = player.position
	ui = CanvasLayer.new()
	ui.set_script(INTERFACE)
	ui.world = self
	add_child(ui)
	audio = AudioStreamPlayer.new()
	audio.volume_db = -15
	add_child(audio)
	for i in range(8):
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -10
		add_child(voice)
		combat_voices.append(voice)
	for sound in ["swing","heavy","hit","guard","parry","dash","recall","crash"]:
		sound_bank[sound] = load("res://assets/audio/combat/%s.wav"%sound)
	var config := ConfigFile.new()
	if config.load("user://stillwater.cfg") == OK:
		shake_enabled = config.get_value("settings","shake",true)
		best = config.get_value("run","best",0.0)
		AudioServer.set_bus_mute(0,not config.get_value("settings","sound",true))
	ui.show_title()

func build_environment() -> void:
	stone = F.weathered(Color("697975"),2.0)
	edge = F.weathered(Color("33494e"),4.0)
	dark = F.material(Color("1c3037"),0.15,0.7)
	wood = F.weathered(Color("4a3b30"),8.0)
	gold = F.material(Color("b89a61"),0.65,0.4)
	leaves = F.material(Color("99432c"),0.03,0.9)
	var env := WorldEnvironment.new()
	var atmosphere := Environment.new()
	atmosphere.background_mode = Environment.BG_COLOR
	atmosphere.background_color = Color("243e4d")
	atmosphere.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	atmosphere.ambient_light_color = Color("93b9cb")
	atmosphere.ambient_light_energy = 0.55
	atmosphere.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	atmosphere.ssao_enabled = true
	atmosphere.ssao_radius = 2.0
	atmosphere.ssao_intensity = 1.6
	atmosphere.glow_enabled = true
	atmosphere.glow_intensity = 0.55
	atmosphere.fog_enabled = true
	atmosphere.fog_light_color = Color("344e5d")
	atmosphere.fog_density = 0.003
	atmosphere.fog_height = -0.4
	atmosphere.fog_height_density = 0.18
	env.environment = atmosphere
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48,-34,0)
	sun.light_color = Color("f6d7a8")
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 65
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	add_child(sun)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 22
	camera.far = 150
	camera.current = true
	add_child(camera)
	# Foundation floats above dark water, with visibly constructed stone courses.
	F.box(self,Vector3(0,-1.1,-2),Vector3(37,2,38),edge)
	F.box(self,Vector3(0,-0.15,-2),Vector3(36,0.3,37),stone)
	var water_shader := Shader.new()
	water_shader.code = "shader_type spatial; render_mode cull_disabled; uniform vec4 deep:source_color=vec4(0.06,0.17,0.21,1.0); void fragment(){ float ripple=sin(UV.x*240.0+TIME*0.5)*sin(UV.y*200.0-TIME*0.35); ALBEDO=deep.rgb+vec3(ripple*0.008); METALLIC=0.65; ROUGHNESS=0.23; NORMAL=normalize(vec3(ripple*0.04,0.0,1.0)); }"
	var water_mat := ShaderMaterial.new()
	water_mat.shader = water_shader
	F.box(self,Vector3(0,-1.5,0),Vector3(180,0.08,180),water_mat)
	# Irregular paving, moss in joints and shallow reflective rain pools.
	var paving := MultiMeshInstance3D.new()
	var stones := MultiMesh.new()
	stones.transform_format = MultiMesh.TRANSFORM_3D
	stones.mesh = F.paver_mesh()
	stones.instance_count = 35*29
	paving.multimesh = stones
	paving.material_override = F.weathered(Color("82918b"),3.5)
	add_child(paving)
	for x in range(35):
		for z in range(29):
			var p := Vector3((x-17)*1.01 + (0.16 if z%2 else 0.0),0.013,(z-15)*1.26)
			stones.set_instance_transform(x*29+z,Transform3D(Basis.IDENTITY,p))
	var moss := F.material(Color("465e4b"))
	for i in range(130):
		var p := Vector3(rng.randf_range(-17,17),0.044,rng.randf_range(-18,14))
		if absf(p.x) < 4 and p.z > -5: continue
		F.box(self,p,Vector3(rng.randf_range(0.1,0.7),0.018,rng.randf_range(0.1,0.5)),moss)
	for i in range(16):
		var p := Vector3(rng.randf_range(-16,16),0.046,rng.randf_range(-17,13))
		var puddle := F.cylinder(self,p,rng.randf_range(0.4,1.3),0.008,F.material(Color("334f55"),0.75,0.15),-1,16)
		puddle.scale.z = 0.45
	# Main circular seal court and restrained inlaid bronze rings.
	F.cylinder(self,Vector3(0,0.055,0),4.1,0.1,F.weathered(Color("546c68"),4.0),-1,64)
	for radius in [3.6,3.85]: F.ring(self,Vector3(0,0.112,0),radius,0.025,gold)
	for i in range(8):
		var a := i*TAU/8
		var inlay := F.box(self,Vector3(sin(a)*3.25,0.12,cos(a)*3.25),Vector3(0.05,0.01,0.45),gold)
		inlay.rotation.y = a
	# Low perimeter parapet with gaps at gates.
	for z in range(-18,16,3):
		for x in [-18,18]:
			F.box(self,Vector3(x,0.35,z),Vector3(0.45,0.75,2.75),edge,true)
	for x in range(-16,18,3):
		if abs(x) < 3: continue
		F.box(self,Vector3(x,0.35,16),Vector3(2.75,0.75,0.45),edge,true)
	build_gate(Vector3(0,0,12),1.0)
	build_shrine(Vector3(0,0,-17))
	for position in [Vector3(-11,0,-6),Vector3(11,0,-6),Vector3(0,0,-13)]:
		build_seal(position)
	for p in [Vector3(-13,0,8),Vector3(13,0,7),Vector3(-15,0,-13),Vector3(14,0,-14),Vector3(-8,0,-18)]:
		build_tree(p)
	for p in [Vector3(-5,0,10),Vector3(5,0,10),Vector3(-7,0,-5),Vector3(7,0,-5),Vector3(-4,0,-13),Vector3(4,0,-13)]:
		build_lantern(p)
	for i in range(27):
		var side := -1 if i % 2 == 0 else 1
		var p := Vector3(side*rng.randf_range(20,35),rng.randf_range(-4,-1),rng.randf_range(-35,22))
		var rock := F.cylinder(self,p,rng.randf_range(2,5),rng.randf_range(4,13),edge,rng.randf_range(0.4,2),5)
		rock.rotation.z = rng.randf_range(-0.2,0.2)
	for i in range(35):
		var mote := F.sphere(self,Vector3(rng.randf_range(-17,17),rng.randf_range(0.5,3),rng.randf_range(-17,15)),0.025,F.material(Color("edbd77"),0,0.6,2.0))
		fireflies.append(mote)
	preload("res://scripts/rebirth/CourtyardDetail.gd").build(self)
	build_rain()

func build_gate(p: Vector3, scale_factor: float) -> void:
	var gate := Node3D.new()
	gate.position = p
	gate.scale *= scale_factor
	add_child(gate)
	for x in [-2.8,2.8]:
		F.box(gate,Vector3(x,1.9,0),Vector3(0.4,3.8,0.4),wood,true)
		F.box(gate,Vector3(x,0.2,0),Vector3(0.7,0.4,0.7),edge)
		F.box(gate,Vector3(x,3.0,0),Vector3(0.52,0.12,0.52),gold)
	F.box(gate,Vector3(0,3.25,0),Vector3(6.4,0.25,0.32),wood)
	F.box(gate,Vector3(0,3.85,0),Vector3(7.2,0.3,0.6),dark)
	for side in [-1,1]:
		var end := F.box(gate,Vector3(side*3.55,3.98,0),Vector3(1.0,0.21,0.62),dark)
		end.rotation.z = side*0.22
	F.box(gate,Vector3(0,3.43,0),Vector3(0.7,0.8,0.18),gold)
	F.box(gate,Vector3(0,3.43,0.1),Vector3(0.48,0.58,0.05),dark)

func build_shrine(p: Vector3) -> void:
	var shrine := Node3D.new()
	shrine.position = p
	add_child(shrine)
	F.box(shrine,Vector3(0,0.3,-1.3),Vector3(9,0.6,4.5),edge,true)
	for x in [-3.6,-1.2,1.2,3.6]:
		F.box(shrine,Vector3(x,2,-1.6),Vector3(0.32,3.4,0.32),wood,true)
	F.box(shrine,Vector3(0,2.0,-2.8),Vector3(7.6,3.4,0.2),wood,true)
	for i in range(-9,10):
		F.box(shrine,Vector3(i*0.4,2.1,-2.6),Vector3(0.04,2.5,0.1),gold)
	for side in [-1,1]:
		var roof := F.box(shrine,Vector3(0,4.05,side*0.8-1.4),Vector3(10,0.22,2.8),dark)
		roof.rotation.x = side*0.28
		for i in range(-12,13):
			F.beam(shrine,Vector3(i*0.4,4.43,-1.4),Vector3(i*0.4,3.65,side*2.65-1.4),0.07,edge)
	F.box(shrine,Vector3(0,4.48,-1.4),Vector3(10.4,0.15,0.24),gold)

func build_tree(p: Vector3) -> void:
	var tree := Node3D.new()
	tree.position = p
	add_child(tree)
	F.cylinder(tree,Vector3(0,1.8,0),0.27,3.6,wood,0.12,7)
	var trunk_body := StaticBody3D.new()
	var trunk_shape := CollisionShape3D.new()
	var trunk := CylinderShape3D.new()
	trunk.radius = 0.3
	trunk.height = 3.6
	trunk_shape.shape = trunk
	trunk_shape.position.y = 1.8
	trunk_body.add_child(trunk_shape)
	tree.add_child(trunk_body)
	var clusters: Array[Vector3] = []
	for i in range(7):
		var a := i*2.4
		var end := Vector3(sin(a)*1.8,3.0+rng.randf(),cos(a)*1.5)
		F.beam(tree,Vector3(0,1.6,0),end,0.14,wood)
		clusters.append(end)
	var canopy := MultiMeshInstance3D.new()
	var leaf_data := MultiMesh.new()
	leaf_data.transform_format = MultiMesh.TRANSFORM_3D
	leaf_data.use_colors = true
	leaf_data.mesh = F.leaf_mesh()
	leaf_data.instance_count = 1500
	canopy.multimesh = leaf_data
	var leaf_material := F.material(Color("c26b3e"))
	leaf_material.vertex_color_use_as_albedo = true
	leaf_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	leaf_material.backlight_enabled = true
	leaf_material.backlight = Color("824c29")
	canopy.material_override = leaf_material
	tree.add_child(canopy)
	for i in range(1500):
		var center: Vector3 = clusters[i%7]
		var angle := rng.randf()*TAU
		var radius := sqrt(rng.randf())*1.5
		var offset := Vector3(cos(angle)*radius,rng.randf_range(-0.22,0.4)*(1-radius/2),sin(angle)*radius)
		var basis := Basis.from_euler(Vector3(rng.randf_range(-0.5,0.5),rng.randf()*TAU,rng.randf_range(-0.4,0.4)))
		basis = basis.scaled(Vector3.ONE*rng.randf_range(0.8,1.4))
		leaf_data.set_instance_transform(i,Transform3D(basis,center+offset))
		leaf_data.set_instance_color(i,Color(1.0,rng.randf_range(0.65,1),rng.randf_range(0.6,1)))
	for i in range(18):
		var leaf := F.box(tree,Vector3(rng.randf_range(-2.5,2.5),0.06,rng.randf_range(-2.5,2.5)),Vector3(0.12,0.025,0.2),leaves)
		leaf.rotation.y = rng.randf()*TAU

func build_lantern(p: Vector3) -> void:
	F.box(self,p+Vector3(0,0.12,0),Vector3(0.85,0.24,0.85),edge)
	F.box(self,p+Vector3(0,0.62,0),Vector3(0.32,0.8,0.32),stone,true)
	F.box(self,p+Vector3(0,1.18,0),Vector3(0.58,0.46,0.58),F.material(Color("eec588"),0,0.7,2.5))
	F.cylinder(self,p+Vector3(0,1.5,0),0.55,0.3,dark,0.07,4)
	for x in [-0.3,0.3]:
		for z in [-0.3,0.3]: F.box(self,p+Vector3(x,1.17,z),Vector3(0.07,0.55,0.07),dark)
	var light := OmniLight3D.new()
	light.position = p+Vector3(0,1.35,0)
	light.light_color = Color("ffbe77")
	light.light_energy = 2.1
	light.omni_range = 4
	add_child(light)

func build_seal(p: Vector3) -> void:
	var seal := Node3D.new()
	seal.position = p
	add_child(seal)
	F.cylinder(seal,Vector3(0,0.14,0),1.25,0.28,edge,-1,8)
	F.ring(seal,Vector3(0,0.3,0),1.0,0.04,gold)
	F.cylinder(seal,Vector3(0,0.66,0),0.38,0.9,stone,0.28,6)
	var body := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var column := CylinderShape3D.new()
	column.radius = 0.4
	column.height = 1.1
	collider.shape = column
	collider.position.y = 0.55
	body.add_child(collider)
	seal.add_child(body)
	var core := F.sphere(seal,Vector3(0,1.45,0),0.23,F.material(Color("97c5be"),0.2,0.3,2))
	core.name = "Core"
	var light := OmniLight3D.new()
	light.position.y = 1.7
	light.light_color = Color("73b9b6")
	light.light_energy = 1.5
	light.omni_range = 3
	seal.add_child(light)
	seals.append(seal)

func build_rain() -> void:
	var rain := GPUParticles3D.new()
	rain.amount = 800
	rain.lifetime = 1.8
	rain.visibility_aabb = AABB(Vector3(-30,-2,-30),Vector3(60,25,60))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(23,1,23)
	process.direction = Vector3(-0.15,-1,0)
	process.spread = 2
	process.initial_velocity_min = 10
	process.initial_velocity_max = 14
	process.gravity = Vector3(0,-4,0)
	process.color = Color(0.65,0.8,0.84,0.2)
	rain.process_material = process
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.008,0.2,0.008)
	mesh.material = F.material(Color(0.7,0.8,0.83,0.2))
	rain.draw_pass_1 = mesh
	rain.position.y = 15
	add_child(rain)

func _process(delta: float) -> void:
	elapsed += delta
	for i in range(fireflies.size()):
		fireflies[i].position.y += sin(elapsed*0.7+i)*delta*0.08
	for seal in seals:
		seal.get_node("Core").position.y = 1.45+sin(elapsed*2)*0.08
	var target := player.position
	if mode == "title":
		target = Vector3(0,0,-1)
		camera.size = lerpf(camera.size,25.0,delta*2)
	else:
		camera.size = lerpf(camera.size,13.0 if not is_instance_valid(boss_node) else 15.5,delta*2)
	camera_target = camera_target.lerp(target,1-exp(-delta*6))
	camera.position = camera_target + Vector3(16,22,16)
	if shake_enabled and shake > 0:
		camera.position += Vector3(rng.randf_range(-shake,shake),rng.randf_range(-shake,shake),0)
	shake = move_toward(shake,0,delta*1.5)
	camera.look_at(camera_target,Vector3.UP)
	if mode != "play": return
	if Input.is_action_just_pressed("wave_skill"): cast(0)
	if Input.is_action_just_pressed("burst_skill"): cast(1)
	if Input.is_action_just_pressed("wine"): heal()
	if Input.is_action_just_pressed("seal_interact"): interact()
	if Input.is_action_just_pressed("cycle_weapon") and player.action == "idle":
		player.weapon = (player.weapon+1)%3
		player.make_weapon()
	run_time += delta
	for i in range(2): skill_cooldowns[i] = maxf(0,skill_cooldowns[i]-delta)
	if encounter:
		if current_seal == 2:
			hazard_timer -= delta
			if hazard_timer <= 0:
				hazard_timer = 5.5
				var hazard := Node3D.new()
				hazard.set_script(preload("res://scripts/rebirth/SealHazard.gd"))
				hazard.world = self
				hazard.position = player.position
				add_child(hazard)
		spawn_timer -= delta
		if spawn_queue > 0 and spawn_timer <= 0:
			spawn_guard()
			spawn_queue -= 1
			spawn_timer = 1.8
		if spawn_queue == 0 and living_enemies() == 0 and not is_instance_valid(boss_node):
			complete_seal()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.relative.length() > 0.5: mouse_aim_time = elapsed
	if event.is_action_pressed("attack"): player.attack_buffer = 0.22
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START:
		if mode == "title": start_run()
		elif mode == "play":
			mode = "pause"
			ui.show_pause()
		elif mode == "pause": resume()
	if event is InputEventKey and event.pressed and event.keycode == KEY_F11:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if mode == "play":
				mode = "pause"
				ui.show_pause()
			elif mode == "pause": resume()
		if mode != "play": return
		match event.keycode:
			KEY_F: interact()
			KEY_Q: cast(0)
			KEY_E: cast(1)
			KEY_R: heal()
			KEY_1,KEY_2,KEY_3:
				if player.action == "idle":
					player.weapon = event.keycode-KEY_1
					player.make_weapon()
					notify(["听雨 · 直剑","断岳 · 重刃","流萤 · 灵剑"][player.weapon],"兵刃已切换",1.4)

func start_run() -> void:
	Input.action_release("dash")
	Input.action_release("attack")
	mode = "play"
	activated = true
	ui.clear_modal()
	notify("第一章 · 雨歇山门", "靠近石灯按 F，解开三处封印",4)

func resume() -> void:
	Input.action_release("dash")
	mode = "play"
	ui.clear_modal()

func aim_point() -> Vector3:
	var mouse := get_viewport().get_mouse_position()
	var origin := camera.project_ray_origin(mouse)
	var direction := camera.project_ray_normal(mouse)
	var point = Plane(Vector3.UP,0.7).intersects_ray(origin,direction)
	return point if point != null else player.position+player.facing*2

func nearest_seal() -> int:
	for i in range(seals.size()):
		if not seal_done[i] and player.position.distance_to(seals[i].position) < 2.5: return i
	return -1

func interact() -> void:
	if try_execute(): return
	if encounter: return
	var index := nearest_seal()
	if index < 0: return
	current_seal = index
	encounter = true
	spawn_queue = 4 + round_index*2
	spawn_timer = 0.8
	hazard_timer = 4.0
	notify(["听雨台","照影台","归藏台"][index],"守灯人已醒 · 击退来敌",3)
	burst(seals[index].position+Vector3.UP,Color("a4d9c5"),25,3)

func spawn_guard() -> void:
	var enemy := ACTOR.new()
	enemy.world = self
	enemy.kind = 2 if current_seal > 0 and spawn_queue % 3 == 0 else (round_index + spawn_queue) % 2
	var angle := rng.randf()*TAU
	var center: Vector3 = seals[current_seal].position
	enemy.position = center + Vector3(cos(angle)*4.5,0.05,sin(angle)*4.5)
	enemy.position.x = clampf(enemy.position.x,-16,16)
	enemy.position.z = clampf(enemy.position.z,-15,14)
	add_child(enemy)
	enemies.append(enemy)
	burst(enemy.position,Color("9eb7ad"),12,1.6)

func living_enemies() -> int:
	var count := 0
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.dead: count += 1
	return count

func complete_seal() -> void:
	encounter = false
	seal_done[current_seal] = true
	seals[current_seal].get_node("Core").material_override = F.material(Color("e9c68b"),0.3,0.3,3)
	round_index += 1
	player.hp = minf(player.max_hp,player.hp+3)
	player.stamina = 100
	if round_index == 3:
		begin_boss()
	else:
		mode = "upgrade"
		ui.show_upgrade()

func upgrade(choice: int) -> void:
	if choice == 0: player.damage_bonus += 0.7
	else:
		player.max_hp += 3
		player.hp = player.max_hp
	resume()
	notify("封印已解", "前往下一座石灯 · 已恢复气血",3)

func begin_boss() -> void:
	boss_node = ACTOR.new()
	boss_node.boss = true
	boss_node.world = self
	boss_node.position = Vector3(0,0.05,-2)
	add_child(boss_node)
	enemies.append(boss_node)
	burst(boss_node.position+Vector3.UP,Color("d6b083"),36,4)
	notify("无 相", "山门最后的守剑人",4)

func melee(attacker: Node3D) -> void:
	if not attacker.hero and not attacker.boss and attacker.kind == 2:
		var bolt := Node3D.new()
		bolt.set_script(preload("res://scripts/rebirth/SpiritBolt.gd"))
		bolt.world = self
		bolt.source = attacker
		bolt.direction = attacker.locked
		bolt.position = attacker.position+Vector3.UP*0.8
		add_child(bolt)
		return
	var targets: Array = enemies if attacker.hero else [player]
	var reach := (2.4 if attacker.weapon == 1 else 1.95) if attacker.hero else (2.8 if attacker.boss else 2.0)
	for target in targets:
		if not is_instance_valid(target) or target.dead: continue
		var offset: Vector3 = target.position-attacker.position
		offset.y = 0
		var minimum_dot := (0.5 if attacker.combo == 3 and attacker.weapon != 1 else 0.0) if attacker.hero else 0.65
		if offset.length() > reach or attacker.locked.dot(offset.normalized()) < minimum_dot: continue
		var query := PhysicsRayQueryParameters3D.create(attacker.position+Vector3.UP,target.position+Vector3.UP,1)
		if not get_world_3d().direct_space_state.intersect_ray(query).is_empty(): continue
		var damage: float = (2.6 if attacker.weapon == 1 else 1.4) + attacker.damage_bonus if attacker.hero else (3.0 if attacker.boss else 1.5)
		if attacker.combo == 3: damage *= 1.5
		if attacker.parry_reward > 0:
			damage *= 1.5
			target.apply_posture(30)
			attacker.parry_reward = 0
		if target.hurt(damage,attacker):
			flash(target.position+Vector3.UP,Color("accfdb") if target.last_guarded else Color("e9d5a6"))
			if attacker.hero: target.apply_posture(30 if attacker.weapon == 1 else 18)
			if attacker.hero and attacker.weapon == 1 and not target.boss and not target.dead and target.action != "broken" and target.interrupt_resist <= 0:
				target.action = "stunned"
				target.timer = 0.25
				target.interrupt_resist = 1.3
			if attacker.hero and attacker.weapon == 2:
				attacker.stamina = minf(100,attacker.stamina+4)
	if attacker.hero and attacker.weapon == 2 and attacker.combo == 3:
		var wave := Node3D.new()
		wave.set_script(preload("res://scripts/rebirth/SwordWave.gd"))
		wave.world = self
		wave.direction = attacker.locked
		wave.position = attacker.position+Vector3.UP*0.8
		add_child(wave)
	impact(0.025,0.4)

func cast(index: int) -> void:
	if mode != "play" or skill_cooldowns[index] > 0 or player.stamina < 24: return
	if index == 0:
		if not is_instance_valid(echo):
			notify("先留雨痕", "闪避后按 Q，沿留影回锋",1.2)
			return
		var end: Vector3 = echo.position
		var origin: Vector3 = player.position
		var line := end-origin
		line.y = 0
		if line.length() < 0.7: return
		var ray := PhysicsRayQueryParameters3D.create(origin+Vector3.UP*0.7,end+Vector3.UP*0.7,1)
		var obstruction := get_world_3d().direct_space_state.intersect_ray(ray)
		if not obstruction.is_empty():
			notify("归路受阻", "雨痕与自身之间需要通路",1.2)
			return
		player.stamina -= 24
		skill_cooldowns[0] = 2.8
		player.action = "recall"
		player.duration = clampf(line.length()/30,0.12,0.45)
		player.recall_speed = line.length()/player.duration
		player.timer = player.duration
		player.locked = line.normalized()
		player.facing = player.locked
		player.immunity = player.duration+0.1
		player.hit_stop = 0
		for enemy in enemies:
			if not is_instance_valid(enemy) or enemy.dead: continue
			var t := clampf((enemy.position-origin).dot(line)/line.length_squared(),0,1)
			if enemy.position.distance_to(origin+line*t) < 1.25:
				enemy.hurt(3.2+player.damage_bonus,player)
				enemy.apply_posture(42)
				flash(enemy.position+Vector3.UP,Color("a4e0d0"))
		echo.queue_free()
		echo = null
		combat_sound("recall")
	else:
		player.stamina -= 24
		skill_cooldowns[1] = 4.0
		player.action = "cast"
		player.duration = 0.28
		player.timer = 0.28
		player.immunity = 0.18
		var direction: Vector3 = (aim_point()-player.position) if elapsed-mouse_aim_time < 4 else player.facing
		direction.y = 0
		if direction.length() < 0.3: direction = player.facing
		direction = direction.normalized()
		player.facing = direction
		var pressure := Node3D.new()
		pressure.set_script(preload("res://scripts/rebirth/PressureWave.gd"))
		pressure.world = self
		pressure.direction = direction
		pressure.position = player.position
		add_child(pressure)
		for enemy in enemies:
			if not is_instance_valid(enemy) or enemy.dead: continue
			var offset: Vector3 = enemy.position-player.position
			offset.y = 0
			if offset.length() < 3.8 and direction.dot(offset.normalized()) > 0.25:
				enemy.hurt(1.0,player)
				enemy.launch(direction,14.0)
		combat_sound("heavy")
		impact(0.12,0.4)

func heal() -> void:
	if heal_count <= 0 or player.hp >= player.max_hp: return
	heal_count -= 1
	player.hp = minf(player.max_hp,player.hp+5)
	burst(player.position+Vector3.UP,Color("b3d2a9"),18,1.5)
	notify("温酒", "气血恢复",1.4)

func fallen(actor: Node3D) -> void:
	if actor.hero:
		mode = "defeat"
		ui.show_result(false)
	else:
		kills += 1
		player.stamina = minf(100,player.stamina+10)
		if actor.boss:
			mode = "victory"
			if best == 0 or run_time < best: best = run_time
			save_settings()
			ui.show_result(true)

func notify(title: String, subtitle: String, seconds := 2.5) -> void:
	if is_instance_valid(ui): ui.notify(title,subtitle,seconds)

func impact(amount: float, _pitch: float) -> void:
	shake = minf(0.24,shake+amount)

func combat_sound(sound: String) -> void:
	if DisplayServer.get_name() == "headless" or combat_voices.is_empty(): return
	var now := Time.get_ticks_msec()
	if now-int(sound_clock.get(sound,-1000)) < 40: return
	sound_clock[sound] = now
	var voice := combat_voices[voice_index%combat_voices.size()]
	voice_index += 1
	voice.stream = sound_bank.get(sound)
	voice.pitch_scale = rng.randf_range(0.94,1.06)
	voice.play()

func burst(p: Vector3, color: Color, count: int, spread: float) -> void:
	for i in range(count):
		var shard := F.box(self,p,Vector3(0.025,0.025,rng.randf_range(0.07,0.2)),F.material(color,0.4,0.4,0.5))
		var target := p + Vector3(rng.randf_range(-spread,spread),rng.randf_range(0.2,spread),rng.randf_range(-spread,spread))
		shard.rotation = Vector3(rng.randf()*3,rng.randf()*3,0)
		var tween := create_tween().set_parallel(true)
		tween.tween_property(shard,"position",target,0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(shard,"scale",Vector3.ZERO,0.4).set_delay(0.1)
		tween.chain().tween_callback(shard.queue_free)

func flash(p: Vector3, color: Color) -> void:
	var hit := Node3D.new()
	hit.set_script(preload("res://scripts/rebirth/CombatImpact.gd"))
	hit.position = p
	hit.color = color
	add_child(hit)

func save_settings() -> void:
	if not persist_progress: return
	var config := ConfigFile.new()
	config.set_value("settings","shake",shake_enabled)
	config.set_value("settings","sound",not AudioServer.is_bus_mute(0))
	config.set_value("run","best",best)
	config.save("user://stillwater.cfg")

func configure_gamepad() -> void:
	for action in ["aim_left","aim_right","aim_up","aim_down","wave_skill","burst_skill","wine","seal_interact","cycle_weapon"]:
		if not InputMap.has_action(action): InputMap.add_action(action,0.2)
	var sticks := [["move_left",JOY_AXIS_LEFT_X,-1.0],["move_right",JOY_AXIS_LEFT_X,1.0],["move_up",JOY_AXIS_LEFT_Y,-1.0],["move_down",JOY_AXIS_LEFT_Y,1.0],["aim_left",JOY_AXIS_RIGHT_X,-1.0],["aim_right",JOY_AXIS_RIGHT_X,1.0],["aim_up",JOY_AXIS_RIGHT_Y,-1.0],["aim_down",JOY_AXIS_RIGHT_Y,1.0]]
	for binding in sticks:
		var event := InputEventJoypadMotion.new()
		event.axis = binding[1]
		event.axis_value = binding[2]
		if not InputMap.action_has_event(binding[0],event): InputMap.action_add_event(binding[0],event)
	for binding in [["attack",JOY_BUTTON_X],["dash",JOY_BUTTON_A],["defend",JOY_BUTTON_LEFT_SHOULDER],["wave_skill",JOY_BUTTON_RIGHT_SHOULDER],["burst_skill",JOY_BUTTON_Y],["wine",JOY_BUTTON_B],["seal_interact",JOY_BUTTON_DPAD_UP],["cycle_weapon",JOY_BUTTON_DPAD_RIGHT]]:
		var event := InputEventJoypadButton.new()
		event.button_index = binding[1]
		if not InputMap.action_has_event(binding[0],event): InputMap.action_add_event(binding[0],event)

func boss_pulse(attacker: Node3D) -> void:
	burst(attacker.position+Vector3.UP*0.15,Color("e7b279"),32,3.8)
	var circle := F.ring(self,attacker.position+Vector3.UP*0.2,0.5,0.035,F.material(Color("e7b279"),0,0.5,1.1))
	var tween := create_tween().set_parallel(true)
	tween.tween_property(circle,"scale",Vector3.ONE*7.6,0.35)
	tween.tween_property(circle,"transparency",1.0,0.4)
	tween.chain().tween_callback(circle.queue_free)
	if player.position.distance_to(attacker.position) < 3.8: player.hurt(3,attacker)

func prepare_shutdown() -> void:
	mode = "closing"

func leave_echo() -> void:
	if is_instance_valid(echo): echo.queue_free()
	echo = Node3D.new()
	echo.set_script(preload("res://scripts/rebirth/RainEcho.gd"))
	echo.world = self
	echo.position = player.position
	add_child(echo)

func crash(victim: Node3D, collider: Node) -> void:
	if victim.dead: return
	var force: Vector3 = victim.knockback.normalized()
	victim.hurt(2.0,player)
	victim.apply_posture(45)
	victim.knockback *= 0.12
	if collider in enemies and is_instance_valid(collider) and not collider.dead:
		collider.hurt(2.0,player)
		collider.launch(force,8)
	flash(victim.position+Vector3.UP,Color("ffe1a3"))
	combat_sound("crash")
	impact(0.18,0.5)
	notify("撞 破", "借力破势",0.8)

func executable_target() -> Node3D:
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.dead and enemy.action == "broken" and enemy.position.distance_to(player.position) < 3.0: return enemy
	return null

func try_execute() -> bool:
	var target := executable_target()
	if target == null: return false
	player.facing = (target.position-player.position).normalized()
	player.action = "execute"
	player.timer = 0.3
	player.duration = 0.3
	player.immunity = 0.4
	player.stamina = minf(100,player.stamina+30)
	target.immunity = 0
	target.hurt(11 if target.boss else 50,player)
	if not target.dead:
		target.action = "stunned"
		target.timer = 0.55
	flash(target.position+Vector3.UP,Color("fbe4b6"))
	combat_sound("crash")
	impact(0.23,1.2)
	notify("追 斩", "破势终结 · 体力恢复",1.2)
	return true
