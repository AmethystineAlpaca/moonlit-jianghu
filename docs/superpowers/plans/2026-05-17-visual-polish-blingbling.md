# Visual Polish — Blingbling Xianxia Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Layer glowing, translucent, fluorescent visual effects across the game in D→A→B→C priority order — moonlit environment, character glow accents, explosive combat feedback, and dramatic skill effects.

**Architecture:** All effects are procedural GDScript (no sprite sheets). Environment effects live in World.tscn / Grassland.gd. Character glow is a shader on existing Sprite2D body nodes. Combat effects extend the existing HitSpark/TimedEffect pattern. Skill effects enhance existing TransformSkillEffect and ProtectiveDivineLightEffect.

**Tech Stack:** Godot 4.6, GDScript, canvas_item shaders, GPUParticles2D, DirectionalLight2D, WorldEnvironment

---

## File Map

**Create:**
- `resources/shaders/grass_glow.gdshader` — grass wind + emission fragment shader
- `resources/shaders/glow_outline.gdshader` — pixel outline + cyan glow for player body
- `scenes/effects/SpiritParticles.tscn` — ambient ice-blue floating particles
- `scenes/effects/SlashTrail.tscn` — arc polygon that fades after attack
- `scripts/effects/SlashTrail.gd` — slash trail logic
- `scenes/effects/PerfectGuardRing.tscn` — expanding cyan ring on perfect guard
- `scripts/effects/PerfectGuardRing.gd` — ring expand + fade logic
- `scenes/effects/ResurrectionBurst.tscn` — green ring + upward column at corpse
- `scripts/effects/ResurrectionBurst.gd` — burst logic

**Modify:**
- `resources/shaders/grass_wind.gdshader` → replaced by `grass_glow.gdshader` (Grassland.gd reference updated)
- `scripts/world/Grassland.gd` — point to new shader, set emission param
- `scenes/world/World.tscn` — add DirectionalLight2D, WorldEnvironment, SpiritParticles instance
- `scripts/world/World.gd` — add `_add_obstacle_shadows()` called from `_ready()`
- `scripts/player/PlayerController.gd` — add camera ref, glow shader, afterimages, slash trail, tiered hit pause, screen shake, perfect guard ring
- `scripts/enemies/BasicEnemy.gd` — accent glow boost, hit stun tilt, corpse desaturation, zombie halo
- `scripts/skills/TransformSkillEffect.gd` — spawn ResurrectionBurst at each corpse
- `scripts/skills/ProtectiveDivineLightEffect.gd` — activation rings, orb pulse animation
- `scenes/skills/ProtectiveDivineLightEffect.tscn` — add ActivationRing polygon nodes

---

## Task 1: Grass Glow Shader

**Files:**
- Create: `resources/shaders/grass_glow.gdshader`
- Modify: `scripts/world/Grassland.gd`

- [ ] **Step 1: Create the new shader**

```glsl
// resources/shaders/grass_glow.gdshader
shader_type canvas_item;

uniform float wind_strength : hint_range(0.0, 8.0) = 2.5;
uniform float wind_speed : hint_range(0.0, 6.0) = 1.4;
uniform float wind_frequency : hint_range(0.0, 4.0) = 1.2;
uniform vec2 wind_dir = vec2(1.0, 0.0);
uniform float emission_strength : hint_range(0.0, 1.5) = 0.55;
uniform vec3 emission_color = vec3(0.15, 0.78, 0.35);

void vertex() {
	float bend = pow(1.0 - UV.y, 2.0);
	vec2 world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	float phase = world_pos.x * 0.05 + world_pos.y * 0.03;
	float wave = sin(TIME * wind_speed + phase + UV.x * wind_frequency * 6.2831853);
	VERTEX += wind_dir * wave * wind_strength * bend;
}

void fragment() {
	COLOR = texture(TEXTURE, UV);
	float tip_factor = pow(max(0.0, 1.0 - UV.y), 1.8);
	vec3 glow = mix(COLOR.rgb, emission_color, tip_factor * emission_strength * 0.65);
	glow += emission_color * tip_factor * emission_strength * 0.45;
	COLOR.rgb = glow;
}
```

- [ ] **Step 2: Update Grassland.gd to use the new shader**

In `scripts/world/Grassland.gd`, change line 4 from:
```gdscript
const GRASS_SHADER := preload("res://resources/shaders/grass_wind.gdshader")
```
to:
```gdscript
const GRASS_SHADER := preload("res://resources/shaders/grass_glow.gdshader")
```

Then in `_build_material()` (line 92), set the emission parameter after creating the material:
```gdscript
func _build_material() -> void:
	_shared_material = ShaderMaterial.new()
	_shared_material.shader = GRASS_SHADER
	_shared_material.set_shader_parameter("emission_strength", 0.55)
	_shared_material.set_shader_parameter("emission_color", Vector3(0.15, 0.78, 0.35))
```

- [ ] **Step 3: Enable WorldEnvironment glow in World.tscn**

Open Godot editor. In `World.tscn`, add a `WorldEnvironment` node as a child of World. Create a new `Environment` resource on it. Set:
- **Glow → Enabled**: on
- **Glow → Intensity**: 0.4
- **Glow → Blend Mode**: Additive
- **Glow → Levels 1–3**: enabled
- **Background → Mode**: Color, **Color**: `Color(0.02, 0.03, 0.06)` (deep night blue)

Also add a `CanvasModulate` node as a child of World with **Color**: `Color(0.55, 0.62, 0.78)` — this darkens the whole scene to a night-blue tint without hiding the glow effects.

Save the scene.

- [ ] **Step 4: Run the game, verify grass tips glow cold green**

Launch the game. Confirm:
- Grass patches have a cold-green glow on the tips
- The glow pulses slightly as the grass sways in the wind
- The rest of the scene has a blue-night tint

- [ ] **Step 5: Commit**

```bash
git add resources/shaders/grass_glow.gdshader scripts/world/Grassland.gd
git commit -m "feat: grass glow emission shader — cold green tips, moonlit scene tint"
```

---

## Task 2: Ambient Spirit Particles

**Files:**
- Create: `scenes/effects/SpiritParticles.tscn`
- Modify: `scenes/world/World.tscn` (add instance)

- [ ] **Step 1: Create SpiritParticles scene in the editor**

In Godot, create a new scene rooted at `GPUParticles2D`. Name it `SpiritParticles`. Save to `scenes/effects/SpiritParticles.tscn`.

