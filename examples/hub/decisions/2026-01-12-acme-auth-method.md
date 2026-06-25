# Decision · 2026-01-12 · Auth method = email magic links

> Append-only. Never rewrite — supersede with a new decision that references this one.

**Decision:** acme's user authentication uses **email magic links** (not username/password,
not a social provider).

**Because:** lowest-friction sign-in for the target audience, no password storage liability,
and it reuses the transactional-email setup already in place. A social provider was rejected
to avoid a third-party dependency for a core flow.

**Affects (canonical updated):**
- Hub: `current_state.md` "Recently decided" updated.
- Spoke `acme-web`: `docs/first-principles.md` — login screen builds against magic links.
- Spoke `acme-api`: `docs/first-principles.md` — auth endpoints implement magic-link issue/verify.

> Note: this decision is pushed into BOTH spokes' own canonicals, not just this log. A worker
> dispatched into acme-web reads acme-web's first-principles, never this file — if the decision
> lived only here, that worker would still build the old auth method. (Core principle 2.)

**Supersedes:** none.
