extends CanvasLayer
const FONT := preload("res://assets/fonts/NotoSansSC.ttf")
const SERIF := preload("res://assets/fonts/NotoSerifSC.ttf")
const WHITE := Color("e4e5d7")
const MUTED := Color("a0b9b9")
const GOLD := Color("d7bb85")
var world: Node3D
var feedback: Control
var root: Control
var modal: Control
var hud: Control
var health: ProgressBar
var stamina: ProgressBar
var objective: Label
var status: Label
var prompt: Label
var toast: Label
var subtitle: Label
var toast_timer := 0.0
var weapon: Label
var skills: Label
var boss_health: ProgressBar
var boss_name: Label
var seal_markers: Array[Label] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var theme := Theme.new()
	theme.default_font = FONT
	theme.default_font_size = 16
	theme.set_color("font_color","Label",WHITE)
	theme.set_color("font_color","Button",WHITE)
	for state in ["normal","hover","pressed","focus"]:
		var panel := StyleBoxFlat.new()
		panel.bg_color = Color(0.05,0.12,0.15,0.9 if state == "hover" else 0.65)
		panel.border_color = GOLD if state == "hover" or state == "focus" else Color(0.6,0.7,0.65,0.2)
		panel.border_width_bottom = 1
		panel.content_margin_left = 22
		panel.content_margin_right = 22
		panel.content_margin_top = 14
		panel.content_margin_bottom = 14
		theme.set_stylebox(state,"Button",panel)
	root.theme = theme
	build_hud()

func label(parent: Control, text: String, pos: Vector2, size: int, color := WHITE, serif := false) -> Label:
	var node := Label.new()
	node.text = text
	node.position = pos
	node.add_theme_font_override("font",SERIF if serif else FONT)
	node.add_theme_font_size_override("font_size",size)
	node.add_theme_color_override("font_color",color)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

func button(parent: Control, text: String, pos: Vector2, size: Vector2, callback: Callable) -> Button:
	var node := Button.new()
	node.text = text
	node.position = pos
	node.size = size
	node.pressed.connect(callback)
	parent.add_child(node)
	if parent.get_children().filter(func(child: Node): return child is Button).size() == 1: _focus_button.call_deferred(node)
	return node

func line(parent: Control, pos: Vector2, size: Vector2, color: Color) -> void:
	var node := ColorRect.new()
	node.color = color
	node.position = pos
	node.size = size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)

func bar(parent: Control, pos: Vector2, size: Vector2, color: Color) -> ProgressBar:
	var node := ProgressBar.new()
	node.position = pos
	node.size = size
	node.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.03,0.08,0.1,0.7)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	node.add_theme_stylebox_override("background",bg)
	node.add_theme_stylebox_override("fill",fill)
	parent.add_child(node)
	node.set_deferred("size",size)
	return node

func build_hud() -> void:
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)
	var edge_shade := ColorRect.new()
	edge_shade.size = Vector2(1280,720)
	edge_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gradient := Shader.new()
	gradient.code = "shader_type canvas_item; void fragment(){ float top=(1.0-smoothstep(0.0,0.22,UV.y))*0.58; float bottom=smoothstep(0.78,1.0,UV.y)*0.68; COLOR=vec4(0.015,0.035,0.045,max(top,bottom)); }"
	var background := ShaderMaterial.new()
	background.shader = gradient
	edge_shade.material = background
	hud.add_child(edge_shade)
	var readout := Control.new()
	readout.set_script(preload("res://scripts/rebirth/CombatReadout.gd"))
	readout.world = world
	hud.add_child(readout)
	feedback = preload("res://scripts/rebirth/CombatFeedback.gd").new()
	feedback.world = world
	hud.add_child(feedback)
	# Quiet perimeter information leaves the center to the duel.
	label(hud,"游 侠",Vector2(48,38),18,WHITE,true)
	health = bar(hud,Vector2(48,76),Vector2(244,5),Color("d0bba0"))
	stamina = bar(hud,Vector2(48,89),Vector2(244,3),Color("80bcb4"))
	status = label(hud,"",Vector2(48,103),12,MUTED)
	objective = label(hud,"",Vector2(915,40),15,WHITE)
	objective.size = Vector2(320,56)
	objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	weapon = label(hud,"",Vector2(48,615),19,WHITE,true)
	label(hud,"1 / 2 / 3   换刃",Vector2(48,653),12,MUTED)
	skills = label(hud,"",Vector2(885,618),14,WHITE)
	skills.size = Vector2(347,65)
	skills.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	prompt = label(hud,"",Vector2(400,582),15,GOLD)
	prompt.size = Vector2(480,38)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label(hud,"WASD 移动    左键 / J 出剑    右键 格挡    Shift / 空格 闪避    Esc 菜单",Vector2(335,689),11,MUTED)
	boss_name = label(hud,"无 相",Vector2(450,41),22,WHITE,true)
	boss_name.size.x = 380
	boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_health = bar(hud,Vector2(450,80),Vector2(380,4),GOLD)
	for i in range(3):
		var marker := label(hud,"",Vector2.ZERO,13,GOLD)
		marker.size = Vector2(130,28)
		marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		marker.add_theme_color_override("font_shadow_color",Color(0.02,0.04,0.05,0.7))
		marker.add_theme_constant_override("shadow_offset_y",1)
		seal_markers.append(marker)
	toast = label(root,"",Vector2(340,155),34,WHITE,true)
	toast.add_theme_color_override("font_shadow_color",Color(0.015,0.04,0.05,0.4))
	toast.add_theme_constant_override("shadow_offset_y",1)
	toast.size = Vector2(600,64)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle = label(root,"",Vector2(340,220),14,MUTED)
	subtitle.add_theme_color_override("font_shadow_color",Color(0.01,0.03,0.04,0.4))
	subtitle.add_theme_constant_override("shadow_offset_y",1)
	subtitle.size.x = 600
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func new_modal() -> Control:
	clear_modal()
	modal = Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(modal)
	return modal

