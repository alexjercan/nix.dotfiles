# make round-1 review unconditionally out-of-context and survive a gate overshoot in afk

- PRIORITY: 60
- TAGS: afk,scripts,agents
- KIND: TASK
- ACTIVITY: -
- GATES: -
- RESOLUTION: -

An `afk run` of `nova-protocol` task `20260802-183352` died with:

    error  the work done gate was approved but 20260802-183352 is in
           COMPOUNDING, not REVIEWING

The work was fine. The branch carried three good commits, REVIEW.md held a
round 1 APPROVE with mutation-tested evidence, RETRO.md was written, and the
record read `COMPOUNDING` / `PLAN REVIEW RETRO` / `RESOLUTION DONE` - the legal
terminal pre-land state. Only the landing was missing, and `afk run <id>`
recovered it through the LAND_READY route.

What broke is afk's postcondition. `lifecycle_gate WORK_DONE` asserts the
cursor through `require_activity`, which is an equality test. The resumed gate
session performed the `WORKING -> REVIEWING` transition and then, instead of
stopping at the context cut `gates.md` asks for, kept going: `review`,
APPROVE, REVIEW earned, `compound`, RETRO earned, RESOLUTION DONE. So the
cursor afk read was two activities past the one it demanded.

The lifecycle only guarantees the cursor is at or past the gate's target, never
exactly on it. Equality turns a benign overshoot into a failed run, and afk's
whole premise is that durable state - not a session's prose - is the authority;
a check that rejects durable state for being *too far along* contradicts that.

The same session also reviewed its own work. Because it never stopped at the
cut, no fresh session ever started at REVIEWING, and REVIEW.md round 1 records
`REVIEWER: primary, in-context` with an exception citing an operator policy
that forbids spawning subagents unless the user asks. The verdict held up on
inspection, but a self-review is not what the cycle promises. That is the third
change below.

Three changes, and all three are wanted:

- Loosen the postcondition. `require_activity` for a gate should accept the
  expected activity or any later one, which means afk needs the lifecycle order
  (the strict equality form still belongs to `lifecycle_gate`'s precondition,
  where "the session reported WORK_DONE from somewhere that is not WORKING" is
  a genuine disagreement). This applies to the PLAN gate too: a session that
  overshoots `PLANNING -> WORKING` into `REVIEWING` would fail the same way.
- Reinforce the protocol. `PROTOCOL` in `home/modules/scripts/afk.sh` never
  tells the session what to do after the runner answers a gate. Say it: perform
  the transition, commit the records, then stop and report `ROTATE` rather than
  continuing into the next phase. Session 1 of that same run stopped correctly
  at the PLAN gate, so this is model variance the protocol can bias but not
  eliminate - which is exactly why it is the second half of the fix and not the
  whole of it.
- Make the round-1 reviewer unconditional, and say who authorized it.
  `review/SKILL.md` step 2 currently reads "A fresh `/flow <id>` session that
  starts at REVIEWING counts as the outside reviewer; do not spawn another by
  default", and `review/rounds.md` repeats it under
  `## The round-1 subagent handoff`. Delete both. Round 1 always starts a
  reviewer outside the implementing context; `review/lanes.md` already governs
  when to fan that out further. Then state, in `review/SKILL.md`, that invoking
  the skill IS the request for that reviewer.

The first change is what makes a run survive the overshoot; the second is what
makes the overshoot rare. Shipping only the protocol wording would leave the
same non-deterministic failure in place.

The first two belong in `home/modules/scripts/afk.sh` with coverage in
`home/modules/scripts/afk-test.sh`; the suite has no case where a gate resume
leaves the cursor past its target.

## Why the reviewer is unconditional

"The session happens to be fresh" is not a property anyone can verify after the
fact, and it is not one the phase controls. This run is the demonstration: the
clause was written for exactly this shape - afk starts every continuation
fresh, so a rotation to REVIEWING would have been a genuine outside reviewer -
and one skipped context cut turned it into a self-review with a recorded
exception. A spawned reviewer is out-of-context by construction. We already run
multiple agents, and `review/lanes.md` already describes parallel lanes over
the same handoff, so the escape hatch buys a saved subagent at the cost of the
one property round 1 exists to have.

Note the consequence for the second change: with an unconditional reviewer, the
rotation is no longer what makes round 1 out-of-context. Both afk changes stand
on their own - a run must not die on a benign overshoot, and a session must not
run three phases in one context - but neither is load-bearing for the review
guarantee any more.

## Why the authorization has to live in the skill

Nothing under `review/` states that invoking the skill is the request. So a
session carrying a standing "do not call the Agent tool unless the user
requested it" directive - injected by the runtime, not by this repo; it is in
neither `~/.claude/settings.json`, `~/AGENTS.md`, `~/.claude/CLAUDE.md` nor
anywhere here, so it cannot be edited away - reads the directive as
operator-level and the skill as a repo preference, and resolves the conflict
against the skill. That is the conservative call on the information available.
It happened on nova-protocol `20260802-183352`, and before it on
`20260725-110435` and `20260725-121329`.

The authorization does exist, but only as this repo's auto-memory
(`flow-implies-its-reviewer-subagent`), which is scoped to `nix.dotfiles`.
nova-protocol's memory does not carry it, and sprout worktrees get their own
memory scope again, so the work and review phases would not see it even if it
were copied there. A sentence in `review/SKILL.md` reaches every repository and
every runtime, since the skills deploy to `~/.claude/skills`, `~/.agents/skills`
and `~/.codex/skills`.

It is not an override, and should not be worded as one. The directive's own
condition is "unless the user requested it"; running `/flow` or `/review` is
that request, for the whole documented cycle of which the reviewer is a named
part. The skill supplies the fact that satisfies the condition.

## Open questions for planning

- Codex and opencode read these same skills. A runtime with no way to start a
  second context cannot satisfy "always". Decide whether
  `- REVIEWER: in-session (<why>)` survives in `rounds.md` as that single named
  exception or goes entirely.
- Two other hatches sit next to the one being deleted: `SKILL.md` step 5,
  "later rounds keep the out-of-context default unless an exception is
  recorded", and `rounds.md`'s "for a trivial diff or a recorded exception".
  Decide their fate in the same pass rather than leaving a half-tightened rule.
- Word budgets are tight: `review/SKILL.md`'s body is at 351/400 and
  `review/rounds.md` at 591/600 under
  `home/modules/agents/skills/check.sh`. Deleting the fresh-session clause from
  both pays for most of the new sentence, but confirm with the checker rather
  than by eye.
- Nothing verifies the reviewer. afk cross-checks activity, gates, resolution
  and git, and reads `REVIEW.md` only for `VERDICT`; it could refuse a round
  whose `- REVIEWER:` is `in-session`. Deliberately NOT proposed here - it
  turns a default into a hard gate and would have failed this run over a sound
  review - but record the decision so it is not re-litigated.
