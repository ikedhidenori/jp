#!/bin/bash
# mini-audit2.sh — Mac mini (Batou) 実査 v2
#
# 性質の正確な記述(v1の「読み取り専用」表記は不正確だったため訂正):
#   - システム状態(設定・サービス・ファイル)は一切変更しない
#   - 書き込みは ~/Desktop のレポート1ファイルのみ
#   - ネットワーク送信なし(git clone/push機能はv1から完全削除)
#   - $HOME全体のdu/find走査はしない。走査対象は下記に明示列挙したパスのみ
#   - sudoが必要な項目はスキップして「要sudo」と記録
#
# レポートの司令部への受け渡しは、ジョニーが内容を確認してから
# iPhoneのClaudeアプリへ手動で貼る(人間によるpreflightを兼ねる)。

set -u
STAMP=$(date +%Y%m%d-%H%M%S)
REPORT="$HOME/Desktop/mini-audit-$STAMP.md"
exec > >(tee "$REPORT") 2>&1

section() { printf '\n===== %s =====\n' "$1"; }
echo "# mini (Batou) audit v2 $STAMP"
echo "(変更なし・送信なし。このレポートは $REPORT のみに保存)"

section "0. ハードウェア / OS"
system_profiler SPHardwareDataType 2>/dev/null | grep -E 'Model|Chip|Memory' || true
sw_vers
uptime

section "1. ディスク"
df -h / /System/Volumes/Data 2>/dev/null

section "2. セキュリティ / 電源"
fdesetup status 2>/dev/null || echo "fdesetup: 要sudoまたは取得不可"
pmset -g 2>/dev/null | grep -E 'autorestart|sleep|standby|womp' || true

section "3. Tailscale 多重インストールの実態"
echo "--- バイナリ ---"
for p in "/Applications/Tailscale.app/Contents/MacOS/Tailscale" \
         /opt/homebrew/bin/tailscale /opt/homebrew/bin/tailscaled \
         /usr/local/bin/tailscale /usr/local/bin/tailscaled; do
  [ -e "$p" ] && ls -la "$p"
done
echo "--- 動作中プロセス ---"
ps aux | grep -i '[t]ailscale' || echo "(なし)"
echo "--- LaunchDaemons/LaunchAgents (tailscale関連) ---"
ls /Library/LaunchDaemons 2>/dev/null | grep -i tailscale || true
ls "$HOME/Library/LaunchAgents" 2>/dev/null | grep -i tailscale || true
echo "--- 各バイナリのstatus(先頭3行) ---"
for ts in "/Applications/Tailscale.app/Contents/MacOS/Tailscale" /opt/homebrew/bin/tailscale /usr/local/bin/tailscale; do
  [ -x "$ts" ] && { echo "[$ts]"; "$ts" status 2>&1 | head -3; }
done

section "4. launchd 非Apple項目"
echo "--- ~/Library/LaunchAgents ---"
ls -la "$HOME/Library/LaunchAgents" 2>/dev/null || echo "(なし)"
echo "--- /Library/LaunchDaemons /Library/LaunchAgents (非Apple) ---"
ls /Library/LaunchDaemons /Library/LaunchAgents 2>/dev/null | grep -v '^com.apple' || true
echo "--- loaded (非Apple, 先頭40) ---"
launchctl list 2>/dev/null | awk '{print $3}' | grep -v '^com.apple' | grep -v '^Label$' | sort | head -40

section "5. cron"
crontab -l 2>/dev/null || echo "(crontabなし)"

section "6. 同期クライアントの存在"
ps aux | grep -iE '[d]ropbox|[g]oogle.?drive' | head -5 || true
[ -d "$HOME/Library/CloudStorage" ] && ls "$HOME/Library/CloudStorage" | wc -l | awk '{print "CloudStorage配下: "$1" 項目"}' || echo "CloudStorageなし"

section "7. エージェント関連ディレクトリのサイズ(対象を明示列挙)"
du -sh "$HOME/.codex" "$HOME/.claude" "$HOME/Library/Caches" 2>/dev/null || true

section "8. gitリポジトリ (ホーム直下2階層のみ・Library等除外)"
find "$HOME" -maxdepth 2 -type d -name .git \
  -not -path "$HOME/Library/*" -not -path "$HOME/.Trash/*" 2>/dev/null | while read -r g; do
  repo="${g%/.git}"
  echo "${repo/#$HOME/~} [branch=$(git -C "$repo" rev-parse --abbrev-ref HEAD 2>/dev/null) dirty=$(git -C "$repo" status --porcelain 2>/dev/null | wc -l | tr -d ' ')]"
done

section "9. エージェントツールの有無"
for c in claude codex node npm brew git; do
  printf '%s: ' "$c"; command -v "$c" 2>/dev/null || echo "なし"
done

echo
echo "完了。レポート: $REPORT"
echo "次: ジョニーが内容を確認し、問題なければiPhoneのClaudeアプリ(司令部)へ貼る。"
echo "この後の変更作業は、司令部が発行するコミット固定の手順書(HANDOFF-B)が届くまで行わない。"
