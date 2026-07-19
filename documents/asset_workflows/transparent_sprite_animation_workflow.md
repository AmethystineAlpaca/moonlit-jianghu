# Transparent Sprite Animation Workflow

## Goal

把透明底的角色图或动作表整理成连贯、可切分、可导入 Godot 的动画资源。

重点不是“让图片能显示”，而是让动作：

- 连贯
- 不抖
- 不错位
- 切出来后能直接接进游戏

## Two Input Types

常见输入分两类：

- 已经是规则网格的透明动作表
- 透明底但排布不规则，或者只是单帧集合

如果已经是规则网格，直接切。
如果排布不规则，先对齐到统一格子，再切。

## Recommended Workflow

1. 先确定动作方向和行定义
2. 检查每一行是不是同一种动作
3. 检查每一列是不是同一套时间顺序
4. 把每帧放进统一大小的格子
5. 尽量用同一个脚底基线对齐
6. 确认循环播放时不会跳
7. 再接进 Godot

## Direction Planning

在这个项目里，目前玩家跑动优先使用五方向：

1. 左下跑
2. 左跑
3. 左上跑
4. 上跑
5. 下跑

右边默认通过镜像左边得到，除非用户明确要求单独画右侧资源。

## Alignment Rules

做连贯动画时，最重要的是对齐规则。

推荐统一：

- 每帧画布尺寸相同
- 人物脚底尽量落在同一条水平线上
- 身体中心不要在每帧里左右乱飘
- 不要为了填满格子把人物强行拉伸

如果一张图里每帧 bounding box 不同，就应该先重排成统一格子，而不是直接拿每个不等大小的裁剪结果进游戏。

## Why Misalignment Happens

常见错位原因：

- 把不规则动作表硬切成平均网格
- 有的帧人物更高或更宽，但没有重新居中
- 头顶和脚底不是按同一基线摆放
- 原图动作顺序本来就不连续，却被当成连续跑动

## Godot Integration Strategy

目前这个项目里，玩家跑动动画不是用 `AnimatedSprite2D`，而是运行时从整张表里切出 `AtlasTexture` 帧，然后按方向切换。

相关代码：

- [scripts/player/PlayerController.gd](../../scripts/player/PlayerController.gd)

当前使用的对齐后透明动作表：

- [assets/xianxia/players_gemini_aligned_5dir_run.png](../../assets/xianxia/players_gemini_aligned_5dir_run.png)

## Current Sheet Layout

当前这张表是：

- 6 列
- 5 行
- 每格 `128 x 208`

行定义：

1. 左下跑
2. 左跑
3. 左上跑
4. 上跑
5. 下跑

## Visual QA Checklist

接进角色前，先肉眼检查：

1. 左跑时腿是否真的在动
2. 每一行动作是否是同一方向
3. 人物不会突然上跳或下沉
4. 头不会在某一帧被切掉
5. 衣摆和腿的摆动节奏是否连续
6. 镜像到右边后是否仍然自然

## Failure Patterns To Watch

- 看起来只有手在动，腿不动
- 某些帧只剩半身
- 头和身体像错层一样上下跳
- 左右镜像后武器或衣摆看起来反常
- 站立缩放和跑动缩放不一致

## Recommended Order In Practice

实际工作时，建议顺序如下：

1. 拿到原图
2. 先转成透明底
3. 如果动作已经正确，优先保留原动作，不重新生成
4. 重建成规则网格
5. 导入 Godot
6. 在游戏里实际跑一遍
7. 再决定要不要继续修动作或换资源

## Current Repo Scripts

- 纯色背景转透明：[scripts/tools/chroma_key_cutout.py](../../scripts/tools/chroma_key_cutout.py)
- 白底动作表提取并对齐：[scripts/tools/extract_gemini_run_sheet.py](../../scripts/tools/extract_gemini_run_sheet.py)
