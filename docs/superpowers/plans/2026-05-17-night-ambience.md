# Night Ambience Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a whole-map moonlit night ambience state for `World` with screen-space tinting, vignette, glow, fireflies, blue sparkles, moonlight patches, and local character lights without repainting the map.

**Architecture:** Introduce a dedicated `NightAmbienceController` scene/script owned by `World` so night-state environment layers stay centralized and reversible. Keep world mood layers in the controller, keep gameplay readability lights in actor scenes, and verify the result with focused headless SceneTree tests.

**Tech Stack:** Godot 4 GDScript, `CanvasModulate`, `WorldEnvironment`, `ColorRect`, `TextureRect`, `GPUParticles2D`, `ParticleProcessMaterial`, `PointLight2D`, existing headless tests under `tests/`, imported PNG assets under `assets/xianxia/pixel_night_assets/`.

---

## File Structure

- `scripts/world/World.gd`
  Owns world startup. Replace the inlined night-atmosphere construction with creation of the dedicated controller and a simple “night state enabled” handoff.

- `scenes/world/NightAmbienceController.tscn`
  Scene container for all world-owned night layers: glow environment, world particle layers, moonlight patches, and screen-space overlay/vignette.

- `scripts/world/NightAmbienceController.gd`
  Creates/configures the night ambience node tree, loads the four selected textures, exposes tuning values, and guards missing-asset cases.

- `scenes/player/Player.tscn`
  Hosts `PlayerLight` and `WeaponLight` so the player remains readable when the mood darkens.

- `scenes/enemies/BasicEnemy.tscn`
  Hosts `EnemyAccentLight` so major enemies do not sink into the grass.

- `tests/test_world_firefly_ambience.gd`
  Expand from the earlier ambience contract into the main structural test for night ambience layers, asset usage, and world/UI separation.

- `tests/test_player_effect_hosts.gd`
  Add assertions that the player scene owns the expected night local light nodes.

### Task 1: Lock The Night Ambience Test Contract

**Files:**
- Modify: `tests/test_world_firefly_ambience.gd`
- Modify: `tests/test_player_effect_hosts.gd`

- [ ] **Step 1: Rewrite the world ambience test around the new four-asset contract**

Replace `tests/test_world_firefly_ambience.gd` with this content:

```gdscript
extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/World.tscn")
const REQUIRED_ASSET_PATHS := [
	"res://assets/xianxia/pixel_night_assets/firefly_dot.png",
	"res://assets/xianxia/pixel_night_assets/sparkle_blue.png",
	"res://assets/xianxia/pixel_night_assets/moonlight_patch.png",
	"res://assets/xianxia/pixel_night_assets/light_circle.png",
]

var failures := 0

func _initialize() -> void:
	_test_required_night_assets_exist()
	await _test_world_creates_night_ambience_controller()
	await _test_controller_owns_expected_layer_groups()
	await _test_screen_fx_stays_outside_hud_canvas_layer()
	await _test_particle_and_patch_layers_are_populated()
	await _test_world_keeps_glow_environment_under_night_ambience()
	quit(failures)

func _test_required_night_assets_exist() -> void:
	for path in REQUIRED_ASSET_PATHS:
		_assert_true(ResourceLoader.exists(path), "required night ambience asset exists: %s" % path)

func _test_world_creates_night_ambience_controller() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame

	var ambience := world.get_node_or_null("NightAmbience")
	_assert_true(ambience is Node2D, "world creates NightAmbience controller")

	world.free()

func _test_controller_owns_expected_layer_groups() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame

	var ambience := world.get_node_or_null("NightAmbience")
	_assert_true(ambience != null, "NightAmbience exists for layer ownership test")
	if ambience != null:
		for path in [
			"NightEnvironment",
			"WorldEffects",
			"WorldEffects/FireflyParticles",
			"WorldEffects/SparkleParticles",
			"WorldEffects/MoonlightPatches",
			"ScreenFx",
			"ScreenFx/NightOverlay",
			"ScreenFx/Vignette",
		]:
			_assert_true(ambience.get_node_or_null(path) != null, "NightAmbience has %s" % path)

	world.free()

func _test_screen_fx_stays_outside_hud_canvas_layer() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame

	var hud := world.get_node_or_null("Hud")
	var overlay := world.get_node_or_null("NightAmbience/ScreenFx/NightOverlay")
	var vignette := world.get_node_or_null("NightAmbience/ScreenFx/Vignette")
	_assert_true(hud is CanvasLayer, "HUD remains a CanvasLayer")
	if hud != null:
		_assert_true(not hud.is_ancestor_of(overlay), "NightOverlay is not parented under HUD")
		_assert_true(not hud.is_ancestor_of(vignette), "Vignette is not parented under HUD")

	world.free()

func _test_particle_and_patch_layers_are_populated() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame
	await process_frame

	var fireflies := world.get_node_or_null("NightAmbience/WorldEffects/FireflyParticles") as GPUParticles2D
	var sparkles := world.get_node_or_null("NightAmbience/WorldEffects/SparkleParticles") as GPUParticles2D
	var patches := world.get_node_or_null("NightAmbience/WorldEffects/MoonlightPatches") as Node2D
	_assert_true(fireflies != null, "firefly layer exists")
	_assert_true(sparkles != null, "sparkle layer exists")
	_assert_true(patches != null, "moonlight patch layer exists")
	if fireflies != null:
		_assert_true(fireflies.amount >= 40, "firefly layer is visibly populated")
		_assert_true(fireflies.emitting, "firefly layer emits in night state")
	if sparkles != null:
		_assert_true(sparkles.amount >= 12, "sparkle layer is visibly populated")
		_assert_true(sparkles.amount < fireflies.amount, "sparkle layer stays sparser than fireflies")
	if patches != null:
		_assert_true(patches.get_child_count() >= 3, "moonlight patches create visible breakup")
		_assert_true(patches.get_child_count() <= 6, "moonlight patches stay sparse")

	world.free()

func _test_world_keeps_glow_environment_under_night_ambience() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame

	var world_env := world.get_node_or_null("NightAmbience/NightEnvironment") as WorldEnvironment
	_assert_true(world_env != null, "NightEnvironment exists")
	if world_env != null and world_env.environment != null:
		_assert_true(world_env.environment.glow_enabled, "night environment enables glow")
		_assert_true(world_env.environment.glow_intensity >= 0.35, "night glow intensity is meaningful")

	world.free()

func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	failures += 1
	push_error(message)
```

- [ ] **Step 2: Extend the player scene host test for local night lights**

Append this test to `tests/test_player_effect_hosts.gd`:

```gdscript
func _test_player_has_night_readability_lights() -> void:
	var player := PLAYER_SCENE.instantiate()
	root.add_child(player)
	await process_frame

	_assert_true(player.get_node_or_null("PlayerLight") is PointLight2D, "player scene has PlayerLight")
	_assert_true(player.get_node_or_null("Sword/WeaponLight") is PointLight2D, "player sword has WeaponLight")

	player.free()
```

Also update `_initialize()` so it runs the new test:

```gdscript
func _initialize() -> void:
	await _test_player_attack_effects_work_without_current_scene()
	await _test_player_afterimage_does_not_use_invalid_interval_callback_chain()
	await _test_player_has_night_readability_lights()
	quit(failures)
```

- [ ] **Step 3: Run the focused tests to verify the new contract fails first**

Run:

```bash
/usr/local/bin/godot --headless --path . --script tests/test_world_firefly_ambience.gd
/usr/local/bin/godot --headless --path . --script tests/test_player_effect_hosts.gd
```

Expected:

- `test_world_firefly_ambience.gd` fails because `NightAmbience`, `ScreenFx`, and the new particle/patch layers do not exist yet
- `test_player_effect_hosts.gd` fails because `PlayerLight` and `WeaponLight` are not in `Player.tscn` yet

- [ ] **Step 4: Commit the failing contract**

Run:

```bash
git add tests/test_world_firefly_ambience.gd tests/test_player_effect_hosts.gd
git commit -m "test: define night ambience scene contract"
```

### Task 2: Scaffold The Night Ambience Controller And World Wiring

