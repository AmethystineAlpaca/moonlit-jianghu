@tool
extends Node2D

const GRASS_SHADER := preload("res://resources/shaders/grass_glow.gdshader")
const PIXEL_SURFACE := preload("res://scripts/world/PixelSurface.gd")

@export var cell_size: float = 15.0
@export var jitter: float = 6.0
@export var short_tuft_size: Vector2i = Vector2i(18, 12)
@export var tall_tuft_size: Vector2i = Vector2i(18, 18)
@export var short_variants: int = 4
@export var tall_variants: int = 1
@export var back_layer_z: int = 0
@export var front_layer_z: int = 4
@export var obstacle_padding: float = 12.0
@export var region_padding: float = 4.0
@export var edge_bleed: float = 20.0
@export var edge_bleed_density: float = 1.0
@export var generate_seed: int = 1337

var _back_layer: Node2D
var _front_layer: Node2D
var _shared_material: ShaderMaterial

func _ready() -> void:
	_generate()

func _generate() -> void:
	_clear_layers()
	_ensure_layers()
	_build_material()
	var textures := _build_variant_textures()
	if textures.is_empty():
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = generate_seed
	var regions := _collect_grassland_regions()
	if regions.is_empty():
		return
	var exclusions := _collect_exclusion_rects()

	for region in regions:
		_populate_region(region, textures, exclusions, rng)

func _populate_region(region: Rect2, textures: Array, exclusions: Array[Rect2], rng: RandomNumberGenerator) -> void:
	var inset := Vector2(region_padding, region_padding)
	var inner := Rect2(region.position + inset, region.size - inset * 2.0)
	if inner.size.x <= 0.0 or inner.size.y <= 0.0:
		return

	var bleed := Vector2(edge_bleed, edge_bleed)
	var spawn_area := Rect2(inner.position - bleed, inner.size + bleed * 2.0)
	spawn_area = spawn_area.intersection(_get_map_bounds())
	if spawn_area.size.x <= 0.0 or spawn_area.size.y <= 0.0:
		return
	var x := spawn_area.position.x
	while x < spawn_area.end.x:
		var y := spawn_area.position.y
		while y < spawn_area.end.y:
			var pos := Vector2(
				x + rng.randf_range(-jitter, jitter),
				y + rng.randf_range(-jitter, jitter)
			)
			var texture: Texture2D = textures[rng.randi() % textures.size()]
			var tuft_scale := Vector2(rng.randf_range(0.9, 1.1), rng.randf_range(0.95, 1.1))
			var in_core := inner.has_point(pos)
			var in_soft_edge := spawn_area.has_point(pos) and rng.randf() < edge_bleed_density
			if (in_core or in_soft_edge) and not _rect_intersects_any(_get_tuft_rect(pos, texture, tuft_scale), exclusions):
				_spawn_tuft(pos, texture, tuft_scale, rng)
			y += cell_size
		x += cell_size

func _spawn_tuft(pos: Vector2, tex: Texture2D, tuft_scale: Vector2, rng: RandomNumberGenerator) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.material = _shared_material
	sprite.position = pos
	sprite.offset = Vector2(0.0, -float(tex.get_height()) * 0.5)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = tuft_scale
	if rng.randf() < 0.5:
		sprite.flip_h = true
	var parent := _front_layer if rng.randf() < 0.35 else _back_layer
	parent.add_child(sprite)

func _get_tuft_rect(pos: Vector2, tex: Texture2D, tuft_scale: Vector2) -> Rect2:
	var scaled_size := Vector2(tex.get_width(), tex.get_height()) * tuft_scale.abs()
	var offset := Vector2(0.0, -float(tex.get_height()) * 0.5) * tuft_scale
	return Rect2(pos - scaled_size * 0.5 + offset, scaled_size)

func _build_material() -> void:
	_shared_material = ShaderMaterial.new()
	_shared_material.shader = GRASS_SHADER
	_shared_material.set_shader_parameter("emission_strength", 0.55)
	_shared_material.set_shader_parameter("emission_color", Vector3(0.15, 0.78, 0.35))

func _build_variant_textures() -> Array:
	var arr: Array = []
	for i in range(maxi(0, short_variants)):
		arr.append(PIXEL_SURFACE.create_grass_tuft(short_tuft_size, generate_seed + 17 * (i + 1)))
	for i in range(maxi(0, tall_variants)):
		arr.append(PIXEL_SURFACE.create_grass_tuft(tall_tuft_size, generate_seed + 53 * (i + 1)))
	if arr.is_empty():
		arr.append(PIXEL_SURFACE.create_grass_tuft(short_tuft_size, generate_seed))
	return arr

