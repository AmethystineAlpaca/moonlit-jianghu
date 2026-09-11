extends Node3D
const F := preload("res://scripts/rebirth/Form.gd")
var world: Node3D
var life := 4.5
var ghost: Node3D
var cloth: StandardMaterial3D
func _ready() -> void:
	ghost = preload("res://assets/characters/kaykit/Rogue_Hooded.glb").instantiate()
	add_child(ghost)
	ghost.global_transform = world.player.puppet.model.global_transform
	ghost.process_mode = Node.PROCESS_MODE_DISABLED
	var skeleton: Skeleton3D = ghost.find_child("Skeleton3D",true,false)
	var source: Skeleton3D = world.player.puppet.skeleton
	for i in range(source.get_bone_count()):
		skeleton.set_bone_pose_position(i,source.get_bone_pose_position(i))
		skeleton.set_bone_pose_rotation(i,source.get_bone_pose_rotation(i))
		skeleton.set_bone_pose_scale(i,source.get_bone_pose_scale(i))
	for slot in ["handslot_r","handslot_l"]:
		for prop in skeleton.get_node(slot).get_children(): prop.visible = false
	cloth = F.material(Color(0.47,0.79,0.75,0.22),0,0.3,0.4)
	cloth.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	style(ghost)
	F.ring(self,Vector3(0,0.17,0),0.32,0.018,F.material(Color("8acdbf"),0,0.4,0.6))
func style(node: Node) -> void:
	if node is AnimationPlayer: node.stop(true)
	if node is MeshInstance3D:
		node.material_override = cloth
		node.material_overlay = null
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children(): style(child)
func _process(delta: float) -> void:
	if world.mode != "play" or world.director.cinematic_left > 0: return
	life -= delta
	cloth.albedo_color.a = minf(0.16,life*0.12)
	if life <= 0: queue_free()
