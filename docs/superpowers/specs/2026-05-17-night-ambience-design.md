# Night Ambience Design

## Goal

Transform the current world into a moonlit, crystal-clear night scene during the night state without repainting the map art.

The target feeling is:

- moonlight falling across the grass
- slow golden-green fireflies drifting through the air
- sparse blue crystal sparkles adding a lucid, glassy finish
- stronger light hierarchy so the screen no longer feels flat or dry

This pass should make the world feel visibly more layered, luminous, and magical while preserving enough gameplay readability for combat and navigation.

## Project Context

The current project already contains several useful foundations:

- `scripts/world/World.gd` already creates night atmosphere with `CanvasModulate`, `WorldEnvironment`, ambient particles, and moon lighting helpers
- `scenes/world/AmbientMagicController.tscn` and `scripts/world/AmbientMagicController.gd` already establish a pattern for world ambience layers
- the HUD already lives in its own `CanvasLayer`, which gives a clean separation target for screen-space ambience layers
- the required first-pass night assets already exist under `assets/xianxia/pixel_night_assets/`

This means the work does not need a new rendering direction from scratch. The main design task is to replace the current relatively thin night pass with a more intentional layered ambience stack.

## Constraints

- Do not repaint or replace the map art
- The effect only activates in the world night state
- The entire `World` map switches into the same night ambience profile
- Atmosphere is prioritized over maximum combat readability
- UI must remain unaffected by the night overlay and vignette layers
- First pass should use only these existing assets:
  - `firefly_dot.png`
  - `sparkle_blue.png`
  - `moonlight_patch.png`
  - `light_circle.png`

## Success Criteria

The pass is successful when all of the following are true:

- the scene reads as night immediately rather than “day map with a blue tint”
- the screen has visible depth and focus rather than flat uniform brightness
- the player, weapon, and major enemies are lifted out of the background with local light accents
- the ambience feels magical and premium rather than noisy, dusty, or placeholder
- the world remains playable and the HUD remains clean

## Recommended Approach

### Option A: State-Driven Layered Night Ambience

Use a dedicated night ambience controller attached to `World` that owns and toggles all environment layers for the night state:

- global night tint
- vignette
- glow / bloom environment
- firefly particles
- crystal sparkle particles
- moonlight ground patches
- local character lights

Pros:

- best match for the desired result
- cleanly supports “night state on, day state off”
- concentrated tuning in one place
- uses existing project structure well

Cons:

- requires disciplined layering and ownership boundaries
- needs careful tuning to avoid muddy over-darkening

### Option B: Mostly Post-Process Night Filter

Rely mainly on global tint, vignette, glow, and a small amount of local lighting.

Pros:

- fastest implementation
- lowest node count

Cons:

- likely to feel like a filter rather than a living environment
- weaker “air full of light” feeling
- does not fully reach the reference mood

### Option C: Hand-Placed Environment Polish

Lean heavily on manually placed moonlight patches, edge glows, and authored light accents around the map.

Pros:

- can create very intentional composition
- produces strong premium polish in still frames

Cons:

- higher editor labor
- brittle to maintain
- too far from the “do not repaint the map” goal for a first pass

### Recommendation

Choose Option A.

It is the best balance between mood, controllability, implementation cost, and compatibility with the current codebase. It also keeps the work focused on a reversible night state rather than scattering one-off visual edits throughout the map.

## Architecture

### Ownership Model

The design should separate environment-level ambience from character-level readability.

### Environment-owned layers under `World`

These layers belong to the world because they describe the scene as a whole:

- `NightEnvironment` for glow / bloom configuration
- `NightOverlay` for the overall night tint
- `Vignette` for edge darkening and center focus
- `MoonlightPatches` for ground-level moonlight breakup
- `FireflyParticles` for the main golden-green moving ambience
- `SparkleParticles` for sparse blue crystal shimmer accents

### Character-owned local lights

These lights belong with their actors because they communicate gameplay presence:

- `PlayerLight`
- `WeaponLight`
- `EnemyAccentLight`

This split avoids mixing “camera mood” with “actor readability” and keeps the night system easy to tune.

## Controller Strategy

The night state should be managed by a dedicated `NightAmbienceController` concept attached to `World`.

It may be implemented as:

- a new child node and script under `World`, or
- a dedicated section inside `World.gd` that instantiates and owns a focused node tree

The important design requirement is not the exact script file name. The important requirement is concentrated ownership:

- one place decides whether night ambience is active
- one place creates and updates the environment layers
- one place exposes tuning values for density, opacity, intensity, and palette

