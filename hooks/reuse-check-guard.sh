#!/usr/bin/env bash
# PreToolUse hook — the "reuse check" (v1). When the hub dispatches a worker (Task/Agent)
# and the prompt targets a tracked spoke, force a one-line "can you reuse an existing worker
# via SendMessage?" prompt. Cures "spawned a fresh worker when you should have continued one
# -> every fresh worker re-onboards the spoke from zero = burns tokens".
# Only warns in the hub session (session startup dir == HUB_DIR; see hook_session_project);
# read-only scout agents (Explore/Plan/...) never trigger it. Non-blocking. Any error ->
# silent exit 0.
# Rule + exceptions: see ORCHESTRATOR.md "Dispatch spec" and docs/worker-reuse.md.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$HERE/config.sh" 2>/dev/null || exit 0
[ -n "$HUB_DIR" ] || exit 0

input="$(cat 2>/dev/null)"
cwd="$(hook_json_get "$input" cwd)"
proj="$(hook_session_project "$cwd")"
hook_is_hub "$proj" || exit 0

# Read-only scout agents are not "workers" — nagging about reuse on them is pure noise
# (observed live 2026-07-04: dispatching a read-only Explore scout tripped the reuse
# check). Skip the known read-only subagent types.
stype="$(hook_tool_input_get "$input" subagent_type)"
case "$stype" in Explore|Plan|claude-code-guide|statusline-setup) exit 0 ;; esac

prompt="$(printf '%s' "$input" | python3 -c "import sys,json
try:
    d=json.load(sys.stdin).get('tool_input',{}) or {}
    print((d.get('prompt','') or '')+' '+(d.get('description','') or ''))
except Exception: print('')" 2>/dev/null)"

[ -f "$TRACKED_FILE" ] || exit 0
SPOKES="$(grep -vE '^\s*(#|$)' "$TRACKED_FILE" 2>/dev/null)"
[ -n "$SPOKES" ] || exit 0

hit=""
while IFS= read -r s; do
  [ -n "$s" ] || continue
  case "$prompt" in *"$s"*) hit="$s"; break;; esac
done <<< "$SPOKES"
[ -n "$hit" ] || exit 0

msg="[reuse check] You're dispatching a worker to spoke ${hit}. **Ask first**: did this session already spawn a worker for it that you can continue? If so, **reuse it via SendMessage** (it's already onboarded — save the tokens) instead of spawning fresh. **Only spawn new when**: (1) you're fanning out in parallel, (2) an independent review — doer != reviewer needs a fresh context, or (3) it's a stale snapshot — a while has passed / the spoke changed since, so reusing would act on the wrong state. If you DO spawn a real (reusable) worker, put **[REGISTER-WORKER:${hit}]** in its brief so the registry hook auto-registers it (never put the marker on read-only scouts). **Default: one active worker per spoke.** This warning does not block."

python3 -c "import json,sys
print(json.dumps({'systemMessage':sys.argv[1],'hookSpecificOutput':{'hookEventName':'PreToolUse','additionalContext':sys.argv[1]}},ensure_ascii=False))" "$msg" 2>/dev/null
exit 0
