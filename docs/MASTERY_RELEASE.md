# 雨歇 0.4.0 · 剑意更新

验证日期：2026-09-11。

- 自动测试：36/36 通过；检查退出状态与 Godot 错误日志。
- 完整脚本操控：三封印、19 名敌人、胜利，最新普通难度约 72.5 秒；不是人类试玩成绩。
- 原生 Metal：1280×720，四名敌人活动与持续攻击的短样本，平均 17.28 ms / 帧，p95 16.67 ms，含垂直同步；仅代表 Apple M4 当前场景。
- 导出 macOS 应用实际验证：标题确认进入游戏、键盘移动、空格闪避与留影、Esc 暂停。
- Windows 完成交叉导出，未做 Windows 实机验证。

本地构建：

- `output/releases/Stillwater-mastery-macOS.zip`
- `output/releases/Stillwater-mastery-macOS/Moonlit Jianghu.app`
- `output/releases/Stillwater-mastery-Windows.zip`

旧构建保留。macOS 为本地签名，未公证；没有公开发布。

主要变化：V 剑意绝技、六种成长、局内检查点、极限闪避奖励、首领抗打断与阶段演出、三档难度、动态披巾与湿石雨景、技能图标与中文字体、新增原创短音效。完整机制见 [STILLWATER.md](STILLWATER.md)。

截图是原生引擎渲染，部分战斗布置和结算数值用于视觉检查。测试日志、性能样本和导出日志位于 `output/mastery/`。
