# Combat Feel Polish Design

## Summary

This pass improves the feel and readability of the existing combat system without adding new combat mechanics.

The current loop already has melee attacks, stamina, dash, guard, perfect guard, counter attacks, stagger, back hits, momentum attacks, hit pause, hit sparks, knockback, enemy windup, corpse impacts, and HUD combat messages. The next improvement should make those existing mechanics feel more physical and easier to understand moment to moment.

The focus is a tight polish pass: weapon presence, impact hierarchy, guard/counter feedback, enemy readability, and visual identity fixes.

## Current Context

The project currently has:

- A top-down player with movement, facing direction, stamina, dash, guard, and melee attack.
- `J`/attack input that creates a directional melee query in `PlayerController`.
- A slash-like `AttackPreview` polygon.
- Hit sparks, hit pause, enemy flash, enemy knockback, and enemy HP bars.
- Enemy attack windup with an `AttackWarning` node.
- Perfect guard, counter-ready state, counter bonus, back hit bonus, momentum bonus, stagger, and corpse/body impacts.
- HUD messages for special combat events.
- Tests for enemy hit feedback, player damage feedback, corpse behavior, targeting, skill integration, and visual polish.

The current test suite exposes a visual identity gap in `test_retro_xianxia_entity_visuals.gd`: player sword presence, crisp pixel filtering, and enemy/zombie accent helpers are expected but not currently satisfied.

## Goals

- Make the player attack feel like a physical weapon swing, not only a hitbox and preview polygon.
- Make normal hits and special hits visually distinct.
- Make perfect guard and counter feel more rewarding and readable.
- Make enemy windup, attack release, stagger, and blocked states easier to parse.
- Fix the visual identity gaps that directly affect combat readability.
- Preserve current combat rules and tuning unless a tiny value adjustment is needed to support feedback timing.

## Non-Goals

- No new combat buttons.
- No new combat mechanics.
- No new enemy archetypes.
- No card or XP work.
- No large combat architecture rewrite.
- No full animation system migration.

## Recommended Approach

Use a tight polish pass on the existing scripts and scenes.

This is preferred over a broader combat refactor because the current mechanics are still young and need tactile validation before the architecture is split. Small helper methods are acceptable where they clarify feedback selection, but this pass should avoid moving large blocks of logic between files.

## Design

### Weapon Presence

Add a visible player weapon node to `Player.tscn`.

The weapon should:

- Be visible at rest.
- Follow the player's facing direction.
- Swing briefly when melee attack starts.
- Return to a readable resting pose after the swing.
- Use crisp pixel filtering or simple polygon visuals consistent with the current prototype.

The first version can be a simple sword shape made from Godot nodes. It does not need sprite-sheet animation.

### Attack Visual Variants

Keep the current `AttackPreview` concept, but allow it to vary based on attack context.

Normal attack:

- Short slash preview.
- Standard yellow/white hit spark.
- Current or slightly shortened hit pause.

Counter attack:

- Brighter slash color.
- Larger hit spark.
- Slightly stronger hit pause.
- Stronger weapon swing pose.

Back hit:

- Distinct accent color or angled spark.
- HUD message remains useful because the condition is spatial and easy to miss.

Momentum attack:

- Wider or longer slash cue.
- Stronger knockback remains the main readable result.
- HUD message can stay, but it should not override higher-priority messages like counter.

Impact Strike / slam-related hits:

- Largest spark and strongest impact cue.
- Existing world combat messages can remain.

### Impact Hierarchy

Normal hits should be mostly diegetic: spark, flash, pulse, knockback, and tiny pause.

HUD combat text should be reserved for special events:

- Perfect Guard / Counter Ready.
- Counter.
- Back Hit.
- Momentum.
- Impact Strike.
- Slam/body impact messages.
- Skill cast results.

If multiple special events happen on one attack, choose a simple priority order instead of letting messages overwrite each other unpredictably:

1. Impact Strike / slam-related messages.
2. Counter.
3. Back Hit.
4. Momentum.

### Guard And Counter Feedback

Perfect guard should feel like a crisp defensive success.

Add or tune:

- A short cyan/white guard burst around the player.
- A slightly stronger freeze than normal hit pause.
- Immediate enemy recoil/knockback remains.
- Counter-ready state should be visible through body/ring color for the full counter window.

Counter attack should feel connected to the guard success:

- Counter swing uses the stronger attack visual variant.
- Counter hit spark is larger or brighter.
- Counter hit pause is stronger than normal hit pause.
- Counter message remains visible briefly.

### Enemy Readability

Improve enemy state feedback without changing enemy behavior.

Windup:

- Keep the warning marker.
- Strengthen the enemy body/facing color during windup.
- Add a slight scale or pose change while winding up.

Attack release:

- Add a tiny snap/lunge or facing-marker pulse when damage is attempted.
- Keep this visual short so it does not look like a new dash mechanic.

Blocked or perfect-guarded attack:

- Enemy should visibly recoil.
- The guard burst should make the cause of recoil clear.

Stagger:

- Keep the yellow/orange flash.
- Make stagger recoil visually distinct from normal hit recoil through a longer pulse or stronger body tint.

Death and corpse impact:

- Preserve corpse flight and body impact behavior.
- Keep messages for `Crowd Crush`, `Shatter`, `Wall Slam`, `Corpse Hit`, and `Body Slam`.
- Avoid adding extra text for normal death if the physical result is already visible.

### Visual Identity Fixes

Fix the combat-related visual identity gaps exposed by tests:

- Player body keeps crisp pixels.
- Player has a visible sword visual.
- Player attack moves the sword.
- Basic and fast enemies expose stable visual accent colors.
- Corpses preserve the source enemy accent.
- Zombies expose inherited/corrupted visual accent colors.

These fixes are part of combat feel because clear silhouettes, weapon presence, and enemy identity are prerequisites for readable melee combat.

## Architecture

### PlayerController

Keep combat ownership in `PlayerController` for this pass.

Add small helper methods as needed:

- Start and update weapon swing feedback.
- Select an attack feedback variant for normal, counter, back hit, momentum, and impact strike.
- Apply special-hit message priority.
- Trigger stronger hit pause only for special feedback variants.

Avoid extracting a new `PlayerCombat` script in this pass unless the implementation becomes hard to follow.

### BasicEnemy

Keep AI and damage behavior in `BasicEnemy`.

Add small feedback helpers as needed:

- Windup visual refresh.
- Attack release visual pulse.
- Stagger visual pulse.
- Visual accent getter.

Do not change detection, pathing, leash, target selection, or attack rules.

### HUD

Keep HUD combat messages, but treat them as special-event feedback.

The HUD should not need to know detailed combat rules. It should continue to display messages emitted by player or world systems.

### Scenes

Update scene nodes where needed:

- `Player.tscn`: add sword/weapon visual node and ensure crisp visual filtering.
- Enemy scenes: ensure body visuals and accent state are stable across basic, fast, corpse, and zombie variants.
- Effect scenes: reuse `HitSpark` by adding parameterized setup methods before adding new effect scenes.

## Data Flow

Player attack flow:

```text
Attack input
  -> PlayerController validates stamina/cooldown/state
  -> weapon swing starts
  -> attack preview variant appears
  -> melee query finds enemies
  -> attack context chooses damage, knockback, stagger, message priority, and visual variant
  -> enemy receives knockback/stagger/damage
  -> hit spark variant appears
  -> hit pause applies based on impact strength
```

Enemy attack flow:

```text
Enemy reaches attack range
  -> windup starts
  -> warning and windup pose appear
  -> attack releases
  -> player handles incoming attack
  -> normal damage, block, or perfect guard resolves
  -> enemy recoil and guard/counter feedback appear when appropriate
```

## Error Handling And Edge Cases

- If the weapon node is missing, combat should still function; feedback helpers should null-check the node.
- If an enemy lacks a health component, it should continue to be ignored by player melee damage.
- If multiple special conditions happen on one attack, message priority should choose one clear message.
- If an enemy dies during a special hit, death/corpse behavior should still run normally.
- If the game is paused for hit pause, existing process modes must continue to allow the pause timer to complete.

## Testing

Run the existing Godot test suite.

Expected covered areas:

- Existing enemy hit feedback remains.
- Existing player damage feedback remains.
- Existing zombie targeting remains.
- Existing corpse behavior remains.
- Visual identity tests pass for player sword, pixel filtering, enemy accents, corpses, and zombies.

Add focused tests for:

- Player sword exists.
- Player sword rotation or pose changes when `_try_melee_attack()` runs.
- Special attack feedback does not break normal damage application.
- Perfect guard still blocks damage and enables counter.

## Acceptance Criteria

This pass is accepted when:

- The player has a visible weapon at rest.
- Pressing attack visibly swings the weapon.
- Normal hit, counter, back hit, and momentum hit have distinguishable feedback.
- Perfect guard has a stronger visual and timing cue than normal block.
- Counter attack feels visually connected to perfect guard.
- Enemy windup and attack release are easier to read.
- Stagger/recoil remains readable.
- Existing combat behavior still works.
- Existing tests pass, including the current visual identity failures.
- No new combat mechanics are introduced.
