#!/usr/bin/env bash
# PostToolUse hook — after dispatching a worker (Task/Agent), record (spoke -> agentId +
# task + timestamp) into the persistent registry, so other sessions can discover and reuse
# it on their next SessionStart (worker-registry-digest.sh). Only in the hub session.
# Writes atomically. Any error -> silent exit 0.
#
# WARNING (hard lesson B, see docs/worker-reuse.md): this depends on PostToolUse firing for
# the Task/Agent tool, which is NOT reliable across setups. Do NOT trust it as the only path
# — the dispatcher must ALSO register by hand right after spawning. Treat this as best-effort.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$HERE/config.sh" 2>/dev/null || exit 0
[ -n "$HUB_DIR" ] || exit 0

input="$(cat 2>/dev/null)"
cwd="$(hook_json_get "$input" cwd)"
hook_is_hub "$cwd" || exit 0

[ -f "$TRACKED_FILE" ] || exit 0
SPOKES="$(grep -vE '^\s*(#|$)' "$TRACKED_FILE" 2>/dev/null)"
[ -n "$SPOKES" ] || exit 0

printf '%s' "$input" | REG="$WORKER_REGISTRY" SPOKES="$SPOKES" python3 -c '
import os, sys, json, re, time
raw=sys.stdin.read()
try:
    h=json.loads(raw)
except Exception:
    raise SystemExit(0)
ti=h.get("tool_input",{}) or {}
prompt=(ti.get("prompt","") or "")+" "+(ti.get("description","") or "")
task=(ti.get("description","") or "")[:40]
resp=h.get("tool_response","")
if not isinstance(resp,str):
    resp=json.dumps(resp,ensure_ascii=False)
blob=str(resp)+" "+raw           # agentId may be in tool_response or the raw json
m=re.search(r"agentId[\"\x27:=\s]+([A-Za-z0-9_-]{6,})", blob)
if not m:
    raise SystemExit(0)
agid=m.group(1)
spoke=None
for s in os.environ["SPOKES"].splitlines():
    s=s.strip()
    if s and s in prompt:
        spoke=s; break
if not spoke:
    raise SystemExit(0)
reg=os.environ["REG"]
try:
    d=json.load(open(reg))
except Exception:
    d={"workers":{}}
d.setdefault("workers",{})[spoke]={"agentId":agid,"task":task,"ts":int(time.time())}
tmp=reg+".tmp"
json.dump(d,open(tmp,"w"),ensure_ascii=False,indent=2)
os.replace(tmp,reg)
' 2>/dev/null
exit 0
