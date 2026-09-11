extends CanvasLayer
const FONT := preload("res://assets/fonts/StillwaterSans.tres")
const SERIF := preload("res://assets/fonts/StillwaterSerif.tres")
const SIGIL := preload("res://scripts/rebirth/AbilitySigil.gd")
const WHITE := Color("edf0e5")
const MUTED := Color("b0c8c5")
const GOLD := Color("e1c28b")
const JADE := Color("a5dacf")
const INK := Color("091b21")
const SEAL_NAMES := ["听雨", "照影", "归藏"]
var world: Node3D
var feedback: Control
var root: Control
var modal: Control
var hud: Control
var health: ProgressBar
var health_trail: ProgressBar
var stamina: ProgressBar
var objective: Label
var objective_detail: Label
var status: Label
var prompt: Label
var prompt_panel: Control
var toast: Label
var subtitle: Label
var toast_timer := 0.0
var toast_duration := 0.0
var weapon: Label
var weapon_detail: Label
var skills: Label
var boss_health: ProgressBar
var boss_posture: ProgressBar
var boss_name: Label
var boss_phase: Label
var seal_markers: Array[Label] = []
var seal_steps: Array[Label] = []
var skill_icons: Array[Control] = []
var skill_states: Array[Label] = []
var skill_keys: Array[Label] = []
var weapon_steps: Array[Label] = []
var flow_bar: ProgressBar
var flow_label: Label
var flow_detail: Label
var caution: Label
var lesson: Label
var run_clock: Label
var mastery: Label
var cinema_top: ColorRect
var cinema_bottom: ColorRect
var cinema_amount := 0.0
var modal_kind := ""
var guide_return := "title"
var hp_display := -1.0
var stamina_display := 100.0
var ui_clock := 0.0
var current_weapon := -1
var gamepad := false
var last_input_pad := false
var menu_tween: Tween
var director: RefCounted

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.name = "StillwaterInterface"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var theme := Theme.new()
	theme.default_font = FONT
	theme.default_font_size = 17
	theme.set_color("font_color","Label",WHITE)
	for state in ["normal","hover","pressed","focus"]:
		var panel := StyleBoxFlat.new()
		panel.bg_color = Color(0.07,0.17,0.19,0.96) if state == "hover" else Color(0.025,0.085,0.105,0.85)
		if state == "pressed": panel.bg_color = Color(0.13,0.25,0.25,0.98)
		if state == "focus": panel.bg_color = Color(0,0,0,0)
		panel.border_color = GOLD if state in ["hover","focus"] else Color(0.63,0.76,0.71,0.28)
		panel.border_width_bottom = 1
		if state == "focus":
			panel.border_width_left = 2
			panel.border_width_top = 1
			panel.border_width_right = 1
		panel.content_margin_left = 20
		panel.content_margin_right = 20
		panel.content_margin_top = 12
		panel.content_margin_bottom = 12
		theme.set_stylebox(state,"Button",panel)
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		theme.set_color(state,"Button",WHITE)
	root.theme = theme
	build_hud()

func label(parent: Control, text: String, pos: Vector2, font_size: int, color := WHITE, serif := false) -> Label:
	var node := Label.new()
	node.text = text
	node.position = pos
	node.add_theme_font_override("font",SERIF if serif else FONT)
	node.add_theme_font_size_override("font_size",font_size)
	node.add_theme_color_override("font_color",color)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

func centered(parent: Control, text: String, pos: Vector2, width: float, font_size: int, color := WHITE, serif := false) -> Label:
	var node := label(parent,text,pos,font_size,color,serif)
	node.size.x = width
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return node

func button(parent: Control, text: String, pos: Vector2, size: Vector2, callback: Callable) -> Button:
	var node := Button.new()
	node.text = text
	node.position = pos
	node.size = size
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.pressed.connect(callback)
	parent.add_child(node)
	if parent.get_children().filter(func(child: Node): return child is Button).size() == 1:
		_focus_button.call_deferred(node)
	return node

func line(parent: Control, pos: Vector2, size: Vector2, color: Color) -> ColorRect:
	var node := ColorRect.new()
	node.color = color
	node.position = pos
	node.size = size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