func clear_modal() -> void:
	if is_instance_valid(modal):
		root.remove_child(modal)
		modal.queue_free()
	modal = null

func shade(parent: Control, alpha := 0.7) -> void:
	line(parent,Vector2.ZERO,Vector2(1280,720),Color(0.025,0.065,0.08,alpha))

func show_title() -> void:
	new_modal()
	# A gradient, not an opaque picture: the title opens on the actual 3D courtyard.
	var wash := ColorRect.new()
	wash.size = Vector2(1280,720)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; void fragment(){ COLOR=vec4(0.025,0.06,0.075,mix(0.91,0.02,smoothstep(0.0,0.8,UV.x))); }"
	var mat := ShaderMaterial.new()
	mat.shader = shader
	wash.material = mat
	modal.add_child(wash)
	label(modal,"M O O N L I T   J I A N G H U",Vector2(78,116),13,MUTED)
	label(modal,"雨 歇",Vector2(70,165),82,WHITE,true)
	label(modal,"S T I L L W A T E R",Vector2(80,277),16,GOLD)
	line(modal,Vector2(80,326),Vector2(38,1),GOLD)
	label(modal,"三盏灯，一座山门。\n雨声停下之前，问剑于此。",Vector2(80,353),18,MUTED,true)
	button(modal,"入 山     /     开始旅程",Vector2(80,458),Vector2(300,58),world.start_run)
	button(modal,"游 玩 指 南",Vector2(80,527),Vector2(300,48),show_guide)
	label(modal,"留影回锋 · 借势撞破 · 见切追斩",Vector2(80,653),12,MUTED)
	label(modal,"青岚山 · 雨后",Vector2(1095,653),13,WHITE,true)

func show_guide() -> void:
	new_modal()
	shade(modal,0.88)
	label(modal,"入 山 须 知",Vector2(180,110),40,WHITE,true)
	label(modal,"走近三座石灯，按 F 唤醒守灯人。清场后选择领悟，解开全部封印，迎战无相。",Vector2(180,190),17,MUTED)
	var body := "WASD / 方向键     沿镜头方向移动\n左键 / J                 连续出剑；最后一击更强\n右键 / K                正面格挡；敌人举刃蓄势，刃光亮起时可见切反击\nShift / 空格           闪避，消耗体力并取消当前动作\nQ  回锋                 沿闪避留下的雨痕回切；E  破阵：踢退并反弹飞弹\nR  温酒                 恢复气血；敌人破势后按 F 追斩\n1 / 2 / 3                直剑、重刃、灵剑；重刃打断，灵剑连击释放剑气"
	var text := label(modal,body,Vector2(180,245),17,WHITE)
	text.add_theme_constant_override("line_spacing",12)
	label(modal,"手柄：左摇杆移动 · 右摇杆朝向 · X 出剑 · A 闪避 · LB 格挡 · RB / Y 技能",Vector2(180,564),13,MUTED)
	button(modal,"返 回",Vector2(180,605),Vector2(200,50),show_title)