Configure the node properties:
- **Amount**: 72
- **Lifetime**: 4.2
- **Explosiveness**: 0.0 (continuous)
- **Randomness**: 1.0
- **Local Coords**: off
- **Emitting**: on

Create a new `ParticleProcessMaterial`. Set:
- **Direction**: `(0, -1, 0)`
- **Spread**: 28°
- **Initial Velocity Min/Max**: 4 / 10
- **Gravity**: `(0, -2, 0)`
- **Scale Min/Max**: 0.6 / 1.4
- **Color**: gradient from `Color(0.5, 0.85, 1.0, 0.9)` at 0% to `Color(0.3, 0.6, 1.0, 0.0)` at 100%

Set **Emission Shape** to Box with extents `(680, 440, 0)` so particles spawn across the entire map.

Add a child `MeshInstance2D` or a tiny `Polygon2D` (2×2 px square, white) to define the particle visual — or use a `CanvasTexture` with a tiny white dot image if the editor allows.

The simplest approach: leave the visual as the default quad (1×1 white pixel will be scaled by `Scale Min/Max`). The `modulate` of `Color(0.5, 0.85, 1.0)` on the parent node tints it ice-blue.

Set parent `GPUParticles2D.modulate = Color(0.55, 0.88, 1.0, 1.0)`.

- [ ] **Step 2: Add SpiritParticles to World.tscn**

In the editor, open `World.tscn`. Instantiate `SpiritParticles.tscn` as a child of the World node. Set its position to `Vector2(0, 0)`. Set `z_index = 10` so particles appear above ground but below characters.

Save the scene.

- [ ] **Step 3: Run the game, verify floating particles**

Launch game. Confirm:
- Ice-blue dots drift slowly upward across the whole map
- Particles are sparse (not dense clouds)
- They fade out as they rise

- [ ] **Step 4: Commit**

```bash
git add scenes/effects/SpiritParticles.tscn
git commit -m "feat: ambient spirit particles — ice-blue floating dots across map"
```

---

## Task 3: Moon Light and Ground Glow

**Files:**
- Modify: `scenes/world/World.tscn`

- [ ] **Step 1: Add DirectionalLight2D**

In the editor, open `World.tscn`. Add a `DirectionalLight2D` node as a child of World. Set:
- **Color**: `Color(0.70, 0.80, 1.0)` (cold blue-white)
- **Energy**: 0.20
- **Height**: 0.0 (flat top-down)
- **Max Distance**: 2048
- **Rotation Degrees**: -30° (upper-right source)

This adds a subtle directional tint. Because `CanvasModulate` (from Task 1) already provides ambient night color, the DirectionalLight2D only adds a light overlay.

- [ ] **Step 2: Add moon glow polygon**

Add a `Polygon2D` node as a child of World, named `MoonGlow`. Set:
- **Position**: `Vector2(580, -380)` (upper-right corner, off-screen)
- **Color**: `Color(0.65, 0.78, 1.0, 0.12)`
- **Polygon**: a large ellipse approximation (32-point circle, radius 280)

Generate the polygon in a temporary GDScript `@tool` or place it manually. For a quick ellipse with radius 280:
```gdscript
# Run this once in a tool script to get the polygon points, then paste into the scene
var pts := PackedVector2Array()
for i in range(32):
    var a := TAU * i / 32.0
    pts.append(Vector2(cos(a) * 280.0, sin(a) * 160.0))
```
Paste the resulting points into the `MoonGlow` polygon in the editor.

Set `z_index = -5` so it sits behind everything.

- [ ] **Step 3: Verify night-time lighting feels cohesive**

Run the game. The scene should look like:
- Dark blue-black background
- Grass glows cold green at the tips
- A faint blue-white directional light from upper-right
- A soft moon glow pool in the upper-right corner

- [ ] **Step 4: Commit**

```bash
git commit -m "feat: moon light and ground glow — DirectionalLight2D + moon polygon"
```

---

## Task 4: Obstacle Soft Shadows

**Files:**
- Modify: `scripts/world/World.gd`

- [ ] **Step 1: Add shadow builder to World.gd**

Open `scripts/world/World.gd`. After the `@onready` declarations, add these two functions:

```gdscript
func _add_obstacle_shadows() -> void:
	var shadow_tex := _build_shadow_texture()
	for group_name in [&"Buildings", &"Landmarks", &"Trees", &"Breakables"]:
		var group_node := get_node_or_null(group_name) as Node2D
		if group_node == null:
			continue
		for child in group_node.get_children():
			if child is Node2D:
				_attach_shadow(child as Node2D, shadow_tex)

func _attach_shadow(obstacle: Node2D, shadow_tex: Texture2D) -> void:
	if obstacle.get_node_or_null("ShadowEllipse") != null:
		return
	var size := _get_obstacle_footprint(obstacle)
	if size == Vector2.ZERO:
		return
	var shadow := Sprite2D.new()
	shadow.name = "ShadowEllipse"
	shadow.texture = shadow_tex
	shadow.scale = Vector2(size.x / 64.0, size.y / 32.0)
	shadow.position = Vector2(0.0, size.y * 0.45)
	shadow.z_index = -1
	shadow.modulate = Color(0.0, 0.0, 0.0, 0.45)
	obstacle.add_child(shadow)

func _get_obstacle_footprint(n: Node2D) -> Vector2:
	if "size" in n:
		var s = n.size
		if s is Vector2 and s != Vector2.ZERO:
			return s * Vector2(1.0, 0.5)
	var col := n.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col != null and col.shape is RectangleShape2D:
		return (col.shape as RectangleShape2D).size * Vector2(1.0, 0.45)
	if col != null and col.shape is CircleShape2D:
		var r := (col.shape as CircleShape2D).radius
		return Vector2(r * 2.2, r * 0.9)
	return Vector2.ZERO

func _build_shadow_texture() -> Texture2D:
	var img := Image.create(64, 32, false, Image.FORMAT_RGBA8)
	var center := Vector2(32.0, 16.0)
	var rx := 30.0
	var ry := 14.0
	for y in range(32):
		for x in range(64):
			var dx := (x - center.x) / rx
			var dy := (y - center.y) / ry
			var dist := sqrt(dx * dx + dy * dy)
			var alpha := clampf(1.0 - dist, 0.0, 1.0)
			alpha = pow(alpha, 1.6)
			img.set_pixel(x, y, Color(0.0, 0.0, 0.0, alpha))
	return ImageTexture.create_from_image(img)
```

- [ ] **Step 2: Call `_add_obstacle_shadows()` from `_ready()`**

In `World.gd`'s `_ready()` function, add at the end:

```gdscript
func _ready() -> void:
	add_to_group("world")
	chest_rng.randomize()
	_spawn_random_breakables()
	_regenerate_grassland()
	_build_path_grid()
	spawn_timer = initial_spawn_interval
	chest_spawn_timer = chest_spawn_interval
	_try_spawn_enemy()
	_add_obstacle_shadows()   # ← add this line
```

- [ ] **Step 3: Run game, verify shadows under obstacles**

Launch the game. Each tree, building, crate, and landmark should have a soft elliptical dark shadow at its base. The shadow should sit below the object (z_index -1) and be partially transparent.

- [ ] **Step 4: Commit**

```bash
git add scripts/world/World.gd
git commit -m "feat: obstacle soft shadows — elliptical blur sprites under all obstacles"
```

---

## Task 5: Player Body Glow Outline

**Files:**
- Create: `resources/shaders/glow_outline.gdshader`
- Modify: `scripts/player/PlayerController.gd`

- [ ] **Step 1: Create glow outline shader**

```glsl
// resources/shaders/glow_outline.gdshader
shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(0.25, 0.88, 0.82, 0.85);
uniform float outline_width : hint_range(0.5, 3.0) = 1.2;
uniform float glow_strength : hint_range(0.0, 2.0) = 0.55;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec2 texel = outline_width / vec2(textureSize(TEXTURE, 0));
	float neighbors =
		texture(TEXTURE, UV + vec2(texel.x, 0.0)).a +
		texture(TEXTURE, UV + vec2(-texel.x, 0.0)).a +
		texture(TEXTURE, UV + vec2(0.0, texel.y)).a +
		texture(TEXTURE, UV + vec2(0.0, -texel.y)).a;
	float is_outline = clamp(neighbors, 0.0, 1.0) * (1.0 - c.a);
	vec4 out_color = outline_color * vec4(1.0 + glow_strength, 1.0 + glow_strength, 1.0 + glow_strength, is_outline);
	COLOR = mix(out_color, c, c.a);
}
```

- [ ] **Step 2: Apply shader to player body in `_setup_xianxia_visuals()`**

In `scripts/player/PlayerController.gd`, add the shader preload near the top (after existing `const` declarations):

```gdscript
const GLOW_OUTLINE_SHADER := preload("res://resources/shaders/glow_outline.gdshader")
```

In `_setup_xianxia_visuals()`, after `body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST`, add:

```gdscript
var outline_mat := ShaderMaterial.new()
outline_mat.shader = GLOW_OUTLINE_SHADER
outline_mat.set_shader_parameter("outline_color", Color(0.25, 0.88, 0.82, 0.85))
outline_mat.set_shader_parameter("outline_width", 1.2)
outline_mat.set_shader_parameter("glow_strength", 0.55)
body.material = outline_mat
```

Also make the sword blade emit a subtle cyan tint. After `sword_visual.texture_filter = ...`, add:
```gdscript
# Tint sword blade polygon toward ice-blue
var blade := sword_mount.get_node_or_null("Blade") as Polygon2D
if blade != null:
    blade.color = Color(0.78, 0.94, 1.0, 1.0)
    var guard := sword_mount.get_node_or_null("Guard") as Polygon2D
    if guard != null:
        guard.color = Color(0.55, 0.82, 0.96, 1.0)
```

- [ ] **Step 3: Run game, verify player has cyan glow outline**

Launch game. The player body should have a thin cyan glowing outline visible against the dark background. The sword should be ice-blue.

- [ ] **Step 4: Commit**

```bash
git add resources/shaders/glow_outline.gdshader scripts/player/PlayerController.gd
git commit -m "feat: player body cyan glow outline shader + ice-blue sword tint"
```

---

## Task 6: Player Movement Afterimages

**Files:**
- Modify: `scripts/player/PlayerController.gd`

- [ ] **Step 1: Add afterimage state variables**

In `PlayerController.gd`, add these variables in the `var` section (after `var visual_time`):

```gdscript
var _afterimage_timer: float = 0.0
var _afterimage_interval_move: float = 0.07
var _afterimage_interval_dash: float = 0.035
var _afterimage_count_move: int = 2
var _afterimage_count_dash: int = 4
```

- [ ] **Step 2: Add afterimage spawn method**

Add this function to `PlayerController.gd`:

```gdscript
func _spawn_afterimage(alpha: float) -> void:
	var ghost := Sprite2D.new()
	ghost.texture = body.texture
	ghost.scale = body.scale
	ghost.rotation = body.rotation
	ghost.position = body.position
	ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ghost.modulate = Color(0.55, 0.88, 1.0, alpha)
	ghost.z_index = body.z_index - 1
	get_parent().add_child(ghost)
	ghost.global_position = body.global_position
	ghost.global_rotation = body.global_rotation
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.12 if dash_timer <= 0.0 else 0.08)
	tween.tween_callback(ghost.queue_free)
```

- [ ] **Step 3: Trigger afterimages in `_update_xianxia_animation()`**

In `_update_xianxia_animation()`, after `var moving := current_input_direction != Vector2.ZERO`, add:

```gdscript
var is_dashing := dash_timer > 0.0
if is_dashing or moving:
    var interval := _afterimage_interval_dash if is_dashing else _afterimage_interval_move
    _afterimage_timer -= _delta
    if _afterimage_timer <= 0.0:
        _afterimage_timer = interval
        var alpha := 0.55 if is_dashing else 0.30
        _spawn_afterimage(alpha)
else:
    _afterimage_timer = 0.0
```

- [ ] **Step 4: Run game, verify afterimages appear**

Move the player around and dash. Moving should leave 1–2 faint blue-white ghost trails. Dashing should leave a stronger, faster trail.

- [ ] **Step 5: Commit**

```bash
git add scripts/player/PlayerController.gd
git commit -m "feat: player movement afterimages — blue-white ghost trail on move and dash"
```

---

## Task 7: Skeleton Enemy Accent Glow + Hit Stun Tilt

**Files:**
- Modify: `scripts/enemies/BasicEnemy.gd`

- [ ] **Step 1: Boost soul accent visual to additive-style brightness**

In `BasicEnemy.gd`'s `_setup_skeleton_visuals()`, after `soul_accent_visual.color = get_visual_accent_color()`, add:

```gdscript
soul_accent_visual.material = _build_accent_material()
```

Add the helper:

```gdscript
func _build_accent_material() -> CanvasItemMaterial:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return mat
```

This makes the soul-flame accent additively blend — it glows brighter against dark backgrounds.

- [ ] **Step 2: Enlarge the soul accent slightly for more presence**