func panel(parent: Control, pos: Vector2, size: Vector2, alpha := 0.7) -> Panel:
	var node := Panel.new()
	node.position = pos
	node.size = size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(INK,alpha)
	style.border_color = Color(GOLD,0.2)
	style.border_width_top = 1
	style.border_width_bottom = 1
	node.add_theme_stylebox_override("panel",style)
	parent.add_child(node)
	return node

func bar(parent: Control, pos: Vector2, size: Vector2, color: Color) -> ProgressBar:
	var node := ProgressBar.new()
	node.position = pos
	node.size = size
	node.show_percentage = false
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.02,0.06,0.075,0.82)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	node.add_theme_stylebox_override("background",bg)
	node.add_theme_stylebox_override("fill",fill)
	parent.add_child(node)
	node.set_deferred("size",size)
	return node

func build_hud() -> void:
	hud = Control.new()
	hud.name = "JourneyHUD"
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)
	var edge_shade := line(hud,Vector2.ZERO,Vector2(1280,720),WHITE)
	var gradient := Shader.new()
	gradient.code = "shader_type canvas_item; void fragment(){ float top=(1.0-smoothstep(0.0,0.22,UV.y))*0.75; float bottom=smoothstep(0.77,1.0,UV.y)*0.88; COLOR=vec4(0.015,0.035,0.045,max(top,bottom)); }"
	var background := ShaderMaterial.new()
	background.shader = gradient
	edge_shade.material = background
	var readout := preload("res://scripts/rebirth/CombatReadout.gd").new()
	readout.world = world
	hud.add_child(readout)
	feedback = preload("res://scripts/rebirth/CombatFeedback.gd").new()
	feedback.world = world
	hud.add_child(feedback)
	label(hud,"游 侠",Vector2(42,30),23,WHITE,true)
	label(hud,"气血",Vector2(43,73),11,MUTED)
	health_trail = bar(hud,Vector2(77,80),Vector2(218,6),Color("b77154"))
	health = bar(hud,Vector2(77,80),Vector2(218,6),Color("e1c6a2"))
	var clear_style := StyleBoxFlat.new()
	clear_style.bg_color = Color.TRANSPARENT
	health.add_theme_stylebox_override("background",clear_style)
	label(hud,"气力",Vector2(43,91),11,MUTED)
	stamina = bar(hud,Vector2(77,99),Vector2(218,3),JADE)
	status = label(hud,"",Vector2(162,41),12,MUTED)
	status.size.x = 133
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	caution = label(hud,"",Vector2(43,114),13,Color("f3aa84"))
	objective = label(hud,"",Vector2(908,29),19,WHITE,true)
	objective.size.x = 324
	objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	objective_detail = label(hud,"",Vector2(878,64),13,MUTED)
	objective_detail.size.x = 354
	objective_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	for i in range(3):
		var step := label(hud,"◇  "+SEAL_NAMES[i],Vector2(993+i*83,93),12,MUTED)
		seal_steps.append(step)
	run_clock = label(hud,"",Vector2(1177,120),11,MUTED)
	weapon = label(hud,"",Vector2(43,607),24,WHITE,true)
	weapon_detail = label(hud,"",Vector2(43,643),12,MUTED)
	for i in range(3):
		var step := label(hud,"%d  %s" % [i+1,["直剑","重刃","灵剑"][i]],Vector2(43+i*80,674),12,MUTED)
		weapon_steps.append(step)
	skills = label(hud,"",Vector2.ZERO,12)
	skills.visible = false
	for i in range(4):
		var x := 876.0+i*97.0
		var icon := SIGIL.new()
		icon.kind = ["recall","burst","wine","surge"][i]
		icon.position = Vector2(x-25,594)
		icon.size = Vector2(50,50)
		icon.accent = GOLD if i == 3 else JADE
		hud.add_child(icon)
		skill_icons.append(icon)
		skill_keys.append(centered(hud,["Q","E","R","V"][i],Vector2(x-29,633),58,11,GOLD))
		centered(hud,["回锋","破阵","温酒","万籁"][i],Vector2(x-42,652),84,15,WHITE,true)
		skill_states.append(centered(hud,"",Vector2(x-44,678),88,11,MUTED))
	flow_label = centered(hud,"剑 意",Vector2(480,622),320,13,GOLD)
	flow_bar = bar(hud,Vector2(520,650),Vector2(240,3),GOLD)
	flow_detail = centered(hud,"",Vector2(460,668),360,11,MUTED)
	mastery = centered(hud,"",Vector2(425,588),430,15,JADE,true)
	mastery.add_theme_color_override("font_outline_color",Color(INK,0.9))
	mastery.add_theme_constant_override("outline_size",2)
	prompt_panel = panel(hud,Vector2(455,548),Vector2(370,39),0.85)
	prompt = centered(prompt_panel,"",Vector2(0,7),370,16,GOLD)
	lesson = centered(hud,"",Vector2(355,113),570,13,MUTED)
	boss_name = centered(hud,"无 相",Vector2(445,27),390,25,WHITE,true)
	boss_phase = centered(hud,"山门最后的守剑人",Vector2(445,64),390,11,MUTED)
	boss_health = bar(hud,Vector2(445,90),Vector2(390,5),GOLD)
	boss_posture = bar(hud,Vector2(485,102),Vector2(310,2),Color("eba267"))
	for i in range(3):
		var marker := centered(hud,"",Vector2.ZERO,150,14,GOLD)
		marker.add_theme_color_override("font_outline_color",Color(0.015,0.03,0.04,0.9))
		marker.add_theme_constant_override("outline_size",2)
		marker.add_theme_constant_override("shadow_offset_y",1)
		seal_markers.append(marker)
	toast = centered(root,"",Vector2(240,163),800,35,WHITE,true)
	toast.add_theme_color_override("font_outline_color",Color(0.01,0.025,0.03,0.85))
	toast.add_theme_constant_override("outline_size",2)
	subtitle = centered(root,"",Vector2(270,216),740,15,MUTED)
	subtitle.add_theme_color_override("font_outline_color",Color(0.01,0.025,0.03,0.85))
	subtitle.add_theme_constant_override("outline_size",2)
	cinema_top = line(root,Vector2.ZERO,Vector2(1280,0),Color("061318"))
	cinema_bottom = line(root,Vector2(0,720),Vector2(1280,0),Color("061318"))

