extends PanelContainer
signal chosen(index: int)
const STYLE := preload("res://scripts/interface/JianghuTheme.gd")
var stage: int = 1
var resolved := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = STYLE.make()
	position = Vector2(280, 192)
	custom_minimum_size = Vector2(720, 310)
	z_index = 220
	add_theme_stylebox_override("panel", STYLE.panel(Color("10222a"), STYLE.GOLD, 30))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 22)
	add_child(box)
	var title := STYLE.label("剑 心 初 明" if stage == 1 else "破 境 而 行", 34, STYLE.PAPER, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var description := STYLE.label("风雨未歇。选择一份领悟，迎接下一战。", 16, STYLE.JADE)
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(description)
	var choices := HBoxContainer.new()
	choices.add_theme_constant_override("separation", 18)
	box.add_child(choices)
	for i in range(2):
		var button := Button.new()
		button.text = ["剑 意\n普通攻击伤害 +1\n[1]", "归 元\n生命上限 +2，并完全恢复\n[2]"][i]
		button.custom_minimum_size = Vector2(320, 130)
		button.pressed.connect(select.bind(i))
		choices.add_child(button)
	get_parent().set_meta("journey_modal", true)
	get_tree().paused = true

func select(index: int) -> void:
	if resolved: return
	resolved = true
	get_parent().set_meta("journey_modal", false)
	Input.action_release("select_skill_1")
	Input.action_release("select_skill_2")
	get_tree().paused = false
	chosen.emit(index)
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("select_skill_1"):
		select(0)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("select_skill_2"):
		select(1)
		get_viewport().set_input_as_handled()
