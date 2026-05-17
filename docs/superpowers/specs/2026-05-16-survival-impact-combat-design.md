# Survival Impact Combat Design

## Summary

This pass shifts the combat test from a small static encounter into an endless survival arena and adds the first lightweight version of impact combat. Enemies spawn forever, always chase the player, and become useful physical objects that can be launched into walls, obstacles, and other enemies.

The goal is to make the battlefield itself satisfying: enemies are not only targets, they are projectiles.

## Approved Direction

Prioritize the endless enemy survival loop first, then add minimal impact/slam mechanics in the same pass.

## Survival Loop

- Enemies spawn forever.
- Spawn points are near the map edges.
- First minute spawns slowly, around every `5s`.
- Spawn frequency increases over time.
- Active enemy count is capped to keep the prototype readable.
- Spawned enemies always chase the player.
- Spawned enemies do not idle by distance.
- Spawned enemies do not return home.

## Impact Mechanics

### Enemy As Projectile

When the player hits an enemy hard enough, the enemy enters a launched state. While launched, it can slam into obstacles or other enemies.

Tiny version:

- Player knockback marks enemy as launched briefly.
- Launched enemy moves with its knockback velocity.
- During launch, collision checks can trigger slam effects.

### Wall Slam

If a launched enemy hits an obstacle or boundary:

- Enemy takes slam damage.
- Enemy recoils/stuns.
- A smash mark appears.
- HUD shows `Wall Slam`.

### Crowd Crush

If a launched enemy hits another enemy:

- Both enemies take slam damage.
- Both recoil.
- A smash mark appears.
- HUD shows `Crowd Crush`.

### Minimal Terrain Shatter

Add a few breakable crate placeholders.

If a launched enemy hits a crate:

- Crate disappears with a small visual pop.
- Enemy takes slam damage.
- HUD shows `Shatter`.

### Slam Charge

Big impacts build a simple slam charge.

Tiny version:

- Each wall slam, crowd crush, or shatter adds charge.
- When full, next player attack launches harder.
- HUD shows charge as text or message.

### Enemy Panic

Big impacts briefly disturb nearby enemies.

Tiny version:

- Enemies near a slam recoil away from the impact.
- This is similar to fear pulse, but triggered by slams, not only death.

### Smash Marks

Impact positions spawn temporary crack/scar marks.

Tiny version:

- Pure visual.
- Fades automatically.

## Architecture

### World

`World.gd` owns:

- Enemy spawn timer.
- Survival elapsed time.
- Spawn interval calculation.
- Active enemy cap.
- Spawn point selection.
- Combat message forwarding if needed.

### BasicEnemy

`BasicEnemy.gd` changes:

- Add `always_chase` mode.
- Add launched state.
- Detect slam collision during launch.
- Add slam helper methods.
- Existing enemy mechanics remain where possible.

### Effects

Add:

- `SmashMark.tscn`
- Optional breakable crate placeholder scene.

### HUD

Existing combat message label can display:

- `Wall Slam`
- `Crowd Crush`
- `Shatter`
- `Slam Charged`

## Acceptance Criteria

- Enemies spawn forever.
- Spawn frequency increases over time.
- Enemies always chase the player.
- Static starting enemies are replaced or no longer the main test.
- Launched enemies can slam into walls/obstacles.
- Launched enemies can slam into other enemies.
- Big impacts show visible feedback.
- Slam charge can empower a later attack.
- Godot headless validation passes.
