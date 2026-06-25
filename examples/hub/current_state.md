# current_state.md · acme-hub living brief

> The hub's living brief. canonical-sync watches this file and tells other running
> sessions to re-read it when it changes. Keep it short — it's the "what's in flight now"
> snapshot, not an archive.

## In flight
- **acme-web**: migrating the login screen to email magic links (per decision 2026-01-12).
- **acme-api**: building the `/auth/magic-link` endpoint to back that migration.

## Watching / blocked
- Nothing blocked. Waiting on acme-api's endpoint before acme-web can wire the real flow.

## Recently decided
- 2026-01-12: auth method = email magic links (see `decisions/2026-01-12-acme-auth-method.md`).
