extends Node3D
const F := preload("res://scripts/rebirth/Form.gd")
var actor: Node3D
var model: Node3D
var skeleton: Skeleton3D
var animation: AnimationPlayer
var hand: Node3D
var meshes: Array[MeshInstance3D] = []
var last_clip := ""
var state_clock := 0.0
var last_action := ""
var hit_material: StandardMaterial3D
var robe_materials: Array[ShaderMaterial] = []
var scarf: MeshInstance3D
var scarf_mesh: ImmediateMesh
var scarf_anchor: BoneAttachment3D
var accessory_clock := 0.0
var head_bone := -1

func _ready() -> void:
	var scene: PackedScene
	if actor.hero:
		scene = preload("res://assets/characters/kaykit/Rogue_Hooded.glb")
	elif actor.kind == 2 and not actor.boss:
		scene = preload("res://assets/characters/kaykit/Mage.glb")
	else:
		scene = preload("res://assets/characters/kaykit/Knight.glb")
	model = scene.instantiate()
	model.rotation.y = PI
	model.scale = Vector3(0.83,0.96,0.82) if actor.hero else Vector3.ONE*(1.02 if actor.boss else 0.87)
	add_child(model)
	skeleton = model.find_child("Skeleton3D",true,false)
	animation = model.find_child("AnimationPlayer",true,false)
	animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	hand = skeleton.get_node("handslot_r")
	for child in hand.get_children(): child.visible = false
	var offhand := skeleton.get_node_or_null("handslot_l")
	if offhand:
		for child in offhand.get_children(): child.visible = false
	collect_meshes(model)
	retone()
	if actor.hero: build_scarf()
	hit_material = F.material(Color(1.0,0.9,0.72,0.28),0,0.3,0.6)
	hit_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	# Keep the original licensed mesh; tune the rendered proportions through its rig.
	animation.play("Idle")
	animation.advance(0)
	var root_pose := skeleton.get_bone_pose_position(0)
	root_pose.x = 0
	root_pose.z = 0
	skeleton.set_bone_pose_position(0,root_pose)
	head_bone = skeleton.find_bone("head")
	skeleton.set_bone_pose_scale(head_bone,Vector3.ONE*(0.55 if actor.hero else 0.60))

func collect_meshes(node: Node) -> void:
	if node is MeshInstance3D:
		meshes.append(node)
	for child in node.get_children(): collect_meshes(child)

