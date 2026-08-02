# Decision: make round-1 review unconditionally out-of-context and survive a gate overshoot in afk

- DATE: 20260803-004050
- STATUS: ACCEPTED
- TASK: 20260803-002416
- TAGS: afk,agents,review

## Context

An `afk run` died on a benign overshoot: the WORK_DONE gate's postcondition is
an equality test on ACTIVITY, and the resumed session ran three phases in one
context, leaving the record at `COMPOUNDING` / `PLAN REVIEW RETRO` /
`RESOLUTION DONE`. The same missed context cut also turned round 1 into a
self-review, recorded as `REVIEWER: primary, in-context` under an exception the
skill itself offers. Planning had to settle four open questions before the work
starts.

## Decision

1. **The postcondition is a floor; the precondition stays an equality.**
   `lifecycle_gate`'s two ends answer different questions. Before the resume,
   "the session reported WORK_DONE from somewhere that is not WORKING" is a
   genuine disagreement between session and record. After it, the lifecycle
   only ever guarantees at-or-past, so equality rejects durable state for being
   too far along - which contradicts afk's premise that durable state is the
   authority. One new helper, `require_activity_at_least`; `require_activity`
   is left alone.

2. **`- REVIEWER: in-session (<why>)` survives, narrowed.** Codex and opencode
   read the same skills, and a runtime with no way to start a second context
   cannot satisfy "always". It stays as the single named exception, reworded to
   name a runtime capability. "for a trivial diff" goes - that is a
   discretionary hatch of the same shape as the fresh-session clause this task
   deletes.

3. **Only round 1 becomes unconditional.** `SKILL.md` step 5 - later rounds
   keep the out-of-context default unless an exception is recorded - stays.
   Round 1 is where the independent judgment lives; later rounds verify
   `Response:` lines against findings already written, which the implementing
   context can read honestly. The rule is now "round 1 always, later rounds by
   default": one hatch, in one place, for the cheaper half.

4. **afk does not gate on `- REVIEWER:`.** Not implemented, deliberately.

## Alternatives considered

- **Delete `in-session` entirely.** Makes `missing-reviewer` unsatisfiable on a
  runtime with no subagents, or pushes it into writing `out-of-context` for a
  review that was not one. A false record is worse than a narrow exception.
- **Make every round unconditional.** Multiplies subagents for the rounds with
  the least to gain, and later rounds' work is confirming named fixes.
- **Have afk refuse a round whose reviewer is `in-session`.** Turns a
  documented default into a hard gate, and would have failed the nova-protocol
  `20260802-183352` run over a review that was sound on inspection. Recorded
  here so it is not re-litigated; it is a separate task if the default keeps
  being skipped.
- **Ship only the `PROTOCOL` wording.** Leaves the same non-deterministic
  failure in place - the overshoot is model variance the protocol can bias but
  not eliminate.
- **Loosen `require_activity` itself.** Would weaken the precondition too,
  where equality is the whole point.

## Consequences

- afk needs the lifecycle order as data. That is a second place the activity
  vocabulary is written down (`phase_gloss` is the first); a new activity has
  to be added to both.
- Round 1 always spends a subagent, including under a standing
  do-not-delegate directive - `review/SKILL.md` now supplies the fact that
  satisfies that directive's own "unless the user requested it" condition, and
  it reaches every repository and runtime because the skills deploy to
  `~/.claude/skills`, `~/.agents/skills` and `~/.codex/skills`.
- The `ROTATE` protocol wording and the unconditional reviewer are now
  independent: neither is load-bearing for the other's guarantee.
