extends Node2D

const FIREFLY_TEXTURE := preload("res://assets/xianxia/pixel_night_assets/firefly_dot.png")
const SPARKLE_TEXTURE := preload("res://assets/xianxia/pixel_night_assets/sparkle_blue.png")
const MOONLIGHT_PATCH_TEXTURE := preload("res://assets/xianxia/pixel_night_assets/moonlight_patch.png")

const FIREFLY_LIGHT_COUNT := 9
const FIREFLY_LIGHT_TEXTURE_SCALE := 10.0

# 3×3 grid offsets in normalized [-1, 1] space
const GRID: Array = [
	Vector2(-1.0, -1.0), Vector2(0.0, -1.0), Vector2(1.0, -1.0),
	Vector2(-1.0,  0.0), Vector2(0.0,  0.0), Vector2(1.0,  0.0),
	Vector2(-1.0,  1.0), Vector2(0.0,  1.0), Vector2(1.0,  1.0),
]

@export var world_half_size: Vector2 = Vector2(680.0, 440.0)
@export var night_modulate_color: Color = Color(0.06, 0.08, 0.14)
@export var vignette_color: Color = Color(0.02, 0.05, 0.10, 0.0)
@export var firefly_amount: int = 88
@export var sparkle_amount: int = 30
@export var moonlight_patch_positions := [
	Vector2(-360.0, -180.0),
	Vector2(250.0, -210.0),
	Vector2(-250.0, 120.0),
	Vector2(320.0, 180.0),
]

@onready var night_environment: WorldEnvironment = $NightEnvironment
@onready var night_modulate: CanvasModulate = $NightModulate
@onready var firefly_lights: Node2D = $FireflyLights
@onready var world_effects: Node = $WorldEffects
@onready var firefly_particles: GPUParticles2D = $WorldEffects/FireflyParticles
@onready var sparkle_particles: GPUParticles2D = $WorldEffects/SparkleParticles
@onready var moonlight_patches: Node2D = $WorldEffects/MoonlightPatches
@onready var screen_fx: CanvasLayer = $ScreenFx
@onready var vignette: TextureRect = $ScreenFx/Vignette


func _ready() -> void:
	_configure_environment()
	_configure_night_modulate()
	_configure_vignette()
	_configure_fireflies()
	_configure_sparkles()
	_rebuild_moonlight_patches()
	_setup_firefly_lights()

