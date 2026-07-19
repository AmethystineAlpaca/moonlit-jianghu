extends CanvasLayer

@onready var hp_bar: ProgressBar = $StatsPanel/Stats/HPBar
@onready var hp_value_label: Label = $StatsPanel/Stats/HPBar/ValueLabel
@onready var stamina_bar: ProgressBar = $StatsPanel/Stats/StaminaBar
@onready var stamina_value_label: Label = $StatsPanel/Stats/StaminaBar/ValueLabel
@onready var status_label: Label = $StatsPanel/Stats/StatusLabel
@onready var blocked_label: Label = $BlockedLabel
@onready var combat_message_label: Label = $CombatMessageLabel
@onready var defeated_label: Label = $DefeatedLabel
@onready var paused_label: Label = $PausedLabel
@onready var skill_bar: HBoxContainer = $SkillBar
@onready var danger_overlay: ColorRect = $DangerOverlay
@onready var controls_hint: Label = $ControlsHint
@onready var inventory_overlay: Control = $InventoryOverlay
@onready var inventory_status_label: Label = $InventoryOverlay/Window/Margin/Layout/Header/InventoryStatus
@onready var weapon_button: Button = $InventoryOverlay/Window/Margin/Layout/Columns/EquipmentPanel/EquipmentContent/WeaponButton
@onready var armor_button: Button = $InventoryOverlay/Window/Margin/Layout/Columns/EquipmentPanel/EquipmentContent/ArmorButton
@onready var bag_buttons: Array[Button] = [
	$InventoryOverlay/Window/Margin/Layout/Columns/BagPanel/BagContent/BagGrid/BagSlot1,
	$InventoryOverlay/Window/Margin/Layout/Columns/BagPanel/BagContent/BagGrid/BagSlot2,
	$InventoryOverlay/Window/Margin/Layout/Columns/BagPanel/BagContent/BagGrid/BagSlot3,
	$InventoryOverlay/Window/Margin/Layout/Columns/BagPanel/BagContent/BagGrid/BagSlot4,
	$InventoryOverlay/Window/Margin/Layout/Columns/BagPanel/BagContent/BagGrid/BagSlot5,
	$InventoryOverlay/Window/Margin/Layout/Columns/BagPanel/BagContent/BagGrid/BagSlot6,
]

const TRANSFORM_ICON_TEXTURE := preload("res://assets/xianxia/icon_dash.png")
const DIVINE_LIGHT_ICON_TEXTURE := preload("res://assets/xianxia/icon_shield.png")
const EMPTY_SLOT_ICON_TEXTURE := preload("res://assets/xianxia/icon_sword.png")
const ARMOR_ICON_TEXTURE := preload("res://assets/xianxia/icon_shield.png")
const WEAPON_ICON_TEXTURE := preload("res://assets/xianxia/icon_sword.png")
const TALISMAN_ICON_TEXTURE := preload("res://assets/xianxia/icon_dash.png")

var player_health: HealthComponent
var player_controller: Node
var blocked_timer: float = 0.0
var combat_message_timer: float = 0.0
var danger_pulse_timer: float = 0.0
var danger_current_health: int = 0
var danger_max_health: int = 0
var skill_slot_names: Array[String] = ["Empty", "Empty", "Empty", "Empty", "Empty"]
var active_skill_slots: Array[bool] = []
var resurrection_icon_texture: Texture2D
var divine_light_icon_texture: Texture2D
var empty_icon_texture: Texture2D
var controls_hint_timer: float = 0.0
var controls_hint_visible_seconds: float = 30.0
var controls_hint_fade_seconds: float = 1.5
var inventory_open: bool = false
var inventory_previously_paused: bool = false
var equipped_items := {
	"weapon": "iron_sword",
	"armor": "",
}
var bag_items: Array[String] = [
	"spirit_armor",
	"jade_talisman",
	"healing_pill",
	"",
	"",
	"",
]
var item_definitions := {}

