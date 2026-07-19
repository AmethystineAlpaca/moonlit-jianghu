# AGENTS

## Asset Workflow

- When the user provides a full sprite sheet or a single generated image, prefer keeping the source image and writing derived files as siblings instead of overwriting the original.
- For AI-generated sprite sheets on flat green backgrounds, use `scripts/tools/chroma_key_cutout.py` to remove the background and validate transparency before importing into Godot.
- For white-background contact sheets like `players_gemini.png`, use `scripts/tools/extract_gemini_run_sheet.py` to detect each sprite, remove the white background, and repack frames onto an aligned transparent sheet before wiring it into animation code.
- Keep both files when helpful:
  - `*_green.png` for the raw keyed source
  - `*.png` for the transparent output
- If the asset will be mirrored in-game, only generate the left-facing directions unless the user explicitly asks for right-facing art too.

## Chroma-Key Commands

- Cut out the background:
  - `python3 scripts/tools/chroma_key_cutout.py cutout --input assets/xianxia/players_gemini_5dir_run_green.png --output assets/xianxia/players_gemini_5dir_run.png --despill`
- Validate transparency:
  - `python3 scripts/tools/chroma_key_cutout.py validate-alpha --input assets/xianxia/players_gemini_5dir_run.png --require-transparent-corners`

## White-Background Sheet Extraction

- Rebuild an aligned transparent sheet directly from the original contact sheet:
  - `python3 scripts/tools/extract_gemini_run_sheet.py --input assets/xianxia/players_gemini.png --output assets/xianxia/players_gemini_aligned_5dir_run.png`
- Prefer this route over AI-regenerating a new sheet when the original already contains the desired motion, because it preserves the leg and body motion from the source art.

## Verification Expectation

- After any cutout pass, validate that:
  - all four corners are transparent
  - the image is not almost fully opaque
  - the image is not fully transparent
- If green fringe remains, rerun with `--despill` and inspect the result before claiming it is ready.
