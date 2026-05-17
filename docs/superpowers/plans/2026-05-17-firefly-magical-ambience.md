# Firefly Magical Ambience Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a whole-map magical ambience layer built from static PNG firefly/sparkle assets, with code-driven motion, fluorescent glow readability, and stable performance.

**Architecture:** Keep the existing moonlit world setup in `World.gd`, but move the new ambience work into a dedicated `AmbientMagicController` scene/script. Use one lightweight background particle field for cheap map-wide coverage, a limited hero-firefly node layer for readable luminous insects, and a sparse sparkle layer for crystal-clear accents.

**Tech Stack:** Godot 4 GDScript, `GPUParticles2D`, `ParticleProcessMaterial`, `Sprite2D`, `CanvasItemMaterial`, existing headless SceneTree tests, imported PNG assets under `assets/xianxia/`.

---

### Task 1: Asset Contract And Ambience Tests

**Files:**
- Modify: `assets/xianxia/asset_manifest.json`
- Create: `tests/test_world_firefly_ambience.gd`

- [ ] **Step 1: Add the static VFX asset contract to the manifest**

Append these objects to the JSON array in `assets/xianxia/asset_manifest.json`:

```json
  ,
  {
    "name": "firefly_core.png",
    "scaled_size": [8, 8],
    "kind": "vfx"
  },
  {
    "name": "firefly_halo.png",
    "scaled_size": [24, 24],
    "kind": "vfx"
  },
  {
    "name": "crystal_sparkle.png",
    "scaled_size": [12, 12],
    "kind": "vfx"
  },
  {
    "name": "gleam_star.png",
    "scaled_size": [10, 10],
    "kind": "vfx"
  },
  {
    "name": "dot_variant_a.png",
    "scaled_size": [6, 6],
    "kind": "vfx"
  },
  {
    "name": "dot_variant_b.png",
    "scaled_size": [6, 6],
    "kind": "vfx"
  },
  {
    "name": "dot_variant_c.png",
    "scaled_size": [6, 6],
    "kind": "vfx"
  }
```

Asset guidance for the person generating them:

```text
firefly_core.png: small bright body, crisp center, pale aqua/white friendly
firefly_halo.png: soft round glow card, smooth falloff, no hard border
crystal_sparkle.png: thin crystalline flare, readable when tinted pale blue-white
gleam_star.png: tiny four-point or six-point sharp catchlight
dot_variant_a/b/c.png: subtle tiny shapes for the background drift field
```

- [ ] **Step 2: Write the failing ambience test file**

Create `tests/test_world_firefly_ambience.gd` with this content:

```gdscript
extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/World.tscn")
const REQUIRED_ASSET_PATHS := [
	"res://assets/xianxia/firefly_core.png",
	"res://assets/xianxia/firefly_halo.png",
	"res://assets/xianxia/crystal_sparkle.png",
	"res://assets/xianxia/gleam_star.png",
	"res://assets/xianxia/dot_variant_a.png",
	"res://assets/xianxia/dot_variant_b.png",
	"res://assets/xianxia/dot_variant_c.png",
]

var failures := 0

func _initialize() -> void:
	_test_required_ambience_assets_exist()
	await _test_world_creates_ambient_magic_controller()
	await _test_ambient_controller_has_background_layers()
	await _test_ambient_controller_spawns_hero_fireflies()
	await _test_ambient_controller_has_sparse_sparkle_layer()
	quit(failures)

func _test_required_ambience_assets_exist() -> void:
	for path in REQUIRED_ASSET_PATHS:
		_assert_true(ResourceLoader.exists(path), "required ambience asset exists: %s" % path)

func _test_world_creates_ambient_magic_controller() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame

	var controller := world.get_node_or_null("AmbientMagic")
	_assert_true(controller != null, "world creates AmbientMagic controller")
	if controller != null:
		_assert_true(controller is Node2D, "AmbientMagic controller is Node2D-based")

	world.free()

func _test_ambient_controller_has_background_layers() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame

	var controller := world.get_node_or_null("AmbientMagic")
	_assert_true(controller != null, "AmbientMagic controller exists for background layer test")
	if controller != null:
		for node_name in ["BackgroundDotsA", "BackgroundDotsB", "BackgroundDotsC", "HeroLayer", "SparkleLayer"]:
			_assert_true(controller.get_node_or_null(node_name) != null, "AmbientMagic has child %s" % node_name)

	world.free()

func _test_ambient_controller_spawns_hero_fireflies() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame
	await process_frame

	var controller := world.get_node_or_null("AmbientMagic")
	var hero_layer := controller.get_node_or_null("HeroLayer") if controller != null else null
	_assert_true(hero_layer is Node2D, "HeroLayer exists")
	if hero_layer is Node2D:
		_assert_true(hero_layer.get_child_count() >= 10, "hero layer spawns a readable number of fireflies")
		for child in hero_layer.get_children():
			_assert_true(child.get_node_or_null("Core") is Sprite2D, "hero firefly has Core sprite")
			_assert_true(child.get_node_or_null("Halo") is Sprite2D, "hero firefly has Halo sprite")

	world.free()

func _test_ambient_controller_has_sparse_sparkle_layer() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame

	var controller := world.get_node_or_null("AmbientMagic")
	var sparkle_layer := controller.get_node_or_null("SparkleLayer") if controller != null else null
	_assert_true(sparkle_layer is Node2D, "SparkleLayer exists")
	if sparkle_layer is Node2D:
		_assert_true(sparkle_layer.get_child_count() >= 4, "sparkle layer contains sparse accent nodes")
		_assert_true(sparkle_layer.get_child_count() <= 20, "sparkle layer stays sparse")

	world.free()

func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	failures += 1
	push_error(message)
```

