#!/usr/bin/env bash
# SessionStart hook — inject the reusable workers (keyed by spoke) into context when you
# open a session in the hub. Solves: a new session doesn't know which workers OTHER sessions
# already spawned, so it spawns fresh ones and re-pays the onboarding tax for each.
# Reads the persistent registry $WORKER_REGISTRY (default $HUB_DIR/active-workers.json).
# This read+surface half is reliable (SessionStart always fires). Any error -> silent exit 0.
# See docs/worker-reuse.md.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$HERE/config.sh" 2>/dev/null || exit 0
[ -n "$HUB_DIR" ] || exit 0

input="$(cat 2>/dev/null)"
cwd="$(hook_json_get "$input" cwd)"
hook_is_hub "$cwd" || exit 0

[ -f "$WORKER_REGISTRY" ] || exit 0
now="$(date +%s 2>/dev/null)"; [ -n "$now" ] || exit 0

out="$(REG="$WORKER_REGISTRY" NOW="$now" python3 -c '
import os, json
reg=os.environ["REG"]; now=int(os.environ["NOW"])
try:
    d=json.load(open(reg))
except Exception:
    raise SystemExit(0)
ws=d.get("workers",{}) or {}
lines=[]
for spoke,info in ws.items():
    ts=info.get("ts",0) or 0
    age=now-ts
    if age>86400 or age<0:      # older than 24h -> probably dead, do not surface
        continue
    name=spoke.rsplit("/",1)[-1]
    when=("%d min ago"%(age//60)) if age<3600 else ("%.1f h ago"%(age/3600.0))
    lines.append("  - %s -> %s (%s; %s)"%(name, info.get("agentId","?"), (info.get("task","") or "")[:30], when))
if lines:
    print("Reusable workers already spawned — before dispatching to one of these spokes, SendMessage to CONTINUE the existing worker rather than spawning fresh (only spawn if you cannot continue):\n"+"\n".join(lines)+"\n(workers older than 24h are hidden = probably dead)")
' 2>/dev/null)"

[ -n "$out" ] || exit 0
python3 -c "import json,sys
print(json.dumps({'hookSpecificOutput':{'hookEventName':'SessionStart','additionalContext':sys.argv[1]}},ensure_ascii=False))" "$out" 2>/dev/null
exit 0
