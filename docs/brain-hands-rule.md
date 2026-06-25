# The brain / hands rule — the orchestrator has no hands

The orchestrator is a brain. It thinks, keeps truth, breaks down briefs, dispatches, and reads
results against acceptance. It does **not** do a spoke's actual work — even though, sitting in a
session full of tools, it always *could*.

## Why "could" is the trap

When the orchestrator does a spoke's work directly inside its own session, it skips everything
that makes that spoke's work correct: the spoke's `CLAUDE.md`, its skill routing, its canonical
pointers. It cherry-picks one file, starts, and proceeds blind to truth that already exists in
that project — then asks the human about things the project already documents, looking ignorant.
Root cause: the brain reached out and used hands it shouldn't have.

**Having a tool in hand is not the same as it being your job to use it.** This is the rule that's
easiest to violate, because the violation always feels efficient in the moment.

## What counts as "work" (all of it gets dispatched)

Not just writing code. Also: producing content, running analysis, pulling data (e.g. via MCP),
reading transcripts, running reports. Any of these = dispatch a worker, never the orchestrator's
own Bash/MCP/Write.

## The "don't bounce it back to the human" corollary

The cleanest *technical* frame for a spoke's work is inside that spoke's own session (CLAUDE.md +
hooks auto-apply there). But that's the frame **a worker** should run in — not work bounced back
to the human. The orchestrator's whole value is that the human talks to one mouth and the brain
dispatches hands. Telling the human "go run it yourself in the spoke session" is the orchestrator
failing its one job. It always dispatches a worker and brings the result back.

## Why a hook, not willpower

This is exactly the kind of rule that willpower fails at, because every violation looks locally
efficient. So it's enforced by a harness: `hooks/orchestrator-no-hands-guard.sh`, a PreToolUse
hook.

- Fires **only** when cwd == `HUB_DIR` (you're in the hub) **and** the tool targets a tracked
  spoke: a `Write`/`Edit` to a file under a spoke, a `Bash` command containing a spoke's path, or
  **any** MCP call.
- Forces a self-classification: *keeping truth / cross-project coordination* (editing a canonical
  pointer, asset registry, the architecture) -> fine, continue; *doing work* -> stop and dispatch.
- **Read is never guarded.** Reading a spoke's CLAUDE.md / STATUS live to keep truth is the core
  correct path; guarding it would false-positive constantly.
- Working inside a spoke's own session (cwd == spoke) never fires. The hub editing its own files
  never fires.

Start non-blocking (v1, a warning). Once you trust it, upgrade to a hard block.
