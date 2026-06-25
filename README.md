# orchestrator-oss

**A hub-and-spoke orchestration pattern for running many projects with Claude Code —
without your AI agents drifting out of sync, and without you becoming the human relay
that bottlenecks everything.**

This is a methodology + a small set of Claude Code hooks. It's for solo operators and
small teams who use the Claude Code CLI to manage **several projects at once**.

> Claude-Code-specific. The hooks and `@import` mechanics are Claude Code features. If
> you don't use Claude Code, take the methodology (below + `docs/`) and skip the hooks.

---

## 1. The problem

When you run multiple Claude Code sessions across multiple projects, two things break:

- **Truth drifts.** You decide something in session A; sessions B and C never find out.
  A worker in one project reads a stale doc and contradicts a decision made an hour ago
  in another. Two sessions edit the same shared file and the second silently clobbers
  the first (last-writer-wins — not a lock).
- **You become the bottleneck.** You end up as a human relay, copy-pasting state between
  projects, re-explaining context, remembering what each session knows. The more projects
  you run, the more you *are* the integration layer — by hand.

## 2. The hub-and-spoke model

One **hub** (the "brain") holds canonical truth and orchestrates. Many **spokes** (the
projects where work actually happens) each read the hub's truth live and never store their
own copy. You talk to one mouth — the hub — and the hub dispatches workers into the spokes.

```
                  ┌──────────────────────────┐
                  │           HUB            │
        you ───►  │   brain + orchestrator    │
                  │  canonical truth, no hands │
                  └────┬─────────┬─────────┬──┘
                  dispatch    dispatch   dispatch
                       ▼         ▼         ▼
                  ┌────────┐ ┌────────┐ ┌────────┐
                  │ spoke  │ │ spoke  │ │ spoke  │
                  │acme-web│ │acme-api│ │  ...   │
                  └────────┘ └────────┘ └────────┘
              work happens here; spokes read hub truth, never copy it
```

## 3. Core principles

1. **One home per truth · reference, never copy.** A fact lives in exactly one place;
   everywhere else points at it. Re-transcribing a value into a second file *is* the drift
   bug. (See `templates/` — every doc is a pointer, not a snapshot.)
2. **A decision must land in the affected spoke's own canonical — not just the hub log.**
   A worker inside a spoke reads only that spoke's files, never the hub's decision log. So
   push every decision *both ways*: into the spoke's own canonical doc (basis for execution)
   and the hub log (the why + traceability). Push only to the hub and the spoke never learns,
   and the next two sessions fight.
3. **Sync truth across sessions in real time.** A canonical file changing in one session is
   auto-injected into other running sessions (`canonical-sync` hook). No verbal reminders, no
   relying on the model to remember to re-read.
4. **Intervention standard — what needs a human, what doesn't.** Lock the human to two ends:
   *setting direction* (before) and *irreversible / external / spending* (after). Throw the
   middle — execution — out to workers. The axis is "how cheaply can this be reversed", and
   the judgment goes at the fork, not the acceptance gate.
5. **Acceptance logic — objective checks for objective things, humans only for taste.** Every
   task has a pre-defined, externally verifiable test (build passes / tests green / file
   exists / URL 200). "I looked, seems fine" isn't done. Only taste/behavior judgments go to
   a human.
6. **doer ≠ reviewer — guard against self-rating bias.** The agent that wrote the code doesn't
   get to declare it done. A separate, independent-context reviewer — fresh mind, told to
   "assume it's broken, find faults" — checks the product *after* delivery and re-runs it
   itself.
7. **Brain / hands separation — the orchestrator has no hands.** The hub thinks, keeps truth,
   and dispatches. It never does a spoke's actual work with its own tools, even when it could.
   Being able to act != it being your job to act.

Full operations manual: **[ORCHESTRATOR.md](ORCHESTRATOR.md)**.

## 4. Low-friction entry point: try just `canonical-sync` first

If the whole methodology feels like a lot — **start with one hook**: `hooks/canonical-sync.sh`.

It makes multiple running Claude Code sessions **automatically pick up changes** to a canonical
file the moment it's edited in any session. Change your "current truth" file in session A, and
session B re-reads it on its next prompt — no reminder, no copy-paste.

