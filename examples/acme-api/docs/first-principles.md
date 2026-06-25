# acme-api first principles

> Operable decision rules for build workers in acme-api. CLAUDE.md `@import`s this file.
> Authoritative strategy lives in the hub; this is its operable projection. Reference, don't copy.

**WHY** — acme-api is the trust boundary; correctness and safety of auth and data beat speed of
delivery on every change.

**Decision gates — pass these before acting:**
1. **Auth = email magic links** (hub decision 2026-01-12). Implement issue + verify; no passwords.
2. Magic-link tokens are single-use and expire after N minutes — never reusable, never logged.
3. The endpoint contract acme-web consumes is owned here; change it -> update this file + notify.

**Out of scope / never do:**
- Touching the production database directly or running data migrations (red zone — stop and ask).
- Deploying to production (red zone).