In `_setup_skeleton_visuals()`, change the soul accent polygon to a slightly larger diamond:

```gdscript
soul_accent_visual.polygon = PackedVector2Array([
    Vector2(0, -18), Vector2(5, -10), Vector2(0, -4), Vector2(-5, -10)
])
```

- [ ] **Step 3: Add hit stun tilt to `_on_damaged()`**

In `BasicEnemy.gd`, find `_on_damaged()` and add a body rotation tilt:

```gdscript
func _on_damaged(_amount: int) -> void:
	body.modulate = Color(1.0, 0.42, 0.18, 1.0)
	body.scale = normal_body_scale * hit_pulse_scale
	hit_flash_timer = hit_flash_duration
	hit_pulse_timer = hit_flash_duration
	# Tilt body backward in the direction away from last knockback
	var tilt_dir := -knockback_velocity.normalized() if knockback_velocity.length() > 1.0 else -facing_direction
	body.rotation = tilt_dir.angle() * 0.12
	var tween := create_tween()
	tween.tween_property(body, "rotation", 0.0, 0.14)
```

- [ ] **Step 4: Brighten accent flash on hit**

In `_on_damaged()`, after setting `body.modulate`, also flash the soul accent:

```gdscript
if soul_accent_visual != null:
    soul_accent_visual.modulate = Color(2.0, 2.0, 2.0, 1.0)
    var accent_tween := create_tween()
    accent_tween.tween_property(soul_accent_visual, "modulate", Color.WHITE, 0.18)
```

- [ ] **Step 5: Run game, verify enemy glows and tilts on hit**

Hit an enemy. Its soul flame should flash brighter, and the body should briefly tilt backward on impact.

- [ ] **Step 6: Commit**

```bash
git add scripts/enemies/BasicEnemy.gd
git commit -m "feat: skeleton enemy additive soul glow + hit stun tilt"
```

---

## Task 8: Corpse Desaturation + Zombie Green Halo

**Files:**
- Modify: `scripts/enemies/BasicEnemy.gd`

- [ ] **Step 1: Desaturate corpse on death**

In `BasicEnemy.gd`'s `_on_died()`, after `body.modulate = Color.WHITE`, add:

```gdscript
# Dim and desaturate the corpse body — accent strip in corpse texture already carries color
body.modulate = Color(0.62, 0.60, 0.58, 1.0)
```

This gives a "cold and extinguished" look to the fallen body.

- [ ] **Step 2: Add green halo ring to zombies**

In `_apply_faction_visuals()`, after setting `body.modulate` for zombies, add:

```gdscript
func _apply_faction_visuals() -> void:
	if faction == "zombie":
		body.modulate = Color(0.78, 1.0, 0.72, 1.0)
		_ensure_zombie_halo()
	else:
		body.modulate = Color.WHITE
		_remove_zombie_halo()
	if soul_accent_visual != null:
		soul_accent_visual.color = get_visual_accent_color()
	if bone_weapon_visual != null:
		bone_weapon_visual.color = get_visual_accent_color().lerp(Color(0.88, 0.86, 0.72, 1.0), 0.35)
```

Add the halo helpers:

```gdscript
func _ensure_zombie_halo() -> void:
	if get_node_or_null("ZombieHalo") != null:
		return
	var halo := Polygon2D.new()
	halo.name = "ZombieHalo"
	var pts := PackedVector2Array()
	for i in range(24):
		var a := TAU * i / 24.0
		pts.append(Vector2(cos(a) * 18.0, sin(a) * 12.0))
	halo.polygon = pts
	halo.color = Color(0.22, 1.0, 0.38, 0.28)
	halo.z_index = -1
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	halo.material = mat
	add_child(halo)

func _remove_zombie_halo() -> void:
	var halo := get_node_or_null("ZombieHalo")
	if halo != null:
		halo.queue_free()
```

- [ ] **Step 3: Pulse the zombie halo in `_update_skeleton_animation()`**

At the end of `_update_skeleton_animation()`, add:

```gdscript
var halo := get_node_or_null("ZombieHalo") as Polygon2D
if halo != null:
    halo.scale = Vector2.ONE * (1.0 + sin(visual_time * 5.5) * 0.12)
    halo.modulate.a = 0.85 + sin(visual_time * 5.5) * 0.15
```

- [ ] **Step 4: Run game, transform an enemy and verify zombie halo**

Kill an enemy, use the Transform skill, confirm the zombie has a pulsing green glow ring. The corpse before resurrection should look dimmer/desaturated.

- [ ] **Step 5: Commit**

```bash
git add scripts/enemies/BasicEnemy.gd
git commit -m "feat: corpse desaturation + zombie additive green halo with pulse"
```

---

## Task 9: Slash Trail Effect

**Files:**
- Create: `scripts/effects/SlashTrail.gd`
- Create: `scenes/effects/SlashTrail.tscn`
- Modify: `scripts/player/PlayerController.gd`

- [ ] **Step 1: Write SlashTrail script**

```gdscript
# scripts/effects/SlashTrail.gd
extends Node2D

var _elapsed: float = 0.0
var _lifetime: float = 0.12
var _arc: Polygon2D

func setup(facing: Vector2, variant: String, melee_range: float) -> void:
	_arc = get_node_or_null("Arc") as Polygon2D
	if _arc == null:
		return
	rotation = facing.angle()
	match variant:
		"counter":
			_arc.color = Color(0.55, 1.0, 0.95, 0.88)
			_arc.scale = Vector2(1.35, 1.35)
			_lifetime = 0.15
		"back_hit":
			_arc.color = Color(0.72, 0.42, 1.0, 0.78)
			_arc.scale = Vector2(1.1, 1.1)
			_lifetime = 0.13
		_:
			_arc.color = Color(0.65, 0.95, 1.0, 0.72)
			_arc.scale = Vector2.ONE
			_lifetime = 0.10

func _process(delta: float) -> void:
	_elapsed += delta
	var t := clampf(_elapsed / _lifetime, 0.0, 1.0)
	modulate.a = 1.0 - t
	if _elapsed >= _lifetime:
		queue_free()
```

- [ ] **Step 2: Create SlashTrail scene**

Create `scenes/effects/SlashTrail.tscn` with this structure:

Root: `Node2D` with script `scripts/effects/SlashTrail.gd`

Child `Arc` (`Polygon2D`):
- Color: `Color(0.65, 0.95, 1.0, 0.72)` (will be overridden by `setup()`)
- Polygon (a crescent arc, 8 points approximating a 120° sweep at radius 38–52):

