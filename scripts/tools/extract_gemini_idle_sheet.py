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
