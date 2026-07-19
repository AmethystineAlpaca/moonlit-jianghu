#!/usr/bin/env python3

from __future__ import annotations

import importlib.util
import unittest
from pathlib import Path

from PIL import Image


MODULE_PATH = Path(__file__).resolve().parents[1] / "scripts" / "tools" / "chroma_key_cutout.py"
SPEC = importlib.util.spec_from_file_location("chroma_key_cutout", MODULE_PATH)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC is not None and SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


class WhiteBackgroundFloodCutoutTests(unittest.TestCase):
    def test_removes_only_outer_connected_white_background(self) -> None:
        white = (255, 255, 255, 255)
        near_white = (247, 248, 246, 255)
        black = (0, 0, 0, 255)
        red = (220, 40, 40, 255)
        inner_white = (252, 252, 252, 255)

        image = Image.new("RGBA", (7, 7), white)
        pixels = image.load()

        for x in range(1, 6):
            pixels[x, 1] = black
            pixels[x, 5] = black
        for y in range(1, 6):
            pixels[1, y] = black
            pixels[5, y] = black

        pixels[3, 3] = inner_white
        pixels[3, 4] = red
        pixels[0, 3] = near_white

        result = MODULE.cutout_outer_white_background(image, white_threshold=245)
        out = result.load()

        self.assertEqual(out[0, 0][3], 0)
        self.assertEqual(out[0, 3][3], 0)
        self.assertEqual(out[3, 3], inner_white)
        self.assertEqual(out[3, 4], red)
        self.assertEqual(out[1, 1], black)


if __name__ == "__main__":
    unittest.main()
