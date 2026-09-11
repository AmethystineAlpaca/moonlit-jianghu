extends SceneTree

const ATMOSPHERE := preload("res://scripts/rebirth/CourtyardAtmosphere.gd")
const F := preload("res://scripts/rebirth/Form.gd")
var failures := 0

class RitualWorld extends Node3D:
	var seals: Array[Node3D] = []
	var seal_done := [false, false, false]
	var encounter := false
	var current_seal := -1
	var boss_node: Node3D
	var gold: Material

class RitualBoss extends Node3D:
	var dead := false

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func count_blooms(atmosphere: Node3D) -> int:
	var count := 0
	for child in atmosphere.get_children():
		if child.get_script() == preload("res://scripts/rebirth/SealBloom.gd"): count += 1
	return count

func run() -> void:
	var world := RitualWorld.new()
	world.gold = F.material(Color("b89a61"))
	root.add_child(world)
	for i in range(3):
		var seal := Node3D.new()
		seal.position = Vector3((i - 1) * 8, 0, -8)
		seal.add_child(OmniLight3D.new())
		world.add_child(seal)
		world.seals.append(seal)
	var atmosphere := ATMOSPHERE.new()
	atmosphere.world = world
	world.add_child(atmosphere)
	atmosphere.set_process(false)
	atmosphere.update_ritual_states()
	check(count_blooms(atmosphere) == 0, "dormant scenery does not emit ritual celebrations")
	world.current_seal = 1
	world.encounter = true
	atmosphere.update_ritual_states()
	atmosphere.update_ritual_states()
	check(count_blooms(atmosphere) == 1, "repeated active state checks emit the activation bloom once")
	check(not world.seal_done[1] and world.encounter, "visual activation cannot advance gameplay")
	world.encounter = false
	world.seal_done[1] = true
	atmosphere.update_ritual_states()
	var completed_material: ShaderMaterial = atmosphere.seal_visuals[1].material
	var dormant_material: ShaderMaterial = atmosphere.seal_visuals[0].material
	check(completed_material.get_shader_parameter("tint") != dormant_material.get_shader_parameter("tint"), "completing one seal preserves the other seal colors")
	check(count_blooms(atmosphere) == 2, "seal completion produces one distinct celebration")
	world.boss_node = RitualBoss.new()
	world.add_child(world.boss_node)
	atmosphere.update_ritual_states()
	check(atmosphere.court_visible, "living final duelist illuminates the central court")
	world.boss_node.dead = true
	atmosphere.update_ritual_states()
	check(not atmosphere.court_visible, "defeated final duelist releases the central ritual")
	for child in atmosphere.get_children():
		if child.get_script() == preload("res://scripts/rebirth/SealBloom.gd"):
			child._process(10.0)
	await process_frame
	check(count_blooms(atmosphere) == 0, "all transient ritual geometry is reclaimed")
	world.queue_free()
	await process_frame
	print("Courtyard atmosphere: ", failures, " failures")
	quit(failures)