func _process(delta: float) -> void:
	if blocked_timer > 0.0:
		blocked_timer -= delta
		if blocked_timer <= 0.0:
			blocked_label.visible = false
	if combat_message_timer > 0.0:
		combat_message_timer -= delta
		if combat_message_timer <= 0.0:
			combat_message_label.visible = false
	if danger_pulse_timer > 0.0:
		danger_pulse_timer -= delta
		_refresh_danger_overlay()
	_update_controls_hint_fade(delta)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_skill_icon_textures()
	_build_item_definitions()
	_connect_inventory_buttons()
	_update_skill_bar()
	_update_pause_label()
	_refresh_inventory_ui()
	if controls_hint != null:
		controls_hint.modulate.a = 1.0

	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		_set_hp_text(0, 0)
		_set_stamina_text(0.0, 0.0)
		return

	player_controller = player
	if player_controller.has_signal("stamina_changed"):
		player_controller.stamina_changed.connect(_on_player_stamina_changed)
		_set_stamina_text(player_controller.current_stamina, player_controller.max_stamina)
	if player_controller.has_signal("exhaustion_changed"):
		player_controller.exhaustion_changed.connect(_on_player_exhaustion_changed)
	if player_controller.has_signal("blocked"):
		player_controller.blocked.connect(_on_player_blocked)
	if player_controller.has_signal("combat_message_requested"):
		player_controller.combat_message_requested.connect(_on_combat_message_requested)
	if player_controller.has_signal("skill_slots_changed"):
		player_controller.skill_slots_changed.connect(_on_skill_slots_changed)
		_on_skill_slots_changed(player_controller.get_skill_slot_names())
	if player_controller.has_signal("active_skill_slots_changed"):
		player_controller.active_skill_slots_changed.connect(_on_active_skill_slots_changed)
		_on_active_skill_slots_changed(player_controller.active_skill_slots)

	var world := get_tree().get_first_node_in_group("world")
	if world != null and world.has_signal("combat_message_requested"):
		world.combat_message_requested.connect(_on_combat_message_requested)

	player_health = player.get_node_or_null("HealthComponent") as HealthComponent
	if player_health == null:
		_set_hp_text(0, 0)
		_sync_player_equipment_visuals()
		return

	player_health.health_changed.connect(_on_player_health_changed)
	player_health.damaged.connect(_on_player_damaged)
	player_health.died.connect(_on_player_died)
	_set_hp_text(player_health.current_health, player_health.max_health)
	_set_danger_health(player_health.current_health, player_health.max_health)
	_sync_player_equipment_visuals()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		_toggle_inventory()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("pause_game"):
		if inventory_open:
			_close_inventory()
			get_viewport().set_input_as_handled()
			return
		get_tree().paused = not get_tree().paused
		_update_pause_label()
		get_viewport().set_input_as_handled()

func _on_player_health_changed(current_health: int, max_health: int) -> void:
	_set_hp_text(current_health, max_health)
	_set_danger_health(current_health, max_health)

func _set_hp_text(current_health: int, max_health: int) -> void:
	hp_bar.max_value = max_health
	hp_bar.value = current_health
	hp_value_label.text = "HP %s / %s" % [current_health, max_health]

func _on_player_damaged(_amount: int) -> void:
	danger_pulse_timer = 0.24
	_refresh_danger_overlay()

func _set_danger_health(current_health: int, max_health: int) -> void:
	danger_current_health = current_health
	danger_max_health = max_health
	_refresh_danger_overlay()

func _refresh_danger_overlay() -> void:
	if danger_overlay == null:
		return
	var is_in_danger := danger_current_health > 0 and danger_current_health <= 2
	danger_overlay.visible = is_in_danger
	if not is_in_danger:
		danger_overlay.color = Color(1.0, 0.0, 0.0, 0.0)
		return

	var missing_ratio := 1.0 - float(danger_current_health) / float(maxi(danger_max_health, 1))
	var base_alpha := lerpf(0.12, 0.26, missing_ratio)
	var pulse_alpha := 0.0
	if danger_pulse_timer > 0.0:
		pulse_alpha = 0.12 * clampf(danger_pulse_timer / 0.24, 0.0, 1.0)
	danger_overlay.color = Color(0.82, 0.02, 0.0, base_alpha + pulse_alpha)

