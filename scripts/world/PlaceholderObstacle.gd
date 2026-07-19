@tool
extends StaticBody2D

const TREE_SWAY_SHADER := preload("res://resources/shaders/grass_wind.gdshader")

@export var size: Vector2 = Vector2(96.0, 96.0)
@export var color: Color = Color(0.45, 0.35, 0.22, 1.0)
@export var collision_size: Vector2 = Vector2.ZERO
@export var collision_offset: Vector2 = Vector2.ZERO
@export_enum("house", "tree", "stone", "well", "wood", "fountain") var visual_style: String = "stone"
@export_file("*.png") var texture_path: String = ""
@export var texture_region: Rect2 = Rect2()
@export var visual_scale: Vector2 = Vector2.ONE
@export var anchor_visual_to_bottom: bool = false
@export_range(0.0, 0.95, 0.01) var passable_upper_ratio: float = 0.0
@export var is_boundary: bool = false

@onready var visual: Sprite2D = $Visual
@onready var backdrop: Sprite2D = $Backdrop if has_node("Backdrop") else null
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var canopy_visual: Sprite2D = $CanopyVisual if has_node("CanopyVisual") else null

const WORLD_Y_SORT_BASE := 500
const SPLIT_OVERLAP_PIXELS := 1
const HOUSE_BACKDROP_Z_OFFSET := 11
const HOUSE_VISUAL_Z_OFFSET := 12
const HOUSE_CANOPY_Z_OFFSET := 28

const DEFAULT_TEXTURE_BY_STYLE := {
	"house": "res://assets/xianxia/shrine.png",
	"tree": "res://assets/xianxia/tree.png",
	"stone": "res://assets/xianxia/rock.png",
	"well": "res://assets/xianxia/rock.png",
	"wood": "res://assets/xianxia/rock.png",
	"fountain": "res://assets/xianxia/rock.png",
}

func _ready() -> void:
	var resolved_collision_size := collision_size
	if resolved_collision_size == Vector2.ZERO:
		resolved_collision_size = size

	var texture := _resolve_texture()
	_apply_visual_texture(texture)

	if is_boundary:
		var shape := RectangleShape2D.new()
		shape.size = resolved_collision_size
		collision_shape.shape = shape
	else:
		var w := resolved_collision_size.x
		var h := resolved_collision_size.y
		var shape := CapsuleShape2D.new()
		shape.radius = min(w, h) * 0.5
		shape.height = max(w, h)
		collision_shape.rotation = 0.0 if h >= w else PI * 0.5
		collision_shape.shape = shape
	collision_shape.position = collision_offset

func _process(_delta: float) -> void:
	_update_visual_layering()

func _apply_visual_texture(texture: Texture2D) -> void:
	if texture == null:
		return
	if canopy_visual != null and passable_upper_ratio > 0.0:
		_apply_split_tree_texture(texture)
		return

	visual.texture = texture
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.centered = true
	visual.scale = visual_scale
	visual.position = Vector2.ZERO
	visual.z_as_relative = false
	if anchor_visual_to_bottom:
		visual.position.y = -texture.get_height() * visual_scale.y * 0.5
	if visual_style == "tree":
		visual.material = _make_tree_sway_material()
	else:
		visual.material = null
	if canopy_visual != null:
		canopy_visual.visible = false
		canopy_visual.material = null
	_update_house_backdrop(texture.get_width(), texture.get_height())
	_update_visual_layering()

func _apply_split_tree_texture(texture: Texture2D) -> void:
	var source_image := texture.get_image()
	var width := source_image.get_width()
	var height := source_image.get_height()
	var split_y := clampi(roundi(height * passable_upper_ratio), 1, height - 1)
	var top_end := mini(height, split_y + SPLIT_OVERLAP_PIXELS)
	var bottom_start := maxi(0, split_y - SPLIT_OVERLAP_PIXELS)

	visual.texture = _make_split_image_texture(source_image, Rect2i(0, bottom_start, width, height - bottom_start))
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.centered = true
	visual.scale = visual_scale
	visual.z_as_relative = false
	visual.position = Vector2.ZERO
	if anchor_visual_to_bottom:
		visual.position.y = -height * visual_scale.y * 0.5
	visual.material = _make_tree_sway_material() if visual_style == "tree" else null

	canopy_visual.texture = _make_split_image_texture(source_image, Rect2i(0, 0, width, top_end))
	canopy_visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	canopy_visual.centered = true
	canopy_visual.scale = visual_scale
	canopy_visual.z_as_relative = false
	canopy_visual.position = visual.position
	canopy_visual.visible = true
	canopy_visual.material = _make_tree_sway_material() if visual_style == "tree" else null
	_update_house_backdrop(width, height)
	_update_visual_layering()

