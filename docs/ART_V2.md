> **历史归档 / Legacy 2D reference.** 本文描述旧二维版本的设计、实验或素材流程，不代表当前 3D 功能与待办状态。[当前版本说明](STILLWATER.md)。

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

## 旧版玩家动作表来源梳理 · 2026-10-17

维护者确认旧版角色图片为 AI 生成素材，主要使用 Gemini 和 GPT Image。原始跑步、待机动作表分别保留在 `assets/unused/players_gemini.png` 和 `assets/unused/players_gemini_still.png`。这一说明记录维护者提供的来源信息，不代表已逐张核实具体模型、账户套餐或输入参考图。

当前 2D 玩家使用本地脚本派生的 `assets/xianxia/players_gemini_aligned_5dir_run.png`（`extract_gemini_run_sheet.py`）和 `assets/xianxia/players_gemini_aligned_idle.png`（`extract_gemini_idle_sheet.py`）。待机表为 3 行 × 6 列，依次为正面、背面和左侧，右侧通过镜像显示。

由于尚未确认 Photoroom 处理时适用的账户和条款，已从当前工作树移除 `players_gemini-Photoroom.png`、`players_gemini_still-Photoroom.png` 及对应导入描述；保留原始生成图片和上述本地派生版本。历史提交及旧发布包不受此清理影响。代码的 MIT 许可及旧版图库的排除范围见 [LICENSE_SCOPE.md](../LICENSE_SCOPE.md)；第三方素材已有许可保持不变。
