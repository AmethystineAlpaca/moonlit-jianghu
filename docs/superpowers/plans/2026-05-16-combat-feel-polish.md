# Combat Feel Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the existing combat loop feel more physical and readable by adding weapon presence, clearer impact tiers, stronger guard/counter feedback, and stable entity visuals without adding new mechanics.

**Architecture:** Keep combat ownership in `PlayerController.gd` and enemy behavior in `BasicEnemy.gd` for this pass. Add small, named feedback helpers and scene nodes instead of a broad refactor. Use existing Godot scene/test patterns and keep the implementation compatible with the current headless test scripts.

**Tech Stack:** Godot 4.6 GDScript, `.tscn` scenes, `SceneTree` script tests, existing `/usr/local/bin/godot --headless --path . --script ...` test runner.

---

## File Structure

- Modify `scenes/player/Player.tscn`: add a visible `Sword` node, ensure player body uses nearest texture filtering, and keep existing combat nodes intact.
- Modify `scripts/player/PlayerController.gd`: cache the sword node, rotate it with facing direction, animate it on attack, choose attack feedback variants, prioritize special combat messages, parameterize hit sparks, and add stronger perfect-guard/counter feedback.
- Modify `scripts/enemies/BasicEnemy.gd`: add `visual_accent_color`, expose `get_visual_accent_color()`, keep zombie accent corruption readable, ensure crisp body filtering, and add windup/release/stagger visual helpers.
- Modify `scenes/enemies/BasicEnemy.tscn`, `scenes/enemies/FastEnemy.tscn`, and `scenes/allies/Zombie.tscn`: set visual accent colors and nearest filtering where scene-side values are needed.
- Modify `scripts/effects/TimedEffect.gd`: support simple color/scale setup so the existing `HitSpark.tscn` scene can represent normal, counter, back hit, and impact variants.
- Keep `tests/test_retro_xianxia_entity_visuals.gd` unchanged; use it as the acceptance test for player sword presence, sword movement, nearest filtering, and enemy accents.
- Create `tests/test_combat_feedback_variants.gd`: focused test for message priority, sword motion, special hit spark setup, and perfect guard/counter state.

The workspace currently is not a git repository, so commit steps are replaced with a local status note. If this folder later becomes a git repo, commit after each task.

---

### Task 1: Restore Combat Visual Identity Baseline

**Files:**
- Modify: `scripts/enemies/BasicEnemy.gd`
- Modify: `scenes/player/Player.tscn`
- Modify: `scenes/enemies/BasicEnemy.tscn`
- Modify: `scenes/enemies/FastEnemy.tscn`
- Modify: `scenes/allies/Zombie.tscn`
- Test: `tests/test_retro_xianxia_entity_visuals.gd`

- [ ] **Step 1: Run the existing failing visual identity test**

Run:

```bash
/usr/local/bin/godot --headless --path . --script tests/test_retro_xianxia_entity_visuals.gd
```

Expected: FAIL with current messages about player sword presence, nearest filtering, and enemy visual accent methods.

- [ ] **Step 2: Add enemy visual accent properties and helper**

In `scripts/enemies/BasicEnemy.gd`, add this export near the other visual exports:

```gdscript
@export var visual_accent_color: Color = Color(0.98, 0.36, 0.24, 1.0)
```

Add this method near `is_transformable_corpse()`:

```gdscript
func get_visual_accent_color() -> Color:
	if faction == "zombie":
		return visual_accent_color.lerp(zombie_body_tint, 0.35)
	return visual_accent_color
```

Update `_ready()` after `normal_body_scale = body.scale`:

```gdscript
	body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
```

- [ ] **Step 3: Set player body nearest filtering and add Sword node**

In `scenes/player/Player.tscn`, update the `Body` node block:

```gdscript
[node name="Body" type="Sprite2D" parent="."]
texture_filter = 1
texture = SubResource("GradientTexture2D_player")
```

Add this node after `FacingMarker`:

```gdscript
[node name="Sword" type="Node2D" parent="."]
position = Vector2(0, 0)

[node name="Blade" type="Polygon2D" parent="Sword"]
position = Vector2(0, 18)
color = Color(0.92, 0.96, 1, 1)
polygon = PackedVector2Array(-2, 0, 2, 0, 3, 22, 0, 28, -3, 22)

[node name="Guard" type="Polygon2D" parent="Sword"]
position = Vector2(0, 16)
color = Color(1, 0.82, 0.35, 1)
polygon = PackedVector2Array(-7, -1, 7, -1, 7, 2, -7, 2)

[node name="Hilt" type="Polygon2D" parent="Sword"]
position = Vector2(0, 10)
color = Color(0.32, 0.18, 0.08, 1)
polygon = PackedVector2Array(-2, -5, 2, -5, 2, 7, -2, 7)
```

