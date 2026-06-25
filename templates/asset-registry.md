# Asset registry · <PROJECT_NAME>

> Spoke contract (3). Declares what this project OWNS and what it PULLS (pointers
> out to other projects' assets). Makes cross-project discovery possible: project A
> can find project B's assets without copying them. Reference, never copy.
>
> This usually lives as a section inside the project's CLAUDE.md; this template is
> the standalone shape.

## I own
| Asset | Where it lives | Notes |
|---|---|---|
| (e.g. the public API schema) | `path/or/url` | |
| (e.g. the brand voice guide) | `path/or/url` | |

## I pull (pointers out)
| Asset | Owned by | Where to read it live |
|---|---|---|
| (e.g. auth tokens) | acme-api | `acme-api/docs/...` |
| (e.g. design tokens) | the hub | `<HUB_DIR>/profiles/...` |
