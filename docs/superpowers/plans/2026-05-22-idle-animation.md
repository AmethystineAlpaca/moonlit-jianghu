# Idle Animation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extract all 6 frames per direction from `players_gemini_still.png` rows 0–2 into a unified idle sprite sheet, then animate the player's idle pose using those frames.

**Architecture:** A new Python script slices the still sheet by fixed grid (5 rows × 6 cols, use rows 0/1/2), applies outer-white-cutout + defringe per frame, then repacks into a 3×6 uniform cell sheet. `PlayerController.gd` loads this sheet, slices it into AtlasTextures per direction, and cycles frames at 4 fps when the player is not moving — same pattern as the existing run animation.

**Tech Stack:** Python/Pillow for asset extraction; GDScript 4 `AtlasTexture` for animation slicing; Godot SceneTree headless tests.

---

## File Map

| Action | Path | Responsibility |
|--------|------|----------------|
| Create | `scripts/tools/extract_gemini_idle_sheet.py` | Grid-based idle frame extraction from still sheet |
| Create | `tests/test_extract_idle_sheet.py` | Unit tests for the Python extraction script |
| Run (generate) | `assets/xianxia/players_gemini_aligned_idle.png` | 3-row × 6-col transparent idle sprite sheet |
| Modify | `scripts/player/PlayerController.gd` | Load idle sheet, build per-direction frame arrays, animate idle |
| Modify | `tests/test_retro_xianxia_entity_visuals.gd` | Add test that idle animation frames load correctly |

---

## Task 1: Python extraction script + tests

**Files:**
- Create: `scripts/tools/extract_gemini_idle_sheet.py`
- Create: `tests/test_extract_idle_sheet.py`

- [ ] **Step 1: Write the failing tests**

Create `tests/test_extract_idle_sheet.py`:

```python
#!/usr/bin/env python3
from __future__ import annotations
from pathlib import Path
import sys
from PIL import Image
import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts" / "tools"))
from extract_gemini_idle_sheet import extract_idle_sheet, _content_bbox


def _make_white_sheet(rows: int, cols: int, cell_w: int, cell_h: int, sprite_rgba: tuple) -> Image.Image:
    """White sheet with a centered filled rectangle sprite in each cell."""
    img = Image.new("RGBA", (cell_w * cols, cell_h * rows), (255, 255, 255, 255))
    sw, sh = cell_w // 2, cell_h // 2
    for row in range(rows):
        for col in range(cols):
            cx = col * cell_w + cell_w // 4
            cy = row * cell_h + cell_h // 4
            for y in range(cy, cy + sh):
                for x in range(cx, cx + sw):
                    img.putpixel((x, y), sprite_rgba)
    return img


def test_content_bbox_empty_returns_none():
    img = Image.new("RGBA", (10, 10), (0, 0, 0, 0))
    assert _content_bbox(img) is None


def test_content_bbox_single_pixel():
    img = Image.new("RGBA", (10, 10), (0, 0, 0, 0))
    img.putpixel((3, 5), (255, 0, 0, 255))
    assert _content_bbox(img) == (3, 5, 4, 6)


def test_extract_idle_sheet_uniform_cell_grid():
    """Output width must be divisible by 6 and height by 3."""
    sheet = _make_white_sheet(5, 6, 60, 60, (100, 150, 200, 255))
    result = extract_idle_sheet(sheet, sheet_rows=5, sheet_cols=6, use_rows=[0, 1, 2], white_threshold=245)
    assert result.width % 6 == 0
    assert result.height % 3 == 0


def test_extract_idle_sheet_shorter_than_full_source():
    """Only 3 of 5 rows are used; output must be shorter than the source."""
    sheet = _make_white_sheet(5, 6, 60, 60, (100, 150, 200, 255))
    result = extract_idle_sheet(sheet, sheet_rows=5, sheet_cols=6, use_rows=[0, 1, 2], white_threshold=245)
    assert result.height < sheet.height


def test_extract_idle_sheet_transparent_corners():
    sheet = _make_white_sheet(5, 6, 60, 60, (100, 150, 200, 255))
    result = extract_idle_sheet(sheet, sheet_rows=5, sheet_cols=6, use_rows=[0, 1, 2], white_threshold=245)
    assert result.getpixel((0, 0))[3] == 0, "top-left corner should be transparent"
    assert result.getpixel((result.width - 1, 0))[3] == 0, "top-right corner should be transparent"
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
python3 \
  -m pytest tests/test_extract_idle_sheet.py -v
```

Expected: `ModuleNotFoundError: No module named 'extract_gemini_idle_sheet'` (or similar import error).

- [ ] **Step 3: Write the extraction script**

Create `scripts/tools/extract_gemini_idle_sheet.py`:

