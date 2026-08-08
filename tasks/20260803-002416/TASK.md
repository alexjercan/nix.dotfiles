# make round-1 review unconditionally out-of-context and survive a gate overshoot in afk

- STATUS: CLOSED
- PRIORITY: 60
- TAGS: afk, scripts, agents

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

## Steps

- [x] `home/modules/scripts/afk.sh`: next to `phase_label`, add the lifecycle
  order as a constant (`UNDERSTANDING PLANNING WORKING REVIEWING COMPOUNDING`,
  confirmed against `tatr` in scratch) plus `activity_rank`, a lookup returning
  a position and failing on an unknown word.
- [x] `home/modules/scripts/afk.sh`: add `require_activity_at_least` beside
  `require_activity`, same three arguments, passing when the cursor's rank is
  at or past the expected one. An unreadable or unknown actual activity still
  dies, and the message names `<expected> or later`. Leave `require_activity`
  itself untouched - `lifecycle_gate`'s precondition keeps the equality test.
- [x] `home/modules/scripts/afk.sh`: in `lifecycle_gate`, switch the
  `activity)` postcondition arm to `require_activity_at_least`. Extend the
  function comment to say why the two ends differ: the precondition is a
  disagreement about where the session reported from, the postcondition is a
  floor, because the lifecycle only guarantees at-or-past.
- [x] `home/modules/scripts/afk.sh`: in `PROTOCOL`, after the gate sentence,
  state what to do once the runner answers - perform the transition, commit
  the task records, then stop and report `ROTATE`, rather than continuing into
  the next phase. Keep it to one or two sentences; `PROTOCOL` is injected into
  every session.
- [x] `home/modules/scripts/afk-test.sh`: in `test_failure_paths`, extend the
  existing "ineffective approval" case so the actual failure it names is
  distinguishable, then add the overshoot case: a WORKING task, invocation 1
  replies `AFK WORK_DONE <id>`, invocation 2's side script runs the transition
  AND `review` + `compound` to leave the record at `COMPOUNDING` /
  `PLAN REVIEW RETRO` / `RESOLUTION DONE`, and replies `AFK LAND_READY <id>`.
  Assert the run does NOT die on the postcondition. Model the side script on
  `gen_work_to_land`'s invocations 2 and 3, collapsed into one.
- [x] `home/modules/scripts/afk-test.sh`: add a case pinning the tightened
  postcondition - a WORK_DONE gate whose resume leaves the cursor BEHIND
  `REVIEWING` (still `WORKING`) still fails, naming `REVIEWING or later`. This
  is the existing "ineffective approval" assertion, updated for the new
  message.
- [x] `home/modules/agents/skills/review/SKILL.md` step 2: delete "A fresh
  `/flow <id>` session that starts at REVIEWING counts as the outside
  reviewer; do not spawn another by default". Replace with an unconditional
  round-1 reviewer plus the authorization sentence - invoking this skill IS
  the request for that reviewer, so it is spawned even under a standing
  do-not-delegate directive. Drop "explain exceptions" from the same step.
- [x] `home/modules/agents/skills/review/rounds.md`, under
  `## The round-1 subagent handoff`: delete the fresh-session clause; the
  paragraph states that round 1 always hands off outside this context and
  points at `work/delegation.md` for the bounded subagent shape.
- [x] `home/modules/agents/skills/review/rounds.md`, `## Required fields`:
  narrow `- REVIEWER:` to `out-of-context`, or `in-session (<why>)` reserved
  for a runtime with no way to start a second context. "for a trivial diff"
  goes; see DECISION.md.
- [x] Run `bash home/modules/agents/skills/check.sh` and confirm both budgets
  still pass; if either is over, trim within the two edited files rather than
  relaxing a budget.
- [x] Write DECISION.md recording the four planning decisions below.

## Definition of Done

- A WORK_DONE gate whose resume overshoots to `COMPOUNDING` /
  `RESOLUTION DONE` completes the run instead of dying.
  (test: `home/modules/scripts/afk-test.sh` overshoot case; red on base with
  `the work done gate was approved but ... is in COMPOUNDING, not REVIEWING`)
- A WORK_DONE gate whose resume leaves the cursor at `WORKING` still fails,
  and the message names `REVIEWING or later`.
  (test: `home/modules/scripts/afk-test.sh` ineffective-approval case)
- A PLAN_READY gate whose resume overshoots past `WORKING` still completes.
  (test: `home/modules/scripts/afk-test.sh`; see Notes - already true on base
  because that postcondition is `require_gate`, so this pins it rather than
  fixing it)
- The whole suite passes.
  (cmd: `bash home/modules/scripts/afk-test.sh`)
- `PROTOCOL` tells a gate-answering session to transition, commit records,
  stop, and report `ROTATE`.
  (cmd: `sed -n '/AFK RUNNER PROTOCOL/,/^EOF$/p' home/modules/scripts/afk.sh | grep -i 'commit the task records'`;
  red on base - the protocol already prints the word `ROTATE` in its status
  list, so grepping for that alone would pass without the change)
