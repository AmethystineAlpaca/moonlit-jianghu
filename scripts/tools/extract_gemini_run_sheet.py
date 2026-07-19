#!/usr/bin/env python3
"""
Extract the 5x6 run sheet from players_gemini.png by detecting sprite bounds
against a white background, then repack the frames onto a clean aligned sheet.
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

from chroma_key_cutout import cutout_outer_white_background, defringe_white_edges


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Extract and align the Gemini player run sheet.")
    parser.add_argument("--input", required=True, help="Source sprite sheet path.")
    parser.add_argument("--output", required=True, help="Aligned transparent output path.")
    parser.add_argument("--rows", type=int, default=5, help="Expected row count.")
    parser.add_argument("--cols", type=int, default=6, help="Expected column count.")
    parser.add_argument("--min-pixels", type=int, default=200, help="Ignore tiny components below this size.")
    parser.add_argument("--white-threshold", type=int, default=245, help="RGB cutoff for background removal.")
    parser.add_argument(
        "--fringe-threshold",
        type=int,
        default=210,
        help="RGB cutoff for detecting near-white fringe pixels on the sprite edge.",
    )
    parser.add_argument(
        "--edge-contract",
        type=int,
        default=0,
        help="Optional number of 1px edge contraction passes after fringe cleanup.",
    )
    parser.add_argument(
        "--bright-edge-contract",
        type=int,
        default=2,
        help="Number of passes that strip bright outer edge pixels touching transparency.",
    )
    return parser.parse_args()


def is_foreground(pixel: tuple[int, int, int, int], white_threshold: int) -> bool:
    r, g, b, _a = pixel
    return not (r > white_threshold and g > white_threshold and b > white_threshold)


def find_components(image: Image.Image, min_pixels: int, white_threshold: int) -> list[tuple[int, int, int, int]]:
    width, height = image.size
    pixels = image.load()
    visited = [[False] * width for _ in range(height)]
    boxes: list[tuple[int, int, int, int]] = []

    for y in range(height):
        for x in range(width):
            if visited[y][x] or not is_foreground(pixels[x, y], white_threshold):
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
                        if is_foreground(pixels[nx, ny], white_threshold):
                            queue.append((nx, ny))
            if count >= min_pixels:
                boxes.append((min_x, min_y, max_x, max_y))
    return boxes


def cluster_rows(boxes: list[tuple[int, int, int, int]], expected_rows: int) -> list[list[tuple[int, int, int, int]]]:
    rows: list[list[tuple[int, int, int, int]]] = []
    for box in sorted(boxes, key=lambda b: b[1]):
        center_y = (box[1] + box[3]) / 2.0
        placed = False
        for row in rows:
            row_center = sum((b[1] + b[3]) / 2.0 for b in row) / float(len(row))
            if abs(center_y - row_center) < 70.0:
                row.append(box)
                placed = True
                break
        if not placed:
            rows.append([box])
    if len(rows) != expected_rows:
        raise ValueError(f"Expected {expected_rows} rows, found {len(rows)}")
    for row in rows:
        row.sort(key=lambda b: b[0])
    return rows


def crop_to_transparent(image: Image.Image, box: tuple[int, int, int, int], white_threshold: int) -> Image.Image:
    min_x, min_y, max_x, max_y = box
    crop = image.crop((min_x, min_y, max_x + 1, max_y + 1)).convert("RGBA")
    return cutout_outer_white_background(crop, white_threshold)


def _collect_opaque_neighbors(pixels, x: int, y: int, width: int, height: int) -> list[tuple[int, int, int, int]]:
    neighbors: list[tuple[int, int, int, int]] = []
    for ny in range(max(0, y - 1), min(height, y + 2)):
        for nx in range(max(0, x - 1), min(width, x + 2)):
            if nx == x and ny == y:
                continue
            sample = pixels[nx, ny]
            if sample[3] > 0:
                neighbors.append(sample)
    return neighbors


def _brightness(sample: tuple[int, int, int, int]) -> float:
    return (sample[0] + sample[1] + sample[2]) / 3.0


def _has_transparent_neighbor(pixels, x: int, y: int, width: int, height: int) -> bool:
    for ny in range(max(0, y - 1), min(height, y + 2)):
        for nx in range(max(0, x - 1), min(width, x + 2)):
            if nx == x and ny == y:
                continue
            if pixels[nx, ny][3] == 0:
                return True
    return False


def cleanup_white_fringe(image: Image.Image, fringe_threshold: int) -> Image.Image:
    out = image.copy()
    source_pixels = image.load()
    dest_pixels = out.load()
    width, height = out.size

    for y in range(height):
        for x in range(width):
            r, g, b, a = source_pixels[x, y]
            if a == 0:
                continue
            if not _has_transparent_neighbor(source_pixels, x, y, width, height):
                continue
            if r < fringe_threshold or g < fringe_threshold or b < fringe_threshold:
                continue
            neighbors = _collect_opaque_neighbors(source_pixels, x, y, width, height)
            darker_neighbors = [
                sample
                for sample in neighbors
                if _brightness(sample) <= _brightness((r, g, b, a)) - 35.0
            ]
            colored = [
                sample
                for sample in darker_neighbors
                if min(sample[0], sample[1], sample[2]) < fringe_threshold
            ]
            if not colored:
                continue
            avg_r = round(sum(sample[0] for sample in colored) / len(colored))
            avg_g = round(sum(sample[1] for sample in colored) / len(colored))
            avg_b = round(sum(sample[2] for sample in colored) / len(colored))
            dest_pixels[x, y] = (avg_r, avg_g, avg_b, a)
    return out


def contract_alpha_edges(image: Image.Image, passes: int) -> Image.Image:
    if passes <= 0:
        return image
    current = image
    for _ in range(passes):
        out = current.copy()
        source_pixels = current.load()
        dest_pixels = out.load()
        width, height = out.size
        for y in range(height):
            for x in range(width):
                if source_pixels[x, y][3] == 0:
                    continue
                if _has_transparent_neighbor(source_pixels, x, y, width, height):
                    dest_pixels[x, y] = (source_pixels[x, y][0], source_pixels[x, y][1], source_pixels[x, y][2], 0)
        current = out
    return current


def drop_bright_edge_pixels(image: Image.Image, fringe_threshold: int, passes: int) -> Image.Image:
    current = image
    for _ in range(max(0, passes)):
        out = current.copy()
        source_pixels = current.load()
        dest_pixels = out.load()
        width, height = out.size
        for y in range(height):
            for x in range(width):
                r, g, b, a = source_pixels[x, y]
                if a == 0:
                    continue
                if r < fringe_threshold or g < fringe_threshold or b < fringe_threshold:
                    continue
                if _has_transparent_neighbor(source_pixels, x, y, width, height):
                    dest_pixels[x, y] = (r, g, b, 0)
        current = out
    return current


def build_aligned_sheet(
    image: Image.Image,
    rows: list[list[tuple[int, int, int, int]]],
    cols: int,
    white_threshold: int,
    fringe_threshold: int,
    bright_edge_contract: int,
    edge_contract: int,
) -> Image.Image:
    all_boxes = [box for row in rows for box in row]
    cell_width = max(box[2] - box[0] + 1 for box in all_boxes)
    cell_height = max(box[3] - box[1] + 1 for box in all_boxes)
    sheet = Image.new("RGBA", (cell_width * cols, cell_height * len(rows)), (0, 0, 0, 0))

    for row_index, row in enumerate(rows):
        if len(row) != cols:
            raise ValueError(f"Expected {cols} columns in row {row_index}, found {len(row)}")
        for col_index, box in enumerate(row):
            sprite = crop_to_transparent(image, box, white_threshold)
            offset_x = col_index * cell_width + (cell_width - sprite.width) // 2
            offset_y = row_index * cell_height + (cell_height - sprite.height)
            sheet.alpha_composite(sprite, (offset_x, offset_y))
    sheet = cleanup_white_fringe(sheet, fringe_threshold)
    sheet = drop_bright_edge_pixels(sheet, fringe_threshold, bright_edge_contract)
    sheet = defringe_white_edges(sheet, iterations=2)
    sheet = contract_alpha_edges(sheet, edge_contract)
    return sheet


def main() -> int:
    args = parse_args()
    source = Path(args.input)
    output = Path(args.output)

    image = Image.open(source).convert("RGBA")
    boxes = find_components(image, args.min_pixels, args.white_threshold)
    if len(boxes) != args.rows * args.cols:
        raise ValueError(f"Expected {args.rows * args.cols} sprites, found {len(boxes)}")
    rows = cluster_rows(boxes, args.rows)
    sheet = build_aligned_sheet(
        image,
        rows,
        args.cols,
        args.white_threshold,
        args.fringe_threshold,
        args.bright_edge_contract,
        args.edge_contract,
    )
    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output)
    print(f"Saved aligned sheet to {output}")
    print(f"Sheet size: {sheet.size[0]}x{sheet.size[1]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