- [ ] **Step 3: Run the new test to verify it fails**

Run:

```bash
/usr/local/bin/godot --headless --path . --script tests/test_world_firefly_ambience.gd
```

Expected: FAIL. The asset files do not exist yet, `World.gd` does not create an `AmbientMagic` controller, and no hero fireflies or sparkle nodes are present.

- [ ] **Step 4: Commit the test-first contract**

Run:

```bash
git add assets/xianxia/asset_manifest.json tests/test_world_firefly_ambience.gd
git commit -m "test: define firefly ambience asset and scene contract"
```

### Task 2: Ambient Controller Scaffold And World Wiring

**Files:**
- Create: `scripts/world/AmbientMagicController.gd`
- Create: `scenes/world/AmbientMagicController.tscn`
- Modify: `scripts/world/World.gd`
- Test: `tests/test_world_firefly_ambience.gd`

- [ ] **Step 1: Create the controller script scaffold**

Create `scripts/world/AmbientMagicController.gd` with this content:

```gdscript
extends Node2D

const HERO_FIREFLY_SCENE := preload("res://scenes/effects/HeroFirefly.tscn")

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
```

- [ ] **Step 2: Create the controller scene structure**

Create `scenes/world/AmbientMagicController.tscn` with this content:

```tscn
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/world/AmbientMagicController.gd" id="1_script"]

[node name="AmbientMagic" type="Node2D"]
z_index = 9
script = ExtResource("1_script")

[node name="BackgroundDotsA" type="GPUParticles2D" parent="."]
z_index = 0

[node name="BackgroundDotsB" type="GPUParticles2D" parent="."]
z_index = 1

[node name="BackgroundDotsC" type="GPUParticles2D" parent="."]
z_index = 2

[node name="HeroLayer" type="Node2D" parent="."]
z_index = 3

[node name="SparkleLayer" type="Node2D" parent="."]
z_index = 4
```

- [ ] **Step 3: Wire the controller into the world**

At the top of `scripts/world/World.gd`, add:

```gdscript
const AMBIENT_MAGIC_SCENE := preload("res://scenes/world/AmbientMagicController.tscn")
```

Then add this helper near `_setup_night_atmosphere()`:

```gdscript
func _ensure_ambient_magic() -> void:
	if get_node_or_null("AmbientMagic") != null:
		return
	var ambience := AMBIENT_MAGIC_SCENE.instantiate() as Node2D
	add_child(ambience)
```

And call it in `_ready()` immediately after `_setup_night_atmosphere()`:

```gdscript
	_setup_night_atmosphere()
	_ensure_ambient_magic()
```

- [ ] **Step 4: Run the ambience test again**

Run:

```bash
/usr/local/bin/godot --headless --path . --script tests/test_world_firefly_ambience.gd
```

Expected: still FAIL. The controller should now exist and expose the correct child nodes, but the asset existence checks should still fail until the PNGs are added, and the hero/sparkle count assertions should fail because the rebuild methods are still empty.

- [ ] **Step 5: Commit the scaffold**

Run:

