#!/bin/bash
# s9-finish.sh — s9復旧の仕上げ一括スクリプト
#
# 使い方（ゴーストのMacから1行）:
#   curl -fsSL https://raw.githubusercontent.com/ikedhidenori/jp/claude/s9-stability-storage-oxpleg/s9-finish.sh | ssh hi@section9.local 'bash -s'
#
# やること:
#   1. ChatGPT/Codexを停止して ~/.codex の肥大ログ・残骸を掃除（承認済み項目のみ）
#   2. Tailscale接続の復旧を試行（認証URLが必要なら表示する）
#   3. ~/.claude の内訳と、ホーム配下gitリポジトリの未コミット/未push棚卸し（読み取りのみ）
#   4. 結果の完全版を ~/Desktop に保存し、機微情報を除いたサマリーだけを
#      jpリポジトリの s9-reports ブランチへ自動push（リモートのClaudeが検知して分析する）
#
# 削除対象は ~/.codex のログDB・旧DB・アーカイブ・一時ファイルのみ。他は一切消さない。

set -u
STAMP=$(date +%Y%m%d-%H%M%S)
REPORT="$HOME/Desktop/s9-finish-$STAMP.txt"
TS_BIN="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
exec > >(tee "$REPORT") 2>&1

section() { printf '\n===== %s =====\n' "$1"; }
echo "s9 finish $(date '+%Y-%m-%d %H:%M:%S')  (完全版ログ: $REPORT)"

DF_START=$(df -h /System/Volumes/Data | tail -1)
section "0. 開始時の空き"
echo "$DF_START"

section "1. ChatGPT/Codex 停止と ~/.codex 掃除"
CODEX_RESULT="unknown"
osascript -e 'quit app "ChatGPT"' >/dev/null 2>&1 || true
sleep 10
if pgrep -f codex >/dev/null 2>&1; then
  echo "quitで残ったため pkill します"
  pkill -f codex 2>/dev/null || true
  sleep 5
fi
if pgrep -f codex >/dev/null 2>&1; then
  CODEX_RESULT="NG: プロセス残存のためスキップ"
  echo "$CODEX_RESULT"; pgrep -fl codex | head -5
else
  echo "掃除前: $(du -sh "$HOME/.codex" 2>/dev/null | awk '{print $1}')"
  rm -f  "$HOME/.codex/logs_2.sqlite" "$HOME/.codex/logs_2.sqlite-wal" "$HOME/.codex/logs_2.sqlite-shm" 2>/dev/null
  rm -rf "$HOME/.codex/sqlite" "$HOME/.codex/archived_sessions" "$HOME/.codex/.tmp" 2>/dev/null
  CODEX_RESULT="OK: 掃除後 $(du -sh "$HOME/.codex" 2>/dev/null | awk '{print $1}')"
  echo "$CODEX_RESULT"
fi

section "2. Tailscale 復旧試行"
TS_LINE="CLIなし"
if [ -x "$TS_BIN" ]; then
  open -a Tailscale 2>/dev/null || true
  sleep 5
  "$TS_BIN" up --timeout 30s 2>&1 || true
  sleep 3
  TS_LINE=$("$TS_BIN" status 2>&1 | head -1)
  "$TS_BIN" status 2>&1 | head -8
  echo "(https://login.tailscale.com のURLが上に出ていたら、ゴーストのブラウザで開いて承認してください)"
fi

section "3. ~/.claude の内訳"
du -sh "$HOME/.claude" 2>/dev/null
du -sh "$HOME"/.claude/* 2>/dev/null | sort -h | tail -10

section "4. gitリポジトリ棚卸し (読み取りのみ・このセクションは完全版ログにのみ残る)"
REPO_TOTAL=0; REPO_DIRTY=0; REPO_AHEAD=0
find "$HOME" -maxdepth 3 -type d -name .git \
     -not -path "$HOME/Library/*" -not -path "$HOME/.Trash/*" 2>/dev/null |
while read -r g; do
  repo="${g%/.git}"
  dirty=$(git -C "$repo" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  branch=$(git -C "$repo" rev-parse --abbrev-ref HEAD 2>/dev/null)
  ahead=$( (git -C "$repo" rev-list --count '@{u}..HEAD' 2>/dev/null) || echo "?")
  echo "${repo/#$HOME/~} [branch=$branch dirty=$dirty ahead=$ahead]"
done | tee /tmp/s9-repo-inventory.txt
REPO_TOTAL=$(wc -l < /tmp/s9-repo-inventory.txt | tr -d ' ')
REPO_DIRTY=$(grep -c 'dirty=[1-9]' /tmp/s9-repo-inventory.txt || true)
REPO_AHEAD=$(grep -Ec 'ahead=[1-9?]' /tmp/s9-repo-inventory.txt || true)
echo "-> リポジトリ $REPO_TOTAL 個 / 未コミットあり $REPO_DIRTY 個 / 未pushあり(不明含む) $REPO_AHEAD 個"

DF_END=$(df -h /System/Volumes/Data | tail -1)
section "5. 終了時の空き"
echo "$DF_END"

section "6. サマリーをGitHubへpush"
JP=""
for g in $(find "$HOME" -maxdepth 3 -type d -name .git -not -path "$HOME/Library/*" 2>/dev/null); do
  url=$(git -C "${g%/.git}" config --get remote.origin.url 2>/dev/null || true)
  case "$url" in
    *ikedhidenori/jp*) JP="${g%/.git}"; break ;;
  esac
done
if [ -n "$JP" ]; then
  echo "jpリポジトリ: $JP"
  WT=$(mktemp -d /tmp/s9wt.XXXXXX); rmdir "$WT"
  git -C "$JP" fetch origin main s9-reports 2>/dev/null || git -C "$JP" fetch origin main
  if git -C "$JP" worktree add "$WT" -B s9-reports origin/s9-reports 2>/dev/null \
     || git -C "$JP" worktree add "$WT" -B s9-reports origin/main; then
    mkdir -p "$WT/triage"
    {
      echo "# s9 finish summary $STAMP"
      echo '```'
      echo "df_start: $DF_START"
      echo "df_end:   $DF_END"
      echo "codex_cleanup: $CODEX_RESULT"
      echo "tailscale: $TS_LINE"
      echo "claude_total: $(du -sh "$HOME/.claude" 2>/dev/null | awk '{print $1}')"
      echo "claude_breakdown_top:"
      du -sh "$HOME"/.claude/* 2>/dev/null | sort -h | tail -8 | sed "s|$HOME|~|"
      echo "repos: total=$REPO_TOTAL dirty=$REPO_DIRTY ahead_or_unknown=$REPO_AHEAD (詳細は完全版ログのみ)"
      echo '```'
    } > "$WT/triage/s9-summary-$STAMP.md"
    git -C "$WT" add triage \
      && git -C "$WT" commit -m "s9 finish summary $STAMP" \
      && git -C "$WT" push -u origin s9-reports \
      && echo "OK: サマリーpush済み (branch: s9-reports)" \
      || echo "NG: pushに失敗。完全版ログ $REPORT を手動で貼ってください"
    git -C "$JP" worktree remove --force "$WT" 2>/dev/null || true
    git -C "$JP" branch -D s9-reports 2>/dev/null || true
  else
    echo "NG: worktree作成に失敗。完全版ログ $REPORT を手動で貼ってください"
  fi
else
  echo "NG: jpリポジトリが見つからず。完全版ログ $REPORT を手動で貼ってください"
fi

echo
echo "完了。完全版ログ: $REPORT"
