# Moonlit Jianghu

[![English](https://img.shields.io/badge/Language-English-2f6feb)](README.md)
[![中文](https://img.shields.io/badge/语言-中文-d73a49)](README.zh.md)
[![日本語](https://img.shields.io/badge/言語-日本語-6f42c1)](README.ja.md)
[![Русский](https://img.shields.io/badge/Язык-Русский-22863a)](README.ru.md)

**A small East Asian fantasy action RPG prototype made in Godot 4.**

By day, the village is green, quiet, and almost kind. By night, the same paths turn cold blue, lights flicker awake, and things that should have stayed buried begin to move.

![Moonlit Jianghu fire lion encounter](docs/showcase/images/02-day-fire-lion-encounter.png)

## The Pitch

Moonlit Jianghu is a playable top-down pixel-art prototype about a lone sword bearer caught between an ordinary village and a haunted jianghu. It blends wuxia movement, xianxia mood, old-world village scenery, and fast little bursts of action combat.

This is not a finished game. It is a preserved slice of one: enough to walk, fight, dash, guard, switch day and night, open the inventory, meet hostile creatures, and feel the shape of the world it wanted to become.

中文简介：这是一个 Godot 4 制作的俯视角像素动作 RPG 原型，带有亚洲古风、武侠、仙侠、江湖、东方幻想、昼夜切换、近战战斗和独立游戏实验气质。

## A Little Story

The village was built on an old road through the jianghu. Travelers once came for tea, shelter, and rumors of immortals in the mountains.

Then the moon changed.

At sunrise, the grass still shines and the houses still look warm. At night, blue fire drifts over the paths, corpses remember how to stand, and a burning lion stalks the edge of the village. The sword bearer has no grand prophecy yet, only a blade, a few unstable skills, and a place that refuses to stay peaceful.

## What You Can Do

- **Switch between day and night** with `P`, changing the village from bright grassland to moonlit danger.
- **Fight in quick top-down melee** with attacks, guard timing, dash movement, stamina pressure, hit flashes, knockback, and impact feedback.
- **Face prototype enemies** including skeletal attackers, zombies, fast enemies, and a blazing fire-lion variant.
- **Explore a compact fantasy village** with tiled paths, lantern-lit buildings, trees, rocks, breakables, particles, and hand-placed landmarks.
- **Open the inventory overlay** and see the early RPG structure behind the combat prototype.

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

## Running It

This project uses Godot `4.6.2`.

```bash
godot --path .
```

Local release builds can be exported into `out/`, which is ignored by git:

```bash
mkdir -p out
godot --headless --path . --export-release "macOS" out/moonlit-jianghu-macos.zip
godot --headless --path . --export-release "Windows Desktop" out/moonlit-jianghu-windows.exe
```

Unsigned builds may trigger operating-system security prompts.

## Prototype Status

Moonlit Jianghu is public as an archival prototype and visual showcase. Some tests document older scene expectations, some systems are experimental, and not every asset in the tree is used by the current scene.

No open-source license has been selected yet. Until a license is added, the code and assets are visible for reference but not explicitly granted for reuse.
