extends Control
const STYLE := preload("res://scripts/interface/JianghuTheme.gd")
var modal: PanelContainer
var menu: VBoxContainer
var title_art: TextureRect
var elapsed: float = 0.0
var starting := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	theme = STYLE.make()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var base := ColorRect.new()
	base.color = Color("091821")
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(base)
	title_art = TextureRect.new()
	title_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	title_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists("res://assets/art_v2/title_moonlit.png"):
		title_art.texture = load("res://assets/art_v2/title_moonlit.png")
	add_child(title_art)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; void fragment(){ float a=mix(0.84,0.04,smoothstep(0.0,0.75,UV.x)); a+=0.16*pow(abs(UV.y-0.5)*2.0,3.0); COLOR=vec4(0.015,0.04,0.06,a); }"
	var shader_material := ShaderMaterial.new()
	shader_material.shader = shader
	shade.material = shader_material
	add_child(shade)
	var eyebrow := STYLE.label("一剑入江湖  ·  一念照山河", 15, STYLE.JADE)
	eyebrow.position = Vector2(86, 112)
	add_child(eyebrow)
	var title := STYLE.label("月 下 江 湖", 64, STYLE.PAPER, true)
	title.position = Vector2(76, 148)
	add_child(title)
	var english := STYLE.label("M O O N L I T   J I A N G H U", 16, STYLE.GOLD)
	english.position = Vector2(88, 238)
	add_child(english)
	var description := STYLE.label("月照青岚，故人未归。\n执剑穿过长夜，守住万家灯火。", 17, Color("a8b6b4"))
	description.position = Vector2(88, 294)
	description.add_theme_constant_override("line_spacing", 9)
	add_child(description)
	menu = VBoxContainer.new()
	menu.position = Vector2(88, 392)
	menu.size = Vector2(282, 204)
	menu.add_theme_constant_override("separation", 12)
	add_child(menu)
	_add_button("踏入江湖     /     开始游戏", start_game)
	_add_button("游 玩 指 南", show_guide)
	_add_button("设 置", show_settings)
	var footer := STYLE.label("青岚卷 · 守村之夜", 14, STYLE.GOLD)
	footer.position = Vector2(88, 656)
	add_child(footer)
	var version := STYLE.label("WASD / 方向键 移动     ·     键鼠操作", 12, Color("7f9698"))
	version.position = Vector2(850, 660)
	add_child(version)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.55)

func _add_button(text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(282, 52)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.pressed.connect(callback)
	menu.add_child(button)

func start_game() -> void:
	if starting:
		return
	starting = true
	for child in menu.get_children(): child.disabled = true
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/main/Main.tscn"))

func _modal(title: String, subtitle: String) -> VBoxContainer:
	if is_instance_valid(modal): modal.queue_free()
	modal = PanelContainer.new()
	modal.position = Vector2(460, 126)
	modal.custom_minimum_size = Vector2(620, 454)
	modal.add_theme_stylebox_override("panel", STYLE.panel(Color("0d1d26"), STYLE.GOLD, 32))
	add_child(modal)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 20)
	modal.add_child(box)
	box.add_child(STYLE.label(title, 30, STYLE.PAPER, true))
	box.add_child(STYLE.label(subtitle, 14, STYLE.JADE))
	return box

func show_guide() -> void:
	var box := _modal("初入江湖", "守住青岚村，击退群妖，再直面山君。")
	box.add_child(STYLE.label("WASD / 方向键    行走\nJ / 鼠标左键        三段连击（按住连续攻击）\nK                          格挡，精准格挡后可反击\nShift / L               闪避，期间免疫伤害\n1 — 5                   施放法术；空格重复当前法术\nM                          行囊与装备\nEsc                       暂停与设置", 16))
	box.add_child(STYLE.label("两次破境选择将改变你的战法；在行囊中切换三种兵刃。", 14, STYLE.GOLD))
	_close_button(box)

func show_settings() -> void:
	var box := _modal("设置", "让江湖适合你的节奏。")
	var settings := ConfigFile.new()
	settings.load("user://settings.cfg")
	for entry in [["镜头震动", "accessibility", "shake"], ["游戏声音", "audio", "sound"]]:
		var button := CheckButton.new()
		button.text = entry[0]
		button.button_pressed = bool(settings.get_value(entry[1], entry[2], true))
		button.toggled.connect(func(enabled: bool):
			settings.set_value(entry[1], entry[2], enabled)
			settings.save("user://settings.cfg")
			if entry[2] == "sound": AudioServer.set_bus_mute(0, not enabled))
		box.add_child(button)
	box.add_child(STYLE.label("设置自动保存在本机，下次进入时生效。", 14, STYLE.JADE))
	_close_button(box)

func _close_button(box: VBoxContainer) -> void:
	var button := Button.new()
	button.text = "返回"
	button.pressed.connect(func(): modal.queue_free())
	box.add_child(button)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game") and is_instance_valid(modal):
		modal.queue_free()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	draw_line(Vector2(88, 272), Vector2(360, 272), Color(STYLE.GOLD, 0.6), 1.0)
	for i in range(18):
		var x := fmod(float(i * 137) + elapsed * (3.0 + i % 4), 1280.0)
		var y := 680.0 - fmod(float(i * 73) + elapsed * (7.0 + i % 3), 650.0)
		draw_circle(Vector2(x, y), 1.2, Color(0.8, 0.87, 0.62, 0.2 + 0.15 * sin(elapsed + i)))
