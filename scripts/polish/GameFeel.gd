extends Node2D

@export var persist_progress: bool = true

var shake: float = 0.0
var shake_enabled: bool = true
var kills: int = 0
var completed: bool = false
var observed: Dictionary = {}
var objective: Label
var minimap: Control
var world: Node2D
var player: Node2D
var hud: CanvasLayer
var sound: AudioStreamPlayer
var sound_cooldown: float = 0.0
var scan_timer: float = 0.0
var best: int = 0
var result_panel: PanelContainer
var stage: int = 0
var boss_spawned := false
var boss_node: Node2D
var boss_bar: ProgressBar
var upgrade_panel: PanelContainer
const GOAL := 24

func _ready() -> void:
	add_to_group("game_feel")
	world = get_parent()
	player = world.get_node("Player")
	hud = world.get_node("Hud")
	var save := ConfigFile.new()
	if save.load("user://journey.cfg") == OK:
		best = int(save.get_value("journey", "best", 0))
	z_index = 2500
	var feedback_material := CanvasItemMaterial.new()
	feedback_material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = feedback_material
	_observe_enemies()
	world.get_node("Enemies").child_entered_tree.connect(func(_node: Node): _observe_enemies.call_deferred())
	_style_hud()
	var pause_menu := PanelContainer.new()
	pause_menu.name = "JourneyPauseMenu"
	pause_menu.set_script(preload("res://scripts/polish/PauseMenu.gd"))
	hud.add_child(pause_menu)
	objective = Label.new()
	objective.position = Vector2(440, 24)
	objective.size = Vector2(400, 62)
	objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective.add_theme_font_override("font", preload("res://scripts/interface/JianghuTheme.gd").font(true))
	objective.add_theme_font_size_override("font_size", 18)
	objective.add_theme_color_override("font_color", Color("eddfb9"))
	hud.add_child(objective)
	minimap = Control.new()
	minimap.set_script(preload("res://scripts/polish/JourneyMap.gd"))
	minimap.position = Vector2(1078, 68)
	minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(minimap)
	var ground := world.get_node("Ground") as CanvasItem
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; void fragment(){ vec4 c=texture(TEXTURE,UV); float l=dot(c.rgb,vec3(0.299,0.587,0.114)); c.rgb=mix(vec3(l),c.rgb,0.85); c.rgb=pow(c.rgb,vec3(0.95))*vec3(0.91,0.97,1.0); COLOR=c; }"
	var ground_material := ShaderMaterial.new()
	ground_material.shader = shader
	ground.material = ground_material
	var camera := player.get_node("Camera2D") as Camera2D
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 9.0
	sound = AudioStreamPlayer.new()
	sound.volume_db = -18.0
	add_child(sound)
	for group_name in ["Trees", "Buildings", "Breakables"]:
		var props := world.get_node_or_null(group_name) as CanvasItem
		if props != null:
			props.modulate = Color(0.86, 0.92, 0.93)
	for building in world.get_node("Buildings").get_children():
		var lantern := Node2D.new()
		lantern.set_script(preload("res://scripts/polish/VillageLantern.gd"))
		lantern.position = building.position + Vector2(-38, 22)
		world.call_deferred("add_child", lantern)
	player.health_component.damaged.connect(func(_amount: int): impact(5.0))
	player.health_component.died.connect(_on_player_defeated)

func _style_hud() -> void:
	preload("res://scripts/interface/BattleLayout.gd").install(hud)

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.075, 0.09, 0.92)
	style.set_border_width_all(1)
	style.border_color = Color("8f9071")
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

func _process(delta: float) -> void:
	sound_cooldown = maxf(0.0, sound_cooldown - delta)
	shake = move_toward(shake, 0.0, delta * 22.0)
	var camera := player.get_node("Camera2D") as Camera2D
	camera.offset = Vector2(sin(Time.get_ticks_msec() * 0.081), cos(Time.get_ticks_msec() * 0.063)) * (shake if shake_enabled else 0.0)
	scan_timer -= delta
	if scan_timer <= 0.0:
		scan_timer = 0.25
		_observe_enemies()
	objective.text = "%s\n%s    %02d / %02d" % [["一 · 灯火未凉", "二 · 夜风骤起", "三 · 破阵迎敌"][stage], "长夜已尽" if completed else "平息妖患", kills, GOAL]
	if boss_spawned and not completed:
		objective.text = "终 幕 · 山 君 现 世\n看清蓄势，闪过冲锋，趁隙反击"
		if is_instance_valid(boss_node) and boss_bar != null:
			boss_bar.value = boss_node.health.current_health
	if player.is_defeated:
		objective.text = "此 战 暂 歇\n已退敌 %d 名 · 按 R 重来" % kills
	for index in range(5):
		var slot := hud.skill_bar.get_node("Slot%d" % [index + 1]) as PanelContainer
		var label := slot.get_node("SlotContent/Label") as Label
		var remaining: float = player.skill_caster.cooldowns[index]
		label.text = "%d  %s\n%s" % [index + 1, preload("res://scripts/interface/BattleLayout.gd").NAMES[index], "%.1f 秒" % remaining if remaining > 0.0 else "就 绪"]
		label.add_theme_font_size_override("font_size", 12)
		hud.status_label.visible = player.is_exhausted
		slot.modulate = Color(0.65, 0.75, 0.8) if remaining > 0.0 else Color.WHITE
		label.modulate = Color("b4d8cb") if player.selected_skill_slot == index else Color("c9b991")
	queue_redraw()

