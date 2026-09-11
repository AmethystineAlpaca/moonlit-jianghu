# Stillwater community launch drafts

Prepared 2026-09-11 for **v0.3.0-preview.1**. These are **unpublished drafts** written in the project maintainer's voice. They are ready for the maintainer's own account once the release and its attached files are public. No Godot Forum account is currently available; no account has been registered and no forum post has been submitted as part of this preparation.

Use [PRESS_KIT.md](PRESS_KIT.md) for media, facts, credits and preview limitations. Keep public claims tied to the released build rather than uncommitted development work.

## Godot Forum — In Development

Use the appropriate **In Development** project category after checking its current description. Publish one topic and continue substantive development updates in that topic. The [official forum guidelines](https://forum.godotengine.org/guidelines) prohibit spam and posting the same thing in multiple topics; they also ask posters to choose the right category and contribute useful discussion. Do not submit this preview to Godot's curated game showcase while it does not meet that showcase's requirements.

Attach `docs/showcase/v3/combat-readability.mp4` or `combat-preview.gif` with the caption “Native-engine capture with scripted controls.” Use one language version appropriate to the audience; the Chinese text below is an alternate draft, not a second duplicate topic.

### English draft

**Title:** Stillwater — a Godot 4.6 3D wuxia combat preview: dash-recall, collisions and readable attacks

I'm the maintainer of Moonlit Jianghu, and I'm sharing a playable preview of its current 3D chapter, **Stillwater**. It takes place in one rainy mountain courtyard: three lantern seals, two upgrade choices, then a final duel.

The interaction I'm testing is movement that creates a follow-up. Dashing leaves a temporary echo; Q recalls along that path and cuts through opponents. E shoves an enemy into another enemy or a wall. Timed guards can reflect projectiles, and breaking posture opens an F follow-up. There are three blades with different attack rhythms.

Some of the most useful changes came from negative feedback. Players couldn't tell when an expanding warning circle would finish, so ordinary enemies now communicate their attacks through a raised weapon, a short hold and a pre-strike glint. I also revised input buffering, stopping motion and damage-direction feedback. I want to find out whether these changes read clearly to someone who hasn't watched the project develop.

On the Godot side, this is a Godot 4.6.2 / GDScript project with skeletal animations, hand-bone weapon attachments, directional hit checks and collision-driven follow-ups. The source includes regression checks for animation movement, input-to-damage timing, recall paths and directional avoidance. The characters use KayKit's CC0 Adventurers models with runtime palette, proportion and animation-timing changes; they are not custom sculpts.

**Try it:** https://github.com/AmethystineAlpaca/moonlit-jianghu/releases/tag/v0.3.0-preview.1

**Source and controls:** https://github.com/AmethystineAlpaca/moonlit-jianghu

This is a single-map development preview with Chinese in-game UI; the README has English controls. macOS startup has been checked on Apple M4 / Metal. The Windows build is cross-exported and still needs Windows hardware feedback. Controller mappings exist but haven't been validated on a physical controller. The source is public; no repository-wide reuse license has been chosen.

If you try one encounter, I'd particularly like to know:

1. Could you predict when an enemy would strike without watching a floor timer?
2. Did movement stop where you expected, and could you tell when you took a hit?
3. Did recall or collision create a choice you wanted to use again?

A specific moment, your hardware and a short clip if available would help more than a score. Replies here are welcome, or use the [playtest form](https://github.com/AmethystineAlpaca/moonlit-jianghu/issues/new?template=playtest-feedback.yml). I'm happy to discuss how the animation sampling or combat state handling works.

### 中文备选稿

**标题：**《雨歇》：Godot 4.6 制作的 3D 武侠战斗试玩，想听听大家对回锋、碰撞和读招的反馈

我是《月下江湖》项目的维护者。这次分享的是当前的 3D 篇章《雨歇》：一座雨后山院、三处石灯封印、两次成长选择，以及最后与无相的一战。

我现在重点尝试的是让位移产生后续选择。闪避会留下短暂的留影，Q 沿回程路径穿斩；E 把敌人踢向墙面或其他敌人，制造碰撞；瞬间正面格挡可以反弹飞弹，打满架势后能按 F 追斩。三种兵刃的出手节奏也不同。

之前的试玩反馈指出，敌人脚下不断变大的圆圈无法让人判断何时出手，移动也像在滑冰。这次普通敌人改为举刃、停留、刃光、下劈来读招，同时调整输入缓冲、收步和受击方向提示。我想知道，第一次接触这个项目的人能否真的看懂这些变化。

项目使用 Godot 4.6.2 / GDScript，武器挂在手骨上，采用方向命中判定与碰撞追击。源码里有动作变化、输入到伤害时序、回锋路径和侧移避击的回归检查。角色来自 KayKit 的 CC0 Adventurers 模型，运行时调整了配色、比例和动作时序，并非专门为本项目制作的角色雕模。

**试玩下载：** https://github.com/AmethystineAlpaca/moonlit-jianghu/releases/tag/v0.3.0-preview.1

**源码与操作说明：** https://github.com/AmethystineAlpaca/moonlit-jianghu

目前是单地图开发试玩版，游戏界面为中文。macOS 已在 Apple M4 / Metal 上检查启动；Windows 是交叉导出，尚待 Windows 实机反馈。手柄有映射，实体手柄还没有验证。源码公开可查看，仓库尚未选定统一的复用许可。

如果愿意打一场，我最想知道三件事：不用地圈计时，能不能预判敌人出手；移动能不能停在预期位置，挨打时是否清楚；回锋和碰撞有没有让你想主动使用的价值。欢迎直接回帖，或者填写[试玩反馈](https://github.com/AmethystineAlpaca/moonlit-jianghu/issues/new?template=playtest-feedback.yml)。能描述一个具体时刻、附上设备信息，就已经很有帮助。

## Short social copy

Pair one paragraph with an actual gameplay clip. Identify yourself as the maintainer, and use the release page as the main destination. Check each service's current posting and character limits before publishing.

### English

I maintain Stillwater, a Godot 3D wuxia combat project. Dash → recall through enemies; shove → collide; deflect → follow up. A single-map preview is ready for feedback on movement and readable attacks. Chinese UI, English controls guide.

https://github.com/AmethystineAlpaca/moonlit-jianghu/releases/tag/v0.3.0-preview.1

Optional relevant tags: `#Godot #GameDev #IndieDev`

### 中文

我维护的 Godot 3D 武侠项目《雨歇》放出单关卡试玩了：闪避留影后回锋穿斩，破阵制造碰撞，见切接破势追斩。想请大家打一场，告诉我操作是否跟手、敌人出招和挨打能否看清。

https://github.com/AmethystineAlpaca/moonlit-jianghu/releases/tag/v0.3.0-preview.1

可选相关标签：`#Godot #独立游戏 #游戏开发`

## Posting and follow-up record

| Destination | Status | Next useful action |
| --- | --- | --- |
| GitHub release | Publication handled separately; verify the tag page and attachments | Link the tested build, controls, platform notes and feedback form. |
| GitHub Discussions | Available for project conversation | Keep one release/playtest thread with specific questions and respond to reports. |
| Godot Forum / In Development | Draft only; no account available | Publish through the maintainer's account when available, after checking category rules. |
| Other social channels | Copy prepared; no publication recorded here | Use an existing maintainer account and a relevant audience, with a native clip. |

Record a real post URL and date only after publication. Reply to useful reports with the issue or fix that follows from them, and update the original topic when a build meaningfully changes. Measure actual release downloads, visitors and actionable playtest reports alongside Stars; a change in Stars alone does not explain whether the game reached interested players. Keep requests for feedback voluntary, and do not offer rewards for Stars or portray promotion as an independent recommendation.
