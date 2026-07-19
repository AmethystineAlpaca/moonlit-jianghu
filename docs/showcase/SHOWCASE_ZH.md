# gaame

一个未完成的 Godot 4 俯视角动作 RPG 原型，方向是复古像素 + 修仙氛围。

这不是一个完成品。它更像是一次实验的存档：移动、近战、敌人、一个小村庄地图、夜晚氛围、简单背包 UI，以及一批 AI 辅助像素素材的尝试。

![世界概览](images/01-world-overview.png)

## 下载构建

导出的文件会放在 `out/`：

- `out/gaame-macos.zip`
- `out/gaame-windows.exe`

构建产物不会提交到 git。更适合把它们放到 GitHub Release，或者上传到 itch.io 这样的游戏页面。

macOS 包没有签名，第一次打开可能需要右键选择 Open。Windows exe 也没有签名，Windows Defender 可能会提示风险。

## 这个原型里有什么

- 俯视角移动、冲刺、近战攻击、防御、体力和战斗反馈。
- 敌人遭遇，包括骷髅风格敌人、快速敌人、僵尸，以及火狮变体。
- 一个小型村庄地图，有房屋、树、可破坏物、地标和边界墙。
- 夜晚氛围，包括夜色地面、光源、类似萤火的粒子和环境效果。
- 一个轻量背包界面，包含装备位和背包格。

![火狮遭遇](images/02-fire-lion-encounter.png)

## 操作

- 移动：`WASD` 或方向键
- 攻击：`J` 或鼠标左键
- 防御：`K`
- 冲刺：`L`
- 使用当前技能：`Space`
- 选择技能：`1`-`5`
- 背包：`M`
- 切换夜晚氛围：`P`
- 重置场景：`R`

![背包界面](images/03-inventory-overlay.png)

## 当前状态

这是一个收尾点，不是正式发布版。有些测试还停留在旧场景结构的预期上，一些视觉系统仍然是实验性的，素材目录里也保留了 active 和 unused 的探索文件。

比较诚实的看法是：这是一个被保存下来的原型。它记录了游戏方向、视觉尝试，以及已经能被分享出来的战斗手感。

![夜晚村庄](images/04-night-village.png)

## 本地运行和导出

项目使用 Godot `4.6.2`。

```bash
godot --path .
```

导出 macOS：

```bash
mkdir -p out
godot --headless --path . --export-release "macOS" out/gaame-macos.zip
```

导出 Windows：

```bash
mkdir -p out
godot --headless --path . --export-release "Windows Desktop" out/gaame-windows.exe
```
