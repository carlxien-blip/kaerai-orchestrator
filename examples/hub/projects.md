# projects.md · project registry (where the hub dispatches)

> Rule: has a CLAUDE.md = a project (dispatchable); no CLAUDE.md = just reference material.
> Before dispatching, check the project's red zone — touching it always stops for the human.
> This is a pointer table, not a state store: detailed state lives in each project's
> STATUS.md, read live (copying state here = drift).

## Active projects (dispatchable)

| Project | Path | What it is + state pointer | Red zone (stop and ask the human) |
|---|---|---|---|
| **acme-web** | `<spokes>/acme-web` | Fictional web frontend. State: `acme-web/STATUS.md` (read live). | deploys, payments |
| **acme-api** | `<spokes>/acme-api` | Fictional backend API. State: `acme-api/STATUS.md` (read live). | production DB, data migration, deploys |

## Adopt / create

- **Adopt**: add a CLAUDE.md header pointing back to the hub + a line here + run `spoke-onboard.sh`.
- **Create**: hub makes the folder + writes CLAUDE.md + git init + registers a line here.