func _observe_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("hostile_enemies"):
		var id: int = enemy.get_instance_id()
		if completed:
			enemy.set_physics_process(false)
			enemy.set_process(false)
		if observed.has(id):
			continue
		observed[id] = true
		var health := enemy.get_node_or_null("HealthComponent") as HealthComponent
		if health != null:
			health.damaged.connect(_damage_number.bind(weakref(enemy)))
			health.died.connect(_enemy_defeated.bind(weakref(enemy)))

func _enemy_defeated(reference: WeakRef = null) -> void:
	if completed or player.is_defeated:
		return
	var enemy: Node = reference.get_ref() if reference != null else null
	if enemy != null and enemy.is_in_group("boss"):
		completed = true
		world.set_process(false)
		for other in get_tree().get_nodes_in_group("hostile_enemies"):
			other.set_physics_process(false)
		_show_result()
		return
	kills += 1
	if kills == 6 or kills == 14:
		stage += 1
		player.health_component.heal(2)
		player._set_stamina(player.max_stamina)
		_show_upgrade.call_deferred()
	if kills >= GOAL and not boss_spawned:
		boss_spawned = true
		_begin_boss.call_deferred()
	var save := ConfigFile.new()
	save.set_value("journey", "best", maxi(best, kills))
	if persist_progress:
		save.save("user://journey.cfg")

func _show_upgrade() -> void:
	upgrade_panel = PanelContainer.new()
	upgrade_panel.name = "UpgradeChoice"
	upgrade_panel.set_script(preload("res://scripts/interface/UpgradeChoice.gd"))
	upgrade_panel.stage = stage
	upgrade_panel.chosen.connect(_apply_upgrade)
	hud.add_child(upgrade_panel)

func _apply_upgrade(index: int) -> void:
	if index == 0:
		player.melee_damage += 1
	else:
		player.health_component.max_health += 2
		player.health_component.heal(player.health_component.max_health)
	world.initial_spawn_interval = 4.0 if stage == 1 else 3.0
	world.active_enemy_cap = 10 if stage == 1 else 12
	world.report_combat_message("第二幕 · 夜风骤起" if stage == 1 else "第三幕 · 破阵迎敌")

func _begin_boss() -> void:
	world.set_process(false)
	for enemy in get_tree().get_nodes_in_group("hostile_enemies"):
		enemy.queue_free()
	boss_node = preload("res://scenes/boss/MountainGuardian.tscn").instantiate()
	var desired: Vector2 = player.global_position + Vector2(125,-65)
	var cell: Vector2i = world._find_nearest_walkable_id(world._world_to_path_id(desired))
	boss_node.position = world.to_local(world._path_id_to_world(cell))
	world.get_node("Enemies").add_child(boss_node)
	_observe_enemies()
	boss_bar = ProgressBar.new()
	boss_bar.position = Vector2(440,100)
	boss_bar.size = Vector2(400,16)
	boss_bar.max_value = boss_node.health.max_health
	boss_bar.show_percentage = false
	var style := preload("res://scripts/interface/JianghuTheme.gd")
	boss_bar.add_theme_stylebox_override("background", style.panel(Color("1b2c31"),style.GOLD,0))
	boss_bar.add_theme_stylebox_override("fill", style.panel(Color("b38661"),style.GOLD,0))
	hud.add_child(boss_bar)
	world.report_combat_message("山 君 现 世")

func _damage_number(amount: int, reference: WeakRef) -> void:
	var enemy = reference.get_ref()
	if enemy == null:
		return
	var label := Label.new()
	label.text = str(amount)
	label.position = world.to_local(enemy.global_position) + Vector2(-5, -34)
	label.z_index = 3000
	label.material = material
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color("fff1c2"))
	world.add_child(label)
	var tween := label.create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 22.0, 0.65)
	tween.tween_property(label, "modulate:a", 0.0, 0.45).set_delay(0.2)
	tween.chain().tween_callback(label.queue_free)

func impact(strength: float) -> void:
	shake = maxf(shake, strength)
	if sound_cooldown > 0.0 or sound == null:
		return
	sound_cooldown = 0.08
	var bytes := PackedByteArray()
	var count := 3200
	bytes.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 73
	for i in range(count):
		var t := float(i) / 22050.0
		var envelope := pow(1.0 - float(i) / count, 3.0)
		var sample := (sin(TAU * (150.0 * t - 250.0 * t * t)) * 0.7 + rng.randf_range(-0.3, 0.3)) * envelope
		bytes.encode_s16(i * 2, int(sample * 24000))
	var audio := AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.mix_rate = 22050
	audio.data = bytes
	sound.stream = audio
	sound.play()

func _draw() -> void:
	# Enemy-local windup arcs make simultaneous threats readable.
	for enemy in get_tree().get_nodes_in_group("hostile_enemies"):
		if not enemy.is_winding_up:
			continue
		var center := to_local(enemy.global_position)
		var ratio := 1.0 - clampf(enemy.windup_timer / maxf(enemy.attack_windup, 0.01), 0.0, 1.0)
		draw_arc(center, 23, -PI * 0.5, -PI * 0.5 + TAU * ratio, 24, Color(1.0, 0.38, 0.25, 0.9), 2.0)

func _show_result(victory: bool = true) -> void:
	if is_instance_valid(result_panel):
		return
	result_panel = PanelContainer.new()
	result_panel.name = "JourneyResult"
	result_panel.set_script(preload("res://scripts/interface/ResultScreen.gd"))
	result_panel.victory = victory
	result_panel.kills = kills
	result_panel.seconds = world.elapsed_time
	result_panel.best = best
	hud.add_child(result_panel)
	if victory:
		player.set_physics_process(false)
	hud.defeated_label.visible = false
	if boss_bar != null: boss_bar.visible = false

func _on_player_defeated() -> void:
	_show_result(false)
