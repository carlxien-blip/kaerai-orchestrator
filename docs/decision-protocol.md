# Decision protocol — landing a decision so every session actually obeys it

A decision that lives only in your head — or only in a log file nobody re-reads — hasn't
happened, as far as your agents are concerned. In a hub-and-spoke setup, "we decided X"
is only true when every instruction surface an agent might read says X and nothing
still says the old thing.

When the human says "record a decision: X, because Y", the hub runs four steps.

## The four steps

1. **Log it** — append a file to the hub's `decisions/` (date + the *why*). This is the
   audit trail: nobody reads it day-to-day; it exists for traceability and for
   superseding later. Append-only, never rewritten (see `templates/decision.md`).
2. **Update the canonical it affects** — change the *one home* of that truth (hub
   canonical and/or the affected spoke's own canonical doc). Everything that references
   the home follows automatically. This is IRON RULE 1 in action: a decision must land
   in the affected spoke's own canonical, not only the hub log — workers read their
   spoke's files, never the hub's `decisions/`.
3. **Persist long-lived facts** — if the decision states something durably true (not a
   one-off), also store it wherever your setup keeps cross-session memory.
4. **Blast-radius sweep (added 2026-07-04)** — the step everyone skips, and the reason
   decisions "don't take". The decision changed a value; now **grep the OLD value across
   the entire instruction surface**: hub files, memory file *bodies*, and every spoke's
   CLAUDE.md / `docs/first-principles.md` / execution docs. Every hit is a stale copy
   that will keep steering some session. For each hit: convert it to a reference to the
   canonical, or mark it stale *in the body* of the file. **The decision counts as
   landed only when a grep for the old truth comes back zero.**

## The scar behind step 4

A product decision moved one module from the free tier to the paid tier. The primary
canonical was updated the same day — steps 1–3 done by the book. But four stale copies
of the old rule ("everything in this set is free") survived in other docs. The worst
one sat inside a spoke's `docs/first-principles.md` — **the exact file the
`canonical-sync` hook auto-injects into every prompt of that spoke's sessions**. So for
a week, our own sync machinery force-fed the outdated rule with hook-level authority,
and sessions kept confidently "re-deciding" the old way no matter how often the human
corrected them. The fix wasn't repeating the correction — it was grepping the old
phrase, finding all four copies, and pointing each at the canonical.

Two lessons inside the lesson:

- **Your sync machinery amplifies whatever it's fed.** A stale copy in a file that hooks
  auto-inject isn't just drift — it's drift with system authority. That makes the sweep
  *more* urgent the better your sync is.
- **Staleness markers must live where retrieval happens.** If your memory system recalls
  individual files, marking a fact stale only in an index file does nothing — the stale
  file still gets recalled whole and believed. Put the marker in the file's *body* (and
  its description/frontmatter), not just the index.

## Why grep, of all things

Because it's the only check that doesn't depend on anyone *remembering* where the copies
are. Rule 1 ("reference, never copy") is the prevention; the sweep is the detection for
the copies that got made anyway — by past sessions, by imports, by you on a bad day.
Zero grep hits is an objective, externally verifiable acceptance criterion (the same
standard we hold workers to), applied to the act of deciding itself.
