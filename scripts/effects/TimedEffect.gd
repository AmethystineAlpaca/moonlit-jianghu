extends Node2D

@export var lifetime: float = 0.18
@export var start_scale: Vector2 = Vector2.ONE
@export var end_scale: Vector2 = Vector2(1.6, 1.6)

var elapsed: float = 0.0

func configure(effect_color: Color, new_start_scale: Vector2, new_end_scale: Vector2, new_lifetime: float) -> void:
	start_scale = new_start_scale
	end_scale = new_end_scale
	lifetime = maxf(new_lifetime, 0.01)
	elapsed = 0.0
	modulate = effect_color
	scale = start_scale

func _ready() -> void:
	scale = start_scale

func _process(delta: float) -> void:
	elapsed += delta
	var t := clampf(elapsed / lifetime, 0.0, 1.0)
	scale = start_scale.lerp(end_scale, t)
	modulate.a = 1.0 - t

	if elapsed >= lifetime:
		queue_free()
