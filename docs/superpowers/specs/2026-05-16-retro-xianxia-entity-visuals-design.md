# Retro Xianxia Entity Visuals Design

## Goal

Keep the game's retro pixel Chinese xianxia identity while replacing abstract player/enemy blobs with readable animated characters.

## Visual Direction

The player is a white-robed celestial swordsman: pale robe, cool cyan trim, dark long hair, and a visible sword. The silhouette should stay small, crisp, and pixel-like rather than becoming high-resolution illustration.

BasicEnemy and FastEnemy become skeleton enemies. Their bones remain naturally off-white, while their current identity colors remain as soul-fire accents, cracks, shadows, and faction markers. BasicEnemy keeps a red spirit accent. FastEnemy keeps a gold/orange spirit accent.

Corpses inherit the same identity accent as the source skeleton instead of turning neutral gray. Zombies also inherit the source identity color, with a green corrupted tint so they read as transformed allies without losing origin identity.

## Animation Direction

Animation uses PNG sprite sheets sliced at runtime into `AtlasTexture` frames. Each entity reads its sheet, maps rows to directions, and cycles frames using existing movement/combat state timers.

**Sheet layout (all sheets):** 6 columns × 5 rows. Right-facing directions are mirrored from left rows via `body.flip_h = true`.

| Row | Direction |
|-----|-----------|
| 0   | down-left |
| 1   | left      |
| 2   | up-left   |
| 3   | up        |
| 4   | down      |

Player states:
- Idle: 6-frame directional idle sheet (`players_gemini_aligned_idle.png`, 3 rows: down/up/left), 4 fps.
- Walk/Run: 6-frame directional run sheet (`players_gemini-Photoroom.png`), 6 fps.
- Dash: same run frames with existing dash visuals.
- Attack/Hit/death: existing flash/pulse/lunge remains.

Enemy (faction="enemy") states:
- Idle/Walk: `enemy1.png` sheet, 7 fps. Idle shows frame 0 of facing row.
- Attack windup/strike: existing bob, snap, and facing marker emphasis.
- Death: switches to `skeleton_corpse.png` at scale 1.0 (corpus is a fixed 32×24px texture).

Zombie (faction="zombie") states:
- Idle/Walk: `zombie.png` sheet (992×1058px, same 6×5 row layout), 7 fps.
- Death: `queue_free()` immediately — no corpse left.

## Implementation Shape

Stay inside the existing scene/script structure:
- Load PNG sheets at runtime with `load()` as `Texture2D`; slice into `AtlasTexture` arrays keyed by direction string.
- Keep `Sprite2D` body nodes for tests and existing feedback.
- Scale body to a fixed display size (`ENEMY1_DISPLAY_SIZE = Vector2(30, 32)`) using `minf(target.x / frame.x, target.y / frame.y)` at setup; this value becomes `normal_body_scale`.
- On enemy death, reset `body.scale` and `normal_body_scale` to `Vector2.ONE` so the fixed-size corpse texture displays at natural pixel dimensions.
- Drive animation from `PlayerController.gd` and `BasicEnemy.gd` using existing timers (`_run_anim_timer`, `_run_anim_frame`), velocity, and facing direction.

## Testing

Add focused Godot SceneTree tests:
- Player scene exposes pixel-textured white-robed body and sword visual.
- Enemy scenes expose pixel-textured skeleton body and keep distinct accent colors.
- Corpses and transformed zombies preserve source enemy accent color.
- Runtime animation changes visual transforms during movement/attack states.

## Asset Files

| File | Entity | Size | Notes |
|------|--------|------|-------|
| `assets/xianxia/players_gemini-Photoroom.png` | Player run | 1024×1024 | 6×5 sheet |
| `assets/xianxia/players_gemini_aligned_idle.png` | Player idle | varies | 6×3 sheet (rows: down/up/left) |
| `assets/xianxia/enemy1.png` | Enemy | 1024×1024 | 6×5 sheet |
| `assets/xianxia/zombie.png` | Zombie | 992×1058 | 6×5 sheet |
| `assets/xianxia/skeleton_corpse.png` | Enemy corpse | 32×24 | Single frame, scale 1.0 |

## Constraints

Do not replace gameplay logic. Do not make the style modern, smooth, or high-resolution. All sprite sheets must follow the 6-column × 5-row directional layout so the shared slicing logic in `BasicEnemy.gd` and `PlayerController.gd` works without modification.
