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
	model.scale = Vector3.ONE * (1.02 if actor.boss else 0.87)
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
	hit_material = F.material(Color(1.0,0.9,0.72,0.28),0,0.3,0.6)
	hit_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	# Keep the original licensed mesh; tune the rendered proportions through its rig.
	animation.play("Idle")
	animation.advance(0)
	var root_pose := skeleton.get_bone_pose_position(0)
	root_pose.x = 0
	root_pose.z = 0
	skeleton.set_bone_pose_position(0,root_pose)
	skeleton.set_bone_pose_scale(skeleton.find_bone("head"),Vector3.ONE*0.60)

func collect_meshes(node: Node) -> void:
	if node is MeshInstance3D:
		meshes.append(node)
	for child in node.get_children(): collect_meshes(child)

func update_pose(delta: float) -> void:
	state_clock += delta
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
		var hit_phase := 0.20 if actor.hero else 0.44
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
		clip = "Dodge_Forward"
		sample = progress*animation.get_animation(clip).length
	elif state == "block_hit":
		clip = "Block_Hit"
		sample = progress*animation.get_animation(clip).length
	elif state == "hurt":
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
		sample = lerpf(0.0,ready,minf(1,progress/0.6))*animation.get_animation(clip).length
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
	skeleton.set_bone_pose_scale(skeleton.find_bone("head"),Vector3.ONE*0.60)
	for mesh in meshes:
		mesh.material_overlay = hit_material if actor.hit_flash > 0 else null
	if actor.action == "launch":
		position.y = sin(progress*PI)*0.32
	else:
		position.y = lerpf(position.y,0,minf(1,delta*18))

func retone() -> void:
	if DisplayServer.get_name() == "headless": return
	var shader := Shader.new()
	shader.code = """shader_type spatial;
uniform sampler2D palette:source_color;
uniform vec3 cloth_color:source_color=vec3(0.75,0.78,0.71);
uniform bool hero=false;
void fragment(){vec3 c=texture(palette,UV).rgb;float light=dot(c,vec3(0.299,0.587,0.114));bool dye=c.g>c.r*1.10&&c.g>c.b*1.04;bool blue=c.b>c.r*1.12;if(dye||blue){c=cloth_color*(0.55+light*0.65);}else if(!hero){c=mix(vec3(light),c,0.30)*0.67;}ALBEDO=c;ROUGHNESS=0.72;METALLIC=hero?0.02:0.32;RIM=0.18;RIM_TINT=0.5;}
"""
	for mesh in meshes:
		for i in range(mesh.mesh.get_surface_count()):
			var original := mesh.get_active_material(i) as StandardMaterial3D
			if original == null: continue
			var mat := ShaderMaterial.new()
			mat.shader = shader
			mat.set_shader_parameter("palette",original.albedo_texture)
			mat.set_shader_parameter("hero",actor.hero)
			mat.set_shader_parameter("cloth_color",Color("d9ded0") if actor.hero else Color("374d52"))
			mesh.set_surface_override_material(i,mat)
