# Moonlit Jianghu

**A tiny East Asian fantasy action RPG prototype made in Godot 4.**

Wander through an Asian historical fantasy village that shifts between bright grassland and cold moonlight, draw a blade against wandering spirits, dash past fire-lit beasts, and test the first pieces of a survival-action combat loop inspired by wuxia, xianxia, Chinese-inspired fantasy, and classic top-down RPGs.

![Moonlit Jianghu fire lion encounter](docs/showcase/images/02-day-fire-lion-encounter.png)

## Why This Exists

Moonlit Jianghu is an unfinished but playable snapshot: a preserved prototype of a top-down pixel-art action RPG with day-night switching, melee combat, hostile creatures, inventory UI, and a small handcrafted village map. It sits somewhere between Asian fantasy RPG, Godot indie game, wuxia combat sketch, and atmospheric pixel-art experiment.

中文简介：这是一个 Godot 4 制作的俯视角像素动作 RPG 原型，带有亚洲古风、武侠、仙侠、江湖、东方幻想、古风村庄、昼夜切换、近战战斗和独立游戏实验气质。

It is not a polished commercial release. It is a mood piece, a combat sketch, and a visual experiment that reached the point where it deserved to be shown.

## Highlights

- **Day-night village mood** that can be switched in-game with `P`, moving between bright green grassland and a colder moonlit atmosphere.
- **Asian historical fantasy scenery** with tiled ground, lantern-lit buildings, trees, rocks, breakables, and drifting magical particles.
- **Wuxia / xianxia flavor** with a sword-bearing hero, supernatural enemies, cultivation-fantasy mood, and old-world village silhouettes.
- **Snappy top-down combat** with movement, dash, melee attacks, guard timing, stamina pressure, hit flashes, knockback, and impact feedback.
- **Enemy encounters** featuring skeletal attackers, zombies, fast enemies, and a blazing fire-lion variant.
- **Skill bar and inventory overlay** with equipment slots, bag slots, and simple prototype RPG affordances.
- **AI-assisted pixel-art pipeline** for cleaning, extracting, and aligning generated sprite sheets into Godot-ready transparent assets.

![Night fire lion encounter](docs/showcase/images/05-night-fire-lion-encounter.png)

## Screenshots

| Day Village | Day Combat |
| --- | --- |
| ![Day village](docs/showcase/images/01-day-village.png) | ![Day fire lion encounter](docs/showcase/images/02-day-fire-lion-encounter.png) |

| Night Village | Night Combat |
| --- | --- |
| ![Night village](docs/showcase/images/04-night-village.png) | ![Night fire lion encounter](docs/showcase/images/05-night-fire-lion-encounter.png) |

| Inventory |
| --- |
| ![Inventory overlay](docs/showcase/images/03-inventory-overlay.png) |

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
- Toggle day/night: `P`
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

`godot` `godot-4` `gdscript` `pixel-art` `2d-game` `top-down` `action-rpg` `fantasy-rpg` `indie-game` `game-prototype` `asian-fantasy` `east-asian-fantasy` `chinese-fantasy` `wuxia` `xianxia` `jianghu` `ancient-asia` `jrpg-inspired` `sprite-sheet` `ai-art-workflow`

中文关键词：`Godot 游戏` `Godot 4` `像素游戏` `像素风` `俯视角` `动作 RPG` `独立游戏` `游戏原型` `亚洲古风` `东方幻想` `古风游戏` `武侠` `仙侠` `江湖` `修仙` `中国风` `古风村庄` `昼夜切换` `近战战斗` `素材工作流`

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
