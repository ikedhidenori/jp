---
name: retro
description: セッション終了時の振り返り＆引き継ぎを生成する。ユーザーが「引き継いで」「おつかれ」「retro」「振り返って」等で終了を示したとき、または明示的に /retro が呼ばれたときに使う。母艦(~/.claude)の司令塔handoff流儀に準拠して、完遂成果・残タスク・重要callout・再開プロンプトを生成し、Linear起票＋チャット貼りまで行う。
---

# /retro — セッション振り返り & 引き継ぎ（司令塔handoff流儀準拠）

ジョニー定義：**「引き継いで」＝①プランを書く ②Linear起票 ③現在地＋再開プロンプトをチャットに貼る** まで。
発火語：「引き継いで」「お疲れ」「おつかれ」「retro」「振り返って」。

> 注：母艦の handoff スキル本体（`~/.claude/handoff/...`、起点レポート、session-save）はこのcontent repoからは見えない。
> 本スキルは Linear JON-62/86 等から抽出した**司令塔handoff流儀**を踏襲する。差異があれば母艦側を正とする。

## 出力フォーマット（Linear description ＝ チャット貼りも同形）

```
**引き継ぎ元**: <セッション/トピック名・日付>
**機密度**: D1(公開コンテンツ) / D2(構成情報・PII無) など
**repo/branch/PR**: ikedhidenori/jp / <branch> / PR #<n>

## 完遂成果
* <done を箇条書き>

## 残タスク（優先度順）
* P1 ★最優先: <task> — <所要時間>
* P2: <task> — <所要>
* …

## 重要 callout
* ⚠ <注意・期限・リスク>
* ✅ <稼働中・確定事項>

## 再開プロンプト（次セッションにそのまま貼る）
> 「<1段落。repo/branch/PR/Linear番号＋次に着手する1タスク>」
```

## 手順
1. 上記フォーマットで振り返り生成（簡潔に）。
2. `content-engine/sessions/YYYY-MM-DD-<topic>.md` に保存（母艦 `~/.claude/handoff/pending/` のrepo内等価物）。
3. Linear `save_issue`：team=`Jon_megane`、label=`handoff`、関連Epicに `relatedTo`、PRを `links`。既存handoff issueがあれば `id` 指定で更新。
4. **現在地＋再開プロンプトをチャットに素テキストで貼る**（ジョニーはRC/モバイル率高 → mdリンク依存禁止）。

## 安全弁（継承）
- 公開・外部送信は係争中の推定無罪・国籍で括らない・noteを先に。
- destructive opは母艦のkill-switch/CMF規律に従う（このrepo内作業は対象外だが意識）。
