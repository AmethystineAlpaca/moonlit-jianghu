"""Derive runtime sprites from the saved generated atlas; retain the raw source."""
from pathlib import Path
from PIL import Image
root = Path(__file__).resolve().parents[2]
assets = root / 'assets/art_v2'
im = Image.open(assets / 'environment.png').convert('RGBA')
w, h = im.size
regions = [(16, 24, w//2-12, h//2-12), (w//2+12, 24, w-24, h//2-12),
           (16, h//2+20, w//2-12, h-18), (w//2+12, h//2+20, w-24, h-18)]
for name, rect, height in zip(['tree_jade','tree_ginkgo','rocks_moss','supply_crate'], regions, [96, 96, 38, 34]):
    sprite = im.crop(rect)
    sprite = sprite.crop(sprite.getbbox())
    sprite = sprite.resize((round(sprite.width * height / sprite.height), height), Image.Resampling.LANCZOS)
    out = Image.new('RGBA', (sprite.width+4, sprite.height+4))
    out.paste(sprite, (2,2))
    out.save(assets / f'{name}.png')
    print(name, out.size)
