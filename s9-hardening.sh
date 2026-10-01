#!/bin/bash
# s9-hardening.sh — s9 再発防止の恒久対策
#
# 使い方: Termius等でs9に入って
#   curl -fsSL https://raw.githubusercontent.com/ikedhidenori/jp/claude/s9-stability-storage-oxpleg/s9-hardening.sh | bash
#   (sudoパスワードを2回ほど聞かれます)
#
# やること:
#   1. 停電・電源断のあと自動で再起動する設定 (sudo)
#   2. Tailscale自動復旧: 5分ごとに接続確認し、落ちていたら up し直す LaunchAgent
#   3. Codexログ肥大の予防: 週1回、logs_2.sqlite が500MB超なら削除する LaunchAgent
#      (Codex動作中はスキップ。ログDBは消えてもCodexが作り直す)
#
# 元に戻す方法:
#   launchctl bootout gui/$(id -u)/jp.section9.tailscale-keepalive
#   launchctl bootout gui/$(id -u)/jp.section9.codex-log-rotate
#   rm ~/Library/LaunchAgents/jp.section9.{tailscale-keepalive,codex-log-rotate}.plist
#   rm -r ~/.local/libexec/s9-maintenance

set -u
echo "=== s9 hardening $(date '+%F %T') ==="

echo "--- 1. 電源断後の自動再起動 ---"
sudo pmset -a autorestart 1 && echo "OK: autorestart=1"
pmset -g | grep -E 'autorestart|sleep ' || true

echo "--- 2/3. メンテナンススクリプト設置 ---"
BIN="$HOME/.local/libexec/s9-maintenance"
mkdir -p "$BIN" "$HOME/Library/LaunchAgents" "$HOME/Library/Logs/s9-maintenance"

cat > "$BIN/tailscale-keepalive.sh" <<'EOF'
#!/bin/bash
TS="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
[ -x "$TS" ] || exit 0
if "$TS" status 2>&1 | grep -qi 'stopped'; then
  echo "$(date '+%F %T') stopped -> up" >> "$HOME/Library/Logs/s9-maintenance/tailscale.log"
  open -a Tailscale 2>/dev/null
  sleep 5
  "$TS" up --accept-routes --timeout 60s >> "$HOME/Library/Logs/s9-maintenance/tailscale.log" 2>&1
fi
EOF

cat > "$BIN/codex-log-rotate.sh" <<'EOF'
#!/bin/bash
LOG="$HOME/.codex/logs_2.sqlite"
LIMIT=$((500*1024*1024))
[ -f "$LOG" ] || exit 0
pgrep -f codex >/dev/null 2>&1 && exit 0
size=$(stat -f%z "$LOG" 2>/dev/null || echo 0)
if [ "$size" -gt "$LIMIT" ]; then
  echo "$(date '+%F %T') rotate: $size bytes" >> "$HOME/Library/Logs/s9-maintenance/codex-rotate.log"
  rm -f "$LOG" "$LOG-wal" "$LOG-shm"
fi
EOF
chmod +x "$BIN"/*.sh

make_agent() {
  local label="$1" script="$2" extra="$3"
  local plist="$HOME/Library/LaunchAgents/$label.plist"
  cat > "$plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>$label</string>
  <key>ProgramArguments</key><array><string>/bin/bash</string><string>$script</string></array>
  $extra
  <key>StandardErrorPath</key><string>$HOME/Library/Logs/s9-maintenance/$label.err</string>
</dict></plist>
EOF
  launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$plist" && echo "OK: $label 設置済み"
}

make_agent "jp.section9.tailscale-keepalive" "$BIN/tailscale-keepalive.sh" \
  "<key>StartInterval</key><integer>300</integer><key>RunAtLoad</key><true/>"

make_agent "jp.section9.codex-log-rotate" "$BIN/codex-log-rotate.sh" \
  "<key>StartCalendarInterval</key><dict><key>Weekday</key><integer>1</integer><key>Hour</key><integer>4</integer><key>Minute</key><integer>0</integer></dict>"

echo
echo "=== 完了。手動で残っている恒久対策(GUIが必要): ==="
echo " - システム設定 → Spotlight → プライバシー に ~/.claude ~/.codex ~/.cache を追加"
echo " - ChatGPT.app(Codex)を最新版へ更新(ログ書き込み問題の上流修正取り込み)"
echo " - gmailアカウントのGoogle Drive Webで マイドライブ/Takeout の重複を整理"
