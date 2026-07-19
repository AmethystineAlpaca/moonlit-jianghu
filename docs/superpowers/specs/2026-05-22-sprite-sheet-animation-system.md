# Sprite Sheet Animation System

How player, enemy, and zombie directional animation is implemented in `BasicEnemy.gd` and `PlayerController.gd`.

## Sheet Layout Convention

All character sprite sheets follow the same 6-column × 5-row grid:

| Row | Direction |
|-----|-----------|
| 0   | down-left |
| 1   | left      |
| 2   | up-left   |
| 3   | up        |
| 4   | down      |

Right-facing directions (right, down-right, up-right) are not stored — they are mirrored from the left rows at runtime via `body.flip_h = true`.

## Slicing Pattern

Sheets are loaded once in `_ready()` with `load(PATH) as Texture2D`, then sliced lazily (on first use) into `Dictionary` of `Array[Texture2D]` keyed by direction string:

```
"down_left" | "left" | "up_left" | "up" | "down"
```

Each frame is an `AtlasTexture` pointing into the parent sheet:

```gdscript
var atlas := AtlasTexture.new()
atlas.atlas = _sheet
atlas.region = Rect2(col * fw, row * fh, fw, fh)
```

Frame width/height come from integer division of the sheet dimensions by column/row counts.

## Direction → Row Mapping

Given `facing_direction: Vector2`:

```
d.x < -0.001 → left side (flip_h = false)
  d.y < -0.001 → "up_left"
  d.y > 0.001  → "down_left"
  else         → "left"

d.x > 0.001  → right side (flip_h = true, mirror left rows)
  d.y < -0.001 → "up_left"
  d.y > 0.001  → "down_left"
  else         → "left"

d.y < -0.001 → "up"
else         → "down"
```

## Scale-to-Display-Size

Since sheet frames are large (e.g. 170×204px from a 1024×1024 sheet), the body is scaled down to a target pixel display size at setup:

```gdscript
const ENEMY1_DISPLAY_SIZE := Vector2(30.0, 32.0)

var tex_size := first_frame.get_size()
var s := minf(ENEMY1_DISPLAY_SIZE.x / tex_size.x, ENEMY1_DISPLAY_SIZE.y / tex_size.y)
body.scale = Vector2(s, s)
```

This value becomes `normal_body_scale` (captured via `normal_body_scale = body.scale` in `_ready()`), so all pulse/flash effects remain correct relative to the display size.

**Corpse exception:** On `_on_died()`, `body.scale` and `normal_body_scale` are both reset to `Vector2.ONE` before applying the corpse texture. The corpse texture (`skeleton_corpse.png`, 32×24px) was designed for scale 1.0 and must not inherit the sheet's scaled-down value.

## Animation Loop

A shared `_run_anim_timer` / `_run_anim_frame` pair drives frame cycling:

- Idle (not moving): show `frames[0]` of the current direction row, reset timer and frame counter.
- Moving: decrement timer by `delta`; when it hits 0, advance frame index modulo column count and reset to `1.0 / RUN_ANIM_FPS`.

```gdscript
_run_anim_timer -= delta
if _run_anim_timer <= 0.0:
    _run_anim_frame = (_run_anim_frame + 1) % COLUMNS
    _run_anim_timer = 1.0 / RUN_ANIM_FPS
body.texture = frames[_run_anim_frame]
```

## Adding a New Sheet

1. Place the PNG in `assets/xianxia/`. It must be 6 columns × 5 rows with the row order above.
2. Add path and layout constants (`_PATH`, `_COLUMNS`, `_ROWS`, `_ROW_*`, `_DISPLAY_SIZE`).
3. Add `_sheet: Texture2D` and `_frames: Dictionary = {}` vars; load in `_ready()`.
4. Copy the three helper methods (`_get_*_frames`, `_build_*_frames`, `_slice_*_row`), substituting the new names and constants.
5. In the animation update function, select frames by faction or entity type and pass `COLUMNS` for the modulo.
6. In `_setup_*_visuals()`, set `body.texture = first_frame` and `body.scale` from display size before `normal_body_scale` is captured.

## Files

| Script | Sheets used |
|--------|-------------|
| `scripts/player/PlayerController.gd` | `players_gemini-Photoroom.png` (run), `players_gemini_aligned_idle.png` (idle) |
| `scripts/enemies/BasicEnemy.gd` | `enemy1.png` (faction="enemy"), `zombie.png` (faction="zombie"), `skeleton_corpse.png` (death) |
