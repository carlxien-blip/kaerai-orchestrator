#!/usr/bin/env bash
# SessionStart hook — when you open a session in the hub, auto-inject each tracked
# spoke's latest status + open todos. Solves "forgot to check the latest state".
# Only fires in the hub (cwd == HUB_DIR); other projects' sessions are left alone.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$HERE/config.sh" 2>/dev/null || exit 0
[ -n "$HUB_DIR" ] || exit 0

input="$(cat 2>/dev/null)"
cwd="$(hook_json_get "$input" cwd)"
hook_is_hub "$cwd" || exit 0

[ -f "$TRACKED_FILE" ] || exit 0
echo "## Tracked projects — latest status (auto-injected by hook, read live, not cached)"
while IFS= read -r p; do
  case "$p" in ''|\#*) continue ;; esac
  [ -d "$p" ] || continue
  echo "### $(basename "$p")"
  last="$(git -C "$p" log -1 --format='%cd · %s' --date=short 2>/dev/null)"
  [ -n "$last" ] && echo "- latest commit: $last"
  [ -n "$(git -C "$p" status --porcelain 2>/dev/null | grep -v 'STATUS.md$')" ] && echo "- WARNING: uncommitted changes (status may not be written back)"
  if [ -f "$p/STATUS.md" ]; then
    todos="$(grep -E '^- \[ \]' "$p/STATUS.md" 2>/dev/null | head -5)"
    if [ -n "$todos" ]; then echo "- open todos:"; echo "$todos" | sed 's/^/  /'; fi
  fi
done < "$TRACKED_FILE"
exit 0
