# Skill System Foundation Design

## Goal

Prepare the combat prototype for future active skills without implementing specific skills yet. The foundation should support later abilities such as explosions, fireballs, illusions, doppelgangers, charm/conversion, summons, and other experimental effects.

The first implementation should wire the system for the player only, but the core design should be actor-agnostic so enemies can use the same system later.

## Current Context

The player controller currently owns movement, attack, dash, defense, stamina, hit feedback, and input handling. Enemies already expose useful combat hooks such as `HealthComponent`, `apply_knockback`, `apply_recoil`, `apply_stagger`, path-following chase behavior, and group membership through `enemies`.

The project already has placeholder inputs `use_card_1` through `use_card_4`, but the skill foundation should move toward explicit skill inputs now. The requested player-facing model is five selectable skill slots, selected with number keys `1` through `5`, and cast with `Space`.

## Recommended Approach

Use data-driven skill resources plus a reusable caster component.

This is a middle path between hard-coding individual skills in `PlayerController.gd` and building a full custom card or scripting graph too early. It keeps the current combat loop stable while creating clean extension points for future abilities.

## Core Pieces

### `SkillDefinition`

A `Resource` that describes a skill slot entry.

Initial fields:

- `display_name`
- `stamina_cost`
- `cooldown`
- `cast_range`
- `targeting_mode`
- `effect_scene`

The first targeting modes should be simple:

- `SELF`
- `FORWARD`
- `POINT`
- `NEAREST_ENEMY`

The first pass does not need custom card editing, deck logic, or a skill selection UI.

### `SkillCaster`

A reusable `Node` that can be added under the player now and under enemies later.

Responsibilities:

- Store skill slots.
- Track cooldowns per slot.
- Check whether the owner can cast.
- Spend stamina through the owner when available.
- Ask the owner for position and facing direction.
- Spawn the skill effect scene or call the effect script.
- Emit a combat message such as the skill display name.

The caster should depend on small owner methods instead of knowing player internals directly. Example owner methods:

- `get_skill_origin() -> Vector2`
- `get_skill_direction() -> Vector2`
- `can_spend_stamina(amount: float) -> bool`
- `spend_stamina(amount: float) -> void`

If a future enemy has no stamina, its caster can use definitions with zero cost or a different resource later.

### `SkillEffect`

A base script for spawned effect scenes.

Responsibilities:

- Receive a cast context: caster, origin, direction, target position, skill definition.
- Execute the effect.
- Clean itself up when finished.

Future effect categories can be built on this base:

- Projectile effect, for fireballs or bolts.
- Area effect, for explosions or shockwaves.
- Summon effect, for illusions or doppelgangers.
- Status effect, for charm, slow, burn, fear, or conversion.

## Player Wiring

Add a `SkillCaster` child to the player scene.

`PlayerController.gd` should keep movement/combat behavior, but skill-specific logic should live in `SkillCaster` and effect scripts. The player should only:

- expose the minimal owner methods needed by `SkillCaster`;
- maintain a selected skill slot, using `-1` to mean no selected skill;
- select slots `0` through `4` when skill-select inputs `1` through `5` are pressed;
- deselect back to no selected skill if the player presses the already-selected slot key again;
- call `SkillCaster.try_cast_slot(selected_slot)` when the skill-use input is pressed;
- reuse the existing stamina/exhaustion behavior for skill costs.

The first implementation may leave all skill slots empty or add harmless placeholder definitions. Empty slots should fail quietly or show a short combat message such as `No Skill`.

## Skill HUD

Add a bottom-center skill bar with five visible slots.

Each slot should show:

- its number key, `1` through `5`;
- a short skill name, using `Empty` for now;
- a highlighted visual state when selected.

When no skill is selected, no slot should be highlighted. The HUD may show a small `No Skill` state beside or above the bar.

The HUD should update from player or caster signals instead of polling whenever possible. Initial useful signals:

- `skill_slots_changed(slot_names: Array[String])`
- `selected_skill_changed(selected_slot: int)`

For this preparation pass, cooldown display can be omitted unless it is cheap to wire cleanly. The skill bar should be built so cooldown text or radial fill can be added later.

## Input Rules

Add or repurpose explicit skill inputs:

- `select_skill_1`: key `1`
- `select_skill_2`: key `2`
- `select_skill_3`: key `3`
- `select_skill_4`: key `4`
- `select_skill_5`: key `5`
- `use_selected_skill`: key `Space`
- `pause_game`: key `Escape`

Because `Space` currently triggers melee attack, melee attack should move to `J` and mouse click only. This keeps `Space` reserved for the selected skill.

Existing `use_card_1` through `use_card_4` can be replaced or left unused. The project is skipping cards for now, so new skill-named actions are clearer.

## Pause Rules

Pressing `Escape` toggles pause and resume.

While paused:

- combat, enemy spawning, movement, and effects should stop;
- the HUD should still process pause input;
- a centered `Paused` label should be visible;
- pressing `Escape` again should resume.

Implementation should use Godot pause mode/process mode intentionally so the HUD or pause controller can receive input while the tree is paused.

## Resource and Cooldown Rules

For now, active skills use stamina.

If a cast spends the last stamina point and stamina reaches zero, the existing exhaustion rule should apply: the player cannot attack, guard, dash, or cast again until stamina fully recovers.

Cooldowns are tracked independently per skill slot. A skill cannot cast while its slot cooldown is active, even if the player has enough stamina.

## Error Handling

The foundation should avoid crashes from incomplete setup:

- Empty slot: no cast, optional `No Skill` message.
- Missing effect scene: no cast, optional `Skill Missing Effect` message.
- Owner missing stamina methods: allow zero-cost skills, reject positive-cost skills.
- Invalid target: no cast.

## Testing and Verification

The first implementation should preserve existing combat behavior.

Verification should include:

- Godot headless parse/load check.
- Manual check that movement, attack, dash, guard, and enemy spawning still work.
- Manual check that pressing skill-slot keys with empty slots does not crash.
- Manual check that `1` through `5` select and toggle skill slots.
- Manual check that `Space` attempts selected skill use and no longer performs melee attack.
- Manual check that `J` and mouse still perform melee attack.
- Manual check that `Escape` pauses and resumes the game, with the pause label visible.

## Out of Scope

This foundation does not implement real fireballs, explosions, doppelgangers, charm, cards, deck building, enemy skill casting, or custom player-authored skill behavior.

Those should be added after the base casting contract is stable.