- [ ] **Step 4: Set enemy scene accent values and nearest filtering**

In `scenes/enemies/BasicEnemy.tscn`, update the root and body blocks:

```gdscript
[node name="BasicEnemy" type="CharacterBody2D" groups=["enemies"]]
script = ExtResource("1_enemy")
visual_accent_color = Color(0.98, 0.36, 0.24, 1)

[node name="Body" type="Sprite2D" parent="."]
texture_filter = 1
texture = SubResource("GradientTexture2D_enemy")
```

In `scenes/enemies/FastEnemy.tscn`, update the body block:

```gdscript
[node name="Body" type="Sprite2D" parent="."]
texture_filter = 1
texture = SubResource("GradientTexture2D_fast_enemy")
```

In `scenes/allies/Zombie.tscn`, update the body block:

```gdscript
[node name="Body" type="Sprite2D" parent="."]
texture_filter = 1
texture = SubResource("GradientTexture2D_zombie")
```

- [ ] **Step 5: Run the visual identity test**

Run:

```bash
/usr/local/bin/godot --headless --path . --script tests/test_retro_xianxia_entity_visuals.gd
```

Expected: FAIL only on `player attack animation swings sword`. All nearest filtering, sword presence, and enemy accent assertions should pass before moving to Task 2.

---

### Task 2: Add Player Weapon Facing And Swing Feedback

**Files:**
- Modify: `scripts/player/PlayerController.gd`
- Test: `tests/test_retro_xianxia_entity_visuals.gd`

- [ ] **Step 1: Confirm sword movement still fails before code changes**

Run:

```bash
/usr/local/bin/godot --headless --path . --script tests/test_retro_xianxia_entity_visuals.gd
```

Expected before implementation: FAIL on `player attack animation swings sword` if Task 1 did not already make the sword move.

- [ ] **Step 2: Cache sword node and add swing state**

In `scripts/player/PlayerController.gd`, add onready properties near the other visual nodes:

```gdscript
@onready var sword: Node2D = $Sword
```

Add exports near the attack feedback exports:

```gdscript
@export var sword_rest_offset: float = -0.35
@export var sword_swing_arc: float = 1.35
@export var sword_swing_duration: float = 0.16
```

Add state variables near the other timers:

```gdscript
var sword_swing_timer: float = 0.0
var sword_swing_strength: float = 1.0
```

- [ ] **Step 3: Update sword rotation every physics frame**

In `_physics_process(delta)`, after facing direction is updated and before attack input handling, add:

```gdscript
	_update_sword_feedback(delta)
```

Add these helper methods near `_show_attack_preview()`:

```gdscript
func _start_sword_swing(strength: float = 1.0) -> void:
	if sword == null:
		return
	sword_swing_timer = sword_swing_duration
	sword_swing_strength = maxf(strength, 0.1)
	_update_sword_feedback(0.0)

func _update_sword_feedback(_delta: float) -> void:
	if sword == null:
		return

	var facing_angle := last_facing_direction.angle() - PI * 0.5
	var swing_offset := sword_rest_offset
	if sword_swing_timer > 0.0:
		sword_swing_timer -= _delta
		var progress := 1.0 - clampf(sword_swing_timer / maxf(sword_swing_duration, 0.001), 0.0, 1.0)
		var eased := sin(progress * PI)
		swing_offset += eased * sword_swing_arc * sword_swing_strength
		if sword_swing_timer <= 0.0:
			sword_swing_timer = 0.0
	sword.rotation = facing_angle + swing_offset
```

- [ ] **Step 4: Start weapon swing when attack starts**

In `_try_melee_attack()`, after `_show_attack_preview()`, add:

```gdscript
	_start_sword_swing(1.0)
```

Task 3 can later replace this `1.0` strength with a variant-specific value. For Task 2, keep the value exactly `1.0`.

- [ ] **Step 5: Run the visual identity test**

Run:

```bash
/usr/local/bin/godot --headless --path . --script tests/test_retro_xianxia_entity_visuals.gd
```

Expected: PASS.

---

