# トピック：絶滅職種図鑑（@zetsumetsuzukan）

> AI・職の自動化テーマの版管理ルート。公開先＝note **[@zetsumetsuzukan](https://note.com/zetsumetsuzukan)** / X 拡散。JON-53（絶滅職種グロース Epic）に供給、JON-65 で git/content-engine 管理へ移行。
> 方針は content-engine 共通（`../../README.md`）を踏襲：**骨子＝Markdown（内部・正本）／対外＝各チャネル形式**。

---

## このトピックの位置づけ

- **アカウント**：@zetsumetsuzukan（テーマ別 = AI/職の自動化・「{職業名}＋AI/消える」の SEO ロングテール入口）。本拠 @jon_megane への送客導線（`../../strategy.md §C/§D-2`）。
- **第一弾の論拠**：安野貴博 × ひろゆき対談（2026-04-28 YouTube）を主軸にした「図鑑型の論点整理」。
- **隣接トピック**：`../bosozoku/`（幕7 AI暴論・職の自動化パートを @zetsumetsuzukan へ別記事化＝相互送客）、`../seicho-vs-suitai/`（誇示と剥奪、@zetsumetsuzukan 公開候補）。

## ⚠️ 在庫の現状（JON-65 P1 調査結果、2026-06-04）

repo ルートに **絶滅職種図鑑の published HTML が 5 本**ある。これらは **同一記事「FIELD GUIDE 001」のデザイン反復（v0.2〜v0.6）**であり、別記事ではない。**正本（backbone.md）は未整備**だった（このトピック移行の主目的）。

| ファイル | 版 | 性質 | git 最終 |
|---|---|---|---|
| `../../../article-de068bc7eed0eeb0.html` | **v0.2** | REVISED・design-pipeline G3 PASS（score_avg 8.25）。**全 8 標本＋判定軸＋戸田エピソード＋図鑑フォーマット案を含む最も構造化された版** | 2026-05-18 |
| `../../../article-30baad9b90fca13c.html` | v0.3 | editorial+brutalist+標本 | 2026-05-19 |
| `../../../article-ceb7dc7c1da7269f.html` | v0.4 | 日本語 editorial＋図解6個＋scrollytelling | 2026-05-19 |
| `../../../article-1a6abe49cacb56d4.html` | v0.5 | typographer 修正・NewsPicks 風 typography | 2026-05-19 |
| `../../../article-f06bf85ad92e77f9.html` | **v0.6** | NewsPicks 風に振り切り（最新デザイン） | 2026-05-19 |

> **論点整理の正本（中身）は v0.2 が最も完備**。デザインの最新は v0.6。`backbone.md` は v0.2 の論点を正本化した（下記）。デザイン採用版の確定は別途（JON-53 側 or johnny 判断）。

## ディレクトリ構成（このトピック）

```
topics/zetsumetsuzukan/
├── README.md        ← これ（管理方針・命名規約・在庫）
├── backbone.md      ← ★正本（全主張・証拠・出典）。v0.2 記事から起こした
├── note-article.md  ← （未作成）長文 note 原稿
├── x-posts.md       ← （未作成）X 単発/スレッド
└── data/            ← （未作成）一次データ・出典原本
```

## 命名規約（bosozoku トピック踏襲）

- 正本：`backbone.md`（`../../templates/backbone-template.md` をコピーして埋める）
- チャネル原稿：`note-article.md` / `x-posts.md` / `starter-pack.md`（量産サンプル）
- 一次データ：`data/<slug>.<ext>` ＋ 算出ワークシートは `data/*-analysis.md`
- デッキ：ルートの `../../../design-system.css` を読む HTML で対外出力

## 運用フロー

1. `backbone.md` をパイプライン①〜⑥（`../../README.md`）で固める（正本＝量産可能）。
2. `../../templates/channel-adapters.md` のレシピで note/X/YouTube/縦尺/デッキへ変換。
3. money-map（`backbone.md §money-map`）で無料/有料を割り付け。
4. デッキ・published HTML は正本から再生成し、版差分を追跡可能にする（ルート直下の loose HTML を将来このトピック配下 or `publish/` に集約する案は JON-53/johnny 判断）。

## 関連 Linear / Epic

- **JON-65**：本トピックの git/content-engine 移行（本 scaffold）。
- **JON-53**：絶滅職種グロース Epic（供給先）。
- **JON-64**：bosozoku content-engine 流（本トピックのフォーマット元）。
