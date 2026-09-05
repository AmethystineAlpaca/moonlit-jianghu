extends Node2D
var elapsed: float = 0.0
var light: PointLight2D

func _ready() -> void:
	z_index = int(position.y) + 500
	light = PointLight2D.new()
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(1, 0.9, 0.7, 0.8), Color(1, 0.7, 0.35, 0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 128
	texture.height = 128
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1, 0.5)
	light.texture = texture
	light.color = Color("ffd196")
	light.position = Vector2(0, -20)
	light.texture_scale = 1.25
	add_child(light)

func _process(delta: float) -> void:
	elapsed += delta
	var night := get_parent().get_node_or_null("NightAmbience") as CanvasItem
	light.visible = night != null and night.visible
	light.energy = 0.7 + 0.06 * sin(elapsed * 2.7 + position.x)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-4, -2, 8, 3), Color(0.02, 0.04, 0.05, 0.5))
	draw_rect(Rect2(-1, -27, 2, 27), Color("554233"))
	draw_rect(Rect2(-6, -26, 12, 2), Color("403a32"))
	draw_rect(Rect2(-4, -24, 8, 10), Color("ab593e"))
	draw_rect(Rect2(-2, -23, 4, 8), Color("f9ce85"))
	draw_rect(Rect2(-4, -14, 8, 2), Color("544436"))
	draw_line(Vector2(0, -12), Vector2(0, -8), Color("bc8050"), 1)
