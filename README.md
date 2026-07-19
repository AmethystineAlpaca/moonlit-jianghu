# Moonlit Jianghu

**A tiny moonlit xianxia action RPG prototype made in Godot 4.**

Wander through a haunted village under cold blue light, draw a blade against wandering spirits, dash past fire-lit beasts, and test the first pieces of a survival-action combat loop inspired by wuxia and xianxia fantasy.

![Moonlit Jianghu world overview](docs/showcase/images/01-world-overview.png)

## Why This Exists

Moonlit Jianghu is an unfinished but playable snapshot: a preserved prototype of a top-down pixel-art action RPG with night ambience, melee combat, hostile creatures, inventory UI, and a small handcrafted village map.

It is not a polished commercial release. It is a mood piece, a combat sketch, and a visual experiment that reached the point where it deserved to be shown.

## Highlights

- **Moonlit xianxia village** with tiled night ground, lantern-lit buildings, trees, rocks, breakables, and drifting magical particles.
- **Snappy top-down combat** with movement, dash, melee attacks, guard timing, stamina pressure, hit flashes, knockback, and impact feedback.
- **Enemy encounters** featuring skeletal attackers, zombies, fast enemies, and a blazing fire-lion variant.
- **Skill bar and inventory overlay** with equipment slots, bag slots, and simple prototype RPG affordances.
- **AI-assisted pixel-art pipeline** for cleaning, extracting, and aligning generated sprite sheets into Godot-ready transparent assets.

![Fire lion encounter](docs/showcase/images/02-fire-lion-encounter.png)

## Screenshots

| Village | Combat |
| --- | --- |
| ![Night village](docs/showcase/images/04-night-village.png) | ![Fire lion encounter](docs/showcase/images/02-fire-lion-encounter.png) |

| Inventory | Overview |
| --- | --- |
| ![Inventory overlay](docs/showcase/images/03-inventory-overlay.png) | ![World overview](docs/showcase/images/01-world-overview.png) |

## Play Notes

Local release builds are written to `out/` and are ignored by git. Attach exported builds to a GitHub Release or upload them to a game page rather than committing binaries.

- macOS export: `out/moonlit-jianghu-macos.zip`
- Windows export: `out/moonlit-jianghu-windows.exe`

Unsigned builds may trigger operating-system security prompts.

## Controls

- Move: `WASD` or arrow keys
- Attack: `J` or left mouse button
- Guard: `K`
- Dash: `L`
- Use selected skill: `Space`
- Select skills: `1`-`5`
- Inventory: `M`
- Toggle night ambience: `P`
- Reset scene: `R`

## Showcase Docs

- [English showcase](docs/showcase/SHOWCASE_EN.md)
- [中文展示文档](docs/showcase/SHOWCASE_ZH.md)

## Build From Source

Requirements:

- Godot `4.6.2`

Run the project:

```bash
godot --path .
```

Export local builds:

```bash
mkdir -p out
godot --headless --path . --export-release "macOS" out/moonlit-jianghu-macos.zip
godot --headless --path . --export-release "Windows Desktop" out/moonlit-jianghu-windows.exe
```

## Project Status

This repository is public as an archival prototype. Some tests document older expectations, some systems are intentionally experimental, and not every asset in the tree is used by the current scene.

No open-source license has been selected yet. Until a license is added, the code and assets are visible for reference but not explicitly granted for reuse.

## Discovery Keywords

`godot` `godot-4` `pixel-art` `xianxia` `wuxia` `action-rpg` `top-down` `indie-game` `game-prototype` `fantasy-rpg` `sprite-sheet` `ai-art-workflow`

## Asset Workflow Notes

This repo includes small utilities for cleaning generated sprite sheets:

- [Chroma-key cutout tool](scripts/tools/chroma_key_cutout.py)
- [White-background run-sheet extractor](scripts/tools/extract_gemini_run_sheet.py)

Example:

```bash
python3 scripts/tools/chroma_key_cutout.py cutout \
  --input assets/xianxia/players_gemini_5dir_run_green.png \
  --output assets/xianxia/players_gemini_5dir_run.png \
  --despill
```
