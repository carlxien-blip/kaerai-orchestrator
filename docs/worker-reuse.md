# Worker reuse discipline

> Companion to the "orchestrator has no hands" rule. No-hands says: *dispatch a worker
> instead of doing the work yourself.* This says: **before you spawn a fresh worker,
> check whether you can reuse one you already have.** Default = **one active worker per
> spoke**; a fresh spawn is the fallback, not the reflex.

## Why

Every fresh worker re-onboards the spoke from zero — reads its CLAUDE.md, walks its
canonical pointers, rebuilds context. That onboarding is the orchestrator's dominant
token cost: the inherent price of division of labor (a stateless worker has no cache).
Spawning a *new* worker for each step of the same job re-pays that tax every time, and
throws away the "already-ruled-out" list the previous worker accumulated. Left
unchecked, a busy hub fans out a dozen fresh workers into one spoke in an afternoon and
pays the onboarding tax a dozen times over.

The fix is cheap: keep a small registry of live workers keyed by spoke, and continue an
existing one with `SendMessage` instead of cold-starting a new Agent.

## The discipline

1. **Check before you spawn.** A registry (`active-workers.json` in the hub) records
   `spoke -> {agentId, task, ts}`. On SessionStart the hub surfaces reusable workers;
   before dispatching, look there first.
2. **Reuse via SendMessage.** If a live worker exists for the target spoke, send it the
   next instruction — its context is already warm, so **don't re-send the whole
   pre-routed brief**, just the next step.
3. **Spawn only as fallback.** Spawn a fresh worker when none can be continued — then
   pre-route its brief (name the file(s) to read + inline the red lines) and **register
   it immediately** (see hard lesson B).
4. **When a fresh spawn IS right** (the reuse-check exceptions): (a) you're fanning out
   in parallel; (b) an independent review — doer != reviewer deliberately needs a fresh,
   uncontaminated context; (c) a stale snapshot — enough time has passed, or the spoke
   has since changed, that reusing the old worker would act on the wrong state.
5. **Multi-stage = same worker.** Sequential stages of one job (outline -> draft -> ...)
   continue the same worker, not a new one per stage.

## The hooks

| Hook | Event | Role |
|---|---|---|
| `worker-registry-digest.sh` | SessionStart | surfaces reusable workers (by spoke, < 24h old) into context |
| `reuse-check-guard.sh` | PreToolUse on `Task\|Agent` | on dispatch to a spoke, forces a "can you reuse?" prompt (non-blocking) |
| `worker-registry-write.sh` | PostToolUse on `Task\|Agent` | best-effort auto-register on spawn (see lesson B) |

All three are parameterized via `hooks/config.sh` (`WORKER_REGISTRY`, `TRACKED_FILE`) and
fail safe (any error -> silent `exit 0`). They only act inside the hub session.

## Two hard lessons (learned by getting burned)

### Lesson A — the guard must live in the HUB (or global) settings, not spoke-local

A hook meant to intercept **workers the hub dispatches** must be wired into the **hub's
(or the user's global) `settings.json`** — not into a spoke's local `.claude/settings.json`.
Hooks bind to the session's cwd at startup, and a hub-spawned worker runs in the **hub's
frame**, so a spoke-local hook **never fires for it**. Put the reuse / no-hands guards
where the work is actually dispatched *from* (the hub / global settings), or they silently
do nothing for exactly the case they exist for. (`install.sh` wires them into the hub's
settings for this reason.)

### Lesson B — register on spawn; don't rely on auto-registration

Auto-registration via a PostToolUse hook on the Task/Agent tool is **not reliable** —
that event does not consistently fire for agent spawns across setups. So treat
`worker-registry-write.sh` as best-effort only, and make the dispatcher **write the
registry entry by hand right after spawning** (`spoke -> agentId + task + ts`). The
registry is only useful if it's actually populated; a missed auto-write means the next
session spawns a duplicate and re-pays onboarding — the exact bug this whole mechanism
exists to prevent.