```python
#!/usr/bin/env python3
"""
Extract a 3×6 idle animation sheet from players_gemini_still.png.

Source sheet: 1024×1024 with 5 rows × 6 cols.
Uses rows 0 (down/front), 1 (up/back), 2 (left); skips rows 3 and 4.
Each cell is sliced by fixed grid, outer white is removed, then all
frames are repacked into a uniform bottom-aligned cell grid.
"""
from __future__ import annotations

import argparse
from pathlib import Path
import sys

from PIL import Image

TOOLS_DIR = Path(__file__).resolve().parent
if str(TOOLS_DIR) not in sys.path:
    sys.path.insert(0, str(TOOLS_DIR))

from chroma_key_cutout import cutout_outer_white_background, defringe_white_edges


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Extract idle frames from players_gemini_still.png")
    parser.add_argument("--input", required=True, help="Source still-sheet path.")
    parser.add_argument("--output", required=True, help="Aligned transparent output path.")
    parser.add_argument("--sheet-rows", type=int, default=5, help="Total rows in source sheet.")
    parser.add_argument("--sheet-cols", type=int, default=6, help="Total cols in source sheet.")
    parser.add_argument("--use-rows", type=int, nargs="+", default=[0, 1, 2],
                        help="Row indices to extract (0=down, 1=up, 2=left).")
    parser.add_argument("--white-threshold", type=int, default=245)
    return parser.parse_args()


def _content_bbox(image: Image.Image) -> tuple[int, int, int, int] | None:
    """Return (left, top, right, bottom) tight bounding box of non-transparent pixels."""
    pixels = image.load()
    w, h = image.size
    min_x, min_y, max_x, max_y = w, h, -1, -1
    for y in range(h):
        for x in range(w):
            if pixels[x, y][3] > 10:
                min_x = min(min_x, x)
                min_y = min(min_y, y)
                max_x = max(max_x, x)
                max_y = max(max_y, y)
    if max_x < 0:
        return None
    return (min_x, min_y, max_x + 1, max_y + 1)


def _extract_frame(
    source: Image.Image,
    left: int, top: int, right: int, bottom: int,
    white_threshold: int,
) -> Image.Image:
    cell = source.crop((left, top, right, bottom))
    transparent = cutout_outer_white_background(cell, white_threshold)
    transparent = defringe_white_edges(transparent, iterations=2)
    bbox = _content_bbox(transparent)
    if bbox is None:
        return Image.new("RGBA", (1, 1), (0, 0, 0, 0))
    return transparent.crop(bbox)


def extract_idle_sheet(
    source: Image.Image,
    sheet_rows: int,
    sheet_cols: int,
    use_rows: list[int],
    white_threshold: int,
) -> Image.Image:
    w, h = source.size
    frames: list[list[Image.Image]] = []
    for row_idx in use_rows:
        top = round(row_idx * h / sheet_rows)
        bot = round((row_idx + 1) * h / sheet_rows)
        row_frames: list[Image.Image] = []
        for col_idx in range(sheet_cols):
            left = round(col_idx * w / sheet_cols)
            right = round((col_idx + 1) * w / sheet_cols)
            frame = _extract_frame(source, left, top, right, bot, white_threshold)
            row_frames.append(frame)
        frames.append(row_frames)

    cell_w = max(f.width for row in frames for f in row)
    cell_h = max(f.height for row in frames for f in row)

    out_rows = len(use_rows)
    sheet = Image.new("RGBA", (cell_w * sheet_cols, cell_h * out_rows), (0, 0, 0, 0))
    for row_i, row_frames in enumerate(frames):
        for col_i, frame in enumerate(row_frames):
            ox = col_i * cell_w + (cell_w - frame.width) // 2
            oy = row_i * cell_h + (cell_h - frame.height)
            sheet.alpha_composite(frame, (ox, oy))
    return sheet


def main() -> int:
    args = parse_args()
    source = Image.open(Path(args.input)).convert("RGBA")
    sheet = extract_idle_sheet(
        source,
        sheet_rows=args.sheet_rows,
        sheet_cols=args.sheet_cols,
        use_rows=args.use_rows,
        white_threshold=args.white_threshold,
    )
    Path(args.output).parent.mkdir(parents=True, exist_ok=True)
    sheet.save(args.output)
    print(f"Saved idle sheet to {args.output}")
    print(f"Sheet size: {sheet.size[0]}x{sheet.size[1]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
```

- [ ] **Step 4: Run tests to confirm they pass**

```bash
python3 \
  -m pytest tests/test_extract_idle_sheet.py -v
```

Expected: 5 tests PASS.

- [ ] **Step 5: Run the script to generate the idle sheet**

```bash
python3 \
  scripts/tools/extract_gemini_idle_sheet.py \
  --input assets/xianxia/players_gemini_still.png \
  --output assets/xianxia/players_gemini_aligned_idle.png
```

