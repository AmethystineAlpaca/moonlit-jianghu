# Development, running and builds

Current snapshot: 2026-09-06 · Godot 4.6.2 · default branch `master`.

## Two launchable versions

Run all commands from the repository root, with `godot` and Python 3 on PATH.

```bash
godot --headless --editor --path . --import --quit
# Default 3D chapter
godot --path .
# Explicit 3D chapter
godot --path . res://scenes/rebirth/Stillwater.tscn
# Previous 2D title
godot --path . res://scenes/interface/TitleScreen.tscn
# Previous 2D world
godot --path . res://scenes/main/Main.tscn
```

In the editor, F5 runs the default 3D scene; F6 runs the currently open scene. Both versions share project input definitions and the Soundscape autoload, but their controls and game systems differ. Continuous music is currently disabled in both. Both have Chinese game UI.

## Current architecture

| Path | Responsibility |
| --- | --- |
| `scenes/rebirth/Stillwater.tscn` | Default entry |
| `scripts/rebirth/Stillwater.gd` | Courtyard, encounters, progression, skills and camera |
| `scripts/rebirth/Duelist.gd` | Movement, input, combat state, stamina, posture and collision |
| `scripts/rebirth/CombatPuppet.gd` | Skeletal animation sampling and runtime palette |
| `scripts/rebirth/StillwaterUI.gd` | Title, HUD, guide, pause, settings and results |
| `scripts/rebirth/CombatFeedback.gd` | Player damage direction and feedback |
| `scripts/rebirth/CombatReadout.gd` | Enemy health and posture |
| `scripts/rebirth/RainEcho.gd`, `PressureWave.gd`, `SpiritBolt.gd` | Echo, shove and reflected projectiles |
| `assets/characters/kaykit` | Original licensed GLB models and license |
| `assets/audio/combat` | Original generated combat Foley |
| `scenes/interface`, `scenes/main`, `scripts/player` | Retained 2D entry points and implementation |

## Validation

```bash
python3 scripts/tools/run_tests.py
# Target a specific regression
python3 scripts/tools/run_tests.py tests/test_control_readability.gd
# Script-controlled full 3D journey; does not edit health or skip enemies
godot --headless --path . --script res://scripts/tools/play_stillwater.gd
```

The runner checks exit status and engine-error output, executes scripts serially, and writes `output/rebirth/test-results.json`. The current snapshot passed 32/32 scripts; the suite includes retained 2D checks and current 3D integration checks. This is not equivalent to sustained human playtesting.

Headless mode skips the character palette shader because of dummy-renderer material-query errors. Native Metal captures separately exercise the actual rendering path.

## Capture current gameplay

```bash
mkdir -p output/rebirth
godot --path . --script res://scripts/tools/capture_readability.gd --write-movie output/rebirth/readability.avi --fixed-fps 30
ffmpeg -y -i output/rebirth/readability.avi -c:v libx264 -crf 20 -pix_fmt yuv420p -c:a aac output/rebirth/Stillwater-readability.mp4
```

`capture_readability.gd` uses normal camera framing. `capture_attack_review.gd` deliberately moves the camera closer to inspect animation; it does not change the shipping camera. `capture_duel_3d.gd` stages a boss encounter; `capture_rebirth.gd` captures title, court, seal and pause screens. These recordings use scripted controls. Movie Maker frame rates are not hardware performance results.

Committed public media is in `docs/showcase/v3`. Raw videos and local exports remain under ignored `output/`. Regenerate Foley with `python3 scripts/tools/compose_combat_audio.py` and rerun the import step afterward.

## Export desktop builds

Install the matching Godot 4.6.2 export templates. The presets are `macOS` and `Windows Desktop`.

```bash
mkdir -p output/releases/Stillwater-Windows
godot --headless --path . --export-release "macOS" output/releases/Stillwater-macOS.zip
godot --headless --path . --export-release "Windows Desktop" output/releases/Stillwater-Windows/Stillwater.exe
```

Archive the **whole Windows output folder**, including `Stillwater.pck` if the preset produces a separate PCK, as `output/releases/Stillwater-Windows.zip`. Extract the macOS archive and run `Moonlit Jianghu.app`. Exports use the current 3D default. To produce a dedicated 2D export, use a separate checkout and change its main scene to `scenes/interface/TitleScreen.tscn`; do not change the repository default merely to play the old scene.

macOS startup was checked on Apple M4 / Metal. Windows was cross-exported without Windows hardware validation; physical controllers are not yet validated. Builds are not Apple-notarized.

[Public preview v0.3.0-preview.1](https://github.com/AmethystineAlpaca/moonlit-jianghu/releases/tag/v0.3.0-preview.1) contains desktop ZIPs, a native-engine video and SHA-256 checksums. It was exported from a clean archive of `0a4f6862533b29a813ab5698ac44cf112d4d59c6`; its 32-script suite and macOS startup were checked again on 2026-09-11. Use that tag's source to reproduce the release. Later sword-intent changes in `master` are not included in these downloads.

See [CONTRIBUTING.md](../CONTRIBUTING.md) for playtest reporting and [PRESS_KIT.md](PRESS_KIT.md) for version-specific descriptions and captures.

## Repository and history

The current work is committed directly to `master`. See [documentation index](README.md) for current documents and dated 2D archives. Preserve original image/model sources and licenses; follow [AGENTS.md](../AGENTS.md) for sprite extraction. See [asset credits](THIRD_PARTY_ASSETS.md) for component-specific rights; no repository-wide reuse license has been chosen.
