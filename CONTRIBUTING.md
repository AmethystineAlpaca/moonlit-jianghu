# Contributing to Stillwater · 雨歇

Stillwater is the current 3D wuxia action chapter of Moonlit Jianghu, built with **Godot 4.6.2**. The game is in active development. Clear playtest reports, reproducible bugs and small, well-explained changes help us decide what to improve next. English and Chinese are both welcome / 欢迎使用中文或英文交流。

## Start with a short playtest

Get the [public preview](https://github.com/AmethystineAlpaca/moonlit-jianghu/releases/tag/v0.3.0-preview.1), or follow the [source launch instructions](README.md#run-the-3d-game). The game UI is currently Chinese; the README includes an English controls table.

Try one seal encounter, then tell us:

- Could you see an enemy preparing to attack, and understand when to move or guard?
- Did your movement and attacks respond as you expected? Describe a specific moment when they did not.
- Could you tell when you took damage, blocked a strike or broke an enemy's posture?
- Did dash → recall, shove → collision, or timed deflection create a useful choice?

Use the [playtest feedback form](https://github.com/AmethystineAlpaca/moonlit-jianghu/issues/new?template=playtest-feedback.yml). Completing the whole chapter is not required. A short clip with the moment marked is especially helpful, but text alone is welcome.

## Bugs, ideas and questions

Search [existing issues](https://github.com/AmethystineAlpaca/moonlit-jianghu/issues) before opening a new report. Add a reproduction to an existing issue when it describes the same problem.

Use the [bug form](https://github.com/AmethystineAlpaca/moonlit-jianghu/issues/new?template=bug-report.yml) for crashes, broken controls, rendering problems or behavior you can reproduce. Include your OS, CPU/GPU if known, release tag or commit, input device, steps, and expected versus actual behavior. Distinguish the **current 3D chapter** from the retained **previous 2D version**.

Use [Discussions](https://github.com/AmethystineAlpaca/moonlit-jianghu/discussions) for questions, design ideas, translation suggestions and conversations about how a mechanic feels. Explain the player problem and an example before proposing a solution. Keep feedback about the work specific and respectful.

## Code and documentation changes

The default branch is `master`. Read [Development & builds](docs/DEVELOPMENT.md) for the architecture, launch commands and checks. For a gameplay change, describe the trigger, the behavior before and after, and how you verified it. For a visual or animation change, include an engine capture or a short recording; damage-only tests cannot show whether an animation actually moves.

Run the relevant existing checks from the repository root:

```bash
godot --headless --editor --path . --import --quit
python3 scripts/tools/run_tests.py
```

Keep changes focused. Link the issue or discussion that provides context, and identify any platform you could not test. Preserve the launchable 2D archive unless a change explicitly targets it. Documentation-only edits need link and formatting checks rather than a full game test run.

## Assets and rights

Preserve original source images, models and their licenses. Follow [AGENTS.md](AGENTS.md) for sprite extraction and [third-party asset credits](docs/THIRD_PARTY_ASSETS.md) for component details. Include the source and license for any proposed external asset; do not label a third-party model as original project artwork.

The repository is publicly viewable, but **no repository-wide reuse license has been selected**. Third-party assets keep their own licenses, including KayKit's CC0 characters and OFL Noto fonts. This contribution guide does not introduce a new license or change those rights. Raise licensing questions with the maintainer in Discussions before planning downstream reuse.

## Follow development

If you want to return to the project, you can Star the repository. Use GitHub's Watch menu to choose release notifications if you want new build announcements. Specific feedback and reproducible reports are the most useful next contribution.
