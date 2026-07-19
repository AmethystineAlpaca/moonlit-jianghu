# gaame

An unfinished Godot 4 top-down action RPG prototype with a retro xianxia mood.

![gaame world overview](docs/showcase/images/01-world-overview.png)

This repository preserves a playable prototype rather than a finished game. It includes movement, melee combat, enemy encounters, a small village map, night ambience, inventory UI, and AI-assisted pixel-art asset experiments.

## Showcase

- [English showcase](docs/showcase/SHOWCASE_EN.md)
- [中文展示文档](docs/showcase/SHOWCASE_ZH.md)

## Builds

Prebuilt binaries are not committed to this repository. Local exports are written to `out/`, which is ignored by git. For public downloads, attach builds to a GitHub Release or upload them to a game page such as itch.io.

```bash
mkdir -p out
godot --headless --path . --export-release "macOS" out/gaame-macos.zip
godot --headless --path . --export-release "Windows Desktop" out/gaame-windows.exe
```

The exported macOS and Windows builds are unsigned. Players may see operating-system security prompts the first time they open them.

## Status

- Engine: Godot `4.6.2`
- Main scene: `scenes/main/Main.tscn`
- State: unfinished prototype / archival showcase
- License: no open-source license has been selected yet

## Sprite Sheet Cutout Workflow

This repo now includes a small reusable utility for AI-generated sprite sheets that arrive with a flat chroma-key background.

- Script: [scripts/tools/chroma_key_cutout.py](scripts/tools/chroma_key_cutout.py)
- Typical use case:
  - generate a sprite sheet on a flat green background
  - save the raw file as something like `*_green.png`
  - run the cutout utility to produce a transparent PNG
  - validate transparent corners before importing into Godot

## Commands

Use the bundled Codex Python runtime if the local shell environment does not already have Pillow installed:

```bash
python3 scripts/tools/chroma_key_cutout.py cutout \
  --input assets/xianxia/players_gemini_5dir_run_green.png \
  --output assets/xianxia/players_gemini_5dir_run.png \
  --despill
```

```bash
python3 scripts/tools/chroma_key_cutout.py validate-alpha \
  --input assets/xianxia/players_gemini_5dir_run.png \
  --require-transparent-corners
```

## Notes

- The current heuristic is tuned for green-screen style backgrounds from image generation workflows.
- `--despill` is useful when the transparent result keeps a thin green edge around pixel art.
- Keep the keyed source file when you expect to iterate on the cutout or re-run with different thresholds.

## White-Background Contact Sheet Extraction

When a source sheet already contains the motion you want, do not regenerate the animation with AI just to change layout. Instead, extract the existing sprites and rebuild a clean aligned transparent sheet.

- Script: [scripts/tools/extract_gemini_run_sheet.py](scripts/tools/extract_gemini_run_sheet.py)
- Example:

```bash
python3 scripts/tools/extract_gemini_run_sheet.py \
  --input assets/xianxia/players_gemini.png \
  --output assets/xianxia/players_gemini_aligned_5dir_run.png
```

This keeps the original leg motion and avoids cut errors caused by forcing a non-uniform contact sheet into a naive equal grid.
