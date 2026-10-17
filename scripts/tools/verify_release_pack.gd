extends SceneTree
## Run from an empty project directory so source files cannot mask omissions.

var failures := 0

func _initialize() -> void:
	call_deferred("verify")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func walk(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null: return
	for name in directory.get_directories():
		if name == ".godot": continue
		walk(path.path_join(name))
	for name in directory.get_files():
		var file := path.path_join(name)
		for forbidden in ["Photoroom", "assets/xianxia/", "assets/art_v2/", "assets/unused/", "docs/showcase/", ".superpowers/"]:
			check(not forbidden in file, "Excluded material in pack: " + file)

func verify() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1 or not ProjectSettings.load_resource_pack(args[0]):
		push_error("Pass one readable exported .pck file")
		quit(1)
		return
	walk("res://")
	for file in ["LICENSE", "LICENSE_SCOPE.md", "THIRD_PARTY_NOTICES.md", "licenses/GODOT_LICENSE.txt", "licenses/GODOT_COPYRIGHT.txt", "licenses/CC0-1.0.txt", "licenses/KAYKIT_CC0_NOTICE.txt", "licenses/NOTO_SANS_OFL.txt", "licenses/NOTO_SERIF_OFL.txt"]:
		check(FileAccess.file_exists("res://" + file), "Missing notice: " + file)
		if FileAccess.file_exists("res://" + file):
			check(FileAccess.get_file_as_string("res://" + file).length() > 100, "Empty notice: " + file)
	for sound in ["swing", "heavy", "hit", "guard", "parry", "dash", "recall", "crash", "ready", "surge", "seal", "boss", "victory", "ui"]:
		check(load("res://assets/audio/combat/" + sound + ".wav") != null, "Missing sound: " + sound)
	var scene := load("res://scenes/rebirth/Stillwater.tscn") as PackedScene
	check(scene != null, "Missing 3D entry scene")
	if scene != null:
		var world := scene.instantiate()
		world.persist_progress = false
		root.add_child(world)
		await process_frame
		await process_frame
		check(world.player != null and world.ui != null, "3D scene failed to initialize")
		world.queue_free()
		await process_frame
	print("Release pack verification failures: ", failures)
	quit(failures)
