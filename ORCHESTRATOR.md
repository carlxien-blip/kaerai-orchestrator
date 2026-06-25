# ORCHESTRATOR.md · how the hub dispatches projects

> Read this when the hub is acting as orchestrator. **The orchestrator has no hands:
> it does no work itself (no writing code / running analysis / pulling data /
> producing content) — it only dispatches. See "IRON RULE: orchestrator has no hands".**
>
> Default stage = **P0 (human in the loop)**: you approve before dispatch and review
> the result. P1 adds auto-loops; P2 a standing queue (see end).

## IRON RULE: the orchestrator has no hands

**The orchestrator = a brain, no hands.** Any spoke's *actual work* — not just writing
code, but **analysis / producing content / pulling data / reading transcripts / running
reports** — is **always dispatched to a worker, never done with the tools the
orchestrator session happens to have (Bash / MCP / Read for editing)**. Having a tool
in hand != it being your job to use it. The orchestrator only: thinks clearly / keeps
truth / breaks down briefs / dispatches / reads results against acceptance.

> **Why this is a written rule (learned the hard way):** an orchestrator that runs a
> spoke's work directly inside its own session cherry-picks one file and starts, skips
> the spoke's CLAUDE.md / skill routing / canonical, and ends up repeatedly asking
> about things that already exist in that project — looking ignorant. Root cause = the
> brain reached out and used hands.

**A dispatched worker does NOT auto-load the spoke's CLAUDE.md / hooks — the brief must
force onboarding.** Claude Code's auto-load and hooks bind to **the session's cwd at
startup**, not to "the project you said you're working on". A worker spawned from the
hub defaults to **the hub's frame**: the spoke's CLAUDE.md is not in its context, and
the spoke's hooks don't fire for it (hooks follow session settings, not the folder you
mention). So:
- **The first line of every task brief must be**: "First read all of `<spoke>/CLAUDE.md`
  and walk its canonical pointers / skill index, then act." Omit it and the worker is as
  blind as a hub-frame session — you just pushed the bug down a level.
- **Never hand "go run it yourself inside the spoke session" back to the human as the
  option.** The orchestrator's whole value is that the human talks to one mouth (the
  brain) and the brain dispatches hands. Making the human enter the spoke = the
  orchestrator failing its job. (In-spoke is technically the cleanest frame — but that's
  the truth *a worker* should run in, not work bounced back to the human.) The
  orchestrator always dispatches a worker and brings the result back.
- **Backstop installed**: `hooks/orchestrator-no-hands-guard.sh` (PreToolUse on
  `Write|Edit|Bash` + `mcp__.*`) — only in the **hub session** (cwd == HUB_DIR), and only
  when the target is a **spoke** (editing a file / a Bash command containing a spoke path
  / any MCP call), it warns and forces a self-classification: "keeping truth -> continue
  / doing work -> stop and dispatch". **Read is not guarded** (reading live to keep truth
  is the correct path); working inside a spoke's own session, or the hub editing its own
  files, never fires. v1 is non-blocking; once stable, upgrade to a hard block.

## One loop

```
0. (read live) The hub first follows the project's CLAUDE.md "Canonical pointer" to the
   real current state + todos (git log / STATUS.md / external truth), then talks goals.
1. Human gives a goal + acceptance criteria.
2. Hub breaks it into a task brief:
   goal + objective acceptance criteria + which slice of hub context + red-zone flags + target project.
3. Dispatch a worker in the target project dir (headless / sub-agent) —
   the brief's first line forces onboarding (workers don't auto-load the spoke's CLAUDE.md).
4. Worker onboards per the first line (reads the project's CLAUDE.md + walks pointers)
   -> does the work -> returns a structured result (what it did / build·test pass or fail / where it's stuck).
5. Hub reviews against acceptance: pass -> report to human; fail -> revise brief, dispatch
   another round (transient state goes in jobs/, disposable).
6. Report to human + surface red zones / forks.
7. (human sign-off triggers write-back) Human satisfied -> hub writes "latest state + todos"
   back to the project's STATUS home (git project -> STATUS.md). Next time, resume from there.
```

## State stays fresh (read live + write back to source, no copies)