### Task 3: Parameterize Hit Sparks And Attack Feedback Variants

**Files:**
- Modify: `scripts/effects/TimedEffect.gd`
- Modify: `scripts/player/PlayerController.gd`
- Create: `tests/test_combat_feedback_variants.gd`

- [ ] **Step 1: Write a focused failing test for feedback helpers**

Create `tests/test_combat_feedback_variants.gd`:

```gdscript
extends SceneTree

const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const HIT_SPARK_SCENE := preload("res://scenes/effects/HitSpark.tscn")

var failures := 0

func _initialize() -> void:
	await _test_hit_spark_can_be_configured()
	await _test_combat_message_priority_prefers_counter_over_momentum()
	quit(failures)

func _test_hit_spark_can_be_configured() -> void:
	var spark := HIT_SPARK_SCENE.instantiate()
	root.add_child(spark)
	await process_frame

	_assert_true(spark.has_method("configure"), "hit spark exposes configure")
	spark.configure(Color(0.2, 0.9, 1.0, 1.0), Vector2(1.2, 1.2), Vector2(2.4, 2.4), 0.22)
	_assert_equal(spark.get("start_scale"), Vector2(1.2, 1.2), "spark start scale can be configured")
	_assert_equal(spark.get("end_scale"), Vector2(2.4, 2.4), "spark end scale can be configured")
	_assert_true(is_equal_approx(spark.get("lifetime"), 0.22), "spark lifetime can be configured")

	spark.free()

func _test_combat_message_priority_prefers_counter_over_momentum() -> void:
	var player := PLAYER_SCENE.instantiate()
	root.add_child(player)
	await process_frame

	_assert_true(player.has_method("_choose_combat_message"), "player exposes combat message priority helper")
	var message: String = player.call("_choose_combat_message", false, true, true, false)
	_assert_equal(message, "Counter", "counter message wins over back hit and momentum")

	player.free()

func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	failures += 1
	push_error(message)

func _assert_equal(actual, expected, message: String) -> void:
	if actual == expected:
		return
	failures += 1
	push_error("%s: expected %s, got %s" % [message, expected, actual])
```

- [ ] **Step 2: Run the new test and verify it fails**

Run:

```bash
/usr/local/bin/godot --headless --path . --script tests/test_combat_feedback_variants.gd
```

Expected: FAIL because `configure` and `_choose_combat_message` do not exist yet.

- [ ] **Step 3: Add configurable effect setup**

In `scripts/effects/TimedEffect.gd`, add:

```gdscript
func configure(effect_color: Color, new_start_scale: Vector2, new_end_scale: Vector2, new_lifetime: float) -> void:
	start_scale = new_start_scale
	end_scale = new_end_scale
	lifetime = maxf(new_lifetime, 0.01)
	modulate = effect_color
	scale = start_scale
```

- [ ] **Step 4: Add attack variant helpers**

In `scripts/player/PlayerController.gd`, add constants near the preloads:

```gdscript
const ATTACK_VARIANT_NORMAL := "normal"
const ATTACK_VARIANT_COUNTER := "counter"
const ATTACK_VARIANT_BACK_HIT := "back_hit"
const ATTACK_VARIANT_MOMENTUM := "momentum"
const ATTACK_VARIANT_IMPACT := "impact"
```

Add helpers near `_spawn_hit_spark()`:

```gdscript
func _choose_attack_variant(is_impact: bool, is_counter: bool, is_back_hit: bool, has_momentum: bool) -> String:
	if is_impact:
		return ATTACK_VARIANT_IMPACT
	if is_counter:
		return ATTACK_VARIANT_COUNTER
	if is_back_hit:
		return ATTACK_VARIANT_BACK_HIT
	if has_momentum:
		return ATTACK_VARIANT_MOMENTUM
	return ATTACK_VARIANT_NORMAL

func _choose_combat_message(is_impact: bool, is_counter: bool, is_back_hit: bool, has_momentum: bool) -> String:
	if is_impact:
		return "Impact Strike"
	if is_counter:
		return "Counter"
	if is_back_hit:
		return "Back Hit"
	if has_momentum:
		return "Momentum"
	return ""

func _get_variant_spark_color(variant: String) -> Color:
	match variant:
		ATTACK_VARIANT_IMPACT:
			return Color(1.0, 0.62, 0.18, 1.0)
		ATTACK_VARIANT_COUNTER:
			return Color(0.35, 1.0, 0.95, 1.0)
		ATTACK_VARIANT_BACK_HIT:
			return Color(1.0, 0.35, 0.72, 1.0)
		ATTACK_VARIANT_MOMENTUM:
			return Color(1.0, 0.92, 0.32, 1.0)
		_:
			return Color(1.0, 0.94, 0.45, 1.0)

func _get_variant_spark_end_scale(variant: String) -> Vector2:
	match variant:
		ATTACK_VARIANT_IMPACT:
			return Vector2(2.5, 2.5)
		ATTACK_VARIANT_COUNTER:
			return Vector2(2.2, 2.2)
		ATTACK_VARIANT_BACK_HIT:
			return Vector2(2.0, 2.0)
		ATTACK_VARIANT_MOMENTUM:
			return Vector2(2.05, 2.05)
		_:
			return Vector2(1.8, 1.8)
```

