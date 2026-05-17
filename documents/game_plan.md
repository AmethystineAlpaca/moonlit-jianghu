# 2D Top-Down Medieval RPG + Custom Card System Plan

## 1. Game Vision

做一个 2D 俯视角中世纪 RPG。玩家在村庄、野外、地牢等场景中探索、战斗、收集资源、推进剧情，并通过一套可自定义的卡牌系统改变角色能力、战斗方式、任务解法，甚至影响世界状态。

核心方向：

- 视角：2D top-down。
- 引擎：Godot 4.x。
- 类型：中世纪 RPG，先做小规模可玩版本，再扩展为更完整的冒险。
- 卡牌定位：不是单独的小游戏，而是 RPG 系统的一部分。卡牌可以代表技能、装备、法术、事件、契约、祝福、诅咒、地形效果等。
- 设计原则：先让角色能动、能打、能获得反馈；再逐步加入成长、卡牌、任务、内容和编辑能力。

## 2. Development Philosophy

### 从简单到成熟

第一阶段不要追求“大世界”和复杂职业系统。先做一个小地图、一个角色、一个敌人、几张基础卡牌，确认核心玩法是否成立。

### 系统先小，但结构要能扩展

卡牌、物品、技能、敌人最好从一开始就用数据驱动方式设计，例如 Godot `Resource`、JSON、或者 `.tres` 资源。这样后面做“自定义卡牌功能”时不会推翻重来。

### 每个阶段都要有可玩成果

每一阶段结束时都应该能打开项目体验到一个明确进步，而不是只堆代码。

## 3. Phase 0: Project Foundation

目标：建立干净的 Godot 项目结构，让后续开发有地方放。

要做：

- 建立目录结构：
  - `scenes/`: 场景文件。
  - `scripts/`: GDScript 脚本。
  - `assets/`: 美术、音效、字体。
  - `resources/`: 卡牌、物品、敌人等数据资源。
  - `ui/`: UI 场景和脚本。
  - `documents/`: 设计文档和计划。
- 建立主场景 `Main.tscn`。
- 建立基础输入映射：
  - move_up
  - move_down
  - move_left
  - move_right
  - interact
  - attack
  - open_deck
  - use_card_1 到 use_card_4
- 确定像素风、手绘风、低分辨率复古风，或者临时占位图风格。

交付结果：

- 项目可以运行。
- 有主场景。
- 有清楚的文件夹结构。

## 4. Phase 1: Minimal Playable Prototype

目标：做出最小可玩的“人能走、敌人会动、能攻击、会受伤”的原型。

要做：

- 玩家角色：
  - 俯视角 8 方向移动。
  - 简单动画状态：idle、walk、attack。
  - 生命值、受伤、死亡。
- 摄像机：
  - 跟随玩家。
  - 限制在地图边界内。
- 测试地图：
  - 一个小村外空地或训练场。
  - 简单障碍物和碰撞。
- 敌人：
  - 基础近战敌人。
  - 简单 AI：巡逻、发现玩家、追击、攻击、死亡。
- 战斗：
  - 玩家基础近战攻击。
  - 敌人基础近战攻击。
  - 命中反馈：闪烁、击退、音效或数字飘字。

交付结果：

- 一个 1-3 分钟的可玩小场景。
- 玩家可以打败敌人，也可能被敌人打败。

## 5. Phase 2: RPG Core Loop

目标：让游戏从“动作测试”变成“RPG 小循环”。

要做：

- 角色属性：
  - HP
  - stamina 或 mana
  - attack
  - defense
  - speed
  - crit chance
- 经验和升级：
  - 击败敌人获得经验。
  - 升级提升基础属性。
  - 升级时可以选择奖励，后面可接入卡牌奖励。
- 物品系统：
  - 金币、药水、材料。
  - 简单背包。
  - 拾取和使用。
- NPC 和交互：
  - 对话框。
  - 一个基础 NPC。
  - 一个简单任务：例如消灭营地敌人，回来领奖。
- 地图流转：
  - 村庄。
  - 野外。
  - 小地牢入口。

交付结果：

- 玩家有成长感。
- 有一个完整的短任务闭环：接任务、探索、战斗、奖励、回到 NPC。

## 6. Phase 3: First Card System

目标：把卡牌作为可玩的核心机制接入 RPG，而不是只做 UI 展示。

第一版卡牌定义：

- Card ID
- 名称
- 描述
- 类型：
  - attack
  - defense
  - spell
  - movement
  - summon
  - passive
  - event
- 消耗：
  - mana
  - stamina
  - cooldown
- 目标类型：
  - self
  - enemy
  - area
  - direction
  - world
- 效果列表：
  - damage
  - heal
  - shield
  - dash
  - buff
  - debuff
  - spawn
  - draw_card
  - modify_card

要做：

- 卡牌数据结构：
  - 建议使用 Godot `Resource` 定义 `CardData`。
  - 每张卡牌保存为独立 `.tres`，方便编辑和扩展。
