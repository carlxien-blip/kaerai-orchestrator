# The intervention standard — what needs a human, what doesn't

The goal: keep the human out of the middle (execution) without losing control of the things that
matter. The wrong axis is "can this be undone at all" — almost anything can, technically. The
right axis is **"how cheaply can we change course"**, and the judgment belongs at the fork (where
changing course is cheapest), not at the acceptance gate (where it's already built).

## Lock the human to two ends

### Before — set direction and taste
- **Structure / architecture / choice of approach.** These are expensive to reverse once built,
  so align direction *before* acting, not after a worker has implemented the wrong one.
- **Anything that goes out in the human's voice.** The agent drafts; the human approves the final.

### After — irreversible / external / spending
- Releases only when they touch **money / payments / pricing / data migration / deleting data**.
- Plus the always-on hard red lines specific to each project (its "red zone" in `projects.md`):
  production servers, external sources of truth, sending things to outsiders, mass deletion.

## Throw the middle out

- **Doesn't need the human (orchestrator accepts, then summarizes):** pure-feature work,
  copy fixes, bug-fix releases, concrete implementation inside an already-decided structure.
- **Fully automatic:** anything the machine can self-check — it compiles, tests are green.

## Tuning over time

The settings start deliberately tight (small volume, building trust). Loosen the knobs one at a
time as trust grows. Usually the first to loosen are **report frequency** (per-item -> daily
digest) and **pure-feature releases** (human approval -> auto with summary).

## Visibility

While volume is small, report each item as it finishes. As volume grows, drop to a daily digest
so the reporting itself doesn't become noise.
