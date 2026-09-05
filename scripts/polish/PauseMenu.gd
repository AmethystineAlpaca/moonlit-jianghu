extends PanelContainer
const STYLE := preload("res://scripts/interface/JianghuTheme.gd")
var hud: CanvasLayer
var feel: Node2D
var settings := ConfigFile.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hud = get_parent()
	feel = get_tree().get_first_node_in_group("game_feel")
	theme = STYLE.make()
	position = Vector2(430, 128)
	custom_minimum_size = Vector2(420, 440)
	z_index = 200
	add_theme_stylebox_override("panel", STYLE.panel(Color("0e2029"), STYLE.GOLD, 28))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	add_child(box)
	var title := STYLE.label("且 歇 片 刻", 34, STYLE.PAPER, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var subtitle := STYLE.label("剑可暂收，江湖仍在。", 14, STYLE.JADE)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(subtitle)
	var resume := Button.new()
	resume.text = "继续游历    [Esc]"
	resume.pressed.connect(func(): get_tree().paused = false)
	box.add_child(resume)
	var restart := Button.new()
	restart.text = "重新挑战"
	restart.pressed.connect(func():
		get_tree().paused = false
		get_tree().reload_current_scene())
	box.add_child(restart)
	settings.load("user://settings.cfg")
	var shake_toggle := CheckButton.new()
	shake_toggle.text = "镜头震动"
	shake_toggle.button_pressed = bool(settings.get_value("accessibility", "shake", true))
	feel.shake_enabled = shake_toggle.button_pressed
	shake_toggle.toggled.connect(func(enabled: bool):
		feel.shake_enabled = enabled
		settings.set_value("accessibility", "shake", enabled)
		settings.save("user://settings.cfg"))
	box.add_child(shake_toggle)
	var sound_toggle := CheckButton.new()
	sound_toggle.text = "游戏声音"
	sound_toggle.button_pressed = bool(settings.get_value("audio", "sound", true))
	AudioServer.set_bus_mute(0, not sound_toggle.button_pressed)
	sound_toggle.toggled.connect(func(enabled: bool):
		AudioServer.set_bus_mute(0, not enabled)
		settings.set_value("audio", "sound", enabled)
		settings.save("user://settings.cfg"))
	box.add_child(sound_toggle)
	var home := Button.new()
	home.text = "返回主菜单"
	home.pressed.connect(func():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/interface/TitleScreen.tscn"))
	box.add_child(home)
	visible = false

func _process(_delta: float) -> void:
	visible = get_tree().paused and not hud.inventory_open and not hud.get_meta("journey_modal", false)
	if visible:
		hud.paused_label.visible = false
