extends StaticBody2D

@onready var visual: Sprite2D = $Visual

const BREAKABLE_TREE_TEXTURE := preload("res://assets/art_v2/supply_crate.png")
const TREE_SWAY_SHADER := preload("res://resources/shaders/grass_wind.gdshader")

var is_broken: bool = false
var break_timer: float = 0.0

func _ready() -> void:
	add_to_group("breakables")
	visual.texture = BREAKABLE_TREE_TEXTURE
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.material = null
	visual.position = Vector2(0, -8)

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
