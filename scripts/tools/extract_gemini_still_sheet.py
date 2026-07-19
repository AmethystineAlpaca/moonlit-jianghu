#!/usr/bin/env python3
"""
Extract selected idle poses from the Gemini still contact sheet.

The source sheet is arranged in horizontal rows. We keep the original image,
remove only outer-connected white background from each selected row slice, and
crop the leftmost sprite in that row to a standalone transparent PNG.
"""

from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path
import sys

from PIL import Image


TOOLS_DIR = Path(__file__).resolve().parent
if str(TOOLS_DIR) not in sys.path:
    sys.path.insert(0, str(TOOLS_DIR))

from chroma_key_cutout import cutout_outer_white_background


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Extract idle sprites from players_gemini_still.png")
    parser.add_argument("--input", required=True, help="Source still-sheet path.")
    parser.add_argument("--output-dir", required=True, help="Directory for extracted idle PNGs.")
    parser.add_argument("--rows", type=int, default=5, help="Total number of horizontal rows in the source sheet.")
    parser.add_argument(
        "--white-threshold",
        type=int,
        default=245,
        help="Pixels at or above this RGB threshold count as removable white background.",
    )
    parser.add_argument(
        "--min-pixels",
        type=int,
        default=200,
        help="Ignore tiny connected components below this size.",
    )
    return parser.parse_args()


def _find_components(image: Image.Image, min_pixels: int) -> list[tuple[int, int, int, int, int]]:
    width, height = image.size
    pixels = image.load()
    visited = [[False] * width for _ in range(height)]
    boxes: list[tuple[int, int, int, int, int]] = []

    for y in range(height):
        for x in range(width):
            if visited[y][x] or pixels[x, y][3] == 0:
                continue
            queue = deque([(x, y)])
            visited[y][x] = True
            min_x = max_x = x
            min_y = max_y = y
            count = 0
            while queue:
                cx, cy = queue.popleft()
                count += 1
                min_x = min(min_x, cx)
                max_x = max(max_x, cx)
                min_y = min(min_y, cy)
                max_y = max(max_y, cy)
                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if 0 <= nx < width and 0 <= ny < height and not visited[ny][nx]:
                        visited[ny][nx] = True
                        if pixels[nx, ny][3] > 0:
                            queue.append((nx, ny))
            if count >= min_pixels:
                boxes.append((min_x, min_y, max_x, max_y, count))
    return boxes


def _crop_leftmost_sprite(row_image: Image.Image, min_pixels: int) -> Image.Image:
    components = sorted(_find_components(row_image, min_pixels), key=lambda box: (box[0], -box[4]))
    if not components:
        raise ValueError("No sprite component found in selected row")
    min_x, min_y, max_x, max_y, _count = components[0]
    return row_image.crop((min_x, min_y, max_x + 1, max_y + 1))


def _extract_row_sprite(
    source: Image.Image,
    row_index: int,
    row_count: int,
    white_threshold: int,
    min_pixels: int,
) -> Image.Image:
    row_height = source.height / float(row_count)
    top = round(row_index * row_height)
    bottom = round((row_index + 1) * row_height)
    row_slice = source.crop((0, top, source.width, bottom)).convert("RGBA")
    transparent_row = cutout_outer_white_background(row_slice, white_threshold)
    return _crop_leftmost_sprite(transparent_row, min_pixels)


def main() -> int:
    args = parse_args()
    source = Image.open(Path(args.input)).convert("RGBA")
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    outputs = {
        "down": 0,
        "up": 1,
        "left": 2,
    }
    for name, row_index in outputs.items():
        sprite = _extract_row_sprite(
            source,
            row_index=row_index,
            row_count=args.rows,
            white_threshold=args.white_threshold,
            min_pixels=args.min_pixels,
        )
        output_path = output_dir / f"players_gemini_idle_{name}.png"
        sprite.save(output_path)
        print(f"Saved {name} idle sprite to {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
