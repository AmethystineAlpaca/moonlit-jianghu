class_name SkillDefinition
extends Resource

enum TargetingMode {
	SELF,
	FORWARD,
	POINT,
	NEAREST_ENEMY
}

@export var display_name: String = "Empty"
@export var stamina_cost: float = 0.0
@export var cooldown: float = 0.0
@export var cast_range: float = 0.0
@export var targeting_mode: TargetingMode = TargetingMode.FORWARD
@export var effect_scene: PackedScene
