#!/usr/bin/env python3

from __future__ import annotations

from pathlib import Path

from PIL import Image


ASSET_PATH = Path("assets/xianxia/players_gemini_aligned_5dir_run.png")
MAX_WHITE_FRINGE_PIXELS = 80


def has_transparent_neighbor(pixels, x: int, y: int, width: int, height: int) -> bool:
    for ny in range(max(0, y - 1), min(height, y + 2)):
        for nx in range(max(0, x - 1), min(width, x + 2)):
            if nx == x and ny == y:
                continue
            if pixels[nx, ny][3] == 0:
                return True
    return False


def brightness(sample: tuple[int, int, int, int]) -> float:
    return (sample[0] + sample[1] + sample[2]) / 3.0


def has_dark_opaque_neighbor(pixels, x: int, y: int, width: int, height: int, current_brightness: float) -> bool:
    for ny in range(max(0, y - 1), min(height, y + 2)):
        for nx in range(max(0, x - 1), min(width, x + 2)):
            if nx == x and ny == y:
                continue
            sample = pixels[nx, ny]
            if sample[3] == 0:
                continue
            if brightness(sample) <= current_brightness - 35.0:
                return True
    return False


def count_white_fringe_pixels(image: Image.Image) -> int:
    pixels = image.load()
    width, height = image.size
    count = 0
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue
            if not has_transparent_neighbor(pixels, x, y, width, height):
                continue
            current_brightness = brightness((r, g, b, a))
            if not has_dark_opaque_neighbor(pixels, x, y, width, height, current_brightness):
                continue
            if r >= 210 and g >= 210 and b >= 210:
                count += 1
    return count


def main() -> int:
    image = Image.open(ASSET_PATH).convert("RGBA")
    white_fringe_pixels = count_white_fringe_pixels(image)
    print(f"white fringe pixels: {white_fringe_pixels}")
    if white_fringe_pixels > MAX_WHITE_FRINGE_PIXELS:
        print(
            f"FAIL: expected at most {MAX_WHITE_FRINGE_PIXELS} white fringe pixels, got {white_fringe_pixels}"
        )
        return 1
    print("PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