- 卡组系统：
  - deck
  - hand
  - discard pile
  - draw pile
- 手牌 UI：
  - 屏幕下方显示 3-5 张手牌。
  - 支持快捷键使用卡牌。
  - 鼠标悬停显示描述。
- 卡牌使用：
  - 先做即时使用。
  - 后面再加入瞄准、范围选择、拖拽等。
- 第一批测试卡：
  - Slash: 对前方敌人造成伤害。
  - Guard: 获得短时间护盾。
  - Firebolt: 发射火球。
  - Dash: 向移动方向冲刺。
  - Heal: 回复生命。

交付结果：

- 玩家能在战斗中抽牌、用牌。
- 卡牌能真正影响战斗结果。

## 7. Phase 4: Data-Driven Custom Cards

目标：支持“卡牌性质和功能可以自定义”，让以后新增卡牌不需要每次写一堆专用代码。

要做：

- 效果系统：
  - 每张卡由多个效果组成。
  - 效果按顺序执行。
  - 效果可以带参数。
- 建议效果格式：

```text
Card: Burning Slash
Cost: 2 mana
Effects:
  1. deal_damage(amount=8, target=front_enemy)
  2. apply_status(status=burning, duration=4)
```

- 效果执行器：
  - `CardEffectExecutor`
  - 根据效果类型调用不同处理逻辑。
- 状态系统：
  - burn
  - poison
  - slow
  - stun
  - shield
  - bless
  - curse
- 条件系统：
  - if target_hp_below
  - if player_has_status
  - if card_type_played_this_turn
  - if in_forest
- 卡牌修改：
  - 升级卡牌。
  - 给卡牌添加额外效果。
  - 改变费用、范围、伤害类型。

交付结果：

- 可以通过数据创建新卡。
- 一张卡可以组合多个效果。
- 初步支持自定义卡牌逻辑。

## 8. Phase 5: Combat Maturity

目标：让战斗从“能打”变成“有策略”。

要做：

- 敌人类型：
  - 近战兵。
  - 弓箭手。
  - 法师。
  - 盾兵。
  - 精英怪。
- 敌人意图：
  - 下一步要攻击、防御、施法、召唤。
  - 可在 UI 上提示，让玩家用卡牌应对。
- 战斗节奏：
  - 实时战斗 + 卡牌冷却。
  - 或实时移动 + 用卡时短暂慢动作。
  - 后续可评估是否改成半即时或回合制。
- 资源管理：
  - mana 自动恢复。
  - stamina 用于闪避和武器攻击。
  - 某些卡牌消耗生命、金币、材料或弃牌。
- Boss 原型：
  - 一个小 Boss。
  - 有 3 个阶段。
  - 需要用卡牌机制解决。

交付结果：

- 一场战斗不只是拼数值，需要玩家选择卡牌时机和站位。

## 9. Phase 6: World, Quest, and Medieval Flavor

目标：建立中世纪 RPG 氛围和可探索内容。

要做：

- 世界区域：
  - 村庄。
  - 森林。
  - 废墟。
  - 地牢。
  - 城堡外围。
- NPC：
  - 铁匠。
  - 炼金师。
  - 修道士。
  - 雇佣兵队长。
  - 流浪卡牌师。
- 任务类型：
  - 击败敌人。
  - 寻找物品。
  - 护送。
  - 解谜。
  - 道德选择。
- 中世纪主题卡牌：
  - Knight's Oath: 获得防御并嘲讽敌人。
  - Witchfire: 对区域造成火焰和恐惧。
  - Blacksmith's Mark: 强化下一次武器攻击。
  - Monk's Prayer: 治疗并清除诅咒。
  - Mercenary Contract: 召唤临时盟友。

交付结果：

- 游戏有明显的世界感，而不只是测试场。

## 10. Phase 7: Deckbuilding and Progression

目标：让卡牌成长成为长期动力。

要做：

- 获得卡牌：
  - 战斗奖励。
  - 任务奖励。
  - 商店购买。
  - NPC 交换。
  - 地牢宝箱。
- 卡组管理：
  - 战斗外编辑卡组。
  - 限制卡组大小。
  - 稀有度和职业倾向。
- 卡牌升级：
  - 数值增强。
  - 新增效果。
  - 改变目标方式。
  - 降低费用。
- 职业或流派：
  - Knight: 防御、反击、嘲讽。
  - Ranger: 位移、陷阱、远程。
  - Mage: 法术、元素、连锁。
  - Cleric: 治疗、祝福、驱散。
  - Warlock: 诅咒、献祭、召唤。
- 构筑关键词：
  - burn
  - bleed
  - shield
  - combo
  - summon
  - curse
  - terrain

交付结果：

- 玩家会开始思考“我要走什么流派”。
- 卡牌不只是战斗按钮，而是角色构筑的一部分。

## 11. Phase 8: Custom Card Editor