```
# Outer arc (radius 52), 120° sweep, then inner arc (radius 34) back
# Sweep from -60° to +60° around origin
```

In the editor (or via tool script), generate the polygon:
```gdscript
# Outer ring: angles -60° to +60° (9 steps)
# Inner ring: angles +60° to -60° (9 steps, reversed, smaller radius)
var outer_r := 52.0
var inner_r := 36.0
var pts := PackedVector2Array()
for i in range(9):
    var a := deg_to_rad(-60.0 + 120.0 * i / 8.0)
    pts.append(Vector2(cos(a) * outer_r, sin(a) * outer_r))
for i in range(9):
    var a := deg_to_rad(60.0 - 120.0 * i / 8.0)
    pts.append(Vector2(cos(a) * inner_r, sin(a) * inner_r))
```

Paste the resulting 18 points as the `Arc` polygon.

Set `Arc.z_index = 5` so it appears above characters.

- [ ] **Step 3: Add slash trail spawning to PlayerController**

Add near the top of `PlayerController.gd`:

```gdscript
const SLASH_TRAIL_SCENE := preload("res://scenes/effects/SlashTrail.tscn")
```

Add the spawn helper:

```gdscript
func _spawn_slash_trail(variant: String) -> void:
	var trail := SLASH_TRAIL_SCENE.instantiate() as Node2D
	get_tree().current_scene.add_child(trail)
	trail.global_position = global_position + last_facing_direction * melee_range
	if trail.has_method("setup"):
		trail.setup(last_facing_direction, variant, melee_range)
```

In `_try_melee_attack()`, after `_show_attack_preview()`, add:

```gdscript
var preview_variant := _choose_attack_variant(
    world != null and world.has_method("has_slam_charge") and world.has_slam_charge(),
    counter_ready_timer > 0.0,
    current_input_direction != Vector2.ZERO and current_input_direction.dot(last_facing_direction) > 0.75,
    false
)
_spawn_slash_trail(preview_variant)
```

Note: the back_hit variant is determined after hits are processed. For the trail, use the pre-hit variant. Back hit coloring is a best-effort guess — if the trail spawns before the query, use the pre-query variant. This is acceptable because back hits are detected in hindsight.

- [ ] **Step 4: Run game, verify slash trail appears**

Attack a few times. A thin cyan arc should briefly flash at the attack position and fade within 0.1–0.15s. Counter attacks should produce a wider, brighter arc.

- [ ] **Step 5: Commit**

```bash
git add scripts/effects/SlashTrail.gd scenes/effects/SlashTrail.tscn scripts/player/PlayerController.gd
git commit -m "feat: slash trail arc effect — variant-colored arc fades after each attack"
```

---

## Task 10: Parameterized Hit Sparks + Counter Flash

**Files:**
- Modify: `scripts/effects/TimedEffect.gd`
- Create: `scenes/effects/HitFlash.tscn`
- Modify: `scripts/player/PlayerController.gd`

- [ ] **Step 1: Add particle-count support to `TimedEffect`**

`TimedEffect.gd` currently scales one polygon. Add a `configure_particles()` variant that spawns multiple Polygon2D children:

```gdscript
# Add to scripts/effects/TimedEffect.gd
func configure_burst(effect_color: Color, particle_count: int, spread_radius: float, new_lifetime: float) -> void:
	lifetime = maxf(new_lifetime, 0.01)
	elapsed = 0.0
	# Remove default children scale approach — hide them and build burst instead
	for child in get_children():
		child.visible = false
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in range(particle_count):
		var angle := rng.randf_range(0.0, TAU)
		var speed := rng.randf_range(spread_radius * 0.4, spread_radius)
		var dot := Polygon2D.new()
		dot.polygon = PackedVector2Array([Vector2(-2,-2), Vector2(2,-2), Vector2(2,2), Vector2(-2,2)])
		dot.color = effect_color
		dot.position = Vector2.ZERO
		add_child(dot)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(dot, "position", Vector2(cos(angle), sin(angle)) * speed, new_lifetime)
		tween.tween_property(dot, "modulate:a", 0.0, new_lifetime)
```

- [ ] **Step 2: Create HitFlash scene (white circle for counter hits)**

Create `scenes/effects/HitFlash.tscn`:

Root: `Node2D` with `TimedEffect.gd` script.  
Properties: `lifetime = 0.07`, `start_scale = Vector2(0.4, 0.4)`, `end_scale = Vector2(1.8, 1.8)`

Child `Circle` (`Polygon2D`):
- 16-point circle polygon, radius 14
- Color: `Color(1.0, 1.0, 1.0, 0.9)`

Generate polygon points:
```gdscript
# 16-point circle at radius 14
for i in range(16):
    var a := TAU * i / 16.0
    pts.append(Vector2(cos(a) * 14.0, sin(a) * 14.0))
```

- [ ] **Step 3: Update `_spawn_hit_spark()` in PlayerController**

Add preload:
```gdscript
const HIT_FLASH_SCENE := preload("res://scenes/effects/HitFlash.tscn")
```

Replace `_spawn_hit_spark()`:

```gdscript
func _spawn_hit_spark(effect_position: Vector2, variant: String = ATTACK_VARIANT_NORMAL) -> void:
	var spark := HIT_SPARK_SCENE.instantiate() as Node2D
	get_tree().current_scene.add_child(spark)
	spark.global_position = effect_position
	var color := _get_variant_spark_color(variant)
	var end_scale := _get_variant_spark_end_scale(variant)
	var spark_lifetime := 0.18 if variant == ATTACK_VARIANT_NORMAL else 0.22
	if spark.has_method("configure"):
		spark.configure(color, Vector2(0.75, 0.75), end_scale, spark_lifetime)

	var is_special := variant in [ATTACK_VARIANT_COUNTER, ATTACK_VARIANT_IMPACT]
	if is_special:
		# Extra burst particles
		var burst := HIT_SPARK_SCENE.instantiate() as Node2D
		get_tree().current_scene.add_child(burst)
		burst.global_position = effect_position
		if burst.has_method("configure_burst"):
			var count := 18 if variant == ATTACK_VARIANT_COUNTER else 22
			burst.configure_burst(color, count, 28.0, 0.25)
		# White flash for counter
		if variant == ATTACK_VARIANT_COUNTER:
			var flash := HIT_FLASH_SCENE.instantiate() as Node2D
			get_tree().current_scene.add_child(flash)
			flash.global_position = effect_position
```

- [ ] **Step 4: Run game, verify hit variants look different**

