# CLAUDE.md · acme-web (a spoke)

> Orchestrated by acme-hub. Strategy lives in the hub; here we execute. Read truth live,
> reference it, never copy it.

@docs/first-principles.md

## Canonical pointer (where my truth lives + how to read it live)

- Current state + todos: `STATUS.md` (read live; the hub writes it back after sign-off).
- Operable decision rules: `docs/first-principles.md`.
- Latest reality: `git log`.
- Auth behavior is decided in the hub's decision log and mirrored into my first-principles —
  always build auth from `docs/first-principles.md`, not from memory.

## Asset registry (what I own + what I pull)

- **I own:** the login UI, the marketing pages, the design tokens for the web app.
- **I pull (pointers out):**
  - auth endpoints — owned by `acme-api`, read its `docs/first-principles.md` for the contract.
  - product copy — owned by the hub.

## Onboarding (for any dispatched worker)

A worker dispatched from the hub does NOT auto-load this file. The task brief's first line
must be: **read all of this CLAUDE.md and walk the canonical pointers above before acting.**
