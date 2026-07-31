# Retro: Bound worker context with delegated checkpoints

- TASK: 20260731-174348
- BRANCH: feat/bounded-worker-context
- REVIEW ROUNDS: 1

## What went well

The budget forced the right placement twice in a row. Putting the 120K/150K
trigger in `work/SKILL.md` and only the protocol in `delegation.md` was not
generosity toward the body budget - the reference loads on "context pressure",
so an agent that has not yet noticed the pressure would never reach the number
that defines it. A reference cannot own its own trigger.

Applying the previous Story's lesson before implementation rather than after.
`proof-must-cover-its-conjunct` landed one commit earlier, and the first thing
this task did was measure its own DoD proofs against base - which is how the
already-green `rg -q 'independent'` conjunct was caught.

## What went wrong

The plan's DoD proof for the delegation rules was GREEN on master before any
code existed: `rg -q 'independent'` matched `verify.md`, three files away from
anything this Story would write. The threshold proof was directory-scoped in
the same way. Both were rewritten during WORKING.

The failed decision belongs to plan time, not to this session: proofs were
written as directory-scoped greps for tokens that read as distinctive
("exclusive", "one writer", "independent") without running them against the
base branch first. `independent` is only distinctive in the sentence the
author had in mind. The plans for this Epic were pre-approved as written, so
the baseline run that would have caught it never happened - the review's
`Process signal:` names this as a plan-gate gap rather than an implementation
failure, which is exactly the routing the new rule is for.

Second, self-inflicted and caught only by luck: the sabotage harness reported
all six threshold conjuncts as surviving mutation. The proof was sound; the
harness was not. `p2; echo "kill [$t] in $(basename $f) -> P2=$?"` runs the
command substitution between the proof and the `$?` expansion, so every line
reported basename's exit status. The identical rule is already in the ledger
as `test-harness-exit-code` for pipes. A command substitution anywhere in the
reporting line is the same defect, and this is its second occurrence.

## What to improve next time

Capture `e=$?` on the line that produces it, before any string that could
contain a substitution. Never inline `$(...)` in the same echo that reads
`$?`.

A DoD proof token has to be distinctive in the repository, not in the sentence
the planner is imagining. Run it against base at plan time.

## Action items

- No follow-up task. The plan-gate half is Story 20260731-174343's scope, and
  the missing flow Route row for the checkpoint handoff is
  Story 20260731-174352's; both are already planned in this Epic.
