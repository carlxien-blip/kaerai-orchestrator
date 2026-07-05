# Multi-session canonical sync — how it works

The problem: you run several Claude Code sessions at once. You edit a canonical truth file
in one. The others, already running, have no idea. They keep working from a stale version and
drift apart.

The fix is the `canonical-sync` hook, wired at two events in every participating session.

## The two events

- **SessionStart** — fires when a session opens. At this point Claude Code has *already* loaded
  the project's `CLAUDE.md` and its `@import`s, so the latest canonical is already in context.
  The hook does **not** re-inject; it only records a baseline `mtime` per (session, file). This
  avoids a duplicate dump at startup.
- **UserPromptSubmit** — fires on every prompt you send. The hook compares the canonical file's
  current `mtime` against the baseline it recorded for this session. If it changed (or this
  session is seeing the file for the first time), it injects the latest — otherwise it stays
  silent.

State is kept per session under `$SYNC_STATE_DIR` (default `~/.claude/canonical-sync-state`),
keyed by `session_id` + a sanitized file path. So two sessions track their own baselines
independently, and one session re-reading doesn't suppress the injection in another.

## Which canonical, and how it's injected

The hook picks the file by the session's cwd:

- **cwd == `HUB_DIR`** -> the hub's living brief (`$HUB_CANONICAL`, default `current_state.md`).
  This file is usually large, so the hook injects a **pointer** ("this changed, re-read it
  now") rather than the whole thing.
- **cwd == any other project (a spoke)** -> that spoke's `$SPOKE_CANONICAL` (default
  `docs/first-principles.md`). These are small and operable, so the hook injects them **in
  full**.

Onboarding a new spoke needs zero changes here: as long as the project has a
`docs/first-principles.md`, the cwd-based selection picks it up automatically.

## Why this and not a daemon / file-watcher

A background watcher would have to push into a running session out-of-band, which Claude Code
doesn't expose cleanly. The hook approach piggybacks on the prompt cycle: the moment you next
interact with a stale session, it self-corrects. No daemon, no extra process, no polling — and
it fails safe (any error -> silent `exit 0`, never interrupts a session).

## Beyond file writes: commit-time concurrency

Syncing reads is half the story — parallel sessions also collide at **commit time**
(committing a stale snapshot reverts a co-worker's landed changes; `git add -A` in a
shared tree smuggles someone else's half-done edits into your batch). The rules live in
ORCHESTRATOR.md, "Concurrency-safety protocol", items 4–5 (single home; not repeated here).

## Failure-safety

Every path in the hook degrades to `exit 0`:
- `HUB_DIR` unset -> exit.
- Canonical file missing -> exit.
- `python3` / `stat` unavailable or erroring -> the surrounding command's failure is swallowed.

The worst case is "no sync this turn", never "broke your session".
