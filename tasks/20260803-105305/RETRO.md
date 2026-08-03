# Retro: Replace afk's agent-driven gates with tatr flow and sprout land probes

- TASK: 20260803-105305
- BRANCH: refactor/afk-mechanical-gates
- REVIEW ROUNDS: 2

## What went well

The probe/execute/verify shape held for all four gates without a special case,
because `tatr flow -n` and `sprout land -n` run the real preconditions. afk
never has to guess, so the only agent it wakes is the one a refusal needs.

Both review rounds were falsified rather than argued. Round 1's fix was
mutation-tested (restoring the old ordering fails exactly one test), and round
2's single finding was proved by replacing the suspect assertion with `test -d`
and watching it fail. Neither round traded a claim for a re-read.

Moving the fixtures onto real `sprout new` instead of hand-rolled
`git worktree add` paid off twice: `sprout.target` made `sprout land` accept
the fixtures, and the suite now exercises the path production takes.

## What went wrong

The plan contradicted itself and the code followed the wrong half. TASK.md's
"Consequences to handle" said an already-advanced session must be a skip, and
Step 10 spelled out an ordering (`require_activity` first) that made the skip
unreachable from two of the three gates. Both were written in the same pass, so
the contradiction predates any code. The implementation followed the Step, the
Close-out honestly recorded the gap, and review round 1 was spent on it.

Step 6 ("write the new tests red, before touching `afk.sh`") was ticked while
its own Reflection said the ordering was inverted. The mutations named there
are real evidence, but a Step whose entire content is an ordering constraint
should not be ticked when the ordering was not kept. Unticking it turned out to
be unavailable: `tatr flow` refuses to leave COMPOUNDING with an unchecked
Steps item, so a task cannot close while admitting a Step it did not deliver.
The tick is back, qualified in the Step's own text, and the admission lives in
three places instead of the checkbox. The real lesson is upstream of the
checkbox - a Step should state a deliverable, not an ordering, because an
ordering constraint is unverifiable after the fact and unrepresentable in the
one field that gates the close.

Round 1's MINOR fix introduced round 2's only finding, in the same shape: an
assertion inspecting a worktree that `sprout land` had already removed, so it
could not fail. It stays open - the behaviour is proven one line above - but a
false sentence in the R1.2 Response had to be corrected in round 2.

## What to improve next time

The from-scratch challenge in `plan` would not have caught this; the plan's
prose and its Steps were each defensible alone. What catches it is reading the
Steps back against the "Consequences to handle" list they were derived from and
asking, for each consequence, which Step delivers it. Two of the three gates
had no Step that could.

A check written to prove "nothing is dirty here" needs a paired guard that the
thing it inspects still exists when the check runs. `test -z "$(git -C <gone>
...)"` is indistinguishable from success.

No context pressure was observed: no checkpoint, no compaction warning, and no
delegation beyond the two out-of-context review rounds the skill requires.

## Action items

- Write Steps as deliverables, never as orderings. "Write the tests red before
  touching X" cannot be verified after the fact and cannot be honestly
  unticked, because `tatr flow` will not close a task with an unchecked Step.
  The checkable form is "each new test has been shown to fail without its fix".
- R2.1 is open and unticked: drop the dead clean-worktree assertion in
  `test_gate_overshoot_is_a_skip` and strike the matching clause from the R1.2
  Response, or re-aim it at the main checkout, which survives the land.

## Landing message

```
refactor: answer afk's gates in code, not in a session

afk no longer spends a Claude session on any of its four approval gates.
Each gate is probe, execute, verify: `tatr flow -n` probes the three
lifecycle transitions and `sprout sync -n` / `sprout land -n` probe the
landing, so afk performs the transition itself, commits `tasks/<id>` and
re-checks the result against tatr and git. A gate whose postcondition
already holds is skipped rather than fatal. A refused probe is not a
failed run: it wakes a FRESH `/flow <id>` carrying the ANSI-free refusal
text, which is the one case an agent is worth waking for.

`run_claude` loses its `--resume` branch - every invocation is a new
`--session-id`, and durable state is all a fresh `/flow` ever needed. A
goal run is four sessions, down from eight. The sprout derivation moves
to `home/modules/scripts/sprout-pkg.nix` so `afk.nix` can put it on the
runtime PATH, and the runner suite grows from 19 tests to 26.
```
