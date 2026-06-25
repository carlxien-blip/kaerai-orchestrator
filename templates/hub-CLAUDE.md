# CLAUDE.md · <HUB_NAME> (the brain + orchestrator)

> This is the hub of your AI operating system. Two jobs in one:
> 1. **Brain** — the canonical current truth about you and all your projects.
> 2. **Orchestrator** — dispatches AI workers inside each project (see `ORCHESTRATOR.md`).
>
> **Work happens inside each project (spoke); here we only "think clearly + keep truth + dispatch".**

## What's in the brain (canonical current truth — other projects @import these)

| File | What it is |
|---|---|
| `current_state.md` | Living brief (what you're doing / thinking / stuck on now) |
| `projects-overview.md` | Project matrix (what each project is + where it stands) |
| `profiles/` | Profiles (you + each project) |
| `decisions/` | Decision log (the why; append-only, never rewritten) |
| `notes/` | Anything else canonical you want one home for |

## Decision protocol (any session that makes a real decision runs this)

You say "**record a decision: X, because Y**" -> do three things:
1. **Record it in `decisions/`** (date + why) — a log; nobody reads it day to day, only when tracing back.
2. **Update the canonical value/file it affects** (change the one source of truth; everything that references it follows) — the present state.
3. If it's a "long-standing fact", store one memory.

**IRON RULE 1: a decision MUST land in the canonical doc of the project it affects, not only the hub log.**
> A worker inside a working project only reads its own project's files, not the hub's `decisions/`. So a decision must be pushed both ways: (a) into that spoke's own canonical doc (the basis for execution) + (b) the hub log/canonical (the why + traceability). Push only to the hub and the spoke never learns, and two sessions will fight. Every spoke must have one **explicitly declared canonical doc** (see spoke contract 1 in `ORCHESTRATOR.md`).

**IRON RULE 2: reference, never copy.** A truth has exactly one home; everywhere else points at it, never re-transcribes it (re-transcribing = drift).

## Orchestrator (dispatching projects)

- How to dispatch / red zones / acceptance / loop limits -> `ORCHESTRATOR.md`
- Project registry (where to dispatch) -> `projects.md`
- Task ledger (interruptible, resumable) -> `jobs/`

**One-line flow**: you give a goal + acceptance criteria -> hub breaks it into tasks, dispatches a worker in the right project -> reads the result against acceptance -> if it falls short, revises the brief and dispatches another round -> only red zone / done / stuck reaches you.
