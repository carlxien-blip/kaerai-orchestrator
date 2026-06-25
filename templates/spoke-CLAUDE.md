# CLAUDE.md · <SPOKE_NAME> (a spoke)

> This project is orchestrated by the hub at `<HUB_DIR>`. Strategy lives in the hub;
> here we execute. Read truth live, reference it, never copy it.

@docs/first-principles.md

## First principles (operable decision rules)

The operable canonical for this project is `docs/first-principles.md` (imported above).
The authoritative strategy lives in the hub — this is its operable projection.
Reference, don't copy.

## Canonical pointer (where my truth lives + how to read it live)

> Spoke contract (1). A worker reads the *right source*, never a copied snapshot.

- My current state + todos: `STATUS.md` (read live; the hub writes it back after sign-off).
- My operable decision rules: `docs/first-principles.md`.
- Latest reality: `git log`, and any external source of truth this project uses (state where).
- (Add the specific live sources a worker must read before acting.)

## Asset registry (what I own + what I pull)

> Spoke contract (3). Makes cross-project discovery possible (A can find B's assets).

- **I own:** (list assets this project produces / holds)
- **I pull (pointers out):** (list other projects' assets this one depends on, with where they live)

## Onboarding (for any worker dispatched here)

A worker dispatched from the hub does NOT automatically load this file (auto-load
binds to the session's startup cwd, not to "the project you said you're working
on"). So a task brief's first line must force onboarding: **read all of this
CLAUDE.md and walk the canonical pointers above before acting.**