func _process(delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var cam_pos := camera.get_screen_center_position()
	firefly_particles.position = cam_pos
	sparkle_particles.position = cam_pos

func apply_world_bounds(bounds: Vector2) -> void:
	world_half_size = bounds
	_configure_fireflies()
	_configure_sparkles()
	_rebuild_moonlight_patches()

func _configure_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_KEEP
	env.glow_enabled = true
	env.glow_intensity = 0.12
	env.glow_bloom = 0.10
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env.set_glow_level(0, 0.175)
	env.set_glow_level(1, 0.20)
	env.set_glow_level(2, 0.18)
	night_environment.environment = env

func _configure_night_modulate() -> void:
	night_modulate.color = night_modulate_color

func _configure_vignette() -> void:
	vignette.modulate = Color.WHITE
	vignette.texture = _build_vignette_texture(512, 512)
	vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vignette.stretch_mode = TextureRect.STRETCH_SCALE

func _build_vignette_texture(width: int, height: int) -> Texture2D:
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	var center := Vector2(width * 0.5, height * 0.5)
	var max_radius := minf(width, height) * 0.5
	for y in range(height):
		for x in range(width):
			var uv := Vector2(x, y)
			var dist := center.distance_to(uv) / max_radius
			var edge := clampf(pow(dist, 1.8), 0.0, 1.0)
			var alpha := smoothstep(0.40, 1.0, edge) * 0.60
			image.set_pixel(x, y, Color(vignette_color.r, vignette_color.g, vignette_color.b, alpha))
	return ImageTexture.create_from_image(image)

func _build_firefly_glow_texture() -> Texture2D:
	var sz := 48
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var half := sz * 0.5
	for y in range(sz):
		for x in range(sz):
			var dist := Vector2(x + 0.5, y + 0.5).distance_to(Vector2(half, half)) / half
			var core := exp(-dist * dist * 32.0)
			var halo := exp(-dist * dist * 3.6)
			var alpha := clampf(halo, 0.0, 1.0)
			var t := clampf(1.0 - core * 3.0, 0.0, 1.0)
			img.set_pixel(x, y, Color(
				lerpf(1.0, 0.88, t),
				lerpf(1.0, 0.93, t),
				lerpf(0.90, 0.16, t),
				alpha
			))
	return ImageTexture.create_from_image(img)

func _build_light_texture() -> Texture2D:
	var sz := 128
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var half := sz * 0.5
	for y in range(sz):
		for x in range(sz):
			var dist := Vector2(x + 0.5, y + 0.5).distance_to(Vector2(half, half)) / half
			# Flat Gaussian — gradual falloff so adjacent grid lights overlap evenly
			var alpha := clampf(exp(-dist * dist * 0.9), 0.0, 1.0)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	return ImageTexture.create_from_image(img)

func _configure_fireflies() -> void:
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(world_half_size.x, world_half_size.y, 0.0)
	material.direction = Vector3(0.0, -1.0, 0.0)
	material.spread = 55.0
	material.initial_velocity_min = 0.5
	material.initial_velocity_max = 1.6
	material.gravity = Vector3.ZERO
	material.scale_min = 0.039
	material.scale_max = 0.067
	material.turbulence_enabled = true
	material.turbulence_noise_strength = 1.4
	material.turbulence_noise_scale = 2.0
	material.turbulence_noise_speed_random = 0.3
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	ramp.colors = PackedColorArray(
		[
			Color(1.0, 1.0, 1.0, 0.0),
			Color(9.0, 11.0, 4.5, 1.0),
			Color(1.0, 1.0, 1.0, 0.0),
		]
	)
	var ramp_texture := GradientTexture1D.new()
	ramp_texture.gradient = ramp
	material.color_ramp = ramp_texture

	firefly_particles.texture = _build_firefly_glow_texture()
	firefly_particles.amount = firefly_amount
	firefly_particles.lifetime = 2.75
	firefly_particles.preprocess = 2.75
	firefly_particles.explosiveness = 0.0
	firefly_particles.randomness = 0.9
	firefly_particles.process_material = material
	firefly_particles.local_coords = false
	firefly_particles.emitting = true
	firefly_particles.modulate = Color(2.0, 1.96, 1.48, 1.0)

func _configure_sparkles() -> void:
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(world_half_size.x * 0.92, world_half_size.y * 0.88, 0.0)
	material.direction = Vector3(0.0, -1.0, 0.0)
	material.spread = 8.0
	material.initial_velocity_min = 0.2
	material.initial_velocity_max = 1.2
	material.gravity = Vector3(0.0, -0.2, 0.0)
	material.scale_min = 0.90
	material.scale_max = 1.35
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray(
		[
			Color(0.58, 0.88, 1.0, 0.0),
			Color(0.66, 0.94, 1.0, 0.70),
			Color(0.82, 0.97, 1.0, 0.0),
		]
	)
	var ramp_texture := GradientTexture1D.new()
	ramp_texture.gradient = ramp
	material.color_ramp = ramp_texture

	sparkle_particles.texture = SPARKLE_TEXTURE
	sparkle_particles.amount = sparkle_amount
	sparkle_particles.lifetime = 2.4
	sparkle_particles.preprocess = 2.4
	sparkle_particles.explosiveness = 0.0
	sparkle_particles.randomness = 1.0
	sparkle_particles.process_material = material
	sparkle_particles.local_coords = false
	sparkle_particles.emitting = false

func _rebuild_moonlight_patches() -> void:
	for child in moonlight_patches.get_children():
		child.queue_free()

	for index in range(moonlight_patch_positions.size()):
		var patch := Sprite2D.new()
		patch.name = "MoonlightPatch%s" % [index + 1]
		patch.texture = MOONLIGHT_PATCH_TEXTURE
		patch.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		patch.position = moonlight_patch_positions[index]
		patch.modulate = Color(0.72, 0.88, 1.0, 0.18)
		patch.scale = Vector2(1.35, 1.35) + Vector2.ONE * (0.12 * float(index % 2))
		moonlight_patches.add_child(patch)

const FIREFLY_LIGHT_COLORS: Array = [
	Color(1.0,  0.15, 0.05),  # 纯红
	Color(0.10, 0.25, 1.0 ),  # 纯蓝
	Color(1.0,  0.75, 0.05),  # 纯琥珀
	Color(0.65, 0.05, 1.0 ),  # 纯紫
	Color(0.05, 0.85, 1.0 ),  # 纯青
	Color(1.0,  0.40, 0.05),  # 纯橙
	Color(0.20, 0.10, 1.0 ),  # 深蓝
	Color(1.0,  0.10, 0.50),  # 玫红
	Color(0.05, 1.0,  0.55),  # 翠绿
]

func _setup_firefly_lights() -> void:
	var light_texture := _build_light_texture()
	for i in FIREFLY_LIGHT_COUNT:
		var light := PointLight2D.new()
		light.name = "FireflyLight%d" % (i + 1)
		light.texture = light_texture
		light.texture_scale = FIREFLY_LIGHT_TEXTURE_SCALE
		light.energy = 0.22
		light.color = FIREFLY_LIGHT_COLORS[i]
		light.blend_mode = Light2D.BLEND_MODE_ADD
		light.shadow_enabled = false
		light.position = GRID[i] * world_half_size * 0.75
		firefly_lights.add_child(light)


func toggle() -> void:
	visible = !visible