func _on_player_died() -> void:
	defeated_label.visible = true

func _on_player_stamina_changed(current_stamina: float, max_stamina: float) -> void:
	_set_stamina_text(current_stamina, max_stamina)

func _set_stamina_text(current_stamina: float, max_stamina: float) -> void:
	stamina_bar.max_value = max_stamina
	stamina_bar.value = current_stamina
	stamina_value_label.text = "STA %s / %s" % [roundi(current_stamina), roundi(max_stamina)]

func _on_player_blocked() -> void:
	blocked_label.visible = true
	blocked_timer = 0.45

func _on_player_exhaustion_changed(is_exhausted: bool) -> void:
	if is_exhausted:
		status_label.text = "Exhausted: recover fully"
	else:
		status_label.text = ""

func _on_combat_message_requested(message: String) -> void:
	combat_message_label.text = message
	combat_message_label.visible = true
	combat_message_timer = 0.65

func _on_skill_slots_changed(slot_names: Array[String]) -> void:
	skill_slot_names = slot_names.duplicate()
	while skill_slot_names.size() < 5:
		skill_slot_names.append("Empty")
	if skill_slot_names.size() > 5:
		skill_slot_names.resize(5)
	_update_skill_bar()

func _on_active_skill_slots_changed(active_states: Array) -> void:
	active_skill_slots.clear()
	for state in active_states:
		active_skill_slots.append(bool(state))
	_update_skill_bar()

func _update_skill_bar() -> void:
	if skill_bar == null:
		return
	for index in range(5):
		var slot := skill_bar.get_node("Slot%s" % [index + 1]) as PanelContainer
		var icon := slot.get_node("SlotContent/Icon") as TextureRect
		var label := slot.get_node("SlotContent/Label") as Label
		var skill_name := skill_slot_names[index]
		icon.texture = _get_skill_icon(skill_name)
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.modulate = Color.WHITE if skill_name != "Empty" else Color(0.62, 0.56, 0.48, 0.76)
		label.text = "%s  %s" % [index + 1, skill_name]
		var is_active := index < active_skill_slots.size() and active_skill_slots[index]
		if is_active:
			slot.add_theme_stylebox_override("panel", _make_selected_slot_style())
			label.modulate = Color(1.0, 0.86, 0.36, 1.0)
		else:
			slot.remove_theme_stylebox_override("panel")
			label.modulate = Color(0.88, 0.78, 0.62, 1.0) if skill_name != "Empty" else Color(0.54, 0.50, 0.44, 1.0)

func _update_pause_label() -> void:
	if paused_label != null:
		paused_label.visible = get_tree().paused and not inventory_open

func _update_controls_hint_fade(delta: float) -> void:
	if controls_hint == null:
		return
	controls_hint_timer += delta
	if controls_hint_timer <= controls_hint_visible_seconds:
		controls_hint.modulate.a = 1.0
		return

	var fade_t := clampf((controls_hint_timer - controls_hint_visible_seconds) / controls_hint_fade_seconds, 0.0, 1.0)
	controls_hint.modulate.a = 1.0 - fade_t
	controls_hint.visible = controls_hint.modulate.a > 0.0

func _build_skill_icon_textures() -> void:
	resurrection_icon_texture = TRANSFORM_ICON_TEXTURE
	divine_light_icon_texture = DIVINE_LIGHT_ICON_TEXTURE
	empty_icon_texture = EMPTY_SLOT_ICON_TEXTURE