- [ ] **Step 5: Use variant helpers in attack flow**

In `_try_melee_attack()`, replace direct message emits for impact/counter/momentum/back hit with local booleans:

```gdscript
	var is_impact_attack := false
	if world != null and world.has_method("consume_slam_charge") and world.consume_slam_charge():
		is_impact_attack = true
		attack_knockback += 260.0
		stagger_amount += 2.0
```

Inside each hit, compute back hit before applying effects:

```gdscript
			var is_back_hit := collider.has_method("is_hit_from_behind") and collider.is_hit_from_behind(global_position)
			var final_damage := attack_damage
			if is_back_hit:
				final_damage += back_attack_damage_bonus
				stagger_amount += 0.75
			var attack_variant := _choose_attack_variant(is_impact_attack, is_counter_attack, is_back_hit, has_momentum)
			var message := _choose_combat_message(is_impact_attack, is_counter_attack, is_back_hit, has_momentum)
			if message != "":
				combat_message_requested.emit(message)
```

Replace `_spawn_hit_spark(collider.global_position)` with:

```gdscript
			_spawn_hit_spark(collider.global_position, attack_variant)
```

Update `_spawn_hit_spark` signature:

```gdscript
func _spawn_hit_spark(effect_position: Vector2, variant: String = ATTACK_VARIANT_NORMAL) -> void:
	var spark := HIT_SPARK_SCENE.instantiate() as Node2D
	get_tree().current_scene.add_child(spark)
	spark.global_position = effect_position
	if spark.has_method("configure"):
		spark.configure(
			_get_variant_spark_color(variant),
			Vector2(0.75, 0.75),
			_get_variant_spark_end_scale(variant),
			0.18 if variant == ATTACK_VARIANT_NORMAL else 0.22
		)
```

- [ ] **Step 6: Run focused feedback tests**

Run:

```bash
/usr/local/bin/godot --headless --path . --script tests/test_combat_feedback_variants.gd
```

Expected: PASS.

---

### Task 4: Strengthen Perfect Guard, Counter, And Enemy Readability

**Files:**
- Modify: `scripts/player/PlayerController.gd`
- Modify: `scripts/enemies/BasicEnemy.gd`
- Test: `tests/test_combat_feedback_variants.gd`
- Test: `tests/test_player_damage_feedback.gd`

- [ ] **Step 1: Add failing perfect guard feedback test**

Append this test to `tests/test_combat_feedback_variants.gd` and call it from `_initialize()` before `quit(failures)`:

```gdscript
	await _test_perfect_guard_creates_counter_ready_visual_state()
```

Add the function:

```gdscript
func _test_perfect_guard_creates_counter_ready_visual_state() -> void:
	var player := PLAYER_SCENE.instantiate()
	root.add_child(player)
	await process_frame

	player.set("is_defending", true)
	player.set("perfect_guard_timer", 0.2)
	player.call("handle_enemy_attack", 1, null)
	await process_frame

	_assert_true(player.get("counter_ready_timer") > 0.0, "perfect guard enables counter window")
	_assert_true(player.has_method("_is_counter_ready_visual_active"), "player exposes counter-ready visual helper")
	_assert_true(player.call("_is_counter_ready_visual_active"), "counter-ready visual state is active")

	player.free()
```

Run:

```bash
/usr/local/bin/godot --headless --path . --script tests/test_combat_feedback_variants.gd
```

Expected: FAIL because `_is_counter_ready_visual_active` does not exist yet.

- [ ] **Step 2: Add counter-ready visual state helper**

In `scripts/player/PlayerController.gd`, add:

