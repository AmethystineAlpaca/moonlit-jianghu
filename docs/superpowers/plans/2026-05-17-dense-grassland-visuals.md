# Dense Grassland Visuals Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make grassland regions render as dense green meadow with an opaque green base and shorter, fuller grass tufts.

**Architecture:** Keep the existing procedural Godot art pipeline. `PixelSurface.gd` owns tiled terrain textures, while `Grassland.gd` owns tuft placement and uses `PixelSurface.create_grass_tuft()` for generated tuft textures.

**Tech Stack:** Godot 4 GDScript, `TextureRect`, `Sprite2D`, `ImageTexture`, existing headless SceneTree tests.

---

### Task 1: Grassland Visual Contract Tests

**Files:**
- Modify: `tests/test_pixel_art_scene_visuals.gd`
- Modify: `scripts/world/PixelSurface.gd`
- Modify: `scripts/world/Grassland.gd`

- [ ] **Step 1: Write failing grassland surface and tuft tests**

Append these calls to `_initialize()` in `tests/test_pixel_art_scene_visuals.gd` after `_test_world_surfaces_use_pixel_textures()`:

```gdscript
	await _test_grassland_surface_is_opaque_green()
	await _test_grassland_generates_dense_tufts()
	_test_grass_tuft_texture_is_bushy()
```

Add these helper tests before `_assert_true()`:

```gdscript
func _test_grassland_surface_is_opaque_green() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame

	for node_name in ["GrasslandNW", "GrasslandNE", "GrasslandSW", "GrasslandSE"]:
		var surface := world.get_node(node_name)
		_assert_true(surface is TextureRect, "%s is a textured grassland surface" % node_name)
		if surface is TextureRect:
			_assert_true(surface.texture != null, "%s has a generated texture" % node_name)
			_assert_equal(surface.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST, "%s keeps crisp pixels" % node_name)
			var image := (surface.texture as Texture2D).get_image()
			var sample := image.get_pixel(0, 0)
			_assert_true(sample.a >= 0.99, "%s is opaque instead of transparent" % node_name)
			_assert_true(sample.g > sample.r and sample.g > sample.b, "%s base color is green-dominant" % node_name)

	world.free()

func _test_grassland_generates_dense_tufts() -> void:
	var world := WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame

	var grassland := world.get_node("Grassland")
	var tufts := _count_sprite_descendants(grassland)
	_assert_true(tufts >= 240, "grassland generates dense tuft coverage")

	world.free()

func _test_grass_tuft_texture_is_bushy() -> void:
	var texture := PixelSurface.create_grass_tuft(Vector2i(18, 12), 4242)
	var image := texture.get_image()
	var occupied_columns := {}
	var colored_pixels := 0

	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			if color.a > 0.0:
				occupied_columns[x] = true
				colored_pixels += 1

	_assert_true(occupied_columns.size() >= 5, "generated grass tuft spreads across multiple columns")
	_assert_true(colored_pixels >= 18, "generated grass tuft has enough blade pixels to read as bushy")

func _count_sprite_descendants(node: Node) -> int:
	var count := 0
	if node is Sprite2D:
		count += 1
	for child in node.get_children():
		count += _count_sprite_descendants(child)
	return count
```

Add this preload near the top of the same test file:

```gdscript
const PixelSurface := preload("res://scripts/world/PixelSurface.gd")
```

- [ ] **Step 2: Run focused test to verify it fails**

Run:

```bash
/usr/local/bin/godot --headless --path . --script tests/test_pixel_art_scene_visuals.gd
```

Expected: FAIL. The grassland surface is currently transparent, tuft coverage is based on the sparse `26.0` cell size, and generated tufts only contain `2-3` thin blades.

- [ ] **Step 3: Commit is skipped**

Do not run `git commit`; `/Users/ming/gaame` is not currently a git repository.

### Task 2: Green Grassland Base Texture

**Files:**
- Modify: `scripts/world/PixelSurface.gd`
- Test: `tests/test_pixel_art_scene_visuals.gd`

- [ ] **Step 1: Replace transparent grassland generation**

In `scripts/world/PixelSurface.gd`, replace the `if surface_kind == "grassland":` block inside `_generate_texture()` with:

```gdscript
	if surface_kind == "grassland":
		var size: int = maxi(8, tile_size)
		var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
		var palette := _get_palette()
		for y in range(size):
			for x in range(size):
				var noise := int(x * 19 + y * 29 + (x / 3) * 11 + (y / 5) * 17) % 13
				var color := palette[0]
				if noise == 0 or noise == 1:
					color = palette[1]
				elif noise == 2:
					color = palette[2]
				image.set_pixel(x, y, color)

		_draw_surface_details(image)
		texture = ImageTexture.create_from_image(image)
		stretch_mode = TextureRect.STRETCH_TILE
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		return
```

- [ ] **Step 2: Tune the grassland palette**

In `_get_palette()`, add a dedicated `"grassland"` match arm before `"path"`:

```gdscript
		"grassland":
			return [
				Color(0.12, 0.34, 0.16, 1.0),
				Color(0.16, 0.42, 0.19, 1.0),
				Color(0.07, 0.24, 0.12, 1.0),
			]
```

- [ ] **Step 3: Run focused test**

