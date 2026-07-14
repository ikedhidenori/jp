#!/bin/bash
# s9-triage.sh — section9 (s9) ストレージ逼迫・安定性の診断スクリプト
#
# 使い方（ゴーストのMacから1行）:
#   curl -fsSL https://raw.githubusercontent.com/ikedhidenori/jp/claude/s9-stability-storage-oxpleg/s9-triage.sh | ssh hi@section9.local 'bash -s'
#
# 方針: 削除・変更は一切しない（読み取りのみ）。唯一の例外は
# Tailscale が起動していない場合に起動を試みることだけ。
# 結果は画面に流しつつ ~/Desktop/s9-triage-<日時>.log にも保存する。

set -u
LOG="$HOME/Desktop/s9-triage-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee "$LOG") 2>&1

section() { printf '\n===== %s =====\n' "$1"; }

echo "s9 triage $(date '+%Y-%m-%d %H:%M:%S')  (log: $LOG)"

section "システム / 稼働時間"
sw_vers
uptime

section "電源"
pmset -g batt
pmset -g custom 2>/dev/null | sed -n '1,20p'

section "ディスク全体"
df -h / /System/Volumes/Data 2>/dev/null

section "CPU上位プロセス"
ps aux | head -1; ps aux | sort -nrk3 | head -10

section "Tailscale"
if pgrep -qif tailscale; then
  echo "Tailscale: 起動中"
else
  echo "Tailscale: 停止中 -> 起動を試みます"
  open -a Tailscale 2>/dev/null && sleep 8
fi
TS="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
[ -x "$TS" ] && "$TS" status 2>&1 | head -10 || echo "(Tailscale CLIが見つからない)"

section "Spotlightインデックス状態"
mdutil -s / 2>/dev/null
mdutil -s /System/Volumes/Data 2>/dev/null

section "APFSローカルスナップショット"
tmutil listlocalsnapshots / 2>/dev/null || echo "(なし)"

echo
echo ">>> ここからディスク使用量の集計。数分かかることがあります。そのまま待ってください <<<"

section "ホーム直下の内訳 (~)"
du -xh -d1 "$HOME" 2>/dev/null | sort -h | tail -20

section "~/Library の内訳"
du -xh -d1 "$HOME/Library" 2>/dev/null | sort -h | tail -20

section "定番の容疑者たち"
du -sh \
  "$HOME/Library/Caches" \
  "$HOME/Library/Logs" \
  "$HOME/Library/Containers" \
  "$HOME/Library/CloudStorage" \
  "$HOME/Library/Application Support" \
  "$HOME/Library/Group Containers" \
  "$HOME/.claude" \
  "$HOME/.codex" \
  "$HOME/.npm" \
  "$HOME/.cache" \
  "$HOME/Downloads" \
  2>/dev/null | sort -h

section "~/Library/Application Support の内訳"
du -xh -d1 "$HOME/Library/Application Support" 2>/dev/null | sort -h | tail -15

section "2GB超の巨大ファイル (ホーム配下)"
find "$HOME" -xdev -type f -size +2G -print0 2>/dev/null | xargs -0 ls -lh 2>/dev/null | awk '{print $5, $9, $10, $11}'

section "直近24時間で更新された1GB超ファイル (書き続けている犯人の候補)"
find "$HOME" -xdev -type f -size +1G -mtime -1 -print0 2>/dev/null | xargs -0 ls -lh 2>/dev/null | awk '{print $5, $9, $10, $11}'

section "まとめ"
df -h /System/Volumes/Data 2>/dev/null | tail -1 | awk '{print "空き容量: " $4 " / " $2}'
echo "ログ保存先: $LOG"
echo "完了。この出力の『ホーム直下の内訳』以降を貼ってください。"
