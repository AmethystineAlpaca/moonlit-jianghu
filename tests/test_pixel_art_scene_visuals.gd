extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/World.tscn")
const TREE_SCENE := preload("res://scenes/world/placeholders/TreePlaceholder.tscn")
const CRATE_SCENE := preload("res://scenes/world/placeholders/BreakableCrate.tscn")
const PixelSurface := preload("res://scripts/world/PixelSurface.gd")

var failures := 0

func _initialize() -> void:
	await _test_world_surfaces_use_pixel_textures()
	await _test_normal_ground_is_soft_green()
	await _test_grassland_surface_is_opaque_green()
	await _test_grassland_generates_dense_tufts()
	await _test_grassland_tufts_bleed_past_region_edges()
	await _test_grassland_avoids_breakable_collision_shapes()
	_test_grass_tuft_texture_is_bushy()
	await _test_placeholder_obstacles_use_pixel_sprites()
	await _test_tree_placeholder_is_stone_obstacle()
	await _test_breakable_crate_uses_pixel_sprite()
	await _test_breakable_crate_renders_as_tree()
	quit(failures)

func _test_world_surfaces_use_pixel_textures() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame

	for node_name in ["Ground", "VerticalPath", "HorizontalPath", "VillageSquare"]:
		var surface := world.get_node(node_name)
		_assert_true(surface is TextureRect, "%s is a textured pixel surface" % node_name)
		if surface is TextureRect:
			_assert_true(surface.texture != null, "%s has a generated texture" % node_name)
			_assert_equal(surface.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST, "%s keeps crisp pixels" % node_name)

	world.free()

func _test_normal_ground_is_soft_green() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame

	var ground := world.get_node("Ground")
	_assert_true(ground is TextureRect, "normal ground is a textured surface")
	if ground is TextureRect:
		var image := (ground.texture as Texture2D).get_image()
		var sample := image.get_pixel(0, 0)
		_assert_true(sample.a >= 0.99, "normal ground is opaque")
		_assert_true(sample.g > sample.r and sample.g > sample.b, "normal ground base color is green-dominant")

	world.free()

func _test_placeholder_obstacles_use_pixel_sprites() -> void:
	var tree := TREE_SCENE.instantiate()
	root.add_child(tree)
	await process_frame

	var visual := tree.get_node("Visual")
	_assert_true(visual is Sprite2D, "placeholder visual is a sprite")
	if visual is Sprite2D:
		_assert_true(visual.texture != null, "placeholder sprite has a texture")
		_assert_equal(visual.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST, "placeholder sprite keeps crisp pixels")

	tree.free()

func _test_tree_placeholder_is_stone_obstacle() -> void:
	var tree := TREE_SCENE.instantiate()
	root.add_child(tree)
	await process_frame

	_assert_equal(tree.visual_style, "stone", "tree placeholder now renders as an immovable stone")
	_assert_true(not tree.is_in_group("breakables"), "tree placeholder remains non-breakable")
	_assert_true(not tree.has_method("shatter"), "tree placeholder has no shatter behavior")

	tree.free()

func _test_breakable_crate_uses_pixel_sprite() -> void:
	var crate := CRATE_SCENE.instantiate()
	root.add_child(crate)
	await process_frame

	var visual := crate.get_node("Visual")
	_assert_true(visual is Sprite2D, "crate visual is a sprite")
	if visual is Sprite2D:
		_assert_true(visual.texture != null, "crate sprite has a texture")
		_assert_equal(visual.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST, "crate sprite keeps crisp pixels")

	crate.free()

func _test_breakable_crate_renders_as_tree() -> void:
	var crate := CRATE_SCENE.instantiate()
	root.add_child(crate)
	await process_frame

	var visual := crate.get_node("Visual") as Sprite2D
	_assert_true(crate.is_in_group("breakables"), "tree-like breakable remains in breakables group")
	_assert_true(crate.has_method("shatter"), "tree-like breakable keeps shatter behavior")
	if visual != null and visual.texture != null:
		var image := visual.texture.get_image()
		var leaf_pixels := 0
		var trunk_pixels := 0
		for y in range(image.get_height()):
			for x in range(image.get_width()):
				var pixel := image.get_pixel(x, y)
				if pixel.g > pixel.r * 1.4 and pixel.g > pixel.b * 1.4 and pixel.a > 0.9:
					leaf_pixels += 1
				if pixel.r > pixel.g * 1.35 and pixel.g > pixel.b * 1.2 and pixel.a > 0.9:
					trunk_pixels += 1
		_assert_true(leaf_pixels >= 120, "breakable visual has a leafy green canopy")
		_assert_true(trunk_pixels >= 40, "breakable visual has a tree trunk")

	crate.free()

