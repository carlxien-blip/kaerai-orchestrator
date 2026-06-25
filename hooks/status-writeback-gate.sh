#!/usr/bin/env bash
# Stop hook — end-of-session gate. If a tracked spoke has code changes/commits
# newer than its STATUS.md, but STATUS.md wasn't updated, remind to write it back.
# Solves "forgot to write the latest state back home".
# v1 = non-blocking reminder (exit 0). Once trusted, upgrade to a hard block (see bottom).

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$HERE/config.sh" 2>/dev/null || exit 0
[ -f "$TRACKED_FILE" ] || exit 0

warn=""
while IFS= read -r p; do
  case "$p" in ''|\#*) continue ;; esac
  [ -d "$p/.git" ] || continue
  # Exclude STATUS.md's own dirtiness (an unwritten STATUS isn't "work not written back").
  dirty="$(git -C "$p" status --porcelain 2>/dev/null | grep -v 'STATUS.md$')"
  last_ct="$(git -C "$p" log -1 --format=%ct 2>/dev/null || echo 0)"
  smt=0
  [ -f "$p/STATUS.md" ] && smt="$(stat -f %m "$p/STATUS.md" 2>/dev/null || stat -c %Y "$p/STATUS.md" 2>/dev/null || echo 0)"
  stale=0
  [ -f "$p/STATUS.md" ] || stale=1                       # no STATUS.md
  [ -n "$dirty" ] && stale=1                              # uncommitted code changes
  [ "${last_ct:-0}" -gt "${smt:-0}" ] && stale=1          # latest commit newer than STATUS
  [ "$stale" -eq 1 ] && warn="$warn  - $(basename "$p")
"
done < "$TRACKED_FILE"

if [ -n "$warn" ]; then
  echo "STATUS write-back gate — these tracked projects have changes newer than STATUS.md (or no STATUS.md). Before ending, write back their 'current state + todos':"
  printf '%s' "$warn"
fi
exit 0

# To upgrade to a hard block: replace the if-block body with
#   echo '{"decision":"block","reason":"<the reminder text above>"}'; exit 0
# (A Stop hook returning JSON decision=block hands control back to the model and
#  forces it to write back before ending.)