Expected output:
```
Saved idle sheet to assets/xianxia/players_gemini_aligned_idle.png
Sheet size: <W>x<H>   (roughly 6 cells wide × 3 cells tall, each cell ~100×200px)
```

- [ ] **Step 6: Validate the output**

```bash
python3 \
  scripts/tools/chroma_key_cutout.py validate-alpha \
  --input assets/xianxia/players_gemini_aligned_idle.png \
  --require-transparent-corners
```

Expected: All checks pass.

- [ ] **Step 7: Commit**

```bash
git add scripts/tools/extract_gemini_idle_sheet.py \
        tests/test_extract_idle_sheet.py \
        assets/xianxia/players_gemini_aligned_idle.png
git commit -m "feat: extract 3×6 idle animation sheet from still sprite sheet"
```

---

## Task 2: PlayerController idle animation

**Files:**
- Modify: `scripts/player/PlayerController.gd`
- Modify: `tests/test_retro_xianxia_entity_visuals.gd`

- [ ] **Step 1: Write the failing GDScript test**

Open `tests/test_retro_xianxia_entity_visuals.gd`. Add the call in `_initialize()` after the existing test calls:

```gdscript
await _test_player_idle_animation_uses_sheet_frames()
```

Then add the test function at the bottom of the file (before any closing):

```gdscript
func _test_player_idle_animation_uses_sheet_frames() -> void:
	var player := PLAYER_SCENE.instantiate()
	root.add_child(player)
	await process_frame

	var down_frames: Array = player._get_idle_frames_for_direction(Vector2.DOWN)
	var up_frames: Array = player._get_idle_frames_for_direction(Vector2.UP)
	var left_frames: Array = player._get_idle_frames_for_direction(Vector2.LEFT)

	_assert_equal(down_frames.size(), 6, "player has 6 down idle frames from sheet")
	_assert_equal(up_frames.size(), 6, "player has 6 up idle frames from sheet")
	_assert_equal(left_frames.size(), 6, "player has 6 left idle frames from sheet")

	for i in range(down_frames.size()):
		_assert_true(down_frames[i] is AtlasTexture, "down idle frame %d is AtlasTexture" % i)

	player.free()
```

- [ ] **Step 2: Run test to confirm it fails**

Run the specific test in Godot headless. Expected: error — `_get_idle_frames_for_direction` does not exist on player.

- [ ] **Step 3: Add constants and vars to PlayerController.gd**

Add after `const RUN_ANIM_FPS: float = 6.0` (line 69):

```gdscript
const PLAYER_IDLE_SHEET_PATH := "res://assets/xianxia/players_gemini_aligned_idle.png"
const IDLE_ANIM_FPS: float = 4.0
const PLAYER_IDLE_SHEET_COLUMNS := 6
const PLAYER_IDLE_SHEET_ROWS := 3
const PLAYER_IDLE_ROW_DOWN := 0
const PLAYER_IDLE_ROW_UP := 1
const PLAYER_IDLE_ROW_LEFT := 2
```

Add after `var _player_left_idle_texture: Texture2D` (line 124):

```gdscript
var _idle_frames: Dictionary = {}
var _idle_sheet: Texture2D
var _idle_anim_timer: float = 0.0
var _idle_anim_frame: int = 0
```

- [ ] **Step 4: Load the idle sheet in `_ready()`**

In `_ready()`, add this as the first line (before `_player_down_idle_texture = ...`):

```gdscript
_idle_sheet = _load_png_texture(PLAYER_IDLE_SHEET_PATH)
```

- [ ] **Step 5: Add the three new methods after `_slice_run_sheet_row()`**

Insert after `_slice_run_sheet_row()` (after line 536):

```gdscript
func _get_idle_frames_for_direction(direction: Vector2) -> Array[Texture2D]:
	if _idle_frames.is_empty():
		_build_idle_frames()
	var key: String
	if absf(direction.x) > absf(direction.y):
		key = "left"
	elif direction.y > 0.0:
		key = "down"
	else:
		key = "up"
	return _idle_frames.get(key, [])

func _build_idle_frames() -> void:
	_idle_frames.clear()
	if _idle_sheet == null:
		return
	var frame_width := int(_idle_sheet.get_width() / PLAYER_IDLE_SHEET_COLUMNS)
	var frame_height := int(_idle_sheet.get_height() / PLAYER_IDLE_SHEET_ROWS)
	if frame_width <= 0 or frame_height <= 0:
		return
	_idle_frames["down"] = _slice_idle_sheet_row(PLAYER_IDLE_ROW_DOWN, frame_width, frame_height)
	_idle_frames["up"] = _slice_idle_sheet_row(PLAYER_IDLE_ROW_UP, frame_width, frame_height)
	_idle_frames["left"] = _slice_idle_sheet_row(PLAYER_IDLE_ROW_LEFT, frame_width, frame_height)

func _slice_idle_sheet_row(row: int, frame_width: int, frame_height: int) -> Array[Texture2D]:
	var frames: Array[Texture2D] = []
	for col in range(PLAYER_IDLE_SHEET_COLUMNS):
		var atlas := AtlasTexture.new()
		atlas.atlas = _idle_sheet
		atlas.region = Rect2(col * frame_width, row * frame_height, frame_width, frame_height)
		frames.append(atlas)
	return frames
```