func _build_item_definitions() -> void:
	item_definitions = {
		"iron_sword": {
			"name": "Iron Sword",
			"slot": "weapon",
			"icon": WEAPON_ICON_TEXTURE,
		},
		"spirit_armor": {
			"name": "Spirit Armor",
			"slot": "armor",
			"icon": ARMOR_ICON_TEXTURE,
		},
		"jade_talisman": {
			"name": "Jade Talisman",
			"slot": "",
			"icon": TALISMAN_ICON_TEXTURE,
		},
		"healing_pill": {
			"name": "Healing Pill",
			"slot": "",
			"icon": TALISMAN_ICON_TEXTURE,
		},
	}

func _connect_inventory_buttons() -> void:
	if weapon_button != null and not weapon_button.pressed.is_connected(_on_weapon_button_pressed):
		weapon_button.pressed.connect(_on_weapon_button_pressed)
	if armor_button != null and not armor_button.pressed.is_connected(_on_armor_button_pressed):
		armor_button.pressed.connect(_on_armor_button_pressed)
	for index in range(bag_buttons.size()):
		var button := bag_buttons[index]
		var callable := Callable(self, "_on_bag_button_pressed").bind(index)
		if button != null and not button.pressed.is_connected(callable):
			button.pressed.connect(callable)

func _on_weapon_button_pressed() -> void:
	_move_equipment_to_bag("weapon")

func _on_armor_button_pressed() -> void:
	_move_equipment_to_bag("armor")

func _on_bag_button_pressed(index: int) -> void:
	if index < 0 or index >= bag_items.size():
		return
	var item_id := bag_items[index]
	if item_id == "":
		_show_inventory_status("Empty bag slot.")
		return

	var slot_name := _get_item_slot(item_id)
	if slot_name == "":
		_show_inventory_status("%s stays in the bag." % [_get_item_name(item_id)])
		return

	var previous_item := String(equipped_items.get(slot_name, ""))
	equipped_items[slot_name] = item_id
	bag_items[index] = previous_item
	_refresh_inventory_ui()
	_sync_player_equipment_visuals()
	if previous_item == "":
		_show_inventory_status("%s equipped." % [_get_item_name(item_id)])
	else:
		_show_inventory_status("%s swapped with %s." % [_get_item_name(item_id), _get_item_name(previous_item)])

func _move_equipment_to_bag(slot_name: String) -> void:
	var item_id := String(equipped_items.get(slot_name, ""))
	if item_id == "":
		_show_inventory_status("%s slot is empty." % [slot_name.capitalize()])
		return

	var empty_index := _find_first_empty_bag_slot()
	if empty_index == -1:
		_show_inventory_status("Bag is full.")
		return

	equipped_items[slot_name] = ""
	bag_items[empty_index] = item_id
	_refresh_inventory_ui()
	_sync_player_equipment_visuals()
	_show_inventory_status("%s moved to the bag." % [_get_item_name(item_id)])

func _refresh_inventory_ui() -> void:
	if inventory_overlay != null:
		inventory_overlay.visible = inventory_open
	_update_equipment_button(weapon_button, "weapon", "Weapon")
	_update_equipment_button(armor_button, "armor", "Armor")
	for index in range(bag_buttons.size()):
		_update_bag_button(bag_buttons[index], index)

func _update_equipment_button(button: Button, slot_name: String, slot_label: String) -> void:
	if button == null:
		return
	var item_id := String(equipped_items.get(slot_name, ""))
	button.icon = _get_item_icon(item_id)
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.text = "%s\n%s" % [slot_label, _get_item_name(item_id)]

func _update_bag_button(button: Button, index: int) -> void:
	if button == null or index < 0 or index >= bag_items.size():
		return
	var item_id := bag_items[index]
	button.icon = _get_item_icon(item_id)
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.text = _get_item_name(item_id)

func _toggle_inventory() -> void:
	if inventory_open:
		_close_inventory()
	else:
		_open_inventory()

func _open_inventory() -> void:
	inventory_previously_paused = get_tree().paused
	inventory_open = true
	get_tree().paused = true
	_refresh_inventory_ui()
	_update_pause_label()
	_show_inventory_status("Click equipment or bag slots to move items.")

