# 引き継ぎ書: Mac mini (Batou) 現地作業セッション 2026-07-14

あなたはMac mini(Batou/niihama、tailscale: his-mac-mini / 100.81.190.6)上で起動されたローカルエージェント(Claude CodeまたはCodex)。
オーナーのジョニー(渡鳥ジョニー)が現地(実家)に物理的に居る。この状況は今日限りなので、**現地でしか安全にできない作業を優先する**。
司令部はクラウドのClaudeセッション(iPhoneのClaudeアプリでジョニーが見ている)。あなたは現場の手として実行を担当する。

## 今日の文脈(要点)

- 今朝、母艦のs9(MacBook)が電源断→バッテリー枯渇で死亡。復旧済みだがロジックボード不安定。教訓:「ソフト起因で物理対応が必要になる状態を作らない」
- 方針決定済み: **このminiを新母艦としてgreenfieldで新築**(レガシーGITSの丸ごと移行はしない)。s9は現用のまま、サービス単位で徐々に移す
- Codexの旧移行プログラム(Architecture B)は**凍結中**。その凍結条件を尊重せよ:
  **個別承認なしの reboot / OSアップデート / production cutover / s9側の変更 は禁止。**
  ただし今日はジョニーが現地で承認者として同席しているため、mini側の下記作業は「都度ジョニーに口頭確認してから実行」でよい

## タスク(順番に)

### 1. 実査(読み取り専用) — まだ実行されていなければ
`mini-audit.sh`(このリポジトリ同梱)を実行するか、同等の調査を自分で行う:
ハード/OS/ディスク、FileVault状態、pmset(autorestart/sleep)、**Tailscaleの多重インストール実態**(GUI app / homebrew / usr-local のバイナリとLaunchDaemons)、非Appleのlaunchd項目(約2ヶ月前実装の自動復旧を含む)、cron、同期クライアント(Dropbox/Drive)、gitリポジトリ、claude/codex/node/brewの有無

### 2. Tailscale一本化(旧Codex監査の最重要指摘)
旧監査所見: 3系統共存、rootプロセスがUID501書換可能なHomebrewバイナリを実行の疑い(セキュリティ問題)。
- 方針: **GUI版(App Store/公式.app)1系統に統一**し、homebrew/standalone系のtailscaledとLaunchDaemonsを除去
- 手順は現状を見て自分で組み立てる。**必ず: 変更前に現状を記録 → ジョニーに口頭確認 → 実行 → `tailscale status`で復帰確認**。経路を切っても物理コンソールがあるので恐れなくてよいが、1ステップずつ
- 完了条件: tailscaledプロセスが1系統のみ、statusでオンライン、鍵期限を記録

### 3. ヘッドレス母艦の生命線設定
- `sudo pmset -a autorestart 1` (停電後自動再起動)
- `sudo systemsetup -setremotelogin on` (SSH。既にONなら確認のみ)
- 自動ログインの状態確認(システム設定)。FileVaultは**今日は変更しない**(greenfield設計で決める)。現状がOFFならOFFのまま記録
- 画面共有ON(バックアップ経路)

### 4. 帰宅前の三重チェック(ジョニーのiPhoneを4Gにして)
- Termius → 100.81.190.6 にSSH到達
- Tailscale status がオンライン
- (可能なら)画面共有到達
この3つが通るまでジョニーを帰らせないこと。

## 報告プロトコル

各タスク完了時に、結果サマリー(数値・OK/NG。個人的なファイルパスの列挙は避ける)を次の方法でpush:
```
git clone --depth 1 --branch s9-reports https://github.com/ikedhidenori/jp /tmp/rep
# /tmp/rep/triage/mini-<内容>-<日時>.md にサマリーを書く
cd /tmp/rep && git add triage && git commit -m "mini report <日時>" && git push origin s9-reports
```
push認証がない場合はジョニー経由(iPhoneのClaudeアプリにコピペ)で司令部へ。
全文ログは ~/Desktop/mini-work-20260714.md に残す。

## してはいけないこと

- s9への一切の変更(遠隔含む)
- OSアップデート、FileVault変更、reboot(Tailscale作業でどうしても必要な場合はジョニー承認後のみ)
- レガシーGITSデータの移行・同期(greenfield設計が終わるまで)
- ~/.claude や ~/.codex の履歴削除(Linear JON-75で保留中)
- 確認なしの破壊的操作全般。迷ったらジョニーに聞く(隣にいる)

## 参照

- 復旧作業の記録: https://github.com/ikedhidenori/jp/pull/4
- 計画: Linear JON-76(Mac mini母艦移行) / JON-75(Claude履歴の扱い)
- 旧Codex移行プログラム: gits-system#19 (Architecture B、凍結中)
