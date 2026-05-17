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
	pass

func _configure_sparkles() -> void:
	pass

func _rebuild_moonlight_patches() -> void:
	pass
