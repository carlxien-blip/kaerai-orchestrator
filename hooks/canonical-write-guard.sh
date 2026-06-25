#!/usr/bin/env bash
# PreToolUse(Write) hook — concurrency-safety guard.
#
# Problem it solves: when two sessions edit the same shared canonical, a blind
# whole-file Write clobbers whatever the other session just wrote (last-writer-wins,
# which is NOT a lock). This warns when you're about to Write (overwrite) an
# *existing* shared canonical file. Creating a new file (e.g. a new decision log)
# is naturally concurrency-safe and passes silently.
#
# Non-blocking: warns only, never blocks. Any error -> silent exit 0.
#
# Which files count as "shared canonical" (warn on overwrite) is the basename list
# below. Customize it for your hub's truth files. Append-only logs (decisions/,
# jobs/) are intentionally absent — new-file-per-entry is already safe.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$HERE/config.sh" 2>/dev/null || exit 0

input="$(cat 2>/dev/null)"
fp="$(hook_tool_input_get "$input" file_path)"
[ -n "$fp" ] || exit 0
# Only guard overwrites of existing files; new files are not a concurrency risk.
[ -f "$fp" ] || exit 0

case "$fp" in
  */current_state.md|*/portfolio_map.md|*/commitments.md|*/first-principles.md|*/CLAUDE.md|*/STATUS.md|*/profiles/*.md) ;;
  *) exit 0 ;;
esac

msg="[concurrency guard] You are using Write to overwrite a shared canonical file: ${fp}. With multiple sessions running in parallel, a blind whole-file write can drop updates another session just wrote (last-writer-wins, not a lock). Prefer Edit (section-level compare-and-swap: if someone changed that section your Edit fails, forcing you to see the new version), or re-read the file to confirm nobody changed it before writing. This warning does not block."

python3 -c "import json,sys
print(json.dumps({
  'systemMessage': sys.argv[1],
  'hookSpecificOutput': {'hookEventName': 'PreToolUse', 'additionalContext': sys.argv[1]}
}, ensure_ascii=False))" "$msg" 2>/dev/null
exit 0