func update_pose(delta: float) -> void:
	state_clock += delta
	accessory_clock += delta
	var state: String = actor.action
	if state != last_action:
		last_action = state
		state_clock = 0
	var clip := "Idle"
	var sample := -1.0
	var progress: float = clampf(1-actor.timer/maxf(actor.duration,0.01),0,1)
	if actor.dead:
		clip = "Death_A"
		sample = minf(state_clock,animation.get_animation(clip).length-0.01)
	elif state == "attack":
		if not actor.hero and not actor.boss and actor.kind == 2:
			clip = "Spellcast_Shoot"
		elif actor.weapon == 1:
			clip = ["2H_Melee_Attack_Slice","2H_Melee_Attack_Chop","2H_Melee_Attack_Spin"][actor.combo-1]
		else:
			clip = ["1H_Melee_Attack_Slice_Horizontal","1H_Melee_Attack_Slice_Diagonal","1H_Melee_Attack_Stab"][actor.combo-1]
		# Each source clip strikes at a different moment. Preserve its windup
		# and follow-through instead of skipping straight past the slash.
		var contact := 0.40
		var windup := 0.25
		var follow := 0.62
		if actor.weapon == 1:
			contact = [0.40,0.50,0.30][actor.combo-1]
			windup = [0.28,0.40,0.20][actor.combo-1]
			follow = [0.65,0.65,0.62][actor.combo-1]
		else:
			contact = [0.26,0.40,0.29][actor.combo-1]
			windup = [0.18,0.29,0.20][actor.combo-1]
			follow = [0.48,0.60,0.53][actor.combo-1]
		if not actor.hero and (actor.boss or actor.kind != 2):
			clip = "2H_Melee_Attack_Chop" if actor.boss else "1H_Melee_Attack_Chop"
			windup = 0.40 if actor.boss else 0.48
			contact = 0.50 if actor.boss else 0.58
			follow = 0.72
			if actor.attack_profile() == "thrust":
				clip = "1H_Melee_Attack_Stab"
				windup = 0.20
				contact = 0.29
				follow = 0.53
			elif actor.attack_profile() == "sweep":
				clip = "2H_Melee_Attack_Spin"
				windup = 0.20
				contact = 0.30
				follow = 0.62
		var hit_phase: float = actor.contact_fraction()
		var ready_phase := hit_phase*0.42
		if progress < ready_phase:
			sample = lerpf(0.0,windup,progress/ready_phase) if actor.hero else windup
		elif progress < hit_phase:
			sample = lerpf(windup,contact,(progress-ready_phase)/(hit_phase-ready_phase))
		elif progress < 0.65:
			sample = lerpf(contact,follow,(progress-hit_phase)/(0.65-hit_phase))
		else:
			sample = lerpf(follow,0.99,(progress-0.65)/0.35)
		sample *= animation.get_animation(clip).length
	elif state == "recall":
		clip = "1H_Melee_Attack_Slice_Horizontal"
		sample = lerpf(0.12,0.62,progress)*animation.get_animation(clip).length
	elif state == "dash":
		var relative: Vector3 = actor.locked.rotated(Vector3.UP,-actor.rig.rotation.y)
		if absf(relative.x) > absf(relative.z): clip = "Dodge_Right" if relative.x > 0 else "Dodge_Left"
		else: clip = "Dodge_Forward" if relative.z < 0 else "Dodge_Backward"
		sample = progress*animation.get_animation(clip).length
	elif state == "block_hit":
		clip = "Block_Hit"
		sample = progress*animation.get_animation(clip).length
	elif state == "hurt" or state == "guard_break":
		clip = "Hit_A"
		sample = lerpf(0.05,0.65,progress)*animation.get_animation(clip).length
	elif state == "launch":
		clip = "Hit_B"
		sample = minf(state_clock*1.5,animation.get_animation(clip).length-0.01)
	elif state == "broken" or state == "stunned":
		clip = "Hit_A" if state_clock < 0.25 else "Lie_Idle"
		sample = minf(state_clock,animation.get_animation(clip).length-0.01)
	elif state == "execute":
		clip = "2H_Melee_Attack_Chop"
		sample = lerpf(0.34,0.99,progress)*animation.get_animation(clip).length
	elif state == "cast":
		clip = "Unarmed_Melee_Attack_Kick"
		sample = lerpf(0.26,0.95,progress)*animation.get_animation(clip).length
	elif state == "windup":
		clip = "2H_Melee_Attack_Chop" if actor.boss else "1H_Melee_Attack_Chop"
		var ready := 0.40 if actor.boss else 0.48
		if actor.kind == 2 and not actor.boss:
			clip = "Spellcast_Shoot"
			ready = 0.25
		elif actor.attack_profile() in ["thrust","charge"]:
			clip = "2H_Melee_Attack_Stab" if actor.boss else "1H_Melee_Attack_Stab"
			ready = 0.20
		elif actor.attack_profile() == "sweep":
			clip = "2H_Melee_Attack_Spin"
			ready = 0.20
		elif actor.attack_profile() == "pulse":
			clip = "Spellcast_Raise"
			if not animation.has_animation(clip): clip = "Spellcast_Shoot"
			ready = 0.5
		sample = lerpf(0.0,ready,minf(1,progress/0.6))*animation.get_animation(clip).length
	elif state == "charge":
		clip = "2H_Melee_Attack_Stab"
		sample = lerpf(0.20,0.35,progress)*animation.get_animation(clip).length
	elif actor.guarding:
		clip = "Blocking"
	elif actor.hit_flash > 0:
		clip = "Hit_A"
		sample = (0.16-actor.hit_flash)*2
	elif actor.movement.length() > 0.1 and actor.velocity.length() > 0.3:
		clip = "Running_B" if actor.hero else "Running_A"
	if last_clip != clip:
		# Sampled actions must not use a timed blend: advance(0) never
		# advances its blend clock, so the outgoing idle pose would win forever.
		animation.play(clip,0.045 if sample < 0 else 0.0)
		last_clip = clip
	if sample >= 0:
		animation.seek(sample,true)
		animation.advance(0)
	else:
		animation.advance(delta*(clampf(actor.velocity.length()/4.4,0.25,1.3) if clip.begins_with("Running") else 1.0))
	var root_pose := skeleton.get_bone_pose_position(0)
	root_pose.x = 0
	root_pose.z = 0
	skeleton.set_bone_pose_position(0,root_pose)
	skeleton.set_bone_pose_scale(head_bone,Vector3.ONE*(0.55 if actor.hero else 0.60))
	for mesh in meshes:
		mesh.material_overlay = hit_material if actor.hit_flash > 0 else null
	if actor.action == "launch":
		position.y = sin(progress*PI)*0.32
	else:
		position.y = lerpf(position.y,0,minf(1,delta*18))
	if actor.hero and is_instance_valid(scarf): update_scarf()
	for mat in robe_materials:
		mat.set_shader_parameter("resolve",minf(actor.parry_reward,1.0) if actor.hero else (0.4 if actor.action == "broken" else 0.0))

