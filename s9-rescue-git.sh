#!/bin/bash
# s9-rescue-git.sh — s9上の未コミット/未push作業の退避
#
# 使い方: Termius等でs9に入って
#   curl -fsSL https://raw.githubusercontent.com/ikedhidenori/jp/claude/s9-stability-storage-oxpleg/s9-rescue-git.sh | bash
#
# 方式: git stash create を使い、ローカルの作業状態(ブランチ・作業ツリー・index)を
# 一切変更せずに、追跡済みファイルの変更をコミットオブジェクト化して
# rescue/s9-<日時> ブランチとしてリモートへpushする。
#   - 未追跡ファイル(新規ファイル)は退避しない(秘密ファイルの誤公開防止)。一覧だけ記録
#   - gits-vault と ~/.codex/memories は対象外(機微の可能性が高いため)
#   - upstreamより進んでいるブランチ(ahead>0)は現在のブランチをそのままpush
#
# ロジックボード不安定なs9が死んでも、追跡済みの作業はリモートに残る状態を作るのが目的。

set -u
STAMP=$(date +%Y%m%d-%H%M%S)
RESCUE="rescue/s9-$STAMP"
REPORT="$HOME/Desktop/s9-rescue-$STAMP.txt"
exec > >(tee "$REPORT") 2>&1

echo "s9 git rescue $STAMP  (完全版ログ: $REPORT)"
OK=0; FAIL=0; SKIP=0

find "$HOME" -maxdepth 3 -type d -name .git \
     -not -path "$HOME/Library/*" -not -path "$HOME/.Trash/*" 2>/dev/null |
sort > /tmp/s9-rescue-repos.txt

while read -r g; do
  repo="${g%/.git}"
  name=$(basename "$repo")
  case "$repo" in
    *gits-vault*|*/.codex/memories) echo "[$name] SKIP (機微のため対象外)"; SKIP=$((SKIP+1)); continue ;;
  esac
  if ! git -C "$repo" remote get-url origin >/dev/null 2>&1; then
    echo "[$name] SKIP (originなし)"; SKIP=$((SKIP+1)); continue
  fi

  # 1) 追跡済みファイルの変更を stash create で退避push（ローカル無変更）
  dirty=$(git -C "$repo" status --porcelain --untracked-files=no 2>/dev/null | wc -l | tr -d ' ')
  if [ "$dirty" -gt 0 ]; then
    c=$(git -C "$repo" stash create "rescue $STAMP" 2>/dev/null || true)
    if [ -n "$c" ] && git -C "$repo" push origin "$c:refs/heads/$RESCUE" 2>&1; then
      echo "[$name] OK: 変更 $dirty 件を $RESCUE へpush"
      OK=$((OK+1))
    else
      echo "[$name] FAIL: rescueブランチのpushに失敗"
      FAIL=$((FAIL+1))
    fi
  fi

  # 2) upstreamより進んでいる場合は現在ブランチをpush
  ahead=$( (git -C "$repo" rev-list --count '@{u}..HEAD' 2>/dev/null) || echo 0 )
  if [ "${ahead:-0}" -gt 0 ] 2>/dev/null; then
    if git -C "$repo" push origin HEAD 2>&1; then
      echo "[$name] OK: 未push $ahead コミットをpush"
      OK=$((OK+1))
    else
      echo "[$name] FAIL: 現在ブランチのpushに失敗"
      FAIL=$((FAIL+1))
    fi
  fi

  # 3) 未追跡ファイルは一覧だけ(退避しない)
  unt=$(git -C "$repo" ls-files --others --exclude-standard 2>/dev/null | head -20)
  if [ -n "$unt" ]; then
    echo "[$name] 未追跡(未退避・要目視):"
    echo "$unt" | sed 's/^/    /'
  fi
done < /tmp/s9-rescue-repos.txt

echo
echo "結果: push成功=$OK 失敗=$FAIL スキップ=$SKIP  rescueブランチ名: $RESCUE"

# サマリーをGitHubへ(件数のみ。リポジトリ名や未追跡一覧は公開しない)
JP=""
for g in $(cat /tmp/s9-rescue-repos.txt); do
  url=$(git -C "${g%/.git}" config --get remote.origin.url 2>/dev/null || true)
  case "$url" in *ikedhidenori/jp*) JP="${g%/.git}"; break ;; esac
done
if [ -n "$JP" ]; then
  WT=$(mktemp -d /tmp/s9wt.XXXXXX); rmdir "$WT"
  git -C "$JP" fetch origin s9-reports 2>/dev/null || true
  if git -C "$JP" worktree add "$WT" -B s9-reports origin/s9-reports 2>/dev/null; then
    mkdir -p "$WT/triage"
    {
      echo "# s9 git rescue summary $STAMP"
      echo '```'
      echo "rescue_branch: $RESCUE"
      echo "pushed_ok: $OK / failed: $FAIL / skipped: $SKIP"
      echo "note: 詳細(リポジトリ名・未追跡一覧)は $REPORT にのみ記録"
      echo '```'
    } > "$WT/triage/s9-rescue-$STAMP.md"
    git -C "$WT" add triage && git -C "$WT" commit -m "s9 rescue summary $STAMP" \
      && git -C "$WT" push origin s9-reports && echo "OK: サマリーpush済み"
    git -C "$JP" worktree remove --force "$WT" 2>/dev/null || true
    git -C "$JP" branch -D s9-reports 2>/dev/null || true
  fi
fi
echo "完了。完全版ログ: $REPORT"
