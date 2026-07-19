# Non-Transparent To Transparent

## Goal

当我们只拿到一张非透明底的图片时，把它稳定地转成透明底 PNG，方便后续切图、做动画、导入 Godot。

这类输入通常有两种：

- 白底或接近白底的 contact sheet
- 纯色背景的 AI 生成图，例如绿底、粉底

## Preferred Rule

优先保留原图，不覆盖源文件。

建议同时保留两种文件：

- 原始输入图
- 透明底输出图

如果是纯色背景中转图，也可以保留一个 `*_green.png` 或类似名字，方便之后重新抠图。

## Case 1: Pure Color Background

如果背景是明显的纯色，例如绿色、粉色、蓝色，优先走 chroma-key 流程。

项目内脚本：

- [scripts/tools/chroma_key_cutout.py](../../scripts/tools/chroma_key_cutout.py)

示例命令：

```bash
python3 \
  scripts/tools/chroma_key_cutout.py cutout \
  --input assets/xianxia/players_gemini_5dir_run_green.png \
  --output assets/xianxia/players_gemini_5dir_run.png \
  --despill
```

透明验证：

```bash
python3 \
  scripts/tools/chroma_key_cutout.py validate-alpha \
  --input assets/xianxia/players_gemini_5dir_run.png \
  --require-transparent-corners
```

## Case 2: White Background Contact Sheet

如果输入不是纯色抠图图，而是一整张白底动作表，不要先用 AI 重画一遍。

### Core Rule

白底图现在默认不再用“看到白色就直接删掉”的方式处理。

正确规则是：

1. 从图像四条外边界开始
2. 只要像素是白色或接近白色，就继续向内扩散
3. 一旦碰到黑边或任何明确不是白色的像素，就停止
4. 只有和外部边界连通的白底会被删掉
5. 内部被轮廓包住的白色区域要保留

这样做的目的，是避免把角色内部的白衣服、白高光、浅色细节一起抠掉。

项目内通用脚本：

- [scripts/tools/chroma_key_cutout.py](../../scripts/tools/chroma_key_cutout.py)

如果只是想把整张白底图先稳定转成透明底，不重排、不切帧，先用这个命令：

```bash
python3 \
  scripts/tools/chroma_key_cutout.py outer-white-cutout \
  --input assets/xianxia/players_gemini_still.png \
  --output assets/xianxia/players_gemini_still_outer_white_cutout.png \
  --white-threshold 245 \
  --defringe
```

`--defringe` 是默认推荐加上的选项。BFS 只能删掉纯白像素，边缘抗锯齿像素（白底和角色颜色混合的半白色）靠 `--defringe` 做白底反推来消除。原理：`white_frac = min(R,G,B)/255`，反推真实 alpha 和颜色，只处理紧贴透明区的边缘像素，内部白色衣服/高光不受影响。默认做 2 层，可用 `--defringe-iterations N` 调整。

### Run Sheet Extraction

优先做法是：

1. 从原图中识别每个角色帧的边界
2. 用“外边界连通白底删除”去掉背景
3. 重新排到规则网格
4. 输出透明底动画表

项目内脚本：

- [scripts/tools/extract_gemini_run_sheet.py](../../scripts/tools/extract_gemini_run_sheet.py)

示例命令：

```bash
python3 \
  scripts/tools/extract_gemini_run_sheet.py \
  --input assets/xianxia/players_gemini.png \
  --output assets/xianxia/players_gemini_aligned_5dir_run.png
```

这个流程适合像 `players_gemini.png` 这样的白底动作图，因为它会尽量保留原始动作，而不是重新生成新动作。

### Still Sheet Extraction

如果是静止姿势表，而且只想取特定几行，不需要先手工裁图。

例如 `players_gemini_still.png` 这张图，当前规则是：

1. 第 1 行当作正向静止 `down`
2. 第 2 行当作背向静止 `up`
3. 第 3 行当作左向静止 `left`
4. 第 4、5 行忽略
5. 右向静止直接镜像左向静止

项目内脚本：

- [scripts/tools/extract_gemini_still_sheet.py](../../scripts/tools/extract_gemini_still_sheet.py)

示例命令：

```bash
python3 \
  scripts/tools/extract_gemini_still_sheet.py \
  --input assets/xianxia/players_gemini_still.png \
  --output-dir assets/xianxia
```

这个命令会输出：

- `assets/xianxia/players_gemini_idle_down.png`
- `assets/xianxia/players_gemini_idle_up.png`
- `assets/xianxia/players_gemini_idle_left.png`

### Run Sheet Extraction（白边说明）

`extract_gemini_run_sheet.py` 内部流程依次是：

1. `cleanup_white_fringe` — 把亮边像素替换成周围深色邻居的平均色
2. `drop_bright_edge_pixels` — 把 RGB 全高于 fringe-threshold 且紧贴透明区的像素直接去掉
3. `defringe_white_edges` — 白底反推，处理前两步遗漏的半白像素（默认 2 层）

三步叠加之后白边像素可以降到 0。如果效果仍不理想，可以调 `--fringe-threshold`（默认 210）或 `--bright-edge-contract`（默认 2）。

## Validation Checklist

每次转透明底之后，至少检查下面几件事：

1. 四个角是否透明
2. 人物主体是否还完整
3. 边缘是否有明显色边
4. 没有出现整张图几乎全透明或几乎全不透明
5. 白底删除是否只发生在外边界连通区域
6. 角色内部的白色衣服或浅色细节没有被一起删掉

如果是动作表，还要额外检查：

1. 每一帧人物没有被裁掉头脚
2. 每一帧的脚底位置是否稳定
3. 左右或上下动作没有被误分到别的行

## Common Mistakes

- 不要把原图直接覆盖掉
- 不要在原图已经有正确动作时，又重新让 AI 生成一版动作
- 不要对不规则排布的白底动作图直接做“硬等分切片”
- 不要再用“只要是白色就全图删除”的办法处理白底角色图
- 不要只看单帧是否透明，还要看整套动作是否会抖动、错位、缺腿

## Recommended Output Naming

- 纯色背景中转图：`*_green.png`
- 抠完后的透明图：`*.png`
- 白底整图先抠出的透明版本：`*_outer_white_cutout.png`
- 从 contact sheet 对齐重建后的透明动画表：`*_aligned_*.png`
- 从静止表提取出的单帧 idle：`*_idle_down.png`、`*_idle_up.png`、`*_idle_left.png`

## Current Repo Examples

- 原始白底动作图：`assets/xianxia/players_gemini.png`
- 原始白底静止图：`assets/xianxia/players_gemini_still.png`
- AI 生成中转图：`assets/xianxia/players_gemini_5dir_run_green.png`
- 白底整图先抠出的透明版本：`assets/xianxia/players_gemini_still_outer_white_cutout.png`
- 从原图对齐重建后的透明动画表：[assets/xianxia/players_gemini_aligned_5dir_run.png](../../assets/xianxia/players_gemini_aligned_5dir_run.png)
- 从静止表提取出的 idle 图：[assets/xianxia/players_gemini_idle_down.png](../../assets/xianxia/players_gemini_idle_down.png)、[assets/xianxia/players_gemini_idle_up.png](../../assets/xianxia/players_gemini_idle_up.png)、[assets/xianxia/players_gemini_idle_left.png](../../assets/xianxia/players_gemini_idle_left.png)