func _test_grassland_surface_is_opaque_green() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame

	for node_name in ["GrasslandNW", "GrasslandNE", "GrasslandSW", "GrasslandSE"]:
		var surface := world.get_node(node_name)
		_assert_true(surface is TextureRect, "%s is a textured grassland surface" % node_name)
		if surface is TextureRect:
			_assert_true(surface.texture != null, "%s has a generated texture" % node_name)
			_assert_equal(surface.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST, "%s keeps crisp pixels" % node_name)
			var image := (surface.texture as Texture2D).get_image()
			var sample := image.get_pixel(0, 0)
			_assert_true(sample.a >= 0.99, "%s is opaque instead of transparent" % node_name)
			_assert_true(sample.g > sample.r and sample.g > sample.b, "%s base color is green-dominant" % node_name)

	world.free()

func _test_grassland_generates_dense_tufts() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame

	var grassland := world.get_node("Grassland")
	var tufts := _count_sprite_descendants(grassland)
	_assert_true(tufts >= 240, "grassland generates dense tuft coverage")

	world.free()

func _test_grassland_tufts_bleed_past_region_edges() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame

	var grassland := world.get_node("Grassland")
	var region := _texture_rect_world_rect(world.get_node("GrasslandNW") as TextureRect)
	var bleed_rect := Rect2(region.position - Vector2(16.0, 16.0), region.size + Vector2(32.0, 32.0))
	var edge_tufts := 0

	for sprite in _collect_sprite_descendants(grassland):
		var pos := (sprite as Sprite2D).global_position
		if bleed_rect.has_point(pos) and not region.has_point(pos):
			edge_tufts += 1

	_assert_true(edge_tufts > 0, "grassland tufts bleed slightly past hard region edges")

	world.free()

func _test_grassland_avoids_breakable_collision_shapes() -> void:
	var parent := Node2D.new()
	root.add_child(parent)

	var region := PixelSurface.new()
	region.surface_kind = "grassland"
	region.position = Vector2(-30.0, -30.0)
	region.size = Vector2(60.0, 60.0)
	parent.add_child(region)

	var breakables := Node2D.new()
	breakables.name = "Breakables"
	parent.add_child(breakables)

	var crate := CRATE_SCENE.instantiate() as Node2D
	crate.position = Vector2.ZERO
	breakables.add_child(crate)

	var grassland := preload("res://scripts/world/Grassland.gd").new()
	grassland.cell_size = 10.0
	grassland.jitter = 0.0
	grassland.obstacle_padding = 0.0
	parent.add_child(grassland)
	await process_frame

	var crate_rect := Rect2(Vector2(-21.0, -21.0), Vector2(42.0, 42.0))
	for sprite in _collect_sprite_descendants(grassland):
		_assert_true(not _sprite_world_rect(sprite).intersects(crate_rect), "grass tuft footprint avoids breakable collision shape")

	parent.free()

func _test_grass_tuft_texture_is_bushy() -> void:
	var texture := PixelSurface.create_grass_tuft(Vector2i(18, 12), 4242)
	var image := texture.get_image()
	var occupied_columns := {}
	var colored_pixels := 0

	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			if color.a > 0.0:
				occupied_columns[x] = true
				colored_pixels += 1

	_assert_true(occupied_columns.size() >= 5, "generated grass tuft spreads across multiple columns")
	_assert_true(colored_pixels >= 18, "generated grass tuft has enough blade pixels to read as bushy")

func _texture_rect_world_rect(tr: TextureRect) -> Rect2:
	return Rect2(tr.global_position, tr.size)

func _count_sprite_descendants(node: Node) -> int:
	var count := 0
	if node is Sprite2D:
		count += 1
	for child in node.get_children():
		count += _count_sprite_descendants(child)
	return count

func _collect_sprite_descendants(node: Node) -> Array[Sprite2D]:
	var sprites: Array[Sprite2D] = []
	if node is Sprite2D:
		sprites.append(node as Sprite2D)
	for child in node.get_children():
		sprites.append_array(_collect_sprite_descendants(child))
	return sprites

func _sprite_world_rect(sprite: Sprite2D) -> Rect2:
	var texture := sprite.texture
	if texture == null:
		return Rect2(sprite.global_position, Vector2.ZERO)
	var scaled_size := Vector2(texture.get_width(), texture.get_height()) * sprite.scale.abs()
	var top_left := sprite.global_position - scaled_size * 0.5 + sprite.offset * sprite.scale
	return Rect2(top_left, scaled_size)

func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	failures += 1
	push_error(message)

func _assert_equal(actual, expected, message: String) -> void:
	if actual == expected:
		return
	failures += 1
	push_error("%s: expected %s, got %s" % [message, expected, actual])