**IRON RULE: the hub doesn't copy state — it reads source + writes back to source.**
- **Read**: state lives in source (git log / each project's STATUS.md / external truth);
  the hub reads it live. `projects.md` keeps only a one-liner + canonical pointer, no
  detailed state (copying = drift).
- **Write**: after sign-off, the hub writes "current state + todos" back to the project's
  STATUS home.
- Reading live also closes the old hole: work done directly in a project (bypassing the
  hub) shows up in git log anyway, so reading live catches it instead of drifting.

### System constraints (hooks, not willpower)
Two hooks are configured in the hub's `.claude/settings.json`, scripts in `hooks/`,
tracked list in `tracked-projects.txt`:
- **SessionStart -> `project-status-digest.sh`**: when you open a session in the hub,
  auto-injects each running project's latest state + open todos (cures "forgot to check").
- **Stop -> `status-writeback-gate.sh`**: at close, if a project's changes are newer than
  its STATUS.md, reminds you to write back (cures "forgot to write back"). v1 non-blocking;
  upgrade to hard block once stable.
- To track a new project: add a STATUS.md + a line in `tracked-projects.txt`. Projects
  with no local git diff (e.g. doc-only) aren't covered by the gate; rely on step 7's
  manual write-back.

## The actual dispatch action (P0)

Run a headless worker in the target project dir:
```
claude -p "<task brief>" --dangerously-skip-permissions   # only for safe, reversible work
```
or spawn a sub-agent via the Agent / Workflow tools. The worker finishes, returns its
result, the hub reads it.

## Four knobs (run through these before every dispatch)

| Knob | Rule |
|---|---|
| **Red zone** | Touching <REPLACE: your irreversible/external/money surfaces — e.g. production server / payments / deploys / external source of truth> -> **always stop and ask the human**; workers may not do these autonomously. Per-project red zones live in `projects.md`. |
| **Acceptance** | Every task carries an **objective** test (build passes / tests green / screenshot / file exists). No objective test = not allowed to declare "done". |
| **Loop limit** | At most N rounds per goal (default 3) + a token budget cap; on hitting it, stop and ask the human — don't spin and burn money. |
| **Intervention** | Before dispatch (P0) / on a red zone / on completion -> involve the human. |

## Intervention standard (what needs the human, what doesn't)

> Lock the human to "**setting direction** (before) + **irreversible / external / spending**
> (after)", and throw the middle (execution) out — so they aren't the bottleneck. The real
> axis is "**how cheaply can this be reversed**", not "can it be reversed at all": put the
> judgment at the fork (where changing course is cheapest), not at the acceptance gate. Tune
> the knobs looser as trust grows (loosen first: report frequency / pure-feature releases).

**Needs the human (both ends):**
- **Before · set direction & taste**: (a) changing structure/architecture/choosing an
  approach (expensive to reverse) -> align direction *before* acting, not after; (b) content
  that goes out in the human's voice -> agent drafts, human approves the final.
- **After · irreversible / external / spending**: releases only when they touch
  money/payment/pricing/data-migration/deleting-data; plus the always-on hard red lines —
  see per-project red zones in `projects.md`.

**Doesn't need the human (hub accepts, then summarizes):** pure-feature / copy-fix / bug-fix
releases, concrete implementation inside already-decided structure.

**Fully automatic:** anything the machine self-checks (compiles / tests green).

**Visibility (current stage):** report each item as it finishes (volume is still small);
as volume grows, drop to a daily digest.

## Acceptance logic (how to judge an agent really finished — don't trust its self-report)

1. **Objective, externally visible, pre-defined**: acceptance criteria are fixed before
   dispatch and an outsider can verify them (build passes / tests green / file exists /
   screenshot / URL 200). "I looked, seems fine" != done.
2. **The doer != the judge**: hand it to a *different* agent / the hub / a dumb script to
   verify, tasked specifically to "find faults, disprove that it's done"; it passes only when
   they can't (cures self-rating bias — in our experience a large share of agent failures are
   the agent talking to itself).
3. **Show evidence, not claims**: make it surface the actual run output / screenshot / files.
   Judge the evidence, not the words. Strictness scales with how irreversible / external the
   change is.

## Dispatch + review flow (doer / reviewer separation — the standard move for a code feature)

> Turns the intervention + acceptance logic above into an executable flow. Core: the one who
> writes the code doesn't get to declare "done"; the reviewer's context is independent and
> comes *after*, not concurrently.

1. **Define spec + objective acceptance (with the human, before acting)** — criteria fixed
   pre-dispatch and externally verifiable (tests green / build passes / expected output for
   behavior cases / which files must not be touched).
2. **Dispatch a worker (independent context, inside the project dir)** — reads the brief +
   project canonical -> implements -> **runs build/test/lint itself** -> reports done only on
   green, **with evidence** (test output / diff), not just "done".
3. **Dispatch an independent reviewer (AFTER the worker delivers, not concurrently)** — the
   reviewer reviews the product; code that doesn't exist can't be reviewed, hence after. Its
   "independence" = **independent context**: fresh mind, never wrote this, told to **"find
   faults / assume it's broken"** (adversarial), checks the diff against spec, **re-runs it
   itself**, doesn't trust the worker's words. It specifically covers the gap that "tests
   green != actually built to spec" (missed cases / broke something else / doesn't match spec).
