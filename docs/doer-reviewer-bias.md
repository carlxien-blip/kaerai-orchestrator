# doer ≠ reviewer — guarding against self-rating bias

The trap: the agent that did the work is the worst judge of whether the work is done. Asked
"did you finish?", an agent will happily say yes — a large share of agent failures are exactly
this, the agent talking to itself and rating its own output as good.

The fix is structural separation of the doer and the reviewer.

## The flow

1. **Define spec + objective acceptance, with the human, before acting.** Criteria fixed
   pre-dispatch and externally verifiable: tests green, build passes, expected output for named
   behavior cases, which files must not be touched.
2. **Worker (independent context, inside the project dir).** Reads brief + project canonical ->
   implements -> runs build/test/lint **itself** -> reports done only on green, **with evidence**
   (test output, diff), not just the word "done".
3. **Reviewer — dispatched AFTER the worker delivers, not concurrently.** You can't review a
   product that doesn't exist yet, so the reviewer comes second. Its independence is **context
   independence**: a fresh mind that never wrote this code, explicitly told to be adversarial —
   "assume it's broken, find faults". It checks the diff against spec and **re-runs it itself**,
   trusting evidence over the worker's claims. It exists to cover the specific gap that *tests
   green != built to spec* (missed cases, broke something else, doesn't match intent).
4. **Falls short -> bounce back to the worker** for another round, up to the loop limit (default
   3). On hitting the limit, stop and ask the human — don't spin and burn tokens.
5. **The orchestrator is not the final judge.** It must not review its own dispatched work and
   declare "looks good" — that's maximum bias. It only aggregates deterministic results + the
   reviewer's verdict, and hands residual taste/behavior judgment to the human.
6. **The human reviews only their slice** — is the behavior right, the experience good, is it
   what they wanted. That's taste; no reviewer agent replaces it.

## Two honest boundaries

- **Shared blind spot.** The reviewer is also an LLM, same source as the worker. It catches
  author bias and framing bias, but **not the error neither of them would think of**. The real
  backstop is deterministic checks (tests/build — the machine decides) plus the human. The more
  of the spec you can express as machine-verifiable acceptance, the more reliable this whole
  scheme is.
- **Strictness scales with risk.** A locally-reversible small feature: worker + one reviewer +
  green tests is enough. Touching production / payments / data: add multiple adversarial reviewers
  and a mandatory human gate.
