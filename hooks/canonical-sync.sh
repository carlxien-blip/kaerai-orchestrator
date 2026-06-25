#!/usr/bin/env bash
# SessionStart + UserPromptSubmit hook — cross-session canonical auto-sync.
#
# Problem it solves: you edit a canonical truth file (the hub's living brief, or a
# spoke's first-principles) in one Claude Code session; another session that's
# already running never finds out. This hook makes the second session pick up the
# change automatically — structure over willpower, no verbal reminders, no relying
# on the model "remembering" to re-read.
#
# Which canonical it watches is chosen by the session's cwd:
#   cwd == HUB_DIR        -> $HUB_CANONICAL          (large file -> inject a "re-read" pointer)
#   cwd == any spoke      -> <cwd>/$SPOKE_CANONICAL  (small file -> inject the whole thing)
#
# SessionStart    : only record a baseline mtime (CLAUDE.md/@import already loaded
#                   the latest content at startup; don't double-inject).
# UserPromptSubmit: if the canonical changed since we last injected (or this is the
#                   first time this session sees it) -> inject; otherwise stay silent.
#
# Injection is via stdout. Any error -> silent exit 0. Never breaks a session.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$HERE/config.sh" 2>/dev/null || exit 0
[ -n "$HUB_DIR" ] || exit 0

input="$(cat 2>/dev/null)"
cwd="$(hook_json_get "$input" cwd)"
sid="$(hook_json_get "$input" session_id)"
evt="$(hook_json_get "$input" hook_event_name)"
[ -n "$cwd" ] || exit 0
[ -n "$sid" ] || sid="nosid"

# Pick canonical by cwd. The hub uses a pointer (its brief is large); every other
# project (spoke) injects its own SPOKE_CANONICAL in full. Onboarding a new spoke
# requires nothing here — as long as it has the SPOKE_CANONICAL file, it just works.
if hook_is_hub "$cwd"; then
  canon="$HUB_CANONICAL"
  mode="pointer"; name="Hub living brief ($(basename "$HUB_CANONICAL"))"
else
  canon="${cwd%/}/${SPOKE_CANONICAL}"
  mode="full"; name="$(basename "${cwd%/}") first principles"
fi
[ -f "$canon" ] || exit 0

mtime="$(stat -f %m "$canon" 2>/dev/null || stat -c %Y "$canon" 2>/dev/null || echo 0)"
mdate="$(stat -f %Sm -t '%Y-%m-%d %H:%M' "$canon" 2>/dev/null || date -r "$canon" '+%Y-%m-%d %H:%M' 2>/dev/null || echo '?')"

mkdir -p "$SYNC_STATE_DIR" 2>/dev/null
key="$(printf '%s' "$canon" | tr '/.' '__')"
statef="${SYNC_STATE_DIR}/${sid}__${key}"
prev=""
[ -f "$statef" ] && prev="$(cat "$statef" 2>/dev/null)"

if [ "$evt" = "SessionStart" ]; then
  # Startup @import already carried the latest; only record baseline.
  printf '%s' "$mtime" > "$statef" 2>/dev/null
  exit 0
fi

# UserPromptSubmit (and anything else): inject only on change / first-sight.
if [ "$mtime" != "$prev" ]; then
  if [ "$mode" = "full" ]; then
    echo "## [canonical-sync] ${name} — current version (updated ${mdate})"
    echo
    echo "> This is the **current canonical** for this project's first principles. Work from it. Source: \`${canon}\` (auto-injected by hook, read live)."
    echo
    cat "$canon"
  else
    echo "## [canonical-sync] ${name} changed (${mdate})"
    echo
    echo "> This file changed after your session loaded. **Re-read \`${canon}\` now before continuing** and work from the latest canonical."
  fi
  printf '%s' "$mtime" > "$statef" 2>/dev/null
fi
exit 0
