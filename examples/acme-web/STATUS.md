# STATUS · acme-web

> The hub reads this file live on SessionStart. Todos use `- [ ]`. The hub writes it back
> after sign-off.

## Current state
Login screen is mid-migration from password auth to email magic links (per hub decision
2026-01-12). UI shell is in place; waiting on acme-api's `/auth/magic-link` endpoint to wire
the real request.

## Todos
- [ ] Replace the password form with the email-only magic-link form.
- [ ] Wire the form to acme-api `/auth/magic-link` once the endpoint ships.
- [ ] Add the "check your email" confirmation state.

## Recently done
- Removed the social-login button (rejected in the auth decision).
