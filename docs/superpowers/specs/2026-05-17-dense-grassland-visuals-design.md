# Dense Grassland Visuals Design

## Goal

Make the grassland read as dense green meadow instead of sparse grass blades over dirt. The player will see mostly green grassland, with enough shade difference to distinguish the ground surface from individual grass tufts.

## Chosen Approach

Use a green grassland base plus dense low grass clumps.

The grassland `TextureRect` regions will no longer render transparent. They will generate a muted green tiled pixel surface. The grass tufts will become shorter, wider, and more frequent, so the result feels like a thick grass carpet with visible blade clusters rather than isolated tall thin stalks.

## Visual Direction

The base grassland surface uses darker, muted greens with subtle pixel noise and small ground-level clumps. It will be visibly different from the surrounding dirt and paths, but not so bright that it competes with characters or interactive objects.

The animated grass tufts use brighter greens than the base. Their silhouettes will be bushier and lower: multiple blades per tuft, slight horizontal spread, and fewer very tall single-pixel stems. A small number of taller accents can remain for variation, but the dominant look will be dense low grass.

## Implementation Shape

Stay inside the existing procedural art pipeline:

- Update `PixelSurface.gd` so `surface_kind == "grassland"` generates an opaque green pixel texture instead of a transparent image.
- Reuse the existing tiled `TextureRect` grassland regions in `World.tscn`.
- Update `create_grass_tuft()` so each tuft has more blades, wider spread, and a fuller base.
- Adjust `Grassland.gd` defaults so tuft placement is denser than the current 26-pixel grid.
- Favor shorter tuft sizes as the common case, with occasional taller variants for natural variation.
- Keep the existing wind shader so the grass still moves lightly.
- Preserve exclusion logic around paths, stone, buildings, trees, boundaries, and breakables.

## Proposed Tuning Targets

- Grassland base: muted green tile with darker shade pixels and subtle light flecks.
- Cell spacing: reduce from `26.0` to `15.0`.
- Jitter: keep moderate jitter so the grid does not look mechanical.
- Short tuft size: wider and lower than today, around `16x12` or `18x12`.
- Tall tuft size: less dominant, around `18x16` or `18x18`.
- Blade count: increase from `2-3` to `5-8` blades per tuft.
- Layering: keep back and front layers, with enough back-layer coverage to create a carpet feel.

## Success Criteria

- Grassland regions are green even when no tuft sprite overlaps them.
- The player sees substantially less dirt color inside grassland regions.
- Tufts read as dense clumps, not tall thin isolated hairs.
- Paths, stone square, buildings, trees, crates, and boundaries remain visually clear.
- The style remains crisp retro pixel art and uses nearest-neighbor filtering.

## Testing

Add or update focused Godot SceneTree tests:

- Grassland surface textures are generated, opaque, green-dominant, and nearest-filtered.
- Grassland node generates more tuft sprites than before for the same regions.
- Generated tuft textures contain multiple blade pixels spread across the width.
- Existing pixel-art surface and obstacle tests continue to pass.

## Constraints

Do not add imported art assets or a new rendering system. Do not change gameplay, map layout, enemy spawning, navigation, or collision behavior. Do not make grass so visually busy that it hides the player, enemies, chests, or breakable crates.
