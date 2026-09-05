# 新素材来源与派生记录

本轮栅格素材通过内置 `image_gen.imagegen` 工具生成；没有覆盖原始素材。以下为最终生成提示的内容摘要（不是逐字调用日志）。原始生成文件复制到 `assets/art_v2/` 后，工具脚本产出同目录派生文件。

| 原图 / 运行文件 | 生成提示内容 |
| --- | --- |
| title_moonlit.png | Moonlit Chinese mountain village, lone swordsman on the right, elegant ink-blue and muted jade palette, warm lanterns, open negative space on the left for a title, no text. |
| terrain_qinglan.png | Top-down wuxia village terrain, muted grass and stone crossroads, central circular stone plaza, cohesive painterly pixel-art texture, no characters or buildings. |
| environment_green.png → tree_jade.png, tree_ginkgo.png, rocks_moss.png, supply_crate.png | Four isolated game props in a 2×2 sheet: jade tree, golden ginkgo, mossy rocks, wooden supply crate; consistent top-down view, flat green chroma-key background. |
| mountain_guardian_green.png → mountain_guardian.png | Left-facing spectral tiger guardian, ivory fur, slate markings, jade wisps and an amber seal, refined pixel-art silhouette on a flat green background. |
| player_attack_green.png → player_attack_aligned.png | Match the existing black-haired white-robed swordsman; 6 columns × 3 rows of sword-swing body poses, down/side/up directions, preparation through follow-through; no weapon, no magic or slash baked into the frames; flat green background. |

`chroma_key_cutout.py --despill` 输出 keyed 图；环境裁切由 `prepare_art_v2.py` 完成，攻击帧由 `prepare_attack_v2.py` 对齐。生成器输出的侧面实际朝右，派生时镜像为左向，游戏再按朝向镜像。攻击图 960×672，6×3 帧，每帧 160×224。

字体：Google Fonts 的 Noto Serif SC 和 Noto Sans SC，SIL Open Font License，许可文本位于 `assets/fonts/OFL-Serif.txt`、`OFL-Sans.txt`。

音乐：`scripts/tools/compose_qinglan.py` 合成的 24 秒五声音阶循环，输出 `assets/audio/qinglan_night.wav`，未使用第三方采样。兵刃和技能符号以 Godot 绘图代码实现。