We haven't seen another project do exactly this (cross-session canonical
auto-sync via Claude Code hooks). Wire up just this one, feel the difference, then funnel into
the full methodology when you're ready.

## 5. Two battle-tested gotchas

These are the non-obvious lessons — the part you'd only learn by getting burned.

### Gotcha A — a dispatched worker does NOT auto-load the spoke's CLAUDE.md / hooks

Claude Code's auto-load (CLAUDE.md, `@import`) and hooks bind to **the session's cwd at
startup**, not to "the project you said you're working on". A worker spawned from the hub
therefore defaults to **the hub's frame**: the spoke's CLAUDE.md is never in its context, and
the spoke's hooks don't fire for it.

So the **first line of every task brief must force onboarding**:

> "First read all of `<spoke>/CLAUDE.md` and walk its canonical pointers / skill index, then act."

Omit it and the worker is as blind as a hub-frame session — you've just pushed the bug down a
level. In our experience this is a common way a "managed" multi-project setup quietly produces
ignorant workers.

### Gotcha B — use the harness to force the orchestrator to keep its hands off

An orchestrator with tools in hand will reach out and do a spoke's work directly — skipping
that spoke's CLAUDE.md, skill routing, and canonical — and end up acting ignorant of truth that
already exists. Willpower doesn't fix this; a hook does.

`hooks/orchestrator-no-hands-guard.sh` is a **PreToolUse** hook that fires when the hub session
tries to act directly on a spoke (edit its files / a Bash command mentioning its path / any MCP
call) and makes it self-classify: *keeping truth -> continue; doing work -> stop and dispatch.*
Read is never guarded (reading live to keep truth is correct). Start non-blocking; upgrade to a
hard block once you trust it.

## 6. Quick start (5 minutes)

The commands below use the default **copy mode** (hooks are copied into your hub). To
reference this repo in place instead, append `--in-place` (recognized in any argument position).

```bash
git clone <this-repo> orchestrator-oss
cd orchestrator-oss
./install.sh /path/to/your/hub        # wires hooks into the hub's .claude/settings.json,
                                      # persists HUB_DIR to your shell rc
source ~/.zshrc                        # (or open a new shell) so HUB_DIR is set

# list your projects, one absolute path per line:
$EDITOR "$HUB_DIR/hooks/tracked-projects.txt"

# bring a project up to the spoke contract:
"$HUB_DIR/scripts/spoke-onboard.sh" /path/to/a/project
```

`install.sh` backs up any existing `settings.json` and merges hooks without clobbering unrelated
keys. Everything is parameterized by `HUB_DIR` — no hard-coded paths.

## 7. Who this is for

- You use the **Claude Code CLI** and manage **several projects at once** (solo operator or
  small team).
- You've felt the drift (sessions contradicting each other) and the relay fatigue (you, copying
  state by hand).
- You want structure (hooks/gates) doing the remembering instead of your willpower.

Not for you if: you work in a single project, or you don't use Claude Code (the hooks won't
apply — but the methodology in `ORCHESTRATOR.md` and `docs/` still travels).

---

## Repo layout

| Path | What |
|---|---|
| `README.md` | this file |
| `ORCHESTRATOR.md` | the full operations manual |
| `hooks/` | the 6 hooks, all paths parameterized via `hooks/config.sh` + env vars |
| `scripts/spoke-onboard.sh` | idempotently bring a project up to the spoke contract |
| `templates/` | empty-shell templates: hub/spoke CLAUDE.md, STATUS, first-principles, decision, asset-registry, contract checklist |
| `examples/` | a worked, fictional example: one hub + two spokes (`acme-web`, `acme-api`) |
| `docs/` | deeper dives: multi-session sync, intervention standard, doer/reviewer bias, brain/hands, comparison with BMAD & LangGraph |
| `install.sh` | wire hooks into the hub + set `HUB_DIR` |

## How it compares (briefly)

See [docs/comparison.md](docs/comparison.md) for a neutral comparison with **BMAD-METHOD** and
**LangGraph**. In short: this is not an agent framework and not a graph runtime — it's a thin,
file-and-hook pattern for keeping truth coherent and a human un-bottlenecked across many Claude
Code projects.

## License

MIT — see [LICENSE](LICENSE).