func new_modal(kind := "") -> Control:
	clear_modal()
	modal_kind = kind
	modal = Control.new()
	modal.name = "Modal_"+kind
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(modal)
	modal.modulate.a = 0
	menu_tween = create_tween()
	menu_tween.tween_property(modal,"modulate:a",1.0,0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	return modal

func clear_modal() -> void:
	if menu_tween and menu_tween.is_valid(): menu_tween.kill()
	if is_instance_valid(modal):
		root.remove_child(modal)
		modal.queue_free()
	modal = null
	modal_kind = ""

func shade(parent: Control, alpha := 0.7) -> void:
	line(parent,Vector2.ZERO,Vector2(1280,720),Color(0.015,0.04,0.055,alpha))

func frame(parent: Control) -> void:
	line(parent,Vector2(80,68),Vector2(1120,1),Color(GOLD,0.27))
	line(parent,Vector2(80,652),Vector2(1120,1),Color(GOLD,0.27))
	label(parent,"雨 歇  /  S T I L L W A T E R",Vector2(80,37),11,MUTED)
	label(parent,"青岚山志 · 问剑篇",Vector2(1055,37),12,GOLD,true)

func show_title() -> void:
	new_modal("title")
	var wash := line(modal,Vector2.ZERO,Vector2(1280,720),WHITE)
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; void fragment(){ float left=mix(0.95,0.02,smoothstep(0.0,0.70,UV.x)); float edge=smoothstep(0.76,1.0,UV.y)*0.4; COLOR=vec4(0.02,0.055,0.068,max(left,edge)); }"
	var mat := ShaderMaterial.new()
	mat.shader = shader
	wash.material = mat
	label(modal,"M O O N L I T   J I A N G H U",Vector2(80,84),12,MUTED)
	line(modal,Vector2(82,124),Vector2(28,1),GOLD)
	label(modal,"雨 歇",Vector2(72,143),91,WHITE,true)
	label(modal,"S T I L L W A T E R",Vector2(82,267),16,GOLD)
	var stamp := panel(modal,Vector2(325,169),Vector2(28,71),0.4)
	centered(stamp,"问\n剑",Vector2(0,8),28,17,GOLD,true)
	label(modal,"三盏灯，一座山门。\n听雨，照影，问此生。",Vector2(82,320),20,MUTED,true)
	button(modal,"入 山    /    开始旅程",Vector2(80,417),Vector2(304,58),world.start_run)
	button(modal,"剑  谱    /    游玩指南",Vector2(80,487),Vector2(304,48),show_guide)
	label(modal,"行 路 难 度",Vector2(82,558),11,MUTED)
	if world.has_method("set_difficulty"):
		for i in range(3):
			var selected: bool = int(world.difficulty) == i
			var choice := button(modal,["听雨","问剑","无相"][i]+(" ·" if selected else ""),Vector2(80+i*104,582),Vector2(96,34),func():
				world.set_difficulty(i)
				show_title())
			choice.add_theme_font_size_override("font_size",13)
			if selected: choice.add_theme_color_override("font_color",GOLD)
	else:
		label(modal,"问剑 · 标准历练",Vector2(82,584),14,GOLD)
	if world.has_method("set_difficulty"):
		label(modal,["从容听雨 · 所受伤害降低","攻守有时 · 标准问剑历练","险中问道 · 所受伤害提高"][int(world.difficulty)],Vector2(82,628),12,MUTED)
	label(modal,"闪避留影 · 见切回锋 · 一剑破万籁",Vector2(82,671),12,MUTED)
	label(modal,"青岚山 · 雨后",Vector2(1085,641),16,WHITE,true)
	label(modal,"耳机体验更佳    F11 全屏",Vector2(1040,674),11,MUTED)
	if world.best >= 1:
		label(modal,"最快问剑  %02d:%02d" % [int(world.best)/60,int(world.best)%60],Vector2(1021,611),12,GOLD)

func guide_column(x: float, number: String, title: String, rows: Array) -> void:
	var card := panel(modal,Vector2(x,232),Vector2(320,322),0.62)
	label(card,number,Vector2(22,18),12,GOLD)
	label(card,title,Vector2(22,44),27,WHITE,true)
	var y := 97.0
	for row in rows:
		label(card,row[0],Vector2(22,y),14,GOLD)
		var detail := label(card,row[1],Vector2(22,y+26),14,MUTED)
		detail.size.x = 280
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		y += 72

func show_guide() -> void:
	if modal_kind != "guide": guide_return = "pause" if world.mode == "pause" else "title"
	new_modal("guide")
	shade(modal,0.92)
	frame(modal)
	label(modal,"一 招 一 式，皆 有 回 响",Vector2(110,111),38,WHITE,true)
	label(modal,"寻访三座石灯 → F 唤醒守灯人 → 击退来敌，选择领悟 → 问剑无相",Vector2(112,178),16,MUTED)
	guide_column(110,"01  /  身法","先站稳，再出剑",[
		["WASD 移动 · 鼠标朝向","按住左键 / J 连斩，第三剑更强。"],
		["右键 / K 格挡 · 见切","迎着来刃格挡；刃光亮起时抓准时机。"],
		["Shift / 空格 闪避","取消出招并留下一道雨痕，消耗气力。"]])
	guide_column(480,"02  /  剑术","让每一步都有后手",[
		["Q 回锋 · E 破阵","闪避后沿雨痕回切；破阵踢退、反弹飞弹。"],
		["F 追斩 · R 温酒","敌人破势时追斩；温酒恢复气血。"],
		["V 万籁一斩","积满剑意释放绝技，短暂进入剑意高涨。"]])
	guide_column(850,"03  /  兵刃","三把剑，三种节奏",[
		["1 听雨 · 直剑","攻守均衡，连段流畅。适合初次问剑。"],
		["2 断岳 · 重刃","出剑稍慢，打断守剑人，迅速压垮架势。"],
		["3 流萤 · 灵剑","连击回气，第三剑放出剑气。"]])
	label(modal,"手柄  左摇杆移动 · 右摇杆朝向 · X 出剑 · A 闪避 · LB 格挡 · RB / Y 技能 · B 温酒 · ↑ 交互 · R3 万籁",Vector2(110,576),12,MUTED)
	button(modal,"合上剑谱   /   返回",Vector2(110,602),Vector2(270,42),_return_from_guide)
	label(modal,"Esc 返回    ·    随时可从暂停菜单翻阅",Vector2(900,672),11,MUTED)

func _return_from_guide() -> void:
	if guide_return == "pause": show_pause()
	else: show_title()

func show_pause() -> void:
	new_modal("pause")
	shade(modal,0.82)
	frame(modal)
	label(modal,"且 听 风 吟",Vector2(176,118),47,WHITE,true)
	label(modal,"雨未歇，剑还在。",Vector2(179,186),18,MUTED,true)
	button(modal,"继续旅程     /     Esc",Vector2(176,256),Vector2(355,54),world.resume)
	button(modal,"翻 阅 剑 谱",Vector2(176,326),Vector2(355,48),show_guide)
	button(modal,"重新启程",Vector2(176,390),Vector2(355,48),func(): get_tree().reload_current_scene())
	button(modal,"离 开 游 戏",Vector2(176,454),Vector2(355,48),func(): get_tree().root.get_node("Soundscape").shutdown())
	line(modal,Vector2(638,249),Vector2(1,291),Color(GOLD,0.24))
	label(modal,"旅 途 设 定",Vector2(726,252),22,WHITE,true)
	button(modal,"镜头震动     "+("开" if world.shake_enabled else "关"),Vector2(726,308),Vector2(348,46),func():
		world.shake_enabled = not world.shake_enabled
		world.save_settings()
		show_pause())
	button(modal,"山间声景     "+("关" if AudioServer.is_bus_mute(0) else "开"),Vector2(726,370),Vector2(348,46),func():
		AudioServer.set_bus_mute(0,not AudioServer.is_bus_mute(0))
		world.save_settings()
		show_pause())
	label(modal,"已解封印  %d / 3    ·    行路  %02d:%02d" % [world.round_index,int(world.run_time)/60,int(world.run_time)%60],Vector2(726,452),14,GOLD)
	label(modal,"F11 切换全屏\n方向键 / 手柄选择 · Enter / A 确认",Vector2(726,488),13,MUTED)
	label(modal,"格挡不必贪早，见切恰在来刃之时。",Vector2(176,581),16,MUTED,true)

func show_upgrade() -> void:
	new_modal("upgrade")
	shade(modal,0.9)
	frame(modal)
	label(modal,"灯 火 长 明",Vector2(128,113),47,WHITE,true)
	label(modal,"一灯一悟。选定此行的剑道。",Vector2(131,184),18,MUTED,true)
	label(modal,"封印已解   %d / 3"%world.round_index,Vector2(1000,164),14,GOLD)
	var choices: Array = [
		{"name":"砺锋","subtitle":"以攻为守","description":"出剑伤害 +0.7\n每一次交锋更有分量。","key":"damage"},
		{"name":"定心","subtitle":"山岳不动","description":"气血上限 +3，并完全恢复\n留住下一次见切的机会。","key":"resilience"}]
	if world.has_method("run_report") and not world.available_upgrades.is_empty(): choices = world.available_upgrades
	var card_width := 304.0
	var spacing := 28.0
	var start_x := (1280.0-(choices.size()*card_width+(choices.size()-1)*spacing))/2.0
	for i in range(choices.size()):
		var item: Dictionary = choices[i]
		var card := button(modal,"",Vector2(start_x+i*(card_width+spacing),267),Vector2(card_width,293),world.upgrade.bind(i))
		label(card,"领 悟  /  0%d"%(i+1),Vector2(25,19),11,MUTED)
		var glyph := SIGIL.new()
		glyph.kind = {"blade":"damage","resolve":"resilience","echo":"recall","breath":"burst","mercy":"resilience","wine":"wine","damage":"damage","resilience":"resilience"}.get(str(item.get("key","")),"damage")
		glyph.position = Vector2(224,22)
		glyph.size = Vector2(50,50)
		glyph.accent = GOLD
		card.add_child(glyph)
		label(card,str(item.get("name","领悟")),Vector2(25,68),37,WHITE,true)
		label(card,str(item.get("subtitle","剑道精进")),Vector2(27,126),14,GOLD)
		line(card,Vector2(27,164),Vector2(250,1),Color(GOLD,0.25))
		var detail := label(card,str(item.get("description","")),Vector2(27,183),15,MUTED)
		detail.size = Vector2(251,82)
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.add_theme_constant_override("line_spacing",6)
		label(card,"%d   领 悟     →"%(i+1),Vector2(27,257),12,GOLD)
	centered(modal,"数字键选择 · 方向键 / 手柄切换 · Enter / A 确认",Vector2(240,598),800,13,MUTED)

func show_result(victory: bool) -> void:
	new_modal("result")
	shade(modal,0.88)
	frame(modal)
	var report: Dictionary = world.run_report() if world.has_method("run_report") else {}
	label(modal,"雨  歇" if victory else "剑  息",Vector2(161,117),73,WHITE,true)
	label(modal,"山门重开，灯火不灭。" if victory else "胜负有时，再问此山。",Vector2(166,228),23,MUTED,true)
	var rank := str(report.get("rank","问剑客" if victory else "行路人"))
	label(modal,"此 行 剑 评",Vector2(928,135),12,MUTED)
	centered(modal,rank,Vector2(855,155),280,65,GOLD,true)
	centered(modal,str(report.get("title","")),Vector2(855,244),280,16,MUTED,true)
	line(modal,Vector2(167,292),Vector2(940,1),Color(GOLD,0.28))
	var metrics := [
		["行路时辰","%02d:%02d"%[int(world.run_time)/60,int(world.run_time)%60]],
		["击退守剑人",str(world.kills)],
		["剑意得分",str(report.get("score",world.kills*100))],
		["最长连势",str(report.get("best_chain",0))]]
	for i in range(4):
		var x := 169.0+i*249.0
		label(modal,metrics[i][0],Vector2(x,324),13,MUTED)
		label(modal,metrics[i][1],Vector2(x,351),38,WHITE,true)
	var record := "见切 %d    ·    追斩 %d    ·    回锋 %d    ·    极限闪避 %d" % [int(report.get("parries",0)),int(report.get("executions",0)),int(report.get("recalls",0)),int(report.get("perfect_dodges",0))]
	label(modal,record,Vector2(169,427),15,GOLD)
	var advice := "换一把剑，再听一次山雨。" if victory else "留意来刃，闪避后回锋；破势时用 F 追斩。"
	label(modal,advice,Vector2(169,475),17,MUTED,true)
	if not victory and world.has_method("retry_from_checkpoint"):
		button(modal,"重 整 剑 心    /    再战此灯",Vector2(167,545),Vector2(340,53),world.retry_from_checkpoint)
		button(modal,"重新启程",Vector2(537,545),Vector2(245,53),func(): get_tree().reload_current_scene())
	else:
		button(modal,"再 走 一 程",Vector2(167,545),Vector2(340,53),func(): get_tree().reload_current_scene())
	label(modal,"青岚山门，静候再临。",Vector2(934,605),14,MUTED,true)

func notify(title: String, text: String, seconds: float) -> void:
	toast.text = title
	subtitle.text = text
	toast_timer = seconds
	toast_duration = seconds

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.25): last_input_pad = true
	elif event is InputEventKey or event is InputEventMouseButton: last_input_pad = false
	if modal_kind == "guide" and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_return_from_guide()
		get_viewport().set_input_as_handled()
	if modal_kind == "upgrade" and event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_1,KEY_2,KEY_3]:
		var index: int = event.keycode-KEY_1
		var count := 2
		if world.has_method("run_report"): count = world.available_upgrades.size()
		if index < count:
			world.upgrade(index)
			get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not is_instance_valid(world) or not is_instance_valid(world.player): return
	ui_clock += delta
	hud.visible = world.mode == "play"
	if world.mode == "play": toast_timer = maxf(0,toast_timer-delta)
	var toast_alpha := minf(1,toast_timer*2.5)*minf(1,(toast_duration-toast_timer)*5.0)
	toast.modulate.a = toast_alpha if world.mode == "play" else 0
	subtitle.modulate.a = toast.modulate.a
	toast.position.y = 163.0+(1.0-minf(1,(toast_duration-toast_timer)*4.0))*8
	var cinematic := 0.0
	if world.has_method("run_report") and is_instance_valid(world.director):
		cinematic = float(world.director.cinematic_left)
	cinema_amount = lerpf(cinema_amount,1.0 if cinematic > 0 and world.mode == "play" else 0.0,1-exp(-delta*6))
	cinema_top.size.y = cinema_amount*36
	cinema_bottom.size.y = cinema_amount*36
	cinema_bottom.position.y = 720-cinema_bottom.size.y
	hud.modulate.a = 1.0-cinema_amount
	if not hud.visible: return
	var p = world.player
	if hp_display < 0: hp_display = p.hp
	hp_display = move_toward(hp_display,p.hp,delta*maxf(2,p.max_hp*0.6))
	stamina_display = lerpf(stamina_display,p.stamina,1-exp(-delta*16))
	health.max_value = p.max_hp
	health.value = p.hp
	health_trail.max_value = p.max_hp
	health_trail.value = hp_display
	stamina.value = stamina_display
	status.text = "%02d / %02d" % [ceili(p.hp),int(p.max_hp)]
	caution.text = "气血将尽 · %s 温酒" % ("B" if last_input_pad else "R") if p.hp <= p.max_hp*0.3 and world.heal_count > 0 else ("气力不足 · 暂缓攻势" if p.stamina < 24 else "")
	if p.hp <= p.max_hp*0.3: health.modulate = Color("f2ac90")
	else: health.modulate = Color.WHITE
	_update_objective()
	if current_weapon != p.weapon:
		current_weapon = p.weapon
		weapon.text = ["听 雨  /  直剑","断 岳  /  重刃","流 萤  /  灵剑"][p.weapon]
		weapon_detail.text = ["攻守均衡 · 三段连斩","重击打断 · 迅速破势","连击回气 · 三剑生芒"][p.weapon]
		for i in range(3): weapon_steps[i].modulate = GOLD if i == p.weapon else Color(0.67,0.79,0.76,0.64)
	_update_abilities()
	var executable: bool = world.executable_target() != null
	prompt.text = ("↑   追斩 · 破势终结" if last_input_pad else "F   追斩 · 破势终结") if executable else (("↑   点亮石灯" if last_input_pad else "F   点亮石灯") if not world.encounter and world.nearest_seal() >= 0 else "")
	prompt_panel.visible = not prompt.text.is_empty()
	_update_lesson()