func retone() -> void:
	var shader := Shader.new()
	shader.code = """shader_type spatial;
uniform sampler2D palette:source_color;
uniform vec3 cloth_color:source_color=vec3(0.16,0.32,0.34);
uniform bool hero=false;
uniform float resolve=0.0;
void fragment(){vec3 c=texture(palette,UV).rgb;float light=dot(c,vec3(0.299,0.587,0.114));bool dye=c.g>c.r*1.10&&c.g>c.b*1.04;bool blue=c.b>c.r*1.12;if(dye||blue){c=cloth_color*(0.65+light*0.75);}else if(!hero){c=mix(vec3(light),c,0.30)*0.67;}ALBEDO=c;ROUGHNESS=0.74;METALLIC=hero?0.04:0.35;RIM=hero?0.30:0.13;RIM_TINT=0.4;EMISSION=cloth_color*resolve*0.20;}
"""
	for mesh in meshes:
		for i in range(mesh.mesh.get_surface_count()):
			var original := mesh.get_active_material(i) as StandardMaterial3D
			if original == null: continue
			var mat := ShaderMaterial.new()
			mat.shader = shader
			var palette: Texture2D = original.albedo_texture
			if palette == null:
				palette = preload("res://assets/characters/kaykit/Rogue_Hooded_rogue_texture.png") if actor.hero else (preload("res://assets/characters/kaykit/Mage_mage_texture.png") if actor.kind == 2 and not actor.boss else preload("res://assets/characters/kaykit/Knight_knight_texture.png"))
			mat.set_shader_parameter("palette",palette)
			mat.set_shader_parameter("hero",actor.hero)
			var dye := Color("395458")
			if actor.hero:
				dye = Color("467b79")
				if "Cape" in mesh.name or "Head" in mesh.name: dye = Color("173e48")
				elif "Arm" in mesh.name: dye = Color("b8c9b8")
			elif actor.boss: dye = Color("73604c")
			elif actor.kind == 1: dye = Color("764c3b")
			elif actor.kind == 2: dye = Color("356b66")
			mat.set_shader_parameter("cloth_color",dye)
			mesh.set_surface_override_material(i,mat)
			robe_materials.append(mat)

func build_scarf() -> void:
	scarf_anchor = BoneAttachment3D.new()
	scarf_anchor.bone_name = "chest"
	skeleton.add_child(scarf_anchor)
	var silk := F.material(Color("d5d5b4"),0,0.9)
	silk.cull_mode = BaseMaterial3D.CULL_DISABLED
	F.cylinder(scarf_anchor,Vector3(0,0.22,0),0.145,0.085,silk,-1,12)
	scarf_mesh = ImmediateMesh.new()
	scarf = F.instance(scarf_anchor,scarf_mesh,Vector3(0,0.23,-0.13),silk)
	scarf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

func update_scarf() -> void:
	scarf_mesh.clear_surfaces()
	scarf_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var speed: float = clampf(actor.velocity.length()/7.0,0,1)
	for tail in range(2):
		for section in range(7):
			var a := scarf_point(float(section)/7.0,tail,speed)
			var b := scarf_point(float(section+1)/7.0,tail,speed)
			var width_a := 0.050*(1.0-float(section)/10.0)
			var width_b := 0.050*(1.0-float(section+1)/10.0)
			for vertex in [a+Vector3.LEFT*width_a,b+Vector3.LEFT*width_b,a+Vector3.RIGHT*width_a,a+Vector3.RIGHT*width_a,b+Vector3.LEFT*width_b,b+Vector3.RIGHT*width_b]:
				scarf_mesh.surface_set_normal(Vector3.BACK)
				scarf_mesh.surface_add_vertex(vertex)
	scarf_mesh.surface_end()

func scarf_point(t: float, tail: int, speed: float) -> Vector3:
	var side := -1.0 if tail == 0 else 1.0
	var flutter := sin(accessory_clock*(5.0+speed*5.0)-t*5.0+tail)*t*t
	return Vector3(side*(0.06+t*0.07)+flutter*0.08,-t*(0.67-speed*0.25)+flutter*0.035,-t*(0.10+speed*0.63)+absf(flutter)*0.06)
