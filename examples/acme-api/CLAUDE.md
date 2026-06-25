# CLAUDE.md · acme-api (a spoke)

> Orchestrated by acme-hub. Strategy lives in the hub; here we execute. Read truth live,
> reference it, never copy it.

@docs/first-principles.md

## Canonical pointer (where my truth lives + how to read it live)

- Current state + todos: `STATUS.md` (read live; the hub writes it back after sign-off).
- Operable decision rules: `docs/first-principles.md`.
- Latest reality: `git log`.
- The auth contract acme-web depends on is defined here — keep `docs/first-principles.md`
  and the endpoint behavior in sync.

## Asset registry (what I own + what I pull)

- **I own:** the auth endpoints (`/auth/magic-link`, verification), the user table schema.
- **I pull (pointers out):**
  - transactional email provider config — owned by the hub's infra notes.

## Onboarding (for any dispatched worker)

A worker dispatched from the hub does NOT auto-load this file. The task brief's first line
must be: **read all of this CLAUDE.md and walk the canonical pointers above before acting.**
