# Spoke contract checklist

> Every project you dispatch work to must expose these 6 "sockets". Without them,
> the hub is shouting into the void — the #1 multi-agent failure mode is agents with
> no shared contract, each talking past the others. Confirm all 6 before dispatching;
> if any is missing, onboard first (`scripts/spoke-onboard.sh <project>` fills 4/5/6
> and placeholders for 2/3).

- [ ] **(1) Canonical pointer** — CLAUDE.md has a "Canonical pointer" section: where my
      truth lives + how to read it live. *Fixes: workers reading the right source, not a copy.*
- [ ] **(2) First principles** — `docs/first-principles.md` (operable decision rules) +
      CLAUDE.md `@import`s it. *Fixes: every change starting from principle, not drifting.*
- [ ] **(3) Asset registry** — CLAUDE.md has an "Asset registry" section: what I own +
      what I pull (pointers out). *Fixes: cross-project discovery.*
- [ ] **(4) STATUS.md** — agreed format, todos as `- [ ]`; the hub reads it live on
      SessionStart. *Fixes: no verbal progress relay needed.*
- [ ] **(5) canonical-sync hook** — `.claude/settings.json` wires `canonical-sync.sh`
      (SessionStart + UserPromptSubmit). *Fixes: truth changes -> running sessions catch up.*
- [ ] **(6) Registration** — one line in `projects.md` + one line in `tracked-projects.txt`.
      *Fixes: the hub knows you exist and how to dispatch to you.*