The existing `AmbientMagicController` should not become the owner of every night feature. It already fits the role of an ambience particle container. This pass adds screen-space layers, ground light patches, and local actor lights, which makes a broader controller boundary more appropriate.

## Scene Structure

Recommended node structure:

```text
World
  Ground
  Grassland
  Buildings
  Landmarks
  Breakables
  Trees
  Boundaries
  Player
  Enemies
  NightAmbience
    NightEnvironment
    WorldEffects
      MoonlightPatches
      FireflyParticles
      SparkleParticles
    ScreenFx
      NightOverlay
      Vignette
  Hud
```

Character-local lights would live inside the relevant actor scenes:

```text
Player
  ...
  PlayerLight
  WeaponLight

BasicEnemy
  ...
  EnemyAccentLight
```

The exact node names can vary slightly, but the separation between world ambience and actor lights should remain intact.

## Visual Layer Design

### Layer 1: Global Night Overlay

Purpose:

- push the entire map into a unified night color family
- cool down the grass and road palette
- create the first step toward the moonlit mood

Implementation direction:

- screen-space color overlay that does not affect UI
- cool cyan-blue tint with restrained alpha

Starting point:

- use the user’s proposed dark blue-green direction
- likely tune the final alpha lower than `0.45` because the current world already has night-related tinting

Design note:

This layer should establish mood, not crush detail. If the map loses too much local variation, the overlay is too strong.

### Layer 2: Vignette

Purpose:

- darken the outer frame
- preserve more visibility toward the center
- give the image focus and depth

Implementation direction:

- screen-space vignette layer, also isolated from the HUD
- deep blue-black edge values rather than pure black

Target read:

- subtle but obvious
- immediately makes the screenshot feel less flat
- supports atmosphere without feeling like a heavy camera filter

### Layer 3: Glow / Bloom

Purpose:

- make luminous elements actually bloom
- connect particles, weapon highlights, and local lights into one cohesive render

Implementation direction:

- configure `WorldEnvironment` glow under the night ambience system
- tune for visible bloom on particles and lights without washing out the grass texture

Target read:

- fireflies and sparkles should “light up,” not merely exist as small sprites
- the effect should read as cool and crystalline rather than soft and foggy

### Layer 4: Firefly Particles

Purpose:

- provide the main visible magical life in the air
- make the world feel inhabited by living light

Asset:

- `assets/xianxia/pixel_night_assets/firefly_dot.png`

Implementation direction:

- `GPUParticles2D`
- golden-green palette
- low speed
- long lifetime
- soft pulse rather than erratic flicker

Behavior goals:

- drift slowly
- feel unevenly distributed, not mathematically uniform
- remain readable at gameplay zoom
- avoid looking like dust or random noise

This layer is the primary ambience read and should be more noticeable than the blue sparkle layer.

### Layer 5: Blue Crystal Sparkles

Purpose:

- create the “crystal-clear” finish
- add sparse suspended points of lucid blue light

Asset:

- `assets/xianxia/pixel_night_assets/sparkle_blue.png`

Implementation direction:

- `GPUParticles2D`
- lower count than fireflies
- shorter lifetime
- minimal movement, possibly slight upward drift
- pale blue / cyan / icy blue range

Behavior goals:

- feel quiet and rare
- support the environment rather than dominate it
- read more like magical gleams than stars

### Layer 6: Moonlight Ground Patches

Purpose:

- break up the grass so it no longer reads as one broad flat surface
- create local zones where moonlight appears to fall through the scene

Asset:

- `assets/xianxia/pixel_night_assets/moonlight_patch.png`

Implementation direction:

- a small number of `Sprite2D` instances
- transparent cold-blue texture laid onto the grass
- not tiled across the whole map

Placement philosophy:

- use only a handful of patches
- bias toward open grass, near trees, near stones, and near path edges
- avoid obvious repetition and avoid covering every surface

This layer is one of the most important tools for restoring depth without changing the underlying map art.

### Layer 7: Character Local Lights

Purpose:

- keep primary actors legible inside the moodier night treatment
- create a clear subject/background separation

Asset:

- `assets/xianxia/pixel_night_assets/light_circle.png`

Implementation direction:

- `PointLight2D` based local lights

Player light:

- pale blue-white
- soft radius
- modest intensity

Weapon light:

- brighter icy-blue accent
- smaller radius
- subtle breathing pulse

Enemy light:

- weaker than player light
- enough to lift the silhouette and interaction target from the grass

These actor lights should improve readability without turning every character into a strong glowing object.

## State Behavior

This pass is specifically for the whole-map night state.

The design assumption is:

- when the world enters night state, the entire ambience stack activates together
- when the world exits night state, the ambience stack deactivates or falls back to a lighter daytime configuration

No region-based night volumes are included in this pass.

No full day/night cycle design is included in this pass.

## Data Flow

The intended flow is straightforward:

1. `World` determines or receives that the current world state is night
2. the night ambience controller activates and configures the environment stack
3. world-owned layers start emitting or becoming visible
4. character scenes expose their local night lights when the state is active
5. the HUD remains unchanged because screen-space world effects are kept out of the UI layer

This keeps state flow explicit and makes it easier to test activation and deactivation boundaries.

## Integration Notes

### Why Not Put Everything In `AmbientMagicController`

That scene already suggests a narrow role: ambience particles.

This pass is broader:

- world environment glow
- screen-space tint
- screen-space vignette
- ground-mounted moonlight
- character-local lights

If all of that is pushed into `AmbientMagicController`, the boundary becomes muddy and the scene stops communicating a clear purpose. It is better either to keep that controller as a particle-specific helper or to let a new night ambience controller own it.

### Why Use A Hybrid Technique

The pass needs four technically different behaviors:

- screen-space mood shaping
- airborne ambient motion
- ground light breakup
- actor readability accents

No single technique fits all of them well.

Recommended mapping:

- overlay and vignette: screen-space nodes
- fireflies and sparkles: `GPUParticles2D`
- moonlight patches: `Sprite2D`
- actor accents: `PointLight2D`

This hybrid structure gives better visual control and keeps each unit simple.

## Error Handling And Guard Rails

The system should fail gracefully if configuration is incomplete.

Expected guard rails:

- if a night asset is missing, the controller should skip that layer rather than crash
- if a character scene lacks its optional local light node, the world should still run
- if glow is active but too strong, tuning should happen through exported values rather than hard-coded magic numbers spread across multiple scripts

The goal is a system that is robust to iteration, not one that only works in a perfect editor setup.

## Testing Strategy

Testing should validate both structure and visual intent.

### Structural tests

Confirm that night activation results in the expected environment layers and that UI isolation is preserved.

Examples:

- `World` creates or reveals the night ambience container
- `NightEnvironment`, `NightOverlay`, and `Vignette` exist when night is active
- particle layers exist and are configured to emit
- player and enemy local lights exist or are enabled
- HUD nodes are not parented under the screen-space night layer

### Visual regression tests

Use fixed world setup and scene-tree assertions to ensure the scene remains in a valid tuning range.

Examples:

- overlay alpha remains within a configured night range
- firefly count remains above a visible floor and below a clutter ceiling
- sparkle count stays lower than firefly count
- moonlight patch count remains within the designed sparse range
- local player light remains stronger than enemy accent light

### Manual acceptance checks

The pass should be reviewed in motion, not only through node existence.

Expected visual checks:

- the scene reads as moonlit immediately
- air feels alive with light
- grass has local depth variation
- player and enemies do not disappear into the grass
- HUD remains clean
- the screen feels magical, calm, and premium rather than busy

## First-Pass Scope

In scope:

- whole-map night ambience activation
- global night overlay
- vignette
- `WorldEnvironment` glow tuning
- one golden-green firefly particle layer
- one blue crystal sparkle particle layer
- a small number of moonlight ground patches
- local light accents for player, weapon, and major enemies
- UI isolation from world screen effects

Out of scope:

- region-based night transitions
- full day/night cycle logic
- complex animated vignette shaders
- broad path-edge moonlight dressing
- per-enemy-type bespoke light color design
- additional asset requirements beyond the selected four textures

## Implementation Order

Recommended order:

1. `NightOverlay`
2. `Vignette`
3. `WorldEnvironment` glow tuning
4. `FireflyParticles`
5. `PlayerLight` and `WeaponLight`
6. `EnemyAccentLight`
7. `SparkleParticles`
8. `MoonlightPatches`

Reasoning:

- the first four steps establish the night mood
- actor lights restore the minimum readability floor
- sparkles and moonlight patches finish the crystal-clear premium quality

By the time steps 1 through 5 are complete, the screen should already feel substantially different. The remaining steps deepen texture and polish.

## Acceptance Criteria

This design is complete when the implemented pass satisfies all of the following:

- the world switches into a unified moonlit night mood
- the screen has noticeable edge falloff and central focus
- visible but restrained fireflies drift across the map
- sparse blue crystal sparkles add lucid ambience
- three to six moonlight patches create grass breakup and local depth
- player, weapon, and major enemies are visibly lifted from the background
- HUD readability remains unaffected
- no map repaint is required
