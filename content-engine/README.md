# 骨子エンジン (Content Engine)

着想を「立論された強固な骨子」に固め、そこから**目的別（X / note / YouTube / Story / TikTok / デッキ）にコンテンツを量産**するための再利用フレームワーク。

> 方針はリポジトリ共通の `feedback_md_internal_html_external` を踏襲。
> **骨子＝Markdown（内部・正本）／対外＝各チャネル形式（HTMLデッキ・テキスト等）**。

---

## なぜ骨子を分けるのか

バズも長文も動画も、**強度の源泉は同じ一本の立論**。チャネルごとにゼロから書くと主張がブレる。
だから「**主張・証拠・出典・殺し文句**」を**1つの正本（backbone.md）に固定**し、各チャネルは**その変換（アレンジ）**として生成する。

```
着想 → 探索リサーチ → 仮説 → 検証(統計/学術) → 立論 → ★骨子固定★ → 目的別に量産
                                                    └─ backbone.md (正本)
                                                          ├─ X（単発/スレッド）
                                                          ├─ note（長文）
                                                          ├─ YouTube（台本）
                                                          ├─ Story / TikTok / Reels（縦尺台本）
                                                          └─ deck（HTML・design-system.css）
```

---

## パイプライン（毎回これを回す）

| 段階 | やること | 完了の目安 |
|---|---|---|
| ①着想 | 素朴な違和感・体感を1行で | 「〜な気がする。本当？」 |
| ②探索 | fan-out検索で地形把握（広く浅く） | 主要論点と一次データ源を列挙 |
| ③仮説 | 反証可能な仮説を複数立てる | 「もし真なら〜が観測されるはず」 |
| ④検証 | 統計・学術・一次資料で各仮説を採点 | 各仮説に★立証度（高/中/低）と出典 |
| ⑤立論 | 仮説群を1本の主張へ統合 | logline（1行）＋幕構成 |
| ⑥**骨子固定** | `backbone.md` に正本化 | 下記スキーマが全部埋まる |
| ⑦量産 | チャネル・アダプタで変換 | 各チャネルの制約に適合した原稿 |

**品質バー（全チャネル共通）**
- 主張は必ず**数字か学術知見**に紐づける（ハッタリの一行も背後に芯を持たせる）
- **⚠️限界・反証**を必ず併記（炎上耐性＝知的誠実さ）
- **Hook first**：最初の1行/3秒で勝負（チャネル別に最適化）
- 出典はリンクで保持（`backbone.md` のSourcesが全チャネルの根拠）

---

## ディレクトリ構成

```
content-engine/
├── README.md                    ← これ（運用ルール）
├── templates/
│   ├── backbone-template.md     ← 新トピックはこれをコピーして埋める
│   └── channel-adapters.md      ← X/note/YouTube/縦尺/デッキの変換レシピ
└── topics/
    └── bosozoku/
        ├── backbone.md          ← ★正本（このトピックの全主張・証拠・出典）
        └── starter-pack.md      ← 正本から量産したサンプル（全チャネル分）
```

## 新しいトピックの始め方

1. `cp templates/backbone-template.md topics/<topic>/backbone.md`
2. パイプライン①〜⑥を回して埋める（リサーチは都度ファンアウト検索）
3. `channel-adapters.md` のレシピで目的別に量産 → `topics/<topic>/` に保存
4. デッキ化するなら `../design-system.css` を読み込んだHTMLで対外出力

## 公開先（アカウント）
- **本拠地**：note 個人アカ **[@jon_megane](https://note.com/jon_megane)** ← 論考・オピニオンはここ（事業ブランドINNFRA等とは切り離す）
- **テーマ別**：note **[@zetsumetsuzukan（絶滅職種）](https://note.com/zetsumetsuzukan)** ← AI/職の自動化・中流没落・「誇示と剥奪」系の派生はこちらが好相性
- **拡散**：X（スレッド→noteへ誘導）。短尺はニュアンスが落ちるため、必ずnoteを先に公開してから。

## 既存トピック
- [`topics/bosozoku/backbone.md`](topics/bosozoku/backbone.md) — **固定済**。暴走族は減ったのに、なぜ"また増えた"気がするのか／逸脱のアンバンドル・中流没落・世界潮流への収斂・AI暴論。時事フック（福生事件ほか）付き。→ 公開：**@jon_megane**（`note-article.md` / `x-posts.md`）
- [`topics/seicho-vs-suitai/backbone.md`](topics/seicho-vs-suitai/backbone.md) — **探索中（起案）**。誇示と剥奪／成長駆動 vs 衰退駆動の逸脱（バブル日本・中国炫富 ≒ 誇示型／令和日本の闇バイト ≒ 剥奪型）。bosozokuの切り分けメモから派生。→ 公開候補：**@zetsumetsuzukan**