Hit a normal attack — small cyan spark. Land a counter — larger burst plus white circle flash. Impact strike — biggest burst.

- [ ] **Step 5: Commit**

```bash
git add scripts/effects/TimedEffect.gd scenes/effects/HitFlash.tscn scripts/player/PlayerController.gd
git commit -m "feat: parameterized hit sparks + counter white flash burst"
```

---

## Task 11: Tiered Hit Pause + Screen Shake

**Files:**
- Modify: `scripts/player/PlayerController.gd`

- [ ] **Step 1: Add camera reference and screen shake variables**

In `PlayerController.gd`, add:

```gdscript
@onready var _camera: Camera2D = $Camera2D

var _shake_timer: float = 0.0
var _shake_strength: float = 0.0
```

- [ ] **Step 2: Add `_apply_screen_shake()` helper**

```gdscript
func _apply_screen_shake(strength: float, duration: float) -> void:
	_shake_strength = strength
	_shake_timer = duration

func _update_screen_shake(delta: float) -> void:
	if _shake_timer <= 0.0:
		if _camera != null:
			_camera.offset = Vector2.ZERO
		return
	_shake_timer -= delta
	var t := clampf(_shake_timer / maxf(_shake_strength * 0.04, 0.001), 0.0, 1.0)
	var shake := Vector2(
		randf_range(-_shake_strength, _shake_strength),
		randf_range(-_shake_strength, _shake_strength)
	) * t
	if _camera != null:
		_camera.offset = shake
```

- [ ] **Step 3: Call `_update_screen_shake()` from `_physics_process()`**

At the top of `_physics_process()`, after `visual_time += delta`, add:

```gdscript
_update_screen_shake(delta)
```

- [ ] **Step 4: Replace `_apply_hit_pause()` with a variant-aware version**

Replace the existing `_apply_hit_pause()` with:

```gdscript
func _apply_hit_pause(variant: String = ATTACK_VARIANT_NORMAL) -> void:
	var duration: float
	var shake_strength: float
	match variant:
		ATTACK_VARIANT_COUNTER, ATTACK_VARIANT_BACK_HIT:
			duration = 0.12
			shake_strength = 5.0
		ATTACK_VARIANT_IMPACT:
			duration = 0.15
			shake_strength = 5.0
		_:
			duration = hit_pause_duration
			shake_strength = 2.0
	_apply_screen_shake(shake_strength, duration * 1.5)
	get_tree().paused = true
	await get_tree().create_timer(duration, true, false, true).timeout
	get_tree().paused = false
```

- [ ] **Step 5: Pass variant to `_apply_hit_pause()` in `_try_melee_attack()`**

In `_try_melee_attack()`, find the line `_apply_hit_pause()` and replace:

```gdscript
var final_variant := _choose_attack_variant(is_impact_attack, is_counter_attack, has_momentum, landed_back_hit)
_apply_hit_pause(final_variant)
```

- [ ] **Step 6: Add normal block and perfect guard shake**

In `apply_incoming_damage()`, after `blocked.emit()`, add:
```gdscript
_apply_screen_shake(1.5, 0.08)
```

In `handle_enemy_attack()`, inside the perfect guard branch, add:
```gdscript
_apply_screen_shake(3.5, 0.14)
```

- [ ] **Step 7: Run game, verify tiered feedback**

Normal hit: tiny shake (±2px). Counter/back hit: bigger shake (±5px), longer pause. The pauses should feel snappy and distinct.

- [ ] **Step 8: Commit**

```bash
git add scripts/player/PlayerController.gd
git commit -m "feat: tiered hit pause durations + camera screen shake per attack variant"
```

---

## Task 12: Perfect Guard Ring

**Files:**
- Create: `scripts/effects/PerfectGuardRing.gd`
- Create: `scenes/effects/PerfectGuardRing.tscn`
- Modify: `scripts/player/PlayerController.gd`

- [ ] **Step 1: Write PerfectGuardRing script**

```gdscript
# scripts/effects/PerfectGuardRing.gd
extends Node2D

var _elapsed: float = 0.0
var _lifetime: float = 0.22
var _ring: Polygon2D
var _inner: Polygon2D

func _ready() -> void:
	_ring = get_node_or_null("Ring") as Polygon2D
	_inner = get_node_or_null("Inner") as Polygon2D

func _process(delta: float) -> void:
	_elapsed += delta
	var t := clampf(_elapsed / _lifetime, 0.0, 1.0)
	scale = Vector2.ONE * (0.4 + t * 1.6)
	modulate.a = 1.0 - t
	if _elapsed >= _lifetime:
		queue_free()
```

- [ ] **Step 2: Create PerfectGuardRing scene**

Create `scenes/effects/PerfectGuardRing.tscn`:

Root: `Node2D` with `PerfectGuardRing.gd` script.

Child `Ring` (`Polygon2D`) — 24-point ring, outer radius 32, inner radius 26, color `Color(0.35, 0.92, 1.0, 0.9)`:
```gdscript
# Generate hollow ring polygon (two concentric circles, 24 points each)
# Outer: radius 32, Inner: radius 26, alternating
var pts := PackedVector2Array()
for i in range(24):
    var a := TAU * i / 24.0
    pts.append(Vector2(cos(a) * 32.0, sin(a) * 32.0))
for i in range(24):
    var a := TAU * (23 - i) / 24.0
    pts.append(Vector2(cos(a) * 26.0, sin(a) * 26.0))
```

Child `Inner` (`Polygon2D`) — 16-point circle, radius 18, color `Color(0.55, 0.98, 1.0, 0.35)`.

Set `CanvasItemMaterial` on root with `blend_mode = BLEND_MODE_ADD`.

- [ ] **Step 3: Spawn PerfectGuardRing in `handle_enemy_attack()`**

Add preload:
```gdscript
const PERFECT_GUARD_RING_SCENE := preload("res://scenes/effects/PerfectGuardRing.tscn")
```

In `handle_enemy_attack()`, inside the `if is_defending and perfect_guard_timer > 0.0` branch, after `blocked.emit()`, add:

```gdscript
var ring := PERFECT_GUARD_RING_SCENE.instantiate() as Node2D
get_tree().current_scene.add_child(ring)
ring.global_position = global_position
```

- [ ] **Step 4: Run game, verify perfect guard ring**

Block an attack at the right moment. A cyan ring should expand outward from the player and fade within 0.22s.

- [ ] **Step 5: Commit**

```bash
git add scripts/effects/PerfectGuardRing.gd scenes/effects/PerfectGuardRing.tscn scripts/player/PlayerController.gd
git commit -m "feat: perfect guard expanding cyan ring effect"
```

