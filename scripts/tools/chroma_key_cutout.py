#!/usr/bin/env python3
"""
Small utility for removing a chroma-key background from sprite sheets and
validating alpha on the output.

This is intentionally lightweight so we can reuse it for AI-generated sheets
that come back on flat green or magenta backgrounds before importing into Godot.
"""

from __future__ import annotations

import argparse
import sys
from collections import deque
from pathlib import Path

from PIL import Image


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Remove a chroma-key background and validate alpha on sprite sheets."
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    cutout = subparsers.add_parser(
        "cutout",
        help="Remove a green-screen style background and optionally despill edges.",
    )
    cutout.add_argument("--input", required=True, help="Input image path.")
    cutout.add_argument("--output", required=True, help="Output PNG path.")
    cutout.add_argument(
        "--min-green",
        type=int,
        default=150,
        help="Minimum green channel value to qualify as key color.",
    )
    cutout.add_argument(
        "--green-margin",
        type=int,
        default=80,
        help="How much greener the pixel must be than red and blue.",
    )
    cutout.add_argument(
        "--despill",
        action="store_true",
        help="Suppress residual green fringe on remaining opaque pixels.",
    )

    white_cutout = subparsers.add_parser(
        "outer-white-cutout",
        help="Remove only white or near-white background connected to the outer image boundary.",
    )
    white_cutout.add_argument("--input", required=True, help="Input image path.")
    white_cutout.add_argument("--output", required=True, help="Output PNG path.")
    white_cutout.add_argument(
        "--white-threshold",
        type=int,
        default=245,
        help="Pixels at or above this RGB threshold count as white background.",
    )
    white_cutout.add_argument(
        "--defringe",
        action="store_true",
        help="After BFS, recover true alpha on border pixels to remove residual white fringe.",
    )
    white_cutout.add_argument(
        "--defringe-iterations",
        type=int,
        default=2,
        help="How many pixel layers inward to defringe (default 2).",
    )

    validate = subparsers.add_parser(
        "validate-alpha",
        help="Check whether transparent output looks sane at a basic level.",
    )
    validate.add_argument("--input", required=True, help="PNG path to inspect.")
    validate.add_argument(
        "--require-transparent-corners",
        action="store_true",
        help="Fail if any corner is still opaque.",
    )
    return parser.parse_args()


def load_rgba(path: Path) -> Image.Image:
    return Image.open(path).convert("RGBA")


def cutout_image(
    image: Image.Image,
    min_green: int,
    green_margin: int,
    despill: bool,
) -> Image.Image:
    out = image.copy()
    pixels = out.load()
    width, height = out.size

    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            if g >= min_green and (g - r) >= green_margin and (g - b) >= green_margin:
                pixels[x, y] = (0, 0, 0, 0)
            elif despill and a > 0 and g > r + 20 and g > b + 20:
                pixels[x, y] = (r, max(r, b), b, a)
    return out


def is_near_white(pixel: tuple[int, int, int, int], white_threshold: int) -> bool:
    r, g, b, a = pixel
    return a > 0 and r >= white_threshold and g >= white_threshold and b >= white_threshold


def cutout_outer_white_background(image: Image.Image, white_threshold: int) -> Image.Image:
    source = image.convert("RGBA")
    out = source.copy()
    pixels = out.load()
    width, height = out.size
    queue: deque[tuple[int, int]] = deque()
    visited: set[tuple[int, int]] = set()

    def enqueue_if_background(x: int, y: int) -> None:
        point = (x, y)
        if point in visited:
            return
        visited.add(point)
        if is_near_white(pixels[x, y], white_threshold):
            queue.append(point)

    for x in range(width):
        enqueue_if_background(x, 0)
        enqueue_if_background(x, height - 1)
    for y in range(height):
        enqueue_if_background(0, y)
        enqueue_if_background(width - 1, y)

    while queue:
        x, y = queue.popleft()
        pixels[x, y] = (0, 0, 0, 0)
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < width and 0 <= ny < height:
                enqueue_if_background(nx, ny)

    return out


