# Review dimensions

The lenses every reviewer runs, out-of-context or in-session. Verify; do not
trust the implementer's summary.

## Correctness

Bugs, edge cases, error handling, concurrency, security. A validation gate
must check a value's meaning in EACH domain it crosses - filesystem path, URL
segment, storage key, served set - not just the domain it was written in. A
trimmed re-validation of an untrimmed parse is a hole: check the bytes the
parser actually consumes.

## Spec

Does the diff deliver the Story? Is every ticked step really done - re-read
each step's literal text against the diff, because ticks from intent have
shipped undelivered clauses. Run each proof from `tatr proofs <id>` yourself
and confirm it passes on ITS stated criterion. Each open `manual:` proof is
not yours to resolve; note it as a pending user check to list with the
verdict.

## Tests

Run the full check suite yourself. Then ask of the new tests:

- Do they assert behavior, or merely execute code?
- Were any existing tests weakened or deleted to reach green?
- Would this test fail with the fix deleted? A test that cannot fail - often
  one copied from a neighbour - verifies nothing.
- Does an "X stays zero / nothing happens" assertion have a paired delivery
  guard proving the provoking stimulus actually fired?
- Is the bug pinned at its OWN boundary, not only by a downstream end-to-end
  test?
- When a refactor changed how an invariant is enforced, was the invariant
  re-pinned on the new mechanism, or the old assertion massaged until it
  passed?

## Design

Consistency with the repository's conventions, missed reuse, and scope the
Story did not ask for. YAGNI is a finding: an abstraction with one caller, an
unused parameter or option, a knob nobody requested, generality no Step names.
Name the lines to delete. Refactoring, tests and records the plan asked for are
not YAGNI findings. If the diff makes a load-bearing architectural choice a
cold reader would need the *why* of, check it has a `DECISION.md`, and that a
decision changing an earlier one carries the supersede link on BOTH records. A
missing record for a genuinely load-bearing choice is MINOR, not BLOCKER.

## Docs

Behavior changes worth documenting are covered in the task's NOTES.md or the
project's reference docs, and the doc-surface sweep ran. Spot-check it: pick
one renamed or changed symbol, flag or path from the diff and grep README, the
reference docs, AGENTS.md and the skill files for stale mentions. When the
repository ships skills, an edit to what a skill describes invalidates that
skill text - the sweep owed it an update in the same task.

The `tasks/` tree is exempt. It is append-only history, so an old record
quoting the pre-rename name is correct, not stale.

## Honesty

TASK.md's close-out notes match what the code actually does. A claimed proof
that was never run, a recorded number no rig produced, and a self-ticked
`manual:` item are all BLOCKER-class findings regardless of how good the code
is.
