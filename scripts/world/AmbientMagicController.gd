extends Node2D

# Task 2 scaffold: Task 4 adds the hero firefly scene at this path.
const HERO_FIREFLY_SCENE_PATH := "res://scenes/effects/HeroFirefly.tscn"

const FIREFLY_CORE_PATH := "res://assets/xianxia/firefly_core.png"
const FIREFLY_HALO_PATH := "res://assets/xianxia/firefly_halo.png"
const CRYSTAL_SPARKLE_PATH := "res://assets/xianxia/crystal_sparkle.png"
const GLEAM_STAR_PATH := "res://assets/xianxia/gleam_star.png"
const DOT_TEXTURE_PATHS := [
	"res://assets/xianxia/dot_variant_a.png",
	"res://assets/xianxia/dot_variant_b.png",
	"res://assets/xianxia/dot_variant_c.png",
]

@export var spawn_half_size: Vector2 = Vector2(680.0, 440.0)
@export var hero_firefly_target_count: int = 12
@export var sparkle_target_count: int = 8

@onready var background_a: GPUParticles2D = $BackgroundDotsA
@onready var background_b: GPUParticles2D = $BackgroundDotsB
@onready var background_c: GPUParticles2D = $BackgroundDotsC
@onready var hero_layer: Node2D = $HeroLayer
@onready var sparkle_layer: Node2D = $SparkleLayer

func _ready() -> void:
	_configure_spawn_bounds()
	_configure_background_layers()
	_rebuild_hero_fireflies()
	_rebuild_sparkles()

func _configure_spawn_bounds() -> void:
	var parent := get_parent()
	if parent != null and "map_half_size" in parent and parent.map_half_size is Vector2:
		spawn_half_size = parent.map_half_size

func _configure_background_layers() -> void:
	background_a.emitting = false
	background_b.emitting = false
	background_c.emitting = false

func _rebuild_hero_fireflies() -> void:
	for child in hero_layer.get_children():
		child.queue_free()

func _rebuild_sparkles() -> void:
	for child in sparkle_layer.get_children():
		child.queue_free()

func _load_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