**Files:**
- Create: `scripts/world/NightAmbienceController.gd`
- Create: `scenes/world/NightAmbienceController.tscn`
- Modify: `scripts/world/World.gd`
- Test: `tests/test_world_firefly_ambience.gd`

- [ ] **Step 1: Create the controller script scaffold**

Create `scripts/world/NightAmbienceController.gd` with this initial structure:

```gdscript
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
```

- [ ] **Step 2: Create the scene container for the controller**

Create `scenes/world/NightAmbienceController.tscn` with this content:

```tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/world/NightAmbienceController.gd" id="1_script"]

[node name="NightAmbience" type="Node2D"]
script = ExtResource("1_script")

[node name="NightEnvironment" type="WorldEnvironment" parent="."]

[node name="WorldEffects" type="Node2D" parent="."]

[node name="FireflyParticles" type="GPUParticles2D" parent="WorldEffects"]
position = Vector2(0, 0)
z_index = 12

[node name="SparkleParticles" type="GPUParticles2D" parent="WorldEffects"]
position = Vector2(0, 0)
z_index = 13

[node name="MoonlightPatches" type="Node2D" parent="WorldEffects"]
z_index = 3

[node name="ScreenFx" type="CanvasLayer" parent="."]
layer = 5

[node name="NightOverlay" type="ColorRect" parent="ScreenFx"]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2

[node name="Vignette" type="TextureRect" parent="ScreenFx"]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
```

- [ ] **Step 3: Replace the inlined night setup in `World.gd` with controller instantiation**

Update the constant and `_ready()`/helper methods in `scripts/world/World.gd`:

```gdscript
const NIGHT_AMBIENCE_SCENE := preload("res://scenes/world/NightAmbienceController.tscn")
const AMBIENT_MAGIC_SCENE := preload("res://scenes/world/AmbientMagicController.tscn")
```

```gdscript
func _ready() -> void:
	add_to_group("world")
	chest_rng.randomize()
	_spawn_random_breakables()
	_spawn_random_trees()
	_regenerate_grassland()
	_build_path_grid()
	spawn_timer = initial_spawn_interval
	chest_spawn_timer = chest_spawn_interval
	_try_spawn_enemy()
	_ensure_night_ambience()
	_ensure_ambient_magic()
	_add_obstacle_shadows()
```

```gdscript
func _ensure_night_ambience() -> void:
	if get_node_or_null("NightAmbience") != null:
		return
	var ambience := NIGHT_AMBIENCE_SCENE.instantiate() as Node2D
	add_child(ambience)
	if ambience.has_method("apply_world_bounds"):
		ambience.call("apply_world_bounds", map_half_size)
```

Delete the old `_setup_night_atmosphere()` function completely so there is only one source of truth for night setup.

- [ ] **Step 4: Run the world ambience test and make it pass at the scaffold level**

Run:

```bash
/usr/local/bin/godot --headless --path . --script tests/test_world_firefly_ambience.gd
```

Expected:

- still failing on particle counts and patch population
- passing on `NightAmbience`, `ScreenFx`, `NightOverlay`, `Vignette`, and `NightEnvironment` existence

- [ ] **Step 5: Commit the scaffold wiring**

Run:

```bash
git add scripts/world/World.gd scripts/world/NightAmbienceController.gd scenes/world/NightAmbienceController.tscn
git commit -m "feat: scaffold world night ambience controller"
```

### Task 3: Implement Overlay, Vignette, And Glow Tuning

**Files:**
- Modify: `scripts/world/NightAmbienceController.gd`
- Test: `tests/test_world_firefly_ambience.gd`

- [ ] **Step 1: Configure the screen-space night overlay**

Add this method to `scripts/world/NightAmbienceController.gd`:

```gdscript
func _configure_overlay() -> void:
	night_overlay.color = overlay_color
	night_overlay.material = null
```

- [ ] **Step 2: Add a simple generated vignette texture so the center stays readable**

Add these methods to `scripts/world/NightAmbienceController.gd`:

