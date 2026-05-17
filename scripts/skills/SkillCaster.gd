class_name SkillCaster
extends Node

signal skill_slots_changed(slot_names: Array[String])
signal skill_cast_failed(message: String)
signal skill_cast_started(message: String)
signal active_slots_changed(active_states: Array[bool])

const SLOT_COUNT := 5
const AUTO_CAST_INTERVAL := 1.0

@export var skills: Array[SkillDefinition] = []

var cooldowns: Array[float] = []
var active_slots: Array[bool] = []
var _auto_cast_timers: Array[float] = []

func _ready() -> void:
	_ensure_slot_data()
	skill_slots_changed.emit(get_slot_names())

func _process(delta: float) -> void:
	for index in range(cooldowns.size()):
		if cooldowns[index] > 0.0:
			cooldowns[index] = maxf(0.0, cooldowns[index] - delta)

	for index in range(SLOT_COUNT):
		if not active_slots[index]:
			continue
		if skills[index] == null:
			continue
		_auto_cast_timers[index] -= delta
		if _auto_cast_timers[index] <= 0.0:
			try_cast_slot(index)
			_auto_cast_timers[index] = AUTO_CAST_INTERVAL

func toggle_slot(slot_index: int) -> void:
	_ensure_slot_data()
	if slot_index < 0 or slot_index >= SLOT_COUNT:
		return
	if skills[slot_index] == null:
		return
	active_slots[slot_index] = not active_slots[slot_index]
	_auto_cast_timers[slot_index] = 0.0
	active_slots_changed.emit(get_active_slots())

func is_slot_active(slot_index: int) -> bool:
	_ensure_slot_data()
	if slot_index < 0 or slot_index >= SLOT_COUNT:
		return false
	return active_slots[slot_index]

func activate_all_filled_slots() -> void:
	_ensure_slot_data()
	for index in range(SLOT_COUNT):
		active_slots[index] = skills[index] != null
		_auto_cast_timers[index] = 0.0
	active_slots_changed.emit(get_active_slots())

func get_active_slots() -> Array[bool]:
	_ensure_slot_data()
	var copy: Array[bool] = []
	for value in active_slots:
		copy.append(value)
	return copy

func get_slot_names() -> Array[String]:
	_ensure_slot_data()
	var names: Array[String] = []
	for index in range(SLOT_COUNT):
		var skill := skills[index]
		if skill == null:
			names.append("Empty")
		else:
			names.append(skill.display_name)
	return names

func try_cast_slot(slot_index: int) -> bool:
	_ensure_slot_data()
	if slot_index < 0 or slot_index >= SLOT_COUNT:
		return _fail("No Skill")

	var skill := skills[slot_index]
	if skill == null:
		return _fail("No Skill")
	if cooldowns[slot_index] > 0.0:
		return _fail("Cooling Down")
	if not _can_pay_cost(skill.stamina_cost):
		return _fail("No Stamina")
	if skill.effect_scene == null:
		return _fail("Skill Missing Effect")

	_pay_cost(skill.stamina_cost)
	cooldowns[slot_index] = skill.cooldown

	var effect := skill.effect_scene.instantiate() as Node
	var effect_parent := get_tree().current_scene
	if effect_parent == null:
		effect_parent = get_tree().root
	effect_parent.add_child(effect)
	if effect is Node2D:
		(effect as Node2D).global_position = _get_owner_origin()
	if effect.has_method("activate"):
		var cast_result = effect.activate(_make_context(skill))
		if cast_result is bool and not cast_result:
			cooldowns[slot_index] = 0.0
			var failure_message := "Skill Failed"
			var effect_failure = effect.get("last_failure")
			if effect_failure is String and not effect_failure.is_empty():
				failure_message = effect_failure
			return _fail(failure_message)

	skill_cast_started.emit(skill.display_name)
	return true

func _ensure_slot_data() -> void:
	while skills.size() < SLOT_COUNT:
		skills.append(null)
	if skills.size() > SLOT_COUNT:
		skills.resize(SLOT_COUNT)
	while cooldowns.size() < SLOT_COUNT:
		cooldowns.append(0.0)
	if cooldowns.size() > SLOT_COUNT:
		cooldowns.resize(SLOT_COUNT)
	while active_slots.size() < SLOT_COUNT:
		active_slots.append(false)
	if active_slots.size() > SLOT_COUNT:
		active_slots.resize(SLOT_COUNT)
	while _auto_cast_timers.size() < SLOT_COUNT:
		_auto_cast_timers.append(0.0)
	if _auto_cast_timers.size() > SLOT_COUNT:
		_auto_cast_timers.resize(SLOT_COUNT)

func _can_pay_cost(cost: float) -> bool:
	if cost <= 0.0:
		return true
	var owner := get_parent()
	if owner != null and owner.has_method("can_spend_stamina"):
		return owner.can_spend_stamina(cost)
	return false

func _pay_cost(cost: float) -> void:
	if cost <= 0.0:
		return
	var owner := get_parent()
	if owner != null and owner.has_method("spend_stamina"):
		owner.spend_stamina(cost)

func _get_owner_origin() -> Vector2:
	var owner := get_parent()
	if owner != null and owner.has_method("get_skill_origin"):
		return owner.get_skill_origin()
	if owner is Node2D:
		return (owner as Node2D).global_position
	return Vector2.ZERO

func _get_owner_direction() -> Vector2:
	var owner := get_parent()
	if owner != null and owner.has_method("get_skill_direction"):
		return owner.get_skill_direction()
	return Vector2.DOWN

func _make_context(skill: SkillDefinition) -> Dictionary:
	var origin := _get_owner_origin()
	var direction := _get_owner_direction()
	return {
		"caster": get_parent(),
		"origin": origin,
		"direction": direction,
		"target_position": origin + direction * skill.cast_range,
		"zone_range": _get_owner_transform_zone_range(skill.cast_range),
		"zone_size": _get_owner_transform_zone_size(),
		"skill": skill,
	}

func _get_owner_transform_zone_range(fallback: float) -> float:
	var owner := get_parent()
	if owner != null and "melee_range" in owner:
		return owner.melee_range
	return fallback

func _get_owner_transform_zone_size() -> Vector2:
	var owner := get_parent()
	if owner != null and "melee_size" in owner:
		return owner.melee_size
	return Vector2(54.0, 34.0)

func _fail(message: String) -> bool:
	skill_cast_failed.emit(message)
	return false
