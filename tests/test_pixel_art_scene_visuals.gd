extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/World.tscn")
const TREE_SCENE := preload("res://scenes/world/placeholders/TreePlaceholder.tscn")
const CRATE_SCENE := preload("res://scenes/world/placeholders/BreakableCrate.tscn")
const HOUSE_SCENE := preload("res://scenes/world/placeholders/HousePlaceholder.tscn")
const PixelSurface := preload("res://scripts/world/PixelSurface.gd")
const TREE_PLACEHOLDER_TEXTURE := preload("res://assets/art_v2/tree_jade.png")
const BREAKABLE_TREE_TEXTURE := preload("res://assets/art_v2/supply_crate.png")

var failures := 0

func _initialize() -> void:
	await _test_world_surfaces_use_pixel_textures()
	await _test_normal_ground_is_soft_green()
	await _test_grassland_avoids_breakable_collision_shapes()
	await _test_grassland_avoids_house_visual_bounds()
	_test_grass_tuft_texture_is_bushy()
	await _test_placeholder_obstacles_use_pixel_sprites()
	await _test_tree_placeholder_uses_large_passable_tree_texture()
	await _test_house_placeholder_uses_shrine_texture()
	await _test_world_uses_curated_house_layout()
	await _test_breakable_crate_uses_pixel_sprite()
	await _test_breakable_crate_renders_as_tree()
	quit(failures)

func _test_world_surfaces_use_pixel_textures() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame

	for node_name in ["Ground"]:
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
		_assert_true(ground.size.x >= 1440 and ground.size.y >= 960, "painted terrain covers the playable village")
		_assert_true(ground.material is ShaderMaterial, "terrain uses the shared restrained palette")

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

func _test_tree_placeholder_uses_large_passable_tree_texture() -> void:
	var tree := TREE_SCENE.instantiate()
	root.add_child(tree)
	await process_frame

	var visual := tree.get_node("Visual") as Sprite2D
	var canopy := tree.get_node_or_null("CanopyVisual") as Sprite2D
	_assert_equal(tree.visual_style, "tree", "tree placeholder uses tree visual style again")
	_assert_equal(tree.texture_path, "res://assets/art_v2/tree_jade.png", "tree placeholder pins the imported tree texture explicitly")
	_assert_true(absf(tree.visual_scale.y - 1.0) < 0.01, "tree visual scales to native pixel scale")
	_assert_equal(tree.collision_size, Vector2(24, 24), "tree collision covers only the lower third trunk area")
	_assert_equal(tree.collision_offset, Vector2(0, -12), "tree trunk collision is anchored to the bottom of the sprite")
	_assert_true(not tree.is_in_group("breakables"), "tree placeholder remains non-breakable")
	_assert_true(not tree.has_method("shatter"), "tree placeholder has no shatter behavior")
	if visual != null and visual.texture != null:
		_assert_true(visual.texture is ImageTexture, "tree trunk uses an alpha-separated pixel texture")
		if visual.texture is AtlasTexture:
			_assert_equal((visual.texture as AtlasTexture).atlas, TREE_PLACEHOLDER_TEXTURE, "tree trunk atlas comes from the imported tree sprite")
	_assert_true(canopy != null, "tree placeholder exposes a canopy overlay for behind-pass visuals")
	if canopy != null and canopy.texture != null:
		_assert_true(canopy.texture is ImageTexture, "tree canopy uses an alpha-separated pixel texture")
		if canopy.texture is AtlasTexture:
			_assert_equal((canopy.texture as AtlasTexture).atlas, TREE_PLACEHOLDER_TEXTURE, "tree canopy atlas comes from the imported tree sprite")

	tree.free()

func _test_house_placeholder_uses_shrine_texture() -> void:
	var house := HOUSE_SCENE.instantiate()
	root.add_child(house)
	await process_frame

	var visual := house.get_node("Visual") as Sprite2D
	_assert_equal(house.visual_style, "house", "house placeholder keeps house visual style")
	if visual != null and visual.texture != null:
		_assert_true(house.call("_resolve_texture").resource_path.ends_with("shrine.png"), "house placeholder uses shrine sprite")

	house.free()

func _test_world_uses_curated_house_layout() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame

	var buildings := world.get_node("Buildings")
	_assert_equal(buildings.get_child_count(), 6, "world uses the fixed six-house layout")
	for child in buildings.get_children():
		var house := child as Node2D
		var visual := house.get_node("Visual") as Sprite2D
		_assert_true(visual.texture is ImageTexture and house.call("_resolve_texture") is AtlasTexture, "%s separates the roof from its source atlas" % house.name)
		if house.call("_resolve_texture") is AtlasTexture:
			var atlas := house.call("_resolve_texture") as AtlasTexture
			_assert_true(atlas.atlas.resource_path.ends_with("houses.png"), "%s is sourced from houses.png" % house.name)

	world.free()

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
	_assert_true(crate.is_in_group("breakables"), "tree breakable remains in breakables group")
	_assert_true(crate.has_method("shatter"), "tree breakable keeps shatter behavior")
	if visual != null and visual.texture != null:
		_assert_equal(visual.texture, BREAKABLE_TREE_TEXTURE, "breakable crate uses the new supply-crate sprite")

	crate.free()

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

func _test_grassland_avoids_house_visual_bounds() -> void:
	var parent := Node2D.new()
	root.add_child(parent)

	var region := PixelSurface.new()
	region.surface_kind = "grassland"
	region.position = Vector2(-100.0, -80.0)
	region.size = Vector2(200.0, 160.0)
	parent.add_child(region)

	var buildings := Node2D.new()
	buildings.name = "Buildings"
	parent.add_child(buildings)

	var house := HOUSE_SCENE.instantiate() as Node2D
	house.position = Vector2.ZERO
	buildings.add_child(house)

	var grassland := preload("res://scripts/world/Grassland.gd").new()
	grassland.cell_size = 10.0
	grassland.jitter = 0.0
	grassland.obstacle_padding = 0.0
	grassland.edge_bleed = 0.0
	parent.add_child(grassland)
	await process_frame

	var house_rect := _sprite_world_rect(house.get_node("Visual") as Sprite2D)
	for sprite in _collect_sprite_descendants(grassland):
		_assert_true(not _sprite_world_rect(sprite).intersects(house_rect), "grass tuft footprint avoids house visual bounds")

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