```gdscript
func _configure_vignette() -> void:
	vignette.color = Color.WHITE
	var texture := _build_vignette_texture(512, 512)
	vignette.texture = texture
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
			image.set_pixel(x, y, Color(0.02, 0.05, 0.10, alpha))
	return ImageTexture.create_from_image(image)
```

Make sure `Vignette` is a `TextureRect` in `scenes/world/NightAmbienceController.tscn`:

```tscn
[node name="Vignette" type="TextureRect" parent="ScreenFx"]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
```

- [ ] **Step 3: Verify the glow environment values are centralized in the controller**

Finish `_configure_environment()` in `scripts/world/NightAmbienceController.gd` so it contains the final values below:

```gdscript
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
```

- [ ] **Step 4: Run the ambience test to verify the mood layers pass**

Run:

```bash
/usr/local/bin/godot --headless --path . --script tests/test_world_firefly_ambience.gd
```

Expected:

- overlay/vignette/glow assertions pass
- particle and patch population assertions still fail

- [ ] **Step 5: Commit the mood-layer tuning**

Run:

```bash
git add scripts/world/NightAmbienceController.gd scenes/world/NightAmbienceController.tscn
git commit -m "feat: add night overlay vignette and glow tuning"
```

### Task 4: Add Fireflies, Sparkles, And Moonlight Patches

**Files:**
- Modify: `scripts/world/NightAmbienceController.gd`
- Test: `tests/test_world_firefly_ambience.gd`

- [ ] **Step 1: Configure the firefly particle layer**

Add this method to `scripts/world/NightAmbienceController.gd`:

```gdscript
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
		Color(0.95, 0.92, 0.42, 0.0),
		Color(0.92, 0.96, 0.48, 0.95),
		Color(0.62, 0.88, 0.42, 0.0)
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
```

- [ ] **Step 2: Configure the sparkle particle layer**

Add this method to `scripts/world/NightAmbienceController.gd`:

```gdscript
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
		Color(0.58, 0.88, 1.0, 0.0),
		Color(0.66, 0.94, 1.0, 0.85),
		Color(0.82, 0.97, 1.0, 0.0)
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
```

- [ ] **Step 3: Populate the moonlight patch layer**

Add this method to `scripts/world/NightAmbienceController.gd`:

```gdscript
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
```

- [ ] **Step 4: Run the ambience test and make the layer population checks pass**

Run:

```bash
/usr/local/bin/godot --headless --path . --script tests/test_world_firefly_ambience.gd
```

Expected: PASS. The world should now create the populated firefly, sparkle, and moonlight patch layers expected by the contract.

- [ ] **Step 5: Commit the world effect layers**

Run:

```bash
git add scripts/world/NightAmbienceController.gd
git commit -m "feat: add night particles and moonlight patches"
```

### Task 5: Add Player Local Night Lights

**Files:**
- Modify: `scenes/player/Player.tscn`
- Test: `tests/test_player_effect_hosts.gd`

- [ ] **Step 1: Add the player body light to `Player.tscn`**

Add this node under the player root in `scenes/player/Player.tscn`:

```tscn
[ext_resource type="Texture2D" path="res://assets/xianxia/pixel_night_assets/light_circle.png" id="4_night_light"]
```

```tscn
[node name="PlayerLight" type="PointLight2D" parent="."]
position = Vector2(0, -2)
texture = ExtResource("4_night_light")
texture_scale = 0.85
color = Color(0.74, 0.88, 1.0, 1)
energy = 0.42
blend_mode = 1
range_item_cull_mask = 1
shadow_enabled = false
```

- [ ] **Step 2: Add the weapon accent light under the sword**

Add this node under `Sword` in `scenes/player/Player.tscn`:

```tscn
[node name="WeaponLight" type="PointLight2D" parent="Sword"]
position = Vector2(0, 20)
texture = ExtResource("4_night_light")
texture_scale = 0.45
color = Color(0.68, 0.92, 1.0, 1)
energy = 0.68
blend_mode = 1
range_item_cull_mask = 1
shadow_enabled = false
```

- [ ] **Step 3: Run the player host test and verify it passes**

Run:

```bash
/usr/local/bin/godot --headless --path . --script tests/test_player_effect_hosts.gd
```

