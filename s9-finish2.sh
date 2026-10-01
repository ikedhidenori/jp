#!/bin/bash
# s9-finish2.sh — s9復旧 仕上げ第2弾（v1の失敗箇所への対策版）
#
# 使い方: Termius等でs9に入って
#   curl -fsSL https://raw.githubusercontent.com/ikedhidenori/jp/claude/s9-stability-storage-oxpleg/s9-finish2.sh | bash
#
# v1からの変更点:
#   1. Codex停止を強化: launchdサービスのbootout + pkill -9 リトライ。
#      それでも残る場合はファイル削除を強行（Codexは再作成する）
#   2. Tailscale: upのエラー全文をローカルに記録。認証URLはターミナル表示のみで
#      GitHubには絶対にpushしない（サマリーからはURL行を除外）
#   3. ~/.claude/projects の30日以上前の履歴サイズを計測（削除はしない。
#      削除はユーザー承認後に別途実施する）

set -u
STAMP=$(date +%Y%m%d-%H%M%S)
REPORT="$HOME/Desktop/s9-finish2-$STAMP.txt"
TS_BIN="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
exec > >(tee "$REPORT") 2>&1

section() { printf '\n===== %s =====\n' "$1"; }
echo "s9 finish2 $(date '+%Y-%m-%d %H:%M:%S')  (完全版ログ: $REPORT)"

DF_START=$(df -h /System/Volumes/Data | tail -1)
section "0. 開始時の空き"
echo "$DF_START"

section "1. Codex/ChatGPT 強制停止と掃除"
osascript -e 'quit app "ChatGPT"' >/dev/null 2>&1 || true
sleep 5
# launchd管理のOpenAI/Codex系サービスを止める（自動再起動を防ぐ）
launchctl list 2>/dev/null | awk '{print $3}' | grep -iE 'openai|codex|chatgpt' | while read -r label; do
  echo "launchctl bootout: $label"
  launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
done
for i in 1 2 3 4 5; do
  pgrep -f codex >/dev/null 2>&1 || break
  pkill -9 -f codex 2>/dev/null || true
  sleep 3
done
if pgrep -f codex >/dev/null 2>&1; then
  CODEX_PROC="残存(削除は強行)"
  pgrep -fl codex | head -5
else
  CODEX_PROC="全停止"
fi
BEFORE=$(du -sh "$HOME/.codex" 2>/dev/null | awk '{print $1}')
rm -f  "$HOME/.codex/logs_2.sqlite" "$HOME/.codex/logs_2.sqlite-wal" "$HOME/.codex/logs_2.sqlite-shm" 2>/dev/null
rm -rf "$HOME/.codex/sqlite" "$HOME/.codex/archived_sessions" "$HOME/.codex/.tmp" 2>/dev/null
AFTER=$(du -sh "$HOME/.codex" 2>/dev/null | awk '{print $1}')
CODEX_RESULT="proc=$CODEX_PROC size: $BEFORE -> $AFTER"
echo "$CODEX_RESULT"

section "2. Tailscale 復旧試行（詳細ログ付き）"
TS_LINE="CLIなし"; TS_ERR=""
if [ -x "$TS_BIN" ]; then
  open -a Tailscale 2>/dev/null || true
  sleep 5
  echo "--- tailscale up の出力（認証URLが出たらブラウザで開いて承認）---"
  "$TS_BIN" up --timeout 45s --accept-routes 2>&1 | tee /tmp/s9-ts-up.txt || true
  echo "--- ここまで ---"
  sleep 3
  TS_LINE=$("$TS_BIN" status 2>&1 | head -1)
  # サマリー用: URLを含む行は除外して1行だけ
  TS_ERR=$(grep -v 'https://' /tmp/s9-ts-up.txt | grep -v '^\s*$' | head -2 | tr '\n' ' / ')
  echo "status: $TS_LINE"
fi

section "3. ~/.claude/projects 30日超の履歴サイズ調査（削除はしない・承認待ち）"
echo "全体: $(du -sh "$HOME/.claude/projects" 2>/dev/null | awk '{print $1}')"
OLD_KB=$(find "$HOME/.claude/projects" -type f -mtime +30 -print0 2>/dev/null | xargs -0 du -k 2>/dev/null | awk '{s+=$1} END {printf "%.1f", s/1024/1024}')
CLAUDE_AFTER="30日超ぶん=${OLD_KB:-0}GB (未削除)"
echo "$CLAUDE_AFTER"

DF_END=$(df -h /System/Volumes/Data | tail -1)
section "4. 終了時の空き"
echo "$DF_END"

section "5. サマリーをGitHubへpush"
JP=""
for g in $(find "$HOME" -maxdepth 3 -type d -name .git -not -path "$HOME/Library/*" 2>/dev/null); do
  url=$(git -C "${g%/.git}" config --get remote.origin.url 2>/dev/null || true)
  case "$url" in
    *ikedhidenori/jp*) JP="${g%/.git}"; break ;;
  esac
done
if [ -n "$JP" ]; then
  WT=$(mktemp -d /tmp/s9wt.XXXXXX); rmdir "$WT"
  git -C "$JP" fetch origin s9-reports 2>/dev/null || true
  if git -C "$JP" worktree add "$WT" -B s9-reports origin/s9-reports 2>/dev/null; then
    mkdir -p "$WT/triage"
    {
      echo "# s9 finish2 summary $STAMP"
      echo '```'
      echo "df_start: $DF_START"
      echo "df_end:   $DF_END"
      echo "codex_cleanup: $CODEX_RESULT"
      echo "tailscale_status: $TS_LINE"
      echo "tailscale_up_msg(URL除外): $TS_ERR"
      echo "claude_projects_after: $CLAUDE_AFTER"
      echo '```'
    } > "$WT/triage/s9-summary2-$STAMP.md"
    git -C "$WT" add triage \
      && git -C "$WT" commit -m "s9 finish2 summary $STAMP" \
      && git -C "$WT" push origin s9-reports \
      && echo "OK: サマリーpush済み" \
      || echo "NG: push失敗。完全版ログ $REPORT を貼ってください"
    git -C "$JP" worktree remove --force "$WT" 2>/dev/null || true
    git -C "$JP" branch -D s9-reports 2>/dev/null || true
  fi
else
  echo "NG: jpリポジトリ未発見。完全版ログ $REPORT を貼ってください"
fi

echo
echo "完了。完全版ログ: $REPORT"
