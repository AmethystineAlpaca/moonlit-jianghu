@tool
extends TextureRect

@export_enum("dirt", "grassland", "grass", "path", "stone") var surface_kind: String = "dirt"
@export var tile_size: int = 32

func _ready() -> void:
	_generate_texture()

func _notification(what: int) -> void:
	if what == NOTIFICATION_EDITOR_PRE_SAVE:
		_generate_texture()

func _generate_texture() -> void:
	if surface_kind == "grassland":
		var size: int = maxi(8, tile_size)
		var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
		var palette := _get_palette()
		for y in range(size):
			for x in range(size):
				var noise := int(x * 19 + y * 29 + (x / 3) * 11 + (y / 5) * 17) % 13
				var color := palette[0]
				if noise == 0 or noise == 1:
					color = palette[1]
				elif noise == 2:
					color = palette[2]
				image.set_pixel(x, y, color)

		_draw_surface_details(image)
		texture = ImageTexture.create_from_image(image)
		stretch_mode = TextureRect.STRETCH_TILE
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		return

	var size: int = maxi(8, tile_size)
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var palette := _get_palette()

	for y in range(size):
		for x in range(size):
			var noise := int(x * 17 + y * 31 + (x / 4) * 7 + (y / 4) * 13) % 11
			var color := palette[0]
			if noise == 0:
				color = palette[1]
			elif noise == 1 or noise == 2:
				color = palette[2]
			image.set_pixel(x, y, color)

	_draw_surface_details(image)

	texture = ImageTexture.create_from_image(image)
	stretch_mode = TextureRect.STRETCH_TILE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _get_palette() -> Array[Color]:
	match surface_kind:
		"grassland":
			return [
				Color(0.20, 0.45, 0.20, 1.0),
				Color(0.25, 0.52, 0.24, 1.0),
				Color(0.14, 0.34, 0.16, 1.0),
			]
		"path":
			return [
				Color(0.24, 0.17, 0.10, 1.0),
				Color(0.32, 0.23, 0.14, 1.0),
				Color(0.14, 0.09, 0.05, 1.0),
			]
		"stone":
			return [
				Color(0.42, 0.41, 0.36, 1.0),
				Color(0.55, 0.53, 0.46, 1.0),
				Color(0.28, 0.29, 0.27, 1.0),
			]
		"dirt":
			return [
				Color(0.20, 0.45, 0.20, 1.0),
				Color(0.25, 0.52, 0.24, 1.0),
				Color(0.14, 0.34, 0.16, 1.0),
			]
		_:
			return [
				Color(0.17, 0.43, 0.22, 1.0),
				Color(0.24, 0.54, 0.27, 1.0),
				Color(0.09, 0.29, 0.16, 1.0),
			]

func _draw_surface_details(image: Image) -> void:
	match surface_kind:
		"path":
			_draw_path_pebbles(image)
		"stone":
			_draw_stone_tiles(image)
		"dirt":
			_draw_field_specks(image)
		_:
			_draw_grass_clumps(image)

func _draw_grass_clumps(image: Image) -> void:
	var dark := Color(0.07, 0.25, 0.13, 1.0)
	var light := Color(0.32, 0.62, 0.31, 1.0)
	for origin in [Vector2i(5, 7), Vector2i(22, 15), Vector2i(14, 25)]:
		image.set_pixel(origin.x, origin.y, light)
		image.set_pixel(origin.x + 1, origin.y - 1, light)
		image.set_pixel(origin.x + 2, origin.y, dark)
		image.set_pixel(origin.x + 1, origin.y + 1, dark)

func _draw_path_pebbles(image: Image) -> void:
	var pebble := Color(0.12, 0.08, 0.04, 1.0)
	for origin in [Vector2i(6, 8), Vector2i(18, 5), Vector2i(25, 22), Vector2i(11, 27)]:
		image.set_pixel(origin.x, origin.y, pebble)
		image.set_pixel(origin.x + 1, origin.y, pebble)

func _draw_dirt_specks(image: Image) -> void:
	var dark := Color(0.30, 0.21, 0.12, 1.0)
	var light := Color(0.60, 0.48, 0.32, 1.0)
	for origin in [Vector2i(4, 9), Vector2i(20, 6), Vector2i(27, 20)]:
		image.set_pixel(origin.x, origin.y, dark)
	for origin in [Vector2i(13, 14), Vector2i(8, 24)]:
		image.set_pixel(origin.x, origin.y, light)

func _draw_field_specks(image: Image) -> void:
	var dark := Color(0.12, 0.30, 0.13, 1.0)
	var light := Color(0.32, 0.58, 0.28, 1.0)
	for origin in [Vector2i(4, 9), Vector2i(20, 6), Vector2i(27, 20)]:
		image.set_pixel(origin.x, origin.y, dark)
	for origin in [Vector2i(13, 14), Vector2i(8, 24)]:
		image.set_pixel(origin.x, origin.y, light)

func _draw_stone_tiles(image: Image) -> void:
	var line := Color(0.23, 0.24, 0.22, 1.0)
	for x in range(0, image.get_width(), 16):
		for y in range(image.get_height()):
			image.set_pixel(x, y, line)
	for y in range(0, image.get_height(), 16):
		for x in range(image.get_width()):
			image.set_pixel(x, y, line)

static func create_grass_tuft(size: Vector2i, seed_value: int) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var dark := Color(0.06, 0.24, 0.12, 1.0)
	var mid := Color(0.20, 0.50, 0.22, 1.0)
	var light := Color(0.42, 0.72, 0.34, 1.0)
	var blade_count := rng.randi_range(5, 8)
	var center := size.x / 2

	for _i in range(blade_count):
		var base_x := clampi(center + rng.randi_range(-size.x / 3, size.x / 3), 1, size.x - 2)
		var lean := rng.randi_range(-2, 2)
		var height := rng.randi_range(int(size.y * 0.45), int(size.y * 0.85))
		var top_y := size.y - height
		for y in range(top_y, size.y):
			var t := float(y - top_y) / maxf(1.0, float(size.y - top_y - 1))
			var x := clampi(base_x + int(roundf(lerpf(float(lean), 0.0, t))), 0, size.x - 1)
			var c := mid
			if y == top_y:
				c = light
			elif y >= size.y - 2:
				c = dark
			image.set_pixel(x, y, c)
			# 2px wide below tip for a chunkier, less jagged blade
			if y > top_y and x + 1 < size.x:
				image.set_pixel(x + 1, y, dark if c == dark else mid)

	for x in range(maxi(0, center - size.x / 3), mini(size.x, center + size.x / 3 + 1)):
		image.set_pixel(x, size.y - 1, dark)

	return ImageTexture.create_from_image(image)