4. **Falls short -> bounce back to the worker for another round** (loop limit N, default 3; on
   hitting it stop and ask the human, don't spin and burn money).
5. **The hub is not the final judge** — it doesn't review its own dispatched work and say
   "looks good" (that's max bias). The hub only **aggregates** deterministic results + the
   reviewer's verdict, and hands the residual **taste / behavior** judgment to the human.
6. **The human reviews only "their" slice** (per the intervention standard) — is the behavior
   right / experience good / is it what they wanted = taste, which a reviewer agent can't
   replace.

**Two honest boundaries:**
- The reviewer is also an LLM, **same source** as the worker -> it catches "author bias /
  framing bias" but **not "the kind of error neither of them would think of" (shared blind
  spot)**. The real backstop = **deterministic checks (tests / build, the machine decides) +
  the human**. -> The more the spec's acceptance can be written as machine-verifiable, the more
  reliable this is.
- **Strictness scales with risk**: a locally-reversible small feature = worker + 1 reviewer +
  green tests is enough; touching production / payments / data = multiple adversarial reviewers
  + mandatory human.

## Where skip-permissions is allowed

- ALLOWED: local, git-reversible code changes.
- NOT: <REPLACE: external source of truth / production / payments / deploys / deleting many
  files> — these are red zones, manual confirmation.

## Spoke contract (the "sockets" every dispatched project must expose)

> The hub accumulating truth isn't enough; a spoke that exposes no standard sockets = the hub
> shouting into the void. The #1 multi-agent failure mode is "no shared contract, agents talk
> past each other". **Before dispatching, confirm the target project meets these 6; if not,
> onboard first.**

| Socket | What it is | What it fixes |
|---|---|---|
| **(1) Canonical pointer** (read truth) | CLAUDE.md has a "Canonical pointer" section: where my truth is, how to read it live | worker reads the right source, not a copy |
| **(2) First principles** (start from principle) | `docs/first-principles.md` (operable decision rules) + CLAUDE.md `@import`s it | every change starts from principle, doesn't drift |
| **(3) Asset registry** (be discoverable) | CLAUDE.md has an "Asset registry": what I own + what I pull (pointers out) | cross-project discovery (A finds B's assets) |
| **(4) STATUS.md** (report state) | agreed format, todos as `- [ ]`; hub reads live on SessionStart | no verbal progress relay |
| **(5) canonical-sync hook** (join sync) | `.claude/settings.json` wires `canonical-sync.sh` (SessionStart + UserPromptSubmit) | truth changes -> running sessions catch up |
| **(6) Registration** (get on the roster) | one line in `projects.md` + one in `tracked-projects.txt` | hub knows you exist + how to dispatch |

**One command to align**: `scripts/spoke-onboard.sh <project-path>` — idempotently fills 4/5/6
+ placeholders for 2/3 + installs the concurrency guard; creates what's missing, never touches
what exists; lists what still needs manual filling (the real content of 1/3, the projects.md
line). **Rely on templates, not hand-wiring (structure over willpower).**

## Concurrency-safety protocol (multiple sessions editing truth, no lost updates)

> Risk: two sessions edit the same shared canonical -> last write wins -> lost update. Naive
> shared truth is last-writer-wins, NOT a lock. If you already run parallel sessions, this is
> the most real trap. **Don't reach for a distributed lock** (Raft/consensus for one person's
> few sessions = over-engineering); these three suffice:

1. **Edit shared canonical with `Edit`, not `Write`.** Edit's exact match = section-level
   compare-and-swap: if someone changed that section, your Edit fails -> you're forced to see
   the new version. A blind whole-file `Write` overwrite = dangerous.
2. **Append instead of editing where possible.** Log-type truth (`decisions/`, `jobs/`) only
   adds new files / appends, never rewrites — naturally concurrency-safe.
3. **When canonical-sync says "it changed", re-read before writing.** The hook already pushes
   "someone changed this file" to you; on seeing it, re-read, don't write on a stale version.
- **Structural guard**: `canonical-write-guard.sh` (PreToolUse-on-Write) warns (non-blocking)
  when you blind-write an existing shared canonical, nudging you to Edit or re-read first.

## New project ("new project: X")

The hub does it in one shot: (1) make the folder (2) write CLAUDE.md (standard header pointing
back to the hub brain + project skeleton) (3) git init (4) run `spoke-onboard.sh` to fill the
6 contract sockets (5) register a line in `projects.md`. **Born connected to the brain, on the
roster, contract-compliant.**

## Adopting an existing project

Add the standard CLAUDE.md header (pointing back to the hub) -> run `spoke-onboard.sh <path>`
to fill the 6 sockets -> add a line in `projects.md` -> fill the placeholders of 2/3 with real
content.

## Stages

- **P0 (now)**: manual dispatch, human in the loop. Already enough to not open 15 windows.
- **P1**: wrap in workflow/loop, auto multi-round until acceptance passes.
- **P2**: background / scheduled, unattended runs of the `jobs/` queue.