- [ ] **Step 6: Update `_get_directional_animation_state()` to return `idle_frames`**

Replace the entire `_get_directional_animation_state()` function (lines 438–499) with:

```gdscript
func _get_directional_animation_state() -> Dictionary:
	var direction := last_facing_direction
	if direction == Vector2.ZERO:
		return {
			"idle_frames": _get_idle_frames_for_direction(Vector2.DOWN),
			"run_frames": [PLAYER_DOWN_RUN_TEXTURE],
			"flip_h": false,
		}

	var run_key := ""
	var flip_h := false
	if direction.x < -0.001:
		if direction.y < -0.001:
			run_key = "up_left"
		elif direction.y > 0.001:
			run_key = "down_left"
		else:
			run_key = "left"
	elif direction.x > 0.001:
		flip_h = true
		if direction.y < -0.001:
			run_key = "up_left"
		elif direction.y > 0.001:
			run_key = "down_left"
		else:
			run_key = "left"
	elif direction.y > 0.001:
		run_key = "down"
	else:
		run_key = "up"

	var run_frames := _get_five_dir_run_frames(run_key)
	if not run_frames.is_empty():
		return {
			"idle_frames": _get_idle_frames_for_direction(direction),
			"run_frames": run_frames,
			"flip_h": flip_h,
		}

	if absf(direction.x) > absf(direction.y):
		if direction.x > 0.0:
			return {
				"idle_frames": _get_idle_frames_for_direction(direction),
				"run_frames": [PLAYER_RIGHT_RUN_TEXTURE],
				"flip_h": true,
			}
		return {
			"idle_frames": _get_idle_frames_for_direction(direction),
			"run_frames": [PLAYER_LEFT_RUN_TEXTURE],
			"flip_h": false,
		}
	if direction.y > 0.0:
		return {
			"idle_frames": _get_idle_frames_for_direction(direction),
			"run_frames": [PLAYER_DOWN_RUN_TEXTURE],
			"flip_h": false,
		}
	return {
		"idle_frames": _get_idle_frames_for_direction(direction),
		"run_frames": [PLAYER_UP_RUN_TEXTURE],
		"flip_h": false,
	}
```

Note: `_get_idle_texture_for_direction()` is now unused — delete it (lines 501–506).

- [ ] **Step 7: Update `_update_xianxia_animation()` to animate idle frames**

Replace lines 593–609 (the `state` read and the moving/idle branch) with:

```gdscript
	var state := _get_directional_animation_state()
	var run_frames: Array = state.get("run_frames", [])
	var idle_frames: Array = state.get("idle_frames", [])
	body.flip_h = bool(state.get("flip_h", false))
	if moving or is_dashing:
		_run_anim_timer -= _delta
		if _run_anim_timer <= 0.0:
			_run_anim_frame = (_run_anim_frame + 1) % maxi(run_frames.size(), 1)
			_run_anim_timer = 1.0 / RUN_ANIM_FPS
		if run_frames.is_empty():
			body.texture = idle_frames[0] if not idle_frames.is_empty() else _player_down_idle_texture
		else:
			body.texture = run_frames[_run_anim_frame % run_frames.size()]
	else:
		_run_anim_timer = 0.0
		_run_anim_frame = 0
		if idle_frames.is_empty():
			body.texture = _player_down_idle_texture
		else:
			_idle_anim_timer -= _delta
			if _idle_anim_timer <= 0.0:
				_idle_anim_frame = (_idle_anim_frame + 1) % idle_frames.size()
				_idle_anim_timer = 1.0 / IDLE_ANIM_FPS
			body.texture = idle_frames[_idle_anim_frame % idle_frames.size()]
```

- [ ] **Step 8: Run tests to confirm they pass**

Run the entity visuals test:

```
test_retro_xianxia_entity_visuals.gd
```

Expected: all tests pass including `_test_player_idle_animation_uses_sheet_frames`.

Also run the existing test to make sure nothing regressed:

```
test_retro_xianxia_entity_visuals.gd::_test_player_uses_idle_and_four_direction_run_textures
```

Expected: PASS (we kept `_player_down/up/left_idle_texture` vars).

- [ ] **Step 9: Commit**

```bash
git add scripts/player/PlayerController.gd \
        tests/test_retro_xianxia_entity_visuals.gd
git commit -m "feat: animate player idle using 6-frame directional sheet"
```