---

## Task 13: Resurrection Burst (Green Ring + Column)

**Files:**
- Create: `scripts/effects/ResurrectionBurst.gd`
- Create: `scenes/effects/ResurrectionBurst.tscn`
- Modify: `scripts/skills/TransformSkillEffect.gd`

- [ ] **Step 1: Write ResurrectionBurst script**

```gdscript
# scripts/effects/ResurrectionBurst.gd
extends Node2D

var _ring_elapsed: float = 0.0
var _ring_lifetime: float = 0.32
var _col_elapsed: float = 0.0
var _col_lifetime: float = 0.38
var _ring: Polygon2D
var _column: Polygon2D

func _ready() -> void:
	_ring = get_node_or_null("Ring") as Polygon2D
	_column = get_node_or_null("Column") as Polygon2D

func _process(delta: float) -> void:
	_ring_elapsed += delta
	_col_elapsed += delta

	if _ring != null:
		var rt := clampf(_ring_elapsed / _ring_lifetime, 0.0, 1.0)
		_ring.scale = Vector2.ONE * (0.3 + rt * 1.7)
		_ring.modulate.a = 1.0 - rt

	if _column != null:
		var ct := clampf(_col_elapsed / _col_lifetime, 0.0, 1.0)
		_column.position = Vector2(0.0, -ct * 48.0)
		_column.modulate.a = 1.0 - ct
		_column.scale.y = 1.0 + ct * 0.5

	if _ring_elapsed >= _ring_lifetime and _col_elapsed >= _col_lifetime:
		queue_free()
```

- [ ] **Step 2: Create ResurrectionBurst scene**

Create `scenes/effects/ResurrectionBurst.tscn`:

Root: `Node2D` with `ResurrectionBurst.gd` script. Apply `CanvasItemMaterial` with `BLEND_MODE_ADD`.

Child `Ring` (`Polygon2D`) — 24-point ring (outer 40, inner 32), color `Color(0.28, 1.0, 0.42, 0.9)`.

Child `Column` (`Polygon2D`) — tall thin rectangle approximating an upward light column, color `Color(0.35, 1.0, 0.48, 0.75)`:
```
Points: Vector2(-6, 0), Vector2(6, 0), Vector2(4, -80), Vector2(-4, -80)
```

- [ ] **Step 3: Spawn ResurrectionBurst at each corpse in TransformSkillEffect**

Add preload to `scripts/skills/TransformSkillEffect.gd`:
```gdscript
const RESURRECTION_BURST_SCENE := preload("res://scenes/effects/ResurrectionBurst.tscn")
```

In `activate()`, change the loop to spawn a burst at each corpse position:

```gdscript
for corpse in _find_corpses_in_radius(origin, resurrection_radius):
	var corpse_pos := corpse.global_position
	_spawn_puff(corpse_pos)
	_spawn_resurrection_burst(corpse_pos)   # ← add this
	var zombie := _create_zombie_from_corpse(corpse)
	if zombie == null:
		continue
	corpse.get_parent().add_child(zombie)
	zombie.global_position = corpse_pos
	if zombie.has_method("_apply_faction_visuals"):
		zombie.call("_apply_faction_visuals")
	if zombie.has_method("set_survival_mode"):
		zombie.set_survival_mode(true)
	corpse.queue_free()
```

Add the spawn helper:

```gdscript
func _spawn_resurrection_burst(at: Vector2) -> void:
	var burst := RESURRECTION_BURST_SCENE.instantiate() as Node2D
	_get_effect_parent().add_child(burst)
	burst.global_position = at
```

- [ ] **Step 4: Run game, verify resurrection burst**

Kill an enemy, activate the Transform skill near the corpse. A green ring should expand outward at the corpse location, and a brief green column of light should rise upward.

- [ ] **Step 5: Commit**

```bash
git add scripts/effects/ResurrectionBurst.gd scenes/effects/ResurrectionBurst.tscn scripts/skills/TransformSkillEffect.gd
git commit -m "feat: resurrection burst — green ring + light column at corpse on transform skill"
```

---

## Task 14: Protective Divine Light Visual Polish

**Files:**
- Modify: `scripts/skills/ProtectiveDivineLightEffect.gd`
- Modify: `scenes/skills/ProtectiveDivineLightEffect.tscn`

- [ ] **Step 1: Add ActivationRing nodes to ProtectiveDivineLightEffect.tscn**

Open `scenes/skills/ProtectiveDivineLightEffect.tscn` in the editor. Add two new `Polygon2D` children to the root:

`ActivationRing1` — 24-point ring (outer 38, inner 30), color `Color(1.0, 0.88, 0.35, 0.85)`, visible = false.

`ActivationRing2` — 24-point ring (outer 52, inner 44), color `Color(1.0, 0.95, 0.55, 0.70)`, visible = false.

Apply `CanvasItemMaterial` with `BLEND_MODE_ADD` to both.

- [ ] **Step 2: Rewrite ProtectiveDivineLightEffect.gd to add visual effects**

Replace the file with:

