# STATUS · acme-api

> The hub reads this file live on SessionStart. Todos use `- [ ]`. The hub writes it back
> after sign-off.

## Current state
Implementing the magic-link auth backend (per hub decision 2026-01-12). Token model designed;
endpoint not yet wired to the email provider.

## Todos
- [ ] Implement `POST /auth/magic-link` (issue a one-time token, email it).
- [ ] Implement `GET /auth/verify` (consume token, start a session).
- [ ] Expire tokens after N minutes; single-use only.

## Recently done
- Designed the one-time-token table schema.
