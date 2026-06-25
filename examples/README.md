# Example: one hub + two spokes

A fully fictional, de-identified worked example of the pattern. Nothing here is real —
`acme-web` and `acme-api` are made up, and the paths are placeholders.

```
examples/
├─ hub/                 the brain + orchestrator
│  ├─ CLAUDE.md         points at canonical truth + the orchestrator
│  ├─ current_state.md  the living brief (synced across sessions)
│  ├─ projects.md       the project registry (where to dispatch + red zones)
│  └─ decisions/        append-only decision log
│     └─ 2026-01-12-acme-auth-method.md
├─ acme-web/            a spoke (a fictional web frontend)
│  ├─ CLAUDE.md         canonical pointer + asset registry + onboarding note
│  ├─ STATUS.md         current state + todos (hub reads this live)
│  ├─ docs/first-principles.md
│  └─ .claude/settings.json   wired to canonical-sync + concurrency guard
└─ acme-api/            a spoke (a fictional backend API)
   ├─ CLAUDE.md
   ├─ STATUS.md
   ├─ docs/first-principles.md
   └─ .claude/settings.json
```

## The thing this example demonstrates

`hub/decisions/2026-01-12-acme-auth-method.md` records a decision that auth moves to
**email magic links**. Watch how it lands in **two places** (core principle 2):

- the hub's decision log (the *why*), and
- `acme-web/docs/first-principles.md` **and** `acme-api/docs/first-principles.md` (the
  *basis for execution* — so a worker dispatched into either spoke reads the decision
  from its own project, not from the hub's log it never opens).

If the decision had been recorded only in the hub log, a worker in `acme-web` would still
be building the old auth method. That's the bug principle 2 exists to prevent.

> The `.claude/settings.json` files in the spokes use the literal path
> `$HOOKS_DIR/canonical-sync.sh` for illustration. In a real install, `spoke-onboard.sh`
> writes the resolved absolute path for your machine.