目标：让自定义卡牌变成可见、可调、可保存的工具。

建议先做开发者工具，再考虑玩家可用编辑器。

要做：

- 内部卡牌编辑器：
  - 名称。
  - 描述。
  - 图标。
  - 类型。
  - 费用。
  - 冷却。
  - 目标规则。
  - 效果列表。
  - 条件列表。
- 效果参数 UI：
  - 数值输入。
  - 下拉选择目标。
  - 状态选择。
  - 持续时间。
- 保存和加载：
  - 保存为 `.tres` 或 JSON。
  - 支持重新加载卡牌数据。
- 校验：
  - 缺少名称时提示。
  - 费用不能为负。
  - 效果参数必须完整。
  - 不允许引用不存在的状态或效果。
- 测试按钮：
  - 在测试场景里立即生成这张卡。
  - 快速验证效果。

交付结果：

- 不写代码也能创建大部分普通卡牌。
- 新卡牌可以快速测试。

## 12. Phase 9: Content Vertical Slice

目标：做一个小而完整的“试玩版”。

内容建议：

- 1 个村庄。
- 1 个野外区域。
- 1 个小地牢。
- 1 个 Boss。
- 5-8 个 NPC。
- 8-12 个任务。
- 30-50 张卡牌。
- 10-15 种敌人。
- 3 个可玩流派。

交付结果：

- 一个 30-60 分钟的可玩版本。
- 可以给别人试玩并收集反馈。

## 13. Phase 10: Polish and Production

目标：从原型进入正式产品质量。

要做：

- 美术：
  - 角色动画。
  - 敌人动画。
  - 地图 tile set。
  - 卡牌图标和边框。
  - UI 风格统一。
- 音频：
  - 移动、攻击、受伤、施法。
  - 环境音。
  - 战斗音乐和村庄音乐。
- UX：
  - 更清晰的卡牌描述。
  - 状态图标。
  - 伤害预览。
  - 键鼠和手柄支持。
- 存档：
  - 玩家位置。
  - 等级和属性。
  - 背包。
  - 卡组。
  - 任务进度。
- 设置：
  - 音量。
  - 分辨率。
  - 全屏。
  - 按键修改。
- 性能：
  - 敌人数量压力测试。
  - 卡牌效果压力测试。
  - 地图加载优化。

交付结果：

- 一个更接近正式发布的版本。

## 14. Suggested Technical Architecture

### Scenes

- `Main.tscn`: 游戏入口。
- `World.tscn`: 当前世界和地图管理。
- `Player.tscn`: 玩家。
- `Enemy.tscn`: 敌人基础场景。
- `CardHandUI.tscn`: 手牌 UI。
- `DeckBuilderUI.tscn`: 卡组编辑。
- `DialogueUI.tscn`: 对话框。
- `InventoryUI.tscn`: 背包。

### Scripts

- `PlayerController.gd`
- `HealthComponent.gd`
- `HitboxComponent.gd`
- `HurtboxComponent.gd`
- `EnemyAI.gd`
- `CardData.gd`
- `CardEffect.gd`
- `CardEffectExecutor.gd`
- `DeckManager.gd`
- `StatusEffect.gd`
- `QuestManager.gd`
- `SaveManager.gd`

### Resources

- `CardData`
- `EnemyData`
- `ItemData`
- `StatusData`
- `QuestData`

### Autoload Singletons

- `GameState`
- `SaveManager`
- `CardDatabase`
- `QuestManager`
- `AudioManager`

## 15. First Milestone Recommendation

最推荐先做 Milestone 1：

1. 建立项目目录。
2. 创建主场景。
3. 创建可移动玩家。
4. 创建测试地图。
5. 创建一个敌人。
6. 实现基础攻击和生命值。
7. 加入 3 张测试卡牌：
   - Slash
   - Guard
   - Firebolt

这个里程碑完成后，就能判断这个游戏的手感方向：它更适合偏动作 RPG、偏卡牌策略，还是两者混合。

## 16. Open Design Questions

后续需要逐步确认：

- 战斗是实时、回合制，还是实时加慢动作选卡？
- 卡牌是在战斗中随机抽，还是像技能栏一样装备后固定使用？
- 玩家是否有职业？
- 卡牌是否有稀有度？
- 卡牌自定义是开发者工具，还是玩家也能在游戏内编辑？
- 世界是线性关卡、半开放区域，还是 roguelike 地牢？
- 美术风格是像素、手绘、还是临时先用占位图？

## 17. Practical Next Step

下一步建议直接实现 Phase 0 和 Phase 1 的一部分：

- 创建目录结构。
- 创建 `Main.tscn`。
- 创建 `Player.tscn` 和移动脚本。
- 设置输入映射。
- 做一个测试地图。

等玩家可以在屏幕上顺滑移动以后，再接敌人、攻击和第一张卡。这样项目会很快从“空项目”变成“能摸到手感”的游戏。
