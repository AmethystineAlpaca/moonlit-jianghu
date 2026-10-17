# Stillwater — third-party notices

Project code uses MIT as scoped in [LICENSE_SCOPE.md](LICENSE_SCOPE.md).
The components below retain their own licenses. This file is distributed with
the game; full license texts are in the adjacent `licenses/` directory.

| Component | Copyright / author | License text |
| --- | --- | --- |
| Godot Engine 4.6.2 | Godot Engine contributors; Juan Linietsky, Ariel Manzur | `licenses/GODOT_LICENSE.txt` (MIT) |
| Godot third-party components | Respective authors listed in the notice | `licenses/GODOT_COPYRIGHT.txt` |
| KayKit Adventurers Character Pack 1.0: Rogue_Hooded, Knight, Mage and associated textures | Kay Lousberg / KayKit | `licenses/KAYKIT_CC0_NOTICE.txt`, `licenses/CC0-1.0.txt` |
| Noto Sans SC | Copyright holder(s) recorded in its accompanying license | `licenses/NOTO_SANS_OFL.txt` (OFL 1.1) |
| Noto Serif SC | Copyright holder(s) recorded in its accompanying license | `licenses/NOTO_SERIF_OFL.txt` (OFL 1.1) |

Sources:

- Godot license: https://godotengine.org/license/
- Engine MIT text: https://github.com/godotengine/godot/blob/4.6.2-stable/LICENSE.txt
- Engine dependency notices: https://github.com/godotengine/godot/blob/4.6.2-stable/COPYRIGHT.txt
- KayKit pack: https://github.com/KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0
- CC0 legal text: https://creativecommons.org/publicdomain/zero/1.0/legalcode
- Noto Sans SC: https://fonts.google.com/noto/specimen/Noto+Sans+SC
- Noto Serif SC: https://fonts.google.com/noto/specimen/Noto+Serif+SC

Godot notice files are copied verbatim from the engine's `4.6.2-stable` tag.
The KayKit and font notices are copied verbatim from the files accompanying the
assets in this repository. The Godot dependency notice includes the upstream
component inventory; a given platform build may use only a subset.

The models' palettes, proportions, animation timing and equipped weapons are
adjusted at runtime by project code. The original GLB files are retained.
The Noto binaries retain OFL; `StillwaterSans.tres` and `StillwaterSerif.tres`
are project resource wrappers, not newly authored font faces.

Combat audio is synthesized by the project's Python scripts without external
samples. Legacy AI-generated 2D artwork and showcase media are excluded from
the project's MIT grant and from the new 3D desktop packages; see the scope
document for details. No rights or endorsement from AI providers are implied.