func _update_objective() -> void:
	var boss_alive: bool = is_instance_valid(world.boss_node) and not world.boss_node.dead
	boss_health.visible = boss_alive
	boss_posture.visible = boss_alive
	boss_name.visible = boss_alive
	boss_phase.visible = boss_alive
	objective.text = "终章 · 问剑无相" if boss_alive else ("守灯之试 · "+SEAL_NAMES[maxi(0,world.current_seal)] if world.encounter else "青岚山 · 寻访石灯")
	objective_detail.text = "破其势，再问其剑" if boss_alive else ("剩余守剑人  %02d" % (world.living_enemies()+world.spawn_queue) if world.encounter else "靠近石灯，唤醒守灯人")
	run_clock.text = "%02d:%02d" % [int(world.run_time)/60,int(world.run_time)%60]
	for i in range(3):
		seal_steps[i].text = ("◆  " if world.seal_done[i] else "◇  ")+SEAL_NAMES[i]
		seal_steps[i].modulate = GOLD if world.seal_done[i] else Color.WHITE
	var nearest := -1
	var nearest_distance := INF
	for i in range(3):
		if not world.seal_done[i]:
			var distance: float = world.player.position.distance_to(world.seals[i].position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest = i
	for i in range(3):
		var marker := seal_markers[i]
		marker.visible = i == nearest and not world.encounter and not boss_alive
		if marker.visible:
			var point: Vector2 = world.camera.unproject_position(world.seals[i].position+Vector3.UP*2.1)
			marker.position = Vector2(clampf(point.x-75,70,1060),clampf(point.y-20,156,514))
			marker.text = "◇ %s · %d步" % [SEAL_NAMES[i],maxi(1,int(nearest_distance))]
	if boss_alive:
		boss_health.max_value = world.boss_node.max_hp
		boss_health.value = world.boss_node.hp
		boss_posture.value = 100 if world.boss_node.action == "broken" else world.boss_node.posture
		boss_phase.text = "破 势  /  追斩机会" if world.boss_node.action == "broken" else ("贰 · 雨骤剑疾" if world.boss_node.hp <= world.boss_node.max_hp*0.5 else "壹 · 静水藏锋")

func _update_abilities() -> void:
	var echo_alive := is_instance_valid(world.echo)
	var cooldown: float = world.skill_cooldowns[0]
	var recall_duration: float = 2.8*pow(0.75,world.director.bonuses.echo)
	var echo_duration: float = 4.5+world.director.bonuses.echo*1.5
	var echo_ready: bool = echo_alive and cooldown <= 0 and world.player.stamina >= 24
	skill_icons[0].enabled = echo_ready
	skill_icons[0].readiness = (1-cooldown/recall_duration) if cooldown > 0 else (clampf(world.echo.life/echo_duration,0,1) if echo_alive else 0)
	skill_states[0].text = "%.1fs" % cooldown if cooldown > 0 else ("留影 %.1fs"%world.echo.life if echo_alive else "闪避后可用")
	skill_icons[0].pulse = (0.5+sin(ui_clock*5)*0.5) if echo_ready else 0
	var push_cooldown: float = world.skill_cooldowns[1]
	skill_icons[1].enabled = push_cooldown <= 0 and world.player.stamina >= 24
	skill_icons[1].readiness = 1-push_cooldown/(4.0*pow(0.8,world.director.bonuses.breath))
	skill_states[1].text = "%.1fs"%push_cooldown if push_cooldown > 0 else ("气力不足" if world.player.stamina < 24 else "踢退 / 反弹")
	skill_icons[2].enabled = world.heal_count > 0 and world.player.hp < world.player.max_hp
	skill_icons[2].readiness = 1.0 if world.heal_count > 0 else 0.0
	skill_states[2].text = "%d 壶"%world.heal_count
	var flow := 0.0
	var chain := 0
	var surge_left := 0.0
	if world.has_method("run_report") and is_instance_valid(world.director):
		director = world.director
		flow = director.flow
		chain = director.chain
		surge_left = director.surge_left
		mastery.text = director.event_caption
		mastery.modulate = Color(director.event_color,minf(1.0,director.event_time*2.5))
		mastery.position.y = 588-(1.8-director.event_time)*3
	flow_bar.value = lerpf(flow_bar.value,flow,0.15)
	flow_label.text = "万 籁 归 寂   ·   %.1fs"%surge_left if surge_left > 0 else ("剑 意 已 满" if flow >= 100 else "剑 意"+("   ·   连势 %d"%chain if chain > 1 else ""))
	flow_detail.text = "剑意高涨" if surge_left > 0 else (("R3  万籁一斩" if last_input_pad else "V  万籁一斩") if flow >= 100 else "进攻 · 见切 · 回锋积攒剑意")
	skill_icons[3].enabled = flow >= 100 or surge_left > 0
	skill_icons[3].readiness = flow/100.0
	skill_icons[3].pulse = 0.5+sin(ui_clock*4)*0.5 if flow >= 100 else 0
	skill_states[3].text = "剑意高涨" if surge_left > 0 else ("绝技就绪" if flow >= 100 else "%d / 100"%int(flow))
	for i in range(4):
		skill_icons[i].queue_redraw()
		skill_keys[i].text = (["RB","Y","B","R3"] if last_input_pad else ["Q","E","R","V"])[i]

func _update_lesson() -> void:
	lesson.visible = world.run_time < 65 and toast_timer <= 0 and not is_instance_valid(world.boss_node)
	if not lesson.visible: return
	if world.run_time < 13:
		lesson.text = "左摇杆移动 · X 出剑 · A 闪避" if last_input_pad else "WASD 移动 · 鼠标朝向 · 按住左键连续出剑"
	elif not world.encounter:
		lesson.text = "跟随 ◇ 寻访石灯；也可按 1 / 2 / 3 试用不同兵刃"
	elif world.run_time < 37:
		lesson.text = "敌人举刃蓄势，刃光亮起时格挡，可见切反击"
	else:
		lesson.text = "闪避留下雨痕 → Q 回锋穿敌 → 敌人破势后 F 追斩"

func _focus_button(node: Button) -> void:
	if is_instance_valid(node) and node.is_inside_tree(): node.grab_focus()
