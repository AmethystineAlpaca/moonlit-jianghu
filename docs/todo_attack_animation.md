# TODO: 攻击动画 - 方案 B（攻击帧图）

## 背景

当前攻击反馈（方案 A）是纯代码驱动：攻击瞬间角色身体向面对方向冲刺 + 轻微缩放，无需新美术。

方案 B 在此基础上加入真正的攻击帧，让角色腰身、手臂有挥击动作感。

---

## 待做事项

### 美术

- [ ] 在现有 sprite sheet 每个方向增加 2-3 帧"攻击序列"
  - 帧 0：蓄力（轻微后仰）
  - 帧 1：出击（身体前倾，手臂伸出）
  - 帧 2：收招（恢复姿势）
- 攻击帧与武器无关，所有武器共用同一套身体动画
- 建议 sheet 格式：在现有 idle/run 行之后新增 `attack_down`、`attack_up`、`attack_left` 行

### 代码（`PlayerController.gd`）

- [ ] 仿照 `_build_five_dir_run_frames` 新增 `_build_attack_frames()`
- [ ] `_update_xianxia_animation` 中，`attack_visual_timer > 0` 期间切换到攻击帧序列
- [ ] 攻击帧播放完后自然衔接 idle/run 帧，无需额外状态

---

## 注意事项

- 换武器只换 `sword_visual.texture`，不影响身体攻击帧
- 攻击帧时长跟随 `ATTACK_VISUAL_DURATION`（当前 0.18s），保持同步
