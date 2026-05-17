# Phase 0 Godot Foundation Design

## Summary

Phase 0 will turn the empty Godot project into a prototype-ready foundation for a 2D top-down medieval RPG with future card-system support. The result should be runnable, organized, and visually aligned with an overhead village-map style: grass, paths, simple obstacle placeholders, and a player moving on a flat map plane.

This phase does not include enemies, combat, cards, inventory, quests, dialogue, or save data. It prepares the project so those systems can be added cleanly in later phases.

## Current Project Context

The project is a minimal Godot 4.6 project. Current files are:

- `project.godot`
- `icon.svg`
- `icon.svg.import`
- `documents/game_plan.md`

There is no git repository currently initialized in this folder.

## Approved Direction

Use the prototype-ready foundation approach.

The key visual and movement direction is top-down RPG, similar to an overhead village map. The game should not feel like a side-scroller or platformer.

Important constraints:

- Camera style is top-down 2D framing.
- Movement is on the 2D X/Y map plane.
- There is no gravity.
- There is no side-view platforming.
- Placeholder visuals should imply a village test area, not a horizontal side-view level.

## Goals

Phase 0 is complete when:

- The project has a clean folder structure for future work.
- Pressing Play launches a main scene.
- A simple top-down test world appears.
- A placeholder player appears on the map.
- The player can move in 8 directions using keyboard input.
- The player uses `CharacterBody2D`, making future collision and combat work straightforward.
- The camera follows the player from a top-down 2D perspective.
- The test scene includes placeholder ground, paths, and obstacles that match the planned village RPG direction.

## Non-Goals

Phase 0 will not implement:

- Enemies.
- Combat.
- Health.
- Cards.
- Decks.
- Inventory.
- NPCs.
- Dialogue.
- Quests.
- Save/load.
- Final art.
- Procedural generation.
- Custom card editing.

## Folder Structure

Create this initial structure:

```text
assets/
assets/art/
assets/audio/
assets/fonts/
documents/
docs/superpowers/specs/
resources/
resources/cards/
resources/enemies/
resources/items/
resources/status_effects/
scenes/
scenes/main/
scenes/player/
scenes/world/
scripts/
scripts/player/
scripts/world/
ui/
```

This structure keeps early work simple while reserving clear homes for later RPG and card-system content.

## Scene Architecture

### Main Scene

Path:

```text
scenes/main/Main.tscn
```

Responsibilities:

- Serve as the project entry point.
- Instance the current world scene.
- Stay intentionally thin so later global flow can be added without moving gameplay logic into the root scene.

### World Scene

Path:

```text
scenes/world/World.tscn
```

Responsibilities:

- Hold the Phase 0 test area.
- Instance the player.
- Provide placeholder ground, path, and obstacle layout.
- Establish the top-down village-map feeling.

The world should include simple placeholder geometry:

- Grass/background area.
- Dirt or stone path area.
- A few obstacle blocks standing in for houses, trees, rocks, or fences.
- Collision on obstacles so movement can be tested against world boundaries.

### Player Scene

Path:

```text
scenes/player/Player.tscn
```

Responsibilities:

- Represent the player as a top-down placeholder.
- Use `CharacterBody2D`.
- Include a visible placeholder body.
- Include a collision shape.
- Include a `Camera2D` configured for top-down following.

The placeholder player should read as a map token or top-down character marker. It should not be designed like a side-view platformer character.

## Script Architecture

### Player Controller

Path:

```text
scripts/player/PlayerController.gd
```

Responsibilities:

- Read movement input.
- Normalize diagonal movement.
- Move the `CharacterBody2D` using Godot 4 movement APIs.
- Keep movement simple and deterministic.

Public tuning values:

- `move_speed`: default player movement speed.

The script should not include combat, animation state machines, card logic, or inventory logic.

## Input Mapping

Add these actions to `project.godot`:

```text
move_up
move_down
move_left
move_right
interact
attack
open_deck
use_card_1
use_card_2
use_card_3
use_card_4
```

Phase 0 will actively use only movement actions. The other actions are added now so later phases have stable names.

Recommended bindings:

- `move_up`: W, Up Arrow
- `move_down`: S, Down Arrow
- `move_left`: A, Left Arrow
- `move_right`: D, Right Arrow
- `interact`: E
- `attack`: Space or Left Mouse Button
- `open_deck`: Tab
- `use_card_1`: 1
- `use_card_2`: 2
- `use_card_3`: 3
- `use_card_4`: 4

## Camera

The Phase 0 camera is a Godot `Camera2D` attached to or following the player. It is top-down framing only.

Behavior:

- Center on the player.
- Use a stable zoom suitable for a village test map.
- No side-view angle, gravity framing, or platformer-style horizontal level composition.

## Data Flow

The flow is intentionally simple:

```text
project.godot
  -> scenes/main/Main.tscn
	-> scenes/world/World.tscn
	  -> scenes/player/Player.tscn
		-> scripts/player/PlayerController.gd
```

Input actions are defined globally in `project.godot`. `PlayerController.gd` reads those actions and moves the player in the world scene.

## Error Handling

Phase 0 has little runtime error surface. The main risk is broken scene references or missing input actions.

Mitigations:

- Set `Main.tscn` as the project run scene.
- Keep scene paths stable.
- Use Godot input actions rather than hard-coded key checks.
- Keep the player controller small enough to inspect quickly.

## Testing Plan

Manual test in Godot:

1. Open the project.
2. Press Play.
3. Confirm `Main.tscn` launches.
4. Confirm the top-down test world appears.
5. Confirm the player appears.
6. Move with WASD.
7. Move with arrow keys.
8. Confirm diagonal movement is not faster than cardinal movement.
9. Confirm the camera follows the player.
10. Confirm obstacle collision blocks player movement.

Optional command-line validation, if the Godot executable is available:

```text
godot --headless --path /Users/ming/gaame --quit
```

## Acceptance Criteria

Phase 0 is accepted when:

- All planned directories exist.
- `project.godot` points to `scenes/main/Main.tscn`.
- The input map contains the agreed actions.
- The project runs into a top-down test world.
- The player can move in 8 directions.
- The camera follows from a top-down 2D perspective.
- The scene layout resembles the beginning of a medieval village test map using placeholders.
- The implementation remains small and ready for Phase 1.

## Phase 1 Handoff

After Phase 0, Phase 1 can add:

- Player animation states.
- Basic enemy scene.
- Health and damage components.
- Hitboxes and hurtboxes.
- A first attack action.
- A first simple card action once combat exists.

Phase 0 should not pre-build these systems, but it should leave the project organized so they fit naturally.
