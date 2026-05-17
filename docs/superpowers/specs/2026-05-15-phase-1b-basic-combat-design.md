# Phase 1B Basic Combat Design

## Summary

Phase 1B adds the first real combat loop to the top-down medieval RPG prototype. The player will press `J` to perform a directional melee attack based on their current facing direction. A simple enemy will detect, chase, and damage the player at close range. Both player and enemy will use a shared health component.

The goal is not polished combat. The goal is to prove the loop: move, face, attack, damage, kill, and take damage.

## Current Project Context

The project currently has:

- A runnable `Main.tscn`.
- A top-down village-style `World.tscn`.
- A movable `Player.tscn`.
- `PlayerController.gd` with acceleration, deceleration, and facing direction.
- Reusable placeholder obstacle scenes.
- Input actions for movement, attack, interaction, deck, and future card slots.

The project is still not a git repository, so this spec cannot be committed from the current environment.

## Approved Direction

Use a simple chase enemy and directional melee attack.

Controls:

- Move: `WASD` and arrow keys.
- Basic melee attack: `J`.
- Existing attack bindings such as Space or mouse can remain temporarily, but `J` is the intended primary binding for this phase.

Enemy behavior:

- Idle while the player is outside detection range.
- Chase when the player enters detection range.
- Stop near the player.
- Damage the player on a cooldown when close enough.
- Die when health reaches zero.

## Goals

Phase 1B is complete when:

- The player has health.
- At least one enemy exists in the world.
- The enemy has health.
- The enemy can detect and chase the player.
- The enemy can damage the player.
- The player can press `J` to perform a melee attack in the current facing direction.
- The attack can damage and kill the enemy.
- The player has a simple visible HP display.

## Non-Goals

Phase 1B will not implement:

- Card actions.
- Decks.
- Skills.
- Player death screen.
- Enemy pathfinding around complex obstacles.
- Patrol routes.
- Animation polish.
- Loot.
- Experience.
- Sound effects.
- Final UI styling.

## Architecture

### Health Component

Path:

```text
scripts/components/HealthComponent.gd
```

Responsibilities:

- Store `max_health` and `current_health`.
- Provide `take_damage(amount)`.
- Emit `health_changed(current, max)`.
- Emit `died` when health reaches zero.

This component should be reusable by player, enemies, and later destructible objects.

### Player Combat

Path:

```text
scripts/player/PlayerController.gd
```

Responsibilities added in Phase 1B:

- Listen for the `attack` input action.
- Use `last_facing_direction` to position a melee hitbox in front of the player.
- Apply damage to enemies inside that hitbox.
- Enforce a short attack cooldown.

The player controller may own the first melee implementation for speed. If it grows too large in later phases, combat can be moved into a separate `PlayerCombat.gd`.

### Enemy

Scene:

```text
scenes/enemies/BasicEnemy.tscn
```

Script:

```text
scripts/enemies/BasicEnemy.gd
```

Responsibilities:

- Use `CharacterBody2D`.
- Find the player by group.
- Idle when far away.
- Chase the player inside detection radius.
- Stop at attack range.
- Damage the player on cooldown.
- Listen for its health component's `died` signal and remove itself.

### UI

Scene:

```text
ui/Hud.tscn
```

Script:

```text
scripts/ui/Hud.gd
```

Responsibilities:

- Display player HP as simple text or a basic bar.
- Connect to the player's health component.

This is intentionally a debug-grade HUD.

## Input Mapping

Update the `attack` action so `J` is included as the primary keyboard attack key.

Existing bindings may remain:

- Space can stay for now.
- Left mouse can stay for now.

The design direction is keyboard-first. Later phases can add:

- `K`: dodge or defensive move.
- `U/I/O/L`: cards or skills.

## Data Flow

Combat flow:

```text
Player presses J
  -> PlayerController reads attack input
  -> melee hitbox is placed in last_facing_direction
  -> overlapping enemy hurtboxes are checked
  -> enemy HealthComponent.take_damage()
  -> enemy dies if HP reaches zero
```

Enemy damage flow:

```text
Enemy detects player
  -> enemy chases player
  -> enemy reaches attack range
  -> enemy waits for attack cooldown
  -> player HealthComponent.take_damage()
  -> HUD updates from health_changed signal
```

## Error Handling

Main risks:

- Enemy cannot find the player.
- Health component path is missing.
- Attack hitbox damages the wrong target.
- Repeated collision checks apply too much damage.

Mitigations:

- Add player to a `"player"` group.
- Add enemies to an `"enemies"` group.
- Check for `HealthComponent` before applying damage.
- Use an attack cooldown and one damage application per attack.
- Keep debug values exported for easy tuning.

## Testing Plan

Manual test:

1. Open the project in Godot.
2. Press Play.
3. Confirm the player appears.
4. Confirm player HP appears.
5. Confirm an enemy appears.
6. Move near the enemy.
7. Confirm the enemy chases the player.
8. Let the enemy touch or approach the player.
9. Confirm player HP decreases on a cooldown.
10. Face the enemy and press `J`.
11. Confirm the enemy takes damage.
12. Keep attacking until the enemy disappears.
13. Confirm movement still works after combat.

## Acceptance Criteria

Phase 1B is accepted when:

- `J` performs a directional melee attack.
- The attack uses the player's facing direction.
- The enemy chases the player from a detection radius.
- The enemy damages the player at close range.
- Both player and enemy use the same health component pattern.
- The player HP display updates when damaged.
- The enemy can be killed.
- The implementation stays small enough to extend into card combat later.

## Phase 1C Handoff

After Phase 1B, the next phase can add the first card prototype:

- A card UI placeholder.
- One card mapped to a combat action.
- A simple draw/use loop.

The melee attack from Phase 1B should become the baseline physical action that cards can later modify or complement.
