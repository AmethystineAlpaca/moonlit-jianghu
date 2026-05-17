# Retro Xianxia Entity Visuals Design

## Goal

Keep the game's retro pixel Chinese xianxia identity while replacing abstract player/enemy blobs with readable animated characters.

## Visual Direction

The player is a white-robed celestial swordsman: pale robe, cool cyan trim, dark long hair, and a visible sword. The silhouette should stay small, crisp, and pixel-like rather than becoming high-resolution illustration.

BasicEnemy and FastEnemy become skeleton enemies. Their bones remain naturally off-white, while their current identity colors remain as soul-fire accents, cracks, shadows, and faction markers. BasicEnemy keeps a red spirit accent. FastEnemy keeps a gold/orange spirit accent.

Corpses inherit the same identity accent as the source skeleton instead of turning neutral gray. Zombies also inherit the source identity color, with a green corrupted tint so they read as transformed allies without losing origin identity.

## Animation Direction

Animation is procedural and lightweight. Each entity uses the existing movement/combat state rather than imported sprite sheets.

Player states:
- Idle: subtle robe/hair breathing.
- Walk: small body bob, sword and robe sway.
- Dash: stronger forward lean, brief sword/robe stretch, optional afterimage-like tint.
- Attack: sword slash pose and body lunge.
- Hit/death: existing flash/pulse remains readable.

Enemy states:
- Idle: small bone jitter.
- Walk: bony bob and side sway.
- Attack windup/strike: arm/facing marker emphasis and forward snap.
- Hit/death/corpse: existing hit feedback remains, corpse becomes colored bone remains.

## Implementation Shape

Stay inside the existing scene/script structure:
- Generate pixel textures in GDScript with `Image` and `ImageTexture`.
- Keep `Sprite2D` body nodes for tests and existing feedback.
- Add small child sprites/polygons for sword, robe/hair accents, skeleton accents, and animation helpers.
- Drive animation from `PlayerController.gd` and `BasicEnemy.gd` using existing timers, velocity, dash state, and windup state.

## Testing

Add focused Godot SceneTree tests:
- Player scene exposes pixel-textured white-robed body and sword visual.
- Enemy scenes expose pixel-textured skeleton body and keep distinct accent colors.
- Corpses and transformed zombies preserve source enemy accent color.
- Runtime animation changes visual transforms during movement/attack states.

## Constraints

Do not add a new asset pipeline. Do not replace gameplay logic. Do not make the style modern, smooth, or high-resolution.