```bash
git add scripts/world/AmbientMagicController.gd scenes/world/AmbientMagicController.tscn scripts/world/World.gd
git commit -m "feat: scaffold ambient magic controller"
```

### Task 3: Background Drift Field

**Files:**
- Modify: `scripts/world/AmbientMagicController.gd`
- Test: `tests/test_world_firefly_ambience.gd`

- [ ] **Step 1: Implement background particle configuration**

Replace `_configure_background_layers()` in `scripts/world/AmbientMagicController.gd` with:

```gdscript
func _configure_background_layers() -> void:
	_configure_background_particle(background_a, DOT_TEXTURE_PATHS[0], 44, 3.8, 0.16, 0.65, Color(0.62, 0.92, 1.0, 0.55), 0)
	_configure_background_particle(background_b, DOT_TEXTURE_PATHS[1], 34, 4.6, 0.18, 0.72, Color(0.54, 0.84, 1.0, 0.45), 137)
	_configure_background_particle(background_c, DOT_TEXTURE_PATHS[2], 26, 5.4, 0.20, 0.82, Color(0.82, 0.95, 1.0, 0.32), 271)

func _configure_background_particle(
	node: GPUParticles2D,
	texture_path: String,
	amount: int,
	lifetime: float,
	scale_min: float,
	scale_max: float,
	tint: Color,
	seed_value: int
) -> void:
	var texture := _load_texture(texture_path)
	if texture == null:
		node.emitting = false
		return

	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(spawn_half_size.x, spawn_half_size.y, 0.0)
	process.direction = Vector3(0.0, -1.0, 0.0)
	process.spread = 22.0
	process.initial_velocity_min = 2.0
	process.initial_velocity_max = 5.0
	process.gravity = Vector3(0.0, -1.2, 0.0)
	process.scale_min = scale_min
	process.scale_max = scale_max
	process.angular_velocity_min = -8.0
	process.angular_velocity_max = 8.0
	process.turbulence_enabled = true
	process.turbulence_noise_scale = 1.2
	process.turbulence_influence_min = 0.03
	process.turbulence_influence_max = 0.08

	node.texture = texture
	node.amount = amount
	node.lifetime = lifetime
	node.randomness = 1.0
	node.explosiveness = 0.0
	node.local_coords = false
	node.process_material = process
	node.modulate = tint
	node.visibility_rect = Rect2(-spawn_half_size, spawn_half_size * 2.0)
	node.use_fixed_seed = true
	node.seed = seed_value
	node.emitting = true
```

- [ ] **Step 2: Slightly strengthen the world glow to support the new field**

In `_setup_night_atmosphere()` inside `scripts/world/World.gd`, change:

```gdscript
	env.glow_intensity = 0.35
	env.glow_bloom = 0.08
```

to:

```gdscript
	env.glow_intensity = 0.42
	env.glow_bloom = 0.10
```

- [ ] **Step 3: Run the ambience test**

Run:

```bash
/usr/local/bin/godot --headless --path . --script tests/test_world_firefly_ambience.gd
```

Expected: still FAIL until the PNGs are present and hero/sparkle layers are populated, but the controller should now have configured background particle nodes that can be inspected in the running scene.

- [ ] **Step 4: Manually verify map-wide drift**

Run:

```bash
/usr/local/bin/godot --path .
```

Expected: once the dot PNGs exist, the whole map should show a faint, low-contrast, cyan-blue drift field with depth variation, without overwhelming the player or terrain.

- [ ] **Step 5: Commit the background layer**

Run:

```bash
git add scripts/world/AmbientMagicController.gd scripts/world/World.gd
git commit -m "feat: add whole-map background drift field"
```

### Task 4: Readable Hero Fireflies

**Files:**
- Create: `scripts/effects/HeroFirefly.gd`
- Create: `scenes/effects/HeroFirefly.tscn`
- Modify: `scripts/world/AmbientMagicController.gd`
- Test: `tests/test_world_firefly_ambience.gd`

- [ ] **Step 1: Create the hero firefly behavior script**

Create `scripts/effects/HeroFirefly.gd` with this content:

