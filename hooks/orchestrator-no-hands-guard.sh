#!/usr/bin/env bash
# PreToolUse hook — the "orchestrator has no hands" backstop.
#
# Problem it solves: doing a spoke's actual work directly inside the hub session
# (editing a spoke's files / running scripts against it / pulling its data via MCP)
# = the brain reaching out and using hands it shouldn't. The orchestrator's whole
# value is that you talk to ONE mouth (the brain), and the brain dispatches workers.
# When it does the work itself, it skips the spoke's CLAUDE.md / skill routing /
# canonical and ends up acting ignorant of truth that already exists.
#
# This warns ONLY when: cwd == HUB_DIR (you're in the hub) AND the tool targets a
# tracked spoke (edit a file under a spoke / Bash command mentioning a spoke path /
# any MCP call). Working inside a spoke's own session (cwd == spoke) is the correct
# path and is never flagged. The hub editing its OWN files is fine and never flagged.
# Read is NOT guarded — reading a spoke's CLAUDE.md/STATUS to "read live for truth"
# is the core correct path; guarding it would false-positive constantly.
#
# Non-blocking self-classification reminder. Any error -> silent exit 0.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$HERE/config.sh" 2>/dev/null || exit 0
[ -n "$HUB_DIR" ] || exit 0

input="$(cat 2>/dev/null)"
cwd="$(hook_json_get "$input" cwd)"
tool="$(hook_json_get "$input" tool_name)"
fp="$(hook_tool_input_get "$input" file_path)"
cmd="$(hook_tool_input_get "$input" command)"

# Only manage things inside the hub session.
hook_is_hub "$cwd" || exit 0

# Spoke roots come from the tracked-projects config — never hard-coded.
[ -f "$TRACKED_FILE" ] || exit 0
SPOKES="$(grep -vE '^\s*(#|$)' "$TRACKED_FILE" 2>/dev/null)"
[ -n "$SPOKES" ] || exit 0

hit=""
case "$tool" in
  Write|Edit)
    while IFS= read -r s; do
      [ -n "$s" ] || continue
      case "$fp" in "$s"/*) hit="$s"; break;; esac
    done <<< "$SPOKES"
    ;;
  Bash)
    while IFS= read -r s; do
      [ -n "$s" ] || continue
      case "$cmd" in *"$s"*) hit="$s"; break;; esac
    done <<< "$SPOKES"
    ;;
  mcp__*)
    hit="MCP($tool)"   # any MCP call from the hub = reaching out with hands (pulling data, etc.)
    ;;
esac
[ -n "$hit" ] || exit 0

msg="[orchestrator has no hands] You're acting directly on a spoke from inside the hub session: ${hit}. **Self-classify first** — [keeping truth / cross-project coordination] (editing a canonical pointer, asset registry, brain-hands architecture) -> fine, continue; [doing work] (producing content / running analysis / pulling data / writing an implementation) -> **stop; reuse-first, don't default to spawning**: (1) **check the worker registry (active-workers.json) first** — if a live worker exists for this spoke, continue it with **SendMessage** (context is already warm; send the next instruction, **don't re-send the whole pre-routed brief**); (2) **only spawn fresh if none can be continued** + a pre-routed brief (first line forces onboarding: 'first read all of <spoke>/CLAUDE.md and walk its skill index / canonical pointers, then act'; name the file(s) + inline the red lines), and **register it by hand immediately after spawning** (auto-registration on the Agent tool is unreliable — don't count on it); (3) or run it inside the spoke's own session. **Default = one active worker per spoke; a fresh spawn is the fallback, not the reflex.** Multi-stage work on the same thing (outline -> draft ...) = continue the same worker, not a new one per stage. **Being able to act is not the same as it being your job to act.** This warning does not block. See docs/worker-reuse.md."

python3 -c "import json,sys
print(json.dumps({'systemMessage':sys.argv[1],'hookSpecificOutput':{'hookEventName':'PreToolUse','additionalContext':sys.argv[1]}},ensure_ascii=False))" "$msg" 2>/dev/null
exit 0