def defringe_white_edges(image: Image.Image, iterations: int = 2) -> Image.Image:
    """
    Remove residual white fringe left after BFS white-background removal.

    For each opaque pixel that borders a transparent pixel, recover the true
    alpha and color by assuming the sprite was originally composited on white:
        C_comp = C_orig * alpha + 255 * (1 - alpha)
    Using min(R,G,B)/255 as an estimate of the white fraction gives a stable
    approximation that works for dark and colored sprites alike.
    Only border pixels are touched, so interior white details are preserved.
    """
    out = image.copy()
    pixels = out.load()
    width, height = out.size

    for _ in range(iterations):
        border = []
        for y in range(height):
            for x in range(width):
                if pixels[x, y][3] == 0:
                    continue
                for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if 0 <= nx < width and 0 <= ny < height and pixels[nx, ny][3] == 0:
                        border.append((x, y))
                        break

        for x, y in border:
            r, g, b, a = pixels[x, y]
            white_frac = min(r, g, b) / 255.0
            new_alpha = int((1.0 - white_frac) * a)
            if new_alpha < 8:
                pixels[x, y] = (0, 0, 0, 0)
            elif new_alpha < a:
                af = new_alpha / 255.0
                r2 = min(255, max(0, round((r - 255 * (1.0 - af)) / af)))
                g2 = min(255, max(0, round((g - 255 * (1.0 - af)) / af)))
                b2 = min(255, max(0, round((b - 255 * (1.0 - af)) / af)))
                pixels[x, y] = (r2, g2, b2, new_alpha)

    return out


def validate_alpha(image: Image.Image, require_transparent_corners: bool) -> tuple[bool, list[str]]:
    width, height = image.size
    pixels = image.load()
    messages: list[str] = []

    corners = {
        "top_left": (0, 0),
        "top_right": (width - 1, 0),
        "bottom_left": (0, height - 1),
        "bottom_right": (width - 1, height - 1),
    }
    opaque_corners: list[str] = []
    for name, point in corners.items():
        if pixels[point][3] != 0:
            opaque_corners.append(f"{name}={pixels[point]}")

    if opaque_corners:
        messages.append("Corners still opaque: " + ", ".join(opaque_corners))
    elif require_transparent_corners:
        messages.append("All four corners are transparent.")

    non_transparent = 0
    for y in range(height):
        for x in range(width):
            if pixels[x, y][3] > 0:
                non_transparent += 1

    coverage = non_transparent / float(width * height)
    messages.append(f"Opaque coverage: {coverage:.4f}")

    ok = True
    if require_transparent_corners and opaque_corners:
        ok = False
    if coverage <= 0.0:
        messages.append("Image is fully transparent.")
        ok = False
    if coverage >= 0.95:
        messages.append("Image is almost fully opaque; cutout likely failed.")
        ok = False

    return ok, messages


def run_cutout(args: argparse.Namespace) -> int:
    source = Path(args.input)
    output = Path(args.output)
    image = load_rgba(source)
    result = cutout_image(image, args.min_green, args.green_margin, args.despill)
    output.parent.mkdir(parents=True, exist_ok=True)
    result.save(output)
    print(f"Saved cutout to {output}")
    return 0


def run_outer_white_cutout(args: argparse.Namespace) -> int:
    source = Path(args.input)
    output = Path(args.output)
    image = load_rgba(source)
    result = cutout_outer_white_background(image, args.white_threshold)
    if args.defringe:
        result = defringe_white_edges(result, iterations=args.defringe_iterations)
    output.parent.mkdir(parents=True, exist_ok=True)
    result.save(output)
    print(f"Saved cutout to {output}")
    return 0


def run_validate_alpha(args: argparse.Namespace) -> int:
    image = load_rgba(Path(args.input))
    ok, messages = validate_alpha(image, args.require_transparent_corners)
    for message in messages:
        print(message)
    return 0 if ok else 1


def main() -> int:
    args = parse_args()
    if args.command == "cutout":
        return run_cutout(args)
    if args.command == "outer-white-cutout":
        return run_outer_white_cutout(args)
    if args.command == "validate-alpha":
        return run_validate_alpha(args)
    print(f"Unknown command: {args.command}", file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
