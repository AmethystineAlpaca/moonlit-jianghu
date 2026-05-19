extends SceneTree

const HUD_SCENE := preload("res://ui/Hud.tscn")

var failures := 0

func _initialize() -> void:
	await _test_hud_uses_framed_pixel_panels()
	await _test_skill_slots_have_themed_frames()
	await _test_health_and_stamina_are_numbered_color_bars()
	await _test_skill_slots_use_icons_for_transform_and_empty_slots()
	await _test_selected_skill_text_panel_is_removed()
	await _test_controls_hint_is_small_top_text_that_fades_after_start()
	quit(failures)

func _test_hud_uses_framed_pixel_panels() -> void:
	var hud := HUD_SCENE.instantiate()
	root.add_child(hud)
	await process_frame

	var stats_panel := hud.get_node_or_null("StatsPanel")
	_assert_true(stats_panel is PanelContainer, "HUD has a framed stats panel")
	if stats_panel is PanelContainer:
		_assert_true((stats_panel as PanelContainer).get_theme_stylebox("panel") is StyleBoxFlat, "stats panel uses a styled flat box")

	hud.free()

func _test_health_and_stamina_are_numbered_color_bars() -> void:
	var hud := HUD_SCENE.instantiate()
	root.add_child(hud)
	await process_frame

	var hp_bar := hud.get_node_or_null("StatsPanel/Stats/HPBar")
	var hp_value := hud.get_node_or_null("StatsPanel/Stats/HPBar/ValueLabel")
	var stamina_bar := hud.get_node_or_null("StatsPanel/Stats/StaminaBar")
	var stamina_value := hud.get_node_or_null("StatsPanel/Stats/StaminaBar/ValueLabel")
	_assert_true(hp_bar is ProgressBar, "HP is shown as a progress bar")
	_assert_true(hp_value is Label, "HP number is inside the bar")
	_assert_true(stamina_bar is ProgressBar, "stamina is shown as a progress bar")
	_assert_true(stamina_value is Label, "stamina number is inside the bar")
	if hp_bar is ProgressBar:
		_assert_true(_fill_color(hp_bar as ProgressBar).r > _fill_color(hp_bar as ProgressBar).g, "HP bar fill is red")
	if stamina_bar is ProgressBar:
		_assert_true(_fill_color(stamina_bar as ProgressBar).r > 0.7 and _fill_color(stamina_bar as ProgressBar).g > 0.55, "stamina bar fill is yellow")

	hud.free()

func _test_selected_skill_text_panel_is_removed() -> void:
	var hud := HUD_SCENE.instantiate()
	root.add_child(hud)
	await process_frame

	_assert_true(hud.get_node_or_null("SkillStatePanel") == null, "selected skill text panel is removed")
	_assert_true(hud.get_node_or_null("SkillStateLabel") == null, "selected skill text label is removed")

	hud.free()

func _test_controls_hint_is_small_top_text_that_fades_after_start() -> void:
	var hud := HUD_SCENE.instantiate()
	root.add_child(hud)
	await process_frame

	var controls_hint := hud.get_node_or_null("ControlsHint") as Label
	_assert_true(controls_hint != null, "controls hint exists")
	if controls_hint != null:
		_assert_true(controls_hint.anchor_top == 0.0 and controls_hint.anchor_bottom == 0.0, "controls hint lives at the top")
		_assert_true(controls_hint.get_theme_font_size("font_size") <= 18, "controls hint uses small text")
		_assert_true(controls_hint.modulate.a > 0.9, "controls hint starts visible")

	if hud.has_method("_update_controls_hint_fade"):
		hud.set("controls_hint_timer", 31.0)
		hud.call("_update_controls_hint_fade", 0.0)
		_assert_true(controls_hint.modulate.a < 1.0, "controls hint fades after the opening window")
	else:
		_assert_true(false, "HUD exposes controls hint fade update")

	hud.free()

func _test_skill_slots_use_icons_for_transform_and_empty_slots() -> void:
	var hud := HUD_SCENE.instantiate()
	root.add_child(hud)
	await process_frame

	var slot_names: Array[String] = ["Transform", "Empty", "Empty", "Empty", "Empty"]
	hud.call("_on_skill_slots_changed", slot_names)
	await process_frame

	var transform_icon := hud.get_node_or_null("SkillBar/Slot1/SlotContent/Icon")
	var empty_icon := hud.get_node_or_null("SkillBar/Slot2/SlotContent/Icon")
	_assert_true(transform_icon is TextureRect, "Transform slot has an icon")
	_assert_true(empty_icon is TextureRect, "empty slot has an icon")
	if transform_icon is TextureRect and empty_icon is TextureRect:
		_assert_true((transform_icon as TextureRect).texture != null, "Transform icon has a texture")
		_assert_true((empty_icon as TextureRect).texture != null, "empty icon has a texture")
		_assert_true((transform_icon as TextureRect).texture != (empty_icon as TextureRect).texture, "Transform and empty slots use different icons")
		_assert_true((transform_icon as TextureRect).texture.resource_path.ends_with("icon_dash.png"), "Transform uses imported dash icon")
		_assert_true((empty_icon as TextureRect).texture.resource_path.ends_with("icon_sword.png"), "empty slot uses imported sword fallback icon")

	hud.free()

func _fill_color(progress_bar: ProgressBar) -> Color:
	var fill := progress_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill == null:
		return Color.BLACK
	return fill.bg_color

func _test_skill_slots_have_themed_frames() -> void:
	var hud := HUD_SCENE.instantiate()
	root.add_child(hud)
	await process_frame

	var skill_bar := hud.get_node("SkillBar")
	for index in range(5):
		var slot := skill_bar.get_node("Slot%s" % [index + 1]) as PanelContainer
		_assert_true(slot.get_theme_stylebox("panel") is StyleBoxFlat, "skill slot has a themed frame")

	hud.free()

func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	failures += 1
	push_error(message)