func _close_inventory() -> void:
	inventory_open = false
	get_tree().paused = inventory_previously_paused
	inventory_previously_paused = false
	_refresh_inventory_ui()
	_update_pause_label()

func _show_inventory_status(message: String) -> void:
	if inventory_status_label != null:
		inventory_status_label.text = message

func _find_first_empty_bag_slot() -> int:
	for index in range(bag_items.size()):
		if bag_items[index] == "":
			return index
	return -1

func _get_item_name(item_id: String) -> String:
	if item_id == "":
		return "Empty"
	if item_definitions.has(item_id):
		return String(item_definitions[item_id].get("name", item_id))
	return item_id.capitalize()

func _get_item_slot(item_id: String) -> String:
	if item_id == "" or not item_definitions.has(item_id):
		return ""
	return String(item_definitions[item_id].get("slot", ""))

func _get_item_icon(item_id: String) -> Texture2D:
	if item_id == "":
		return null
	if item_definitions.has(item_id):
		return item_definitions[item_id].get("icon") as Texture2D
	return null

func _sync_player_equipment_visuals() -> void:
	if player_controller == null:
		return
	if player_controller.has_method("set_equipped_weapon"):
		player_controller.set_equipped_weapon(String(equipped_items.get("weapon", "")))

func _get_skill_icon(skill_name: String) -> Texture2D:
	if skill_name == "Transform":
		return resurrection_icon_texture
	if skill_name == "Resurrection":
		return resurrection_icon_texture
	if skill_name == "Divine Light":
		return divine_light_icon_texture
	return empty_icon_texture

func _make_resurrection_icon() -> Texture2D:
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.05, 0.03, 0.02, 0.0))
	var seal := Color(0.78, 0.10, 0.10, 1.0)
	var palm_green := Color(0.30, 0.72, 0.34, 1.0)
	var leaf_tip := Color(0.68, 1.0, 0.62, 1.0)
	var wrist_shadow := Color(0.18, 0.46, 0.22, 1.0)
	var dark_soil := Color(0.28, 0.17, 0.08, 1.0)
	var mid_soil := Color(0.50, 0.32, 0.18, 1.0)

	_fill_rect(image, Rect2i(0, 0, 4, 3), seal)
	_fill_rect(image, Rect2i(28, 0, 4, 3), seal)
	_fill_rect(image, Rect2i(14, 5, 1, 1), seal)
	_fill_rect(image, Rect2i(17, 5, 1, 1), seal)

	_fill_rect(image, Rect2i(1, 31, 30, 1), dark_soil)
	_fill_rect(image, Rect2i(2, 30, 28, 1), dark_soil)
	_fill_rect(image, Rect2i(3, 29, 26, 1), dark_soil)
	_fill_rect(image, Rect2i(4, 28, 24, 1), dark_soil)
	_fill_rect(image, Rect2i(6, 27, 20, 1), dark_soil)
	_fill_rect(image, Rect2i(9, 26, 14, 1), dark_soil)
	_fill_rect(image, Rect2i(11, 25, 10, 1), dark_soil)
	_fill_rect(image, Rect2i(4, 29, 2, 1), mid_soil)
	_fill_rect(image, Rect2i(8, 30, 2, 1), mid_soil)
	_fill_rect(image, Rect2i(15, 31, 2, 1), mid_soil)
	_fill_rect(image, Rect2i(22, 30, 2, 1), mid_soil)
	_fill_rect(image, Rect2i(25, 29, 2, 1), mid_soil)
	_fill_rect(image, Rect2i(13, 27, 2, 1), mid_soil)
	_fill_rect(image, Rect2i(19, 27, 2, 1), mid_soil)

	_fill_rect(image, Rect2i(13, 23, 6, 2), wrist_shadow)
	_fill_rect(image, Rect2i(11, 18, 10, 5), palm_green)
	_fill_rect(image, Rect2i(11, 9, 2, 9), palm_green)
	_fill_rect(image, Rect2i(15, 8, 2, 10), palm_green)
	_fill_rect(image, Rect2i(19, 9, 2, 9), palm_green)
	_fill_rect(image, Rect2i(11, 9, 2, 1), leaf_tip)
	_fill_rect(image, Rect2i(15, 8, 2, 1), leaf_tip)
	_fill_rect(image, Rect2i(19, 9, 2, 1), leaf_tip)
	return ImageTexture.create_from_image(image)

