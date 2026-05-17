# Retro Xianxia Entity Visuals Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace abstract entity blobs with retro pixel Chinese xianxia player and skeleton enemy visuals, including procedural movement and attack animation.

**Architecture:** Keep the existing Godot scene structure and generate pixel textures at runtime from `PlayerController.gd` and `BasicEnemy.gd`. Add small existing-node-compatible visual helpers so current combat, health, corpse, and transform behavior remains intact.

**Tech Stack:** Godot 4 GDScript, `ImageTexture`, `Sprite2D`, `Polygon2D`, existing SceneTree tests.

---

### Task 1: Character Visual Contract Tests

**Files:**
- Create: `tests/test_retro_xianxia_entity_visuals.gd`
- Modify: `scripts/player/PlayerController.gd`
- Modify: `scripts/enemies/BasicEnemy.gd`
- Modify: `scenes/player/Player.tscn`
- Modify: `scenes/enemies/BasicEnemy.tscn`
- Modify: `scenes/enemies/FastEnemy.tscn`
- Modify: `scenes/allies/Zombie.tscn`

- [x] **Step 1: Write failing tests**

Create tests that instantiate player, basic enemy, fast enemy, and zombie scenes. Assert player body is a nearest-filtered generated texture with a white robe center, a `Sword` child exists, enemies expose `get_visual_accent_color()`, enemy accents are distinct, enemy bodies have generated textures, corpse accent remains close to source color, and zombie accent keeps source identity with green corruption.

- [x] **Step 2: Run test to verify it fails**

Run: `/usr/local/bin/godot --headless --path . --script tests/test_retro_xianxia_entity_visuals.gd`

Expected: FAIL because the new sword node, visual accent API, and generated entity textures do not exist yet.

- [x] **Step 3: Implement player visual generation**

In `PlayerController.gd`, generate a 32x36 pixel texture for the body in `_ready()`, add/cache a `Sword` child if absent, set nearest filtering, and animate body/sword transforms in `_physics_process()`.

- [x] **Step 4: Implement skeleton visual generation**

In `BasicEnemy.gd`, export `visual_accent_color`, generate skeleton textures, add/cache `SoulAccent` and `BoneWeapon` children, expose `get_visual_accent_color()`, and animate idle/walk/dash-like knockback/attack states.

- [x] **Step 5: Preserve corpse and zombie colors**

Update corpse death visuals to use the source accent color instead of neutral gray. Update zombie visuals to blend the source accent with green corruption while keeping the source hue visible.

- [x] **Step 6: Run focused test**

Run: `/usr/local/bin/godot --headless --path . --script tests/test_retro_xianxia_entity_visuals.gd`

Expected: PASS.

### Task 2: Regression Tests

**Files:**
- Modify: `tests/test_enemy_corpse_visual.gd`

- [x] **Step 1: Update corpse expectation**

Change the old neutral-gray corpse assertion to expect retained skeleton accent color.

- [x] **Step 2: Run all tests**

Run: `/bin/bash -lc 'for test_file in tests/*.gd; do /usr/local/bin/godot --headless --path . --script "$test_file" || exit $?; done'`

Expected: PASS for all SceneTree tests.

## Self-Review

The plan covers player appearance, enemy skeleton colors, corpse/zombie color inheritance, procedural movement/attack animation, and regression testing. No placeholders or contradictory scope remain. Git commits are omitted because `/Users/ming/gaame` is not currently a git repository.
