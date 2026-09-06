extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var world := preload("res://scenes/rebirth/Stillwater.tscn").instantiate()
	world.persist_progress = false
	root.add_child(world)
	world.start_run()
	var actor = world.player
	actor.set_physics_process(false)
	var puppet = actor.puppet
	var skeleton: Skeleton3D = puppet.skeleton
	var arm := skeleton.find_bone("upperarm.r")
	for weapon in range(3):
		actor.weapon = weapon
		for combo in range(1,4):
			actor.action = "idle"
			puppet.update_pose(0.1)
			var initial := skeleton.get_bone_pose_rotation(arm)
			var maximum := 0.0
			var first_pose := Quaternion.IDENTITY
			var movement := 0.0
			actor.action = "attack"
			actor.combo = combo
			actor.duration = 0.46 if weapon == 1 else 0.33
			for frame in range(20):
				actor.timer = actor.duration*(1-float(frame)/20)
				puppet.update_pose(actor.duration/20)
				var pose := skeleton.get_bone_pose_rotation(arm)
				if frame == 0: first_pose = pose
				movement = maxf(movement,first_pose.angle_to(pose))
				maximum = maxf(maximum,initial.angle_to(pose))
			print("weapon ",weapon," combo ",combo," arm excursion ",maximum)
			if maximum < 0.5 or movement < 0.5:
				failures += 1
				push_error("Attack animation did not visibly move the weapon arm")
	world.queue_free()
	await process_frame
	print("Animation checks: ",failures," failures")
	quit(failures)
