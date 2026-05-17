extends Node2D

const FIREFLY_TEXTURE := preload("res://assets/xianxia/pixel_night_assets/firefly_dot.png")
const SPARKLE_TEXTURE := preload("res://assets/xianxia/pixel_night_assets/sparkle_blue.png")
const MOONLIGHT_PATCH_TEXTURE := preload("res://assets/xianxia/pixel_night_assets/moonlight_patch.png")

@export var world_half_size: Vector2 = Vector2(680.0, 440.0)
@export var overlay_color: Color = Color(0.02, 0.07, 0.16, 0.38)
@export var vignette_color: Color = Color(0.04, 0.09, 0.16, 0.0)
@export var firefly_amount: int = 52
@export var sparkle_amount: int = 18
@export var moonlight_patch_positions := [
	Vector2(-360.0, -180.0),
	Vector2(250.0, -210.0),
	Vector2(-250.0, 120.0),
	Vector2(320.0, 180.0),
]

@onready var night_environment: WorldEnvironment = $NightEnvironment
@onready var world_effects: Node2D = $WorldEffects
@onready var firefly_particles: GPUParticles2D = $WorldEffects/FireflyParticles
@onready var sparkle_particles: GPUParticles2D = $WorldEffects/SparkleParticles
@onready var moonlight_patches: Node2D = $WorldEffects/MoonlightPatches
@onready var screen_fx: CanvasLayer = $ScreenFx
@onready var night_overlay: ColorRect = $ScreenFx/NightOverlay
@onready var vignette: TextureRect = $ScreenFx/Vignette

func _ready() -> void:
	_configure_environment()
	_configure_overlay()
	_configure_vignette()
	_configure_fireflies()
	_configure_sparkles()
	_rebuild_moonlight_patches()

func apply_world_bounds(bounds: Vector2) -> void:
	world_half_size = bounds
	_configure_fireflies()
	_configure_sparkles()
	_rebuild_moonlight_patches()

func _configure_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_KEEP
	env.glow_enabled = true
	env.glow_intensity = 0.42
	env.glow_bloom = 0.12
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env.set_glow_level(0, 0.90)
	env.set_glow_level(1, 0.98)
	env.set_glow_level(2, 0.92)
	night_environment.environment = env

func _configure_overlay() -> void:
	night_overlay.color = overlay_color
	night_overlay.material = null

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
			var alpha := smoothstep(0.35, 1.0, edge) * 0.42
			image.set_pixel(x, y, Color(vignette_color.r, vignette_color.g, vignette_color.b, alpha))
	return ImageTexture.create_from_image(image)

func _configure_fireflies() -> void:
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(world_half_size.x, world_half_size.y, 0.0)
	material.direction = Vector3(0.0, -1.0, 0.0)
	material.spread = 32.0
	material.initial_velocity_min = 4.0
	material.initial_velocity_max = 11.0
	material.gravity = Vector3.ZERO
	material.scale_min = 0.55
	material.scale_max = 1.15
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray(
		[
			Color(0.95, 0.92, 0.42, 0.0),
			Color(0.92, 0.96, 0.48, 0.95),
			Color(0.62, 0.88, 0.42, 0.0),
		]
	)
	var ramp_texture := GradientTexture1D.new()
	ramp_texture.gradient = ramp
	material.color_ramp = ramp_texture

	firefly_particles.texture = FIREFLY_TEXTURE
	firefly_particles.amount = firefly_amount
	firefly_particles.lifetime = 6.0
	firefly_particles.randomness = 0.9
	firefly_particles.process_material = material
	firefly_particles.local_coords = false
	firefly_particles.emitting = true
	firefly_particles.modulate = Color(1.0, 0.98, 0.72, 0.95)

func _configure_sparkles() -> void:
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(world_half_size.x * 0.92, world_half_size.y * 0.88, 0.0)
	material.direction = Vector3(0.0, -1.0, 0.0)
	material.spread = 10.0
	material.initial_velocity_min = 1.0
	material.initial_velocity_max = 4.0
	material.gravity = Vector3(0.0, -1.0, 0.0)
	material.scale_min = 0.45
	material.scale_max = 0.90
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray(
		[
			Color(0.58, 0.88, 1.0, 0.0),
			Color(0.66, 0.94, 1.0, 0.85),
			Color(0.82, 0.97, 1.0, 0.0),
		]
	)
	var ramp_texture := GradientTexture1D.new()
	ramp_texture.gradient = ramp
	material.color_ramp = ramp_texture

	sparkle_particles.texture = SPARKLE_TEXTURE
	sparkle_particles.amount = sparkle_amount
	sparkle_particles.lifetime = 1.8
	sparkle_particles.randomness = 1.0
	sparkle_particles.process_material = material
	sparkle_particles.local_coords = false
	sparkle_particles.emitting = true
	sparkle_particles.modulate = Color(0.78, 0.94, 1.0, 0.90)

func _rebuild_moonlight_patches() -> void:
	for child in moonlight_patches.get_children():
		child.queue_free()

	for index in range(moonlight_patch_positions.size()):
		var patch := Sprite2D.new()
		patch.name = "MoonlightPatch%s" % [index + 1]
		patch.texture = MOONLIGHT_PATCH_TEXTURE
		patch.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		patch.position = moonlight_patch_positions[index]
		patch.modulate = Color(0.66, 0.84, 1.0, 0.18)
		patch.scale = Vector2(0.95, 0.95) + Vector2.ONE * (0.08 * float(index % 2))
		moonlight_patches.add_child(patch)
