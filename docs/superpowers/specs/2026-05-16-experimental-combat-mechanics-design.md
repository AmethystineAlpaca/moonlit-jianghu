# Experimental Combat Mechanics Design

## Summary

This pass adds tiny experimental versions of six combat mechanics to make the current arena combat more satisfying and distinctive: perfect guard, counter attack, stagger, back attack, momentum attack, and fear pulse on kill.

The goal is not to fully mature every mechanic. The goal is to quickly test which ideas feel good in play, then polish the best ones later.

## Current Context

The project currently has:

- Top-down player movement.
- `J` melee attack with stamina cost.
- `K` guard with stamina drain.
- Exhaustion when stamina reaches zero.
- Basic enemies that chase, wind up attacks, recoil, and die with a pop.
- Hit pause, hit sparks, knockback, HUD HP/stamina, block feedback, and reset.

## Approved Scope

Implement tiny versions of all six mechanics:

- Perfect guard.
- Counter attack.
- Stagger.
- Weak side/back attack.
- Momentum attack.
- Fear pulse on kill.

No cards, no XP, no new enemy types, no new buttons.

## Mechanics

### Perfect Guard

When an enemy attack lands, if the player started guarding recently, it becomes a perfect guard.

Tiny version:

- Perfect guard window: about `0.25s` after entering guard.
- Blocks all damage.
- Restores stamina.
- Knocks the enemy back.
- Recoils/stuns the enemy briefly.
- Shows `Perfect Guard` feedback.
- Grants a counter-ready state.

### Counter Attack

After a perfect guard, the player's next `J` attack within a short window becomes a counter.

Tiny version:

- Counter window: about `1.5s`.
- Counter attack deals more damage.
- Counter attack has stronger knockback.
- Counter attack has stronger feedback.
- Counter is consumed on use.

### Stagger

Enemies build stagger from hits and perfect guards.

Tiny version:

- Normal hit adds small stagger.
- Perfect guard adds larger stagger.
- When stagger reaches threshold, enemy enters a short recoil/stun.
- No stagger bar yet.

### Back Attack

Attacking from behind an enemy should feel special.

Tiny version:

- Compare attack direction with enemy facing direction.
- If player hits from behind, add bonus damage.
- Show a short `Back Hit` message.

### Momentum Attack

Attacking while moving into the slash should feel stronger.

Tiny version:

- If movement direction roughly matches attack direction, attack gets extra knockback and stagger.
- Show a short `Momentum` message.

### Fear Pulse

Killing an enemy should affect the encounter around it.

Tiny version:

- On death, nearby enemies briefly recoil.
- The effect is small but visible.

## Architecture

### PlayerController

Add:

- Perfect guard timing.
- Counter-ready timer.
- Attack modifiers for counter and momentum.
- HUD message signals.
- Calls into enemy helper methods for stagger, recoil, back-hit checks, and fear pulse.

### BasicEnemy

Add:

- `facing_direction`.
- `apply_stagger(amount)`.
- `apply_recoil(duration)`.
- `trigger_fear_from(source_position)`.
- `is_hit_from_behind(attacker_position)`.
- Death pulse that affects nearby enemies.

### HUD

Add:

- One short combat message label, reused for:
  - `Perfect Guard`
  - `Counter Ready`
  - `Back Hit`
  - `Momentum`

## Acceptance Criteria

- Perfect guard blocks all damage and shows feedback.
- Perfect guard enables a counter.
- Counter attack is visibly stronger than normal attack.
- Repeated hits can stagger enemies.
- Back attacks produce bonus feedback and extra damage.
- Momentum attacks produce bonus feedback and stronger impact.
- Killing one enemy briefly affects nearby enemies.
- Existing movement, reset, stamina, and basic combat still work.