func _update_visual_layering() -> void:
	var base_z := int(global_position.y) + WORLD_Y_SORT_BASE
	if backdrop != null and backdrop.visible:
		backdrop.z_index = base_z + HOUSE_BACKDROP_Z_OFFSET
	visual.z_index = base_z + _get_visual_z_offset()
	if canopy_visual != null and canopy_visual.visible:
		canopy_visual.z_index = base_z + _get_canopy_z_offset()

func _update_house_backdrop(texture_width: int, texture_height: int) -> void:
	if backdrop == null:
		return
	if visual_style != "house":
		backdrop.visible = false
		return

	backdrop.visible = true
	backdrop.texture = _make_house_backdrop_texture(visual.texture, texture_width, texture_height)
	backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	backdrop.centered = true
	backdrop.scale = visual_scale
	backdrop.position = visual.position
	backdrop.z_as_relative = false

func _make_house_backdrop_texture(source_texture: Texture2D, texture_width: int, texture_height: int) -> ImageTexture:
	var source_image := source_texture.get_image()
	var image := Image.create(texture_width, texture_height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var fill := Color(0.18, 0.11, 0.07, 0.98)
	for y in range(texture_height):
		for x in range(texture_width):
			if source_image.get_pixel(x, y).a > 0.02:
				image.set_pixel(x, y, fill)
	return ImageTexture.create_from_image(image)

func _get_visual_z_offset() -> int:
	return HOUSE_VISUAL_Z_OFFSET if visual_style == "house" else 0

func _get_canopy_z_offset() -> int:
	if visual_style == "house":
		return HOUSE_CANOPY_Z_OFFSET
	return 1

func _make_region_texture(texture: Texture2D, region: Rect2) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	return atlas

func _make_split_image_texture(source_image: Image, source_rect: Rect2i) -> ImageTexture:
	var image := Image.create(source_image.get_width(), source_image.get_height(), false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	image.blit_rect(source_image, source_rect, source_rect.position)
	return ImageTexture.create_from_image(image)

func _resolve_texture() -> Texture2D:
	var resolved_path := texture_path
	if resolved_path.is_empty() and DEFAULT_TEXTURE_BY_STYLE.has(visual_style):
		resolved_path = String(DEFAULT_TEXTURE_BY_STYLE[visual_style])
	if not resolved_path.is_empty():
		var texture := load(resolved_path) as Texture2D
		if texture != null:
			if texture_region.size.x > 0.0 and texture_region.size.y > 0.0:
				return _make_region_texture(texture, texture_region)
			return texture
	return _build_texture()

func _build_texture() -> Texture2D:
	var texture_size := Vector2i(maxi(8, roundi(size.x)), maxi(8, roundi(size.y)))
	var image := Image.create(texture_size.x, texture_size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))

	match visual_style:
		"house":
			_draw_house(image)
		"tree":
			_draw_tree(image)
		"well":
			_draw_well(image)
		"wood":
			_draw_wood_pile(image)
		"fountain":
			_draw_fountain(image)
		_:
			_draw_stone(image)

	return ImageTexture.create_from_image(image)

func _fill_rect(image: Image, rect: Rect2i, fill: Color) -> void:
	var min_x := clampi(rect.position.x, 0, image.get_width())
	var min_y := clampi(rect.position.y, 0, image.get_height())
	var max_x := clampi(rect.end.x, 0, image.get_width())
	var max_y := clampi(rect.end.y, 0, image.get_height())
	for y in range(min_y, max_y):
		for x in range(min_x, max_x):
			image.set_pixel(x, y, fill)

func _draw_house(image: Image) -> void:
	var w := image.get_width()
	var h := image.get_height()
	var wall := Color(0.67, 0.50, 0.32, 1.0)
	var wall_shadow := Color(0.42, 0.27, 0.16, 1.0)
	var roof := color
	var roof_dark := color.darkened(0.35)
	var roof_light := color.lightened(0.25)

	_fill_rect(image, Rect2i(w * 0.18, h * 0.36, w * 0.64, h * 0.46), wall_shadow)
	_fill_rect(image, Rect2i(w * 0.22, h * 0.40, w * 0.56, h * 0.36), wall)
	_fill_rect(image, Rect2i(w * 0.12, h * 0.18, w * 0.76, h * 0.28), roof_dark)
	_fill_rect(image, Rect2i(w * 0.18, h * 0.12, w * 0.64, h * 0.24), roof)
	_fill_rect(image, Rect2i(w * 0.26, h * 0.12, w * 0.48, maxi(3, h * 0.04)), roof_light)
	_fill_rect(image, Rect2i(w * 0.46, h * 0.56, w * 0.12, h * 0.20), Color(0.18, 0.10, 0.07, 1.0))
	_fill_rect(image, Rect2i(w * 0.30, h * 0.50, w * 0.10, h * 0.09), Color(0.18, 0.26, 0.30, 1.0))
	_fill_rect(image, Rect2i(w * 0.62, h * 0.50, w * 0.10, h * 0.09), Color(0.18, 0.26, 0.30, 1.0))

func _draw_tree(image: Image) -> void:
	var w := image.get_width()
	var h := image.get_height()
	var trunk := Color(0.35, 0.19, 0.09, 1.0)
	var leaf := color
	var leaf_dark := color.darkened(0.35)
	var leaf_light := color.lightened(0.18)

	_fill_rect(image, Rect2i(w * 0.43, h * 0.54, w * 0.14, h * 0.30), trunk)
	_fill_rect(image, Rect2i(w * 0.20, h * 0.20, w * 0.60, h * 0.42), leaf_dark)
	_fill_rect(image, Rect2i(w * 0.28, h * 0.10, w * 0.44, h * 0.46), leaf)
	_fill_rect(image, Rect2i(w * 0.34, h * 0.16, w * 0.18, h * 0.12), leaf_light)
	_fill_rect(image, Rect2i(w * 0.58, h * 0.30, w * 0.12, h * 0.12), leaf_light)

func _draw_stone(image: Image) -> void:
	var w := image.get_width()
	var h := image.get_height()
	var stone := color
	_fill_rect(image, Rect2i(w * 0.18, h * 0.28, w * 0.64, h * 0.44), stone.darkened(0.28))
	_fill_rect(image, Rect2i(w * 0.24, h * 0.22, w * 0.46, h * 0.40), stone)
	_fill_rect(image, Rect2i(w * 0.34, h * 0.28, w * 0.18, h * 0.10), stone.lightened(0.25))

func _draw_well(image: Image) -> void:
	var w := image.get_width()
	var h := image.get_height()
	_fill_rect(image, Rect2i(w * 0.18, h * 0.34, w * 0.64, h * 0.40), Color(0.26, 0.27, 0.24, 1.0))
	_fill_rect(image, Rect2i(w * 0.26, h * 0.28, w * 0.48, h * 0.30), Color(0.45, 0.45, 0.40, 1.0))
	_fill_rect(image, Rect2i(w * 0.34, h * 0.36, w * 0.32, h * 0.16), Color(0.10, 0.20, 0.24, 1.0))
	_fill_rect(image, Rect2i(w * 0.18, h * 0.18, w * 0.64, h * 0.08), Color(0.36, 0.18, 0.08, 1.0))

func _draw_wood_pile(image: Image) -> void:
	var w := image.get_width()
	var h := image.get_height()
	var dark := Color(0.25, 0.12, 0.05, 1.0)
	var mid := Color(0.55, 0.31, 0.12, 1.0)
	var light := Color(0.76, 0.52, 0.25, 1.0)
	for index in range(4):
		var y := int(h * 0.26) + index * int(max(4, h * 0.12))
		_fill_rect(image, Rect2i(w * 0.12, y, w * 0.76, max(4, h * 0.10)), dark)
		_fill_rect(image, Rect2i(w * 0.16, y, w * 0.66, max(2, h * 0.05)), mid)
		_fill_rect(image, Rect2i(w * 0.18, y + 1, w * 0.10, 2), light)

func _make_tree_sway_material() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = TREE_SWAY_SHADER
	mat.set_shader_parameter("wind_strength", 1.2)
	mat.set_shader_parameter("wind_speed", 0.65)
	mat.set_shader_parameter("wind_frequency", 0.4)
	mat.set_shader_parameter("wind_dir", Vector2(1.0, 0.0))
	return mat

func _draw_fountain(image: Image) -> void:
	var w := image.get_width()
	var h := image.get_height()
	_fill_rect(image, Rect2i(w * 0.16, h * 0.24, w * 0.68, h * 0.52), Color(0.27, 0.33, 0.34, 1.0))
	_fill_rect(image, Rect2i(w * 0.24, h * 0.30, w * 0.52, h * 0.34), Color(0.16, 0.37, 0.50, 1.0))
	_fill_rect(image, Rect2i(w * 0.36, h * 0.18, w * 0.28, h * 0.18), Color(0.56, 0.60, 0.56, 1.0))
	_fill_rect(image, Rect2i(w * 0.40, h * 0.38, w * 0.20, h * 0.08), Color(0.55, 0.78, 0.86, 1.0))
