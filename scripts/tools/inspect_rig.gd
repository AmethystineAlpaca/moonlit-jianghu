extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func walk(node: Node, indent := "") -> void:
	print(indent,node.name," ",node.get_class())
	if node is Skeleton3D:
		for i in range(node.get_bone_count()): print("BONE ",i," ",node.get_bone_name(i)," ",node.get_bone_rest(i))
	if node is AnimationPlayer:
		for a in node.get_animation_list():
			if "Melee" in a or a == "Idle" or "Dodge" in a: print("CLIP ",a," ",node.get_animation(a).length)
	for child in node.get_children(): walk(child,indent+" ")
func run() -> void:
	var model := preload("res://assets/characters/kaykit/Rogue_Hooded.glb").instantiate()
	root.add_child(model)
	walk(model)
	model.queue_free()
	await process_frame
	quit()