```gdscript
# scripts/skills/ProtectiveDivineLightEffect.gd
extends Node2D

@export var orbit_radius: float = 32.0
@export var orbit_speed_rad: float = 4.0
@export var damage: int = 1
@export var lifetime: float = 1.5
@export var hit_dwell: float = 0.6
@export var hit_check_radius: float = 11.0

var caster: Node2D
var _hit_cooldowns: Dictionary = {}
var _life_remaining: float = 0.0
var _is_primary: bool = false
var _query_shape: CircleShape2D
var _visual_time: float = 0.0
var _outer_glow: Polygon2D
var _core: Polygon2D
var _ring1: Polygon2D
var _ring2: Polygon2D
var _ring1_timer: float = 0.0
var _ring2_timer: float = 0.0
const RING1_DURATION := 0.28
const RING2_DURATION := 0.42

func _ready() -> void:
	_query_shape = CircleShape2D.new()
	_query_shape.radius = hit_check_radius
	_outer_glow = get_node_or_null("OuterGlow") as Polygon2D
	_core = get_node_or_null("Core") as Polygon2D
	_ring1 = get_node_or_null("ActivationRing1") as Polygon2D
	_ring2 = get_node_or_null("ActivationRing2") as Polygon2D
	tree_exiting.connect(_on_tree_exiting)

func activate(context: Dictionary) -> bool:
	var origin_caster = context.get("caster")
	if not (origin_caster is Node2D):
		call_deferred("queue_free")
		return false

	var existing = origin_caster.get_meta("protective_orb") if origin_caster.has_meta("protective_orb") else null
	if existing is Node and is_instance_valid(existing):
		existing.call("refresh")
		call_deferred("queue_free")
		return true

	caster = origin_caster
	origin_caster.set_meta("protective_orb", self)
	_is_primary = true
	_life_remaining = lifetime
	global_position = _orbit_position()
	_play_activation_rings()
	return true

func refresh() -> void:
	_life_remaining = lifetime
	_play_activation_rings()

func _play_activation_rings() -> void:
	_ring1_timer = RING1_DURATION
	_ring2_timer = RING2_DURATION
	if _ring1 != null:
		_ring1.visible = true
		_ring1.scale = Vector2(0.3, 0.3)
		_ring1.modulate.a = 1.0
	if _ring2 != null:
		_ring2.visible = true
		_ring2.scale = Vector2(0.25, 0.25)
		_ring2.modulate.a = 0.85

func _physics_process(delta: float) -> void:
	if not _is_primary:
		return
	if caster == null or not is_instance_valid(caster):
		queue_free()
		return

	_life_remaining -= delta
	_visual_time += delta
	if _life_remaining <= 0.0:
		queue_free()
		return

	global_position = _orbit_position()

	# Orb pulse
	var pulse := 1.0 + sin(_visual_time * 4.2) * 0.14
	if _outer_glow != null:
		_outer_glow.scale = Vector2.ONE * pulse
	if _core != null:
		_core.scale = Vector2.ONE * (0.88 + sin(_visual_time * 4.2 + 1.0) * 0.12)
		_core.modulate = Color(1.0, 0.95 + sin(_visual_time * 6.0) * 0.05, 0.6 + sin(_visual_time * 3.0) * 0.15, 0.95)

	# Activation rings expand + fade
	if _ring1_timer > 0.0:
		_ring1_timer -= delta
		var t := 1.0 - clampf(_ring1_timer / RING1_DURATION, 0.0, 1.0)
		if _ring1 != null:
			_ring1.scale = Vector2.ONE * (0.3 + t * 1.7)
			_ring1.modulate.a = 1.0 - t
		if _ring1_timer <= 0.0 and _ring1 != null:
			_ring1.visible = false

	if _ring2_timer > 0.0:
		_ring2_timer -= delta
		var t := 1.0 - clampf(_ring2_timer / RING2_DURATION, 0.0, 1.0)
		if _ring2 != null:
			_ring2.scale = Vector2.ONE * (0.25 + t * 1.9)
			_ring2.modulate.a = 0.85 * (1.0 - t)
		if _ring2_timer <= 0.0 and _ring2 != null:
			_ring2.visible = false

	for id in _hit_cooldowns.keys():
		_hit_cooldowns[id] -= delta
		if _hit_cooldowns[id] <= 0.0:
			_hit_cooldowns.erase(id)

	_scan_and_hit()

func _orbit_position() -> Vector2:
	var phase := (Time.get_ticks_msec() / 1000.0) * orbit_speed_rad
	return caster.global_position + Vector2(cos(phase), sin(phase)) * orbit_radius

func _scan_and_hit() -> void:
	var space_state := get_world_2d().direct_space_state
	if space_state == null:
		return
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _query_shape
	query.transform = Transform2D(0.0, global_position)
	query.collision_mask = 1
	query.collide_with_bodies = true
	query.collide_with_areas = false
	var hits := space_state.intersect_shape(query, 16)
	for hit in hits:
		var collider := hit.get("collider") as Node
		_try_contact(collider)

func _try_contact(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	var id := node.get_instance_id()
	if _hit_cooldowns.has(id):
		return
	if node.is_in_group("enemies"):
		if node.is_in_group("zombies"):
			return
		var health := node.get_node_or_null("HealthComponent") as HealthComponent
		if health != null:
			health.take_damage(damage)
			_hit_cooldowns[id] = hit_dwell
			_flash_on_hit()
		return
	if node.is_in_group("breakables") and node.has_method("shatter"):
		node.shatter()
		_hit_cooldowns[id] = hit_dwell

func _flash_on_hit() -> void:
	if _core == null:
		return
	_core.modulate = Color(2.0, 2.0, 1.5, 1.0)
	var tween := create_tween()
	tween.tween_property(_core, "modulate", Color(1.0, 0.95, 0.6, 0.95), 0.14)

func _on_tree_exiting() -> void:
	if caster != null and is_instance_valid(caster):
		var current = caster.get_meta("protective_orb", null)
		if current == self:
			caster.remove_meta("protective_orb")
```

- [ ] **Step 3: Run game, verify divine light orb effects**

Activate the Protective Divine Light skill. Two gold rings should expand from the orb position on activation. The orb should pulse gently while orbiting. When it hits an enemy it should flash bright gold-white.

- [ ] **Step 4: Commit**

```bash
git add scripts/skills/ProtectiveDivineLightEffect.gd scenes/skills/ProtectiveDivineLightEffect.tscn
git commit -m "feat: divine light orb — activation rings, pulse animation, hit flash"
```

---

## Self-Review Checklist

**Spec coverage:**
- D.1 Grass glow ✓ Task 1
- D.2 Spirit particles ✓ Task 2
- D.3 Moon beam + ground glow ✓ Task 3
- D.4 Obstacle shadows ✓ Task 4
- A.1 Player glow outline ✓ Task 5
- A.2 Player afterimages ✓ Task 6
- A.3 Skeleton accent glow + tilt ✓ Task 7
- A.4 Corpse + zombie halo ✓ Task 8
- B.1 Slash trail ✓ Task 9
- B.2 Hit spark variants + counter flash ✓ Task 10
- B.3 Tiered hit pause + screen shake ✓ Task 11
- B.4 Perfect guard ring ✓ Task 12
- C.1 Resurrection burst ✓ Task 13
- C.2 Divine light visual ✓ Task 14

**Type/name consistency verified:**
- `configure()` on `TimedEffect` — existing method, not changed
- `configure_burst()` — new method added in Task 10, referenced in Task 10 only
- `_spawn_slash_trail()` → calls `trail.setup(facing, variant, melee_range)` — defined in `SlashTrail.gd`
- `_apply_hit_pause(variant)` — changed signature in Task 11, call site updated in same task
- `_apply_screen_shake()` — added in Task 11, used in Tasks 11 and 12
- `RESURRECTION_BURST_SCENE` — added in Task 13, used in Task 13 only
- `_play_activation_rings()` — defined and called in Task 14 only
