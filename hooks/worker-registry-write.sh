#!/usr/bin/env bash
# PostToolUse hook — after dispatching a worker (Task/Agent), record (spoke -> agentId +
# task + timestamp) into the persistent registry, so other sessions can discover and reuse
# it on their next SessionStart (worker-registry-digest.sh). Only in the hub session.
# Writes atomically. Any error -> silent exit 0.
#
# 2026-07-04 update (verified live, see docs/worker-reuse.md hard lesson B):
# - PostToolUse on Task/Agent DOES fire in our setup — the old "may not fire" caveat is
#   retired. The failure mode we actually hit is worse: MIS-registration. A read-only
#   scout agent whose prompt merely *mentioned* a spoke path got auto-registered as that
#   spoke's live worker — overwriting the entry for the real, reusable one.
# - Fix 1: register ONLY on an explicit marker. The dispatcher puts
#   `[REGISTER-WORKER:<spoke-root>]` in the brief of a real (reusable) worker; read-only
#   scouts never carry it. A path string happening to appear in a prompt != a dispatch.
# - Fix 2: overwrite protection — if the spoke already has a live entry (<24h) with a
#   different agentId, do NOT clobber it; that worker should be continued, not silently lost.
# - Auto-writes remain best-effort: treat registry entries written by this hook as leads,
#   and have the dispatcher hand-write/verify the entry after a real spawn.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$HERE/config.sh" 2>/dev/null || exit 0
[ -n "$HUB_DIR" ] || exit 0

input="$(cat 2>/dev/null)"
cwd="$(hook_json_get "$input" cwd)"
proj="$(hook_session_project "$cwd")"
hook_is_hub "$proj" || exit 0

printf '%s' "$input" | REG="$WORKER_REGISTRY" python3 -c '
import os, sys, json, re, time
raw=sys.stdin.read()
try:
    h=json.loads(raw)
except Exception:
    raise SystemExit(0)
ti=h.get("tool_input",{}) or {}
prompt=(ti.get("prompt","") or "")+" "+(ti.get("description","") or "")

# Fix 1: explicit marker only — mentioning a spoke path is not dispatching to it.
m=re.search(r"\[REGISTER-WORKER:([^\]\s]+)\]", prompt)
if not m:
    raise SystemExit(0)
spoke=m.group(1)

task=(ti.get("description","") or "")[:40]
resp=h.get("tool_response","")
if not isinstance(resp,str):
    resp=json.dumps(resp,ensure_ascii=False)
blob=str(resp)+" "+raw           # agentId may be in tool_response or the raw json
ma=re.search(r"agentId[\"\x27:=\s]+([A-Za-z0-9_-]{6,})", blob)
if not ma:
    raise SystemExit(0)
agid=ma.group(1)

reg=os.environ["REG"]
try:
    d=json.load(open(reg))
except Exception:
    d={"workers":{}}
d.setdefault("workers",{})

# Fix 2: overwrite protection — never clobber a live (<24h) entry for a DIFFERENT agent.
now=int(time.time())
old=d["workers"].get(spoke)
if old and old.get("agentId")!=agid and (now-(old.get("ts",0) or 0))<86400:
    raise SystemExit(0)

d["workers"][spoke]={"agentId":agid,"task":task,"ts":now}
tmp=reg+".tmp"
json.dump(d,open(tmp,"w"),ensure_ascii=False,indent=2)
os.replace(tmp,reg)
' 2>/dev/null
exit 0