func show_pause() -> void:
	new_modal()
	shade(modal)
	label(modal,"且 听 风 吟",Vector2(462,155),44,WHITE,true)
	button(modal,"继续旅程",Vector2(470,260),Vector2(340,52),world.resume)
	button(modal,"震屏："+("开" if world.shake_enabled else "关"),Vector2(470,325),Vector2(340,52),func():
		world.shake_enabled = not world.shake_enabled
		world.save_settings()
		show_pause())
	button(modal,"声音："+("关" if AudioServer.is_bus_mute(0) else "开"),Vector2(470,390),Vector2(340,52),func():
		AudioServer.set_bus_mute(0,not AudioServer.is_bus_mute(0))
		world.save_settings()
		show_pause())
	button(modal,"重新启程",Vector2(470,455),Vector2(340,52),func(): get_tree().reload_current_scene())
	button(modal,"离 开 游 戏",Vector2(470,520),Vector2(340,52),func(): get_tree().root.get_node("Soundscape").shutdown())

func show_upgrade() -> void:
	new_modal()
	shade(modal,0.8)
	label(modal,"灯 火 长 明",Vector2(462,160),44,WHITE,true)
	label(modal,"选择领悟，继续深入山门。",Vector2(490,237),16,MUTED)
	button(modal,"砺 锋\n\n出剑伤害 +0.7\n适合主动进攻",Vector2(305,315),Vector2(315,180),world.upgrade.bind(0))
	button(modal,"定 心\n\n气血上限 +3，并完全恢复\n获得更多容错",Vector2(660,315),Vector2(315,180),world.upgrade.bind(1))

func show_result(victory: bool) -> void:
	new_modal()
	shade(modal,0.75)
	label(modal,"雨  歇" if victory else "剑  息",Vector2(490,165),70,WHITE,true)
	label(modal,"山门重开，灯火不灭。" if victory else "胜负有时，再问此山。",Vector2(465,282),22,MUTED,true)
	label(modal,"用时 %02d:%02d    ·    击退 %d 名守剑人" % [int(world.run_time)/60,int(world.run_time)%60,world.kills],Vector2(450,353),15,GOLD)
	button(modal,"再走一程",Vector2(470,444),Vector2(340,55),func(): get_tree().reload_current_scene())

func notify(title: String, text: String, seconds: float) -> void:
	toast.text = title
	subtitle.text = text
	toast_timer = seconds

func _process(delta: float) -> void:
	if not is_instance_valid(world.player): return
	hud.visible = world.mode == "play" or world.mode == "pause"
	toast_timer = maxf(0,toast_timer-delta)
	toast.modulate.a = minf(1,toast_timer*2) if world.mode == "play" else 0
	subtitle.modulate.a = toast.modulate.a
	health.max_value = world.player.max_hp
	health.value = world.player.hp
	stamina.value = world.player.stamina
	status.text = "%02d / %02d    ·    温酒 %d" % [ceili(world.player.hp),int(world.player.max_hp),world.heal_count]
	objective.text = "青岚山 · 封印 %d / 3\n%s" % [world.round_index,"击退守灯人" if world.encounter else "寻访石灯"]
	weapon.text = ["听雨 / 直剑","断岳 / 重刃","流萤 / 灵剑"][world.player.weapon]
	var echo_state: String = "%.1fs"%world.echo.life if is_instance_valid(world.echo) else "先闪避留影"
	var push_state: String = "就绪" if world.skill_cooldowns[1]<=0 else "%.1fs"%world.skill_cooldowns[1]
	skills.text = "Q  回锋 · %s     E  破阵 · %s\nR  温酒    ·    %d 壶" % [echo_state,push_state,world.heal_count]
	prompt.text = "F   追斩 · 破势终结" if world.executable_target() != null else ("F   点亮石灯" if not world.encounter and world.nearest_seal() >= 0 else "")
	var boss_alive: bool = is_instance_valid(world.boss_node) and not world.boss_node.dead
	boss_health.visible = boss_alive
	boss_name.visible = boss_alive
	for i in range(3):
		var marker := seal_markers[i]
		marker.visible = not world.seal_done[i] and not world.encounter and not boss_alive
		if marker.visible:
			var point: Vector2 = world.camera.unproject_position(world.seals[i].position+Vector3.UP*2.3)
			marker.position = Vector2(clampf(point.x-65,110,1040),clampf(point.y-20,135,545))
			marker.text = "◇ %s · %d步" % [["听雨","照影","归藏"][i],int(world.player.position.distance_to(world.seals[i].position))]
	if boss_alive:
		boss_health.max_value = world.boss_node.max_hp
		boss_health.value = world.boss_node.hp
		objective.text = "终章 · 问剑无相"

func _focus_button(node: Button) -> void:
	if is_instance_valid(node) and node.is_inside_tree(): node.grab_focus()