Run:

```bash
/usr/local/bin/godot --headless --path . --script tests/test_pixel_art_scene_visuals.gd
```

Expected: still FAIL because tuft density and bushy tuft generation are not implemented yet. The grassland opacity/green assertions should now pass.

### Task 3: Bushier Tuft Texture Generation

**Files:**
- Modify: `scripts/world/PixelSurface.gd`
- Test: `tests/test_pixel_art_scene_visuals.gd`

- [ ] **Step 1: Replace `create_grass_tuft()` with fuller clump drawing**

Replace the existing `static func create_grass_tuft(size: Vector2i, seed_value: int) -> ImageTexture:` in `scripts/world/PixelSurface.gd` with:

```gdscript
static func create_grass_tuft(size: Vector2i, seed_value: int) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var dark := Color(0.06, 0.24, 0.12, 1.0)
	var mid := Color(0.20, 0.50, 0.22, 1.0)
	var light := Color(0.42, 0.72, 0.34, 1.0)
	var blade_count := rng.randi_range(5, 8)
	var center := size.x / 2

	for i in range(blade_count):
		var base_x := clampi(center + rng.randi_range(-size.x / 3, size.x / 3), 1, size.x - 2)
		var lean := rng.randi_range(-2, 2)
		var height := rng.randi_range(int(size.y * 0.45), int(size.y * 0.85))
		var top_y := size.y - height
		for y in range(top_y, size.y):
			var t := float(y - top_y) / maxf(1.0, float(size.y - top_y - 1))
			var x := clampi(base_x + int(roundf(lerpf(float(lean), 0.0, t))), 0, size.x - 1)
			var c := mid
			if y == top_y:
				c = light
			elif y >= size.y - 2:
				c = dark
			image.set_pixel(x, y, c)
			if y >= size.y - 3 and x + 1 < size.x:
				image.set_pixel(x + 1, y, dark)

	for x in range(maxi(0, center - size.x / 3), mini(size.x, center + size.x / 3 + 1)):
		image.set_pixel(x, size.y - 1, dark)

	return ImageTexture.create_from_image(image)
```

- [ ] **Step 2: Run focused test**

Run:

```bash
/usr/local/bin/godot --headless --path . --script tests/test_pixel_art_scene_visuals.gd
```

Expected: still FAIL if density is not yet changed. The bushy tuft texture assertions should now pass.

### Task 4: Dense Grassland Placement Defaults

**Files:**
- Modify: `scripts/world/Grassland.gd`
- Test: `tests/test_pixel_art_scene_visuals.gd`

- [ ] **Step 1: Tune placement and size defaults**

In `scripts/world/Grassland.gd`, update these exported defaults at the top of the file:

```gdscript
@export var cell_size: float = 15.0
@export var jitter: float = 6.0
@export var short_tuft_size: Vector2i = Vector2i(18, 12)
@export var tall_tuft_size: Vector2i = Vector2i(18, 18)
@export var short_variants: int = 4
@export var tall_variants: int = 1
```

- [ ] **Step 2: Bias dense coverage toward the back layer**

In `_spawn_tuft()`, replace:

```gdscript
	var parent := _front_layer if rng.randf() < 0.5 else _back_layer
```

with:

```gdscript
	var parent := _front_layer if rng.randf() < 0.35 else _back_layer
```

- [ ] **Step 3: Run focused test**

Run:

```bash
/usr/local/bin/godot --headless --path . --script tests/test_pixel_art_scene_visuals.gd
```

Expected: PASS.

### Task 5: Regression Sweep

**Files:**
- Test: `tests/*.gd`

- [ ] **Step 1: Run all SceneTree tests**

Run:

```bash
/bin/bash -lc 'for test_file in tests/*.gd; do /usr/local/bin/godot --headless --path . --script "$test_file" || exit $?; done'
```

Expected: PASS for all tests.

- [ ] **Step 2: Inspect visual result in the running game**

Run:

```bash
/usr/local/bin/godot --path .
```

Expected: The game opens. The four grassland corner regions render as green meadow surfaces with dense, low, brighter grass clumps. Dirt no longer shows through the grassland except outside the grassland rectangles, and paths/stone/objects remain readable.

- [ ] **Step 3: Commit is skipped**

Do not run `git commit`; `/Users/ming/gaame` is not currently a git repository.

## Self-Review

Spec coverage: Task 2 implements the opaque green base, Task 3 implements bushier tuft textures, Task 4 implements denser placement and layering, and Task 5 covers regression plus visual inspection. The plan preserves the existing procedural art pipeline, nearest-neighbor filtering, wind shader usage, and obstacle/path exclusion behavior.

Placeholder scan: no red-flag placeholder instructions remain. Each code edit includes concrete code and each verification step includes exact commands and expected results.

Type consistency: the plan uses existing Godot classes and names: `PixelSurface.gd`, `create_grass_tuft(size: Vector2i, seed_value: int)`, `Grassland.gd`, `cell_size`, `jitter`, `short_tuft_size`, `tall_tuft_size`, `short_variants`, `tall_variants`, `_spawn_tuft()`, `_front_layer`, and `_back_layer`.

Git note: commits are omitted because `/Users/ming/gaame` is not currently a git repository.
