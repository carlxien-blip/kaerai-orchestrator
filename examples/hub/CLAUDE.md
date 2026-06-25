# CLAUDE.md · acme-hub (the brain + orchestrator)

> The hub of this AI operating system. Two jobs: **brain** (canonical truth about every
> project) + **orchestrator** (dispatches workers into each project — see `ORCHESTRATOR.md`).
> Work happens inside each project (spoke); here we only think, keep truth, and dispatch.

## What's in the brain (canonical truth — spokes @import or point at these)

| File | What it is |
|---|---|
| `current_state.md` | Living brief — what's in flight right now |
| `projects.md` | Project registry: where to dispatch + each project's red zone |
| `decisions/` | Decision log (append-only, the why) |

## Decision protocol

"Record a decision: X, because Y" ->
1. Append a file to `decisions/` (date + why).
2. Update the canonical value it affects — **and** push it into the affected spoke's own
   `docs/first-principles.md` (IRON RULE 1: a worker in a spoke reads only its own files).
3. If it's a long-standing fact, store a memory.

**IRON RULE 2: reference, never copy.** One home per truth; everywhere else points at it.

## Orchestrator

- How to dispatch / red zones / acceptance / loop limits -> `ORCHESTRATOR.md` (repo root)
- Project registry -> `projects.md`

One-line flow: goal + acceptance criteria -> hub dispatches a worker in the right project ->
reads result against acceptance -> revises + redispatches if short -> only red zone / done /
stuck reaches the human.