func _ensure_layers() -> void:
	_back_layer = Node2D.new()
	_back_layer.name = "BackLayer"
	_back_layer.z_index = back_layer_z
	add_child(_back_layer)
	_front_layer = Node2D.new()
	_front_layer.name = "FrontLayer"
	_front_layer.z_index = front_layer_z
	add_child(_front_layer)

func _clear_layers() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

func _collect_grassland_regions() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	var parent := get_parent()
	if parent == null:
		return rects
	for child in parent.get_children():
		if not child is TextureRect:
			continue
		var kind := ""
		if "surface_kind" in child:
			kind = child.surface_kind
		elif child.has_meta("surface_kind"):
			kind = child.get_meta("surface_kind")
		if kind == "grassland":
			rects.append(_texture_rect_world_rect(child))
	return rects

func _collect_exclusion_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	var parent := get_parent()
	if parent == null:
		return rects
	for child in parent.get_children():
		_collect_rect_from(child, rects)
	return rects

func _collect_rect_from(node: Node, rects: Array[Rect2]) -> void:
	if node == self:
		return
	if node is TextureRect:
		_collect_texture_rect(node as TextureRect, rects)
		return
	if node.name in [&"Buildings", &"Landmarks", &"Trees", &"Boundaries", &"Breakables"]:
		for ch in node.get_children():
			_collect_rect_from(ch, rects)
		return
	if node is Node2D:
		_collect_obstacle_rect(node as Node2D, rects)

func _collect_texture_rect(tr: TextureRect, rects: Array[Rect2]) -> void:
	if not ("surface_kind" in tr):
		return
	var kind: String = tr.surface_kind
	if kind != "path" and kind != "stone":
		return
	var world_rect := _texture_rect_world_rect(tr)
	var pad := Vector2(obstacle_padding, obstacle_padding)
	rects.append(Rect2(world_rect.position - pad, world_rect.size + pad * 2.0))

func _texture_rect_world_rect(tr: TextureRect) -> Rect2:
	var top_left := Vector2(tr.offset_left, tr.offset_top)
	var size := Vector2(tr.offset_right - tr.offset_left, tr.offset_bottom - tr.offset_top)
	return Rect2(top_left, size)

func _get_map_bounds() -> Rect2:
	var half := Vector2(680.0, 440.0)
	var parent := get_parent()
	if parent != null and "map_half_size" in parent:
		var value = parent.map_half_size
		if value is Vector2:
			half = value
	return Rect2(-half, half * 2.0)

func _collect_obstacle_rect(n: Node2D, rects: Array[Rect2]) -> void:
	var rect := _get_node_exclusion_rect(n)
	if rect.size == Vector2.ZERO:
		return
	rects.append(rect)

func _get_node_exclusion_rect(n: Node2D) -> Rect2:
	var rect := Rect2()
	var has_rect := false

	var size := _get_node_size(n)
	if size != Vector2.ZERO:
		var half := size * 0.5
		rect = Rect2(n.global_position - half, size)
		has_rect = true

	var sprite_rect := _get_visual_sprite_rect(n)
	if sprite_rect.size != Vector2.ZERO:
		rect = sprite_rect if not has_rect else rect.merge(sprite_rect)
		has_rect = true

	if not has_rect:
		return Rect2()

	var pad := Vector2.ONE * obstacle_padding
	return Rect2(rect.position - pad, rect.size + pad * 2.0)

func _get_visual_sprite_rect(n: Node2D) -> Rect2:
	var sprite := n.get_node_or_null("Visual") as Sprite2D
	if sprite == null or sprite.texture == null:
		return Rect2()

	var size := Vector2(sprite.texture.get_width(), sprite.texture.get_height()) * sprite.scale.abs()
	var offset := sprite.offset * sprite.scale
	var top_left := sprite.global_position - size * 0.5 + offset
	return Rect2(top_left, size)

func _get_node_size(n: Node2D) -> Vector2:
	if "collision_size" in n:
		var cs = n.collision_size
		if cs is Vector2 and cs != Vector2.ZERO:
			return cs
	if "size" in n:
		var s = n.size
		if s is Vector2:
			return s
	var collision_shape := n.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape != null:
		if collision_shape.shape is RectangleShape2D:
			return (collision_shape.shape as RectangleShape2D).size
		if collision_shape.shape is CircleShape2D:
			var radius := (collision_shape.shape as CircleShape2D).radius
			return Vector2(radius * 2.0, radius * 2.0)
	return Vector2.ZERO

func _rect_intersects_any(rect: Rect2, rects: Array[Rect2]) -> bool:
	for r in rects:
		if rect.intersects(r):
			return true
	return false
