# Skill HUD Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a visible five-slot skill bar, selected-skill input flow, Space-to-use-selected-skill behavior, and Escape pause/resume.

**Architecture:** Keep the skill system as a lightweight foundation. `SkillCaster` owns slot names and empty-slot cast behavior, `PlayerController` owns input selection and stamina-facing owner hooks, and `Hud` renders selected skill state and pause state.

**Tech Stack:** Godot 4.6 GDScript, existing `CanvasLayer` HUD, existing input map in `project.godot`.

---

### Task 1: Skill Foundation Scripts

**Files:**
- Create: `scripts/skills/SkillDefinition.gd`
- Create: `scripts/skills/SkillEffect.gd`
- Create: `scripts/skills/SkillCaster.gd`

- [ ] Add `SkillDefinition` resource with display name, cost, cooldown, range, targeting mode, and effect scene fields.
- [ ] Add `SkillEffect` base node with an `activate(context)` hook for future effect scenes.
- [ ] Add `SkillCaster` with five slots, selected-slot signal data helpers, cooldown ticking, and safe `No Skill` empty-slot behavior.

### Task 2: Player Input Wiring

**Files:**
- Modify: `project.godot`
- Modify: `scenes/player/Player.tscn`
- Modify: `scripts/player/PlayerController.gd`

- [ ] Move Space out of `attack`; keep attack on `J` and mouse.
- [ ] Add `select_skill_1` through `select_skill_5`, `use_selected_skill`, and `pause_game`.
- [ ] Add a `SkillCaster` child to the player.
- [ ] Add player signals for skill slot names and selected slot changes.
- [ ] Add `1-5` select/toggle behavior, Space use-selected-skill behavior, and owner methods for future skill effects.

### Task 3: HUD Skill Bar And Pause UI

**Files:**
- Modify: `ui/Hud.tscn`
- Modify: `scripts/ui/Hud.gd`

- [ ] Add a bottom-center five-slot skill bar.
- [ ] Show `Empty` for all slots initially.
- [ ] Highlight selected slot and clear highlight when deselected.
- [ ] Add a centered `Paused` label.
- [ ] Let HUD process while paused and toggle pause on Escape.

### Task 4: Verification

**Files:**
- Validate existing project scenes and scripts.

- [ ] Run `/usr/local/bin/godot --headless --path /Users/ming/gaame --quit-after 1`.
- [ ] Confirm parse/load succeeds.
- [ ] Confirm expected controls: `1-5` select/toggle skill slots, `Space` emits `No Skill`, `J`/mouse still attack, `ESC` pauses/resumes.
