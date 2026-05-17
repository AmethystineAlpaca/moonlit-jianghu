extends StaticBody2D

@onready var visual: Sprite2D = $Visual

var is_broken: bool = false
var break_timer: float = 0.0

func _ready() -> void:
	add_to_group("breakables")
	visual.texture = _build_texture()
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

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

func _build_texture() -> Texture2D:
	var size := 42
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var trunk := Color(0.38, 0.20, 0.08, 1.0)
	var trunk_light := Color(0.60, 0.36, 0.15, 1.0)
	var leaf := Color(0.10, 0.46, 0.18, 1.0)
	var leaf_dark := Color(0.05, 0.28, 0.11, 1.0)
	var leaf_light := Color(0.24, 0.66, 0.26, 1.0)

	_fill_rect(image, Rect2i(18, 22, 7, 16), trunk)
	_fill_rect(image, Rect2i(20, 23, 2, 11), trunk_light)
	_fill_rect(image, Rect2i(8, 14, 26, 15), leaf_dark)
	_fill_rect(image, Rect2i(12, 8, 20, 18), leaf)
	_fill_rect(image, Rect2i(16, 4, 13, 12), leaf)
	_fill_rect(image, Rect2i(11, 19, 8, 7), leaf_light)
	_fill_rect(image, Rect2i(25, 15, 6, 7), leaf_light)
	return ImageTexture.create_from_image(image)

func _fill_rect(image: Image, rect: Rect2i, fill: Color) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			image.set_pixel(x, y, fill)
