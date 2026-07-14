#!/bin/bash
# mini-audit.sh — Mac mini (Batou/niihama) 読み取り専用実査
#
# 使い方: 実家でminiに入って(画面直接 or ghost/TermiusからSSH):
#   curl -fsSL https://raw.githubusercontent.com/ikedhidenori/jp/claude/s9-stability-storage-oxpleg/mini-audit.sh | bash
#
# 完全に読み取り専用。変更は一切しない(sudo項目はスキップして「要sudo」と記録)。
# 新システム(greenfield)設計の入力データ収集と、Codex監査(2026-07-14以前)の追認が目的。
# 結果は ~/Desktop に保存。git pushは試みるが、認証がなければ手動で貼ってもらう。

set -u
STAMP=$(date +%Y%m%d-%H%M%S)
REPORT="$HOME/Desktop/mini-audit-$STAMP.md"
exec > >(tee "$REPORT") 2>&1

section() { printf '\n===== %s =====\n' "$1"; }
echo "# mini (Batou) audit $STAMP"

section "0. ハードウェア / OS"
system_profiler SPHardwareDataType 2>/dev/null | grep -E 'Model|Chip|Memory|Serial' || true
sw_vers
uptime

section "1. ディスク"
df -h / /System/Volumes/Data 2>/dev/null

section "2. セキュリティ / 電源 (Codex監査の追認)"
fdesetup status 2>/dev/null || echo "fdesetup: 要sudoまたは取得不可"
pmset -g 2>/dev/null | grep -E 'autorestart|sleep|standby|womp' || true
echo "--- リモートログイン/共有(取得できる範囲) ---"
launchctl print-disabled system 2>/dev/null | grep -E 'ssh|screensharing' || echo "(要sudo)"

section "3. Tailscale 3系統共存の実態"
echo "--- 存在するバイナリ ---"
ls -la /Applications/Tailscale.app/Contents/MacOS/Tailscale 2>/dev/null || echo "GUI app: なし"
ls -la /opt/homebrew/bin/tailscale* /usr/local/bin/tailscale* 2>/dev/null || echo "homebrew/usr-local: なし"
echo "--- 動作中プロセス ---"
ps aux | grep -i '[t]ailscale' || echo "(なし)"
echo "--- LaunchDaemons/Agents内のtailscale ---"
ls /Library/LaunchDaemons 2>/dev/null | grep -i tailscale || true
ls "$HOME/Library/LaunchAgents" 2>/dev/null | grep -i tailscale || true
echo "--- status ---"
for ts in "/Applications/Tailscale.app/Contents/MacOS/Tailscale" /opt/homebrew/bin/tailscale /usr/local/bin/tailscale; do
  [ -x "$ts" ] && { echo "[$ts]"; "$ts" status 2>&1 | head -3; }
done

section "4. launchd 非Apple項目 (2ヶ月前実装の自動復旧を含む)"
echo "--- user agents (~/Library/LaunchAgents) ---"
ls -la "$HOME/Library/LaunchAgents" 2>/dev/null || echo "(なし)"
echo "--- system daemons/agents (非Apple) ---"
ls /Library/LaunchDaemons /Library/LaunchAgents 2>/dev/null | grep -v '^com.apple' || true
echo "--- loaded (非Apple) ---"
launchctl list 2>/dev/null | awk '{print $3}' | grep -v '^com.apple' | grep -v '^Label$' | sort | head -40

section "5. cron / 既存の自動化"
crontab -l 2>/dev/null || echo "(crontabなし)"

section "6. 同期クライアント / 常駐アプリ"
ps aux | grep -iE '[d]ropbox|[g]oogle.?drive|fileproviderd' | head -10 || true
ls "$HOME/Library/CloudStorage" 2>/dev/null || echo "(CloudStorageなし)"

section "7. ディスク使用の概観"
du -xh -d1 "$HOME" 2>/dev/null | sort -h | tail -15

section "8. gitリポジトリ棚卸し"
find "$HOME" -maxdepth 3 -type d -name .git -not -path "$HOME/Library/*" 2>/dev/null | while read -r g; do
  repo="${g%/.git}"
  echo "${repo/#$HOME/~} [branch=$(git -C "$repo" rev-parse --abbrev-ref HEAD 2>/dev/null) dirty=$(git -C "$repo" status --porcelain 2>/dev/null | wc -l | tr -d ' ')]"
done

section "9. エージェント環境"
ls -la "$HOME/.codex" 2>/dev/null | head -5 || echo "~/.codex なし"
ls -la "$HOME/.claude" 2>/dev/null | head -5 || echo "~/.claude なし"
which claude codex node npm brew 2>/dev/null || true

section "10. レポートpush試行 (失敗したら手動で貼る)"
TMP=$(mktemp -d /tmp/miniaudit.XXXXXX)
if git clone --depth 1 --branch s9-reports https://github.com/ikedhidenori/jp "$TMP/jp" 2>/dev/null; then
  mkdir -p "$TMP/jp/triage"
  cp "$REPORT" "$TMP/jp/triage/mini-audit-$STAMP.md"
  git -C "$TMP/jp" add triage \
    && git -C "$TMP/jp" -c user.name="mini-audit" -c user.email="audit@batou.local" commit -m "mini audit $STAMP" \
    && git -C "$TMP/jp" push origin s9-reports 2>&1 \
    && echo "OK: push成功" \
    || echo "NG: push不可(認証なし)。このターミナル出力か $REPORT を貼ってください"
else
  echo "NG: clone失敗。このターミナル出力か $REPORT を貼ってください"
fi
rm -rf "$TMP"
echo
echo "完了。レポート: $REPORT"
