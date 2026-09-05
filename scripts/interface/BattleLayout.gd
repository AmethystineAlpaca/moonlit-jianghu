extends RefCounted
const STYLE := preload("res://scripts/interface/JianghuTheme.gd")
const NAMES := ["唤灵", "神光", "月牙斩", "玉风暴", "回春"]

static func install(hud: CanvasLayer) -> void:
	var chrome := Control.new()
	chrome.name = "BattleChrome"
	chrome.set_script(preload("res://scripts/interface/BattleChrome.gd"))
	hud.add_child(chrome)
	hud.move_child(chrome, 0)
	var portrait := TextureRect.new()
	portrait.position = Vector2(39, 41)
	portrait.size = Vector2(53, 74)
	portrait.texture = load("res://assets/xianxia/players_gemini_idle_down.png")
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(portrait)
	var hero := STYLE.label("游侠   ·   初入江湖", 15, STYLE.PAPER, true)
	hero.position = Vector2(118, 35)
	hud.add_child(hero)
	var location := STYLE.label("青岚村  /  QINGLAN", 13, STYLE.GOLD)
	location.position = Vector2(1078, 37)
	hud.add_child(location)
	var panel := hud.get_node("StatsPanel") as PanelContainer
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(118, 65)
	panel.size = Vector2(230, 51)
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	for name in ["HPBar", "StaminaBar"]:
		var bar := hud.get_node("StatsPanel/Stats/" + name) as ProgressBar
		bar.custom_minimum_size = Vector2(228, 17)
		bar.add_theme_stylebox_override("background", STYLE.panel(Color("172b32"), Color("344b4b"), 0))
		var fill := StyleBoxFlat.new()
		fill.bg_color = Color("b8786b") if name == "HPBar" else Color("70a799")
		bar.add_theme_stylebox_override("fill", fill)
		var label := bar.get_node("ValueLabel") as Label
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", STYLE.PAPER)
	panel.call_deferred("set_size", Vector2(230, 51))
	hud.status_label.add_theme_font_size_override("font_size", 12)
	hud.skill_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	hud.skill_bar.position = Vector2(340, 599)
	hud.skill_bar.size = Vector2(600, 95)
	hud.skill_bar.add_theme_constant_override("separation", 10)
	for index in range(5):
		var slot := hud.skill_bar.get_node("Slot%d" % [index + 1]) as PanelContainer
		slot.custom_minimum_size = Vector2(112, 95)
		slot.add_theme_stylebox_override("panel", STYLE.panel(Color("12252d"), Color("526b62"), 7))
		var content := slot.get_node("SlotContent")
		content.get_node("Icon").visible = false
		var sigil := Control.new()
		sigil.name = "Sigil"
		sigil.set_script(preload("res://scripts/interface/SkillSigil.gd"))
		sigil.kind = index
		content.add_child(sigil)
		content.move_child(sigil, 0)
		var label := content.get_node("Label") as Label
		label.add_theme_font_override("font", STYLE.font())
		slot.tooltip_text = ["唤醒倒下的灵体，化敌为友", "护体神光：环绕自身，伤害近身敌人", "月牙斩：前方剑气 · 2 体力 · 3 秒", "玉风暴：周身范围攻击 · 4 体力 · 7 秒", "回春：恢复 3 点生命 · 3 体力 · 14 秒"][index]
	hud.controls_hint.text = "WASD 行走     J 攻击     K 格挡     Shift 闪避     1—5 法术     M 行囊     Esc 菜单"
	hud.controls_hint.add_theme_font_override("font", STYLE.font())
	hud.controls_hint.add_theme_font_size_override("font_size", 13)
	hud.controls_hint.add_theme_color_override("font_color", Color("b1c0ba"))
	hud.controls_hint.offset_top = 555
	hud.controls_hint.offset_bottom = 578
	hud.inventory_overlay.z_index = 100
	_skin_inventory(hud.inventory_overlay)

static func _skin_inventory(node: Node, shared_theme: Theme = null) -> void:
	if shared_theme == null:
		shared_theme = STYLE.make()
	if node is Control:
		node.theme = shared_theme
	if node is PanelContainer:
		node.add_theme_stylebox_override("panel", STYLE.panel(Color("10212b"), STYLE.GOLD, 18))
	if node is Button:
		node.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		node.alignment = HORIZONTAL_ALIGNMENT_CENTER
		node.add_theme_constant_override("icon_max_width", 28)
		node.add_theme_constant_override("h_separation", 10)
		for state in ["normal", "hover", "pressed", "focus"]:
			node.remove_theme_stylebox_override(state)
	if node is Label:
		node.add_theme_color_override("font_color", STYLE.PAPER)
		var translations := {"Inventory": "行 囊", "Equipment": "随 身 装 备", "Bag": "囊 中 之 物"}
		if translations.has(node.text): node.text = translations[node.text]
	for child in node.get_children(): _skin_inventory(child, shared_theme)
