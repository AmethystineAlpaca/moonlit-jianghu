#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import sys

from PIL import Image
import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts" / "tools"))
from extract_gemini_idle_sheet import extract_idle_sheet, _content_bbox


def _make_white_sheet(rows: int, cols: int, cell_w: int, cell_h: int, sprite_rgba: tuple) -> Image.Image:
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
    sheet = _make_white_sheet(5, 6, 60, 60, (100, 150, 200, 255))
    result = extract_idle_sheet(sheet, sheet_rows=5, sheet_cols=6, use_rows=[0, 1, 2], white_threshold=245)
    assert result.width % 6 == 0
    assert result.height % 3 == 0


def test_extract_idle_sheet_shorter_than_full_source():
    sheet = _make_white_sheet(5, 6, 60, 60, (100, 150, 200, 255))
    result = extract_idle_sheet(sheet, sheet_rows=5, sheet_cols=6, use_rows=[0, 1, 2], white_threshold=245)
    assert result.height < sheet.height


def test_extract_idle_sheet_no_white_background():
    """White (255,255,255) pixels from background must not remain opaque."""
    sheet = _make_white_sheet(5, 6, 60, 60, (100, 150, 200, 255))
    result = extract_idle_sheet(sheet, sheet_rows=5, sheet_cols=6, use_rows=[0, 1, 2], white_threshold=245)
    pixels = [result.getpixel((x, y)) for y in range(result.height) for x in range(result.width)]
    white_opaque = [p for p in pixels if p[3] > 200 and p[0] > 245 and p[1] > 245 and p[2] > 245]
    assert len(white_opaque) == 0, f"found {len(white_opaque)} white background pixels that should have been removed"
