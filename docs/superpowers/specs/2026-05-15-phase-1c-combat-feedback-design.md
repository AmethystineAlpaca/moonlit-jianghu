# Phase 1C Combat Feedback Design

## Summary

Phase 1C makes the existing basic combat loop readable. The player already has movement, health, a directional melee attack, and one enemy that chases and deals damage. This phase adds immediate visual feedback so the player can understand attack direction, successful hits, enemy health, player damage, and defeat.

The goal is readable prototype feedback, not final animation polish.

## Current Project Context

The project currently has:

- A top-down village test world.
- A player with movement, facing direction, health, and a `J` melee attack.
- A basic enemy with chase AI, contact damage, and health.
- A simple HUD that displays player HP.
- A centered attack preview that currently appears as a rectangle.

The project is not a git repository, so this spec cannot be committed from the current environment.

## Approved Direction

Use readable prototype feedback.

This includes:

- Replace the visible attack rectangle with a translucent slash wedge/arc.
- Keep the actual damage check simple and reliable.
- Add hit flashes.
- Add light enemy knockback.
- Add an enemy HP bar.
- Add player hurt feedback.
- Add a simple defeated state.

## Goals

Phase 1C is complete when:

- Pressing `J` shows a slash-like visual in the player's facing direction.
- Hitting an enemy makes the enemy flash.
- Hitting an enemy nudges it backward.
- Enemy HP is visible above the enemy.
- Enemy HP updates when damaged.
- Player flashes when damaged.
- Player HP still updates in the HUD.
- Player reaches 0 HP and enters a defeated state.
- Defeated state disables player movement and attacking.
- HUD shows a simple defeated message.

## Non-Goals

Phase 1C will not implement:

- Card UI.
- Card effects.
- New enemy types.
- Loot or experience.
- Sound effects.
- Particle effects.
- Screen shake.
- Final character animations.
- Final UI styling.

## Architecture

### Health Component

Path:

```text
scripts/components/HealthComponent.gd
```

Add a `damaged(amount)` signal. This lets player and enemy feedback react to damage without duplicating health logic.

### Player Controller

Path:

```text
scripts/player/PlayerController.gd
```

Add:

- A defeated flag.
- Player hurt flash when health emits `damaged`.
- Disable movement and melee when health emits `died`.
- Replace the attack preview rectangle behavior with a slash visual node.

The real damage query can remain rectangle-based for this phase.

### Enemy

Path:

```text
scripts/enemies/BasicEnemy.gd
```

Add:

- Damage flash.
- Knockback impulse when hit.
- HP bar connection.
- HP bar update on health changes.

The enemy should still disappear on death.

### Enemy Scene

Path:

```text
scenes/enemies/BasicEnemy.tscn
```

Add:

- A simple HP bar above the enemy.
- A body node that can visibly flash.

### HUD

Paths:

```text
ui/Hud.tscn
scripts/ui/Hud.gd
```

Add:

- A simple defeated label.
- Show it only after player death.

## Data Flow

Enemy hit flow:

```text
Player presses J
  -> slash visual appears
  -> melee query finds enemy
  -> enemy health takes damage
  -> health emits damaged and health_changed
  -> enemy flashes
  -> enemy HP bar updates
  -> enemy knockback is applied
```

Player damage flow:

```text
Enemy reaches attack range
  -> player health takes damage
  -> health emits damaged and health_changed
  -> player flashes
  -> HUD HP updates
  -> if HP reaches 0, player dies
  -> player controller disables movement and attack
  -> HUD shows Defeated
```

## Testing Plan

Manual test:

1. Run the project.
2. Press `J` while facing different directions.
3. Confirm the slash visual appears in front of the player.
4. Move near the enemy.
5. Hit the enemy.
6. Confirm enemy flashes and HP bar decreases.
7. Confirm enemy is nudged back.
8. Let enemy damage the player.
9. Confirm player flashes and HUD HP decreases.
10. Let player HP reach 0.
11. Confirm movement and attack stop.
12. Confirm HUD shows defeated.
13. Confirm enemy still dies when HP reaches 0.

## Acceptance Criteria

Phase 1C is accepted when combat is readable without opening debug tools:

- Attack direction is visible.
- Successful hits are visible.
- Enemy health is visible.
- Player damage is visible.
- Player defeat is visible.
- No cards or extra systems are introduced yet.