- No `review/` file offers a fresh session as a substitute for the round-1
  reviewer.
  (cmd: `! grep -rn 'starts at REVIEWING counts\|do not spawn another\|started at REVIEWING after\|trivial diff' home/modules/agents/skills/review/`;
  red on base - 3 matches, 2 in `SKILL.md` and 1 in `rounds.md`)
- `review/SKILL.md` states that invoking the skill is the request for the
  round-1 reviewer.
  (cmd: `grep -n 'request' home/modules/agents/skills/review/SKILL.md`)
- Skill budgets and conformance hold.
  (cmd: `bash home/modules/agents/skills/check.sh`)
- The repository gates hold.
  (cmd: `nix flake check`, `tatr check`)

## Notes

- Confirmed in scratch (`/tmp/tatrscratch`): the terminal pre-land record is
  `ACTIVITY: COMPOUNDING`, `GATES: PLAN REVIEW RETRO`, `RESOLUTION: DONE`.
  ACTIVITY is never cleared by a resolution, so ranking activities alone
  covers the reported overshoot; no resolution term is needed in the order.
- Correction to the Story: the PLAN gate is NOT currently broken by an
  overshoot. `lifecycle_gate PLAN_READY` uses the `gate PLAN` postcondition,
  and `require_gate` is a token match against an accumulating GATES field, so
  a cursor two activities past `WORKING` still passes. `WORK_DONE`'s
  `activity REVIEWING` is the only equality postcondition. The generalized
  helper is still the right shape - it is where any future `activity`
  postcondition lands - but the PLAN case is a regression pin, not a fix.
- Current budgets: `review/SKILL.md` body 351/400, `review/rounds.md` 591/600
  (measured with `check.sh`'s own `body_of` + `wc -w`). Both edits delete more
  than they add, so headroom grows.
- `flow/gates.md` "## Continue or stop" already tells the session to
  transition, commit records, and stop. The `PROTOCOL` change restates it at
  the runner's own authority level, where a session that never loaded
  `gates.md` still sees it.
- `check.sh` has a duplicated-prose rule (a 12+ word paragraph verbatim in two
  files). Deleting the near-duplicate clause from both `SKILL.md` and
  `rounds.md` only reduces exposure to it.
- Assumption: later rounds keep their recorded-exception default. Only round 1
  becomes unconditional - see DECISION.md.

## Close-out

What and why. `afk.sh` gained `ACTIVITY_ORDER` + `activity_rank` (a one-based
lookup that fails on any word it cannot place, the empty string included) and
`require_activity_at_least`. `lifecycle_gate`'s `activity)` postcondition arm
now calls it; the precondition still calls `require_activity`, and the function
comment says why the two ends differ. `PROTOCOL` gained one sentence telling a
gate-answering session to transition, commit the records, stop and report
`ROTATE`. `review/SKILL.md` step 2 now makes round 1's outside reviewer
unconditional and states that invoking the skill IS the request for it;
`review/rounds.md` lost the fresh-session clause and narrowed `in-session` to a
runtime that cannot start a second context.

Deviation from the Steps. The overshoot case is its own test,
`test_gate_resume_may_overshoot`, not an addition to `test_failure_paths`: it
asserts a run SUCCEEDS, and a success assertion inside a function whose whole
subject is failure reads as a mistake. `test_failure_paths` keeps the
ineffective-approval case, now pinning both halves of the new message
(`REVIEWING or later` and `is in WORKING`). The new test holds both overshoots -
the WORK_DONE one that was broken, and the PLAN_READY one that was already
survivable - so the two sit next to each other. Three side-script generators
(`gen_sprout_work`, `gen_review_to_done`, `gen_land`) were factored out of the
shapes `gen_work_to_land` already used.

Difficulties. Confirming the proof's red-on-base message needed the base
`afk.sh` restored under the NEW test, and `afk-test.sh` resolves `$AFK` from its
own directory, so the debug copy had to live in `home/modules/scripts/` rather
than `/tmp`. Base failure, verbatim: `the work done gate was approved but
20260803-005247 is in COMPOUNDING, not REVIEWING`. Seeding a PLANNING task
reused `seed_working_task` plus `tatr rewind --to PLANNING --force`; the plain
rewind refuses to discard the earned PLAN gate.

Evidence. `bash home/modules/scripts/afk-test.sh` - 19 passed, 0 failed (17
before). `bash home/modules/agents/skills/check.sh` - clean, budgets still pass
with more headroom than before. `nix flake check` - all checks passed.
`tatr check` - silent.

Reflection. The Notes' correction held up exactly: only `WORK_DONE` had an
equality postcondition, so the PLAN case is a pin. Writing that pin was still
worth it - both cases now go through one test whose comment states the
at-or-past invariant, which is the thing a future `activity` postcondition
needs to know.
