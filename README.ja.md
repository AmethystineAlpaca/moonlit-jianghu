# Stillwater · 雨歇

[English](README.md) | [中文](README.zh.md) | [日本語](README.ja.md) | [Русский](README.ru.md)

**Godot 4.6.2 製、Moonlit Jianghu の現在の 3D 武侠アクション。**

雨上がりの山門で三つの封印を解き、最後の剣士・無相に挑みます。

![現在の 3D タイトル](docs/showcase/v3/01-title.png)

[![3D 戦闘プレビュー](docs/showcase/v3/combat-preview.gif)](docs/showcase/v3/combat-readability.mp4)

[戦闘動画（MP4）](docs/showcase/v3/combat-readability.mp4)。実際のエンジン描画とスクリプト操作による映像です。人間のプレイテストや性能測定ではありません。

## 現在の 3D 版

- 骨格アニメーションと直剣・重刃・霊剣の三種類の武器。
- ダッシュで残像を残し、Q で帰路を斬る。残像とキャラクターを結ぶ線はありません。
- E で敵を壁や他の敵に押し当て、飛び道具を反射。タイミングよく防御し、体勢を崩した敵には F で追撃。
- 敵は剣を上げて構え、攻撃直前に刃が光ります。方向を読んで横に避けることができます。
- 短い停止動作、入力バッファ、被弾方向とダメージ表示。連続 BGM は停止し、戦闘効果音を使用。
- 三つの封印、二回の成長選択、二段階のボス、タイトル・ガイド・設定・結果画面。

## 3D の起動

リポジトリのルートで実行します。

```bash
godot --headless --editor --path . --import --quit
godot --path .
# 3D シーンを明示的に選択
godot --path . res://scenes/rebirth/Stillwater.tscn
```

エディターでは `project.godot` を開いて F5。ゲーム内 UI は中国語です。

操作：WASD / 矢印で移動、左クリック / J で攻撃、右クリック / K で防御、Shift / Space / L でダッシュ、Q で帰路斬り、E で押し出し、R で回復、F で封印・追撃、1–3 で武器変更、Esc で停止、F11 で全画面。

[開発・ビルド手順](docs/DEVELOPMENT.md) · [現在の仕様](docs/STILLWATER.md) · [素材ライセンス](docs/THIRD_PARTY_ASSETS.md)

2026-09-06：32/32 の回帰スクリプトが成功。macOS は Apple M4 で起動確認済み。Windows はクロスビルドのみで、実機確認は未完了です。実物のゲームパッド、長期プレイテスト、追加マップも今後の作業です。現在は一つのマップからなる章です。ローカルの `output/releases` は Git に含まれません。

---

## 以前の 2D 版 · 青岚一夜

スプライトの武侠村、昼夜の景色、三種類の武器、五つの術、インベントリ、成長と山君戦を保存しています。3D 版とは独立した旧版で、現在の帰路斬りや体勢システムは含みません。

![以前の 2D 版](docs/showcase/v2/01-title.png)

![以前の 2D ボス戦](docs/showcase/v2/10-mountain-guardian.png)

```bash
# 2D タイトルから開始
godot --path . res://scenes/interface/TitleScreen.tscn
# 2D ワールドへ直接入る
godot --path . res://scenes/main/Main.tscn
```

エディターでは対象シーンを開いて F6。F5 は現在の 3D 版を起動します。

2D 操作：WASD / 矢印で移動、J / 左クリックで攻撃、K で防御、Shift / L でダッシュ、1–5 で術、Space で選択中の術、M で所持品、Esc で停止。共有の音声処理により、旧版でも連続 BGM は再生されません。

[2D 実装記録](docs/POLISH.md) · [2D 美術記録](docs/ART_V2.md)

リポジトリ全体の再利用ライセンスは未指定です。KayKit の CC0、Noto の OFL など、第三者素材のライセンスは個別に適用されます。既定の Git ブランチは `master` です。