```gdscript
func _is_counter_ready_visual_active() -> bool:
	return counter_ready_timer > 0.0 and not is_defeated
```

Update `_refresh_body_feedback()` so counter-ready has priority after defeated and before exhausted:

```gdscript
	if is_defeated:
		body.modulate = Color(0.45, 0.45, 0.45, 1.0)
	elif _is_counter_ready_visual_active():
		body.modulate = Color(0.5, 1.0, 0.92, 1.0)
	elif is_exhausted:
		body.modulate = Color(0.78, 0.78, 0.78, 1.0)
	elif is_defending:
		body.modulate = Color(0.55, 0.78, 1.0, 1.0)
	else:
		body.modulate = Color.WHITE
```

Also update the selection ring branch:

```gdscript
	if _is_counter_ready_visual_active():
		selection_ring.color = Color(0.1, 1.0, 0.9, 0.62)
		guard_ring.visible = true
	elif is_defending:
		selection_ring.color = Color(0.42, 0.78, 1.0, 0.45)
		guard_ring.visible = true
```

In `_physics_process(delta)`, after decrementing `counter_ready_timer`, call `_refresh_body_feedback()` when it expires:

```gdscript
	if counter_ready_timer > 0.0:
		counter_ready_timer -= delta
		if counter_ready_timer <= 0.0:
			_refresh_body_feedback()
```

- [ ] **Step 3: Add enemy windup/release visual helpers**

In `scripts/enemies/BasicEnemy.gd`, add state near other timers:

```gdscript
var attack_release_timer: float = 0.0
```

In `_physics_process(delta)`, after hit pulse updates:

```gdscript
	if attack_release_timer > 0.0:
		attack_release_timer -= delta
		facing_marker.scale = Vector2.ONE * 1.25
		if attack_release_timer <= 0.0:
			facing_marker.scale = Vector2.ONE
```

Update `_update_attack_windup(_delta)` when windup begins:

```gdscript
		body.scale = normal_body_scale * 1.08
```

Update `_cancel_windup()`:

```gdscript
	body.scale = normal_body_scale
```

Before `_try_damage_player()` in the release branch:

```gdscript
		attack_release_timer = 0.12
		facing_marker.scale = Vector2.ONE * 1.25
```

Update `apply_stagger(amount)` threshold branch:

```gdscript
		body.modulate = Color(1.0, 0.78, 0.2, 1.0)
		body.scale = normal_body_scale * 1.16
		hit_flash_timer = 0.22
		hit_pulse_timer = 0.22
```

- [ ] **Step 4: Run focused and existing damage tests**

Run:

```bash
/usr/local/bin/godot --headless --path . --script tests/test_combat_feedback_variants.gd
/usr/local/bin/godot --headless --path . --script tests/test_player_damage_feedback.gd
```

Expected: both PASS.

---

### Task 5: Full Regression Pass

**Files:**
- Verify all modified files.
- Test: all `tests/*.gd`

- [ ] **Step 1: Run the full Godot test suite**

Run:

```bash
for test_file in tests/*.gd; do /usr/local/bin/godot --headless --path . --script "$test_file" || exit $?; done
```

Expected: PASS for every test file.

- [ ] **Step 2: If a test fails, inspect that exact failing file**

Run the failing test alone by copying its path from the full-suite output. For example, if `tests/test_combat_feedback_variants.gd` fails, run:

```bash
/usr/local/bin/godot --headless --path . --script tests/test_combat_feedback_variants.gd
```

Expected: reproduce the same failure with a smaller output.

- [ ] **Step 3: Verify no new mechanics slipped in**

Read these files:

```bash
sed -n '1,520p' scripts/player/PlayerController.gd
sed -n '1,520p' scripts/enemies/BasicEnemy.gd
```

Expected: changes are limited to visual feedback, message priority, hit spark parameters, weapon swing, and visual identity helpers. No new inputs, no new enemy archetypes, no new combat resources.

- [ ] **Step 4: Record final verification**

Because this workspace is not a git repository, do not run `git commit`. In the final implementation response, include:

```text
Verification:
- /usr/local/bin/godot --headless --path . --script tests/test_retro_xianxia_entity_visuals.gd
- /usr/local/bin/godot --headless --path . --script tests/test_combat_feedback_variants.gd
- for test_file in tests/*.gd; do /usr/local/bin/godot --headless --path . --script "$test_file" || exit $?; done
```

Expected: all listed commands pass.