Expected: PASS. Existing attack-effect assertions stay green and the new local-light assertions pass.

- [ ] **Step 4: Commit the player light host changes**

Run:

```bash
git add scenes/player/Player.tscn tests/test_player_effect_hosts.gd
git commit -m "feat: add player night readability lights"
```

### Task 6: Add Enemy Accent Lights And Run Final Verification

**Files:**
- Modify: `scenes/enemies/BasicEnemy.tscn`
- Modify: `tests/test_world_firefly_ambience.gd`
- Test: `tests/test_world_firefly_ambience.gd`
- Test: `tests/test_player_effect_hosts.gd`

- [ ] **Step 1: Add the enemy accent light to `BasicEnemy.tscn`**

Add the same light texture resource to `scenes/enemies/BasicEnemy.tscn`:

```tscn
[ext_resource type="Texture2D" path="res://assets/xianxia/pixel_night_assets/light_circle.png" id="3_night_light"]
```

Add this node under the enemy root:

```tscn
[node name="EnemyAccentLight" type="PointLight2D" parent="."]
position = Vector2(0, -2)
texture = ExtResource("3_night_light")
texture_scale = 0.62
color = Color(0.56, 0.82, 1.0, 1)
energy = 0.26
blend_mode = 1
range_item_cull_mask = 1
shadow_enabled = false
```

- [ ] **Step 2: Extend the world ambience test to assert enemy light presence**

Append this helper test to `tests/test_world_firefly_ambience.gd`:

```gdscript
func _test_world_enemy_instances_have_accent_lights() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame

	var enemies := world.get_node_or_null("Enemies")
	_assert_true(enemies != null, "Enemies container exists")
	if enemies != null:
		world.call("_try_spawn_enemy")
		await process_frame
		var found_light := false
		for child in enemies.get_children():
			if child.get_node_or_null("EnemyAccentLight") is PointLight2D:
				found_light = true
				break
		_assert_true(found_light, "spawned enemies expose EnemyAccentLight")

	world.free()
```

Also call it from `_initialize()`:

```gdscript
func _initialize() -> void:
	_test_required_night_assets_exist()
	await _test_world_creates_night_ambience_controller()
	await _test_controller_owns_expected_layer_groups()
	await _test_screen_fx_stays_outside_hud_canvas_layer()
	await _test_particle_and_patch_layers_are_populated()
	await _test_world_keeps_glow_environment_under_night_ambience()
	await _test_world_enemy_instances_have_accent_lights()
	quit(failures)
```

- [ ] **Step 3: Run the final verification set**

Run:

```bash
/usr/local/bin/godot --headless --path . --script tests/test_world_firefly_ambience.gd
/usr/local/bin/godot --headless --path . --script tests/test_player_effect_hosts.gd
```

Expected: PASS on both scripts. The world-level night ambience contract and the player local-light host contract should now both be green.

- [ ] **Step 4: Commit the finishing pass**

Run:

```bash
git add scenes/enemies/BasicEnemy.tscn tests/test_world_firefly_ambience.gd
git commit -m "feat: finish night ambience readability pass"
```

## Self-Review

### Spec coverage

- Whole-map night ambience activation: covered by Tasks 2 through 4
- Global night overlay: covered by Task 3
- Vignette: covered by Task 3
- `WorldEnvironment` glow tuning: covered by Task 3
- Fireflies: covered by Task 4
- Blue sparkles: covered by Task 4
- Moonlight patches: covered by Task 4
- Player/weapon local lights: covered by Task 5
- Major enemy accent light: covered by Task 6
- HUD isolation: covered by Task 1 structural tests

### Placeholder scan

- No `TODO` / `TBD`
- Every task has exact file paths
- Every code-changing step includes concrete code
- Every verification step includes concrete commands and expected outcomes

### Type consistency

- `NightAmbience` is consistently the world controller node name
- `NightEnvironment`, `WorldEffects`, `ScreenFx`, `NightOverlay`, and `Vignette` are consistent across tests and implementation
- `PlayerLight`, `WeaponLight`, and `EnemyAccentLight` are consistent across tests and scenes
