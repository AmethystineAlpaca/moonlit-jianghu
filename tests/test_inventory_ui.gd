extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/World.tscn")

var failures := 0

func _initialize() -> void:
	await _test_inventory_opens_with_default_equipped_sword()
	await _test_inventory_toggle_pauses_and_resumes_game()
	await _test_inventory_moves_items_between_bag_and_equipment()
	quit(failures)

func _test_inventory_opens_with_default_equipped_sword() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame

	var hud := world.get_node("Hud")
	var weapon_button := hud.get_node("InventoryOverlay/Window/Margin/Layout/Columns/EquipmentPanel/EquipmentContent/WeaponButton") as Button
	var armor_button := hud.get_node("InventoryOverlay/Window/Margin/Layout/Columns/EquipmentPanel/EquipmentContent/ArmorButton") as Button
	_assert_true(weapon_button.text.contains("Iron Sword"), "inventory starts with the sword equipped")
	_assert_true(armor_button.text.contains("Empty"), "armor slot starts empty")

	world.free()

func _test_inventory_toggle_pauses_and_resumes_game() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame

	var hud := world.get_node("Hud")
	var inventory_overlay := hud.get_node("InventoryOverlay") as Control
	var toggle_event := InputEventAction.new()
	toggle_event.action = "toggle_inventory"
	toggle_event.pressed = true

	hud.call("_unhandled_input", toggle_event)
	await process_frame
	_assert_true(get_root().get_tree().paused, "opening inventory pauses the game")
	_assert_true(inventory_overlay.visible, "inventory overlay becomes visible")

	hud.call("_unhandled_input", toggle_event)
	await process_frame
	_assert_false(get_root().get_tree().paused, "closing inventory resumes the game")
	_assert_false(inventory_overlay.visible, "inventory overlay hides after closing")

	world.free()

func _test_inventory_moves_items_between_bag_and_equipment() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame

	var hud := world.get_node("Hud")
	var player := world.get_node("Player")
	var bag_slot_1 := hud.get_node("InventoryOverlay/Window/Margin/Layout/Columns/BagPanel/BagContent/BagGrid/BagSlot1") as Button
	var weapon_button := hud.get_node("InventoryOverlay/Window/Margin/Layout/Columns/EquipmentPanel/EquipmentContent/WeaponButton") as Button
	var armor_button := hud.get_node("InventoryOverlay/Window/Margin/Layout/Columns/EquipmentPanel/EquipmentContent/ArmorButton") as Button
	var sword := player.get_node("Sword") as Node2D

	weapon_button.emit_signal("pressed")
	await process_frame
	_assert_true(weapon_button.text.contains("Empty"), "weapon slot can move the sword back into the bag")
	_assert_true(sword.visible == false, "player sword hides when weapon slot is empty")

	bag_slot_1.emit_signal("pressed")
	await process_frame
	_assert_true(armor_button.text.contains("Spirit Armor"), "bag armor equips into the armor slot")

	var bag_slot_with_sword := _find_bag_slot_by_text(hud, "Iron Sword")
	_assert_true(bag_slot_with_sword != null, "sword appears in the bag after unequipping")
	if bag_slot_with_sword != null:
		bag_slot_with_sword.emit_signal("pressed")
		await process_frame
		_assert_true(weapon_button.text.contains("Iron Sword"), "bag sword re-equips into the weapon slot")
		_assert_true(sword.visible, "player sword reappears when weapon is equipped")

	world.free()

func _find_bag_slot_by_text(hud: Node, snippet: String) -> Button:
	for index in range(1, 7):
		var button := hud.get_node("InventoryOverlay/Window/Margin/Layout/Columns/BagPanel/BagContent/BagGrid/BagSlot%s" % [index]) as Button
		if button.text.contains(snippet):
			return button
	return null

func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	failures += 1
	push_error(message)

func _assert_false(value: bool, message: String) -> void:
	_assert_true(not value, message)
