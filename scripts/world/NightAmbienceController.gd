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
	env.set_glow_level(0, 0.85)
	env.set_glow_level(1, 0.95)
	env.set_glow_level(2, 0.90)
	night_environment.environment = env

func _configure_overlay() -> void:
	pass

func _configure_vignette() -> void:
	pass

func _configure_fireflies() -> void:
	pass

func _configure_sparkles() -> void:
	pass

func _rebuild_moonlight_patches() -> void:
	pass