```gdscript
extends Node2D

@export var drift_velocity: Vector2 = Vector2(6.0, -2.0)
@export var wander_radius: Vector2 = Vector2(18.0, 10.0)
@export var pulse_speed: float = 1.35
@export var pulse_offset: float = 0.0
@export var alpha_min: float = 0.35
@export var alpha_max: float = 0.92
@export var scale_min: float = 0.82
@export var scale_max: float = 1.18
@export var rotation_speed: float = 0.18

var _anchor_position: Vector2
var _time: float = 0.0

@onready var halo: Sprite2D = $Halo
@onready var core: Sprite2D = $Core

func setup(core_texture: Texture2D, halo_texture: Texture2D, start_position: Vector2, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	_anchor_position = start_position
	position = start_position
	core.texture = core_texture
	halo.texture = halo_texture
	drift_velocity = Vector2(rng.randf_range(-5.5, 5.5), rng.randf_range(-3.0, 1.5))
	wander_radius = Vector2(rng.randf_range(10.0, 28.0), rng.randf_range(6.0, 16.0))
	pulse_speed = rng.randf_range(0.75, 1.55)
	pulse_offset = rng.randf_range(0.0, TAU)
	alpha_min = rng.randf_range(0.25, 0.42)
	alpha_max = rng.randf_range(0.78, 0.96)
	scale_min = rng.randf_range(0.78, 0.92)
	scale_max = rng.randf_range(1.08, 1.28)
	rotation_speed = rng.randf_range(-0.28, 0.28)

func _process(delta: float) -> void:
	_time += delta
	_anchor_position += drift_velocity * delta
	var orbit := Vector2(
		sin(_time * pulse_speed + pulse_offset) * wander_radius.x,
		cos(_time * (pulse_speed * 0.8) + pulse_offset) * wander_radius.y
	)
	position = _anchor_position + orbit
	rotation += rotation_speed * delta

	var pulse := 0.5 + 0.5 * sin(_time * pulse_speed + pulse_offset)
	var alpha := lerpf(alpha_min, alpha_max, pulse)
	var scale_value := lerpf(scale_min, scale_max, pulse)
	core.modulate.a = alpha
	halo.modulate.a = alpha * 0.65
	scale = Vector2.ONE * scale_value
```

- [ ] **Step 2: Create the hero firefly scene**

Create `scenes/effects/HeroFirefly.tscn` with this content:

```tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/effects/HeroFirefly.gd" id="1_script"]

[sub_resource type="CanvasItemMaterial" id="1_additive"]
blend_mode = 1

[node name="HeroFirefly" type="Node2D"]
script = ExtResource("1_script")

[node name="Halo" type="Sprite2D" parent="."]
material = SubResource("1_additive")
centered = true

[node name="Core" type="Sprite2D" parent="."]
centered = true
z_index = 1
```

- [ ] **Step 3: Populate the hero layer from the controller**

Replace `_rebuild_hero_fireflies()` in `scripts/world/AmbientMagicController.gd` with:

```gdscript
func _rebuild_hero_fireflies() -> void:
	for child in hero_layer.get_children():
		child.queue_free()

	var core_texture := _load_texture(FIREFLY_CORE_PATH)
	var halo_texture := _load_texture(FIREFLY_HALO_PATH)
	if core_texture == null or halo_texture == null:
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = 9017
	for i in range(hero_firefly_target_count):
		var firefly := HERO_FIREFLY_SCENE.instantiate()
		var start := Vector2(
			rng.randf_range(-spawn_half_size.x, spawn_half_size.x),
			rng.randf_range(-spawn_half_size.y, spawn_half_size.y)
		)
		hero_layer.add_child(firefly)
		firefly.call("setup", core_texture, halo_texture, start, 5000 + i * 37)

	for cluster_index in range(2):
		var cluster_center := Vector2(
			rng.randf_range(-spawn_half_size.x * 0.85, spawn_half_size.x * 0.85),
			rng.randf_range(-spawn_half_size.y * 0.85, spawn_half_size.y * 0.85)
		)
		for local_index in range(3):
			var firefly := HERO_FIREFLY_SCENE.instantiate()
			var offset := Vector2(rng.randf_range(-26.0, 26.0), rng.randf_range(-18.0, 18.0))
			hero_layer.add_child(firefly)
			firefly.call("setup", core_texture, halo_texture, cluster_center + offset, 8000 + cluster_index * 100 + local_index)
```

- [ ] **Step 4: Run the ambience test**

Run:

```bash
/usr/local/bin/godot --headless --path . --script tests/test_world_firefly_ambience.gd
```

Expected: the controller and hero-layer assertions should now pass once `firefly_core.png` and `firefly_halo.png` exist. The sparkle-layer assertions may still fail until the next task adds the crystal accent nodes.

- [ ] **Step 5: Commit the hero-firefly layer**

Run:

```bash
git add scripts/effects/HeroFirefly.gd scenes/effects/HeroFirefly.tscn scripts/world/AmbientMagicController.gd
git commit -m "feat: add readable hero firefly ambience layer"
```

### Task 5: Crystal Sparkles, Final Tuning, And Verification

**Files:**
- Modify: `scripts/world/AmbientMagicController.gd`
- Modify: `tests/test_world_firefly_ambience.gd`
- Test: `tests/test_pixel_art_scene_visuals.gd`
- Test: `tests/test_world_firefly_ambience.gd`

- [ ] **Step 1: Add sparse sparkle nodes with code-driven shimmer**

Replace `_rebuild_sparkles()` in `scripts/world/AmbientMagicController.gd` with:

```gdscript
func _rebuild_sparkles() -> void:
	for child in sparkle_layer.get_children():
		child.queue_free()

	var sparkle_texture := _load_texture(CRYSTAL_SPARKLE_PATH)
	var gleam_texture := _load_texture(GLEAM_STAR_PATH)
	if sparkle_texture == null or gleam_texture == null:
		return

	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var rng := RandomNumberGenerator.new()
	rng.seed = 14421

	for i in range(sparkle_target_count):
		var sprite := Sprite2D.new()
		sprite.texture = sparkle_texture if i % 2 == 0 else gleam_texture
		sprite.material = additive
		sprite.position = Vector2(
			rng.randf_range(-spawn_half_size.x, spawn_half_size.x),
			rng.randf_range(-spawn_half_size.y, spawn_half_size.y)
		)
		sprite.scale = Vector2.ONE * rng.randf_range(0.65, 1.15)
		sprite.modulate = Color(0.82, 0.94, 1.0, rng.randf_range(0.18, 0.42))
		sprite.rotation = rng.randf_range(-PI, PI)
		sprite.set_meta("pulse_speed", rng.randf_range(0.45, 1.10))
		sprite.set_meta("pulse_offset", rng.randf_range(0.0, TAU))
		sparkle_layer.add_child(sprite)
```

Then add this `_process()` method to the same file:

```gdscript
func _process(delta: float) -> void:
	var time := Time.get_ticks_msec() * 0.001
	for sprite in sparkle_layer.get_children():
		if not sprite is Sprite2D:
			continue
		var pulse_speed := float(sprite.get_meta("pulse_speed", 0.75))
		var pulse_offset := float(sprite.get_meta("pulse_offset", 0.0))
		var pulse := 0.5 + 0.5 * sin(time * pulse_speed + pulse_offset)
		sprite.modulate.a = lerpf(0.12, 0.42, pulse)
		sprite.scale = Vector2.ONE * lerpf(0.72, 1.18, pulse)
		sprite.rotation += delta * 0.18
```

- [ ] **Step 2: Tighten the test so it checks the finished sparkle layer**

In `tests/test_world_firefly_ambience.gd`, inside `_test_ambient_controller_has_sparse_sparkle_layer()`, add this assertion:

```gdscript
		for child in sparkle_layer.get_children():
			_assert_true(child is Sprite2D, "sparkle layer uses lightweight Sprite2D accents")
```

- [ ] **Step 3: Run the ambience tests and existing world-visual regression test**

Run:

```bash
/usr/local/bin/godot --headless --path . --script tests/test_world_firefly_ambience.gd
/usr/local/bin/godot --headless --path . --script tests/test_pixel_art_scene_visuals.gd
```

Expected: PASS. The ambience controller exists, required asset paths resolve, hero fireflies and sparse sparkles spawn, and the earlier pixel-world visuals still pass.

- [ ] **Step 4: Perform final visual tuning in the live game**

Run:

```bash
/usr/local/bin/godot --path .
```

Tune only these exported values until the result feels shipped-quality:

```text
hero_firefly_target_count: 12 -> 18
sparkle_target_count: 6 -> 10
BackgroundDotsA/B/C amount values
halo alpha ceiling
glow_intensity
glow_bloom
```

Success criteria for the manual pass:

```text
the ambience is obvious at a glance
the whole map feels enchanted, not just the center
fireflies read as bright living light with soft halos
crystal accents stay sparse and crisp
the scene remains readable during movement and combat
```

- [ ] **Step 5: Commit the final ambience pass**

Run:

```bash
git add scripts/world/AmbientMagicController.gd tests/test_world_firefly_ambience.gd scripts/world/World.gd
git commit -m "feat: add firefly magical ambience system"
```
