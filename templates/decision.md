# Decision · YYYY-MM-DD · <short title>

> Append-only. One file per decision. Never rewrite a past decision — supersede it
> with a new one that references it.

**Decision:** (what was decided, in one line)

**Because:** (the why — the reasoning, constraints, and tradeoffs that led here)

**Affects (canonical updated):**
- Hub: (which hub canonical value/file was updated)
- Spoke: (which spoke's `docs/first-principles.md` or canonical doc was updated — IRON RULE 1: a decision must land in the affected spoke's own canonical, not only this log)

**Blast-radius sweep:** (grep term(s) for the OLD value + where the hits were + how each
was cleaned — converted to a reference, or marked stale in the body. Landed = the
old-truth grep comes back zero. See `docs/decision-protocol.md`.)

**Supersedes:** (link to an earlier decision this replaces, or "none")