func _make_divine_light_icon() -> Texture2D:
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.05, 0.04, 0.02, 0.0))
	var halo := Color(1.0, 0.86, 0.36, 0.55)
	var glow := Color(1.0, 0.94, 0.58, 0.85)
	var core := Color(1.0, 1.0, 0.92, 1.0)
	var ray := Color(1.0, 0.88, 0.42, 0.85)

	_fill_rect(image, Rect2i(15, 2, 2, 4), ray)
	_fill_rect(image, Rect2i(15, 26, 2, 4), ray)
	_fill_rect(image, Rect2i(2, 15, 4, 2), ray)
	_fill_rect(image, Rect2i(26, 15, 4, 2), ray)
	_fill_rect(image, Rect2i(5, 5, 3, 3), ray)
	_fill_rect(image, Rect2i(24, 5, 3, 3), ray)
	_fill_rect(image, Rect2i(5, 24, 3, 3), ray)
	_fill_rect(image, Rect2i(24, 24, 3, 3), ray)

	_fill_rect(image, Rect2i(10, 10, 12, 12), halo)
	_fill_rect(image, Rect2i(9, 12, 1, 8), halo)
	_fill_rect(image, Rect2i(22, 12, 1, 8), halo)
	_fill_rect(image, Rect2i(12, 9, 8, 1), halo)
	_fill_rect(image, Rect2i(12, 22, 8, 1), halo)

	_fill_rect(image, Rect2i(12, 12, 8, 8), glow)
	_fill_rect(image, Rect2i(11, 14, 1, 4), glow)
	_fill_rect(image, Rect2i(20, 14, 1, 4), glow)
	_fill_rect(image, Rect2i(14, 11, 4, 1), glow)
	_fill_rect(image, Rect2i(14, 20, 4, 1), glow)

	_fill_rect(image, Rect2i(14, 14, 4, 4), core)
	_fill_rect(image, Rect2i(13, 15, 1, 2), core)
	_fill_rect(image, Rect2i(18, 15, 1, 2), core)
	_fill_rect(image, Rect2i(15, 13, 2, 1), core)
	_fill_rect(image, Rect2i(15, 18, 2, 1), core)
	return ImageTexture.create_from_image(image)

func _make_empty_icon() -> Texture2D:
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.04, 0.035, 0.03, 0.0))
	var border := Color(0.42, 0.34, 0.24, 0.84)
	var mark := Color(0.24, 0.21, 0.18, 0.72)
	_fill_rect(image, Rect2i(8, 8, 16, 3), border)
	_fill_rect(image, Rect2i(8, 21, 16, 3), border)
	_fill_rect(image, Rect2i(8, 8, 3, 16), border)
	_fill_rect(image, Rect2i(21, 8, 3, 16), border)
	_fill_rect(image, Rect2i(13, 14, 6, 4), mark)
	_fill_rect(image, Rect2i(14, 13, 4, 6), mark)
	return ImageTexture.create_from_image(image)

func _fill_rect(image: Image, rect: Rect2i, fill: Color) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
				image.set_pixel(x, y, fill)

func _make_selected_slot_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.26, 0.17, 0.08, 0.95)
	style.border_color = Color(0.98, 0.74, 0.24, 1.0)
	style.set_border_width_all(4)
	style.set_corner_radius_all(2)
	style.content_margin_left = 8.0
	style.content_margin_top = 6.0
	style.content_margin_right = 8.0
	style.content_margin_bottom = 6.0
	return style
