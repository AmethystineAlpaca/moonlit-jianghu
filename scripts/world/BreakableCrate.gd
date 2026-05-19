extends StaticBody2D

@onready var visual: Sprite2D = $Visual

const BREAKABLE_TREE_TEXTURE := preload("res://assets/xianxia/breakable_tree.png")
const TREE_SWAY_SHADER := preload("res://resources/shaders/grass_wind.gdshader")

var is_broken: bool = false
var break_timer: float = 0.0

func _ready() -> void:
	add_to_group("breakables")
	visual.texture = BREAKABLE_TREE_TEXTURE
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var mat := ShaderMaterial.new()
	mat.shader = TREE_SWAY_SHADER
	mat.set_shader_parameter("wind_strength", 1.0)
	mat.set_shader_parameter("wind_speed", 0.7)
	mat.set_shader_parameter("wind_frequency", 0.5)
	mat.set_shader_parameter("wind_dir", Vector2(1.0, 0.0))
	visual.material = mat

func _process(delta: float) -> void:
	if not is_broken:
		return

	break_timer += delta
	var t := clampf(break_timer / 0.18, 0.0, 1.0)
	scale = Vector2.ONE.lerp(Vector2(1.45, 1.45), t)
	modulate.a = 1.0 - t

	if break_timer >= 0.18:
		queue_free()

func shatter() -> void:
	if is_broken:
		return

	is_broken = true
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	visual.modulate = Color(1.0, 0.82, 0.36, 1.0)
