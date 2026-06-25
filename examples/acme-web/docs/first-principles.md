# acme-web first principles

> Operable decision rules for build workers in acme-web. CLAUDE.md `@import`s this file.
> Authoritative strategy lives in the hub; this is its operable projection. Reference, don't copy.

**WHY** — acme-web is the public-facing entry point; every change should reduce friction for a
first-time visitor reaching a working, signed-in state.

**Decision gates — pass these before acting:**
1. **Auth = email magic links** (hub decision 2026-01-12). No password fields, no social login.
2. The login flow calls acme-api `/auth/magic-link`; never invent a local auth shortcut.
3. No new third-party front-end dependency for a core flow without escalating.

**Out of scope / never do:**
- Deploying to production (red zone — stop and ask the human).
- Touching payment flows (red zone).
