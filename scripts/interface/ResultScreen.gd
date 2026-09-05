extends PanelContainer
const STYLE := preload("res://scripts/interface/JianghuTheme.gd")
var victory: bool = true
var kills: int = 0
var seconds: float = 0.0
var best: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = STYLE.make()
	position = Vector2(390, 142)
	custom_minimum_size = Vector2(500, 420)
	z_index = 210
	add_theme_stylebox_override("panel", STYLE.panel(Color("0d2029"), STYLE.GOLD, 30))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 20)
	add_child(box)
	var chapter := STYLE.label("青 岚 卷  ·  守 村 之 夜", 14, STYLE.GOLD)
	chapter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(chapter)
	var title := STYLE.label("长 夜 已 尽" if victory else "胜 败 乃 常 事", 36, STYLE.PAPER, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var subtitle := STYLE.label("万家灯火，因你长明。" if victory else "收拾剑心，再赴江湖。", 16, STYLE.JADE)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(subtitle)
	var stats := STYLE.label("退敌  %02d 名       历时  %02d:%02d       最佳  %02d" % [kills, int(seconds) / 60, int(seconds) % 60, maxi(best, kills)], 16)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(stats)
	var again := Button.new()
	again.text = "再入江湖   [R]"
	again.pressed.connect(func():
		get_tree().paused = false
		get_tree().reload_current_scene())
	box.add_child(again)
	var home := Button.new()
	home.text = "返回主菜单"
	home.pressed.connect(func():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/interface/TitleScreen.tscn"))
	box.add_child(home)
